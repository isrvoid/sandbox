import std.stdio;
import std.math;
import std.numeric;
import std.complex;

enum sampleCount = 32;
enum absCorrectionFactor = 2.0 / sampleCount;

void main()
{
    auto dcCouplingLut = getDcCoupling(&getFundamental, 0.1, 10);
    auto harmonicCouplingLut = getHarmonicCoupling(&getFundamental);

    auto dcCouplingFft = getDcCoupling(&getFundamentalFromFft, 0.1, 10);
    auto harmonicCouplingFft = getHarmonicCoupling(&getFundamentalFromFft);

    writeln("sin-cos-LUT coupling --------");
    writeln("DC:");
    writeln(dcCouplingLut);
    writeln("harmonic:");
    writeln(harmonicCouplingLut);
    writeln();
    writeln("FFT coupling ----------------");
    writeln("DC:");
    writeln(dcCouplingFft);
    writeln("harmonic:");
    writeln(harmonicCouplingFft);
}

auto getSamples(double abs, double arg = 0.0, double periods = 1.0)
{
    auto res = new double[](sampleCount);
    foreach (i, ref s; res)
    {
        auto x = periods * 2.0 * PI / sampleCount * i + arg;
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
    auto fft = getSamples(42.0, 0.123 * PI).fft();
    assert(approxEqual(42.0, abs(fft[1]) * absCorrectionFactor));
    assert(approxEqual(0.123 * PI - PI_2, arg(fft[1])));
}

unittest
{
    auto fft = getSamples(42.0, 1.23 * PI, 3.0).fft();
    assert(approxEqual(42.0, abs(fft[3]) * absCorrectionFactor));
    assert(approxEqual(1.23 * PI - PI_2, arg(fft[3])));
}

unittest
{
    auto testSignal = new double[](sampleCount);
    testSignal[] = 0.5 + getSamples(7.0, -PI)[] + getSamples(3.0, -PI * 0.8, 6.0)[];
    auto fft = fft(testSignal);

    assert(approxEqual(0.0, fft[0].im));
    assert(approxEqual(0.5 * sampleCount, fft[0].re));

    assert(approxEqual(7.0, abs(fft[1]) * absCorrectionFactor));
    assert(approxEqual(2.0 * PI - PI - PI_2, arg(fft[1])));

    assert(approxEqual(3.0, abs(fft[6]) * absCorrectionFactor));
    assert(approxEqual(2.0 * PI - PI * 0.8 - PI_2, arg(fft[6])));
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
    auto f = getFundamental(getSamples(42.0, 2.34 * PI));
    auto expected = fromPolar(42.0, 2.34 * PI - PI_2);
    assert(approxEqual(expected.re, f.re));
    assert(approxEqual(expected.im, f.im));
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

auto getFundamentalFromFft(double[] samples)
{
    auto fund = samples.fft()[1];
    return fromPolar(abs(fund) * absCorrectionFactor, arg(fund));
}

unittest
{
    auto f = getFundamentalFromFft(getSamples(42.0, -2.34 * PI));
    auto expected = fromPolar(42.0, -2.34 * PI - PI_2);
    assert(approxEqual(expected.re, f.re));
    assert(approxEqual(expected.im, f.im));
}

alias getFundamentalFunc = Complex!double function(double[] samples);

auto getDcCoupling(getFundamentalFunc getFund, double limit = 0.1, uint steps = 10)
{
    enum argSteps = 32;
    enum expectedAbs = 1.0;
    auto dcCoupling = new double[](steps);
    foreach (i, ref dcCoup; dcCoupling)
    {
        auto maxAbsError = 0.0;
        immutable dcOffset = limit / steps * (i + 1);
        foreach (j; 0 .. argSteps)
        {
            immutable arg = 2.0 * PI / argSteps * j;
            immutable expected = fromPolar(expectedAbs, arg - PI_2);
            auto samples = getSamples(expectedAbs, arg);
            samples[] += dcOffset;
            auto fund = getFund(samples);
            auto absError = abs(fund - expected);
            if (absError > maxAbsError)
                maxAbsError = absError;
        }
        dcCoup = maxAbsError / dcOffset;
    }

    return dcCoupling;
}

unittest
{
    auto steps = 10;
    auto dc = getDcCoupling(&getFundamentalFromFft, 0.5, steps);
    assert(steps == dc.length);
}

auto getHarmonicCoupling(getFundamentalFunc getFund)
{
    import std.array : Appender;
    enum argSteps = 16;
    enum noiseAmp = 0.1;

    Appender!(double[]) coupling;
    foreach (harmonic; 2 .. sampleCount / 2)
    {
        auto maxError = 0.0;
        foreach (j; 0 .. argSteps)
        {
            auto signalArg = 2.0 * PI / argSteps * j;
            auto expected = fromPolar(1.0, signalArg - PI_2);
            auto signal = getSamples(1.0, signalArg);
            foreach (k; 0 .. argSteps)
            {
                auto noiseArg = 2.0 * PI / argSteps * k;
                auto noise = getSamples(noiseAmp, noiseArg, harmonic);
                signal[] += noise[];
                auto fund = getFund(signal);
                auto error = abs(fund - expected);
                if (error > maxError)
                    maxError = error;
            }
        }
        coupling.put(maxError / noiseAmp);
    }
    return coupling.data;
}

unittest
{
    auto hc = getHarmonicCoupling(&getFundamental);
    assert(sampleCount / 2 - 2 == hc.length);
}
