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
end
