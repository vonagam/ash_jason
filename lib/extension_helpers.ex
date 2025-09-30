defmodule AshJason.ExtensionHelpers do
  @moduledoc false

  def jason_section(target) do
    tuples_list = {:list, {:tuple, [:any, :any]}}
    tuples_map = {:map, :any, :any}

    compact_entity = %Spark.Dsl.Entity{
      name: :compact,
      describe: """
        A step to omit fields with unwanted values (nil, for example).
      """,
      target: AshJason.TransformerHelpers.Step,
      auto_set_fields: [type: :compact],
      args: [:config],
      schema: [
        config: [
          doc: """
            Accepts `true` to remove any field with nil, a tagged `only`/`except` tuple to specify targeted fields or a map to configure which value or fields to work on.
          """,
          type: {
            :or,
            [
              :boolean,
              {:tagged_tuple, :only, {:list, :atom}},
              {:tagged_tuple, :except, {:list, :atom}},
              {:map,
               [
                 values: [
                   doc: """
                     List of values that are unwanted in the result. By default removes only nil.
                   """,
                   type: {:list, :any},
                 ],
                 fields: [
                   doc: """
                     Tagged `only`/`except` tuple to specify which fields to apply to. By default applies to all.
                   """,
                   type: {:or, [{:tagged_tuple, :only, {:list, :atom}}, {:tagged_tuple, :except, {:list, :atom}}]},
                 ],
               ]},
            ]
          },
          as: :input,
          required: true,
        ],
      ],
    }

    merge_entity = %Spark.Dsl.Entity{
      name: :merge,
      describe: """
        A step to merge fixed values into a result.
      """,
      target: AshJason.TransformerHelpers.Step,
      auto_set_fields: [type: :merge],
      args: [:values],
      schema: [
        values: [
          doc: """
            Values to merge into a result. Accepts a map or a tuples list.
          """,
          type: {:or, [tuples_list, tuples_map]},
          as: :input,
          required: true,
        ],
      ],
    }

    rename_entity = %Spark.Dsl.Entity{
      name: :rename,
      describe: """
        A step to rename keys in a result.
      """,
      target: AshJason.TransformerHelpers.Step,
      auto_set_fields: [type: :rename],
      args: [:renames],
      schema: [
        renames: [
          doc: """
            A mapping for renaming keys in a result. Accepts a map, a tuples list or a function.
          """,
          type: {:or, [tuples_list, tuples_map, {:fun, [:any], :any}]},
          as: :input,
          required: true,
        ],
      ],
    }

    order_entity = %Spark.Dsl.Entity{
      name: :order,
      describe: """
        A step to reorder keys in a result.
      """,
      target: AshJason.TransformerHelpers.Step,
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

    customize_entity = %Spark.Dsl.Entity{
      name: :customize,
      describe: """
        A step to arbitrary customize a result.
      """,
      target: AshJason.TransformerHelpers.Step,
      auto_set_fields: [type: :customize],
      args: [:fun],
      schema: [
        fun: [
          doc: """
            A function to customize a result with. Receives a result and a resource record.
          """,
          type: {:fun, [tuples_list, :map], tuples_list},
          as: :input,
          required: true,
        ],
      ],
    }

    pick_options =
      [
        private?: [
          doc: """
            Whenever to pick private fields.
          """,
          type: :boolean,
          default: false,
        ],
        sensitive?: [
          doc: """
            Whenever to pick sensitive fields.
          """,
          type: :boolean,
          default: false,
        ],
        include: [
          doc: """
            Keys to pick. In addition to fields.
          """,
          type: {:list, :atom},
        ],
        exclude: [
          doc: """
            Keys not to pick.
          """,
          type: {:list, :atom},
        ],
      ]

    pick_options =
      if target == Ash.TypedStruct do
        Keyword.take(pick_options, [:include, :exclude])
      else
        pick_options
      end

    jason_section = %Spark.Dsl.Section{
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
               {:map, pick_options},
             ]},
        ],
      ],
      entities: [
        compact_entity,
        merge_entity,
        rename_entity,
        order_entity,
        customize_entity,
      ],
    }

    jason_section
  end
end
