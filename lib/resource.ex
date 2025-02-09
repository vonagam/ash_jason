defmodule AshJason.Resource do
  @moduledoc """
  Ash resource extension for implementing `Jason.Encoder` protocol.
  """

  @tuples_list {:list, {:tuple, [:any, :any]}}
  @tuples_enumerable {:or, [{:map, :any, :any}, @tuples_list]}

  @merge %Spark.Dsl.Entity{
    name: :merge,
    target: AshJason.Transformer.Step,
    auto_set_fields: [type: :merge],
    args: [:values],
    schema: [
      values: [
        type: @tuples_enumerable,
        as: :value,
        required: true,
        doc: "Values to merge into a result. An enumerable (map or list) of key-value tuples.",
      ],
    ],
    describe: "A step to merge fixed values into a result."
  }

  @rename %Spark.Dsl.Entity{
    name: :rename,
    target: AshJason.Transformer.Step,
    auto_set_fields: [type: :rename],
    args: [:renames],
    schema: [
      renames: [
        type: @tuples_enumerable,
        as: :value,
        required: true,
        doc: "A mapping for renaming keys in a result. An enumerable (map or list) of key-value tuples.",
      ],
    ],
    describe: "A step to rename keys in a result."
  }

  @order %Spark.Dsl.Entity{
    name: :order,
    target: AshJason.Transformer.Step,
    auto_set_fields: [type: :order],
    args: [:sort],
    schema: [
      sort: [
        type: {:or, [:boolean, {:fun, [{:list, :any}], {:list, :any}}, {:list, :any}]},
        as: :value,
        required: true,
        doc: "An order to apply to keys in json. A boolean, a sort function or a list of keys in a desired order.",
      ],
    ],
    describe: "A step to order keys in a result."
  }

  @customize %Spark.Dsl.Entity{
    name: :customize,
    target: AshJason.Transformer.Step,
    auto_set_fields: [type: :customize],
    args: [:fun],
    schema: [
      fun: [
        type: {:fun, [@tuples_list, :map], @tuples_list},
        as: :value,
        required: true,
        doc: "A function to customize a result with. Receives a result and a resource record.",
      ],
    ],
    describe: "A step to arbitrary customize a result."
  }

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
        doc: "Keys to pick from a record into a result. An explicit names list or a behaviour configuration map.",
      ],
    ],
    entities: [
      @merge,
      @rename,
      @order,
      @customize,
    ],
  }

  use Spark.Dsl.Extension,
    sections: [@jason],
    transformers: [AshJason.Transformer]
end
