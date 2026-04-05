defmodule Server do
  @moduledoc """
  Your implementation of a Redis server
  """

  use Application

  def start(_type, _args) do
    Supervisor.start_link([{Task, fn -> Server.listen() end}], strategy: :one_for_one)
  end

  @doc """
  Listen for incoming connections
  """
  def listen() do
    # You can use print statements as follows for debugging, they'll be visible when running tests.
    IO.puts("Logs from your program will appear here!")

    # Uncomment the code below to pass the first stage
    #
    # Since the tester restarts your program quite often, setting SO_REUSEADDR
    # ensures that we don't run into 'Address already in use' errors
    {:ok, socket} = :gen_tcp.listen(6379, [:binary, active: false, reuseaddr: true])

    handle_socket(socket)
  end

  def handle_socket(socket) do
    {:ok, client} = :gen_tcp.accept(socket)

    IO.puts("Accepted: #{inspect(client)}")

    Task.start_link(fn -> handle_client(client) end)

    handle_socket(socket)
  end

  def handle_client(client) do
    loop(client)
  end

  defp loop(client) do
    case :gen_tcp.recv(client, 0) do
      {:ok, cmd} ->
        IO.inspect("Data Recieved : #{cmd}")
        resp = Server.Parser.parse_command(cmd)
        # :gen_tcp.send(client, "+PONG\r\n")
        :gen_tcp.send(client, resp)
        loop(client)

      {:error, :closed} ->
        :ok
    end
  end
end

defmodule CLI do
  def main(_args) do
    # Start the Server application
    {:ok, _pid} = Application.ensure_all_started(:codecrafters_redis)

    # Run forever
    Process.sleep(:infinity)
  end
end
