defmodule Http2.Frame.PingTest do
  use ExUnit.Case
  doctest Http2

  describe "Flags" do
    test "decodes ack flag" do
      assert Http2.Frame.Ping.Flags.decode(<< 0::7, 1::1 >>).ack?
      refute Http2.Frame.Ping.Flags.decode(<< 0::7, 0::1 >>).ack?
    end
  end

  describe ".decode" do
    test "decode ping frame" do
      flags = <<0::7, 1::1>>
      payload = <<1::64>>
      len = 8

      frame = %Http2.Frame{
        flags: flags,
        payload: payload,
        type: :ping,
        len: 8
      }

      ping = Http2.Frame.Ping.decode(frame)

      assert ping.flags.ack?
      assert ping.data == payload
    end
  end
end
