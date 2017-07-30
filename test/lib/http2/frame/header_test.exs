defmodule Http2.Frame.HeaderTest do
  use ExUnit.Case
  doctest Http2

  describe "Priority" do
    test "decode weight from payload" do
      assert Http2.Frame.Header.Priority.decode(<<0::1, 0::31, 30::8>>).weight == 30
    end

    test "decode exclusive flag from payload" do
      assert Http2.Frame.Header.Priority.decode(<<1::1, 0::31, 30::8>>).exclusive?
      refute Http2.Frame.Header.Priority.decode(<<0::1, 0::31, 30::8>>).exclusive?
    end

    test "decode dependency_stream_id from payload" do
      assert Http2.Frame.Header.Priority.decode(<<1::1, 90::31, 30::8>>).dependency_stream_id == 90
    end
  end

  describe "Flags" do
    test "decodes end_headers flag" do
      assert Http2.Frame.Header.Flags.decode(<< 0::1, 0::1, 0::1, 0::1, 0::1, 1::1, 0::1, 0::1>>).end_headers?
      refute Http2.Frame.Header.Flags.decode(<< 0::1, 0::1, 0::1, 0::1, 0::1, 0::1, 0::1, 0::1>>).end_headers?
    end

    test "decodes end_stream flag" do
      assert Http2.Frame.Header.Flags.decode(<< 0::1, 0::1, 0::1, 0::1, 0::1, 0::1, 0::1, 1::1>>).end_stream?
      refute Http2.Frame.Header.Flags.decode(<< 0::1, 0::1, 0::1, 0::1, 0::1, 0::1, 0::1, 0::1>>).end_stream?
    end

    test "decodes padded flag" do
      assert Http2.Frame.Header.Flags.decode(<< 0::1, 0::1, 0::1, 0::1, 1::1, 0::1, 0::1, 0::1>>).padded?
      refute Http2.Frame.Header.Flags.decode(<< 0::1, 0::1, 0::1, 0::1, 0::1, 0::1, 0::1, 0::1>>).padded?
    end

    test "decodes priority flag" do
      assert Http2.Frame.Header.Flags.decode(<< 0::1, 0::1, 1::1, 0::1, 0::1, 0::1, 0::1, 0::1>>).priority?
      refute Http2.Frame.Header.Flags.decode(<< 0::1, 0::1, 0::1, 0::1, 0::1, 0::1, 0::1, 0::1>>).priority?
    end
  end

  describe ".decode" do

    setup do
      {:ok, hpack_table} = HPack.Table.start_link(1000)

      {:ok, hpack_table: hpack_table}
    end

    test "decoding the flags", %{ hpack_table: hpack_table } do
      paylaod = <<130, 134, 132, 65, 138, 8, 157, 92, 11, 129, 112, 220, 121, 166, 153>>
      flags   = encode_flags(0, 0, 0, 1)
      frame   = %Http2.Frame{ type: :header, flags: flags, len: 16, payload: paylaod }
      header  = Http2.Frame.Header.decode(frame, hpack_table)

      assert header.flags.end_stream?
      refute header.flags.end_headers?
      refute header.flags.padded?
      refute header.flags.priority?
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

    test "decoding a payload with priority", %{ hpack_table: hpack_table } do
      # payload with priority info
      paylaod = <<0, 0, 0, 0, 255, 130, 134, 132, 65, 138, 8, 157, 92, 11, 129, 112, 220, 121, 166, 153>>
      flags   = encode_flags(1, 0, 1, 0) # priority
      frame   = %Http2.Frame{ type: :header, flags: flags, len: 16, payload: paylaod }
      header  = Http2.Frame.Header.decode(frame, hpack_table)

      assert header.header_block_fragment == [
        {":method", "GET"},
        {":scheme", "http"},
        {":path", "/"},
        {":authority", "127.0.0.1:8443"}
      ]

      assert header.priority.weight == 255
      assert header.priority.dependency_stream_id == 0
      refute header.priority.exclusive?
    end

  end

  test ".remove_padding" do
    payload = <<8, 130, 134, 132, 65, 138, 8, 157, 92,
                11, 129, 112, 220, 121, 166, 153,
                0, 0, 0, 0, 0, 0, 0, 0>>

    payload_without_padding = Http2.Frame.Header.remove_padding(payload)

    assert payload_without_padding == <<130, 134, 132, 65, 138, 8,
                                        157, 92, 11, 129, 112, 220,
                                        121, 166, 153>>
  end

  def encode_flags(priority, padded, end_headers, end_stream) do
    << 0::1, 0::1, priority::1, 0::1, padded::1, end_headers::1, 0::1, end_stream::1>>
  end
end
