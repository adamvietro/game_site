defmodule GameSiteWeb.MultiPokerLive.InstructionHelperTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias GameSiteWeb.MultiPokerLive.InstructionHelper

  describe "helper_bubble/1" do
    test "renders the help bubble button and rules panel" do
      html = render_component(&InstructionHelper.helper_bubble/1, %{})

      assert html =~ ~s(id="poker-rules-help")
      assert html =~ ~s(phx-hook="HelpBubble")
      assert html =~ ~s(data-help-button)
      assert html =~ ~s(data-help-panel)
      assert html =~ ~s(aria-label="Show game rules")
      assert html =~ "?"
      assert html =~ "Poker Rules"
    end

    test "renders all poker rule text" do
      html = render_component(&InstructionHelper.helper_bubble/1, %{})

      assert html =~ "Each player is dealt 2 hole cards."
      assert html =~ "Betting happens across pre-flop, flop, turn, and river."
      assert html =~ "If all but one player folds, that player wins immediately."
      assert html =~ "If all remaining players are all-in, the board runs out automatically."
      assert html =~ "The best 5-card hand wins."

      assert html =~
               "If you bust, you can come back with 1000 chips after leaving the table or being removed."
    end
  end
end
