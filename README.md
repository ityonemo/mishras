# Mishras

A powerful factory library for Elixir that simplifies test data creation for Ecto schemas with support for associations, embeds, and custom data generation.

## Overview

Mishras provides a protocol-based factory system that automatically handles:
- **Associations** (belongs_to, has_one, has_many, many_to_many)
- **Embedded schemas** (embeds_one, embeds_many)
- **Primary key generation** (both integer and binary_id)
- **Custom data generation** through implementation modules

## Installation

Add `mishras` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:mishras, "~> 0.1.0"}
  ]
end
```

## Configuration

Configure your repo in `config/config.exs`:

```elixir
config :mishras, repo: MyApp.Repo
```

## Usage

### Basic Schema Factory

```elixir
defmodule MyApp.User do
  use Ecto.Schema
  
  schema "users" do
    field :name, :string
    field :email, :string
  end
  
  def changeset(struct \\ %__MODULE__{}, attrs) do
    struct
    |> Ecto.Changeset.cast(attrs, [:name, :email])
    |> Ecto.Changeset.validate_required([:name, :email])
  end
end

# Implement the factory
defimpl Mishras.Factory, for: MyApp.User do
  use Mishras
  
  def build_map(_mode, _attrs) do
    %{
      name: "John Doe",
      email: "john@example.com"
    }
  end
end
```

### Creating Test Data

```elixir
# Build a struct (no database insertion)
user = Mishras.Factory.build(MyApp.User, %{name: "Jane"})

# Insert into database
user = Mishras.Factory.insert(MyApp.User, %{email: "jane@example.com"})
```

### Advanced Features

- **Automatic association handling**: Referenced schemas are automatically built/inserted
- **Embedded schema support**: Nested embeds are properly constructed
- **Custom ID generation**: Override `autogenerate_id/1` for custom primary key logic
- **Mode-aware factories**: Different behavior for `:build` vs `:insert` modes

## API

### Main Functions

- `Mishras.Factory.build/2` - Build a struct without database insertion
- `Mishras.Factory.insert/2` - Insert a record into the database

### Implementation Callbacks

- `build_map/2` - Required. Defines default attributes for the schema
- `autogenerate_id/1` - Optional. Custom primary key generation logic

## License

This project is licensed under the MIT License.
