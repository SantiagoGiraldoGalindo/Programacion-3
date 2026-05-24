defmodule Inmobiliaria.Supervisor do
  @moduledoc """
  Supervisor raíz de la aplicación (definido en application.ex).
  Este módulo documenta la estrategia de supervisión.

  Árbol de supervisión:
    Inmobiliaria.Supervisor (one_for_one)
    ├── Inmobiliaria.PropertySupervisor (DynamicSupervisor)
    │   └── Inmobiliaria.Property (uno por propiedad)
    ├── Inmobiliaria.UserManager
    ├── Inmobiliaria.PropertyManager
    ├── Inmobiliaria.MessageManager
    └── Inmobiliaria.Server

  DynamicSupervisor permite:
  - Crear procesos Property en tiempo de ejecución
  - Reiniciar propiedades individuales si fallan
  - Aislar fallos: un crash en una propiedad no afecta las demás
  """
end
