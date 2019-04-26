defmodule LsppWebWeb.Router do
  use LsppWebWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug Phoenix.LiveView.Flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", LsppWebWeb do
    pipe_through :browser

    get "/", PageController, :index
  end

  get "/css/app.css", LsppWebWeb.StaticAssetController, :app_css
  get "/js/app.js", LsppWebWeb.StaticAssetController, :app_js
  get "/images/phoenix.png", LsppWebWeb.StaticAssetController, :phoenix_png

  scope "/" do
    pipe_through :browser

    live "/messages", LsppWebWeb.MessagesLive
  end

  # Other scopes may use custom stacks.
  scope "/api", LsppWebWeb do
    pipe_through :api

    post "/messages", MessagesController, :create
    post "/incoming_messages", MessagesController, :incoming
    post "/outgoing_messages", MessagesController, :outgoing
  end
end
