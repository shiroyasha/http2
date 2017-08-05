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
      promised_stream_id = 43
      payload = <<0::1, promised_stream_id::31>>

      frame = %Http2.Frame{
        type: :push_promise,
        flags: flags,
        payload: <<3::8>> <> payload <> <<1, 2, 3>>, # 3-octet padding
        len: byte_size(payload) + 4
      }

      push_promise = Http2.Frame.PushPromise.decode(frame)

      assert push_promise.flags.padded?
      refute push_promise.flags.end_headers?
      assert push_promise.promised_stream_id == promised_stream_id
    end

    test "non-padded payload" do
      flags = <<0::4, 1::1, 0::3>> # end_headers
      promised_stream_id = 43
      payload = <<0::1, promised_stream_id::31>>

      frame = %Http2.Frame{
        type: :push_promise,
        flags: flags,
        payload: payload,
        len: byte_size(payload)
      }

      push_promise = Http2.Frame.PushPromise.decode(frame)

      refute push_promise.flags.padded?
      assert push_promise.flags.end_headers?
      assert push_promise.promised_stream_id == promised_stream_id
    end
  end
end
