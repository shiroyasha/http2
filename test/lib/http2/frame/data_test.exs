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
    # test "decode ping frame" do
    #   flags = <<0::7, 1::1>>
    #   payload = <<1::64>>
    #   len = 8

    #   frame = %Http2.Frame{
    #     flags: flags,
    #     payload: payload,
    #     type: :ping,
    #     len: 8
    #   }

    #   ping = Http2.Frame.Ping.decode(frame)

    #   assert ping.flags.ack?
    #   assert ping.data == payload
    # end
  end
end
