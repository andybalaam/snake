enum class Direction {
    UP,
    DOWN,
    LEFT,
    RIGHT;

    fun opposite(): Direction =
        when (this) {
            UP -> DOWN
            DOWN -> UP
            LEFT -> RIGHT
            RIGHT -> LEFT
        }
}

class Snake {
    private var nextDir: Direction = Direction.UP
    private var dir = Direction.UP
    var body: List<Point> = (0..4).map { Point(10, 10 + it) }
    var alive = true

    fun step() {
        dir = nextDir
        val head = move(body.first())
        val rest = body.dropLast(1)
        body = listOf(head) + rest
    }

    private fun move(point: Point): Point =
        when (dir) {
            Direction.UP -> Point(point.x, point.y - 1)
            Direction.DOWN -> Point(point.x, point.y + 1)
            Direction.LEFT -> Point(point.x - 1, point.y)
            Direction.RIGHT -> Point(point.x + 1, point.y)
        }

    fun turn(newDir: Direction) {
        if (newDir != dir.opposite()) {
            nextDir = newDir
        }
    }
}