defmodule GameSiteWeb.ScoreLive.FormComponent do
  use GameSiteWeb, :live_component

  alias GameSite.Scores

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage score records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="score-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:score]} type="number" label="Score" />
        <.input field={@form[:user_id]} type="hidden" value={@current_user.id} />
        <.input field={@form[:game_id]} type="text" label="Game Id" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Score</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{score: score} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Scores.change_score(score))
     end)}
  end

  @impl true
  def handle_event("validate", %{"score" => score_params}, socket) do
    changeset = Scores.change_score(socket.assigns.score, score_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"score" => score_params}, socket) do
    save_score(socket, socket.assigns.action, score_params)
  end

  defp save_score(socket, :edit, score_params) do
    case Scores.update_score(socket.assigns.score, score_params) do
      {:ok, score} ->
        notify_parent({:edit, score})

        {:noreply,
         socket
         |> put_flash(:info, "Score updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_score(socket, :new, score_params) do
    case Scores.create_score(score_params) do
      {:ok, score} ->
        notify_parent({:new, score})

        {:noreply,
         socket
         |> put_flash(:info, "Score created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  def handle_info({GameSiteWeb.ScoreLive.FormComponent, {:new, score}}, socket) do
    # prepends the new message
    {:noreply, stream_insert(socket, :scores, score, at: 0)}
  end

  def handle_info({GameSiteWeb.ScoreLive.FormComponent, {:edit, score}}, socket) do
    # updates the new message in its current position
    {:noreply, stream_insert(socket, :scores, score)}
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
