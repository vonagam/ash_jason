# AshJason

[![Module Version](https://img.shields.io/hexpm/v/ash_jason)](https://hex.pm/packages/ash_jason)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen)](https://hexdocs.pm/ash_jason/)
[![License](https://img.shields.io/hexpm/l/ash_jason)](https://github.com/vonagam/ash_jason/blob/master/LICENSE.md)

Ash resource extension for implementing `Jason.Encoder` protocol.

## Installation

Add to the deps:

```elixir
def deps do
  [
    {:ash_jason, "~> 2.0.0"},
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

Producing json object can have multiple steps:
- Picking keys from a record.
- Merging some values.
- Renaming keys.
- Ordering keys.
- Customizing a result with a function.

By default only the picking step happens and it takes all non-private non-sensitive fields
(attributes, relationships, aggregates, calculations) with loaded non-nil values from a record.

For adding and configuring those steps there is an optional `jason` dsl section:

```elixir
defmodule Example.Resource do
  use Ash.Resource,
    extensions: [AshJason.Resource]

  jason do
    # options
  end
end
```

All optional steps can be specified multiple times and are applied in the order they were defined in.

A result object on which those steps operate is a key-value list - not map, not keyword list.
- Unlike map the order is stable and guaranteed.
- Unlike keyword list it can have string keys.

#### `pick`

Keys to pick from a record and include in the result.
Accepts a fixed explicit list of keys or a map with a configuration of default behaviour.

Values of `nil`/`Ash.NotLoaded`/`Ash.ForbiddenField` are omitted.

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

#### `merge`

A step to merge values into a result.
Accepts a map or a tuples list.

Map has no guarantees about keys order so if you care about that prefer the list form.

```elixir
jason do
  # Merge with map
  merge %{key: "value"}

  # Merge with list
  merge key: "value"
end
```

#### `rename`

A step to rename keys in a result.
Accepts a map, a tuples list or a function for mapping.

```elixir
jason do
  # Rename with map
  rename %{from_key: "to_key"}

  # Rename with list
  rename from_key: "to_key"

  # Rename with a function
  rename fn name -> String.capitalize(to_string(name)) end
end
```

#### `order`

A step to reorder keys in a result.
Accepts a boolean, a sort function or a list of keys in a desired order.

If it is a list then it also acts as a filter and removes keys not present in that list.

```elixir
jason do
  # Order with standard `Enum.sort`
  order true

  # Order with a custom sort function
  order fn keys -> Enum.sort(keys, :desc) end

  # Order in accordance with a list
  order [:only, :these, :keys, :in, :that, "order"]
end
```

#### `customize`

A step to arbitrary customize a result.
Accepts a function that will get a result and a resource record as arguments and return a modifed result.

As mentioned above a result has a form of a list with two elements, key and value, tuples.
To work with it you might want to use `List` methods like `List.keytake` or `List.keystore`.

```elixir
jason do
  customize fn result, _record ->
    result |> List.keystore(:custom_key, 0, {:custom_key, "custom_value"})
  end
end
```

## Links

[`Jason` docs](https://hexdocs.pm/jason).
