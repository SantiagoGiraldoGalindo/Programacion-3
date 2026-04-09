defmodule Matrushka do

  def main do
    numero_matrushka="ingresar el numero de matrushka"
    |> Util.ingresar(:texto)
    abrir_matrushka=abriendo_matrushka(numero_matrushka)
    cerrar_matrushka=cerrando_matrushka(numero_matrushka)
    mensaje=generar_mensaje(numero_matrushka, matrushka)

  end

  defp abriendo_matrushka(numero_matrushka) when numero_matrushka>0 do

  end
end
