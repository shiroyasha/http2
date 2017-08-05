defmodule Http2.Frame.WindowUpdateTest do
  use ExUnit.Case
  doctest Http2

  describe ".decode" do
    test "decoding the window update frame" do
      flags = <<0::8>>
      window_size_increment = 45
      payload = <<0::1, window_size_increment::31>>

      frame = %Http2.Frame{
        type: :window_update,
        flags: flags,
        len: byte_size(payload),
        payload: payload
      }

      settings = Http2.Frame.WindowUpdate.decode(frame)

      assert settings.window_size_increment == 45
    end
  end
end
