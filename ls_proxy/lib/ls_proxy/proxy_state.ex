defmodule LsProxy.ProxyState do
  @moduledoc """
  Records the state of LSP session
  """
  use GenServer

  defmodule State do
    defstruct [:messages]
  end

  def start_link(_, name \\ __MODULE__) do
    GenServer.start_link(__MODULE__, nil, name: name)
  end

  @impl GenServer
  def init(_) do
    initial_state = %State{
      messages: :queue.new()
    }

    {:ok, initial_state}
  end

  def register_listener() do
    Registry.register(LsProxy.MessageRegistry, "listener", :value)
  end

  def record_incoming(msg, name \\ __MODULE__) do
    GenServer.call(name, {:record_incoming, msg})
  end

  def record_outgoing(msg, name \\ __MODULE__) do
    GenServer.call(name, {:record_outgoing, msg})
  end

  def messages(name \\ __MODULE__) do
    GenServer.call(name, {:messages})
  end

  def clear(name \\ __MODULE__) do
    GenServer.call(name, {:clear})
  end

  @impl GenServer
  def handle_call({:record_incoming, msg}, _from, state) do
    message = LsProxy.MessageRecord.new(msg, :incoming)

    queue =
      if message.message.content["method"] == "initialize" do
        :queue.new()
      else
        state.messages
      end

    state = %State{state | messages: :queue.in(message, queue)}
    {:reply, :ok, state, {:continue, :notify_listeners}}
  end

  def handle_call({:record_outgoing, msg}, _from, state) do
    message = LsProxy.MessageRecord.new(msg, :outgoing)
    queue = state.messages
    state = %State{state | messages: :queue.in(message, queue)}
    {:reply, :ok, state, {:continue, :notify_listeners}}
  end

  def handle_call({:messages}, _from, state) do
    {:reply, :queue.to_list(state.messages), state}
  end

  def handle_call({:clear}, _from, _state) do
    state = %State{
      messages: :queue.new()
    }

    {:reply, :ok, state, {:continue, :notify_listeners}}
  end

  @impl GenServer
  def handle_continue(:notify_listeners, state) do
    notify_listeners()
    {:noreply, state}
  end

  def notify_listeners do
    Registry.dispatch(LsProxy.MessageRegistry, "listener", fn entries ->
      for {pid, _value} <- entries do
        send(pid, {:update_messages})
      end
    end)
  end

  def kill_listeners do
    Registry.dispatch(LsProxy.MessageRegistry, "listener", fn entries ->
      for {pid, _value} <- entries do
        Process.exit(pid, :kill)
      end
    end)
  end
end
