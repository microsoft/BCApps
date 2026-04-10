codeunit 144508 "ERM Agreements"
{
    TestPermissions = NonRestrictive;
    Subtype = Test;
    Permissions = tabledata "Vendor Ledger Entry" = imd,
                  tabledata "Cust. Ledger Entry" = imd;

    trigger OnRun()
    begin
        // [FEATURE] [Agreement]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryDimension: Codeunit "Library - Dimension";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        AgreementPosting: Option "No Agreement",Mandatory;
        AppliesToDocType: Option " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder,Refund;
        IsInitialized: Boolean;
        AgrmtNoIncorrectErr: Label 'Agreement No. is incorrect';
        AgrmtMustbeMsg: Label 'Agreement must be %1 in document no. %2', Comment = '%1=Agreement No.;%2=Document No.';
        AgrmtFieldValueErr: Label 'Document field %1 value differs from the value in Agreement Card', Comment = '%1=caption of different fileds';
        AgrmtNoShouldBeEmptyMsg: Label 'Agreement No. should be empty';
        AgrmtMustExistErr: Label '%1 must exist', Comment = '%1=Customer Agreement table caption';
        RecordNotFoundErr: Label '%1 not found', Comment = '%1=table caption';
        FieldValueIncorrectErr: Label 'Field %1 value is incorrect', Comment = '%1=field caption';
        DeleteAgmtWithLEErr: Label 'You cannot delete agreement if you already have ledger entries.';
        DimValueExistsErr: Label 'Dimension Value should get deleted when %1 is deleted', Comment = '%1=table caption';
        DefaultDimNotExistErr: Label 'Default Dimension does not exist';

    [Test]
    [Scope('OnPrem')]
    procedure NoAgreementSalesOrder()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Create Customer with No Agreement - Check Agreement No. is Empty is Sales Document
        CreateCustAndSalesHeader(AgreementPosting::"No Agreement", SalesHeader, false);
        Assert.AreEqual(SalesHeader."Agreement No.", '', AgrmtNoShouldBeEmptyMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoAgreementPurchOrder()
    var
        PurchHeader: Record "Purchase Header";
    begin
        // Create Vendor with No Agreement - Check Agreement No. is Empty is Purchase Document
        CreateVendAndPurchHeader(AgreementPosting::"No Agreement", PurchHeader, false);
        Assert.AreEqual(PurchHeader."Agreement No.", '', AgrmtNoShouldBeEmptyMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MandatoryAgrmtSalesOrderNotFilled()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Create Customer with Agreement Posting = Mandatory
        // Try to post Sales Document without filled Agreement No.
        // Check error appears
        CreateCustAndSalesHeader(AgreementPosting::Mandatory, SalesHeader, true);

        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);
        Assert.ExpectedTestFieldError(SalesHeader.FieldCaption("Agreement No."), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MandatoryAgrmtPurchOrderNotFilled()
    var
        PurchHeader: Record "Purchase Header";
    begin
        // Create Vendor with Agreement Posting = Mandatory
        // Try to post Purchase Document without filled Agreement No.
        // Check error appears

        CreateVendAndPurchHeader(AgreementPosting::Mandatory, PurchHeader, true);

        asserterror LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);
        Assert.ExpectedTestFieldError(PurchHeader.FieldCaption("Agreement No."), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MandatoryAgrmtSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
        AgreementNo: Code[20];
    begin
        // Create Customer with Agreement Posting = Mandatory
        // Post Sales Document with Agreement No.
        // Check posted Sales Document for correct Agreement No.

        CreateCustAndSalesHeader(AgreementPosting::Mandatory, SalesHeader, true);
        AgreementNo := SalesDocAssignAgrmt(SalesHeader);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        VerifyPostedSalesDocAgrmt(DocumentNo, AgreementNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MandatoryAgrmtPurchOrder()
    var
        PurchHeader: Record "Purchase Header";
        DocumentNo: Code[20];
        AgreementNo: Code[20];
    begin
        // [GIVEN] Vendor with Agreement Posting = "Mandatory" and Vendor Posting Group = "X"
        CreateVendAndPurchHeader(AgreementPosting::Mandatory, PurchHeader, true);

        // [GIVEN] Vendor Agreement = "Y" with Vendor Posting Group = "Z"
        AgreementNo := PurchDocAssignAgrmt(PurchHeader);

        // [WHEN] Post Purchase Document with filled Agreement No.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // [THEN] Check posted Purchase Document for Agreement No. = "Y"
        VerifyPostedPurchDocAgrmt(DocumentNo, AgreementNo);

        // [THEN] Check Vendor Ledger Entry for Vendor Posting Group =  "Z" (TFS 380564)
        VerifyVLEVendorPostingGroup(PurchHeader."Buy-from Vendor No.", DocumentNo, AgreementNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesApplicationDiffArgmt()
    var
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
        AgreementNo: Code[20];
    begin
        // Create Customer with Agreement Posting = Mandatory
        // Post Sales Document with Agreement No.
        // Post Payment with other Agreement No. applied to Sales Document
        // Check error appears

        CreateCustAndSalesHeader(AgreementPosting::Mandatory, SalesHeader, true);
        SalesDocAssignAgrmt(SalesHeader);
        AgreementNo := CreateCustomerAgreement(SalesHeader."Sell-to Customer No.", true);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        asserterror CreateApplySalesPayment(
            DocumentNo, AgreementNo, AppliesToDocType::Invoice);
        Assert.ExpectedError(
          StrSubstNo(AgrmtMustbeMsg, AgreementNo, DocumentNo));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchApplicationDiffArgmt()
    var
        PurchHeader: Record "Purchase Header";
        DocumentNo: Code[20];
        AgreementNo: Code[20];
    begin
        // Create Vendor with Agreement Posting = Mandatory
        // Post Purchase Document with filled Agreement No.
        // Post Payment with other Agreement No. applied to Purchase Document
        // Check error appears

        CreateVendAndPurchHeader(AgreementPosting::Mandatory, PurchHeader, true);
        PurchDocAssignAgrmt(PurchHeader);
        AgreementNo := CreateVendorAgreement(PurchHeader."Buy-from Vendor No.", true);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        asserterror CreateApplyPurchPayment(
            DocumentNo, AgreementNo, AppliesToDocType::Invoice);
        Assert.ExpectedError(
          StrSubstNo(AgrmtMustbeMsg, AgreementNo, DocumentNo));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesApplicationSameArgmt()
    var
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
        AgreementNo: Code[20];
        CustomerNo: Code[20];
    begin
        // Create Customer with Agreement Posting = Mandatory
        // Post Sales Document with Agreement No.
        // Post Payment with other Agreement No. applied to Sales Document
        // Check Customer Ledger entries for correct Agreement No. value
        CreateCustAndSalesHeader(AgreementPosting::Mandatory, SalesHeader, true);
        CustomerNo := SalesHeader."Sell-to Customer No.";
        AgreementNo := SalesDocAssignAgrmt(SalesHeader);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        CreateApplySalesPayment(DocumentNo, AgreementNo, AppliesToDocType::Invoice);

        VerifyCustLedgerEntryAgrmt(CustomerNo, AgreementNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchApplicationSameArgmt()
    var
        PurchHeader: Record "Purchase Header";
        DocumentNo: Code[20];
        AgreementNo: Code[20];
        VendorNo: Code[20];
    begin
        // Create Vendor with Agreement Posting = Mandatory
        // Post Purchase Document with filled Agreement No.
        // Post Payment with the same Agreement No. applied to Purchase Document
        // Check Vendor Ledger entries for correct Agreement No. value

        CreateVendAndPurchHeader(AgreementPosting::Mandatory, PurchHeader, true);
        VendorNo := PurchHeader."Buy-from Vendor No.";
        AgreementNo := PurchDocAssignAgrmt(PurchHeader);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        CreateApplyPurchPayment(
          DocumentNo, AgreementNo, AppliesToDocType::Invoice);
        VerifyVendLedgerEntryAgrmt(VendorNo, AgreementNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustLEApplicationAgmt()
    var
        SalesHeader: Record "Sales Header";
        GenJnlLine: Record "Gen. Journal Line";
        AgreementNo: Code[20];
        CustomerNo: Code[20];
        InvoiceDocNo: Code[20];
        PaymentDocNo: Code[20];
    begin
        // Create Customer with Agreement Posting = Mandatory
        // Post Sales Document, Post Payment with Agreement No., Apply Payment to Invoice
        // Verify Customer Ledger entries are applied

        CreateCustAndSalesHeader(AgreementPosting::Mandatory, SalesHeader, true);
        CustomerNo := SalesHeader."Sell-to Customer No.";
        AgreementNo := SalesDocAssignAgrmt(SalesHeader);

        InvoiceDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        PaymentDocNo := CreatePostPayment(
            GenJnlLine."Account Type"::Customer, CustomerNo,
            GetSalesInvoiceAmount(InvoiceDocNo), AgreementNo);
        ApplyCustomerPaymentToInvoice(PaymentDocNo, InvoiceDocNo);

        VerifyClosedCustLedgerEntry(CustomerNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendLEApplicationAgmt()
    var
        PurchHeader: Record "Purchase Header";
        GenJnlLine: Record "Gen. Journal Line";
        AgreementNo: Code[20];
        VendorNo: Code[20];
        InvoiceDocNo: Code[20];
        PaymentDocNo: Code[20];
    begin
        // Create Vendor with Agreement Posting = Mandatory
        // Post Purchse Document, Post Payment with Agreement No., Apply Payment to Invoice
        // Verify Vendor Ledger entries are applied

        CreateVendAndPurchHeader(AgreementPosting::Mandatory, PurchHeader, true);
        VendorNo := PurchHeader."Buy-from Vendor No.";
        AgreementNo := PurchDocAssignAgrmt(PurchHeader);

        InvoiceDocNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);
        PaymentDocNo := CreatePostPayment(
            GenJnlLine."Account Type"::Vendor, VendorNo,
            -GetPurchInvoiceAmount(InvoiceDocNo), AgreementNo);
        ApplyVendorPaymentToInvoice(PaymentDocNo, InvoiceDocNo);

        VerifyClosedVendLedgerEntry(VendorNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustAgrmtSettingsToSalesDoc()
    var
        SalesHeader: Record "Sales Header";
        AgreementNo: Code[20];
    begin
        // Check fields values from Agreement Card are copied to Sales Document
        CreateCustAndSalesHeader(AgreementPosting::Mandatory, SalesHeader, false);
        AgreementNo := CreateCustomerAgreement(SalesHeader."Sell-to Customer No.", true);
        ExtendAssignCustAgrmt(SalesHeader, AgreementNo);
        VerifyCompareSalesDocAgrmt(SalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendAgrmtSettingsToPurchDoc()
    var
        PurchHeader: Record "Purchase Header";
        AgreementNo: Code[20];
    begin
        // Check fields values from Agreement Card are copied to Purchase Document
        CreateVendAndPurchHeader(AgreementPosting::Mandatory, PurchHeader, false);
        AgreementNo := CreateVendorAgreement(PurchHeader."Buy-from Vendor No.", true);
        ExtendAssignVendAgrmt(PurchHeader, AgreementNo);
        VerifyComparePurchDocAgrmt(PurchHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetAgreementAsMandatoryForCust()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        CustAgreement: Record "Customer Agreement";
    begin
        // Change Agreement Posting to Mandatory after posting Sales Document
        // Verify empty Customer Agreement is created
        CreateCustAndSalesHeader(AgreementPosting::"No Agreement", SalesHeader, true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        Customer.Get(SalesHeader."Sell-to Customer No.");
        Customer.Validate("Agreement Posting", Customer."Agreement Posting"::Mandatory);

        Assert.IsTrue(
          CustAgreement.Get(SalesHeader."Sell-to Customer No.", ''),
          StrSubstNo(AgrmtMustExistErr, CustAgreement.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetAgreementAsMandatoryForVend()
    var
        PurchHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        VendAgreement: Record "Vendor Agreement";
    begin
        // Change Agreement Posting to Mandatory after posting Purchase Document
        // Verify empty Vendor Agreement is created

        CreateVendAndPurchHeader(AgreementPosting::"No Agreement", PurchHeader, true);
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        Vendor.Get(PurchHeader."Buy-from Vendor No.");
        Vendor.Validate("Agreement Posting", Vendor."Agreement Posting"::Mandatory);

        Assert.IsTrue(VendAgreement.Get(PurchHeader."Buy-from Vendor No.", ''),
          StrSubstNo(AgrmtMustExistErr, VendAgreement.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorAgreementInsertDimCheck()
    var
        VendorAgreement: Record "Vendor Agreement";
    begin
        // Check appropriate Dimension Value and Default Dimension are created On Vendor Agreement Insert,
        // when Purchase & Payables Setup "Synch. Agreement Dimension" = TRUE;
        InitVendorAgreement(VendorAgreement, true);
        CheckVendorAgmtDimensions(VendorAgreement."No.", false);

        ClearPurchSalesSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerAgreementInsertDimCheck()
    var
        CustomerAgreement: Record "Customer Agreement";
    begin
        // Check appropriate Dimension Value and Default Dimension are created On Customer Agreement Insert,
        // when Sales & Receivables Setup "Synch. Agreement Dimension" = TRUE;
        InitCustomerAgreement(CustomerAgreement, true);
        CheckCustomerAgmtDimensions(CustomerAgreement."No.", false);

        ClearPurchSalesSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlockedVendorAgmtToDimension()
    var
        VendorAgreement: Record "Vendor Agreement";
    begin
        // Check DimValue Blocked value depending on Vendor Agreement Blocked state
        InitVendorAgreement(VendorAgreement, true);

        BlockVendorAgreement(VendorAgreement, true);
        CheckVendorAgmtDimensions(VendorAgreement."No.", true);
        BlockVendorAgreement(VendorAgreement, false);
        CheckVendorAgmtDimensions(VendorAgreement."No.", false);

        ClearPurchSalesSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlockedCustomerAgmtToDimension()
    var
        CustomerAgreement: Record "Customer Agreement";
    begin
        // Check DimValue Blocked value depending on Customer Agreement Blocked state
        InitCustomerAgreement(CustomerAgreement, true);

        BlockCustomerAgreement(CustomerAgreement, true);
        CheckCustomerAgmtDimensions(CustomerAgreement."No.", true);
        BlockCustomerAgreement(CustomerAgreement, false);
        CheckCustomerAgmtDimensions(CustomerAgreement."No.", false);

        ClearPurchSalesSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorAgreementDelete()
    var
        VendorAgreement: Record "Vendor Agreement";
        DimValue: Record "Dimension Value";
    begin
        // Check connected Dimension Value is deleted when Vendor Agreement is deleted
        InitVendorAgreement(VendorAgreement, true);
        VendorAgreement.Delete(true);

        Assert.IsFalse(
          DimValue.Get(GetPurchSetupAgreementDimCode(), VendorAgreement."No."),
          StrSubstNo(DimValueExistsErr, VendorAgreement.TableCaption()));

        ClearPurchSalesSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorAgreementDeleteVLEExist()
    var
        VendorAgreement: Record "Vendor Agreement";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        RecRef: RecordRef;
    begin
        // Check Vendor Agreement cannot be deleted while connected VLE exists
        InitVendorAgreement(VendorAgreement, false);
        VendorLedgerEntry.Init();
        RecRef.GetTable(VendorLedgerEntry);
        VendorLedgerEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, VendorLedgerEntry.FieldNo("Entry No."));
        VendorLedgerEntry."Vendor No." := VendorAgreement."Vendor No.";
        VendorLedgerEntry."Agreement No." := VendorAgreement."No.";
        VendorLedgerEntry.Insert();

        asserterror VendorAgreement.Delete(true);
        Assert.ExpectedError(DeleteAgmtWithLEErr);
        ClearPurchSalesSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerAgreementDelete()
    var
        CustomerAgreement: Record "Customer Agreement";
        DimValue: Record "Dimension Value";
    begin
        // Check connected Dimension Value is deleted when Vendor Agreement is deleted
        InitCustomerAgreement(CustomerAgreement, true);
        CustomerAgreement.Delete(true);

        Assert.IsFalse(
          DimValue.Get(GetSalesSetupAgreementDimCode(), CustomerAgreement."No."),
          StrSubstNo(DimValueExistsErr, CustomerAgreement.TableCaption()));

        ClearPurchSalesSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerAgreementDeleteCLEExist()
    var
        CustomerAgreement: Record "Customer Agreement";
        CustomerLedgerEntry: Record "Cust. Ledger Entry";
        RecRef: RecordRef;
    begin
        // Check Vendor Agreement cannot be deleted while connected VLE exists
        InitCustomerAgreement(CustomerAgreement, false);
        CustomerLedgerEntry.Init();
        RecRef.GetTable(CustomerLedgerEntry);
        CustomerLedgerEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, CustomerLedgerEntry.FieldNo("Entry No."));
        CustomerLedgerEntry."Customer No." := CustomerAgreement."Customer No.";
        CustomerLedgerEntry."Agreement No." := CustomerAgreement."No.";
        CustomerLedgerEntry.Insert();

        asserterror CustomerAgreement.Delete(true);
        Assert.ExpectedError(DeleteAgmtWithLEErr);
        ClearPurchSalesSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorAgreementTransferDim()
    var
        VendorAgreement: Record "Vendor Agreement";
        Vendor: Record Vendor;
        GLSetup: Record "General Ledger Setup";
        DimValueCode1: Code[20];
        DimValueCode2: Code[20];
    begin
        // Check Vendor Default Dimensions are copied to new Agreement
        Initialize();
        GLSetup.Get();
        CreateGlobalDimensionValues(DimValueCode1, DimValueCode2);
        Vendor.Get(CreateVendor(AgreementPosting::Mandatory));
        Vendor.Validate("Global Dimension 1 Code", DimValueCode1);
        Vendor.Validate("Global Dimension 2 Code", DimValueCode2);
        Vendor.Modify();
        CreateSimpleVendorAgreement(VendorAgreement, Vendor."No.");

        CheckDefaultDimExists(
          DATABASE::"Vendor Agreement", VendorAgreement."No.", GLSetup."Global Dimension 1 Code");
        CheckDefaultDimExists(
          DATABASE::"Vendor Agreement", VendorAgreement."No.", GLSetup."Global Dimension 2 Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerAgreementTransferDim()
    var
        CustomerAgreement: Record "Customer Agreement";
        Customer: Record Customer;
        GLSetup: Record "General Ledger Setup";
        DimValueCode1: Code[20];
        DimValueCode2: Code[20];
    begin
        // Check Customer Default Dimensions are copied to new Agreement
        Initialize();
        GLSetup.Get();
        CreateGlobalDimensionValues(DimValueCode1, DimValueCode2);
        Customer.Get(CreateCustomer(AgreementPosting::Mandatory));
        Customer.Validate("Global Dimension 1 Code", DimValueCode1);
        Customer.Validate("Global Dimension 2 Code", DimValueCode2);
        Customer.Modify();
        CreateSimpleCustomerAgreement(CustomerAgreement, Customer."No.");

        CheckDefaultDimExists(
          DATABASE::"Customer Agreement", CustomerAgreement."No.", GLSetup."Global Dimension 1 Code");
        CheckDefaultDimExists(
          DATABASE::"Customer Agreement", CustomerAgreement."No.", GLSetup."Global Dimension 2 Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorAgreementValidateNo()
    var
        VendorAgreement: Record "Vendor Agreement";
    begin
        // Check Vendor Agreement "No." field OnValidate trigger
        VendorAgreement.Init();
        VendorAgreement."Vendor No." := CreateVendor(AgreementPosting::Mandatory);
        VendorAgreement.Insert(true);
        VendorAgreement.Validate("No.", LibraryUtility.GenerateGUID());
        Assert.IsTrue(VendorAgreement."No. Series" = '', StrSubstNo(FieldValueIncorrectErr, VendorAgreement.FieldCaption("No. Series")));
        VendorAgreement."Vendor No." := '';
        asserterror VendorAgreement.Validate("No.", LibraryUtility.GenerateGUID());
        Assert.ExpectedErrorCannotFind(Database::Vendor, VendorAgreement."Vendor No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerAgreementValidateNo()
    var
        CustomerAgreement: Record "Customer Agreement";
    begin
        // Check Customer Agreement "No." field OnValidate trigger
        CustomerAgreement.Init();
        CustomerAgreement."Customer No." := CreateCustomer(AgreementPosting::Mandatory);
        CustomerAgreement.Insert(true);
        CustomerAgreement.Validate("No.", LibraryUtility.GenerateGUID());
        Assert.IsTrue(CustomerAgreement."No. Series" = '', StrSubstNo(FieldValueIncorrectErr, CustomerAgreement.FieldCaption("No. Series")));
        CustomerAgreement."Customer No." := '';
        asserterror CustomerAgreement.Validate("No.", LibraryUtility.GenerateGUID());
        Assert.ExpectedErrorCannotFind(Database::Customer, CustomerAgreement."Customer No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PurchaseDocAgreementGlobalDim()
    var
        PurchaseHeader: Record "Purchase Header";
        DimValue1Code: Code[20];
        DimValue2Code: Code[20];
        VendorNo: Code[20];
        VendorAgreementNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Dimensions]
        // [SCENARIO 379392] Purchase document shortcut dimensions match to global dimension fields of vendor agreement
        Initialize();

        // [GIVEN] Active vendor agreement with global dimensions
        VendorNo := CreateVendor(AgreementPosting::Mandatory);
        VendorAgreementNo := CreateVendorAgreement(VendorNo, true);
        CreateGlobalDimensionValues(DimValue1Code, DimValue2Code);
        SetVendorAgreementGlobalDimensions(VendorNo, VendorAgreementNo, DimValue1Code, DimValue2Code);
        // [GIVEN] Purchase document for created vendor
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);

        // [WHEN] Agreement Number is being assigned to purchase document
        PurchaseHeader.Validate("Agreement No.", VendorAgreementNo);

        // [THEN] Document shortcut dimensions match to global dimension fields of vendor agreement
        PurchaseHeader.TestField("Shortcut Dimension 1 Code", DimValue1Code);
        PurchaseHeader.TestField("Shortcut Dimension 2 Code", DimValue2Code);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure SalesDocAgreementGlobalDim()
    var
        SalesHeader: Record "Sales Header";
        DimValue1Code: Code[20];
        DimValue2Code: Code[20];
        CustomerNo: Code[20];
        CustomerAgreementNo: Code[20];
    begin
        // [FEATURE] [Sales] [Dimensions]
        // [SCENARIO 379392] Sales document shortcut dimensions match to global dimension fields of customer agreement
        Initialize();

        // [GIVEN] Active customer agreement with global dimensions
        CustomerNo := CreateCustomer(AgreementPosting::Mandatory);
        CustomerAgreementNo := CreateCustomerAgreement(CustomerNo, true);
        CreateGlobalDimensionValues(DimValue1Code, DimValue2Code);
        SetCustomerAgreementGlobalDimensions(CustomerNo, CustomerAgreementNo, DimValue1Code, DimValue2Code);
        // [GIVEN] Sales document for created customer
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);

        // [WHEN] Agreement Number is being assigned to purchase document
        SalesHeader.Validate("Agreement No.", CustomerAgreementNo);

        // [THEN] Document shortcut dimensions match to global dimension fields of customer agreement
        SalesHeader.TestField("Shortcut Dimension 1 Code", DimValue1Code);
        SalesHeader.TestField("Shortcut Dimension 2 Code", DimValue2Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ConsecutiveFillingOfAgreementNoFieldForANewGenJournalLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustomerNo: Code[20];
        AgreementNo: Code[20];
    begin
        // [FEATURE] [UT] [Customer]
        // [SCENARIO 205759] System allows consecutive filling of "Agreement No." field for a new general journal line
        Initialize();

        // [GIVEN] Customer "C" with active agreement "A" having "Agreement Posting" = "Mandatory"
        CustomerNo := CreateCustomer(AgreementPosting::Mandatory);
        AgreementNo := CreateCustomerAgreement(CustomerNo, true);

        // [GIVEN] A new general journal line:
        // [GIVEN] Validate "Document Type" = "Payment"
        // [GIVEN] Validate "Account Type" = "Customer"
        // [GIVEN] Validate "Account No." = "C"
        GenJournalLine.Init();
        GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::Payment);
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::Customer);
        GenJournalLine.Validate("Account No.", CustomerNo);

        // [WHEN] Validate "Agreement No." = "A"
        GenJournalLine.Validate("Agreement No.", AgreementNo);

        // [THEN] Journal line's "Agreement No." field has been validated with value "A"
        Assert.AreEqual(AgreementNo, GenJournalLine."Agreement No.", GenJournalLine.FieldCaption("Agreement No."));
    end;

    [Test]
    [HandlerFunctions('UnapplyCustomerEntriesModalPageHandler,ApplyCustomerEntriesPageHandler,PostApplicationPageHandler,ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure GLEntriesSalesApplyUnapply()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GLEntry: Record "G/L Entry";
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
        InvoiceNo: Code[20];
        PaymentNo: Code[20];
        AgreementNo: Code[20];
    begin
        // [FEATURE] [Sales] [Customer Ledger Entry] [Apply] [Unapply] [Prepayment]
        // [SCENARIO 307988] G/L Entries created on Apply and Unapply of Customer Ledger Entries for prepayment have correct agreement
        Initialize();

        // [GIVEN] Customer with Agreement Posting = Mandatory and Agreement No. "AG01"
        // [GIVEN] Released Sales Order "USO01" with Agreement No. "AG01"
        CreateCustAndSalesHeader(AgreementPosting::Mandatory, SalesHeader, true);
        AgreementNo := SalesDocAssignAgrmt(SalesHeader);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Posted Prepayment "PAY01" with Agreement No. "AG01" for "USO01"
        PaymentNo := CreateSalesPrepayment(AgreementNo, SalesHeader."Document Type", SalesHeader."No.");

        // [GIVEN] Posted Sales Invoice "PSI01" from "USO01"
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Prepayment "PAY01" applied to "PSI01"
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, PaymentNo);
        CustEntryApplyPostedEntries.ApplyCustEntryFormEntry(CustLedgerEntry);

        // [WHEN] Unapply Customer Ledger entries
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, PaymentNo);
        CustEntryApplyPostedEntries.UnApplyCustLedgEntry(CustLedgerEntry."Entry No.");

        // [THEN] All G/L Entries for Invoice "PSI01" have correct agreement
        VerifyGLEntryAgrmt(GLEntry."Document Type"::Invoice, InvoiceNo, AgreementNo);

        // [THEN] All G/L Entries for Prepayment "PAY01" have correct agreement
        VerifyGLEntryAgrmt(GLEntry."Document Type"::Payment, PaymentNo, AgreementNo);
    end;

    [Test]
    [HandlerFunctions('UnapplyVendorEntriesPageHandler,ApplyVendorEntriesPageHandler,PostApplicationPageHandler,ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure GLEntriesPurchaseApplyUnapply()
    var
        PurchHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GLEntry: Record "G/L Entry";
        VendEntryApplyPostedEntries: Codeunit "VendEntry-Apply Posted Entries";
        InvoiceNo: Code[20];
        PaymentNo: Code[20];
        AgreementNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Vendor Ledger Entry] [Apply] [Unapply] [Prepayment]
        // [SCENARIO 307988] G/L Entries created on Apply and Unapply of Vendor Ledger Entries for prepayment have correct agreement
        Initialize();

        // [GIVEN] Vendor with Agreement Posting = Mandatory and Agreement No. "AG01"
        // [GIVEN] Released Purchase Order "UPO01" with Agreement No. "AG01"
        CreateVendAndPurchHeader(AgreementPosting::Mandatory, PurchHeader, true);
        AgreementNo := PurchDocAssignAgrmt(PurchHeader);
        LibraryPurchase.ReleasePurchaseDocument(PurchHeader);

        // [GIVEN] Posted Prepayment "PAY01" with Agreement No. "AG01" for "UPO01"
        PaymentNo := CreatePurchPrepayment(AgreementNo, PurchHeader."Document Type", PurchHeader."No.");

        // [GIVEN] Posted Purchase Invoice "PPI01" from "UPO01"
        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // [GIVEN] Prepayment "PAY01" applied to "PPI01"
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Payment, PaymentNo);
        VendEntryApplyPostedEntries.ApplyVendEntryFormEntry(VendorLedgerEntry);

        // [WHEN] Unapply Vendor Ledger entries
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Payment, PaymentNo);
        VendEntryApplyPostedEntries.UnApplyVendLedgEntry(VendorLedgerEntry."Entry No.");

        // [THEN] All G/L Entries for Invoice "PPI01" have correct agreement
        VerifyGLEntryAgrmt(GLEntry."Document Type"::Invoice, InvoiceNo, AgreementNo);

        // [THEN] All G/L Entries for Prepayment "PAY01" have correct agreement
        VerifyGLEntryAgrmt(GLEntry."Document Type"::Payment, PaymentNo, AgreementNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerAgreementInvalidExpireDateError()
    var
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
        CustomerAgreementNo: Code[20];
    begin
        // [FEATURE] [Customer] [Sales]
        // [SCENARIO 356754] Validating "Agreement No." for Sales Document with empty "Expire Date" on Customer Agreement less than "Posting Date" throws error
        Initialize();

        // [GIVEN] Created Customer and Customer Agreement with "Expire Date" = 01.01.2020
        CustomerNo := CreateCustomer(AgreementPosting::Mandatory);
        CustomerAgreementNo := CreateCustomerAgreement(CustomerNo, true);
        SetCustomerAgreementExpireDate(CustomerNo, CustomerAgreementNo, WorkDate());

        // [GIVEN] Created Sales Document with "Posting Date" = 01.02.2020
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesHeader.Validate("Posting Date", CalcDate('<1M>', WorkDate()));
        SalesHeader.Modify(true);

        // [WHEN] Agreement Number is being assigned to Sales Document
        asserterror SalesHeader.Validate("Agreement No.", CustomerAgreementNo);

        // [THEN] An error is thrown 'Agreement Expire Date should be no earlier than Posting Date.'
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError('Agreement Expire Date should be no earlier than Posting Date.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure CustomerAgreementEmptyExpireDate()
    var
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
        CustomerAgreementNo: Code[20];
    begin
        // [FEATURE] [Customer] [Sales]
        // [SCENARIO 356754] Validating "Agreement No." for Sales Document with empty "Expire Date" on Customer Agreement doesn't throw error
        Initialize();

        // [GIVEN] Created Customer and Customer Agreement with empty "Expire Date"
        CustomerNo := CreateCustomer(AgreementPosting::Mandatory);
        CustomerAgreementNo := CreateCustomerAgreement(CustomerNo, true);
        SetCustomerAgreementExpireDate(CustomerNo, CustomerAgreementNo, 0D);

        // [GIVEN] Created Sales Document
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);

        // [WHEN] Agreement Number is being assigned to Sales Document
        SalesHeader.Validate("Agreement No.", CustomerAgreementNo);

        // [THEN] No errors thrown, Agreement Number assigned
        SalesHeader.TestField("Agreement No.", CustomerAgreementNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorAgreementInvalidExpireDateError()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
        VendorAgreementNo: Code[20];
    begin
        // [FEATURE] [Vendor] [Purchase]
        // [SCENARIO 356754] Validating "Agreement No." for Purchase Document with empty "Expire Date" on Vendor Agreement less than "Posting Date" throws error
        Initialize();

        // [GIVEN] Created Vendor and Vendor Agreement with "Expire Date" = 01.01.2020
        VendorNo := CreateVendor(AgreementPosting::Mandatory);
        VendorAgreementNo := CreateVendorAgreement(VendorNo, true);
        SetVendorAgreementExpireDate(VendorNo, VendorAgreementNo, WorkDate());

        // [GIVEN] Created Purchase Document with "Posting Date" = 01.02.2020
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        PurchaseHeader.Validate("Posting Date", CalcDate('<1M>', WorkDate()));
        PurchaseHeader.Modify(true);

        // [WHEN] Agreement Number is being assigned to Purchase Document
        asserterror PurchaseHeader.Validate("Agreement No.", VendorAgreementNo);

        // [THEN] An error is thrown 'Agreement Expire Date should be no earlier than Posting Date.'
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError('Agreement Expire Date should be no earlier than Posting Date.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure VendorAgreementEmptyExpireDate()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
        VendorAgreementNo: Code[20];
    begin
        // [FEATURE] [Vendor] [Purchase]
        // [SCENARIO 356754] Validating "Agreement No." for Purchase Document with empty "Expire Date" on Vendor Agreement doesn't throw error
        Initialize();

        // [GIVEN] Created Vendor and Vendor Agreement with empty "Expire Date"
        VendorNo := CreateVendor(AgreementPosting::Mandatory);
        VendorAgreementNo := CreateVendorAgreement(VendorNo, true);
        SetVendorAgreementExpireDate(VendorNo, VendorAgreementNo, 0D);

        // [GIVEN] Created Purchase Document
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);

        // [WHEN] Agreement Number is being assigned to Purchase Document
        PurchaseHeader.Validate("Agreement No.", VendorAgreementNo);

        // [THEN] No errors thrown, Agreement Number assigned
        PurchaseHeader.TestField("Agreement No.", VendorAgreementNo);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        if IsInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralPostingSetup();

        IsInitialized := true;
    end;

    local procedure CreateCustomer(AgreementPosting: Option): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Agreement Posting", AgreementPosting);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustAndSalesHeader(AgreementPosting: Option; var SalesHeader: Record "Sales Header"; AddLine: Boolean)
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
        CustomerNo: Code[20];
    begin
        Initialize();
        CustomerNo := CreateCustomer(AgreementPosting);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        if AddLine then begin
            LibrarySales.CreateSalesLine(
              SalesLine, SalesHeader, SalesLine.Type::Item,
              LibraryInventory.CreateItem(Item), LibraryRandom.RandInt(10));
            SalesLine.Validate("Unit Price", LibraryRandom.RandDec(1000, 2));
            SalesLine.Modify(true);
        end;
    end;

    local procedure CreateVendor(AgreementPosting: Option): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Agreement Posting", AgreementPosting);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateVendAndPurchHeader(AgreementPosting: Option; var PurchHeader: Record "Purchase Header"; AddLine: Boolean)
    var
        PurchLine: Record "Purchase Line";
        Item: Record Item;
        VendorNo: Code[20];
    begin
        Initialize();
        VendorNo := CreateVendor(AgreementPosting);
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, VendorNo);
        if AddLine then begin
            LibraryPurchase.CreatePurchaseLine(
              PurchLine, PurchHeader, PurchLine.Type::Item,
              LibraryInventory.CreateItem(Item), LibraryRandom.RandInt(10));
            PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(1000, 2));
            PurchLine.Modify(true);
        end;
    end;

    local procedure CreateCustomerAgreement(CustomerNo: Code[20]; IsActive: Boolean): Code[20]
    var
        CustomerAgreement: Record "Customer Agreement";
    begin
        CustomerAgreement.Init();
        CustomerAgreement."Customer No." := CustomerNo;
        CustomerAgreement.Active := IsActive;
        CustomerAgreement."Expire Date" := CalcDate('<1M>', WorkDate());
        CustomerAgreement.Insert(true);
        exit(CustomerAgreement."No.");
    end;

    local procedure CreateVendorAgreement(VendorNo: Code[20]; IsActive: Boolean): Code[20]
    var
        VendorAgreement: Record "Vendor Agreement";
    begin
        VendorAgreement.Init();
        VendorAgreement."Vendor No." := VendorNo;
        VendorAgreement.Active := IsActive;
        VendorAgreement."Expire Date" := CalcDate('<1M>', WorkDate());
        VendorAgreement.Insert(true);
        exit(VendorAgreement."No.");
    end;

    local procedure ApplyCustomerPaymentToInvoice(PaymentDocNo: Code[20]; InvoiceDocNo: Code[20])
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.ApplyCustomerLedgerEntry(
          CustLedgEntry."Document Type"::Payment, PaymentDocNo,
          CustLedgEntry."Document Type"::Invoice, InvoiceDocNo);
    end;

    local procedure ApplyVendorPaymentToInvoice(PaymentDocNo: Code[20]; InvoiceDocNo: Code[20])
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.ApplyVendorLedgerEntry(
          VendLedgEntry."Document Type"::Payment, PaymentDocNo,
          VendLedgEntry."Document Type"::Invoice, InvoiceDocNo);
    end;

    local procedure GetSalesInvoiceAmount(SalesInvoiceDocNo: Code[20]): Decimal
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Get(SalesInvoiceDocNo);
        SalesInvoiceHeader.CalcFields("Amount Including VAT");
        exit(SalesInvoiceHeader."Amount Including VAT");
    end;

    local procedure GetPurchInvoiceAmount(PurchInvoiceDocNo: Code[20]): Decimal
    var
        PurchInvoiceHeader: Record "Purch. Inv. Header";
    begin
        PurchInvoiceHeader.Get(PurchInvoiceDocNo);
        PurchInvoiceHeader.CalcFields("Amount Including VAT");
        exit(PurchInvoiceHeader."Amount Including VAT");
    end;

    local procedure SalesDocAssignAgrmt(var SalesHeader: Record "Sales Header") AgreementNo: Code[20]
    begin
        AgreementNo := CreateCustomerAgreement(SalesHeader."Sell-to Customer No.", true);
        SalesHeader.Validate("Agreement No.", AgreementNo);
        SalesHeader.Modify(true);
    end;

    local procedure PurchDocAssignAgrmt(var PurchHeader: Record "Purchase Header") AgreementNo: Code[20]
    begin
        AgreementNo := CreateVendorAgreement(PurchHeader."Buy-from Vendor No.", true);
        PurchHeader.Validate("Agreement No.", AgreementNo);
        PurchHeader.Modify(true);
    end;

    local procedure VerifyPostedSalesDocAgrmt(SalesDocNo: Code[20]; AgreementNo: Code[20])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.SetRange("No.", SalesDocNo);
        SalesInvoiceHeader.FindFirst();
        Assert.AreEqual(AgreementNo, SalesInvoiceHeader."Agreement No.", AgrmtNoIncorrectErr);
    end;

    local procedure VerifyPostedPurchDocAgrmt(PurchDocNo: Code[20]; AgreementNo: Code[20])
    var
        PurchInvoiceHeader: Record "Purch. Inv. Header";
    begin
        PurchInvoiceHeader.SetRange("No.", PurchDocNo);
        PurchInvoiceHeader.FindFirst();
        Assert.AreEqual(AgreementNo, PurchInvoiceHeader."Agreement No.", AgrmtNoIncorrectErr);
    end;

    local procedure VerifyVLEVendorPostingGroup(VendorNo: Code[20]; PurchDocNo: Code[20]; AgreementNo: Code[20])
    var
        VendorAgreement: Record "Vendor Agreement";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange("Document No.", PurchDocNo);
        VendorLedgerEntry.FindFirst();
        VendorAgreement.Get(VendorLedgerEntry."Buy-from Vendor No.", AgreementNo);
        VendorLedgerEntry.TestField("Vendor Posting Group", VendorAgreement."Vendor Posting Group");
    end;

    local procedure CreatePostPayment(AccountType: Enum "Gen. Journal Account Type"; CVNo: Code[20]; AmountValue: Decimal; AgreementNo: Code[20]): Code[20]
    begin
        exit(CreateApplyPayment(AccountType, CVNo, AmountValue, 0, '', AgreementNo));
    end;

    local procedure CreateApplyPayment(AccountType: Enum "Gen. Journal Account Type"; CVNo: Code[20]; AmountValue: Decimal; AppliedDocType: Option; AppliedDocNo: Code[20]; AgreementNo: Code[20]): Code[20]
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.FindGenJournalTemplate(GenJnlTemplate);
        LibraryERM.FindGenJournalBatch(GenJnlBatch, GenJnlTemplate.Name);
        LibraryERM.CreateBankAccount(BankAccount);
        GenJnlLine.DeleteAll();
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJnlLine, GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Payment,
          AccountType, CVNo, GenJnlLine."Bal. Account Type"::"Bank Account", BankAccount."No.", -AmountValue);
        GenJnlLine.Validate("Applies-to Doc. Type", AppliedDocType);
        GenJnlLine.Validate("Applies-to Doc. No.", AppliedDocNo);
        GenJnlLine.Validate("Agreement No.", AgreementNo);
        GenJnlLine.Modify(true);

        LibraryERM.PostGeneralJnlLine(GenJnlLine);
        exit(GenJnlLine."Document No.")
    end;

    local procedure CreatePostPrepayment(AccountType: Enum "Gen. Journal Account Type"; CVNo: Code[20]; AmountValue: Decimal; AgreementNo: Code[20]; PrepaymentDocNo: Code[20]): Code[20]
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.FindGenJournalTemplate(GenJnlTemplate);
        LibraryERM.FindGenJournalBatch(GenJnlBatch, GenJnlTemplate.Name);
        LibraryERM.CreateBankAccount(BankAccount);
        GenJnlLine.DeleteAll();
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJnlLine, GenJnlBatch."Journal Template Name", GenJnlBatch.Name, GenJnlLine."Document Type"::Payment,
          AccountType, CVNo, GenJnlLine."Bal. Account Type"::"Bank Account", BankAccount."No.", -AmountValue);
        GenJnlLine.Validate("Agreement No.", AgreementNo);
        GenJnlLine.Validate(Prepayment, true);
        GenJnlLine.Validate("External Document No.", LibraryUtility.GenerateGUID());
        GenJnlLine.Validate("Prepayment Document No.", PrepaymentDocNo);
        GenJnlLine.Modify(true);

        LibraryERM.PostGeneralJnlLine(GenJnlLine);
        exit(GenJnlLine."Document No.");
    end;

    local procedure CreateApplySalesPayment(DocumentNo: Code[20]; AgreementNo: Code[20]; AppliedDocType: Option)
    var
        GenJnlLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.CalcFields(Amount);
        CreateApplyPayment(
          GenJnlLine."Account Type"::Customer, CustLedgerEntry."Customer No.",
          CustLedgerEntry.Amount, AppliedDocType, DocumentNo, AgreementNo);
    end;

    local procedure CreateSalesPrepayment(AgreementNo: Code[20]; DocumentType: Enum "Sales Document Type"; PrepmtDocNo: Code[20]): Code[20]
    var
        GenJnlLine: Record "Gen. Journal Line";
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Document No.", PrepmtDocNo);
        SalesLine.FindFirst();
        exit(
          CreatePostPrepayment(
            GenJnlLine."Account Type"::Customer, SalesLine."Sell-to Customer No.",
            SalesLine.Amount, AgreementNo, PrepmtDocNo));
    end;

    local procedure CreateApplyPurchPayment(DocumentNo: Code[20]; AgreementNo: Code[20]; AppliedDocType: Option)
    var
        GenJnlLine: Record "Gen. Journal Line";
        VendLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendLedgerEntry.SetRange("Document No.", DocumentNo);
        VendLedgerEntry.FindFirst();
        VendLedgerEntry.CalcFields(Amount);
        CreateApplyPayment(
          GenJnlLine."Account Type"::Vendor, VendLedgerEntry."Vendor No.",
          VendLedgerEntry.Amount, AppliedDocType, DocumentNo, AgreementNo);
    end;

    local procedure CreatePurchPrepayment(AgreementNo: Code[20]; DocumentType: Enum "Purchase Document Type"; PrepmtDocNo: Code[20]): Code[20]
    var
        GenJnlLine: Record "Gen. Journal Line";
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", DocumentType);
        PurchaseLine.SetRange("Document No.", PrepmtDocNo);
        PurchaseLine.FindFirst();
        exit(
          CreatePostPrepayment(
            GenJnlLine."Account Type"::Vendor, PurchaseLine."Buy-from Vendor No.",
            -PurchaseLine.Amount, AgreementNo, PrepmtDocNo));
    end;

    local procedure ExtendAssignCustAgrmt(var SalesHeader: Record "Sales Header"; AgreementNo: Code[20])
    var
        CustomerAgreement: Record "Customer Agreement";
        Language: Record Language;
        Currency: Record Currency;
        SalesPerson: Record "Salesperson/Purchaser";
        PaymentTerms: Record "Payment Terms";
        PaymentMethod: Record "Payment Method";
        CustomerPostingGroup: Record "Customer Posting Group";
        CustomerPriceGroup: Record "Customer Price Group";
        CustomerDiscGroup: Record "Customer Discount Group";
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        VATBusPostingGroup: Record "VAT Business Posting Group";
        Location: Record Location;
        ShipToAddress: Record "Ship-to Address";
        ResponsibilityCenter: Record "Responsibility Center";
        ShippingAgent: Record "Shipping Agent";
        ShippingAgentService: Record "Shipping Agent Services";
        ShipmentMethodCode: Record "Shipment Method";
        DateFormula: DateFormula;
    begin
        CustomerAgreement.Get(SalesHeader."Sell-to Customer No.", AgreementNo);
        Language.FindFirst();
        CustomerAgreement.Validate("Language Code", Language.Code);
        Currency.FindFirst();
        CustomerAgreement.Validate("Currency Code", Currency.Code);
        SalesPerson.FindFirst();
        CustomerAgreement.Validate("Payment Terms Code", PaymentTerms.Code);
        PaymentMethod.FindFirst();
        CustomerAgreement.Validate("Payment Method Code", PaymentMethod.Code);
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);
        CustomerAgreement.Validate("Customer Price Group", CustomerPriceGroup.Code);
        CustomerPostingGroup.FindFirst();
        CustomerAgreement.Validate("Customer Posting Group", CustomerPostingGroup.Code);
        CustomerDiscGroup.FindFirst();
        CustomerAgreement.Validate("Customer Disc. Group", CustomerDiscGroup.Code);
        LibraryERM.CreateGenBusPostingGroup(GenBusinessPostingGroup);
        CustomerAgreement.Validate("Gen. Bus. Posting Group", GenBusinessPostingGroup.Code);
        LibraryERM.CreateVATBusinessPostingGroup(VATBusPostingGroup);
        CustomerAgreement.Validate("VAT Bus. Posting Group", VATBusPostingGroup.Code);
        Location.FindFirst();
        CustomerAgreement.Validate("Location Code", Location.Code);
        LibrarySales.CreateShipToAddress(ShipToAddress, SalesHeader."Sell-to Customer No.");
        CustomerAgreement.Validate("Ship-to Code", ShipToAddress.Code);
        ResponsibilityCenter.FindFirst();
        CustomerAgreement.Validate("Responsibility Center", ResponsibilityCenter.Code);
        ShippingAgent.FindFirst();
        CustomerAgreement.Validate("Shipping Agent Code", ShippingAgent.Code);
        Evaluate(DateFormula, '<1D>');
        CustomerAgreement.Validate("Shipping Time", DateFormula);
        ShippingAgentService.SetRange("Shipping Agent Code", ShippingAgent.Code);
        ShippingAgentService.FindFirst();
        CustomerAgreement.Validate("Shipping Agent Service Code", ShippingAgentService.Code);
        CustomerAgreement.Validate("Shipping Advice", CustomerAgreement."Shipping Advice"::Complete);
        ShipmentMethodCode.FindFirst();
        CustomerAgreement.Validate("Shipment Method Code", ShipmentMethodCode.Code);
        CustomerAgreement.Modify(true);
        SalesHeader.Validate("Agreement No.", AgreementNo);
        SalesHeader.Modify(true);
    end;

    local procedure ExtendAssignVendAgrmt(var PurchHeader: Record "Purchase Header"; AgreementNo: Code[20])
    var
        VendorAgreement: Record "Vendor Agreement";
        Language: Record Language;
        Currency: Record Currency;
        SalesPerson: Record "Salesperson/Purchaser";
        PaymentTerms: Record "Payment Terms";
        PaymentMethod: Record "Payment Method";
        VendorPostingGroup: Record "Vendor Posting Group";
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        VATBusPostingGroup: Record "VAT Business Posting Group";
        Location: Record Location;
        ResponsibilityCenter: Record "Responsibility Center";
    begin
        VendorAgreement.Get(PurchHeader."Buy-from Vendor No.", AgreementNo);
        Language.FindFirst();
        VendorAgreement.Validate("Language Code", Language.Code);
        Currency.FindFirst();
        VendorAgreement.Validate("Currency Code", Currency.Code);
        SalesPerson.FindFirst();
        VendorAgreement.Validate("Purchaser Code", SalesPerson.Code);
        PaymentTerms.FindFirst();
        VendorAgreement.Validate("Payment Terms Code", PaymentTerms.Code);
        PaymentMethod.FindFirst();
        VendorAgreement.Validate("Payment Method Code", PaymentMethod.Code);
        VendorPostingGroup.FindFirst();
        VendorAgreement.Validate("Vendor Posting Group", VendorPostingGroup.Code);
        LibraryERM.CreateGenBusPostingGroup(GenBusinessPostingGroup);
        VendorAgreement.Validate("Gen. Bus. Posting Group", GenBusinessPostingGroup.Code);
        LibraryERM.CreateVATBusinessPostingGroup(VATBusPostingGroup);
        VendorAgreement.Validate("VAT Bus. Posting Group", VATBusPostingGroup.Code);
        Location.FindFirst();
        VendorAgreement.Validate("Location Code", Location.Code);
        ResponsibilityCenter.FindFirst();
        VendorAgreement.Validate("Responsibility Center", ResponsibilityCenter.Code);
        VendorAgreement.Modify(true);
        PurchHeader.Validate("Agreement No.", AgreementNo);
        PurchHeader.Modify(true);
    end;

    local procedure VerifyCompareSalesDocAgrmt(SalesHeader: Record "Sales Header")
    var
        CustomerAgreement: Record "Customer Agreement";
    begin
        CustomerAgreement.Get(SalesHeader."Sell-to Customer No.", SalesHeader."Agreement No.");
        Assert.AreEqual(
          SalesHeader."Language Code", CustomerAgreement."Language Code",
          StrSubstNo(AgrmtFieldValueErr, SalesHeader.FieldCaption("Language Code")));
        Assert.AreEqual(
          SalesHeader."Currency Code", CustomerAgreement."Currency Code",
          StrSubstNo(AgrmtFieldValueErr, SalesHeader.FieldCaption("Currency Code")));
        Assert.AreEqual(
          SalesHeader."Payment Terms Code", CustomerAgreement."Payment Terms Code",
          StrSubstNo(AgrmtFieldValueErr, SalesHeader.FieldCaption("Payment Terms Code")));
        Assert.AreEqual(
          SalesHeader."Payment Method Code", CustomerAgreement."Payment Method Code",
          StrSubstNo(AgrmtFieldValueErr, SalesHeader.FieldCaption("Payment Method Code")));
        Assert.AreEqual(
          SalesHeader."Customer Price Group", CustomerAgreement."Customer Price Group",
          StrSubstNo(AgrmtFieldValueErr, SalesHeader.FieldCaption("Customer Price Group")));
        Assert.AreEqual(
          SalesHeader."Customer Posting Group", CustomerAgreement."Customer Posting Group",
          StrSubstNo(AgrmtFieldValueErr, SalesHeader.FieldCaption("Customer Posting Group")));
        Assert.AreEqual(
          SalesHeader."Customer Disc. Group", CustomerAgreement."Customer Disc. Group",
          StrSubstNo(AgrmtFieldValueErr, SalesHeader.FieldCaption("Customer Disc. Group")));
        Assert.AreEqual(
          SalesHeader."Gen. Bus. Posting Group", CustomerAgreement."Gen. Bus. Posting Group",
          StrSubstNo(AgrmtFieldValueErr, SalesHeader.FieldCaption("Gen. Bus. Posting Group")));
        Assert.AreEqual(
          SalesHeader."VAT Bus. Posting Group", CustomerAgreement."VAT Bus. Posting Group",
          StrSubstNo(AgrmtFieldValueErr, SalesHeader.FieldCaption("VAT Bus. Posting Group")));
        Assert.AreEqual(
          SalesHeader."Location Code", CustomerAgreement."Location Code",
          StrSubstNo(AgrmtFieldValueErr, SalesHeader.FieldCaption("Location Code")));
        Assert.AreEqual(
          SalesHeader."Ship-to Code", CustomerAgreement."Ship-to Code",
          StrSubstNo(AgrmtFieldValueErr, SalesHeader.FieldCaption("Ship-to Code")));
        Assert.AreEqual(
          SalesHeader."Responsibility Center", CustomerAgreement."Responsibility Center",
          StrSubstNo(AgrmtFieldValueErr, SalesHeader.FieldCaption("Responsibility Center")));
        Assert.AreEqual(
          SalesHeader."Shipping Agent Code", CustomerAgreement."Shipping Agent Code",
          StrSubstNo(AgrmtFieldValueErr, SalesHeader.FieldCaption("Shipping Agent Code")));
        Assert.AreEqual(
          Format(SalesHeader."Shipping Time"), Format(CustomerAgreement."Shipping Time"),
          StrSubstNo(AgrmtFieldValueErr, SalesHeader.FieldCaption("Shipping Time")));
        Assert.AreEqual(
          SalesHeader."Shipping Agent Code", CustomerAgreement."Shipping Agent Code",
          StrSubstNo(AgrmtFieldValueErr, SalesHeader.FieldCaption("Shipping Agent Code")));
        Assert.AreEqual(
          SalesHeader."Shipping Agent Service Code", CustomerAgreement."Shipping Agent Service Code",
          StrSubstNo(AgrmtFieldValueErr, SalesHeader.FieldCaption("Shipping Agent Service Code")));
        Assert.AreEqual(
          SalesHeader."Shipping Advice", CustomerAgreement."Shipping Advice",
          StrSubstNo(AgrmtFieldValueErr, SalesHeader.FieldCaption("Shipping Advice")));
        Assert.AreEqual(
          SalesHeader."Shipment Method Code", CustomerAgreement."Shipment Method Code",
          StrSubstNo(AgrmtFieldValueErr, SalesHeader.FieldCaption("Shipment Method Code")));
    end;

    local procedure VerifyComparePurchDocAgrmt(PurchHeader: Record "Purchase Header")
    var
        VendorAgreement: Record "Vendor Agreement";
    begin
        VendorAgreement.Get(PurchHeader."Buy-from Vendor No.", PurchHeader."Agreement No.");
        Assert.AreEqual(
          PurchHeader."Language Code", VendorAgreement."Language Code",
          StrSubstNo(AgrmtFieldValueErr, PurchHeader.FieldCaption("Language Code")));
        Assert.AreEqual(
          PurchHeader."Currency Code", VendorAgreement."Currency Code",
          StrSubstNo(AgrmtFieldValueErr, PurchHeader.FieldCaption("Currency Code")));
        Assert.AreEqual(
          PurchHeader."Purchaser Code", VendorAgreement."Purchaser Code",
          StrSubstNo(AgrmtFieldValueErr, PurchHeader.FieldCaption("Purchaser Code")));
        Assert.AreEqual(
          PurchHeader."Payment Terms Code", VendorAgreement."Payment Terms Code",
          StrSubstNo(AgrmtFieldValueErr, PurchHeader.FieldCaption("Payment Terms Code")));
        Assert.AreEqual(
          PurchHeader."Payment Method Code", VendorAgreement."Payment Method Code",
          StrSubstNo(AgrmtFieldValueErr, PurchHeader.FieldCaption("Payment Method Code")));
        Assert.AreEqual(
          PurchHeader."Vendor Posting Group", VendorAgreement."Vendor Posting Group",
          StrSubstNo(AgrmtFieldValueErr, PurchHeader.FieldCaption("Vendor Posting Group")));
        Assert.AreEqual(
          PurchHeader."Gen. Bus. Posting Group", VendorAgreement."Gen. Bus. Posting Group",
          StrSubstNo(AgrmtFieldValueErr, PurchHeader.FieldCaption("Gen. Bus. Posting Group")));
        Assert.AreEqual(
          PurchHeader."VAT Bus. Posting Group", VendorAgreement."VAT Bus. Posting Group",
          StrSubstNo(AgrmtFieldValueErr, PurchHeader.FieldCaption("VAT Bus. Posting Group")));
        Assert.AreEqual(
          PurchHeader."Location Code", VendorAgreement."Location Code",
          StrSubstNo(AgrmtFieldValueErr, PurchHeader.FieldCaption("Location Code")));
        Assert.AreEqual(
          PurchHeader."Responsibility Center", VendorAgreement."Responsibility Center",
          StrSubstNo(AgrmtFieldValueErr, PurchHeader.FieldCaption("Responsibility Center")));
    end;

    local procedure VerifyCustLedgerEntryAgrmt(CustomerNo: Code[20]; AgreementNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.FindSet();
        repeat
            Assert.AreEqual(CustLedgerEntry."Agreement No.", AgreementNo, AgrmtNoIncorrectErr)
        until CustLedgerEntry.Next() = 0;
    end;

    local procedure VerifyVendLedgerEntryAgrmt(VendorNo: Code[20]; AgreementNo: Code[20])
    var
        VendLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendLedgerEntry.FindSet();
        repeat
            Assert.AreEqual(VendLedgerEntry."Agreement No.", AgreementNo, AgrmtNoIncorrectErr)
        until VendLedgerEntry.Next() = 0;
    end;

    local procedure VerifyGLEntryAgrmt(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; AgreementNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindSet();
        repeat
            Assert.AreEqual(GLEntry."Agreement No.", AgreementNo, AgrmtNoIncorrectErr);
        until GLEntry.Next() = 0;
    end;

    local procedure VerifyClosedCustLedgerEntry(CustomerNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.FindSet();
        repeat
            Assert.IsFalse(CustLedgerEntry.Open, CustLedgerEntry.FieldCaption(Open))
        until CustLedgerEntry.Next() = 0;
    end;

    local procedure VerifyClosedVendLedgerEntry(VendorNo: Code[20])
    var
        VendLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendLedgerEntry.FindSet();
        repeat
            Assert.IsFalse(VendLedgerEntry.Open, VendLedgerEntry.FieldCaption(Open))
        until VendLedgerEntry.Next() = 0;
    end;

    local procedure PurchSetupInit(SynchAgmtDim: Boolean)
    var
        PurchSetup: Record "Purchases & Payables Setup";
        Dimension: Record Dimension;
    begin
        Dimension.FindFirst();
        PurchSetup.Get();
        PurchSetup."Synch. Agreement Dimension" := SynchAgmtDim;
        PurchSetup."Vendor Agreement Dim. Code" := Dimension.Code;
        PurchSetup.Modify();
    end;

    local procedure SalesSetupInit(SynchAgmtDim: Boolean)
    var
        SalesSetup: Record "Sales & Receivables Setup";
        Dimension: Record Dimension;
    begin
        Dimension.FindFirst();
        SalesSetup.Get();
        SalesSetup."Synch. Agreement Dimension" := SynchAgmtDim;
        SalesSetup."Customer Agreement Dim. Code" := Dimension.Code;
        SalesSetup.Modify();
    end;

    local procedure CheckAgreementDimensions(AgreementDimCode: Code[20]; AgreementCode: Code[20]; TableID: Integer; IsDimValueBlocked: Boolean)
    var
        DimValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        Assert.IsTrue(
          DimValue.Get(AgreementDimCode, AgreementCode),
          StrSubstNo(RecordNotFoundErr, DimValue.TableCaption()));
        Assert.AreEqual(
          IsDimValueBlocked, DimValue.Blocked,
          StrSubstNo(FieldValueIncorrectErr, DimValue.FieldCaption(Blocked)));
        Assert.IsTrue(
          DefaultDimension.Get(
            TableID, AgreementCode, AgreementDimCode),
          StrSubstNo(RecordNotFoundErr, DefaultDimension.TableCaption()));
        Assert.AreEqual(
          AgreementCode, DefaultDimension."Dimension Value Code",
          StrSubstNo(FieldValueIncorrectErr, DefaultDimension.FieldCaption("Dimension Value Code")));
    end;

    local procedure CheckVendorAgmtDimensions(VendorAgreementCode: Code[20]; IsDimValueBlocked: Boolean)
    var
        PurchSetup: Record "Purchases & Payables Setup";
    begin
        PurchSetup.Get();
        CheckAgreementDimensions(
          PurchSetup."Vendor Agreement Dim. Code", VendorAgreementCode, DATABASE::"Vendor Agreement", IsDimValueBlocked);
    end;

    local procedure CheckCustomerAgmtDimensions(CustomerAgreementCode: Code[20]; IsDimValueBlocked: Boolean)
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        SalesSetup.Get();
        CheckAgreementDimensions(
          SalesSetup."Customer Agreement Dim. Code", CustomerAgreementCode, DATABASE::"Customer Agreement", IsDimValueBlocked);
    end;

    local procedure ClearPurchSalesSetup()
    var
        PurchSetup: Record "Purchases & Payables Setup";
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        PurchSetup.Get();
        PurchSetup."Synch. Agreement Dimension" := true;
        PurchSetup.Modify();

        SalesSetup.Get();
        SalesSetup."Synch. Agreement Dimension" := true;
        SalesSetup.Modify();
    end;

    local procedure InitVendorAgreement(var VendorAgreement: Record "Vendor Agreement"; SynchAgmtDim: Boolean)
    begin
        Initialize();
        PurchSetupInit(SynchAgmtDim);
        CreateSimpleVendorAgreement(
          VendorAgreement, CreateVendor(AgreementPosting::Mandatory));
    end;

    local procedure InitCustomerAgreement(var CustomerAgreement: Record "Customer Agreement"; SynchAgmtDim: Boolean)
    begin
        Initialize();
        SalesSetupInit(SynchAgmtDim);
        CreateSimpleCustomerAgreement(
          CustomerAgreement, CreateCustomer(AgreementPosting::Mandatory));
    end;

    local procedure BlockVendorAgreement(var VendorAgreement: Record "Vendor Agreement"; Block: Boolean)
    begin
        if Block then
            VendorAgreement.Blocked := VendorAgreement.Blocked::All
        else
            VendorAgreement.Blocked := VendorAgreement.Blocked::" ";
        VendorAgreement.Modify(true);
    end;

    local procedure BlockCustomerAgreement(var CustomerAgreement: Record "Customer Agreement"; Block: Boolean)
    begin
        if Block then
            CustomerAgreement.Blocked := CustomerAgreement.Blocked::All
        else
            CustomerAgreement.Blocked := CustomerAgreement.Blocked::" ";
        CustomerAgreement.Modify(true);
    end;

    local procedure GetPurchSetupAgreementDimCode(): Code[20]
    var
        PurchSetup: Record "Purchases & Payables Setup";
    begin
        PurchSetup.Get();
        exit(PurchSetup."Vendor Agreement Dim. Code");
    end;

    local procedure GetSalesSetupAgreementDimCode(): Code[20]
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        SalesSetup.Get();
        exit(SalesSetup."Customer Agreement Dim. Code");
    end;

    local procedure SetVendorAgreementGlobalDimensions(VendorNo: Code[20]; VendorAgreementNo: Code[20]; DimValue1Code: Code[20]; DimValue2Code: Code[20])
    var
        VendorAgreement: Record "Vendor Agreement";
    begin
        VendorAgreement.Get(VendorNo, VendorAgreementNo);
        VendorAgreement.Validate("Global Dimension 1 Code", DimValue1Code);
        VendorAgreement.Validate("Global Dimension 2 Code", DimValue2Code);
        VendorAgreement.Modify(true);
    end;

    local procedure SetCustomerAgreementGlobalDimensions(CustomerNo: Code[20]; CustomerAgreementNo: Code[20]; DimValue1Code: Code[20]; DimValue2Code: Code[20])
    var
        CustomerAgreement: Record "Customer Agreement";
    begin
        CustomerAgreement.Get(CustomerNo, CustomerAgreementNo);
        CustomerAgreement.Validate("Global Dimension 1 Code", DimValue1Code);
        CustomerAgreement.Validate("Global Dimension 2 Code", DimValue2Code);
        CustomerAgreement.Modify(true);
    end;

    local procedure SetCustomerAgreementExpireDate(CustomerNo: Code[20]; CustomerAgreementNo: Code[20]; Date: Date)
    var
        CustomerAgreement: Record "Customer Agreement";
    begin
        CustomerAgreement.Get(CustomerNo, CustomerAgreementNo);
        CustomerAgreement.Validate("Expire Date", Date);
        CustomerAgreement.Modify(true);
    end;

    local procedure SetVendorAgreementExpireDate(VendorNo: Code[20]; VendorAgreementNo: Code[20]; Date: Date)
    var
        VendorAgreement: Record "Vendor Agreement";
    begin
        VendorAgreement.Get(VendorNo, VendorAgreementNo);
        VendorAgreement.Validate("Expire Date", Date);
        VendorAgreement.Modify(true);
    end;

    local procedure CreateSimpleVendorAgreement(var VendorAgreement: Record "Vendor Agreement"; VendorNo: Code[20])
    begin
        VendorAgreement.Init();
        VendorAgreement."Vendor No." := VendorNo;
        VendorAgreement.Insert(true);
    end;

    local procedure CreateSimpleCustomerAgreement(var CustomerAgreement: Record "Customer Agreement"; CustomerNo: Code[20])
    begin
        CustomerAgreement.Init();
        CustomerAgreement."Customer No." := CustomerNo;
        CustomerAgreement.Insert(true);
    end;

    local procedure CreateGlobalDimensionValues(var DimensionValue1Code: Code[20]; var DimensionValue2Code: Code[20])
    var
        GLSetup: Record "General Ledger Setup";
        DimensionValue: Record "Dimension Value";
    begin
        GLSetup.Get();
        LibraryDimension.CreateDimensionValue(DimensionValue, GLSetup."Global Dimension 1 Code");
        DimensionValue1Code := DimensionValue.Code;
        LibraryDimension.CreateDimensionValue(DimensionValue, GLSetup."Global Dimension 2 Code");
        DimensionValue2Code := DimensionValue.Code;
    end;

    local procedure CheckDefaultDimExists(TableNo: Integer; AgreementNo: Code[20]; GlobalDimCode: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
    begin
        Assert.IsTrue(
          DefaultDimension.Get(
            TableNo, AgreementNo, GlobalDimCode), DefaultDimNotExistErr);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure UnapplyCustomerEntriesModalPageHandler(var UnapplyCustomerEntries: TestPage "Unapply Customer Entries")
    begin
        UnapplyCustomerEntries.Unapply.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure UnapplyVendorEntriesPageHandler(var UnapplyVendorEntries: TestPage "Unapply Vendor Entries")
    begin
        UnapplyVendorEntries.Unapply.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyVendorEntriesPageHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    begin
        ApplyVendorEntries.ActionSetAppliesToID.Invoke();
        ApplyVendorEntries.ActionPostApplication.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries."Set Applies-to ID".Invoke();
        ApplyCustomerEntries."Post Application".Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostApplicationPageHandler(var PostApplication: TestPage "Post Application")
    begin
        PostApplication.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Message Handler.
    end;
}

