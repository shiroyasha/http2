defmodule Http2.Frame.HeaderTest do
  use ExUnit.Case
  doctest Http2

  describe ".decode" do

    setup do
      {:ok, hpack_table} = HPack.Table.start_link(1000)

      {:ok, hpack_table: hpack_table}
    end

    test "decoding the flags", %{ hpack_table: hpack_table } do
      paylaod = <<130, 134, 132, 65, 138, 8, 157, 92, 11, 129, 112, 220, 121, 166, 153>>
      flags   = encode_flags(1, 0, 0, 1)
      frame   = %Http2.Frame{ type: :header, flags: flags, len: 16, payload: paylaod }
      header  = Http2.Frame.Header.decode(frame, hpack_table)

      assert header.end_stream == true
      assert header.end_headers == false
      assert header.padded == false
      assert header.priority == true
    end

    test "decoding the payload", %{ hpack_table: hpack_table } do
      paylaod = <<130, 134, 132, 65, 138, 8, 157, 92, 11, 129, 112, 220, 121, 166, 153>>
      flags   = encode_flags(0, 0, 1, 0)
      frame   = %Http2.Frame{ type: :header, flags: flags, len: 16, payload: paylaod }
      header  = Http2.Frame.Header.decode(frame, hpack_table)

      assert header.header_block_fragment == [
        {":method", "GET"},
        {":scheme", "http"},
        {":path", "/"},
        {":authority", "127.0.0.1:8443"}
      ]
    end

    test "decoding a payload with padding", %{ hpack_table: hpack_table } do
      # 8 octets of padding
      paylaod = <<8, 130, 134, 132, 65, 138, 8, 157, 92, 11, 129, 112, 220, 121, 166, 153, 0, 0, 0, 0, 0, 0, 0, 0>>
      flags   = encode_flags(0, 1, 1, 0) # padded
      frame   = %Http2.Frame{ type: :header, flags: flags, len: 16, payload: paylaod }
      header  = Http2.Frame.Header.decode(frame, hpack_table)

      assert header.header_block_fragment == [
        {":method", "GET"},
        {":scheme", "http"},
        {":path", "/"},
        {":authority", "127.0.0.1:8443"}
      ]
    end

  end

  def encode_flags(priority, padded, end_headers, end_stream) do
    << 0::1, 0::1, priority::1, 0::1, padded::1, end_headers::1, 0::1, end_stream::1>>
  end
end
