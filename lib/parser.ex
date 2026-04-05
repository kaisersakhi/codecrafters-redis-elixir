defmodule Server.Parser do
  @valid_commands ["PING", "ECHO"]
  @crlf "\r\n"

  def parse_command(cmd) do
    parse(cmd)
    |> prepare_response
  end

  # defp prepare_response("ECHO" <> args), do: "+#{args}\r\n"
  # defp prepare_response("PING" <> _rest), do: "+PONG\r\n"
  defp prepare_response(input) do
    [cmd | rest] = input
    IO.inspect("User CMD: #{cmd}")
    IO.inspect("User input: #{rest}")

    case String.upcase(cmd) do
      "ECHO" ->
        [arg] = rest
        "$#{byte_size(arg)}\r\n#{arg}\r\n"

      "PING" ->
        "+PONG\r\n"

      _ ->
        "-Err unknown command\r\n"
    end
  end

  # defp prepare_response(_whatever), do: "ERR unknonw command\r\n"

  defp parse("+" <> rest), do: parse_simple_string(rest)
  # defp parse("$" <> rest), do: parse_bulk_string(rest)
  defp parse("*" <> rest), do: parse_array(rest)

  defp parse(_unknow), do: ["ERROR", 0]

  defp parse_simple_string(data), do: [data |> String.split("\r\n") |> List.first(), 0]

  defp parse_array(data) do
    IO.puts("Parse Array <> #{data}")
    [_array_len | items] = String.split(data, "\r\n")

    parse_items(items)
  end

  defp parse_items([_type_len, data | others]) do
    IO.inspect("FN:PARSE_ITEMS-Data " <> data)
    [data |> String.trim() | parse_items(others)]
  end

  defp parse_items([""]), do: []
end
