defmodule Http2.Frame.SettingsTest do
  use ExUnit.Case
  doctest Http2

  describe "Flags" do
    test "decodes ack flag" do
      assert Http2.Frame.Settings.Flags.decode(<<0::7, 1::1>>).ack?
      refute Http2.Frame.Settings.Flags.decode(<<0::7, 0::1>>).ack?
    end
  end

  describe ".decode" do
    test "decoding the settings frame" do
      flags   = <<0::7, 1::1>> # acked
      payload = <<3::16, 666::32>>

      frame = %Http2.Frame{
        type: :settings,
        flags: flags,
        len: byte_size(payload),
        payload: payload
      }

      settings = Http2.Frame.Settings.decode(frame)

      assert settings.flags.ack?
      assert settings.id == :settings_max_concurrent_streams
      assert settings.value == 666
    end
  end
end
