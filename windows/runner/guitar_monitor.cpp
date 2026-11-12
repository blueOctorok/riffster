#include "guitar_monitor.h"

#include "utils.h"

#include <flutter/encodable_value.h>
#include <flutter/event_channel.h>
#include <flutter/event_stream_handler_functions.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <audioclient.h>
#include <avrt.h>
#include <mmdeviceapi.h>
#include <mmreg.h>

#include <wrl/client.h>

#include <algorithm>
#include <atomic>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <mutex>
#include <string>
#include <thread>
#include <vector>

namespace {

using Microsoft::WRL::ComPtr;

constexpr UINT kPcmMessage = WM_APP + 7;
constexpr int kRingCap = 16384;
// 100-nanosecond units. 10 ms is one USB audio frame. Shorter than that
// and the speaker asks for samples the cable has not delivered yet, which
// plays as static.
constexpr REFERENCE_TIME kShortPeriod = 100000;
// Exclusive capture skips the Windows recording level and Microphone Boost,
// so the raw cable sits around a fifth of full scale and sounds faint.
// The volume slider sends 0 to 1. Full is this four-times boost. WriteSample
// caps anything past full scale, so a hard hit flattens instead of wrapping
// into fuzz. The copy Dart uses for pitch is left at the raw level.
constexpr float kMonitorGain = 4.f;
// The count-in click: a short tone that dies away. It is made here, on
// the audio thread, because in exclusive mode this thread owns the
// speakers and nothing else in the app can be heard.
constexpr float kClickSeconds = 0.03f;
constexpr float kClickLevel = 0.35f;
constexpr float kClickHz = 1046.5f;
constexpr float kAccentClickHz = 1568.f;
constexpr float kTwoPi = 6.2831853f;

// PKEY_Device_FriendlyName and PKEY_Device_DeviceDesc. Written out so this
// file does not have to define every Windows GUID.
const PROPERTYKEY kFriendlyName = {
    {0xa45c254e, 0xdf1c, 0x4efd, {0x80, 0x20, 0x67, 0xd1, 0x46, 0xa8, 0x50, 0xe0}},
    14};
const PROPERTYKEY kDeviceDesc = {
    {0xa45c254e, 0xdf1c, 0x4efd, {0x80, 0x20, 0x67, 0xd1, 0x46, 0xa8, 0x50, 0xe0}},
    2};

const GUID kSubtypePcm = {
    0x00000001, 0x0000, 0x0010, {0x80, 0x00, 0x00, 0xaa, 0x00, 0x38, 0x9b, 0x71}};
const GUID kSubtypeFloat = {
    0x00000003, 0x0000, 0x0010, {0x80, 0x00, 0x00, 0xaa, 0x00, 0x38, 0x9b, 0x71}};

struct AudioFormat {
  int rate = 0;
  int channels = 0;
  int block = 0;
  bool is_float = false;
  bool exclusive = false;
};

struct Ring {
  float data[kRingCap] = {};
  int read = 0;
  int count = 0;

  void Clear() {
    read = 0;
    count = 0;
  }

  void Push(float sample) {
    if (count == kRingCap) {
      read = (read + 1) % kRingCap;
      count--;
    }
    data[(read + count) % kRingCap] = sample;
    count++;
  }

  bool Pop(float* sample) {
    if (count == 0) return false;
    *sample = data[read];
    read = (read + 1) % kRingCap;
    count--;
    return true;
  }

  float Peek() const { return data[read]; }

