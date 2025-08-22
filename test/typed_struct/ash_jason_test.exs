defmodule AshJason.Test.TypedStruct.Macros do
  defmacro deftypedstruct(name, block) do
    quote do
      defmodule unquote(name) do
        use Ash.TypedStruct,
          extensions: [AshJason.TypedStruct]

        typed_struct do
          field(:id, :uuid)

          field(:i, :integer)
          field(:j, :integer)
          field(:k, :integer)
        end

        unquote(block)
      end
    end
  end
end

defmodule AshJason.Test.TypedStruct do
  use ExUnit.Case
  import Jason, only: [encode!: 1]
  import AshJason.Test.TypedStruct.Macros

  @id "8a94dbb1-9b64-4884-886e-710f87e56487"

  describe "by default" do
    deftypedstruct Default do
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

    test "omits unknown fields" do
      assert encode!(%Default{id: @id} |> Map.put(:a, 1)) == "{\"id\":\"#{@id}\"}"
    end
  end

  describe "`pick` option" do
    deftypedstruct WithPickList do
      jason do
        pick [:j, :k]
      end
    end

    test "replaces default pick if a list is provided" do
      assert encode!(%WithPickList{id: @id, j: 2, k: 3}) == "{\"j\":2,\"k\":3}"
    end

    deftypedstruct WithPickExclude do
      jason do
        pick %{exclude: [:k]}
      end
    end

    test "removes fields specified in `exclude`" do
      assert encode!(%WithPickExclude{id: @id, k: 1}) == "{\"id\":\"#{@id}\"}"
    end
  end

  describe "`merge` option" do
    deftypedstruct WithMerge do
      jason do
        merge %{m: 10}
      end
    end

    test "merges specified map into json" do
      assert encode!(%WithMerge{id: @id, k: 1}) == "{\"id\":\"#{@id}\",\"k\":1,\"m\":10}"
    end
  end

  describe "`customize` option" do
    deftypedstruct WithCustomize do
      jason do
        customize fn result, _record ->
          result |> List.keystore(:c, 0, {:c, 10})
        end
      end
    end

    test "modifies resulted map" do
      assert encode!(%WithCustomize{id: @id, k: 1}) == "{\"id\":\"#{@id}\",\"k\":1,\"c\":10}"
    end
  end

  describe "`order` option" do
    deftypedstruct WithOrderTrue do
      jason do
        order true
      end
    end

    test "orders keys using default sort if true" do
      assert encode!(%WithOrderTrue{id: @id, k: 1, i: 1, j: 1}) == "{\"i\":1,\"id\":\"#{@id}\",\"j\":1,\"k\":1}"
    end

    deftypedstruct WithOrderFun do
      jason do
        order fn keys ->
          Enum.sort(keys, :desc)
        end
      end
    end

    test "orders keys using a function to sort if a function" do
      assert encode!(%WithOrderFun{id: @id, k: 1, i: 1, j: 1}) == "{\"k\":1,\"j\":1,\"id\":\"#{@id}\",\"i\":1}"
    end

    deftypedstruct WithOrderList do
      jason do
        order [:id, :z, :x, :k, :i]
      end
    end

    test "orders and limits keys according to a list if a list" do
      assert encode!(%WithOrderList{id: @id, i: 1, j: 1, k: 1}) ==
               "{\"id\":\"#{@id}\",\"k\":1,\"i\":1}"
    end
  end

  describe "`rename` option" do
    deftypedstruct WithRenameMap do
      jason do
        rename %{i: :I, j: "✅", k: "@type"}
      end
    end

    test "renames keys if a map is provided" do
      assert encode!(%WithRenameMap{id: @id, i: 1, j: 2, k: 3}) == "{\"id\":\"#{@id}\",\"I\":1,\"✅\":2,\"@type\":3}"
    end

    deftypedstruct WithRenameKeyword do
      jason do
        rename i: :I, j: "✅", k: "@type"
      end
    end

    test "renames keys if a keyword list is provided" do
      assert encode!(%WithRenameKeyword{id: @id, i: 1, j: 2, k: 3}) == "{\"id\":\"#{@id}\",\"I\":1,\"✅\":2,\"@type\":3}"
    end

    deftypedstruct WithRenameFun do
      jason do
        rename &String.capitalize(to_string(&1))
      end
    end

    test "renames keys if a function" do
      assert encode!(%WithRenameFun{id: @id, i: 1, j: 2, k: 3}) == "{\"Id\":\"#{@id}\",\"I\":1,\"J\":2,\"K\":3}"
    end
  end

  describe "all options" do
    deftypedstruct WithAll do
      jason do
        merge %{"@type" => "survey"}
        rename j: "✅"
        customize fn result, _record -> List.keystore(result, "❌", 0, {"❌", 10}) end
        order [:id, "✅", "❌", "@type"]
      end
    end

    test "all options with non-atom keys" do
      assert encode!(%WithAll{id: @id, j: 1, k: 2}) ==
               "{\"id\":\"#{@id}\",\"✅\":1,\"❌\":10,\"@type\":\"survey\"}"
    end
  end
end
