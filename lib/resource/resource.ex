defmodule AshJason.Resource do
  @moduledoc """
  `Ash.Resource` extension for implementing `Jason.Encoder` protocol.
  """

  use Spark.Dsl.Extension,
    sections: [AshJason.ExtensionHelpers.jason_section(Ash.Resource)],
    transformers: [AshJason.Resource.Transformer]
end
