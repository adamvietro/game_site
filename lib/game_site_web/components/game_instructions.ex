defmodule GameSiteWeb.GameInstructions do
  use Phoenix.Component

  def show(assigns) do
    ~H"""
    <div class="mx-auto max-w-4xl px-4 py-8">
      <h1 class="font-heavy text-3xl mb-6">How to Play</h1>
      <p class="mb-4">
        The goal of Pento is to fill the board with the pentominoes in your palette.
        Each pentomino is made up of five squares, and there are up to twelve different
        shapes to choose from. You can rotate and flip the pieces to fit them into
        the board, but you cannot overlap them or leave any empty spaces.
      </p>
      <p class="mb-4">
        To move a piece, use the arrow keys to move the active piece
        around the board. Press the space bar to drop the piece into place.
      </p>
      <p class="mb-4">
        The game is won when all pieces are placed on the board without any overlaps
        or empty spaces. Good luck, and have fun playing Pento!
      </p>
    </div>
    """
  end
end
