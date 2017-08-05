defmodule Http2.Frame.PushPromise do
  require Logger

  #
  # The PUSH_PROMISE frame (type=0x5) is used to notify the peer endpoint
  # in advance of streams the sender intends to initiate.  The
  # PUSH_PROMISE frame includes the unsigned 31-bit identifier of the
  # stream the endpoint plans to create along with a set of headers that
  # provide additional context for the stream.  Section 8.2 contains a
  # thorough description of the use of PUSH_PROMISE frames.
  #
  #  +---------------+
  #  |Pad Length? (8)|
  #  +-+-------------+-----------------------------------------------+
  #  |R|                  Promised Stream ID (31)                    |
  #  +-+-----------------------------+-------------------------------+
  #  |                   Header Block Fragment (*)                 ...
  #  +---------------------------------------------------------------+
  #  |                           Padding (*)                       ...
  #  +---------------------------------------------------------------+
  #
  #                Figure 11: PUSH_PROMISE Payload Format
  #
  # The PUSH_PROMISE frame payload has the following fields:
  #
  # Pad Length:  An 8-bit field containing the length of the frame
  #    padding in units of octets.  This field is only present if the
  #    PADDED flag is set.
  #
  # R: A single reserved bit.
  #
  # Promised Stream ID:  An unsigned 31-bit integer that identifies the
  #    stream that is reserved by the PUSH_PROMISE.  The promised stream
  #    identifier MUST be a valid choice for the next stream sent by the
  #    sender (see "new stream identifier" in Section 5.1.1).
  #
  # Header Block Fragment:  A header block fragment (Section 4.3)
  #    containing request header fields.
  #
  # Padding:  Padding octets.
  #
  # The PUSH_PROMISE frame defines the following flags:
  #
  # END_HEADERS (0x4):  When set, bit 2 indicates that this frame
  #    contains an entire header block (Section 4.3) and is not followed
  #    by any CONTINUATION frames.
  #
  #    A PUSH_PROMISE frame without the END_HEADERS flag set MUST be
  #    followed by a CONTINUATION frame for the same stream.  A receiver
  #    MUST treat the receipt of any other type of frame or a frame on a
  #    different stream as a connection error (Section 5.4.1) of type
  #    PROTOCOL_ERROR.
  #
  # PADDED (0x8):  When set, bit 3 indicates that the Pad Length field
  #    and any padding that it describes are present.
  #

  defmodule Flags do
    defstruct end_headers?: false, padded?: false

    def decode(raw_flags) do
      <<padded::1, _::3, end_headers::1, _::3>> = raw_flags

      %__MODULE__{
        padded?: (padded == 1),
        end_headers?: (end_headers == 1)
      }
    end
  end

  defstruct flags: nil
  #  +---------------+
  #  |Pad Length? (8)|
  #  +-+-------------+-----------------------------------------------+
  #  |R|                  Promised Stream ID (31)                    |
  #  +-+-----------------------------+-------------------------------+
  #  |                   Header Block Fragment (*)                 ...
  #  +---------------------------------------------------------------+
  #  |                           Padding (*)                       ...
  #  +---------------------------------------------------------------+

  def decode(frame) do
    flags = Flags.decode(frame.flags)

    %__MODULE__{
      flags: flags
    }
  end
end
