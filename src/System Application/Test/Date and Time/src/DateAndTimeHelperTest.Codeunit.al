namespace System.Test.DateTime;

using System.DateTime;
using System.TestLibraries.Utilities;

codeunit 132980 "Date and Time Helper Test"
{
    Subtype = Test;

    var
        LibraryAssert: Codeunit "Library Assert";

    [Test]
    procedure TestRoundTimeToSQLAccuracy()
    var
        DateAndTimeHelper: Codeunit "Date and Time Helper";
        TimeToRound: Time;
        ExpectedTime: Time;
    begin
        // Test case for no rounding 0 to 0
        TimeToRound := 000000.000T;
        ExpectedTime := 000000.000T;
        LibraryAssert.IsTrue(DateAndTimeHelper.RoundToSQLAccuracy(TimeToRound) = ExpectedTime, 'Time should remain ending with 0');

        // Test case for rounding 1 to 0
        TimeToRound := 000000.001T;
        ExpectedTime := 000000.000T;
        LibraryAssert.IsTrue(DateAndTimeHelper.RoundToSQLAccuracy(TimeToRound) = ExpectedTime, 'Time should be rounded to 0');

        // Test case for rounding 2 to 3
        TimeToRound := 000000.002T;
        ExpectedTime := 000000.003T;
        LibraryAssert.IsTrue(DateAndTimeHelper.RoundToSQLAccuracy(TimeToRound) = ExpectedTime, 'Time should be rounded to 3');

        // Test case for no rounding 3 to 3
        TimeToRound := 000000.003T;
        ExpectedTime := 000000.003T;
        LibraryAssert.IsTrue(DateAndTimeHelper.RoundToSQLAccuracy(TimeToRound) = ExpectedTime, 'Time should remain ending with 3');

        // Test case for rounding 4 to 3
        TimeToRound := 000000.004T;
        ExpectedTime := 000000.003T;
        LibraryAssert.IsTrue(DateAndTimeHelper.RoundToSQLAccuracy(TimeToRound) = ExpectedTime, 'Time should be rounded to 3');

        // Test case for rounding 5 to 7
        TimeToRound := 000000.005T;
        ExpectedTime := 000000.007T;
        LibraryAssert.IsTrue(DateAndTimeHelper.RoundToSQLAccuracy(TimeToRound) = ExpectedTime, 'Time should be rounded to 7');

        // Test case for no rounding 6 to 7
        TimeToRound := 000000.006T;
        ExpectedTime := 000000.007T;
        LibraryAssert.IsTrue(DateAndTimeHelper.RoundToSQLAccuracy(TimeToRound) = ExpectedTime, 'Time should remain ending with 7');

        // Test case for no rounding 7 to 7
        TimeToRound := 000000.007T;
        ExpectedTime := 000000.007T;
        LibraryAssert.IsTrue(DateAndTimeHelper.RoundToSQLAccuracy(TimeToRound) = ExpectedTime, 'Time should remain ending with 7');

        // Test case for rounding 8 to 7
        TimeToRound := 000000.008T;
        ExpectedTime := 000000.007T;
        LibraryAssert.IsTrue(DateAndTimeHelper.RoundToSQLAccuracy(TimeToRound) = ExpectedTime, 'Time should be rounded to 7');

        // Test case for rounding 9 to 0
        TimeToRound := 235959.999T;
        ExpectedTime := 000000.000T;
        LibraryAssert.IsTrue(DateAndTimeHelper.RoundToSQLAccuracy(TimeToRound) = ExpectedTime, 'Time should be rounded to 0');
    end;

    [Test]
    procedure TestCompareTime()
    var
        DateAndTimeHelper: Codeunit "Date and Time Helper";
        FirstTime: Time;
        SecondTime: Time;
    begin
        // Test case equal values
        FirstTime := DT2Time(CurrentDateTime());
        SecondTime := FirstTime;
        LibraryAssert.IsTrue(DateAndTimeHelper.Compare(FirstTime, SecondTime) = 0, 'Return value should be 0 for equal values.');

        // Test case for first value null
        FirstTime := 0T;
        SecondTime := DT2Time(CurrentDateTime());
        LibraryAssert.IsTrue(DateAndTimeHelper.Compare(FirstTime, SecondTime) = -1, 'Return value should be -1 if first value is null.');

        // Test case for second value null
        FirstTime := DT2Time(CurrentDateTime());
        SecondTime := 0T;
        LibraryAssert.IsTrue(DateAndTimeHelper.Compare(FirstTime, SecondTime) = 1, 'Return value should be 1 if second value is null.');

        // Test case for first value less than second value
        FirstTime := DT2Time(CurrentDateTime());
        SecondTime := GetNextPossibleTimeWithSQLAccuracy(FirstTime);
        LibraryAssert.IsTrue(DateAndTimeHelper.Compare(FirstTime, SecondTime) = -1, 'Return value should be -1 if first value is less than second value.');

        // Test case for first value greater than second value
        SecondTime := DT2Time(CurrentDateTime());
        FirstTime := GetNextPossibleTimeWithSQLAccuracy(SecondTime);
        LibraryAssert.IsTrue(DateAndTimeHelper.Compare(FirstTime, SecondTime) = 1, 'Return value should be 1 if first value is greater than second value.');

        // Test case for first value less than second value but equal with sql rounding
        FirstTime := DT2Time(CurrentDateTime());
        SecondTime := GetNextPossibleTimeWithSQLAccuracy(FirstTime) - 1;
        LibraryAssert.IsTrue(DateAndTimeHelper.Compare(FirstTime, SecondTime) = 0, 'Return value should be 0 if first value is less than second value but equal with sql rounding.');

        // Test case for first value greater than second value but equal with sql rounding
        SecondTime := DT2Time(CurrentDateTime());
        FirstTime := GetNextPossibleTimeWithSQLAccuracy(SecondTime) - 1;
        LibraryAssert.IsTrue(DateAndTimeHelper.Compare(FirstTime, SecondTime) = 0, 'Return value should be 0 if first value is greater than second value but equal with sql rounding.');
    end;

    [Test]
    procedure TestTimeIsEqual()
    var
        DateAndTimeHelper: Codeunit "Date and Time Helper";
        FirstTime: Time;
        SecondTime: Time;
    begin
        // Test case equal values
        FirstTime := DT2Time(CurrentDateTime());
        SecondTime := FirstTime;
        LibraryAssert.IsTrue(DateAndTimeHelper.IsEqual(FirstTime, SecondTime), 'Return value should be true for equal values.');

        // Test case for different values
        FirstTime := DT2Time(CurrentDateTime());
        SecondTime := GetNextPossibleTimeWithSQLAccuracy(FirstTime);
        LibraryAssert.IsFalse(DateAndTimeHelper.IsEqual(FirstTime, SecondTime), 'Return value should be false for different values.');

        // Test case for first value null
        FirstTime := 0T;
        SecondTime := DT2Time(CurrentDateTime());
        LibraryAssert.IsFalse(DateAndTimeHelper.IsEqual(FirstTime, SecondTime), 'Return value should be false if first value is null.');

        // Test case for second value null
        FirstTime := DT2Time(CurrentDateTime());
        SecondTime := 0T;
        LibraryAssert.IsFalse(DateAndTimeHelper.IsEqual(FirstTime, SecondTime), 'Return value should be false if second value is null.');
    end;

    [Test]
    procedure TestTimeIsGreater()
    var
        DateAndTimeHelper: Codeunit "Date and Time Helper";
        FirstTime: Time;
        SecondTime: Time;
    begin
        // Test case for equal values
        FirstTime := DT2Time(CurrentDateTime());
        SecondTime := FirstTime;
        LibraryAssert.IsFalse(DateAndTimeHelper.IsGreater(FirstTime, SecondTime), 'Return value should be false for equal values.');

        // Test case for first value greater than second value
        FirstTime := DT2Time(CurrentDateTime());
        SecondTime := GetNextPossibleTimeWithSQLAccuracy(FirstTime);
        LibraryAssert.IsTrue(DateAndTimeHelper.IsGreater(FirstTime, SecondTime), 'Return value should be true if first value is greater than second value.');

        // Test case for first value less than second value
        SecondTime := DT2Time(CurrentDateTime());
        FirstTime := GetNextPossibleTimeWithSQLAccuracy(SecondTime);
        LibraryAssert.IsFalse(DateAndTimeHelper.IsGreater(FirstTime, SecondTime), 'Return value should be false if first value is less than second value.');

        // Test case for first value null
        FirstTime := 0T;
        SecondTime := DT2Time(CurrentDateTime());
        LibraryAssert.IsFalse(DateAndTimeHelper.IsGreater(FirstTime, SecondTime), 'Return value should be false if first value is null.');

        // Test case for second value null
        FirstTime := DT2Time(CurrentDateTime());
        SecondTime := 0T;
        LibraryAssert.IsTrue(DateAndTimeHelper.IsGreater(FirstTime, SecondTime), 'Return value should be true if second value is null.');
    end;

    [Test]
    procedure TestTimeIsLess()
    var
        DateAndTimeHelper: Codeunit "Date and Time Helper";
        FirstTime: Time;
        SecondTime: Time;
    begin
        // Test case for equal values
        FirstTime := DT2Time(CurrentDateTime());
        SecondTime := FirstTime;
        LibraryAssert.IsFalse(DateAndTimeHelper.IsLess(FirstTime, SecondTime), 'Return value should be false for equal values.');

        // Test case for first value greater than second value
        FirstTime := DT2Time(CurrentDateTime());
        SecondTime := GetNextPossibleTimeWithSQLAccuracy(FirstTime);
        LibraryAssert.IsFalse(DateAndTimeHelper.IsLess(FirstTime, SecondTime), 'Return value should be false if first value is greater than second value.');

        // Test case for first value less than second value
        SecondTime := DT2Time(CurrentDateTime());
        FirstTime := GetNextPossibleTimeWithSQLAccuracy(SecondTime);
        LibraryAssert.IsTrue(DateAndTimeHelper.IsLess(FirstTime, SecondTime), 'Return value should be true if first value is less than second value.');

        // Test case for first value null
        FirstTime := 0T;
        SecondTime := DT2Time(CurrentDateTime());
        LibraryAssert.IsTrue(DateAndTimeHelper.IsLess(FirstTime, SecondTime), 'Return value should be true if first value is null.');

        // Test case for second value null
        FirstTime := DT2Time(CurrentDateTime());
        SecondTime := 0T;
        LibraryAssert.IsFalse(DateAndTimeHelper.IsLess(FirstTime, SecondTime), 'Return value should be false if second value is null.');
    end;

    [Test]
    procedure TestRoundDateTimeToSQLAccuracy()
    var
        DateAndTimeHelper: Codeunit "Date and Time Helper";
        DateTimeToRound: DateTime;
        ExpectedDateTime: DateTime;
    begin
        // Test case for no rounding 0 to 0
        DateTimeToRound := CreateDateTime(WorkDate(), 000000.000T);
        ExpectedDateTime := CreateDateTime(WorkDate(), 000000.000T);
        LibraryAssert.IsTrue(DateAndTimeHelper.RoundToSQLAccuracy(DateTimeToRound) = ExpectedDateTime, 'DateTime should remain ending with 0');

        // Test case for rounding 1 to 0
        DateTimeToRound := CreateDateTime(WorkDate(), 000000.001T);
        ExpectedDateTime := CreateDateTime(WorkDate(), 000000.000T);
        LibraryAssert.IsTrue(DateAndTimeHelper.RoundToSQLAccuracy(DateTimeToRound) = ExpectedDateTime, 'DateTime should be rounded to 0');

        // Test case for rounding 2 to 3
        DateTimeToRound := CreateDateTime(WorkDate(), 000000.002T);
        ExpectedDateTime := CreateDateTime(WorkDate(), 000000.003T);
        LibraryAssert.IsTrue(DateAndTimeHelper.RoundToSQLAccuracy(DateTimeToRound) = ExpectedDateTime, 'DateTime should be rounded to 3');

        // Test case for no rounding 3 to 3
        DateTimeToRound := CreateDateTime(WorkDate(), 000000.003T);
        ExpectedDateTime := CreateDateTime(WorkDate(), 000000.003T);
        LibraryAssert.IsTrue(DateAndTimeHelper.RoundToSQLAccuracy(DateTimeToRound) = ExpectedDateTime, 'DateTime should remain ending with 3');

        // Test case for rounding 4 to 3
        DateTimeToRound := CreateDateTime(WorkDate(), 000000.004T);
        ExpectedDateTime := CreateDateTime(WorkDate(), 000000.003T);
        LibraryAssert.IsTrue(DateAndTimeHelper.RoundToSQLAccuracy(DateTimeToRound) = ExpectedDateTime, 'DateTime should be rounded to 3');

        // Test case for rounding 5 to 7
        DateTimeToRound := CreateDateTime(WorkDate(), 000000.005T);
        ExpectedDateTime := CreateDateTime(WorkDate(), 000000.007T);
        LibraryAssert.IsTrue(DateAndTimeHelper.RoundToSQLAccuracy(DateTimeToRound) = ExpectedDateTime, 'DateTime should be rounded to 7');

        // Test case for no rounding 6 to 7
        DateTimeToRound := CreateDateTime(WorkDate(), 000000.006T);
        ExpectedDateTime := CreateDateTime(WorkDate(), 000000.007T);
        LibraryAssert.IsTrue(DateAndTimeHelper.RoundToSQLAccuracy(DateTimeToRound) = ExpectedDateTime, 'DateTime should remain ending with 7');

        // Test case for no rounding 7 to 7
        DateTimeToRound := CreateDateTime(WorkDate(), 000000.007T);
        ExpectedDateTime := CreateDateTime(WorkDate(), 000000.007T);
        LibraryAssert.IsTrue(DateAndTimeHelper.RoundToSQLAccuracy(DateTimeToRound) = ExpectedDateTime, 'DateTime should remain ending with 7');

        // Test case for rounding 8 to 7
        DateTimeToRound := CreateDateTime(WorkDate(), 000000.008T);
        ExpectedDateTime := CreateDateTime(WorkDate(), 000000.007T);
        LibraryAssert.IsTrue(DateAndTimeHelper.RoundToSQLAccuracy(DateTimeToRound) = ExpectedDateTime, 'DateTime should be rounded to 7');

        // Test case for rounding 9 to 0
        DateTimeToRound := CreateDateTime(WorkDate(), 235959.999T);
        ExpectedDateTime := CreateDateTime(WorkDate(), 000000.000T);
        LibraryAssert.IsTrue(DateAndTimeHelper.RoundToSQLAccuracy(DateTimeToRound) = ExpectedDateTime, 'DateTime should be rounded to 0');
    end;

    [Test]
    procedure TestCompareDateTime()
    var
        DateAndTimeHelper: Codeunit "Date and Time Helper";
        FirstDateTime: DateTime;
        SecondDateTime: DateTime;
    begin
        // Test case equal values
        FirstDateTime := CurrentDateTime();
        SecondDateTime := FirstDateTime;
        LibraryAssert.IsTrue(DateAndTimeHelper.Compare(FirstDateTime, SecondDateTime) = 0, 'Return value should be 0 for equal values.');

        // Test case for first value null
        FirstDateTime := 0DT;
        SecondDateTime := CurrentDateTime();
        LibraryAssert.IsTrue(DateAndTimeHelper.Compare(FirstDateTime, SecondDateTime) = -1, 'Return value should be -1 if first value is null.');

        // Test case for second value null
        FirstDateTime := CurrentDateTime();
        SecondDateTime := 0DT;
        LibraryAssert.IsTrue(DateAndTimeHelper.Compare(FirstDateTime, SecondDateTime) = 1, 'Return value should be 1 if second value is null.');

        // Test case for first value less than second value
        FirstDateTime := CurrentDateTime();
        SecondDateTime := GetNextPossibleDateTimeWithSQLAccuracy(FirstDateTime);
        LibraryAssert.IsTrue(DateAndTimeHelper.Compare(FirstDateTime, SecondDateTime) = -1, 'Return value should be -1 if first value is less than second value.');

        // Test case for first value greater than second value
        SecondDateTime := CurrentDateTime();
        FirstDateTime := GetNextPossibleDateTimeWithSQLAccuracy(SecondDateTime);
        LibraryAssert.IsTrue(DateAndTimeHelper.Compare(FirstDateTime, SecondDateTime) = 1, 'Return value should be 1 if first value is greater than second value.');

        // Test case for first value less than second value but equal with sql rounding
        FirstDateTime := CurrentDateTime();
        SecondDateTime := GetNextPossibleDateTimeWithSQLAccuracy(FirstDateTime) - 1;
        LibraryAssert.IsTrue(DateAndTimeHelper.Compare(FirstDateTime, SecondDateTime) = 0, 'Return value should be 0 if first value is less than second value but equal with sql rounding.');

        // Test case for first value greater than second value but equal with sql rounding
        SecondDateTime := CurrentDateTime();
        FirstDateTime := GetNextPossibleDateTimeWithSQLAccuracy(SecondDateTime) - 1;
        LibraryAssert.IsTrue(DateAndTimeHelper.Compare(FirstDateTime, SecondDateTime) = 0, 'Return value should be 0 if first value is greater than second value but equal with sql rounding.');
    end;


    local procedure GetNextPossibleTimeWithSQLAccuracy(CurrTime: Time): Time;
    var
        DateAndTimeHelper: Codeunit "Date and Time Helper";
        NewTime: Time;
    begin
        NewTime := CurrTime + 1;
        while DateAndTimeHelper.RoundToSQLAccuracy(CurrTime) = DateAndTimeHelper.RoundToSQLAccuracy(NewTime) do
            NewTime := NewTime + 1;
        exit(NewTime);
    end;

    local procedure GetNextPossibleDateTimeWithSQLAccuracy(FirstDateTime: DateTime): DateTime
    begin
        exit(CreateDateTime(DT2Date(FirstDateTime), GetNextPossibleTimeWithSQLAccuracy(DT2Time(FirstDateTime))));
    end;
}