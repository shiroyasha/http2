defmodule Http2.Frame.WindowUpdate do
  require Logger

  #
  #  +-+-------------------------------------------------------------+
  #  |R|              Window Size Increment (31)                     |
  #  +-+-------------------------------------------------------------+
  #
  #                Figure 14: WINDOW_UPDATE Payload Format
  #
  # The payload of a WINDOW_UPDATE frame is one reserved bit plus an
  # unsigned 31-bit integer indicating the number of octets that the
  # sender can transmit in addition to the existing flow-control window.
  # The legal range for the increment to the flow-control window is 1 to
  # 2^31-1 (2,147,483,647) octets.
  #
  # The WINDOW_UPDATE frame does not define any flags.
  #

  defstruct window_size_increment: nil

  def decode(frame) do
    <<_::1, window_size_increment::31>> = frame.payload

    %__MODULE__{
      window_size_increment: window_size_increment
    }
  end
end
