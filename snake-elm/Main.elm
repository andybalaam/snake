import Effects exposing ( Never )
import SnakeElm exposing ( update, view, init )
import StartApp
import Task

port startTime : Float

app =
    StartApp.start
    {
          init = init startTime
        , update = update
        , view = view
        , inputs = []
    }

main = app.html

port tasks : Signal (Task.Task Never ())
port tasks =
      app.tasks

