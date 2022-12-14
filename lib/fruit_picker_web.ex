defmodule FruitPickerWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use FruitPickerWeb, :controller
      use FruitPickerWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def controller do
    quote do
      use Phoenix.Controller, namespace: FruitPickerWeb

      import Plug.Conn
      import FruitPickerWeb.Gettext
      alias FruitPickerWeb.Router.Helpers, as: Routes
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/fruit_picker_web/templates",
        namespace: FruitPickerWeb

    import Phoenix.Controller, only: [get_flash: 1, get_flash: 2, view_module: 1, action_name: 1]
    unquote(view_helpers())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView

      unquote(view_helpers())
    end
  end

  def router do
    quote do
      use Phoenix.Router
      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import FruitPickerWeb.Gettext
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end

  defp view_helpers do
    quote do
      # Import convenience functions from controllers
      import PhoenixActiveLink
      import Phoenix.LiveView.Helpers
      import Recase

      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      import FruitPickerWeb.ErrorHelpers
      import FruitPickerWeb.Gettext
      alias FruitPickerWeb.Router.Helpers, as: Routes
    end
  end

end
