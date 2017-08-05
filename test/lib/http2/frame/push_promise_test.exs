defmodule Http2.Frame.PushPromiseTest do
  use ExUnit.Case
  doctest Http2

  describe "Flags" do
    test "decodes padded flag" do
      assert Http2.Frame.PushPromise.Flags.decode(<< 1::1, 0::7>>).padded?
      refute Http2.Frame.PushPromise.Flags.decode(<< 0::1, 0::7>>).padded?
    end

    test "decodes end_stream flag" do
      assert Http2.Frame.PushPromise.Flags.decode(<<0::4, 1::1, 0::3>>).end_headers?
      refute Http2.Frame.PushPromise.Flags.decode(<<0::4, 0::1, 0::3>>).end_headers?
    end
  end

  describe ".decode" do
    test "padded payload" do
      flags = <<1::1, 0::7>> # padded
      payload = ""

      frame = %Http2.Frame{
        type: :push_promise,
        flags: flags,
        payload: payload,
        len: byte_size(payload)
      }

      push_promise = Http2.Frame.PushPromise.decode(frame)

      assert push_promise.flags.padded?
      refute push_promise.flags.end_headers?
    end

    test "non-padded payload" do
      flags = <<0::4, 1::1, 0::3>> # end_headers
      payload = ""

      frame = %Http2.Frame{
        type: :push_promise,
        flags: flags,
        payload: payload,
        len: byte_size(payload)
      }

      push_promise = Http2.Frame.PushPromise.decode(frame)

      refute push_promise.flags.padded?
      assert push_promise.flags.end_headers?
    end
  end
end
