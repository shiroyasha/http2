defmodule Http2.Frame.ContinuationTest do
  use ExUnit.Case
  doctest Http2

  describe "Flags" do
    test "decodes end_headers flag" do
      assert Http2.Frame.Continuation.Flags.decode(<<0::5, 1::1, 0::2>>).end_headers?
      refute Http2.Frame.Continuation.Flags.decode(<<0::5, 0::1, 0::2>>).end_headers?
    end
  end

  describe ".decode" do

    setup do
      {:ok, hpack_table} = HPack.Table.start_link(1000)

      {:ok, hpack_table: hpack_table}
    end

    test "decoding the flags", %{ hpack_table: hpack_table } do
      paylaod = <<130, 134, 132, 65, 138, 8, 157, 92, 11, 129, 112, 220, 121, 166, 153>>
      flags   = <<0::5, 1::1, 0::2>>

      frame = %Http2.Frame{type: :continuation, flags: flags, len: 16, payload: paylaod }
      continuation = Http2.Frame.Header.decode(frame, hpack_table)

      assert continuation.flags.end_headers?
    end

    test "decoding the payload", %{ hpack_table: hpack_table } do
      paylaod = <<130, 134, 132, 65, 138, 8, 157, 92, 11, 129, 112, 220, 121, 166, 153>>
      flags   = <<0::5, 1::1, 0::2>>

      frame = %Http2.Frame{type: :continuation, flags: flags, len: 16, payload: paylaod }
      continuation = Http2.Frame.Header.decode(frame, hpack_table)

      assert continuation.header_block_fragment == [
        {":method", "GET"},
        {":scheme", "http"},
        {":path", "/"},
        {":authority", "127.0.0.1:8443"}
      ]
    end

  end
end
