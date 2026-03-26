defmodule GameSiteWeb.PentoLive.ColorsTest do
  use ExUnit.Case, async: true

  alias GameSiteWeb.PentoLive.Colors

  describe "color/1" do
    test "defaults to inactive and incomplete" do
      assert Colors.color(:green) == "#8BBF57"
      assert Colors.color(:purple) == "#240054"
    end
  end

  describe "color/3 priority rules" do
    test "active overrides completed and base color" do
      assert Colors.color(:green, true, false) == "#B86EF0"
      assert Colors.color(:green, true, true) == "#B86EF0"
      assert Colors.color(:purple, true, false) == "#B86EF0"
    end

    test "completed overrides base color when not active" do
      assert Colors.color(:green, false, true) == "#000000"
      assert Colors.color(:orange, false, true) == "#000000"
      assert Colors.color(:purple, false, true) == "#000000"
    end
  end

  describe "color/3 base colors" do
    test "green shades" do
      assert Colors.color(:green, false, false) == "#8BBF57"
      assert Colors.color(:dark_green, false, false) == "#689042"
      assert Colors.color(:light_green, false, false) == "#C1D6AC"
    end

    test "orange shades" do
      assert Colors.color(:orange, false, false) == "#B97328"
      assert Colors.color(:dark_orange, false, false) == "#8D571E"
      assert Colors.color(:light_orange, false, false) == "#F4CCA1"
    end

    test "gray shades" do
      assert Colors.color(:gray, false, false) == "#848386"
      assert Colors.color(:dark_gray, false, false) == "#5A595A"
      assert Colors.color(:light_gray, false, false) == "#B1B1B1"
    end

    test "blue shades" do
      assert Colors.color(:blue, false, false) == "#83C7CE"
      assert Colors.color(:dark_blue, false, false) == "#63969B"
      assert Colors.color(:light_blue, false, false) == "#B9D7DA"
    end

    test "purple" do
      assert Colors.color(:purple, false, false) == "#240054"
    end
  end
end
