defmodule Matriz do

  def main do
    matriz = [
      [60,22,41,5],
      [13,33,44,5],
      [89,10,100,94],
      [5,101,6,34]
    ]


    t1 = Task.async(fn -> suma_diagonalInferior(matriz) end)
    t2 = Task.async(fn -> obtener_promedio(matriz) end)

    suma = Task.await(t1)
    promedio = Task.await(t2)

    IO.puts("Suma de la diagonal inferior: #{suma}")
    IO.puts("Promedio de los elementos: #{promedio}")


    multiplicar = multiplicarS1_S2(suma, promedio)

    imprimir_multiplicacion(multiplicar)
  end
  def suma_diagonalInferior(matriz) do
  Enum.with_index(matriz)
  |> Enum.reduce(0, fn {fila, i}, acc ->
    acc + (Enum.take(fila, i) |> Enum.sum())
  end)
end

  def obtener_promedio(matriz) do
    total_elementos = length(matriz) * length(List.first(matriz))

    suma_total = Enum.reduce(matriz, 0, fn fila, acc ->
      acc + Enum.reduce(fila, 0, fn elemento, acc2 ->
        acc2 + elemento
      end)
    end)

    suma_total / total_elementos
  end


  def multiplicarS1_S2(suma, promedio) do
    suma * promedio
  end


  def imprimir_multiplicacion(resultado) do
    IO.puts("Resultado de la multiplicación: #{resultado}")
  end

end

Matriz.main()
