defmodule EntradaDatos do
  def main do
    "Ingrese el nombre del empleado: "
    |> ingresar_texto()
    |> generar_mensaje()
    |> Util.mostrar_mensaje()
  end   

  def ingresar_texto(mensaje) do
    mensaje
    |> IO.gets()
    |> String.trim()
  end

  def generar_mensaje(nombre) do
    "Bienvenido a la empresa Once ltda, #{nombre}"
  end
end

EntradaDatos.main()