  void DropDownTo(int keep) {
    if (count <= keep) return;
    const int drop = count - keep;
    read = (read + drop) % kRingCap;
    count = keep;
  }
};

void LogHr(const char* what, HRESULT hr) {
  char buffer[160];
  sprintf_s(buffer, "Riffster %s failed 0x%08lx\n", what, static_cast<unsigned long>(hr));
  OutputDebugStringA(buffer);
}

std::wstring Lower(std::wstring value) {
  for (auto& ch : value) ch = static_cast<wchar_t>(towlower(ch));
  return value;
}

bool Contains(const std::wstring& hay, const wchar_t* needle) {
  return hay.find(needle) != std::wstring::npos;
}

std::wstring ReadProp(IPropertyStore* store, const PROPERTYKEY& key) {
  PROPVARIANT value;
  PropVariantInit(&value);
  std::wstring text;
  if (SUCCEEDED(store->GetValue(key, &value)) && value.vt == VT_LPWSTR && value.pwszVal) {
    text = value.pwszVal;
  }
  PropVariantClear(&value);
  return text;
}

std::wstring DeviceName(IMMDevice* device, std::wstring* match) {
  ComPtr<IPropertyStore> store;
  if (FAILED(device->OpenPropertyStore(STGM_READ, &store))) return L"";
  const std::wstring friendly = ReadProp(store.Get(), kFriendlyName);
  const std::wstring desc = ReadProp(store.Get(), kDeviceDesc);
  *match = Lower(friendly + L" " + desc);
  return friendly.empty() ? desc : friendly;
}

bool IsGuitarName(const std::wstring& name) {
  return Contains(name, L"rocksmith") || Contains(name, L"real tone") ||
         Contains(name, L"guitar adapter");
}

struct PickedDevice {
  ComPtr<IMMDevice> device;
  std::string name;
  bool irig = false;
};

PickedDevice PickCapture(IMMDeviceEnumerator* enumerator) {
  PickedDevice rocksmith;
  PickedDevice irig;
  ComPtr<IMMDeviceCollection> devices;
  if (FAILED(enumerator->EnumAudioEndpoints(eCapture, DEVICE_STATE_ACTIVE, &devices))) {
    return {};
  }
  UINT count = 0;
  devices->GetCount(&count);
  for (UINT i = 0; i < count; i++) {
    ComPtr<IMMDevice> device;
    if (FAILED(devices->Item(i, &device))) continue;
    std::wstring match;
    const std::wstring display = DeviceName(device.Get(), &match);
    if (!rocksmith.device && IsGuitarName(match)) {
      rocksmith.device = device;
      rocksmith.name = Utf8FromUtf16(display.c_str());
    } else if (!irig.device && Contains(match, L"irig")) {
      irig.device = device;
      irig.name = Utf8FromUtf16(display.c_str());
      irig.irig = true;
    }
  }
  if (rocksmith.device) return rocksmith;
  return irig;
}

ComPtr<IMMDevice> PickRender(IMMDeviceEnumerator* enumerator, bool irig) {
  if (irig) {
    ComPtr<IMMDeviceCollection> devices;
    if (SUCCEEDED(enumerator->EnumAudioEndpoints(eRender, DEVICE_STATE_ACTIVE, &devices))) {
      UINT count = 0;
      devices->GetCount(&count);
      for (UINT i = 0; i < count; i++) {
        ComPtr<IMMDevice> device;
        if (FAILED(devices->Item(i, &device))) continue;
        std::wstring match;
        DeviceName(device.Get(), &match);
        if (Contains(match, L"irig")) return device;
      }
    }
  }
  ComPtr<IMMDevice> device;
  enumerator->GetDefaultAudioEndpoint(eRender, eConsole, &device);
  return device;
}

WAVEFORMATEXTENSIBLE MakeFormat(int rate, int channels, int bits, bool is_float) {
  WAVEFORMATEXTENSIBLE format = {};
  format.Format.wFormatTag = WAVE_FORMAT_EXTENSIBLE;
  format.Format.nChannels = static_cast<WORD>(channels);
  format.Format.nSamplesPerSec = static_cast<DWORD>(rate);
  format.Format.wBitsPerSample = static_cast<WORD>(bits);
  format.Format.nBlockAlign = static_cast<WORD>(channels * bits / 8);
  format.Format.nAvgBytesPerSec = format.Format.nSamplesPerSec * format.Format.nBlockAlign;
  format.Format.cbSize = sizeof(WAVEFORMATEXTENSIBLE) - sizeof(WAVEFORMATEX);
  format.Samples.wValidBitsPerSample = static_cast<WORD>(bits);
  if (channels == 1) {
    format.dwChannelMask = SPEAKER_FRONT_CENTER;
  } else {
    format.dwChannelMask = SPEAKER_FRONT_LEFT | SPEAKER_FRONT_RIGHT;
  }
  format.SubFormat = is_float ? kSubtypeFloat : kSubtypePcm;
  return format;
}

AudioFormat Describe(const WAVEFORMATEX* mix, bool exclusive) {
  AudioFormat format;
  format.rate = static_cast<int>(mix->nSamplesPerSec);
  format.channels = mix->nChannels;
  format.block = mix->nBlockAlign;
  format.exclusive = exclusive;
  if (mix->wFormatTag == WAVE_FORMAT_EXTENSIBLE &&
      mix->cbSize >= sizeof(WAVEFORMATEXTENSIBLE) - sizeof(WAVEFORMATEX)) {
    const auto* ext = reinterpret_cast<const WAVEFORMATEXTENSIBLE*>(mix);
    format.is_float = IsEqualGUID(ext->SubFormat, kSubtypeFloat) == TRUE;
  } else {
    format.is_float = mix->wFormatTag == WAVE_FORMAT_IEEE_FLOAT;
  }
  return format;
}

float ReadSample(const BYTE* frame, const AudioFormat& format) {
  const int container = format.channels > 0 ? format.block / format.channels : 0;
  if (format.is_float && container == 4) {
    return *reinterpret_cast<const float*>(frame);
  }
  if (container == 2) {
    return *reinterpret_cast<const int16_t*>(frame) / 32768.f;
  }
  if (container == 3) {
    int value = frame[0] | (frame[1] << 8) | (frame[2] << 16);
    if (value & 0x800000) value |= ~0xFFFFFF;
    return value / 8388608.f;
  }
  if (container == 4) {
    return *reinterpret_cast<const int32_t*>(frame) / 2147483648.f;
  }
  return 0.f;
}

// The slider is 0 to 1. One is the makeup gain. Anything outside that
// range is pulled back so a bad message cannot blast the speakers.
float MonitorGain(const flutter::EncodableValue* args) {
  double raw = 1.0;
  if (args != nullptr) {
    if (std::holds_alternative<double>(*args)) raw = std::get<double>(*args);
    else if (std::holds_alternative<int32_t>(*args)) raw = std::get<int32_t>(*args);
  }
  if (raw < 0) raw = 0;
  if (raw > 1) raw = 1;
  return static_cast<float>(raw) * kMonitorGain;
}

void WriteSample(BYTE* frame, float sample, const AudioFormat& format) {
  if (sample > 1.f) sample = 1.f;
  if (sample < -1.f) sample = -1.f;
  const int container = format.channels > 0 ? format.block / format.channels : 0;
  for (int channel = 0; channel < format.channels; channel++) {
    BYTE* dest = frame + channel * container;
    if (format.is_float && container == 4) {
      *reinterpret_cast<float*>(dest) = sample;
    } else if (container == 2) {
      *reinterpret_cast<int16_t*>(dest) = static_cast<int16_t>(sample * 32767.f);
    } else if (container == 3) {
      const int value = static_cast<int>(sample * 8388607.f);
      dest[0] = static_cast<BYTE>(value);
      dest[1] = static_cast<BYTE>(value >> 8);
      dest[2] = static_cast<BYTE>(value >> 16);
    } else if (container == 4) {
      *reinterpret_cast<int32_t*>(dest) = static_cast<int32_t>(sample * 2147483647.f);
    }
  }
}

class Endpoint {
 public:
  ComPtr<IAudioClient> client;
  HANDLE event = nullptr;
  AudioFormat format;
  UINT32 buffer_frames = 0;

