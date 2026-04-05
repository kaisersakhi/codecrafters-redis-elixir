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

  def handle_cast({:set, key, value, _options}, state) do
    {:noreply, Map.put(state, key, value)}
  end

  def handle_call({:get, key}, _from, state) do
    {:reply, Map.get(state, key), state}
  end
end
