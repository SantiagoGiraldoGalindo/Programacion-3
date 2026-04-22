defmodule Estructuras do
  def main do
    "ingrese los datos del cliente: "
    |>Cliente.ingresar()
    |>generar_mensaje()
    |> Util.mostrar_mensaje()
  end
  def generar_mensaje(cliente) do
altura = cliente.altura |> Float.round(2)
"Hola #{cliente.nombre}, tu edad es de #{cliente.edad} años y " <>
"tienes una altura de #{altura}\n"
end

end
Estructuras.main()