  ~Endpoint() { Close(); }

  void Close() {
    client.Reset();
    if (event) {
      CloseHandle(event);
      event = nullptr;
    }
  }

  bool TryExclusive(IMMDevice* device, const WAVEFORMATEXTENSIBLE& format_in) {
    Close();
    ComPtr<IAudioClient> opened;
    HRESULT hr = device->Activate(__uuidof(IAudioClient), CLSCTX_ALL, nullptr, &opened);
    if (FAILED(hr)) return false;
    if (opened->IsFormatSupported(AUDCLNT_SHAREMODE_EXCLUSIVE, &format_in.Format, nullptr) != S_OK) {
      return false;
    }
    REFERENCE_TIME def_period = 0;
    REFERENCE_TIME min_period = 0;
    opened->GetDevicePeriod(&def_period, &min_period);
    // The device minimum is often 1–3 ms. That plays, then crackles.
    // Ask for 10 ms first. The raw minimum is only the last try.
    const REFERENCE_TIME stable = std::max(min_period, kShortPeriod);
    const REFERENCE_TIME periods[] = {
        stable,
        def_period > 0 ? def_period : stable,
        min_period > 0 ? min_period : stable,
    };
    for (REFERENCE_TIME period : periods) {
      if (period <= 0) continue;
      if (InitExclusive(device, format_in, period)) return true;
    }
    return false;
  }

