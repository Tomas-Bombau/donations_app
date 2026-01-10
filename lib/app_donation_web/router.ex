defmodule AppDonationWeb.Router do
  use AppDonationWeb, :router

  import AppDonationWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {AppDonationWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", AppDonationWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/", PageController, :home
  end

  # Other scopes may use custom stacks.
  # scope "/api", AppDonationWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:app_donation, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: AppDonationWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", AppDonationWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/users/register", UserRegistrationController, :new
    post "/users/register", UserRegistrationController, :create

    get "/organizations/register", OrganizationRegistrationController, :new
    post "/organizations/register", OrganizationRegistrationController, :create
  end

  scope "/", AppDonationWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
  end

  scope "/", AppDonationWeb do
    pipe_through [:browser]

    get "/users/log-in", UserSessionController, :new
    get "/users/log-in/:token", UserSessionController, :confirm
    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end

  ## Admin routes
  scope "/admin", AppDonationWeb.Admin, as: :admin do
    pipe_through [:browser, :require_authenticated_user, :require_admin]

    get "/", DashboardController, :index
    get "/metrics", MetricsController, :index

    get "/donors/:id", ManageDonorController, :show
    get "/organizations/:id", ManageOrganizationController, :show
  end

  scope "/admin", AppDonationWeb.Admin, as: :admin do
    pipe_through [:browser]

    live_session :admin,
      on_mount: [{AppDonationWeb.UserAuth, :admin}] do
      live "/organizations", OrganizationLive.Index, :index
      live "/organizations/:id/edit", OrganizationLive.Edit, :edit
      live "/donors", DonorLive.Index, :index
      live "/categories", CategoryLive.Index, :index
      live "/categories/new", CategoryLive.Index, :new
      live "/categories/:id/edit", CategoryLive.Index, :edit
    end
  end

  ## Organization routes
  scope "/organization", AppDonationWeb.Organization, as: :organization do
    pipe_through [:browser]

    live_session :organization,
      on_mount: [{AppDonationWeb.UserAuth, :organization}] do
      live "/profile", ProfileLive, :show
      live "/settings", SettingsLive, :edit
      live "/requests", RequestLive.Index, :index
      live "/requests/new", RequestLive.New, :new
      live "/requests/:id", RequestLive.Show, :show
      live "/requests/:id/edit", RequestLive.Edit, :edit
    end
  end

  ## Donor routes
  scope "/donor", AppDonationWeb.Donor, as: :donor do
    pipe_through [:browser]

    live_session :donor,
      on_mount: [{AppDonationWeb.UserAuth, :donor}] do
      live "/requests", RequestLive.Index, :index
      live "/requests/:id", RequestLive.Show, :show
      live "/donations", DonationLive.Index, :index
    end
  end
end
