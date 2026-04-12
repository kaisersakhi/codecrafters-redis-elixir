defmodule Server.Parser do
  alias Server.Store

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

      "SET" ->
        [key, value | options] = rest
        IO.inspect("Key: " <> key)
        IO.inspect("Val: " <> value)
        IO.inspect("Options: #{options}")

        Store.set(key, value |> String.trim(), tarray_to_map(options))
        "+OK\r\n"

      "GET" ->
        [key] = rest

        value = Store.get(key) || ""

        size = byte_size(value)

        IO.puts("prepare_response:Byte Size: " <> "#{byte_size(value)}")
        IO.puts("prepare_response:Value: #{value}")

        # IO.puts("prepare_response:GET IO: " <> "$#{size}\r\n#{value}\r\n")

        cond do
          size > 0 ->
            "$#{size}\r\n#{value}\r\n"

          true ->
            "$#{-1}\r\n"
        end

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

  # Tuple array to map. Yeah, i don't know how to name things!
  defp tarray_to_map(list) do
    list
    |> Enum.chunk_every(2)
    |> Map.new(fn [k, v] -> {k, v} end)
  end
end