  bool TryShared(IMMDevice* device) {
    Close();
    ComPtr<IAudioClient> opened;
    HRESULT hr = device->Activate(__uuidof(IAudioClient), CLSCTX_ALL, nullptr, &opened);
    if (FAILED(hr)) return false;
    WAVEFORMATEX* mix = nullptr;
    hr = opened->GetMixFormat(&mix);
    if (FAILED(hr) || mix == nullptr) return false;
    hr = opened->Initialize(AUDCLNT_SHAREMODE_SHARED, AUDCLNT_STREAMFLAGS_EVENTCALLBACK, 0, 0, mix,
                            nullptr);
    if (FAILED(hr)) {
      LogHr("shared init", hr);
      CoTaskMemFree(mix);
      return false;
    }
    const bool started = Finish(opened, Describe(mix, false));
    CoTaskMemFree(mix);
    return started;
  }

 private:
  bool InitExclusive(IMMDevice* device, const WAVEFORMATEXTENSIBLE& format_in, REFERENCE_TIME period) {
    ComPtr<IAudioClient> opened;
    HRESULT hr = device->Activate(__uuidof(IAudioClient), CLSCTX_ALL, nullptr, &opened);
    if (FAILED(hr)) return false;
    hr = opened->Initialize(AUDCLNT_SHAREMODE_EXCLUSIVE, AUDCLNT_STREAMFLAGS_EVENTCALLBACK, period,
                            period, &format_in.Format, nullptr);
    if (hr == AUDCLNT_E_BUFFER_SIZE_NOT_ALIGNED) {
      UINT32 frames = 0;
      opened->GetBufferSize(&frames);
      opened.Reset();
      hr = device->Activate(__uuidof(IAudioClient), CLSCTX_ALL, nullptr, &opened);
      if (FAILED(hr)) return false;
      const REFERENCE_TIME aligned = static_cast<REFERENCE_TIME>(
          static_cast<double>(frames) * 10000000.0 / format_in.Format.nSamplesPerSec + 0.5);
      hr = opened->Initialize(AUDCLNT_SHAREMODE_EXCLUSIVE, AUDCLNT_STREAMFLAGS_EVENTCALLBACK,
                              aligned, aligned, &format_in.Format, nullptr);
    }
    if (FAILED(hr)) return false;
    return Finish(opened, Describe(&format_in.Format, true));
  }

  bool Finish(ComPtr<IAudioClient> opened, AudioFormat described) {
    HANDLE created = CreateEvent(nullptr, FALSE, FALSE, nullptr);
    if (!created) return false;
    if (FAILED(opened->SetEventHandle(created))) {
      CloseHandle(created);
      return false;
    }
    UINT32 frames = 0;
    opened->GetBufferSize(&frames);
    client = std::move(opened);
    event = created;
    format = described;
    buffer_frames = frames;
    return buffer_frames > 0;
  }
};

class Monitor {
 public:
  Monitor() {
    stop_event_ = CreateEvent(nullptr, TRUE, FALSE, nullptr);
    ready_event_ = CreateEvent(nullptr, TRUE, FALSE, nullptr);
  }

  ~Monitor() {
    Stop();
    if (stop_event_) CloseHandle(stop_event_);
    if (ready_event_) CloseHandle(ready_event_);
  }

