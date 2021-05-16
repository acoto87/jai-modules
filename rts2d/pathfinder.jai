// NOTE: this value is the distance squared to avoid dynamic units
// so if the dynamic entity at a distance squared less than this value,
// treat it like a static one, so the unit can get around it and the risk of
// overlapping units is less
DISTANCE_SQR_AVOID_DYNAMIC_POSITIONS : f32 : 2.0;

PathFindingType :: enum u16 {
    Bfs;
    Astar;
}

PathFinderDataType :: enum u16 {
    Empty;
    Static;
    Dynamic;
}

MapPath :: struct {
    nodes: List(Vec2i);
}

PathFinder :: struct {
    type: PathFindingType;
    width: s32;
    height: s32;
    data: *u16;
}

getTileValue :: inline (finder: PathFinder, position: Vec2i) -> u16 {
    assert(isInside(finder, position));
    return finder.data[position.y * finder.width + position.x];
}

setTileValue :: inline (finder: PathFinder, position: Vec2i, value: u16) {
    assert(isInside(finder, position));
    finder.data[position.y * finder.width + position.x] = value;
}

setTilesValue :: (finder: PathFinder, area: Recti, value: u16) {
    if (area.x < 0 || area.x >= finder.width) return;
    if (area.y < 0 || area.y >= finder.height) return;

    if (area.x + area.w >= finder.width) {
        area.w = finder.width - area.x;
    }

    if (area.y + area.h >= finder.height) {
        area.h = finder.height - area.y;
    }

    endX := area.x + area.w;
    endY := area.y + area.h;

    for y : range(s32, area.y, endY) {
        for x : range(s32, area.x, endX) {
            setTileValue(finder, vec2i(x, y), value);
        }
    }
}

setFreeTiles :: inline (finder: PathFinder, area: Recti) {
    setTilesValue(finder, area, cast(u16) PathFinderDataType.Empty);
}

setStaticEntity :: inline (finder: PathFinder, area: Recti, id: EntityId) {
    setTilesValue(finder, area, (id << 4) | cast(u16) PathFinderDataType.Static);
}

setDynamicEntity :: inline (finder: PathFinder, area: Recti, id: EntityId) {
    setTilesValue(finder, area, (id << 4) | cast(u16) PathFinderDataType.Dynamic);
}

getTileValueType :: inline (finder: PathFinder, position: Vec2i) -> u16 {
    return getTileValue(finder, position) & 0x000F;
}

getTileEntityId :: inline (finder: PathFinder, position: Vec2i) -> EntityId {
    return (getTileValue(finder, position) & 0xFFF0) >> 4;
}

isEmpty :: inline (finder: PathFinder, position: Vec2i) -> bool {
    return getTileValueType(finder, position) == cast(u16) PathFinderDataType.Empty;
}

isStatic :: inline (finder: PathFinder, position: Vec2i) -> bool {
    return getTileValueType(finder, position) == cast(u16) PathFinderDataType.Static;
}

isDynamic :: inline (finder: PathFinder, position: Vec2i) -> bool {
    return getTileValueType(finder, position) == cast(u16) PathFinderDataType.Dynamic;
}

isDynamicOfEntity :: inline (finder: PathFinder, position: Vec2i, id: EntityId) -> bool {
    return getTileEntityId(finder, position) == id;
}

initPathFinder :: (type: PathFindingType, width: s32, height: s32, data: [] u16) -> PathFinder {
    finder: PathFinder = ---;
    finder.type = type;
    finder.width = width;
    finder.height = height;
    finder.data = alloc(u16, width * height);
    memoryCopy(finder.data, data.data, width * height);
    return finder;
}

isInside :: inline (finder: PathFinder, position: Vec2i) -> bool {
    return position.x >= 0 && position.x < finder.with &&
           position.y >= 0 && position.y < finder.height;
}

