if Code.ensure_loaded? Ecto.Type do
  defmodule Belt.Ecto.Config do
    @moduledoc """
    Ecto type for storing Belt.Provider config structs.

    This Ecto type allows storing and retrieving Belt.Provider configurations
    without needing to perform manual conversions.

    ## Usage
    ```
    #in migrations

    create table(:belt_providers) do
      add :config, :map #Belt.Ecto.Config uses Ecto primitive :map
    end
    ```
    ```
    #in schemas

    schema "belt_providers" do
      field :config, Belt.Ecto.Config
    end
    ```
    """

    use Ecto.Type

    @doc """
    Underlying Ecto primitive is a Map.
    """
    def type, do: :map

    @doc """
    Only valid provider config structs can be cast.
    """
    def cast(%{provider: _, __struct__: _} = config) do
      {:ok, config}
    end
    def cast(_), do: :error

    def cast!(value) do
      case cast(value) do
        {:ok, date} -> date
        :error -> raise Ecto.CastError, "#{inspect value} is not a Belt.Provider config struct!"
      end
    end

    @doc """
    Serializes config struct to Map primitive while preserving atoms.

    Config structs that contain nested maps/structs or lists are currently not supported.
    """
    def dump(%{provider: _, __struct__: _} = config) do
      config
      |> Map.delete(:__struct__)
      |> Enum.map(fn(pair) ->
        stringify(pair)
      end)
      |> Enum.into(%{})
      |> fn(config) -> {:ok, config} end.()
    end

    def dump(_), do: :error

    @doc """
    Loads config struct from serialized Map and restores existing atoms.
    """
    def load(%{"provider" => provider} = serialized_config)
    when is_binary(provider) do
      config = serialized_config
        |> Enum.map(fn(pair) ->
          unstringify(pair)
        end)
        |> Enum.into(%{})
        |> to_config_struct()
      {:ok, config}
    end

    def load(_), do: :error

    defp stringify({key, _}) when not is_atom(key), do: :error

    defp stringify({key, value})
    when is_binary(value) or is_number(value) or value in [nil, true, false] do
      {Atom.to_string(key), value}
    end

    defp stringify({key, value}) when is_atom(value) do
      {Atom.to_string(key), "belt_atom::" <> Atom.to_string(value)}
    end

    defp stringify(_), do: :error

    defp unstringify({key, _}) when not is_binary(key), do: :error

    defp unstringify({key, "belt_atom::" <> value}) do
      {String.to_existing_atom(key), String.to_existing_atom(value)}
    end

    defp unstringify({key, value}) do
      {String.to_existing_atom(key), value}
    end

    defp unstringify(_), do: :error

    defp to_config_struct(config) do
      Map.put(config, :__struct__, :"#{config.provider}.Config")
    end
  end
else
  defmodule Belt.Ecto.Config do
  end
end
