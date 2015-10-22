module SnakeElm ( Model, init, Action, update, view ) where

import Char
import Effects exposing ( Effects, tick )

import Html exposing ( .. )
import Html.Attributes exposing ( class, style, tabindex )
import Html.Events exposing ( onKeyDown )

import Random exposing ( .. )

import Time exposing ( Time, second )

-- CONSTANTS

frame_time : Time
frame_time = 200
world_size : Size
world_size = Size 20 20
snake_start_x : Int
snake_start_x = 10
snake_start_y : Int
snake_start_y = 5
snake_start_length : Int
snake_start_length = 5

init_seed : Random.Seed
init_seed = Random.initialSeed ( round startTime )

port startTime : Float

-- MODEL

type alias Size  = { width: Int, height: Int }
type alias Point = { x: Int, y: Int }

type Direction = Up | Down | Left | Right

opposite : Direction -> Direction -> Bool
opposite a b =
    case ( a, b ) of
        ( Up, Down    ) -> True
        ( Down, Up    ) -> True
        ( Left, Right ) -> True
        ( Right, Left ) -> True
        ( x, y        ) -> False

type alias Snake =
    {
          dir  : Direction
        , body : List Point
    }

type alias Model =
    {
          alive          : Bool
        , size           : Size
        , apple          : Point
        , snake          : Snake
        , next_dir       : Maybe Direction
        , random_seed    : Random.Seed
        , next_move_time : Maybe Time
    }

init : ( Model, Effects Action )
init = ( init_model init_seed, Effects.tick Tick )

init_model : Random.Seed -> Model
init_model s =
    let ( apple_pos, seed ) = new_apple_position s world_size
    in
        Model True world_size apple_pos init_snake Nothing seed Nothing

init_snake : Snake
init_snake =
    Snake
        Up
        (
            List.map
                ( Point snake_start_x )
                [ snake_start_y .. ( snake_start_y + snake_start_length ) ]
        )

new_apple_position : Random.Seed -> Size -> ( Point, Random.Seed )
new_apple_position seed0 size =
    let
        genx = Random.int 2 ( size.width  - 1 )
        geny = Random.int 2 ( size.height - 1 )
        ( x, seed1 ) = Random.generate genx seed0
        ( y, seed2 ) = Random.generate geny seed1
    in
        ( Point x y, seed2 )

-- UPDATE

type alias KeyCode = Int

type Action = Tick Time | KeyPress KeyCode

update : Action -> Model -> ( Model, Effects Action )
update action model =
    case action of
        Tick now     -> ( frame model now, Effects.tick Tick )
        KeyPress key -> ( process_key model key, Effects.none )

process_key : Model -> KeyCode -> Model
process_key model key =
    case model.alive of
        True  -> alive_process_key model key
        False -> case key_to_dir key Nothing of
            Just a  -> model                         -- Ignore direction keys
            Nothing -> init_model model.random_seed  -- Restart on any other key

alive_process_key : Model -> KeyCode -> Model
alive_process_key model key =
    let new_dir =
        key_to_dir key model.next_dir
    in
       case new_dir of
           Nothing -> model
           Just d ->
               if opposite model.snake.dir d
                  then model
                  else { model | next_dir <- new_dir }

key_to_dir : KeyCode -> Maybe Direction -> Maybe Direction
key_to_dir key default = case key of
    37 -> Just Left
    38 -> Just Up
    39 -> Just Right
    40 -> Just Down
    _ -> default

frame : Model -> Time -> Model
frame model now =
    case model.next_move_time
    of
        Just t  -> if now >= t then time_step model now else model
        Nothing -> increase_frame_time now model

time_step : Model -> Time -> Model
time_step model now =
    case model.alive of
        True  -> increase_frame_time now ( eat_apple ( move_snake model ) )
        False -> model

increase_frame_time now model =
    let next_or_now =
        case model.next_move_time
        of
            Just t  -> t
            Nothing -> now
    in
       {
           model | next_move_time <- ( Just ( next_or_now + frame_time ) )
       }


