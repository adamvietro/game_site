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
        notify_parent({:saved, score})

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
        notify_parent({:saved, score})

        {:noreply,
         socket
         |> put_flash(:info, "Score created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
