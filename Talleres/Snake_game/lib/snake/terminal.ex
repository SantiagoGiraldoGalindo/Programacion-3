defmodule Snake.Terminal do
  @moduledoc "Interfaz de terminal para el juego"

  def start do
    IO.write("\e[H\e[2J") #limpiar terminal en pantalla
    IO.puts("╔════════════════════════════════════════╗")
    IO.puts("║        🐍 SNAKE GAME EN ELIXIR 🐍      ║")
    IO.puts("╚════════════════════════════════════════╝\n")
    main_menu()
  end

  defp main_menu do
    IO.puts("\n📋 MENÚ PRINCIPAL:")
    IO.puts("  1️⃣  Crear jugador")
    IO.puts("  2️⃣  Ver puntuaciones")
    IO.puts("  3️⃣  Jugar")
    IO.puts("  4️⃣  Eliminar jugador")
    IO.puts("  5️⃣  Salir\n")

    case IO.gets("Selecciona una opción (1-5): ") |> String.trim() do
      "1" -> create_player(); main_menu()
      "2" -> show_scores(); main_menu()
      "3" -> play_game(); main_menu()
      "4" -> delete_player(); main_menu()
      "5" -> IO.puts("\n👋 ¡Hasta luego!\n")
      _ -> IO.puts("\n❌ Opción no válida\n"); main_menu()
    end
  end

  defp create_player do
    name = IO.gets("\n👤 Nombre del jugador: ") |> String.trim()

    case name do
      "" ->
        IO.puts("❌ El nombre no puede estar vacío")
        create_player()
      _ ->
        case Snake.Player.create(name) do
          {:ok, _} -> IO.puts("✅ ¡Jugador '#{name}' creado exitosamente!")
          {:error, :exists} -> IO.puts("❌ Ya existe un jugador con ese nombre")
        end
    end
  end

  defp show_scores do
    players = Snake.Player.list_all()

    IO.puts("\n🏆 TABLA DE PUNTUACIONES:")
    IO.puts("─────────────────────────────")

    if Enum.empty?(players) do
      IO.puts("No hay jugadores registrados aún")
    else
      players
      |> Enum.with_index(1) #agrega a cada jugador un numero (indexa)
      |> Enum.each(fn {{name, score}, idx} ->
        IO.puts("#{idx}. #{name}: #{score} puntos")
      end)
    end

    IO.puts("─────────────────────────────")
  end

  defp play_game do
    name = IO.gets("\n👤 ¿Quién va a jugar? ") |> String.trim()

    case Snake.Player.get_score(name) do
      nil ->
        IO.puts("❌ El jugador '#{name}' no existe")
      _score ->
        IO.puts("✅ ¡Bienvenido, #{name}!")
        Snake.Game.start(name)
    end
  end

  defp delete_player do
    name = IO.gets("\n👤 Nombre del jugador a eliminar: ") |> String.trim()

    case Snake.Player.delete(name) do
      {:ok, :deleted} -> IO.puts("✅ Jugador '#{name}' eliminado")
      {:error, :not_found} -> IO.puts("❌ El jugador no existe")
    end
  end
end
