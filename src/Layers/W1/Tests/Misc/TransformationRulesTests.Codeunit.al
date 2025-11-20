codeunit 134274 "Transformation Rules Tests"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Transformation Rule]
    end;

    var
        Assert: Codeunit Assert;
        REMOVE_CURR_SYMBOLSTxt: Label 'REMOVE_CURR_SYMBOLS', Comment = 'TransformationRule.Code for removing currency symbol in string';
        LowerAlphaNumericCharsTxt: Label 'abcdefghijklmnopqrstuvwxyz1234567890!"#%&/()=?`^*::_;';
        TitleCaseJohnRobertsTxt: Label 'john roberts';
        EUR_DKKTxt: Label 'EURDKK', Comment = 'A sample example representing a concatenation of two currency codes';
        FindReplaceTxt: Label 'abaabbaaabbbaaaabbbb';
        REPLACEATxt: Label 'REPLACEA', Comment = 'TransformationRule.Code for replacing all a characters to b';
        ROUNDTxt: Label 'ROUND', Comment = 'TransformationRule.Code for rounding';
        LibraryUtility: Codeunit "Library - Utility";
        FindValueErr: Label 'Find Value must have a value in Transformation Rule';

    [Test]
    [Scope('OnPrem')]
    procedure TestUpperCase()
    var
        TransformationRule: Record "Transformation Rule";
        InputText: Text;
    begin
        Iniatialize();

        TransformationRule.Get(TransformationRule.GetUppercaseCode());
        InputText := LowerAlphaNumericCharsTxt;
        Assert.AreEqual(UpperCase(InputText), TransformationRule.TransformText(InputText), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestLowerCase()
    var
        TransformationRule: Record "Transformation Rule";
        InputText: Text;
    begin
        Iniatialize();

        TransformationRule.Get(TransformationRule.GetLowercaseCode());
        InputText := UpperCase(LowerAlphaNumericCharsTxt);
        Assert.AreEqual(LowerCase(InputText), TransformationRule.TransformText(InputText), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTitleCase()
    var
        TransformationRule: Record "Transformation Rule";
        InputText: Text;
        ResultText: Text;
        Index: Integer;
    begin
        Iniatialize();

        TransformationRule.Get(TransformationRule.GetTitlecaseCode());

        InputText := TitleCaseJohnRobertsTxt;
        ResultText := TransformationRule.TransformText(InputText);

        for Index := 1 to StrLen(InputText) do
            if true in [Index = 1, InputText[Index - 1] = ' '] then
                Assert.IsFalse(ResultText[Index] in ['a' .. 'z'], Format(ResultText[Index]))
            else
                Assert.IsFalse(ResultText[Index] in ['A' .. 'Z'], Format(ResultText[Index]))
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTrim()
    var
        TransformationRule: Record "Transformation Rule";
        InputText: Text;
    begin
        Iniatialize();

        TransformationRule.Get(TransformationRule.GetTrimCode());
        InputText := StrSubstNo(' %1 ', LowerAlphaNumericCharsTxt);

        Assert.AreEqual(Format(LowerAlphaNumericCharsTxt), TransformationRule.TransformText(InputText), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSubstring()
    var
        TransformationRule: Record "Transformation Rule";
        InputText: Text;
        ResultText: Text;
        i: Integer;
    begin
        Iniatialize();

        TransformationRule.Get(TransformationRule.GetFourthToSixthSubstringCode());

        InputText := EUR_DKKTxt;
        ResultText := TransformationRule.TransformText(InputText);

        for i := TransformationRule."Start Position" to TransformationRule.Length do
            Assert.AreEqual(InputText[i], ResultText[i - TransformationRule."Start Position"], '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSubstringStartingTextWithEndingTextWithoutQuotes()
    var
        TransformationRule: Record "Transformation Rule";
        InputText: Text;
        ResultText: Text;
    begin
        Iniatialize();

        TransformationRule.Init();
        TransformationRule.Validate("Transformation Type", TransformationRule."Transformation Type"::Substring);
        TransformationRule.Validate("Starting Text", '(');
        TransformationRule.Validate("Ending Text", ')');

        InputText := 'British Pound(GBP)/Algerian Dinar(DZD)';
        ResultText := TransformationRule.TransformText(InputText);

        Assert.AreEqual('GBP', ResultText, 'Substring is not correct');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSubstringStartingTextWithEndingText()
    var
        TransformationRule: Record "Transformation Rule";
        InputText: Text;
        ResultText: Text;
    begin
        Iniatialize();

        TransformationRule.Init();
        TransformationRule.Validate("Transformation Type", TransformationRule."Transformation Type"::Substring);
        TransformationRule.Validate("Starting Text", '1 British Pound = ');
        TransformationRule.Validate("Ending Text", ''' ''');

        InputText := '1 British Pound = 701.37865 Comoros Franc ';
        ResultText := TransformationRule.TransformText(InputText);

        Assert.AreEqual('701.37865', ResultText, 'Substring is not correct');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSubstringStartingTextWithLength()
    var
        TransformationRule: Record "Transformation Rule";
        InputText: Text;
        ResultText: Text;
    begin
        Iniatialize();

        TransformationRule.Init();
        TransformationRule.Validate("Transformation Type", TransformationRule."Transformation Type"::Substring);
        TransformationRule.Validate("Starting Text", '1 British Pound = ');
        TransformationRule.Validate(Length, 6);

        InputText := '1 British Pound = 701.37865 Comoros Franc ';
        ResultText := TransformationRule.TransformText(InputText);

        Assert.AreEqual('701.37', ResultText, 'Substring is not correct');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSubstringStartPositionWithEndingText()
    var
        TransformationRule: Record "Transformation Rule";
        InputText: Text;
        ResultText: Text;
    begin
        Iniatialize();

        TransformationRule.Init();
        TransformationRule.Validate("Transformation Type", TransformationRule."Transformation Type"::Substring);
        TransformationRule.Validate("Start Position", 19);
        TransformationRule.Validate("Ending Text", ''' ''');

        InputText := '1 British Pound = 701.37865 Comoros Franc ';
        ResultText := TransformationRule.TransformText(InputText);

        Assert.AreEqual('701.37865', ResultText, 'Substring is not correct');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSubstringEndingTextNotFound()
    var
        TransformationRule: Record "Transformation Rule";
        InputText: Text;
        ResultText: Text;
    begin
        Iniatialize();

        TransformationRule.Init();
        TransformationRule.Validate("Transformation Type", TransformationRule."Transformation Type"::Substring);
        TransformationRule.Validate("Starting Text", '1 British Pound = ');
        TransformationRule.Validate("Ending Text", 'Non Existing VALUE');

        InputText := '1 British Pound = 701.37865 Comoros Franc ';
        ResultText := TransformationRule.TransformText(InputText);

        Assert.AreEqual('', ResultText, 'Substring is not correct');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSubstringStartPositionMissingIsDefaultedToOne()
    var
        TransformationRule: Record "Transformation Rule";
        InputText: Text;
        ResultText: Text;
    begin
        Iniatialize();

        TransformationRule.Init();
        TransformationRule.Validate("Transformation Type", TransformationRule."Transformation Type"::Substring);
        TransformationRule.Validate("Ending Text", ''' = ''');

        InputText := '1 British Pound = 701.37865 Comoros Franc ';
        ResultText := TransformationRule.TransformText(InputText);

        Assert.AreEqual('1 British Pound', ResultText, 'Substring is not correct');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSubstringStartPositionWithoutEndingSelectsRemainingLength()
    var
        TransformationRule: Record "Transformation Rule";
        InputText: Text;
        ResultText: Text;
    begin
        Iniatialize();

        TransformationRule.Init();
        TransformationRule.Validate("Transformation Type", TransformationRule."Transformation Type"::Substring);
        TransformationRule.Validate("Start Position", 19);

        InputText := '1 British Pound = 701.37865 Comoros Franc ';
        ResultText := TransformationRule.TransformText(InputText);

        Assert.AreEqual('701.37865 Comoros Franc ', ResultText, 'Substring is not correct');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSubstringValidateIsBlankingTheOtherValue()
    var
        TransformationRule: Record "Transformation Rule";
    begin
        Iniatialize();

        TransformationRule.Init();
        TransformationRule.Validate("Transformation Type", TransformationRule."Transformation Type"::Substring);
        TransformationRule.Validate("Start Position", 19);

        TransformationRule.Validate("Starting Text", 'Test');
        Assert.AreEqual(TransformationRule."Start Position", 0, 'Start position should be set to 0');

        TransformationRule.Validate("Start Position", 19);
        Assert.AreEqual(TransformationRule."Starting Text", '', 'Starting Text should be set to blank');

        TransformationRule.Validate(Length, 10);
        TransformationRule.Validate("Ending Text", 'Test');
        Assert.AreEqual(TransformationRule.Length, 0, 'Lenght should be set to 0');

        TransformationRule.Validate(Length, 10);
        Assert.AreEqual(TransformationRule."Ending Text", '', 'Ending text should be set to blank');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSubstringStartTextIsNotMatched()
    var
        TransformationRule: Record "Transformation Rule";
        InputText: Text;
        ResultText: Text;
    begin
        Iniatialize();

        TransformationRule.Init();
        TransformationRule.Validate("Transformation Type", TransformationRule."Transformation Type"::Substring);
        TransformationRule.Validate("Starting Text", 'dfadsfad');
        TransformationRule.Validate("Ending Text", ''' ''');

        InputText := '1 British Pound = 701.37865 Comoros Franc ';
        ResultText := TransformationRule.TransformText(InputText);

        Assert.AreEqual('', ResultText, 'Substring is not correct');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSubstringEndTextIsNotMatched()
    var
        TransformationRule: Record "Transformation Rule";
        InputText: Text;
        ResultText: Text;
    begin
        Iniatialize();

        TransformationRule.Init();
        TransformationRule.Validate("Transformation Type", TransformationRule."Transformation Type"::Substring);
        TransformationRule.Validate("Starting Text", '1 British Pound = ');
        TransformationRule.Validate("Ending Text", '''dfadfa''');

        InputText := '1 British Pound = 701.37865 Comoros Franc ';
        ResultText := TransformationRule.TransformText(InputText);

        Assert.AreEqual('', ResultText, 'Substring is not correct');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSubstringStartingTextFirstCharacterOfString()
    var
        TransformationRule: Record "Transformation Rule";
        InputText: Text;
        ResultText: Text;
    begin
        Iniatialize();

        TransformationRule.Init();
        TransformationRule.Validate("Transformation Type", TransformationRule."Transformation Type"::Substring);
        TransformationRule.Validate("Starting Text", '(');
        TransformationRule.Validate("Ending Text", ')');

        InputText := '(GBP)/(DZD)';
        ResultText := TransformationRule.TransformText(InputText);

        Assert.AreEqual('GBP', ResultText, 'Substring is not correct');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSubstringEndingTextLastCharacterOfString()
    var
        TransformationRule: Record "Transformation Rule";
        InputText: Text;
        ResultText: Text;
    begin
        Iniatialize();

        TransformationRule.Init();
        TransformationRule.Validate("Transformation Type", TransformationRule."Transformation Type"::Substring);
        TransformationRule.Validate("Starting Text", '(');
        TransformationRule.Validate("Ending Text", ')');

        InputText := 'Algerian Dinar(DZD)';
        ResultText := TransformationRule.TransformText(InputText);

        Assert.AreEqual('DZD', ResultText, 'Substring is not correct');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestReplace()
    var
        TransformationRule: Record "Transformation Rule";
        InputText: Text;
        ResultText: Text;
        i: Integer;
        j: Integer;
        k: Integer;
        m: Integer;
    begin
        Iniatialize();

        TransformationRule.Init();
        TransformationRule.Validate(Code, REPLACEATxt);
        TransformationRule.Validate("Transformation Type", TransformationRule."Transformation Type"::Replace);
        TransformationRule.Validate("Find Value", 'a');
        TransformationRule.Validate("Replace Value", 'b');
        TransformationRule.Insert();

        InputText := FindReplaceTxt;
        ResultText := TransformationRule.TransformText(InputText);

        j := 1;
        for i := 1 to StrLen(ResultText) do
            if ResultText[i] <> InputText[j] then begin
                for k := 1 to StrLen(TransformationRule."Find Value") do begin
                    Assert.AreEqual(Format(TransformationRule."Find Value"[k]), Format(InputText[j]), '');
                    j += 1;
                end;

                for m := 1 to StrLen(TransformationRule."Replace Value") do begin
                    Assert.AreEqual(Format(TransformationRule."Replace Value"[m]), Format(ResultText[i]), '');
                    i += 1;
                end
            end else
                j += 1;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRegularExpressionReplace()
    var
        TransformationRule: Record "Transformation Rule";
        InputText: Text;
        ResultText: Text;
    begin
        Iniatialize();

        TransformationRule.Init();
        TransformationRule.Validate(Code, REMOVE_CURR_SYMBOLSTxt);
        TransformationRule.Validate("Transformation Type", TransformationRule."Transformation Type"::"Regular Expression - Replace");
        TransformationRule.Validate("Find Value", '(\p{Sc}\s?)?(\d+\.?((?<=\.)\d+)?)(?(1)|\s?\p{Sc})?');
        TransformationRule.Validate("Replace Value", '$2');
        TransformationRule.Insert();

        InputText := '$17.43  $2 16.33  0.98  0.43   43   12$  12$';
        ResultText := TransformationRule.TransformText(InputText);

        Assert.AreEqual('17.43  2 16.33  0.98  0.43   43   12  12', ResultText, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestChainedRules()
    var
        TransformationRule: Record "Transformation Rule";
        TransformationRule2: Record "Transformation Rule";
        InputText: Text;
        ResultText: Text;
        Rule2Name: Code[20];
    begin
        Iniatialize();

        Rule2Name := 'Rule 2';
        TransformationRule2.Init();
        TransformationRule2.Validate(Code, Rule2Name);
        TransformationRule2.Validate("Transformation Type", TransformationRule."Transformation Type"::Replace);
        TransformationRule2.Validate("Find Value", 'abc');
        TransformationRule2.Insert(true);

        TransformationRule.Init();
        TransformationRule.Validate(Code, 'Rule 1');
        TransformationRule.Validate(
          "Transformation Type", TransformationRule."Transformation Type"::"Remove Non-Alphanumeric Characters");
        TransformationRule.Validate("Next Transformation Rule", Rule2Name);
        TransformationRule.Insert(true);

        InputText := 'abc - 123 - def';
        ResultText := TransformationRule.TransformText(InputText);

        Assert.AreEqual('123def', ResultText, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestChainedRulesAssistEdit()
    var
        TransformationRule: Record "Transformation Rule";
        TransformationRule2: Record "Transformation Rule";
        TransformationRuleCardSecondRule: TestPage "Transformation Rule Card";
        TransformationRuleCard: TestPage "Transformation Rule Card";
        Rule2Name: Code[20];
    begin
        Iniatialize();

        Rule2Name := 'Second Rule';
        TransformationRule2.Init();
        TransformationRule2.Validate(Code, Rule2Name);
        TransformationRule2.Validate("Transformation Type", TransformationRule."Transformation Type"::Uppercase);
        TransformationRule2.Insert(true);

        TransformationRule.Init();
        TransformationRule.Validate(Code, 'First Rule');
        TransformationRule.Validate(
          "Transformation Type", TransformationRule."Transformation Type"::"Remove Non-Alphanumeric Characters");
        TransformationRule.Validate("Next Transformation Rule", Rule2Name);
        TransformationRule.Insert(true);

        TransformationRuleCard.OpenEdit();
        TransformationRuleCard.GotoRecord(TransformationRule);

        TransformationRuleCardSecondRule.Trap();
        TransformationRuleCard."Next Transformation Rule".AssistEdit();

        Assert.AreEqual(Rule2Name, TransformationRuleCardSecondRule.Code.Value, 'Wrong record was opened');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRegularExpressionMatchSingleCapture()
    var
        TransformationRule: Record "Transformation Rule";
        InputText: Text;
        ResultText: Text;
    begin
        Iniatialize();

        TransformationRule.Init();
        TransformationRule.Validate("Transformation Type", TransformationRule."Transformation Type"::"Regular Expression - Match");
        TransformationRule.Validate("Find Value", 'abc(\d+)d');

        InputText := 'abc123def';
        ResultText := TransformationRule.TransformText(InputText);

        Assert.AreEqual('123', ResultText, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRegularExpressionMatchMultipleCaptures()
    var
        TransformationRule: Record "Transformation Rule";
        InputText: Text;
        ResultText: Text;
    begin
        Iniatialize();

        TransformationRule.Init();
        TransformationRule.Validate("Transformation Type", TransformationRule."Transformation Type"::"Regular Expression - Match");
        TransformationRule.Validate("Find Value", '\D+(?<digit>\d+)\D+(?<digit>\d+)?');

        InputText := 'abc123def456';
        ResultText := TransformationRule.TransformText(InputText);

        Assert.AreEqual('123456', ResultText, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRegularExpressionMatchNoMatches()
    var
        TransformationRule: Record "Transformation Rule";
        InputText: Text;
        ResultText: Text;
    begin
        Iniatialize();

        TransformationRule.Init();
        TransformationRule.Validate("Transformation Type", TransformationRule."Transformation Type"::"Regular Expression - Match");
        TransformationRule.Validate("Find Value", '\D+(?<digit>\d+)\D+(?<digit>\d+)?');

        InputText := 'abcdef';
        ResultText := TransformationRule.TransformText(InputText);

        Assert.AreEqual('', ResultText, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRemoveNonAlphaNumbericCharacters()
    var
        TransformationRule: Record "Transformation Rule";
        InputText: Text;
        ResultText: Text;
        Index: Integer;
    begin
        Iniatialize();

        TransformationRule.Get(TransformationRule.GetAlphanumericCode());
        InputText := LowerAlphaNumericCharsTxt;
        ResultText := TransformationRule.TransformText(InputText);

        for Index := 1 to StrLen(ResultText) do
            Assert.IsTrue(InputText[Index] in ['a' .. 'z', '0' .. '9'], '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUSDateFormating()
    var
        TransformationRule: Record "Transformation Rule";
        TestDate: Date;
        InputText: Text;
        ResultText: Text;
    begin
        Iniatialize();

        TransformationRule.Get(TransformationRule.GetUSDateFormatCode());

        TestDate := Today;

        InputText := Format(TestDate, 0, '<Year4>/<Month,2>/<Day,2>');
        ResultText := TransformationRule.TransformText(InputText);

        Assert.AreEqual(Format(TestDate, 0, XmlFormat()), ResultText, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUSDateTimeFormating()
    var
        TransformationRule: Record "Transformation Rule";
        TestDate: Date;
        InputText: Text;
        ResultText: Text;
    begin
        Iniatialize();

        TransformationRule.Get(TransformationRule.GetUSDateTimeFormatCode());

        TestDate := Today;

        InputText := StrSubstNo('%1 1:14:15 PM', Format(TestDate, 0, '<Month,2>/<Day,2>/<Year4>'));
        ResultText := TransformationRule.TransformText(InputText);

        Assert.AreEqual(StrSubstNo('%1T13:14:15Z', Format(TestDate, 0, XmlFormat())), ResultText, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestYYYYMMDDDateFormating()
    var
        TransformationRule: Record "Transformation Rule";
        TestDate: Date;
        InputText: Text;
        ResultText: Text;
    begin
        Iniatialize();

        TransformationRule.Get(TransformationRule.GetYYYYMMDDCode());

        TestDate := DMY2Date(13, 12, 2015);

        InputText := Format(TestDate, 0, '<Year4><Month,2><Day,2>');
        ResultText := TransformationRule.TransformText(InputText);

        Assert.AreEqual(Format(TestDate, 0, XmlFormat()), ResultText, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestYYYYMMDDHHMMSSDateTimeFormating()
    var
        TransformationRule: Record "Transformation Rule";
        TestDateTime: DateTime;
        InputText: Text;
        ResultText: Text;
    begin
        Iniatialize();

        TransformationRule.Get(TransformationRule.GetYYYYMMDDHHMMSSCode());

        TestDateTime := CreateDateTime(DMY2Date(13, 12, 2015), 030405T);

        InputText := Format(TestDateTime, 0, '<Year4><Month,2><Day,2><Hours24,2><Minutes,2><Seconds,2>');
        ResultText := TransformationRule.TransformText(InputText);

        Assert.AreEqual('2015-12-13T03:04:05Z', ResultText, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRound()
    var
        TransformationRule: Record "Transformation Rule";
        InputText: Text;
    begin
        Iniatialize();
        TransformationRule.InsertRec(ROUNDTxt, ROUNDTxt, TransformationRule."Transformation Type"::Round, 0, 0, '', '');
        TransformationRule.Get(ROUNDTxt);
        TransformationRule.Precision := 0.00001;
        TransformationRule.Direction := '=';

        InputText := '12.3456789';
        Assert.AreEqual('12.34568', TransformationRule.TransformText(InputText), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DateFormattingStaysWithTheDateInputEast()
    var
        TransformationRule: Record "Transformation Rule";
        InputDateTime: DateTime;
        InputDate: Date;
        InputText: Text;
        ResultText: Text;
    begin
        // [SCENARIO 290388] Date Formatting does not change input date. This test addresses time zones to the east of UTC.
        Iniatialize();

        // [GIVEN] Transformation rule of "Date Formatting" type.
        TransformationRule.Init();
        TransformationRule.Validate("Transformation Type", TransformationRule."Transformation Type"::"Date Formatting");
        TransformationRule.Validate("Data Format", 'yyyyMMddHHmm');

        // [GIVEN] Date-time to be tested = 20/01/2020 23:59:59.
        InputDate := DMY2Date(20, 1, 2020);
        InputDateTime := CreateDateTime(InputDate, 235959T);
        InputText := Format(InputDateTime, 0, '<Year4><Month,2><Day,2><Hours24,2><Minutes,2>');

        // [WHEN] Transform the date-time to a date string.
        ResultText := TransformationRule.TransformText(InputText);

        // [THEN] The resulting string is 2020-01-20, which is equal to the input date in XML format.
        Assert.AreEqual(Format(InputDate, 0, XmlFormat()), ResultText, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DateFormattingStaysWithTheDateInputWest()
    var
        TransformationRule: Record "Transformation Rule";
        InputDateTime: DateTime;
        InputDate: Date;
        InputText: Text;
        ResultText: Text;
    begin
        // [SCENARIO 290388] Date Formatting does not change input date. This test addresses time zones to the west of UTC.
        Iniatialize();

        // [GIVEN] Transformation rule of "Date Formatting" type.
        TransformationRule.Init();
        TransformationRule.Validate("Transformation Type", TransformationRule."Transformation Type"::"Date Formatting");
        TransformationRule.Validate("Data Format", 'yyyyMMddHHmm');

        // [GIVEN] Date-time to be tested = 20/01/2020 00:00:01.
        InputDate := DMY2Date(20, 1, 2020);
        InputDateTime := CreateDateTime(InputDate, 000001T);
        InputText := Format(InputDateTime, 0, '<Year4><Month,2><Day,2><Hours24,2><Minutes,2>');

        // [WHEN] Transform the date-time to a date string.
        ResultText := TransformationRule.TransformText(InputText);

        // [THEN] The resulting string is 2020-01-20, which is equal to the input date in XML format.
        Assert.AreEqual(Format(InputDate, 0, XmlFormat()), ResultText, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DateTimeFormattingStaysWithTheDateInput()
    var
        TransformationRule: Record "Transformation Rule";
        InputDateTime: DateTime;
        InputDate: Date;
        InputText: Text;
        ResultText: Text;
    begin
        // [SCENARIO 290388] Date and Time Formatting does not change input date.
        Iniatialize();

        // [GIVEN] Transformation rule of "Date and Time Formatting" type.
        TransformationRule.Init();
        TransformationRule.Validate("Transformation Type", TransformationRule."Transformation Type"::"Date and Time Formatting");
        TransformationRule.Validate("Data Format", 'yyyyMMddHHmmss');

        // [GIVEN] Date-time to be tested = 20/01/2020 23:59:59.
        InputDate := DMY2Date(20, 1, 2020);
        InputDateTime := CreateDateTime(InputDate, 235959T);
        InputText := Format(InputDateTime, 0, '<Year4><Month,2><Day,2><Hours24,2><Minutes,2><Seconds,2>');

        // [WHEN] Transform the date-time to a date-time string.
        ResultText := TransformationRule.TransformText(InputText);

        // [THEN] The resulting string is 2020-01-20T23:59:59Z, which is equal to the input date in XML format.
        Assert.AreEqual('2020-01-20T23:59:59Z', ResultText, '');
    end;

    [Test]
    procedure DateFormattingWrongInput()
    var
        TransformationRule: Record "Transformation Rule";
        InputText: Text;
    begin
        // [SCENARIO 399408] Date Formatting returns the input string in case of a wrong input
        Iniatialize();

        TransformationRule.Init();
        TransformationRule.Validate("Transformation Type", TransformationRule."Transformation Type"::"Date Formatting");
        TransformationRule.Validate("Data Format", 'yyyyMMddHHmmss');

        InputText := 'wrong date time';
        Assert.AreEqual(InputText, TransformationRule.TransformText(InputText), '');
    end;

    [Test]
    procedure DateTimeFormattingWrongInput()
    var
        TransformationRule: Record "Transformation Rule";
        InputText: Text;
    begin
        // [SCENARIO 399408] Date and Time Formatting returns the input string in case of a wrong input
        Iniatialize();

        TransformationRule.Init();
        TransformationRule.Validate("Transformation Type", TransformationRule."Transformation Type"::"Date and Time Formatting");
        TransformationRule.Validate("Data Format", 'yyyyMMddHHmmss');

        InputText := 'wrong date time';
        Assert.AreEqual(InputText, TransformationRule.TransformText(InputText), '');
    end;

#if not CLEAN25
    [Test]
    [Scope('OnPrem')]
    procedure TestUnixtimestamp()
    var
        TransformationRule: Record "Transformation Rule";
        UnixtimestampTransformation: Codeunit "Unixtimestamp Transformation";
        TypeHelper: Codeunit "Type Helper";
        Timestamp: BigInteger;
        Testdate: DateTime;
        InputText: Text;
        ResultText: Text;
    begin
        Iniatialize();

        TransformationRule.Get(UnixtimestampTransformation.GetUnixTimestampCode());

        Timestamp := 1481544732;
        Testdate := TypeHelper.EvaluateUnixTimestamp(Timestamp);

        InputText := Format(Timestamp);
        ResultText := TransformationRule.TransformText(InputText);

        Assert.AreEqual(Format(Testdate, 0, XmlFormat()), ResultText, '');
    end;
#endif

    [Test]
    [Scope('OnPrem')]
    procedure CheckMandatoryTypeReplaceInsert()
    var
        TransformationRule: Record "Transformation Rule";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 228885] System requires to fill "Find Value" of "Transformation Rule" when type = "Replace" due inserting
        Iniatialize();

        // [GIVEN] New record of "Transformation Rule" with Type = "Replace"
        InitTransformationRule(TransformationRule, TransformationRule."Transformation Type"::Replace);

        // [WHEN] Inserting record
        asserterror TransformationRule.Insert(true);

        // [THEN] Error appears
        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError(FindValueErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckMandatoryTypeReplaceModify()
    var
        TransformationRule: Record "Transformation Rule";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 228885] System requires to fill "Find Value" of "Transformation Rule" when type = "Replace" due modifying
        Iniatialize();

        // [GIVEN] New record of "Transformation Rule" with Type = "Replace"
        InitTransformationRule(TransformationRule, TransformationRule."Transformation Type"::Replace);
        TransformationRule.Insert();

        // [WHEN] Inserting record
        asserterror TransformationRule.Modify(true);

        // [THEN] Error appears
        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError(FindValueErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckMandatoryTypeRegularExpressionReplaceInsert()
    var
        TransformationRule: Record "Transformation Rule";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 228885] System requires to fill "Find Value" of "Transformation Rule" when type = "Regular Expression - Replace" due inserting
        Iniatialize();

        // [GIVEN] New record of "Transformation Rule" with Type = "Regular Expression - Replace"
        InitTransformationRule(TransformationRule, TransformationRule."Transformation Type"::"Regular Expression - Replace");

        // [WHEN] Inserting record
        asserterror TransformationRule.Insert(true);

        // [THEN] Error appears
        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError(FindValueErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckMandatoryTypeRegularExpressionReplaceModify()
    var
        TransformationRule: Record "Transformation Rule";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 228885] System requires to fill "Find Value" of "Transformation Rule" when type = "Regular Expression - Replace" due modifying
        Iniatialize();

        // [GIVEN] New record of "Transformation Rule" with Type = "Regular Expression - Replace"
        InitTransformationRule(TransformationRule, TransformationRule."Transformation Type"::"Regular Expression - Replace");
        TransformationRule.Insert();

        // [WHEN] Inserting record
        asserterror TransformationRule.Modify(true);

        // [THEN] Error appears
        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError(FindValueErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckMandatoryTypeRegularExpressionMatchInsert()
    var
        TransformationRule: Record "Transformation Rule";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 228885] System requires to fill "Find Value" of "Transformation Rule" when type = "Regular Expression - Match" due inserting
        Iniatialize();

        // [GIVEN] New record of "Transformation Rule" with Type = "Regular Expression - Match"
        InitTransformationRule(TransformationRule, TransformationRule."Transformation Type"::"Regular Expression - Match");

        // [WHEN] Inserting record
        asserterror TransformationRule.Insert(true);

        // [THEN] Error appears
        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError(FindValueErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckMandatoryTypeRegularExpressionMatchModify()
    var
        TransformationRule: Record "Transformation Rule";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 228885] System requires to fill "Find Value" of "Transformation Rule" when type = "Regular Expression - Match" due modifying
        Iniatialize();

        // [GIVEN] New record of "Transformation Rule" with Type = "Regular Expression - Match"
        InitTransformationRule(TransformationRule, TransformationRule."Transformation Type"::"Regular Expression - Match");
        TransformationRule.Insert();

        // [WHEN] Inserting record
        asserterror TransformationRule.Modify(true);

        // [THEN] Error appears
        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError(FindValueErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DataFormatForCustomTransformationType()
    var
        TransformationRule: Record "Transformation Rule";
        TransformationRulesTests: Codeunit "Transformation Rules Tests";
        DataFormat: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 302372] User is able to specify Data Format for Custom transformation type 
        Iniatialize();

        BindSubscription(TransformationRulesTests);
        // [GIVEN] New record of "Transformation Rule" with Type = Custom
        InitTransformationRule(TransformationRule, TransformationRule."Transformation Type"::Custom);
        TransformationRule.Insert();

        // [WHEN] Data Format "XXX" is being specified
        DataFormat := LibraryUtility.GenerateRandomText(MaxStrLen(TransformationRule."Data Format"));
        TransformationRule.Validate(
            "Data Format",
            CopyStr(DataFormat, 1, MaxStrLen(TransformationRule."Data Format")));

        // [THEN] Data Format value changed to "XXX"
        Assert.AreEqual(DataFormat, TransformationRule."Data Format", 'Data Format must be specified.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DataFormatVisibleForCustomTransformationType()
    var
        TransformationRule: Record "Transformation Rule";
        TransformationRulesTests: Codeunit "Transformation Rules Tests";
        TransformationRuleCard: TestPage "Transformation Rule Card";
        DataFormat: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 302372] User is able to edit Data Format field on the Transformation Rule Card page for Custom transformation type 
        Iniatialize();

        BindSubscription(TransformationRulesTests);
        // [GIVEN] New record of "Transformation Rule" with Type = Custom
        InitTransformationRule(TransformationRule, TransformationRule."Transformation Type"::Custom);
        TransformationRule.Insert();

        // [WHEN] Data Format "XXX" is being specified on Transformation Rule Card page
        DataFormat := LibraryUtility.GenerateRandomText(MaxStrLen(TransformationRule."Data Format"));
        TransformationRuleCard.OpenEdit();
        TransformationRuleCard.Filter.SetFilter(Code, TransformationRule.Code);
        TransformationRuleCard."Data Format".SetValue(DataFormat);
        TransformationRuleCard.OK().Invoke();

        // [THEN] Data Format value changed to "XXX"
        TransformationRule.Find();
        Assert.AreEqual(DataFormat, TransformationRule."Data Format", 'Data Format must be specified.');
    end;

    local procedure Iniatialize()
    var
        TransformationRule: Record "Transformation Rule";
    begin
        TransformationRule.DeleteAll();
        TransformationRule.CreateDefaultTransformations();
    end;

    local procedure XmlFormat(): Integer
    begin
        exit(9);
    end;

    local procedure InitTransformationRule(var TransformationRule: Record "Transformation Rule"; TransformationType: Enum "Transformation Rule Type")
    begin
        TransformationRule.Init();
        TransformationRule.Code := LibraryUtility.GenerateRandomCode(TransformationRule.FieldNo(Code), DATABASE::"Transformation Rule");
        TransformationRule."Transformation Type" := TransformationType;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transformation Rule", 'OnBeforeIsDataFormatUpdateAllowed', '', false, false)]
    local procedure OnBeforeIsDataFormatUpdateAllowed(FieldNumber: Integer; var DataFormatUpdateAllowed: boolean; var isHandled: boolean)
    begin
        DataFormatUpdateAllowed := true;
        isHandled := true;
    end;
}