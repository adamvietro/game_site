defmodule GameSiteWeb.DailyWordleLive.Archive do
  use GameSiteWeb, :live_view

  alias GameSite.DailyWordle

  @impl true
  def mount(_params, _session, socket) do
    user_wordles =
      DailyWordle.list_user_wordles(socket.assigns.current_user.id)

    {:ok,
     socket
     |> assign(:page_title, "Daily Wordle Archive")
     |> assign(:user_wordles, user_wordles)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-2xl p-4">
      <h1 class="mb-4 text-3xl font-bold">Daily Wordle Archive</h1>

      <%= if Enum.empty?(@user_wordles) do %>
        <p class="text-gray-600">You have not played any daily Wordles yet.</p>
      <% else %>
        <div class="space-y-3">
          <%= for user_wordle <- @user_wordles do %>
            <.link
              navigate={~p"/daily-wordle/archive/#{user_wordle.id}"}
              class="block rounded-lg bg-white p-4 shadow transition hover:bg-gray-50 hover:shadow-md"
            >
              <div class="flex items-center justify-between">
                <div>
                  <p class="font-semibold">
                    {user_wordle.multi_wordle.date}
                  </p>

                  <p class="text-sm text-gray-600">
                    Status: {user_wordle.status} · Attempts: {user_wordle.attempts}
                  </p>
                </div>

                <%= if user_wordle.status in ["won", "lost"] do %>
                  <span class="rounded bg-gray-100 px-3 py-1 text-sm font-mono">
                    {String.upcase(user_wordle.multi_wordle.word)}
                  </span>
                <% end %>
              </div>

              <div class="mt-3 text-sm text-gray-700">
                Guesses: {Enum.join(user_wordle.entered_words || [], ", ")}
              </div>
            </.link>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end
end
