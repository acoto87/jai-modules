KdTree :: struct {
    point: Vec2;
    userData: *void;
    boundary: Rect;
    left: *KdTree;
    right: *KdTree;
}

KdTreeEntry :: struct {
    point: Vec2;
    userData: *void;
}

init :: (tree: *KdTree, boundary: Rect, entries: [] KdTreeEntry) {
    initInternal(tree, boundary, entries, 0, entries.count - 1, 0);
}

uninit :: (tree: *KdTree, freeTree: bool) {
    if (tree.left != null) {
        uninit(tree.left, true);
    }

    if (tree.right != null) {
        uninit(tree.right, true);
    }

    if (freeTree) {
        free(tree);
    }
}

insert :: (tree: *KdTree, entry: KdTreeEntry) {
    insertInternal(tree, entry, 0);
}

query :: (tree: *KdTree, range: Rect, results: *List(KdTreeEntry)) {
    if (!intersects(tree.boundary, range)) {
        return;
    }

    if (contains(range, tree.point.x, tree.point.y)) {
        entry: KdTreeEntry;
        entry.point = tree.point;
        entry.userData = tree.userData;
        add(results, entry);
    }

    if (tree.left != null) {
        query(tree.left, range, results);
    }

    if (tree.right != null) {
        query(tree.right, range, results);
    }
}

query :: (tree: *KdTree, range: Circle, results: *List(KdTreeEntry)) {
    if (!intersects(tree.boundary, range)) {
        return;
    }

    if (contains(range, tree.point.x, tree.point.y)) {
        entry: KdTreeEntry;
        entry.point = tree.point;
        entry.userData = tree.userData;
        add(results, entry);
    }

    if (tree.left != null) {
        query(tree.left, range, results);
    }

    if (tree.right != null) {
        query(tree.right, range, results);
    }
}

#scope_file

initInternal :: (tree: *KdTree, boundary: Rect, entries: [] KdTreeEntry, i: s64, j: s64, depth: s64) {
    if ((depth & 1) == 0) {
        qsort(entries, i, j, compareByX);
    } else {
        qsort(entries, i, j, compareByY);
    }

    m := (i + j) / 2;
    tree.point = entries[m].point;
    tree.userData = entries[m].userData;
    tree.boundary = boundary;

    leftBoundary := getLeftBoundary(tree, depth);
    rightBoundary := getRightBoundary(tree, depth);

    if (m - 1 - i >= 0) {
        tree.left = alloc(KdTree);
        initInternal(tree.left, leftBoundary, entries, i, m - 1, depth + 1);
    }

    if (j - m - 1 >= 0) {
        tree.right = alloc(KdTree);
        initInternal(tree.right, rightBoundary, entries, m + 1, j, depth + 1);
    }
}

insertInternal :: (tree: *KdTree, entry: KdTreeEntry, depth: s64) {
    if ((depth & 1) == 0) {
        if (tree.point.x <= entry.point.x) {
            insertInternalLeft(tree, entry, depth);
        } else {
            insertInternalRight(tree, entry, depth);
        }
    } else {
        if (tree.point.y <= entry.point.y) {
            insertInternalLeft(tree, entry, depth);
        } else {
            insertInternalRight(tree, entry, depth);
        }
    }
}

insertInternalLeft :: (tree: *KdTree, entry: KdTreeEntry, depth: s64) {
    if (tree.left == null) {
        tree.left = alloc(KdTree);
        tree.left.point = entry.point;
        tree.left.userData = entry.userData;
        tree.left.boundary = getLeftBoundary(tree, depth);
    } else {
        insertInternal(tree.left, entry, depth + 1);
    }
}

insertInternalRight :: (tree: *KdTree, entry: KdTreeEntry, depth: s64) {
    if (tree.right == null) {
        tree.right = alloc(KdTree);
        tree.right.point = entry.point;
        tree.right.userData = entry.userData;
        tree.right.boundary = getRightBoundary(tree, depth);
    } else {
        insertInternal(tree.right, entry, depth + 1);
    }
}

getLeftBoundary :: (tree: *KdTree, depth: s64) -> Rect {
    if ((depth & 1) == 0) {
        return rect(
            tree.boundary.x,
            tree.boundary.y,
            tree.point.x - tree.boundary.x,
            tree.boundary.h
        );
    } else {
        return rect(
            tree.boundary.x,
            tree.boundary.y,
            tree.boundary.w,
            tree.point.y - tree.boundary.y
        );
    }
}

getRightBoundary :: (tree: *KdTree, depth: s64) {
    if ((depth & 1) == 0) {
        return rect(
            tree.point.x,
            tree.boundary.y,
            tree.boundary.x + tree.boundary.w - tree.point.x,
            tree.boundary.h
        );
    } else {
        return rect(
            tree.boundary.x,
            tree.point.y,
            tree.boundary.w,
            tree.boundary.y + tree.boundary.h - tree.point.y
        );
    }
}

compareByX :: inline (e1: KdTreeEntry, e2: KdTreeEntry) -> s64 {
    return cast(s64) (e1.point.x - e2.point.x);
}

compareByY :: inline (e1: KdTreeEntry, e2: KdTreeEntry) -> s64 {
    return cast(s64) (e1.point.y - e2.point.y);
}
