defmodule GameSiteWeb.WordleLiveTest do
  use GameSiteWeb.ConnCase

  import Phoenix.LiveViewTest
  import GameSite.GamesFixtures
  import GameSite.AccountsFixtures
  import GameSiteWeb.WordleLive

  @keyboard %{
    q: "bg-gray-100",
    w: "bg-gray-100",
    e: "bg-gray-100",
    r: "bg-gray-100",
    t: "bg-gray-100",
    y: "bg-gray-100",
    u: "bg-gray-100",
    i: "bg-gray-100",
    o: "bg-gray-100",
    p: "bg-gray-100",
    a: "bg-gray-100",
    s: "bg-gray-100",
    d: "bg-gray-100",
    f: "bg-gray-100",
    g: "bg-gray-100",
    h: "bg-gray-100",
    j: "bg-gray-100",
    k: "bg-gray-100",
    l: "bg-gray-100",
    z: "bg-gray-100",
    x: "bg-gray-100",
    c: "bg-gray-100",
    v: "bg-gray-100",
    b: "bg-gray-100",
    n: "bg-gray-100",
    m: "bg-gray-100"
  }

  defp log_in_and_socket(conn, user) do
    conn =
      conn
      |> log_in_user(user)

    {:ok, view, _html} = live(conn, ~p"/4")

    state = :sys.get_state(view.pid)
    socket = state.socket

    [conn, socket]
  end

  defp get_answer(socket) do
    socket.assigns.word
  end

  defp get_row_colors(state, round) do
    start = round * 5
    last = round * 5 + 4

    colors =
      Enum.map(start..last, fn key ->
        Map.get(state, key)
      end)

    colors
  end

  defp get_row_colors(socket) do
    round = socket.assigns.round
    start = round * 5
    last = round * 5 + 4

    colors =
      Enum.map(start..last, fn key ->
        Map.get(socket.assigns.state, key)
      end)

    colors
  end

  defp rotate_letters(word) do
    word_list = to_charlist(word)
    {first_letter, _} = List.pop_at(word_list, 0)

    Enum.map(0..4, fn index ->
      {letter, _} = List.pop_at(word_list, index + 1, first_letter)
      letter
    end)
  end

  describe "html/live" do
    setup do
      user = user_fixture()
      game = game_fixture(%{game_id: 4})

      %{user: user, game: game}
    end

    test "access route", %{conn: conn, user: user} do
      conn =
        conn
        |> log_in_user(user)

      {:ok, _view, html} = live(conn, ~p"/4")

      assert html =~ "Wordle"
    end

    test "good guess", %{conn: conn, user: user} do
      [_conn, socket] = log_in_and_socket(conn, user)

      answer = get_answer(socket)

      {:noreply, new_socket} =
        GameSiteWeb.WordleLive.handle_event(
          "guess",
          %{"guess" => to_string(answer), "no-input" => to_string(answer)},
          socket
        )

      assert new_socket.assigns.score == 60
      assert new_socket.assigns.highest_score == 60
      assert new_socket.assigns.streak == 1
      assert new_socket.assigns.word == answer

      assert get_row_colors(new_socket) == [
               "bg-green-400",
               "bg-green-400",
               "bg-green-400",
               "bg-green-400",
               "bg-green-400"
             ]
    end

    test "2 good guesses", %{conn: conn, user: user} do
      [_conn, socket] = log_in_and_socket(conn, user)

      answer = get_answer(socket)

      {:noreply, socket} =
        GameSiteWeb.WordleLive.handle_event(
          "guess",
          %{"guess" => to_string(answer), "no-input" => to_string(answer)},
          socket
        )

      {:noreply, socket} =
        GameSiteWeb.WordleLive.handle_event(
          "reset",
          %{},
          socket
        )

      answer = get_answer(socket)

      {:noreply, new_socket} =
        GameSiteWeb.WordleLive.handle_event(
          "guess",
          %{"guess" => to_string(answer), "no-input" => answer},
          socket
        )

      assert new_socket.assigns.score == 120
      assert new_socket.assigns.highest_score == 120
      assert new_socket.assigns.streak == 2
      assert new_socket.assigns.round == 0

      assert get_row_colors(new_socket) == [
               "bg-green-400",
               "bg-green-400",
               "bg-green-400",
               "bg-green-400",
               "bg-green-400"
             ]
    end

    test "bad guess word not in list", %{conn: conn, user: user} do
      [_conn, socket] = log_in_and_socket(conn, user)

      {:noreply, new_socket} =
        GameSiteWeb.WordleLive.handle_event(
          "guess",
          %{"guess" => to_string("     "), "no-input" => to_string("     ")},
          socket
        )

      assert new_socket.assigns.score == 0
      assert new_socket.assigns.highest_score == 0
      assert new_socket.assigns.streak == 0
    end

    test "all yellow", %{conn: conn, user: user} do
      [_conn, socket] = log_in_and_socket(conn, user)

      answer = get_answer(socket)

      {:noreply, new_socket} =
        GameSiteWeb.WordleLive.handle_event(
          "guess",
          %{"guess" => to_string(rotate_letters(answer)), "no-input" => rotate_letters(answer)},
          socket
        )

      assert new_socket.assigns.score == 0
      assert new_socket.assigns.highest_score == 0
      assert new_socket.assigns.streak == 0
      assert new_socket.assigns.round == 0

      assert get_row_colors(new_socket) == [
               "bg-gray-100",
               "bg-gray-100",
               "bg-gray-100",
               "bg-gray-100",
               "bg-gray-100"
             ]
    end

    test "exit after a good guess", %{conn: conn, user: user, game: game} do
      [_conn, socket] = log_in_and_socket(conn, user)
      answer = get_answer(socket)

      {:noreply, updated_socket} =
        GameSiteWeb.WordleLive.handle_event(
          "guess",
          %{"guess" => to_string(answer), "no-input" => to_string(answer)},
          socket
        )

      assert updated_socket.assigns.score == 60
      assert updated_socket.assigns.round == 0
      assert updated_socket.assigns.highest_score == 60

      {:noreply, updated_socket} =
        GameSiteWeb.MathLive.handle_event(
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

  describe "functions" do
    test "feedback/2 & set_colors/3 all green" do
      colors_letters =
        feedback("glove", "glove")

      colors =
        set_colors(colors_letters, 0, %{
          0 => "bg-gray-100",
          1 => "bg-gray-100",
          2 => "bg-gray-100",
          3 => "bg-gray-100",
          4 => "bg-gray-100"
        })

      assert get_row_colors(colors, 0) == [
               "bg-green-400",
               "bg-green-400",
               "bg-green-400",
               "bg-green-400",
               "bg-green-400"
             ]
    end

    test "feedback/2 & set_colors/3 all yellow" do
      colors_letters =
        feedback("glove", "loveg")

      colors =
        set_colors(colors_letters, 0, %{
          0 => "bg-gray-100",
          1 => "bg-gray-100",
          2 => "bg-gray-100",
          3 => "bg-gray-100",
          4 => "bg-gray-100"
        })

      assert get_row_colors(colors, 0) == [
               "bg-yellow-300",
               "bg-yellow-300",
               "bg-yellow-300",
               "bg-yellow-300",
               "bg-yellow-300"
             ]
    end

    test "feedback/2 & set_colors/3 all gray" do
      colors_letters = feedback("ppppp", "ooooo")

      colors =
        set_colors(colors_letters, 0, %{
          0 => "bg-gray-100",
          1 => "bg-gray-100",
          2 => "bg-gray-100",
          3 => "bg-gray-100",
          4 => "bg-gray-100"
        })

      assert get_row_colors(colors, 0) == [
               "bg-gray-300",
               "bg-gray-300",
               "bg-gray-300",
               "bg-gray-300",
               "bg-gray-300"
             ]
    end

    test "set_keyboard/2 all green" do
      colors_letters = feedback("green", "green")

      keyboard = set_keyboard(colors_letters, @keyboard)

      assert keyboard == %{
               q: "bg-gray-100",
               w: "bg-gray-100",
               e: "bg-green-400",
               r: "bg-green-400",
               t: "bg-gray-100",
               y: "bg-gray-100",
               u: "bg-gray-100",
               i: "bg-gray-100",
               o: "bg-gray-100",
               p: "bg-gray-100",
               a: "bg-gray-100",
               s: "bg-gray-100",
               d: "bg-gray-100",
               f: "bg-gray-100",
               g: "bg-green-400",
               h: "bg-gray-100",
               j: "bg-gray-100",
               k: "bg-gray-100",
               l: "bg-gray-100",
               z: "bg-gray-100",
               x: "bg-gray-100",
               c: "bg-gray-100",
               v: "bg-gray-100",
               b: "bg-gray-100",
               n: "bg-green-400",
               m: "bg-gray-100"
             }
    end

    test "set_keyboard/2 all yellow" do
      colors_letters = feedback("abcde", "bcdea")

      keyboard = set_keyboard(colors_letters, @keyboard)

      assert keyboard == %{
               q: "bg-gray-100",
               w: "bg-gray-100",
               e: "bg-yellow-300",
               r: "bg-gray-100",
               t: "bg-gray-100",
               y: "bg-gray-100",
               u: "bg-gray-100",
               i: "bg-gray-100",
               o: "bg-gray-100",
               p: "bg-gray-100",
               a: "bg-yellow-300",
               s: "bg-gray-100",
               d: "bg-yellow-300",
               f: "bg-gray-100",
               g: "bg-gray-100",
               h: "bg-gray-100",
               j: "bg-gray-100",
               k: "bg-gray-100",
               l: "bg-gray-100",
               z: "bg-gray-100",
               x: "bg-gray-100",
               c: "bg-yellow-300",
               v: "bg-gray-100",
               b: "bg-yellow-300",
               n: "bg-gray-100",
               m: "bg-gray-100"
             }
    end

    test "set_keyboard/2 all gray" do
      colors_letters = feedback("green", "ppppp")

      keyboard = set_keyboard(colors_letters, @keyboard)

      assert keyboard == %{
               q: "bg-gray-100",
               w: "bg-gray-100",
               e: "bg-gray-100",
               r: "bg-gray-100",
               t: "bg-gray-100",
               y: "bg-gray-100",
               u: "bg-gray-100",
               i: "bg-gray-100",
               o: "bg-gray-100",
               p: "bg-gray-300",
               a: "bg-gray-100",
               s: "bg-gray-100",
               d: "bg-gray-100",
               f: "bg-gray-100",
               g: "bg-gray-100",
               h: "bg-gray-100",
               j: "bg-gray-100",
               k: "bg-gray-100",
               l: "bg-gray-100",
               z: "bg-gray-100",
               x: "bg-gray-100",
               c: "bg-gray-100",
               v: "bg-gray-100",
               b: "bg-gray-100",
               n: "bg-gray-100",
               m: "bg-gray-100"
             }
    end

  end
end
