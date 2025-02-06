defmodule AshJason.Transformer do
  @moduledoc false

  use Spark.Dsl.Transformer

  def transform(dsl) do
    defimpl Jason.Encoder, for: dsl.persist.module do
      @pick AshJason.Transformer.get_pick(dsl)
      @merge AshJason.Transformer.get_merge(dsl)
      @customize AshJason.Transformer.get_customize(dsl)
      @order AshJason.Transformer.get_order(dsl)
      @rename AshJason.Transformer.get_rename(dsl)

      def encode(record, opts) do
        record
        |> AshJason.Transformer.do_pick(@pick)
        |> AshJason.Transformer.do_merge(@merge)
        |> AshJason.Transformer.do_customize(@customize, record)
        |> AshJason.Transformer.do_order(@order)
        |> AshJason.Transformer.do_rename(@rename)
        |> AshJason.Transformer.encode(opts)
      end
    end

    :ok
  end

  def get_pick(dsl) do
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
  end

  def get_merge(dsl) do
    Spark.Dsl.Transformer.get_option(dsl, [:jason], :merge, %{})
  end

  def get_customize(dsl) do
    Spark.Dsl.Transformer.get_option(dsl, [:jason], :customize, &AshJason.Transformer.customize_noop/2)
  end

  def customize_noop(result, _record) do
    result
  end

  def get_order(dsl) do
    Spark.Dsl.Transformer.get_option(dsl, [:jason], :order, false)
  end

  def get_rename(dsl) do
    Spark.Dsl.Transformer.get_option(dsl, [:jason], :rename, nil)
  end

  def do_pick(record, pick) do
    for key <- pick, reduce: %{} do map ->
      case Map.get(record, key) do
        nil -> map
        %Ash.NotLoaded{} -> map
        %Ash.ForbiddenField{} -> map
        value -> Map.put(map, key, value)
      end
    end
  end

  def do_merge(map, merge) do
    Map.merge(map, merge)
  end

  def do_customize(map, customize, record) do
    customize.(map, record)
  end

  def do_order(map, order) do
    case order do
      false ->
        map |> Map.to_list()

      true ->
        map |> Enum.sort()

      fun when is_function(fun, 1) ->
        map |> Map.keys() |> fun.() |> Enum.map(&{&1, map[&1]})

      keys when is_list(keys) ->
        keys |> Enum.filter(&Map.has_key?(map, &1)) |> Enum.map(&{&1, map[&1]})
    end
  end

  def do_rename(list, rename) do
    case rename do
      renamings when is_map(renamings) ->
        Jason.OrderedObject.new(
          list
          |> Enum.into([],
            fn {key, value} ->
              if Map.has_key?(renamings, key) do
                {Map.get(renamings, key), value}
              else
                {key, value}
              end
            end)
        )
      nil ->
        list
    end
  end

  def encode(input, opts) do
    if (Keyword.keyword?(input)) do
      Jason.Encode.keyword(input, opts)
    else
      Jason.Encode.struct(input, opts)
    end
  end
end
