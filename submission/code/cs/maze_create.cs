using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.IO;
namespace MazeCreator
{
    class maze_create
    {
        static void Main(string[] args)
        {

            //args = new string[] { "--w=16", "--h=16", "--s=4", "--a=fuga.txt", "--d=0.8", "--g=20", "--pd=0.1"};
            int? h = null, w = null, s = null, g = null;
            double? d = null, pd = null;
            string o = null;
            if (args.Length > 0)
                processArgs(args, ref h, ref w,ref d,ref pd,ref g, ref s, ref o);
            var creator = new MazeCreator(h, w, d,pd, g, s);
            var maze = creator.CreateMaze();
            if (o != null)
            {
                using (var sw = new StreamWriter(o))
                    WriteMaze(maze, sw);
            }
            else WriteMaze(maze, Console.Out);
        }
        
        // --w=X : width=X
        // --h=X : height=X
        // --s=X : sead=X
        // --o=X : outputFilePath=X
        static void processArgs(string[] args, ref int? h, ref int? w, ref double? d,ref double?pd, ref int? g, ref int? s, ref string o)
        {
            var width = new Regex(@"--w=(\d+)");
            var height = new Regex(@"--h=(\d+)");
            var sead = new Regex(@"--s=(\d+)");
            var dencity = new Regex(@"--d=0.(\d+)");
            var powerPillDencity = new Regex(@"--pd=0.(\d+)");
            var ghostSize = new Regex(@"--g=(\d+)");
            var output = new Regex(@"--o=(.+)");
            foreach (var x in args)
            {
                if (width.IsMatch(x))
                    w = int.Parse(width.Match(x).Groups[1].Value);
                else if (height.IsMatch(x))
                    h = int.Parse(height.Match(x).Groups[1].Value);
                else if (sead.IsMatch(x))
                    s = int.Parse(sead.Match(x).Groups[1].Value);
                else if (output.IsMatch(x))
                    o = output.Match(x).Groups[1].Value;
                else if (dencity.IsMatch(x))
                    d = double.Parse("0." + dencity.Match(x).Groups[1].Value);
                else if (powerPillDencity.IsMatch(x))
                    pd = double.Parse("0." + dencity.Match(x).Groups[1].Value);
                else if (ghostSize.IsMatch(x))
                    g = int.Parse(ghostSize.Match(x).Groups[1].Value);
            }

        }
        static void WriteMaze(char[,] maze,TextWriter writer)
        {
            var h = maze.GetLength(0);
            var w = maze.GetLength(1);
            var sb = new StringBuilder();
            var wall = new string(Symbol.Wall, w+2);
            sb.AppendLine(wall);
            for (int i = 0; i < h; i++)
            {
                sb.Append(Symbol.Wall);
                for (int j = 0; j < w; j++)
                    sb.Append(maze[i, j]);
                sb.Append(Symbol.Wall);
                sb.AppendLine();
            }
            sb.Append(wall);
            var output = sb.ToString();
            writer.WriteLine(output);
        }

    }
    static class Symbol
    {
        public const char LambdaMan = '\\';
        public const char Ghost = '=';
        public const char Fruit = '%';
        public const char Pill = '.';
        public const char Wall = '#';
        public const char PowerPill = 'o';
        public const char Empty = ' ';
    }

    class MazeCreator
    {
        public MazeCreator(int? h, int? w, double? dencity, double? powerPillDencity, int? ghosts, int? sead)
        {
            this.rand = (sead != null) ? new Random(sead.Value) : new Random();
            var height = h??1 + (rand.Next() % 256);
            var width = w??1 + (rand.Next() % 256);
            this.Size = new Pair<int>(height, width);
            Dencity = dencity ?? rand.NextDouble();
            PowerPillDencity = powerPillDencity ?? rand.NextDouble();
            GhostSize = ghosts ?? rand.Next() % 257;
        }

