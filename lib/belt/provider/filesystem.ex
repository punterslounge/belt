defmodule Belt.Provider.Filesystem do
  @moduledoc """
  Provider module offering support for storing files in a directory on the
  local filesystem.
  """

  use Belt.Provider
  alias Belt.Provider.Filesystem.Config
  alias Belt.Provider.Helpers

  @max_renames Belt.Config.get(__MODULE__, :max_renames)

  @typedoc """
  Options for creating an Filesystem provider.
  """
  @type filesystem_option ::
    {:directory, String.t} |
    {:base_url, String.t}

  @doc """
  Creates a new Filesystem provider configuration.

  ## Options
  - `:directory` (required) - `Path.t` - path to folder on the file system.
  - `:base_url` - `String.t` - URL under which files stored with this configuration are accessible
  """
  @spec new([filesystem_option]) :: {:ok, Belt.Provider.configuration}
  def new(opts) do
    directory = Keyword.get(opts, :directory)
    base_url = Keyword.get(opts, :base_url, :unavailable)
    if (directory),
      do: {:ok, %Config{directory: directory, base_url: base_url}},
      else: {:error, "no directory specified"}
  end


  @doc """
  Implementation of the `Belt.Provider.store/3` callback.
  """
  def store(config, file_source, options) do
    directory = config.directory
    scope = Keyword.get(options, :scope, "")
    key = Keyword.get(options, :key)
    overwrite = Keyword.get(options, :overwrite, :rename)
    max_renames = if (overwrite === :rename),
      do: @max_renames,
      else: 0

    with {:ok, path} <- create_target_file(directory, scope, key,
                                           overwrite: overwrite,
                                           max_renames: max_renames),
         :ok <- File.cp(file_source, path) do
      :timer.sleep(500)
      get_info(config, Path.relative_to(path, directory), options)
    end
  end

  defp create_target_file(directory, scope, key, options) do
    overwrite = Keyword.get(options, :overwrite) == true
    max_renames = Keyword.get(options, :max_renames)
    create_target_file(directory, scope, key, overwrite, 0, max_renames)
  end

  defp create_target_file(directory, scope, key, overwrite, renames, max_renames)

  defp create_target_file(directory, scope, key, overwrite, renames, max_renames)
  when renames <= max_renames do
    open_opts = if overwrite,
      do: [:write],
      else: [:write, :exclusive]
    with {:ok, path} <- build_target_path(directory, scope, key, renames),
         :ok <- File.mkdir_p(Path.dirname(path)),
         {:ok, device} <- File.open(path, open_opts) do
         File.close(device)
         {:ok, path}
    else
      {:error, :eexist}
        -> create_target_file(directory, scope, key, overwrite, renames + 1, max_renames)
      {:error, _} = error -> error
    end
  end

  defp create_target_file(_, _, _, _, _, _),
    do: {:error, "could not create target file"}


  @doc """
  Implementation of the `Belt.Provider.delete/3` callback.
  """
  def delete(config, identifier, _options) do
    {:ok, path} = build_target_path(config.directory, "", identifier)
    File.rm!(path)
  end


  @doc """
  Implementation of the `Belt.Provider.get_info/3` callback.
  """
  def get_info(config, identifier, options) do
    {:ok, path} = build_target_path(config.directory, "", identifier)
    %{size: size, ctime: modified} = File.stat!(path)
    url = case config.base_url do
      :unavailable -> :unavailable
      url -> URI.merge(url, identifier) |> to_string() |> URI.encode()
    end
    hashes = case Keyword.get(options, :hashes, []) do
      [_ | _] = algs -> Belt.Hasher.hash_file(path, algs)
      _other -> []
    end

    file_info = %Belt.FileInfo{
      identifier: identifier,
      config: config,
      size: size,
      modified: modified,
      url: url,
      hashes: hashes
    }
    {:ok, file_info}
  end

  defp build_target_path(directory, scope, key, renames \\ 0) do
    path = [directory, scope, key]
    |> Path.join()
    |> Path.expand()
    |> Helpers.increment_path(renames)

    if (Path.relative_to(path, directory) == path),
      do: {:error, "invalid scope or filename"},
      else: {:ok, path}
  end


  @doc """
  Implementation of the `Belt.Provider.get_url/3` callback.
  """
  def get_url(%{base_url: base_url}, identifier, _options) when is_binary(base_url) do
    url = base_url
      |> URI.merge(identifier)
      |> URI.to_string()
    {:ok, url}
  end

  def get_url(_, _, _), do: :unavailable


  @doc """
  Implementation of the `Belt.Provider.list_files/2` callback.
  """
  def list_files(config, options) do
    directory = config.directory
    files = do_list_files([directory], [], options)
      |> Enum.map(&Path.relative_to(&1, directory))
    {:ok, files}
  end

  def do_list_files([], files, _), do: files

  def do_list_files([dir | t], files, options) do
    {new_dirs, new_files} = File.ls!(dir)
      |> Enum.map(fn(name) ->
        path = Path.join(dir, name)
        if File.dir?(path), do: {:dir, path}, else: {:file, path}
      end)
      |> Enum.reduce({[], []}, fn({type, path}, {dirs, files}) ->
        case type do
          :dir  -> {[path | dirs], files}
          :file -> {dirs, [path | files]}
          _     -> {dirs, files}
        end
      end)

    do_list_files(new_dirs ++ t, new_files ++ files, options)
  end
end
