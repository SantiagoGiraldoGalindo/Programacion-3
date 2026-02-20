
# defmodule es como el public class en java, el main es la funcion
defmodule Saludo do
  def main do
    "Bienvenido a la empresa Once ldta"
    |> mostrar_mensaje_java()
  end



defp  mostrar_mensaje(mensaje) do
  mensaje
  |> IO.puts()
end
end
Saludo.main()
