#!/usr/bin/env python3
"""Generates the room layouts in scripts/rooms.gd.

Makes thousands of random rooms, keeps only the ones that pass every check,
then picks 100 spread from easiest to hardest. Run it from the repo root:

    python3 tools/generate_rooms.py [seed]

A room passes when:
  * the exit is reachable from wherever you enter,
  * there is nowhere you can get stuck (alive, but unable to reach the exit),
    including after cracked walls are broken and you drop back in from below,
  * it takes at least MIN_SWIPES swipes, so no room is a free pass,
  * the same is true with its fake tiles turned on (they act as pits).

Legend: # wall, . floor, c coin, ^ spikes, x cracked wall, S start,
f fake floor, F fake floor with a coin on it (bait). Fake tiles are normal
floor except on trap floors, where they drop you out of the tower.
"""
import random
import sys
from collections import deque

W, H = 13, 12
DOOR = W // 2
COUNT = 100
MIN_SWIPES = 3
MAX_SWIPES = 12
DIRS = [(0, -1), (0, 1), (-1, 0), (1, 0)]


def tile(room, x, y, broken, fakes_deadly):
    if y < 0:
        return 'TOP' if x == DOOR and room[0][x] != '#' else '#'
    if y >= H:
        return 'BOT' if x == DOOR and room[H - 1][x] != '#' else '#'
    if x < 0 or x >= W:
        return '#'
    t = room[y][x]
    if t == 'x' and (x, y) in broken:
        return '.'
    if t in 'fF':
        return '^' if fakes_deadly else '.'
    return t


def slide(room, x, y, d, broken, fakes_deadly, path=None):
    dx, dy = d
    while True:
        t = tile(room, x + dx, y + dy, broken, fakes_deadly)
        if t == '#':
            return ('stop', x, y, None)
        if t == 'x':
            return ('stop', x, y, (x + dx, y + dy))
        if t == 'TOP':
            return ('win',)
        if t == 'BOT':
            return ('below',)
        x, y = x + dx, y + dy
        if path is not None:
            path.append((x, y))
        if t == '^':
            return ('dead',)


def analyse(room, fakes_deadly=False):
    """Returns (swipes, stuck_count, states, traversed, route_cells) or None."""
    start = None
    for y in range(H):
        for x in range(W):
            if room[y][x] == 'S':
                start = (x, y)
    def enter(b):
        return slide(room, DOOR, H, (0, -1), b, fakes_deadly)
    if start:
        init = (start[0], start[1], frozenset())
    else:
        r = enter(frozenset())
        if r[0] != 'stop':
            return None
        init = (r[1], r[2], frozenset([r[3]]) if r[3] else frozenset())
    seen = {init}
    q = deque([init])
    edges = {}
    wins = set()
    traversed = set()
    while q:
        s = q.popleft()
        edges.setdefault(s, [])
        if s[0] == 'below':
            continue
        x, y, b = s
        for d in DIRS:
            path = []
            r = slide(room, x, y, d, b, fakes_deadly, path)
            if r[0] != 'dead':
                traversed.update(path)
            if r[0] == 'win':
                wins.add(s)
                continue
            if r[0] == 'dead':
                continue
            if r[0] == 'below':
                if start:
                    continue
                n = ('below', 0, b)
                edges[s].append((n, d))
                if n not in seen:
                    seen.add(n)
                    edges[n] = []
                    e = enter(b)
                    if e[0] == 'win':
                        wins.add(n)
                    elif e[0] == 'stop':
                        m = (e[1], e[2], b | {e[3]} if e[3] else b)
                        edges[n].append((m, (0, -1)))
                        if m not in seen:
                            seen.add(m)
                            q.append(m)
                continue
            nb = b | {r[3]} if r[3] else b
            n = (r[1], r[2], frozenset(nb))
            if n == s:
                continue
            edges[s].append((n, d))
            if n not in seen:
                seen.add(n)
                q.append(n)
    can = set(wins)
    changed = True
    while changed:
        changed = False
        for s, ns in edges.items():
            if s not in can and any(n in can for n, _ in ns):
                can.add(s)
                changed = True
    stuck = [s for s in seen if s not in can]
    # Shortest route, and the cells it slides over.
    prev = {init: None}
    q = deque([init])
    goal = None
    while q:
        s = q.popleft()
        if s in wins:
            goal = s
            break
        for n, d in edges[s]:
            if n not in prev:
                prev[n] = (s, d)
                q.append(n)
    if goal is None:
        return None
    swipes = 1
    route = []
    s = goal
    while prev[s] is not None:
        p, d = prev[s]
        swipes += 1
        if p[0] != 'below':
            path = []
            slide(room, p[0], p[1], d, p[2], fakes_deadly, path)
            route.extend(path)
        s = p
    return swipes, len(stuck), len(seen), traversed, set(route)


def blank():
    room = [['#'] * W for _ in range(H)]
    for y in range(1, H - 1):
        for x in range(1, W - 1):
            room[y][x] = '.'
    room[0][DOOR] = '.'
    room[H - 1][DOOR] = '.'
    return room


