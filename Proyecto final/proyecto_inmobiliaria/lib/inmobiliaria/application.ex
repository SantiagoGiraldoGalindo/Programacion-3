defmodule Inmobiliaria.Application do
  @moduledoc """
  Punto de entrada de la aplicación. Inicia el árbol de supervisión.
  """
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Supervisor dinámico para procesos de propiedades
      {DynamicSupervisor, name: Inmobiliaria.PropertySupervisor, strategy: :one_for_one},
      # Gestor de usuarios
      Inmobiliaria.UserManager,
      # Gestor de propiedades
      Inmobiliaria.PropertyManager,
      # Gestor de mensajes
      Inmobiliaria.MessageManager,
      # Servidor principal (CLI)
      Inmobiliaria.Server
    ]

    opts = [strategy: :one_for_one, name: Inmobiliaria.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
