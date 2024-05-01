defmodule AshJason.Extension do
  @jason %Spark.Dsl.Section{
    name: :jason,
    describe: "Configuration for Jason encoder implementation",
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
        doc: "Keys to pick from a record into json. Either an explicit names list or a behaviour configuration map.",
      ],
      merge: [
        type: :map,
        doc: "A map to merge into json.",
      ],
      customize: [
        type: {:fun, 2},
        doc: "A function to customize json. Receives a current result and a resource record.",
      ],
    ],
  }

  use Spark.Dsl.Extension,
    sections: [@jason],
    transformers: [AshJason.Transformer]
end
