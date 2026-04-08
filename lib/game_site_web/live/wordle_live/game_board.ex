defmodule GameSiteWeb.Live.WordleLive.GameBoard do
  use GameSiteWeb, :live_view

  attr(:board_state, :map, required: true)
  attr(:entries, :map, required: true)

  def game_board(assigns) do
    ~H"""
    <div class="w-full">
      <div class="grid grid-cols-5 gap-1.5 sm:gap-2">
        <%= for {label, index} <- Enum.with_index(get_labels(@entries)) do %>
          <div class={
              "flex h-11 items-center justify-center rounded text-sm font-medium uppercase sm:h-12 sm:text-base " <>
                Map.get(@board_state, index)
            }>
            {label}
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  attr(:keyboard, :map, required: true)

  def keyboard(assigns) do
    ~H"""
    <div class="space-y-1 sm:space-y-2 text-sm" id="keyboard">
      <.keyboard_row attr={get_keyboard_row_attr(:top)} keyboard={@keyboard} />
      <.keyboard_row attr={get_keyboard_row_attr(:middle)} keyboard={@keyboard} />
      <div class="flex gap-1 sm:gap-2">
        <.keyboard_row attr={get_keyboard_row_attr(:bottom)} keyboard={@keyboard} />
        <.keyboard_delete />
      </div>
    </div>
    """
  end

  attr(:attr, :map, required: true)
  attr(:keyboard, :map, required: true)

  def keyboard_row(assigns) do
    ~H"""
    <div class={@attr.class}>
      <%= for key <- @attr.letters do %>
        <div
          phx-click="add_letter"
          phx-value-letter={Atom.to_string(key)}
          class={
            "flex-1 cursor-pointer rounded py-3 text-center text-sm font-medium uppercase sm:py-4 sm:text-base " <>
              @keyboard[key]
          }
        >
          {Atom.to_string(key)}
        </div>
      <% end %>
    </div>
    """
  end

  def keyboard_delete(assigns) do
    ~H"""
    <div class="mt-1 flex">
      <div
        phx-click="delete_letter"
        class="cursor-pointer rounded bg-red-700 px-4 py-3 text-center text-sm font-medium text-white"
      >
        Delete
      </div>
    </div>
    """
  end

  def get_keyboard_row_attr(:top),
    do: %{
      letters: [:q, :w, :e, :r, :t, :y, :u, :i, :o, :p],
      class: "flex gap-1"
    }

  def get_keyboard_row_attr(:middle),
    do: %{
      letters: [:a, :s, :d, :f, :g, :h, :j, :k, :l],
      class: "flex gap-1 px-4"
    }

  def get_keyboard_row_attr(:bottom),
    do: %{letters: [:z, :x, :c, :v, :b, :n, :m], class: "flex flex-1 gap-1 sm:gap-2"}

  def get_labels(entry) do
    for round <- [:first, :second, :third, :fourth, :fifth, :sixth],
        letter <- 1..5 do
      Map.get(entry[round], :"l#{letter}")
    end
  end
end
