defmodule GameSiteWeb.Router do
  # alias GameSiteWeb.GuessingLive
  use GameSiteWeb, :router

  import GameSiteWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {GameSiteWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", GameSiteWeb do
    pipe_through :browser

    get "/", PageController, :home

    live "/scores", ScoreLive.Index, :index
    # live "/scores/new", ScoreLive.Index, :new
    # live "/scores/:id/edit", ScoreLive.Index, :edit

    # live "/scores/:id", ScoreLive.Show, :show
    # live "/scores/:id/show/edit", ScoreLive.Show, :edit

    live "/1", GuessingLive, :game
    live "/2", MathLive, :game
    live "/3", RockPaperScissorsLive, :game
    live "/4", WordleLive, :game
    live "/5", PokerLive, :game
  end

  scope "/", GameSiteWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :scores, on_mount: [{GameSiteWeb.UserAuth, :mount_current_user}] do
      live "/games", GameLive.Index, :index
      live "/games/new", GameLive.Index, :new
      live "/games/:id/edit", GameLive.Index, :edit

      live "/games/:id", GameLive.Show, :show
      live "/games/:id/show/edit", GameLive.Show, :edit
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", GameSiteWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:game_site, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: GameSiteWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", GameSiteWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{GameSiteWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/", GameSiteWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{GameSiteWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
    end
  end

  scope "/", GameSiteWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{GameSiteWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end
end
