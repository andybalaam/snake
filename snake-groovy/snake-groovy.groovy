
/* Prerequisites:
sudo apt-get install groovy */

import groovy.swing.SwingBuilder
import javax.swing.WindowConstants as WC
import java.awt.*
import javax.swing.*
import java.util.Random  

class Direction
{
    static int UP    = 38 // Numbers are keyCodes
    static int DOWN  = 40
    static int LEFT  = 37
    static int RIGHT = 39
}

class KeyCode
{
    static int ESCAPE = 27
    static int SPACE  = 32
    static int RETURN = 10
}

class Colors
{
    static def snake         = [0, 255, 0]
    static def snakeDeadHead = [0, 0, 255]
    static def apple         = [255, 50, 50]
    static def wall          = [170, 170, 170]
    static def bg            = [0, 0, 0]
    static def border        = [70, 70, 100]
}

class ScaledGraphics
{
    Graphics2D gfx
    Dimension panelSize
    Integer[] gridSize

    Integer[] offset
    Double[] scale

    ScaledGraphics( gfx, panelSize, gridSize )
    {
        this.gfx = gfx
        this.panelSize = panelSize
        this.gridSize = gridSize

        def shortestLength = Math.min( panelSize.width, panelSize.height )

        this.scale = [
            (int)( shortestLength / gridSize[0] ),
            (int)( shortestLength / gridSize[1] )
        ]

        this.offset = [
            (int)( ( panelSize.width -  ( gridSize[0] * scale[0] ) ) / 2 ),
            (int)( ( panelSize.height - ( gridSize[1] * scale[1] ) ) / 2 )
        ]
    }

    def clear()
    {
        setColor( Colors.border )
        gfx.fillRect( 0, 0, (int)panelSize.width, (int)panelSize.height );

        setColor( Colors.bg )
        fillRect( [0, 0], gridSize );
    }

    def overlay()
    {
        gfx.setPaint( [128, 128, 128, 128] as Color )
        fillRect( [0, 0], gridSize );
    }

    def write( text )
    {
        gfx.setFont( new Font( "Ubuntu", Font.PLAIN, (int)( scale[0] * 1.3 ) ) );
        gfx.setColor( Color.white )
        gfx.setRenderingHint(
            RenderingHints.KEY_TEXT_ANTIALIASING,
            RenderingHints.VALUE_TEXT_ANTIALIAS_ON
        );

        FontMetrics fm = gfx.getFontMetrics();
        int x = ( panelSize.width - fm.stringWidth( text ) ) / 2
        int y = (
            fm.getAscent() +
            (
                panelSize.height - (
                    fm.getAscent() + fm.getDescent()
                )
            ) / 2
        )

        gfx.drawString( text, x, y )
    }

    def dot( color, gridPos )
    {
        setColor( color )
        fillRect( gridPos, [1, 1], 1 )
    }

    def fillRect( pos, sz, clip = 0 )
    {
        gfx.fillRect(
            (int)( offset[0] + scale[0] * pos[0] ),
            (int)( offset[1] + scale[1] * pos[1] ),
            (int)( scale[0] * sz[0] ) - clip,
            (int)( scale[1] * sz[1] ) - clip,
        )
    }

    def setColor( c )
    {
        gfx.setColor( c as Color )
    }
}



class SnakePanel extends JPanel
{
    Game game
    def gridSize

    public SnakePanel( gridSize )
    {
        this.game = null // Must set this before use
        this.gridSize = gridSize
    }

    @Override
    protected void paintComponent( Graphics g )
    {
        def scaledGfx = new ScaledGraphics( g, getSize(), gridSize );
        drawGrid( gridSize, scaledGfx )
    }

    def drawGrid( gridSize, scaledGfx )
    {
        scaledGfx.clear()
        for ( int x = 0; x < gridSize[0]; ++x )
        {
            scaledGfx.dot( Colors.wall, [x, 0] )
            scaledGfx.dot( Colors.wall, [x, gridSize[1] - 1] )
        }
        for ( int y = 0; y < gridSize[0]; ++y )
        {
            scaledGfx.dot( Colors.wall, [0, y] )
            scaledGfx.dot( Colors.wall, [gridSize[0] - 1, y] )
        }
        if ( game == null )
        {
            return
        }

        game.snakeBody.each {
            scaledGfx.dot( Colors.snake, it )
        }
        scaledGfx.dot( Colors.apple, game.applePos )

        if ( game.dead )
        {
            scaledGfx.dot( Colors.snakeDeadHead, game.snakeBody[0] )
            scaledGfx.overlay()
            scaledGfx.write( "Score: ${game.snakeBody.size()}.  Press SPACE." )
        }
    }
}

