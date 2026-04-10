codeunit 132590 "Type Helper Unit Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Type Helper] [UT]
    end;

    var
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        WrongDateFormatErr: Label 'Wrong date format';
        WrongDateTimeFormatErr: Label 'Wrong date format';
        GetOptionNoErr: Label 'GetOptionNo function returns wrong result.';

    [Test]
    [Scope('OnPrem')]
    procedure EvaluateDateWithoutTimeShift()
    var
        TypeHelper: Codeunit "Type Helper";
        Value: Variant;
        Date: Date;
        Day: Integer;
        Month: Integer;
        Year: Integer;
        String: Text;
    begin
        // [FEATURE] [Date]
        // [SCENARIO 375640] TypeHelper.Evaluate() correctly evaluates DateString to Day, Month, Year when there is no time shift

        // [GIVEN] DateString '2015-08-18T00:00:00'
        GenerateDateString(String, Day, Month, Year, '');

        // [WHEN] Evaluate DateString TypeHelper.Evaluate(...) into Date
        Value := Date;
        TypeHelper.Evaluate(Value, String, '', '');
        Date := Value;

        // [THEN] Date.Day=18, Date.Month=08, Date.Year=2015
        VerifyDateValues(Date, Day, Month, Year);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EvaluateDateWithZeroTimeShift()
    var
        TypeHelper: Codeunit "Type Helper";
        Value: Variant;
        Date: Date;
        Day: Integer;
        Month: Integer;
        Year: Integer;
        String: Text;
    begin
        // [FEATURE] [Date]
        // [SCENARIO 375640] TypeHelper.Evaluate() correctly evaluates DateString to Day, Month, Year when there is zero time shift

        // [GIVEN] DateString '2015-08-18T00:00:00+00:00'
        GenerateDateString(String, Day, Month, Year, '+00:00');

        // [WHEN] Evaluate DateString TypeHelper.Evaluate(...) into Date
        Value := Date;
        TypeHelper.Evaluate(Value, String, '', '');
        Date := Value;

        // [THEN] Date.Day=18, Date.Month=08, Date.Year=2015
        VerifyDateValues(Date, Day, Month, Year);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EvaluateDateWithPositiveTimeShift()
    var
        TypeHelper: Codeunit "Type Helper";
        Value: Variant;
        Date: Date;
        Day: Integer;
        Month: Integer;
        Year: Integer;
        String: Text;
    begin
        // [FEATURE] [Date]
        // [SCENARIO 375640] TypeHelper.Evaluate() correctly evaluates DateString to Day, Month, Year when there is positive time shift

        // [GIVEN] DateString '2015-08-18T00:00:00+12:00'
        GenerateDateString(String, Day, Month, Year, '+12:00');

        // [WHEN] Evaluate DateString TypeHelper.Evaluate(...) into Date
        Value := Date;
        TypeHelper.Evaluate(Value, String, '', '');
        Date := Value;

        // [THEN] Date.Day=18, Date.Month=08, Date.Year=2015
        VerifyDateValues(Date, Day, Month, Year);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EvaluateDateWithNegativeTimeShift()
    var
        TypeHelper: Codeunit "Type Helper";
        Value: Variant;
        Date: Date;
        Day: Integer;
        Month: Integer;
        Year: Integer;
        String: Text;
    begin
        // [FEATURE] [Date]
        // [SCENARIO 375640] TypeHelper.Evaluate() correctly evaluates DateString to Day, Month, Year when there is negative time shift

        // [GIVEN] DateString '2015-08-18T00:00:00-12:00'
        GenerateDateString(String, Day, Month, Year, '-12:00');

        // [WHEN] Evaluate DateString TypeHelper.Evaluate(...) into Date
        Value := Date;
        TypeHelper.Evaluate(Value, String, '', '');
        Date := Value;

        // [THEN] Date.Day=18, Date.Month=08, Date.Year=2015
        VerifyDateValues(Date, Day, Month, Year);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EvaluateDateTimeWithoutFormatAndCulture()
    var
        TypeHelper: Codeunit "Type Helper";
        Value: Variant;
        DateTime: DateTime;
        Day: Integer;
        Month: Integer;
        Year: Integer;
        Hour: Integer;
        Minute: Integer;
        Second: Integer;
        Milisecond: Integer;
        String: Text;
    begin
        // [FEATURE] [Date] [UT]
        // [SCENARIO 227335] TypeHelper.Evaluate() correctly evaluates DateTimeString to Day, Month, Year, Hour, Minute, Second and Millisecond with empty format and culture

        // [GIVEN] DateTimeString '2001-09-02T22:54:31.78'
        GenerateDateTimeParts(Day, Month, Year, Hour, Minute, Second, Milisecond);
        String :=
          StrSubstNo('%1-%2-%3T%4:%5:%6.%7',
            Format(Year),
            Format(Month, 0, '<Integer,2><Filler Character,0>'),
            Format(Day, 0, '<Integer,2><Filler Character,0>'),
            Format(Hour, 0, '<Integer,2><Filler Character,0>'),
            Format(Minute, 0, '<Integer,2><Filler Character,0>'),
            Format(Second, 0, '<Integer,2><Filler Character,0>'),
            Format(Milisecond, 0, '<Integer,3><Filler Character,0>'));

        // [WHEN] Evaluate DateTimeString TypeHelper.Evaluate(...) into DateTime
        Value := DateTime;
        TypeHelper.Evaluate(Value, String, '', '');
        DateTime := Value;

        // [THEN] Day=2, Month=09, Year=2001, Hour=22, Minute=54, Second=31, Milisecond=780
        VerifyDateTimeValues(DateTime, Day, Month, Year, Hour, Minute, Second, Milisecond);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EvaluateDateTimeWithFormat()
    var
        TypeHelper: Codeunit "Type Helper";
        Value: Variant;
        EvaluatedDateTime: DateTime;
        Day: Integer;
        Month: Integer;
        Year: Integer;
        Hour: Integer;
        Minute: Integer;
        Second: Integer;
        Milisecond: Integer;
        TimeShift: Integer;
        String: Text;
    begin
        // [FEATURE] [Date] [UT]
        // [SCENARIO 227335] TypeHelper.Evaluate() correctly evaluates DateTimeString to Day, Month, Year, Hour, Minute, Second and Millisecond using custom format value

        // [GIVEN] DateTimeString '02.09.2001 22:54:31.78 +01:00'
        GenerateDateTimeParts(Day, Month, Year, Hour, Minute, Second, Milisecond);
        TimeShift := LibraryRandom.RandIntInRange(1, 5);
        String :=
          StrSubstNo('%1.%2.%3 %4:%5:%6.%7 +0%8:00',
            Format(Day, 0, '<Integer,2><Filler Character,0>'),
            Format(Month, 0, '<Integer,2><Filler Character,0>'),
            Format(Year),
            Format(Hour, 0, '<Integer,2><Filler Character,0>'),
            Format(Minute, 0, '<Integer,2><Filler Character,0>'),
            Format(Second, 0, '<Integer,2><Filler Character,0>'),
            Format(Milisecond, 0, '<Integer,3><Filler Character,0>'),
            TimeShift);

        // [WHEN] Evaluate DateTimeString TypeHelper.Evaluate(...) into DateTime
        Value := EvaluatedDateTime;
        TypeHelper.Evaluate(Value, String, 'dd.MM.yyyy HH:mm:ss.fff zzz', '');
        EvaluatedDateTime := Value;

        // [THEN] Date.Day=2, Date.Month=09, Date.Year=2001, Hour=21, Minute=54, Second=31, Milisecond=780
        VerifyDateTimeValues(EvaluatedDateTime, Day, Month, Year, Hour - TimeShift, Minute, Second, Milisecond);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EvaluateDateTimeWithCultureAndFormat()
    var
        Language: Record Language;
        TypeHelper: Codeunit "Type Helper";
        Value: Variant;
        EvaluatedDateTime: DateTime;
        Day: Integer;
        Month: Integer;
        Year: Integer;
        Hour: Integer;
        Minute: Integer;
        Second: Integer;
        Milisecond: Integer;
        String: Text;
    begin
        // [FEATURE] [Date] [UT]
        // [SCENARIO 227335] TypeHelper.Evaluate() correctly evaluates DateTimeString to Day, Month, Year, Hour, Minute, Second and Millisecond using Danish culture and format

        // [GIVEN] Danish DateTimeString '02 sen 2001 22:54:31.78'
        GenerateDateTimeParts(Day, Month, Year, Hour, Minute, Second, Milisecond);
        Language.Get('DAN');
        String :=
          StrSubstNo('%1 %2 %3 %4:%5:%6.%7',
            Format(Day, 0, '<Integer,2><Filler Character,0>'),
            GetTranslatedMonth(DMY2Date(Day, Month, Year), Language."Windows Language ID"),
            Format(Year),
            Format(Hour, 0, '<Integer,2><Filler Character,0>'),
            Format(Minute, 0, '<Integer,2><Filler Character,0>'),
            Format(Second, 0, '<Integer,2><Filler Character,0>'),
            Format(Milisecond, 0, '<Integer,3><Filler Character,0>'));

        // [WHEN] Evaluate DateTimeString TypeHelper.Evaluate(...) into DateTime
        Value := EvaluatedDateTime;
        TypeHelper.Evaluate(Value, String, 'dd MMM yyyy HH:mm:ss.fff', 'da-DK');
        EvaluatedDateTime := Value;

        // [THEN] Date.Day=2, Date.Month=09, Date.Year=2001, Hour=22, Minute=54, Second=31, Milisecond=780
        VerifyDateTimeValues(EvaluatedDateTime, Day, Month, Year, Hour, Minute, Second, Milisecond);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EvaluateUTCDateTime()
    var
        TypeHelper: Codeunit "Type Helper";
        DateTime: DateTime;
        Day: Integer;
        Month: Integer;
        Year: Integer;
        Hour: Integer;
        Minute: Integer;
        Second: Integer;
        Milisecond: Integer;
        String: Text;
    begin
        // [FEATURE] [Date] [UT]
        // [SCENARIO 227335] TypeHelper.Evaluate() correctly evaluates UTC DateTimeString to Day, Month, Year, Hour, Minute, Second and Millisecond

        // [GIVEN] DateTimeString 'Sun, 02 Sep 2001 22:54:31 GMT'
        GenerateDateTimeParts(Day, Month, Year, Hour, Minute, Second, Milisecond);
        String :=
          StrSubstNo('%1, %2 %3 %4 %5:%6:%7 GMT',
            Format(DMY2Date(Day, Month, Year), 0, '<Weekday Text,3>'),
            Format(Day, 0, '<Integer,2><Filler Character,0>'),
            Format(DMY2Date(Day, Month, Year), 0, '<Month Text,3>'),
            Format(Year),
            Format(Hour, 0, '<Integer,2><Filler Character,0>'),
            Format(Minute, 0, '<Integer,2><Filler Character,0>'),
            Format(Second, 0, '<Integer,2><Filler Character,0>'));

        // [WHEN] Evaluate DateTimeString TypeHelper.Evaluate(...) into DateTime
        DateTime := TypeHelper.EvaluateUTCDateTime(String);

        // [THEN] Day=2, Month=09, Year=2001, Hour=22, Minute=54, Second=31, Milisecond=780
        VerifyDateTimeValues(DateTime, Day, Month, Year, Hour, Minute, Second, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FormatDateTimeWithCultureAndFormat()
    var
        TypeHelper: Codeunit "Type Helper";
        DateTime: DateTime;
        FormattedDateTime: Text;
    begin
        // [FEATURE] [Date] [UT]
        // [SCENARIO 227335] TypeHelper.FormatDateTime correctly formats DateTime using custom format and Danish culture

        // [GIVEN] DateTime '01.10.2017 22:54:31.123'
        DateTime := CreateDateTime(DMY2Date(1, 10, 2017), CreateTime(22, 54, 31, 123));

        // [WHEN] Formatting DateTime with Danish culture and format 'dd MMM yyyy HH:mm:ss.fff'
        FormattedDateTime := TypeHelper.FormatDateTime(DateTime, 'dd MMM yyyy HH:mm:ss.fff', 'da-DK');

        // [THEN] Result is equalt to '01 okt 2017 22:54:31.123'
        Assert.AreEqual('01 okt 2017 22:54:31.123', FormattedDateTime, WrongDateTimeFormatErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FormatDateToSpecificDateFormat_ENU()
    var
        Language: Record Language;
        TypeHelper: Codeunit "Type Helper";
        Date: Date;
        ConvertedDateText: Text;
    begin
        // [FEATURE] [Date]
        // [SCENARIO 377566] TypeHelper.FormatDate() correctly converts Date to ENU Date Format

        // [GIVEN] Date '01/10/2016'
        Date := DMY2Date(1, 10, 2016);

        // [WHEN] Format Date to 'ENU' English (United States) Language Date Format
        Language.Get('ENU');
        ConvertedDateText := TypeHelper.FormatDate(Date, Language."Windows Language ID");

        // [THEN] Date is equal to '10/1/2016'
        Assert.AreEqual('10/1/2016', ConvertedDateText, WrongDateFormatErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FormatDateToSpecificDateFormat_DEU()
    var
        Language: Record Language;
        TypeHelper: Codeunit "Type Helper";
        Date: Date;
        ConvertedDateText: Text;
    begin
        // [FEATURE] [Date]
        // [SCENARIO 377566] TypeHelper.FormatDate() correctly converts Date to DEU Date Format

        // [GIVEN] Date '01/10/2016'
        Date := DMY2Date(1, 10, 2016);

        // [WHEN] Format Date to 'DEU' German (Germany) Language Date Format
        Language.Get('DEU');
        ConvertedDateText := TypeHelper.FormatDate(Date, Language."Windows Language ID");

        // [THEN] Date is equal to '01.10.2016'
        Assert.AreEqual('01.10.2016', ConvertedDateText, WrongDateFormatErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FormatDateToSpecificDateFormat_ESP()
    var
        Language: Record Language;
        TypeHelper: Codeunit "Type Helper";
        Date: Date;
        ConvertedDateText: Text;
    begin
        // [FEATURE] [Date]
        // [SCENARIO 377566] TypeHelper.FormatDate() correctly converts Date to ESP Date Format

        // [GIVEN] Date '01/10/2016'
        Date := DMY2Date(1, 10, 2016);

        // [WHEN] Format Date to 'ESP' Spanish (Spain) Language Date Format
        Language.Get('ESP');
        ConvertedDateText := TypeHelper.FormatDate(Date, Language."Windows Language ID");

        // [THEN] Date is equal to '01/10/2016'
        Assert.AreEqual('01/10/2016', ConvertedDateText, WrongDateFormatErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FormatDecimalToStandardFormatWithDotNetString()
    var
        TypeHelper: Codeunit "Type Helper";
        Amount: Decimal;
        FormattingResult: Text;
    begin
        // [FEATURE] [Standard DotNet Formats]
        // [SCENARIO] TypeHelper.Format() correctly converts Decimal to standard NAV formatting

        // [GIVEN] Amount 123.456789
        Amount := 123.456789;

        // [WHEN] Format Decimal to DotNet standard format
        FormattingResult := TypeHelper.FormatDecimal(Amount, 'G', '');

        // [THEN] Amount is equal to standard NAV format
        Assert.AreEqual(Format(Amount, 0, 1), FormattingResult, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FormatDecimalToStandardXmlFormatDotNetString()
    var
        TypeHelper: Codeunit "Type Helper";
        Amount: Decimal;
        FormattingResult: Text;
    begin
        // [FEATURE] [Standard DotNet Formats]
        // [SCENARIO] TypeHelper.Format() correctly converts Decimal to standard Xml formatting

        // [GIVEN] Amount 123.456789
        Amount := 123.456789;

        // [WHEN] Format Decimal to DotNet standard Xml format
        FormattingResult := TypeHelper.FormatDecimal(Amount, 'G', 'en-US');

        // [THEN] Amount is equal to standard NAV format
        Assert.AreEqual(Format(Amount, 0, 9), FormattingResult, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FormatDateTimeToUtcDateTimeWithDotNetString()
    var
        TypeHelper: Codeunit "Type Helper";
        DateTime: DateTime;
        FormattingResult: Text;
    begin
        // [FEATURE] [Standard DotNet Formats]
        // [SCENARIO] TypeHelper.Format() correctly converts DateTime to utc date time formatting

        // [GIVEN] DateTime is current date and time
        DateTime := RoundDateTime(TypeHelper.GetCurrUTCDateTime());

        // [WHEN] Format DateTime with DotNet to get utc time
        FormattingResult := TypeHelper.FormatUtcDateTime(DateTime, 's', 'en-US');

        // [THEN] DateTime matches NAV Xml formatting
        Assert.AreEqual(Format(DateTime, 0, 9), FormattingResult + 'Z', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIsLeapYear()
    var
        TypeHelper: Codeunit "Type Helper";
        Date: Date;
    begin
        // [GIVEN] A leap year
        Date := DMY2Date(1, 1, 2000);

        // [WHEN] IsLeapYear is called
        // [THEN] It returns true
        Assert.IsTrue(TypeHelper.IsLeapYear(Date), 'Year was not a leap year');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIsNotLeapYear()
    var
        TypeHelper: Codeunit "Type Helper";
        Date: Date;
    begin
        // [GIVEN] A non-leap year
        Date := DMY2Date(1, 1, 2001);

        // [WHEN] IsLeapYear is called
        // [THEN] It returns false
        Assert.IsFalse(TypeHelper.IsLeapYear(Date), 'Year was a leap year');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIsNumeric()
    var
        TypeHelper: Codeunit "Type Helper";
        Text: Text;
    begin
        // [GIVEN] A numeric string
        Text := '1234567890';
        // [WHEN] IsNumeric is called
        // [THEN] It returns true
        Assert.IsTrue(TypeHelper.IsNumeric(Text), 'String was not numeric');

        // [GIVEN] A numeric decimal with negative sign and comma
        Text := '-123.12';
        // [WHEN] IsNumeric is called
        // [THEN] It returns true
        Assert.IsTrue(TypeHelper.IsNumeric(Text), 'String was not numeric');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIsNotNumeric()
    var
        TypeHelper: Codeunit "Type Helper";
        Text: Text;
    begin
        // [GIVEN] A non-numeric string
        Text := 'Test1234567890';

        // [WHEN] IsNumeric is called
        // [THEN] It returns false
        Assert.IsFalse(TypeHelper.IsNumeric(Text), 'String was numeric');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNewLine()
    var
        TypeHelper: Codeunit "Type Helper";
    begin
        // [WHEN] NewLine is called
        // [THEN] A new line is returned
        Assert.AreEqual(TypeHelper.CRLFSeparator(), TypeHelper.NewLine(), 'Function did not return new line');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestLevenshteinDistance()
    var
        TypeHelper: Codeunit "Type Helper";
        LongText: Text;
        i: Integer;
    begin
        // Assert that the Levenshtein distance is calculated correctly in codeunit 10 (Type Helper)
        Assert.AreEqual(11, TypeHelper.TextDistance('Hello World', ''), 'Test - edge case 1');
        Assert.AreEqual(11, TypeHelper.TextDistance('', 'Hello World'), 'Test - edge case 2');
        Assert.AreEqual(0, TypeHelper.TextDistance('', ''), 'Test - edge case 3');
        Assert.AreEqual(0, TypeHelper.TextDistance('Hello World', 'Hello World'), 'Test 1');
        Assert.AreEqual(1, TypeHelper.TextDistance('Hello Word', 'Hello World'), 'Test 2');
        Assert.AreEqual(1, TypeHelper.TextDistance('Hello World', 'Hello Word'), 'Test 3');
        Assert.AreEqual(1, TypeHelper.TextDistance('Hallo World', 'Hello World'), 'Test 4');
        Assert.AreEqual(2, TypeHelper.TextDistance('Hallo World', 'Hell World'), 'Test 5');
        Assert.AreEqual(8, TypeHelper.TextDistance('Hard', 'Hello World'), 'Test 6');
        for i := 1 to 100 do
            LongText += 'Hello World ';
        asserterror i := TypeHelper.TextDistance(LongText, 'Hello World');
        asserterror i := TypeHelper.TextDistance('Hello World', LongText);
        LongText := CopyStr(LongText, 1, 1023);
        Assert.AreEqual(2, TypeHelper.TextDistance('X' + LongText, LongText + 'Y'), 'Test 7');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIsPhoneNumber()
    var
        TypeHelper: Codeunit "Type Helper";
        ValidPhoneNb1: Text;
        ValidPhoneNb2: Text;
        ValidPhoneNb3: Text;
        ValidPhoneNb4: Text;
        InvalidPhoneNb1: Text;
        InvalidPhoneNb2: Text;
        InvalidPhoneNb3: Text;
        InvalidPhoneNb4: Text;
        InvalidPhoneNb5: Text;
        InvalidPhoneNb6: Text;
    begin
        // [SCENARIO] Test different phone numbers (valid and invalid ones) and check the results are as expected.

        // [GIVEN] Different phone numbers
        ValidPhoneNb1 := '+45 12345678';
        ValidPhoneNb2 := '12 34 56 78';
        ValidPhoneNb3 := '(512) 736-1777';
        ValidPhoneNb4 := ''; // if mandatory field, we assume the test is performed elsewhere
        InvalidPhoneNb1 := 'WRONG';
        InvalidPhoneNb2 := '12.345.678';
        InvalidPhoneNb3 := '#123456789';
        InvalidPhoneNb4 := '1337!';
        InvalidPhoneNb5 := 'bad123';
        InvalidPhoneNb6 := '3615 *';

        // [WHEN] We test them
        // [THEN] The function gives us the correct result (valid phone number or not)
        Assert.IsTrue(TypeHelper.IsPhoneNumber(ValidPhoneNb1), 'Should be true: ' + ValidPhoneNb1 + ' is a valid phone number.');
        Assert.IsTrue(TypeHelper.IsPhoneNumber(ValidPhoneNb2), 'Should be true: ' + ValidPhoneNb2 + ' is a valid phone number.');
        Assert.IsTrue(TypeHelper.IsPhoneNumber(ValidPhoneNb3), 'Should be true: ' + ValidPhoneNb3 + ' is a valid phone number.');
        Assert.IsTrue(TypeHelper.IsPhoneNumber(ValidPhoneNb4), 'Should be true: ' + ValidPhoneNb4 + ' is a valid phone number.');
        Assert.IsFalse(TypeHelper.IsPhoneNumber(InvalidPhoneNb1), 'Should be false: ' + InvalidPhoneNb1 + ' is an invalid phone number.');
        Assert.IsFalse(TypeHelper.IsPhoneNumber(InvalidPhoneNb2), 'Should be false: ' + InvalidPhoneNb2 + ' is an invalid phone number.');
        Assert.IsFalse(TypeHelper.IsPhoneNumber(InvalidPhoneNb3), 'Should be false: ' + InvalidPhoneNb3 + ' is an invalid phone number.');
        Assert.IsFalse(TypeHelper.IsPhoneNumber(InvalidPhoneNb4), 'Should be false: ' + InvalidPhoneNb4 + ' is an invalid phone number.');
        Assert.IsFalse(TypeHelper.IsPhoneNumber(InvalidPhoneNb5), 'Should be false: ' + InvalidPhoneNb5 + ' is an invalid phone number.');
        Assert.IsFalse(TypeHelper.IsPhoneNumber(InvalidPhoneNb6), 'Should be false: ' + InvalidPhoneNb6 + ' is an invalid phone number.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBitwiseAnd()
    var
        TypeHelper: Codeunit "Type Helper";
        Zero: Integer;
        "Max": Integer;
        Sequence10: Integer;
        Sequence01: Integer;
        Positive: Integer;
        Negative: Integer;
    begin
        // [SCENARIO] BitwiseAnd() implements a bitwise AND operator

        // [GIVEN] Different numbers
        Zero := 0; // 0000 0000 0000 0000 0000 0000 0000 0000
        Max := 2147483647; // 0111 1111 1111 1111 1111 1111 1111 1111
        Sequence10 := 715827882; // 0010 1010 1010 1010 1010 1010 1010 1010
        Sequence01 := 1431655765; // 0101 0101 0101 0101 0101 0101 0101 0101
        Positive := LibraryRandom.RandInt(Max);
        Negative := -LibraryRandom.RandInt(Max);

        // [WHEN] We test them
        // [THEN] The function gives us the correct result
        asserterror TypeHelper.BitwiseAnd(Negative, Positive);
        asserterror TypeHelper.BitwiseAnd(Positive, Negative);
        Assert.AreEqual(TypeHelper.BitwiseAnd(Zero, Zero), Zero, StrSubstNo('%1 & %2 <> %3', Zero, Zero, Zero));
        Assert.AreEqual(TypeHelper.BitwiseAnd(Max, Max), Max, StrSubstNo('%1 & %2 <> %3', Max, Max, Max));
        Assert.AreEqual(TypeHelper.BitwiseAnd(Positive, Positive), Positive, StrSubstNo('%1 & %2 <> %3', Positive, Positive, Positive));
        Assert.AreEqual(TypeHelper.BitwiseAnd(Positive, Zero), Zero, StrSubstNo('%1 & %2 <> %3', Positive, Zero, Zero));
        Assert.AreEqual(TypeHelper.BitwiseAnd(Zero, Positive), Zero, StrSubstNo('%1 & %2 <> %3', Zero, Positive, Zero));
        Assert.AreEqual(TypeHelper.BitwiseAnd(Positive, Max), Positive, StrSubstNo('%1 & %2 <> %3', Positive, Max, Positive));
        Assert.AreEqual(TypeHelper.BitwiseAnd(Max, Positive), Positive, StrSubstNo('%1 & %2 <> %3', Max, Positive, Positive));
        Assert.AreEqual(TypeHelper.BitwiseAnd(Sequence01, Sequence10), Zero, StrSubstNo('%1 & %2 <> %3', Sequence01, Sequence10, Zero));
        Assert.AreEqual(TypeHelper.BitwiseAnd(Sequence10, Sequence01), Zero, StrSubstNo('%1 & %2 <> %3', Sequence10, Sequence01, Zero));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBitwiseOr()
    var
        TypeHelper: Codeunit "Type Helper";
        Zero: Integer;
        "Max": Integer;
        Sequence10: Integer;
        Sequence01: Integer;
        Positive: Integer;
        Negative: Integer;
    begin
        // [SCENARIO] BitwiseOr() implements a bitwise OR operator

        // [GIVEN] Different numbers
        Zero := 0; // 0000 0000 0000 0000 0000 0000 0000 0000
        Max := 2147483647; // 0111 1111 1111 1111 1111 1111 1111 1111
        Sequence10 := 715827882; // 0010 1010 1010 1010 1010 1010 1010 1010
        Sequence01 := 1431655765; // 0101 0101 0101 0101 0101 0101 0101 0101
        Positive := LibraryRandom.RandInt(Max);
        Negative := -LibraryRandom.RandInt(Max);

        // [WHEN] We test them
        // [THEN] The function gives us the correct result
        asserterror TypeHelper.BitwiseOr(Negative, Positive);
        asserterror TypeHelper.BitwiseOr(Positive, Negative);
        Assert.AreEqual(TypeHelper.BitwiseOr(Zero, Zero), Zero, StrSubstNo('%1 | %2 <> %3', Zero, Zero, Zero));
        Assert.AreEqual(TypeHelper.BitwiseOr(Max, Max), Max, StrSubstNo('%1 | %2 <> %3', Max, Max, Max));
        Assert.AreEqual(TypeHelper.BitwiseOr(Positive, Positive), Positive, StrSubstNo('%1 | %2 <> %3', Positive, Positive, Positive));
        Assert.AreEqual(TypeHelper.BitwiseOr(Positive, Zero), Positive, StrSubstNo('%1 | %2 <> %3', Positive, Zero, Positive));
        Assert.AreEqual(TypeHelper.BitwiseOr(Zero, Positive), Positive, StrSubstNo('%1 | %2 <> %3', Zero, Positive, Positive));
        Assert.AreEqual(TypeHelper.BitwiseOr(Positive, Max), Max, StrSubstNo('%1 | %2 <> %3', Positive, Max, Max));
        Assert.AreEqual(TypeHelper.BitwiseOr(Max, Positive), Max, StrSubstNo('%1 | %2 <> %3', Max, Positive, Max));
        Assert.AreEqual(TypeHelper.BitwiseOr(Sequence01, Sequence10), Max, StrSubstNo('%1 | %2 <> %3', Sequence01, Sequence10, Max));
        Assert.AreEqual(TypeHelper.BitwiseOr(Sequence10, Sequence01), Max, StrSubstNo('%1 | %2 <> %3', Sequence10, Sequence01, Max));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBitwiseXor()
    var
        TypeHelper: Codeunit "Type Helper";
        Zero: Integer;
        "Max": Integer;
        Sequence10: Integer;
        Sequence01: Integer;
        Positive: Integer;
        Negative: Integer;
    begin
        // [SCENARIO] BitwiseXor() implements a bitwise XOR operator

        // [GIVEN] Different numbers
        Zero := 0; // 0000 0000 0000 0000 0000 0000 0000 0000
        Max := 2147483647; // 0111 1111 1111 1111 1111 1111 1111 1111
        Sequence10 := 715827882; // 0010 1010 1010 1010 1010 1010 1010 1010
        Sequence01 := 1431655765; // 0101 0101 0101 0101 0101 0101 0101 0101
        Positive := LibraryRandom.RandInt(Max);
        Negative := -LibraryRandom.RandInt(Max);

        // [WHEN] We test them
        // [THEN] The function gives us the correct result
        asserterror TypeHelper.BitwiseXor(Negative, Positive);
        asserterror TypeHelper.BitwiseXor(Positive, Negative);
        Assert.AreEqual(TypeHelper.BitwiseXor(Zero, Zero), Zero, StrSubstNo('%1 ^ %2 <> %3', Zero, Zero, Zero));
        Assert.AreEqual(TypeHelper.BitwiseXor(Max, Max), Zero, StrSubstNo('%1 ^ %2 <> %3', Max, Max, Zero));
        Assert.AreEqual(TypeHelper.BitwiseXor(Positive, Positive), Zero, StrSubstNo('%1 ^ %2 <> %3', Positive, Positive, Zero));
        Assert.AreEqual(TypeHelper.BitwiseXor(Positive, Zero), Positive, StrSubstNo('%1 ^ %2 <> %3', Positive, Zero, Positive));
        Assert.AreEqual(TypeHelper.BitwiseXor(Zero, Positive), Positive, StrSubstNo('%1 ^ %2 <> %3', Zero, Positive, Positive));
        Assert.AreEqual(TypeHelper.BitwiseXor(Sequence01, Sequence10), Max, StrSubstNo('%1 ^ %2 <> %3', Sequence01, Sequence10, Max));
        Assert.AreEqual(TypeHelper.BitwiseXor(Sequence10, Sequence01), Max, StrSubstNo('%1 ^ %2 <> %3', Sequence10, Sequence01, Max));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDateTimeComparison()
    var
        TypeHelper: Codeunit "Type Helper";
        DateTimeA: DateTime;
        DateTimeB: DateTime;
        Threshold: Integer;
    begin
        // Threshold for equality when comparing DateTime values. If the difference
        // is less than this value, then we treat them as equal values.
        Threshold := 10;

        Assert.IsTrue(TypeHelper.CompareDateTime(DateTimeA, DateTimeB) = 0, 'Return value should be 0 for two null values.');

        DateTimeA := CurrentDateTime;
        Assert.IsTrue(TypeHelper.CompareDateTime(DateTimeA, DateTimeB) > 0, 'Return value should be > 0 if second value is null.');
        Assert.IsTrue(TypeHelper.CompareDateTime(DateTimeB, DateTimeA) < 0, 'Return value should be < 0 if first value is null.');

        DateTimeB := DateTimeA;
        Assert.IsTrue(TypeHelper.CompareDateTime(DateTimeA, DateTimeB) = 0, 'Return value should be 0 for equal values.');

        DateTimeB := DateTimeA + LibraryRandom.RandIntInRange(0, Threshold - 1);
        Assert.IsTrue(TypeHelper.CompareDateTime(DateTimeA, DateTimeB) = 0, 'Return value should be 0 for values within threshold.');
        Assert.IsTrue(TypeHelper.CompareDateTime(DateTimeB, DateTimeA) = 0, 'Return value should be 0 for values within threshold.');

        DateTimeB := DateTimeA + Threshold;
        Assert.IsTrue(TypeHelper.CompareDateTime(DateTimeA, DateTimeB) < 0, 'Return value should be < 0.');
        Assert.IsTrue(TypeHelper.CompareDateTime(DateTimeB, DateTimeA) > 0, 'Return value should be > 0.');

        DateTimeB := DateTimeA + LibraryRandom.RandIntInRange(Threshold + 1, 500);
        Assert.IsTrue(TypeHelper.CompareDateTime(DateTimeA, DateTimeB) < 0, 'Return value should be < 0.');
        Assert.IsTrue(TypeHelper.CompareDateTime(DateTimeB, DateTimeA) > 0, 'Return value should be > 0.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetAmountFormat()
    var
        TypeHelper: Codeunit "Type Helper";
    begin
        // $n formats
        Assert.AreEqual('$<Precision,0:0><Standard Format,0>', TypeHelper.GetAmountFormat(2057, '$'), 'Invalid amount format for en-gb'); // en-gb
        Assert.AreEqual('$<Precision,0:0><Standard Format,0>', TypeHelper.GetAmountFormat(1033, '$'), 'Invalid amount format for en-us'); // en-us

        // $ n formats
        Assert.AreEqual('$ <Precision,0:0><Standard Format,0>', TypeHelper.GetAmountFormat(1044, '$'), 'Invalid amount format for no-no '); // no-no
        Assert.AreEqual('$ <Precision,0:0><Standard Format,0>', TypeHelper.GetAmountFormat(2055, '$'), 'Invalid amount format for de-ch'); // de-ch
        Assert.AreEqual('$ <Precision,0:0><Standard Format,0>', TypeHelper.GetAmountFormat(2064, '$'), 'Invalid amount format for it-ch'); // it-ch
        Assert.AreEqual('$ <Precision,0:0><Standard Format,0>', TypeHelper.GetAmountFormat(1043, '$'), 'Invalid amount format for nl-nl'); // nl-nl
        Assert.AreEqual('$ <Precision,0:0><Standard Format,0>', TypeHelper.GetAmountFormat(3079, '$'), 'Invalid amount format for de-at'); // de-at
        Assert.AreEqual('$ <Precision,0:0><Standard Format,0>', TypeHelper.GetAmountFormat(2067, '$'), 'Invalid amount format for nl-be'); // nl-be

        // n $ formats        
        Assert.AreEqual('<Precision,0:0><Standard Format,0> $', TypeHelper.GetAmountFormat(2060, '$'), 'Invalid amount format for fr-be'); // fr-be
        Assert.AreEqual('<Precision,0:0><Standard Format,0> $', TypeHelper.GetAmountFormat(1040, '$'), 'Invalid amount format for it-it'); // it-it
        Assert.AreEqual('<Precision,0:0><Standard Format,0> $', TypeHelper.GetAmountFormat(1035, '$'), 'Invalid amount format for fi'); // fi
        Assert.AreEqual('<Precision,0:0><Standard Format,0> $', TypeHelper.GetAmountFormat(1034, '$'), 'Invalid amount format for es-es'); // es-es
        // FIXME Assert.AreEqual('<Precision,0:0><Standard Format,0> $',TypeHelper.GetAmountFormat(4108,'$'),'Invalid amount format for fr-ch'); // fr-ch
        Assert.AreEqual('<Precision,0:0><Standard Format,0> $', TypeHelper.GetAmountFormat(1031, '$'), 'Invalid amount format for de-de'); // de-de
        Assert.AreEqual('<Precision,0:0><Standard Format,0> $', TypeHelper.GetAmountFormat(1030, '$'), 'Invalid amount format for da-DK'); // da-DK
        Assert.AreEqual('<Precision,0:0><Standard Format,0> $', TypeHelper.GetAmountFormat(1053, '$'), 'Invalid amount format for sv-SE'); // sv-Se

        // error cases
        Assert.AreEqual('<Precision,0:0><Standard Format,0>', TypeHelper.GetAmountFormat(-1, '$'), 'Invalid amount format for error case');
        Assert.AreEqual('<Precision,0:0><Standard Format,0>', TypeHelper.GetAmountFormat(0, '$'), 'Invalid amount format for error case');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyReadRecordLinkNote()
    var
        RecordLink: Record "Record Link";
        RecordLinkManagement: Codeunit "Record Link Management";
    begin
        RecordLink.DeleteAll();

        RecordLinkManagement.WriteNote(RecordLink, 'This is a test');

        RecordLink.Insert();
        Assert.AreEqual(RecordLinkManagement.ReadNote(RecordLink), 'This is a test',
          'The value in the Note field was read incorrectly');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyEmptyReadRecordLinkNote()
    var
        RecordLink: Record "Record Link";
        RecordLinkManagement: Codeunit "Record Link Management";
    begin
        RecordLink.DeleteAll();

        RecordLink.Insert();
        Assert.AreEqual(RecordLinkManagement.ReadNote(RecordLink), '', 'The value in the Note field was read incorrectly');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCalculateLog()
    var
        TypeHelper: Codeunit "Type Helper";
    begin
        Assert.AreEqual(2, TypeHelper.CalculateLog(100), '10 raised to 2 is 100.');
        Assert.AreEqual(-2, TypeHelper.CalculateLog(0.01), '10 raised to -2 is 0.01.');
        Assert.AreNearlyEqual(0.301, TypeHelper.CalculateLog(2), 0.0001, '10 raised to 0.3010 is nearly 2.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DateTimeToTimeZone()
    var
        TimeZone: Record "Time Zone";
        TypeHelper: Codeunit "Type Helper";
        TimeZoneOffset: Duration;
        UserOffset: Duration;
        InputDateTime: DateTime;
    begin
        // [SCENARIO 323341] Convert DateTime to Time Zone
        InputDateTime := CreateDateTime(LibraryRandom.RandDate(10), Time);

        TypeHelper.GetUserClientTypeOffset(UserOffset);
        TimeZone.SetFilter("Display Name", '*:00*');
        TimeZone.FindSet();
        TimeZone.Next(LibraryRandom.RandInt(TimeZone.Count));
        TypeHelper.GetTimezoneOffset(TimeZoneOffset, TimeZone.ID);

        Assert.AreEqual(
          InputDateTime + TimeZoneOffset - UserOffset,
          TypeHelper.ConvertDateTimeFromUTCToTimeZone(InputDateTime, TimeZone.ID), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DateTimeToBlankTimeZone()
    var
        TypeHelper: Codeunit "Type Helper";
        InputDateTime: DateTime;
    begin
        // [SCENARIO 323341] Convert DateTime when Time Zone is not specified does not change DateTime
        InputDateTime := CreateDateTime(LibraryRandom.RandDate(10), Time);
        Assert.AreEqual(InputDateTime, TypeHelper.ConvertDateTimeFromUTCToTimeZone(InputDateTime, ''), '');
    end;

    local procedure CreateTime(Hour: Integer; Minute: Integer; Second: Integer; Milisecond: Integer): Time
    var
        NewTime: Time;
    begin
        Evaluate(
          NewTime,
          StrSubstNo('%1:%2:%3.%4', Hour, Minute, Second, Milisecond));
        exit(NewTime);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetOptionNoUT_EmptySubstringAndEmptyOptionNotExists_NoOption()
    var
        TypeHelper: Codeunit "Type Helper";
    begin
        Assert.AreEqual(-1, TypeHelper.GetOptionNo('', 'aaa,bbb'), GetOptionNoErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetOptionNoUT_EmptySubstringAndEmptyOptionInTheMiddle_OptionFound()
    var
        TypeHelper: Codeunit "Type Helper";
    begin
        Assert.AreEqual(-1, TypeHelper.GetOptionNo('', 'aaa,,bbb'), GetOptionNoErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetOptionNoUT_EmptySubstringAndSpaceOptionInTheEnd_OptionFound()
    var
        TypeHelper: Codeunit "Type Helper";
    begin
        Assert.AreEqual(2, TypeHelper.GetOptionNo('', 'aaa,bbb, '), GetOptionNoErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetOptionNoUT_SpaceSubstringAndSpaceOptionInTheEnd_OptionFound()
    var
        TypeHelper: Codeunit "Type Helper";
    begin
        Assert.AreEqual(2, TypeHelper.GetOptionNo(' ', 'aaa,bbb, '), GetOptionNoErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetOptionNoUT_OnlyOneOptionExists_OptionFound()
    var
        TypeHelper: Codeunit "Type Helper";
    begin
        Assert.AreEqual(0, TypeHelper.GetOptionNo('aaa', 'aaa'), GetOptionNoErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetOptionNoUT_OnlyOneEmptyOptionExists_OptionFound()
    var
        TypeHelper: Codeunit "Type Helper";
    begin
        Assert.AreEqual(-1, TypeHelper.GetOptionNo('', ''), GetOptionNoErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetOptionNoUT_GetWrongOptionFromOneOption_OptionNotFound()
    var
        TypeHelper: Codeunit "Type Helper";
    begin
        Assert.AreEqual(-1, TypeHelper.GetOptionNo('', 'aaa'), GetOptionNoErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetOptionNoUT_GetWrongOptionFromOneEmptyOption_OptionNotFound()
    var
        TypeHelper: Codeunit "Type Helper";
    begin
        Assert.AreEqual(-1, TypeHelper.GetOptionNo('aaa', ''), GetOptionNoErr);
    end;

    [Test]
    procedure EvaluateDecimalWithCurrencySignAndParentheses()
    var
        TypeHelper: Codeunit "Type Helper";
        InputValue: Text;
        Result: Variant;
    begin
        // [FEATURE] [UT] 
        // [SCENARIO 414170] Evalute decimal value with currency sign and parenthesess
        // [GIVEN] String "($123.45)"
        InputValue := '($123.45)';

        // [WHEN] Invoke "Type Helper".Evaluate
        Result := 0.0;
        TypeHelper.Evaluate(Result, InputValue, '', 'en-US');

        // [THEN] Result = -123.45
        Assert.AreEqual(-123.45, Result, 'Wrong value.');
    end;

    local procedure GenerateDateString(var String: Text; var Day: Integer; var Month: Integer; var Year: Integer; TimeShift: Text)
    begin
        Day := LibraryRandom.RandIntInRange(1, 28);
        Month := LibraryRandom.RandIntInRange(1, 12);
        Year := LibraryRandom.RandIntInRange(2000, 2050);
        String :=
          Format(Year) + '-' +
          Format(Month, 0, '<Integer,2><Filler Character,0>') + '-' +
          Format(Day, 0, '<Integer,2><Filler Character,0>') + 'T00:00:00' +
          TimeShift;
    end;

    local procedure GenerateDateTimeParts(var Day: Integer; var Month: Integer; var Year: Integer; var Hour: Integer; var Minute: Integer; var Second: Integer; var Milisecond: Integer)
    begin
        Day := LibraryRandom.RandIntInRange(1, 28);
        Month := LibraryRandom.RandIntInRange(1, 12);
        Year := LibraryRandom.RandIntInRange(2000, 2050);
        Hour := LibraryRandom.RandIntInRange(0, 23);
        Minute := LibraryRandom.RandIntInRange(0, 59);
        Second := LibraryRandom.RandIntInRange(0, 59);
        Milisecond := LibraryRandom.RandIntInRange(0, 999);
    end;

    local procedure GetTranslatedMonth(Date: Date; LanguageId: Integer) Month: Text
    var
        SavedLanguage: Integer;
    begin
        SavedLanguage := GlobalLanguage;
        GlobalLanguage(LanguageId);
        Month := Format(Date, 0, '<Month Text,3>');
        GlobalLanguage(SavedLanguage);
    end;

    local procedure VerifyDateValues(Date: Date; ExpectedDay: Integer; ExpectedMonth: Integer; ExpectedYear: Integer)
    begin
        Assert.AreEqual(ExpectedDay, Date2DMY(Date, 1), '');
        Assert.AreEqual(ExpectedMonth, Date2DMY(Date, 2), '');
        Assert.AreEqual(ExpectedYear, Date2DMY(Date, 3), '');
    end;

    local procedure VerifyDateTimeValues(DateTime: DateTime; ExpectedDay: Integer; ExpectedMonth: Integer; ExpectedYear: Integer; ExpectedHour: Integer; ExpectedMinute: Integer; ExpectedSecond: Integer; ExpectedMilisecond: Integer)
    var
        Date: Date;
        ExpectedTime: Time;
    begin
        Date := DT2Date(DateTime);
        VerifyDateValues(Date, ExpectedDay, ExpectedMonth, ExpectedYear);
        ExpectedTime := CreateTime(ExpectedHour, ExpectedMinute, ExpectedSecond, ExpectedMilisecond);
        Assert.AreEqual(ExpectedTime, DT2Time(DateTime), 'Invalid time');
    end;
}

