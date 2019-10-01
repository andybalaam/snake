import org.w3c.dom.CanvasRenderingContext2D
import org.w3c.dom.HTMLCanvasElement
import kotlin.browser.document

fun main(args: Array<String>) {
    val canvas = document.getElementById("snake-canvas") as HTMLCanvasElement;

    println("height=${canvas.height}")
    println("width=${canvas.width}")
    val ctx = canvas.getContext("2d") as CanvasRenderingContext2D

    ctx.fillStyle = "#F00"
    ctx.fillRect(10.0, 10.0, 20.0, 20.0)
}
