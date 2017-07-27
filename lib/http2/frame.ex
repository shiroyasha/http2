defmodule Http2.Frame do
  #
  # RFC 7540: 4.1.  Frame Format
  #
  # All frames begin with a fixed 9-octet header followed by a variable-
  # length payload.
  #
  #  +-----------------------------------------------+
  #  |                 Length (24)                   |
  #  +---------------+---------------+---------------+
  #  |   Type (8)    |   Flags (8)   |
  #  +-+-------------+---------------+-------------------------------+
  #  |R|                 Stream Identifier (31)                      |
  #  +=+=============================================================+
  #  |                   Frame Payload (0...)                      ...
  #  +---------------------------------------------------------------+
  #
  # The fields of the frame header are defined as:
  #
  # Length:  The length of the frame payload expressed as an unsigned
  #    24-bit integer.  Values greater than 2^14 (16,384) MUST NOT be
  #    sent unless the receiver has set a larger value for
  #    SETTINGS_MAX_FRAME_SIZE.
  #    The 9 octets of the frame header are not included in this value.
  #
  # Type:  The 8-bit type of the frame.  The frame type determines the
  #    format and semantics of the frame.  Implementations MUST ignore
  #    and discard any frame that has a type that is unknown.
  #
  # Flags:  An 8-bit field reserved for boolean flags specific to the
  #    frame type.
  #
  #    Flags are assigned semantics specific to the indicated frame type.
  #    Flags that have no defined semantics for a particular frame type
  #    MUST be ignored and MUST be left unset (0x0) when sending.
  #
  # R: A reserved 1-bit field.  The semantics of this bit are undefined,
  #    and the bit MUST remain unset (0x0) when sending and MUST be
  #    ignored when receiving.
  #
  # Stream Identifier:  A stream identifier (see Section 5.1.1) expressed
  #    as an unsigned 31-bit integer.  The value 0x0 is reserved for
  #    frames that are associated with the connection as a whole as
  #    opposed to an individual stream.
  #

  require Logger

  defstruct len: nil,
            type: nil,
            flags: nil,
            stream_id: nil,
            payload: nil

  # returns a parsed frame with payload, and the unprocessed data
  def parse(header = << len::24, type::8, flags::8, _r::1, stream_id::31>> <> rest) do
    <<payload :: binary-size(len)>> <> unprocessed = rest

    frame = %Http2.Frame{
      len: len, # in bytes
      type: type,
      flags: flags,
      stream_id: stream_id,
      payload: payload
    }

    {frame, unprocessed}
  end

  #
  # +---------------+------+--------------+
  # | Frame Type    | Code | Section      |
  # +---------------+------+--------------+
  # | DATA          | 0x0  | Section 6.1  |
  # | HEADERS       | 0x1  | Section 6.2  |
  # | PRIORITY      | 0x2  | Section 6.3  |
  # | RST_STREAM    | 0x3  | Section 6.4  |
  # | SETTINGS      | 0x4  | Section 6.5  |
  # | PUSH_PROMISE  | 0x5  | Section 6.6  |
  # | PING          | 0x6  | Section 6.7  |
  # | GOAWAY        | 0x7  | Section 6.8  |
  # | WINDOW_UPDATE | 0x8  | Section 6.9  |
  # | CONTINUATION  | 0x9  | Section 6.10 |
  # +---------------+------+--------------+
  #
  def frame_type(frame) do
    case frame.type do
      0 -> :data
      1 -> :header
      2 -> :priority
      3 -> :rst_stream
      4 -> :settings
      5 -> :push_promise
      6 -> :ping
      7 -> :go_away
      8 -> :window_update
      9 -> :continuation
    end
  end

end
