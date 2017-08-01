defmodule Http2.Frame.PriorityTest do
  use ExUnit.Case
  doctest Http2

  describe ".decode" do
    test "decode weight from payload" do
      frame = %Http2.Frame{ payload: <<0::1, 0::31, 30::8>> }

      assert Http2.Frame.Priority.decode(frame).weight == 30
    end

    test "decode exclusive flag from payload" do
      frame1 = %Http2.Frame{ payload: <<1::1, 90::31, 30::8>> }
      frame2 = %Http2.Frame{ payload: <<0::1, 90::31, 30::8>> }

      assert Http2.Frame.Priority.decode(frame1).exclusive?
      refute Http2.Frame.Priority.decode(frame2).exclusive?
    end

    test "decode dependency_stream_id from payload" do
      frame = %Http2.Frame{ payload: <<1::1, 90::31, 30::8>> }

      assert Http2.Frame.Priority.decode(frame).dependency_stream_id == 90
    end
  end

end
