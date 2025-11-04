# SPDX-FileCopyrightText: 2023 ash_jason contributors <https://github.com/vonagam/ash_jason/graphs/contributors>
#
# SPDX-License-Identifier: MIT

defmodule AshJason.TransformerHelpers do
  @moduledoc false

  defmodule Step do
    @moduledoc false

    defstruct [:type, :input, __spark_metadata__: nil]
  end

  def transform(dsl, get_fields) do
    dsl =
      Spark.Dsl.Transformer.eval(
        dsl,
        [],
        quote do
          defimpl Jason.Encoder do
            def encode(record, opts) do
              unquote(make_pick(dsl, get_fields))
              unquote_splicing(make_steps(dsl))
              Jason.Encode.keyword(result, opts)
            end
          end
        end
      )

    {:ok, dsl}
  end

  defp make_pick(dsl, get_fields) do
    keys =
      case Spark.Dsl.Transformer.get_option(dsl, [:jason], :pick, %{}) do
        keys when is_list(keys) ->
          keys

        options when is_map(options) ->
          fields = get_fields.(dsl, options)
          keys = Enum.map(fields, & &1.name)
          keys = keys ++ Map.get(options, :include, [])
          keys = Enum.uniq(keys)
          keys = keys -- Map.get(options, :exclude, [])
          keys
      end

    quote bind_quoted: [keys: Macro.escape(keys)] do
      result =
        for key <- keys,
            {:ok, value} = {:ok, Map.get(record, key)},
            not is_struct(value, Ash.NotLoaded),
            not is_struct(value, Ash.ForbiddenField) do
          {key, value}
        end
    end
  end

  defp make_steps(dsl) do
    for step <- Spark.Dsl.Transformer.get_entities(dsl, [:jason]),
        step_expression = make_step(step.type, step.input) do
      step_expression
    end
  end

  defp make_step(:compact, false) do
    nil
  end

  defp make_step(:compact, true) do
    make_step(:compact, %{})
  end

  defp make_step(:compact, {tag, fields}) when tag in [:only, :except] and is_list(fields) do
    make_step(:compact, %{fields: {tag, fields}})
  end

  defp make_step(:compact, config) do
    value_check =
      case config[:values] do
        nil ->
          quote do: value == nil

        [value] ->
          quote bind_quoted: [compact_value: Macro.escape(value)], do: value == compact_value

        values ->
          quote bind_quoted: [compact_values: Macro.escape(values)], do: value in compact_values
      end

    case config[:fields] do
      nil ->
        quote do
          result = Enum.reject(result, fn {_key, value} -> unquote(value_check) end)
        end

      {:only, fields} ->
        quote bind_quoted: [compact_fields: Macro.escape(fields)], unquote: true do
          result = Enum.reject(result, fn {key, value} -> unquote(value_check) and key in compact_fields end)
        end

      {:except, fields} ->
        quote bind_quoted: [compact_fields: Macro.escape(fields)], unquote: true do
          result = Enum.reject(result, fn {key, value} -> unquote(value_check) and key not in compact_fields end)
        end
    end
  end

  defp make_step(:merge, values) do
    quote bind_quoted: [values: Macro.escape(values)] do
      result =
        for tuple <- values, {key, value} = tuple, reduce: result do result ->
          List.keystore(result, key, 0, tuple)
        end
    end
  end

  defp make_step(:rename, renames) when is_list(renames) do
    quote bind_quoted: [renames: Macro.escape(renames)] do
      result =
        for {key, value} <- result do
          {List.keyfind(renames, key, 0, {key, key}) |> elem(1), value}
        end
    end
  end

  defp make_step(:rename, renames) when is_map(renames) do
    quote bind_quoted: [renames: Macro.escape(renames)] do
      result =
        for {key, value} <- result do
          {Map.get(renames, key, key), value}
        end
    end
  end

  defp make_step(:rename, fun) when is_function(fun, 1) do
    quote bind_quoted: [fun: Macro.escape(fun)] do
      result =
        for {key, value} <- result do
          {fun.(key), value}
        end
    end
  end

  defp make_step(:order, false) do
    nil
  end

  defp make_step(:order, true) do
    quote do
      result = Enum.sort(result)
    end
  end

  defp make_step(:order, fun) when is_function(fun, 1) do
    quote bind_quoted: [fun: Macro.escape(fun)] do
      result = result |> Enum.map(&elem(&1, 0)) |> fun.() |> Enum.map(&{&1, List.keyfind!(result, &1, 0) |> elem(1)})
    end
  end

  defp make_step(:order, keys) when is_list(keys) do
    quote bind_quoted: [keys: Macro.escape(keys)] do
      result = for key <- keys, tuple = List.keyfind(result, key, 0), do: tuple
    end
  end

  defp make_step(:customize, fun) do
    quote bind_quoted: [fun: Macro.escape(fun)] do
      result = fun.(result, record)
    end
  end
end