findPath :: (finder: PathFinder, start: Vec2i, end: Vec2i) -> MapPath {
    if finder.type == {
        case PathFindingType.Bfs; return bfs(finder, start, end);
        case PathFindingType.Astar; return astar(finder, start, end);
        case; {
            logWarning("Unkown path finding type %, defaulting to %\n", finder.type, PathFindingType.Astar);
            return astar(finder, start, end);
        }
    }
}

reRoutePath :: (finder: PathFinder, path: *MapPath, fromIndex: s32, toIndex: s32) -> bool {
    assert(fromIndex >= 0 && fromIndex < path.nodes.count);
    assert(toIndex >= 0 && toIndex < path.nodes.count);

    result := false;

    if (fromIndex != toIndex) {
        fromNode := path.nodes[fromIndex];
        toNode := path.nodes[toIndex];

        // find a new path from the current position to the destination
        newPath := findPath(finder, fromNode, toNode);
        defer freePath(newPath);

        if (newPath.nodes.count > 1) {
            minIndex := min(fromIndex, toIndex);
            maxIndex := max(fromIndex, toIndex);

            // remove the nodes in the range [fromIndex, toIndex] or [toIndex, fromIndex] from current to last remaining nodes of the current path
            removeAtRange(*path.nodes, minIndex, maxIndex - minIndex + 1);

            // if a path was found subsitute the portion of the path with the new one
            insertRange(*path.nodes, minIndex, newPath.nodes);

            result = true;
        }
    }

    return result;
}

pathExists :: (finder: PathFinder, start: Vec2i, end: Vec2i) -> bool {
    result := false;

    if (isInside(finder, start) && isInside(finder, end)) {
        path := findPath(finder, start, end);
        defer freePath(path);

        if (path.nodes.count >= 2) {
            lastPosition := path.nodes[path.nodes.count - 1];
            if (lastPosition == end) {
                result = true;
            } else {
                result = checkEntityAtEnd(finder, end, lastPosition);
            }
        }
    }

    return result;
}

freePath :: (path: MapPath) {
    uninit(*path.nodes);
}

findEmptyPosition :: (finder: PathFinder, position: Vec2i) -> Vec2i {
    if (isEmpty(finder, position)) {
        return position;
    }

    positions := createList(Vec2i);
    defer uninit(*positions);

    add(*positions, position);

    for i : range(s32, 0, positions.count) {
        currentPosition := positions[i];

        if (isEmpty(finder, currentPosition)) {
            position = currentPosition;
            break;
        }

        for d : dir {
            neighbor = currentPosition + d;
            if (isInside(finder, neighbor)) {
                if (!contains(*positions, neighbor, equals)) {
                    add(*positions, neighbor);
                }
            }
        }
    }

    return position;
}

isPositionAccesible :: (finder: PathFinder, position: Vec2i) -> bool {
    for d : dir {
        neighbor := position + d;
        if (isInside(finder, neighbor) && isEmpty(finder, neighbor)) {
            return true;
        }
    }

    return false;
}

#scope_file

dir :: Vec2i.[
    .{ 0,-1},
    .{ 1,-1},
    .{ 1, 0},
    .{ 1, 1},
    .{ 0, 1},
    .{-1, 1},
    .{-1, 0},
    .{-1,-1}
];

MapNode :: struct {
    id: s32;     // id of the node
    pos: Vec2i;  // the coordinates of the node
    level: s32;  // the length of the path from the start to this node
    parent: s32; // the previous node in the path from start to end passing through this node
    gScore: s32; // the cost from the start to this node
    fScore: s32; // the cost from start to end passing through this node
}

createNode :: inline (finder: PathFinder, pos: Vec2i) -> MapNode {
    node: MapNode = ---;
    node.id = pos.y * finder.width + pos.x;
    node.pos = pos;
    node.level = 0;
    node.parent = -1;
    node.gScore = INT32_MAX;
    node.fScore = INT32_MAX;
    return node;
}

equalsMapNode :: inline (node1: MapNode, node2: MapNode) -> bool {
    return node1.pos == node2.pos;;
}

