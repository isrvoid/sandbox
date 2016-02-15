import std.stdio;
import std.digest.crc;

void main() {
    auto text = "The quick brown fox jumps over the lazy dog";
    immutable dig = digest!CRC32(text);

    auto textBytes = cast(immutable(ubyte)[]) text;
    auto digBytes = digest!CRC32(textBytes);
    assert(dig == digBytes);

    CRC32 digest;
    foreach (b; textBytes)
        digest.put(b);

    auto digSingleBytes = digest.finish();
    assert(dig == digSingleBytes);

    digest.put(textBytes);
    auto digRangeAfterFinish = digest.finish();
    assert(dig == digRangeAfterFinish);

    digest.put(textBytes[0 .. $ / 2]);
    digest.put(textBytes[$ / 2 .. $]);
    auto digPeekAfterCorrectRanges = digest.peek();
    assert(dig == digPeekAfterCorrectRanges);

    digest.put(textBytes);
    auto digForgotToCallStart = digest.peek();
    assert(dig != digForgotToCallStart);

    digest.start();
    digest.put(textBytes);
    auto digRangeAfterStart = digest.finish();
    assert(dig == digRangeAfterStart);
}

