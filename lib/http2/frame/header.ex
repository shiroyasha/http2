defmodule Http2.Frame.Header do
  require Logger

  # Payload format
  #
  # +---------------+
  # |Pad Length? (8)|
  # +-+-------------+-----------------------------------------------+
  # |E|                 Stream Dependency? (31)                     |
  # +-+-------------+-----------------------------------------------+
  # |  Weight? (8)  |
  # +-+-------------+-----------------------------------------------+
  # |                   Header Block Fragment (*)                 ...
  # +---------------------------------------------------------------+
  # |                           Padding (*)                       ...
  # +---------------------------------------------------------------+
  #
  # The HEADERS frame payload has the following fields:
  #
  # Pad Length:
  # An 8-bit field containing the length of the frame padding in units
  # of octets. This field is only present if the PADDED flag is set.
  #
  # E:
  # A single-bit flag indicating that the stream dependency is exclusive
  # (see Section 5.3). This field is only present if the PRIORITY flag is set.
  #
  # Stream Dependency:
  # A 31-bit stream identifier for the stream that this stream depends
  # on (see Section 5.3). This field is only present if the PRIORITY flag is set.
  #
  # Weight:
  # An unsigned 8-bit integer representing a priority weight for the
  # stream (see Section 5.3). Add one to the value to obtain a weight between 1
  #  and 256. This field is only present if the PRIORITY flag is set.
  #
  # Header Block Fragment:
  # A header block fragment (Section 4.3).
  #
  # Padding:
  # Padding octets.
  #
  #
  # The HEADERS frame defines the following flags:
  #
  # END_STREAM (0x1):
  # When set, bit 0 indicates that the header block (Section 4.3) is the
  # last that the endpoint will send for the identified stream.
  #
  # A HEADERS frame carries the END_STREAM flag that signals the end of a stream.
  # However, a HEADERS frame with the END_STREAM flag set can be followed by
  # CONTINUATION frames on the same stream. Logically, the CONTINUATION frames
  # are part of the HEADERS frame.
  #
  # END_HEADERS (0x4):
  # When set, bit 2 indicates that this frame contains an entire header
  # block (Section 4.3) and is not followed by any CONTINUATION frames.
  #
  # A HEADERS frame without the END_HEADERS flag set MUST be followed by a
  # CONTINUATION frame for the same stream. A receiver MUST treat the receipt
  # of any other type of frame or a frame on a different stream as a connection
  # error (Section 5.4.1) of type PROTOCOL_ERROR.
  #
  # PADDED (0x8):
  # When set, bit 3 indicates that the Pad Length field and any padding that it
  # describes are present.
  #
  # PRIORITY (0x20):
  # When set, bit 5 indicates that the Exclusive Flag (E), Stream Dependency, and
  # Weight fields are present; see Section 5.3.

  def decode(frame, hpack_table) do
    <<_::1, _::1, priority::1, _::1, padded::1, end_headers::1, _::1, end_stream::1>> = frame.flags

    header_block_fragment = if padded == 1 do
      remove_payload_padding(frame.payload)
    else
      frame.payload
    end

    %{
      end_headers: (end_headers == 1),
      end_stream: (end_stream == 1),
      priority: (priority == 1),
      padded: (padded == 1),
      header_block_fragment: HPack.decode(header_block_fragment, hpack_table)
    }
  end

  defp remove_payload_padding(frame_payload) do
    <<pad_length::8>> <> padded_payload = frame_payload

    length_without_padding = byte_size(padded_payload) - pad_length

    <<payload::bytes-size(length_without_padding)>> <> _padding = padded_payload

    payload
  end

end
