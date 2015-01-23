// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:html';

//import 'package:snake/nav_menu.dart';
//import 'package:snake/reverser.dart';
//import 'package:route_hierarchical/client.dart';

import 'dart:math';

void main()
{
  var rand = new Random();
  Game game = new Game( 20, 20, rand );

  CanvasElement canvas = document.querySelector( "#canvas" );
  DivElement text = document.querySelector( "#textdiv" );

  Renderer renderer = new Renderer( canvas, text, game );

  GameLoop gameLoop = new GameLoop( renderer, game );

  window.onKeyDown.listen( gameLoop.key );
  window.requestAnimationFrame( gameLoop.frame );
}

class Colours
{
  static const String bg            = '#000000';
  static const String border        = '#464664';
  static const String wall          = '#aaaaaa';
  static const String apple         = '#ff3232';
  static const String snake         = '#00ff00';
  static const String snakeDeadHead = '#0000ff';
}

class Dir
{
  static const int none  = -1;
  static const int up    = 0;
  static const int down  = 1;
  static const int left  = 2;
  static const int right = 3;
}

int opposite( int dir )
{
  switch ( dir )
  {
    case Dir.up:    return Dir.down;
    case Dir.down:  return Dir.up;
    case Dir.left:  return Dir.right;
    case Dir.right: return Dir.left;
  }
  return Dir.none;
}

class GameLoop
{
  Renderer renderer;
  Game game;
  int nextTime;
  int frameTime;
  int nD = Dir.none;

  GameLoop( this.renderer, this.game  )
  {
    frameTime = 200;
    nextTime = 0;
  }

  void key( KeyboardEvent e )
  {
    switch( e.keyCode )
    {
      case KeyCode.UP:    nextDir = Dir.up;    break;
      case KeyCode.DOWN:  nextDir = Dir.down;  break;
      case KeyCode.LEFT:  nextDir = Dir.left;  break;
      case KeyCode.RIGHT: nextDir = Dir.right; break;
      default:
        if ( game.dead )
        {
          nextTime = 0;
          game.reset();
          window.requestAnimationFrame( frame );
        }
        break;
    }
  }

  int get nextDir => nD;
  set nextDir( int val )
  {
    if ( val != opposite( game.snake_dir ) )
    {
      nD = val;
    }
  }

  void frame( num time )
  {
    if ( time > nextTime )
    {
      game.step( nextDir );
      renderer.draw();
      nextDir = Dir.none;
      nextTime += frameTime;
      if ( time > nextTime )
      {
        nextTime = time.toInt() + frameTime;
      }
    }

    if ( !game.dead )
    {
      window.requestAnimationFrame( frame );
    }
  }
}

class Game
{
  int width;
  int height;
  Random rand;

  Point apple;

  List<Point> snake;
  int snake_dir;
  bool dead;

  Game( this.width, this.height, this.rand )
  {
    reset();
  }

  void moveApple()
  {
    apple = new Point(
      1 + rand.nextInt( width  - 2 ),
      1 + rand.nextInt( height - 2 )
    );
  }

  void step( int dir )
  {
    if ( dir != Dir.none )
    {
      snake_dir = dir;
    }

    for ( int i = snake.length - 1; i > 0; --i )
    {
      snake[i] = snake[i-1];
    }

    switch ( snake_dir )
    {
      case Dir.up:    snake[0] = new Point( snake[0].x, snake[0].y - 1 ); break;
      case Dir.down:  snake[0] = new Point( snake[0].x, snake[0].y + 1 ); break;
      case Dir.left:  snake[0] = new Point( snake[0].x - 1, snake[0].y ); break;
      case Dir.right: snake[0] = new Point( snake[0].x + 1, snake[0].y ); break;
    }

    Point head = snake[0];
    if ( head.x < 1 || head.y < 1 || head.x >= width - 1 || head.y >= height - 1 )
    {
      dead = true;
    }

    if ( head == apple )
    {
      growSnake();
      moveApple();
    }
    else
    {
      for ( int i = 1; i < snake.length; ++i )
      {
        if ( snake[i] == head )
        {
          dead = true;
        }
      }
    }
  }

  void growSnake()
  {
    var tail = snake.last;
    for ( int i = 0; i < 5; ++i )
    {
      snake.add( tail );
    }
  }

  void reset()
  {
    snake = new List<Point>();
    moveApple();

    snake.add( new Point( 10, 10 ) );
    snake.add( new Point( 10, 11 ) );
    snake.add( new Point( 10, 12 ) );
    snake.add( new Point( 10, 13 ) );
    snake.add( new Point( 10, 14 ) );
  
    snake_dir = Dir.up;
    dead = false;
  }
}


class Renderer
{
  CanvasElement canvas;
  DivElement text;
  Game game;
  CanvasRenderingContext2D ctx;
  double mult_x;
  double mult_y;
  double off_x;
  double off_y;

  Renderer( this.canvas, this.text, this.game )
  {
    this.ctx = canvas.getContext("2d");

    int minDim = ( canvas.width < canvas.height )
      ? canvas.width
      : canvas.height;

    this.mult_x = minDim / game.width;
    this.mult_y = minDim / game.height;
    this.off_x = 0.5 * ( canvas.width  - game.width  * mult_x );
    this.off_y = 0.5 * ( canvas.height - game.height * mult_y );
  }

  void draw()
  {
    ctx.fillStyle = Colours.border;
    ctx.fillRect( 0, 0, canvas.width, canvas.height );

    ctx.fillStyle = Colours.bg;
    ctx.fillRect( off_x, off_y, game.width * mult_x, game.height * mult_y );

    for ( int i = 0; i < game.width; ++i )
    {
      square( Colours.wall, i, 0 );
      square( Colours.wall, i, game.height - 1 );
    }

    for ( int i = 0; i < game.height; ++i )
    {
      square( Colours.wall, 0, i );
      square( Colours.wall, game.width - 1, i );
    }

    for ( Point p in game.snake )
    {
      square( Colours.snake, p.x, p.y );
    }

    if ( game.dead )
    {
      square( Colours.snakeDeadHead, game.snake[0].x, game.snake[0].y );
      text.style.visibility = "visible";
      text.innerHtml = "Score: " + game.snake.length.toString() + ".<br/>Press SPACE.";
    }
    else
    {
      text.style.visibility = "hidden";
    }

    square( Colours.apple, game.apple.x, game.apple.y );
  }

  void square( String colour, int x, int y )
  {
    ctx.fillStyle = colour;
    ctx.fillRect( off_x + x*mult_x, off_y + y*mult_y, mult_x - 1, mult_y -1 );
  }
}

