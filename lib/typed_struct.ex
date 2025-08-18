defmodule AshJason.TypedStruct do
  @moduledoc """
  Ash TypedStruct extension for implementing `Jason.Encoder` protocol.
  """

  @tuples_list {:list, {:tuple, [:any, :any]}}
  @tuples_map {:map, :any, :any}

  @merge %Spark.Dsl.Entity{
    name: :merge,
    describe: """
      A step to merge fixed values into a result.
    """,
    target: AshJason.Transformer.Step,
    auto_set_fields: [type: :merge],
    args: [:values],
    schema: [
      values: [
        doc: """
          Values to merge into a result. Accepts a map or a tuples list.
        """,
        type: {:or, [@tuples_list, @tuples_map]},
        as: :input,
        required: true,
      ],
    ],
  }

  @rename %Spark.Dsl.Entity{
    name: :rename,
    describe: """
      A step to rename keys in a result.
    """,
    target: AshJason.Transformer.Step,
    auto_set_fields: [type: :rename],
    args: [:renames],
    schema: [
      renames: [
        doc: """
          A mapping for renaming keys in a result. Accepts a map, a tuples list or a function.
        """,
        type: {:or, [@tuples_list, @tuples_map, {:fun, [:any], :any}]},
        as: :input,
        required: true,
      ],
    ],
  }

  @order %Spark.Dsl.Entity{
    name: :order,
    describe: """
      A step to reorder keys in a result.
    """,
    target: AshJason.Transformer.Step,
    auto_set_fields: [type: :order],
    args: [:sort],
    schema: [
      sort: [
        doc: """
          An order to apply to keys in json. Accepts a boolean, a sort function or a list of keys in a desired order.
        """,
        type: {:or, [:boolean, {:fun, [{:list, :any}], {:list, :any}}, {:list, :any}]},
        as: :input,
        required: true,
      ],
    ],
  }

  @customize %Spark.Dsl.Entity{
    name: :customize,
    describe: """
      A step to arbitrary customize a result.
    """,
    target: AshJason.Transformer.Step,
    auto_set_fields: [type: :customize],
    args: [:fun],
    schema: [
      fun: [
        doc: """
          A function to customize a result with. Receives a result and a typed struct record.
        """,
        type: {:fun, [@tuples_list, :map], @tuples_list},
        as: :input,
        required: true,
      ],
    ],
  }

  @jason %Spark.Dsl.Section{
    name: :jason,
    describe: """
      Configuration for Jason encoder implementation.
    """,
    schema: [
      pick: [
        doc: """
          Keys to pick from a record into a result. Accepts an explicit names list or a behaviour configuration map.
        """,
        type:
          {:or,
           [
             {:list, :atom},
             {:map,
              [
                exclude: [
                  doc: """
                    Keys not to pick.
                  """,
                  type: {:list, :atom},
                ],
              ]},
           ]},
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
    transformers: [AshJason.TypedStructTransformer]
end
