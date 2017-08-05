defmodule Http2.Frame.GoAwayTest do
  use ExUnit.Case
  doctest Http2

  describe ".decode" do
    test "decode go away frame" do
      last_stream_id = 45
      error_code = 13
      additional_debug_data = "lolz"

      payload = <<0::1, last_stream_id::31, error_code::32>> <> additional_debug_data

      frame = %Http2.Frame{
        flags: <<0::8>>,
        payload: payload,
        type: :go_away,
        len: byte_size(payload)
      }

      go_away = Http2.Frame.GoAway.decode(frame)

      assert go_away.last_stream_id == last_stream_id
      assert go_away.error_code == error_code
      assert go_away.additional_debug_data == additional_debug_data
    end
  end
end
