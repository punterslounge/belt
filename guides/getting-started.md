# Getting Started

## Installation
Belt is [free software](https://www.fsf.org/about/what-is-free-software). You can use it in your projects under the conditions of one of its two licenses ([GNU AGPL 3.0](https://www.gnu.org/licenses/agpl-3.0.en.html) or [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0.html) - which is the license also used by Elixir and many other libraries). For more information, please read the `LICENSE` file.

Belt can be installed by adding `:belt` to your dependencies and application
list in `mix.exs`:

```elixir
def deps do
  [{:belt, "~> 0.5.1"}]
end

def application do
  [extra_applications: [:logger, :belt]]
end
```
## Providers

### Supported providers
Belt comes with backends for the local filesystem (`Belt.Provider.Filesystem`), SFTP (`Belt.Provider.SFTP`) and S3 (`Belt.Provider.S3`).

By default, Belt will automatically determine which providers are available according to your installed dependencies. You can also manually configure the Providers that should be started alongside Belt (typically in your `config/config.exs` file:
```
config :belt,
  providers: [Belt.Provider.Filesystem, Belt.Provider.SFTP, Belt.Provider.S3]
```

#### Belt.Provider.Filesystem
`Belt.Provider.Filesystem` has no special dependencies.

#### Belt.Provider.SFTP
`Belt.Provider.SFTP` requires `:ssh_sftp` which is already included in many OTP distributions.

#### Belt.Provider.S3
If you want to use `Belt.Provider.S3`, you need to make sure to include [ExAws](https://github.com/ex-aws/ex_aws/) with [ExAws S3](https://github.com/ex-aws/ex_aws_s3) as well as their dependencies [Hackney](https://hex.pm/packages/hackney) and [sweet_xml](https://hex.pm/packages/sweet_xml) (which are required by ExAws) to your dependencies and applications list:
```elixir
def deps do
  [{:belt, "~> 0.5.1"},
   {:ex_aws, "~> 2.1"},
   {:ex_aws_s3, "~> 2.0"},
   {:hackney, "~> 1.16"},
   {:sweet_xml, "~> 0.6"}]
end

def application do
  [extra_applications: [:belt, :hackney, .sweet_xml]]
end
```

## Using Belt with Ecto
You can use `Belt.Ecto.Config` for easily persisting your provider configuration in a database:
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
