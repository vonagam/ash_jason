defmodule AshJason.TypedStruct do
  @moduledoc """
  `Ash.TypedStruct` extension for implementing `Jason.Encoder` protocol.
  """

  use Spark.Dsl.Extension,
    sections: [AshJason.ExtensionHelpers.jason_section(Ash.TypedStruct)],
    transformers: [AshJason.TypedStruct.Transformer]
end
