defmodule AshJason.Resource do
  @moduledoc """
  Ash resource extension for implementing `Jason.Encoder` protocol.
  """

  @jason %Spark.Dsl.Section{
    name: :jason,
    describe: "Configuration for Jason encoder implementation.",
    schema: [
      pick: [
        type:
          {:or,
           [
             {:list, :atom},
             {:map,
              [
                private?: [
                  type: :boolean,
                  default: false,
                  doc: "Whenever to pick private fields.",
                ],
                sensitive?: [
                  type: :boolean,
                  default: false,
                  doc: "Whenever to pick sensitive fields.",
                ],
                include: [
                  type: {:list, :atom},
                  doc: "Keys to pick. In addition to fields.",
                ],
                exclude: [
                  type: {:list, :atom},
                  doc: "Keys not to pick.",
                ],
              ]},
           ]},
        doc: "Keys to pick from a record into json. An explicit names list or a behaviour configuration map.",
      ],
      merge: [
        type: :map,
        doc: "A map to merge into json.",
      ],
      customize: [
        type: {:fun, [:map, :map], :map},
        doc: "A function to customize json. Receives a current result and a resource record.",
      ],
      order: [
        type: {:or, [:boolean, {:fun, [{:list, :atom}], {:list, :atom}}, {:list, :atom}]},
        doc: "An order to apply to keys in json. A boolean, a sort function or a list of keys in a desired order.",
      ],
      rename: [
        type: {:map, :atom, {:or, [:atom, :string]}},
        doc: "A map of key renamings",
      ]
    ],
  }

  use Spark.Dsl.Extension,
    sections: [@jason],
    transformers: [AshJason.Transformer]
end
