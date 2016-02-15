module util.random;

import std.random;
import std.algorithm : min, max;

import util.region;

package auto sharedGenerator = Random();
static this() {
    sharedGenerator.seed(unpredictableSeed);
}

uint getRandomUint() nothrow @safe {
    auto result = sharedGenerator.front;
    sharedGenerator.popFront();
    return result;
}

Region getRandomRegion(Region within) @safe {
    int startOrEndA, startOrEndB;
    do {
        startOrEndA = uniform!"[]"(within.start, within.end, sharedGenerator);
        startOrEndB = uniform!"[]"(within.start, within.end, sharedGenerator);
    } while (startOrEndA == startOrEndB);
    auto start = min(startOrEndA, startOrEndB);
    auto end = max(startOrEndA, startOrEndB);
    return Region(start, end);
}

unittest {
    auto narrow = Region(int.min, cast(uint) 1);
    foreach (i; 0 .. 5) {
        auto rand = getRandomRegion(narrow);
        assert(narrow.contains(rand));
    }
}

ubyte[] getRandomBytes(uint byteCount, uint seed = unpredictableSeed) pure nothrow @safe {
    auto generator = Random();
    generator.seed(seed);
    auto uintCount = byteCount / 4 + 1;
    uint[] randomUints = new uint[uintCount];
    foreach (ref rand; randomUints) {
        rand = generator.front;
        generator.popFront();
    }
    ubyte[] result = cast(ubyte[]) randomUints;
    result.length = byteCount;
    return result;
}