  void Attach(HWND hwnd, flutter::BinaryMessenger* messenger) {
    std::lock_guard<std::mutex> lock(api_);
    hwnd_ = hwnd;
    const auto* codec = &flutter::StandardMethodCodec::GetInstance();
    methods_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
        messenger, "riffster/guitar", codec);
    pcm_ = std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
        messenger, "riffster/guitar_pcm", codec);
    methods_->SetMethodCallHandler(
        [this](const flutter::MethodCall<flutter::EncodableValue>& call,
               std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
          Handle(call, std::move(result));
        });
    pcm_->SetStreamHandler(
        std::make_unique<flutter::StreamHandlerFunctions<flutter::EncodableValue>>(
            [this](const flutter::EncodableValue*,
                   std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&& events) {
              sink_ = std::move(events);
              return std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>>();
            },
            [this](const flutter::EncodableValue*) {
              sink_.reset();
              return std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>>();
            }));
  }

  void Detach() {
    Stop();
    std::lock_guard<std::mutex> lock(api_);
    hwnd_ = nullptr;
    sink_.reset();
    if (methods_) methods_->SetMethodCallHandler(nullptr);
    if (pcm_) pcm_->SetStreamHandler(nullptr);
    methods_.reset();
    pcm_.reset();
  }

  void Deliver() {
    std::vector<std::vector<uint8_t>> batch;
    {
      std::lock_guard<std::mutex> lock(pcm_lock_);
      batch.swap(pcm_queue_);
      pcm_posted_ = false;
    }
    if (!sink_) return;
    for (const auto& bytes : batch) {
      sink_->Success(flutter::EncodableValue(bytes));
    }
  }

 private:
  void Handle(const flutter::MethodCall<flutter::EncodableValue>& call,
              std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    const std::string& method = call.method_name();
    if (method == "start") {
      const bool ok = Start();
      flutter::EncodableMap map;
      map[flutter::EncodableValue("ok")] = flutter::EncodableValue(ok);
      map[flutter::EncodableValue("name")] = flutter::EncodableValue(name_);
      map[flutter::EncodableValue("sampleRate")] = flutter::EncodableValue(reported_rate_);
      map[flutter::EncodableValue("renderExclusive")] =
          flutter::EncodableValue(reported_render_exclusive_);
      result->Success(flutter::EncodableValue(map));
      return;
    }
    if (method == "stop") {
      Stop();
      result->Success();
      return;
    }
    if (method == "setSpeaker") {
      const auto* args = call.arguments();
      speaker_.store(args != nullptr && std::holds_alternative<bool>(*args) && std::get<bool>(*args));
      result->Success();
      return;
    }
    if (method == "setVolume") {
      gain_.store(MonitorGain(call.arguments()));
      result->Success();
      return;
    }
    if (method == "click") {
      // Only a request is left here. The audio thread picks it up when
      // it fills the next buffer, so the two threads never share the
      // click's own state.
      const auto* args = call.arguments();
      const bool accent =
          args != nullptr && std::holds_alternative<bool>(*args) && std::get<bool>(*args);
      click_request_.store(accent ? 2 : 1);
      result->Success();
      return;
    }
    result->NotImplemented();
  }

  bool Start() {
    std::lock_guard<std::mutex> lock(api_);
    StopUnlocked();
    ResetEvent(stop_event_);
    ResetEvent(ready_event_);
    ok_ = false;
    name_.clear();
    thread_ = std::thread([this] { Run(); });
    WaitForSingleObject(ready_event_, 3000);
    if (!ok_) {
      SetEvent(stop_event_);
      if (thread_.joinable()) thread_.join();
      return false;
    }
    return true;
  }

  void Stop() {
    std::lock_guard<std::mutex> lock(api_);
    StopUnlocked();
  }

  void StopUnlocked() {
    if (!thread_.joinable()) return;
    SetEvent(stop_event_);
    thread_.join();
    speaker_.store(true);
    ring_.Clear();
    resample_cursor_ = 0;
  }

  void Run() {
    CoInitializeEx(nullptr, COINIT_MULTITHREADED);
    DWORD task = 0;
    HANDLE mmcss = AvSetMmThreadCharacteristicsW(L"Pro Audio", &task);

    bool playing = OpenEndpoints();
    if (playing) playing = StartStreams();
    reported_rate_ = playing ? capture_.format.rate : 0;
    reported_render_exclusive_ = playing && render_.format.exclusive;
    // Release the cable before Dart is told, or the shared fallback cannot open it.
    if (!playing) ReleaseAudio();
    ok_ = playing;
    SetEvent(ready_event_);

    if (playing) {
      Loop();
      ReleaseAudio();
    }
    if (mmcss) AvRevertMmThreadCharacteristics(mmcss);
    CoUninitialize();
  }

  bool OpenEndpoints() {
    ComPtr<IMMDeviceEnumerator> enumerator;
    HRESULT hr = CoCreateInstance(__uuidof(MMDeviceEnumerator), nullptr, CLSCTX_ALL,
                                  IID_PPV_ARGS(&enumerator));
    if (FAILED(hr)) {
      LogHr("enumerator", hr);
      return false;
    }
    const PickedDevice input = PickCapture(enumerator.Get());
    if (!input.device) return false;
    name_ = input.name;
    if (!OpenCapture(input.device.Get())) return false;
    const ComPtr<IMMDevice> output = PickRender(enumerator.Get(), input.irig);
    if (!output || !OpenRender(output.Get())) return false;
    hr = capture_.client->GetService(IID_PPV_ARGS(&capture_client_));
    if (FAILED(hr)) return false;
    hr = render_.client->GetService(IID_PPV_ARGS(&render_client_));
    if (FAILED(hr)) return false;
    char buffer[180];
    sprintf_s(buffer, "Riffster exclusive %d Hz capture, render %s %d Hz\n", capture_.format.rate,
              render_.format.exclusive ? "exclusive" : "shared", render_.format.rate);
    OutputDebugStringA(buffer);
    return true;
  }

  bool OpenCapture(IMMDevice* device) {
    const int rates[] = {48000, 44100};
    const int channels[] = {1, 2};
    for (int rate : rates) {
      for (int channel : channels) {
        const WAVEFORMATEXTENSIBLE format = MakeFormat(rate, channel, 16, false);
        if (capture_.TryExclusive(device, format)) return true;
      }
    }
    LogHr("exclusive capture", E_FAIL);
    return false;
  }

  bool OpenRender(IMMDevice* device) {
    const int rate = capture_.format.rate > 0 ? capture_.format.rate : 48000;
    const WAVEFORMATEXTENSIBLE stereo = MakeFormat(rate, 2, 16, false);
    const WAVEFORMATEXTENSIBLE mono = MakeFormat(rate, 1, 16, false);
    const WAVEFORMATEXTENSIBLE stereo24 = MakeFormat(rate, 2, 24, false);
    const WAVEFORMATEXTENSIBLE stereo_float = MakeFormat(rate, 2, 32, true);
    if (render_.TryExclusive(device, stereo)) return true;
    if (render_.TryExclusive(device, mono)) return true;
    if (render_.TryExclusive(device, stereo24)) return true;
    if (render_.TryExclusive(device, stereo_float)) return true;
    // The speakers stay usable by other apps only when exclusive will not open.
    // The cable is still exclusive, so the long mixer queue is gone on the way in.
    return render_.TryShared(device);
  }

  // Capture starts first so the ring holds a real pluck. The speaker is
  // started only after that, with the guitar in the first buffer.
  bool StartStreams() {
    HRESULT hr = capture_.client->Start();
    if (FAILED(hr)) {
      LogHr("capture start", hr);
      return false;
    }
    const int need = static_cast<int>(std::max<UINT32>(1, render_.buffer_frames));
    const DWORD deadline = GetTickCount() + 250;
    while (ring_.count < need && GetTickCount() < deadline &&
           WaitForSingleObject(stop_event_, 0) != WAIT_OBJECT_0) {
      WaitForSingleObject(capture_.event, 15);
      DrainCapture();
    }
    FillRender();
    hr = render_.client->Start();
    if (FAILED(hr)) {
      LogHr("render start", hr);
      return false;
    }
    return true;
  }

  void ReleaseAudio() {
    if (capture_.client) capture_.client->Stop();
    if (render_.client) render_.client->Stop();
    capture_client_.Reset();
    render_client_.Reset();
    capture_.Close();
    render_.Close();
  }

  void Loop() {
    speaker_.store(true);
    // The render event has to come before the capture event. When both are
    // signaled, Windows reports the earlier handle and leaves the other one
    // waiting. Capture stays signaled the whole time a string is ringing, so
    // the speaker never got a turn and played silence.
    HANDLE waits[3] = {stop_event_, render_.event, capture_.event};
    while (WaitForSingleObject(stop_event_, 0) != WAIT_OBJECT_0) {
      const DWORD woke = WaitForMultipleObjects(3, waits, FALSE, 200);
      if (WaitForSingleObject(stop_event_, 0) == WAIT_OBJECT_0) break;
      DrainCapture();
      if (!render_.format.exclusive || woke == WAIT_OBJECT_0 + 1) FillRender();
    }
  }

  void DrainCapture() {
    UINT32 packet = 0;
    while (SUCCEEDED(capture_client_->GetNextPacketSize(&packet)) && packet > 0) {
      BYTE* data = nullptr;
      UINT32 frames = 0;
      DWORD flags = 0;
      if (FAILED(capture_client_->GetBuffer(&data, &frames, &flags, nullptr, nullptr))) return;
      const bool silent = (flags & AUDCLNT_BUFFERFLAGS_SILENT) != 0;
      for (UINT32 i = 0; i < frames; i++) {
        const float sample = silent ? 0.f : ReadSample(data + i * capture_.format.block, capture_.format);
        ring_.Push(sample);
        const float clamped = std::clamp(sample, -1.f, 1.f);
        pending_.push_back(static_cast<int16_t>(clamped * 32767.f));
      }
      capture_client_->ReleaseBuffer(frames);
      // About 5 ms a chunk. The detector reads the pitch as the sound
      // arrives, so a long chunk would hold every note's result back.
      const int hop = std::max(256, capture_.format.rate / 200);
      while (static_cast<int>(pending_.size()) >= hop) {
        QueuePcm(hop);
      }
      if (pending_.size() > static_cast<size_t>(std::max(capture_.format.rate, hop))) {
        pending_.erase(pending_.begin(), pending_.end() - hop);
      }
    }
  }

  void QueuePcm(int hop) {
    std::vector<uint8_t> bytes(static_cast<size_t>(hop) * 2);
    memcpy(bytes.data(), pending_.data(), bytes.size());
    pending_.erase(pending_.begin(), pending_.begin() + hop);
    bool post = false;
    {
      std::lock_guard<std::mutex> lock(pcm_lock_);
      // 32 chunks is about 170 ms. A screen that stalls longer than
      // that loses the oldest sound, not the newest.
      if (pcm_queue_.size() >= 32) pcm_queue_.erase(pcm_queue_.begin());
      pcm_queue_.push_back(std::move(bytes));
      if (!pcm_posted_) {
        pcm_posted_ = true;
        post = true;
      }
    }
    if (post && hwnd_) PostMessage(hwnd_, kPcmMessage, 0, 0);
  }

  void FillRender() {
    // Exclusive mode signals when the next whole buffer is due. Padding
    // stays non-zero while the previous buffer is still playing, so waiting
    // for it to hit zero never submits the guitar and the speakers stay quiet.
    StartRequestedClick();
    // The click is heard even with the speaker switch off. That switch
    // is for the guitar.
    const bool speaking = speaker_.load();
    const bool clicking = click_left_ > 0;
    if (!speaking) {
      ring_.Clear();
      resample_cursor_ = 0;
    }
    UINT32 frames = 0;
    UINT32 padding = 0;
    if (render_.format.exclusive) {
      frames = render_.buffer_frames;
    } else {
      if (FAILED(render_.client->GetCurrentPadding(&padding))) return;
      if (ring_.count == 0 && !clicking) return;
      const UINT32 target = static_cast<UINT32>(std::max(1, render_.format.rate * 6 / 1000));
      if (padding >= target || padding >= render_.buffer_frames) return;
      const UINT32 available = render_.buffer_frames - padding;
      frames = std::min(available, target - padding);
    }
    if (frames == 0) return;
    BYTE* dest = nullptr;
    if (FAILED(render_client_->GetBuffer(frames, &dest))) return;
    const int bytes = static_cast<int>(frames) * render_.format.block;
    memset(dest, 0, static_cast<size_t>(bytes));
    if (!speaking && !clicking) {
      render_client_->ReleaseBuffer(frames, AUDCLNT_BUFFERFLAGS_SILENT);
      return;
    }
    // Two render buffers is the whole delay we allow. Anything older is
    // dropped so a late chunk cannot turn into a slapback.
    ring_.DropDownTo(static_cast<int>(frames) * 2);
    const double step = render_.format.rate > 0
                            ? static_cast<double>(capture_.format.rate) / render_.format.rate
                            : 1.0;
    for (UINT32 i = 0; i < frames; i++) {
      float sample = NextClickSample();
      if (ring_.count > 0) {
        sample += ring_.Peek() * gain_.load();
        resample_cursor_ += step;
        while (resample_cursor_ >= 1.0 && ring_.count > 0) {
          float discarded = 0;
          ring_.Pop(&discarded);
          resample_cursor_ -= 1.0;
        }
      }
      WriteSample(dest + i * render_.format.block, sample, render_.format);
    }
    render_client_->ReleaseBuffer(frames, 0);
  }

  // Audio thread only.
  void StartRequestedClick() {
    const int request = click_request_.exchange(0);
    if (request == 0) return;
    click_total_ = std::max(1, static_cast<int>(render_.format.rate * kClickSeconds));
    click_left_ = click_total_;
    click_phase_ = 0.f;
    click_step_ = kTwoPi * (request == 2 ? kAccentClickHz : kClickHz) /
                  static_cast<float>(std::max(1, render_.format.rate));
  }

  // Audio thread only. Silence when no click is sounding.
  float NextClickSample() {
    if (click_left_ <= 0) return 0.f;
    // Squaring the fade makes it drop fast at first, like a struck
    // block of wood, and not like a tone being turned down.
    const float fade = static_cast<float>(click_left_) / static_cast<float>(click_total_);
    const float sample = kClickLevel * fade * fade * sinf(click_phase_);
    click_phase_ += click_step_;
    click_left_--;
    return sample;
  }

  std::mutex api_;
  std::mutex pcm_lock_;
  HWND hwnd_ = nullptr;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> methods_;
  std::unique_ptr<flutter::EventChannel<flutter::EncodableValue>> pcm_;
  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> sink_;
  std::vector<std::vector<uint8_t>> pcm_queue_;
  bool pcm_posted_ = false;

  HANDLE stop_event_ = nullptr;
  HANDLE ready_event_ = nullptr;
  std::thread thread_;
  bool ok_ = false;
  int reported_rate_ = 0;
  bool reported_render_exclusive_ = false;
  std::string name_;
  std::atomic<bool> speaker_{true};
  std::atomic<float> gain_{kMonitorGain};
  // 0 is no request, 1 is a click, 2 is the higher click on beat one.
  std::atomic<int> click_request_{0};
  int click_left_ = 0;
  int click_total_ = 1;
  float click_phase_ = 0.f;
  float click_step_ = 0.f;

  Endpoint capture_;
  Endpoint render_;
  ComPtr<IAudioCaptureClient> capture_client_;
  ComPtr<IAudioRenderClient> render_client_;
  Ring ring_;
  std::vector<int16_t> pending_;
  double resample_cursor_ = 0;
};

Monitor& Instance() {
  static Monitor monitor;
  return monitor;
}

}  // namespace

void GuitarMonitorAttach(HWND hwnd, flutter::BinaryMessenger* messenger) {
  Instance().Attach(hwnd, messenger);
}

void GuitarMonitorDetach() { Instance().Detach(); }

bool GuitarMonitorHandleMessage(UINT message) {
  if (message != kPcmMessage) return false;
  Instance().Deliver();
  return true;
}
