defmodule Tienda do

  def main do
    IO.puts("Ingrese el valor total de la compra:")
    valor_total = Util.ingresar(:entero)

    IO.puts("Ingrese el valor entregado por el cliente:")
    valor_entregado = Util.ingresar(:entero)

    calcular_cambio(valor_total, valor_entregado)
    |> generar_mensaje()
    |> Util.mostrar_mensaje()
  end

  defp calcular_cambio(valor_total, valor_entregado) do
    valor_entregado - valor_total
  end

  defp generar_mensaje(cambio) do
    "El cambio a entregar al cliente es: #{cambio}"
  end

end

Tienda.main()

