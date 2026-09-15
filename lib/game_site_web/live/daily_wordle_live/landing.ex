defmodule GameSiteWeb.DailyWordleLive.Landing do
  use GameSiteWeb, :live_view

  alias GameSite.DailyWordle

  @impl true
  def mount(_params, _session, socket) do
    multi_wordle = DailyWordle.get_or_create_today_wordle()

    {:ok,
     socket
     |> assign(:multi_wordle, multi_wordle)
     |> assign(:page_title, "Daily Wordle")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-xl rounded-lg bg-white p-6 shadow dark:bg-zinc-900">
      <h1 class="text-3xl font-bold text-zinc-900 dark:text-zinc-100">Daily Wordle</h1>

      <p class="mt-3 text-zinc-700 dark:text-zinc-300">
        Play today's shared Wordle. Everyone gets the same word each day.
      </p>

      <div class="mt-6">
        <%= if @current_user do %>
          <.link
            navigate={~p"/daily-wordle/play"}
            class="inline-block rounded bg-blue-600 px-4 py-2 font-semibold text-white hover:bg-blue-700"
          >
            Start today's Wordle
          </.link>
          <.link
            navigate={~p"/daily-wordle/archive"}
            class="inline-block rounded bg-blue-600 px-4 py-2 font-semibold text-white hover:bg-blue-700"
          >
            View your archive
          </.link>
        <% else %>
          <div class="space-y-3">
            <p class="text-zinc-700 dark:text-zinc-300">
              Please log in to play today's Wordle and save your progress.
            </p>

            <.link
              navigate={~p"/users/log_in"}
              class="inline-block rounded bg-blue-600 px-4 py-2 font-semibold text-white hover:bg-blue-700"
            >
              Log in
            </.link>

            <.link
              navigate={~p"/users/register"}
              class="ml-2 inline-block rounded bg-zinc-200 px-4 py-2 font-semibold text-zinc-800 hover:bg-zinc-300 dark:bg-zinc-800 dark:text-zinc-200 dark:hover:bg-zinc-700"
            >
              Create account
            </.link>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
