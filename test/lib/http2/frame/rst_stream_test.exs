defmodule Http2.Frame.RstStreamTest do
  use ExUnit.Case
  doctest Http2

  describe ".decode" do
    test "decode ping frame" do
      payload = <<4::32>>
      frame = %Http2.Frame{ payload: payload }

      rst_stream = Http2.Frame.RstStream.decode(frame)

      assert rst_stream.error_code == 4
    end
  end
end
