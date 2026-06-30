codeunit 134920 "ERM General Journal UT"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [General Journal] [UT]
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryERM: Codeunit "Library - ERM";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryJournals: Codeunit "Library - Journals";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        Assert: Codeunit Assert;
        GenJnlManagement: Codeunit GenJnlManagement;
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryVariableStorageCounter: Codeunit "Library - Variable Storage";
        IsInitialized: Boolean;
        DocNoFilterErr: Label 'The document numbers cannot be renumbered while there is an active filter on the Document No. field.';
        WrongJobQueueStatus: Label 'Journal line cannot be modified because it has been scheduled for posting.';
        WrongFieldVisibilityErr: Label 'Wrong field visiblity';
        CannotBeSpecifiedForRecurrJnlErr: Label 'cannot be specified when using recurring journals';
        GenJournalBatchFromGenJournalLineErr: Label 'General Journal must be opened with a Journal Batch that is equal to GenJournalLine."Journal Batch Name"';
        MustSelectAndEmailBodyOrAttahmentErr: Label 'You must select an email body or attachment in report selection';
        RecordDoesNotMatchErr: Label 'The record that will be sent does not match the original record. The original record was changed or deleted.';
        VATAmountLCYErr: Label 'Invalid VAT Amount LCY';
        GenJouranlLinePostedMsg: Label 'The journal lines were successfully posted.';
        NoSeriesLineStartDateErr: Label 'Starting Date not updated.';

    [Test]
    [Scope('OnPrem')]
    procedure DefaultDescriptionWithAccountNo()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        GLAccount2: Record "G/L Account";
    begin
        Initialize();
        // Setup
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGLAccount(GLAccount2);
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", GLAccount."No.",
          GenJournalLine."Account Type"::"G/L Account", '', '');
        GenJournalLine.TestField(Description, GLAccount.Name);
        // Execute
        GenJournalLine.Validate("Account No.", GLAccount2."No.");
        // Verify
        GenJournalLine.TestField(Description, GLAccount2.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdHocDescriptionWithGLAccountNo()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        GLAccount2: Record "G/L Account";
        AdHocDescription: Code[50];
    begin
        Initialize();
        // Setup
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGLAccount(GLAccount2);
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", GLAccount."No.",
          GenJournalLine."Account Type"::"G/L Account", '', '');
        GenJournalLine.TestField(Description, GLAccount.Name);
        UpdateDescriptionAdHoc(GenJournalLine, AdHocDescription);
        // Execute
        GenJournalLine.Validate("Account No.", GLAccount2."No.");
        // Verify
        GenJournalLine.TestField(Description, AdHocDescription);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdHocDescriptionWithCustomerNo()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        Customer2: Record Customer;
        AdHocDescription: Code[50];
    begin
        Initialize();
        // Setup
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomer(Customer2);
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::Customer, Customer."No.",
          GenJournalLine."Account Type"::"G/L Account", '', '');
        GenJournalLine.TestField(Description, Customer.Name);
        UpdateDescriptionAdHoc(GenJournalLine, AdHocDescription);
        // Execute
        GenJournalLine.Validate("Account No.", Customer2."No.");
        // Verify
        GenJournalLine.TestField(Description, AdHocDescription);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdHocDescriptionWithVendorNo()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        Vendor2: Record Vendor;
        AdHocDescription: Code[50];
    begin
        Initialize();
        // Setup
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateVendor(Vendor2);
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::Vendor, Vendor."No.",
          GenJournalLine."Account Type"::"G/L Account", '', '');
        GenJournalLine.TestField(Description, Vendor.Name);
        UpdateDescriptionAdHoc(GenJournalLine, AdHocDescription);
        // Execute
        GenJournalLine.Validate("Account No.", Vendor2."No.");
        // Verify
        GenJournalLine.TestField(Description, AdHocDescription);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdHocDescriptionWithBankAccountNo()
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        BankAccount2: Record "Bank Account";
        AdHocDescription: Code[50];
    begin
        Initialize();
        // Setup
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryERM.CreateBankAccount(BankAccount2);
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"Bank Account", BankAccount."No.",
          GenJournalLine."Account Type"::"G/L Account", '', '');
        GenJournalLine.TestField(Description, BankAccount.Name);
        UpdateDescriptionAdHoc(GenJournalLine, AdHocDescription);
        // Execute
        GenJournalLine.Validate("Account No.", BankAccount2."No.");
        // Verify
        GenJournalLine.TestField(Description, AdHocDescription);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdHocDescriptionWithFixedAssetNo()
    var
        GenJournalLine: Record "Gen. Journal Line";
        FixedAsset: Record "Fixed Asset";
        FixedAsset2: Record "Fixed Asset";
        AdHocDescription: Code[50];
    begin
        Initialize();
        // Setup
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        LibraryFixedAsset.CreateFixedAsset(FixedAsset2);
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"Fixed Asset", FixedAsset."No.",
          GenJournalLine."Account Type"::"G/L Account", '', '');
        GenJournalLine.TestField(Description, FixedAsset.Description);
        UpdateDescriptionAdHoc(GenJournalLine, AdHocDescription);
        // Execute
        GenJournalLine.Validate("Account No.", FixedAsset2."No.");
        // Verify
        GenJournalLine.TestField(Description, AdHocDescription);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdHocDescriptionWithICPartnerNo()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        ICPartner: Record "IC Partner";
        ICPartner2: Record "IC Partner";
        AdHocDescription: Code[50];
    begin
        Initialize();
        // Setup
        LibraryERM.CreateICPartner(ICPartner);
        LibraryERM.CreateICPartner(ICPartner2);

        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Type := GenJournalTemplate.Type::Intercompany;
        GenJournalTemplate.Modify(true);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLine2(GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"IC Partner", ICPartner.Code, LibraryRandom.RandDec(100, 2));

        GenJournalLine.TestField(Description, ICPartner.Name);
        UpdateDescriptionAdHoc(GenJournalLine, AdHocDescription);
        // Execute
        GenJournalLine.Validate("Account No.", ICPartner2.Code);
        // Verify
        GenJournalLine.TestField(Description, AdHocDescription);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdHocDescriptionWithBlankAccountNo()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        AdHocDescription: Code[50];
    begin
        Initialize();
        // Setup
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", '',
          GenJournalLine."Account Type"::"G/L Account", '', '');
        GenJournalLine.Validate("Bal. Account No.", '');
        GenJournalLine.TestField(Description, '');
        UpdateDescriptionAdHoc(GenJournalLine, AdHocDescription);
        // Execute
        LibraryERM.CreateGLAccount(GLAccount);
        GenJournalLine.Validate("Account No.", GLAccount."No.");
        // Verify
        GenJournalLine.TestField(Description, AdHocDescription);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlankDescriptionWithBlankAccountNo()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
    begin
        Initialize();
        // Setup
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", '',
          GenJournalLine."Account Type"::"G/L Account", '', '');
        GenJournalLine.TestField(Description, '');
        // Execute
        LibraryERM.CreateGLAccount(GLAccount);
        GenJournalLine.Validate("Account No.", GLAccount."No.");
        // Verify
        GenJournalLine.TestField(Description, GLAccount.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure KeepDescriptionWithBlankAccountNo()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
    begin
        Initialize();
        // Setup
        LibraryERM.CreateGLAccount(GLAccount);
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", GLAccount."No.",
          GenJournalLine."Account Type"::"G/L Account", '', '');
        GenJournalLine.TestField(Description, GLAccount.Name);
        // Execute
        GenJournalLine.Validate("Account No.", '');
        // Verify
        GenJournalLine.TestField(Description, GLAccount.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlankFieldsWithChangedAccountType()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
    begin
        // [SCENARIO 372248] Description field is updated in a Gen. Journal Line when Account Type is changed
        Initialize();

        // [GIVEN] Customer with VAT Registration No.
        LibrarySales.CreateCustomerWithVATRegNo(Customer);

        // [GIVEN] General Journal Line with Customer
        CreateGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::Customer, Customer."No.",
          GenJournalLine."Account Type"::"G/L Account", '', '');
        // [GIVEN] Description field has non-empty value.
        GenJournalLine.Validate(Description, LibraryUtility.GenerateGUID());

        // [WHEN] Account Type is changed to Vendor.
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::Vendor);

        // [THEN] Description field is empty.
        GenJournalLine.TestField(Description, '');
        // [THEN] Fields "Bill-to/Pay-to No.","Ship-to/Order Address Code","Sell-to/Buy-from No.","Country/Region Code","VAT Registration No."
        VerifyGenJnlLineFieldsAreBlank(GenJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlankFieldsWithChangedAccountNo()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
    begin
        // [SCENARIO 372248] Description field is updated in a Gen. Journal Line when Account No is changed
        Initialize();

        // [GIVEN] Customer with VAT Registration No.
        LibrarySales.CreateCustomerWithVATRegNo(Customer);

        // [GIVEN] General Journal Line with Customer
        CreateGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::Customer, Customer."No.",
          GenJournalLine."Account Type"::"G/L Account", '', '');
        // [GIVEN] Description has not empty value.
        GenJournalLine.Validate(Description, LibraryUtility.GenerateGUID());

        // [WHEN] Account No. is changed to empty.
        GenJournalLine.Validate("Account No.", '');

        // [THEN] Fields "Bill-to/Pay-to No.","Ship-to/Order Address Code","Sell-to/Buy-from No.","Country/Region Code","VAT Registration No." are empty
        VerifyGenJnlLineFieldsAreBlank(GenJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AppliesToExtDocNoOnApplyCustLedgEntry()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        Initialize();

        // Setup
        FindOpenCustLedgEntryAndSetExtDoc(CustLedgEntry);
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::Customer, CustLedgEntry."Customer No.",
          GenJournalLine."Account Type"::"G/L Account", '', '');

        // Execute
        GenJournalLine.Validate("Applies-to Doc. Type", CustLedgEntry."Document Type");
        GenJournalLine.Validate("Applies-to Doc. No.", CustLedgEntry."Document No.");

        // Verify
        GenJournalLine.TestField("Applies-to Ext. Doc. No.", CustLedgEntry."External Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AppliesToExtDocNoOnApplyVendLedgEntry()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        Initialize();

        // Setup
        FindOpenVendLedgEntry(VendLedgEntry);
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::Vendor, VendLedgEntry."Vendor No.",
          GenJournalLine."Account Type"::"G/L Account", '', '');

        // Execute
        GenJournalLine.Validate("Posting Date", VendLedgEntry."Posting Date");
        GenJournalLine.Validate("Applies-to Doc. Type", VendLedgEntry."Document Type");
        GenJournalLine.Validate("Applies-to Doc. No.", VendLedgEntry."Document No.");

        // Verify
        GenJournalLine.TestField("Applies-to Ext. Doc. No.", VendLedgEntry."External Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ClearAppliesToExtDocNoOnClearApplyCustLedgEntry()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        Initialize();

        // Setup
        FindOpenCustLedgEntryAndSetExtDoc(CustLedgEntry);
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::Customer, CustLedgEntry."Customer No.",
          GenJournalLine."Account Type"::"G/L Account", '', '');
        GenJournalLine.Validate("Applies-to Doc. Type", CustLedgEntry."Document Type");
        GenJournalLine.Validate("Applies-to Doc. No.", CustLedgEntry."Document No.");

        // Execute
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::" ");
        GenJournalLine.Validate("Applies-to Doc. No.", '');

        // Verify
        GenJournalLine.TestField("Applies-to Ext. Doc. No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ClearAppliesToExtDocNoOnClearApplyVendLedgEntry()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        Initialize();

        // Setup
        FindOpenVendLedgEntry(VendLedgEntry);
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::Vendor, VendLedgEntry."Vendor No.",
          GenJournalLine."Account Type"::"G/L Account", '', '');
        GenJournalLine.Validate("Posting Date", VendLedgEntry."Posting Date");
        GenJournalLine.Validate("Applies-to Doc. Type", VendLedgEntry."Document Type");
        GenJournalLine.Validate("Applies-to Doc. No.", VendLedgEntry."Document No.");

        // Execute
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::" ");
        GenJournalLine.Validate("Applies-to Doc. No.", '');

        // Verify
        GenJournalLine.TestField("Applies-to Ext. Doc. No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GeneralJournalBalFieldValidation()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        Initialize();

        // Setup
        BankExportImportSetup.Init();
        BankExportImportSetup.Code := CopyStr(Format(CreateGuid()), 1, MaxStrLen(BankExportImportSetup.Code));
        BankExportImportSetup.Direction := BankExportImportSetup.Direction::Import;
        if not BankExportImportSetup.Insert() then
            BankExportImportSetup.Modify();
        GenJournalBatch.Init();
        GenJournalBatch."Bank Statement Import Format" := BankExportImportSetup.Code;
        GenJournalBatch."Bal. Account No." := CopyStr(Format(CreateGuid()), 1, MaxStrLen(GenJournalBatch."Bal. Account No."));

        // Execute
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"Bank Account");

        // Verify
        GenJournalBatch.TestField("Bank Statement Import Format", '');
        GenJournalBatch.TestField("Bal. Account No.", '');
        asserterror GenJournalBatch.Validate("Bank Statement Import Format", BankExportImportSetup.Code);
        asserterror GenJournalBatch.Validate(
            "Bank Statement Import Format", CopyStr(Format(CreateGuid()), 1, MaxStrLen(BankExportImportSetup.Code)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GeneralJournalBankStmtFormatFieldValidation()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        Initialize();

        // Setup
        BankExportImportSetup.Init();
        BankExportImportSetup.Code := CopyStr(Format(CreateGuid()), 1, MaxStrLen(BankExportImportSetup.Code));
        BankExportImportSetup.Direction := BankExportImportSetup.Direction::Export;
        if not BankExportImportSetup.Insert() then
            BankExportImportSetup.Modify();

        GenJournalBatch.Init();

        // Execute
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"G/L Account");

        // Verify
        asserterror GenJournalBatch.Validate("Bank Statement Import Format", BankExportImportSetup.Code);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure NoRenumberDocNoWithoutNoSeries()
    var
        GLAccount: Record "G/L Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        NewDocNo: Code[20];
    begin
        Initialize();

        // Setup
        LibraryERM.CreateGLAccount(GLAccount);
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", GLAccount."No.",
          GenJournalLine."Account Type"::"G/L Account", '', '');
        NewDocNo := SetNewDocNo(GenJournalLine);

        // Exercise
        asserterror GenJournalLine.RenumberDocumentNo();
        Assert.ExpectedTestFieldError(GenJournalBatch.FieldCaption("No. Series"), Format(0));
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure RenumberDocNoOneLine()
    var
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        OldDocNo: Code[20];
    begin
        Initialize();

        // Setup
        LibraryERM.CreateGLAccount(GLAccount);
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", GLAccount."No.",
          GenJournalLine."Account Type"::"G/L Account", '', LibraryERM.CreateNoSeriesCode());
        OldDocNo := GenJournalLine."Document No.";
        SetNewDocNo(GenJournalLine);

        // Exercise
        Commit();
        GenJournalLine.RenumberDocumentNo();

        // Verify
        VerifyGenJnlLineDocNo(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
          GenJournalLine."Line No.", OldDocNo);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure RenumberDocNoMultipleLines()
    var
        GLAccount: Record "G/L Account";
        GLAccount2: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        NoSeries: Codeunit "No. Series";
        NoSeriesCode: Code[20];
        NewDocNo: Code[20];
    begin
        Initialize();

        // Setup
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGLAccount(GLAccount2);
        NoSeriesCode := LibraryERM.CreateNoSeriesCode();
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", GLAccount."No.",
          GenJournalLine."Account Type"::"G/L Account", GLAccount2."No.", NoSeriesCode);
        SetNewDocNo(GenJournalLine);
        CreateSingleLineGenJnlDoc(GenJournalLine, GenJournalLine."Account Type"::"G/L Account", GLAccount."No.");
        SetNewDocNo(GenJournalLine);
        CreateSingleLineGenJnlDoc(GenJournalLine, GenJournalLine."Account Type"::"G/L Account", GLAccount."No.");
        SetNewDocNo(GenJournalLine);

        // Exercise
        Commit();
        GenJournalLine.RenumberDocumentNo();

        // Verify
        NewDocNo := NoSeries.PeekNextNo(NoSeriesCode);
        VerifyGenJnlLineDocNo(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
          10000, NewDocNo);
        VerifyGenJnlLineDocNo(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
          20000, IncStr(NewDocNo));
        VerifyGenJnlLineDocNo(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
          30000, IncStr(IncStr(NewDocNo)));
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure RenumberDocNoMultipleLinesWithBalanceLine()
    var
        GLAccount: Record "G/L Account";
        GLAccount2: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        NoSeries: Codeunit "No. Series";
        NoSeriesCode: Code[20];
        NewDocNo: Code[20];
    begin
        Initialize();

        // Setup
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGLAccount(GLAccount2);

        NoSeriesCode := LibraryERM.CreateNoSeriesCode();

        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", GLAccount."No.",
          GenJournalLine."Account Type"::"G/L Account", GLAccount2."No.", NoSeriesCode);
        SetNewDocNo(GenJournalLine);
        CreateMultiLineGenJnlDoc(GenJournalLine, GLAccount."No.", GLAccount2."No.");
        CreateSingleLineGenJnlDoc(GenJournalLine, GenJournalLine."Account Type"::"G/L Account", GLAccount."No.");
        SetNewDocNo(GenJournalLine);

        // Exercise
        Commit();
        GenJournalLine.RenumberDocumentNo();

        // Verify
        NewDocNo := NoSeries.PeekNextNo(NoSeriesCode);
        VerifyGenJnlLineDocNo(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
          10000, NewDocNo);
        VerifyGenJnlLineDocNo(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
          20000, IncStr(NewDocNo));
        VerifyGenJnlLineDocNo(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
          30000, IncStr(NewDocNo)); // same doc no as line 20000
        VerifyGenJnlLineDocNo(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
          40000, IncStr(IncStr(NewDocNo)));
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure RenumberDocNoMultipleLinesWithFilter()
    var
        GLAccount: Record "G/L Account";
        GLAccount2: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        NoSeries: Codeunit "No. Series";
        NoSeriesCode: Code[20];
        NewDocNo: Code[20];
    begin
        Initialize();

        // Setup
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGLAccount(GLAccount2);

        NoSeriesCode := LibraryERM.CreateNoSeriesCode();

        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", GLAccount."No.",
          GenJournalLine."Account Type"::"G/L Account", GLAccount2."No.", NoSeriesCode);
        CreateMultiLineGenJnlDoc(GenJournalLine, GLAccount."No.", GLAccount2."No.");
        CreateSingleLineGenJnlDoc(GenJournalLine, GenJournalLine."Account Type"::"G/L Account", GLAccount."No.");

        // Exercise
        Commit();
        GenJournalLine.SetRange("Line No.", 20000, 30000);
        GenJournalLine.RenumberDocumentNo();

        // Verify
        NewDocNo := NoSeries.PeekNextNo(NoSeriesCode);
        VerifyGenJnlLineDocNo(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
          20000, NewDocNo); // line 20000 is now first doc
        VerifyGenJnlLineDocNo(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
          30000, NewDocNo); // same doc no as line 20000
        VerifyGenJnlLineDocNo(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
          10000, IncStr(NewDocNo));
        VerifyGenJnlLineDocNo(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
          40000, IncStr(IncStr(NewDocNo)));
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure RenumberDocNoWithFilterError()
    var
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        NoSeriesCode: Code[20];
    begin
        Initialize();

        // Setup
        LibraryERM.CreateGLAccount(GLAccount);
        NoSeriesCode := LibraryERM.CreateNoSeriesCode();
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", GLAccount."No.",
          GenJournalLine."Account Type"::"G/L Account", '', NoSeriesCode);

        // Exercise
        Commit();
        GenJournalLine.SetRange("Document No.", GenJournalLine."Document No.");
        asserterror GenJournalLine.RenumberDocumentNo();

        // Verify
        Assert.ExpectedError(DocNoFilterErr);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure RenumberDocNoOneLineWithAppliesToIdVendor()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        OldDocNo: Code[20];
        EntryNo: Integer;
    begin
        Initialize();

        // Setup
        LibraryPurchase.CreateVendor(Vendor);
        EntryNo := CreateGenJournalLineWithVendEntry(GenJournalLine, LibraryERM.CreateNoSeriesCode(), Vendor."No.", '');
        OldDocNo := GenJournalLine."Document No.";
        SetNewDocNo(GenJournalLine);

        // Exercise
        Commit();
        GenJournalLine.RenumberDocumentNo();

        // Verify
        VerifyGenJnlDocNoAndAppliesToIDVend(GenJournalLine, GenJournalLine."Line No.", EntryNo, OldDocNo);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure RenumberDocNoMultipleLinesWithAppliesToIdVendor()
    var
        Vendor: Record Vendor;
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        NoSeries: Codeunit "No. Series";
        NoSeriesCode: Code[20];
        NewDocNo: Code[20];
        EntryNo: Integer;
    begin
        Initialize();

        // Setup
        LibraryPurchase.CreateVendor(Vendor);
        LibraryERM.CreateGLAccount(GLAccount);
        NoSeriesCode := LibraryERM.CreateNoSeriesCode();
        EntryNo := CreateGenJournalLineWithVendEntry(GenJournalLine, NoSeriesCode, Vendor."No.", GLAccount."No.");
        CreateSingleLineGenJnlDocAndVendEntry(GenJournalLine, Vendor."No.");
        CreateSingleLineGenJnlDocAndVendEntry(GenJournalLine, Vendor."No.");

        // Exercise
        Commit();
        GenJournalLine.RenumberDocumentNo();

        // Verify
        NewDocNo := NoSeries.PeekNextNo(NoSeriesCode);
        VerifyGenJnlDocNoAndAppliesToIDVend(GenJournalLine, 10000, EntryNo, NewDocNo);
        VerifyGenJnlDocNoAndAppliesToIDVend(GenJournalLine, 20000, EntryNo + 1, IncStr(NewDocNo));
        VerifyGenJnlDocNoAndAppliesToIDVend(GenJournalLine, 30000, EntryNo + 2, IncStr(IncStr(NewDocNo)));
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure RenumberDocNoOneLineWithAppliesToIdCustomer()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        OldDocNo: Code[20];
        EntryNo: Integer;
    begin
        Initialize();

        // Setup
        LibrarySales.CreateCustomer(Customer);
        EntryNo := CreateGenJournalLineWithCustEntry(GenJournalLine, LibraryERM.CreateNoSeriesCode(), Customer."No.", '');
        OldDocNo := GenJournalLine."Document No.";
        SetNewDocNo(GenJournalLine);

        // Exercise
        Commit();
        GenJournalLine.RenumberDocumentNo();

        // Verify
        VerifyGenJnlDocNoAndAppliesToIDCust(GenJournalLine, GenJournalLine."Line No.", EntryNo, OldDocNo);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure RenumberDocNoMultipleLinesWithAppliesToIdCustomer()
    var
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        NoSeries: Codeunit "No. Series";
        NoSeriesCode: Code[20];
        NewDocNo: Code[20];
        EntryNo: Integer;
    begin
        Initialize();

        // Setup
        LibrarySales.CreateCustomer(Customer);
        LibraryERM.CreateGLAccount(GLAccount);
        NoSeriesCode := LibraryERM.CreateNoSeriesCode();
        EntryNo := CreateGenJournalLineWithCustEntry(GenJournalLine, NoSeriesCode, Customer."No.", GLAccount."No.");
        CreateSingleLineGenJnlDocAndCustEntry(GenJournalLine, Customer."No.");
        CreateSingleLineGenJnlDocAndCustEntry(GenJournalLine, Customer."No.");

        // Exercise
        Commit();
        GenJournalLine.RenumberDocumentNo();

        // Verify
        NewDocNo := NoSeries.PeekNextNo(NoSeriesCode);
        VerifyGenJnlDocNoAndAppliesToIDCust(GenJournalLine, 10000, EntryNo, NewDocNo);
        VerifyGenJnlDocNoAndAppliesToIDCust(GenJournalLine, 20000, EntryNo + 1, IncStr(NewDocNo));
        VerifyGenJnlDocNoAndAppliesToIDCust(GenJournalLine, 30000, EntryNo + 2, IncStr(IncStr(NewDocNo)));
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure RenumberDocNoOneLineWithAppliesToDocNo()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        Vendor: Record Vendor;
        NoSeries: Codeunit "No. Series";
        NoSeriesCode: Code[20];
        AppliesToDocNo: Code[20];
        NewDocNo: Code[20];
    begin
        Initialize();

        // Setup
        LibraryPurchase.CreateVendor(Vendor);
        LibraryERM.CreateGLAccount(GLAccount);
        NoSeriesCode := LibraryERM.CreateNoSeriesCode();
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::Vendor, Vendor."No.",
          GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", NoSeriesCode);
        GenJournalLine."Document Type" := GenJournalLine."Document Type"::Invoice;
        AppliesToDocNo := SetNewDocNo(GenJournalLine);
        CreateSingleLinePayment(GenJournalLine, Vendor."No.", AppliesToDocNo);

        // Exercise
        Commit();
        GenJournalLine.RenumberDocumentNo();

        // Verify
        NewDocNo := NoSeries.PeekNextNo(NoSeriesCode);
        VerifyGenJnlLineDocNo(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", 10000,
          NewDocNo);
        VerifyGenJnlLineDocNoAndAppliesToDocNo(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", 20000,
          IncStr(NewDocNo), NewDocNo);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure RenumberDocNoMultipleLinesWithAppliesToDocNo()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        Vendor: Record Vendor;
        NoSeries: Codeunit "No. Series";
        NoSeriesCode: Code[20];
        AppliesToDocNo: Code[20];
        NewDocNo: Code[20];
    begin
        Initialize();

        // Setup
        LibraryPurchase.CreateVendor(Vendor);
        LibraryERM.CreateGLAccount(GLAccount);
        NoSeriesCode := LibraryERM.CreateNoSeriesCode();
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::Vendor, Vendor."No.",
          GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", NoSeriesCode);
        GenJournalLine."Document Type" := GenJournalLine."Document Type"::Invoice;
        AppliesToDocNo := SetNewDocNo(GenJournalLine);
        CreateSingleLinePayment(GenJournalLine, Vendor."No.", AppliesToDocNo);

        AppliesToDocNo := CreateSingleLineInvoice(GenJournalLine, Vendor."No.");
        CreateSingleLinePayment(GenJournalLine, Vendor."No.", AppliesToDocNo);

        // Exercise
        Commit();
        GenJournalLine.RenumberDocumentNo();

        // Verify
        NewDocNo := NoSeries.PeekNextNo(NoSeriesCode); // GU00000000
        VerifyGenJnlLineDocNo(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", 10000,
          NewDocNo);

        AppliesToDocNo := NewDocNo; // GU00000000
        NewDocNo := IncStr(NewDocNo); // GU00000001
        VerifyGenJnlLineDocNoAndAppliesToDocNo(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", 20000,
          NewDocNo, AppliesToDocNo);

        NewDocNo := IncStr(NewDocNo); // GU00000002
        VerifyGenJnlLineDocNo(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", 30000,
          NewDocNo);

        AppliesToDocNo := NewDocNo; // GU00000002
        NewDocNo := IncStr(NewDocNo); // GU00000003
        VerifyGenJnlLineDocNoAndAppliesToDocNo(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", 40000,
          NewDocNo, AppliesToDocNo);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure RenumberDocNoWithSortingOnDocNo()
    var
        GLAccount: Record "G/L Account";
        GLAccount2: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        NoSeries: Codeunit "No. Series";
        NoSeriesCode: Code[20];
        NewDocNo: Code[20];
    begin
        Initialize();

        // Setup
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGLAccount(GLAccount2);
        NoSeriesCode := LibraryERM.CreateNoSeriesCode();
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", GLAccount."No.",
          GenJournalLine."Account Type"::"G/L Account", GLAccount2."No.", NoSeriesCode);
        GenJournalLine."Document No." := 'C';
        GenJournalLine.Modify();
        CreateSingleLineGenJnlDoc(GenJournalLine, GenJournalLine."Account Type"::"G/L Account", GLAccount."No.");
        GenJournalLine."Document No." := 'A';
        GenJournalLine.Modify();
        CreateSingleLineGenJnlDoc(GenJournalLine, GenJournalLine."Account Type"::"G/L Account", GLAccount."No.");
        GenJournalLine."Document No." := 'B';
        GenJournalLine.Modify();

        // Exercise
        Commit();
        GenJournalLine.SetCurrentKey("Document No.");
        GenJournalLine.RenumberDocumentNo();

        // Verify
        NewDocNo := NoSeries.PeekNextNo(NoSeriesCode);
        VerifyGenJnlLineDocNo(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
          20000, NewDocNo);
        VerifyGenJnlLineDocNo(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
          30000, IncStr(NewDocNo));
        VerifyGenJnlLineDocNo(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
          10000, IncStr(IncStr(NewDocNo)));
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure RenumberDocNoWithSortingOnDate()
    var
        GLAccount: Record "G/L Account";
        GLAccount2: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        NoSeries: Codeunit "No. Series";
        NoSeriesCode: Code[20];
        NewDocNo: Code[20];
    begin
        Initialize();

        // Setup
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGLAccount(GLAccount2);
        NoSeriesCode := LibraryERM.CreateNoSeriesCode();
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", GLAccount."No.",
          GenJournalLine."Account Type"::"G/L Account", GLAccount2."No.", NoSeriesCode);
        GenJournalLine."Posting Date" := CalcDate('<-2D>', GenJournalLine."Posting Date");
        GenJournalLine.Modify();
        CreateSingleLineGenJnlDoc(GenJournalLine, GenJournalLine."Account Type"::"G/L Account", GLAccount."No.");
        GenJournalLine."Posting Date" := CalcDate('<-4D>', GenJournalLine."Posting Date");
        GenJournalLine.Modify();
        CreateSingleLineGenJnlDoc(GenJournalLine, GenJournalLine."Account Type"::"G/L Account", GLAccount."No.");

        // Exercise
        Commit();
        GenJournalLine.SetCurrentKey("Journal Template Name", "Journal Batch Name", "Posting Date");
        GenJournalLine.RenumberDocumentNo();

        // Verify
        NewDocNo := NoSeries.PeekNextNo(NoSeriesCode);
        VerifyGenJnlLineDocNo(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
          10000, NewDocNo);
        VerifyGenJnlLineDocNo(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
          20000, IncStr(NewDocNo));
        VerifyGenJnlLineDocNo(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
          30000, IncStr(IncStr(NewDocNo)));
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure RenumberDocNoMultipleLinesWhenGenJnlLineDeleted()
    var
        Vendor: Record Vendor;
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        NoSeries: Codeunit "No. Series";
        NoSeriesCode: Code[20];
        NewDocNo: Code[20];
        EntryNo: Integer;
        LineNoToDelete: Integer;
        LastLineNo: Integer;
    begin
        // Test create several General Journal Lines and deletes second line. Then test runs Renumber Document No
        // and checks Vendor Ledger Entries for last line also have new "Applies-to ID" field.
        Initialize();

        // Setup
        LibraryPurchase.CreateVendor(Vendor);
        LibraryERM.CreateGLAccount(GLAccount);
        NoSeriesCode := LibraryERM.CreateNoSeriesCode();
        EntryNo := CreateGenJournalLineWithVendEntry(GenJournalLine, NoSeriesCode, Vendor."No.", GLAccount."No.");
        CreateSingleLineGenJnlDocAndVendEntry(GenJournalLine, Vendor."No.");
        LineNoToDelete := GenJournalLine."Line No.";
        CreateSingleLineGenJnlDocAndVendEntry(GenJournalLine, Vendor."No.");
        LastLineNo := GenJournalLine."Line No.";

        // Exercise
        Commit();
        GenJournalLine.RenumberDocumentNo();
        GenJournalLine.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", LineNoToDelete);
        GenJournalLine.Delete(true);
        Commit();

        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJournalLine.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", LastLineNo);
        GenJournalLine.RenumberDocumentNo();
        NewDocNo := NoSeries.PeekNextNo(NoSeriesCode);

        VerifyGenJnlDocNoAndAppliesToIDVend(GenJournalLine, LastLineNo, EntryNo + 2, IncStr(NewDocNo));
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesMPH')]
    [Scope('OnPrem')]
    procedure GenJnlApplyCustomerEntryWhenBalAccountIsCustomer()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
    begin
        // [FEATURE] [Customer]
        // [SCENARIO 377410] Applying "Customer No." and Description are corespond to actual Customer when "Bal. Account Type" = Customer
        Initialize();

        // [GIVEN] Customer "A" with Name = "B"
        CreateCustomerWithName(Customer);
        // [GIVEN] GenJournalLine with "Account Type" = G/L Account, "Account No." = "X", "Bal. Account Type" = Customer, "Bal Account No." = "A"
        CreateGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
          GenJournalLine."Bal. Account Type"::Customer, Customer."No.", LibraryERM.CreateNoSeriesCode());

        // [WHEN] Run Apply Entries action
        RunGenJnlApplyAction(GenJournalLine, Customer."No.", Customer.Name);

        // [THEN] Page "Apply Customer Entries" is opened with following values: "Customer No." = "A", "Description" = "B"
        // Verification is done in handler ApplyCustomerEntriesMPH
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesMPH')]
    [Scope('OnPrem')]
    procedure GenJnlApplyCustomerEntryWhenBalAccountIsGLAccount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
    begin
        // [FEATURE] [Customer]
        // [SCENARIO 377410] Applying "Customer No." and Description are corespond to actual Customer when "Bal. Account Type" = G/L Account
        Initialize();

        // [GIVEN] Customer "A" with Name = "B"
        CreateCustomerWithName(Customer);
        // [GIVEN] GenJournalLine with "Account Type" = Customer, "Account No." = "A", "Bal. Account Type" = G/L Account, "Bal Account No." = "X"
        CreateGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::Customer, Customer."No.",
          GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), LibraryERM.CreateNoSeriesCode());

        // [WHEN] Run Apply Entries action
        RunGenJnlApplyAction(GenJournalLine, Customer."No.", Customer.Name);

        // [THEN] Page "Apply Customer Entries" is opened with following values: "Customer No." = "A", "Description" = "B"
        // Verification is done in handler ApplyCustomerEntriesMPH
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesMPH')]
    [Scope('OnPrem')]
    procedure GenJnlApplyVendorEntryWhenBalAccountIsVendor()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Vendor]
        // [SCENARIO 377410] Applying "Vendor No." and Description are corespond to actual Vendor when "Bal. Account Type" = Customer
        Initialize();

        // [GIVEN] Vendor "A" with Name = "B"
        CreateVendorWithName(Vendor);
        // [GIVEN] GenJournalLine with "Account Type" = G/L Account, "Account No." = "X", "Bal. Account Type" = Vendor, "Bal Account No." = "A"
        CreateGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
          GenJournalLine."Bal. Account Type"::Vendor, Vendor."No.", LibraryERM.CreateNoSeriesCode());

        // [WHEN] Run Apply Entries action
        RunGenJnlApplyAction(GenJournalLine, Vendor."No.", Vendor.Name);

        // [THEN] Page "Apply Vendor Entries" is opened with following values: "Vendor No." = "A", "Description" = "B"
        // Verification is done in handler ApplyVendorEntriesMPH
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesMPH')]
    [Scope('OnPrem')]
    procedure GenJnlApplyVendorEntryWhenBalAccountIsGLAccount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Vendor]
        // [SCENARIO 377410] Applying "Vendor No." and Description are corespond to actual Vendor when "Bal. Account Type" = G/L Account
        Initialize();

        // [GIVEN] Vendor "A" with Name = "B"
        CreateVendorWithName(Vendor);
        // [GIVEN] GenJournalLine with "Account Type" = Vendor, "Account No." = "A", "Bal. Account Type" = G/L Account, "Bal Account No." = "X"
        CreateGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::Vendor, Vendor."No.",
          GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), LibraryERM.CreateNoSeriesCode());

        // [WHEN] Run Apply Entries action
        RunGenJnlApplyAction(GenJournalLine, Vendor."No.", Vendor.Name);

        // [THEN] Page "Apply Vendor Entries" is opened with following values: "Vendor No." = "A", "Description" = "B"
        // Verification is done in handler ApplyVendorEntriesMPH
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocNoIncByInNewGenJournalLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLineNew: Record "Gen. Journal Line";
    begin
        // [SCENARIO 378200] "Document No." should be incremented by "Increment-by No." of No. Series Line if it is set up

        Initialize();

        CreateGenJournalLineWithDocNo(GenJournalLine, 'X00013');

        SetUpNewGenJnlLineWithNoSeries(GenJournalLine, GenJournalLineNew, 7);

        GenJournalLineNew.TestField("Document No.", 'X00020');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocNoWithoutIncByInNewGenJournalLine()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLineNew: Record "Gen. Journal Line";
    begin
        // [SCENARIO 378200] "Document No." should be incremented by 1 if "Increment-by No." of No. Series Line is not set up

        Initialize();

        CreateGenJournalLineWithDocNo(GenJournalLine, 'X00013');

        GenJnlBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");

        GenJournalLineNew."Journal Template Name" := GenJournalLine."Journal Template Name";
        GenJournalLineNew."Journal Batch Name" := GenJournalLine."Journal Batch Name";
        GenJournalLineNew.SetUpNewLine(GenJournalLine, GenJournalLine."Balance (LCY)", true);

        GenJournalLine."Document No." := IncStr(GenJournalLine."Document No.");
        GenJournalLineNew.TestField("Document No.", 'X00014');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocNoIncByOneIfIncorrectNoSeriesInNewGenJournalLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLineNew: Record "Gen. Journal Line";
    begin
        // [SCENARIO 378200] "Document No." should be incremented by 1 if "Increment-by No." of No. Series Line is 1 or less

        Initialize();

        CreateGenJournalLineWithDocNo(GenJournalLine, 'X00013');

        SetUpNewGenJnlLineWithNoSeries(GenJournalLine, GenJournalLineNew, -LibraryRandom.RandIntInRange(2, 10));

        GenJournalLine."Document No." := IncStr(GenJournalLine."Document No.");
        GenJournalLineNew.TestField("Document No.", 'X00014');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocNoIncWithoutNoSeriesInNewGenJournalLine()
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLineNew: Record "Gen. Journal Line";
    begin
        // [SCENARIO 378200] "Document No." should be incremented by 1 if No. Series is not specified

        Initialize();

        CreateGenJournalLineWithDocNo(GenJournalLine, 'X00013');

        GenJnlBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");

        GenJournalLineNew."Journal Template Name" := GenJournalLine."Journal Template Name";
        GenJournalLineNew."Journal Batch Name" := GenJournalLine."Journal Batch Name";
        GenJournalLineNew.SetUpNewLine(GenJournalLine, GenJournalLine."Balance (LCY)", true);

        GenJournalLine."Document No." := IncStr(GenJournalLine."Document No.");
        GenJournalLineNew.TestField("Document No.", 'X00014');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecipientBankAccountOnInvoiceGenJnlLineForCustomerAsAccount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
    begin
        // [FEATURE] [Customer]
        // [SCENARIO 407085] "Recipient Bank Account" is filled in on Invoice Gen. Jnl. Line when Account No has Customer with "Preferred Bank Account Code"
        Initialize();
        CreateCustomerWithBankAccount(Customer);
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, Customer."No.",
          GenJournalLine."Bal. Account Type"::"G/L Account", '', '');

        GenJournalLine.TestField("Recipient Bank Account", Customer."Preferred Bank Account Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecipientBankAccountOnInvoiceGenJnlLineForCustomerAsBalAccount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
    begin
        // [FEATURE] [Customer]
        // [SCENARIO 407085] "Recipient Bank Account" is filled in on Invoice Gen. Jnl. Line when Bal. Account No has Customer with "Preferred Bank Account Code"
        Initialize();
        CreateCustomerWithBankAccount(Customer);
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::"G/L Account", '',
          GenJournalLine."Bal. Account Type"::Customer, Customer."No.", '');

        GenJournalLine.TestField("Recipient Bank Account", Customer."Preferred Bank Account Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecipientBankAccountOnInvoiceGenJnlLineForVendorAsAccount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Vendor]
        // [SCENARIO 407085] "Recipient Bank Account" is filled in on Invoice Gen. Jnl. Line when Account No has Vendor with "Preferred Bank Account Code"
        Initialize();
        CreateVendorWithBankAccount(Vendor);
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor, Vendor."No.",
          GenJournalLine."Bal. Account Type"::"G/L Account", '', '');

        GenJournalLine.TestField("Recipient Bank Account", Vendor."Preferred Bank Account Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecipientBankAccountOnInvoiceGenJnlLineForVendorAsBalAccount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Vendor]
        // [SCENARIO 407085] "Recipient Bank Account" is filled in on Invoice Gen. Jnl. Line when Bal. Account No has Vendor with "Preferred Bank Account Code"
        Initialize();
        CreateVendorWithBankAccount(Vendor);
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::"G/L Account", '',
          GenJournalLine."Bal. Account Type"::Vendor, Vendor."No.", '');

        GenJournalLine.TestField("Recipient Bank Account", Vendor."Preferred Bank Account Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecipientBankAccountOnPaymentGenJnlLineForCustomer()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
    begin
        // [FEATURE] [Customer]
        // [SCENARIO 378439] "Recipient Bank Account" should be filled on Payment Gen. Jnl. Line when Account No has Customer with "Preferred Bank Account Code"
        Initialize();
        CreateCustomerWithBankAccount(Customer);
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, Customer."No.",
          GenJournalLine."Bal. Account Type"::"G/L Account", '', '');

        GenJournalLine.TestField("Recipient Bank Account", Customer."Preferred Bank Account Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecipientBankAccountOnPaymentGenJnlLineForVendor()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Vendor]
        // [SCENARIO 378439] "Recipient Bank Account" should be filled on Payment Gen. Jnl. Line when Account No has Vendor with "Preferred Bank Account Code"
        Initialize();
        CreateVendorWithBankAccount(Vendor);
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Vendor, Vendor."No.",
          GenJournalLine."Bal. Account Type"::"G/L Account", '', '');

        GenJournalLine.TestField("Recipient Bank Account", Vendor."Preferred Bank Account Code");
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure RenumberingOfEntriesWithoutDocNo()
    var
        GenJournalLine: array[2] of Record "Gen. Journal Line";
        Vendor: Record Vendor;
        AppliesToDocNo: Code[20];
    begin
        // [FEATURE] [Renumbering]
        // [SCENARIO 379388] If renumbering several General Journal Line where "Document No" is blank, then "Applies-to Doc No" is not renumbered

        Initialize();

        CreateVendorWithBankAccount(Vendor);
        CreateGenJournalLine(GenJournalLine[1], GenJournalLine[1]."Document Type"::" ",
          GenJournalLine[1]."Account Type"::Vendor, Vendor."No.",
          GenJournalLine[1]."Bal. Account Type"::"G/L Account", '', LibraryERM.CreateNoSeriesCode());
        SetDocNoAndAppliesToDocNo(GenJournalLine[1], '', '');

        LibraryERM.CreateGeneralJnlLine2(
          GenJournalLine[2], GenJournalLine[1]."Journal Template Name", GenJournalLine[1]."Journal Batch Name",
          GenJournalLine[2]."Document Type"::" ", GenJournalLine[2]."Account Type"::Vendor, Vendor."No.", LibraryRandom.RandDec(100, 2));
        SetDocNoAndAppliesToDocNo(
          GenJournalLine[2], '',
          LibraryUtility.GenerateRandomCode(GenJournalLine[2].FieldNo("Applies-to Doc. No."), DATABASE::"Gen. Journal Line"));
        AppliesToDocNo := GenJournalLine[2]."Applies-to Doc. No.";

        Commit();
        GenJournalLine[1].RenumberDocumentNo();

        GenJournalLine[1].TestField("Applies-to Doc. No.", '');
        GenJournalLine[2].TestField("Applies-to Doc. No.", AppliesToDocNo);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure NoRenumberingForPrintedDoc()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DocNo: Code[20];
    begin
        // [SCENARIO 379147] User runs "Renumber Document Numbers" action for Gen. Journal Line which refers to printed Check. "No Check Lines were renumbered." message appears and Document number is not changed.

        Initialize();

        CreateGenJournalLineWithVendEntry(
          GenJournalLine, LibraryERM.CreateNoSeriesCode(), LibraryPurchase.CreateVendorNo(), LibraryERM.CreateGLAccountNo());
        GenJournalLine.Validate("Check Printed", true);
        GenJournalLine.Modify();
        DocNo := GenJournalLine."Document No.";

        Commit();

        asserterror GenJournalLine.RenumberDocumentNo();

        Assert.ExpectedTestFieldError(GenJournalLine.FieldCaption("Check Printed"), Format(false));
        GenJournalLine.TestField("Document No.", DocNo);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure NoRenumberingForDifferentPrintedDocLine()
    var
        GLAccount: Record "G/L Account";
        GLAccount2: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        NoSeries: Codeunit "No. Series";
        NoSeriesCode: Code[20];
        NewDocNo: Code[20];
        PrintedDocNo: Code[20];
        FirstLineNo: Integer;
    begin
        Initialize();

        // Setup
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGLAccount(GLAccount2);
        NoSeriesCode := LibraryERM.CreateNoSeriesCode();
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", GLAccount."No.",
          GenJournalLine."Account Type"::"G/L Account", GLAccount2."No.", NoSeriesCode);
        SetNewDocNo(GenJournalLine);
        FirstLineNo := GenJournalLine."Line No.";
        CreateSingleLineGenJnlDoc(GenJournalLine, GenJournalLine."Account Type"::"G/L Account", GLAccount."No.");
        SetNewDocNo(GenJournalLine);
        GenJournalLine."Check Printed" := true;
        GenJournalLine.Modify(false);
        PrintedDocNo := GenJournalLine."Document No.";

        // Exercise
        Commit();
        GenJournalLine.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", FirstLineNo);
        GenJournalLine.RenumberDocumentNo();

        // Verify
        NewDocNo := NoSeries.PeekNextNo(NoSeriesCode);
        VerifyGenJnlLineDocNo(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
          10000, NewDocNo);
        VerifyGenJnlLineDocNo(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
          20000, PrintedDocNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoModifyWithJobQueueStatusScheduledOrPosting()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify modify is not allowed when line has been scheduled in the job queue
        Initialize();

        CreateGenJournalLineWithVendEntry(
          GenJournalLine, LibraryERM.CreateNoSeriesCode(), LibraryPurchase.CreateVendorNo(), LibraryERM.CreateGLAccountNo());
        GenJournalLine.Validate("Job Queue Status", GenJournalLine."Job Queue Status"::"Scheduled for Posting");
        GenJournalLine.Modify();
        Commit();

        GenJournalLine.Validate(Amount, 123);
        asserterror GenJournalLine.Modify(true);
        Assert.ExpectedError(WrongJobQueueStatus);

        GenJournalLine.Validate("Job Queue Status", GenJournalLine."Job Queue Status"::Posting);
        GenJournalLine.Modify();
        Commit();

        GenJournalLine.Validate(Amount, 123);
        asserterror GenJournalLine.Modify(true);
        Assert.ExpectedError(WrongJobQueueStatus);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoDeleteWithJobQueueStatusScheduledOrPosting()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify delete is not allowed when line has been scheduled in the job queue
        Initialize();

        CreateGenJournalLineWithVendEntry(
          GenJournalLine, LibraryERM.CreateNoSeriesCode(), LibraryPurchase.CreateVendorNo(), LibraryERM.CreateGLAccountNo());
        GenJournalLine.Validate("Job Queue Status", GenJournalLine."Job Queue Status"::"Scheduled for Posting");
        GenJournalLine.Modify();
        Commit();

        asserterror GenJournalLine.Delete(true);
        Assert.ExpectedError(WrongJobQueueStatus);

        GenJournalLine.Validate("Job Queue Status", GenJournalLine."Job Queue Status"::Posting);
        GenJournalLine.Modify();
        Commit();

        asserterror GenJournalLine.Delete(true);
        Assert.ExpectedError(WrongJobQueueStatus);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure NoRenumberWithJobQueueStatusScheduledOrPosting()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify renumber is not allowed when line has been scheduled in the job queue
        Initialize();

        CreateGenJournalLineWithVendEntry(
          GenJournalLine, LibraryERM.CreateNoSeriesCode(), LibraryPurchase.CreateVendorNo(), LibraryERM.CreateGLAccountNo());
        GenJournalLine.Validate("Job Queue Status", GenJournalLine."Job Queue Status"::"Scheduled for Posting");
        GenJournalLine.Modify();
        Commit();

        asserterror GenJournalLine.RenumberDocumentNo();
        Assert.ExpectedError(WrongJobQueueStatus);

        GenJournalLine.Validate("Job Queue Status", GenJournalLine."Job Queue Status"::Posting);
        GenJournalLine.Modify();
        Commit();

        asserterror GenJournalLine.RenumberDocumentNo();
        Assert.ExpectedError(WrongJobQueueStatus);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoRenameWithJobQueueStatusScheduledOrPosting()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
    begin
        // Verify modify is not allowed when line has been scheduled in the job queue
        Initialize();

        CreateGenJournalLineWithVendEntry(
          GenJournalLine, LibraryERM.CreateNoSeriesCode(), LibraryPurchase.CreateVendorNo(), LibraryERM.CreateGLAccountNo());
        GenJournalLine.Validate("Job Queue Status", GenJournalLine."Job Queue Status"::"Scheduled for Posting");
        GenJournalLine.Modify();
        Commit();

        asserterror GenJournalLine.Rename(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No." + 1);
        Assert.ExpectedError(WrongJobQueueStatus);

        CreateGenJournalLineWithVendEntry(
          GenJournalLine2, LibraryERM.CreateNoSeriesCode(), LibraryPurchase.CreateVendorNo(), LibraryERM.CreateGLAccountNo());
        GenJournalLine2.Validate("Job Queue Status", GenJournalLine2."Job Queue Status"::"Posting");
        GenJournalLine2.Modify();
        Commit();

        asserterror GenJournalLine2.Rename(GenJournalLine2."Journal Template Name", GenJournalLine2."Journal Batch Name", GenJournalLine2."Line No." + 1);
        Assert.ExpectedError(WrongJobQueueStatus);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure RenumberingGenJournalLinesWithBalAccountEmptyDocumentNo()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: array[4] of Record "Gen. Journal Line";
        GLAccountNo: Code[20];
        BalGLAccountNo: Code[20];
        NoSeriesCode: Code[20];
        i: Integer;
    begin
        // [FEATURE] [Renumbering]
        // [SCENARIO 424335] After renumbering, Gen. Journal Lines having Bal. Account should have unique Document Nos,
        // Lines without Bal. Account should have same Document No, but different from lines with Bal. Account
        Initialize();

        GLAccountNo := LibraryERM.CreateGLAccountNo();
        BalGLAccountNo := LibraryERM.CreateGLAccountNo();
        CreateGenJournalTemplateBatch(GenJournalTemplate, GenJournalBatch);
        NoSeriesCode := LibraryERM.CreateNoSeriesCode();
        GenJournalBatch."No. Series" := NoSeriesCode;
        GenJournalBatch.Modify();

        // [GIVEN] First and second Gen. Journal Lines with Bal. Account without Doc. No
        CreateGenJournalLineWithEmptyDocNo(GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine[1], GLAccountNo, BalGLAccountNo);
        CreateGenJournalLineWithEmptyDocNo(GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine[2], GLAccountNo, BalGLAccountNo);

        // [GIVEN] Third and forth Gen. Journal Lines without Bal. Account without Doc. No in the same Batch
        CreateGenJournalLineWithEmptyDocNo(GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine[3], GLAccountNo, '');
        CreateGenJournalLineWithEmptyDocNo(GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine[4], GLAccountNo, '');

        // [WHEN] Run "Renumber Document Numbers"
        Commit();
        GenJournalLine[1].RenumberDocumentNo();
        for i := 1 to 4 do
            GenJournalLine[i].Find();

        // [THEN] Lines 1 and 2 have different document number
        Assert.AreNotEqual(GenJournalLine[1]."Document No.", GenJournalLine[2]."Document No.", '');
        // [THEN] Lines 3 and 4 have same document number
        Assert.AreNotEqual(GenJournalLine[2]."Document No.", GenJournalLine[3]."Document No.", '');
        Assert.AreEqual(GenJournalLine[3]."Document No.", GenJournalLine[4]."Document No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetAmountFromVendLedgerEntry()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 381241] When calling "Get Vendor Ledger Entry", "Amount" of Gen. Journal Line should be calculated according to found Vendor Ledger Entry

        Initialize();

        // [GIVEN] Vendor Ledger Entry having -("Remaining Amount" - "Remaining Pmt. Disc. Possible") = -100 and "Document No." = AAA
        CreateVendLedgEntry(VendLedgEntry, LibraryPurchase.CreateVendorNo(), '');

        // [GIVEN] General Journal Line habing "Applies-to Doc. No." = AAA
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::Vendor, '', 0);
        GenJournalLine."Applies-to Doc. No." := VendLedgEntry."Document No.";
        GenJournalLine.Modify();

        // [WHEN] Call "Get Vendor Ledger Entry" for General Journal Line
        GenJournalLine.GetVendLedgerEntry();

        // [THEN] General Journal Line "Amount" = -100
        GenJournalLine.TestField(Amount, -(VendLedgEntry."Remaining Amount" - VendLedgEntry."Remaining Pmt. Disc. Possible"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowAmountsChangeDebitCreditAmountFieldVisibility()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJnlManagement: Codeunit GenJnlManagement;
        GeneralJournalBatches: TestPage "General Journal Batches";
        GeneralJournal: TestPage "General Journal";
    begin
        // [FEATURE] [Show Amounts]
        // [SCENARIO 224180] Fields Debit Amount/Credit Amount/Amount visibility depending on "Show Amount" setting
        Initialize();

        // By default General journal (PAG 39) opens up in simple mode where debit and credit are always shown
        // regardless of the general ledger setup settings.
        // So, for this test we need to open up General journal page in 'classic mode' where the settings for
        // credit / debit comes from general ledger setup. This is same as executing 'show more columns' action on PAG39.
        GenJnlManagement.SetJournalSimplePageModePreference(false, PAGE::"General Journal");

        // [GIVEN] General Ledger Setup with Show Amount = "Debit/Credit Only"
        SetShowAmounts(GeneralLedgerSetup."Show Amounts"::"Debit/Credit Only");

        // [GIVEN] General Journal Batch is created and selected on General Journal Batches page.
        CreateGenJournalTemplateBatch(GenJournalTemplate, GenJournalBatch);
        PrepareGeneralJournalBatchesPage(GeneralJournalBatches, GenJournalBatch);

        // [WHEN] General Journal page opened from General Journal Batches
        RunEditJournalActionOnGeneralJournalPage(GeneralJournal, GeneralJournalBatches);

        // [THEN] "Debit Amount", "Credit Amount" columns are visible, "Amount" column - not visible
        VerifyGenJnlLinePageDebitCreditAmtFieldsVisibility(GeneralJournal, true, true, false);

        // [GIVEN] General Ledger Setup with Show Amount = "All Amounts"
        SetShowAmounts(GeneralLedgerSetup."Show Amounts"::"All Amounts");

        // [WHEN] General Journal page opened from General Journal Batches
        RunEditJournalActionOnGeneralJournalPage(GeneralJournal, GeneralJournalBatches);

        // [THEN] "Debit Amount", "Credit Amount" and "Amount" columns are visible
        VerifyGenJnlLinePageDebitCreditAmtFieldsVisibility(GeneralJournal, true, true, true);

        // [GIVEN] General Ledger Setup with Show Amount = "Amount Only"
        SetShowAmounts(GeneralLedgerSetup."Show Amounts"::"Amount Only");

        // [WHEN] General Journal page opened from General Journal Batches
        RunEditJournalActionOnGeneralJournalPage(GeneralJournal, GeneralJournalBatches);

        // [THEN] "Debit Amount", "Credit Amount" columns are not visible, "Amount" column - visible
        VerifyGenJnlLinePageDebitCreditAmtFieldsVisibility(GeneralJournal, false, false, true);
        GeneralJournalBatches.Close();

        // Reset general journal page to simple mode or 'show less columns'.
        GenJnlManagement.SetJournalSimplePageModePreference(true, PAGE::"General Journal");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowAmountsAllAmountsVisibilityPaymentJournal()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GeneralJournalBatches: TestPage "General Journal Batches";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [FEATURE] [Show Amounts] [Payment]
        // [SCENARIO 232464] Amount columns visibility on Payment Journal page for Show Amount = "All Amounts" in General Ledger Setup.
        Initialize();

        // [GIVEN] General Ledger Setup with Show Amount = "All Amounts"
        SetShowAmounts(GeneralLedgerSetup."Show Amounts"::"All Amounts");

        // [GIVEN] General Journal Batch is created for Payment Template and selected on General Journal Batches page.
        PreparePaymentTemplateBatchAndPage(GeneralJournalBatches);

        // [WHEN] Payment Journal page is opened from General Journal Batches page.
        RunEditJournalActionOnPaymentJournalPage(PaymentJournal, GeneralJournalBatches);

        // [THEN] "Debit Amount", "Credit Amount" and "Amount" columns are visible on Payment Journal page.
        VerifyPaymentJnlLinePageDebitCreditAmtFieldsVisibility(PaymentJournal, true, true, true);
        GeneralJournalBatches.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowAmountsDebitCreditOnlyVisibilityPaymentJournal()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GeneralJournalBatches: TestPage "General Journal Batches";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [FEATURE] [Show Amounts] [Payment]
        // [SCENARIO 232464] Amount columns visibility on Payment Journal page for Show Amount = "Debit/Credit Only" in General Ledger Setup.
        Initialize();

        // [GIVEN] General Ledger Setup with Show Amount = "Debit/Credit Only"
        SetShowAmounts(GeneralLedgerSetup."Show Amounts"::"Debit/Credit Only");

        // [GIVEN] General Journal Batch is created for Payment Template and selected on General Journal Batches page.
        PreparePaymentTemplateBatchAndPage(GeneralJournalBatches);

        // [WHEN] Payment Journal page is opened from General Journal Batches page.
        RunEditJournalActionOnPaymentJournalPage(PaymentJournal, GeneralJournalBatches);

        // [THEN] "Debit Amount", "Credit Amount" columns are visible, "Amount" column is not visible on Payment Journal page.
        VerifyPaymentJnlLinePageDebitCreditAmtFieldsVisibility(PaymentJournal, true, true, false);
        GeneralJournalBatches.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowAmountsAmountOnlyVisibilityPaymentJournal()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GeneralJournalBatches: TestPage "General Journal Batches";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [FEATURE] [Show Amounts] [Payment]
        // [SCENARIO 232464] Amount columns visibility on Payment Journal page for Show Amount = "Amount Only" in General Ledger Setup.
        Initialize();

        // [GIVEN] General Ledger Setup with Show Amount = "Amount Only"
        SetShowAmounts(GeneralLedgerSetup."Show Amounts"::"Amount Only");

        // [GIVEN] General Journal Batch is created for Payment Template and selected on General Journal Batches page.
        PreparePaymentTemplateBatchAndPage(GeneralJournalBatches);

        // [WHEN] Payment Journal page is opened from General Journal Batches page.
        RunEditJournalActionOnPaymentJournalPage(PaymentJournal, GeneralJournalBatches);

        // [THEN] "Debit Amount", "Credit Amount" columns are not visible, "Amount" column is visible on Payment Journal page.
        VerifyPaymentJnlLinePageDebitCreditAmtFieldsVisibility(PaymentJournal, false, false, true);
        GeneralJournalBatches.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AppliesToExtDocNoFieldLength()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorPaymentBuffer: Record "Vendor Payment Buffer";
    begin
        // [SCENARIO 264227] "Applies-to Ext. Doc. No." field length < "Description" field length
        Assert.IsTrue(MaxStrLen(GenJournalLine."Applies-to Ext. Doc. No.") < MaxStrLen(GenJournalLine.Description), '');
        Assert.IsTrue(MaxStrLen(VendorPaymentBuffer."Applies-to Ext. Doc. No.") < MaxStrLen(GenJournalLine.Description), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPurchLCYAfterValidateAmountAndRecurringMethod()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 264513] "Sales/Purch. (LCY)" field value after validate Amount and "Recurring Method"

        // positive\negative regardless recurring method
        VerifySalesPurchLCYAfterValidateAmount(GenJournalLine."Recurring Method"::" ");
        VerifySalesPurchLCYAfterValidateAmount(GenJournalLine."Recurring Method"::"F  Fixed");

        // negative: not recurring, blanked balance account no. for customer\vendor invoice\credit memo
        VerifyGenJournalLineSalesPurchLCY_CustomerInvoice(GenJournalLine."Recurring Method"::" ", '', 1, 0);
        VerifyGenJournalLineSalesPurchLCY_VendorInvoice(GenJournalLine."Recurring Method"::" ", '', 1, 0);
        VerifyGenJournalLineSalesPurchLCY_CustomerCrMemo(GenJournalLine."Recurring Method"::" ", '', 1, 0);
        VerifyGenJournalLineSalesPurchLCY_VendorCrMemo(GenJournalLine."Recurring Method"::" ", '', 1, 0);

        // positive: recurring, blanked balance account no. for customer\vendor invoice\credit memo
        VerifyGenJournalLineSalesPurchLCY_CustomerInvoice(GenJournalLine."Recurring Method"::"F  Fixed", '', 1, 1);
        VerifyGenJournalLineSalesPurchLCY_VendorInvoice(GenJournalLine."Recurring Method"::"F  Fixed", '', 1, 1);
        VerifyGenJournalLineSalesPurchLCY_CustomerCrMemo(GenJournalLine."Recurring Method"::"F  Fixed", '', 1, 1);
        VerifyGenJournalLineSalesPurchLCY_VendorCrMemo(GenJournalLine."Recurring Method"::"F  Fixed", '', 1, 1);
        // validate recurring method after Amount validation
        ValidateAmountAndVerifySalesPurchLCYGenJournalLine(
            GenJournalLine, GenJournalLine."Recurring Method"::" ", false,
            GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(), GenJournalLine."Bal. Account Type"::"G/L Account", '', 1, 0);
        GenJournalLine.Validate("Recurring Method", GenJournalLine."Recurring Method"::"F  Fixed");
        GenJournalLine.TestField("Sales/Purch. (LCY)", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotPossibleToSpecifyBalAccNoInRecurringJournal()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // [FEATURE] [General Journal Batch]
        // [SCENARIO 271027] Stan cannot specify "Bal. Account No." in Gen. Journal Batch with type Recurring

        Initialize();
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Recurring, true);
        GenJournalTemplate.Modify(true);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"G/L Account");
        asserterror GenJournalBatch.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
        Assert.ExpectedErrorCode('TableErrorStr');
        Assert.ExpectedError(CannotBeSpecifiedForRecurrJnlErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SpecifyBalAccNoInGeneralJournal()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccNo: Code[20];
    begin
        // [FEATURE] [General Journal Batch]
        // [SCENARIO 271027] Stan can specify "Bal. Account No." in Gen. Journal Batch

        Initialize();
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"G/L Account");
        GLAccNo := LibraryERM.CreateGLAccountNo();
        GenJournalBatch.Validate("Bal. Account No.", GLAccNo);
        GenJournalBatch.TestField("Bal. Account No.", GLAccNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CurrencyCodeWhenValidateBalAccountNoInNewLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccountNo: Code[20];
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [Currency Code] [Gen. Journal Line] [Bal. Account No.]
        // [SCENARIO 266335] When validate "Bal. Account No" = LCY Bank Account in new Gen. Journal Line with <non-blank> Account then "Currency Code" is not changed in Gen. Journal Line
        Initialize();
        CurrencyCode := CreateCurrency();

        // [GIVEN] Bank Account "B" with <blank> Currency Code
        BankAccountNo := CreateBankAccountWithCurrency('');

        // [GIVEN] Gen. Journal Line is initialized with Currency Code = "EUR", <non-blank> Account and Bal. Account Type = Bank Account
        GenJournalLine.Init();
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::Customer);
        GenJournalLine.Validate("Account No.", LibrarySales.CreateCustomerNo());
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");

        // [WHEN] Validate Bal. Account No. = "B"
        GenJournalLine.Validate("Bal. Account No.", BankAccountNo);

        // [THEN] Currency Code is "EUR" in Gen. Journal Line
        GenJournalLine.TestField("Currency Code", CurrencyCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CurrencyCodeRemainsWhenClearBalAccount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccountNo: Code[20];
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [Currency Code] [Gen. Journal Line] [Bal. Account No.]
        // [SCENARIO 266335] Currency Code is not cleared in Gen. Journal Line when clear Bal. Account No. in Gen. Journal Line
        // [SCENARIO 266335] having Bal. Account = LCY Bank Account and Currency Code = FCY
        Initialize();
        CurrencyCode := CreateCurrency();

        // [GIVEN] Bank Account "B" with "Currency Code" = <blank>
        BankAccountNo := CreateBankAccountWithCurrency('');

        // [GIVEN] Gen. Journal Line with Currency Code = "EUR", "Bal. Account Type" = Bank Account, "Bal. Account No." = "B"
        MockGenJournalLine(GenJournalLine, BankAccountNo, CurrencyCode);

        // [WHEN] Clear "Bal. Account No." in Gen. Journal Line
        GenJournalLine.Validate("Bal. Account No.", '');

        // [THEN] Currency Code = "EUR" in Gen. Journal Line
        GenJournalLine.TestField("Currency Code", CurrencyCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CurrencyCodeClearWhenClearBalAccount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccountNo: Code[20];
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [Currency Code] [Gen. Journal Line] [Bal. Account No.]
        // [SCENARIO 266335] Currency Code is cleared in Gen. Journal Line when clear Bal. Account No. in Gen. Journal Line
        // [SCENARIO 266335] having Bal. Account = FCY Bank Account "B" and Currency Code = "B" Currency Code
        Initialize();
        CurrencyCode := CreateCurrency();

        // [GIVEN] Bank Account "B" with "Currency Code" = "EUR"
        BankAccountNo := CreateBankAccountWithCurrency(CurrencyCode);

        // [GIVEN] Gen. Journal Line with Currency Code = "EUR", "Bal. Account Type" = Bank Account, "Bal. Account No." = "B"
        MockGenJournalLine(GenJournalLine, BankAccountNo, CurrencyCode);

        // [WHEN] Clear "Bal. Account No." in Gen. Journal Line
        GenJournalLine.Validate("Bal. Account No.", '');

        // [THEN] Currency Code is cleared in Gen. Journal Line
        GenJournalLine.TestField("Currency Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CurrencyCodeRemainsWhenValidateBalAccount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccountNo: Code[20];
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [Currency Code] [Gen. Journal Line] [Bal. Account No.]
        // [SCENARIO 266335] Currency Code is not cleared in Gen. Journal Line when validate Bal. Account No. = LCY Bank Account in Gen. Journal Line
        // [SCENARIO 266335] having Bal. Account = LCY Bank Account and Currency Code = FCY
        Initialize();
        CurrencyCode := CreateCurrency();

        // [GIVEN] Bank Account "B1" with "Currency Code" = <blank>
        BankAccountNo := CreateBankAccountWithCurrency('');

        // [GIVEN] Gen. Journal Line with <non-blank> Account, Currency Code = "EUR", "Bal. Account Type" = Bank Account, "Bal. Account No." = "B1"
        MockGenJournalLine(GenJournalLine, BankAccountNo, CurrencyCode);

        // [GIVEN] Bank Account "B2" with "Currency Code" = <blank>
        BankAccountNo := CreateBankAccountWithCurrency('');

        // [WHEN] Validate "Bal. Account No." = "B2" in Gen. Journal Line
        GenJournalLine.Validate("Bal. Account No.", BankAccountNo);

        // [THEN] Currency Code = "EUR" in Gen. Journal Line
        GenJournalLine.TestField("Currency Code", CurrencyCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CurrencyCodeClearWhenValidateBalAccount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        BankAccountNo: Code[20];
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [Currency Code] [Gen. Journal Line] [Bal. Account No.]
        // [SCENARIO 266335] Currency Code is cleared in Gen. Journal Line when validate Bal. Account No. = LCY Bank Account in Gen. Journal Line
        // [SCENARIO 266335] having Bal. Account = FCY Bank Account "B" and Currency Code = "B" Currency Code
        Initialize();
        CurrencyCode := CreateCurrency();

        // [GIVEN] Bank Account "B1" with "Currency Code" = "EUR"
        BankAccountNo := CreateBankAccountWithCurrency(CurrencyCode);

        // [GIVEN] Gen. Journal Line with <non-blank> Account, Currency Code = "EUR", "Bal. Account Type" = Bank Account, "Bal. Account No." = "B1"
        MockGenJournalLine(GenJournalLine, BankAccountNo, CurrencyCode);

        // [GIVEN] Bank Account "B2" with "Currency Code" = <blank>
        BankAccountNo := CreateBankAccountWithCurrency('');

        // [WHEN] Validate "Bal. Account No." = "B2" in Gen. Journal Line
        GenJournalLine.Validate("Bal. Account No.", BankAccountNo);

        // [THEN] Currency Code is cleared in Gen. Journal Line
        GenJournalLine.TestField("Currency Code", '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure CheckModifyCurrencyCodeModifiesCurrencyCodeInGenJournalLineIfConfirmed()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [UT] [Currency Code]
        // [SCENARIO 273704] Function CheckModifyCurrencyCode modifies Currency Code in Gen. Journal Line if confirmed

        // [GIVEN] Currency "FCY"
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(
            WorkDate(), LibraryRandom.RandDecInDecimalRange(10, 20, 2), LibraryRandom.RandDecInRange(10, 20, 2));

        // [GIVEN] Gen. Journal Line with <blank> Currency Code
        GenJournalLine.Init();
        GenJournalLine."Currency Code" := '';

        // [GIVEN] Called CheckModifyCurrencyCode with "FCY" in Gen. Journal Line
        GenJournalLine.CheckModifyCurrencyCode(GenJournalLine."Account Type"::Customer, CurrencyCode);

        // [WHEN] Confirm Currency Code change to "FCY"
        // Confirmation is done in ConfirmHandlerYes

        // [THEN] Gen. Journal Line has Currency Code = "FCY"
        GenJournalLine.TestField("Currency Code", CurrencyCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowAmountsAllAmountsVisibilityJobGLJournal()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalTemplate: Record "Gen. Journal Template";
        GeneralJournalBatches: TestPage "General Journal Batches";
        JobGLJournal: TestPage "Job G/L Journal";
    begin
        // [FEATURE] [Show Amounts] [Job G/L]
        // [SCENARIO 275827] Amount columns visibility on Job G/L Journal page for Show Amount = "All Amounts" in General Ledger Setup.
        Initialize();

        // [GIVEN] General Ledger Setup with Show Amount = "All Amounts"
        SetShowAmounts(GeneralLedgerSetup."Show Amounts"::"All Amounts");

        // [GIVEN] General Journal Batch is created for Jobs Template and selected on General Journal Batches page.
        PrepareTemplateBatchAndPageWithTypeAndReccuring(GeneralJournalBatches, GenJournalTemplate.Type::Jobs, false);

        // [WHEN] Job G/L Journal page is opened from General Journal Batches page.
        RunEditJournalActionOnJobGLJournalPage(JobGLJournal, GeneralJournalBatches);

        // [THEN] "Debit Amount", "Credit Amount", "Amount" and "Amount (LCY)" columns are visible on Job G/L Journal page.
        VerifyJobGLJnlPageDebitCreditAmtFieldsVisibility(JobGLJournal, true, true, true, true);
        GeneralJournalBatches.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowAmountsDebitCreditOnlyVisibilityJobGLJournal()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalTemplate: Record "Gen. Journal Template";
        GeneralJournalBatches: TestPage "General Journal Batches";
        JobGLJournal: TestPage "Job G/L Journal";
    begin
        // [FEATURE] [Show Amounts] [Job G/L]
        // [SCENARIO 275827] Amount columns visibility on Job G/L Journal page for Show Amount = "Debit/Credit Only" in General Ledger Setup.
        Initialize();

        // [GIVEN] General Ledger Setup with Show Amount = "Debit/Credit Only"
        SetShowAmounts(GeneralLedgerSetup."Show Amounts"::"Debit/Credit Only");

        // [GIVEN] General Journal Batch is created for Jobs Template and selected on General Journal Batches page.
        PrepareTemplateBatchAndPageWithTypeAndReccuring(GeneralJournalBatches, GenJournalTemplate.Type::Jobs, false);

        // [WHEN] Job G/L Journal page is opened from General Journal Batches page.
        RunEditJournalActionOnJobGLJournalPage(JobGLJournal, GeneralJournalBatches);

        // [THEN] "Debit Amount", "Credit Amount" columns are visible, "Amount" and "Amount (LCY)" column are not visible on Job G/L Journal page.
        VerifyJobGLJnlPageDebitCreditAmtFieldsVisibility(JobGLJournal, true, true, false, false);
        GeneralJournalBatches.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowAmountsAmountOnlyVisibilityJobGLJournal()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalTemplate: Record "Gen. Journal Template";
        GeneralJournalBatches: TestPage "General Journal Batches";
        JobGLJournal: TestPage "Job G/L Journal";
    begin
        // [FEATURE] [Show Amounts] [Job G/L]
        // [SCENARIO 275827] Amount columns visibility on Job G/L Journal page for Show Amount = "Amount Only" in General Ledger Setup.
        Initialize();

        // [GIVEN] General Ledger Setup with Show Amount = "Amount Only"
        SetShowAmounts(GeneralLedgerSetup."Show Amounts"::"Amount Only");

        // [GIVEN] General Journal Batch is created for Jobs Template and selected on General Journal Batches page.
        PrepareTemplateBatchAndPageWithTypeAndReccuring(GeneralJournalBatches, GenJournalTemplate.Type::Jobs, false);

        // [WHEN] Job G/L Journal page is opened from General Journal Batches page.
        RunEditJournalActionOnJobGLJournalPage(JobGLJournal, GeneralJournalBatches);

        // [THEN] "Debit Amount", "Credit Amount" columns are not visible, "Amount" and "Amount (LCY)" column are visible on Job G/L Journal page.
        VerifyJobGLJnlPageDebitCreditAmtFieldsVisibility(JobGLJournal, false, false, true, true);
        GeneralJournalBatches.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowAmountsAllAmountsVisibilityChartOfAccounts()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ChartofAccounts: TestPage "Chart of Accounts";
    begin
        // [FEATURE] [Show Amounts] [Chart of Accounts]
        // [SCENARIO 275827] Amount columns visibility on Chart of Accounts page for Show Amount = "All Amounts" in General Ledger Setup.
        Initialize();

        // [GIVEN] General Ledger Setup with Show Amount = "All Amounts"
        SetShowAmounts(GeneralLedgerSetup."Show Amounts"::"All Amounts");

        // [WHEN] Chart of Accounts page is opened.
        ChartofAccounts.OpenView();

        // [THEN] "Debit Amount" and "Credit Amount" columns are visible on Chart of Accounts page.
        VerifyChartOfAccountsPageDebitCreditAmtFieldsVisibility(ChartofAccounts, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowAmountsDebitCreditOnlyVisibilityChartOfAccounts()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ChartofAccounts: TestPage "Chart of Accounts";
    begin
        // [FEATURE] [Show Amounts] [Chart of Accounts]
        // [SCENARIO 275827] Amount columns visibility on Chart of Accounts page for Show Amount = "Debit/Credit Only" in General Ledger Setup.
        Initialize();

        // [GIVEN] General Ledger Setup with Show Amount = "Debit/Credit Only"
        SetShowAmounts(GeneralLedgerSetup."Show Amounts"::"Debit/Credit Only");

        // [WHEN] Chart of Accounts page is opened.
        ChartofAccounts.OpenView();

        // [THEN] "Debit Amount", "Credit Amount" columns are visible on Chart of Accounts page.
        VerifyChartOfAccountsPageDebitCreditAmtFieldsVisibility(ChartofAccounts, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowAmountsAmountOnlyVisibilityChartOfAccounts()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ChartofAccounts: TestPage "Chart of Accounts";
    begin
        // [FEATURE] [Show Amounts] [Chart of Accounts]
        // [SCENARIO 275827] Amount columns visibility on Chart of Accounts page for Show Amount = "Amount Only" in General Ledger Setup.
        Initialize();

        // [GIVEN] General Ledger Setup with Show Amount = "Amount Only"
        SetShowAmounts(GeneralLedgerSetup."Show Amounts"::"Amount Only");

        // [WHEN] Chart of Accounts page is opened .
        ChartofAccounts.OpenView();

        // [THEN] "Debit Amount", "Credit Amount" columns are not visible on Chart of Accounts page.
        VerifyChartOfAccountsPageDebitCreditAmtFieldsVisibility(ChartofAccounts, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowAmountsAllAmountsVisibilityGeneralLedgerEntries()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GeneralLedgerEntries: TestPage "General Ledger Entries";
    begin
        // [FEATURE] [Show Amounts] [General Ledger Entries]
        // [SCENARIO 275827] Amount columns visibility on General Ledger Entries page for Show Amount = "All Amounts" in General Ledger Setup.
        Initialize();

        // [GIVEN] General Ledger Setup with Show Amount = "All Amounts"
        SetShowAmounts(GeneralLedgerSetup."Show Amounts"::"All Amounts");

        // [WHEN] General Ledger Entries page is opened.
        GeneralLedgerEntries.OpenView();

        // [THEN] "Debit Amount", "Credit Amount" and "Amount" columns are visible on General Ledger Entries page.
        VerifyGeneralLedgerEntriesPageDebitCreditAmtFieldsVisibility(GeneralLedgerEntries, true, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowAmountsDebitCreditOnlyVisibilityGeneralLedgerEntries()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GeneralLedgerEntries: TestPage "General Ledger Entries";
    begin
        // [FEATURE] [Show Amounts] [General Ledger Entries]
        // [SCENARIO 275827] Amount columns visibility on General Ledger Entries page for Show Amount = "Debit/Credit Only" in General Ledger Setup.
        Initialize();

        // [GIVEN] General Ledger Setup with Show Amount = "Debit/Credit Only"
        SetShowAmounts(GeneralLedgerSetup."Show Amounts"::"Debit/Credit Only");

        // [WHEN] General Ledger Entries page is opened.
        GeneralLedgerEntries.OpenView();

        // [THEN] "Debit Amount", "Credit Amount" columns are visible, "Amount" column is not visible on General Ledger Entries page.
        VerifyGeneralLedgerEntriesPageDebitCreditAmtFieldsVisibility(GeneralLedgerEntries, true, true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowAmountsAmountOnlyVisibilityGeneralLedgerEntries()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GeneralLedgerEntries: TestPage "General Ledger Entries";
    begin
        // [FEATURE] [Show Amounts] [General Ledger Entries]
        // [SCENARIO 275827] Amount columns visibility on General Ledger Entries page for Show Amount = "Amount Only" in General Ledger Setup.
        Initialize();

        // [GIVEN] General Ledger Setup with Show Amount = "Amount Only"
        SetShowAmounts(GeneralLedgerSetup."Show Amounts"::"Amount Only");

        // [WHEN] General Ledger Entries page is opened .
        GeneralLedgerEntries.OpenView();

        // [THEN] "Debit Amount", "Credit Amount" columns are not visible, "Amount" column is visible on General Ledger Entries page.
        VerifyGeneralLedgerEntriesPageDebitCreditAmtFieldsVisibility(GeneralLedgerEntries, false, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowAmountsAllAmountsVisibilityCustomerLedgerEntries()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        CustomerLedgerEntries: TestPage "Customer Ledger Entries";
    begin
        // [FEATURE] [Show Amounts] [Customer Ledger Entries]
        // [SCENARIO 275827] Amount columns visibility on Customer Ledger Entries page for Show Amount = "All Amounts" in General Ledger Setup.
        Initialize();

        // [GIVEN] General Ledger Setup with Show Amount = "All Amounts"
        SetShowAmounts(GeneralLedgerSetup."Show Amounts"::"All Amounts");

        // [WHEN] Customer Ledger Entries page is opened.
        CustomerLedgerEntries.OpenView();

        // [THEN] "Debit Amount", "Debit Amount (LCY)", "Credit Amount", "Credit Amount (LCY)", "Amount" and "Amount (LCY)" columns are visible on Customer Ledger Entries page.
        VerifyCustomerLedgerEntriesPageDebitCreditAmtFieldsVisibility(CustomerLedgerEntries, true, true, true, true, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowAmountsDebitCreditOnlyVisibilityCustomerLedgerEntries()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        CustomerLedgerEntries: TestPage "Customer Ledger Entries";
    begin
        // [FEATURE] [Show Amounts] [Customer Ledger Entries]
        // [SCENARIO 275827] Amount columns visibility on Customer Ledger Entries page for Show Amount = "Debit/Credit Only" in General Ledger Setup.
        Initialize();

        // [GIVEN] General Ledger Setup with Show Amount = "Debit/Credit Only"
        SetShowAmounts(GeneralLedgerSetup."Show Amounts"::"Debit/Credit Only");

        // [WHEN] Customer Ledger Entries page is opened.
        CustomerLedgerEntries.OpenView();

        // [THEN] "Debit Amount", "Debit Amount (LCY)", "Credit Amount", "Credit Amount (LCY)" columns are visible, "Amount" and "Amount (LCY)" column are not visible on Customer Ledger Entries page.
        VerifyCustomerLedgerEntriesPageDebitCreditAmtFieldsVisibility(CustomerLedgerEntries, true, true, true, true, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowAmountsAmountOnlyVisibilityCustomerLedgerEntries()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        CustomerLedgerEntries: TestPage "Customer Ledger Entries";
    begin
        // [FEATURE] [Show Amounts] [Customer Ledger Entries]
        // [SCENARIO 275827] Amount columns visibility on Customer Ledger Entries page for Show Amount = "Amount Only" in General Ledger Setup.
        Initialize();

        // [GIVEN] General Ledger Setup with Show Amount = "Amount Only"
        SetShowAmounts(GeneralLedgerSetup."Show Amounts"::"Amount Only");

        // [WHEN] Customer Ledger Entries page is opened .
        CustomerLedgerEntries.OpenView();

        // [THEN] "Debit Amount", "Debit Amount (LCY)", "Credit Amount", "Credit Amount (LCY)" columns are not visible, "Amount" and "Amount (LCY)" column is visible on Customer Ledger Entries page.
        VerifyCustomerLedgerEntriesPageDebitCreditAmtFieldsVisibility(CustomerLedgerEntries, false, false, false, false, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowAmountsAllAmountsVisibilitySalesJournalMoreColumnsMode()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalTemplate: Record "Gen. Journal Template";
        GeneralJournalBatches: TestPage "General Journal Batches";
        SalesJournal: TestPage "Sales Journal";
    begin
        // [FEATURE] [Show Amounts] [Sales]
        // [SCENARIO 275827] Verifying amount columns visibility on Sales Journal page opened in "Show More Columns" mode and General Ledger Setup having the setting Show Amount = "All Amounts".
        Initialize();

        // [GIVEN] General Ledger Setup with Show Amount = "All Amounts"
        SetShowAmounts(GeneralLedgerSetup."Show Amounts"::"All Amounts");

        // Setting the Sales Journal to "Show More Columns" mode for this test since by default the mode is set to "Show Fewer Columns".
        GenJnlManagement.SetJournalSimplePageModePreference(false, PAGE::"Sales Journal");

        // [GIVEN] General Journal Batch is created for Sales Template and selected on General Journal Batches page.
        PrepareTemplateBatchAndPageWithTypeAndReccuring(GeneralJournalBatches, GenJournalTemplate.Type::Sales, false);

        // [WHEN] Sales Journal page is opened from General Journal Batches page.
        RunEditJournalActionOnSalesJournalPage(SalesJournal, GeneralJournalBatches);

        // [THEN] "Debit Amount", "Credit Amount", "Amount" and "Amount (LCY)" columns are visible on Sales Journal page in "Show More Columns" mode.
        VerifySalesJnlPageDebitCreditAmtFieldsVisibility(SalesJournal, true, true, true, true);
        GeneralJournalBatches.Close();

        // Resetting the mode to "Show Fewer Columns" as the default view.
        GenJnlManagement.SetJournalSimplePageModePreference(true, PAGE::"Sales Journal");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowAmountsDebitCreditOnlyVisibilitySalesJournalMoreColumnsMode()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalTemplate: Record "Gen. Journal Template";
        GeneralJournalBatches: TestPage "General Journal Batches";
        SalesJournal: TestPage "Sales Journal";
    begin
        // [FEATURE] [Show Amounts] [Sales]
        // [SCENARIO 275827] Verifying amount columns visibility on Sales Journal page opened in "Show More Columns" mode and General Ledger Setup having the setting Show Amount = "Debit/Credit Only".
        Initialize();

        // [GIVEN] General Ledger Setup with Show Amount = "Debit/Credit Only"
        SetShowAmounts(GeneralLedgerSetup."Show Amounts"::"Debit/Credit Only");

        // Setting the Sales Journal to "Show More Columns" mode for this test since by default the mode is set to "Show Fewer Columns".
        GenJnlManagement.SetJournalSimplePageModePreference(false, PAGE::"Sales Journal");

        // [GIVEN] General Journal Batch is created for Sales Template and selected on General Journal Batches page.
        PrepareTemplateBatchAndPageWithTypeAndReccuring(GeneralJournalBatches, GenJournalTemplate.Type::Sales, false);

        // [WHEN] Sales Journal page is opened from General Journal Batches page.
        RunEditJournalActionOnSalesJournalPage(SalesJournal, GeneralJournalBatches);

        // [THEN] "Debit Amount", "Credit Amount" columns are visible, "Amount" and "Amount (LCY)" column are not visible on Sales Journal page in "Show More Columns" mode.
        VerifySalesJnlPageDebitCreditAmtFieldsVisibility(SalesJournal, true, true, false, false);
        GeneralJournalBatches.Close();

        // Resetting the mode to "Show Fewer Columns" as the default view.
        GenJnlManagement.SetJournalSimplePageModePreference(true, PAGE::"Sales Journal");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowAmountsAmountOnlyVisibilitySalesJournalMoreColumnsMode()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalTemplate: Record "Gen. Journal Template";
        GeneralJournalBatches: TestPage "General Journal Batches";
        SalesJournal: TestPage "Sales Journal";
    begin
        // [FEATURE] [Show Amounts] [Sales]
        // [SCENARIO 275827] Verifying amount columns visibility on Sales Journal page opened in "Show More Columns" mode and General Ledger Setup having the setting Show Amount = "Amount Only".
        Initialize();

        // [GIVEN] General Ledger Setup with Show Amount = "Amount Only"
        SetShowAmounts(GeneralLedgerSetup."Show Amounts"::"Amount Only");

        // Setting the Sales Journal to "Show More Columns" mode for this test since by default the mode is set to "Show Fewer Columns".
        GenJnlManagement.SetJournalSimplePageModePreference(false, PAGE::"Sales Journal");

        // [GIVEN] General Journal Batch is created for Sales Template and selected on General Journal Batches page.
        PrepareTemplateBatchAndPageWithTypeAndReccuring(GeneralJournalBatches, GenJournalTemplate.Type::Sales, false);

        // [WHEN] Sales Journal page is opened from General Journal Batches page.
        RunEditJournalActionOnSalesJournalPage(SalesJournal, GeneralJournalBatches);

        // [THEN] "Debit Amount", "Credit Amount" columns are not visible, "Amount" and "Amount (LCY)" column are visible on Sales Journal page in "Show More Columns" mode.
        VerifySalesJnlPageDebitCreditAmtFieldsVisibility(SalesJournal, false, false, true, true);
        GeneralJournalBatches.Close();

        // Resetting the mode to "Show Fewer Columns" as the default view.
        GenJnlManagement.SetJournalSimplePageModePreference(true, PAGE::"Sales Journal");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowAmountsAllAmountsVisibilitySalesJournalFewerColumnsMode()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalTemplate: Record "Gen. Journal Template";
        GeneralJournalBatches: TestPage "General Journal Batches";
        SalesJournal: TestPage "Sales Journal";
    begin
        // [FEATURE] [Show Amounts] [Sales]
        // [SCENARIO 275827] Verifying amount columns visibility on Sales Journal page opened in default mode "Show Fewer Columns" and General Ledger Setup having the setting Show Amount = "All Amounts".
        Initialize();

        // [GIVEN] General Ledger Setup with Show Amount = "All Amounts"
        SetShowAmounts(GeneralLedgerSetup."Show Amounts"::"All Amounts");

        // [GIVEN] General Journal Batch is created for Sales Template and selected on General Journal Batches page.
        PrepareTemplateBatchAndPageWithTypeAndReccuring(GeneralJournalBatches, GenJournalTemplate.Type::Sales, false);

        // [WHEN] Sales Journal page is opened from General Journal Batches page.
        RunEditJournalActionOnSalesJournalPage(SalesJournal, GeneralJournalBatches);

        // [THEN] "Debit Amount", "Credit Amount", "Amount" and "Amount (LCY)" columns are not visible on Sales Journal page in "Show Fewer Columns" mode.
        VerifySalesJnlPageDebitCreditAmtFieldsVisibility(SalesJournal, false, false, false, false);
        GeneralJournalBatches.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowAmountsDebitCreditOnlyVisibilitySalesJournalFewerColumnsMode()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalTemplate: Record "Gen. Journal Template";
        GeneralJournalBatches: TestPage "General Journal Batches";
        SalesJournal: TestPage "Sales Journal";
    begin
        // [FEATURE] [Show Amounts] [Sales]
        // [SCENARIO 275827] Verifying amount columns visibility on Sales Journal page opened in default mode "Show Fewer Columns" and General Ledger Setup having the setting Show Amount = "Debit/Credit Only".
        Initialize();

        // [GIVEN] General Ledger Setup with Show Amount = "Debit/Credit Only"
        SetShowAmounts(GeneralLedgerSetup."Show Amounts"::"Debit/Credit Only");

        // [GIVEN] General Journal Batch is created for Sales Template and selected on General Journal Batches page.
        PrepareTemplateBatchAndPageWithTypeAndReccuring(GeneralJournalBatches, GenJournalTemplate.Type::Sales, false);

        // [WHEN] Sales Journal page is opened from General Journal Batches page.
        RunEditJournalActionOnSalesJournalPage(SalesJournal, GeneralJournalBatches);

        // [THEN] "Debit Amount", "Credit Amount", "Amount" and "Amount (LCY)" columns are not visible on Sales Journal page in "Show Fewer Columns" mode.
        VerifySalesJnlPageDebitCreditAmtFieldsVisibility(SalesJournal, false, false, false, false);
        GeneralJournalBatches.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowAmountsAmountOnlyVisibilitySalesJournalFewerColumnsMode()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalTemplate: Record "Gen. Journal Template";
        GeneralJournalBatches: TestPage "General Journal Batches";
        SalesJournal: TestPage "Sales Journal";
    begin
        // [FEATURE] [Show Amounts] [Sales]
        // [SCENARIO 275827] Verifying amount columns visibility on Sales Journal page opened in default mode "Show Fewer Columns" and General Ledger Setup having the setting Show Amount = "Amount Only".
        Initialize();

        // [GIVEN] General Ledger Setup with Show Amount = "Amount Only"
        SetShowAmounts(GeneralLedgerSetup."Show Amounts"::"Amount Only");

        // [GIVEN] General Journal Batch is created for Sales Template and selected on General Journal Batches page.
        PrepareTemplateBatchAndPageWithTypeAndReccuring(GeneralJournalBatches, GenJournalTemplate.Type::Sales, false);

        // [WHEN] Sales Journal page is opened from General Journal Batches page.
        RunEditJournalActionOnSalesJournalPage(SalesJournal, GeneralJournalBatches);

        // [THEN] "Debit Amount", "Credit Amount", "Amount" and "Amount (LCY)" columns are not visible on Sales Journal page in "Show Fewer Columns" mode.
        VerifySalesJnlPageDebitCreditAmtFieldsVisibility(SalesJournal, false, false, false, false);
        GeneralJournalBatches.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowAmountsAllAmountsVisibilityPurchaseJournalMoreColumnsMode()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalTemplate: Record "Gen. Journal Template";
        GeneralJournalBatches: TestPage "General Journal Batches";
        PurchaseJournal: TestPage "Purchase Journal";
    begin
        // [FEATURE] [Show Amounts] [Purchase]
        // [SCENARIO 275827] Verifying amount columns visibility on Purchase Journal page opened in "Show More Columns" mode and General Ledger Setup having the setting Show Amount = "All Amounts".
        Initialize();

        // [GIVEN] General Ledger Setup with Show Amount = "All Amounts"
        SetShowAmounts(GeneralLedgerSetup."Show Amounts"::"All Amounts");

        // Setting the Purchase Journal to "Show More Columns" mode for this test since by default the mode is set to "Show Fewer Columns".
        GenJnlManagement.SetJournalSimplePageModePreference(false, PAGE::"Purchase Journal");

        // [GIVEN] General Journal Batch is created for Purchases Template and selected on General Journal Batches page.
        PrepareTemplateBatchAndPageWithTypeAndReccuring(GeneralJournalBatches, GenJournalTemplate.Type::Purchases, false);

        // [WHEN] Purchase Journal page is opened from General Journal Batches page.
        RunEditJournalActionOnPurchaseJournalPage(PurchaseJournal, GeneralJournalBatches);

        // [THEN] "Debit Amount", "Credit Amount", "Amount" and "Amount (LCY)" columns are visible on Purchase Journal page in "Show More Columns" mode.
        VerifyPurchaseJnlPageDebitCreditAmtFieldsVisibility(PurchaseJournal, true, true, true, true);
        GeneralJournalBatches.Close();

        // Resetting the mode to "Show Fewer Columns" as the default view.
        GenJnlManagement.SetJournalSimplePageModePreference(true, PAGE::"Purchase Journal");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowAmountsDebitCreditOnlyVisibilityPurchaseJournalMoreColumnsMode()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalTemplate: Record "Gen. Journal Template";
        GeneralJournalBatches: TestPage "General Journal Batches";
        PurchaseJournal: TestPage "Purchase Journal";
    begin
        // [FEATURE] [Show Amounts] [Purchase]
        // [SCENARIO 275827] Verifying amount columns visibility on Purchase Journal page opened in "Show More Columns" mode and General Ledger Setup having the setting Show Amount = "Debit/Credit Only".
        Initialize();

        // Setting the Purchase Journal to "Show More Columns" mode for this test since by default the mode is set to "Show Fewer Columns".
        GenJnlManagement.SetJournalSimplePageModePreference(false, PAGE::"Purchase Journal");

        // [GIVEN] General Ledger Setup with Show Amount = "Debit/Credit Only"
        SetShowAmounts(GeneralLedgerSetup."Show Amounts"::"Debit/Credit Only");

        // [GIVEN] General Journal Batch is created for Purchases Template and selected on General Journal Batches page.
        PrepareTemplateBatchAndPageWithTypeAndReccuring(GeneralJournalBatches, GenJournalTemplate.Type::Purchases, false);

        // [WHEN] Purchase Journal page is opened from General Journal Batches page.
        RunEditJournalActionOnPurchaseJournalPage(PurchaseJournal, GeneralJournalBatches);

        // [THEN] "Debit Amount", "Credit Amount" columns are visible, "Amount" and "Amount (LCY)" column are not visible on Purchase Journal page in "Show More Columns" mode.
        VerifyPurchaseJnlPageDebitCreditAmtFieldsVisibility(PurchaseJournal, true, true, false, false);
        GeneralJournalBatches.Close();

        // Resetting the mode to "Show Fewer Columns" as the default view.
        GenJnlManagement.SetJournalSimplePageModePreference(true, PAGE::"Purchase Journal");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowAmountsAmountOnlyVisibilityPurchaseJournalMoreColumnsMode()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalTemplate: Record "Gen. Journal Template";
        GeneralJournalBatches: TestPage "General Journal Batches";
        PurchaseJournal: TestPage "Purchase Journal";
    begin
        // [FEATURE] [Show Amounts] [Purchase]
        // [SCENARIO 275827] Verifying amount columns visibility on Purchase Journal page opened in "Show More Columns" mode and General Ledger Setup having the setting Show Amount = "Amount Only".
        Initialize();

        // Setting the Purchase Journal to "Show More Columns" mode for this test since by default the mode is set to "Show Fewer Columns".
        GenJnlManagement.SetJournalSimplePageModePreference(false, PAGE::"Purchase Journal");

        // [GIVEN] General Ledger Setup with Show Amount = "Amount Only"
        SetShowAmounts(GeneralLedgerSetup."Show Amounts"::"Amount Only");

        // [GIVEN] General Journal Batch is created for Purchases Template and selected on General Journal Batches page.
        PrepareTemplateBatchAndPageWithTypeAndReccuring(GeneralJournalBatches, GenJournalTemplate.Type::Purchases, false);

        // [WHEN] Purchase Journal page is opened from General Journal Batches page.
        RunEditJournalActionOnPurchaseJournalPage(PurchaseJournal, GeneralJournalBatches);

        // [THEN] "Debit Amount", "Credit Amount" columns are not visible, "Amount" and "Amount (LCY)" column are visible on Purchase Journal page in "Show More Columns" mode.
        VerifyPurchaseJnlPageDebitCreditAmtFieldsVisibility(PurchaseJournal, false, false, true, true);
        GeneralJournalBatches.Close();

        // Resetting the mode to "Show Fewer Columns" as the default view.
        GenJnlManagement.SetJournalSimplePageModePreference(true, PAGE::"Purchase Journal");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowAmountsAllAmountsVisibilityPurchaseJournalFewerColumnsMode()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalTemplate: Record "Gen. Journal Template";
        GeneralJournalBatches: TestPage "General Journal Batches";
        PurchaseJournal: TestPage "Purchase Journal";
    begin
        // [FEATURE] [Show Amounts] [Purchase]
        // [SCENARIO 275827] Verifying amount columns visibility on Purchase Journal page opened in default mode "Show Fewer Columns" and General Ledger Setup having the setting Show Amount = "All Amounts".
        Initialize();

        // [GIVEN] General Ledger Setup with Show Amount = "All Amounts"
        SetShowAmounts(GeneralLedgerSetup."Show Amounts"::"All Amounts");

        // [GIVEN] General Journal Batch is created for Purchases Template and selected on General Journal Batches page.
        PrepareTemplateBatchAndPageWithTypeAndReccuring(GeneralJournalBatches, GenJournalTemplate.Type::Purchases, false);

        // [WHEN] Purchase Journal page is opened from General Journal Batches page.
        RunEditJournalActionOnPurchaseJournalPage(PurchaseJournal, GeneralJournalBatches);

        // [THEN] "Debit Amount", "Credit Amount", "Amount" and "Amount (LCY)" columns are not visible on Purchase Journal page in "Show Fewer Columns" mode.
        VerifyPurchaseJnlPageDebitCreditAmtFieldsVisibility(PurchaseJournal, false, false, false, false);
        GeneralJournalBatches.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowAmountsDebitCreditOnlyVisibilityPurchaseJournalFewerColumnsMode()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalTemplate: Record "Gen. Journal Template";
        GeneralJournalBatches: TestPage "General Journal Batches";
        PurchaseJournal: TestPage "Purchase Journal";
    begin
        // [FEATURE] [Show Amounts] [Purchase]
        // [SCENARIO 275827] Verifying amount columns visibility on Purchase Journal page opened in default mode "Show Fewer Columns" and General Ledger Setup having the setting Show Amount = "Debit/Credit Only".
        Initialize();

        // [GIVEN] General Ledger Setup with Show Amount = "Debit/Credit Only"
        SetShowAmounts(GeneralLedgerSetup."Show Amounts"::"Debit/Credit Only");

        // [GIVEN] General Journal Batch is created for Purchases Template and selected on General Journal Batches page.
        PrepareTemplateBatchAndPageWithTypeAndReccuring(GeneralJournalBatches, GenJournalTemplate.Type::Purchases, false);

        // [WHEN] Purchase Journal page is opened from General Journal Batches page.
        RunEditJournalActionOnPurchaseJournalPage(PurchaseJournal, GeneralJournalBatches);

        // [THEN] "Debit Amount", "Credit Amount", "Amount" and "Amount (LCY)" columns are not visible on Purchase Journal page in "Show Fewer Columns" mode.
        VerifyPurchaseJnlPageDebitCreditAmtFieldsVisibility(PurchaseJournal, false, false, false, false);
        GeneralJournalBatches.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowAmountsAmountOnlyVisibilityPurchaseJournalFewerColumnsMode()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalTemplate: Record "Gen. Journal Template";
        GeneralJournalBatches: TestPage "General Journal Batches";
        PurchaseJournal: TestPage "Purchase Journal";
    begin
        // [FEATURE] [Show Amounts] [Purchase]
        // [SCENARIO 275827] Verifying amount columns visibility on Purchase Journal page opened in default mode "Show Fewer Columns" and General Ledger Setup having the setting Show Amount = "Amount Only".
        Initialize();

        // [GIVEN] General Ledger Setup with Show Amount = "Amount Only"
        SetShowAmounts(GeneralLedgerSetup."Show Amounts"::"Amount Only");

        // [GIVEN] General Journal Batch is created for Purchases Template and selected on General Journal Batches page.
        PrepareTemplateBatchAndPageWithTypeAndReccuring(GeneralJournalBatches, GenJournalTemplate.Type::Purchases, false);

        // [WHEN] Purchase Journal page is opened from General Journal Batches page.
        RunEditJournalActionOnPurchaseJournalPage(PurchaseJournal, GeneralJournalBatches);

        // [THEN] "Debit Amount", "Credit Amount", "Amount" and "Amount (LCY)" columns are not visible on Purchase Journal page in "Show Fewer Columns" mode.
        VerifyPurchaseJnlPageDebitCreditAmtFieldsVisibility(PurchaseJournal, false, false, false, false);
        GeneralJournalBatches.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowAmountsAllAmountsVisibilityCashReceiptJournal()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalTemplate: Record "Gen. Journal Template";
        GeneralJournalBatches: TestPage "General Journal Batches";
        CashReceiptJournal: TestPage "Cash Receipt Journal";
    begin
        // [FEATURE] [Show Amounts] [Cash Receipt]
        // [SCENARIO 275827] Amount columns visibility on Cash Receipt Journal page for Show Amount = "All Amounts" in General Ledger Setup.
        Initialize();

        // [GIVEN] General Ledger Setup with Show Amount = "All Amounts"
        SetShowAmounts(GeneralLedgerSetup."Show Amounts"::"All Amounts");

        // [GIVEN] General Journal Batch is created for Cash Receipts Template and selected on General Journal Batches page.
        PrepareTemplateBatchAndPageWithTypeAndReccuring(GeneralJournalBatches, GenJournalTemplate.Type::"Cash Receipts", false);

        // [WHEN] Cash Receipt Journal page is opened from General Journal Batches page.
        RunEditJournalActionOnCashReceiptJournalPage(CashReceiptJournal, GeneralJournalBatches);

        // [THEN] "Debit Amount", "Credit Amount", "Amount" and "Amount (LCY)" columns are visible on Cash Receipt Journal page.
        VerifyCashReceiptJnlPageDebitCreditAmtFieldsVisibility(CashReceiptJournal, true, true, true, true);
        GeneralJournalBatches.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowAmountsDebitCreditOnlyVisibilityCashReceiptJournal()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalTemplate: Record "Gen. Journal Template";
        GeneralJournalBatches: TestPage "General Journal Batches";
        CashReceiptJournal: TestPage "Cash Receipt Journal";
    begin
        // [FEATURE] [Show Amounts] [Cash Receipt]
        // [SCENARIO 275827] Amount columns visibility on Cash Receipt Journal page for Show Amount = "Debit/Credit Only" in General Ledger Setup.
        Initialize();

        // [GIVEN] General Ledger Setup with Show Amount = "Debit/Credit Only"
        SetShowAmounts(GeneralLedgerSetup."Show Amounts"::"Debit/Credit Only");

        // [GIVEN] General Journal Batch is created for Cash Receipts Template and selected on General Journal Batches page.
        PrepareTemplateBatchAndPageWithTypeAndReccuring(GeneralJournalBatches, GenJournalTemplate.Type::"Cash Receipts", false);

        // [WHEN] Cash Receipt Journal page is opened from General Journal Batches page.
        RunEditJournalActionOnCashReceiptJournalPage(CashReceiptJournal, GeneralJournalBatches);

        // [THEN] "Debit Amount", "Credit Amount" columns are visible, "Amount" and "Amount (LCY)" column are not visible on Cash Receipt Journal page.
        VerifyCashReceiptJnlPageDebitCreditAmtFieldsVisibility(CashReceiptJournal, true, true, false, false);
        GeneralJournalBatches.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowAmountsAmountOnlyVisibilityCashReceiptJournal()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalTemplate: Record "Gen. Journal Template";
        GeneralJournalBatches: TestPage "General Journal Batches";
        CashReceiptJournal: TestPage "Cash Receipt Journal";
    begin
        // [FEATURE] [Show Amounts] [Cash Receipt]
        // [SCENARIO 275827] Amount columns visibility on Cash Receipt Journal page for Show Amount = "Amount Only" in General Ledger Setup.
        Initialize();

        // [GIVEN] General Ledger Setup with Show Amount = "Amount Only"
        SetShowAmounts(GeneralLedgerSetup."Show Amounts"::"Amount Only");

        // [GIVEN] General Journal Batch is created for Cash Receipts Template and selected on General Journal Batches page.
        PrepareTemplateBatchAndPageWithTypeAndReccuring(GeneralJournalBatches, GenJournalTemplate.Type::"Cash Receipts", false);

        // [WHEN] Cash Receipt Journal page is opened from General Journal Batches page.
        RunEditJournalActionOnCashReceiptJournalPage(CashReceiptJournal, GeneralJournalBatches);

        // [THEN] "Debit Amount", "Credit Amount" columns are not visible, "Amount" and "Amount (LCY)" column are visible on Cash Receipt Journal page.
        VerifyCashReceiptJnlPageDebitCreditAmtFieldsVisibility(CashReceiptJournal, false, false, true, true);
        GeneralJournalBatches.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowAmountsAllAmountsVisibilityRecurringGeneralJournal()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalTemplate: Record "Gen. Journal Template";
        GeneralJournalBatches: TestPage "General Journal Batches";
        RecurringGeneralJournal: TestPage "Recurring General Journal";
    begin
        // [FEATURE] [Show Amounts] [Recurring General]
        // [SCENARIO 275827] Amount columns visibility on Recurring General Journal page for Show Amount = "All Amounts" in General Ledger Setup.
        Initialize();

        // [GIVEN] General Ledger Setup with Show Amount = "All Amounts"
        SetShowAmounts(GeneralLedgerSetup."Show Amounts"::"All Amounts");

        // [GIVEN] General Journal Batch is created for General Template and selected on General Journal Batches page.
        PrepareTemplateBatchAndPageWithTypeAndReccuring(GeneralJournalBatches, GenJournalTemplate.Type::General, true);

        // [WHEN] Recurring General Journal page is opened from General Journal Batches page.
        RunEditJournalActionOnRecurringGeneralJournalPage(RecurringGeneralJournal, GeneralJournalBatches);

        // [THEN] "Debit Amount", "Credit Amount", "Amount" and "Amount (LCY)" columns are visible on Recurring General Journal page.
        VerifyRecurringGeneralJnlPageDebitCreditAmtFieldsVisibility(RecurringGeneralJournal, true, true, true, true);
        GeneralJournalBatches.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowAmountsDebitCreditOnlyVisibilityRecurringGeneralJournal()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalTemplate: Record "Gen. Journal Template";
        GeneralJournalBatches: TestPage "General Journal Batches";
        RecurringGeneralJournal: TestPage "Recurring General Journal";
    begin
        // [FEATURE] [Show Amounts] [Recurring General]
        // [SCENARIO 275827] Amount columns visibility on Recurring General Journal page for Show Amount = "Debit/Credit Only" in General Ledger Setup.
        Initialize();

        // [GIVEN] General Ledger Setup with Show Amount = "Debit/Credit Only"
        SetShowAmounts(GeneralLedgerSetup."Show Amounts"::"Debit/Credit Only");

        // [GIVEN] General Journal Batch is created for General Template and selected on General Journal Batches page.
        PrepareTemplateBatchAndPageWithTypeAndReccuring(GeneralJournalBatches, GenJournalTemplate.Type::General, true);

        // [WHEN] Recurring General Journal page is opened from General Journal Batches page.
        RunEditJournalActionOnRecurringGeneralJournalPage(RecurringGeneralJournal, GeneralJournalBatches);

        // [THEN] "Debit Amount", "Credit Amount" columns are visible, "Amount" and "Amount (LCY)" column are not visible on Recurring General Journal page.
        VerifyRecurringGeneralJnlPageDebitCreditAmtFieldsVisibility(RecurringGeneralJournal, true, true, false, false);
        GeneralJournalBatches.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowAmountsAmountOnlyVisibilityRecurringGeneralJournal()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalTemplate: Record "Gen. Journal Template";
        GeneralJournalBatches: TestPage "General Journal Batches";
        RecurringGeneralJournal: TestPage "Recurring General Journal";
    begin
        // [FEATURE] [Show Amounts] [Recurring General]
        // [SCENARIO 275827] Amount columns visibility on Recurring General Journal page for Show Amount = "Amount Only" in General Ledger Setup.
        Initialize();

        // [GIVEN] General Ledger Setup with Show Amount = "Amount Only"
        SetShowAmounts(GeneralLedgerSetup."Show Amounts"::"Amount Only");

        // [GIVEN] General Journal Batch is created for General Template and selected on General Journal Batches page.
        PrepareTemplateBatchAndPageWithTypeAndReccuring(GeneralJournalBatches, GenJournalTemplate.Type::General, true);

        // [WHEN] Recurring General Journal page is opened from General Journal Batches page.
        RunEditJournalActionOnRecurringGeneralJournalPage(RecurringGeneralJournal, GeneralJournalBatches);

        // [THEN] "Debit Amount", "Credit Amount" columns are not visible, "Amount" and "Amount (LCY)" column are visible on Recurring General Journal page.
        VerifyRecurringGeneralJnlPageDebitCreditAmtFieldsVisibility(RecurringGeneralJournal, false, false, true, true);
        GeneralJournalBatches.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowAmountsAllAmountsVisibilityVendorLedgerEntries()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
    begin
        // [FEATURE] [Show Amounts] [Vendor Ledger Entries]
        // [SCENARIO 275827] Amount columns visibility on Vendor Ledger Entries page for Show Amount = "All Amounts" in General Ledger Setup.
        Initialize();

        // [GIVEN] General Ledger Setup with Show Amount = "All Amounts"
        SetShowAmounts(GeneralLedgerSetup."Show Amounts"::"All Amounts");

        // [WHEN] Vendor Ledger Entries page is opened.
        VendorLedgerEntries.OpenView();

        // [THEN] "Debit Amount", "Debit Amount (LCY)", "Credit Amount", "Credit Amount (LCY)", "Amount" and "Amount (LCY)" columns are visible on Vendor Ledger Entries page.
        VerifyVendorLedgerEntriesPageDebitCreditAmtFieldsVisibility(VendorLedgerEntries, true, true, true, true, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowAmountsDebitCreditOnlyVisibilityVendorLedgerEntries()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
    begin
        // [FEATURE] [Show Amounts] [Vendor Ledger Entries]
        // [SCENARIO 275827] Amount columns visibility on Vendor Ledger Entries page for Show Amount = "Debit/Credit Only" in General Ledger Setup.
        Initialize();

        // [GIVEN] General Ledger Setup with Show Amount = "Debit/Credit Only"
        SetShowAmounts(GeneralLedgerSetup."Show Amounts"::"Debit/Credit Only");

        // [WHEN] Vendor Ledger Entries page is opened.
        VendorLedgerEntries.OpenView();

        // [THEN] "Debit Amount", "Debit Amount (LCY)", "Credit Amount", "Credit Amount (LCY)" columns are visible, "Amount" and "Amount (LCY)" column are not visible on Vendor Ledger Entries page.
        VerifyVendorLedgerEntriesPageDebitCreditAmtFieldsVisibility(VendorLedgerEntries, true, true, true, true, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowAmountsAmountOnlyVisibilityVendorLedgerEntries()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
    begin
        // [FEATURE] [Show Amounts] [Vendor Ledger Entries]
        // [SCENARIO 275827] Amount columns visibility on Vendor Ledger Entries page for Show Amount = "Amount Only" in General Ledger Setup.
        Initialize();

        // [GIVEN] General Ledger Setup with Show Amount = "Amount Only"
        SetShowAmounts(GeneralLedgerSetup."Show Amounts"::"Amount Only");

        // [WHEN] Vendor Ledger Entries page is opened .
        VendorLedgerEntries.OpenView();

        // [THEN] "Debit Amount", "Debit Amount (LCY)", "Credit Amount", "Credit Amount (LCY)" columns are not visible, "Amount" and "Amount (LCY)" column are visible on Vendor Ledger Entries page.
        VerifyVendorLedgerEntriesPageDebitCreditAmtFieldsVisibility(VendorLedgerEntries, false, false, false, false, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowAmountsAllAmountsVisibilityApplyBankAccLedgerEntries()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ApplyBankAccLedgerEntries: TestPage "Apply Bank Acc. Ledger Entries";
    begin
        // [FEATURE] [Show Amounts] [Apply Bank Acc Ledger Entries]
        // [SCENARIO 275827] Amount columns visibility on Apply Bank Acc. Ledger Entries page for Show Amount = "All Amounts" in General Ledger Setup.
        Initialize();

        // [GIVEN] General Ledger Setup with Show Amount = "All Amounts"
        SetShowAmounts(GeneralLedgerSetup."Show Amounts"::"All Amounts");

        // [WHEN] Apply Bank Acc. Ledger Entries page is opened.
        ApplyBankAccLedgerEntries.OpenView();

        // [THEN] "Debit Amount", "Credit Amount", "Amount" columns are visible on Apply Bank Acc. Ledger Entries page.
        VerifyApplyBankAccLedgerEntriesPageDebitCreditAmtFieldsVisibility(ApplyBankAccLedgerEntries, true, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowAmountsDebitCreditOnlyVisibilityApplyBankAccLedgerEntries()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ApplyBankAccLedgerEntries: TestPage "Apply Bank Acc. Ledger Entries";
    begin
        // [FEATURE] [Show Amounts] [Apply Bank Acc Ledger Entries]
        // [SCENARIO 275827] Amount columns visibility on Apply Bank Acc. Ledger Entries page for Show Amount = "Debit/Credit Only" in General Ledger Setup.
        Initialize();

        // [GIVEN] General Ledger Setup with Show Amount = "Debit/Credit Only"
        SetShowAmounts(GeneralLedgerSetup."Show Amounts"::"Debit/Credit Only");

        // [WHEN] Apply Bank Acc. Ledger Entries page is opened.
        ApplyBankAccLedgerEntries.OpenView();

        // [THEN] "Debit Amount", "Credit Amount" columns are visible, "Amount" column is not visible on Apply Bank Acc. Ledger Entries page.
        VerifyApplyBankAccLedgerEntriesPageDebitCreditAmtFieldsVisibility(ApplyBankAccLedgerEntries, true, true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowAmountsAmountOnlyVisibilityApplyBankAccLedgerEntries()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ApplyBankAccLedgerEntries: TestPage "Apply Bank Acc. Ledger Entries";
    begin
        // [FEATURE] [Show Amounts] [Apply Bank Acc Ledger Entries]
        // [SCENARIO 275827] Amount columns visibility on Apply Bank Acc. Ledger Entries page for Show Amount = "Amount Only" in General Ledger Setup.
        Initialize();

        // [GIVEN] General Ledger Setup with Show Amount = "Amount Only"
        SetShowAmounts(GeneralLedgerSetup."Show Amounts"::"Amount Only");

        // [WHEN] Apply Bank Acc. Ledger Entries page is opened .
        ApplyBankAccLedgerEntries.OpenView();

        // [THEN] "Debit Amount", "Credit Amount" columns are not visible, "Amount" column is visible on Apply Bank Acc. Ledger Entries page.
        VerifyApplyBankAccLedgerEntriesPageDebitCreditAmtFieldsVisibility(ApplyBankAccLedgerEntries, false, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowAmountsAllAmountsVisibilityDetailedCustLedgEntries()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DetailedCustLedgEntries: TestPage "Detailed Cust. Ledg. Entries";
    begin
        // [FEATURE] [Show Amounts] [Detailed Cust Ledg Entries]
        // [SCENARIO 275827] Amount columns visibility on Detailed Cust. Ledg. Entries page for Show Amount = "All Amounts" in General Ledger Setup.
        Initialize();

        // [GIVEN] General Ledger Setup with Show Amount = "All Amounts"
        SetShowAmounts(GeneralLedgerSetup."Show Amounts"::"All Amounts");

        // [WHEN] Detailed Cust. Ledg. Entries page is opened.
        DetailedCustLedgEntries.OpenView();

        // [THEN] "Debit Amount", "Debit Amount (LCY)", "Credit Amount", "Credit Amount (LCY)", "Amount" and "Amount (LCY)" columns are visible on Detailed Cust. Ledg. Entries page.
        VerifyDetailedCustLedgEntriesPageDebitCreditAmtFieldsVisibility(DetailedCustLedgEntries, true, true, true, true, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowAmountsDebitCreditOnlyVisibilityDetailedCustLedgEntries()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DetailedCustLedgEntries: TestPage "Detailed Cust. Ledg. Entries";
    begin
        // [FEATURE] [Show Amounts] [Detailed Cust Ledg Entries]
        // [SCENARIO 275827] Amount columns visibility on Detailed Cust. Ledg. Entries page for Show Amount = "Debit/Credit Only" in General Ledger Setup.
        Initialize();

        // [GIVEN] General Ledger Setup with Show Amount = "Debit/Credit Only"
        SetShowAmounts(GeneralLedgerSetup."Show Amounts"::"Debit/Credit Only");

        // [WHEN] Detailed Cust. Ledg. Entries page is opened.
        DetailedCustLedgEntries.OpenView();

        // [THEN] "Debit Amount", "Debit Amount (LCY)", "Credit Amount", "Credit Amount (LCY)" columns are visible, "Amount" and "Amount (LCY)" column are not visible on Detailed Cust. Ledg. Entries page.
        VerifyDetailedCustLedgEntriesPageDebitCreditAmtFieldsVisibility(DetailedCustLedgEntries, true, true, true, true, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowAmountsAmountOnlyVisibilityDetailedCustLedgEntries()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DetailedCustLedgEntries: TestPage "Detailed Cust. Ledg. Entries";
    begin
        // [FEATURE] [Show Amounts] [Detailed Cust Ledg Entries]
        // [SCENARIO 275827] Amount columns visibility on Detailed Cust. Ledg. Entries page for Show Amount = "Amount Only" in General Ledger Setup.
        Initialize();

        // [GIVEN] General Ledger Setup with Show Amount = "Amount Only"
        SetShowAmounts(GeneralLedgerSetup."Show Amounts"::"Amount Only");

        // [WHEN] Detailed Cust. Ledg. Entries page is opened.
        DetailedCustLedgEntries.OpenView();

        // [THEN] "Debit Amount", "Debit Amount (LCY)", "Credit Amount", "Credit Amount (LCY)" columns are not visible, "Amount" and "Amount (LCY)" column are visible on Detailed Cust. Ledg. Entries page.
        VerifyDetailedCustLedgEntriesPageDebitCreditAmtFieldsVisibility(DetailedCustLedgEntries, false, false, false, false, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowAmountsAllAmountsVisibilityDetailedVendorLedgEntries()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DetailedVendorLedgEntries: TestPage "Detailed Vendor Ledg. Entries";
    begin
        // [FEATURE] [Show Amounts] [Detailed Vendor Ledg Entries]
        // [SCENARIO 275827] Amount columns visibility on Detailed Vendor. Ledg Entries page for Show Amount = "All Amounts" in General Ledger Setup.
        Initialize();

        // [GIVEN] General Ledger Setup with Show Amount = "All Amounts"
        SetShowAmounts(GeneralLedgerSetup."Show Amounts"::"All Amounts");

        // [WHEN] Detailed Vendor Ledg. Entries page is opened.
        DetailedVendorLedgEntries.OpenView();

        // [THEN] "Debit Amount", "Debit Amount (LCY)", "Credit Amount", "Credit Amount (LCY)", "Amount" and "Amount (LCY)" columns are visible on Detailed Vendor Ledg. Entries page.
        VerifyDetailedVendorLedgEntriesPageDebitCreditAmtFieldsVisibility(DetailedVendorLedgEntries, true, true, true, true, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowAmountsDebitCreditOnlyVisibilityDetailedVendorLedgEntries()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DetailedVendorLedgEntries: TestPage "Detailed Vendor Ledg. Entries";
    begin
        // [FEATURE] [Show Amounts] [Detailed Vendor Ledg Entries]
        // [SCENARIO 275827] Amount columns visibility on Detailed Vendor Ledg. Entries page for Show Amount = "Debit/Credit Only" in General Ledger Setup.
        Initialize();

        // [GIVEN] General Ledger Setup with Show Amount = "Debit/Credit Only"
        SetShowAmounts(GeneralLedgerSetup."Show Amounts"::"Debit/Credit Only");

        // [WHEN] Detailed Vendor Ledg. Entries page is opened.
        DetailedVendorLedgEntries.OpenView();

        // [THEN] "Debit Amount", "Debit Amount (LCY)", "Credit Amount", "Credit Amount (LCY)" columns are visible, "Amount" and "Amount (LCY)" column are not visible on Detailed Vendor Ledg. Entries page.
        VerifyDetailedVendorLedgEntriesPageDebitCreditAmtFieldsVisibility(DetailedVendorLedgEntries, true, true, true, true, false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowAmountsAmountOnlyVisibilityDetailedVendorLedgEntries()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DetailedVendorLedgEntries: TestPage "Detailed Vendor Ledg. Entries";
    begin
        // [FEATURE] [Show Amounts] [Detailed Vendor Ledg Entries]
        // [SCENARIO 275827] Amount columns visibility on Detailed Vendor Ledg. Entries page for Show Amount = "Amount Only" in General Ledger Setup.
        Initialize();

        // [GIVEN] General Ledger Setup with Show Amount = "Amount Only"
        SetShowAmounts(GeneralLedgerSetup."Show Amounts"::"Amount Only");

        // [WHEN] Detailed Vendor Ledg. Entries page is opened.
        DetailedVendorLedgEntries.OpenView();

        // [THEN] "Debit Amount", "Debit Amount (LCY)", "Credit Amount", "Credit Amount (LCY)" columns are not visible, "Amount" and "Amount (LCY)" column are visible on Detailed Vendor Ledg. Entries page.
        VerifyDetailedVendorLedgEntriesPageDebitCreditAmtFieldsVisibility(DetailedVendorLedgEntries, false, false, false, false, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowAmountsAllAmountsVisibilityAppliedVendorEntries()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        AppliedVendorEntries: TestPage "Applied Vendor Entries";
    begin
        // [FEATURE] [Show Amounts] [Applied Vendor Entries]
        // [SCENARIO 275827] Amount columns visibility on Applied Vendor Entries page for Show Amount = "All Amounts" in General Ledger Setup.
        Initialize();

        // [GIVEN] General Ledger Setup with Show Amount = "All Amounts"
        SetShowAmounts(GeneralLedgerSetup."Show Amounts"::"All Amounts");

        // [WHEN] Applied Vendor Entries page is opened.
        AppliedVendorEntries.OpenView();

        // [THEN] "Debit Amount", "Credit Amount", "Amount" columns are visible on Applied Vendor Entries page.
        VerifyAppliedVendorEntriesPageDebitCreditAmtFieldsVisibility(AppliedVendorEntries, true, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowAmountsDebitCreditOnlyVisibilityAppliedVendorEntries()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        AppliedVendorEntries: TestPage "Applied Vendor Entries";
    begin
        // [FEATURE] [Show Amounts] [Applied Vendor Entries]
        // [SCENARIO 275827] Amount columns visibility on Applied Vendor Entries page for Show Amount = "Debit/Credit Only" in General Ledger Setup.
        Initialize();

        // [GIVEN] General Ledger Setup with Show Amount = "Debit/Credit Only"
        SetShowAmounts(GeneralLedgerSetup."Show Amounts"::"Debit/Credit Only");

        // [WHEN] Applied Vendor Entries page is opened.
        AppliedVendorEntries.OpenView();

        // [THEN] "Debit Amount", "Credit Amount" columns are visible, "Amount" column is not visible on Applied Vendor Entries page.
        VerifyAppliedVendorEntriesPageDebitCreditAmtFieldsVisibility(AppliedVendorEntries, true, true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowAmountsAmountOnlyVisibilityAppliedVendorEntries()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        AppliedVendorEntries: TestPage "Applied Vendor Entries";
    begin
        // [FEATURE] [Show Amounts] [Applied Vendor Entries]
        // [SCENARIO 275827] Amount columns visibility on Applied Vendor Entries page for Show Amount = "Amount Only" in General Ledger Setup.
        Initialize();

        // [GIVEN] General Ledger Setup with Show Amount = "Amount Only"
        SetShowAmounts(GeneralLedgerSetup."Show Amounts"::"Amount Only");

        // [WHEN] Applied Vendor Entries page is opened.
        AppliedVendorEntries.OpenView();

        // [THEN] "Debit Amount", "Credit Amount" columns are not visible, "Amount" column is visible on Applied Vendor Entries page.
        VerifyAppliedVendorEntriesPageDebitCreditAmtFieldsVisibility(AppliedVendorEntries, false, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowAmountsAllAmountsVisibilityAppliedCustomerEntries()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        AppliedCustomerEntries: TestPage "Applied Customer Entries";
    begin
        // [FEATURE] [Show Amounts] [Applied Customer Entries]
        // [SCENARIO 275827] Amount columns visibility on Applied Customer Entries page for Show Amount = "All Amounts" in General Ledger Setup.
        Initialize();

        // [GIVEN] General Ledger Setup with Show Amount = "All Amounts"
        SetShowAmounts(GeneralLedgerSetup."Show Amounts"::"All Amounts");

        // [WHEN] Applied Customer Entries page is opened.
        AppliedCustomerEntries.OpenView();

        // [THEN] "Debit Amount", "Credit Amount", "Amount" columns are visible on Applied Customer Entries page.
        VerifyAppliedCustomerEntriesPageDebitCreditAmtFieldsVisibility(AppliedCustomerEntries, true, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowAmountsDebitCreditOnlyVisibilityAppliedCustomerEntries()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        AppliedCustomerEntries: TestPage "Applied Customer Entries";
    begin
        // [FEATURE] [Show Amounts] [Applied Customer Entries]
        // [SCENARIO 275827] Amount columns visibility on Applied Customer Entries page for Show Amount = "Debit/Credit Only" in General Ledger Setup.
        Initialize();

        // [GIVEN] General Ledger Setup with Show Amount = "Debit/Credit Only"
        SetShowAmounts(GeneralLedgerSetup."Show Amounts"::"Debit/Credit Only");

        // [WHEN] Applied Customer Entries page is opened.
        AppliedCustomerEntries.OpenView();

        // [THEN] "Debit Amount", "Credit Amount" columns are visible, "Amount" column is not visible on Applied Customer Entries page.
        VerifyAppliedCustomerEntriesPageDebitCreditAmtFieldsVisibility(AppliedCustomerEntries, true, true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowAmountsAmountOnlyVisibilityAppliedCustomerEntries()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        AppliedCustomerEntries: TestPage "Applied Customer Entries";
    begin
        // [FEATURE] [Show Amounts] [Applied Customer Entries]
        // [SCENARIO 275827] Amount columns visibility on Applied Customer Entries page for Show Amount = "Amount Only" in General Ledger Setup.
        Initialize();

        // [GIVEN] General Ledger Setup with Show Amount = "Amount Only"
        SetShowAmounts(GeneralLedgerSetup."Show Amounts"::"Amount Only");

        // [WHEN] Applied Customer Entries page is opened.
        AppliedCustomerEntries.OpenView();

        // [THEN] "Debit Amount", "Credit Amount" columns are not visible, "Amount" column is visible on Applied Customer Entries page.
        VerifyAppliedCustomerEntriesPageDebitCreditAmtFieldsVisibility(AppliedCustomerEntries, false, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureDimShortCutCodesAreNeverShownInSimpleModeForGenJournals()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GeneralJournalBatches: TestPage "General Journal Batches";
        GeneralJournal: TestPage "General Journal";
    begin
        // [SCENARIO] [Ensures that dimension shortcut codes are never shown if general journal page is open in 'Simple Mode']
        // [FEATURE] [UI] [Dimension] [General Journal]
        Initialize();

        // [GIVEN] General ledger setup has shortcut dim codes
        SetAllShortCutDimOnGLSetup();

        // [GIVEN] General Journal Batch is created and selected on General Journal Batches page.
        CreateGenJournalTemplateBatch(GenJournalTemplate, GenJournalBatch);
        PrepareGeneralJournalBatchesPage(GeneralJournalBatches, GenJournalBatch);

        // [WHEN] General Journal page opened from General Journal Batches
        RunEditJournalActionOnGeneralJournalPage(GeneralJournal, GeneralJournalBatches);

        // [THEN] None of the dimensions codes are visible.
        VerifyShortcutDimCodesVisibilityOnGenJournalPageInSimplePageMode(GeneralJournal);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureDimShortCutCodesAreShownForGenJournals()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJnlManagement: Codeunit GenJnlManagement;
        GeneralJournalBatches: TestPage "General Journal Batches";
        GeneralJournal: TestPage "General Journal";
    begin
        // [SCENARIO] [Ensures that dimension shortcut codes are shown if general journal page is open in classic mode]
        // [FEATURE] [UI] [Dimension] [General Journal]
        Initialize();

        // By default General journal (PAG 39) opens up in simple mode where NO shortcut dim codes are shown
        // regardless of the general ledger setup settings.
        // So, for this test we need to open up General journal page in 'classic mode' where the settings for
        // shorcut dim codes comes from general ledger setup. This is same as executing 'show more columns' action on PAG39.
        GenJnlManagement.SetJournalSimplePageModePreference(false, PAGE::"General Journal");

        // [GIVEN] General ledger setup has shortcut dim codes
        SetAllShortCutDimOnGLSetup();

        // [GIVEN] General Journal Batch is created and selected on General Journal Batches page.
        CreateGenJournalTemplateBatch(GenJournalTemplate, GenJournalBatch);
        PrepareGeneralJournalBatchesPage(GeneralJournalBatches, GenJournalBatch);

        // [WHEN] General Journal page opened from General Journal Batches
        RunEditJournalActionOnGeneralJournalPage(GeneralJournal, GeneralJournalBatches);

        // [THEN] All of the dimensions codes are visible.
        VerifyShortcutDimCodesVisibilityOnGenJournalPage(GeneralJournal);

        // Reset general journal page to simple mode or 'show less columns'.
        GenJnlManagement.SetJournalSimplePageModePreference(true, PAGE::"General Journal");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureDimShortCutCodesAreNeverShownInSimpleModeForSalesJournals()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GeneralJournalBatches: TestPage "General Journal Batches";
        SalesJournal: TestPage "Sales Journal";
    begin
        // [SCENARIO] [Ensures that dimension shortcut codes are never shown if sales journal page is open in 'Simple Mode']
        // [FEATURE] [UI] [Dimension] [Sales Journal]
        Initialize();

        // [GIVEN] General ledger setup has shortcut dim codes
        SetAllShortCutDimOnGLSetup();

        // [GIVEN] General Journal Batch is created for Sales Template and selected on General Journal Batches page
        PrepareTemplateBatchAndPageWithTypeAndReccuring(GeneralJournalBatches, GenJournalTemplate.Type::Sales, false);

        // [WHEN] Sales Journal page is opened from General Journal Batches page.
        RunEditJournalActionOnSalesJournalPage(SalesJournal, GeneralJournalBatches);

        // [THEN] None of the dimensions codes are visible.
        VerifyShortcutDimCodesVisibilityOnSalesJournalPageInSimplePageMode(SalesJournal);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureDimShortCutCodesAreShownForSalesJournals()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJnlManagement: Codeunit GenJnlManagement;
        GeneralJournalBatches: TestPage "General Journal Batches";
        SalesJournal: TestPage "Sales Journal";
    begin
        // [SCENARIO] [Ensures that dimension shortcut codes are shown if sales journal page is open in classic mode]
        // [FEATURE] [UI] [Dimension] [Sales Journal]
        Initialize();

        // By default Sales journal (PAG 253) opens up in simple mode where NO shortcut dim codes are shown
        // regardless of the general ledger setup settings.
        // So, for this test we need to open up Sales journal page in 'classic mode' where the settings for
        // shorcut dim codes comes from general ledger setup. This is same as executing 'show more columns' action on PAG253.
        GenJnlManagement.SetJournalSimplePageModePreference(false, PAGE::"Sales Journal");

        // [GIVEN] General ledger setup has shortcut dim codes
        SetAllShortCutDimOnGLSetup();

        // [GIVEN] General Journal Batch is created for Sales Template and selected on General Journal Batches page
        PrepareTemplateBatchAndPageWithTypeAndReccuring(GeneralJournalBatches, GenJournalTemplate.Type::Sales, false);

        // [WHEN] Sales Journal page is opened from General Journal Batches page.
        RunEditJournalActionOnSalesJournalPage(SalesJournal, GeneralJournalBatches);

        // [THEN] All of the dimensions codes are visible.
        VerifyShortcutDimCodesVisibilityOnSalesJournalPage(SalesJournal);

        // Reset sales journal page to simple mode or 'show less columns'.
        GenJnlManagement.SetJournalSimplePageModePreference(true, PAGE::"Sales Journal");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureDimShortCutCodesAreNeverShownInSimpleModeForPurchaseJournals()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GeneralJournalBatches: TestPage "General Journal Batches";
        PurchaseJournal: TestPage "Purchase Journal";
    begin
        // [SCENARIO] [Ensures that dimension shortcut codes are never shown if purchase journal page is open in 'Simple Mode']
        // [FEATURE] [UI] [Dimension] [Purchase Journal]
        Initialize();

        // [GIVEN] General ledger setup has shortcut dim codes
        SetAllShortCutDimOnGLSetup();

        // [GIVEN] General Journal Batch is created for Sales Template and selected on General Journal Batches page
        PrepareTemplateBatchAndPageWithTypeAndReccuring(GeneralJournalBatches, GenJournalTemplate.Type::Purchases, false);

        // [WHEN] Purchase Journal page is opened from General Journal Batches page.
        RunEditJournalActionOnPurchaseJournalPage(PurchaseJournal, GeneralJournalBatches);

        // [THEN] None of the dimensions codes are visible.
        VerifyShortcutDimCodesVisibilityOnPurchaseJournalPageInSimplePageMode(PurchaseJournal);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureDimShortCutCodesAreShownForPurchaseJournals()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJnlManagement: Codeunit GenJnlManagement;
        GeneralJournalBatches: TestPage "General Journal Batches";
        PurchaseJournal: TestPage "Purchase Journal";
    begin
        // [SCENARIO] [Ensures that dimension shortcut codes are shown if purchase journal page is open in classic mode]
        // [FEATURE] [UI] [Dimension] [Purchase Journal]
        Initialize();

        // By default Purchase journal (PAG 254) opens up in simple mode where NO shortcut dim codes are shown
        // regardless of the general ledger setup settings.
        // So, for this test we need to open up Purchase journal page in 'classic mode' where the settings for
        // shorcut dim codes comes from general ledger setup. This is same as executing 'show more columns' action on PAG254.
        GenJnlManagement.SetJournalSimplePageModePreference(false, PAGE::"Purchase Journal");

        // [GIVEN] General ledger setup has shortcut dim codes
        SetAllShortCutDimOnGLSetup();

        // [GIVEN] General Journal Batch is created for Purchase Template and selected on General Journal Batches page
        PrepareTemplateBatchAndPageWithTypeAndReccuring(GeneralJournalBatches, GenJournalTemplate.Type::Purchases, false);

        // [WHEN] Purchase Journal page is opened from General Journal Batches page.
        RunEditJournalActionOnPurchaseJournalPage(PurchaseJournal, GeneralJournalBatches);

        // [THEN] All of the dimensions codes are visible.
        VerifyShortcutDimCodesVisibilityOnPurchaseJournalPage(PurchaseJournal);

        // Reset purchase journal page to simple mode or 'show less columns'.
        GenJnlManagement.SetJournalSimplePageModePreference(true, PAGE::"Purchase Journal");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyGeneralJournalJobQueueStatusAndRemoveFromJobQueueVisibility()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
    begin
        // [SCENARIO] [Ensures that column and action have correct visibility]
        Initialize();
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(), 0);
        GenJournalLine.Validate("Document No.", LibraryUtility.GenerateGUID());
        GenJournalLine.Modify(true);

        GeneralJournal.Trap();
        PAGE.Run(PAGE::"General Journal", GenJournalLine);
        // Job Queue Status should be visible when Post With Job Queue = true.
        Assert.IsFalse(GeneralJournal."Job Queue Status".Visible(), 'Incorrect visibility value for Job Queue Status');
        // Remove from Job Queue should be visible when  Job Queue Status = "Scheduled for Posting"
        Assert.IsFalse(GeneralJournal."Remove From Job Queue".Visible(), 'Incorrect visibility value for Remove from Job Queue');

        LibraryJournals.SetPostWithJobQueue(true);

        GeneralJournal.Trap();
        PAGE.Run(PAGE::"General Journal", GenJournalLine);
        // Job Queue Status should be visible when Post With Job Queue = true.
        Assert.IsTrue(GeneralJournal."Job Queue Status".Visible(), 'Incorrect visibility value for Job Queue Status');
        // Remove from Job Queue should be visible when  Job Queue Status = "Scheduled for Posting"
        Assert.IsFalse(GeneralJournal."Remove From Job Queue".Visible(), 'Incorrect visibility value for Remove from Job Queue');

        GenJournalLine.Validate("Job Queue Status", GenJournalLine."Job Queue Status"::"Scheduled for Posting");
        GenJournalLine.Modify();

        GeneralJournal.Trap();
        PAGE.Run(PAGE::"General Journal", GenJournalLine);
        // Job Queue Status should be visible when Post With Job Queue = true.
        Assert.IsTrue(GeneralJournal."Job Queue Status".Visible(), 'Incorrect visibility value for Job Queue Status');
        // Remove from Job Queue should be visible when  Job Queue Status = "Scheduled for Posting"
        Assert.IsTrue(GeneralJournal."Remove From Job Queue".Visible(), 'Incorrect visibility value for Remove from Job Queue');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifySalesJournalJobQueueStatusAndRemoveFromJobQueueVisibility()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        SalesJournal: TestPage "Sales Journal";
    begin
        // [SCENARIO] [Ensures that column and action have correct visibility]
        Initialize();
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, GenJournalTemplate.Type::Sales);
        GenJournalTemplate.Modify();
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(), 0);
        GenJournalLine.Validate("Document No.", LibraryUtility.GenerateGUID());
        GenJournalLine.Modify(true);

        SalesJournal.Trap();
        PAGE.Run(PAGE::"Sales Journal", GenJournalLine);
        // Job Queue Status should be visible when Post With Job Queue = true.
        Assert.IsFalse(SalesJournal."Job Queue Status".Visible(), 'Incorrect visibility value for Job Queue Status');
        // Remove from Job Queue should be visible when  Job Queue Status = "Scheduled for Posting"
        Assert.IsFalse(SalesJournal."Remove From Job Queue".Visible(), 'Incorrect visibility value for Remove from Job Queue');

        LibraryJournals.SetPostWithJobQueue(true);

        SalesJournal.Trap();
        PAGE.Run(PAGE::"Sales Journal", GenJournalLine);
        // Job Queue Status should be visible when Post With Job Queue = true.
        Assert.IsTrue(SalesJournal."Job Queue Status".Visible(), 'Incorrect visibility value for Job Queue Status');
        // Remove from Job Queue should be visible when  Job Queue Status = "Scheduled for Posting"
        Assert.IsFalse(SalesJournal."Remove From Job Queue".Visible(), 'Incorrect visibility value for Remove from Job Queue');

        GenJournalLine.Validate("Job Queue Status", GenJournalLine."Job Queue Status"::"Scheduled for Posting");
        GenJournalLine.Modify();

        SalesJournal.Trap();
        PAGE.Run(PAGE::"Sales Journal", GenJournalLine);
        // Job Queue Status should be visible when Post With Job Queue = true.
        Assert.IsTrue(SalesJournal."Job Queue Status".Visible(), 'Incorrect visibility value for Job Queue Status');
        // Remove from Job Queue should be visible when  Job Queue Status = "Scheduled for Posting"
        Assert.IsTrue(SalesJournal."Remove From Job Queue".Visible(), 'Incorrect visibility value for Remove from Job Queue');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyPurchaseJournalJobQueueStatusAndRemoveFromJobQueueVisibility()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseJournal: TestPage "Purchase Journal";
    begin
        // [SCENARIO] [Ensures that column and action have correct visibility]
        Initialize();
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, GenJournalTemplate.Type::Purchases);
        GenJournalTemplate.Modify();
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(), 0);
        GenJournalLine.Validate("Document No.", LibraryUtility.GenerateGUID());
        GenJournalLine.Modify(true);

        PurchaseJournal.Trap();
        PAGE.Run(PAGE::"Purchase Journal", GenJournalLine);
        // Job Queue Status should be visible when Post With Job Queue = true.
        Assert.IsFalse(PurchaseJournal."Job Queue Status".Visible(), 'Incorrect visibility value for Job Queue Status');
        // Remove from Job Queue should be visible when  Job Queue Status = "Scheduled for Posting"
        Assert.IsFalse(PurchaseJournal."Remove From Job Queue".Visible(), 'Incorrect visibility value for Remove from Job Queue');

        LibraryJournals.SetPostWithJobQueue(true);

        PurchaseJournal.Trap();
        PAGE.Run(PAGE::"Purchase Journal", GenJournalLine);
        // Job Queue Status should be visible when Post With Job Queue = true.
        Assert.IsTrue(PurchaseJournal."Job Queue Status".Visible(), 'Incorrect visibility value for Job Queue Status');
        // Remove from Job Queue should be visible when  Job Queue Status = "Scheduled for Posting"
        Assert.IsFalse(PurchaseJournal."Remove From Job Queue".Visible(), 'Incorrect visibility value for Remove from Job Queue');

        GenJournalLine.Validate("Job Queue Status", GenJournalLine."Job Queue Status"::"Scheduled for Posting");
        GenJournalLine.Modify();

        PurchaseJournal.Trap();
        PAGE.Run(PAGE::"Purchase Journal", GenJournalLine);
        // Job Queue Status should be visible when Post With Job Queue = true.
        Assert.IsTrue(PurchaseJournal."Job Queue Status".Visible(), 'Incorrect visibility value for Job Queue Status');
        // Remove from Job Queue should be visible when  Job Queue Status = "Scheduled for Posting"
        Assert.IsTrue(PurchaseJournal."Remove From Job Queue".Visible(), 'Incorrect visibility value for Remove from Job Queue');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyCashReceiptJournalJobQueueStatusAndRemoveFromJobQueueVisibility()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        CashReceiptJournal: TestPage "Cash Receipt Journal";
    begin
        // [SCENARIO] [Ensures that column and action have correct visibility]
        Initialize();
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, GenJournalTemplate.Type::"Cash Receipts");
        GenJournalTemplate.Modify();
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(), 0);
        GenJournalLine.Validate("Document No.", LibraryUtility.GenerateGUID());
        GenJournalLine.Modify(true);

        CashReceiptJournal.Trap();
        PAGE.Run(PAGE::"Cash Receipt Journal", GenJournalLine);
        // Job Queue Status should be visible when Post With Job Queue = true.
        Assert.IsFalse(CashReceiptJournal."Job Queue Status".Visible(), 'Incorrect visibility value for Job Queue Status');
        // Remove from Job Queue should be visible when  Job Queue Status = "Scheduled for Posting"
        Assert.IsFalse(CashReceiptJournal."Remove From Job Queue".Visible(), 'Incorrect visibility value for Remove from Job Queue');

        LibraryJournals.SetPostWithJobQueue(true);

        CashReceiptJournal.Trap();
        PAGE.Run(PAGE::"Cash Receipt Journal", GenJournalLine);
        // Job Queue Status should be visible when Post With Job Queue = true.
        Assert.IsTrue(CashReceiptJournal."Job Queue Status".Visible(), 'Incorrect visibility value for Job Queue Status');
        // Remove from Job Queue should be visible when  Job Queue Status = "Scheduled for Posting"
        Assert.IsFalse(CashReceiptJournal."Remove From Job Queue".Visible(), 'Incorrect visibility value for Remove from Job Queue');

        GenJournalLine.Validate("Job Queue Status", GenJournalLine."Job Queue Status"::"Scheduled for Posting");
        GenJournalLine.Modify();

        CashReceiptJournal.Trap();
        PAGE.Run(PAGE::"Cash Receipt Journal", GenJournalLine);
        // Job Queue Status should be visible when Post With Job Queue = true.
        Assert.IsTrue(CashReceiptJournal."Job Queue Status".Visible(), 'Incorrect visibility value for Job Queue Status');
        // Remove from Job Queue should be visible when  Job Queue Status = "Scheduled for Posting"
        Assert.IsTrue(CashReceiptJournal."Remove From Job Queue".Visible(), 'Incorrect visibility value for Remove from Job Queue');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyICGeneralJournalJobQueueStatusAndRemoveFromJobQueueVisibility()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        ICGeneralJournal: TestPage "IC General Journal";
    begin
        // [SCENARIO] [Ensures that column and action have correct visibility]
        Initialize();
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, GenJournalTemplate.Type::Intercompany);
        GenJournalTemplate.Modify();
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(), 0);
        GenJournalLine.Validate("Document No.", LibraryUtility.GenerateGUID());
        GenJournalLine.Modify(true);

        ICGeneralJournal.Trap();
        PAGE.Run(PAGE::"IC General Journal", GenJournalLine);
        // Job Queue Status should be visible when Post With Job Queue = true.
        Assert.IsFalse(ICGeneralJournal."Job Queue Status".Visible(), 'Incorrect visibility value for Job Queue Status');
        // Remove from Job Queue should be visible when  Job Queue Status = "Scheduled for Posting"
        Assert.IsFalse(ICGeneralJournal."Remove From Job Queue".Visible(), 'Incorrect visibility value for Remove from Job Queue');

        LibraryJournals.SetPostWithJobQueue(true);

        ICGeneralJournal.Trap();
        PAGE.Run(PAGE::"IC General Journal", GenJournalLine);
        // Job Queue Status should be visible when Post With Job Queue = true.
        Assert.IsTrue(ICGeneralJournal."Job Queue Status".Visible(), 'Incorrect visibility value for Job Queue Status');
        // Remove from Job Queue should be visible when  Job Queue Status = "Scheduled for Posting"
        Assert.IsFalse(ICGeneralJournal."Remove From Job Queue".Visible(), 'Incorrect visibility value for Remove from Job Queue');

        GenJournalLine.Validate("Job Queue Status", GenJournalLine."Job Queue Status"::"Scheduled for Posting");
        GenJournalLine.Modify();

        ICGeneralJournal.Trap();
        PAGE.Run(PAGE::"IC General Journal", GenJournalLine);
        // Job Queue Status should be visible when Post With Job Queue = true.
        Assert.IsTrue(ICGeneralJournal."Job Queue Status".Visible(), 'Incorrect visibility value for Job Queue Status');
        // Remove from Job Queue should be visible when  Job Queue Status = "Scheduled for Posting"
        Assert.IsTrue(ICGeneralJournal."Remove From Job Queue".Visible(), 'Incorrect visibility value for Remove from Job Queue');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyJobGLJournalJobQueueStatusAndRemoveFromJobQueueVisibility()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        JobGLJournal: TestPage "Job G/L Journal";
    begin
        // [SCENARIO] [Ensures that column and action have correct visibility]
        Initialize();
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, GenJournalTemplate.Type::Jobs);
        GenJournalTemplate.Modify();
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(), 0);
        GenJournalLine.Validate("Document No.", LibraryUtility.GenerateGUID());
        GenJournalLine.Modify(true);

        JobGLJournal.Trap();
        PAGE.Run(PAGE::"Job G/L Journal", GenJournalLine);
        // Job Queue Status should be visible when Post With Job Queue = true.
        Assert.IsFalse(JobGLJournal."Job Queue Status".Visible(), 'Incorrect visibility value for Job Queue Status');
        // Remove from Job Queue should be visible when  Job Queue Status = "Scheduled for Posting"
        Assert.IsFalse(JobGLJournal."Remove From Job Queue".Visible(), 'Incorrect visibility value for Remove from Job Queue');

        LibraryJournals.SetPostWithJobQueue(true);

        JobGLJournal.Trap();
        PAGE.Run(PAGE::"Job G/L Journal", GenJournalLine);
        // Job Queue Status should be visible when Post With Job Queue = true.
        Assert.IsTrue(JobGLJournal."Job Queue Status".Visible(), 'Incorrect visibility value for Job Queue Status');
        // Remove from Job Queue should be visible when  Job Queue Status = "Scheduled for Posting"
        Assert.IsFalse(JobGLJournal."Remove From Job Queue".Visible(), 'Incorrect visibility value for Remove from Job Queue');

        GenJournalLine.Validate("Job Queue Status", GenJournalLine."Job Queue Status"::"Scheduled for Posting");
        GenJournalLine.Modify();

        JobGLJournal.Trap();
        PAGE.Run(PAGE::"Job G/L Journal", GenJournalLine);
        // Job Queue Status should be visible when Post With Job Queue = true.
        Assert.IsTrue(JobGLJournal."Job Queue Status".Visible(), 'Incorrect visibility value for Job Queue Status');
        // Remove from Job Queue should be visible when  Job Queue Status = "Scheduled for Posting"
        Assert.IsTrue(JobGLJournal."Remove From Job Queue".Visible(), 'Incorrect visibility value for Remove from Job Queue');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyPaymentJournalJobQueueStatusAndRemoveFromJobQueueVisibility()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [SCENARIO] [Ensures that column and action have correct visibility]
        Initialize();
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, GenJournalTemplate.Type::Payments);
        GenJournalTemplate.Modify();
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(), 0);
        GenJournalLine.Validate("Document No.", LibraryUtility.GenerateGUID());
        GenJournalLine.Modify(true);

        PaymentJournal.Trap();
        PAGE.Run(PAGE::"Payment Journal", GenJournalLine);
        // Job Queue Status should be visible when Post With Job Queue = true.
        Assert.IsFalse(PaymentJournal."Job Queue Status".Visible(), 'Incorrect visibility value for Job Queue Status');
        // Remove from Job Queue should be visible when  Job Queue Status = "Scheduled for Posting"
        Assert.IsFalse(PaymentJournal."Remove From Job Queue".Visible(), 'Incorrect visibility value for Remove from Job Queue');

        LibraryJournals.SetPostWithJobQueue(true);

        PaymentJournal.Trap();
        PAGE.Run(PAGE::"Payment Journal", GenJournalLine);
        // Job Queue Status should be visible when Post With Job Queue = true.
        Assert.IsTrue(PaymentJournal."Job Queue Status".Visible(), 'Incorrect visibility value for Job Queue Status');
        // Remove from Job Queue should be visible when  Job Queue Status = "Scheduled for Posting"
        Assert.IsFalse(PaymentJournal."Remove From Job Queue".Visible(), 'Incorrect visibility value for Remove from Job Queue');

        GenJournalLine.Validate("Job Queue Status", GenJournalLine."Job Queue Status"::"Scheduled for Posting");
        GenJournalLine.Modify();

        PaymentJournal.Trap();
        PAGE.Run(PAGE::"Payment Journal", GenJournalLine);
        // Job Queue Status should be visible when Post With Job Queue = true.
        Assert.IsTrue(PaymentJournal."Job Queue Status".Visible(), 'Incorrect visibility value for Job Queue Status');
        // Remove from Job Queue should be visible when  Job Queue Status = "Scheduled for Posting"
        Assert.IsTrue(PaymentJournal."Remove From Job Queue".Visible(), 'Incorrect visibility value for Remove from Job Queue');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyRecurringGeneralJournalJobQueueStatusAndRemoveFromJobQueueVisibility()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        RecurringGeneralJournal: TestPage "Recurring General Journal";
    begin
        // [SCENARIO] [Ensures that column and action have correct visibility]
        Initialize();
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, GenJournalTemplate.Type::General);
        GenJournalTemplate.Modify();
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(), 0);
        GenJournalLine.Validate("Document No.", LibraryUtility.GenerateGUID());
        GenJournalLine.Modify(true);

        RecurringGeneralJournal.Trap();
        PAGE.Run(PAGE::"Recurring General Journal", GenJournalLine);
        // Job Queue Status should be visible when Post With Job Queue = true.
        Assert.IsFalse(RecurringGeneralJournal."Job Queue Status".Visible(), 'Incorrect visibility value for Job Queue Status');
        // Remove from Job Queue should be visible when  Job Queue Status = "Scheduled for Posting"
        Assert.IsFalse(RecurringGeneralJournal."Remove From Job Queue".Visible(), 'Incorrect visibility value for Remove from Job Queue');

        LibraryJournals.SetPostWithJobQueue(true);

        RecurringGeneralJournal.Trap();
        PAGE.Run(PAGE::"Recurring General Journal", GenJournalLine);
        // Job Queue Status should be visible when Post With Job Queue = true.
        Assert.IsTrue(RecurringGeneralJournal."Job Queue Status".Visible(), 'Incorrect visibility value for Job Queue Status');
        // Remove from Job Queue should be visible when  Job Queue Status = "Scheduled for Posting"
        Assert.IsFalse(RecurringGeneralJournal."Remove From Job Queue".Visible(), 'Incorrect visibility value for Remove from Job Queue');

        GenJournalLine.Validate("Job Queue Status", GenJournalLine."Job Queue Status"::"Scheduled for Posting");
        GenJournalLine.Modify();

        RecurringGeneralJournal.Trap();
        PAGE.Run(PAGE::"Recurring General Journal", GenJournalLine);
        // Job Queue Status should be visible when Post With Job Queue = true.
        Assert.IsTrue(RecurringGeneralJournal."Job Queue Status".Visible(), 'Incorrect visibility value for Job Queue Status');
        // Remove from Job Queue should be visible when  Job Queue Status = "Scheduled for Posting"
        Assert.IsTrue(RecurringGeneralJournal."Remove From Job Queue".Visible(), 'Incorrect visibility value for Remove from Job Queue');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,JournalLinesScheduledMessageHandler')]
    [Scope('OnPrem')]
    procedure PostJournalLinesWithJobQueue()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        JournalsScheduledMsg: Label 'Journal lines have been scheduled for posting.';
        GeneralJournal: TestPage "General Journal";
    begin
        // Verify journal lines are scheduled and correct messages are shown
        Initialize();
        LibraryVariableStorageCounter.Clear();
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        BindSubscription(LibraryJobQueue);

        LibraryJournals.SetPostWithJobQueue(true);

        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, GenJournalTemplate.Type::General);
        GenJournalTemplate.Modify();
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(), 123);

        GeneralJournal.Trap();
        PAGE.Run(PAGE::"General Journal", GenJournalLine);
        GeneralJournal.Post.Invoke();

        // Verify journals scheduled message is shown
        Assert.ExpectedMessage(JournalsScheduledMsg, LibraryVariableStorageCounter.DequeueText());

        //Verify job queue info on line
        GenJournalLine.Get(GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Line No.");
        GenJournalLine.TestField("Job Queue Entry ID");
        GenJournalLine.TestField("Job Queue Status");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,JournalLinesScheduledMessageHandler')]
    [Scope('OnPrem')]
    procedure PostAndPrintJournalLinesWithJobQueue()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        JournalsScheduledMsg: Label 'Journal lines have been scheduled for posting.';
        GeneralJournal: TestPage "General Journal";
    begin
        // Verify journal lines are scheduled and correct messages are shown
        Initialize();
        LibraryVariableStorageCounter.Clear();
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        BindSubscription(LibraryJobQueue);

        LibraryJournals.SetPostAndPrintWithJobQueue(true);

        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, GenJournalTemplate.Type::General);
        GenJournalTemplate.Modify();
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(), 123);

        GeneralJournal.Trap();
        PAGE.Run(PAGE::"General Journal", GenJournalLine);
        GeneralJournal.PostAndPrint.Invoke();

        // Verify journals scheduled message is shown
        Assert.ExpectedMessage(JournalsScheduledMsg, LibraryVariableStorageCounter.DequeueText());

        //Verify job queue info on line
        GenJournalLine.Get(GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Line No.");
        GenJournalLine.TestField("Job Queue Entry ID");
        GenJournalLine.TestField("Job Queue Status");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,JournalLinesScheduledMessageHandler')]
    [Scope('OnPrem')]
    procedure PostJournalBatchesWithJobQueue()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: record "Gen. Journal Batch";
        GenJournalBatch2: record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        JournalsScheduledMsg: Label 'Journals have been scheduled for posting.';
        GeneralJournalBatches: TestPage "General Journal Batches";
    begin
        // Verify journal lines are scheduled and correct messages are shown
        Initialize();
        LibraryVariableStorageCounter.Clear();
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        BindSubscription(LibraryJobQueue);

        LibraryJournals.SetPostWithJobQueue(true);

        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, GenJournalTemplate.Type::General);
        GenJournalTemplate.Modify();
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch2, GenJournalTemplate.Name);

        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(), 123);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine2, GenJournalTemplate.Name, GenJournalBatch2.Name, GenJournalLine2."Document Type"::" ",
          GenJournalLine2."Account Type"::Customer, LibrarySales.CreateCustomerNo(), 456);

        GeneralJournalBatches.OpenView();
        GeneralJournalBatches.FILTER.SetFilter("Journal Template Name", GenJournalBatch."Journal Template Name");
        GeneralJournalBatches.Filter.SetFilter(Name, GenJournalBatch.Name);
        GeneralJournalBatches."P&ost".Invoke();

        // Verify journals scheduled message is shown
        Assert.ExpectedMessage(JournalsScheduledMsg, LibraryVariableStorageCounter.DequeueText());

        //Verify job queue info on lines
        GenJournalLine.Get(GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Line No.");
        GenJournalLine.TestField("Job Queue Entry ID");
        GenJournalLine.TestField("Job Queue Status");
        GenJournalLine2.Get(GenJournalTemplate.Name, GenJournalBatch2.Name, GenJournalLine2."Line No.");
        // The batches needs to be marked in the ui
        Assert.IsTrue(IsNullGuid(GenJournalLine2."Job Queue Entry ID"), 'Should not be posted');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,JournalLinesScheduledMessageHandler')]
    [Scope('OnPrem')]
    procedure PostAndPrintJournalBatchesWithJobQueue()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: record "Gen. Journal Batch";
        GenJournalBatch2: record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        JournalsScheduledMsg: Label 'Journals have been scheduled for posting.';
        GeneralJournalBatches: TestPage "General Journal Batches";
    begin
        // Verify journal lines are scheduled and correct messages are shown
        Initialize();
        LibraryVariableStorageCounter.Clear();
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        BindSubscription(LibraryJobQueue);

        LibraryJournals.SetPostAndPrintWithJobQueue(true);

        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, GenJournalTemplate.Type::General);
        GenJournalTemplate.Modify();
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch2, GenJournalTemplate.Name);

        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(), 123);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine2, GenJournalTemplate.Name, GenJournalBatch2.Name, GenJournalLine2."Document Type"::" ",
          GenJournalLine2."Account Type"::Customer, LibrarySales.CreateCustomerNo(), 456);

        GeneralJournalBatches.OpenView();
        GeneralJournalBatches.FILTER.SetFilter("Journal Template Name", GenJournalBatch."Journal Template Name");
        GeneralJournalBatches.Filter.SetFilter(Name, GenJournalBatch.Name);
        GeneralJournalBatches."Post and &Print".Invoke();

        // Verify journals scheduled message is shown
        Assert.ExpectedMessage(JournalsScheduledMsg, LibraryVariableStorageCounter.DequeueText());

        //Verify job queue info on lines
        GenJournalLine.Get(GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Line No.");
        GenJournalLine.TestField("Job Queue Entry ID");
        GenJournalLine.TestField("Job Queue Status");
        GenJournalLine2.Get(GenJournalTemplate.Name, GenJournalBatch2.Name, GenJournalLine2."Line No.");
        // The batches needs to be marked in the ui
        Assert.IsTrue(IsNullGuid(GenJournalLine2."Job Queue Entry ID"), 'Should not be posted');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureGlobalPropertiesWhenGenJnlPageIsOpenedFromBatch()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        GeneralJournal: TestPage "General Journal";
        GeneralJournalBatches: TestPage "General Journal Batches";
    begin
        // [SCENARIO] Verify global properties on open page in simple mode
        // By default General page opens up in simple view which means :-
        // 1. Posting date defaults to WORKDATE;
        // 2. Batch name should reflect correct batch.

        // Initialize
        Initialize();

        // Setup
        CreateGenJournalTemplateBatch(GenJournalTemplate, GenJournalBatch);
        PrepareGeneralJournalBatchesPage(GeneralJournalBatches, GenJournalBatch);

        // [WHEN] General Journal page opened from General Journal Batches
        RunEditJournalActionOnGeneralJournalPage(GeneralJournal, GeneralJournalBatches);

        // Verify scenario 1 / 2
        Assert.AreEqual(WorkDate(), GeneralJournal."<CurrentPostingDate>".AsDate(), 'Current posting date NOT equal to WORKDATE.');
        Assert.AreEqual(
          GenJournalBatch.Name, GeneralJournal.CurrentJnlBatchName.Value,
          'Current journal batch name not equal to batch that was opened.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureNewlyCreatedGenJourLinesWhenPageIsOpenedFromBatch()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        GeneralJournal: TestPage "General Journal";
        GeneralJournalBatches: TestPage "General Journal Batches";
        "Count": Integer;
        DocNoToSet: Code[10];
    begin
        // [SCENARIO] Verify new GL lines when page is opened from batch
        // 1. Verify that document number is assigned properly
        // 2. Verify that posting date is assigned properly
        // 3. Verify that batch name is assigned properly

        // Initialize
        Initialize();

        // Setup
        // Delete all lines
        GenJournalLine.DeleteAll();
        DocNoToSet := '100001';
        LibraryERM.CreateGLAccount(GLAccount);
        CreateGenJournalTemplateBatch(GenJournalTemplate, GenJournalBatch);
        PrepareGeneralJournalBatchesPage(GeneralJournalBatches, GenJournalBatch);

        // [WHEN] General Journal page opened from General Journal Batches
        RunEditJournalActionOnGeneralJournalPage(GeneralJournal, GeneralJournalBatches);

        // Create new entries
        // Set doc no. on page
        GeneralJournal."<Document No. Simple Page>".SetValue(DocNoToSet);
        GeneralJournal."Account No.".SetValue(GLAccount."No.");
        GeneralJournal.Next();
        GeneralJournal."Account No.".SetValue(GLAccount."No.");

        // Verify scenario 1 / 2 / 3
        Count := 0;
        GenJournalLine.Reset();
        GenJournalLine."Document No." := DocNoToSet;
        if GenJournalLine.Find('-') then
            repeat
                Count := Count + 1;
                Assert.AreEqual(WorkDate(), GenJournalLine."Posting Date", 'Unexpected value for posting date.');
                Assert.AreEqual(GenJournalBatch.Name, GenJournalLine."Journal Batch Name", 'Unexpected value for journal batch name.');
            until GenJournalLine.Next() <= 0;

        Assert.AreEqual(2, Count, 'General journal lines count does not match.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureNextAndPreviousDocNumberActionsIteratesAsExpected()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLineNew: Record "Gen. Journal Line";
        GenJournalLineNew2: Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
        GeneralJournalBatches: TestPage "General Journal Batches";
    begin
        // [SCENARIO] Verify next and previous document number actions iterates as expected for general journal lines.
        // 1. Verify that document number changes to next available document number and previous document number
        // when next and previous document number actions are executed.
        // 2. All the G/L lines are filtered by document number from step 1.

        // Initialize
        Initialize();
        // Setup
        // Delete all lines
        GenJournalLine.DeleteAll();
        CreateGenJournalLineWithDocNo(GenJournalLine, 'T0001');
        // Create 2 lines with different document numbers but with same batch and template
        SetUpNewGenJnlLineWithNoSeries(GenJournalLine, GenJournalLineNew, 2);
        GenJournalLineNew.TestField("Document No.", 'T0003');
        GenJournalLineNew."Line No." := GenJournalLine."Line No." + 50;
        GenJournalLineNew.Insert();
        SetUpNewGenJnlLineWithNoSeries(GenJournalLine, GenJournalLineNew2, 4);
        GenJournalLineNew2.TestField("Document No.", 'T0005');
        GenJournalLineNew2."Line No." := GenJournalLineNew."Line No." + 50;
        GenJournalLineNew2.Insert();

        GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");
        PrepareGeneralJournalBatchesPage(GeneralJournalBatches, GenJournalBatch);

        // [WHEN] General Journal page opened from General Journal Batches and next doc number action is invoked
        RunEditJournalActionOnGeneralJournalPage(GeneralJournal, GeneralJournalBatches);
        GeneralJournal.NextDocNumberTrx.Invoke();

        // Verify 1 (should be next doc number)
        Assert.AreEqual('T0003', GeneralJournal."<Document No. Simple Page>".Value, 'Document number does not match.');
        GeneralJournal.Last();
        Assert.AreEqual('T0003', GeneralJournal."Document No.".Value, 'Last line displayed has a different document number.');

        GeneralJournal.NextDocNumberTrx.Invoke(); // Going to T0005
        GeneralJournal.PreviousDocNumberTrx.Invoke(); // Going back to T0003

        Assert.AreEqual('T0003', GeneralJournal."<Document No. Simple Page>".Value, 'Document number does not match.');
        GeneralJournal.Last();
        Assert.AreEqual('T0003', GeneralJournal."Document No.".Value, 'Last line displayed has a different document number.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureNewDocumentNumberIncrementsDocNumber()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GeneralJournal: TestPage "General Journal";
        GeneralJournalBatches: TestPage "General Journal Batches";
    begin
        // [SCENARIO] Verify new document number actions creates a new doc number based on number series.
        // 1. Verify that document number changes to next available document number.

        // Initialize
        Initialize();

        // Setup
        // Delete all lines
        GenJournalLine.DeleteAll();
        CreateGenJournalLineWithDocNo(GenJournalLine, 'U0001');

        GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");
        PrepareGeneralJournalBatchesPage(GeneralJournalBatches, GenJournalBatch);

        // [WHEN] General Journal page opened from General Journal Batches and next doc number action is invoked
        RunEditJournalActionOnGeneralJournalPage(GeneralJournal, GeneralJournalBatches);
        GeneralJournal."New Doc No.".Invoke();

        // Verify 1 (should be next doc number)
        Assert.AreEqual('U0002', GeneralJournal."<Document No. Simple Page>".Value, 'Document number does not match.');
        Assert.AreEqual(WorkDate(), GeneralJournal."<CurrentPostingDate>".AsDate(), 'Current posting date NOT equal to WORKDATE.');
        Assert.AreEqual(
          GenJournalBatch.Name, GeneralJournal.CurrentJnlBatchName.Value,
          'Current journal batch name not equal to batch that was opened.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsurePostingDateCanBeSetForLinesFromHeader()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GeneralJournal: TestPage "General Journal";
        GeneralJournalBatches: TestPage "General Journal Batches";
        DocNoToSet: Code[10];
        CurrentPostingDate: Date;
    begin
        // [SCENARIO] Verify that posting date can be set from header.
        // 1. Verify posting date defaults to WORKDATE when a new GL line is created.
        // 2. Verify that posting date for GL line is changed when posting date on the header is modified.

        // Initialize
        Initialize();
        // Setup
        DocNoToSet := LibraryUtility.GenerateGUID();
        CurrentPostingDate := LibraryRandom.RandDate(10);

        CreateGenJournalLineWithDocNo(GenJournalLine, DocNoToSet);

        // Verify 1
        Assert.AreEqual(WorkDate(), GenJournalLine."Posting Date", 'Posting date for newly created GL line is not equal to WORKDATE.');

        GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");
        PrepareGeneralJournalBatchesPage(GeneralJournalBatches, GenJournalBatch);

        // [WHEN] General Journal page opened from General Journal Batches and posting date on header is changed.
        RunEditJournalActionOnGeneralJournalPage(GeneralJournal, GeneralJournalBatches);
        GeneralJournal."<CurrentPostingDate>".SetValue(CurrentPostingDate);

        // Verify 2
        GenJournalLine.Reset();
        GenJournalLine.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No.");
        GenJournalLine.TestField("Posting Date", CurrentPostingDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DueDateOnInvoiceGenJournalLineEmptyPaymentTerms()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        DocumentDate: Date;
    begin
        // [FEATURE] [Invoice] [Payment Terms] [Due Date]
        // [SCENARIO 285181] "Due Date" on Gen. Journal Line of "Document Type" = Invoice, Payment Terms Code = '' is based on "Document Date"
        Initialize();

        // [GIVEN] Created Customer
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Gen. Journal Line for Customer with "Document Type" = Invoice and "Payment Terms Code" = ''
        CreateGenJournalLineWithCustEntry(GenJournalLine, LibraryERM.CreateNoSeriesCode(), Customer."No.", '');
        GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::Invoice);
        GenJournalLine.Validate("Payment Terms Code", '');

        // [WHEN] Set "Document Date" to 01.08.18
        DocumentDate := LibraryRandom.RandDate(100);
        GenJournalLine.Validate("Document Date", DocumentDate);

        // [THEN] "Due Date" = 01.08.18 on Gen. Journal Line
        GenJournalLine.TestField("Due Date", DocumentDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DueDateOnCrMemoGenJournalLineEmptyPaymentTerms()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        DocumentDate: Date;
    begin
        // [FEATURE] [Credit Memo] [Payment Terms] [Due Date]
        // [SCENARIO 285181] "Due Date" on Gen. Journal Line of "Document Type" = "Credit Memo", Payment Terms Code = '' is based on "Document Date"
        Initialize();

        // [GIVEN] Created Customer
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Gen. Journal Line for Customer with "Document Type" = "Credit Memo" and "Payment Terms Code" = ''
        CreateGenJournalLineWithCustEntry(GenJournalLine, LibraryERM.CreateNoSeriesCode(), Customer."No.", '');
        GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::"Credit Memo");
        GenJournalLine.Validate("Payment Terms Code", '');

        // [WHEN] Set "Document Date" to 01.08.18
        DocumentDate := LibraryRandom.RandDate(100);
        GenJournalLine.Validate("Document Date", DocumentDate);

        // [THEN] "Due Date" = 01.08.18 on Gen. Journal Line
        GenJournalLine.TestField("Due Date", DocumentDate);
    end;

    [Test]
    [HandlerFunctions('GenJournalModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestGeneralJournalPageIsOpenedForSelectedJournalLineWithOtherBatch()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: array[2] of Record "Gen. Journal Line";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 277086] "General Journal" Page opened with a certain GenJournalLine must switch CurrentJnlBatchName Filter to the GenJournalLine."Journal Batch Name"
        Initialize();
        GenJournalTemplate.DeleteAll();
        GenJournalBatch.DeleteAll();

        PrepareGenJournalTemplateWithTwoBatchesAndGenJournalLines(GenJournalLine);

        PAGE.RunModal(PAGE::"General Journal", GenJournalLine[1]);

        Assert.AreEqual(
          GenJournalLine[1]."Journal Batch Name",
          LibraryVariableStorage.DequeueText(), GenJournalBatchFromGenJournalLineErr);

        PAGE.RunModal(PAGE::"General Journal", GenJournalLine[2]);

        Assert.AreEqual(
          GenJournalLine[2]."Journal Batch Name",
          LibraryVariableStorage.DequeueText(), GenJournalBatchFromGenJournalLineErr);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIsOpenedFromBatchWithRecordWithNoFilters()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: array[2] of Record "Gen. Journal Line";
    begin
        // [FEATURE] [General Journal] [UT]
        // [SCENARIO 277086] GenJournalLine.IsOpenedFromBatch must return TRUE when the record is already selected
        Initialize();
        GenJournalTemplate.DeleteAll();
        GenJournalBatch.DeleteAll();

        PrepareGenJournalTemplateWithTwoBatchesAndGenJournalLines(GenJournalLine);

        // When the page is opened from an URL link, the record is already exist
        Assert.IsTrue(GenJournalLine[2].IsOpenedFromBatch(), 'GenJournalLine.IsOpenedFromBatch must return TRUE');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIsOpenedFromBatchWithNoRecordWithFilters()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [General Journal] [UT]
        // [SCENARIO 277086] GenJournalLine.IsOpenedFromBatch must return TRUE when there are filters exists, but no record selected
        Initialize();
        GenJournalTemplate.DeleteAll();

        CreateGenJournalLineTemplate(GenJournalLine, GenJournalBatch);

        GenJournalLine.Init();
        GenJournalLine.SetFilter("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.SetFilter("Journal Template Name", GenJournalBatch."Journal Template Name");

        Assert.IsTrue(GenJournalLine.IsOpenedFromBatch(), 'GenJournalLine.IsOpenedFromBatch must return TRUE');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIsOpenedFromBatchWithNoRecordAndNoFilters()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [General Journal] [UT]
        // [SCENARIO 277086] GenJournalLine.IsOpenedFromBatch must return FALSE when there are no filters and no record selected
        Initialize();

        Assert.IsFalse(GenJournalLine.IsOpenedFromBatch(), 'GenJournalLine.IsOpenedFromBatch must return FALSE');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DebitAmountIsResetToZeroWhenValidateAmountWithZero()
    var
        GenJournalLine: Record "Gen. Journal Line";
        LineAmount: Decimal;
    begin
        // [FEATURE] [General Journal]
        // [SCENARIO 304707] Debit amount is set to zero if amount is set to zero in Gen. Journal Line.

        // [GIVEN] Gen. Journal Line with Amount = 150, "Debit Amount" = 150, "Credit Amount" = 0.
        GenJournalLine.Init();
        LineAmount := LibraryRandom.RandDecInRange(100, 200, 2);
        GenJournalLine.Validate(Amount, LineAmount);
        VerifyAmountDebitAndCreditValues(GenJournalLine, LineAmount, LineAmount, 0);

        // [WHEN] Amount is set to 0.
        GenJournalLine.Validate(Amount, 0);

        // [THEN] Gen. Journal Line updated with Amount = 0,  "Debit Amount" = 0, "Credit Amount" = 0.
        VerifyAmountDebitAndCreditValues(GenJournalLine, 0, 0, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreditAmountIsResetToZeroWhenValidateAmountWithZero()
    var
        GenJournalLine: Record "Gen. Journal Line";
        LineAmount: Decimal;
    begin
        // [FEATURE] [General Journal]
        // [SCENARIO 304707] Credit amount is set to zero if amount is set to zero in Gen. Journal Line.

        // [GIVEN] Gen. Journal Line with Amount = -150, "Debit Amount" = 0, "Credit Amount" = 150.
        GenJournalLine.Init();
        LineAmount := -LibraryRandom.RandDecInRange(100, 200, 2);
        GenJournalLine.Validate(Amount, LineAmount);
        VerifyAmountDebitAndCreditValues(GenJournalLine, LineAmount, 0, -LineAmount);

        // [WHEN] Amount is set to 0.
        GenJournalLine.Validate(Amount, 0);

        // [THEN] Gen. Journal Line updated with Amount = 0,  "Debit Amount" = 0, "Credit Amount" = 0.
        VerifyAmountDebitAndCreditValues(GenJournalLine, 0, 0, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureRecipientBankAccountIsEmptyForBlankGenJnlLineWithAccNoVend()
    var
        GenJnlLine: Record "Gen. Journal Line";
        VendorBankAccount: Record "Vendor Bank Account";
        GLAccountNo: Code[20];
    begin
        // [SCENARIO 407085] Field "Recipient Bank Account" of TAB81 Gen. Journal Line is validated for "Document Type" = " "
        Initialize();

        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, LibraryPurchase.CreateVendorNo());
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        CreateGenJournalLine(
              GenJnlLine, GenJnlLine."Document Type"::" ", GenJnlLine."Account Type"::"G/L Account", GLAccountNo,
              GenJnlLine."Bal. Account Type"::Vendor, VendorBankAccount."Vendor No.", '');

        GenJnlLine.Validate("Recipient Bank Account", VendorBankAccount.Code);

        GenJnlLine.TestField("Recipient Bank Account", VendorBankAccount.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureRecipientBankAccountIsEmptyForCreditMemoGenJnlLineWithAccNoVend()
    var
        GenJnlLine: Record "Gen. Journal Line";
        VendorBankAccount: Record "Vendor Bank Account";
        GLAccountNo: Code[20];
    begin
        // [SCENARIO 407085] Field "Recipient Bank Account" of TAB81 Gen. Journal Line is validated for "Document Type" = "Credit Memo"
        Initialize();

        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, LibraryPurchase.CreateVendorNo());
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        CreateGenJournalLine(
              GenJnlLine, GenJnlLine."Document Type"::"Credit Memo", GenJnlLine."Account Type"::"G/L Account",
              GLAccountNo, GenJnlLine."Bal. Account Type"::Vendor, VendorBankAccount."Vendor No.", '');

        GenJnlLine.Validate("Recipient Bank Account", VendorBankAccount.Code);

        GenJnlLine.TestField("Recipient Bank Account", VendorBankAccount.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureRecipientBankAccountIsEmptyForBlankGenJnlLineWithAccNoCust()
    var
        GenJnlLine: Record "Gen. Journal Line";
        CustomerBankAccount: Record "Customer Bank Account";
        GLAccountNo: Code[20];
    begin
        // [SCENARIO 407085] Field "Recipient Bank Account" of TAB81 Gen. Journal Line is validated for "Document Type" = " "
        Initialize();

        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, LibrarySales.CreateCustomerNo());
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        CreateGenJournalLine(
              GenJnlLine, GenJnlLine."Document Type"::" ", GenJnlLine."Account Type"::"G/L Account", GLAccountNo,
              GenJnlLine."Bal. Account Type"::Customer, CustomerBankAccount."Customer No.", '');

        GenJnlLine.Validate("Recipient Bank Account", CustomerBankAccount.Code);

        GenJnlLine.TestField("Recipient Bank Account", CustomerBankAccount.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EnsureRecipientBankAccountIsEmptyForCreditMemoGenJnlLineWithAccNoCust()
    var
        GenJnlLine: Record "Gen. Journal Line";
        CustomerBankAccount: Record "Customer Bank Account";
        GLAccountNo: Code[20];
    begin
        // [SCENARIO 407085] Field "Recipient Bank Account" of TAB81 Gen. Journal Line is validated for "Document Type" = "Credit Memo"
        Initialize();

        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, LibrarySales.CreateCustomerNo());
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        CreateGenJournalLine(
              GenJnlLine, GenJnlLine."Document Type"::"Credit Memo", GenJnlLine."Account Type"::"G/L Account",
              GLAccountNo, GenJnlLine."Bal. Account Type"::Customer, CustomerBankAccount."Customer No.", '');

        GenJnlLine.Validate("Recipient Bank Account", CustomerBankAccount.Code);

        GenJnlLine.TestField("Recipient Bank Account", CustomerBankAccount.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocumentNoResetOnChangedBatch()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
    begin
        // [SCENARIO 307215] Document No is reset to blank value when changing to empty batch with not-defined "No Series."
        Initialize();
        GenJnlManagement.SetJournalSimplePageModePreference(true, PAGE::"General Journal");

        // [GIVEN] Gen. Journal Template "GENERAL"
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);

        // [GIVEN] Gen. Journal Batch "GENERAL","BATCH01"
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        VerifyGenJnlBatchIsEmpty(GenJournalBatch);

        // [GIVEN] Gen. Journal Line on "BATCH01" with "Document No." = "DOC01"
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(), 0);
        GenJournalLine.Validate("Document No.", LibraryUtility.GenerateGUID());
        GenJournalLine.Modify(true);

        // [GIVEN] Empty Gen. Journal Batch "GENERAL","BATCH02" with blank "No. Series"
        CreateGenJournalBatchWithNoSeries(GenJournalBatch, GenJournalTemplate.Name, '');
        VerifyGenJnlBatchIsEmpty(GenJournalBatch);

        // [GIVEN] General Journal Page open in simple mode for batch "BATCH01"
        GeneralJournal.Trap();
        PAGE.Run(PAGE::"General Journal", GenJournalLine);
        Assert.AreEqual(
          GenJournalLine."Document No.", GeneralJournal."<Document No. Simple Page>".Value, 'Unexpected Document No.');

        // [WHEN] Switch to batch "BATCH02"
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);

        // [THEN] "Document No." reset to blank
        GeneralJournal."<Document No. Simple Page>".AssertEquals('');
        GeneralJournal.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocumentNoResetOnChangedDocNoAndBatch()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
        DocumentNo: Code[20];
    begin
        // [SCENARIO 307215] Document No is reset to blank value when changing to empty batch with not-defined "No Series." and Document No. previously changed on page
        Initialize();
        GenJnlManagement.SetJournalSimplePageModePreference(true, PAGE::"General Journal");

        // [GIVEN] Gen. Journal Template "GENERAL"
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);

        // [GIVEN] Gen. Journal Batch "GENERAL","BATCH01"
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        VerifyGenJnlBatchIsEmpty(GenJournalBatch);

        // [GIVEN] Gen. Journal Line on "BATCH01" with "Document No." = "DOC01"
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(), 0);
        GenJournalLine.Validate("Document No.", LibraryUtility.GenerateGUID());
        GenJournalLine.Modify(true);

        // [GIVEN] Empty Gen. Journal Batch "GENERAL","BATCH02" with blank "No. Series"
        CreateGenJournalBatchWithNoSeries(GenJournalBatch, GenJournalTemplate.Name, '');
        VerifyGenJnlBatchIsEmpty(GenJournalBatch);

        // [GIVEN] General Journal Page open in simple mode for batch "BATCH01"
        GeneralJournal.Trap();
        PAGE.Run(PAGE::"General Journal", GenJournalLine);

        // [GIVEN] "Document No." set to "TEST01" on the page
        DocumentNo := LibraryUtility.GenerateGUID();
        GeneralJournal."<Document No. Simple Page>".SetValue(DocumentNo);
        Assert.AreEqual(DocumentNo, GeneralJournal."<Document No. Simple Page>".Value, 'New Document No. was not set');

        // [WHEN] Switch to batch "BATCH02"
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);

        // [THEN] "Document No." reset to blank
        GeneralJournal."<Document No. Simple Page>".AssertEquals('');
        GeneralJournal.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentJournalDimensionsVisibleWhenOpenedFromBatch()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        GeneralJournalBatches: TestPage "General Journal Batches";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [FEATURE] [Payment Journal] [UI] [Dimensions]
        // [SCENARIO 312850] Shortcut dimension columns are visible on Payment Journal page when opened from batch
        Initialize();
        GenJournalBatch.DeleteAll();
        GenJournalTemplate.DeleteAll();

        // [GIVEN] General ledger setup has shortcut dim codes
        SetAllShortCutDimOnGLSetup();

        // [GIVEN] General Journal Batch is created for Payment Template and selected on General Journal Batches page.
        PreparePaymentTemplateBatchAndPage(GeneralJournalBatches);

        // [WHEN] Payment Journal page is opened from General Journal Batches page.
        RunEditJournalActionOnPaymentJournalPage(PaymentJournal, GeneralJournalBatches);

        // [THEN] Shortcut dimension columns are visible on Payment Journal page.
        VerifyShortcutDimCodesVisibilityOnPaymentJournalPage(PaymentJournal);
        PaymentJournal.Close();
        GeneralJournalBatches.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GeneralJournalNumberOfJournalLines()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GeneralJournal: TestPage "General Journal";
        NumberOfLines: Integer;
        i: Integer;
    begin
        // [FEATURE] [General Journal] [UI]
        // [SCENARIO 304797] "Number of Journal Lines" in the General Journal page
        Initialize();

        // [GIVEN] General journal batch "GJB"
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);

        // [GIVEN] Create "N" general journal lines in the batch "GJB"
        NumberOfLines := LibraryRandom.RandInt(20);
        for i := 1 to NumberOfLines do
            LibraryERM.CreateGeneralJnlLine(
              GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
              GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(), 0);

        // [WHEN] General Journal page is opened for batch "GJB"
        GeneralJournal.Trap();
        PAGE.Run(PAGE::"General Journal", GenJournalLine);

        // [THEN] "Number of Journal Lines" = "N"
        GeneralJournal.NumberOfJournalRecords.AssertEquals(NumberOfLines);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateBlankDocumentTypeOnGeneralJournalPage()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournalSimple: TestPage "General Journal";
        GeneralJournalClassic: TestPage "General Journal";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 346835] Stan can set "Blank" type as document type on General Journal Page
        Initialize();

        GenJournalTemplate.DeleteAll();
        GenJournalBatch.DeleteAll();
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);

        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);

        GeneralJournalSimple.OpenEdit();
        GeneralJournalClassic.Trap();
        GeneralJournalSimple.ClassicView.Invoke();
        GeneralJournalClassic."Document Type".SetValue(Format(GenJournalLine."Document Type"::Invoice));
        GeneralJournalClassic.Close();

        GenJournalLine.FindFirst();
        GenJournalLine.TestField("Document Type", GenJournalLine."Document Type"::Invoice);

        GeneralJournalSimple.OpenEdit();
        GeneralJournalClassic.Trap();
        GeneralJournalSimple.ClassicView.Invoke();
        GeneralJournalClassic."Document Type".SetValue(Format(GenJournalLine."Document Type"::" "));
        GeneralJournalClassic.Close();

        GenJournalLine.FindFirst();
        GenJournalLine.TestField("Document Type", GenJournalLine."Document Type"::" ");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateBlankDocumentTypeOnPurchaselJournalPage()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseJournalSimple: TestPage "Purchase Journal";
        PurchaseJournalClassic: TestPage "Purchase Journal";
        VendorNo: Code[20];
    begin
        // [FEATURE] [Purchase Journal] [UI]
        // [SCENARIO 346835] Stan can set "Blank" type as document type on Purchase Journal Page
        Initialize();

        GenJournalTemplate.DeleteAll();
        GenJournalBatch.DeleteAll();
        VendorNo := LibraryPurchase.CreateVendorNo();

        PurchaseJournalSimple.OpenEdit();
        PurchaseJournalClassic.Trap();
        PurchaseJournalSimple.ClassicView.Invoke();
        PurchaseJournalClassic."Document Type".SetValue(GenJournalLine."Document Type"::Invoice);
        PurchaseJournalClassic."Account Type".SetValue(GenJournalLine."Account Type"::Vendor);
        PurchaseJournalClassic."Account No.".SetValue(VendorNo);
        PurchaseJournalClassic.Close();

        GenJournalLine.SetRange("Account No.", VendorNo);

        GenJournalLine.FindFirst();
        GenJournalLine.TestField("Document Type", GenJournalLine."Document Type"::Invoice);

        PurchaseJournalSimple.OpenEdit();
        PurchaseJournalClassic.Trap();
        PurchaseJournalSimple.ClassicView.Invoke();
        PurchaseJournalClassic."Document Type".SetValue(Format(GenJournalLine."Document Type"::" "));
        PurchaseJournalClassic.DocumentAmount.SETVALUE(LibraryRandom.RandIntInRange(100, 200));
        PurchaseJournalClassic.Close();

        GenJournalLine.FindFirst();
        GenJournalLine.TestField("Document Type", GenJournalLine."Document Type"::" ");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotChangeOnModePurchaseJournalWhenWrongAccountTypeExisted()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseJournalSimple: TestPage "Purchase Journal";
        PurchaseJournalClassic: TestPage "Purchase Journal";
        VendorNo: Code[20];
        GLAccountNo: Code[20];
        ExpectedErrorText: Text;
    begin
        // [FEATURE] [Purchase Journal] [UI]
        // [SCENARIO 346835] Stan can set "Blank" type as document type on Purchase Journal Page
        Initialize();

        GenJournalTemplate.DeleteAll();
        GenJournalBatch.DeleteAll();

        VendorNo := LibraryPurchase.CreateVendorNo();
        GLAccountNo := LibraryERM.CreateGLAccountNo();

        PurchaseJournalSimple.OpenEdit();
        PurchaseJournalClassic.Trap();
        PurchaseJournalSimple.ClassicView.Invoke();
        PurchaseJournalClassic."Document Type".SetValue(GenJournalLine."Document Type"::Invoice);
        PurchaseJournalClassic."Account Type".SetValue(GenJournalLine."Account Type"::Vendor);
        PurchaseJournalClassic."Account No.".SetValue(VendorNo);
        PurchaseJournalClassic.Amount.SetValue(LibraryRandom.RandIntInRange(10, 100));
        PurchaseJournalClassic.Next();
        PurchaseJournalClassic."Document Type".SetValue(GenJournalLine."Document Type"::Invoice);
        PurchaseJournalClassic."Account Type".SetValue(GenJournalLine."Account Type"::"G/L Account");
        PurchaseJournalClassic."Account No.".SetValue(GLAccountNo);
        PurchaseJournalClassic.Amount.SetValue(LibraryRandom.RandIntInRange(10, 100));
        PurchaseJournalClassic.Close();
        Commit();

        GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::"G/L Account");
        GenJournalLine.SetRange("Account No.", GLAccountNo);
        GenJournalLine.FindFirst();

        asserterror GenJournalLine.TestField("Account Type", GenJournalLine."Account Type"::Vendor);
        ExpectedErrorText := GetLastErrorText();

        ClearLastError();
        PurchaseJournalClassic.OpenEdit();
        asserterror PurchaseJournalClassic.SimpleView.Invoke();

        Assert.ExpectedError(ExpectedErrorText);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateGenJnlBatchPostWebService()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        NewGenJnlBatchName: Code[10];
        JsonText: Text;
        TargetURL: Text;
        ResponseText: text;
    begin
        // [SCENARIO 357907] Create Gen. Journal batch with Web Service or Excel add-in 
        Initialize();

        // [GIVEN] Gen. Journal Template = "GJT"
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);

        // [GIVEN] Web Service for Gen. Journal Batches page = "WS"
        LibraryGraphMgt.EnsureWebServiceExist('GeneralJournalBatches', PAGE::"General Journal Batches");

        // [WHEN] Post Json request to Web Service "WS" (new Gen. Journal Batch - Name = "GJB", Journal_Template_Name = "GJT")
        NewGenJnlBatchName := LibraryUtility.GenerateRandomCode(GenJournalBatch.FieldNo("Name"), DATABASE::"Gen. Journal Batch");
        JSonText := GetGenJnlBatchJson(NewGenJnlBatchName, GenJournalTemplate.Name);
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"General Journal Batches", 'GeneralJournalBatches');
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, JSonText, ResponseText, 201);

        // [THEN] Gen. Journal Batch "GJB" created with Journal Template Name = "GJT"
        Assert.IsTrue(GenJournalBatch.Get(GenJournalTemplate.Name, NewGenJnlBatchName), 'Record not found');
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure RenumberDocNoMultipleLinesForDifferentNoSeries()
    var
        GLAccount: Record "G/L Account";
        GLAccount2: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        NoSeries: Codeunit "No. Series";
        NoSeriesCode: Code[20];
        NoSeriesCode2: Code[20];
        NewDocNo: Code[20];
    begin
        // [FEATURE] [No. Series]
        // [SCENARIO 383931] Different No. Series Gen. Journal lines are preserved after Renumber Document No.
        Initialize();

        // [GIVEN] Setup GL Accounts and two No. Series created (GU1.. and GU2..)
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGLAccount(GLAccount2);
        NoSeriesCode := LibraryERM.CreateNoSeriesCode();
        NoSeriesCode2 := LibraryERM.CreateNoSeriesCode();

        // [GIVEN] Created two Gen. Journal Lines (GJL1 and GJL2) for each No. Series
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", GLAccount."No.",
          GenJournalLine."Account Type"::"G/L Account", GLAccount2."No.", NoSeriesCode);
        CreateGenJournalLine(GenJournalLine2, GenJournalLine2."Document Type"::" ",
          GenJournalLine2."Account Type"::"G/L Account", GLAccount."No.",
          GenJournalLine2."Account Type"::"G/L Account", GLAccount2."No.", NoSeriesCode2);

        // [WHEN] Run "Renumber Document No" for lines
        Commit();
        GenJournalLine.RenumberDocumentNo();

        // [THEN] GJL1 has "Doc No." from "GU1.." No. Series, GJL2 has "Doc No." from "GU2.." No. Series
        NewDocNo := NoSeries.PeekNextNo(NoSeriesCode);
        VerifyGenJnlLineDocNo(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
          10000, NewDocNo);
        NewDocNo := NoSeries.PeekNextNo(NoSeriesCode2);
        VerifyGenJnlLineDocNo(GenJournalLine2."Journal Template Name", GenJournalLine2."Journal Batch Name",
          10000, NewDocNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure KeepDescriptionBalGLAccount()
    var
        GenJnlLine: Record "Gen. Journal Line";
        OriginalDescription: Text[100];
    begin
        // [SCENARIO 395563] Gen. Journal Line Description is not changed when update "Bal. Account No." for G/L Account type and "Keep Description" = Yes
        Initialize();

        // [GIVEN] Create Gen. Journal Line with empty "Account No.", Description = XYZ, "Keep Description" = Yes
        MockGenJournalLineWithKeepDescription(GenJnlLine);
        OriginalDescription := GenJnlLine.Description;

        // [WHEN] Validate "Bal. Account No." to G/L Account AAA
        GenJnlLine.Validate("Bal. Account Type", "Gen. Journal Account Type"::"G/L Account");
        GenJnlLine.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNoWithDirectPosting());

        // [THEN] Gen. Journal Line has same description "XYZ"
        GenJnlLine.TestField(Description, OriginalDescription);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure KeepDescriptionBalCustAccount()
    var
        GenJnlLine: Record "Gen. Journal Line";
        OriginalDescription: Text[100];
    begin
        // [SCENARIO 395563] Gen. Journal Line Description is not changed when update "Bal. Account No." for Customer type and "Keep Description" = Yes
        Initialize();

        // [GIVEN] Create Gen. Journal Line with empty "Account No.", Description = XYZ, "Keep Description" = Yes
        MockGenJournalLineWithKeepDescription(GenJnlLine);
        OriginalDescription := GenJnlLine.Description;

        // [WHEN] Validate "Bal. Account No." to Customer AAA
        GenJnlLine.Validate("Bal. Account Type", "Gen. Journal Account Type"::Customer);
        GenJnlLine.Validate("Bal. Account No.", LibrarySales.CreateCustomerNo());

        // [THEN] Gen. Journal Line has same description "XYZ"
        GenJnlLine.TestField(Description, OriginalDescription);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure KeepDescriptionBalVendAccount()
    var
        GenJnlLine: Record "Gen. Journal Line";
        OriginalDescription: Text[100];
    begin
        // [SCENARIO 395563] Gen. Journal Line Description is not changed when update "Bal. Account No." for Vendor type and "Keep Description" = Yes
        Initialize();

        // [GIVEN] Create Gen. Journal Line with empty "Account No.", Description = XYZ, "Keep Description" = Yes
        MockGenJournalLineWithKeepDescription(GenJnlLine);
        OriginalDescription := GenJnlLine.Description;

        // [WHEN] Validate "Bal. Account No." to Vendor AAA
        GenJnlLine.Validate("Bal. Account Type", "Gen. Journal Account Type"::Vendor);
        GenJnlLine.Validate("Bal. Account No.", LibraryPurchase.CreateVendorNo());

        // [THEN] Gen. Journal Line has same description "XYZ"
        GenJnlLine.TestField(Description, OriginalDescription);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure KeepDescriptionBalBankAccount()
    var
        GenJnlLine: Record "Gen. Journal Line";
        OriginalDescription: Text[100];
    begin
        // [SCENARIO 395563] Gen. Journal Line Description is not changed when update "Bal. Account No." for Bank type and "Keep Description" = Yes
        Initialize();

        // [GIVEN] Create Gen. Journal Line with empty "Account No.", Description = XYZ, "Keep Description" = Yes
        MockGenJournalLineWithKeepDescription(GenJnlLine);
        OriginalDescription := GenJnlLine.Description;

        // [WHEN] Validate "Bal. Account No." to Bank AAA
        GenJnlLine.Validate("Bal. Account Type", "Gen. Journal Account Type"::"Bank Account");
        GenJnlLine.Validate("Bal. Account No.", LibraryERM.CreateBankAccountNo());

        // [THEN] Gen. Journal Line has same description "XYZ"
        GenJnlLine.TestField(Description, OriginalDescription);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure KeepDescriptionBalFAAccount()
    var
        GenJnlLine: Record "Gen. Journal Line";
        OriginalDescription: Text[100];
    begin
        // [SCENARIO 395563] Gen. Journal Line Description is not changed when update "Bal. Account No." for "Fixed Asset" type and "Keep Description" = Yes
        Initialize();

        // [GIVEN] Create Gen. Journal Line with empty "Account No.", Description = XYZ, "Keep Description" = Yes
        MockGenJournalLineWithKeepDescription(GenJnlLine);
        OriginalDescription := GenJnlLine.Description;

        // [WHEN] Validate "Bal. Account No." to Fixed Asset AAA
        GenJnlLine.Validate("Bal. Account Type", "Gen. Journal Account Type"::"Fixed Asset");
        GenJnlLine.Validate("Bal. Account No.", LibraryFixedAsset.CreateFixedAssetNo());

        // [THEN] Gen. Journal Line has same description "XYZ"
        GenJnlLine.TestField(Description, OriginalDescription);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure KeepDescriptionBalICPartnerAccount()
    var
        GenJnlLine: Record "Gen. Journal Line";
        OriginalDescription: Text[100];
    begin
        // [SCENARIO 395563] Gen. Journal Line Description is not changed when update "Bal. Account No." for "IC Partner" type and "Keep Description" = Yes
        Initialize();

        // [GIVEN] Create Gen. Journal Line with empty "Account No.", Description = XYZ, "Keep Description" = Yes
        MockIntercompanyGenJournalLineWithKeepDescription(GenJnlLine);
        OriginalDescription := GenJnlLine.Description;

        // [WHEN] Validate "Bal. Account No." to "IC Partner" AAA
        GenJnlLine.Validate("Bal. Account Type", "Gen. Journal Account Type"::"IC Partner");
        GenJnlLine.Validate("Bal. Account No.", LibraryERM.CreateICPartnerNo());

        // [THEN] Gen. Journal Line has same description "XYZ"
        GenJnlLine.TestField(Description, OriginalDescription);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure GenJnlLinesRenumberUnfilteredEntries()
    var
        GLAccount: Record "G/L Account";
        GenJournalLine: Array[4] of Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        NoSeriesBatch: Codeunit "No. Series - Batch";
        DocNos: array[3] of Code[20];
        NoSeriesCode: Code[20];
        i: Integer;
    begin
        // [FEATURE] [Renumber Document]
        // [SCENARIO 402266] Unfiltered Document Nos should be correctly renumbered
        Initialize();

        // [GIVEN] Setup GL Account and No. Series 
        LibraryERM.CreateGLAccount(GLAccount);

        NoSeriesCode := LibraryERM.CreateNoSeriesCode();

        LibraryErm.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.VALIDATE("No. Series", NoSeriesCode);
        GenJournalBatch.Modify();

        // [GIVEN] Gen. Journal Line "1" with Document No. = "1" and Amount = 100
        CreateGenJournalLine1(
            GenJournalLine[1], GenJournalBatch.Name, GenJournalTemplate.Name,
            GLAccount."No.",
            100, NoSeriesBatch.GetNextNo(NoSeriesCode));

        // [GIVEN] Gen. Journal Line "2" with Document No. = "2" and Amount = 200
        CreateGenJournalLine1(
            GenJournalLine[2], GenJournalBatch.Name, GenJournalTemplate.Name,
            GLAccount."No.",
            200, NoSeriesBatch.GetNextNo(NoSeriesCode));

        // [GIVEN] Gen. Journal Line "3" with Document No. = "3" and Amount = 100
        CreateGenJournalLine1(
            GenJournalLine[3], GenJournalBatch.Name, GenJournalTemplate.Name,
            GLAccount."No.",
            100, NoSeriesBatch.GetNextNo(NoSeriesCode));

        for i := 1 to ArrayLen(DocNos) do
            DocNos[i] := GenJournalLine[i]."Document No.";

        // [GIVEN] Gen. Journal Lines filtered by Batch/Template and Amount = 100   
        GenJournalLine[4].SetFilter("Journal Template Name", GenJournalTemplate.Name);
        GenJournalLine[4].SetFilter("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine[4].SetFilter(Amount, FORMAT(100));
        GenJournalLine[4].FindLast();

        // [WHEN] Run "Renumber Document No" for Gen. Journal Line "3"
        Commit();
        GenJournalLine[4].RenumberDocumentNo();
        For i := 1 to ArrayLen(DocNos) do
            GenJournalLine[i].Find();

        // [THEN] Gen. Journal Line "1" Document No. = "1", Gen. Journal Line "2" Document No. = "3", Gen. Journal Line "3" Document No. = "2"
        GenJournalLine[1].TestField("Document No.", DocNos[1]);
        GenJournalLine[2].TestField("Document No.", DocNos[3]);
        GenJournalLine[3].TestField("Document No.", DocNos[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendRemitAdviceDeletedAndCreatedEntryUT()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        SavedGenJournalLine: Record "Gen. Journal Line";
        DocumentSendingProfile: Record "Document Sending Profile";
        Vendor: Record Vendor;
        LibraryJobQueue: Codeunit "Library - Job Queue";
        ERMGeneralJournalUT: Codeunit "ERM General Journal UT";
        NoSeriesCode: Code[20];
    begin
        // [SCENARIO 409569] Create gen. jnl. line, send it via remittance report by email in background. Then delete original line and create a new one.
        Initialize();

        // [GIVEN] Vendor "V" with email
        LibraryPurchase.CreateVendor(Vendor);
        Vendor."E-Mail" := '1@1.com';
        Vendor.Modify();

        // [GIVEN] General journal line "GJL" with "V"
        NoSeriesCode := LibraryERM.CreateNoSeriesCode();
        LibraryErm.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        CreateGenJournalLine(
            GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::Vendor, Vendor."No.",
            GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), NoSeriesCode);
        SavedGenJournalLine := GenJournalLine;

        // [GIVEN] "GJL" sent via remittance advice report by email in background
        BindSubscription(ERMGeneralJournalUT);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        DocumentSendingProfile.Init();
        DocumentSendingProfile."E-Mail" := DocumentSendingProfile."E-Mail"::"Yes (Use Default Settings)";
        DocumentSendingProfile."E-Mail Attachment" := DocumentSendingProfile."E-Mail Attachment"::PDF;
        DocumentSendingProfile.SendVendor(
            "Report Selection Usage"::"V.Remittance".AsInteger(), GenJournalLine, GenJournalLine."Document No.", GenJournalLine."Account No.",
            'Remittance Advice', GenJournalLine.FieldNo("Account No."), GenJournalLine.FieldNo("Document No."));
        UnbindSubscription(ERMGeneralJournalUT);
        UnbindSubscription(LibraryJobQueue);

        // [WHEN] Delete "GJL" and create a new one "GJL2"
        GenJournalLine.Delete();
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, SavedGenJournalLine."Journal Template Name", SavedGenJournalLine."Journal Batch Name",
            GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::Vendor, SavedGenJournalLine."Account No.", 100);
        asserterror LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(GenJournalLine.RecordId);

        // [THEN] "GJL2" did NOT pass validation because it replaced the original "GJL"
        Assert.ExpectedError(RecordDoesNotMatchErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendRemitAdviceUT()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentSendingProfile: Record "Document Sending Profile";
        Vendor: Record Vendor;
        ReportSelections: Record "Report Selections";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        ERMGeneralJournalUT: Codeunit "ERM General Journal UT";
        NoSeriesCode: Code[20];
    begin
        // [SCENARIO 409569] Create gen. jnl. line and send it via remittance report by email in background
        Initialize();

        // [GIVEN] Clean report selection for remittance advice to get error in ShowNoBodyNoAttachmentError () and just to skip report generation and save time.
        // [GIVEN] Record verification pass earlier in SendEmailInBackground().
        ReportSelections.SetRange(Usage, ReportSelections.Usage::"V.Remittance");
        ReportSelections.DeleteAll();

        // [GIVEN] Vendor "V" with email
        LibraryPurchase.CreateVendor(Vendor);
        Vendor."E-Mail" := '1@1.com';
        Vendor.Modify();

        // [GIVEN] General journal line "GJL" with "V"
        NoSeriesCode := LibraryERM.CreateNoSeriesCode();
        LibraryErm.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        CreateGenJournalLine(
            GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::Vendor, Vendor."No.",
            GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), NoSeriesCode);

        // [WHEN] Send "GJL" via remittance advice report by email in background
        BindSubscription(ERMGeneralJournalUT);
        BindSubscription(LibraryJobQueue);
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        DocumentSendingProfile.Init();
        DocumentSendingProfile."E-Mail" := DocumentSendingProfile."E-Mail"::"Yes (Use Default Settings)";
        DocumentSendingProfile."E-Mail Attachment" := DocumentSendingProfile."E-Mail Attachment"::PDF;
        DocumentSendingProfile.SendVendor(
            "Report Selection Usage"::"V.Remittance".AsInteger(), GenJournalLine, GenJournalLine."Document No.", GenJournalLine."Account No.",
            'Remittance Advice', GenJournalLine.FieldNo("Account No."), GenJournalLine.FieldNo("Document No."));
        UnbindSubscription(ERMGeneralJournalUT);
        UnbindSubscription(LibraryJobQueue);
        asserterror LibraryJobQueue.FindAndRunJobQueueEntryByRecordId(GenJournalLine.RecordId);

        // [THEN] "GJL" passed validation in DocumentMailing and job failed on getting body for email due to cleared report selection
        Assert.ExpectedError(MustSelectAndEmailBodyOrAttahmentErr);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure RenumberDocNoNotInitLine()
    var
        GLAccount: Record "G/L Account";
        GLAccount2: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        NoSeries: Codeunit "No. Series";
        NoSeriesCode: Code[20];
        NewDocNo: Code[20];
        JournalTemplateName: Code[10];
        JournalBatchName: Code[10];
    begin
        Initialize();

        // [GIVEN] 3 General Journal lines with Document No. = '0008', '0009', '0020'
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGLAccount(GLAccount2);
        NoSeriesCode := LibraryERM.CreateNoSeriesCode();
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", GLAccount."No.",
          GenJournalLine."Account Type"::"G/L Account", GLAccount2."No.", NoSeriesCode);
        SetNewDocNo(GenJournalLine);
        CreateSingleLineGenJnlDoc(GenJournalLine, GenJournalLine."Account Type"::"G/L Account", GLAccount."No.");
        SetNewDocNo(GenJournalLine);
        CreateSingleLineGenJnlDoc(GenJournalLine, GenJournalLine."Account Type"::"G/L Account", GLAccount."No.");
        SetNewDocNo(GenJournalLine);
        JournalTemplateName := GenJournalLine."Journal Template Name";
        JournalBatchName := GenJournalLine."Journal Batch Name";

        // [GIVEN] Not initialized General Journal Line with "Journal Template Name", "Journal Batch Name" same as lines already created
        Clear(GenJournalLine);
        GenJournalLine.Init();
        GenJournalLine."Journal Template Name" := JournalTemplateName;
        GenJournalLine."Journal Batch Name" := JournalBatchName;

        // [WHEN] Invoke Renumber Document No.
        Commit();
        GenJournalLine.RenumberDocumentNo();

        // [THEN] 3 General Journal lines exist with Document No. = '0000', '0001', '0002'
        NewDocNo := NoSeries.PeekNextNo(NoSeriesCode);
        VerifyGenJnlLineDocNo(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
          10000, NewDocNo);
        VerifyGenJnlLineDocNo(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
          20000, IncStr(NewDocNo));
        VerifyGenJnlLineDocNo(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
          30000, IncStr(IncStr(NewDocNo)));
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure GenJnlLinesRenumberGroupedByDocNo()
    var
        GLAccount: Record "G/L Account";
        GenJournalLine: Array[4] of Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        NoSeriesBatch: Codeunit "No. Series - Batch";
        DocNos: array[3] of Code[20];
        NoSeriesCode: Code[20];
        i: Integer;
    begin
        // [FEATURE] [Renumber Document]
        // [SCENARIO 424335] Lines grouped by Document Nos should be correctly renumbered
        Initialize();

        // [GIVEN] Setup GL Account and No. Series 
        LibraryERM.CreateGLAccount(GLAccount);
        NoSeriesCode := LibraryERM.CreateNoSeriesCode();

        LibraryErm.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("No. Series", NoSeriesCode);
        GenJournalBatch.Modify();

        for i := 1 to 3 do
            DocNos[i] := NoSeriesBatch.GetNextNo(NoSeriesCode);

        // [GIVEN] Mock Document No. gap: 2 lines with Document No. = 1 and 2 lines with Document No. = 3
        // [GIVEN] Line 1 with Document No. = "1"
        CreateGeneralJnlLineWithBalAcc(
            GenJournalLine[1], GenJournalBatch.Name, GenJournalTemplate.Name,
            GLAccount."No.",
            LibraryRandom.RandDecInRange(10, 20, 2), DocNos[1]);

        // [GIVEN] Line 2 with Document No. = "1"
        CreateGeneralJnlLineWithBalAcc(
            GenJournalLine[2], GenJournalBatch.Name, GenJournalTemplate.Name,
            GLAccount."No.",
            LibraryRandom.RandDecInRange(10, 20, 2), DocNos[1]);

        // [GIVEN] Line 3 with Document No. = "3"
        CreateGeneralJnlLineWithBalAcc(
            GenJournalLine[3], GenJournalBatch.Name, GenJournalTemplate.Name,
            GLAccount."No.",
            LibraryRandom.RandDecInRange(10, 20, 2), DocNos[3]);

        // [GIVEN] Line 4 with Document No. = "3" 
        CreateGeneralJnlLineWithBalAcc(
            GenJournalLine[4], GenJournalBatch.Name, GenJournalTemplate.Name,
            GLAccount."No.",
            LibraryRandom.RandDecInRange(10, 20, 2), DocNos[3]);


        // [WHEN] Run "Renumber Document No" 
        Commit();
        GenJournalLine[1].RenumberDocumentNo();
        For i := 1 to 4 do
            GenJournalLine[i].Find();

        // [THEN] Lines 1 and 2 have Document No. = "1", lines 3 and 4 have Document No. = "2"
        GenJournalLine[1].TestField("Document No.", DocNos[1]);
        GenJournalLine[2].TestField("Document No.", DocNos[1]);
        GenJournalLine[3].TestField("Document No.", DocNos[2]);
        GenJournalLine[4].TestField("Document No.", DocNos[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OpenGenJnlLinesFromBatchWithSpecialSymbols()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        GeneralJournal: TestPage "General Journal";
        GeneralJournalBatches: TestPage "General Journal Batches";
    begin
        // [SCENARIO 432887] Open general journal lines from batch with special symbols
        Initialize();
        GenJournalTemplate.DeleteAll();
        GenJournalBatch.DeleteAll();

        // [GIVEN] General journal batch with special symbols
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalBatch.Init();
        GenJournalBatch.Validate("Journal Template Name", GenJournalTemplate.Name);
        GenJournalBatch.Validate(Name, '=|&@()<>');
        GenJournalBatch.Validate(Description, GenJournalBatch.Name);
        GenJournalBatch.Insert(true);

        // [WHEN] General Journal page opened from General Journal Batches
        PrepareGeneralJournalBatchesPage(GeneralJournalBatches, GenJournalBatch);
        RunEditJournalActionOnGeneralJournalPage(GeneralJournal, GeneralJournalBatches);

        // [THEN] General journal page opened
        Assert.AreEqual(GenJournalBatch.Name, GeneralJournal.CurrentJnlBatchName.Value, 'Current journal batch name not equal to batch that was opened.');
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure NoRenumberDocNoWithNoBalAcc()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        BankAccount: Record "Bank Account";
        Customer: Record Customer;
        Customer2: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        NoSeries: Codeunit "No. Series";
        NoSeriesCode: Code[20];
        Amount: Decimal;
        Amount2: Decimal;
        DocNo: Code[20];
    begin
        // [SCENARIO 441235] Renumber Document Numbers function does not work as expected if the Payment Journal Lines do not have Bal. Account No.
        Initialize();

        // [GIVEN] Create Bank Account, 2 customer and 1 No. Series.
        LibraryERM.CreateBankAccount(BankAccount);
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomer(Customer2);
        NoSeriesCode := LibraryERM.CreateNoSeriesCode();

        // [GIVEN] Save DocNo and amount in Variable to verify the result.
        DocNo := NoSeries.PeekNextNo(NoSeriesCode);
        Amount := LibraryRandom.RandDec(100, 2);
        Amount2 := LibraryRandom.RandDec(100, 2);

        // [GIVEN] Create Gen Journal Template and Batch with No Series.
        CreateGenJournalTemplateBatch(GenJournalTemplate, GenJournalBatch);
        GenJournalBatch."No. Series" := NoSeriesCode;
        GenJournalBatch.Modify();

        // [GIVEN] Create 4 Gen. Journal Line with blank document no.
        CreateGenJournalLineWithoutDocNo(GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name,
            GenJournalLine."Account Type"::Customer, Customer."No.", -1 * Amount, WorkDate());
        CreateGenJournalLineWithoutDocNo(GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name,
            GenJournalLine."Account Type"::"Bank Account", BankAccount."No.", Amount, WorkDate());
        CreateGenJournalLineWithoutDocNo(GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name,
            GenJournalLine."Account Type"::Customer, Customer2."No.", -1 * Amount2, WorkDate() + 1);
        CreateGenJournalLineWithoutDocNo(GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name,
            GenJournalLine."Account Type"::"Bank Account", BankAccount."No.", Amount2, WorkDate() + 1);
        Commit();

        // [THEN] Renumber the document no
        GenJournalLine.RenumberDocumentNo();

        // [VERIFY] Verify all the Document No. on Gen. Journal Line
        VerifyGenJnlLineDocNo(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
         10000, DocNo);
        VerifyGenJnlLineDocNo(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
          20000, DocNo);
        VerifyGenJnlLineDocNo(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
          30000, IncStr(DocNo));
        VerifyGenJnlLineDocNo(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
          40000, IncStr(DocNo));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyVATAmountLCYInGenJnlLinesWhenFullVATAndCurrency()
    var
        GenJournalLine: Array[4] of Record "Gen. Journal Line";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        GLAccount: Record "G/L Account";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        GeneralPostingSetup: Record "General Posting Setup";
        CurrExchRate: Record "Currency Exchange Rate";
        Currency: Record Currency;
        GLAccountNo: Code[20];
        BalGLAccountNo: Code[20];
        VATAmountLCY: Decimal;
    begin
        // [SCENARIO 450651] In a "Full VAT" and "Currency" scenario the VAT Amount (LCY) is not filled in General Journal Lines
        Initialize();

        // [GIVEN] Create currency with Exchange Rate.
        LibraryERM.CreateCurrency(Currency);
        Currency.Description := LibraryUtility.GenerateGUID();
        Currency.Modify();
        LibraryERM.CreateExchangeRate(Currency.Code, Today, 1, 10);

        // [GIVEN] Create Business Posting Group, Gen. Product Posting Group and General Posting Setup
        LibraryERM.CreateGenBusPostingGroup(GenBusinessPostingGroup);
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, GenBusinessPostingGroup.Code, GenProductPostingGroup.Code);

        // [GIVEN] Create GL Account's
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        BalGLAccountNo := LibraryERM.CreateGLAccountNo();

        // [GIVEN] Create VAT Business Posting Group, VAT Product Posting Group and VAT Posting Setup
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);
        VATPostingSetup."VAT Calculation Type" := VATPostingSetup."VAT Calculation Type"::"Full VAT";
        VATPostingSetup."Sales VAT Account" := GLAccountNo;
        VATPostingSetup."VAT %" := 100;
        VATPostingSetup.Modify();

        // [GIVEN] Update the GL Account with Posting Groups
        GLAccount.Get(GLAccountNo);
        GLAccount."Direct Posting" := true;
        GLAccount."Gen. Posting Type" := GLAccount."Gen. Posting Type"::Sale;
        GLAccount."Gen. Bus. Posting Group" := GenBusinessPostingGroup.Code;
        GLAccount."Gen. Prod. Posting Group" := GenProductPostingGroup.Code;
        GLAccount."VAT Bus. Posting Group" := VATBusinessPostingGroup.Code;
        GLAccount."VAT Prod. Posting Group" := VATProductPostingGroup.Code;
        GLAccount.Modify();

        // [GIVEN] Create GenJournalTemplate and GenJournalBatch
        CreateGenJournalTemplateBatch(GenJournalTemplate, GenJournalBatch);
        GenJournalBatch."No. Series" := LibraryERM.CreateNoSeriesCode();
        GenJournalBatch.Modify();

        // [WHEN] Create 1st General Journal Line
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJournalLine[1], GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine[1]."Document Type"::" ",
          GenJournalLine[1]."Account Type"::"G/L Account", GLAccountNo, GenJournalLine[1]."Bal. Account Type"::"G/L Account",
          BalGLAccountNo, LibraryRandom.RandDec(100, 2));
        GenJournalLine[1].Validate("Currency Code", '');
        GenJournalLine[1].Modify();

        // [WHEN] Create 2nd General Journal Line
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJournalLine[2], GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine[2]."Document Type"::" ",
          GenJournalLine[2]."Account Type"::"G/L Account", BalGLAccountNo, GenJournalLine[2]."Bal. Account Type"::"G/L Account",
          GLAccountNo, -LibraryRandom.RandDec(100, 2));
        GenJournalLine[2].Validate("Currency Code", '');
        GenJournalLine[2].Modify();

        // [WHEN] Create 3rd General Journal Line
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJournalLine[3], GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine[3]."Document Type"::" ",
          GenJournalLine[3]."Account Type"::"G/L Account", GLAccountNo, GenJournalLine[3]."Bal. Account Type"::"G/L Account",
          BalGLAccountNo, LibraryRandom.RandDec(100, 2));
        GenJournalLine[3].Validate("Currency Code", Currency.Code);
        GenJournalLine[3].Modify();

        VATAmountLCY :=
        Round(
            CurrExchRate.ExchangeAmtFCYToLCY(GenJournalLine[3]."Posting Date", GenJournalLine[3]."Currency Code", GenJournalLine[3]."VAT Amount", GenJournalLine[3]."Currency Factor"),
            Currency."Amount Rounding Precision", Currency.VATRoundingDirection());

        // [WHEN] Create 4th General Journal Line
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJournalLine[4], GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine[4]."Document Type"::" ",
          GenJournalLine[4]."Account Type"::"G/L Account", BalGLAccountNo, GenJournalLine[4]."Bal. Account Type"::"G/L Account",
          GLAccountNo, -LibraryRandom.RandDec(100, 2));
        GenJournalLine[4].Validate("Currency Code", Currency.Code);
        GenJournalLine[4].Modify();

        // [THEN] Verify VAT Amount (LCY) is filled in 3rd General Journal Line.
        Assert.AreEqual(GenJournalLine[3]."VAT Amount (LCY)", VATAmountLCY, VATAmountLCYErr);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler,JournalLinesScheduledMessageHandler')]
    [Scope('OnPrem')]
    procedure RenumberDocNoForEachStartingDate()
    var
        GLAccount: Record "G/L Account";
        GLAccount2: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        NoSeriesBatch: Codeunit "No. Series - Batch";
        NoSeries: Record "No. Series";
        NoSeriesLine: array[3] of Record "No. Series Line";
        GenJnlPost: Codeunit "Gen. Jnl.-Post";
        NewDocNo: Code[20];
    begin
        // [SCENARIO 461384] Renumber Document Numbers on General Journal does not consider No. Series Lines setup for each Starting Date
        Initialize();

        // [GIVEN] Create two GL Account
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateGLAccount(GLAccount2);

        // [GIVEN] Create No Series and three no series line with different Starting Date
        LibraryUtility.CreateNoSeries(NoSeries, true, false, false);
        CreateNoSeriesLine(NoSeriesLine[1], NoSeries.Code, WorkDate());
        CreateNoSeriesLine(NoSeriesLine[2], NoSeries.Code, CalcDate('<+1M>', WorkDate()));
        CreateNoSeriesLine(NoSeriesLine[3], NoSeries.Code, CalcDate('<+2M>', WorkDate()));

        // [GIVEN] Create first general journal line 
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", GLAccount."No.",
          GenJournalLine."Account Type"::"G/L Account", GLAccount2."No.", NoSeries.Code);
        SetNewDocNo(GenJournalLine);

        // [GIVEN] Create second general journal line
        CreateSingleLineGenJnlDoc(GenJournalLine, GenJournalLine."Account Type"::"G/L Account", GLAccount."No.");
        SetNewDocNo(GenJournalLine);
        UpdateGenJournaLine(GenJournalLine, CalcDate('<+1M>', WorkDate()));

        // [GIVEN] Create third general journal line
        CreateSingleLineGenJnlDoc(GenJournalLine, GenJournalLine."Account Type"::"G/L Account", GLAccount."No.");
        SetNewDocNo(GenJournalLine);
        UpdateGenJournaLine(GenJournalLine, CalcDate('<+2M>', WorkDate()));

        // [THEN] Renumber the document mo
        Commit();
        GenJournalLine.RenumberDocumentNo();

        // [VERIFY Verify all three document no
        NewDocNo := NoSeriesBatch.GetNextNo(NoSeries.Code, WorkDate());
        VerifyGenJnlLineDocNo(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
          10000, NewDocNo);

        NewDocNo := NoSeriesBatch.GetNextNo(NoSeries.Code, CalcDate('<+1M>', WorkDate()));
        VerifyGenJnlLineDocNo(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
          20000, NewDocNo);

        NewDocNo := NoSeriesBatch.GetNextNo(NoSeries.Code, CalcDate('<+2M>', WorkDate()));
        VerifyGenJnlLineDocNo(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
          30000, NewDocNo);

        // [GIVEN] Post the Gen. Journal Line
        GenJnlPost.Run(GenJournalLine);

        // [VERIFY] Verify Gen. Journal Line post successfully
        Assert.ExpectedMessage(GenJouranlLinePostedMsg, LibraryVariableStorageCounter.DequeueText());

        // [VERIFY] No. Series line start date update successfully.
        Assert.AreEqual(WorkDate(), NoSeriesLine[1]."Starting Date", NoSeriesLineStartDateErr);
        Assert.AreEqual(CalcDate('<+1M>', WorkDate()), NoSeriesLine[2]."Starting Date", NoSeriesLineStartDateErr);
        Assert.AreEqual(CalcDate('<+2M>', WorkDate()), NoSeriesLine[3]."Starting Date", NoSeriesLineStartDateErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure S466305_CanChangeDocumentTypeToBlankInSalesJournalLineWithoutAmount()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GeneralJournalBatches: TestPage "General Journal Batches";
        SalesJournal: TestPage "Sales Journal";
    begin
        // [FEATURE] [Sales Journal]
        // [SCENARIO 275827] "Document Type" can be changed to blank when Amount = 0.
        Initialize();

        GenJournalTemplate.DeleteAll();
        GenJournalBatch.DeleteAll();

        // [GIVEN] General Ledger Setup with Show Amount = "All Amounts"
        SetShowAmounts(GeneralLedgerSetup."Show Amounts"::"All Amounts");

        // [GIVEN] General Journal Batch is created for Sales Template and selected on General Journal Batches page.
        PrepareTemplateBatchAndPageWithTypeAndReccuring(GeneralJournalBatches, "Gen. Journal Template Type"::Sales, false);

        // [GIVEN] Sales Journal page is opened from General Journal Batches page.
        RunEditJournalActionOnSalesJournalPage(SalesJournal, GeneralJournalBatches);

        // [THEN] Set "Document Type" to Invoice.
        SalesJournal."Document Type".SetValue("Gen. Journal Document Type"::Invoice);

        // [WHEN] Set "Document Type" to blank without error.
        SalesJournal."Document Type".SetValue("Gen. Journal Document Type"::" ");

        GeneralJournalBatches.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DebitCreditAmountGLEntriesPreviewFieldVisibility()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLEntriesPreviewPage: TestPage "G/L Entries Preview";
    begin
        // [FEATURE] [Show Amounts]
        // [SCENARIO 542680] Debit Amount and Credit Amount fields are visible and Amount field is not on the G/L Entries Preview page when "Show Amount is" set to "Debit/Credit Only"

        Initialize();

        // [GIVEN] General Ledger Setup with Show Amount = "Debit/Credit Only"
        SetShowAmounts(GeneralLedgerSetup."Show Amounts"::"Debit/Credit Only");

        // [WHEN] General Journal Preview page opened
        RunGeneralJournalPreviewPage(GLEntriesPreviewPage);

        // [THEN] "Debit Amount", "Credit Amount" columns are visible, "Amount" column - not visible
        VerifyGenJnlLinePageDebitCreditAmtFieldsVisibility(GLEntriesPreviewPage, true, true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllAmountsGLEntriesPreviewFieldVisibility()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLEntriesPreviewPage: TestPage "G/L Entries Preview";
    begin
        // [FEATURE] [Show Amounts]
        // [SCENARIO 542680] Amount, Debit Amount and Credit Amount fields are visible on the G/L Entries Preview page when "Show Amount is" set to "All Amounts"

        Initialize();

        // [GIVEN] General Ledger Setup with Show Amount = "All Amounts"
        SetShowAmounts(GeneralLedgerSetup."Show Amounts"::"All Amounts");

        // [WHEN] General Journal Preview page opened
        RunGeneralJournalPreviewPage(GLEntriesPreviewPage);

        // [THEN] "Debit Amount", "Credit Amount" and "Amount" columns are visible
        VerifyGenJnlLinePageDebitCreditAmtFieldsVisibility(GLEntriesPreviewPage, true, true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountGLEntriesPreviewFieldVisibility()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLEntriesPreviewPage: TestPage "G/L Entries Preview";
    begin
        // [FEATURE] [Show Amounts]
        // [SCENARIO 542680] Amount field is visible and Debit/Credit Amount fields are not on the G/L Entries Preview page when "Show Amount is" set to "Amount"

        Initialize();

        // [GIVEN] General Ledger Setup with Show Amount = "Amount Only"
        SetShowAmounts(GeneralLedgerSetup."Show Amounts"::"Amount Only");

        // [WHEN] General Journal Preview page opened
        RunGeneralJournalPreviewPage(GLEntriesPreviewPage);

        // [THEN] "Debit Amount", "Credit Amount" columns are not visible, "Amount" column - visible
        VerifyGenJnlLinePageDebitCreditAmtFieldsVisibility(GLEntriesPreviewPage, false, false, true);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    procedure RenumberDocNoMultipleJnlLinesDiffAccTypeAndAccNo()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: array[4] of Record "Gen. Journal Line";
        NoSeries: Codeunit "No. Series";
        OldDocNo: array[2] of Code[20];
        NewDocNo: Code[20];
    begin
        // [SCENARIO 545989] Stan can renumber document numbers for multiple general journal lines with different Account Type and Account No.
        Initialize();

        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        CreateGenJournalBatchWithNoSeries(GenJournalBatch, GenJournalTemplate.Name, LibraryERM.CreateNoSeriesCode());
        NewDocNo := NoSeries.PeekNextNo(GenJournalBatch."No. Series");
        // [GIVEN] General journal with multiple lines
        // [GIVEN] "Document Type" = Invoice, "Document No." = "X1", "Account Type" = Vendor, "Account No." = 10000, "Bal. Account No." = "Y"
        // [GIVEN] "Document Type" = Invoice, "Document No." = "X1", "Account Type" = Vendor, "Account No." = 20000, "Bal. Account No." = "Y"
        // [GIVEN] "Document Type" = Invoice, "Document No." = "X2", "Account Type" = Vendor, "Account No." = 20000, "Bal. Account No." is blank
        // [GIVEN] "Document Type" = Invoice, "Document No." = "X2", "Account Type" = G/LAccount, "Account No." = Y, "Bal. Account No." is blank
        OldDocNo[1] := LibraryUtility.GenerateGUID();
        CreateGeneralJnlLineWithBatchAndDocNo(
            GenJournalLine[1], GenJournalTemplate.Name, GenJournalBatch.Name,
            GenJournalLine[1]."Document Type"::Invoice, OldDocNo[1], GenJournalLine[1]."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(),
            GenJournalLine[1]."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), LibraryRandom.RandDec(100, 2));
        CreateGeneralJnlLineWithBatchAndDocNo(
            GenJournalLine[2], GenJournalTemplate.Name, GenJournalBatch.Name,
            GenJournalLine[2]."Document Type"::Invoice, OldDocNo[1], GenJournalLine[2]."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(),
            GenJournalLine[2]."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), LibraryRandom.RandDec(100, 2));
        OldDocNo[2] := LibraryUtility.GenerateGUID();
        CreateGeneralJnlLineWithBatchAndDocNo(
            GenJournalLine[3], GenJournalTemplate.Name, GenJournalBatch.Name,
            GenJournalLine[3]."Document Type"::Invoice, OldDocNo[2], GenJournalLine[3]."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(),
            GenJournalLine[3]."Bal. Account Type"::"G/L Account", '', LibraryRandom.RandDec(100, 2));
        CreateGeneralJnlLineWithBatchAndDocNo(
            GenJournalLine[4], GenJournalTemplate.Name, GenJournalBatch.Name,
            GenJournalLine[4]."Document Type"::Invoice, OldDocNo[2], GenJournalLine[4]."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
            GenJournalLine[4]."Bal. Account Type"::"G/L Account", '', LibraryRandom.RandDec(100, 2));

        // [WHEN] Renumber Document No.
        GenJournalLine[4].RenumberDocumentNo();

        // [THEN] The "Document No." has been renumbered in the following way
        // [THEN] "Document Type" = Invoice, "Document No." = "Z1", "Account Type" = Vendor, "Account No." = 10000, "Bal. Account No." = "Y"
        // [THEN] "Document Type" = Invoice, "Document No." = "Z2", "Account Type" = Vendor, "Account No." = 20000, "Bal. Account No." = "Y"
        // [THEN] "Document Type" = Invoice, "Document No." = "Z3", "Account Type" = Vendor, "Account No." = 20000, "Bal. Account No." is blank
        // [THEN] "Document Type" = Invoice, "Document No." = "Z3", "Account Type" = G/LAccount, "Account No." = Y, "Bal. Account No." is blank
        GenJournalLine[1].Find();
        GenJournalLine[1].TestField("Document No.", NewDocNo);
        GenJournalLine[2].Find();
        NewDocNo := IncStr(NewDocNo);
        GenJournalLine[2].TestField("Document No.", NewDocNo);
        NewDocNo := IncStr(NewDocNo);
        GenJournalLine[3].Find();
        GenJournalLine[3].TestField("Document No.", NewDocNo);
        GenJournalLine[4].Find();
        GenJournalLine[4].TestField("Document No.", NewDocNo);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    procedure RenumberDocNoMultipleJnlLinesBalAccSeparateLine()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: array[4] of Record "Gen. Journal Line";
        NoSeries: Codeunit "No. Series";
        OldDocNo: array[2] of Code[20];
        NewDocNo: Code[20];
        i, LineNo : Integer;
    begin
        // [SCENARIO 545989] Stan can renumber document numbers for multiple general journal lines where the balancing line is a separate line
        Initialize();

        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        CreateGenJournalBatchWithNoSeries(GenJournalBatch, GenJournalTemplate.Name, LibraryERM.CreateNoSeriesCode());
        NewDocNo := NoSeries.PeekNextNo(GenJournalBatch."No. Series");
        // [GIVEN] General journal with multiple lines
        // [GIVEN] "Document Type" = Invoice, "Document No." = "X1", "Account Type" = Vendor, "Account No." = 10000, "Bal. Account No." = "Y"
        // [GIVEN] "Document Type" = Invoice, "Document No." = "X1", "Account Type" = G/LAccount, "Account No." = Y, "Bal. Account No." is blank
        // [GIVEN] "Document Type" = Invoice, "Document No." = "X2", "Account Type" = Vendor, "Account No." = 20000, "Bal. Account No." = "Y"
        // [GIVEN] "Document Type" = Invoice, "Document No." = "X2", "Account Type" = G/LAccount, "Account No." = Y, "Bal. Account No." is blank
        LineNo := 0;
        for i := 1 to ArrayLen(OldDocNo) do begin
            LineNo += 1;
            OldDocNo[i] := LibraryUtility.GenerateGUID();
            CreateGeneralJnlLineWithBatchAndDocNo(
                GenJournalLine[LineNo], GenJournalTemplate.Name, GenJournalBatch.Name,
                GenJournalLine[LineNo]."Document Type"::Invoice, OldDocNo[i], GenJournalLine[LineNo]."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(),
                GenJournalLine[LineNo]."Bal. Account Type"::"G/L Account", '', LibraryRandom.RandDec(100, 2));
            LineNo += 1;
            CreateGeneralJnlLineWithBatchAndDocNo(
                GenJournalLine[LineNo], GenJournalTemplate.Name, GenJournalBatch.Name,
                GenJournalLine[LineNo]."Document Type"::Invoice, OldDocNo[i], GenJournalLine[LineNo]."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
                GenJournalLine[LineNo]."Bal. Account Type"::"G/L Account", '', LibraryRandom.RandDec(100, 2));
        end;

        // [WHEN] Renumber Document No.
        GenJournalLine[4].RenumberDocumentNo();

        // [THEN] The "Document No." has been renumbered in the following way
        // [THEN] "Document Type" = Invoice, "Document No." = "Z1", "Account Type" = Vendor, "Account No." = 10000, "Bal. Account No." = "Y"
        // [THEN] "Document Type" = Invoice, "Document No." = "Z1", "Account Type" = G/LAccount, "Account No." = Y, "Bal. Account No." is blank
        // [THEN] "Document Type" = Invoice, "Document No." = "Z2", "Account Type" = Vendor, "Account No." = 20000, "Bal. Account No." = "Y"
        // [THEN] "Document Type" = Invoice, "Document No." = "Z2", "Account Type" = G/LAccount, "Account No." = Y, "Bal. Account No." is blank
        GenJournalLine[1].Find();
        GenJournalLine[1].TestField("Document No.", NewDocNo);
        GenJournalLine[2].Find();
        GenJournalLine[2].TestField("Document No.", NewDocNo);
        NewDocNo := IncStr(NewDocNo);
        GenJournalLine[3].Find();
        GenJournalLine[3].TestField("Document No.", NewDocNo);
        GenJournalLine[4].Find();
        GenJournalLine[4].TestField("Document No.", NewDocNo);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    procedure RenumberDocGLAccountBeforeVendor()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: array[4] of Record "Gen. Journal Line";
        NoSeries: Codeunit "No. Series";
        OldDocNo: array[2] of Code[20];
        NewDocNo: Code[20];
    begin
        // [SCENARIO 563098] Stan can renumber document numbers for multiple general journal lines with G/L account lines goes before vendor
        Initialize();

        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        CreateGenJournalBatchWithNoSeries(GenJournalBatch, GenJournalTemplate.Name, LibraryERM.CreateNoSeriesCode());
        NewDocNo := NoSeries.PeekNextNo(GenJournalBatch."No. Series");
        // [GIVEN] General journal with multiple lines
        // [GIVEN] "Document Type" = Invoice, "Document No." = "X1", "Account Type" = G/L Account, "Account No." = Y, "Bal. Account No." is blank
        // [GIVEN] "Document Type" = Invoice, "Document No." = "X1", "Account Type" = Vendor, "Account No." = 10000, "Bal. Account No." is blank
        // [GIVEN] "Document Type" = Invoice, "Document No." = "X2", "Account Type" = G/L Account, "Account No." = Y, "Bal. Account No." is blank
        // [GIVEN] "Document Type" = Invoice, "Document No." = "X2", "Account Type" = Vendor, "Account No." = 20000, "Bal. Account No." is blank
        OldDocNo[1] := LibraryUtility.GenerateGUID();
        CreateGeneralJnlLineWithBatchAndDocNo(
            GenJournalLine[1], GenJournalTemplate.Name, GenJournalBatch.Name,
            GenJournalLine[1]."Document Type"::Invoice, OldDocNo[1], GenJournalLine[1]."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
            GenJournalLine[1]."Bal. Account Type"::"G/L Account", '', LibraryRandom.RandDec(100, 2));
        CreateGeneralJnlLineWithBatchAndDocNo(
            GenJournalLine[2], GenJournalTemplate.Name, GenJournalBatch.Name,
            GenJournalLine[2]."Document Type"::Invoice, OldDocNo[1], GenJournalLine[2]."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(),
            GenJournalLine[2]."Bal. Account Type"::"G/L Account", '', LibraryRandom.RandDec(100, 2));
        OldDocNo[2] := LibraryUtility.GenerateGUID();
        CreateGeneralJnlLineWithBatchAndDocNo(
            GenJournalLine[3], GenJournalTemplate.Name, GenJournalBatch.Name,
            GenJournalLine[3]."Document Type"::Invoice, OldDocNo[2], GenJournalLine[3]."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
            GenJournalLine[3]."Bal. Account Type"::"G/L Account", '', LibraryRandom.RandDec(100, 2));
        CreateGeneralJnlLineWithBatchAndDocNo(
            GenJournalLine[4], GenJournalTemplate.Name, GenJournalBatch.Name,
            GenJournalLine[4]."Document Type"::Invoice, OldDocNo[2], GenJournalLine[4]."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(),
            GenJournalLine[2]."Bal. Account Type"::"G/L Account", '', LibraryRandom.RandDec(100, 2));

        // [WHEN] Renumber Document No.
        GenJournalLine[4].RenumberDocumentNo();

        // [THEN] The "Document No." has been renumbered in the following way
        // [GIVEN] "Document Type" = Invoice, "Document No." = "Z1", "Account Type" = G/L Account, "Account No." = Y, "Bal. Account No." is blank
        // [GIVEN] "Document Type" = Invoice, "Document No." = "Z1", "Account Type" = Vendor, "Account No." = 10000, "Bal. Account No." is blank
        // [GIVEN] "Document Type" = Invoice, "Document No." = "Z2", "Account Type" = G/L Account, "Account No." = Y, "Bal. Account No." is blank
        // [GIVEN] "Document Type" = Invoice, "Document No." = "Z2", "Account Type" = Vendor, "Account No." = 20000, "Bal. Account No." is blank
        GenJournalLine[1].Find();
        GenJournalLine[1].TestField("Document No.", NewDocNo);
        GenJournalLine[2].Find();
        GenJournalLine[2].TestField("Document No.", NewDocNo);
        NewDocNo := IncStr(NewDocNo);
        GenJournalLine[3].Find();
        GenJournalLine[3].TestField("Document No.", NewDocNo);
        GenJournalLine[4].Find();
        GenJournalLine[4].TestField("Document No.", NewDocNo);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    procedure RenumberDocNoMultipleJnlLinesBalAccSeparateLineBlankDocType()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: array[4] of Record "Gen. Journal Line";
        NoSeries: Codeunit "No. Series";
        OldDocNo: Code[20];
        NewDocNo: Code[20];
        i, LineNo : Integer;
    begin
        // [SCENARIO 563098] Stan can renumber document numbers for multiple general journal lines with blank document type and where the balancing line is a separate line
        Initialize();

        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        CreateGenJournalBatchWithNoSeries(GenJournalBatch, GenJournalTemplate.Name, LibraryERM.CreateNoSeriesCode());
        NewDocNo := NoSeries.PeekNextNo(GenJournalBatch."No. Series");
        // [GIVEN] General journal with multiple lines
        // [GIVEN] "Document Type" = Invoice, "Document No." = "X1", "Account Type" = Vendor, "Account No." = 10000, "Bal. Account No." = "Y"
        // [GIVEN] "Document Type" = Invoice, "Document No." = "X1", "Account Type" = G/LAccount, "Account No." = Y, "Bal. Account No." is blank
        // [GIVEN] "Document Type" = Invoice, "Document No." = "X1", "Account Type" = Vendor, "Account No." = 20000, "Bal. Account No." = "Y"
        // [GIVEN] "Document Type" = Invoice, "Document No." = "X1", "Account Type" = G/LAccount, "Account No." = Y, "Bal. Account No." is blank
        OldDocNo := LibraryUtility.GenerateGUID();
        LineNo := 0;
        for i := 1 to 2 do begin
            LineNo += 1;
            CreateGeneralJnlLineWithBatchAndDocNo(
                GenJournalLine[LineNo], GenJournalTemplate.Name, GenJournalBatch.Name,
                GenJournalLine[LineNo]."Document Type"::" ", OldDocNo, GenJournalLine[LineNo]."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(),
                GenJournalLine[LineNo]."Bal. Account Type"::"G/L Account", '', LibraryRandom.RandDec(100, 2));
            LineNo += 1;
            CreateGeneralJnlLineWithBatchAndDocNo(
                GenJournalLine[LineNo], GenJournalTemplate.Name, GenJournalBatch.Name,
                GenJournalLine[LineNo]."Document Type"::" ", OldDocNo, GenJournalLine[LineNo]."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
                GenJournalLine[LineNo]."Bal. Account Type"::"G/L Account", '', LibraryRandom.RandDec(100, 2));
        end;

        // [WHEN] Renumber Document No.
        GenJournalLine[4].RenumberDocumentNo();

        // [THEN] The "Document No." has been renumbered in the following way
        // [THEN] "Document Type" = Invoice, "Document No." = "Z1", "Account Type" = Vendor, "Account No." = 10000, "Bal. Account No." = "Y"
        // [THEN] "Document Type" = Invoice, "Document No." = "Z1", "Account Type" = G/LAccount, "Account No." = Y, "Bal. Account No." is blank
        // [THEN] "Document Type" = Invoice, "Document No." = "Z1", "Account Type" = Vendor, "Account No." = 20000, "Bal. Account No." = "Y"
        // [THEN] "Document Type" = Invoice, "Document No." = "Z1", "Account Type" = G/LAccount, "Account No." = Y, "Bal. Account No." is blank
        GenJournalLine[1].Find();
        GenJournalLine[1].TestField("Document No.", NewDocNo);
        GenJournalLine[2].Find();
        GenJournalLine[2].TestField("Document No.", NewDocNo);
        GenJournalLine[3].Find();
        GenJournalLine[3].TestField("Document No.", NewDocNo);
        GenJournalLine[4].Find();
        GenJournalLine[4].TestField("Document No.", NewDocNo);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    procedure RenumberDocGLAccountBeforeVendorBlankDocType()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: array[4] of Record "Gen. Journal Line";
        NoSeries: Codeunit "No. Series";
        OldDocNo: Code[20];
        NewDocNo: Code[20];
    begin
        // [SCENARIO 563098] Stan can renumber document numbers for multiple general journal lines with blank document type and G/L account lines goes before vendor
        Initialize();

        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        CreateGenJournalBatchWithNoSeries(GenJournalBatch, GenJournalTemplate.Name, LibraryERM.CreateNoSeriesCode());
        NewDocNo := NoSeries.PeekNextNo(GenJournalBatch."No. Series");
        // [GIVEN] General journal with multiple lines
        // [GIVEN] "Document Type" = "", "Document No." = "X1", "Account Type" = G/L Account, "Account No." = Y, "Bal. Account No." is blank
        // [GIVEN] "Document Type" = "", "Document No." = "X1", "Account Type" = Vendor, "Account No." = 10000, "Bal. Account No." is blank
        // [GIVEN] "Document Type" = "", "Document No." = "X1", "Account Type" = G/L Account, "Account No." = Y, "Bal. Account No." is blank
        // [GIVEN] "Document Type" = "", "Document No." = "X1", "Account Type" = Vendor, "Account No." = 20000, "Bal. Account No." is blank
        OldDocNo := LibraryUtility.GenerateGUID();
        CreateGeneralJnlLineWithBatchAndDocNo(
            GenJournalLine[1], GenJournalTemplate.Name, GenJournalBatch.Name,
            GenJournalLine[1]."Document Type"::" ", OldDocNo, GenJournalLine[1]."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
            GenJournalLine[1]."Bal. Account Type"::"G/L Account", '', LibraryRandom.RandDec(100, 2));
        CreateGeneralJnlLineWithBatchAndDocNo(
            GenJournalLine[2], GenJournalTemplate.Name, GenJournalBatch.Name,
            GenJournalLine[2]."Document Type"::" ", OldDocNo, GenJournalLine[2]."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(),
            GenJournalLine[2]."Bal. Account Type"::"G/L Account", '', LibraryRandom.RandDec(100, 2));
        CreateGeneralJnlLineWithBatchAndDocNo(
            GenJournalLine[3], GenJournalTemplate.Name, GenJournalBatch.Name,
            GenJournalLine[3]."Document Type"::" ", OldDocNo, GenJournalLine[3]."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
            GenJournalLine[3]."Bal. Account Type"::"G/L Account", '', LibraryRandom.RandDec(100, 2));
        CreateGeneralJnlLineWithBatchAndDocNo(
            GenJournalLine[4], GenJournalTemplate.Name, GenJournalBatch.Name,
            GenJournalLine[4]."Document Type"::" ", OldDocNo, GenJournalLine[4]."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(),
            GenJournalLine[2]."Bal. Account Type"::"G/L Account", '', LibraryRandom.RandDec(100, 2));

        // [WHEN] Renumber Document No.
        GenJournalLine[4].RenumberDocumentNo();

        // [THEN] The "Document No." has been renumbered in the following way
        // [GIVEN] "Document Type" = "", "Document No." = "Z1", "Account Type" = G/L Account, "Account No." = Y, "Bal. Account No." is blank
        // [GIVEN] "Document Type" = "", "Document No." = "Z1", "Account Type" = Vendor, "Account No." = 10000, "Bal. Account No." is blank
        // [GIVEN] "Document Type" = "", "Document No." = "Z1", "Account Type" = G/L Account, "Account No." = Y, "Bal. Account No." is blank
        // [GIVEN] "Document Type" = "", "Document No." = "Z1", "Account Type" = Vendor, "Account No." = 20000, "Bal. Account No." is blank
        GenJournalLine[1].Find();
        GenJournalLine[1].TestField("Document No.", NewDocNo);
        GenJournalLine[2].Find();
        GenJournalLine[2].TestField("Document No.", NewDocNo);
        GenJournalLine[3].Find();
        GenJournalLine[3].TestField("Document No.", NewDocNo);
        GenJournalLine[4].Find();
        GenJournalLine[4].TestField("Document No.", NewDocNo);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    procedure RenumberDocGLAccountBeforeVendorPayment()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: array[4] of Record "Gen. Journal Line";
        NoSeries: Codeunit "No. Series";
        OldDocNo: Code[20];
        NewDocNo: Code[20];
    begin
        // [SCENARIO 569020] Stan can renumber document numbers for multiple payment general journal lines and G/L account lines goes before vendor
        Initialize();

        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        CreateGenJournalBatchWithNoSeries(GenJournalBatch, GenJournalTemplate.Name, LibraryERM.CreateNoSeriesCode());
        NewDocNo := NoSeries.PeekNextNo(GenJournalBatch."No. Series");
        // [GIVEN] General journal with multiple lines
        // [GIVEN] "Document Type" = Payment, "Document No." = "X1", "Account Type" = G/L Account, "Account No." = Y, "Bal. Account No." is blank
        // [GIVEN] "Document Type" = Payment, "Document No." = "X1", "Account Type" = Vendor, "Account No." = 10000, "Bal. Account No." is blank
        // [GIVEN] "Document Type" = Payment, "Document No." = "X1", "Account Type" = G/L Account, "Account No." = Y, "Bal. Account No." is blank
        // [GIVEN] "Document Type" = Payment, "Document No." = "X1", "Account Type" = Vendor, "Account No." = 20000, "Bal. Account No." is blank
        OldDocNo := LibraryUtility.GenerateGUID();
        CreateGeneralJnlLineWithBatchAndDocNo(
            GenJournalLine[1], GenJournalTemplate.Name, GenJournalBatch.Name,
            GenJournalLine[1]."Document Type"::Payment, OldDocNo, GenJournalLine[1]."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
            GenJournalLine[1]."Bal. Account Type"::"G/L Account", '', LibraryRandom.RandDec(100, 2));
        CreateGeneralJnlLineWithBatchAndDocNo(
            GenJournalLine[2], GenJournalTemplate.Name, GenJournalBatch.Name,
            GenJournalLine[2]."Document Type"::Payment, OldDocNo, GenJournalLine[2]."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(),
            GenJournalLine[2]."Bal. Account Type"::"G/L Account", '', LibraryRandom.RandDec(100, 2));
        CreateGeneralJnlLineWithBatchAndDocNo(
            GenJournalLine[3], GenJournalTemplate.Name, GenJournalBatch.Name,
            GenJournalLine[3]."Document Type"::Payment, OldDocNo, GenJournalLine[3]."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
            GenJournalLine[3]."Bal. Account Type"::"G/L Account", '', LibraryRandom.RandDec(100, 2));
        CreateGeneralJnlLineWithBatchAndDocNo(
            GenJournalLine[4], GenJournalTemplate.Name, GenJournalBatch.Name,
            GenJournalLine[4]."Document Type"::Payment, OldDocNo, GenJournalLine[4]."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(),
            GenJournalLine[2]."Bal. Account Type"::"G/L Account", '', LibraryRandom.RandDec(100, 2));

        // [WHEN] Renumber Document No.
        GenJournalLine[4].RenumberDocumentNo();

        // [THEN] The "Document No." has been renumbered in the following way
        // [GIVEN] "Document Type" = Payment, "Document No." = "Z1", "Account Type" = G/L Account, "Account No." = Y, "Bal. Account No." is blank
        // [GIVEN] "Document Type" = Payment, "Document No." = "Z1", "Account Type" = Vendor, "Account No." = 10000, "Bal. Account No." is blank
        // [GIVEN] "Document Type" = Payment, "Document No." = "Z1", "Account Type" = G/L Account, "Account No." = Y, "Bal. Account No." is blank
        // [GIVEN] "Document Type" = Payment, "Document No." = "Z1", "Account Type" = Vendor, "Account No." = 20000, "Bal. Account No." is blank
        GenJournalLine[1].Find();
        GenJournalLine[1].TestField("Document No.", NewDocNo);
        GenJournalLine[2].Find();
        GenJournalLine[2].TestField("Document No.", NewDocNo);
        GenJournalLine[3].Find();
        GenJournalLine[3].TestField("Document No.", NewDocNo);
        GenJournalLine[4].Find();
        GenJournalLine[4].TestField("Document No.", NewDocNo);
    end;

    [Test]
    [HandlerFunctions('YesConfirmHandler')]
    procedure RenumberDocGLAccountBeforeVendorRefund()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: array[4] of Record "Gen. Journal Line";
        NoSeries: Codeunit "No. Series";
        OldDocNo: Code[20];
        NewDocNo: Code[20];
    begin
        // [SCENARIO 569020] Stan can renumber document numbers for multiple refund general journal lines and G/L account lines goes before vendor
        Initialize();

        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        CreateGenJournalBatchWithNoSeries(GenJournalBatch, GenJournalTemplate.Name, LibraryERM.CreateNoSeriesCode());
        NewDocNo := NoSeries.PeekNextNo(GenJournalBatch."No. Series");
        // [GIVEN] General journal with multiple lines
        // [GIVEN] "Document Type" = Refund, "Document No." = "X1", "Account Type" = G/L Account, "Account No." = Y, "Bal. Account No." is blank
        // [GIVEN] "Document Type" = Refund, "Document No." = "X1", "Account Type" = Vendor, "Account No." = 10000, "Bal. Account No." is blank
        // [GIVEN] "Document Type" = Refund, "Document No." = "X1", "Account Type" = G/L Account, "Account No." = Y, "Bal. Account No." is blank
        // [GIVEN] "Document Type" = Refund, "Document No." = "X1", "Account Type" = Vendor, "Account No." = 20000, "Bal. Account No." is blank
        OldDocNo := LibraryUtility.GenerateGUID();
        CreateGeneralJnlLineWithBatchAndDocNo(
            GenJournalLine[1], GenJournalTemplate.Name, GenJournalBatch.Name,
            GenJournalLine[1]."Document Type"::Refund, OldDocNo, GenJournalLine[1]."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
            GenJournalLine[1]."Bal. Account Type"::"G/L Account", '', LibraryRandom.RandDec(100, 2));
        CreateGeneralJnlLineWithBatchAndDocNo(
            GenJournalLine[2], GenJournalTemplate.Name, GenJournalBatch.Name,
            GenJournalLine[2]."Document Type"::Refund, OldDocNo, GenJournalLine[2]."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(),
            GenJournalLine[2]."Bal. Account Type"::"G/L Account", '', LibraryRandom.RandDec(100, 2));
        CreateGeneralJnlLineWithBatchAndDocNo(
            GenJournalLine[3], GenJournalTemplate.Name, GenJournalBatch.Name,
            GenJournalLine[3]."Document Type"::Refund, OldDocNo, GenJournalLine[3]."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
            GenJournalLine[3]."Bal. Account Type"::"G/L Account", '', LibraryRandom.RandDec(100, 2));
        CreateGeneralJnlLineWithBatchAndDocNo(
            GenJournalLine[4], GenJournalTemplate.Name, GenJournalBatch.Name,
            GenJournalLine[4]."Document Type"::Refund, OldDocNo, GenJournalLine[4]."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(),
            GenJournalLine[2]."Bal. Account Type"::"G/L Account", '', LibraryRandom.RandDec(100, 2));

        // [WHEN] Renumber Document No.
        GenJournalLine[4].RenumberDocumentNo();

        // [THEN] The "Document No." has been renumbered in the following way
        // [GIVEN] "Document Type" = Refund, "Document No." = "Z1", "Account Type" = G/L Account, "Account No." = Y, "Bal. Account No." is blank
        // [GIVEN] "Document Type" = Refund, "Document No." = "Z1", "Account Type" = Vendor, "Account No." = 10000, "Bal. Account No." is blank
        // [GIVEN] "Document Type" = Refund, "Document No." = "Z1", "Account Type" = G/L Account, "Account No." = Y, "Bal. Account No." is blank
        // [GIVEN] "Document Type" = Refund, "Document No." = "Z1", "Account Type" = Vendor, "Account No." = 20000, "Bal. Account No." is blank
        GenJournalLine[1].Find();
        GenJournalLine[1].TestField("Document No.", NewDocNo);
        GenJournalLine[2].Find();
        GenJournalLine[2].TestField("Document No.", NewDocNo);
        GenJournalLine[3].Find();
        GenJournalLine[3].TestField("Document No.", NewDocNo);
        GenJournalLine[4].Find();
        GenJournalLine[4].TestField("Document No.", NewDocNo);
    end;

    [Test]
    procedure VendorNameFieldPopulatesOnlyForVendorAccountType()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        GLAccount: Record "G/L Account";
        Vendor: Record Vendor;
        PurchaseJournal: TestPage "Purchase Journal";
    begin
        // [SCENARIO 599505] Purchase Journal page validates vendor name field based on account type
        Initialize();

        // [GIVEN] Create a vendor with random name
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Name := LibraryRandom.RandText(20);
        Vendor.Modify(true);

        // [GIVEN] Create Purchase Journal Template and Batch
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, LibraryJournals.SelectGenJournalTemplate(GenJournalTemplate.Type::Purchases, Page::"Purchase Journal"));

        // [WHEN] Open Purchase Journal page and perform actions as per YAML recording
        PurchaseJournal.OpenEdit();
        PurchaseJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);

        // [GIVEN] Set Document Type to Invoice and Document No. to random value
        PurchaseJournal."Document Type".SetValue("Gen. Journal Document Type"::Invoice);
        PurchaseJournal."Document No.".SetValue(LibraryRandom.RandText(10));

        // [GIVEN] Set Account Type to Vendor and Account No. to Vendor."No."
        PurchaseJournal."Account Type".SetValue("Gen. Journal Account Type"::Vendor);
        PurchaseJournal."Account No.".SetValue(Vendor."No.");

        // [THEN] Verify Vendor Name page field is populated with Vendor.Name
        PurchaseJournal."<Vendor Name>".AssertEquals(Vendor.Name);

        // [WHEN] Set Account Type to G/L Account and Account No. to a new G/L Account."No."
        PurchaseJournal."Account Type".SetValue("Gen. Journal Account Type"::"G/L Account");
        LibraryERM.CreateGLAccount(GLAccount);
        PurchaseJournal."Account No.".SetValue(GLAccount."No.");

        // [THEN] Verify Vendor Name field should be empty for G/L Account
        PurchaseJournal."<Vendor Name>".AssertEquals('');

        // [CLEANUP] Close Purchase Journal page
        PurchaseJournal.Close();
    end;

    [Test]
    [HandlerFunctions('GenJournalTemplateListModalPageHandler')]
    [Scope('OnPrem')]
    procedure BatchNameLookup_SaveRecord_OnlyWhenNotEmptyLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch1: Record "Gen. Journal Batch";
        GenJournalBatch2: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        TestPageGeneralJournal: TestPage "General Journal";
        BatchName1: Code[10];
        BatchName2: Code[10];
        InitialAmount: Decimal;
    begin
        // [SCENARIO 609699] Batch Name lookup and switching batches works correctly with empty lines in General Journal
        Initialize();

        // [GIVEN] Create one template with two batches (same template to avoid template switch issues)
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch1, GenJournalTemplate.Name);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch2, GenJournalTemplate.Name);
        BatchName1 := GenJournalBatch1.Name;
        BatchName2 := GenJournalBatch2.Name;

        // [GIVEN] Create a journal line with data in first batch
        InitialAmount := LibraryRandom.RandDec(1000, 2);
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJournalTemplate.Name, GenJournalBatch1.Name,
            GenJournalLine."Document Type"::Invoice,
            GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(),
            InitialAmount);

        // [GIVEN] Setup modal handlers - store template name for template selection modal
        LibraryVariableStorage.Enqueue(GenJournalTemplate.Name);
        // Store batch name for batch selection modal (if needed)
        LibraryVariableStorage.Enqueue(BatchName1);

        // [WHEN] Open the General Journal page with the first batch
        TestPageGeneralJournal.OpenEdit();
        // The modal handlers will automatically select template and batch

        // [THEN] Verify the line data is displayed
        Assert.AreEqual(InitialAmount, TestPageGeneralJournal.Amount.AsDecimal(), 'Amount should be displayed when batch has data');

        // [WHEN] Change to a different batch directly
        TestPageGeneralJournal.CurrentJnlBatchName.SetValue(BatchName2);

        // [THEN] Verify the page shows empty lines for the new batch
        Assert.AreEqual(0, TestPageGeneralJournal.Amount.AsDecimal(), 'Amount should be 0 when switching to empty batch');

        // [WHEN] Switch back to the original batch with data
        TestPageGeneralJournal.CurrentJnlBatchName.SetValue(BatchName1);

        // [THEN] Verify the original data is still preserved
        Assert.AreEqual(InitialAmount, TestPageGeneralJournal.Amount.AsDecimal(), 'Original data should be preserved when switching back');

        // [WHEN] Delete all lines and switch batches
        GenJournalLine.DeleteAll();
        TestPageGeneralJournal.CurrentJnlBatchName.SetValue(BatchName2);

        // [THEN] Verify no error occurs when switching from empty batch
        Assert.AreEqual(BatchName2, TestPageGeneralJournal.CurrentJnlBatchName.Value(),
            'Should be able to switch from empty batch without error');
        TestPageGeneralJournal.Close();
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();
        if IsInitialized then
            exit;

        LibraryERMCountryData.UpdateLocalData();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        IsInitialized := true;

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
    end;

    local procedure MockGenJournalLineWithKeepDescription(var GenJnlLine: Record "Gen. Journal Line")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGenJournalTemplateBatch(GenJournalTemplate, GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine2(GenJnlLine, GenJournalTemplate.Name, GenJournalBatch.Name, "Gen. Journal Document Type"::" ",
            "Gen. Journal Account Type"::"G/L Account", '', LibraryRandom.RandDec(100, 2));
        GenJnlLine."Keep Description" := true;
        GenJnlLine.Description := LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen((GenJnlLine.Description)), 0);
        GenJnlLine.Modify();
    end;

    local procedure MockIntercompanyGenJournalLineWithKeepDescription(var GenJnlLine: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateICJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine2(GenJnlLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, "Gen. Journal Document Type"::" ",
            "Gen. Journal Account Type"::"G/L Account", '', LibraryRandom.RandDec(100, 2));
        GenJnlLine."Keep Description" := true;
        GenJnlLine.Description := LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen((GenJnlLine.Description)), 0);
        GenJnlLine.Modify();
    end;

    local procedure CreateICJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Intercompany);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure PreparePaymentTemplateBatchAndPage(var GeneralJournalBatches: TestPage "General Journal Batches")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGenJournalTemplateBatchPayment(GenJournalTemplate, GenJournalBatch);
        PrepareGeneralJournalBatchesPage(GeneralJournalBatches, GenJournalBatch);
    end;

    local procedure PrepareTemplateBatchAndPageWithTypeAndReccuring(var GeneralJournalBatches: TestPage "General Journal Batches"; GenJournalTemplateType: Enum "Gen. Journal Template Type"; Recurring: Boolean)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGenJournalTemplateBatchWithTypeAndRecurring(GenJournalTemplate, GenJournalBatch, GenJournalTemplateType, Recurring);
        PrepareGeneralJournalBatchesPage(GeneralJournalBatches, GenJournalBatch);
    end;

    local procedure PrepareGeneralJournalBatchesPage(var GeneralJournalBatches: TestPage "General Journal Batches"; GenJournalBatch: Record "Gen. Journal Batch")
    begin
        GeneralJournalBatches.OpenEdit();
        GeneralJournalBatches.FILTER.SetFilter("Journal Template Name", GenJournalBatch."Journal Template Name");
        GeneralJournalBatches.GotoRecord(GenJournalBatch);
    end;

    local procedure MockGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; BalAccountNo: Code[20]; CurrencyCode: Code[10])
    begin
        GenJournalLine.Init();
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::Customer);
        GenJournalLine.Validate("Account No.", LibrarySales.CreateCustomerNo());
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocType: Enum "Gen. Journal Document Type"; AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; BalAccType: Enum "Gen. Journal Account Type"; BalAccNo: Code[20]; NoSeriesCode: Code[20])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGenJournalTemplateBatch(GenJournalTemplate, GenJournalBatch);
        GenJournalBatch."Bal. Account Type" := BalAccType;
        GenJournalBatch."Bal. Account No." := BalAccNo;
        GenJournalBatch."No. Series" := NoSeriesCode;
        GenJournalBatch.Modify();
        LibraryERM.CreateGeneralJnlLine2(GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, DocType,
          AccType, AccNo, LibraryRandom.RandDec(100, 2))
    end;

    local procedure CreateGenJournalLineWithDocNo(var GenJournalLine: Record "Gen. Journal Line"; DocNo: Code[20])
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        NoSeriesLine.Get(LibraryERM.CreateNoSeriesCode(), 10000);
        NoSeriesLine."Starting No." := DocNo;
        NoSeriesLine."Ending No." := '';
        NoSeriesLine.Modify();

        CreateGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(),
          GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), NoSeriesLine."Series Code");
        GenJournalLine."Document No." := DocNo;
        GenJournalLine.Modify();
    end;

    local procedure CreateGenJournalLineWithEmptyDocNo(GenJournalTemplateName: Code[10]; GenJournalBatchName: Code[10]; var GenJournalLine: Record "Gen. Journal Line"; GLAccountNo: Code[20]; BalGLAccountNo: Code[20])
    begin
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJournalLine, GenJournalTemplateName, GenJournalBatchName, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", GLAccountNo, GenJournalLine."Bal. Account Type"::"G/L Account",
          BalGLAccountNo, LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("Document No.", '');
        GenJournalLine.Modify(true);
    end;

    local procedure CreateSingleLineGenJnlDoc(var GenJournalLine: Record "Gen. Journal Line"; AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20])
    begin
        LibraryERM.CreateGeneralJnlLine2(GenJournalLine, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
          GenJournalLine."Document Type"::" ", AccType, AccNo, LibraryRandom.RandDec(100, 2))
    end;

    local procedure CreateSingleLineInvoice(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20]): Code[20]
    begin
        CreateSingleLineGenJnlDoc(GenJournalLine, GenJournalLine."Account Type"::Vendor, VendorNo);
        GenJournalLine."Document Type" := GenJournalLine."Document Type"::Invoice;
        exit(SetNewDocNo(GenJournalLine))
    end;

    local procedure CreateSingleLinePayment(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20]; AppliesToDocNo: Code[20])
    begin
        CreateSingleLineGenJnlDoc(GenJournalLine, GenJournalLine."Account Type"::Vendor, VendorNo);
        GenJournalLine."Document Type" := GenJournalLine."Document Type"::Payment;
        GenJournalLine."Applies-to Doc. Type" := GenJournalLine."Applies-to Doc. Type"::Invoice;
        GenJournalLine."Applies-to Doc. No." := AppliesToDocNo;
        GenJournalLine.Modify();
    end;

    local procedure CreateGenJournalLine1(var GenJournalLine: Record "Gen. Journal Line"; GenJnlBatchName: Code[10]; GenJnlTemplateName: Code[10]; AccountNo: Code[20]; Amount: Decimal; DocNo: Code[20])
    begin
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJnlTemplateName, GenJnlBatchName,
            GenJournalLine."Document Type"::" ",
            GenJournalLine."Account Type"::"G/L Account", AccountNo, Amount);
        GenJournalLine.Validate("Document No.", DocNo);
        GenJournalLine.Modify();
    end;

    local procedure CreateGeneralJnlLineWithBalAcc(var GenJournalLine: Record "Gen. Journal Line"; GenJnlBatchName: Code[10]; GenJnlTemplateName: Code[10]; AccountNo: Code[20]; Amount: Decimal; DocNo: Code[20])
    begin
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
            GenJournalLine, GenJnlTemplateName, GenJnlBatchName,
            GenJournalLine."Document Type"::" ",
            GenJournalLine."Account Type"::"G/L Account", AccountNo,
            "Gen. Journal Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(), Amount);
        GenJournalLine.Validate("Document No.", DocNo);
        GenJournalLine.Modify();
    end;

    local procedure CreateGeneralJnlLineWithBatchAndDocNo(var GenJournalLine: Record "Gen. Journal Line"; JournalTemplateName: Code[10]; JournalBatchName: Code[10]; DocumentType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; BalAccountType: Enum "Gen. Journal Account Type"; BalAccountNo: Code[20]; Amount: Decimal)
    begin
        LibraryERM.CreateGeneralJnlLine2WithBalAcc(
            GenJournalLine, JournalTemplateName, JournalBatchName,
            DocumentType, AccountType, AccountNo, BalAccountType, BalAccountNo, Amount);
        GenJournalLine.Validate("Document No.", DocNo);
        GenJournalLine.Modify();
    end;

    local procedure CreateMultiLineGenJnlDoc(var GenJournalLine: Record "Gen. Journal Line"; AccNo: Code[20]; AccNo2: Code[20])
    begin
        LibraryERM.CreateGeneralJnlLine2WithBalAcc(GenJournalLine, GenJournalLine."Journal Template Name",
          GenJournalLine."Journal Batch Name", GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account",
          AccNo, GenJournalLine."Bal. Account Type"::"G/L Account", '', LibraryRandom.RandDec(100, 2));
        LibraryERM.CreateGeneralJnlLine2WithBalAcc(GenJournalLine, GenJournalLine."Journal Template Name",
          GenJournalLine."Journal Batch Name", GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account",
          AccNo2, GenJournalLine."Bal. Account Type"::"G/L Account", '', -GenJournalLine.Amount);
    end;

    local procedure CreateSingleLineGenJnlDocAndVendEntry(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20])
    var
        VendLedgerEntry: Record "Vendor Ledger Entry";
    begin
        CreateSingleLineGenJnlDoc(GenJournalLine, GenJournalLine."Account Type"::Vendor, VendorNo);
        SetNewDocNoAndAppliesToID(GenJournalLine);
        CreateVendLedgEntry(VendLedgerEntry, VendorNo, GenJournalLine."Document No.")
    end;

    local procedure CreateGenJournalLineWithVendEntry(var GenJournalLine: Record "Gen. Journal Line"; NoSeriesCode: Code[20]; VendorNo: Code[20]; GLAccountNo: Code[20]): Integer
    var
        VendLedgerEntry: Record "Vendor Ledger Entry";
    begin
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::Vendor, VendorNo,
          GenJournalLine."Account Type"::"G/L Account", GLAccountNo, NoSeriesCode);
        GenJournalLine."Applies-to ID" := GenJournalLine."Document No.";
        GenJournalLine.Modify();
        CreateVendLedgEntry(VendLedgerEntry, VendorNo, GenJournalLine."Document No.");
        exit(VendLedgerEntry."Entry No.")
    end;

    local procedure CreateSingleLineGenJnlDocAndCustEntry(var GenJournalLine: Record "Gen. Journal Line"; CustomerNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CreateSingleLineGenJnlDoc(GenJournalLine, GenJournalLine."Account Type"::Customer, CustomerNo);
        SetNewDocNoAndAppliesToID(GenJournalLine);
        CreateCustLedgEntry(CustLedgerEntry, CustomerNo, GenJournalLine."Document No.")
    end;

    local procedure CreateGenJournalTemplateBatch(var GenJournalTemplate: Record "Gen. Journal Template"; var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateGenJournalTemplateBatchPayment(var GenJournalTemplate: Record "Gen. Journal Template"; var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        CreateGenJournalTemplateBatch(GenJournalTemplate, GenJournalBatch);
        GenJournalTemplate.Validate(Type, GenJournalTemplate.Type::Payments);
        GenJournalTemplate.Modify(true);
    end;

    local procedure CreateGenJournalTemplateBatchWithTypeAndRecurring(var GenJournalTemplate: Record "Gen. Journal Template"; var GenJournalBatch: Record "Gen. Journal Batch"; GenJournalTemplateType: Enum "Gen. Journal Template Type"; Recurring: Boolean)
    begin
        CreateGenJournalTemplateBatch(GenJournalTemplate, GenJournalBatch);
        GenJournalTemplate.Validate(Type, GenJournalTemplateType);
        GenJournalTemplate.Validate(Recurring, Recurring);
        GenJournalTemplate.Modify(true);
    end;

    local procedure CreateGenJournalBatchWithNoSeries(var GenJournalBatch: Record "Gen. Journal Batch"; GenJournalTemplateName: Code[10]; NoSeriesCode: Code[20])
    begin
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplateName);
        GenJournalBatch.Validate("No. Series", NoSeriesCode);
        GenJournalBatch.Modify(true);
    end;

    local procedure CreateGenJournalLineWithCustEntry(var GenJournalLine: Record "Gen. Journal Line"; NoSeriesCode: Code[20]; CustomerNo: Code[20]; GLAccountNo: Code[20]): Integer
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CreateGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::Customer, CustomerNo,
          GenJournalLine."Account Type"::"G/L Account", GLAccountNo, NoSeriesCode);
        GenJournalLine."Applies-to ID" := GenJournalLine."Document No.";
        GenJournalLine.Modify();
        CreateCustLedgEntry(CustLedgerEntry, CustomerNo, GenJournalLine."Document No.");
        exit(CustLedgerEntry."Entry No.")
    end;

    local procedure CreateGenJournalLineTemplate(var GenJournalLine: Record "Gen. Journal Line"; var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        CreateGenJournalTemplateBatch(GenJournalTemplate, GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(), LibraryRandom.RandDec(1000, 2));
    end;

    local procedure CreateVendLedgEntry(var VendLedgEntry: Record "Vendor Ledger Entry"; VendorNo: Code[20]; AppliesToID: Code[50])
    begin
        VendLedgEntry.FindLast();
        VendLedgEntry.Init();
        VendLedgEntry."Entry No." += 1;
        VendLedgEntry."Vendor No." := VendorNo;
        VendLedgEntry."Applies-to ID" := AppliesToID;
        VendLedgEntry.Open := true;
        VendLedgEntry.Insert();
    end;

    local procedure CreateCustLedgEntry(var CustLedgEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20]; AppliesToID: Code[50])
    begin
        CustLedgEntry.FindLast();
        CustLedgEntry.Init();
        CustLedgEntry."Entry No." += 1;
        CustLedgEntry."Customer No." := CustomerNo;
        CustLedgEntry."Applies-to ID" := AppliesToID;
        CustLedgEntry.Open := true;
        CustLedgEntry.Insert();
    end;

    local procedure CreateCustomerWithName(var Customer: Record Customer)
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate(Name, LibraryUtility.GenerateGUID());
        Customer.Modify(true);
    end;

    local procedure CreateVendorWithName(var Vendor: Record Vendor)
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate(Name, LibraryUtility.GenerateGUID());
        Vendor.Modify(true);
    end;

    local procedure CreateCustomerWithBankAccount(var Customer: Record Customer)
    var
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, Customer."No.");
        Customer."Preferred Bank Account Code" := CustomerBankAccount.Code;
        Customer.Modify();
    end;

    local procedure CreateVendorWithBankAccount(var Vendor: Record Vendor)
    var
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
        Vendor."Preferred Bank Account Code" := VendorBankAccount.Code;
        Vendor.Modify();
    end;

    local procedure CreateCurrency(): Code[10]
    begin
        exit(LibraryERM.CreateCurrencyWithExchangeRate(
            WorkDate(), LibraryRandom.RandDecInRange(10, 20, 2), LibraryRandom.RandDecInRange(1, 10, 2)));
    end;

    local procedure CreateBankAccountWithCurrency(CurrencyCode: Code[10]): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Currency Code", CurrencyCode);
        BankAccount.Modify(true);
        exit(BankAccount."No.");
    end;

    local procedure PrepareGenJournalTemplateWithTwoBatchesAndGenJournalLines(var GenJournalLine: array[2] of Record "Gen. Journal Line")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: array[2] of Record "Gen. Journal Batch";
        CustomerNo: Code[20];
        Index: Integer;
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        CustomerNo := LibrarySales.CreateCustomerNo();
        for Index := 1 to ArrayLen(GenJournalBatch) do begin
            LibraryERM.CreateGenJournalBatch(GenJournalBatch[Index], GenJournalTemplate.Name);
            LibraryERM.CreateGeneralJnlLine(
              GenJournalLine[Index], GenJournalTemplate.Name, GenJournalBatch[Index].Name,
              GenJournalLine[Index]."Document Type"::Invoice, GenJournalLine[Index]."Account Type"::Customer, CustomerNo, LibraryRandom.RandDec(1000, 2));
        end;
    end;

    local procedure UpdateDescriptionAdHoc(var GenJournalLine: Record "Gen. Journal Line"; var AdHocDescription: Code[50])
    begin
        AdHocDescription := LibraryUtility.GenerateRandomCode(GenJournalLine.FieldNo(Description), DATABASE::"Gen. Journal Line");
        GenJournalLine.Validate(Description, AdHocDescription);
        GenJournalLine.Modify(true);
    end;

    local procedure SetNewDocNo(var GenJournalLine: Record "Gen. Journal Line"): Code[20]
    var
        i: Integer;
    begin
        for i := 1 to LibraryRandom.RandIntInRange(2, 10) do
            GenJournalLine."Document No." := IncStr(GenJournalLine."Document No.");
        GenJournalLine.Modify();
        exit(GenJournalLine."Document No.")
    end;

    local procedure SetNewDocNoAndAppliesToID(var GenJournalLine: Record "Gen. Journal Line"): Code[20]
    begin
        SetNewDocNo(GenJournalLine);
        GenJournalLine."Applies-to ID" := GenJournalLine."Document No.";
        GenJournalLine.Modify();
        exit(GenJournalLine."Document No.")
    end;

    local procedure SetDocNoAndAppliesToDocNo(var GenJournalLine: Record "Gen. Journal Line"; DocNo: Code[20]; AppliesToDocNo: Code[20])
    begin
        GenJournalLine."Document No." := DocNo;
        GenJournalLine."Applies-to Doc. No." := AppliesToDocNo;
        GenJournalLine.Modify();
    end;

    local procedure FindOpenCustLedgEntryAndSetExtDoc(var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
        CustLedgEntry.SetRange(Open, true);
        CustLedgEntry.FindFirst();
        CustLedgEntry."External Document No." :=
          LibraryUtility.GenerateRandomCode(CustLedgEntry.FieldNo("External Document No."), DATABASE::"Cust. Ledger Entry");
        CustLedgEntry.Modify();
    end;

    local procedure FindOpenVendLedgEntry(var VendLedgEntry: Record "Vendor Ledger Entry")
    begin
        VendLedgEntry.SetRange(Open, true);
        VendLedgEntry.SetFilter("External Document No.", '<>%1', '');
        VendLedgEntry.FindFirst();
    end;

    local procedure RunGenJnlApplyAction(GenJournalLine: Record "Gen. Journal Line"; ExpectedApplyingAccountNo: Code[20]; ExpectedApplyingDescription: Text)
    begin
        LibraryVariableStorage.Enqueue(ExpectedApplyingAccountNo);
        LibraryVariableStorage.Enqueue(ExpectedApplyingDescription);
        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Apply", GenJournalLine);
    end;

    local procedure RunEditJournalActionOnPaymentJournalPage(var PaymentJournal: TestPage "Payment Journal"; GeneralJournalBatches: TestPage "General Journal Batches")
    begin
        PaymentJournal.Trap();
        GeneralJournalBatches.EditJournal.Invoke();
    end;

    local procedure RunEditJournalActionOnGeneralJournalPage(var GeneralJournal: TestPage "General Journal"; GeneralJournalBatches: TestPage "General Journal Batches")
    begin
        GeneralJournal.Trap();
        GeneralJournalBatches.EditJournal.Invoke();
    end;

    local procedure RunGeneralJournalPreviewPage(var GLEntriesPreview: TestPage "G/L Entries Preview")
    begin
        GLEntriesPreview.OpenEdit();
    end;

    local procedure RunEditJournalActionOnJobGLJournalPage(var JobGLJournal: TestPage "Job G/L Journal"; GeneralJournalBatches: TestPage "General Journal Batches")
    begin
        JobGLJournal.Trap();
        GeneralJournalBatches.EditJournal.Invoke();
    end;

    local procedure RunEditJournalActionOnSalesJournalPage(var SalesJournal: TestPage "Sales Journal"; GeneralJournalBatches: TestPage "General Journal Batches")
    begin
        SalesJournal.Trap();
        GeneralJournalBatches.EditJournal.Invoke();
    end;

    local procedure RunEditJournalActionOnPurchaseJournalPage(var PurchaseJournal: TestPage "Purchase Journal"; GeneralJournalBatches: TestPage "General Journal Batches")
    begin
        PurchaseJournal.Trap();
        GeneralJournalBatches.EditJournal.Invoke();
    end;

    local procedure RunEditJournalActionOnCashReceiptJournalPage(var CashReceiptJournal: TestPage "Cash Receipt Journal"; GeneralJournalBatches: TestPage "General Journal Batches")
    begin
        CashReceiptJournal.Trap();
        GeneralJournalBatches.EditJournal.Invoke();
    end;

    local procedure RunEditJournalActionOnRecurringGeneralJournalPage(var RecurringGeneralJournal: TestPage "Recurring General Journal"; GeneralJournalBatches: TestPage "General Journal Batches")
    begin
        RecurringGeneralJournal.Trap();
        GeneralJournalBatches.EditJournal.Invoke();
    end;

    local procedure SetUpNewGenJnlLineWithNoSeries(GenJournalLine: Record "Gen. Journal Line"; var GenJournalLineNew: Record "Gen. Journal Line"; IncrementByNo: Integer)
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        NoSeriesLine: Record "No. Series Line";
        NoSeries: Codeunit "No. Series";
    begin
        GenJnlBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");

        NoSeries.GetNoSeriesLine(NoSeriesLine, GenJnlBatch."No. Series", GenJournalLine."Posting Date", true);
        NoSeriesLine.Validate("Increment-by No.", IncrementByNo);
        NoSeriesLine.Modify(true);

        GenJournalLineNew."Journal Template Name" := GenJournalLine."Journal Template Name";
        GenJournalLineNew."Journal Batch Name" := GenJournalLine."Journal Batch Name";
        GenJournalLineNew.SetUpNewLine(GenJournalLine, GenJournalLine."Balance (LCY)", true);
    end;

    local procedure ValidateAmountAndVerifySalesPurchLCYGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; RecurringMethod: Enum "Gen. Journal Recurring Method"; SystemCreatedEntry: Boolean; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; BalAccountType: Enum "Gen. Journal Account Type"; BalAccountNo: Code[20]; ValidateAmount: Decimal; ExpectedValue: Decimal)
    begin
        GenJournalLine.Init();
        GenJournalLine."Recurring Method" := RecurringMethod;
        GenJournalLine."System-Created Entry" := SystemCreatedEntry;
        GenJournalLine."Document Type" := DocumentType;
        GenJournalLine."Account Type" := AccountType;
        GenJournalLine."Account No." := AccountNo;
        GenJournalLine."Bal. Account Type" := BalAccountType;
        GenJournalLine."Bal. Account No." := BalAccountNo;
        GenJournalLine.Validate(Amount, ValidateAmount);
        GenJournalLine.TestField("Sales/Purch. (LCY)", ExpectedValue);
    end;

    local procedure VerifyAmountDebitAndCreditValues(GenJournalLine: Record "Gen. Journal Line"; ExpectedAmount: Decimal; ExpectedDebitAmount: Decimal; ExpectedCreditAmount: Decimal)
    begin
        GenJournalLine.TestField(Amount, ExpectedAmount);
        GenJournalLine.TestField("Debit Amount", ExpectedDebitAmount);
        GenJournalLine.TestField("Credit Amount", ExpectedCreditAmount);
    end;

    local procedure VerifyGenJnlLineDocNo(TemplateName: Code[20]; BatchName: Code[20]; LineNo: Integer; DocNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.Get(TemplateName, BatchName, LineNo);
        GenJournalLine.TestField("Document No.", DocNo)
    end;

    local procedure VerifyGenJnlLineDocNoAndAppliesToDocNo(TemplateName: Code[20]; BatchName: Code[20]; LineNo: Integer; DocNo: Code[20]; AppliesToDocNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.Get(TemplateName, BatchName, LineNo);
        GenJournalLine.TestField("Document No.", DocNo);
        GenJournalLine.TestField("Applies-to Doc. No.", AppliesToDocNo)
    end;

    local procedure VerifyGenJnlDocNoAndAppliesToIDVend(GenJournalLine: Record "Gen. Journal Line"; LineNo: Integer; EntryNo: Integer; DocNo: Code[20])
    begin
        VerifyGenJnlLineDocNo(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
          LineNo, DocNo);
        VerifyGenJnlLineAppliesToID(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
          LineNo, DocNo);
        VerifyVendLedgerEntry(EntryNo, DocNo)
    end;

    local procedure VerifyGenJnlDocNoAndAppliesToIDCust(GenJournalLine: Record "Gen. Journal Line"; LineNo: Integer; EntryNo: Integer; DocNo: Code[20])
    begin
        VerifyGenJnlLineDocNo(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
          LineNo, DocNo);
        VerifyGenJnlLineAppliesToID(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
          LineNo, DocNo);
        VerifyCustLedgerEntry(EntryNo, DocNo)
    end;

    local procedure VerifyGenJnlLineAppliesToID(TemplateName: Code[20]; BatchName: Code[20]; LineNo: Integer; AppliesToID: Code[50])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.Get(TemplateName, BatchName, LineNo);
        GenJournalLine.TestField("Applies-to ID", AppliesToID)
    end;

    local procedure VerifyVendLedgerEntry(EntryNo: Integer; AppliesToID: Code[50])
    var
        VendLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendLedgerEntry.Get(EntryNo);
        VendLedgerEntry.TestField("Applies-to ID", AppliesToID)
    end;

    local procedure VerifyCustLedgerEntry(EntryNo: Integer; AppliesToID: Code[50])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.Get(EntryNo);
        CustLedgerEntry.TestField("Applies-to ID", AppliesToID)
    end;

    local procedure VerifyGenJnlLineFieldsAreBlank(GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine.TestField("Bill-to/Pay-to No.", '');
        GenJournalLine.TestField("Ship-to/Order Address Code", '');
        GenJournalLine.TestField("Sell-to/Buy-from No.", '');
        GenJournalLine.TestField("Country/Region Code", '');
        GenJournalLine.TestField("VAT Registration No.", '');
    end;

    local procedure VerifyGenJnlBatchIsEmpty(GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        Assert.RecordIsEmpty(GenJournalLine);
    end;

    local procedure VerifyGenJnlLinePageDebitCreditAmtFieldsVisibility(GeneralJournal: TestPage "General Journal"; DebitAmountVisilble: Boolean; CreditAmountVisilble: Boolean; AmountVisilble: Boolean)
    begin
        Assert.AreEqual(DebitAmountVisilble, GeneralJournal."Debit Amount".Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(CreditAmountVisilble, GeneralJournal."Credit Amount".Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(AmountVisilble, GeneralJournal.Amount.Visible(), WrongFieldVisibilityErr);
        GeneralJournal.Close();
    end;

    local procedure VerifyGenJnlLinePageDebitCreditAmtFieldsVisibility(GLEntriesPreview: TestPage "G/L Entries Preview"; DebitAmountVisilble: Boolean; CreditAmountVisilble: Boolean; AmountVisilble: Boolean)
    begin
        Assert.AreEqual(DebitAmountVisilble, GLEntriesPreview."Debit Amount".Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(CreditAmountVisilble, GLEntriesPreview."Credit Amount".Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(AmountVisilble, GLEntriesPreview.Amount.Visible(), WrongFieldVisibilityErr);
        GLEntriesPreview.Close();
    end;

    local procedure VerifyPaymentJnlLinePageDebitCreditAmtFieldsVisibility(PaymentJournal: TestPage "Payment Journal"; DebitAmountVisilble: Boolean; CreditAmountVisilble: Boolean; AmountVisilble: Boolean)
    begin
        Assert.IsTrue(PaymentJournal."Posting Date".Visible(), PaymentJournal."Posting Date".Caption);
        Assert.IsTrue(PaymentJournal."Document Type".Visible(), PaymentJournal."Document Type".Caption);
        Assert.IsTrue(PaymentJournal."Document No.".Visible(), PaymentJournal."Document No.".Caption);

        Assert.AreEqual(DebitAmountVisilble, PaymentJournal."Debit Amount".Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(CreditAmountVisilble, PaymentJournal."Credit Amount".Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(AmountVisilble, PaymentJournal.Amount.Visible(), WrongFieldVisibilityErr);
        PaymentJournal.Close();
    end;

    local procedure VerifyJobGLJnlPageDebitCreditAmtFieldsVisibility(JobGLJournal: TestPage "Job G/L Journal"; DebitAmountVisilble: Boolean; CreditAmountVisilble: Boolean; AmountVisilble: Boolean; AmountLCYVisilble: Boolean)
    begin
        Assert.IsTrue(JobGLJournal."Posting Date".Visible(), JobGLJournal."Posting Date".Caption);
        Assert.IsTrue(JobGLJournal."Document Type".Visible(), JobGLJournal."Document Type".Caption);
        Assert.IsTrue(JobGLJournal."Document No.".Visible(), JobGLJournal."Document No.".Caption);

        Assert.AreEqual(DebitAmountVisilble, JobGLJournal."Debit Amount".Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(CreditAmountVisilble, JobGLJournal."Credit Amount".Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(AmountVisilble, JobGLJournal.Amount.Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(AmountLCYVisilble, JobGLJournal."Amount (LCY)".Visible(), WrongFieldVisibilityErr);
        JobGLJournal.Close();
    end;

    local procedure VerifyChartOfAccountsPageDebitCreditAmtFieldsVisibility(ChartOfAccounts: TestPage "Chart of Accounts"; DebitAmountVisilble: Boolean; CreditAmountVisilble: Boolean)
    begin
        Assert.AreEqual(DebitAmountVisilble, ChartOfAccounts."Debit Amount".Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(CreditAmountVisilble, ChartOfAccounts."Credit Amount".Visible(), WrongFieldVisibilityErr);
        ChartOfAccounts.Close();
    end;

    local procedure VerifyGeneralLedgerEntriesPageDebitCreditAmtFieldsVisibility(GeneralLedgerEntries: TestPage "General Ledger Entries"; DebitAmountVisilble: Boolean; CreditAmountVisilble: Boolean; AmountVisilble: Boolean)
    begin
        Assert.AreEqual(DebitAmountVisilble, GeneralLedgerEntries."Debit Amount".Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(CreditAmountVisilble, GeneralLedgerEntries."Credit Amount".Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(AmountVisilble, GeneralLedgerEntries.Amount.Visible(), WrongFieldVisibilityErr);
        GeneralLedgerEntries.Close();
    end;

    local procedure VerifyCustomerLedgerEntriesPageDebitCreditAmtFieldsVisibility(CustomerLedgerEntries: TestPage "Customer Ledger Entries"; DebitAmountVisilble: Boolean; DebitAmountLCYVisilble: Boolean; CreditAmountVisilble: Boolean; CreditAmountLCYVisilble: Boolean; AmountVisilble: Boolean; AmountLCYVisilble: Boolean)
    begin
        Assert.AreEqual(DebitAmountVisilble, CustomerLedgerEntries."Debit Amount".Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(DebitAmountLCYVisilble, CustomerLedgerEntries."Debit Amount (LCY)".Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(CreditAmountVisilble, CustomerLedgerEntries."Credit Amount".Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(CreditAmountLCYVisilble, CustomerLedgerEntries."Credit Amount (LCY)".Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(AmountVisilble, CustomerLedgerEntries.Amount.Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(AmountLCYVisilble, CustomerLedgerEntries."Amount (LCY)".Visible(), WrongFieldVisibilityErr);
        CustomerLedgerEntries.Close();
    end;

    local procedure VerifySalesJnlPageDebitCreditAmtFieldsVisibility(SalesJournal: TestPage "Sales Journal"; DebitAmountVisilble: Boolean; CreditAmountVisilble: Boolean; AmountVisilble: Boolean; AmountLCYVisilble: Boolean)
    begin
        Assert.IsTrue(SalesJournal."Posting Date".Visible(), SalesJournal."Posting Date".Caption);
        Assert.IsTrue(SalesJournal."Document Type".Visible(), SalesJournal."Document Type".Caption);
        Assert.IsTrue(SalesJournal."Document No.".Visible(), SalesJournal."Document No.".Caption);

        Assert.AreEqual(DebitAmountVisilble, SalesJournal."Debit Amount".Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(CreditAmountVisilble, SalesJournal."Credit Amount".Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(AmountVisilble, SalesJournal.Amount.Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(AmountLCYVisilble, SalesJournal."Amount (LCY)".Visible(), WrongFieldVisibilityErr);
        SalesJournal.Close();
    end;

    local procedure VerifyPurchaseJnlPageDebitCreditAmtFieldsVisibility(PurchaseJournal: TestPage "Purchase Journal"; DebitAmountVisilble: Boolean; CreditAmountVisilble: Boolean; AmountVisilble: Boolean; AmountLCYVisilble: Boolean)
    begin
        Assert.IsTrue(PurchaseJournal."Posting Date".Visible(), PurchaseJournal."Posting Date".Caption);
        Assert.IsTrue(PurchaseJournal."Document Type".Visible(), PurchaseJournal."Document Type".Caption);
        Assert.IsTrue(PurchaseJournal."Document No.".Visible(), PurchaseJournal."Document No.".Caption);

        Assert.AreEqual(DebitAmountVisilble, PurchaseJournal."Debit Amount".Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(CreditAmountVisilble, PurchaseJournal."Credit Amount".Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(AmountVisilble, PurchaseJournal.Amount.Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(AmountLCYVisilble, PurchaseJournal."Amount (LCY)".Visible(), WrongFieldVisibilityErr);
        PurchaseJournal.Close();
    end;

    local procedure VerifyCashReceiptJnlPageDebitCreditAmtFieldsVisibility(CashReceiptJournal: TestPage "Cash Receipt Journal"; DebitAmountVisilble: Boolean; CreditAmountVisilble: Boolean; AmountVisilble: Boolean; AmountLCYVisilble: Boolean)
    begin
        Assert.IsTrue(CashReceiptJournal."Posting Date".Visible(), CashReceiptJournal."Posting Date".Caption);
        Assert.IsTrue(CashReceiptJournal."Document Type".Visible(), CashReceiptJournal."Document Type".Caption);
        Assert.IsTrue(CashReceiptJournal."Document No.".Visible(), CashReceiptJournal."Document No.".Caption);

        Assert.AreEqual(DebitAmountVisilble, CashReceiptJournal."Debit Amount".Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(CreditAmountVisilble, CashReceiptJournal."Credit Amount".Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(AmountVisilble, CashReceiptJournal.Amount.Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(AmountLCYVisilble, CashReceiptJournal."Amount (LCY)".Visible(), WrongFieldVisibilityErr);
        CashReceiptJournal.Close();
    end;

    local procedure VerifyRecurringGeneralJnlPageDebitCreditAmtFieldsVisibility(RecurringGeneralJournal: TestPage "Recurring General Journal"; DebitAmountVisilble: Boolean; CreditAmountVisilble: Boolean; AmountVisilble: Boolean; AmountLCYVisilble: Boolean)
    begin
        Assert.IsTrue(RecurringGeneralJournal."Posting Date".Visible(), RecurringGeneralJournal."Posting Date".Caption);
        Assert.IsTrue(RecurringGeneralJournal."Document Type".Visible(), RecurringGeneralJournal."Document Type".Caption);
        Assert.IsTrue(RecurringGeneralJournal."Document No.".Visible(), RecurringGeneralJournal."Document No.".Caption);

        Assert.AreEqual(DebitAmountVisilble, RecurringGeneralJournal."Debit Amount".Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(CreditAmountVisilble, RecurringGeneralJournal."Credit Amount".Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(AmountVisilble, RecurringGeneralJournal.Amount.Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(AmountLCYVisilble, RecurringGeneralJournal."Amount (LCY)".Visible(), WrongFieldVisibilityErr);
        RecurringGeneralJournal.Close();
    end;

    local procedure VerifyVendorLedgerEntriesPageDebitCreditAmtFieldsVisibility(VendorLedgerEntries: TestPage "Vendor Ledger Entries"; DebitAmountVisilble: Boolean; DebitAmountLCYVisilble: Boolean; CreditAmountVisilble: Boolean; CreditAmountLCYVisilble: Boolean; AmountVisilble: Boolean; AmountLCYVisilble: Boolean)
    begin
        Assert.AreEqual(DebitAmountVisilble, VendorLedgerEntries."Debit Amount".Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(DebitAmountLCYVisilble, VendorLedgerEntries."Debit Amount (LCY)".Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(CreditAmountVisilble, VendorLedgerEntries."Credit Amount".Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(CreditAmountLCYVisilble, VendorLedgerEntries."Credit Amount (LCY)".Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(AmountVisilble, VendorLedgerEntries.Amount.Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(AmountLCYVisilble, VendorLedgerEntries."Amount (LCY)".Visible(), WrongFieldVisibilityErr);
        VendorLedgerEntries.Close();
    end;

    local procedure VerifyApplyBankAccLedgerEntriesPageDebitCreditAmtFieldsVisibility(ApplyBankAccLedgerEntries: TestPage "Apply Bank Acc. Ledger Entries"; DebitAmountVisilble: Boolean; CreditAmountVisilble: Boolean; AmountVisilble: Boolean)
    begin
        Assert.AreEqual(DebitAmountVisilble, ApplyBankAccLedgerEntries."Debit Amount".Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(CreditAmountVisilble, ApplyBankAccLedgerEntries."Credit Amount".Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(AmountVisilble, ApplyBankAccLedgerEntries.Amount.Visible(), WrongFieldVisibilityErr);
        ApplyBankAccLedgerEntries.Close();
    end;

    local procedure VerifyDetailedCustLedgEntriesPageDebitCreditAmtFieldsVisibility(DetailedCustLedgEntries: TestPage "Detailed Cust. Ledg. Entries"; DebitAmountVisilble: Boolean; DebitAmountLCYVisilble: Boolean; CreditAmountVisilble: Boolean; CreditAmountLCYVisilble: Boolean; AmountVisilble: Boolean; AmountLCYVisilble: Boolean)
    begin
        Assert.AreEqual(DebitAmountVisilble, DetailedCustLedgEntries."Debit Amount".Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(DebitAmountLCYVisilble, DetailedCustLedgEntries."Debit Amount (LCY)".Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(CreditAmountVisilble, DetailedCustLedgEntries."Credit Amount".Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(CreditAmountLCYVisilble, DetailedCustLedgEntries."Credit Amount (LCY)".Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(AmountVisilble, DetailedCustLedgEntries.Amount.Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(AmountLCYVisilble, DetailedCustLedgEntries."Amount (LCY)".Visible(), WrongFieldVisibilityErr);
        DetailedCustLedgEntries.Close();
    end;

    local procedure VerifyDetailedVendorLedgEntriesPageDebitCreditAmtFieldsVisibility(DetailedVendorLedgEntries: TestPage "Detailed Vendor Ledg. Entries"; DebitAmountVisilble: Boolean; DebitAmountLCYVisilble: Boolean; CreditAmountVisilble: Boolean; CreditAmountLCYVisilble: Boolean; AmountVisilble: Boolean; AmountLCYVisilble: Boolean)
    begin
        Assert.AreEqual(DebitAmountVisilble, DetailedVendorLedgEntries."Debit Amount".Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(DebitAmountLCYVisilble, DetailedVendorLedgEntries."Debit Amount (LCY)".Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(CreditAmountVisilble, DetailedVendorLedgEntries."Credit Amount".Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(CreditAmountLCYVisilble, DetailedVendorLedgEntries."Credit Amount (LCY)".Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(AmountVisilble, DetailedVendorLedgEntries.Amount.Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(AmountLCYVisilble, DetailedVendorLedgEntries."Amount (LCY)".Visible(), WrongFieldVisibilityErr);
        DetailedVendorLedgEntries.Close();
    end;

    local procedure VerifyAppliedVendorEntriesPageDebitCreditAmtFieldsVisibility(AppliedVendorEntries: TestPage "Applied Vendor Entries"; DebitAmountVisilble: Boolean; CreditAmountVisilble: Boolean; AmountVisilble: Boolean)
    begin
        Assert.AreEqual(DebitAmountVisilble, AppliedVendorEntries."Debit Amount".Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(CreditAmountVisilble, AppliedVendorEntries."Credit Amount".Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(AmountVisilble, AppliedVendorEntries.Amount.Visible(), WrongFieldVisibilityErr);
        AppliedVendorEntries.Close();
    end;

    local procedure VerifyAppliedCustomerEntriesPageDebitCreditAmtFieldsVisibility(AppliedCustomerEntries: TestPage "Applied Customer Entries"; DebitAmountVisilble: Boolean; CreditAmountVisilble: Boolean; AmountVisilble: Boolean)
    begin
        Assert.AreEqual(DebitAmountVisilble, AppliedCustomerEntries."Debit Amount".Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(CreditAmountVisilble, AppliedCustomerEntries."Credit Amount".Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(AmountVisilble, AppliedCustomerEntries.Amount.Visible(), WrongFieldVisibilityErr);
        AppliedCustomerEntries.Close();
    end;

    local procedure VerifySalesPurchLCYAfterValidateAmount(RecurringMethod: Enum "Gen. Journal Recurring Method")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // negative: system-created entry
        ValidateAmountAndVerifySalesPurchLCYGenJournalLine(
          GenJournalLine, RecurringMethod, true, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer,
          LibrarySales.CreateCustomerNo(), GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), 1, 0);
        // negative: document type = payment
        ValidateAmountAndVerifySalesPurchLCYGenJournalLine(
          GenJournalLine, RecurringMethod, false, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer,
          LibrarySales.CreateCustomerNo(), GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), 1, 0);
        // negative: document type = refund
        ValidateAmountAndVerifySalesPurchLCYGenJournalLine(
          GenJournalLine, RecurringMethod, false, GenJournalLine."Document Type"::Refund, GenJournalLine."Account Type"::Customer,
          LibrarySales.CreateCustomerNo(), GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), 1, 0);
        // negative: account type = g/l account
        ValidateAmountAndVerifySalesPurchLCYGenJournalLine(
          GenJournalLine, RecurringMethod, false, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::"G/L Account",
          LibraryERM.CreateGLAccountNo(), GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), 1, 0);
        // positive: customer\vendor invoice\credit memo
        VerifyGenJournalLineSalesPurchLCY_CustomerInvoice(RecurringMethod, LibraryERM.CreateGLAccountNo(), 1, 1);
        VerifyGenJournalLineSalesPurchLCY_VendorInvoice(RecurringMethod, LibraryERM.CreateGLAccountNo(), 1, 1);
        VerifyGenJournalLineSalesPurchLCY_CustomerCrMemo(RecurringMethod, LibraryERM.CreateGLAccountNo(), 1, 1);
        VerifyGenJournalLineSalesPurchLCY_VendorCrMemo(RecurringMethod, LibraryERM.CreateGLAccountNo(), 1, 1);
        // positive: balance customer\vendor invoice\creit memo
        VerifyGenJournalLineSalesPurchLCY_BalCustomerInvoice(RecurringMethod, LibraryERM.CreateGLAccountNo(), 1, -1);
        VerifyGenJournalLineSalesPurchLCY_BalVendorInvoice(RecurringMethod, LibraryERM.CreateGLAccountNo(), 1, -1);
        VerifyGenJournalLineSalesPurchLCY_BalCustomerCrMemo(RecurringMethod, LibraryERM.CreateGLAccountNo(), 1, -1);
        VerifyGenJournalLineSalesPurchLCY_BalVendorCrMemo(RecurringMethod, LibraryERM.CreateGLAccountNo(), 1, -1);
        // negative: blanked account no. for balance customer\vendor invoice\credit memo
        VerifyGenJournalLineSalesPurchLCY_BalCustomerInvoice(RecurringMethod, '', 1, 0);
        VerifyGenJournalLineSalesPurchLCY_BalVendorInvoice(RecurringMethod, '', 1, 0);
        VerifyGenJournalLineSalesPurchLCY_BalCustomerCrMemo(RecurringMethod, '', 1, 0);
        VerifyGenJournalLineSalesPurchLCY_BalVendorCrMemo(RecurringMethod, '', 1, 0);
    end;

    local procedure VerifyGenJournalLineSalesPurchLCY_CustomerInvoice(RecurringMethod: Enum "Gen. Journal Recurring Method"; BalAccountNo: Code[20]; ValidateAmount: Decimal; ExpectedValue: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        ValidateAmountAndVerifySalesPurchLCYGenJournalLine(
              GenJournalLine, RecurringMethod, false, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer,
              LibrarySales.CreateCustomerNo(), GenJournalLine."Bal. Account Type"::"G/L Account", BalAccountNo, ValidateAmount, ExpectedValue);
    end;

    local procedure VerifyGenJournalLineSalesPurchLCY_CustomerCrMemo(RecurringMethod: Enum "Gen. Journal Recurring Method"; BalAccountNo: Code[20]; ValidateAmount: Decimal; ExpectedValue: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        ValidateAmountAndVerifySalesPurchLCYGenJournalLine(
              GenJournalLine, RecurringMethod, false, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Account Type"::Customer,
              LibrarySales.CreateCustomerNo(), GenJournalLine."Bal. Account Type"::"G/L Account", BalAccountNo, ValidateAmount, ExpectedValue);
    end;

    local procedure VerifyGenJournalLineSalesPurchLCY_VendorInvoice(RecurringMethod: Enum "Gen. Journal Recurring Method"; BalAccountNo: Code[20]; ValidateAmount: Decimal; ExpectedValue: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        ValidateAmountAndVerifySalesPurchLCYGenJournalLine(
              GenJournalLine, RecurringMethod, false, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor,
              LibraryPurchase.CreateVendorNo(), GenJournalLine."Bal. Account Type"::"G/L Account", BalAccountNo, ValidateAmount, ExpectedValue);
    end;

    local procedure VerifyGenJournalLineSalesPurchLCY_VendorCrMemo(RecurringMethod: Enum "Gen. Journal Recurring Method"; BalAccountNo: Code[20]; ValidateAmount: Decimal; ExpectedValue: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        ValidateAmountAndVerifySalesPurchLCYGenJournalLine(
              GenJournalLine, RecurringMethod, false, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Account Type"::Vendor,
              LibraryPurchase.CreateVendorNo(), GenJournalLine."Bal. Account Type"::"G/L Account", BalAccountNo, ValidateAmount, ExpectedValue);
    end;

    local procedure VerifyGenJournalLineSalesPurchLCY_BalCustomerInvoice(RecurringMethod: Enum "Gen. Journal Recurring Method"; AccountNo: Code[20]; ValidateAmount: Decimal; ExpectedValue: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        ValidateAmountAndVerifySalesPurchLCYGenJournalLine(
              GenJournalLine, RecurringMethod, false, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::"G/L Account", AccountNo,
              GenJournalLine."Bal. Account Type"::Customer, LibraryERM.CreateGLAccountNo(), ValidateAmount, ExpectedValue);
    end;

    local procedure VerifyGenJournalLineSalesPurchLCY_BalCustomerCrMemo(RecurringMethod: Enum "Gen. Journal Recurring Method"; AccountNo: Code[20]; ValidateAmount: Decimal; ExpectedValue: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        ValidateAmountAndVerifySalesPurchLCYGenJournalLine(
              GenJournalLine, RecurringMethod, false, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Account Type"::"G/L Account", AccountNo,
              GenJournalLine."Bal. Account Type"::Customer, LibraryERM.CreateGLAccountNo(), ValidateAmount, ExpectedValue);
    end;

    local procedure VerifyGenJournalLineSalesPurchLCY_BalVendorInvoice(RecurringMethod: Enum "Gen. Journal Recurring Method"; AccountNo: Code[20]; ValidateAmount: Decimal; ExpectedValue: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        ValidateAmountAndVerifySalesPurchLCYGenJournalLine(
              GenJournalLine, RecurringMethod, false, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::"G/L Account", AccountNo,
              GenJournalLine."Bal. Account Type"::Vendor, LibraryPurchase.CreateVendorNo(), ValidateAmount, ExpectedValue);
    end;

    local procedure VerifyGenJournalLineSalesPurchLCY_BalVendorCrMemo(RecurringMethod: Enum "Gen. Journal Recurring Method"; AccountNo: Code[20]; ValidateAmount: Decimal; ExpectedValue: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        ValidateAmountAndVerifySalesPurchLCYGenJournalLine(
              GenJournalLine, RecurringMethod, false, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Account Type"::"G/L Account", AccountNo,
              GenJournalLine."Bal. Account Type"::Vendor, LibraryPurchase.CreateVendorNo(), ValidateAmount, ExpectedValue);
    end;

    local procedure CreateGenJournalLineWithoutDocNo(
        var GenJournalLine: Record "Gen. Journal Line";
        JournalTemplateName: Code[10];
        JournalBatchName: Code[10];
        AccountType: Enum "Gen. Journal Account Type";
        AccountNo: Code[20];
        Amount: Decimal;
        PostingDate: Date)
    begin
        LibraryERM.CreateGeneralJnlLine2(GenJournalLine, JournalTemplateName, JournalBatchName, GenJournalLine."Document Type"::Payment,
            AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine."Document No." := '';
        GenJournalLine.Modify();
    end;

    [Scope('OnPrem')]
    procedure VerifyShortcutDimCodesVisibilityOnGenJournalPageInSimplePageMode(GeneralJournal: TestPage "General Journal")
    begin
        Assert.AreEqual(false, GeneralJournal."Shortcut Dimension 1 Code".Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(false, GeneralJournal."Shortcut Dimension 2 Code".Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(false, GeneralJournal.ShortcutDimCode3.Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(false, GeneralJournal.ShortcutDimCode4.Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(false, GeneralJournal.ShortcutDimCode5.Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(false, GeneralJournal.ShortcutDimCode6.Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(false, GeneralJournal.ShortcutDimCode7.Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(false, GeneralJournal.ShortcutDimCode8.Visible(), WrongFieldVisibilityErr);
    end;

    [Scope('OnPrem')]
    procedure VerifyShortcutDimCodesVisibilityOnGenJournalPage(GeneralJournal: TestPage "General Journal")
    begin
        Assert.AreEqual(true, GeneralJournal."Shortcut Dimension 1 Code".Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(true, GeneralJournal."Shortcut Dimension 2 Code".Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(true, GeneralJournal.ShortcutDimCode3.Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(true, GeneralJournal.ShortcutDimCode4.Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(true, GeneralJournal.ShortcutDimCode5.Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(true, GeneralJournal.ShortcutDimCode6.Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(true, GeneralJournal.ShortcutDimCode7.Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(true, GeneralJournal.ShortcutDimCode8.Visible(), WrongFieldVisibilityErr);
    end;

    [Scope('OnPrem')]
    procedure VerifyShortcutDimCodesVisibilityOnSalesJournalPageInSimplePageMode(SalesJournal: TestPage "Sales Journal")
    begin
        Assert.AreEqual(false, SalesJournal."Shortcut Dimension 1 Code".Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(false, SalesJournal."Shortcut Dimension 2 Code".Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(false, SalesJournal.ShortcutDimCode3.Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(false, SalesJournal.ShortcutDimCode4.Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(false, SalesJournal.ShortcutDimCode5.Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(false, SalesJournal.ShortcutDimCode6.Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(false, SalesJournal.ShortcutDimCode7.Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(false, SalesJournal.ShortcutDimCode8.Visible(), WrongFieldVisibilityErr);
    end;

    [Scope('OnPrem')]
    procedure VerifyShortcutDimCodesVisibilityOnSalesJournalPage(SalesJournal: TestPage "Sales Journal")
    begin
        Assert.AreEqual(true, SalesJournal."Shortcut Dimension 1 Code".Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(true, SalesJournal."Shortcut Dimension 2 Code".Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(true, SalesJournal.ShortcutDimCode3.Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(true, SalesJournal.ShortcutDimCode4.Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(true, SalesJournal.ShortcutDimCode5.Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(true, SalesJournal.ShortcutDimCode6.Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(true, SalesJournal.ShortcutDimCode7.Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(true, SalesJournal.ShortcutDimCode8.Visible(), WrongFieldVisibilityErr);
    end;

    [Scope('OnPrem')]
    procedure VerifyShortcutDimCodesVisibilityOnPurchaseJournalPageInSimplePageMode(PurchaseJournal: TestPage "Purchase Journal")
    begin
        Assert.AreEqual(false, PurchaseJournal."Shortcut Dimension 1 Code".Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(false, PurchaseJournal."Shortcut Dimension 2 Code".Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(false, PurchaseJournal.ShortcutDimCode3.Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(false, PurchaseJournal.ShortcutDimCode4.Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(false, PurchaseJournal.ShortcutDimCode5.Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(false, PurchaseJournal.ShortcutDimCode6.Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(false, PurchaseJournal.ShortcutDimCode7.Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(false, PurchaseJournal.ShortcutDimCode8.Visible(), WrongFieldVisibilityErr);
    end;

    [Scope('OnPrem')]
    procedure VerifyShortcutDimCodesVisibilityOnPurchaseJournalPage(PurchaseJournal: TestPage "Purchase Journal")
    begin
        Assert.AreEqual(true, PurchaseJournal."Shortcut Dimension 1 Code".Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(true, PurchaseJournal."Shortcut Dimension 2 Code".Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(true, PurchaseJournal.ShortcutDimCode3.Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(true, PurchaseJournal.ShortcutDimCode4.Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(true, PurchaseJournal.ShortcutDimCode5.Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(true, PurchaseJournal.ShortcutDimCode6.Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(true, PurchaseJournal.ShortcutDimCode7.Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(true, PurchaseJournal.ShortcutDimCode8.Visible(), WrongFieldVisibilityErr);
    end;

    [Scope('OnPrem')]
    local procedure VerifyShortcutDimCodesVisibilityOnPaymentJournalPage(PaymentJournal: TestPage "Payment Journal")
    begin
        Assert.AreEqual(true, PaymentJournal."Shortcut Dimension 1 Code".Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(true, PaymentJournal."Shortcut Dimension 2 Code".Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(true, PaymentJournal.ShortcutDimCode3.Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(true, PaymentJournal.ShortcutDimCode4.Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(true, PaymentJournal.ShortcutDimCode5.Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(true, PaymentJournal.ShortcutDimCode6.Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(true, PaymentJournal.ShortcutDimCode7.Visible(), WrongFieldVisibilityErr);
        Assert.AreEqual(true, PaymentJournal.ShortcutDimCode8.Visible(), WrongFieldVisibilityErr);
    end;

    local procedure SetShowAmounts(ShowAmounts: Option)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Show Amounts", ShowAmounts);
        GeneralLedgerSetup.Modify();
    end;

    [Scope('OnPrem')]
    procedure SetAllShortCutDimOnGLSetup()
    var
        DimensionValue: Record "Dimension Value";
        i: Integer;
    begin
        for i := 1 to 8 do begin
            LibraryDimension.CreateDimWithDimValue(DimensionValue);
            LibraryERM.SetShortcutDimensionCode(i, DimensionValue."Dimension Code");
        end;
    end;

    local procedure GetGenJnlBatchJson(NewGenJnlBatchName: Code[10]; GenJnlTemplateName: Code[10]) GenJnlBatchJson: Text
    var
        JSONManagement: Codeunit "JSON Management";
        JsonObject: DotNet JObject;
    begin
        JSONManagement.InitializeEmptyObject();
        JSONManagement.GetJSONObject(JsonObject);
        JSONManagement.AddJPropertyToJObject(JsonObject, 'Name', NewGenJnlBatchName);
        JSONManagement.AddJPropertyToJObject(JsonObject, 'Journal_Template_Name', GenJnlTemplateName);

        GenJnlBatchJson := JSONManagement.WriteObjectToString();
    end;

    local procedure CreateNoSeriesLine(var NoSeriesLine: Record "No. Series Line"; SeriesCode: Code[20]; StartDate: Date)
    begin
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, SeriesCode, LibraryUtility.GenerateGUID(), '');
        NoSeriesLine.Validate("Starting Date", StartDate);
        NoSeriesLine.Modify();
    end;

    local procedure UpdateGenJournaLine(var GenJournalLine: Record "Gen. Journal Line"; PostingDate: Date)
    begin
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesMPH(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    var
        CaptionTxt: Text;
    begin
        CaptionTxt := ApplyCustomerEntries.Caption;
        Assert.IsTrue(StrPos(CaptionTxt, LibraryVariableStorage.DequeueText()) > 0, '');
        Assert.IsTrue(StrPos(CaptionTxt, LibraryVariableStorage.DequeueText()) > 0, '');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyVendorEntriesMPH(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    var
        CaptionTxt: Text;
    begin
        CaptionTxt := ApplyVendorEntries.Caption;
        Assert.IsTrue(StrPos(CaptionTxt, LibraryVariableStorage.DequeueText()) > 0, '');
        Assert.IsTrue(StrPos(CaptionTxt, LibraryVariableStorage.DequeueText()) > 0, '');
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        LibraryVariableStorage.Enqueue(Question);
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure JournalLinesScheduledMessageHandler(Message: Text[1024])
    begin
        LibraryVariableStorageCounter.Enqueue(Message);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GenJournalModalPageHandler(var GeneralJournal: TestPage "General Journal")
    begin
        LibraryVariableStorage.Enqueue(GeneralJournal.CurrentJnlBatchName.Value);
        GeneralJournal.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure YesConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GenJournalTemplateListModalPageHandler(var GenJournalTemplateList: TestPage "General Journal Template List")
    var
        TemplateName: Text;
    begin
        // Get the template name from storage and find it
        TemplateName := LibraryVariableStorage.DequeueText();
        GenJournalTemplateList.FILTER.SetFilter(Name, TemplateName);
        GenJournalTemplateList.First();
        GenJournalTemplateList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GeneralJournalBatchesModalPageHandler(var GeneralJournalBatches: TestPage "General Journal Batches")
    var
        BatchName: Text;
    begin
        // Get the batch name from storage and find it
        BatchName := LibraryVariableStorage.DequeueText();
        GeneralJournalBatches.FILTER.SetFilter(Name, BatchName);
        GeneralJournalBatches.First();
        GeneralJournalBatches.OK().Invoke();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Mail Management", 'OnBeforeIsEnabled', '', false, false)]
    local procedure OnBeforeIsEnabled(OutlookSupported: Boolean; var Result: Boolean; var IsHandled: Boolean)
    begin
        // subscriber required to emulate new email experience and send email in background
        OutlookSupported := false;
        Result := true;
        IsHandled := true;
    end;
}

