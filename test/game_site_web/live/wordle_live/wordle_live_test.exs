defmodule WordleLiveTest do
  use GameSiteWeb.ConnCase

  import Phoenix.LiveViewTest
  import GameSite.GamesFixtures
  import GameSite.AccountsFixtures

  alias GameSiteWeb.WordleLive

  defp get_socket(view) do
    state = :sys.get_state(view.pid)
    state.socket
  end

  defp log_in_and_socket(conn, user) do
    conn = log_in_user(conn, user)
    {:ok, view, _html} = live(conn, ~p"/wordle")
    socket = get_socket(view)

    %{conn: conn, view: view, socket: socket}
  end

  describe "html/live" do
    setup %{conn: conn} do
      user = user_fixture()
      game = game_fixture(%{game_id: 4})

      %{conn: conn, view: view, socket: socket} = log_in_and_socket(conn, user)

      %{
        conn: conn,
        view: view,
        socket: socket,
        user: user,
        game: game
      }
    end

    test "access route", %{view: view} do
      assert render(view) =~ "Wordle"
    end

    test "good guess", %{socket: socket} do
      answer = get_answer(socket)

      {:noreply, new_socket} =
        WordleLive.handle_event(
          "guess",
          %{"guess" => to_string(answer), "no-input" => to_string(answer)},
          socket
        )

      assert new_socket.assigns.score == 60
      assert new_socket.assigns.highest_score == 60
      assert new_socket.assigns.current_streak == 1
      assert new_socket.assigns.word == answer

      assert get_row_colors(new_socket) == [
               "bg-green-400",
               "bg-green-400",
               "bg-green-400",
               "bg-green-400",
               "bg-green-400"
             ]
    end

    test "2 good guesses", %{socket: socket} do
      answer = get_answer(socket)

      {:noreply, socket} =
        WordleLive.handle_event(
          "guess",
          %{"guess" => to_string(answer), "no-input" => to_string(answer)},
          socket
        )

      {:noreply, socket} =
        WordleLive.handle_event(
          "reset",
          %{},
          socket
        )

      answer = get_answer(socket)

      {:noreply, new_socket} =
        WordleLive.handle_event(
          "guess",
          %{"guess" => to_string(answer), "no-input" => answer},
          socket
        )

      assert new_socket.assigns.score == 120
      assert new_socket.assigns.highest_score == 120
      assert new_socket.assigns.current_streak == 2
      assert new_socket.assigns.round == 0

      assert get_row_colors(new_socket) == [
               "bg-green-400",
               "bg-green-400",
               "bg-green-400",
               "bg-green-400",
               "bg-green-400"
             ]
    end

    test "bad guess word not in list", %{socket: socket} do
      {:noreply, new_socket} =
        WordleLive.handle_event(
          "guess",
          %{"guess" => "     ", "no-input" => "     "},
          socket
        )

      assert new_socket.assigns.score == 0
      assert new_socket.assigns.highest_score == 0
      assert new_socket.assigns.current_streak == 0
    end

    test "all yellow", %{socket: socket} do
      answer = get_answer(socket)
      rotated = rotate_letters(answer)

      {:noreply, new_socket} =
        WordleLive.handle_event(
          "guess",
          %{"guess" => to_string(rotated), "no-input" => rotated},
          socket
        )

      assert new_socket.assigns.score == 0
      assert new_socket.assigns.highest_score == 0
      assert new_socket.assigns.current_streak == 0
      assert new_socket.assigns.round == 0

      assert get_row_colors(new_socket) == [
               "bg-gray-100",
               "bg-gray-100",
               "bg-gray-100",
               "bg-gray-100",
               "bg-gray-100"
             ]
    end

    test "exit after a good guess", %{socket: socket, user: user, game: game} do
      answer = get_answer(socket)

      {:noreply, updated_socket} =
        WordleLive.handle_event(
          "guess",
          %{"guess" => to_string(answer), "no-input" => to_string(answer)},
          socket
        )

      assert updated_socket.assigns.score == 60
      assert updated_socket.assigns.round == 0
      assert updated_socket.assigns.highest_score == 60

      {:noreply, updated_socket} =
        WordleLive.handle_event(
          "exit",
          %{
            "user_id" => user.id,
            "score" => updated_socket.assigns.highest_score,
            "game_id" => game.id
          },
          updated_socket
        )

      assert Phoenix.Flash.get(updated_socket.assigns.flash, :info) ==
               "Score created successfully"
    end
  end

  defp get_answer(socket) do
    socket.assigns.word
  end

  defp get_row_colors(socket) do
    round = socket.assigns.round
    start = round * 5
    last = round * 5 + 4

    Enum.map(start..last, fn key ->
      Map.get(socket.assigns.board_state, key)
    end)
  end

  defp rotate_letters(word) do
    word_list = to_charlist(word)
    {first_letter, _} = List.pop_at(word_list, 0)

    Enum.map(0..4, fn index ->
      {letter, _} = List.pop_at(word_list, index + 1, first_letter)
      letter
    end)
  end
end
