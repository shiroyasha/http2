defmodule Http2.Frame.DataTest do
  use ExUnit.Case
  doctest Http2

  describe "Flags" do
    test "decodes padded flag" do
      assert Http2.Frame.Data.Flags.decode(<< 1::1, 0::6, 0::1 >>).padded?
      refute Http2.Frame.Data.Flags.decode(<< 0::1, 0::6, 0::1 >>).padded?
    end

    test "decodes end_stream flag" do
      assert Http2.Frame.Data.Flags.decode(<< 0::1, 0::6, 1::1 >>).end_stream?
      refute Http2.Frame.Data.Flags.decode(<< 0::1, 0::6, 0::1 >>).end_stream?
    end
  end

  describe ".decode" do
    test "decoding the payload" do
      flags   = << 0::1, 0::6, 1::1 >> # not padded
      payload = "test"
      frame   = %Http2.Frame{ type: :data, flags: flags, len: 4, payload: payload }
      header  = Http2.Frame.Data.decode(frame)

      assert header.data == "test"
    end

    test "decoding the payload with payload" do
      flags   = << 1::1, 0::6, 1::1 >> # padded
      payload = <<4::8>> <> "test" <> <<1, 1, 1, 1>> # for octet padding
      frame   = %Http2.Frame{ type: :data, flags: flags, len: 9, payload: payload }
      header  = Http2.Frame.Data.decode(frame)

      assert header.data == "test"
    end
  end
end