gridSize = [ 20, 20 ];

class Game
{
    def gridSize
    def rand
    def snakeBody;
    def snakeDirection;
    def nextDirection;
    def dead
    def applePos

    Game( gridSize, rand )
    {
        this.gridSize = gridSize
        this.rand = rand
        init()
    }
    
    def init()
    {
        this.snakeBody = [
            [ 10, 10 ],
            [ 10, 11 ],
            [ 10, 12 ],
            [ 10, 13 ],
            [ 10, 14 ],
        ]
        this.snakeDirection = Direction.UP
        this.nextDirection = Direction.UP
        this.dead = false
        moveApple()
    }

    void moveSnake()
    {
        snakeDirection = nextDirection
        for ( int i = snakeBody.size() - 1; i > 0; --i )
        {
            snakeBody[i] = snakeBody[i - 1]
        }
        snakeBody[0] = nextPos( snakeBody[0], snakeDirection )
    }

    def opposite( d1, d2 )
    {
        return (
               ( d1 == Direction.UP    && d2 == Direction.DOWN  )
            || ( d1 == Direction.DOWN  && d2 == Direction.UP    )
            || ( d1 == Direction.LEFT  && d2 == Direction.RIGHT )
            || ( d1 == Direction.RIGHT && d2 == Direction.LEFT  )
        )
    }

    def nextPos( pos, dir )
    {
        switch( dir )
        {
            case Direction.UP:    return [ pos[0],     pos[1] - 1 ]
            case Direction.DOWN:  return [ pos[0],     pos[1] + 1 ]
            case Direction.LEFT:  return [ pos[0] - 1, pos[1]     ]
            case Direction.RIGHT: return [ pos[0] + 1, pos[1]     ]
        }
    }

    def growSnake()
    {
        def lastPos = snakeBody.last()
        for ( i in 1..5 )
        {
            snakeBody.add( lastPos )
        }
    }

    def moveApple()
    {
        this.applePos = [
            1 + rand.nextInt( gridSize[0] - 2 ),
            1 + rand.nextInt( gridSize[1] - 2 ),
        ]
    }

    def isWall( pos )
    {
        return (
               pos[0] == 0
            || pos[0] == gridSize[0] - 1
            || pos[1] == 0
            || pos[1] == gridSize[0] - 1
        );
    }

    def isApple( pos )
    {
        return ( pos == applePos )
    }

    def keyPressed( keyCode )
    {
        switch( keyCode )
        {
            case Direction.UP:
            case Direction.DOWN:
            case Direction.LEFT:
            case Direction.RIGHT:
                if ( !opposite( snakeDirection, keyCode ) )
                {
                    nextDirection = keyCode
                }
                break
            case KeyCode.ESCAPE:
                System.exit( 0 )
                break
            case KeyCode.SPACE:
            case KeyCode.RETURN:
                if ( dead )
                {
                    init()
                }
                break
            default:
                break
        }
    }

    def isBody( pos )
    {
        for ( int i = 1; i < snakeBody.size(); ++i )
        {
            if ( pos == snakeBody[i] )
            {
                return true;
            }
        }
        return false;
    }

    def step()
    {
        if ( dead )
        {
            return
        }

        moveSnake()
        def head = snakeBody[0]
        if ( isApple( head ) )
        {
            growSnake()
            moveApple()
        }
        else if ( isWall( head ) || isBody( head ) )
        {
            dead = true;
        }
    }
}

def swing = SwingBuilder.build()
{
    frame(
        id:'frame',
        title:'Snake in Groovy',
        size:[600, 600], 
        location:[200, 200],
        visible:true,
        defaultCloseOperation:WC.EXIT_ON_CLOSE,
    )
    {
        panel( new SnakePanel( gridSize ), id:'canvas' )
    }
}

def canvas = swing.canvas;
def frame = swing.frame;

Random rand = new Random()  
def game = new Game( gridSize, rand );

frame.keyPressed = { game.keyPressed( it.keyCode ) }
canvas.game = game

while( true )
{
    frame.repaint()
    sleep( 100 )
    game.step()
}

