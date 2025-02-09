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
      assert encode!(%Default{id: @id, k: 1}) == "{\"id\":\"#{@id}\",\"k\":1}"
    end

    test "omits nil fields" do
      assert encode!(%Default{id: @id, k: nil}) == "{\"id\":\"#{@id}\"}"
    end

    test "omits not loaded fields" do
      assert encode!(%Default{id: @id, k: %Ash.NotLoaded{}}) == "{\"id\":\"#{@id}\"}"
    end

    test "omits forbidden fields" do
      assert encode!(%Default{id: @id, k: %Ash.ForbiddenField{}}) == "{\"id\":\"#{@id}\"}"
    end

    test "omits private fields" do
      assert encode!(%Default{id: @id, x: 1}) == "{\"id\":\"#{@id}\"}"
    end

    test "omits sensitive fields" do
      assert encode!(%Default{id: @id, y: 1}) == "{\"id\":\"#{@id}\"}"
    end

    test "omits unknown fields" do
      assert encode!(%Default{id: @id} |> Map.put(:a, 1)) == "{\"id\":\"#{@id}\"}"
    end
  end

  describe "`pick` option" do
    defresource WithPickList do
      jason do
        pick [:x, :y]
      end
    end

    test "replaces default pick if a list is provided" do
      assert encode!(%WithPickList{id: @id, k: 1, x: 1, y: 1, z: 1}) == "{\"y\":1,\"x\":1}"
    end

    defresource WithPickPrivate do
      jason do
        pick %{private?: true}
      end
    end

    test "adds private fields if `private?` is true" do
      assert encode!(%WithPickPrivate{id: @id, k: 1, x: 1, y: 1, z: 1}) == "{\"id\":\"#{@id}\",\"k\":1,\"x\":1}"
    end

    defresource WithPickSensitive do
      jason do
        pick %{sensitive?: true}
      end
    end

    test "adds sensitive fields if `sensitive?` is true" do
      assert encode!(%WithPickSensitive{id: @id, k: 1, x: 1, y: 1, z: 1}) == "{\"id\":\"#{@id}\",\"k\":1,\"y\":1}"
    end

    defresource WithPickAll do
      jason do
        pick %{private?: true, sensitive?: true}
      end
    end

    test "adds all fields if `private?` and `sensitive?` are true" do
      assert encode!(%WithPickAll{id: @id, k: 1, x: 1, y: 1, z: 1}) ==
               "{\"id\":\"#{@id}\",\"k\":1,\"y\":1,\"x\":1,\"z\":1}"
    end

    defresource WithPickInclude do
      jason do
        pick %{include: [:x]}
      end
    end

    test "adds fields specified in `include`" do
      assert encode!(%WithPickInclude{id: @id, k: 1, x: 1, y: 1, z: 1}) == "{\"id\":\"#{@id}\",\"k\":1,\"x\":1}"
    end

    defresource WithPickExclude do
      jason do
        pick %{exclude: [:k]}
      end
    end

    test "removes fields specified in `exclude`" do
      assert encode!(%WithPickExclude{id: @id, k: 1, x: 1, y: 1, z: 1}) == "{\"id\":\"#{@id}\"}"
    end
  end

  describe "`rename` option" do
    defresource WithRenameMap do
      jason do
        rename %{i: :I, j: "✅", k: "@type"}
      end
    end

    test "renames keys if a map is provided" do
      assert encode!(%WithRenameMap{id: @id, i: 1, j: 2, k: 3}) == "{\"id\":\"#{@id}\",\"I\":1,\"@type\":3,\"✅\":2}"
    end

    defresource WithRenameKeyword do
      jason do
        rename i: :I, j: "✅", k: "@type"
      end
    end

    test "renames keys if a keyword list is provided" do
      assert encode!(%WithRenameKeyword{id: @id, i: 1, j: 2, k: 3}) == "{\"id\":\"#{@id}\",\"I\":1,\"@type\":3,\"✅\":2}"
    end
  end

  describe "`merge` option" do
    defresource WithMergeMap do
      jason do
        merge %{m: 1, "@type": "survey"}
      end
    end

    test "merges specified map into json" do
      assert encode!(%WithMergeMap{id: @id, k: 1, x: 1}) == "{\"id\":\"#{@id}\",\"k\":1,\"m\":1,\"@type\":\"survey\"}"
    end
  end

  describe "`customize` option" do
    defresource WithCustomize do
      jason do
        customize fn result, _record ->
          result |> Map.put(:c, 1)
        end
      end
    end

    test "modifies resulted map" do
      assert encode!(%WithCustomize{id: @id, k: 1, x: 1}) == "{\"id\":\"#{@id}\",\"c\":1,\"k\":1}"
    end
  end

  describe "`order` option" do
    defresource WithOrderTrue do
      jason do
        order true
      end
    end

    test "orders keys using default sort if true" do
      assert encode!(%WithOrderTrue{id: @id, k: 1, i: 1, j: 1}) == "{\"i\":1,\"id\":\"#{@id}\",\"j\":1,\"k\":1}"
    end

    defresource WithOrderFun do
      jason do
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
        pick %{private?: true, sensitive?: true}
        order [:id, :z, :x, :k, :i]
      end
    end

    test "orders and limits keys according to a list if a list" do
      assert encode!(%WithOrderList{id: @id, i: 1, j: 1, k: 1, x: 1, y: 1, z: 1}) ==
               "{\"id\":\"#{@id}\",\"z\":1,\"x\":1,\"k\":1,\"i\":1}"
    end
  end

  describe "all options" do
    defresource WithAllOptions do
      jason do
        pick %{private?: true, sensitive?: true}
        merge %{"@type" => "survey"}
        rename %{:j => "✅"}
        customize fn result, _record ->
          result |> Map.put(:c, 1)|> Map.put("❌", 3)
        end
        order [:id, :c, :y, :z, "✅", "❌", "@type"]
      end
    end

    test "all options with non-atom keys" do
      assert encode!(%WithAllOptions{id: @id, y: 1, j: 2, k: 3, z: 4}) ==
               "{\"id\":\"#{@id}\",\"c\":1,\"y\":1,\"z\":4,\"✅\":2,\"❌\":3,\"@type\":\"survey\"}"
    end
  end
end