distanceManhattan :: inline (node1: MapNode, node2: MapNode) -> s32 {
    return distanceManhattan(node1.pos, node2.pos);
}

nodeDistanceSqr :: inline (node1: MapNode, node2: MapNode) -> f32 {
    return distanceSqr(node1.pos, node2.pos);
}

bfs :: (finder: PathFinder, start: Vec2i, end: Vec2i) -> MapPath {
    nodes: createList(MapNode);
    defer uninit(*nodes);

    startNode := createNode(finder, start);
    endNode := createNode(finder, end);

    add(*nodes, startNode);

    i := 0;
    while (i < nodes.count) {
        node := nodes[i];
        if (equalsMapNode(node, endNode)) {
            break;
        }

        for d : dir {
            neighbor := node + d;
            if (isInside(finder, neighbor) && isEmpty(finder, neighbor)) {
                newNode := createNode(finder, neighbor);
                if (!contains(*nodes, newNode, equalsMapNode)) {
                    newNode.parent = i;
                    newNode.level = node.level + 1;
                    add(*nodes, newNode);
                }
            }
        }
    }

    path: MapPath;
    path.nodes = createList(Vec2i);

    if (i < nodes.count) {
        node := nodes[i];
        add(*path.nodes, node.pos);

        while (node.parent >= 0) {
            node = nodes[node.parent];
            add(*path.nodes, node.pos);
        }

        reverse(*path.nodes);
    }

    return path;
}

evaluateStartNode :: (finder: PathFinder, start: Vec2i) -> bool, MapNode {
    if (!isInside(finder, start)) {
        return false, createNode(finder, vec2i(-1, -1));
    }

    if (isEmpty(finder, start)) {
        return true, createNode(finder, start);
    }

    entityAtStart := getTileEntityId(finder, start);
    if (entityAtStart == 0) {
        return true, createNode(finder, start);
    }

    positions := createList(Vec2i);
    defer uninit(*positions);

    add(*positions, start);

    for i : range(s32, 0, positions.count) {
        currentPosition := positions[i];

        if (isEmpty(finder, currentPosition)) {
            return true, createNode(finder, currentPosition);
        }

        for d : dir {
            neighbor := currentPosition + d;
            if (isInside(finder, neighbor)) {
                entityAtNeighbor := getTileEntityId(finder, neighbor);
                if (entityAtNeighbor == 0 || entityAtStart == entityAtNeighbor) {
                    if (!contains(*positions, neighbor, equals)) {
                        add(*positions, neighbor);
                    }
                }
            }
        }
    }

    return false, createNode(finder, -1, -1);
}

evaluateEndNode :: (finder: PathFinder, end: Vec2i) -> bool, MapNode {
    if (!isInside(finder, end)) {
        return false, createNode(finder, vec2i(-1, -1));
    }

    emptyPosition := findEmptyPosition(finder, end);
    return true, createNode(finder, emptyPosition);
}

