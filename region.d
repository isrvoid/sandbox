module util.region;

import std.stdio;
import std.algorithm : min, max;
import std.exception : enforce;

struct Region {
    alias offset = start;
    immutable {
        int start;
        int end;
        uint length;
    }

    @disable this();

    this(int start, uint length) pure @safe {
        enforce(length > 0, "length should be greater than 0");
        int end = start + length;
        enforce(start < end, "end should be within start types reach");
        this.start = start;
        this.length = length;
        this.end = end;
    }

    this(int start, int end) pure @safe {
        enforce(start < end, "end should be greater than start");
        this.start = start;
        this.end = end;
        length = end - start;
    }

    this(uint length) pure @safe {
        this(0, length);
    }

    bool contains(int element) pure nothrow @safe {
        return start <= element && end > element;
    }

    bool contains(Region sub) pure nothrow @safe {
        return contains(sub.start) && contains(sub.end - 1);
    }

    bool isContainedWithin(Region container) pure nothrow @safe {
        return container.contains(this);
    }

    bool intersects(Region rhs) pure nothrow @safe {
        return contains(rhs.start) || contains(rhs.end - 1);
    }

    Region[] opBinary(string op : "+")(Region rhs) pure @safe {
        if (intersects(rhs))
            return [Region(min(start, rhs.start), max(end, rhs.end))];

        if (start < rhs.start)
            return [this, rhs];
        else
            return [rhs, this];
    }

    Region[] opBinary(string op : "-")(Region rhs) pure  @safe {
        if (intersects(rhs) == false)
            return [this];

        Region[] result;

        bool leftRegionExists = start < rhs.start;
        if (leftRegionExists)
            result ~= Region(start, rhs.start);

        bool rightRegionExists = end > rhs.end;
        if (rightRegionExists)
            result ~= Region(rhs.end, end);

        return result;
    }
}

// basic construction
unittest {
    auto r1 = Region(int.min, int.max);
    assert(r1.length == uint.max);
    auto r2 = Region(42, cast(uint) 123);
    assert(r2.start == 42 && r2.length == 123);
}

// immutability
unittest {
    Region immutabilityTest = Region(0, 1);
    assert(is(typeof(immutabilityTest.offset) == immutable(int)));
    assert(__traits(compiles, immutabilityTest.length++) == false);
}

// contains
unittest {
    // int element
    auto foo = Region(-1234, 5678);
    int[] contained = [foo.start, foo.start + cast(int) foo.length / 2, foo.end - 1];
    int[] notContained = [foo.start - 1, foo.start - 64, foo.end, foo.end + 23];
    foreach (element; contained)
        assert(foo.contains(element));
    foreach (element; notContained)
        assert(foo.contains(element) == false);
}

unittest {
    // Region
    auto foo = Region(-123, 42);
    assert(foo.contains(foo));
    auto smallerThanFoo = Region(foo.start, foo.end - 1);
    assert(smallerThanFoo.contains(foo) == false);
}

// isContainedWithin
unittest {
    auto foo = Region(-4, 42);
    assert(foo.isContainedWithin(foo));
    auto fooClipped = Region(foo.start + 1, foo.end - 1);
    assert(fooClipped.isContainedWithin(foo));
    assert(foo.isContainedWithin(fooClipped) == false);
}
// op "+"
unittest {
    // not intersecting
    auto foo = Region(-432, -321);
    auto bar = Region(12, 34);
    auto fooBar = foo + bar;
    assert(fooBar.length == 2);
    assert(fooBar[0] == foo);
    assert(fooBar[1] == bar);
    assert(fooBar == bar + foo);
}

unittest {
    // intersecting
    auto foo = Region(-765, 23);
    auto bar = Region(-17, 987);
    auto fooBar = foo + bar;
    assert(fooBar == bar + foo);
    assert(fooBar.length == 1);
    assert(fooBar[0] == Region(foo.start, bar.end));
}

// op "-"
unittest {
    auto r1 = Region(-10, cast(uint) 3);
    auto r2 = Region(-9, cast(uint) 1);
    auto diff = r1 - r2;
    assert(diff.length == 2);
    assert(diff[0] == Region(-10, cast(uint) 1));
    assert(diff[1] == Region(-8, cast(uint) 1));
}

unittest {
    auto r1 = Region(42, 43);
    auto r2 = Region(3, 4);
    auto diff12 = r1 - r2;
    assert(diff12.length == 1);
    assert(diff12[0] == r1);

    auto diff21 = r2 - r1;
    assert(diff21.length == 1);
    assert(diff21[0] == r2);
}

unittest {
    auto foo = Region(-42, 42);
    auto withinFoo = Region(-7, 23);
    auto leftChunk = (foo - withinFoo)[0];
    auto rightChunk = (foo - withinFoo)[1];
    assert((foo - foo).length == 0);
    assert(((withinFoo - leftChunk)[0] - rightChunk)[0] == withinFoo);
}

// intersects
unittest {
    auto foo = Region(-123, 42);
    Region[] intersecting;
    intersecting ~= Region(foo.start, cast(uint) 1);
    intersecting ~= Region(foo.start - 1, foo.start + 1);
    intersecting ~= Region(foo.end - 1, cast(uint) 1);
    intersecting ~= Region(foo.end - 1, foo.end + 1);

    Region[] notIntersecting;
    notIntersecting ~= Region(foo.start - 8, foo.start);
    notIntersecting ~= Region(foo.end, cast(uint) 3);
    notIntersecting ~= Region(foo.end + 1, cast(uint) 321);

    assert(foo.intersects(foo));

    foreach(region; intersecting) {
        assert(foo.intersects(region));
        assert(region.intersects(foo));
    }

    foreach(region; notIntersecting) {
        assert(foo.intersects(region) == false);
        assert(region.intersects(foo) == false);
    }
}

