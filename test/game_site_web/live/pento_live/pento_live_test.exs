defmodule GameSiteWeb.PentoLiveTest do
  use GameSiteWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias GameSite.Pento.Board, as: PentoBoard
  alias GameSiteWeb.PentoLive

  defp valid_puzzle_string do
    PentoBoard.puzzles()
    |> hd()
    |> to_string()
  end

  describe "mount/3" do
    test "assigns puzzle and complete false" do
      puzzle = valid_puzzle_string()
      socket = %Phoenix.LiveView.Socket{}

      assert {:ok, socket} = PentoLive.mount(%{"puzzle" => puzzle}, %{}, socket)

      assert socket.assigns.puzzle == puzzle
      assert socket.assigns.complete == false
    end
  end

  describe "handle_info/2" do
    test "ignores unknown messages" do
      socket = %Phoenix.LiveView.Socket{}

      assert {:noreply, returned_socket} = PentoLive.handle_info(:something_else, socket)
      assert returned_socket == socket
    end
  end

  describe "handle_event/3" do
    test "try_again sets complete to false" do
      socket =
        %Phoenix.LiveView.Socket{}
        |> Phoenix.Component.assign(complete: true)

      assert {:noreply, socket} = PentoLive.handle_event("try_again", %{}, socket)

      assert socket.assigns.complete == false
    end
  end

  describe "complete_modal/1" do
    test "renders try again and pick a puzzle" do
      html =
        render_component(&PentoLive.complete_modal/1,
          puzzle: valid_puzzle_string(),
          current_user: nil
        )

      assert html =~ "Puzzle Complete!"
      assert html =~ "Try Again"
      assert html =~ "Pick a Puzzle"
      refute html =~ "phx-click=\"exit\""
    end

    test "renders exit button when current_user exists" do
      html =
        render_component(&PentoLive.complete_modal/1,
          puzzle: valid_puzzle_string(),
          current_user: %{id: 1}
        )

      assert html =~ "Exit"
      assert html =~ "phx-click=\"exit\""
    end
  end

  describe "help/1" do
    test "renders help button and help page" do
      html = render_component(&PentoLive.help/1, %{})

      assert html =~ "hero-question-mark-circle-solid"
      assert html =~ "Click on a pento to pick it up"
      assert html =~ "Place all the pentos to win"
    end
  end

  describe "help_button/1" do
    test "renders help toggle button" do
      html = render_component(&PentoLive.help_button/1, %{})

      assert html =~ "hero-question-mark-circle-solid"
      assert html =~ "phx-click"
    end
  end

  describe "help_page/1" do
    test "renders instructions list" do
      html = render_component(&PentoLive.help_page/1, %{})

      assert html =~ "id=\"info\""
      assert html =~ "Click on a pento to pick it up"
      assert html =~ "Drop a pento with a space"
      assert html =~ "Rotate a pento with shift"
      assert html =~ "Flip a pento with enter"
      assert html =~ "Place all the pentos to win"
    end
  end

  describe "give_up/1" do
    test "renders give up link" do
      html = render_component(&PentoLive.give_up/1, %{})

      assert html =~ "Give Up?"
      assert html =~ "/pento_choice"
      assert html =~ "Are you sure you want to give up?"
    end
  end

  describe "render/1" do
    test "renders main page content when incomplete" do
      html =
        render_component(&PentoLive.render/1,
          puzzle: valid_puzzle_string(),
          complete: false,
          current_user: nil
        )

      assert html =~ "Welcome to Pento!"
      assert html =~ "Give Up?"
      assert html =~ "game-container"
      refute html =~ "Puzzle Complete!"
    end

    test "renders complete modal when complete is true" do
      html =
        render_component(&PentoLive.render/1,
          puzzle: valid_puzzle_string(),
          complete: true,
          current_user: %{id: 1}
        )

      assert html =~ "Puzzle Complete!"
      assert html =~ "Try Again"
      assert html =~ "Exit"
    end
  end
end
