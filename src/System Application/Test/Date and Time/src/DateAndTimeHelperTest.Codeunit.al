namespace System.Test.DateTime;

using System.DateTime;
using System.TestLibraries.Utilities;

codeunit 132980 "Date and Time Helper Test"
{
    Subtype = Test;

    var
        LibraryAssert: Codeunit "Library Assert";
        Any: Codeunit Any;
        IsInitialized: Boolean;
        DSTTimeZoneData: Dictionary of [Text, Decimal];
        NonDSTTimeZoneData: Dictionary of [Text, Decimal];

    [Test]
    [Scope('OnPrem')]
    procedure TestDateTimeComparison()
    var
        DateAndTimeHelper: Codeunit "Date and Time Helper";
        DateTimeA: DateTime;
        DateTimeB: DateTime;
        Threshold: Integer;
    begin
        // Threshold for equality when comparing DateTime values. If the difference
        // is less than this value, then we treat them as equal values.
        Threshold := 10;

        LibraryAssert.IsTrue(DateAndTimeHelper.CompareDateTimes(DateTimeA, DateTimeB) = 0, 'Return value should be 0 for two null values.');

        DateTimeA := CurrentDateTime();
        LibraryAssert.IsTrue(DateAndTimeHelper.CompareDateTimes(DateTimeA, DateTimeB) > 0, 'Return value should be > 0 if second value is null.');
        LibraryAssert.IsTrue(DateAndTimeHelper.CompareDateTimes(DateTimeB, DateTimeA) < 0, 'Return value should be < 0 if first value is null.');

        DateTimeB := DateTimeA;
        LibraryAssert.IsTrue(DateAndTimeHelper.CompareDateTimes(DateTimeA, DateTimeB) = 0, 'Return value should be 0 for equal values.');

        DateTimeB := DateTimeA + Any.IntegerInRange(0, Threshold - 1);
        LibraryAssert.IsTrue(DateAndTimeHelper.CompareDateTimes(DateTimeA, DateTimeB) = 0, 'Return value should be 0 for values within threshold.');
        LibraryAssert.IsTrue(DateAndTimeHelper.CompareDateTimes(DateTimeB, DateTimeA) = 0, 'Return value should be 0 for values within threshold.');

        DateTimeB := DateTimeA + Threshold;
        LibraryAssert.IsTrue(DateAndTimeHelper.CompareDateTimes(DateTimeA, DateTimeB) < 0, 'Return value should be < 0.');
        LibraryAssert.IsTrue(DateAndTimeHelper.CompareDateTimes(DateTimeB, DateTimeA) > 0, 'Return value should be > 0.');

        DateTimeB := DateTimeA + Any.IntegerInRange(Threshold + 1, 500);
        LibraryAssert.IsTrue(DateAndTimeHelper.CompareDateTimes(DateTimeA, DateTimeB) < 0, 'Return value should be < 0.');
        LibraryAssert.IsTrue(DateAndTimeHelper.CompareDateTimes(DateTimeB, DateTimeA) > 0, 'Return value should be > 0.');
    end;

    [Test]
    procedure TestTimeComparison()
    var
        DateAndTimeHelper: Codeunit "Date and Time Helper";
        TimeA: Time;
        TimeB: Time;
        Threshold: Integer;
    begin
        // Threshold for equality when comparing Time values. If the difference
        // is less than this value, then we treat them as equal values.
        Threshold := 10;

        LibraryAssert.IsTrue(DateAndTimeHelper.CompareTimes(TimeA, TimeB) = 0, 'Return value should be 0 for two null values.');

        TimeA := DT2Time(CurrentDateTime());
        LibraryAssert.IsTrue(DateAndTimeHelper.CompareTimes(TimeA, TimeB) > 0, 'Return value should be > 0 if second value is null.');
        LibraryAssert.IsTrue(DateAndTimeHelper.CompareTimes(TimeB, TimeA) < 0, 'Return value should be < 0 if first value is null.');

        TimeB := TimeA;
        LibraryAssert.IsTrue(DateAndTimeHelper.CompareTimes(TimeA, TimeB) = 0, 'Return value should be 0 for equal values.');

        TimeB := TimeA + Any.IntegerInRange(0, Threshold - 1);
        LibraryAssert.IsTrue(DateAndTimeHelper.CompareTimes(TimeA, TimeB) = 0, 'Return value should be 0 for values within threshold.');
        LibraryAssert.IsTrue(DateAndTimeHelper.CompareTimes(TimeB, TimeA) = 0, 'Return value should be 0 for values within threshold.');

        TimeB := TimeA + Threshold;
        LibraryAssert.IsTrue(DateAndTimeHelper.CompareTimes(TimeA, TimeB) < 0, 'Return value should be < 0.');
        LibraryAssert.IsTrue(DateAndTimeHelper.CompareTimes(TimeB, TimeA) > 0, 'Return value should be > 0.');

        TimeB := TimeA + Any.IntegerInRange(Threshold + 1, 500);
        LibraryAssert.IsTrue(DateAndTimeHelper.CompareTimes(TimeA, TimeB) < 0, 'Return value should be < 0.');
        LibraryAssert.IsTrue(DateAndTimeHelper.CompareTimes(TimeB, TimeA) > 0, 'Return value should be > 0.');

        TimeA := 235959.999T;
        TimeB := 000000.000T;
        LibraryAssert.IsTrue(DateAndTimeHelper.CompareTimes(TimeA, TimeB) = 0, 'Return value should be 0 for values that would be equal after sql server rounding.');
    end;
}