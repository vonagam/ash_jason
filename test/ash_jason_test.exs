defmodule AshJason.Test.Macros do
  defmacro defresource(name, block) do
    quote do
      defmodule unquote(name) do
        use Ash.Resource,
          domain: nil,
          validate_domain_inclusion?: false,
          data_layer: Ash.DataLayer.Ets,
          extensions: [AshJason.Resource]

        attributes do
          uuid_primary_key :id, writable?: true

          attribute :i, :integer, public?: true
          attribute :j, :integer, public?: true
          attribute :k, :integer, public?: true

          attribute :x, :integer
          attribute :y, :integer, public?: true, sensitive?: true
          attribute :z, :integer, sensitive?: true

          attribute :b, :boolean, public?: true
        end

        unquote(block)
      end
    end
  end
end

defmodule AshJason.Test do
  use ExUnit.Case
  import Jason, only: [encode!: 1]
  import AshJason.Test.Macros

  @id "8a94dbb1-9b64-4884-886e-710f87e56487"

  describe "by default" do
    defresource Default do
    end

    test "encodes fields" do
      assert encode!(%Default{id: @id, k: 1}) == "{\"id\":\"#{@id}\",\"i\":null,\"j\":null,\"k\":1,\"b\":null}"
    end

    test "encodes boolean fields" do
      assert encode!(%Default{id: @id, b: false}) == "{\"id\":\"#{@id}\",\"i\":null,\"j\":null,\"k\":null,\"b\":false}"
    end

    test "does not omit nil fields" do
      assert encode!(%Default{id: @id, k: nil}) == "{\"id\":\"#{@id}\",\"i\":null,\"j\":null,\"k\":null,\"b\":null}"
    end

    test "omits not loaded fields" do
      assert encode!(%Default{id: @id, k: %Ash.NotLoaded{}}) == "{\"id\":\"#{@id}\",\"i\":null,\"j\":null,\"b\":null}"
    end

    test "omits forbidden fields" do
      assert encode!(%Default{id: @id, k: %Ash.ForbiddenField{}}) ==
               "{\"id\":\"#{@id}\",\"i\":null,\"j\":null,\"b\":null}"
    end

    test "omits private fields" do
      assert encode!(%Default{id: @id, x: 1}) == "{\"id\":\"#{@id}\",\"i\":null,\"j\":null,\"k\":null,\"b\":null}"
    end

    test "omits sensitive fields" do
      assert encode!(%Default{id: @id, y: 1}) == "{\"id\":\"#{@id}\",\"i\":null,\"j\":null,\"k\":null,\"b\":null}"
    end

    test "omits unknown fields" do
      assert encode!(%Default{id: @id} |> Map.put(:a, 1)) ==
               "{\"id\":\"#{@id}\",\"i\":null,\"j\":null,\"k\":null,\"b\":null}"
    end
  end

  describe "`pick` option" do
    defresource WithPickList do
      jason do
        compact true
        pick [:x, :y]
      end
    end

    test "replaces default pick if a list is provided" do
      assert encode!(%WithPickList{id: @id, k: 1, x: 2, y: 3, z: 4}) == "{\"x\":2,\"y\":3}"
    end

    defresource WithPickPrivate do
      jason do
        compact true
        pick %{private?: true}
      end
    end

    test "adds private fields if `private?` is true" do
      assert encode!(%WithPickPrivate{id: @id, k: 1, x: 2, y: 3, z: 4}) == "{\"id\":\"#{@id}\",\"k\":1,\"x\":2}"
    end

    defresource WithPickSensitive do
      jason do
        compact true
        pick %{sensitive?: true}
      end
    end

    test "adds sensitive fields if `sensitive?` is true" do
      assert encode!(%WithPickSensitive{id: @id, k: 1, x: 2, y: 3, z: 4}) == "{\"id\":\"#{@id}\",\"k\":1,\"y\":3}"
    end

    defresource WithPickAll do
      jason do
        compact true
        pick %{private?: true, sensitive?: true}
      end
    end

    test "adds all fields if `private?` and `sensitive?` are true" do
      assert encode!(%WithPickAll{id: @id, k: 1, x: 2, y: 3, z: 4}) ==
               "{\"id\":\"#{@id}\",\"k\":1,\"x\":2,\"y\":3,\"z\":4}"
    end

    defresource WithPickInclude do
      jason do
        compact true
        pick %{include: [:x]}
      end
    end

    test "adds fields specified in `include`" do
      assert encode!(%WithPickInclude{id: @id, k: 1, x: 2, y: 3, z: 4}) == "{\"id\":\"#{@id}\",\"k\":1,\"x\":2}"
    end

    defresource WithPickExclude do
      jason do
        compact true
        pick %{exclude: [:k]}
      end
    end

    test "removes fields specified in `exclude`" do
      assert encode!(%WithPickExclude{id: @id, k: 1, x: 2, y: 3, z: 4}) == "{\"id\":\"#{@id}\"}"
    end
  end

  describe "`compact` option" do
    defresource WithCompactTrue do
      jason do
        compact true
      end
    end

    test "removes nil values" do
      assert encode!(%WithCompactTrue{id: @id, k: nil, x: nil}) == "{\"id\":\"#{@id}\"}"
    end

    defresource WithCompactValues do
      jason do
        compact %{values: [1]}
      end
    end

    test "removes only specified values" do
      assert encode!(%WithCompactValues{id: @id, i: 1, j: 2}) == "{\"id\":\"#{@id}\",\"j\":2,\"k\":null,\"b\":null}"
    end

    defresource WithCompactOnlyFields do
      jason do
        compact %{fields: {:only, [:i, :j]}}
      end
    end

    test "checks only specified fields when `only` tuple is used" do
      assert encode!(%WithCompactOnlyFields{id: @id}) == "{\"id\":\"#{@id}\",\"k\":null,\"b\":null}"
    end

    defresource WithCompactExceptFields do
      jason do
        compact %{fields: {:except, [:j]}}
      end
    end

    test "checks all except specified fields when `except` tuple is used" do
      assert encode!(%WithCompactExceptFields{id: @id}) == "{\"id\":\"#{@id}\",\"j\":null}"
    end

    defresource WithCompactExceptShortFields do
      jason do
        compact {:except, [:j]}
      end
    end

    test "checks all except specified fields when `except` tuple is used in short form" do
      assert encode!(%WithCompactExceptShortFields{id: @id}) == "{\"id\":\"#{@id}\",\"j\":null}"
    end

    defresource WithCompactValuesFields do
      jason do
        compact %{values: [1, 2], fields: {:except, [:j]}}
      end
    end

    test "works with both `values` and `fields` options provided" do
      assert encode!(%WithCompactValuesFields{id: @id, i: 1, j: 1, k: 1}) == "{\"id\":\"#{@id}\",\"j\":1,\"b\":null}"
    end
  end

  describe "`merge` option" do
    defresource WithMerge do
      jason do
        compact true
        merge %{m: 10}
      end
    end

    test "merges specified map into json" do
      assert encode!(%WithMerge{id: @id, k: 1, x: 2}) == "{\"id\":\"#{@id}\",\"k\":1,\"m\":10}"
    end
  end

  describe "`customize` option" do
    defresource WithCustomize do
      jason do
        compact true

        customize fn result, _record ->
          result |> List.keystore(:c, 0, {:c, 10})
        end
      end
    end

    test "modifies resulted map" do
      assert encode!(%WithCustomize{id: @id, k: 1, x: 2}) == "{\"id\":\"#{@id}\",\"k\":1,\"c\":10}"
    end
  end

  describe "`order` option" do
    defresource WithOrderTrue do
      jason do
        compact true
        order true
      end
    end

    test "orders keys using default sort if true" do
      assert encode!(%WithOrderTrue{id: @id, k: 1, i: 1, j: 1}) == "{\"i\":1,\"id\":\"#{@id}\",\"j\":1,\"k\":1}"
    end

    defresource WithOrderFun do
      jason do
        compact true

        order fn keys ->
          Enum.sort(keys, :desc)
        end
      end
    end

    test "orders keys using a function to sort if a function" do
      assert encode!(%WithOrderFun{id: @id, k: 1, i: 1, j: 1}) == "{\"k\":1,\"j\":1,\"id\":\"#{@id}\",\"i\":1}"
    end

    defresource WithOrderList do
      jason do
        compact true
        pick %{private?: true, sensitive?: true}
        order [:id, :z, :x, :k, :i]
      end
    end

    test "orders and limits keys according to a list if a list" do
      assert encode!(%WithOrderList{id: @id, i: 1, j: 1, k: 1, x: 1, y: 1, z: 1}) ==
               "{\"id\":\"#{@id}\",\"z\":1,\"x\":1,\"k\":1,\"i\":1}"
    end
  end

  describe "`rename` option" do
    defresource WithRenameMap do
      jason do
        compact true
        rename %{i: :I, j: "✅", k: "@type"}
      end
    end

    test "renames keys if a map is provided" do
      assert encode!(%WithRenameMap{id: @id, i: 1, j: 2, k: 3}) == "{\"id\":\"#{@id}\",\"I\":1,\"✅\":2,\"@type\":3}"
    end

    defresource WithRenameKeyword do
      jason do
        compact true
        rename i: :I, j: "✅", k: "@type"
      end
    end

    test "renames keys if a keyword list is provided" do
      assert encode!(%WithRenameKeyword{id: @id, i: 1, j: 2, k: 3}) == "{\"id\":\"#{@id}\",\"I\":1,\"✅\":2,\"@type\":3}"
    end

    defresource WithRenameFun do
      jason do
        compact true
        rename &String.capitalize(to_string(&1))
      end
    end

    test "renames keys if a function" do
      assert encode!(%WithRenameFun{id: @id, i: 1, j: 2, k: 3}) == "{\"Id\":\"#{@id}\",\"I\":1,\"J\":2,\"K\":3}"
    end
  end

  describe "all options" do
    defresource WithAll do
      jason do
        compact true
        pick %{private?: true, sensitive?: true}
        merge %{"@type" => "survey"}
        rename j: "✅"
        customize fn result, _record -> List.keystore(result, "❌", 0, {"❌", 10}) end
        order [:id, :z, :y, "✅", "❌", "@type"]
      end
    end

    test "all options with non-atom keys" do
      assert encode!(%WithAll{id: @id, j: 1, k: 2, y: 3, z: 4}) ==
               "{\"id\":\"#{@id}\",\"z\":4,\"y\":3,\"✅\":1,\"❌\":10,\"@type\":\"survey\"}"
    end
  end
end
