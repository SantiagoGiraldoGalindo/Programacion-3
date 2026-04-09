defmodule SumaDV do

  def main do
    lista = [1, 2, 3, 4, 5]

    resultado = suma(lista)

    IO.puts("La suma de los elementos es: #{resultado}")
  end

  # caso base: lista vacía
  def suma([]), do: 0

  # caso base: un elemento
  def suma([x]), do: x

  # divide y vencerás
  def suma(lista) do
    mitad = div(length(lista), 2)

    {izq, der} = Enum.split(lista, mitad)

    suma(izq) + suma(der)
  end

end

SumaDV.main()
