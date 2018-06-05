defmodule CRUDimentaryTest do
  use ExUnit.Case
  doctest CRUDimentary

  test "greets the world" do
    assert CRUDimentary.hello() == :world
  end
end