        //迷路のレベル
        public int Level { get; set; }
        public Pair<int>? Size { get; set; }
        //迷路生成全体で使うための乱数のシード
        public int Sead { get; private set; }
        private Random rand;
        //Pillの密度
        public double Dencity { get; private set; }
        //PowerPillの密度
        public double PowerPillDencity { get; private set; }
        //Ghostの最大数
        public int GhostSize { get; private set; }
        public char[,] CreateMaze()
        {
            var size = determineSize();
            var w = size.L-2;
            var h = size.R-2;
            var maze = new char[h, w];
            //'#' と' 'を設置
            for (int i = 0; i < h; i++)
                for (int j = 0; j < w; j++)
                    maze[i, j] = Symbol.Empty;
            putWall(maze);
            //スタート位置の決定，pillの設置，fruitの設置
            var start = determinePosition(maze,Symbol.Wall);
            var pills = putPill(start, maze).ToArray();
            maze[start.L, start.R] = Symbol.LambdaMan;
            var fruit = determinePosition(maze, Symbol.Wall, Symbol.LambdaMan, Symbol.Empty);
            maze[fruit.L, fruit.R] = Symbol.Fruit;
            
            //pillを' 'にする
            var pillToEmpty = (int)(pills.Length * (1.0 - Dencity));
            randomSet(pills, maze, Symbol.Empty, pillToEmpty);
            pills = enumeratePosition(maze, Symbol.Wall, Symbol.LambdaMan, Symbol.Empty, Symbol.Fruit).ToArray();

            //pillをpowerpillにする
            var powerPills = (int)(pills.Length * PowerPillDencity);
            randomSet(pills, maze, Symbol.PowerPill, powerPills);

            //ghostの設置
            var canPutGhost = enumeratePosition(maze, Symbol.Wall, Symbol.LambdaMan, Symbol.Fruit).ToArray();
            randomSet(canPutGhost, maze, Symbol.Ghost, Math.Min(canPutGhost.Length, GhostSize));


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
                    maze[i, j] = Symbol.Wall;
            for (int i = 1; i < h; i += 2)
                for (int j = 1; j < w; j += 2)

                    for (int k = 0; k < 1000; k++)
                    {
                        var d = this.rand.Next() % 4;
                        int nh = i + dh[d], nw = j + dw[d];
                        if (nh < 0 || nh >= h || nw < 0 || nw >= w)
                            continue;
                        if (maze[nh, nw] == Symbol.Wall)
                            continue;
                        maze[i + dh[d], j + dw[d]] = Symbol.Wall;
                        break;
                    }
        }
        private void randomSet(Pair<int>[] positions, char[,] maze, char symbol, int size)
        {
            size = Math.Min(size, positions.Length);
            foreach (var x in positions.OrderBy(x => rand.Next()).Take(size))
                maze[x.L, x.R] = symbol; 
        }

        //Lambdaマンのスタート地点から幅優先探索でpillを置く
        //pillの座標を返す
        private IEnumerable<Pair<int>> putPill(Pair<int> start, char[,] maze)
        {
            var q = new Queue<Pair<int>>();
            q.Enqueue(start);
            int h = maze.GetLength(0), w = maze.GetLength(1);
            var dh = new int[] { 0, 1, 0, -1 };
            var dw = new int[] { -1, 0, 1, 0 };
            maze[start.L, start.R] = Symbol.Wall;
            while (q.Any())
            {
                var p = q.Dequeue();
                int ph = p.L, pw = p.R;
                for (int i = 0; i < 4; i++)
                {
                    int nh = ph + dh[i], nw = pw + dw[i];
                    if (nh < 0 || nh >= h || nw < 0 || nw >= w)
                        continue;
                    if (maze[nh, nw] == Symbol.Wall) continue;
                    if (maze[nh, nw] == Symbol.Pill) continue;
                    maze[nh, nw] = Symbol.Pill;
                    var np = new Pair<int>(nh, nw);
                    q.Enqueue(np);
                    yield return np;
                }
            }
            maze[start.L, start.R] = Symbol.Empty;

        }

        //迷路のサイズ決定
        Pair<int> determineSize()
        {
            if (this.Size != null)
                return this.Size.Value;
            var max = this.Level * 100;
            var min = max - 100;
            do
            {
                var h = (this.rand.Next() % 256) + 1;
                var w = (this.rand.Next() % 256) + 1;
                var size = w * h;
                if (min < size && size <= max)
                {
                    this.Size = new Pair<int>(h, w);
                    return this.Size.Value;
                }

            } while (true);
        }

        //指定したシンボルでない座標をランダムに返す
        Pair<int> determinePosition(char[,] maze,params char[] forbidden)
        {
            int h = maze.GetLength(0), w = maze.GetLength(1);
            for (int k = 0; k < 100000; k++)
            {
                var ph = this.rand.Next() % h;
                var pw = this.rand.Next() % w;
                if (forbidden.Contains(maze[ph, pw])) continue;
                return new Pair<int>(ph, pw);
            }
            throw new TimeoutException("指定回数内に座標が得られませんでした");
        }
        private IEnumerable<Pair<int>> enumeratePosition(char[,] maze, params char[] forbidden)
        {
            int h = maze.GetLength(0), w = maze.GetLength(1);
            for (int i = 0; i < h; i++)
                for (int j = 0; j < w; j++)
                    if (!forbidden.Contains(maze[i, j]))
                        yield return new Pair<int>(i, j);
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
