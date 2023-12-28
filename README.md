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
    {:ash_jason, "~> 0.2"},
  ]
end
```

## Usage

Add `AshJason.Extension` to `extensions` list in `use Ash.Resource`:

```elixir
defmodule Example.Resource do
  use Ash.Resource,
    extensions: [Ash.ULID.Extension]
end
```

By default encodes all non-private fields (attributes/relationships/aggregates/calculations) with loaded non-nil values.

### Configuration

For configuration there is an optional `jason` dsl section:

```elixir
defmodule Example.Resource do
  use Ash.Resource,
    extensions: [Ash.ULID.Extension]

  jason do
    # options
  end
end
```

#### fields

Fields to pick from a record and include in json.
Feilds with values of `nil`/`Ash.NotLoaded`/`Ash.NotSelected` are omitted.
By default includes all public non-sensitive fields (attributes/relationships/aggregates/calculations).
Specifying `fields` overwrites that default, `pick`/`omit` can be used instead to simply modify it.

```elixir
jason do
  fields [:only_some_field]
end
```

#### pick

Keys to pick from a record in addition to `fields`.
Can be used to whitelist some private/sensitive attributes or custom non-field properties.

```elixir
jason do
  pick [:additional_key]
end
```

#### omit

Keys to omit from `fields`/`pick`.
Can be used to blacklist some public attributes that get included by default.

```elixir
jason do
  omit [:privatish_key]
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
