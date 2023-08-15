defmodule Ash.Test.Type.UnionTest do
  @moduledoc false
  use ExUnit.Case, async: true

  defmodule Foo do
    use Ash.Resource, data_layer: :embedded

    attributes do
      attribute :foo, :string, constraints: [match: ~r/foo/]

      attribute :type, :string do
        writable? false
        default "foo"
      end
    end
  end

  defmodule Bar do
    use Ash.Resource, data_layer: :embedded

    attributes do
      attribute :bar, :string, constraints: [match: ~r/bar/]

      attribute :type, :string do
        writable? false
        default "bar"
      end
    end
  end

  test "it handles simple types" do
    constraints = [
      types: [
        int: [
          type: :integer,
          constraints: [
            max: 10
          ]
        ],
        string: [
          type: :string
        ]
      ]
    ]

    {:ok, %{constraints: constraints}} =
      Ash.Type.set_type_transformation(%{type: Ash.Type.Union, constraints: constraints})

    assert {:ok, %Ash.Union{value: 1, type: :int}} = Ash.Type.cast_input(:union, 1, constraints)

    assert {:error, _} = Ash.Type.cast_input(:union, 11, constraints)
  end

  test "it handles tagged types" do
    constraints = [
      types: [
        foo: [
          type: :map,
          tag: :type,
          tag_value: :foo
        ],
        bar: [
          type: :map,
          tag: :type,
          tag_value: :bar
        ]
      ]
    ]

    {:ok, %{constraints: constraints}} =
      Ash.Type.set_type_transformation(%{type: Ash.Type.Union, constraints: constraints})

    assert {:ok, %Ash.Union{value: %{type: :foo, bar: 1}, type: :foo}} =
             Ash.Type.cast_input(:union, %{type: :foo, bar: 1}, constraints)

    assert {:ok, %Ash.Union{value: %{type: :bar, bar: 1}, type: :bar}} =
             Ash.Type.cast_input(:union, %{type: :bar, bar: 1}, constraints)

    assert {:error, _} =
             Ash.Type.cast_input(:union, %{type: :baz, bar: 1}, constraints)
  end

  test "it handles paths" do
    constraints = [
      items: [
        types: [
          foo: [
            type: Foo,
            tag: :type,
            tag_value: :foo
          ],
          bar: [
            type: Bar,
            tag: :type,
            tag_value: :bar
          ]
        ]
      ]
    ]

    {:ok, %{type: type, constraints: constraints}} =
      Ash.Type.set_type_transformation(%{
        type: {:array, Ash.Type.Union},
        constraints: constraints
      })

    assert {:ok, [%Ash.Union{value: %{type: "foo", foo: "foo"}, type: :foo}]} =
             Ash.Type.cast_input(type, [%{type: :foo, foo: "foo"}], constraints)

    # assert {:ok, [%Ash.Union{value: %{type: "foo", foo: "foo"}, type: :foo}]} =
    Ash.Type.cast_input(type, [%{type: :foo, foo: "bar"}], constraints) |> IO.inspect()
  end
end
