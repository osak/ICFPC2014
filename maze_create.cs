using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
namespace MazeCreator
{
    class maze_create
    {
        static void Main(string[] args)
        {
            const int level = 1;
            const int sead = 1;
            var creator = new MazeCreator(level,sead);
            var maze = creator.CreateMaze();
            var h = maze.GetLength(0);
            var w = maze.GetLength(1);
            var sb = new StringBuilder();
            for (int i = 0; i < h; i++)
            {
                for (int j = 0; j < w; j++)
                    sb.Append(maze[i, j]);
                sb.AppendLine();
            }
            Console.WriteLine(sb.ToString());
        }
    }
    class MazeCreator
    {
        public MazeCreator(int level)
        {
            this.Level = level;
            var r = new Random();
            this.Sead = r.Next();
            this.rand = new Random(Sead);
        }
        public MazeCreator(int level,int sead)
        {
            this.Level = level;
            this.Sead = sead;
            this.rand = new Random(Sead);
        }

        //迷路のレベル
        public int Level { get; set; }

        //迷路生成全体で使うための乱数のシード
        public int Sead { get; private set; }
        private Random rand;


        public char[,] CreateMaze()
        {
            var size = determineSize();
            var w = size.L;
            var h = size.R;
            var maze = new char[h, w];
            putWall(maze);
            var start = determinePosition(maze);
            putPill(start, maze);
            maze[start.L, start.R] = '\\';

            return maze;
        }

        //壁を置く(アルゴリズムをいくつか用意しないといろんなケースを用意できなさそう)
        //現在は棒倒し法(格子上にはじめに壁を置いて，そこからマンハッタン距離1のところに壁生やすみたいなことをする)
        private void putWall(char[,] maze)
        {
            var h = maze.GetLength(0);
            var w = maze.GetLength(1);
            var dh = new int[] { 0, 1, 0, -1 };
            var dw = new int[] { -1, 0, 1, 0 };

            for (int i = 1; i < h; i += 2)
                for (int j = 1; j < w; j += 2)
                    maze[i, j] = '#';
            for (int i = 1; i < h; i+=2)
                for (int j = 1; j < w; j += 2)
                {
                    do
                    {
                        var d = this.rand.Next() % 4;
                        var nh = i + dh[d];
                        var nw = j + dw[d];
                        if (nh < 0 || nh >= h || nw < 0 || nw >= w)
                            continue;
                        if (maze[nh, nw] == '#')
                            continue;
                        maze[i + dh[d], j + dw[d]] = '#';
                        break;
                    } while (true);
                   
                    
                }
            
        }
        //Lambdaマンのスタート地点から幅優先探索でpillを置く
        private void putPill(Pair<int> start,char[,]maze)
        {
            var q = new Queue<Pair<int>>();
            q.Enqueue(start);
            var h = maze.GetLength(0);
            var w = maze.GetLength(1);
            var dh = new int[] { 0, 1, 0, -1 };
            var dw = new int[] { -1, 0, 1, 0 }; 
            while (q.Any())
            {
                var p = q.Dequeue();
                var ph = p.L;
                var pw = p.R;
                for (int i = 0; i < 4; i++)
                {
                    var nh = ph + dh[i];
                    var nw = pw + dw[i];
                    if (nh < 0 || nh >= h || nw < 0 || nw >= w)
                        continue;
                    if (maze[nh, nw] == '#') continue;
                    if (maze[nh, nw] == '.') continue;
                    maze[nh, nw] = '.';
                    q.Enqueue(new Pair<int>(nh, nw));
                }
            }
            
 
        }

        //迷路のサイズ決定
        Pair<int> determineSize()
        {
            var max = this.Level * 100;
            var min = max - 100;
            do
            {
                var h = (this.rand.Next() % 256) + 1;
                var w = (this.rand.Next() % 256) + 1;
                var size = w * h;
                if (min < size && size <= max)
                    return new Pair<int>(h, w);
                
            } while (true);
        }

        //壁でない座標をランダムに返す
        Pair<int> determinePosition(char[,] maze)
        {
            var h = maze.GetLength(0);
            var w = maze.GetLength(1);
            do
            {
                var ph = this.rand.Next() % h;
                var pw = this.rand.Next() % w;
                if (maze[ph, pw] == '#') continue;
                return new Pair<int>(ph, pw);
            } while (true);
        }
 
    }

    public struct Pair<T>
    {
        public T L { get; set; }
        public T R { get; set; }
        public Pair(T l, T r)
            : this()
        {
            L = l;
            R = r;
        }
        public override string ToString()
        {
            return string.Format("{0} {1}", L, R);
        }
    }
}
