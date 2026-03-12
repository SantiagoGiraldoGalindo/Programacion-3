defmodule Snake.Game do
  @moduledoc "Lógica principal del juego Snake"
  @width 40 #constante del ancho del tablero
  @height 15 # constante del alto del tablero
  @initial_delay 150 #tiempo entre movimientos

  defstruct snake: [{10, 7}, {9, 7}, {8, 7}], #posiciones del cuerpo de la serpiente
            direction: :right, #dirrecion actual
            next_direction: :right, #siguiente direccion
            food: {20, 7}, #posicion inicial de la comida
            score: 0, #puntaje por default
            over: false # indica que no a perdido

  def start(player_name) do
    IO.write("\e[H\e[2J") # limpia terminal
    IO.puts("🐍 ¡A jugar! #{player_name}") # muestra las instrucciones
    IO.puts("Controles: W=Arriba | S=Abajo | A=Izquierda | D=Derecha | Q=Salir")
    Process.sleep(1000) # esperar un segundo

    state = %__MODULE__{} # se crea el estado inicial
    game_loop(state, player_name, @initial_delay) #inicia el juego
  end

  defp game_loop(state, player_name, delay) do
    IO.write("\e[H\e[2J") # se limpia pantalla
    render(state) # se renderiza de nuevo

    if state.over do
      # si el juego termina
      IO.puts("\n❌ ¡GAME OVER!")
      IO.puts("Puntuación final: #{state.score}")
      Snake.Player.update_score(player_name, state.score)
      :game_over
    else
      direction = get_input_non_blocking()

      case direction do
        :quit ->
          IO.puts("\n👋 ¡Juego terminado!")
          :quit
        _ ->
          new_state = state
            |> validate_direction(direction)
            |> step()

          new_delay = if state.score > 0 and rem(state.score, 50) == 0 do
            #aumentar dificultad
            max(50, delay - 10)
          else
            delay
          end

          Process.sleep(new_delay)
          game_loop(new_state, player_name, new_delay)
      end
    end
  end

  defp get_input_non_blocking do
    #lectura del teclado
    case IO.getn("", 1) do
      "w" -> :up
      "W" -> :up
      "s" -> :down
      "S" -> :down
      "a" -> :left
      "A" -> :left
      "d" -> :right
      "D" -> :right
      "q" -> :quit
      "Q" -> :quit
      _ -> nil # si se ingresa otra no hace nada
    end
  rescue
    _ -> nil # si ocurre un error devulve nulo
  end

  defp validate_direction(state, direction) when direction != nil do
    # evita que la serpiente gire en dirreciones imposibles
    case {state.direction, direction} do
      {:up, :down} -> state
      {:down, :up} -> state
      {:left, :right} -> state
      {:right, :left} -> state
      _ -> %{state | next_direction: direction}
    end
  end

  defp validate_direction(state, _), do: state

  defp step(state) do
    #Este bloque es el avanze de la serpiente
    direction = state.next_direction
    [head | tail] = state.snake # obtiene la cabeza y cola de la serpiente
    new_head = move(head, direction) # luego calcula la nueva posicion

    cond do
      out_of_bounds?(new_head) -> #si choca con una pared over se vuelve true
        %{state | over: true}

      new_head in state.snake -> #si choca con sigo misma over se vuelve true
        %{state | over: true}

      new_head == state.food -> # si come la manzana aumenta el puntaje y randomiza la nueva posicion
        new_food = random_food(state.snake)
        %{
          state
          | snake: [new_head | state.snake],
            food: new_food,
            score: state.score + 10,
            direction: direction
        }

      true ->
        %{
          state #avanze normal de la serpiente
          | snake: [new_head | Enum.drop(tail, -1)], # se agrega una nueva cabeza y se elimina una nueva cola
            direction: direction
        }
    end
  end

  defp move({x, y}, :up), do: {x, y - 1} #define como se muve la serpiente
  defp move({x, y}, :down), do: {x, y + 1}
  defp move({x, y}, :left), do: {x - 1, y}
  defp move({x, y}, :right), do: {x + 1, y}

  defp out_of_bounds?({x, y}) do #detectar la salida del tablero (si choca con el)
    x < 0 or x >= @width or y < 0 or y >= @height
  end

  defp random_food(snake) do
    pos = {Enum.random(0..(@width - 1)), Enum.random(0..(@height - 1))}
    if pos in snake, do: random_food(snake), else: pos
  end

  def render(state) do

    #generar comida en una posicion aleatoria
    board = Enum.map_join(0..(@height - 1), "\n", fn y ->
      Enum.map_join(0..(@width - 1), "", fn x ->
        pos = {x, y}

        cond do
          pos == hd(state.snake) -> "◉"
          pos in tl(state.snake) -> "●"
          pos == state.food -> "🍎"
          true -> " "
        end
      end)
    end)

    border = "┌" <> String.duplicate("─", @width) <> "┐" #dibuga los bordes
    bottom = "└" <> String.duplicate("─", @width) <> "┘"

    IO.puts(border)
    board |> String.split("\n") |> Enum.each(&IO.puts("│" <> &1 <> "│"))
    IO.puts(bottom)
    IO.puts("📊 Puntuación: #{state.score} | 🐍 Longitud: #{length(state.snake)}")
  end
end
