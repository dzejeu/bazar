defmodule BazarTest do
  use ExUnit.Case
  doctest Bazar

  test "greets the world" do
    assert Bazar.hello() == :world
  end
end
