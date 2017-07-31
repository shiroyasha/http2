defmodule Http2.Frame.Continuation do
  require Logger

  #
  # Continuation payload:
  #
  # +---------------------------------------------------------------+
  # |                   Header Block Fragment (*)                 ...
  # +---------------------------------------------------------------+
  #
  # The CONTINUATION frame defines the following flag:
  #
  # END_HEADERS (0x4):
  # When set, bit 2 indicates that this frame ends a header
  # block (Section 4.3).
  #
  # If the END_HEADERS bit is not set, this frame MUST be
  # followed by another CONTINUATION frame. A receiver MUST
  # treat the receipt of any other type of frame or a frame
  # on a different stream as a connection error
  # (Section 5.4.1) of type PROTOCOL_ERROR.
  #

  require Logger

  defmodule Flags do
    defstruct end_headers?: false

    def decode(raw_flags) do
      <<_::5, end_headers::1, _::2>> = raw_flags

      %__MODULE__{ end_headers?: (end_headers == 1) }
    end
  end

  defstruct flags: nil, header_block_fragment: nil

  def decode(frame, hpack_table) do
    %__MODULE__{
      flags: Flags.decode(frame.flags),
      header_block_fragment: HPack.decode(frame.payload, hpack_table)
    }
  end

end
