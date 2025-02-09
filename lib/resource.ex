defmodule AshJason.Resource do
  @moduledoc """
  Ash resource extension for implementing `Jason.Encoder` protocol.
  """

  @atom_or_string {:or, [:atom, :string]}
  @keyword_list_or_map {:or, [:keyword_list, :map]}
  @map_string_or_atom_keys {:map, @atom_or_string, :any}

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
        doc: "Atom keys to pick from a record into json. An explicit names list or a behaviour configuration map.",
      ],
      merge: [
        type: @map_string_or_atom_keys,
        doc: "A map to merge into json, may contain string or atom keys.",
      ],
      rename: [
        type: @keyword_list_or_map,
        doc: "A mapping for renaming atom keys in json to string or atom. Can be a map or a keyword list.",
      ],
      customize: [
        type: {:fun, [:map, :map], :map},
        doc: "A function to customize json. Receives a current result and a resource record.",
      ],
      order: [
        type: {:or, [:boolean, {:fun, [{:list, @atom_or_string}], {:list, @atom_or_string}}, {:list, @atom_or_string}]},
        doc: "An order to apply to atom or string keys in json. A boolean, a sort function or a list of keys in a desired order.",
      ],
    ],
  }

  use Spark.Dsl.Extension,
    sections: [@jason],
    transformers: [AshJason.Transformer]
end
