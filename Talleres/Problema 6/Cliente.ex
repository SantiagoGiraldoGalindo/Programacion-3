defmodule Cliente do
  defstruct nombre: "", edad: 0, altura: 0.0
def crear(nombre, edad, altura) do
%Cliente{nombre: nombre, edad: edad, altura: altura}
end
def ingresar(mensaje) do
  mensaje
  |>Util.mostrar_mensaje()

  nombre = "ingrese nombre:"
  |>Util.ingresar(:texto)

  edad= "ingresar edad: "
  |>Util.ingresar(:entero)

  altura= "ingrear altura: "
  |> Util.ingresar(:real)

  crear(nombre,edad,altura)



end



end
