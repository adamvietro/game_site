defmodule GameSiteWeb.Live.WordleLive.GameBoard do
  use GameSiteWeb, :live_view

  attr(:board_state, :map, required: true)
  attr(:entry, :map, required: true)

  def game_board(assigns) do
    ~H"""
    <div class="grid grid-cols-5 gap-2 sm:gap-4">
      <%= for {label, index} <- Enum.with_index(get_labels(@entry)) do %>
        <div class={"p-4 text-center rounded " <> Map.get(@board_state, index)}>
          {label}
        </div>
      <% end %>
    </div>
    """
  end

  attr(:keyboard, :map, required: true)

  def keyboard(assigns) do
    ~H"""
    <div class="space-y-1 sm:space-y-2 text-sm" phx-hook="KeyInput" id="keyboard">
      <.keyboard_row attr={get_keyboard_row_attr(:top)} keyboard={@keyboard} />
      <.keyboard_row attr={get_keyboard_row_attr(:middle)} keyboard={@keyboard} />
      <.keyboard_row attr={get_keyboard_row_attr(:bottom)} keyboard={@keyboard} />
      <.keyboard_delete />
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
          class={"cursor-pointer w-8 sm:w-10 p-1 sm:p-2 text-center rounded " <> @keyboard[key]}
        >
          {Atom.to_string(key) |> String.upcase()}
        </div>
      <% end %>
    </div>
    """
  end

  def keyboard_delete(assigns) do
    ~H"""
    <div class="mt-2 grid grid-cols-3 gap-1 sm:gap-2">
      <div
        phx-click="delete_letter"
        class="col-span-1 p-2 text-center rounded bg-red-200 cursor-pointer"
      >
        Delete
      </div>
    </div>
    """
  end

  def get_keyboard_row_attr(:top),
    do: %{
      letters: [:q, :w, :e, :r, :t, :y, :u, :i, :o, :p],
      class: "grid grid-cols-10 gap-1 sm:gap-2"
    }

  def get_keyboard_row_attr(:middle),
    do: %{letters: [:a, :s, :d, :f, :g, :h, :j, :k, :l], class: "grid grid-cols-9 gap-1 sm:gap-2"}

  def get_keyboard_row_attr(:bottom),
    do: %{letters: [:z, :x, :c, :v, :b, :n, :m], class: "grid grid-cols-7 gap-1 sm:gap-2"}

  def get_labels(entry) do
    for round <- [:first, :second, :third, :fourth, :fifth, :sixth],
        letter <- 1..5 do
      Map.get(entry[round], :"l#{letter}")
    end
  end
end
