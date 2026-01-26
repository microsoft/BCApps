codeunit 144053 "VAT 2010 - UT"
{
    // // [FEATURE] [VAT 2010] [UT]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        NegativeMsg: Label 'Error';
        PositiveMsg: Label 'OK';
        VATLogicalTests: Codeunit VATLogicalTests;

    [Test]
    [Scope('OnPrem')]
    procedure VATLogicalTests_CodeA_Positive()
    var
        Row: array[99, 12] of Decimal;
        Control: array[14] of Text[250];
        CheckList: array[14, 12] of Text[30];
    begin
        Row[1, 1] := LibraryRandom.RandDec(1000, 2);
        Row[2, 1] := LibraryRandom.RandDec(1000, 2);
        Row[3, 1] := LibraryRandom.RandDec(1000, 2);
        Row[54, 1] := LibraryRandom.RandDec(1000, 2);

        VATLogicalTests.CheckForErrors(1, Row, 0, 0, Control, CheckList);
        Assert.ExpectedMessage(PositiveMsg, CheckList[1, 1]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATLogicalTests_CodeA_Negative()
    var
        Row: array[99, 12] of Decimal;
        Control: array[14] of Text[250];
        CheckList: array[14, 12] of Text[30];
    begin
        Row[1, 1] := LibraryRandom.RandDec(1000, 2);
        Row[2, 1] := LibraryRandom.RandDec(1000, 2);
        Row[3, 1] := LibraryRandom.RandDec(1000, 2);
        Row[54, 1] := 0;

        VATLogicalTests.CheckForErrors(1, Row, 0, 0, Control, CheckList);
        Assert.ExpectedMessage(NegativeMsg, CheckList[1, 1]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATLogicalTests_CodeB_Positive()
    var
        Row: array[99, 12] of Decimal;
        Control: array[14] of Text[250];
        CheckList: array[14, 12] of Text[30];
    begin
        Row[1, 1] := 0;
        Row[2, 1] := 0;
        Row[3, 1] := 0;
        Row[54, 1] := 0;

        VATLogicalTests.CheckForErrors(1, Row, 0, 0, Control, CheckList);
        Assert.ExpectedMessage(PositiveMsg, CheckList[2, 1]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATLogicalTests_CodeB_Negative()
    var
        Row: array[99, 12] of Decimal;
        Control: array[14] of Text[250];
        CheckList: array[14, 12] of Text[30];
    begin
        Row[1, 1] := 0;
        Row[2, 1] := 0;
        Row[3, 1] := 0;
        Row[54, 1] := LibraryRandom.RandDec(1000, 2);

        VATLogicalTests.CheckForErrors(1, Row, 0, 0, Control, CheckList);
        Assert.ExpectedMessage(NegativeMsg, CheckList[2, 1]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATLogicalTests_CodeC_Positive()
    var
        Row: array[99, 12] of Decimal;
        Control: array[14] of Text[250];
        CheckList: array[14, 12] of Text[30];
    begin
        Row[86, 1] := LibraryRandom.RandDec(1000, 2);
        Row[88, 1] := LibraryRandom.RandDec(1000, 2);
        Row[55, 1] := LibraryRandom.RandDec(1000, 2);

        VATLogicalTests.CheckForErrors(1, Row, 0, 0, Control, CheckList);
        Assert.ExpectedMessage(PositiveMsg, CheckList[3, 1]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATLogicalTests_CodeC_Negative()
    var
        Row: array[99, 12] of Decimal;
        Control: array[14] of Text[250];
        CheckList: array[14, 12] of Text[30];
    begin
        Row[86, 1] := LibraryRandom.RandDec(1000, 2);
        Row[88, 1] := LibraryRandom.RandDec(1000, 2);
        Row[55, 1] := 0;

        VATLogicalTests.CheckForErrors(1, Row, 0, 0, Control, CheckList);
        Assert.ExpectedMessage(NegativeMsg, CheckList[3, 1]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATLogicalTests_CodeD_Positive()
    var
        Row: array[99, 12] of Decimal;
        Control: array[14] of Text[250];
        CheckList: array[14, 12] of Text[30];
    begin
        Row[56, 1] := LibraryRandom.RandDec(1000, 2);
        Row[57, 1] := LibraryRandom.RandDec(1000, 2);
        Row[87, 1] := LibraryRandom.RandDec(1000, 2);

        VATLogicalTests.CheckForErrors(1, Row, 0, 0, Control, CheckList);
        Assert.ExpectedMessage(PositiveMsg, CheckList[4, 1]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATLogicalTests_CodeD_Negative()
    var
        Row: array[99, 12] of Decimal;
        Control: array[14] of Text[250];
        CheckList: array[14, 12] of Text[30];
    begin
        Row[56, 1] := 0;
        Row[57, 1] := 0;
        Row[87, 1] := LibraryRandom.RandDec(1000, 2);

        VATLogicalTests.CheckForErrors(1, Row, 0, 0, Control, CheckList);
        Assert.ExpectedMessage(NegativeMsg, CheckList[4, 1]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATLogicalTests_Test5_Positive()
    var
        Row: array[99, 12] of Decimal;
        Control: array[14] of Text[250];
        CheckList: array[14, 12] of Text[30];
    begin
        Row[65, 1] := 0;
        Row[66, 1] := 0;

        VATLogicalTests.CheckForErrors(1, Row, 0, 0, Control, CheckList);
        Assert.ExpectedMessage(PositiveMsg, CheckList[5, 1]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATLogicalTests_Test5_Negative()
    var
        Row: array[99, 12] of Decimal;
        Control: array[14] of Text[250];
        CheckList: array[14, 12] of Text[30];
    begin
        Row[65, 1] := LibraryRandom.RandDec(1000, 2);
        Row[66, 1] := LibraryRandom.RandDec(1000, 2);

        VATLogicalTests.CheckForErrors(1, Row, 0, 0, Control, CheckList);
        Assert.ExpectedMessage(NegativeMsg, CheckList[5, 1]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATLogicalTests_Code5_Positive()
    var
        Row: array[99, 12] of Decimal;
        Control: array[14] of Text[250];
        CheckList: array[14, 12] of Text[30];
    begin
        Row[91, 1] := 0;

        VATLogicalTests.CheckForErrors(1, Row, 0, 12, Control, CheckList);
        Assert.ExpectedMessage(PositiveMsg, CheckList[6, 1]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATLogicalTests_Code5_Negative()
    var
        Row: array[99, 12] of Decimal;
        Control: array[14] of Text[250];
        CheckList: array[14, 12] of Text[30];
    begin
        Row[91, 1] := LibraryRandom.RandDec(1000, 2);

        VATLogicalTests.CheckForErrors(1, Row, 0, 0, Control, CheckList);
        Assert.ExpectedMessage(NegativeMsg, CheckList[6, 1]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATLogicalTests_CodeO_Positive()
    var
        ErrorMargin: Decimal;
        Row: array[99, 12] of Decimal;
        Control: array[14] of Text[250];
        CheckList: array[14, 12] of Text[30];
    begin
        ErrorMargin := LibraryRandom.RandDec(100, 2);
        Row[1, 1] := LibraryRandom.RandDecInDecimalRange(10000, 20000, 2);
        Row[2, 1] := LibraryRandom.RandDecInDecimalRange(10000, 20000, 2);
        Row[3, 1] := LibraryRandom.RandDecInDecimalRange(10000, 20000, 2);
        Row[54, 1] := (Row[1, 1] * 0.06 + Row[2, 1] * 0.12 + Row[3, 1] * 0.21) - ErrorMargin;

        VATLogicalTests.CheckForErrors(1, Row, ErrorMargin, 0, Control, CheckList);
        Assert.ExpectedMessage(PositiveMsg, CheckList[7, 1]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATLogicalTests_CodeO_Negative()
    var
        ErrorMargin: Decimal;
        Row: array[99, 12] of Decimal;
        Control: array[14] of Text[250];
        CheckList: array[14, 12] of Text[30];
    begin
        ErrorMargin := LibraryRandom.RandDec(100, 2);
        Row[1, 1] := LibraryRandom.RandDecInDecimalRange(10000, 20000, 2);
        Row[2, 1] := LibraryRandom.RandDecInDecimalRange(10000, 20000, 2);
        Row[3, 1] := LibraryRandom.RandDecInDecimalRange(10000, 20000, 2);
        Row[54, 1] := (Row[1, 1] * 0.06 + Row[2, 1] * 0.12 + Row[3, 1] * 0.21) - ErrorMargin - 0.01;

        VATLogicalTests.CheckForErrors(1, Row, ErrorMargin, 0, Control, CheckList);
        Assert.ExpectedMessage(NegativeMsg, CheckList[7, 1]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATLogicalTests_CodeP_Positive()
    var
        ErrorMargin: Decimal;
        Row: array[99, 12] of Decimal;
        Control: array[14] of Text[250];
        CheckList: array[14, 12] of Text[30];
    begin
        ErrorMargin := LibraryRandom.RandDec(1000, 2);
        Row[84, 1] := LibraryRandom.RandDec(1000, 2);
        Row[86, 1] := LibraryRandom.RandDec(1000, 2);
        Row[88, 1] := LibraryRandom.RandDec(1000, 2);
        Row[55, 1] := (Row[84, 1] + Row[86, 1] + Row[88, 1]) * 0.21 + ErrorMargin;

        VATLogicalTests.CheckForErrors(1, Row, ErrorMargin, 0, Control, CheckList);
        Assert.ExpectedMessage(PositiveMsg, CheckList[8, 1]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATLogicalTests_CodeP_Negative()
    var
        ErrorMargin: Decimal;
        Row: array[99, 12] of Decimal;
        Control: array[14] of Text[250];
        CheckList: array[14, 12] of Text[30];
    begin
        ErrorMargin := LibraryRandom.RandDec(1000, 2);
        Row[84, 1] := LibraryRandom.RandDec(1000, 2);
        Row[86, 1] := LibraryRandom.RandDec(1000, 2);
        Row[88, 1] := LibraryRandom.RandDec(1000, 2);
        Row[55, 1] := (Row[84, 1] + Row[86, 1] + Row[88, 1]) * 0.21 + ErrorMargin + 0.01;

        VATLogicalTests.CheckForErrors(1, Row, ErrorMargin, 0, Control, CheckList);
        Assert.ExpectedMessage(NegativeMsg, CheckList[8, 1]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATLogicalTests_CodeQ_Positive()
    var
        ErrorMargin: Decimal;
        Row: array[99, 12] of Decimal;
        Control: array[14] of Text[250];
        CheckList: array[14, 12] of Text[30];
    begin
        ErrorMargin := LibraryRandom.RandDec(100, 2);
        Row[85, 1] := LibraryRandom.RandDecInDecimalRange(10000, 20000, 2);
        Row[87, 1] := LibraryRandom.RandDecInDecimalRange(10000, 20000, 2);
        Row[56, 1] := LibraryRandom.RandDec(100, 2);
        Row[57, 1] := (Row[85, 1] + Row[87, 1]) * 0.21 + ErrorMargin - Row[56, 1];

        VATLogicalTests.CheckForErrors(1, Row, ErrorMargin, 0, Control, CheckList);
        Assert.ExpectedMessage(PositiveMsg, CheckList[9, 1]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATLogicalTests_CodeQ_Negative()
    var
        ErrorMargin: Decimal;
        Row: array[99, 12] of Decimal;
        Control: array[14] of Text[250];
        CheckList: array[14, 12] of Text[30];
    begin
        ErrorMargin := LibraryRandom.RandDec(100, 2);
        Row[85, 1] := LibraryRandom.RandDecInDecimalRange(10000, 20000, 2);
        Row[87, 1] := LibraryRandom.RandDecInDecimalRange(10000, 20000, 2);
        Row[56, 1] := LibraryRandom.RandDec(100, 2);
        Row[57, 1] := (Row[85, 1] + Row[87, 1]) * 0.21 + ErrorMargin - Row[56, 1] + 0.01;

        VATLogicalTests.CheckForErrors(1, Row, ErrorMargin, 0, Control, CheckList);
        Assert.ExpectedMessage(NegativeMsg, CheckList[9, 1]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATLogicalTests_CodeS_Positive()
    var
        Row: array[99, 12] of Decimal;
        Control: array[14] of Text[250];
        CheckList: array[14, 12] of Text[30];
    begin
        Row[81, 1] := LibraryRandom.RandDec(1000, 2);
        Row[82, 1] := LibraryRandom.RandDec(1000, 2);
        Row[83, 1] := LibraryRandom.RandDec(1000, 2);
        Row[84, 1] := LibraryRandom.RandDec(1000, 2);
        Row[85, 1] := LibraryRandom.RandDec(1000, 2);
        Row[59, 1] := (Row[81, 1] + Row[82, 1] + Row[83, 1] + Row[84, 1] + Row[85, 1]) * 0.5;

        VATLogicalTests.CheckForErrors(1, Row, 0, 0, Control, CheckList);
        Assert.ExpectedMessage(PositiveMsg, CheckList[10, 1]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATLogicalTests_CodeS_Negative()
    var
        Row: array[99, 12] of Decimal;
        Control: array[14] of Text[250];
        CheckList: array[14, 12] of Text[30];
    begin
        Row[81, 1] := LibraryRandom.RandDec(1000, 2);
        Row[82, 1] := LibraryRandom.RandDec(1000, 2);
        Row[83, 1] := LibraryRandom.RandDec(1000, 2);
        Row[84, 1] := LibraryRandom.RandDec(1000, 2);
        Row[85, 1] := LibraryRandom.RandDec(1000, 2);
        Row[59, 1] := (Row[81, 1] + Row[82, 1] + Row[83, 1] + Row[84, 1] + Row[85, 1]) * 0.5 + 0.01;

        VATLogicalTests.CheckForErrors(1, Row, 0, 0, Control, CheckList);
        Assert.ExpectedMessage(NegativeMsg, CheckList[10, 1]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATLogicalTests_CodeT_Positive()
    var
        ErrorMargin: Decimal;
        Row: array[99, 12] of Decimal;
        Control: array[14] of Text[250];
        CheckList: array[14, 12] of Text[30];
    begin
        ErrorMargin := LibraryRandom.RandDec(1000, 2);
        Row[85, 1] := LibraryRandom.RandDec(1000, 2);
        Row[63, 1] := Row[85, 1] * 0.21 + ErrorMargin;

        VATLogicalTests.CheckForErrors(1, Row, ErrorMargin, 0, Control, CheckList);
        Assert.ExpectedMessage(PositiveMsg, CheckList[11, 1]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATLogicalTests_CodeT_Negative()
    var
        ErrorMargin: Decimal;
        Row: array[99, 12] of Decimal;
        Control: array[14] of Text[250];
        CheckList: array[14, 12] of Text[30];
    begin
        ErrorMargin := LibraryRandom.RandDec(1000, 2);
        Row[85, 1] := LibraryRandom.RandDec(1000, 2);
        Row[63, 1] := Row[85, 1] * 0.21 + ErrorMargin + 0.01;

        VATLogicalTests.CheckForErrors(1, Row, ErrorMargin, 0, Control, CheckList);
        Assert.ExpectedMessage(NegativeMsg, CheckList[11, 1]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATLogicalTests_CodeU_Positive()
    var
        ErrorMargin: Decimal;
        Row: array[99, 12] of Decimal;
        Control: array[14] of Text[250];
        CheckList: array[14, 12] of Text[30];
    begin
        ErrorMargin := LibraryRandom.RandDec(1000, 2);
        Row[49, 1] := LibraryRandom.RandDec(1000, 2);
        Row[64, 1] := Row[49, 1] * 0.21 + ErrorMargin;

        VATLogicalTests.CheckForErrors(1, Row, ErrorMargin, 0, Control, CheckList);
        Assert.ExpectedMessage(PositiveMsg, CheckList[12, 1]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATLogicalTests_CodeU_Negative()
    var
        ErrorMargin: Decimal;
        Row: array[99, 12] of Decimal;
        Control: array[14] of Text[250];
        CheckList: array[14, 12] of Text[30];
    begin
        ErrorMargin := LibraryRandom.RandDec(1000, 2);
        Row[49, 1] := LibraryRandom.RandDec(1000, 2);
        Row[64, 1] := Row[49, 1] * 0.21 + ErrorMargin + 0.01;

        VATLogicalTests.CheckForErrors(1, Row, ErrorMargin, 0, Control, CheckList);
        Assert.ExpectedMessage(NegativeMsg, CheckList[12, 1]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATLogicalTests_Test13_Positive()
    var
        Row: array[99, 12] of Decimal;
        Control: array[14] of Text[250];
        CheckList: array[14, 12] of Text[30];
        i: Integer;
    begin
        for i := 1 to 99 do
            Row[i, 1] := LibraryRandom.RandDec(1000, 2);

        VATLogicalTests.CheckForErrors(1, Row, 0, 0, Control, CheckList);
        Assert.ExpectedMessage(PositiveMsg, CheckList[13, 1]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATLogicalTests_Test13_Negative()
    var
        Row: array[99, 12] of Decimal;
        Control: array[14] of Text[250];
        CheckList: array[14, 12] of Text[30];
        i: Integer;
    begin
        for i := 1 to 99 do
            Row[i, 1] := LibraryRandom.RandDec(1000, 2);
        Row[LibraryRandom.RandIntInRange(1, 99), 1] := -LibraryRandom.RandDec(1000, 2);

        VATLogicalTests.CheckForErrors(1, Row, 0, 0, Control, CheckList);
        Assert.ExpectedMessage(NegativeMsg, CheckList[13, 1]);
    end;
}

