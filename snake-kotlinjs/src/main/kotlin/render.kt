import org.w3c.dom.*

const val background = "#000000"
const val wall = "#aaaaaa"
const val apple = "#ff3232"
const val snake = "#00ff00"
const val snakedeadhead = "#0000ff"
const val overlaybg = "#77777777"
const val overlaytext = "#ffffff"

fun render(canvas: HTMLCanvasElement, game: Game) {
    val ctx = canvas.getContext("2d") as CanvasRenderingContext2D
    ctx.fillStyle = background
    ctx.fillRect(0.0, 0.0, canvas.width.toDouble(), canvas.height.toDouble())

    val gridSizeX: Double = (canvas.width.toDouble() - 1) / game.width
    val gridSizeY: Double = (canvas.height.toDouble() - 1) / game.height

    fun drawSquare(x: Int, y: Int) {
        ctx.fillRect(
            x * gridSizeX + 1, y * gridSizeY + 1,
            gridSizeX - 1, gridSizeY - 1
        )
    }

    ctx.fillStyle = wall
    for (x in 0 until game.width) {
        drawSquare(x, 0)
        drawSquare(x, game.height - 1)
    }
    for (y in 1 until game.height - 1) {
        drawSquare(0, y)
        drawSquare(game.width - 1, y)
    }

    ctx.fillStyle = snake
    for (p in game.snake.body) {
        drawSquare(p.x, p.y)
    }
    if (!game.snake.alive) {
        val head = game.snake.body.first()
        ctx.fillStyle = snakedeadhead
        drawSquare(head.x, head.y)
    }

    ctx.fillStyle = apple
    drawSquare(game.apple.x, game.apple.y)

    if (!game.snake.alive) {
        ctx.fillStyle = overlaybg
        ctx.fillRect(
            0.0, 0.0, canvas.width.toDouble(), canvas.height.toDouble())

        ctx.fillStyle = overlaytext
        ctx.textBaseline = CanvasTextBaseline.MIDDLE
        ctx.textAlign = CanvasTextAlign.CENTER
        ctx.font = (canvas.height * 0.07).toString() + "px sans-serif"
        ctx.fillText(
            "Score: ${game.snake.body.size}.  Press SPACE.",
            canvas.width / 2.0,
            canvas.height / 2.0
        )
    }
}