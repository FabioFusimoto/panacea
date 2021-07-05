defmodule PanaceaWeb.ArduinoController do
  use PanaceaWeb, :controller
  require Panacea.Serial.Core

  def connection(conn, _params) do
    pid = Panacea.Serial.Core.retrieve_connection()
    render(conn, "connection.html", connection_pid: inspect(pid))
  end
end
