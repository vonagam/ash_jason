defmodule AshJason.Resource.Transformer do
  @moduledoc false

  use Spark.Dsl.Transformer

  @impl true
  def transform(dsl) do
    AshJason.TransformerHelpers.transform(dsl, fn dsl, options ->
      fields = Ash.Resource.Info.fields(dsl)
      fields = if Map.get(options, :private?), do: fields, else: Enum.filter(fields, & &1.public?)
      fields = if Map.get(options, :sensitive?), do: fields, else: Enum.reject(fields, &Map.get(&1, :sensitive?))
      fields
    end)
  end
end
