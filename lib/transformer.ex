defmodule AshJason.Transformer do
  use Spark.Dsl.Transformer

  def transform(dsl) do
    keys = dsl |> Ash.Resource.Info.fields() |> Enum.reject(&(&1.private? || &1.sensitive?)) |> Enum.map(& &1.name)
    keys = Spark.Dsl.Transformer.get_option(dsl, [:jason], :fields, keys)
    keys = keys ++ Spark.Dsl.Transformer.get_option(dsl, [:jason], :pick, [])
    keys = keys -- Spark.Dsl.Transformer.get_option(dsl, [:jason], :omit, [])

    merge = Spark.Dsl.Transformer.get_option(dsl, [:jason], :merge)
    customize = Spark.Dsl.Transformer.get_option(dsl, [:jason], :customize)

    defimpl Jason.Encoder, for: dsl.persist.module do
      @keys keys
      @merge merge
      @customize customize

      def encode(record, opts) do
        result = %{}

        result =
          for key <- @keys, reduce: result do result ->
            case Map.get(record, key) do
              nil -> result
              %Ash.NotLoaded{} -> result
              %Ash.NotSelected{} -> result
              value -> Map.put(result, key, value)
            end
          end

        result = if merge = @merge, do: Map.merge(result, merge), else: result
        result = if customize = @customize, do: customize.(result, record), else: result

        Jason.Encode.map(result, opts)
      end
    end

    :ok
  end
end
