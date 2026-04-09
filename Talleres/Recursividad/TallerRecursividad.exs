defmodule Recursividad do

  def main do
    # 1 y 2 - Vocales
    cadena = "Hola Mundo"
    IO.puts("Vocales (graphemes): #{contar_vocales_graphemes(cadena)}")
    IO.puts("Vocales (binario): #{contar_vocales_binario(cadena)}")

    # 3 - Potencia
    IO.puts("16 es potencia de 2: #{es_potencia(16, 2)}")
    IO.puts("50 es potencia de 10: #{es_potencia(50, 10)}")

    # 4 - Número perfecto
    IO.puts("6 es perfecto: #{es_perfecto(6)}")
    IO.puts("10 es perfecto: #{es_perfecto(10)}")

    # 5 - Cadena más larga
    lista = ["hola", "mundo", "programacion", "elixir"]
    IO.puts("Cadena más larga: #{cadena_mas_larga(lista)}")

    # 6 - Número reversible
    IO.puts("36 es reversible: #{reversible?(36)}")
    IO.puts("123 es reversible: #{reversible?(123)}")
  end



  # 1. Contar vocales con String.graphemes

  def contar_vocales_graphemes(cadena) do
    cadena
    |> String.graphemes()
    |> contar_vocales_lista(0)
  end

  defp contar_vocales_lista([], contador), do: contador

  defp contar_vocales_lista([cabeza | cola], contador) do
    if cabeza in ["a", "e", "i", "o", "u", "A", "E", "I", "O", "U"] do
      contar_vocales_lista(cola, contador + 1)
    else
      contar_vocales_lista(cola, contador)
    end
  end



  # 2. Contar vocales sin String.graphemes

  def contar_vocales_binario(<<>>), do: 0

  def contar_vocales_binario(<<c::utf8, resto::binary>>) do
    if <<c::utf8>> in ["a","e","i","o","u","A","E","I","O","U"] do
      1 + contar_vocales_binario(resto)
    else
      contar_vocales_binario(resto)
    end
  end



  # 3. Saber si n es potencia de b

  def es_potencia(n, b) when n == 1, do: true
  def es_potencia(n, b) when n < b, do: false

  def es_potencia(n, b) do
    if rem(n, b) == 0 do
      es_potencia(div(n, b), b)
    else
      false
    end
  end



  # 4. Número perfecto (recursividad de cola)

  def es_perfecto(n) do
    suma_divisores(n, 1, 0) == n
  end

  defp suma_divisores(n, i, suma) when i == n, do: suma

  defp suma_divisores(n, i, suma) do
    if rem(n, i) == 0 do
      suma_divisores(n, i + 1, suma + i)
    else
      suma_divisores(n, i + 1, suma)
    end
  end



  # 5. Cadena más larga

  def cadena_mas_larga([una]), do: una

  def cadena_mas_larga([cabeza | cola]) do
    mayor = cadena_mas_larga(cola)

    if String.length(cabeza) > String.length(mayor) do
      cabeza
    else
      mayor
    end
  end



  # 6. Número reversible

  def reversible?(n) when n <= 0, do: false

  def reversible?(n) do
    invertido = invertir(n, 0)
    suma = n + invertido
    todos_impares?(suma)
  end

  defp invertir(0, acc), do: acc

  defp invertir(n, acc) do
    invertir(div(n, 10), acc * 10 + rem(n, 10))
  end

  defp todos_impares?(0), do: true

  defp todos_impares?(n) do
    digito = rem(n, 10)

    if rem(digito, 2) == 0 do
      false
    else
      todos_impares?(div(n, 10))
    end
  end

end
Recursividad.main()
