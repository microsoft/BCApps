codeunit 144000 "IT - Fixed Assets"
{
    // Fixed Assets Localization for Italy
    // 
    //  1. Test creation of Multiple Fixed Assets while Posting Purchase Invoice.
    //  2. Test compressed depreciation.

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        IncorrectNumberOfEntries: Label 'Incorrect number of entries posted to %1 table.';
        DepreciationBookCode: Code[10];
        UseAnticipatedDepr: Boolean;
        UseAccDecrDepr: Boolean;
        TotalDepreciationCalcError: Label 'The Total Depreciation is calculated incorrectly!';
        CompletionStatsTok: Label 'The depreciation has been calculated.';

    local procedure Initialize()
    begin
        // Clear Global Variables used in Handlers.
        Clear(DepreciationBookCode);
        Clear(UseAnticipatedDepr);
        Clear(UseAccDecrDepr);
    end;

    [Test]
    [HandlerFunctions('CalculateDepreciationPageHandler,DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure DepreciationCompSameGroup()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DepreciationBook: Code[10];
        DocumentNo: Code[20];
        FAPostingGroup: Code[20];
    begin
        // Test Compressed Depreciation.
        // GLIntegration for Acqusition Cost = Yes, GLIntegration for Depreciation = No, Fixed Assets use same FA Posting Group.

        // 1.Setup.
        Initialize();

        // 2.Exercise: Create Depreciation Book, FA Journal Setup, FA Posting Group.
        DepreciationBook := CreateDepreciationBook(true, false, true, false, false);
        FAPostingGroup := CreateFAPostingGroup();

        // 2.Exercise: Create Purchase Invoice Header.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateVendor());

        // 3. Exercise: Create Fixed Asset, Purchase Line.
        CreatePurchLine(PurchaseLine, PurchaseHeader, DepreciationBook, FAPostingGroup, 1);

        // 4. Exercise: Create Fixed Asset, Purchase Line.
        CreatePurchLine(PurchaseLine, PurchaseHeader, DepreciationBook, FAPostingGroup, 1);

        // 5. Post Purchase Invoice.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // 6. Exercise: Calculate and Post Depreciation
        DocumentNo := CalculatePostDepreciation(DepreciationBook, false);

        // 7. Verify G/L Entries.
        VerifyGLEntryCompression(DocumentNo, true); // Depreciation for Fixed Assets posted to G/L Entry as single entry. Compression expected.
    end;

    [Test]
    [HandlerFunctions('CalculateDepreciationPageHandler,DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure DepreciationCompDiffGroup()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DepreciationBook: Code[10];
        DocumentNo: Code[20];
    begin
        // Test Compress Depreciation.
        // GLIntegration for Acqusition Cost = Yes, GLIntegration for Depreciation = No, Fixed Assets use different FA Posting Group.

        // 1.Setup.
        Initialize();

        // 2.Exercise: Create Depreciation Book and FA Journal Setup.
        DepreciationBook := CreateDepreciationBook(true, false, true, false, false);

        // 2.Exercise: Create Purchase Invoice Header.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateVendor());

        // 3. Exercise: Create Fixed Asset, FA Posting Group, Purchase Line.
        CreatePurchLine(PurchaseLine, PurchaseHeader, DepreciationBook, CreateFAPostingGroup(), 1);

        // 4. Exercise: Create Fixed Asset, FA Posting Group, Purchase Line.
        CreatePurchLine(PurchaseLine, PurchaseHeader, DepreciationBook, CreateFAPostingGroup(), 1);

        // 5. Post Purchase Invoice.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // 6. Exercise: Calculate and Post Depreciation
        DocumentNo := CalculatePostDepreciation(DepreciationBook, false);

        // 7. Verify G/L Entries.
        VerifyGLEntryCompression(DocumentNo, false); // Depreciation for Fixed Assets posted to G/L Entry as separate entries. No compression expected.
    end;

    [Test]
    [HandlerFunctions('CalculateDepreciationPageHandler,DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure DepreciationNoCompSameGroup()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DepreciationBook: Code[10];
        DocumentNo: Code[20];
        FAPostingGroup: Code[20];
    begin
        // Test Compress Depreciation.
        // GLIntegration for Acqusition Cost = Yes, GLIntegration for Depreciation = No, Fixed Assets use same FA Posting Group, Compression = No.

        // 1.Setup.
        Initialize();

        // 2.Exercise: Create Depreciation Book, FA Journal Setup, FA Posting Group.
        DepreciationBook := CreateDepreciationBook(true, false, false, false, false);
        FAPostingGroup := CreateFAPostingGroup();

        // 2.Exercise: Create Purchase Invoice Header.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateVendor());

        // 3. Exercise: Create Fixed Asset, Purchase Line.
        CreatePurchLine(PurchaseLine, PurchaseHeader, DepreciationBook, FAPostingGroup, 1);

        // 4. Exercise: Create Fixed Asset, Purchase Line.
        CreatePurchLine(PurchaseLine, PurchaseHeader, DepreciationBook, FAPostingGroup, 1);

        // 5. Post Purchase Invoice.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // 6. Exercise: Calculate and Post Depreciation
        DocumentNo := CalculatePostDepreciation(DepreciationBook, false);

        // 7. Verify G/L Entries.
        VerifyNoGLEntriesPosted(DocumentNo, 0); // Depreciation for Fixed Assets posted to G/L Entry as separate entries. No compression expected.
    end;

    [Test]
    [HandlerFunctions('CalculateDepreciationPageHandler,DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure DepreciationCompDeprIntSameGroup()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DepreciationBook: Code[10];
        DocumentNo: Code[20];
        FAPostingGroup: Code[20];
    begin
        // Test Compress Depreciation.
        // GLIntegration for Acqusition Cost = Yes, GLIntegration for Depreciation = Yes, Fixed Assets use same FA Posting Group.

        // 1.Setup.
        Initialize();

        // 2.Exercise: Create Depreciation Book, FA Journal Setup, FA Posting Group.
        DepreciationBook := CreateDepreciationBook(true, true, true, false, false);
        FAPostingGroup := CreateFAPostingGroup();

        // 2.Exercise: Create Purchase Invoice Header.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateVendor());

        // 3. Exercise: Create Fixed Asset, Purchase Line.
        CreatePurchLine(PurchaseLine, PurchaseHeader, DepreciationBook, FAPostingGroup, 1);

        // 4. Exercise: Create Fixed Asset, Purchase Line.
        CreatePurchLine(PurchaseLine, PurchaseHeader, DepreciationBook, FAPostingGroup, 1);

        // 5. Post Purchase Invoice.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // 6. Exercise: Calculate and Post Depreciation
        DocumentNo := CalculatePostDepreciation(DepreciationBook, true);

        // 7. Verify G/L Entries.
        VerifyNoGLEntriesPosted(DocumentNo, 2); // Depreciation for Fixed Assets posted to G/L Entry as separate entries. No compression expected.
    end;

    [Test]
    [HandlerFunctions('CalculateDepreciationPageHandler,DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure DepreciationCompAcqNotIntSameGroup()
    var
        DepreciationBook: Code[10];
        DocumentNo: Code[20];
        FAPostingGroup: Code[20];
    begin
        // Test Compress Depreciation.
        // GLIntegration for Acqusition Cost = No, GLIntegration for Depreciation = No, Fixed Assets use same FA Posting Group.

        // 1.Setup.
        Initialize();

        // 2.Exercise: Create Depreciation Book, FA Journal Setup, FA Posting Group.
        DepreciationBook := CreateDepreciationBook(false, false, true, false, false);
        FAPostingGroup := CreateFAPostingGroup();

        // 3. Create Fixed Assets, Post Acquisition Cost.
        PostAcqusitionCost(DepreciationBook, FAPostingGroup);
        PostAcqusitionCost(DepreciationBook, FAPostingGroup);

        // 4. Exercise: Calculate and Post Depreciation
        DocumentNo := CalculatePostDepreciation(DepreciationBook, false);

        // 5. Verify G/L Entries.
        VerifyNoGLEntriesPosted(DocumentNo, 1); // Depreciation for Fixed Assets posted to G/L Entry as single entry. Compression expected.
    end;

    [Test]
    [HandlerFunctions('PostConfirmHandler,PostConfirmMessage,CalculateDepreciationPageHandler')]
    [Scope('OnPrem')]
    procedure DepreciationCompConfirmation()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        FAJournalLine: Record "FA Journal Line";
        DepreciationBook: Code[10];
        FAPostingGroup: Code[20];
    begin
        // Verify Confirmation message for Compress Depreciation.
        // GLIntegration for Acqusition Cost = Yes, GLIntegration for Depreciation = No, Fixed Assets use same FA Posting Group.

        // 1.Setup.
        Initialize();

        // 2.Exercise: Create Depreciation Book, FA Journal Setup, FA Posting Group.
        DepreciationBook := CreateDepreciationBook(true, false, true, false, false);
        FAPostingGroup := CreateFAPostingGroup();

        // 2.Exercise: Create Purchase Invoice Header.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateVendor());

        // 3. Exercise: Create Fixed Asset, Purchase Line.
        CreatePurchLine(PurchaseLine, PurchaseHeader, DepreciationBook, FAPostingGroup, 1);

        // 4. Exercise: Create Fixed Asset, Purchase Line.
        CreatePurchLine(PurchaseLine, PurchaseHeader, DepreciationBook, FAPostingGroup, 1);

        // 5. Post Purchase Invoice.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // 6. Exercise: Calculate Depreciation.
        CalculateDepreciation(DepreciationBook);

        // 7. Get Template and Batch from Depreciation Book.
        GetFAJournalLine(FAJournalLine, DepreciationBook);

        // 8. Post FA Journal Lines. Confirmation dialog expected.
        CODEUNIT.Run(CODEUNIT::"FA. Jnl.-Post", FAJournalLine);
    end;

    [Test]
    [HandlerFunctions('CalculateDepreciationPageHandler,DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure AnticipatedDepreciation()
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        // Test User Defined Depreciation with Anticipated %.

        // 1.Setup.
        Initialize();

        // 2. Set Global Variable and Execute Verification.
        UseAnticipatedDepr := true;
        CustomDepreciation(FALedgerEntry."FA Posting Type"::"Custom 1");
    end;

    [Test]
    [HandlerFunctions('CalculateDepreciationPageHandler,DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure AcceleratedDepreciation()
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        // Test User Defined Depreciation with Accelerated/Reduced %.

        // 1. Setup.
        Initialize();

        // 2. Set Global Variable and Execute Verification.
        UseAccDecrDepr := true;
        CustomDepreciation(FALedgerEntry."FA Posting Type"::"Custom 2");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckTotalDeprinDeprTable()
    begin
        // Direct way scenario: check that Total Depreciation is correct when the Depreciation table is simply created by adding lines

        CalculateTotalDepreciation(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckTotalDeprinDeprTableZeroPerc()
    begin
        // More complex scenario: Creating "empty" line and then returning back. Total Depreciation Value should be the same.

        CalculateTotalDepreciation(true);
    end;

    local procedure CustomDepreciation(FAPostingType: Enum "FA Ledger Entry FA Posting Type")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DepreciationTableLine: Record "Depreciation Table Line";
        FADepreciationBook: Record "FA Depreciation Book";
        DepreciationBook: Code[10];
        DocumentNo: Code[20];
        FAPostingGroup: Code[20];
        FANo: Code[20];
        Amount: Decimal;
    begin
        // Test User Defined Depreciation.

        // 1.Exercise: Create Depreciation Book, FA Journal Setup, FA Posting Group.
        DepreciationBook := CreateDepreciationBook(true, false, false, UseAnticipatedDepr, UseAccDecrDepr);
        FAPostingGroup := CreateFAPostingGroup();

        // 2.Exercise: Create Purchase Invoice Header.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateVendor());

        // 3. Exercise: Create Fixed Asset, Purchase Line.
        FANo := CreatePurchLine(PurchaseLine, PurchaseHeader, DepreciationBook, FAPostingGroup, 1);

        // 4. Post Purchase Invoice.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // 5. Create Depreciation Table.
        CreateDepreciationTable(DepreciationTableLine, false, UseAnticipatedDepr, UseAccDecrDepr);

        // 5. Setup Depreciation Method.
        ModifyDepreciationMethod(
          FANo, DepreciationBook, FADepreciationBook."Depreciation Method"::"User-Defined",
          DepreciationTableLine."Depreciation Table Code", '<CD>');

        // 6. Exercise: Calculate and Post Depreciation
        DocumentNo := CalculatePostDepreciation(DepreciationBook, false);

        // 7. Verify FA Ledger Entries.
        if UseAnticipatedDepr then
            Amount := PurchaseLine."Direct Unit Cost" * DepreciationTableLine."Anticipated %" / 100;
        if UseAccDecrDepr then
            Amount := PurchaseLine."Direct Unit Cost" * DepreciationTableLine."Accelerated/Reduced %" / 100;
        VerifyUserDefinedDepreciation(DocumentNo, FANo, FAPostingType, Amount);
    end;

    local procedure RunCalculateDepreciation(var CalculateDepreciation: TestRequestPage "Calculate Depreciation"; DepreciationBook: Code[10]; PostingDate: Date; BalAccount: Boolean; UseAncipated: Boolean; UseAccDec: Boolean)
    begin
        CalculateDepreciation."Fixed Asset".SetFilter("No.", '');
        CalculateDepreciation.DepreciationBook.SetValue(DepreciationBook);
        CalculateDepreciation.PostingDate.SetValue(PostingDate);
        CalculateDepreciation.FAPostingDate.SetValue(PostingDate);
        CalculateDepreciation.UseForceNoOfDays.SetValue(false);
        CalculateDepreciation.DocumentNo.SetValue('NOR-' + DepreciationBook);
        CalculateDepreciation.InsertBalAccount.SetValue(BalAccount);

        CalculateDepreciation.UseAnticipatedDepr.SetValue(UseAncipated);
        CalculateDepreciation.DocumentNoAnticipated.SetValue('ANT-' + DepreciationBook);

        CalculateDepreciation.UseAccRedDepr.SetValue(UseAccDec);
        CalculateDepreciation.DocumentNoAccRed.SetValue('ACC-' + DepreciationBook);
    end;

    local procedure CalculateDepreciation(DepreciationBook: Code[10])
    begin
        // Calculate Depreciation for the First Year.
        DepreciationBookCode := DepreciationBook; // Set value of global variable for Handler.

        Commit(); // Required to run report with Request Page.
        REPORT.Run(REPORT::"Calculate Depreciation", true); // Calculate depreciation Handler.
    end;

    local procedure CalculatePostDepreciation(DepreciationBook: Code[10]; GLIntegration: Boolean) DocumentNo: Code[20]
    begin
        // Calculate Depreciation for the First Year.
        CalculateDepreciation(DepreciationBook);

        // Post Journal Lines.
        DocumentNo := PostDepreciation(DepreciationBook, GLIntegration);
    end;

    local procedure CreateDepreciationBook(GLIntegrationAcqCost: Boolean; GLIntegrationDepreciation: Boolean; CompressDepreciaton: Boolean; AnticipatedDepreciation: Boolean; AccRedDepreciation: Boolean): Code[10]
    var
        DepreciationBook: Record "Depreciation Book";
        FAJournalBatch: Record "FA Journal Batch";
        FAJournalTemplate: Record "FA Journal Template";
        FAJournalSetup: Record "FA Journal Setup";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // Create Depreciation Book.
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        DepreciationBook.Validate("G/L Integration - Acq. Cost", GLIntegrationAcqCost);
        DepreciationBook.Validate("G/L Integration - Depreciation", GLIntegrationDepreciation);
        DepreciationBook.Validate("Compress Depreciation", CompressDepreciaton);
        DepreciationBook.Validate("Anticipated Depreciation Calc.", AnticipatedDepreciation);
        DepreciationBook.Validate("Acc./Red. Depreciation Calc.", AccRedDepreciation);
        DepreciationBook.Modify(true);

        // Create Journal Template & Batch.
        LibraryFixedAsset.CreateJournalTemplate(FAJournalTemplate);
        LibraryFixedAsset.CreateFAJournalBatch(FAJournalBatch, FAJournalTemplate.Name);
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        // Assign Template & Batch.
        LibraryFixedAsset.CreateFAJournalSetup(FAJournalSetup, DepreciationBook.Code, UserId);
        FAJournalSetup.Validate("FA Jnl. Template Name", FAJournalTemplate.Name);
        FAJournalSetup.Validate("FA Jnl. Batch Name", FAJournalBatch.Name);
        FAJournalSetup.Validate("Gen. Jnl. Template Name", GenJournalTemplate.Name);
        FAJournalSetup.Validate("Gen. Jnl. Batch Name", GenJournalBatch.Name);
        FAJournalSetup.Modify(true);

        exit(DepreciationBook.Code);
    end;

    local procedure CreateDepreciationTable(var DepreciationTableLine: Record "Depreciation Table Line"; Normal: Boolean; Anticipated: Boolean; AccReduced: Boolean)
    var
        DepreciationTableHeader: Record "Depreciation Table Header";
    begin
        LibraryFixedAsset.CreateDepreciationTableHeader(DepreciationTableHeader);
        LibraryFixedAsset.CreateDepreciationTableLine(DepreciationTableLine, DepreciationTableHeader.Code);
        if Normal then
            DepreciationTableLine.Validate("Period Depreciation %", LibraryRandom.RandInt(10));
        if Anticipated then
            DepreciationTableLine.Validate("Anticipated %", LibraryRandom.RandInt(10));
        if AccReduced then
            DepreciationTableLine.Validate("Accelerated/Reduced %", LibraryRandom.RandInt(10));
        DepreciationTableLine.Modify(true);
    end;

    local procedure CreateFA(var FixedAsset: Record "Fixed Asset"; DepreciationBook: Code[10]; FAPostingGroup: Code[20])
    begin
        Clear(FixedAsset);
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        CreateFADepreciationBook(FixedAsset."No.", DepreciationBook, FAPostingGroup);
    end;

    local procedure CreateFADepreciationBook(FANo: Code[20]; DepreciationBook: Code[10]; FAPostingGroup: Code[20])
    var
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FANo, DepreciationBook);
        FADepreciationBook.Validate("Depreciation Starting Date", CalcDate('<CM+1D>', WorkDate()));
        FADepreciationBook.Validate("No. of Depreciation Years", LibraryRandom.RandInt(5));
        FADepreciationBook.Validate("FA Posting Group", FAPostingGroup);
        FADepreciationBook.Modify(true);
    end;

    local procedure CreateFAPostingGroup(): Code[20]
    var
        FAPostingGroup: Record "FA Posting Group";
        FAPostingGroup2: Record "FA Posting Group";
    begin
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        GetFAPostingGroup(FAPostingGroup2);
        FAPostingGroup.Validate("Acquisition Cost Account", FAPostingGroup2."Acquisition Cost Account");
        FAPostingGroup.Validate("Accum. Depreciation Account", FAPostingGroup2."Accum. Depreciation Account");
        FAPostingGroup.Validate("Depreciation Expense Acc.", FAPostingGroup2."Depreciation Expense Acc.");
        FAPostingGroup.Validate("Custom 1 Account", CreateGLAccount());
        FAPostingGroup.Validate("Custom 1 Expense Acc.", CreateGLAccount());
        FAPostingGroup.Validate("Custom 2 Account", CreateGLAccount());
        FAPostingGroup.Validate("Custom 2 Expense Acc.", CreateGLAccount());
        FAPostingGroup.Modify(true);
        exit(FAPostingGroup.Code);
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        exit(GLAccount."No.");
    end;

    local procedure CreatePurchLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; DepreciationBook: Code[10]; FAPostingGroup: Code[20]; NoOfFACards: Integer): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
    begin
        CreateFA(FixedAsset, DepreciationBook, FAPostingGroup);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Fixed Asset", FixedAsset."No.", 1);
        UpdatePurchaseLine(PurchaseLine, DepreciationBook, NoOfFACards);
        exit(FixedAsset."No.");
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        exit(Vendor."No.");
    end;

    local procedure GetFAJournalLine(var FAJournalLine: Record "FA Journal Line"; DepreciationBook: Code[10])
    var
        FAJournalSetup: Record "FA Journal Setup";
    begin
        // Get Template and Batch from Depreciation Book.
        FAJournalSetup.Get(DepreciationBook, UserId);
        FAJournalLine.SetRange("Journal Template Name", FAJournalSetup."FA Jnl. Template Name");
        FAJournalLine.SetRange("Journal Batch Name", FAJournalSetup."FA Jnl. Batch Name");
        FAJournalLine.SetFilter(Amount, '<>0');
        if FAJournalLine.FindFirst() then;
    end;

    local procedure GetFAPostingGroup(var FAPostingGroup: Record "FA Posting Group"): Boolean
    begin
        FAPostingGroup.SetFilter("Acquisition Cost Account", '<>''''');
        FAPostingGroup.SetFilter("Accum. Depreciation Account", '<>''''');
        FAPostingGroup.SetFilter("Depreciation Expense Acc.", '<>''''');
        exit(FAPostingGroup.FindFirst())
    end;

    local procedure GetGenJournalLine(var GenJnlLine: Record "Gen. Journal Line"; DepreciationBook: Code[10]): Boolean
    var
        FAJournalSetup: Record "FA Journal Setup";
    begin
        FAJournalSetup.Get(DepreciationBook, UserId);
        GenJnlLine.SetRange("Journal Template Name", FAJournalSetup."Gen. Jnl. Template Name");
        GenJnlLine.SetRange("Journal Batch Name", FAJournalSetup."Gen. Jnl. Batch Name");
        GenJnlLine.SetFilter(Amount, '<>0');
        exit(GenJnlLine.FindFirst())
    end;

    local procedure ModifyDepreciationMethod(FANo: Code[20]; DepreciationBook: Code[10]; DepreciationMethod: Enum "FA Depreciation Method"; DepreciationTableCode: Code[10]; FirstUserDefinedDeprDate: Code[10])
    var
        FADepreciationBook: Record "FA Depreciation Book";
        Delta: DateFormula;
    begin
        Evaluate(Delta, FirstUserDefinedDeprDate);
        FADepreciationBook.Get(FANo, DepreciationBook);
        FADepreciationBook.Validate("Depreciation Method", DepreciationMethod);
        FADepreciationBook.Validate("Depreciation Table Code", DepreciationTableCode);
        FADepreciationBook.Validate("First User-Defined Depr. Date", CalcDate(Delta, FADepreciationBook."Depreciation Starting Date"));
        FADepreciationBook.Modify(true);
    end;

    local procedure PostAcqusitionCost(DepreciationBook: Code[10]; FAPostingGroup: Code[20])
    var
        FAJournalLine: Record "FA Journal Line";
        FixedAsset: Record "Fixed Asset";
    begin
        // Create Fixed Asset.
        CreateFA(FixedAsset, DepreciationBook, FAPostingGroup);

        // Get Template and Batch from Depreciation Book.
        GetFAJournalLine(FAJournalLine, DepreciationBook);
        // Create Line with Acquisition.
        LibraryERM.CreateFAJournalLine(
            FAJournalLine, FAJournalLine.GetFilter("Journal Template Name"), FAJournalLine.GetFilter("Journal Batch Name"), FAJournalLine."Document Type"::" ",
            FAJournalLine."FA Posting Type"::"Acquisition Cost", FixedAsset."No.", LibraryRandom.RandInt(10) * 10000);
        FAJournalLine.Validate("Depreciation Book Code", DepreciationBook);
        FAJournalLine.Validate("FA Posting Group", FAPostingGroup);
        FAJournalLine.Validate("Document No.", FixedAsset."No." + '-' + Format(Date2DMY(WorkDate(), 2)) + '-' + Format(Date2DMY(WorkDate(), 3)));
        FAJournalLine.Modify(true);

        // Post FA Journal Lines.
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
    end;

    local procedure PostDepreciation(DepreciationBook: Code[10]; GLIntegration: Boolean) DocumentNo: Code[20]
    var
        FAJournalLine: Record "FA Journal Line";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        // Get Template and Batch from Depreciation Book.
        // Post Journal Lines.
        if GLIntegration then begin
            GetGenJournalLine(GenJnlLine, DepreciationBook);
            DocumentNo := GenJnlLine."Document No.";
            LibraryERM.PostGeneralJnlLine(GenJnlLine);
        end else begin
            GetFAJournalLine(FAJournalLine, DepreciationBook);
            DocumentNo := FAJournalLine."Document No.";
            LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
        end;
    end;

    local procedure VerifyUserDefinedDepreciation(DocumentNo: Code[20]; FANo: Code[20]; FAPostingType: Enum "FA Ledger Entry FA Posting Type"; Amount: Decimal)
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        FALedgerEntry.SetFilter("Document No.", DocumentNo);
        FALedgerEntry.SetFilter("FA No.", FANo);
        FALedgerEntry.SetRange("FA Posting Type", FAPostingType);
        FALedgerEntry.FindFirst();
        FALedgerEntry.TestField(Amount, -Amount);
    end;

    local procedure VerifyGLEntryCompression(DocumentNo: Code[20]; Compressed: Boolean)
    var
        GLEntry: Record "G/L Entry";
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        GLEntry.SetCurrentKey("Transaction No.", "G/L Account No.", "Document No.", Positive, "Source Type", "Source No.");
        GLEntry.SetFilter("Document No.", DocumentNo);
        GLEntry.SetRange(Positive, true);
        FALedgerEntry.SetCurrentKey("Document Type", "Document No.");
        FALedgerEntry.SetFilter("Document No.", DocumentNo);
        FALedgerEntry.CalcSums(Amount);

        if Compressed then begin
            VerifyNoGLEntriesPosted(DocumentNo, 1);
            GLEntry.FindFirst();
        end else begin
            VerifyNoGLEntriesPosted(DocumentNo, FALedgerEntry.Count);
            GLEntry.CalcSums(Amount);
        end;
        GLEntry.TestField(Amount, -FALedgerEntry.Amount);
    end;

    local procedure VerifyNoGLEntriesPosted(DocumentNo: Code[20]; "Count": Integer)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetFilter("Document No.", DocumentNo);
        GLEntry.SetRange(Positive, true);
        Assert.AreEqual(Count, GLEntry.Count, StrSubstNo(IncorrectNumberOfEntries, GLEntry.TableCaption()));
    end;

    local procedure UpdatePurchaseLine(var PurchaseLine: Record "Purchase Line"; DepreciationBook: Code[10]; NoOfFixedAssetCards: Integer)
    begin
        PurchaseLine.Validate("Depreciation Book Code", DepreciationBook);
        PurchaseLine.Validate("No. of Fixed Asset Cards", NoOfFixedAssetCards);
        if NoOfFixedAssetCards > PurchaseLine.Quantity then
            PurchaseLine.Validate("Direct Unit Cost", NoOfFixedAssetCards * LibraryRandom.RandInt(10) * 10000) // Cost is not important.
        else
            PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(10) * 10000); // Cost is not important.
        PurchaseLine.Modify(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure PostConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        if 0 <> StrPos(Question, CompletionStatsTok) then
            Reply := false
        else
            Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure PostConfirmMessage(Message: Text[1024])
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalculateDepreciationPageHandler(var CalculateDepreciation: TestRequestPage "Calculate Depreciation")
    begin
        RunCalculateDepreciation(
          CalculateDepreciation, DepreciationBookCode, CalcDate('<CM+1Y>', WorkDate()), true, UseAnticipatedDepr, UseAccDecrDepr);
        CalculateDepreciation.OK().Invoke();
    end;

    [Normal]
    local procedure CalculateTotalDepreciation(GoToPrevLine: Boolean)
    var
        i: Integer;
        LinesQty: Integer;
        DepreciationTableCardPage: TestPage "Depreciation Table Card";
        DepreciationTableCode: Code[10];
        DeprPercent: Decimal;
        AntPercent: Decimal;
        AccRedPercent: Decimal;
        TotalDepr: Decimal;
        TotalDeprValue: Decimal;
    begin
        Initialize();

        // Setting random quantity to number of lines in Depreciation Table
        LinesQty := LibraryRandom.RandInt(10);

        DepreciationTableCode := LibraryUtility.GenerateGUID();

        TotalDepr := 0;

        // Creating new Depreciation Table
        DepreciationTableCardPage.OpenNew();
        DepreciationTableCardPage.Code.SetValue(DepreciationTableCode);

        for i := 1 to LinesQty do begin
            DeprPercent := LibraryRandom.RandDecInDecimalRange(1.0, 10.0, 2);
            AntPercent := LibraryRandom.RandDecInDecimalRange(0.0, DeprPercent / 2, 2);
            AccRedPercent := LibraryRandom.RandDecInDecimalRange(0.0, DeprPercent / 2, 2);
            CreateDepreciationTableLinesPage(DepreciationTableCardPage, DeprPercent, AntPercent, AccRedPercent);
            TotalDepr += DeprPercent + AntPercent + AccRedPercent;
        end;

        if GoToPrevLine then
            // Going on the previous line
            DepreciationTableCardPage.SubFormDeprTableLines.Previous();

        // Getting "Total Depreciation %" value from Page
        Evaluate(TotalDeprValue, DepreciationTableCardPage.SubFormDeprTableLines.TotalDepreciationPct.Value);

        // Check that the value, calculated earlier, is equal to the value from Page
        Assert.AreEqual(TotalDepr, TotalDeprValue, TotalDepreciationCalcError);
        DepreciationTableCardPage.Close();
    end;

    [Normal]
    local procedure CreateDepreciationTableLinesPage(var DepreciationTableCardPage: TestPage "Depreciation Table Card"; DeprPercent: Decimal; AntPercent: Decimal; AccRedPercent: Decimal)
    begin
        DepreciationTableCardPage.SubFormDeprTableLines."Period Depreciation %".SetValue(DeprPercent);
        DepreciationTableCardPage.SubFormDeprTableLines."Anticipated %".SetValue(AntPercent);
        DepreciationTableCardPage.SubFormDeprTableLines."Accelerated/Reduced %".SetValue(AccRedPercent);

        DepreciationTableCardPage.SubFormDeprTableLines.Next();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure DepreciationCalcConfirmHandler(Message: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;
}

