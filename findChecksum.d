import std.stdio;
import std.exception : enforce;
import std.digest.crc;
import std.random;
import std.algorithm;

import util.region;
import util.random;

enum WINDOW_WIDTH_MIN = 8;
enum CRC_SIZE = digestLength!(CRC32);

struct ChecksumMatch {
    Region sourceRegion;
    ubyte[] checksum;
    uint[] positions;
}

uint[][uint] getCrcMap(ubyte[] haystack) pure nothrow @trusted {
    uint[][uint] crcMap;
    uint crcPosition = 0;

    while (haystack.length >= CRC_SIZE) {
        uint crcCandidate = *cast(uint*) haystack;

        if (auto crcList = crcCandidate in crcMap)
            *crcList ~= crcPosition;
        else
            crcMap[crcCandidate] = [crcPosition];

        haystack = haystack[1 .. $];
        crcPosition++;
    }

    return crcMap;
}

ChecksumMatch[] findCrcChecksum(ubyte[] haystack, uint windowWidthMax) pure @trusted {
    assert(windowWidthMax > 0);

    CRC32 crc;
    ChecksumMatch[] matches;
    auto crcMap = getCrcMap(haystack);

    int start = 0;
    while (haystack.length >= WINDOW_WIDTH_MIN) {
        crc.start();
        auto window = haystack[0 .. min($, windowWidthMax)];
        crc.put(window[0 .. WINDOW_WIDTH_MIN - 1]);
        window = window[WINDOW_WIDTH_MIN - 1 .. $];
        int end = start + 1 + (WINDOW_WIDTH_MIN - 1);
        while (window.length > 0) {
            crc.put(window[0]);
            auto digest = crc.peek();
            uint uiDigest = *cast(uint*) digest;
            if (auto crcPositions = uiDigest in crcMap) {
                matches ~= ChecksumMatch(Region(start, end), digest.dup, *crcPositions);
            }
            window = window[1 .. $];
            end++;
        }

        haystack = haystack[1 .. $];
        start++;
    }

    return matches;
}

void main() {
}

// FIXME conditional compilation if unittest
Region fitInRegionRandomly(Region[] frames, uint length) {
    // FIXME frames must not intersect
    uint validStartPositionCount = 0;
    Region[] startPositions;
    foreach (frame; frames) {
        if (frame.length >= length) {
            auto framesValidStartPositionCount = frame.length - length + 1;
            validStartPositionCount += framesValidStartPositionCount;
            startPositions ~= Region(frame.start, framesValidStartPositionCount);
        }
    }

    if (validStartPositionCount == 0)
        throw new Exception("no space to fit in region");

    uint startPositionIndex = uniform(0, validStartPositionCount);
    foreach (reg; startPositions) {
        if (reg.length > startPositionIndex)
            return Region(cast(int) (reg.start + startPositionIndex), length);

        startPositionIndex -= reg.length;
    }
    assert(0);
}

ChecksumMatch hideChecksum(ubyte[] haystack) {
    auto haystackRegion = Region(cast(uint) haystack.length);
    auto digestSourceRegion = getRandomRegion(haystackRegion);
    auto digestDestinationRegion = fitInRegionRandomly(haystackRegion - digestSourceRegion, digestLength!(CRC32));
    auto digestSourceBytes = haystack[digestSourceRegion.start .. digestSourceRegion.end];
    auto digest = digest!CRC32(digestSourceBytes);
    haystack[digestDestinationRegion.start .. digestDestinationRegion.end] = digest[];
    return ChecksumMatch(digestSourceRegion, digest.dup, [digestDestinationRegion.start]);
}

unittest {
    auto haystack = getRandomBytes(1024 * 2);
    auto hiddenMatch = hideChecksum(haystack);
    assert(hiddenMatch.positions.length == 1);
    auto source = haystack[hiddenMatch.sourceRegion.start .. hiddenMatch.sourceRegion.end];
    CRC32 crc;
    crc.put(source);
    auto digest = crc.finish();
    assert(digest == hiddenMatch.checksum);
    auto hiddenChecksum = haystack[hiddenMatch.positions[0] .. hiddenMatch.positions[0] + CRC_SIZE];
    assert(digest == hiddenChecksum);
}

bool testChecksumSearchOnRandomlyHiddenCrc(uint haystackSize) {
    auto haystack = getRandomBytes(haystackSize);
    auto knownMatch = hideChecksum(haystack);
    auto matches = findCrcChecksum(haystack, 1024 * 2);

    foreach(match; matches) {
        if (match.sourceRegion == knownMatch.sourceRegion && match.checksum == knownMatch.checksum && countUntil(match.positions, knownMatch.positions[0]) >= 0) {
            return true;
        }
    }
    return false;
}

unittest {
    assert(testChecksumSearchOnRandomlyHiddenCrc(1024 * 2), "testChecksumSearchOnRandomlyHiddenCrc() failed");
    auto haystack = getRandomBytes(1024 * 32);
    auto matches = findCrcChecksum(haystack, 1024 * 2);
    writeln(matches.length);
}

