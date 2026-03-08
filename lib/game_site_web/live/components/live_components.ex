defmodule GameSiteWeb.Live.Component do
  use GameSiteWeb, :live_view
  use Phoenix.Component

  attr(:form, :map, required: true)
  attr(:game_id, :integer, required: true)
  attr(:score, :integer, required: true)
  attr(:current_user, :map, required: false)

  def score_submit(assigns) do
    ~H"""
    <div class="bg-white shadow-md rounded p-4">
      <%= if @current_user == nil do %>
        <p>
          <br /> <br />If you want to submit your score please make an
          <a
            href="/users/register"
            style="cursor: pointer; text-decoration: none; color: blue;"
            onmouseover="this.style.textDecoration='underline'; this.style.color='red';"
            onmouseout="this.style.textDecoration='none'; this.style.color='blue';"
          >
            account
          </a>
        </p>
      <% else %>
        <.simple_form
          id="exit-form"
          for={@form}
          phx-submit="exit"
          class="bg-white shadow-md rounded p-4"
        >
          <.input type="hidden" field={@form[:user_id]} value={@current_user.id} />
          <.input type="hidden" field={@form[:game_id]} value={@game_id} />
          <.input type="hidden" field={@form[:score]} value={@score} />
          <:actions>
            <.button class="bg-red-500 hover:bg-red-600 text-white px-4 py-2 rounded shadow">
              Exit and Save Score
            </.button>
          </:actions>
        </.simple_form>
      <% end %>
    </div>
    """
  end
end