def random_room(rng):
    room = blank()
    for _ in range(rng.randint(10, 24)):
        x, y = rng.randint(1, W - 2), rng.randint(1, H - 2)
        dx, dy = rng.choice([(1, 0), (0, 1)])
        for i in range(rng.choice([1, 1, 2, 2, 3])):
            cx, cy = x + dx * i, y + dy * i
            if 1 <= cx <= W - 2 and 1 <= cy <= H - 2:
                room[cy][cx] = '#'
    for ch, lo, hi in (('^', 0, 7), ('x', 0, 3)):
        for _ in range(rng.randint(lo, hi)):
            x, y = rng.randint(1, W - 2), rng.randint(1, H - 2)
            if room[y][x] == '.':
                room[y][x] = ch
    # Keep the doorway clear.
    room[H - 2][DOOR] = '.' if room[H - 2][DOOR] != 'x' else 'x'
    return room


def valid(room, fakes_deadly):
    a = analyse(room, fakes_deadly)
    if a is None:
        return None
    swipes, stuck, states, traversed, route = a
    if stuck or not (MIN_SWIPES <= swipes <= MAX_SWIPES):
        return None
    return a


def add_coins_and_fakes(room, rng, info):
    swipes, _, _, traversed, route = info
    traversed = {c for c in traversed if 0 < c[1] < H - 1}
    route = {c for c in route if 0 < c[1] < H - 1}
    open_cells = [c for c in traversed if room[c[1]][c[0]] == '.']
    off_route = [c for c in open_cells if c not in route]
    rng.shuffle(off_route)
    on_route = [c for c in open_cells if c in route]
    rng.shuffle(on_route)
    for x, y in off_route[:rng.randint(3, 6)] + on_route[:2]:
        room[y][x] = 'c'
    # Fakes: try tempting cells first (on the quickest route, or under a coin).
    candidates = [c for c in route if room[c[1]][c[0]] in '.c']
    rng.shuffle(candidates)
    others = [c for c in traversed if c not in route and room[c[1]][c[0]] in '.c']
    rng.shuffle(others)
    fakes = 0
    for x, y in candidates + others:
        if fakes >= 3:
            break
        if (x, y) == (DOOR, H - 2):
            continue
        old = room[y][x]
        room[y][x] = 'F' if old == 'c' else 'f'
        if valid(room, True):
            fakes += 1
        else:
            room[y][x] = old
    return fakes


def score(room, info):
    swipes, _, states, _, _ = info
    flat = ''.join(''.join(r) for r in room)
    return swipes * 2 + flat.count('^') * 0.8 + flat.count('x') * 1.2 + states * 0.05


def key(room):
    a = '\n'.join(''.join(r) for r in room)
    b = '\n'.join(''.join(reversed(r)) for r in room)
    return min(a, b)


def main():
    seed = int(sys.argv[1]) if len(sys.argv) > 1 else 2026
    rng = random.Random(seed)
    found = {}
    attempts = 0
    while len(found) < 1500 and attempts < 400000:
        attempts += 1
        room = random_room(rng)
        info = valid(room, False)
        if info is None:
            continue
        fakes = add_coins_and_fakes(room, rng, info)
        if fakes < 2:
            continue
        info = valid(room, False)
        if info is None or not valid(room, True):
            continue
        k = key(room)
        if k not in found:
            found[k] = (score(room, info), [''.join(r) for r in room])
    ranked = sorted(found.values())
    picks = [ranked[round(i * (len(ranked) - 1) / (COUNT - 1))] for i in range(COUNT)]
    print(f"{attempts} attempts, {len(found)} valid rooms, kept {len(picks)}", file=sys.stderr)
    write(picks, seed)


START_ROOM = [
    "######.######",
    "#...........#",
    "#.c.c.c.c.c.#",
    "#...........#",
    "######.######",
    "#......#....#",
    "#...........#",
    "#...........#",
    "#c....S....c#",
    "#...........#",
    "#....#......#",
    "#############",
]


def write(picks, seed):
    out = ['extends RefCounted',
           '## Room layouts. Generated by tools/generate_rooms.py (seed %d); do not edit by hand.' % seed,
           '##',
           '## Rooms are 13 wide and 12 tall and join through a door in column 6.',
           '##   #  wall          c  coin           x  cracked wall (stops you once, then crumbles)',
           '##   .  floor         ^  spikes         S  start',
           '##   f  fake floor    F  fake floor with a coin on it',
           '## Fake floor is ordinary floor, except on trap floors (every 30th),',
           '## where it gives way under you.',
           '',
           'const START := [']
    out += ['\t"%s",' % r for r in START_ROOM]
    out += [']', '', '## Easiest first, hardest last.', 'const LAYOUTS := [']
    for i, (sc, rows) in enumerate(picks):
        out.append('\t[  # %d' % i)
        out += ['\t\t"%s",' % r for r in rows]
        out.append('\t],')
    out.append(']')
    open('scripts/rooms.gd', 'w').write('\n'.join(out) + '\n')


if __name__ == '__main__':
    # Sanity-check the hand-made start room before writing anything.
    a = analyse([list(r) for r in START_ROOM])
    assert a and a[1] == 0, 'start room has stuck spots'
    main()
