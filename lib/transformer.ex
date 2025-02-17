defmodule AshJason.Transformer do
  @moduledoc false

  use Spark.Dsl.Transformer

  defmodule Step do
    @moduledoc false

    defstruct [:type, :input]
  end

  def transform(dsl) do
    dsl =
      Spark.Dsl.Transformer.eval(
        dsl,
        [],
        quote do
          defimpl Jason.Encoder do
            def encode(record, opts) do
              unquote(make_pick(dsl))
              unquote_splicing(make_steps(dsl))
              Jason.Encode.keyword(result, opts)
            end
          end
        end
      )

    {:ok, dsl}
  end

  def make_pick(dsl) do
    keys =
      case Spark.Dsl.Transformer.get_option(dsl, [:jason], :pick, %{}) do
        keys when is_list(keys) ->
          keys

        options when is_map(options) ->
          fields = Ash.Resource.Info.fields(dsl)
          fields = if Map.get(options, :private?), do: fields, else: Enum.filter(fields, & &1.public?)
          fields = if Map.get(options, :sensitive?), do: fields, else: Enum.reject(fields, &Map.get(&1, :sensitive?))
          keys = Enum.map(fields, & &1.name)
          keys = keys ++ Map.get(options, :include, [])
          keys = Enum.uniq(keys)
          keys = keys -- Map.get(options, :exclude, [])
          keys
      end

    quote bind_quoted: [keys: Macro.escape(keys)] do
      result =
        for key <- keys,
            value = Map.get(record, key),
            not is_struct(value, Ash.NotLoaded),
            not is_struct(value, Ash.ForbiddenField) do
          {key, value}
        end
    end
  end

  def make_steps(dsl) do
    for step <- Spark.Dsl.Transformer.get_entities(dsl, [:jason]),
        step_expression = make_step(step.type, step.input) do
      step_expression
    end
  end

  def make_step(:merge, values) do
    quote bind_quoted: [values: Macro.escape(values)] do
      result =
        for tuple <- values, {key, value} = tuple, reduce: result do result ->
          List.keystore(result, key, 0, tuple)
        end
    end
  end

  def make_step(:rename, renames) when is_list(renames) do
    quote bind_quoted: [renames: Macro.escape(renames)] do
      result =
        for {key, value} <- result do
          {List.keyfind(renames, key, 0, {key, key}) |> elem(1), value}
        end
    end
  end

  def make_step(:rename, renames) when is_map(renames) do
    quote bind_quoted: [renames: Macro.escape(renames)] do
      result =
        for {key, value} <- result do
          {Map.get(renames, key, key), value}
        end
    end
  end

  def make_step(:rename, fun) when is_function(fun, 1) do
    quote bind_quoted: [fun: Macro.escape(fun)] do
      result =
        for {key, value} <- result do
          {fun.(key), value}
        end
    end
  end

  def make_step(:order, false) do
    nil
  end

  def make_step(:order, true) do
    quote do
      result = Enum.sort(result)
    end
  end

  def make_step(:order, fun) when is_function(fun, 1) do
    quote bind_quoted: [fun: Macro.escape(fun)] do
      result = result |> Enum.map(&elem(&1, 0)) |> fun.() |> Enum.map(&{&1, List.keyfind!(result, &1, 0) |> elem(1)})
    end
  end

  def make_step(:order, keys) when is_list(keys) do
    quote bind_quoted: [keys: Macro.escape(keys)] do
      result = for key <- keys, tuple = List.keyfind(result, key, 0), do: tuple
    end
  end

  def make_step(:customize, fun) do
    quote bind_quoted: [fun: Macro.escape(fun)] do
      result = fun.(result, record)
    end
  end
end
