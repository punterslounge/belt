defmodule Belt.Provider.Supervisor do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      defmodule Supervisor do
        @moduledoc false
        use ConsumerSupervisor

        @concurrency_limit 3

        def start_link(arg \\ init(:ok)) do
          ConsumerSupervisor.start_link(__MODULE__, arg)
        end

        def init(_arg) do
          children = [%{
            id: get_worker_name(),
            start: {get_worker_name(), :start_link, []}, restart: :transient
          }]
          ConsumerSupervisor.init(children,
            strategy: :one_for_one,
            subscribe_to: [{Belt,
              max_demand: @concurrency_limit,
              min_demand: Integer.floor_div(@concurrency_limit, 2),
              partition: get_worker_name()
            }]
          )
        end

        defp get_worker_name() do
          __MODULE__
          |> to_string()
          |> String.split(".")
          |> Enum.drop(-1)
          |> Enum.join(".")
          |> String.to_existing_atom()
        end
      end
    end
  end
end
