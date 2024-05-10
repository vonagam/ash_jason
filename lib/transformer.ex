defmodule AshJason.Transformer do
  @moduledoc false

  use Spark.Dsl.Transformer

  def transform(dsl) do
    pick =
      case Spark.Dsl.Transformer.get_option(dsl, [:jason], :pick, %{}) do
        keys when is_list(keys) ->
          keys

        options when is_map(options) ->
          fields = dsl |> Ash.Resource.Info.fields()
          fields = if Map.get(options, :private?), do: fields, else: fields |> Enum.filter(& &1.public?)
          fields = if Map.get(options, :sensitive?), do: fields, else: fields |> Enum.reject(&Map.get(&1, :sensitive?))
          keys = fields |> Enum.map(& &1.name)
          keys = keys ++ Map.get(options, :include, [])
          keys = keys |> Enum.uniq()
          keys = keys -- Map.get(options, :exclude, [])
          keys
      end

    merge = Spark.Dsl.Transformer.get_option(dsl, [:jason], :merge, %{})
    customize = Spark.Dsl.Transformer.get_option(dsl, [:jason], :customize, &AshJason.Transformer.default_customize/2)

    defimpl Jason.Encoder, for: dsl.persist.module do
      @pick pick
      @merge merge
      @customize customize

      def encode(record, opts) do
        result = %{}

        result =
          for key <- @pick, reduce: result do result ->
            case Map.get(record, key) do
              nil -> result
              %Ash.NotLoaded{} -> result
              value -> Map.put(result, key, value)
            end
          end

        result = Map.merge(result, @merge)
        result = @customize.(result, record)

        Jason.Encode.map(result, opts)
      end
    end

    :ok
  end

  def default_customize(result, _record), do: result
end
