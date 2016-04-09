import std.stdio;
import std.math;
import std.numeric;
import std.complex;

enum sampleCount = 32;
enum absCorrectionFactor = 2.0 / sampleCount;

void main()
{
}

auto getSamples(double abs, double arg = 0.0)
{
    auto res = new double[](sampleCount);
    foreach (i, ref s; res)
    {
        auto x = 2.0 * PI / sampleCount * i + arg;
        s = abs * sin(x);
    }
    return res;
}

unittest
{
    assert(sampleCount == getSamples(42.0, PI_4).length);
}

unittest
{
    assert(getSamples(3.0, PI_2)[0] == 3.0);
}

unittest
{
    auto fft = getSamples(42.0, PI_4).fft();
    assert(approxEqual(42.0, abs(fft[1]) * absCorrectionFactor));
    assert(approxEqual(-PI_4, arg(fft[1])));
}

auto getFundamental(double[] samples)
{
    assert(sampleCount == samples.length);
    enum sinLut = getSamples(1.0);
    enum cosLut = getSamples(1.0, PI_2);

    auto sinMult = new double[](sampleCount);
    auto cosMult = new double[](sampleCount);
    sinMult[] = samples[] * sinLut[];
    cosMult[] = samples[] * cosLut[];

    import std.algorithm : reduce;
    auto sinMean = sinMult.reduce!"a + b" / sampleCount;
    auto cosMean = cosMult.reduce!"a + b" / sampleCount;
    return complex(cosMean * 2.0, -sinMean * 2.0);
}

unittest
{
    auto f = getFundamental(getSamples(0.0));
    assert(approxEqual(0.0, f.re));
    assert(approxEqual(0.0, f.im));
}

unittest
{
    auto f = getFundamental(getSamples(1.0));
    assert(approxEqual(0.0, f.re));
    assert(approxEqual(-1.0, f.im));
}

unittest
{
    auto f = getFundamental(getSamples(42.0));
    assert(approxEqual(-42.0, f.im));
}

unittest
{
    auto f = getFundamental(getSamples(3.0, PI_2));
    assert(approxEqual(3.0, f.re));
    assert(approxEqual(0.0, f.im));
}

unittest
{
    foreach(i; 0 .. 10)
    {
        auto startArg = 2.0 * PI / 10 * i;
        auto samples = getSamples(42.0, startArg);
        auto fftFund = fft(samples)[1];
        auto fund = getFundamental(samples);
        assert(approxEqual(arg(fftFund), arg(fund)));
        assert(approxEqual(abs(fftFund) * absCorrectionFactor, abs(fund)));
    }
}
