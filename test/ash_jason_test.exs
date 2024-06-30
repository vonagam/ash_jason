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
          attribute :x, :integer, public?: true
          attribute :y, :integer
          attribute :z, :integer, public?: true, sensitive?: true
          attribute :w, :integer, sensitive?: true
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
      assert encode!(%Default{id: @id, x: 1}) == "{\"id\":\"#{@id}\",\"x\":1}"
    end

    test "omits nil fields" do
      assert encode!(%Default{id: @id, x: nil}) == "{\"id\":\"#{@id}\"}"
    end

    test "omits not loaded fields" do
      assert encode!(%Default{id: @id, x: %Ash.NotLoaded{}}) == "{\"id\":\"#{@id}\"}"
    end

    test "omits forbidden fields" do
      assert encode!(%Default{id: @id, x: %Ash.ForbiddenField{}}) == "{\"id\":\"#{@id}\"}"
    end

    test "omits private fields" do
      assert encode!(%Default{id: @id, y: 1}) == "{\"id\":\"#{@id}\"}"
    end

    test "omits sensitive fields" do
      assert encode!(%Default{id: @id, z: 1}) == "{\"id\":\"#{@id}\"}"
    end

    test "omits unknown fields" do
      assert encode!(%Default{id: @id} |> Map.put(:a, 1)) == "{\"id\":\"#{@id}\"}"
    end
  end

  describe "`pick` option" do
    defresource WithPickList do
      jason do
        pick [:y, :z]
      end
    end

    test "replaces default pick if a list is provided" do
      assert encode!(%WithPickList{id: @id, x: 1, y: 1, z: 1, w: 1}) == "{\"y\":1,\"z\":1}"
    end

    defresource WithPickPrivate do
      jason do
        pick %{private?: true}
      end
    end

    test "adds private fields if `private?` is true" do
      assert encode!(%WithPickPrivate{id: @id, x: 1, y: 1, z: 1, w: 1}) == "{\"id\":\"#{@id}\",\"y\":1,\"x\":1}"
    end

    defresource WithPickSensitive do
      jason do
        pick %{sensitive?: true}
      end
    end

    test "adds sensitive fields if `sensitive?` is true" do
      assert encode!(%WithPickSensitive{id: @id, x: 1, y: 1, z: 1, w: 1}) == "{\"id\":\"#{@id}\",\"x\":1,\"z\":1}"
    end

    defresource WithPickAll do
      jason do
        pick %{private?: true, sensitive?: true}
      end
    end

    test "adds all fields if `private?` and `sensitive?` are true" do
      assert encode!(%WithPickAll{id: @id, x: 1, y: 1, z: 1, w: 1}) ==
               "{\"id\":\"#{@id}\",\"w\":1,\"y\":1,\"x\":1,\"z\":1}"
    end

    defresource WithPickInclude do
      jason do
        pick %{include: [:y]}
      end
    end

    test "adds fields specified in `include`" do
      assert encode!(%WithPickInclude{id: @id, x: 1, y: 1, z: 1, w: 1}) == "{\"id\":\"#{@id}\",\"y\":1,\"x\":1}"
    end

    defresource WithPickExclude do
      jason do
        pick %{exclude: [:x]}
      end
    end

    test "removes fields specified in `exclude`" do
      assert encode!(%WithPickExclude{id: @id, x: 1, y: 1, z: 1, w: 1}) == "{\"id\":\"#{@id}\"}"
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
