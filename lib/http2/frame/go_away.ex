defmodule Http2.Frame.GoAway do
  require Logger

  #
  # GOAWAY Payload Format
  #
  # +-+-------------------------------------------------------------+
  # |R|                  Last-Stream-ID (31)                        |
  # +-+-------------------------------------------------------------+
  # |                      Error Code (32)                          |
  # +---------------------------------------------------------------+
  # |                  Additional Debug Data (*)                    |
  # +---------------------------------------------------------------+
  #
  # The GOAWAY frame does not define any flags.
  #

  defstruct last_stream_id: nil,
            error_code: nil,
            additional_debug_data: nil

  def decode(frame) do
    <<_::1, last_stream_id::31, error_code::32>> <> additional_debug_data = frame.payload

    %__MODULE__{
      last_stream_id: last_stream_id,
      error_code: error_code,
      additional_debug_data: additional_debug_data
    }
  end

end
