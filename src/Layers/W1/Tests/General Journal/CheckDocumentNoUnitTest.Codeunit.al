codeunit 134073 "Check Document No. Unit Test"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Document No.] [General Journal] [UT]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryNoSeries: Codeunit "Library - No. Series";
        DocumentNoErr: Label 'You have one or more documents that must be posted before you post document no. %1 according to your company''s No. Series setup.', Comment = '%1 = Document number';
        IncorrectNoSeriesCodeErr: Label 'Incorrect No. Series code';
        LibraryVariableStorage: Codeunit "Library - Variable Storage";

    [Test]
    [Scope('OnPrem')]
    procedure MultipleLinesDifferentVendorDifferentDocNo()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        Vendor1: Record Vendor;
        Vendor2: Record Vendor;
    begin
        // Pre-Setup
        CreateGenJnlBatch(GenJnlBatch);
        LibraryPurchase.CreateVendor(Vendor1);
        LibraryPurchase.CreateVendor(Vendor2);

        // Setup
        CreateDiffAccNoDiffDocNoLines(GenJnlBatch, GenJnlLine."Account Type"::Vendor, Vendor1."No.", Vendor2."No.");

        // Pre-Exercise
        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);

        // Exercise
        GenJnlLine.CheckDocNoOnLines();

        // Verify
        BatchPostJournalLines(GenJnlBatch);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultipleLinesDifferentVendorSameDocNo()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        Vendor1: Record Vendor;
        Vendor2: Record Vendor;
    begin
        // Pre-Setup
        CreateGenJnlBatch(GenJnlBatch);
        LibraryPurchase.CreateVendor(Vendor1);
        LibraryPurchase.CreateVendor(Vendor2);

        // Setup
        CreateDiffAccNoSameDocNoLines(GenJnlBatch, GenJnlLine."Account Type"::Vendor, Vendor1."No.", Vendor2."No.");

        // Pre-Exercise
        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);

        // Exercise
        GenJnlLine.CheckDocNoOnLines();

        // Verify
        BatchPostJournalLines(GenJnlBatch);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MulitpleLinesSameVendorSameDocNo()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
    begin
        // Pre-Setup
        CreateGenJnlBatch(GenJnlBatch);
        LibraryPurchase.CreateVendor(Vendor);

        // Setup
        CreateSameAccNoSameDocNoLines(GenJnlBatch, GenJnlLine."Account Type"::Vendor, Vendor."No.");

        // Pre-Exercise
        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);

        // Exercise
        GenJnlLine.CheckDocNoOnLines();

        // Verify
        BatchPostJournalLines(GenJnlBatch);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultipleLinesSameVendorWithDocNoGap()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        CorrectDocumentNo: Code[20];
    begin
        // Pre-Setup
        CreateGenJnlBatch(GenJnlBatch);
        LibraryPurchase.CreateVendor(Vendor);

        // Setup
        CorrectDocumentNo := CreateSameAccLinesWithDocNoGap(GenJnlBatch, GenJnlLine."Account Type"::Vendor, Vendor."No.");

        // Pre-Exercise
        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);

        // Exercise
        asserterror GenJnlLine.CheckDocNoOnLines();

        // Verify
        Assert.ExpectedError(StrSubstNo(DocumentNoErr, IncStr(CorrectDocumentNo)));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure NoSeriesAboveLimitDecimal()
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        NoSeriesCodeunit: Codeunit "No. Series";
        NextNo: Code[20];
    begin
        // [FEATURE] [No. Series]
        // [SCENARIO 201310] Getting next No. Series when number encoded exceeds limit for type "decimal"

        // [GIVEN]
        LibraryUtility.CreateNoSeries(NoSeries, false, false, false);

        // [GIVEN] No. Series with "Last No. Used"= "T09000000000000001" and "Increment-by No." = "10"
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, 'T09000000000000000', 'T09999999999999991');
        NoSeriesLine."Last No. Used" := 'T09000000000000001'; // The limit for type "decimal" is "999,999,999,999,999.00"
        NoSeriesLine."Increment-by No." := 10;
        NoSeriesLine.Modify();

        // [WHEN] Get next No. Series
        NextNo := NoSeriesCodeunit.GetNextNo(NoSeries.Code);

        // [THEN] Returns Next No. generated = "T09000000000000011"
        Assert.AreEqual('T09000000000000011', NextNo, 'Next No. Series is not as expected');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultNoSeriesIfSelectNoSeriesNotAllowed()
    var
        NoSeries: Record "No. Series";
        RelatedNoSeries: Record "No. Series";
        ActualNoSeries: Code[20];
    begin
        // [FEATURE] [No. Series]
        // [SCENARIO 210983] Default No. Series used if SelectNoSeriesAllowed is false when call GetNoSeriesWithCheck

        LibraryUtility.CreateNoSeries(NoSeries, false, false, false);
        LibraryUtility.CreateNoSeries(RelatedNoSeries, true, false, false);
        LibraryNoSeries.CreateNoSeriesRelationship(NoSeries.Code, RelatedNoSeries.Code);

        ActualNoSeries := GetNoSeriesWithCheck(NoSeries.Code, false, '');

        Assert.AreEqual(NoSeries.Code, ActualNoSeries, IncorrectNoSeriesCodeErr);
    end;

    local procedure GetNoSeriesWithCheck(NoSeriesCode: Code[20]; SelectNoSeriesAllowed: Boolean; CurrentNoSeriesCode: Code[20]): Code[20]
    var
        NoSeries: Codeunit "No. Series";
    begin

        if not SelectNoSeriesAllowed then
            exit(NoSeriesCode);

        if NoSeries.IsAutomatic(NoSeriesCode) then
            exit(NoSeriesCode);

        if NoSeries.HasRelatedSeries(NoSeriesCode) then
            if NoSeries.LookupRelatedNoSeries(NoSeriesCode, CurrentNoSeriesCode) then
                exit(CurrentNoSeriesCode);

        exit(NoSeriesCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultNoSeriesIfSelectNoSeriesAllowedAndDefaultNos()
    var
        NoSeries: Record "No. Series";
        RelatedNoSeries: Record "No. Series";
        ActualNoSeries: Code[20];
    begin
        // [FEATURE] [No. Series]
        // [SCENARIO 210983] Default No. Series used if SelectNoSeriesAllowed is true and No. Series is "Default Nos." when call GetNoSeriesWithCheck

        LibraryUtility.CreateNoSeries(NoSeries, true, false, false);
        LibraryUtility.CreateNoSeries(RelatedNoSeries, true, false, false);
        LibraryNoSeries.CreateNoSeriesRelationship(NoSeries.Code, RelatedNoSeries.Code);

        ActualNoSeries := GetNoSeriesWithCheck(NoSeries.Code, true, '');

        Assert.AreEqual(NoSeries.Code, ActualNoSeries, IncorrectNoSeriesCodeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultNoSeriesIfSelectNoSeriesAllowedNotDefaultNosNoRelations()
    var
        NoSeries: Record "No. Series";
        ActualNoSeries: Code[20];
    begin
        // [FEATURE] [No. Series]
        // [SCENARIO 210983] Default No. Series used if SelectNoSeriesAllowed is true, No. Series is not "Default Nos." and no series relations when call GetNoSeriesWithCheck

        LibraryUtility.CreateNoSeries(NoSeries, false, false, false);

        ActualNoSeries := GetNoSeriesWithCheck(NoSeries.Code, true, '');

        Assert.AreEqual(NoSeries.Code, ActualNoSeries, IncorrectNoSeriesCodeErr);
    end;

    [Test]
    [HandlerFunctions('NoSeriesListModalPageHandler')]
    [Scope('OnPrem')]
    procedure RelatedNoSeriesIfSelectNoSeriesAllowedSelectRelation()
    var
        NoSeries: Record "No. Series";
        RelatedNoSeries: Record "No. Series";
        ActualNoSeries: Code[20];
    begin
        // [FEATURE] [No. Series]
        // [SCENARIO 210983] Related No. Series used if SelectNoSeriesAllowed is true, No. Series is not "Default Nos." and no. series relation selected when call GetNoSeriesWithCheck

        LibraryUtility.CreateNoSeries(NoSeries, false, false, false);
        LibraryUtility.CreateNoSeries(RelatedNoSeries, true, false, false);
        LibraryNoSeries.CreateNoSeriesRelationship(NoSeries.Code, RelatedNoSeries.Code);
        LibraryVariableStorage.Enqueue(RelatedNoSeries.Code);

        ActualNoSeries := GetNoSeriesWithCheck(NoSeries.Code, true, '');

        Assert.AreEqual(RelatedNoSeries.Code, ActualNoSeries, IncorrectNoSeriesCodeErr);
    end;

    [Test]
    [HandlerFunctions('NoSeriesListSelectNothingModalPageHandler')]
    [Scope('OnPrem')]
    procedure DefaultNoSeriesIfSelectNoSeriesAllowedCancelSelectRelation()
    var
        NoSeries: Record "No. Series";
        RelatedNoSeries: Record "No. Series";
        ActualNoSeries: Code[20];
    begin
        // [FEATURE] [No. Series]
        // [SCENARIO 210983] Default No. Series used if SelectNoSeriesAllowed is true, No. Series is not "Default Nos." and no. series relation not selected when call GetNoSeriesWithCheck

        LibraryUtility.CreateNoSeries(NoSeries, false, false, false);
        LibraryUtility.CreateNoSeries(RelatedNoSeries, true, false, false);
        LibraryNoSeries.CreateNoSeriesRelationship(NoSeries.Code, RelatedNoSeries.Code);
        LibraryVariableStorage.Enqueue(RelatedNoSeries.Code);

        ActualNoSeries := GetNoSeriesWithCheck(NoSeries.Code, true, '');

        Assert.AreEqual(NoSeries.Code, ActualNoSeries, IncorrectNoSeriesCodeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LastNoUsedNotIncrementedWhenPostGenJnlLineDocNoManual()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        NoSeriesCode: Code[20];
        LastNoUsed: Code[20];
        GenJournalAccountType: Enum "Gen. Journal Account Type";
    begin
        // [FEATURE] [No. Series]
        // [SCENARIO 376013] Post General Journal Line when No. Series has Manual Nos = true and Document No. is not equal to the next No from No. Series.

        // [GIVEN] No. Series with Manual Nos. = true.
        // [GIVEN] No. Series Line with Last No. Used = 'A001'.
        // [GIVEN] General Journal Line with Document No. = 'ABC', i.e. number is not from No Series.
        NoSeriesCode := CreateNoSeriesWithManualNos(true);
        LastNoUsed := GetLastNoUsedFromNoSeries(NoSeriesCode);

        CreateGenJournalBatchWithNoSeries(GenJournalBatch, NoSeriesCode);
        LibraryJournals.CreateGenJournalLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
            GenJournalAccountType::Vendor, LibraryPurchase.CreateVendorNo(),
            GenJournalAccountType::"G/L Account", LibraryERM.CreateGLAccountNo(), LibraryRandom.RandDecInRange(100, 200, 2));
        GenJournalLine.Validate("Document No.", LibraryUtility.GenerateRandomXMLText(MaxStrLen(GenJournalLine."Document No.")));
        GenJournalLine.Modify(true);

        // [WHEN] Post General Journal Line.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Last No. Used was not changed.
        Assert.AreEqual(LastNoUsed, GetLastNoUsedFromNoSeries(NoSeriesCode), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LastNoUsedIncrementedWhenPostGenJnlLineDocNoIsNextNoFromNoSeries()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        NoSeriesCode: Code[20];
        DocumentNo: Code[20];
        GenJournalAccountType: Enum "Gen. Journal Account Type";
    begin
        // [FEATURE] [No. Series]
        // [SCENARIO 376013] Post General Journal Line when No. Series has Manual Nos = true and Document No. is equal to the next No from No. Series.

        // [GIVEN] No. Series with Manual Nos. = true.
        // [GIVEN] No. Series Line with Last No. Used = 'A001'.
        // [GIVEN] General Journal Line with Document No. = 'A002', i.e. number is the next No from No Series.
        NoSeriesCode := CreateNoSeriesWithManualNos(true);
        DocumentNo := GetLastNoUsedFromNoSeries(NoSeriesCode);
        DocumentNo := IncStr(DocumentNo);

        CreateGenJournalBatchWithNoSeries(GenJournalBatch, NoSeriesCode);
        LibraryJournals.CreateGenJournalLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
            GenJournalAccountType::Vendor, LibraryPurchase.CreateVendorNo(),
            GenJournalAccountType::"G/L Account", LibraryERM.CreateGLAccountNo(), LibraryRandom.RandDecInRange(100, 200, 2));
        GenJournalLine.Validate("Document No.", DocumentNo);
        GenJournalLine.Modify(true);

        // [WHEN] Post General Journal Line.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Last No. Used was changed to 'A002'.
        Assert.AreEqual(DocumentNo, GetLastNoUsedFromNoSeries(NoSeriesCode), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorWhenManualNosEnabledAndPostingDateOrderReversedInGenJournalLines()
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [No. Series]
        // [SCENARIO 416887] Stan can't post gen journal lines with reversed order of posting dates when "Document No." does not fit respective "No. Series Line"'s range.

        // [GIVEN] "No. Series" "X" with the lines.
        // [GIVEN] "No. Series Line"[1]: "Starting Date" = 01/01/2021, "Starting No." = A00000, "Ending No." = A01000
        // [GIVEN] "No. Series Line"[2]: "Starting Date" = 01/01/2022, "Starting No." = A01001, "Ending No." = A02000
        LibraryUtility.CreateNoSeries(NoSeries, false, false, false);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, 'A0001', 'A1000');
        NoSeriesLine."Starting Date" := WorkDate();
        NoSeriesLine.Modify();
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, 'A1001', 'A2000');
        NoSeriesLine."Starting Date" := WorkDate() + 1;
        NoSeriesLine.Modify();

        // [GIVEN] General journal batch with "No. Series" = "X"
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"G/L Account");
        GenJournalBatch.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNoWithDirectPosting());
        GenJournalBatch.Validate("No. Series", NoSeries.Code);
        GenJournalBatch.Modify(true);

        // [GIVEN] Two general journal lines
        // [GIVEN] [1]: "Posting Date" = 01/01/2022, "Document No." = A01001
        // [GIVEN] [2]: "Posting Date" = 01/01/2021, "Document No." = A01002 // out of range
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(),
          LibraryRandom.RandIntInRange(100, 200));
        GenJournalLine.Validate("Posting Date", WorkDate() + 1);
        GenJournalLine.Validate("Document No.", 'A1001');
        GenJournalLine.Modify(true);

        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(),
          LibraryRandom.RandIntInRange(100, 200));
        GenJournalLine.Validate("Posting Date", WorkDate());
        GenJournalLine.Validate("Document No.", 'A1002');
        GenJournalLine.Modify(true);

        // [WHEN] Post general journal batch
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Error has been thrown with the message "You have one or more documents that must be posted before you post document no. A01002 according to your company's No. Series setup."
        Assert.ExpectedError(StrSubstNo(DocumentNoErr, 'A1002'));
    end;

    local procedure CreateGenJnlBatch(var GenJnlBatch: Record "Gen. Journal Batch")
    var
        BankAcc: Record "Bank Account";
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        LibraryERM.CreateGenJournalBatch(GenJnlBatch, LibraryERM.SelectGenJnlTemplate());

        LibraryERM.CreateBankAccount(BankAcc);
        GenJnlBatch.Validate("Bal. Account Type", GenJnlBatch."Bal. Account Type"::"Bank Account");
        GenJnlBatch.Validate("Bal. Account No.", BankAcc."No.");
        GenJnlBatch.Modify(true);

        LibraryUtility.CreateNoSeries(NoSeries, true, false, false);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, '', '');
        GenJnlBatch.Validate("No. Series", NoSeries.Code);
        GenJnlBatch.Modify(true);
    end;

    local procedure CreateGenJournalBatchWithNoSeries(var GenJournalBatch: Record "Gen. Journal Batch"; NoSeriesCode: Code[20])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        GenJournalBatch.Validate("No. Series", NoSeriesCode);
        GenJournalBatch.Modify(true);
    end;

    local procedure CreateDiffAccNoDiffDocNoLines(GenJnlBatch: Record "Gen. Journal Batch"; AccountType: Enum "Gen. Journal Account Type"; FirstAccountNo: Code[20]; SecondAccountNo: Code[20])
    var
        GenJnlLine1: Record "Gen. Journal Line";
        GenJnlLine2: Record "Gen. Journal Line";
    begin
        LibraryERM.CreateGeneralJnlLine(GenJnlLine1, GenJnlBatch."Journal Template Name", GenJnlBatch.Name,
          GenJnlLine1."Document Type"::Payment, AccountType, FirstAccountNo, LibraryRandom.RandDec(1000, 2));

        LibraryERM.CreateGeneralJnlLine(GenJnlLine2, GenJnlBatch."Journal Template Name", GenJnlBatch.Name,
          GenJnlLine2."Document Type"::Payment, AccountType, SecondAccountNo, LibraryRandom.RandDec(1000, 2));
        GenJnlLine2.Validate("Document No.", IncStr(GenJnlLine1."Document No."));
        GenJnlLine2.Modify(true);
    end;

    local procedure BatchPostJournalLines(GenJnlBatch: Record "Gen. Journal Batch")
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);
        GenJnlLine.FindFirst();
        LibraryERM.PostGeneralJnlLine(GenJnlLine);
    end;

    local procedure CreateDiffAccNoSameDocNoLines(GenJnlBatch: Record "Gen. Journal Batch"; AccountType: Enum "Gen. Journal Account Type"; FirstAccountNo: Code[20]; SecondAccountNo: Code[20])
    var
        GenJnlLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
    begin
        CreateDiffAccNoDiffDocNoLines(GenJnlBatch, AccountType, FirstAccountNo, SecondAccountNo);

        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);
        GenJnlLine.FindFirst();
        DocumentNo := GenJnlLine."Document No.";

        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);
        GenJnlLine.ModifyAll("Document No.", DocumentNo, true);
    end;

    local procedure CreateSameAccNoSameDocNoLines(GenJnlBatch: Record "Gen. Journal Batch"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20])
    begin
        CreateDiffAccNoSameDocNoLines(GenJnlBatch, AccountType, AccountNo, AccountNo);
    end;

    local procedure CreateSameAccLinesWithDocNoGap(GenJnlBatch: Record "Gen. Journal Batch"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]) CorrectDocumentNo: Code[20]
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        CreateDiffAccNoDiffDocNoLines(GenJnlBatch, AccountType, AccountNo, AccountNo);

        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);
        GenJnlLine.FindLast();
        CorrectDocumentNo := GenJnlLine."Document No.";

        GenJnlLine.Validate("Document No.", IncStr(GenJnlLine."Document No."));
        GenJnlLine.Modify(true);
    end;

    local procedure CreateNoSeriesWithManualNos(ManualNos: Boolean) NoSeriesCode: Code[20]
    var
        NoSeries: Record "No. Series";
        NoSeriesCodeunit: Codeunit "No. Series";
    begin
        NoSeriesCode := LibraryERM.CreateNoSeriesCode();

        NoSeries.Get(NoSeriesCode);
        NoSeries.Validate("Manual Nos.", ManualNos);
        NoSeries.Modify(true);

        NoSeriesCodeunit.GetNextNo(NoSeriesCode);  // initialize Last No. Used
    end;

    local procedure GetLastNoUsedFromNoSeries(NoSeriesCode: Code[20]) LastNoUsed: Code[20]
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        NoSeriesLine.SetRange("Series Code", NoSeriesCode);
        NoSeriesLine.FindLast();

        NoSeriesLine.TestField("Last No. Used");
        LastNoUsed := NoSeriesLine."Last No. Used";
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure NoSeriesListModalPageHandler(var NoSeriesList: TestPage "No. Series")
    begin
        NoSeriesList.FILTER.SetFilter(Code, LibraryVariableStorage.DequeueText());
        NoSeriesList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure NoSeriesListSelectNothingModalPageHandler(var NoSeriesList: TestPage "No. Series")
    begin
        NoSeriesList.Cancel().Invoke();
    end;
}
