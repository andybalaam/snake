import org.w3c.dom.HTMLCanvasElement
import org.w3c.dom.Window
import org.w3c.dom.events.KeyboardEvent
import kotlin.browser.document
import kotlin.browser.window
import kotlin.math.min
import kotlin.random.Random

fun main() {
    val canvas = document.getElementById("snake-canvas") as HTMLCanvasElement
    val game = Game(Random.Default)

    window.onresize = { scaleCanvas(canvas, window); render(canvas, game) }

    scaleCanvas(canvas, window)
    render(canvas, game)

    document.onkeydown = { onkeydown(game, it) }

    window.setInterval({ game.step(); render(canvas, game) }, 100)
}

private fun scaleCanvas(canvas: HTMLCanvasElement, window: Window) {
    val minDim = min(window.innerHeight, window.innerWidth - 1)
    canvas.height = minDim
    canvas.width = minDim

    canvas.style.paddingTop =
        ((window.innerHeight - minDim) / 2).toString() + "px"

    canvas.style.paddingLeft =
        ((window.innerWidth - minDim) / 2).toString() + "px"
}

private fun onkeydown(game: Game, e: KeyboardEvent) {
    when (e.key) {
        "ArrowUp", "w" -> game.snake.turn(Direction.UP)
        "ArrowDown", "s" -> game.snake.turn(Direction.DOWN)
        "ArrowLeft", "a" -> game.snake.turn(Direction.LEFT)
        "ArrowRight", "d" -> game.snake.turn(Direction.RIGHT)
        " " -> if (!game.snake.alive) game.reset()
    }
}