defmodule AshJason.Test.Macros do
  defmacro defresource(name, block) do
    quote do
      defmodule unquote(name) do
        use Ash.Resource,
          validate_api_inclusion?: false,
          data_layer: Ash.DataLayer.Ets,
          extensions: [AshJason.Extension]

        attributes do
          uuid_primary_key :id, writable?: true
          attribute :x, :integer
          attribute :y, :integer, private?: true
        end

        actions do
          defaults [:read, :create]
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

  defmodule Api do
    use Ash.Api,
      validate_config_inclusion?: false

    resources do
      allow_unregistered? true
    end
  end

  describe "by default" do
    defresource Default do
    end

    test "encodes public fields" do
      assert encode!(%Default{id: @id, x: 1}) == "{\"id\":\"#{@id}\",\"x\":1}"
    end

    test "omits nil fields" do
      assert encode!(%Default{id: @id, x: nil}) == "{\"id\":\"#{@id}\"}"
    end

    test "omits not loaded fields" do
      assert encode!(%Default{id: @id, x: %Ash.NotLoaded{}}) == "{\"id\":\"#{@id}\"}"
    end

    test "omits private fields" do
      assert encode!(%Default{id: @id, x: 1, y: 1}) == "{\"id\":\"#{@id}\",\"x\":1}"
    end

    test "omits unknown fields" do
      assert encode!(%Default{id: @id, x: 1} |> Map.put(:a, 1)) == "{\"id\":\"#{@id}\",\"x\":1}"
    end
  end

  describe "`fields` option" do
    defresource WithFields do
      jason do
        fields [:y]
      end
    end

    test "replaces default pick" do
      assert encode!(%WithFields{id: @id, x: 1, y: 1}) == "{\"y\":1}"
    end
  end

  describe "`pick` option" do
    defresource WithPick do
      jason do
        pick [:y]
      end
    end

    test "modifies default pick" do
      assert encode!(%WithPick{id: @id, x: 1, y: 1}) == "{\"id\":\"#{@id}\",\"y\":1,\"x\":1}"
    end
  end

  describe "`omit` option" do
    defresource WithOmit do
      jason do
        omit [:x]
      end
    end

    test "modifies default pick" do
      assert encode!(%WithOmit{id: @id, x: 1, y: 1}) == "{\"id\":\"#{@id}\"}"
    end
  end

  describe "`merge` option" do
    defresource WithMerge do
      jason do
        merge %{m: 1}
      end
    end

    test "merges specified map into json" do
      assert encode!(%WithMerge{id: @id, x: 1, y: 1}) == "{\"id\":\"#{@id}\",\"m\":1,\"x\":1}"
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
      assert encode!(%WithCustomize{id: @id, x: 1, y: 1}) == "{\"id\":\"#{@id}\",\"c\":1,\"x\":1}"
    end
  end
end
