defmodule GameSiteWeb.Live.WordleLive.Component do
  use GameSiteWeb, :live_view

  def instructions(assigns) do
    ~H"""
    <h2 class="text-xl font-semibold">Wordle Game Overview</h2>
    <div class="max-w-prose text-gray-800 space-y-4">
      <p>
        Wordle game. For this game you will be asked to find a 5 letter word. Once you have submitted a 5 letter word, you will be given feedback on how close you are to the word.
      </p>
      <ul class="list-disc list-inside space-y-1 text-left">
        <li>
          <strong class="text-green-600">Green box:</strong> Right letter in the right position
        </li>
        <li>
          <strong class="text-yellow-500">Yellow box:</strong> Letter in the word but wrong position
        </li>
        <li><strong class="text-gray-500">Grey box:</strong> Letter not in the word</li>
        <li>The faster you guess (fewer attempts), the higher your score</li>
        <li>You can use the on-screen keyboard or your own keyboard to enter a word</li>
      </ul>
    </div>
    """
  end

  attr(:highest_score, :integer, required: true)
  attr(:highest_streak, :integer, required: true)
  attr(:current_score, :integer, required: true)
  attr(:current_streak, :integer, required: true)
  attr(:reset, :boolean, required: true)

  def score_board(assigns) do
    ~H"""
    <div class="bg-white rounded p-4 shadow grid grid-cols-2 gap-6 text-center font-semibold text-gray-800">
      <div>
        <div class="text-sm text-gray-500">Highest Score</div>
        <div>{@highest_score}</div>
      </div>
      <div>
        <div class="text-sm text-gray-500">Highest Streak</div>
        <div>{@highest_streak}</div>
      </div>
      <div>
        <div class="text-sm text-gray-500">Current Score</div>
        <div>{@current_score}</div>
      </div>
      <div>
        <div class="text-sm text-gray-500">Current Streak</div>
        <div>{@current_streak}</div>
      </div>
      <%= if @reset do %>
        <div class="col-span-2 mt-4">
          <div class="text-sm text-gray-500">Word</div>
          <div class="uppercase tracking-wider font-medium">{@word}</div>
        </div>
      <% end %>
    </div>
    """
  end

  attr(:form, :map, required: true)
  attr(:reset, :boolean, required: true)
  attr(:guess_string, :string, required: true)

  def user_input(assigns) do
    ~H"""
    <%= if @reset == true do %>
      <div class="reset-input border-gray-300 rounded bg-gray-100 p-4 text-center">
        <.simple_form id="input-form" for={@form} phx-submit="reset">
          <:actions>
            <.button class="px-6 py-2 text-lg">Reset</.button>
          </:actions>
        </.simple_form>
      </div>
    <% end %>
    <%= if @reset == false do %>
      <div class="user-input">
        <.simple_form id="input-form" for={@form} phx-submit="guess">
          <.input type="text" field={@form[:guess]} value={@guess_string} label="Guess" />

          <:actions>
            <.button class="px-6 py-2 text-lg">Submit</.button>
          </:actions>
        </.simple_form>
      </div>
    <% end %>
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
end
