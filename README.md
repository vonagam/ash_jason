# AshJason

[![Module Version](https://img.shields.io/hexpm/v/ash_jason)](https://hex.pm/packages/ash_jason)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen)](https://hexdocs.pm/ash_jason/)
[![License](https://img.shields.io/hexpm/l/ash_jason)](https://github.com/vonagam/ash_jason/blob/master/LICENSE.md)

Ash resource extension for implementing `Jason.Encoder` protocol.

## Installation

Add to the deps, get deps (`mix deps.get`), compile them (`mix deps.compile`).

```elixir
def deps do
  [
    {:ash_jason, "~> 1.0.1"},
  ]
end
```

## Usage

Add `AshJason.Resource` to `extensions` list within `use Ash.Resource` options:

```elixir
defmodule Example.Resource do
  use Ash.Resource,
    extensions: [AshJason.Resource]
end
```

### Configuration

The process to get data for json happens with four steps: 
- Pick keys from a record.
- Merge some fixed values.
- Customize a result.
- Order keys.

By default only first step happens and it picks all non-private fields (attributes, relationships, aggregates,
calculations) with loaded non-nil values.

For configuration there is an optional `jason` dsl section:

```elixir
defmodule Example.Resource do
  use Ash.Resource,
    extensions: [AshJason.Resource]

  jason do
    # options
  end
end
```

#### pick

Keys to pick from a record and include in json.
Values of `nil`/`Ash.NotLoaded`/`Ash.ForbiddenField` are omitted.

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

#### order

Can be specified as a boolean, a sort function or a fixed explicit list of keys in a desired order.

If it is a list then it also omits keys not present in that list.

```elixir
jason do
  # Order with standart `Enum.sort`
  order true

  # Order with a custom sort function
  order fn keys -> Enum.sort(keys, :desc) end

  # Order in accordance with a list
  order [:a, :b, :c]
end
```

## Links

[`Jason` docs](https://hexdocs.pm/jason).
