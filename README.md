# AshJason

[![Module Version](https://img.shields.io/hexpm/v/ash_jason)](https://hex.pm/packages/ash_jason)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen)](https://hexdocs.pm/ash_jason/)
[![License](https://img.shields.io/hexpm/l/ash_jason)](https://github.com/vonagam/ash_jason/blob/master/LICENSE.md)

Ash resource extension for implementing Jason.Encoder protocol.

## Installation

Add to the deps, get deps (`mix deps.get`), compile them (`mix deps.compile`).

```elixir
def deps do
  [
    {:ash_jason, "~> 0.3.1"},
  ]
end
```

## Usage

Add `AshJason.Extension` to `extensions` list in `use Ash.Resource`:

```elixir
defmodule Example.Resource do
  use Ash.Resource,
    extensions: [AshJason.Extension]
end
```

### Configuration

The process to get data for json happens with three steps: 
- Pick keys from a record.
- Merge some fixed values.
- Customize a result.

By default only first step happens and it picks all non-private fields (attributes, relationships, aggregates,
calculations) with loaded non-nil values.

For configuration there is an optional `jason` dsl section:

```elixir
defmodule Example.Resource do
  use Ash.Resource,
    extensions: [AshJason.Extension]

  jason do
    # options
  end
end
```

#### pick

Keys to pick from a record and include in json.
Values of `nil`/`Ash.NotLoaded`/`Ash.NotSelected` are omitted.

Can be specified as a fixed explicit list of keys or a map with a configuration of default behaviour.

Map can have such options as:
- `private?` - Whenever to pick private fields.
- `sensitive?` - Whenever to pick sensitive fields.
- `include` - Keys to pick. In addition to fields.
- `exclude` - Keys not to pick. 

```elixir
jason do
  # Pick only those listed keys
  pick [:only_some_field]

  # Pick non-sensitive fields
  pick %{private?: true}

  # Pick non-private fields
  pick %{sensitive?: true}

  # Pick all fields
  pick %{private?: true, sensitive?: true}

  # Pick usual but include and exclude some specific keys
  pick %{include: [:ok_private_field], exclude: [:irrelevant_public_field]}
end
```

#### merge

A map to merge into json.

```elixir
jason do
  merge %{merged_key: "merged_value"}
end
```

#### customize

A function to customize json.
Receives a current resulted json map and a source resource record.
Returns a modified json map.

```elixir
jason do
  customize fn result, _record ->
    result |> Map.put(:custom_key, "custom_value")
  end
end
```

## Links

[`Jason` docs](https://hexdocs.pm/jason).
