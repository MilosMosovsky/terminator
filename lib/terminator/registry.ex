defmodule Terminator.Registry do
  @moduledoc false

  use GenServer

  def start_link() do
    {:ok, pid} = GenServer.start_link(__MODULE__, %{table: nil})
    GenServer.call(pid, :init_table)
    {:ok, pid}
  end

  @impl true
  def init(stack) do
    {:ok, stack}
  end

  @impl true
  def handle_call(:init_table, _from, _state) do
    table = :ets.new(__MODULE__, [:named_table, :set, :public, read_concurrency: true])
    {:reply, table, %{table: table}}
  end

  def insert(name, value) do
    :ets.insert(__MODULE__, {name, value})
  end

  def add(name, value) do
    current =
      case lookup(name) do
        {:ok, nil} -> []
        {:ok, current} -> current
      end

    uniq = Enum.uniq(current ++ [value])

    insert(name, uniq)
  end

  def lookup(name) do
    case :ets.lookup(__MODULE__, name) do
      [{^name, value}] -> {:ok, value}
      [] -> {:ok, nil}
    end
  end
end