eat_apple : Model -> Model
eat_apple model =
    case List.head model.snake.body of
        Nothing -> model  -- Snake is empty - won't happen
        Just h  ->
            if h == model.apple
               then
                   let ( apple_pos, seed ) =
                       new_apple_position model.random_seed world_size
                   in
                   {
                       model |
                           snake       <- grow_snake model.snake,
                           apple       <- apple_pos,
                           random_seed <- seed
                   }
               else model


grow_snake : Snake -> Snake
grow_snake snake =
    { snake | body <- snake.body ++ List.repeat 5 ( Point 0 0 ) }

move_snake : Model -> Model
move_snake model =
    let
        m = turn_snake model
        snake = move_snake_body m.snake
    in
        {
            m |
                alive <- ( still_alive snake m.size ),
                snake <- snake
        }


still_alive : Snake -> Size -> Bool
still_alive snake size =
    case List.head snake.body
    of
        Nothing -> False -- Snake is empty - won't happen
        Just head  -> (
               head.x /= 1
            && head.x /= size.width
            && head.y /= 1
            && head.y /= size.height
            && not ( hit_body head snake.body )
        )

hit_body : Point -> List Point -> Bool
hit_body head body =
    case List.tail body of
        Nothing -> False -- Snake is empty - won't happen
        Just t -> List.member head t

turn_snake : Model -> Model
turn_snake model =
    let
        snake = model.snake
    in
        {
            model |
                snake <-
                {
                    snake |
                        dir <- Maybe.withDefault snake.dir model.next_dir
                },
                next_dir <- Nothing
        }

move_snake_body : Snake -> Snake
move_snake_body snake =

    case List.tail snake.body
    of
        Just t  -> Snake snake.dir ( next_head_pos snake :: all_but_last snake.body )
        Nothing -> fail_snake -- Snake is empty - won't happen

all_but_last : List a -> List a
all_but_last l = List.take ( List.length l - 1 ) l

fail_snake : Snake
fail_snake = Snake Up [ Point 2 2, Point 3 3 ]

next_head_pos : Snake -> Point
next_head_pos snake =
    case List.head snake.body
    of
        Nothing -> Point 1 1 -- Snake is empty - won't happen
        Just head ->
            case snake.dir
            of
                Up    -> Point head.x ( head.y - 1 )
                Down  -> Point head.x ( head.y + 1 )
                Left  -> Point ( head.x - 1 ) head.y
                Right -> Point ( head.x + 1 ) head.y

-- VIEW

view : Signal.Address Action -> Model -> Html

view address model =
    div
        [
              tabindex 1
            , class "main_div"
            , onKeyDown address KeyPress
        ]
        [
            table
                [ class "game_table" ]
                ( game_trs model )
            --, text ( toString model.next_dir )
        ]

game_trs : Model -> List Html
game_trs model = List.map ( game_tr model ) [1..model.size.height]

game_tr : Model -> Int -> Html
game_tr model y = tr [ class "game_tr" ] ( game_tds model y )

game_tds : Model -> Int -> List Html
game_tds model y = List.map ( game_td model y ) [1..model.size.width]

game_td : Model -> Int -> Int -> Html
game_td model y x = td ( game_td_style model ( Point x y ) ) [ text "" ]


game_td_style : Model -> Point -> List Attribute
game_td_style model p = [ game_td_style_size model, game_td_class model p ]

game_td_style_size : Model -> Attribute
game_td_style_size model = style [ ( "width", "30px" ), ( "height", "30px" )]

game_td_class : Model -> Point -> Attribute
game_td_class model p = class ( "game_td " ++ game_td_class_dyn model p )

game_td_class_dyn : Model -> Point -> String
game_td_class_dyn model p =
    let nonwall = game_td_class_nonwall model p 
    in
        if nonwall /= ""
        then nonwall
        else
            if (
                p.x == 1 || p.x == model.size.width
                || p.y == 1 || p.y == model.size.height
            )
            then "wall"
            else ""

game_td_class_nonwall : Model -> Point -> String
game_td_class_nonwall model p =
    if p == model.apple
    then
        "apple"
    else
        case List.head model.snake.body of
            Nothing   -> ""
            Just head ->
                if p == head
                    then
                        if model.alive then "snake" else "snakedeadhead"
                    else
                        if List.member p model.snake.body then "snake" else ""


