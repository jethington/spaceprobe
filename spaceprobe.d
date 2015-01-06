import std.stdio;
import std.string;
import std.conv;
import std.typecons;
import std.random;
import std.algorithm;
import std.array;

// arguments: 
// 1. length/width of space
// 2. start x
// 3. start y
// 4. end x
// 5. end y
// ex: 20 0 0 19 19

// note: halved number of asteroids and gravity wells so there is more likely
//       to be a solution

void main(string[] args) {
  int width = to!int(args[1]);
  Tuple!(int, int) start = tuple(to!int(args[2]), to!int(args[3]));
  Tuple!(int, int) end = tuple(to!int(args[4]), to!int(args[5]));
  
  // initialize
  char[][] space;
  for (int i = 0; i < width; i++) {
    char[] row;
    for (int j = 0; j < width; j++) {
      row ~= '.';
    }
    space ~= row;
  }
  space[start[0]][start[1]] = 'S';
  space[end[0]][end[1]] = 'E';

  // place asteroids and black holes
  int asteroids = width^^2 * 3/20;
  int blackholes = width^^2 * 1/20;
  int[] locations;
  for (int i = 0; i < width^^2; i++) {
    // exclude start and end points
    if ((start[0] + start[1]*width == i) ||
        (end[0] + end[1]*width == i)) {
      continue;
    }
    locations ~= i;
  }
  randomShuffle(locations);
  for (int j = 0; j < asteroids; j++) {
    int x = locations[j] % width;
    int y = locations[j] / width;
    space[x][y] = 'A';
  }
  for (int k = asteroids; k < asteroids+blackholes; k++) {
    int x = locations[k] % width;
    int y = locations[k] / width;
    space[x][y] = 'G';
  }
  
  path(space, start);
  
  print(space);
}

void path(char[][] space, Tuple!(int, int) start) {
  int[][] weights;
  foreach (s; space) {
    int[] a;
    foreach (c; s) {
      if ((c == 'A') || (c == 'G')) {
        // -1 = can't travel
        a ~= -1;
      }
      else {
        // -2 = not visited yet
        a ~= -2;
      }
    }
    weights ~= a;
  }
  
  // eliminate squares around black holes
  int width = space.length; // assuming space is square
  for (int i = 0; i < width; i++) {
    for (int j = 0; j < width; j++) {
      if (space[i][j] == 'G') {
        // there must be a better way to write this
        if (i != 0) { 
          weights[i-1][j] = -1; // cross off left
        }
        if (i != width-1) {
          weights[i+1][j] = -1; // cross off right
        }
        if (j != 0) {
          weights[i][j-1] = -1; // cross off below
        }
        if (j != width-1) {
          weights[i][j+1] = -1; // cross off above
        }
        if ((i != 0) && (j != 0)) {
          weights[i-1][j-1] = -1; // below to left
        }
        if ((i != width-1) && (j != width-1)) {
          weights[i+1][j+1] = -1; // above to right
        }
        if ((i != 0) && (j != width-1)) {
          weights[i-1][j+1] = -1; // above to left
        }
        if ((i != width-1) && (j != 0)) {
          weights[i+1][j-1] = -1; // below to right
        }
      }
    }
  }
  
  // find optimal path
  bool[][] visited;
  for (int i = 0; i < width; i++) {
    bool[] a;
    for (int j = 0; j < width; j++) {
      if (weights[i][j] == -1) {
        a ~= true;
      }
      else {
        a ~= false;
      }
    }
    visited ~= a;
  }
  
  visited[start[0]][start[1]] = true;
  weights[start[0]][start[1]] = 0;
  
  // only works if starting at 0,0 ??? why?
  findweights(start, weights, visited);
  printpath(weights);
  writeln();
}

static Tuple!(int, int)[] queue;

void queueadd(Tuple!(int, int) point, ref bool[][] visited) {
  visited[point[0]][point[1]] = true;
  queue ~= point;
}

Tuple!(int, int) queueremove() {
  Tuple!(int, int) ret = queue[0];
  popFront(queue);
  return ret;
}

void findweights(Tuple!(int, int) point, ref int[][] weights, ref bool[][] visited) {
  int[] nextto;
  if (point[0] != 0) {
    nextto ~= weights[point[0]-1][point[1]];
  }
  if (point[0] != weights.length-1) {
    nextto ~= weights[point[0]+1][point[1]];
  }
  if (point[1] != 0) {
    nextto ~= weights[point[0]][point[1]-1];
  }
  if (point[1] != weights.length-1) {
    nextto ~= weights[point[0]][point[1]+1];
  }
  if ((point[0] != 0) && (point[1] != 0)) {
    nextto ~= weights[point[0]-1][point[1]-1];
  }
  if ((point[0] != weights.length-1) && (point[1] != weights.length-1)) {
    nextto ~= weights[point[0]+1][point[1]+1];
  }
  if ((point[0] != 0) && (point[1] != weights.length-1)) {
    nextto ~= weights[point[0]-1][point[1]+1];
  }
  if ((point[0] != weights.length-1) && (point[1] != 0)) {
    nextto ~= weights[point[0]+1][point[1]-1];
  }
  
  // if nextto is empty, must be start location, so leave weight as is
  if (nextto.length != 0) {
    nextto = filter!(a => a != -2)(nextto).array(); // not visited yet
    if (nextto.length != 0) {
      nextto = filter!(a => a != -1)(nextto).array(); // can't travel through these
    }
    if (nextto.length != 0) {
      weights[point[0]][point[1]] = (minCount(nextto))[0] + 1;
    }
  }
  
  // recursion
  if (point[0] != 0) {
    if (!visited[point[0]-1][point[1]]) {
      queueadd(tuple(point[0]-1, point[1]), visited);
    }
  }
  if (point[0] != weights.length-1) {
    if (!visited[point[0]+1][point[1]]) {
      queueadd(tuple(point[0]+1, point[1]), visited);
    }
  }
  if (point[1] != 0) {
    if (!visited[point[0]][point[1]-1]) {
      queueadd(tuple(point[0], point[1]-1), visited);
    }
  }
  if (point[1] != weights.length-1) {
    if (!visited[point[0]][point[1]+1]) {
      queueadd(tuple(point[0], point[1]+1), visited);
    }
  }
  if ((point[0] != 0) && (point[1] != 0)) {
    if (!visited[point[0]-1][point[1]-1]) {
      queueadd(tuple(point[0]-1, point[1]-1), visited);
    }
  }
  if ((point[0] != weights.length-1) && (point[1] != weights.length-1)) {
    if (!visited[point[0]+1][point[1]+1]) {
      queueadd(tuple(point[0]+1, point[1]+1), visited);
    }
  }
  if ((point[0] != 0) && (point[1] != weights.length-1)) {
    if (!visited[point[0]-1][point[1]+1]) {
      queueadd(tuple(point[0]-1, point[1]+1), visited);
    }
  }
  if ((point[0] != weights.length-1) && (point[1] != 0)) {
    if (!visited[point[0]+1][point[1]-1]) {
      queueadd(tuple(point[0]+1, point[1]-1), visited);
    }
  }
  
  if (queue.length != 0) {
    auto next = queueremove();
    findweights(next, weights, visited);
  }
}

void printpath(int[][] weights) {
  foreach (line; weights) {
    foreach (i; line) {
      string s = to!string(i);
      if (s.length == 1) {
        write("  ");
      }
      else if (s.length == 2) {
        write(" ");
      }
      write(s);
    }
    writeln("\n");
  }
}

void print(char[][] toprint) {
  foreach (line; toprint) {
    writeln(line);
  }
}