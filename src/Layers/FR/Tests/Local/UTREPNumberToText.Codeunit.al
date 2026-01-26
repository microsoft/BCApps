codeunit 144042 "UT REP Number To Text"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Language] [UT]
    end;

    var
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        AmountErr: Label 'Amount in text must be same.';
        OriginalLanguageID: Integer;
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure FormatNoTextFRVendorCheck()
    var
        AmountText: array[2] of Text[80];
        AmountTextFR: array[2] of Text[80];
    begin
        // [SCENARIO 270440] Validate FormatNoTextFR function used for Vendor for Report 1401 - Check when using French language.
        Initialize();

        // [GIVEN] French language selected
        GlobalLanguage(1036);

        // [WHEN] Use Report 1401 Check to generate Standard and French amounts in text.
        ConvertNumToTextFR(LibraryRandom.RandDecInRange(100, 200, 2), AmountText, AmountTextFR);

        // [THEN] Verify Standard amount Text is equal to French amount.
        Assert.AreEqual(AmountText[1], AmountTextFR[1], AmountErr);

        // Rollback
        GlobalLanguage(OriginalLanguageID);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FormatNoTextINTLVendorCheck()
    var
        AmountText: array[2] of Text[80];
        AmountTextINTL: array[2] of Text[80];
    begin
        // [SCENARIO 270440] Validate FormatNoTextINTL function used for Vendor for Report 1401 - Check when using English language.
        Initialize();

        // [GIVEN] Default (English) language selected
        GlobalLanguage(OriginalLanguageID);

        // [WHEN] Use Report 1401 Check to generate Standard and English amounts in text.
        ConvertNumToTextINTL(LibraryRandom.RandDecInRange(100, 200, 2), AmountText, AmountTextINTL);

        // [THEN] Verify Standard amount Text is equal to English amount.
        Assert.AreEqual(AmountText[1], AmountTextINTL[1], AmountErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FormatNoTextFRCustomerCheck()
    var
        AmountText: array[2] of Text[80];
        AmountTextFR: array[2] of Text[80];
    begin
        // [SCENARIO 270440] Validate FormatNoTextFR function for Customer for Report 1401 - Check when using French language.
        Initialize();

        // [GIVEN] French language selected
        GlobalLanguage(1036);

        // [WHEN] Use Report 1401 Check to generate Standard and French amounts in text.
        ConvertNumToTextFR(LibraryRandom.RandDecInRange(100, 200, 2), AmountText, AmountTextFR);

        // [THEN] Verify Standard amount Text is equal to French amount.
        Assert.AreEqual(AmountText[1], AmountTextFR[1], AmountErr);

        // Rollback
        GlobalLanguage(OriginalLanguageID);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FormatNoTextINTLCustomerCheck()
    var
        AmountText: array[2] of Text[80];
        AmountTextINTL: array[2] of Text[80];
    begin
        // [SCENARIO 270440] Validate FormatNoTextINTL function used for Customer for Report 1401 - Check when using English language.
        Initialize();

        // [GIVEN] Default (English) language selected
        GlobalLanguage(OriginalLanguageID);

        // [WHEN] Use Report 1401 Check to generate Standard and English amounts in text.
        ConvertNumToTextINTL(LibraryRandom.RandDecInRange(100, 200, 2), AmountText, AmountTextINTL);

        // [THEN] Verify Standard amount Text is equal to English amount.
        Assert.AreEqual(AmountText[1], AmountTextINTL[1], AmountErr);
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        OriginalLanguageID := GlobalLanguage;
        IsInitialized := true;
    end;

    local procedure ConvertNumToTextFR(Amount: Decimal; var TextStandard: array[2] of Text[80]; var TextFR: array[2] of Text[80])
    var
        Check: Report Check;
    begin
        Check.InitTextVariable();
        Check.FormatNoText(TextStandard, Amount, '');
        Check.FormatNoTextFR(TextFR, Amount, '');
    end;

    local procedure ConvertNumToTextINTL(Amount: Decimal; var TextStandard: array[2] of Text[80]; var TextINTL: array[2] of Text[80])
    var
        Check: Report Check;
    begin
        Check.InitTextVariable();
        Check.FormatNoText(TextStandard, Amount, '');
        Check.FormatNoTextINTL(TextINTL, Amount, '');
    end;
}

