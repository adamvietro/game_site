defmodule GameSiteWeb.MathLive.Component do
  use GameSiteWeb, :live_view
  use Phoenix.Component

  attr(:helper, :map, required: true)
  attr(:toggle, :boolean, required: true)

  def helper_board(assigns) do
    ~H"""
    <section class="w-full rounded-xl border border-gray-300 bg-white p-4 shadow-md">
      <div class="flex flex-col gap-4">
        <p class="text-sm text-gray-700">
          Toggle the helper if you want a hint or want to hide it.
        </p>

        <label class="flex items-center justify-between gap-3 cursor-pointer" phx-click="toggle">
          <span class="text-sm font-medium text-gray-700">Show Helper</span>

          <div class="relative">
            <input type="checkbox" class="sr-only" checked={@toggle} readonly />
            <div class="h-6 w-11 rounded-full bg-gray-300 transition-colors">
              <div class={[
                "absolute top-0.5 left-0.5 h-5 w-5 rounded-full bg-white shadow transition-transform",
                if(@toggle, do: "translate-x-5", else: "translate-x-0")
              ]}>
              </div>
            </div>
          </div>
        </label>

        <div class={[
          "space-y-2 text-sm text-gray-700",
          if(@toggle, do: "block", else: "hidden")
        ]}>
          <p>{@helper.first}</p>
          <p>{@helper.second}</p>
          <p>{@helper.third}</p>
          <p>{@helper.fourth}</p>
        </div>
      </div>
    </section>
    """
  end

  attr(:question, :string, required: true)

  def question(assigns) do
    ~H"""
    <section class="rounded-xl bg-gray-50 p-4 text-center shadow">
      <div class="space-y-1">
        <div class="text-sm font-medium text-gray-500">Question</div>
        <div class="text-base font-semibold text-gray-800 sm:text-lg">{@question}</div>
      </div>
    </section>
    """
  end

  attr(:form, :map, required: true)
  attr(:score, :integer, required: true)
  attr(:wager, :integer, required: true)

  def answer_submit(assigns) do
    ~H"""
    <div class="w-full">
      <form id="answer-form" phx-submit="answer" class="rounded-xl bg-white p-4 shadow-md">
        <.error_message form={@form} />

        <div class="grid grid-cols-3 gap-3">
          <div>
            <label for="guess_input" class="mb-2 block text-sm font-medium text-gray-700">
              Guess
            </label>
            <input
              id="guess_input"
              name="guess"
              type="number"
              class="w-full rounded-lg border border-gray-300 px-3 py-2 shadow-sm focus:border-blue-500 focus:ring-blue-500"
            />
          </div>

          <div>
            <label for="wager_input" class="mb-2 block text-sm font-medium text-gray-700">
              Wager
            </label>
            <input
              id="wager_input"
              name="wager"
              type="number"
              min="1"
              max={@score}
              value={@wager}
              class="w-full rounded-lg border border-gray-300 px-3 py-2 shadow-sm focus:border-blue-500 focus:ring-blue-500"
            />
          </div>

          <div>
            <label class="mb-2 block text-sm font-medium invisible">
              Answer
            </label>
            <button
              type="submit"
              class="w-full rounded-lg bg-blue-500 px-4 py-2 text-white shadow hover:bg-blue-600"
            >
              Answer
            </button>
          </div>
        </div>
      </form>
    </div>
    """
  end

  attr(:form, :map, required: true)

  def error_message(assigns) do
    ~H"""
    <div class="min-h-[28px] flex items-center justify-center">
      <%= for {_field, {msg, meta}} <- @form.errors do %>
        <p class={
          case meta[:type] do
            :info -> "text-center text-sm font-medium text-green-600"
            :error -> "text-center text-sm font-medium text-red-600"
            _ -> "text-center text-sm font-medium text-gray-600"
          end
        }>
          {msg}
        </p>
      <% end %>
    </div>
    """
  end
end
