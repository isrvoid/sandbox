import std.stdio;
import std.math;

void main(string[] args)
{
    import std.getopt;
    import std.numeric;
    import std.complex;
    import core.time;
    import std.array : empty;

    auto opt =  getopt(
            args);

    if (opt.helpWanted)
    {
        defaultGetoptPrinter("FFT bandwidth test.", opt.options);
        return;
    }

    enum periodCount = 1_000_000;
    auto stream = makeSampleStream(periodCount);
    auto fftObj = new Fft(sampleCount);

    auto start = MonoTime.currTime;
    while (!stream.empty)
    {
        auto samples = convertSamples(stream[0 .. sampleCount]);
        stream = stream[sampleCount .. $];

        auto fft = fftObj.fft!(float, float[])(samples);
    }
    auto elapsed = MonoTime.currTime - start;
    writeln(elapsed);
}

@safe:

private:
enum sampleCount = 32;
enum sampleBits = 18;
enum scaleFactor = (1 << sampleBits) - 1;

int[sampleCount] getSamples(double mod, double arg)
{
    assert(mod >= 0.0 && mod <= 1.0);
    enum xStep = PI / sampleCount;
    int[sampleCount] result;
    foreach(i, ref sample; result)
    {
        auto x = arg + i * xStep;
        auto y = mod * sin(x);
        sample = cast(int) (y * scaleFactor);
    }
    return result;
}

float[sampleCount] convertSamples(int[] rawSamples)
{
    enum float convertFactor = 1.0 / scaleFactor;
    float[sampleCount] result;
    foreach (i, ref sample; result)
        sample = rawSamples[i] * convertFactor;

    return result;
}

int[] makeSampleStream(uint periodCount)
{
    import std.random : uniform;
    auto result = new int[sampleCount * periodCount];
    auto toFill = result;
    foreach (i; 0 .. periodCount)
    {
        double mod = uniform!"[]"(0.0, 1.0);
        double arg = uniform(0.0, 2.0 * PI);
        toFill[0 .. sampleCount] = getSamples(mod, arg)[];
        toFill = toFill[sampleCount .. $];
    }
    return result;
}
