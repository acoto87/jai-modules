QuadTree :: struct {
    boundary: Rect;
    capacity: s64;
    count: s64;
    entries: *QuadTreeEntry;
    children: *QuadTree;
}

QuadTreeEntry :: struct {
    point: Vec2;
    userData: *void;
}

init :: (tree: *QuadTree, boundary: Rect, capacity: s64) {
    assert(capacity > 0);

    tree.boundary = boundary;
    tree.capacity = capacity;
    tree.count = 0;
    tree.entries = alloc(QuadTreeEntry, capacity);
}

uninit :: (tree: *QuadTree, freeTree: bool = false, freeUserData: bool = false) {
    if (freeUserData) {
        for i : 0..tree.count-1 {
            free(tree.entries[i].userData);
        }
    }

    free(tree.entries);
    tree.entries = null;

    if (tree.children != null) {
        for i : 0..3 {
            uninit(*tree.children[i], false);
        }
    }
    free(tree.children);
    tree.children = null;

    if (freeTree) {
        free(tree);
    }
}

insert :: (tree: *QuadTree, point: Vec2, userData: *void) -> bool {
    if (!contains(tree.boundary, point.x, point.y)) {
        return false;
    }

    if (tree.count < tree.capacity) {
        tree.entries[tree.count].point = point;
        tree.entries[tree.count].userData = userData;
        tree.count += 1;
        return true;
    }

    if (tree.children == null) {
        subdivide(tree);
    }

    for i : 0..3 {
        if (insert(*tree.children[i], point, userData)) {
            return true;
        }
    }

    return false;
}

query :: (tree: *QuadTree, range: Rect, results: *List(QuadTreeEntry)) {
    if (!intersects(tree.boundary, range)) {
        return;
    }

    for i : 0..tree.count-1 {
        point := tree.entries[i].point;
        if (contains(range, point.x, point.y)) {
            add(results, tree.entries[i]);
        }
    }

    if (tree.children != null) {
        for i : 0..3 {
            query(*tree.children[i], range, results);
        }
    }
}

query :: (tree: *QuadTree, range: Circle, results: *List(QuadTreeEntry)) {
    if (!intersects(tree.boundary, range)) {
        return;
    }

    for i : 0..tree.count-1 {
        point := tree.entries[i].point;
        if (contains(range, point.x, point.y)) {
            add(results, tree.entries[i]);
        }
    }

    if (tree.children != null) {
        for i : 0..3 {
            query(*tree.children[i], range, results);
        }
    }
}

#scope_file

subdivide :: (tree: *QuadTree) {
    childrenBoundarySize := getSize(tree.boundary) / 2;

    topLeft := getTopLeft(tree.boundary);
    topCenter := getTopCenter(tree.boundary);
    middleLeft := getMiddleLeft(tree.boundary);
    middleCenter := getMiddleCenter(tree.boundary);

    tree.children = alloc(QuadTree, 4);
    init(*tree.children[0], rect(topLeft, childrenBoundarySize), tree.capacity);
    init(*tree.children[1], rect(topCenter, childrenBoundarySize), tree.capacity);
    init(*tree.children[2], rect(middleLeft, childrenBoundarySize), tree.capacity);
    init(*tree.children[3], rect(middleCenter, childrenBoundarySize), tree.capacity);
}
