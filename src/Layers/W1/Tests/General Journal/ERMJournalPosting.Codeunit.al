codeunit 134420 "ERM Journal Posting"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [General Journal]
        isInitialized := false;
    end;

    var
        LibraryAssert: Codeunit "Library Assert";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryUtility: Codeunit "Library - Utility";
        Any: Codeunit "Any";
        isInitialized: Boolean;
        MinRange: Decimal;
        MiddleRange: Decimal;
        MaxRange: Decimal;

    [Test]
    [Scope('OnPrem')]
    procedure PostOneGenJnLineWithQty()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
        Qty: Decimal;
        PostedQty: Decimal;
    begin
        Initialize();
        Qty := LibraryRandom.RandDecInRange(MinRange, MaxRange, 2);
        CreateGenJournalBatch(GenJournalBatch);
        FindGLAccount(GLAccount, false);
        PostedQty := CreateAndPostGenJrnLine(GenJournalBatch, GLAccount, Qty);

        LibraryAssert.AreEqual(
          Qty, PostedQty, 'The Quantity on Entry must match the Quantity on the Journal');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NegativeTestForPostOneGenJnLineWithQty()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
        Qty: Decimal;
        PostedQty: Decimal;
    begin
        Initialize();
        Qty := LibraryRandom.RandDecInRange(MinRange, MiddleRange, 2);
        CreateGenJournalBatch(GenJournalBatch);
        FindGLAccount(GLAccount, false);
        PostedQty := CreateAndPostGenJrnLine(GenJournalBatch, GLAccount, Qty);

        LibraryAssert.AreNotEqual(
          LibraryRandom.RandDecInRange(MiddleRange, MaxRange, 2), PostedQty,
          'The Quantity on Entry must match the Quantity on the Journal');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostOneGenJnLineWithoutQty()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
        Qty: Decimal;
        PostedQty: Decimal;
    begin
        Initialize();
        Qty := 0;
        CreateGenJournalBatch(GenJournalBatch);
        FindGLAccount(GLAccount, false);
        PostedQty := CreateAndPostGenJrnLine(GenJournalBatch, GLAccount, Qty);

        LibraryAssert.AreEqual(Qty, PostedQty, 'The Quantity on Entry must match the Quantity on the Journal');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyOmitDescOnJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccountOmitDesc: Record "G/L Account";
        GLAccountWithDesc: Record "G/L Account";
    begin
        Initialize();
        CreateGenJournalBatch(GenJournalBatch);
        FindGLAccount(GLAccountOmitDesc, true);

        LibraryLowerPermissions.SetJournalsEdit();
        CreateGenJrnLine(GenJournalLine, GenJournalBatch, GLAccountOmitDesc);
        LibraryAssert.IsTrue(DelChr(GenJournalLine.Description, '=', ' ') = '', 'Description must be blank');
        LibraryLowerPermissions.SetO365Setup();

        FindGLAccount(GLAccountWithDesc, false);
        LibraryLowerPermissions.SetJournalsEdit();
        CreateGenJrnLine(GenJournalLine, GenJournalBatch, GLAccountWithDesc);
        LibraryAssert.IsFalse(DelChr(GenJournalLine.Description, '=', ' ') = '', 'Description must not be blank');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlPostBatchResetsAutoCalcFields()
    var
        GenJournalLine: Record "Gen. Journal Line";
        ERMJournalPosting: Codeunit "ERM Journal Posting";
    begin
        // [FEATURE] [UT] [Batch] [Performance]
        // [SCENARIO 301026] COD 13 "Gen. Jnl.-Post Batch" resets auto calc fields
        Initialize();

        // [GIVEN] General Journal Line with enabled auto calc fields for "Has Payment Export Error" field
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::"G/L Account", '', 0);
        GenJournalLine.SetAutoCalcFields("Has Payment Export Error");
        // [GIVEN] Linked "Payment Jnl. Export Error Text" record
        MockPmtExportErr(GenJournalLine);
        // [GIVEN] Ensure "General Journal Line"."Has Payment Export Error" = TRUE after FIND
        GenJournalLine.Find();
        GenJournalLine.TestField("Has Payment Export Error", true);

        // [WHEN] Perform COD 13 "Gen. Jnl.-Post Batch".RUN()
        BindSubscription(ERMJournalPosting);
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post Batch", GenJournalLine);

        // [THEN] Auto calc field is reset within COD13: "Has Payment Export Error" = FALSE after FIND
        // See [EventSubscriber] OnBeforeCode
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlPostBatchResetsAutoCalcFieldsOnPreview()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJnlPostBatch: Codeunit "Gen. Jnl.-Post Batch";
        ERMJournalPosting: Codeunit "ERM Journal Posting";
    begin
        // [FEATURE] [UT] [Batch] [Performance] [Preview]
        // [SCENARIO 301026] COD 13 "Gen. Jnl.-Post Batch" resets auto calc fields in case of Preview posting
        Initialize();

        // [GIVEN] General Journal Line with enabled auto calc fields for "Has Payment Export Error" field
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::"G/L Account", '', 0);
        GenJournalLine.SetAutoCalcFields("Has Payment Export Error");
        // [GIVEN] Linked "Payment Jnl. Export Error Text" record
        MockPmtExportErr(GenJournalLine);
        // [GIVEN] Ensure "General Journal Line"."Has Payment Export Error" = TRUE after FIND
        GenJournalLine.Find();
        GenJournalLine.TestField("Has Payment Export Error", true);

        // [WHEN] Perform COD 13 "Gen. Jnl.-Post Batch".Preview()
        BindSubscription(ERMJournalPosting);
        asserterror GenJnlPostBatch.Preview(GenJournalLine);
        LibraryAssert.ExpectedError('Preview mode.');

        // [THEN] Auto calc field is reset within COD13: "Has Payment Export Error" = FALSE after FIND
        // See [EventSubscriber] OnBeforeCode
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetPostAndPrintWithJobQueueGeneralLedgerSetupUT()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // [FEATURE] [Setup] [UT]
        // [SCENARIO ] "Post with Job Queue" is TRUE when "Post & Print with Job Queue" enabled
        Initialize();

        // [GIVEN] Setup, "Post with Job Queue" = FALSE, "Post & Print with Job Queue" = FALSE
        LibraryJournals.SetPostWithJobQueue(false);
        LibraryJournals.SetPostAndPrintWithJobQueue(false);
        GeneralLedgerSetup.Get();
        // [WHEN] Set "Post & Print with Job Queue" = TRUE
        GeneralLedgerSetup.Validate("Post & Print with Job Queue", true);
        // [THEN] "Post with Job Queue" = TRUE
        LibraryAssert.IsTrue(GeneralLedgerSetup."Post with Job Queue", 'Setup is not correct.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResetPostWithJobQueueGeneralLedgerSetupUT()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // [FEATURE] [Setup] [UT]
        // [SCENARIO ] "Post & Print with Job Queue" is FALSE when "Post with Job Queue" is disabled
        Initialize();

        // [GIVEN] Setup, "Post with Job Queue" = TRUE, "Post & Print with Job Queue" = TRUE
        LibraryJournals.SetPostWithJobQueue(true);
        LibraryJournals.SetPostAndPrintWithJobQueue(true);
        GeneralLedgerSetup.Get();
        // [WHEN] Set "Post with Job Queue" = FALSE
        GeneralLedgerSetup.Validate("Post with Job Queue", false);
        // [THEN] "Post & Print with Job Queue" = FALSE
        LibraryAssert.IsFalse(GeneralLedgerSetup."Post & Print with Job Queue", 'Setup is not correct.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetPrintReportOutputTypeInSaaSGeneralLedgerSetupUT()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        // [FEATURE] [Setup] [UT]
        // [SCENARIO ] Set "Report Output Type" = Print in SaaS
        Initialize();

        // [GIVEN] SaaS, Setup
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        GeneralLedgerSetup.Get();
        // [WHEN] Set "Report Output Type" = Print
        asserterror GeneralLedgerSetup.Validate("Report Output Type", GeneralLedgerSetup."Report Output Type"::Print);
        // [THEN] Error, "Report Output Type" must be PDF
        Assert.ExpectedTestFieldError(GeneralLedgerSetup.FieldCaption("Report Output Type"), Format(GeneralLedgerSetup."Report Output Type"::PDF));
    end;

    [Test]
    procedure RecordLinkDeletedAfterPostingGenJnlLine()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        RecordLink: Record "Record Link";
    begin
        // [FEATURE] [Record Link] 
        // [SCENARIO] Record links are deleted after posting a general journal line

        Initialize();

        // [GIVEN] General journal line
        LibraryJournals.CreateGenJournalBatch(GenJnlBatch);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
            GenJnlLine, GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::" ",
            GenJnlLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
            GenJnlLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), LibraryRandom.RandDec(1000, 2));

        // [GIVEN] Assign a record link to the journal line
        LibraryUtility.CreateRecordLink(GenJnlLine);

        // [WHEN] Post the journal
        LibraryERM.PostGeneralJnlLine(GenJnlLine);

        // [THEN] The record link is deleted
        RecordLink.SetRange("Record ID", GenJnlLine.RecordId);
        LibraryAssert.RecordIsEmpty(RecordLink);
    end;

    [Test]
    procedure TestGenJnlPosting_NoSeries_NoMatch()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        NoSeriesLine: Record "No. Series Line";
    begin
        // [FEATURE] [General Journal] [No. Series]
        // [SCENARIO] No. Series is not updated when posting a general journal line with a manual document no.

        // init
        Initialize();
        CreateNoSeriesWithLine(NoSeriesLine);
        CreateGenJournalBatchWithForceDocBalance(GenJournalBatch, NoSeriesLine."Series Code");
        CreateGenJournalLine(GenJournalLine, GenJournalBatch);

        // setup
        GenJournalLine.Validate("Document No.", CopyStr(Any.AlphanumericText(10), 1, MaxStrleN(GenJournalLine."Document No.")));
        GenJournalLine.Modify(true);

        // exercise
        Codeunit.Run(Codeunit::"Gen. Jnl.-Post Batch", GenJournalLine);

        // verify
        NoSeriesLine.Get(NoSeriesLine."Series Code", NoSeriesLine."Line No.");
        LibraryAssert.AreEqual('', NoSeriesLine."Last No. Used", 'Last No. Used must be empty.');
    end;

    [Test]
    procedure TestGenJnlPosting_NoSeries_Match()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        NoSeriesLine: Record "No. Series Line";
        DocNo: Code[20];
    begin
        // [FEATURE] [General Journal] [No. Series]
        // [SCENARIO] No. Series is not updated when posting a general journal line with a manual document no.

        // init
        Initialize();
        CreateNoSeriesWithLine(NoSeriesLine);
        CreateGenJournalBatchWithForceDocBalance(GenJournalBatch, NoSeriesLine."Series Code");
        CreateGenJournalLine(GenJournalLine, GenJournalBatch);

        // setup
        //todo save docno to assert later
        DocNo := GenJournalLine."Document No.";
        LibraryAssert.AreEqual(DocNo, NoSeriesLine."Starting No.", 'The document no. must match the no series.');
        LibraryAssert.AreEqual('', NoSeriesLine."Last No. Used", 'Last No. Used must be empty.');

        // exercise
        Codeunit.Run(Codeunit::"Gen. Jnl.-Post Batch", GenJournalLine);

        // verify
        NoSeriesLine.Get(NoSeriesLine."Series Code", NoSeriesLine."Line No.");
        LibraryAssert.AreEqual(DocNo, NoSeriesLine."Last No. Used", 'The document no. must match the Last No. Used');
    end;

    [Test]
    procedure TestGenJnlPosting_NoSeries_Match_2lines()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        NoSeriesLine: Record "No. Series Line";
        DocNo, DocNo2 : Code[20];
    begin
        // [FEATURE] [General Journal] [No. Series]
        // [SCENARIO] No. Series is not updated when posting a general journal line with a manual document no.

        // init
        Initialize();
        CreateNoSeriesWithLine(NoSeriesLine);
        CreateGenJournalBatchWithForceDocBalance(GenJournalBatch, NoSeriesLine."Series Code");
        CreateGenJournalLine(GenJournalLine, GenJournalBatch);
        DocNo := GenJournalLine."Document No.";
        CreateGenJournalLine(GenJournalLine, GenJournalBatch);
        DocNo2 := GenJournalLine."Document No.";

        // setup
        LibraryAssert.AreEqual(DocNo, NoSeriesLine."Starting No.", 'The document no. must match the no series.');
        LibraryAssert.AreEqual('', NoSeriesLine."Last No. Used", 'Last No. Used must be empty.');

        // exercise
        Codeunit.Run(Codeunit::"Gen. Jnl.-Post Batch", GenJournalLine);

        // verify
        NoSeriesLine.Get(NoSeriesLine."Series Code", NoSeriesLine."Line No.");
        LibraryAssert.AreEqual(DocNo2, NoSeriesLine."Last No. Used", 'The document no. must match the Last No. Used');
    end;

    [Test]
    procedure TestGenJnlPosting_NoSeries_Match_2linesReversed() //todo
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine, GenJournalLine2 : Record "Gen. Journal Line";
        NoSeriesLine: Record "No. Series Line";
        DocNo1, DocNo2 : Code[20];
    begin
        // [FEATURE] [General Journal] [No. Series]
        // [SCENARIO] No. Series is not updated when posting a general journal line with a manual document no.

        // init
        Initialize();
        CreateNoSeriesWithLine(NoSeriesLine);
        CreateGenJournalBatchWithForceDocBalance(GenJournalBatch, NoSeriesLine."Series Code");
        CreateGenJournalLine(GenJournalLine, GenJournalBatch);
        GenJournalLine2 := GenJournalLine;
        DocNo1 := GenJournalLine."Document No.";
        CreateGenJournalLine(GenJournalLine, GenJournalBatch);
        DocNo2 := GenJournalLine."Document No.";
        LibraryAssert.AreNotEqual(DocNo1, DocNo2, 'The document no. must not match.');
        LibraryAssert.AreEqual(DocNo1, NoSeriesLine."Starting No.", 'The document no. must match the no series.');
        LibraryAssert.AreEqual('', NoSeriesLine."Last No. Used", 'Last No. Used must be empty.');

        // setup
        // reverse doc no.
        GenJournalLine2.Validate("Document No.", DocNo2);
        GenJournalLine2.Modify(true);
        GenJournalLine."Document No." := DocNo1;
        GenJournalLine.Modify(true);

        // exercise
        Codeunit.Run(Codeunit::"Gen. Jnl.-Post Batch", GenJournalLine);

        // verify
        NoSeriesLine.Get(NoSeriesLine."Series Code", NoSeriesLine."Line No.");
        LibraryAssert.AreEqual(DocNo2, NoSeriesLine."Last No. Used", 'The document no. must match the Last No. Used');
    end;

    [Test]
    procedure TestGenJnlPosting_NoSeries_Match_2linesReversedNoForceBalance()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine, GenJournalLine2 : Record "Gen. Journal Line";
        NoSeriesLine: Record "No. Series Line";
        DocNo1, DocNo2 : Code[20];
    begin
        // [FEATURE] [General Journal] [No. Series]
        // [SCENARIO] No. Series is not updated when posting a general journal line with a manual document no.

        // init
        Initialize();
        CreateNoSeriesWithLine(NoSeriesLine);
        CreateGenJournalBatchWithoutForceDocBalance(GenJournalBatch, NoSeriesLine."Series Code");
        CreateGenJournalLine(GenJournalLine, GenJournalBatch);
        GenJournalLine2 := GenJournalLine;
        DocNo1 := GenJournalLine."Document No.";
        CreateGenJournalLine(GenJournalLine, GenJournalBatch);
        DocNo2 := GenJournalLine."Document No.";
        LibraryAssert.AreNotEqual(DocNo1, DocNo2, 'The document no. must not match.');
        LibraryAssert.AreEqual(DocNo1, NoSeriesLine."Starting No.", 'The document no. must match the no series.');
        LibraryAssert.AreEqual('', NoSeriesLine."Last No. Used", 'Last No. Used must be empty.');

        // setup
        // reverse doc no.
        GenJournalLine2.Validate("Document No.", DocNo2);
        GenJournalLine2.Modify(true);
        GenJournalLine."Document No." := DocNo1;
        GenJournalLine.Modify(true);

        // exercise
        Codeunit.Run(Codeunit::"Gen. Jnl.-Post Batch", GenJournalLine);

        // verify
        NoSeriesLine.Get(NoSeriesLine."Series Code", NoSeriesLine."Line No.");

        // could consider this a bug. keeping as is for now, documenting behaviour.
        asserterror LibraryAssert.AreEqual(DocNo2, NoSeriesLine."Last No. Used", 'The document no. must match the Last No. Used');
        LibraryAssert.AreEqual(DocNo1, NoSeriesLine."Last No. Used", 'The document no. must match the Last No. Used');
    end;

    [Test]
    procedure TestGenJnlPosting_NoSeries_PatternMatch()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        NoSeriesLine: Record "No. Series Line";
        NoSeriesBatch: Codeunit "No. Series - Batch";
        DocNo: Code[20];
    begin
        // [FEATURE] [General Journal] [No. Series]
        // [SCENARIO] No. Series is not updated when posting a general journal line with a manual document no.

        // init
        Initialize();
        CreateNoSeriesWithLine(NoSeriesLine);
        CreateGenJournalBatchWithForceDocBalance(GenJournalBatch, NoSeriesLine."Series Code");
        CreateGenJournalLine(GenJournalLine, GenJournalBatch);
        NoSeriesBatch.GetNextNo(NoSeriesLine."Series Code");
        NoSeriesBatch.GetNextNo(NoSeriesLine."Series Code");
        NoSeriesBatch.GetNextNo(NoSeriesLine."Series Code");
        GenJournalLine."Document No." := NoSeriesBatch.GetNextNo(NoSeriesLine."Series Code");
        GenJournalLine.Modify(true);

        // setup
        DocNo := GenJournalLine."Document No.";
        LibraryAssert.AreNotEqual(DocNo, NoSeriesLine."Starting No.", 'The document no. must not match the no series.');
        LibraryAssert.AreEqual('', NoSeriesLine."Last No. Used", 'Last No. Used must be empty.');

        // exercise
        Codeunit.Run(Codeunit::"Gen. Jnl.-Post Batch", GenJournalLine);

        // verify
        NoSeriesLine.Get(NoSeriesLine."Series Code", NoSeriesLine."Line No.");
        LibraryAssert.AreEqual('', NoSeriesLine."Last No. Used", 'Last No. Used must be empty.');
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Journal Posting");
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Journal Posting");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        isInitialized := true;
        MinRange := 0;
        MiddleRange := 100;
        MaxRange := 200;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Journal Posting");
    end;

    local procedure CreateGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    local procedure CreateAndPostGenJrnLine(GenJournalBatch: Record "Gen. Journal Batch"; GLAccount: Record "G/L Account"; Qty: Decimal): Decimal
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
    begin
        GenJournalLine.Init();
        CreateGenJrnLine(GenJournalLine, GenJournalBatch, GLAccount);
        GenJournalLine.Validate(Quantity, Qty);
        GenJournalLine.Modify(true);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        GLEntry.SetRange("Document No.", GenJournalLine."Document No.");
        GLEntry.FindLast();
        exit(GLEntry.Quantity);
    end;

    local procedure CreateGenJrnLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; GLAccount: Record "G/L Account")
    begin
        GenJournalLine.Init();
        GenJournalLine."Account Type" := GenJournalLine."Account Type"::"G/L Account";
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine,
          GenJournalBatch."Journal Template Name",
          GenJournalBatch.Name,
          GenJournalLine."Document Type",
          GenJournalLine."Account Type",
          GLAccount."No.",
          0);

        GenJournalLine.Validate("Posting Date", CalcDate('<+3Y>', Today));
        GenJournalLine.Validate(Amount, LibraryRandom.RandDecInRange(MinRange, MaxRange, 2));
        GenJournalLine.Modify(true);
    end;

    local procedure MockPmtExportErr(GenJournalLine: Record "Gen. Journal Line")
    var
        PaymentJnlExportErrorText: Record "Payment Jnl. Export Error Text";
    begin
        PaymentJnlExportErrorText.Init();
        PaymentJnlExportErrorText."Journal Template Name" := GenJournalLine."Journal Template Name";
        PaymentJnlExportErrorText."Journal Batch Name" := GenJournalLine."Journal Batch Name";
        PaymentJnlExportErrorText."Journal Line No." := GenJournalLine."Line No.";
        PaymentJnlExportErrorText.Insert();
    end;

    local procedure FindGLAccount(var GLAccount: Record "G/L Account"; OmitDesc: Boolean)
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Name := 'Not Blank';
        GLAccount."Omit Default Descr. in Jnl." := OmitDesc;
        GLAccount.Modify();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Batch", 'OnBeforeCode', '', false, false)]
    local procedure OnBeforeCode(var GenJournalLine: Record "Gen. Journal Line"; PreviewMode: Boolean; CommitIsSuppressed: Boolean)
    begin
        // Verify auto calc field is reset
        GenJournalLine.TestField("Has Payment Export Error", true);
        GenJournalLine.Find();
        GenJournalLine.TestField("Has Payment Export Error", false);
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch")
    var
        GLAccount: Record "G/L Account";
        BalGLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryAssert.IsTrue(GLAccount."Direct Posting", 'Direct Posting must be true for this test.');
        LibraryERM.CreateGLAccount(BalGLAccount);
        LibraryAssert.IsTrue(BalGLAccount."Direct Posting", 'Direct Posting must be true for this test.');
        LibraryJournals.CreateGenJournalLine2(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account", GLAccount."No.",
          GenJournalLine."Bal. Account Type"::"G/L Account", BalGLAccount."No.", Any.DecimalInRange(10000, 0));
    end;

    local procedure CreateNoSeriesWithLine(var NoSeriesLine: Record "No. Series Line")
    var
        NoSeries: Record "No. Series";
        NoSeriesBaseNo: Code[10];
    begin
        LibraryUtility.CreateNoSeries(NoSeries, true, true, false); // default and manual nos., no date order
        NoSeriesBaseNo := CopyStr(Any.AlphanumericText(3), 1, MaxStrLen(NoSeriesBaseNo));
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, CopyStr(NoSeriesBaseNo + '0001', 1, MaxStrLen(NoSeriesLine."Starting No.")), CopyStr(NoSeriesBaseNo + '9999', 1, MaxStrLen(NoSeriesLine."Starting No.")));
    end;

    local procedure CreateGenJournalBatchWithForceDocBalance(var GenJournalBatch: Record "Gen. Journal Batch"; NoSeriesCode: Code[20])
    begin
        CreateGenJournalBatch(GenJournalBatch, NoSeriesCode, true);
    end;

    local procedure CreateGenJournalBatchWithoutForceDocBalance(var GenJournalBatch: Record "Gen. Journal Batch"; NoSeriesCode: Code[20])
    begin
        CreateGenJournalBatch(GenJournalBatch, NoSeriesCode, false);
    end;

    local procedure CreateGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; NoSeriesCode: Code[20]; ForceDocBalance: Boolean)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate("Force Doc. Balance", ForceDocBalance);
        GenJournalTemplate.Modify(true);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("No. Series", NoSeriesCode);
        GenJournalBatch.Validate("Posting No. Series", '');
        GenJournalBatch.Modify(true);
    end;
}
