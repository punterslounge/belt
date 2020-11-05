defmodule Belt.Job.Supervisor do
  @moduledoc """
  Supervisor for `Belt.Job` processes.
  """

  use Supervisor

  def start_link(_init_arg \\ :ok) do
    Supervisor.start_link(__MODULE__, :ok, [name: __MODULE__])
  end

  @impl true
  def init(:ok) do
    children = []

    Supervisor.init(children, strategy: :one_for_one)
  end

  @doc """
  Starts a new `Belt.Job` process with the given payload and supervises it.
  When `name` is set to `:auto` or omitted, a name for the process will be
  generated automatically.
  """
  @spec start_child(term, term | :auto) :: {:ok, Belt.Job.t} | {:error, term}
  def start_child(payload, name \\ :auto) do
    name = case name do
      :auto -> :erlang.unique_integer([:positive])
      other -> other
    end

    Supervisor.start_child(__MODULE__, %{
      id: name,
      start: {Belt.Job, :start_link, [name, payload]},
      type: :worker,
      restart: :transient,
      shutdown: 500
    })
    |> case do
      {:ok, _pid} -> {:ok, name}
      other -> {:error, other}
    end
  end
end
