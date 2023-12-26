defmodule AshJason.Extension do
  @jason %Spark.Dsl.Section{
    name: :jason,
    describe: "Configuration for Jason encoder implementation",
    schema: [
      fields: [
        type: {:list, :atom},
        doc: "Fields to pick from a record and include in json.",
      ],
      pick: [
        type: {:list, :atom},
        doc: "Keys to pick from a record (in addition to `fields`).",
      ],
      omit: [
        type: {:list, :atom},
        doc: "Keys to omit from a record (despite `fields`/`pick`).",
      ],
      merge: [
        type: :map,
        doc: "A map to merge into json.",
      ],
      customize: [
        type: {:fun, [:map, :map], :map},
        doc: "A function to customize json.",
      ],
    ],
  }

  use Spark.Dsl.Extension,
    sections: [@jason],
    transformers: [AshJason.Transformer]
end
