defmodule PanaceaWeb.Demo do
  use Surface.LiveView

  alias PanaceaWeb.Components.Hero

  def render(assigns) do
    ~F"""
    <div>
      <Hero name="John Doe" subtitle="How are you?" color="info"/>
    </div>
    """
  end
end
