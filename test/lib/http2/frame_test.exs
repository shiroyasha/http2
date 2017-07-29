defmodule Http2.FrameTest do
  use ExUnit.Case
  doctest Http2

  describe ".parse" do
    test "when the data is shorted then 9 octets it returns {nil, data}" do
      data = << 0, 1, 2, 3, 4, 5, 6, 7>>

      assert byte_size(data) == 8
      assert Http2.Frame.parse(data) == {nil, data}
    end

    test "unrecognized header" do
      frame_type = 11 # incorrect frame type
      data = << 0::24, frame_type::8, 0::8, 0::1, 0::31 >>

      assert Http2.Frame.parse(data) == {:error, data}
    end

    test "data frame" do
      payload = <<1, 2, 3>>

      data = << byte_size(payload)::24, 0::8, 0::8, 0::1, 0::31, payload::binary >>

      assert Http2.Frame.parse(data) == {%Http2.Frame{len: 3, flags: <<0::8>>, type: :data, payload: payload, stream_id: 0}, ""}
    end

    test "header frame" do
      payload = <<1, 2, 3>>

      data = << byte_size(payload)::24, 1::8, 0::8, 0::1, 0::31, payload::binary >>

      assert Http2.Frame.parse(data) == {%Http2.Frame{len: 3, flags: <<0::8>>, type: :header, payload: payload, stream_id: 0}, ""}
    end

    test "priority frame" do
      payload = <<1, 2, 3>>

      data = << byte_size(payload)::24, 2::8, 0::8, 0::1, 0::31, payload::binary >>

      assert Http2.Frame.parse(data) == {%Http2.Frame{len: 3, flags: <<0::8>>, type: :priority, payload: payload, stream_id: 0}, ""}
    end

    test "rst_stream frame" do
      payload = <<1, 2, 3>>

      data = << byte_size(payload)::24, 3::8, 0::8, 0::1, 0::31, payload::binary >>

      assert Http2.Frame.parse(data) == {%Http2.Frame{len: 3, flags: <<0::8>>, type: :rst_stream, payload: payload, stream_id: 0}, ""}
    end

    test "settings frame" do
      payload = <<1, 2, 3>>

      data = << byte_size(payload)::24, 4::8, 0::8, 0::1, 0::31, payload::binary >>

      assert Http2.Frame.parse(data) == {%Http2.Frame{len: 3, flags: <<0::8>>, type: :settings, payload: payload, stream_id: 0}, ""}
    end

    test "push promise frame" do
      payload = <<1, 2, 3>>

      data = << byte_size(payload)::24, 5::8, 0::8, 0::1, 0::31, payload::binary >>

      assert Http2.Frame.parse(data) == {%Http2.Frame{len: 3, flags: <<0::8>>, type: :push_promise, payload: payload, stream_id: 0}, ""}
    end

    test "ping frame" do
      payload = <<1, 2, 3>>

      data = << byte_size(payload)::24, 6::8, 0::8, 0::1, 0::31, payload::binary >>

      assert Http2.Frame.parse(data) == {%Http2.Frame{len: 3, flags: <<0::8>>, type: :ping, payload: payload, stream_id: 0}, ""}
    end

    test "go away frame" do
      payload = <<1, 2, 3>>

      data = << byte_size(payload)::24, 7::8, 0::8, 0::1, 0::31, payload::binary >>

      assert Http2.Frame.parse(data) == {%Http2.Frame{len: 3, flags: <<0::8>>, type: :go_away, payload: payload, stream_id: 0}, ""}
    end

    test "window update frame" do
      payload = <<1, 2, 3>>

      data = << byte_size(payload)::24, 8::8, 0::8, 0::1, 0::31, payload::binary >>

      assert Http2.Frame.parse(data) == {%Http2.Frame{len: 3, flags: <<0::8>>, type: :window_update, payload: payload, stream_id: 0}, ""}
    end

    test "continuation frame" do
      payload = <<1, 2, 3>>

      data = << byte_size(payload)::24, 9::8, 0::8, 0::1, 0::31, payload::binary >>

      assert Http2.Frame.parse(data) == {%Http2.Frame{len: 3, flags: <<0::8>>, type: :continuation, payload: payload, stream_id: 0}, ""}
    end

    test "extra peyload is returned to the called" do
      payload = <<1, 2, 3, 5, 6, 7, 8, 9, 10>>
      len = 3

      data = << len::24, 0::8, 0::8, 0::1, 0::31, payload::binary >>

      assert Http2.Frame.parse(data) == {%Http2.Frame{len: 3, flags: <<0::8>>, type: :data, payload: <<1, 2, 3>>, stream_id: 0}, <<5, 6, 7, 8, 9, 10>>}
    end

    test "flags are storred as bits" do
      # random flags
      flags = <<1::1, 0::1, 1::1, 1::1, 0::1, 1::1, 1::1, 0::1>>
      data = << 0::24, 0::8, flags::binary, 0::1, 0::31 >>

      {frame, _} = Http2.Frame.parse(data)

      assert frame.flags == flags
    end
  end
end
