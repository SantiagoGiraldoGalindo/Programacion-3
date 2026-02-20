defmodule Descuento do
def main do
valor_producto =
"Ingrese el valor del producto: "
|> Util.ingresar(:entero)
porcentaje_descuento = "Ingrese el porcentaje de descuento: "
|> Util.ingresar(:real)
valor_descuento = calcular_valor_descuento(valor_producto, porcentaje_descuento)
valor_final = calcular_valor_final(valor_producto, valor_descuento)
generar_mensaje(valor_descuento, valor_final)
|> Util.mostrar_mensaje()
end



defp calcular_valor_descuento(valor_producto, porcentaje_descuento) do
valor_producto * porcentaje_descuento
end

defp calcular_valor_final(valor_producto, valor_descuento) do
valor_producto - valor_descuento
end




defp generar_mensaje(valor_descuento, valor_final) do
  descuento_texto = :erlang.float_to_binary(valor_descuento, [decimals: 1])
  final_texto = :erlang.float_to_binary(valor_final, [decimals: 1])

  "Valor de descuento de $#{descuento_texto} y el valor final $#{final_texto}"
end
end

Descuento.main()