astar :: (finder: PathFinder, start: Vec2i, end: Vec2i) -> MapPath {
    path: MapPath;
    path.nodes = createList(Vec2i);

    startNodeOk, startNode := evaluateStartNode(finder, start);
    if (!startNodeOk) {
        return path;
    }

    endNodeOk, endNode := evaluateEndNode(finder, end);
    if (!endNodeOk) {
        return path;
    }

    // The set of currently discovered nodes that are not evaluated yet.
    openSet := createBinaryHeap(MapNode);
    defer uninit(*openSet);

    // The set of nodes already evaluated (this could be a simple boolean array to mark the visited nodes)
    closedSet := createMap(s32, MapNode);
    defer uninit(*closedSet);

    // The cost of going from start to start is zero.
    startNode.gScore = 0;

    // The cost of going from start to end is infinity.
    endNode.gScore = INT32_MAX;

    // For the first node, the fScore that value is completely heuristic.
    startNode.fScore = distanceManhattan(startNode, endNode);

    // For the last node, the fScore is 0
    endNode.fScore = 0;

    // Initially, only the start node is known.
    push(*openSet, startNode);

    while (openSet.count > 0) {
        // the node in openSet having the lowest fScore value
        current := pop(*openSet);
        set(*closedSet, current.id, current);

        if (equalsMapNode(current, endNode)) {
            break;
        }

        for d : dir {
            neighbor := current + d;
            if (isInside(finder, neighbor)) {
                // if the neighbor position is occupied by a static entity,
                // don't consider it so that the unit is able to surround it
                if (isStatic(finder, neighbor)) {
                    continue;
                }

                neighborNode := createNode(finder, neighbor);

                // if the neighbor position is a occupied by a dynamic entity (another unit moving),
                // there is a chance that when the unit gets there the position is empty
                // but only consider it in the path when that position is far away from the start,
                // because when that position is close enough, the risk of overlaping units is greater
                if (isDynamic(finder, neighbor)) {
                    distance := nodeDistanceSqr(startNode, neighbor);
                    if (distance < DISTANCE_SQR_AVOID_DYNAMIC_POSITIONS) {
                        continue;
                    }
                }

                // Ignore the neighbor which is already evaluated.
                if (contains(*closedSet, neighborNode.id)) {
                    continue;
                }

                // The distance from start -> current node -> neighbor
                gScore := current.gScore + 1 /* cost from current to neighbor, can be a little higher for diagonals */;

                // < 0 indicates that this node need to be inserted into the heap
                index := indexOf(*openSet, neighborNode);

                // if the node is already in the heap, check to update its gScore if necessary
                if (index >= 0) {
                    neighborNode = openSet[index];

                    // going from the current node through this neighbor is not the best way, skip it
                    if (gScore >= neighborNode.gScore) {
                        continue;
                    }
                }

                // This path is the best until now. Record it!
                neighborNode.parent = current.id;
                neighborNode.gScore = gScore;
                neighborNode.fScore = neighborNode.gScore + distanceManhattan(neighborNode, endNode);

                if (index >= 0) {
                    update(*openSet, index, neighborNode);
                } else {
                    push(*openSet, neighborNode);
                }
            }
        }
    }

    // only process the path if has at least two points
    if (closedSet.count > 1) {
        node: MapNode = ---;

        // if the last node is not in the collection of processed nodes,
        // then the node is unreachable, look for the closest one and go there
        if (!contains(*closedSet, endNode.id)) {
            minDistanceToEnd := S32_MAX;
            minDistanceFromStart := S32_MAX;

            for entry : closedSet {
                distanceToEnd := nodeDistanceSqr(endNode, entry.value);
                if (distanceToEnd < minDistanceToEnd) {
                    node = entry.value;
                    minDistanceToEnd = distanceToEnd;
                    minDistanceFromStart = nodeDistanceSqr(startNode, entry.value);
                } else if(distanceToEnd == minDistanceToEnd) {
                    distanceFromStart := nodeDistanceSqr(startNode, entry.value);
                    if (distanceFromStart < minDistanceFromStart) {
                        node = entry.value;
                        minDistanceToEnd = distanceToEnd;
                        minDistanceFromStart = distanceFromStart;
                    }
                }
            }
        } else {
            _, node = get(*closedSet, endNode.id);
        }

        while (node.parent >= 0) {
            if (!isStatic(finder, node.pos)) {
                add(*path.nodes, node.pos);
            }

            _, node = get(*closedSet, node.parent);
        }

        add(*path.nodes, node.pos);
        reverse(*path.nodes);
    }

    return path;
}

checkEntityAtEnd :: (finder: PathFinder, end: Vec2i, lastPosition: Vec2i) -> bool {
    result := false;

    entityAtEnd := getTileEntityId(finder, end);
    if (entityAtEnd) {
        for d : dir {
            neighbor = lastPosition + d;
            if (isInside(finder, neighbor)) {
                entityAtNeighbor := getTileEntityId(finder, neighbor);
                if (entityAtNeighbor == entityAtEnd) {
                    result = true;
                    break;
                }
            }
        }
    }

    return result;
}
