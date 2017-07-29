defmodule Http2.Frame.Settings do
  require Logger

  # length    MUST be 6
  # type      MUST be 4
  # stream_id MUST be 0
  def parse(<<len::24, 4::8, flags::8, 0::1, 0::31>> <> payload) do
    if len / 6 == 0 do
      parse_settings(payload)
    else
      Logger.info "ERROR!!! Must be multiple of 6"
    end
  end

  def parse_settings("") do
    # do nothing
  end

  def parse_settings(payload) do
    <<id :: 16, value :: 32>> <> rest = payload

    Logger.info "SETTINGS: #{type(id)} => #{value}"

    parse_settings(rest)
  end

  def type(settings_id) do
    case settings_id do
      1 -> :settings_header_table_size
      2 -> :settings_enable_push
      3 -> :settings_max_concurrent_streams
      4 -> :settings_initial_window_size
      5 -> :settings_max_frame_size
      6 -> :settings_max_header_list_size
    end
  end

  def ack do
    <<0::24, 4::8, 1::8, 0::1, 0::31>>
  end

end
