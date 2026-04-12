defmodule Server.Store do
  use GenServer

  def start_link(initial \\ %{}) do
    GenServer.start_link(__MODULE__, initial, name: __MODULE__)
  end

  def set(key, value), do: set(key, value, [])

  def set(key, value, options) do
    GenServer.cast(__MODULE__, {:set, key, value, options})
  end

  def get(key) do
    GenServer.call(__MODULE__, {:get, key})
  end

  def init(state), do: {:ok, state}

  def handle_cast({:set, key, value, options}, state) do
    set_at = now(:px)

    options = Map.put(options, "set_at", set_at)

    new_state = Map.put(state, key, %{value: value, options: options})

    {:noreply, new_state}
  end

  def handle_call({:get, key}, _from, state) do
    case Map.get(state, key) do
      nil ->
        {:reply, nil, state}

      %{value: value, options: %{"EX" => expiry, "set_at" => set_at}} ->
        case expired?(expiry, set_at, :ex) do
          true ->
            {:reply, nil, Map.delete(state, key)}

          false ->
            {:reply, value, state}
        end

      %{value: value, options: %{"PX" => expiry, "set_at" => set_at}} ->
        case expired?(expiry, set_at, :px) do
          true ->
            {:reply, nil, Map.delete(state, key)}

          false ->
            {:reply, value, state}
        end

      %{value: value} ->
        {:reply, value, state}
    end
  end

  def expired?(expiry, set_at, time_in) do
    set_at =
      if time_in == :ex do
        set_at / 1000
      end || set_at

    set_at + str_to_int(expiry) < now(time_in)
  end

  def now(:ex), do: System.system_time(:second)
  def now(:px), do: System.system_time(:millisecond)

  defp str_to_int(val) do
    trimmed =
      val
      |> String.trim()

    case Integer.parse(trimmed) do
      {int, ""} -> int
      _ -> 0
    end
  end
end
