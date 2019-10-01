import kotlin.random.Random

class Game(private val random: Random) {
    val width: Int = 20
    val height: Int = 20
    var apple: Point = newApple(random)
    var snake = Snake()

    private fun newApple(random: Random): Point {
        return Point(
            random.nextInt(1, width - 1),
            random.nextInt(1, height - 1)
        )
    }

    fun step() {
        if (snake.alive) {
            snake.step()

            val head = snake.body.first()
            val headOutsideGame =
                head.x < 1 ||
                    head.x >= width - 1 ||
                    head.y < 1 ||
                    head.y >= height - 1

            fun headHittingBody() = snake.body.drop(1).any { head == it }

            if (headOutsideGame || (head != apple && headHittingBody())) {
                snake.alive = false
            }

            if (head == apple) {
                snake.body += List(5, { head.copy() })
                apple = newApple(random)
            }
        }
    }

    fun reset() {
        apple = newApple(random)
        snake = Snake()
    }
}

