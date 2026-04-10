codeunit 139158 "Invoice Mapping Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Data Exchange] [Intermediate Data Import] [Map Incoming Doc to Purch Doc]
    end;

    var
        CompanyInfo: Record "Company Information";
        DummyIntermediateDataImport: Record "Intermediate Data Import";
        Assert: Codeunit Assert;
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryIncomingDocuments: Codeunit "Library - Incoming Documents";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        ValueErr: Label 'Cannot find a value for field %1 of table %2 in table %3.', Comment = '%1 - field caption, %2 - table caption, %3 - table caption';
        NotValidOptionErr: Label 'not a valid option.';
        TableNotEmptiedErr: Label 'Records in table %1 for Data Exch. Entry No. %2 are not deleted.', Comment = '%1=Table Caption,%2=Data Exch. Entry No.';
        TotalsMismatchErr: Label 'The total amount %1 on the created document is different than the total amount %2 in the incoming document.', Comment = '%1 total amount, %2 expected total amount';
        InvoiceChargeHasNoReasonErr: Label 'Invoice charge on the incoming document has no reason code.';
        UnableToApplyDiscountErr: Label 'The invoice discount of %1 cannot be applied. Invoice discount must be allowed on at least one invoice line and invoice total must not be 0.', Comment = '%1 - a decimal number';
        CannotPostErr: Label 'The invoice cannot be posted because the total is different from the total on the related incoming document.';
        DialogCodeErr: Label 'Dialog';

    [Test]
    [Scope('OnPrem')]
    procedure TestInvoiceCreated()
    var
        DataExch: Record "Data Exch.";
        BuyFromVendor: Record Vendor;
        Item1: Record Item;
        Item2: Record Item;
        Currency: Record Currency;
    begin
        Initialize();

        // Setup
        SetupDataExchTable(DataExch);
        SetupValidIntermediateTable(DataExch, BuyFromVendor, Item1, Item2, Currency, 1);

        // Excercise
        CODEUNIT.Run(CODEUNIT::"Map Incoming Doc to Purch Doc", DataExch);

        // Verify
        AssertPurchaseDoc(DataExch, BuyFromVendor, BuyFromVendor, Item1, Item2, Currency, 0);
        AssertIntermediateDataIsDeleted(DataExch);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInvoiceCreatedWithTotalsMismatch()
    var
        DataExch: Record "Data Exch.";
        BuyFromVendor: Record Vendor;
        Item1: Record Item;
        Item2: Record Item;
        Currency: Record Currency;
        PurchaseHeader: Record "Purchase Header";
        ErrorMessage: Record "Error Message";
        IncomingDocument: Record "Incoming Document";
        ActualTotalAmount: Decimal;
    begin
        Initialize();

        // Setup
        SetupDataExchTable(DataExch);
        SetupValidIntermediateTable(DataExch, BuyFromVendor, Item1, Item2, Currency, 1);
        InsertIntermediateTableRowWithRecordNoAndOptional(DataExch, DATABASE::"Purchase Header"
          , PurchaseHeader.FieldNo("Amount Including VAT"), '0', 1, 0, true);
        IncomingDocument.Get(DataExch."Incoming Entry No.");
        IncomingDocument."Created Doc. Error Msg. Type" := IncomingDocument."Created Doc. Error Msg. Type"::Error;
        IncomingDocument.Modify();

        // Excercise
        CODEUNIT.Run(CODEUNIT::"Map Incoming Doc to Purch Doc", DataExch);

        // Verify
        AssertPurchaseDoc(DataExch, BuyFromVendor, BuyFromVendor, Item1, Item2, Currency, 0);
        AssertIntermediateDataIsDeleted(DataExch);
        ActualTotalAmount := CalculateTotalsForCreatedDoc(DataExch);
        AssertExpectedError(DataExch, ErrorMessage."Message Type"::Error,
          StrSubstNo(TotalsMismatchErr, Format(ActualTotalAmount, 0, '<Precision,2:2><Standard Format,0>'), '0'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInvoiceCreatedWithTotalsMismatchWarning()
    var
        DataExch: Record "Data Exch.";
        BuyFromVendor: Record Vendor;
        Item1: Record Item;
        Item2: Record Item;
        Currency: Record Currency;
        PurchaseHeader: Record "Purchase Header";
        IncomingDocument: Record "Incoming Document";
        ActualTotalAmount: Decimal;
    begin
        Initialize();

        // Setup
        SetupDataExchTable(DataExch);
        SetupValidIntermediateTable(DataExch, BuyFromVendor, Item1, Item2, Currency, 1);
        InsertIntermediateTableRowWithRecordNoAndOptional(DataExch, DATABASE::"Purchase Header"
          , PurchaseHeader.FieldNo("Amount Including VAT"), '0', 1, 0, true);
        IncomingDocument.Init();
        IncomingDocument."Entry No." := LibraryRandom.RandInt(100000);
        IncomingDocument."Created Doc. Error Msg. Type" := IncomingDocument."Created Doc. Error Msg. Type"::Warning;
        IncomingDocument.Insert();
        DataExch."Incoming Entry No." := IncomingDocument."Entry No.";
        DataExch.Modify();

        // Excercise
        CODEUNIT.Run(CODEUNIT::"Map Incoming Doc to Purch Doc", DataExch);

        // Verify
        AssertPurchaseDoc(DataExch, BuyFromVendor, BuyFromVendor, Item1, Item2, Currency, 0);
        AssertIntermediateDataIsDeleted(DataExch);
        ActualTotalAmount := CalculateTotalsForCreatedDoc(DataExch);
        AssertWarning(DataExch,
          StrSubstNo(TotalsMismatchErr, Format(ActualTotalAmount, 0, '<Precision,2:2><Standard Format,0>'), '0'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInvoiceNotPostedWhenTotalsMismatchWithIncomingDocument()
    var
        DataExch: Record "Data Exch.";
        BuyFromVendor: Record Vendor;
        Item1: Record Item;
        Item2: Record Item;
        Currency: Record Currency;
        PurchaseHeader: Record "Purchase Header";
        ActualTotalAmount: Decimal;
        ChangedTotalAmount: Decimal;
    begin
        Initialize();

        // Setup
        SetupDataExchTable(DataExch);
        SetupValidIntermediateTable(DataExch, BuyFromVendor, Item1, Item2, Currency, 1);
        InsertIntermediateTableRowWithRecordNoAndOptional(DataExch, DATABASE::"Purchase Header"
          , PurchaseHeader.FieldNo("Amount Including VAT"), '0', 1, 0, true);

        // Excercise
        CODEUNIT.Run(CODEUNIT::"Map Incoming Doc to Purch Doc", DataExch);
        ActualTotalAmount := CalculateTotalsForCreatedDoc(DataExch);
        ChangedTotalAmount := ActualTotalAmount + LibraryRandom.RandDecInRange(1, 100, 2);
        SetTotalInIncomingDocument(DataExch."Incoming Entry No.", Currency.Code, ChangedTotalAmount);

        // Verify
        AssertPurchaseDoc(DataExch, BuyFromVendor, BuyFromVendor, Item1, Item2, Currency, 0);
        AssertIntermediateDataIsDeleted(DataExch);
        PostPurchaseInvoice(DataExch."Incoming Entry No.");
    end;

    local procedure SetTotalInIncomingDocument(IncomingEntryNo: Integer; CurrencyCode: Code[10]; AmountIncVAT: Decimal)
    var
        IncomingDocument: Record "Incoming Document";
    begin
        IncomingDocument.Get(IncomingEntryNo);
        IncomingDocument."Currency Code" := CurrencyCode;
        IncomingDocument."Amount Incl. VAT" := AmountIncVAT;
        IncomingDocument.Modify();
    end;

    local procedure PostPurchaseInvoice(IncomingEntryNo: Integer)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        PurchaseHeader.SetRange("Incoming Document Entry No.", IncomingEntryNo);
        PurchaseHeader.FindFirst();
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseHeader);
        asserterror PurchaseInvoice.Post.Invoke();
        Assert.ExpectedError(CannotPostErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInvoiceCreatedWithApplyDiscountWarning()
    var
        DataExch: Record "Data Exch.";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        IncomingDocument: Record "Incoming Document";
        DiscountAmount: Integer;
    begin
        Initialize();
        DiscountAmount := 100;

        // Setup
        Setup(DataExch);
        IncomingDocument.Get(DataExch."Incoming Entry No.");
        IncomingDocument."Created Doc. Error Msg. Type" := IncomingDocument."Created Doc. Error Msg. Type"::Warning;
        IncomingDocument.Modify();

        // add invoice discount
        InsertIntermediateTableRowWithRecordNo(DataExch, DATABASE::"Purchase Header",
          PurchaseHeader.FieldNo("Invoice Discount Value"), Format(DiscountAmount), 1, 0);

        // make all lines disallow invoice discount
        InsertIntermediateTableRowWithRecordNo(DataExch, DATABASE::"Purchase Line",
          PurchaseLine.FieldNo("Allow Invoice Disc."), Format(false), 2, 1);
        InsertIntermediateTableRowWithRecordNo(DataExch, DATABASE::"Purchase Line",
          PurchaseLine.FieldNo("Allow Invoice Disc."), Format(false), 3, 1);

        // Excercise
        CODEUNIT.Run(CODEUNIT::"Map Incoming Doc to Purch Doc", DataExch);

        // Verify
        AssertWarning(DataExch,
          StrSubstNo(UnableToApplyDiscountErr, Format(DiscountAmount)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInvoiceCreatedWithApplyDiscountError()
    var
        DataExch: Record "Data Exch.";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        IncomingDocument: Record "Incoming Document";
        ErrorMessage: Record "Error Message";
        DiscountAmount: Integer;
    begin
        Initialize();
        DiscountAmount := 100;

        // Setup
        Setup(DataExch);
        IncomingDocument.Get(DataExch."Incoming Entry No.");
        IncomingDocument."Created Doc. Error Msg. Type" := IncomingDocument."Created Doc. Error Msg. Type"::Error;
        IncomingDocument.Modify();

        // add invoice discount
        InsertIntermediateTableRowWithRecordNo(DataExch, DATABASE::"Purchase Header",
          PurchaseHeader.FieldNo("Invoice Discount Value"), Format(DiscountAmount), 1, 0);

        // make all lines disallow invoice discount
        InsertIntermediateTableRowWithRecordNo(DataExch, DATABASE::"Purchase Line",
          PurchaseLine.FieldNo("Allow Invoice Disc."), Format(false), 2, 1);
        InsertIntermediateTableRowWithRecordNo(DataExch, DATABASE::"Purchase Line",
          PurchaseLine.FieldNo("Allow Invoice Disc."), Format(false), 3, 1);

        // Excercise
        CODEUNIT.Run(CODEUNIT::"Map Incoming Doc to Purch Doc", DataExch);

        // Verify
        AssertExpectedError(DataExch, ErrorMessage."Message Type"::Error, StrSubstNo(UnableToApplyDiscountErr, Format(DiscountAmount)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInvoiceCreatedWithVATMismatch()
    var
        DataExch: Record "Data Exch.";
        BuyFromVendor: Record Vendor;
        Item1: Record Item;
        Item2: Record Item;
        Currency: Record Currency;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        Initialize();

        // Setup
        SetupDataExchTable(DataExch);
        SetupValidIntermediateTable(DataExch, BuyFromVendor, Item1, Item2, Currency, 1);
        InsertIntermediateTableRowWithRecordNoAndOptional(DataExch, DATABASE::"Purchase Header"
          , PurchaseHeader.FieldNo("Amount Including VAT"), '0', 1, 0, true);
        InsertIntermediateTableRowWithRecordNoAndOptional(DataExch, DATABASE::"Purchase Line"
          , PurchaseLine.FieldNo("VAT %"), '99', 2, 1, true);

        // Excercise
        CODEUNIT.Run(CODEUNIT::"Map Incoming Doc to Purch Doc", DataExch);

        // Verify
        AssertPurchaseDoc(DataExch, BuyFromVendor, BuyFromVendor, Item1, Item2, Currency, 0);
        AssertIntermediateDataIsDeleted(DataExch);
        AssertWarning(DataExch, 'which is different than');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInvoiceCreatedWithTotalsMismatchAndPrepayment()
    var
        DataExch: Record "Data Exch.";
        BuyFromVendor: Record Vendor;
        Item1: Record Item;
        Item2: Record Item;
        Currency: Record Currency;
        PurchaseHeader: Record "Purchase Header";
        ErrorMessage: Record "Error Message";
        IncomingDocument: Record "Incoming Document";
        ActualTotalAmount: Decimal;
        PrepaidAmount: Decimal;
    begin
        Initialize();

        // Setup
        PrepaidAmount := LibraryRandom.RandDecInDecimalRange(1, 100, 2);
        SetupDataExchTable(DataExch);
        SetupValidIntermediateTable(DataExch, BuyFromVendor, Item1, Item2, Currency, 1);
        InsertIntermediateTableRowWithRecordNoAndOptional(DataExch, DATABASE::"Purchase Header"
          , PurchaseHeader.FieldNo("Amount Including VAT"), '0', 1, 0, true);
        InsertIntermediateTableRowWithRecordNoAndOptional(DataExch, DATABASE::"Prepayment Inv. Line Buffer"
          , PurchaseHeader.FieldNo("No."), Format(PrepaidAmount, 0, 9), 1, 0, true);

        IncomingDocument.Get(DataExch."Incoming Entry No.");
        IncomingDocument."Created Doc. Error Msg. Type" := IncomingDocument."Created Doc. Error Msg. Type"::Error;
        IncomingDocument.Modify();

        // Excercise
        CODEUNIT.Run(CODEUNIT::"Map Incoming Doc to Purch Doc", DataExch);

        // Verify
        AssertPurchaseDoc(DataExch, BuyFromVendor, BuyFromVendor, Item1, Item2, Currency, 0);
        AssertIntermediateDataIsDeleted(DataExch);
        ActualTotalAmount := CalculateTotalsForCreatedDoc(DataExch);
        AssertExpectedError(
          DataExch, ErrorMessage."Message Type"::Error,
          StrSubstNo(TotalsMismatchErr, Format(ActualTotalAmount, 0, '<Precision,2:2><Standard Format,0>'), '0'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInvoiceCreatedWithBlankDueDate()
    var
        DataExch: Record "Data Exch.";
        BuyFromVendor: Record Vendor;
        Item1: Record Item;
        Item2: Record Item;
        Currency: Record Currency;
        PurchaseHeader: Record "Purchase Header";
    begin
        Initialize();

        // Setup
        SetupDataExchTable(DataExch);
        SetupValidIntermediateTable(DataExch, BuyFromVendor, Item1, Item2, Currency, 1);
        InsertIntermediateTableRowWithRecordNoAndOptional(DataExch, DATABASE::"Purchase Header"
          , PurchaseHeader.FieldNo("Posting Date"), Format(WorkDate()), 1, 0, false);
        InsertIntermediateTableRowWithRecordNoAndOptional(DataExch, DATABASE::"Purchase Header"
          , PurchaseHeader.FieldNo("Due Date"), '', 1, 0, false);
        // Excercise
        CODEUNIT.Run(CODEUNIT::"Map Incoming Doc to Purch Doc", DataExch);

        // Verify
        AssertPurchaseDoc(DataExch, BuyFromVendor, BuyFromVendor, Item1, Item2, Currency, 0);
        AssertIntermediateDataIsDeleted(DataExch);
        PurchaseHeader.SetRange("Incoming Document Entry No.", DataExch."Incoming Entry No.");
        PurchaseHeader.FindFirst();
        Assert.AreEqual(PurchaseHeader."Posting Date", PurchaseHeader."Due Date", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInvoiceChargeWithoutChargeReason()
    var
        DataExch: Record "Data Exch.";
        BuyFromVendor: Record Vendor;
        Item1: Record Item;
        Item2: Record Item;
        Currency: Record Currency;
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        ErrorMessage: Record "Error Message";
        ChargeAmount: Decimal;
    begin
        Initialize();

        // Setup
        ChargeAmount := LibraryRandom.RandDecInDecimalRange(1, 100, 2);
        SetupDataExchTable(DataExch);
        SetupValidIntermediateTable(DataExch, BuyFromVendor, Item1, Item2, Currency, 1);
        InsertIntermediateTableRowWithRecordNoAndOptional(DataExch, DATABASE::"Item Charge Assignment (Purch)"
          , ItemChargeAssignmentPurch.FieldNo("Amount to Assign"), Format(ChargeAmount, 0, 9), 1, 0, true);

        // Excercise
        CODEUNIT.Run(CODEUNIT::"Map Incoming Doc to Purch Doc", DataExch);

        // Verify
        AssertExpectedError(DataExch, ErrorMessage."Message Type"::Error, InvoiceChargeHasNoReasonErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInvoiceChargeImportedAsGLAccountLine()
    var
        DataExch: Record "Data Exch.";
        BuyFromVendor: Record Vendor;
        Item1: Record Item;
        Item2: Record Item;
        Currency: Record Currency;
        PurchaseHeader: Record "Purchase Header";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        ItemCharge: Record "Item Charge";
        PurchaseLine: Record "Purchase Line";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        TextToAccountMapping: Record "Text-to-Account Mapping";
        ChargeAmount: Decimal;
        ChargeReason: Text;
    begin
        Initialize();

        // Setup
        ChargeAmount := LibraryRandom.RandDecInDecimalRange(1, 100, 2);
        ChargeReason := LibraryUtility.GenerateRandomText(MaxStrLen(ItemCharge.Description));
        SetupDataExchTable(DataExch);
        SetupValidIntermediateTable(DataExch, BuyFromVendor, Item1, Item2, Currency, 1);
        InsertIntermediateTableRowWithRecordNoAndOptional(
          DataExch, DATABASE::"Item Charge Assignment (Purch)", ItemChargeAssignmentPurch.FieldNo("Amount to Assign"),
          Format(ChargeAmount, 0, 9), 1, 0, true);
        InsertIntermediateTableRowWithRecordNoAndOptional(
          DataExch, DATABASE::"Item Charge", ItemCharge.FieldNo(Description),
          CopyStr(ChargeReason, 1, MaxStrLen(ItemCharge.Description)), 1, 0, true);

        // set up G/L Account in Text to Account Mapping
        PurchasesPayablesSetup.Get();
        TextToAccountMapping.Init();
        TextToAccountMapping."Mapping Text" := CopyStr(ChargeReason, 1, MaxStrLen(TextToAccountMapping."Mapping Text"));
        TextToAccountMapping."Debit Acc. No." := PurchasesPayablesSetup."Debit Acc. for Non-Item Lines";
        TextToAccountMapping.Insert();
        PurchasesPayablesSetup."Debit Acc. for Non-Item Lines" := '';
        PurchasesPayablesSetup.Modify();

        // Excercise
        CODEUNIT.Run(CODEUNIT::"Map Incoming Doc to Purch Doc", DataExch);

        // Verify
        PurchaseHeader.SetRange("Incoming Document Entry No.", DataExch."Incoming Entry No.");
        Assert.IsTrue(PurchaseHeader.FindFirst(), 'Document was not created.');
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::"G/L Account");
        PurchaseLine.SetRange(Description, ChargeReason);
        PurchaseLine.SetRange(Quantity, 1);
        PurchaseLine.SetRange("Direct Unit Cost", ChargeAmount);
        PurchaseLine.SetRange("No.", TextToAccountMapping."Debit Acc. No.");
        Assert.IsTrue(PurchaseLine.FindFirst(), 'Purchase line for invoice charge not created correctly.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInvoiceChargeWithoutGLAccountSetup()
    var
        DataExch: Record "Data Exch.";
        BuyFromVendor: Record Vendor;
        Item1: Record Item;
        Item2: Record Item;
        Currency: Record Currency;
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        ItemCharge: Record "Item Charge";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        ChargeAmount: Decimal;
        ChargeReason: Text;
    begin
        Initialize();

        // Setup
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Debit Acc. for Non-Item Lines" := '';
        PurchasesPayablesSetup.Modify(true);
        ChargeAmount := LibraryRandom.RandDecInDecimalRange(1, 100, 2);
        ChargeReason := LibraryUtility.GenerateRandomXMLText(10);
        SetupDataExchTable(DataExch);
        SetupValidIntermediateTable(DataExch, BuyFromVendor, Item1, Item2, Currency, 1);
        InsertIntermediateTableRowWithRecordNoAndOptional(DataExch, DATABASE::"Item Charge Assignment (Purch)"
          , ItemChargeAssignmentPurch.FieldNo("Amount to Assign"), Format(ChargeAmount, 0, 9), 1, 0, true);
        InsertIntermediateTableRowWithRecordNoAndOptional(DataExch, DATABASE::"Item Charge"
          , ItemCharge.FieldNo(Description), CopyStr(ChargeReason, 1, MaxStrLen(ItemCharge.Description)), 1, 0, true);

        // Excercise
        asserterror CODEUNIT.Run(CODEUNIT::"Map Incoming Doc to Purch Doc", DataExch);

        // Verify
        Assert.IsTrue(StrPos(GetLastErrorText(), 'Cannot find G/L Account') > 0, 'Unexpected error');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInvoiceCreatedWithDiscount()
    var
        DataExch: Record "Data Exch.";
        BuyFromVendor: Record Vendor;
        Item1: Record Item;
        Item2: Record Item;
        Currency: Record Currency;
        PurchaseHeader: Record "Purchase Header";
        DiscountAmount: Decimal;
    begin
        Initialize();
        DiscountAmount := 100;

        // Setup
        SetupDataExchTable(DataExch);
        SetupValidIntermediateTable(DataExch, BuyFromVendor, Item1, Item2, Currency, 1);
        InsertIntermediateTableRowWithRecordNo(DataExch, DATABASE::"Purchase Header",
          PurchaseHeader.FieldNo("Invoice Discount Value"), Format(DiscountAmount), 1, 0);

        // Excercise
        CODEUNIT.Run(CODEUNIT::"Map Incoming Doc to Purch Doc", DataExch);

        // Verify
        AssertPurchaseDoc(DataExch, BuyFromVendor, BuyFromVendor, Item1, Item2, Currency, DiscountAmount);
        AssertIntermediateDataIsDeleted(DataExch);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMissingDocumentType()
    var
        DataExch: Record "Data Exch.";
        PurchaseHeader: Record "Purchase Header";
    begin
        Initialize();

        // Setup
        Setup(DataExch);

        DeleteIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Document Type"));

        // Excercise
        asserterror CODEUNIT.Run(CODEUNIT::"Map Incoming Doc to Purch Doc", DataExch);
        Assert.ExpectedError(
          StrSubstNo(ValueErr, PurchaseHeader.FieldCaption("Document Type"),
            PurchaseHeader.TableCaption(), DummyIntermediateDataImport.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInvalidDocumentType()
    var
        DataExch: Record "Data Exch.";
        PurchaseHeader: Record "Purchase Header";
    begin
        Initialize();

        // Setup
        Setup(DataExch);

        UpdateIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Document Type"),
          CopyStr(LibraryUtility.GenerateRandomText(5), 1, 5));

        // Excercise
        asserterror CODEUNIT.Run(CODEUNIT::"Map Incoming Doc to Purch Doc", DataExch);
        Assert.ExpectedError(NotValidOptionErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMissingBuyFromVendor()
    var
        DataExch: Record "Data Exch.";
        PurchaseHeader: Record "Purchase Header";
    begin
        Initialize();

        // Setup
        Setup(DataExch);

        DeleteIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."));

        // Excercise
        asserterror CODEUNIT.Run(CODEUNIT::"Map Incoming Doc to Purch Doc", DataExch);
        Assert.ExpectedError(
          StrSubstNo(ValueErr, PurchaseHeader.FieldCaption("Buy-from Vendor No."),
            PurchaseHeader.TableCaption(), DummyIntermediateDataImport.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMissingLineType()
    var
        DataExch: Record "Data Exch.";
        PurchaseLine: Record "Purchase Line";
    begin
        Initialize();

        // Setup
        Setup(DataExch);

        DeleteIntermediateTableRow(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo(Type));

        // Excercise
        asserterror CODEUNIT.Run(CODEUNIT::"Map Incoming Doc to Purch Doc", DataExch);
        Assert.ExpectedError(
          StrSubstNo(ValueErr, PurchaseLine.FieldCaption(Type), PurchaseLine.TableCaption(), DummyIntermediateDataImport.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMissingLineNo()
    var
        DataExch: Record "Data Exch.";
        PurchaseLine: Record "Purchase Line";
    begin
        Initialize();

        // Setup
        Setup(DataExch);

        DeleteIntermediateTableRow(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo("No."));

        // Excercise
        asserterror CODEUNIT.Run(CODEUNIT::"Map Incoming Doc to Purch Doc", DataExch);
        Assert.ExpectedError(
          StrSubstNo(ValueErr, PurchaseLine.FieldCaption("No."), PurchaseLine.TableCaption(), DummyIntermediateDataImport.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMissingLineUOM()
    var
        DataExch: Record "Data Exch.";
        PurchaseLine: Record "Purchase Line";
        BuyFromVendor: Record Vendor;
        Item1: Record Item;
        Item2: Record Item;
        Currency: Record Currency;
    begin
        Initialize();

        // Setup
        SetupDataExchTable(DataExch);
        SetupValidIntermediateTable(DataExch, BuyFromVendor, Item1, Item2, Currency, 1);
        DeleteIntermediateTableRow(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo("Unit of Measure Code"));

        // Excercise
        CODEUNIT.Run(CODEUNIT::"Map Incoming Doc to Purch Doc", DataExch);

        // Verify
        AssertPurchaseDoc(DataExch, BuyFromVendor, BuyFromVendor, Item1, Item2, Currency, 0);
        AssertIntermediateDataIsDeleted(DataExch);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMissingLineQuantity()
    var
        DataExch: Record "Data Exch.";
        PurchaseLine: Record "Purchase Line";
    begin
        Initialize();

        // Setup
        Setup(DataExch);

        DeleteIntermediateTableRow(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo(Quantity));

        // Excercise
        asserterror CODEUNIT.Run(CODEUNIT::"Map Incoming Doc to Purch Doc", DataExch);
        Assert.ExpectedError(
          StrSubstNo(ValueErr, PurchaseLine.FieldCaption(Quantity), PurchaseLine.TableCaption(), DummyIntermediateDataImport.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestConfirmMsgHidden()
    var
        PurchaseHeader: Record "Purchase Header";
        DataExch: Record "Data Exch.";
        BuyFromVendor: Record Vendor;
        PayToVendor: Record Vendor;
        Item1: Record Item;
        Item2: Record Item;
        Currency: Record Currency;
        HeaderRecNo: Integer;
    begin
        Initialize();
        HeaderRecNo := 1;

        // Setup
        SetupDataExchTable(DataExch);
        SetupValidIntermediateTable(DataExch, BuyFromVendor, Item1, Item2, Currency, HeaderRecNo);
        LibraryPurchase.CreateVendor(PayToVendor);

        InsertIntermediateTableRowWithRecordNo(DataExch, DATABASE::"Purchase Header",
          PurchaseHeader.FieldNo("Pay-to Vendor No."), PayToVendor."No.", HeaderRecNo, 0);
        InsertIntermediateTableRowWithRecordNo(DataExch, DATABASE::"Purchase Header",
          PurchaseHeader.FieldNo("VAT Base Discount %"), '1', HeaderRecNo, 0);

        // Excercise
        CODEUNIT.Run(CODEUNIT::"Map Incoming Doc to Purch Doc", DataExch);

        // Verify - also if confirm will show, test will fail
        AssertPurchaseDoc(DataExch, BuyFromVendor, PayToVendor, Item1, Item2, Currency, 0);
        AssertIntermediateDataIsDeleted(DataExch);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceNotPostedWhenTotalsMismatchIncomingDocumentWithLCY()
    var
        IncomingDocument: Record "Incoming Document";
        PurchaseHeader: Record "Purchase Header";
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [Incoming Document]
        // [SCENARIO 294747] Purchase Invoice is not posted when totals differ from Incoming Document totals in case Incoming Document has LCY
        Initialize();
        CurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();
        UpdateGLSetupLCYCode(CurrencyCode);

        // [GIVEN] Purchase Invoice and mapped Incoming Document both had LCY, but totals were different
        LibraryIncomingDocuments.CreateNewIncomingDocument(IncomingDocument);
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        PurchaseHeader.Validate("Incoming Document Entry No.", IncomingDocument."Entry No.");
        PurchaseHeader.Modify(true);
        PurchaseHeader.CalcFields("Amount Including VAT");
        SetTotalInIncomingDocument(IncomingDocument."Entry No.", CurrencyCode, PurchaseHeader."Amount Including VAT" * 2);

        // [WHEN] Post Purchase Invoice
        PostPurchaseInvoice(PurchaseHeader."Incoming Document Entry No.");

        // [THEN] Error "The invoice cannot be posted because the total is different from the total on the related incoming document."
        Assert.ExpectedError(CannotPostErr);
        Assert.ExpectedErrorCode(DialogCodeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyIncomingDocumentsOnPostedPurchaseInvoice()
    var
        IncomingDocument: Record "Incoming Document";
        PurchaseHeader: Record "Purchase Header";
        PurchInvoiceHeader: Record "Purch. Inv. Header";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        VendorNo: Code[10];
        IncomingDocDesc: Text[250];
    begin
        // [SCENARIO 294747] When the Incoming Document is selected from the Purchase Order, the Incoming Document is not visible in Factbox from the Posted Purchase Invoice
        Initialize();

        // [GIVEN] Create Incoming document and Purchase Invoice
        LibraryIncomingDocuments.CreateNewIncomingDocument(IncomingDocument);
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);

        // [GIVEN] Mapping Incoming document with Purchase document
        PurchaseHeader.Validate("Incoming Document Entry No.", IncomingDocument."Entry No.");
        PurchaseHeader.Modify(true);

        // [THEN] Save Vendor No and Incoming Document detail
        VendorNo := PurchaseHeader."Buy-from Vendor No.";
        IncomingDocDesc := IncomingDocument.URL;

        // [THEN] Post the Purchsase Invoice
        Codeunit.Run(Codeunit::"Purch.-Post", PurchaseHeader);

        // [THEN] Find Posted Purchase Invocie
        PurchInvoiceHeader.SetFilter("Buy-from Vendor No.", VendorNo);
        PurchInvoiceHeader.FindFirst();

        // [VERIFY] Open the posted purchase invoice and verify Incoming Document will appear on factbox.
        PostedPurchaseInvoice.OpenEdit();
        PostedPurchaseInvoice.GotoRecord(PurchInvoiceHeader);
        PostedPurchaseInvoice.IncomingDocAttachFactBox.Name.AssertEquals(IncomingDocDesc);
    end;

    local procedure Initialize()
    var
        IntermediateDataImport: Record "Intermediate Data Import";
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        TextToAccountMapping: Record "Text-to-Account Mapping";
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Invoice Mapping Tests");

        IntermediateDataImport.DeleteAll();
        TextToAccountMapping.DeleteAll();
        PurchaseHeader.DontNotifyCurrentUserAgain(PurchaseHeader.GetModifyVendorAddressNotificationId());
        PurchaseHeader.DontNotifyCurrentUserAgain(PurchaseHeader.GetModifyPayToVendorAddressNotificationId());
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Invoice Mapping Tests");
        CompanyInfo.Get();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        GLAccount.Get(LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale));
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Debit Acc. for Non-Item Lines", GLAccount."No.");
        PurchasesPayablesSetup.Modify(true);
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Invoice Mapping Tests");
    end;

    local procedure UpdateGLSetupLCYCode(CurrencyCode: Code[10])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."LCY Code" := '';    // to avoid error on updating LCY Code
        GeneralLedgerSetup.Validate("LCY Code", CurrencyCode);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure Setup(var DataExch: Record "Data Exch.")
    var
        BuyFromVendor: Record Vendor;
        Item1: Record Item;
        Item2: Record Item;
        Currency: Record Currency;
    begin
        SetupDataExchTable(DataExch);
        SetupValidIntermediateTable(DataExch, BuyFromVendor, Item1, Item2, Currency, 1);
    end;

    local procedure SetupDataExchTable(var DataExch: Record "Data Exch.")
    var
        IncomingDocument: Record "Incoming Document";
        LibraryIncomingDocuments: Codeunit "Library - Incoming Documents";
        EntryNo: Integer;
    begin
        EntryNo := 1;

        LibraryIncomingDocuments.CreateNewIncomingDocument(IncomingDocument);
        IncomingDocument."Created Doc. Error Msg. Type" := IncomingDocument."Created Doc. Error Msg. Type"::Warning;
        IncomingDocument.Modify();

        if DataExch.FindLast() then
            EntryNo += DataExch."Entry No.";

        DataExch.Init();
        DataExch."Entry No." := EntryNo;
        DataExch."Incoming Entry No." := IncomingDocument."Entry No.";
        DataExch.Insert();
    end;

    local procedure SetupValidIntermediateTable(DataExch: Record "Data Exch."; var BuyFromVendor: Record Vendor; var Item1: Record Item; var Item2: Record Item; var Currency: Record Currency; HeaderRecNo: Integer)
    var
        LineRecNo: Integer;
    begin
        LineRecNo := 2;

        SetupValidIntermediateTableForPurchHdr(DataExch, BuyFromVendor, Currency, HeaderRecNo);

        // Create lines
        InsertItemToIntermediateTable(DataExch, Item1, LineRecNo, HeaderRecNo);
        InsertItemToIntermediateTable(DataExch, Item2, LineRecNo + 1, HeaderRecNo);
        InsertDescriptionLineToIntermediateTable(DataExch, LineRecNo + 2, HeaderRecNo);
    end;

    local procedure SetupValidIntermediateTableForPurchHdr(DataExch: Record "Data Exch."; var BuyFromVendor: Record Vendor; var Currency: Record Currency; HeaderRecNo: Integer)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        InsertIntermediateTableRowWithRecordNo(DataExch, DATABASE::"Purchase Header",
          PurchaseHeader.FieldNo("Document Type"), Format(PurchaseHeader."Document Type"::Invoice, 0, 9), HeaderRecNo, 0);
        Currency.Get(LibraryERM.CreateCurrencyWithRandomExchRates());
        InsertIntermediateTableRowWithRecordNo(DataExch, DATABASE::"Purchase Header",
          PurchaseHeader.FieldNo("Currency Code"), Currency.Code, HeaderRecNo, 0);
        LibraryPurchase.CreateVendor(BuyFromVendor);
        InsertIntermediateTableRowWithRecordNo(DataExch, DATABASE::"Purchase Header"
          , PurchaseHeader.FieldNo("Buy-from Vendor No."), BuyFromVendor."No.", HeaderRecNo, 0);
        InsertIntermediateTableRowWithRecordNo(DataExch, DATABASE::"Purchase Header",
          PurchaseHeader.FieldNo("Vendor Invoice No."),
          LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("Vendor Invoice No."), DATABASE::"Purchase Header")
          , HeaderRecNo, 0);
    end;

    local procedure InsertItemToIntermediateTable(var DataExch: Record "Data Exch."; var Item: Record Item; RowNo: Integer; ParentRecordNo: Integer)
    var
        PurchaseLine: Record "Purchase Line";
        UnitOfMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        DirectUnitCost: Decimal;
        Qty: Decimal;
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", UnitOfMeasure.Code, 1);

        InsertIntermediateTableRowWithRecordNo(DataExch, DATABASE::"Purchase Line",
          PurchaseLine.FieldNo("No."), Item."No.", RowNo, ParentRecordNo);
        InsertIntermediateTableRowWithRecordNo(DataExch, DATABASE::"Purchase Line",
          PurchaseLine.FieldNo(Type), Format(PurchaseLine.Type::Item, 0, 9), RowNo, ParentRecordNo);

        InsertIntermediateTableRowWithRecordNo(DataExch, DATABASE::"Purchase Line",
          PurchaseLine.FieldNo("Unit of Measure Code"), UnitOfMeasure.Code, RowNo, ParentRecordNo);

        Qty := LibraryRandom.RandDecInRange(1, 100, 2);
        InsertIntermediateTableRowWithRecordNo(DataExch, DATABASE::"Purchase Line",
          PurchaseLine.FieldNo(Quantity), Format(Qty, 0, 9), RowNo, ParentRecordNo);

        DirectUnitCost := LibraryRandom.RandDecInRange(1, 100, 2);
        InsertIntermediateTableRowWithRecordNo(DataExch, DATABASE::"Purchase Line",
          PurchaseLine.FieldNo("Direct Unit Cost"), Format(DirectUnitCost, 0, 9), RowNo, ParentRecordNo);

        InsertIntermediateTableRowWithRecordNo(DataExch, DATABASE::"Purchase Line",
          PurchaseLine.FieldNo("Line Discount Amount"),
          Format(LibraryRandom.RandDecInRange(1, Round(Qty * DirectUnitCost / 2, 1, '<'), 2), 0, 9), RowNo, ParentRecordNo);
    end;

    local procedure InsertDescriptionLineToIntermediateTable(var DataExch: Record "Data Exch."; RowNo: Integer; ParentRecordNo: Integer)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Only Type and Description should be filled in for this line
        InsertIntermediateTableRowWithRecordNo(DataExch, DATABASE::"Purchase Line",
          PurchaseLine.FieldNo(Type), Format(PurchaseLine.Type::" ", 0, 9), RowNo, ParentRecordNo);
        InsertIntermediateTableRowWithRecordNo(DataExch, DATABASE::"Purchase Line",
          PurchaseLine.FieldNo(Description),
          LibraryUtility.GenerateRandomCode(PurchaseLine.FieldNo(Description), DATABASE::"Purchase Line"),
          RowNo, ParentRecordNo);
    end;

    local procedure InsertIntermediateTableRowWithRecordNo(DataExch: Record "Data Exch."; TableID: Integer; FieldID: Integer; Value: Text[250]; RecordNo: Integer; ParentRecordNo: Integer)
    begin
        InsertIntermediateTableRowWithRecordNoAndOptional(DataExch, TableID, FieldID, Value, RecordNo, ParentRecordNo, false);
    end;

    local procedure InsertIntermediateTableRowWithRecordNoAndOptional(DataExch: Record "Data Exch."; TableID: Integer; FieldID: Integer; Val: Text[250]; RecordNo: Integer; ParentRecordNo: Integer; IsOptional: Boolean)
    var
        IntermediateDataImport: Record "Intermediate Data Import";
    begin
        IntermediateDataImport.Init();
        IntermediateDataImport."Data Exch. No." := DataExch."Entry No.";
        IntermediateDataImport."Table ID" := TableID;
        IntermediateDataImport."Record No." := RecordNo;
        IntermediateDataImport."Field ID" := FieldID;
        IntermediateDataImport.Value := Val;
        IntermediateDataImport."Validate Only" := IsOptional;
        IntermediateDataImport."Parent Record No." := ParentRecordNo;
        IntermediateDataImport.Insert();
    end;

    local procedure UpdateIntermediateTableRow(DataExch: Record "Data Exch."; TableID: Integer; FieldID: Integer; Val: Text[250])
    var
        IntermediateDataImport: Record "Intermediate Data Import";
    begin
        IntermediateDataImport.SetRange("Data Exch. No.", DataExch."Entry No.");
        IntermediateDataImport.SetRange("Table ID", TableID);
        IntermediateDataImport.SetRange("Field ID", FieldID);
        IntermediateDataImport.FindFirst();
        IntermediateDataImport.Value := Val;
        IntermediateDataImport.Modify();
    end;

    local procedure DeleteIntermediateTableRow(DataExch: Record "Data Exch."; TableID: Integer; FieldID: Integer)
    var
        IntermediateDataImport: Record "Intermediate Data Import";
    begin
        IntermediateDataImport.SetRange("Data Exch. No.", DataExch."Entry No.");
        IntermediateDataImport.SetRange("Table ID", TableID);
        IntermediateDataImport.SetRange("Field ID", FieldID);

        if IntermediateDataImport.FindFirst() then
            IntermediateDataImport.DeleteAll();
    end;

    local procedure AssertPurchaseDoc(DataExch: Record "Data Exch."; BuyFromVendor: Record Vendor; PayToVendor: Record Vendor; Item1: Record Item; Item2: Record Item; Currency: Record Currency; DiscountAmount: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineDiscPerc: Decimal;
    begin
        PurchaseHeader.SetRange("Incoming Document Entry No.", DataExch."Incoming Entry No.");
        Assert.IsTrue(PurchaseHeader.FindFirst(), 'Document was not created.');
        Assert.AreEqual(BuyFromVendor."No.", PurchaseHeader."Buy-from Vendor No.",
          'Vendor no is not correctly set on the Purchase Header.');
        Assert.AreEqual(PayToVendor."No.", PurchaseHeader."Pay-to Vendor No.",
          'Pay-to Vendor no is not correctly set on the Purchase Header.');
        Assert.AreEqual(Currency.Code, PurchaseHeader."Currency Code",
          'Currency Code is not correctly set on the Purchase Header.');

        // Lines
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        Assert.IsTrue(PurchaseLine.Count = 3, '3 Purchase lines should have been created.');

        PurchaseLine.SetRange("No.", Item1."No.");
        Assert.IsTrue(PurchaseLine.FindFirst(), 'Purchase line for Item ' + Item1."No." + ' is not created');
        LineDiscPerc := PurchaseLine."Line Discount %";
        PurchaseLine.Validate("Line Discount Amount", PurchaseLine."Line Discount Amount"); // call actual trigger
        Assert.AreEqual(LineDiscPerc, PurchaseLine."Line Discount %",
          'Line disc % for purchase line with Item ' + Item1."No." + ' is wrong');
        PurchaseLine.SetRange("No.", Item2."No.");
        Assert.IsTrue(PurchaseLine.FindFirst(), 'Purchase line for Item ' + Item2."No." + ' is not created');
        LineDiscPerc := PurchaseLine."Line Discount %";
        PurchaseLine.Validate("Line Discount Amount", PurchaseLine."Line Discount Amount"); // call actual trigger
        Assert.AreEqual(LineDiscPerc, PurchaseLine."Line Discount %",
          'Line disc % for purchase line with Item ' + Item2."No." + ' is wrong');
        // description line
        PurchaseLine.SetRange("No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::" ");
        Assert.IsTrue(PurchaseLine.FindFirst(), 'Purchase line for description only is not created');

        // Invoice discount
        if DiscountAmount <> 0 then begin
            Assert.AreEqual(PurchaseHeader."Invoice Discount Calculation"::Amount,
              PurchaseHeader."Invoice Discount Calculation", 'Wrong invoice discount calculation.');
            Assert.AreEqual(DiscountAmount, PurchaseHeader."Invoice Discount Value", 'Wrong invoice discount value.');
        end;
    end;

    local procedure AssertIntermediateDataIsDeleted(DataExch: Record "Data Exch.")
    var
        IntermediateDataImport: Record "Intermediate Data Import";
        DataExchField: Record "Data Exch. Field";
    begin
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        Assert.IsFalse(DataExchField.FindFirst(), StrSubstNo(TableNotEmptiedErr, DataExchField.TableCaption(), DataExch."Entry No."));
        IntermediateDataImport.SetRange("Data Exch. No.", DataExch."Entry No.");
        Assert.IsFalse(
          IntermediateDataImport.FindFirst(), StrSubstNo(TableNotEmptiedErr, IntermediateDataImport.TableCaption(), DataExch."Entry No."));
    end;

    local procedure CalculateTotalsForCreatedDoc(DataExch: Record "Data Exch."): Decimal
    var
        PurchaseHeader: Record "Purchase Header";
        CurrentPurchaseLine: Record "Purchase Line";
        TempTotalPurchaseLine: Record "Purchase Line" temporary;
        DocumentTotals: Codeunit "Document Totals";
        VATAmount: Decimal;
    begin
        // prepare variables needed for calculation of totals
        PurchaseHeader.SetRange("Incoming Document Entry No.", DataExch."Incoming Entry No.");
        if PurchaseHeader.FindFirst() then begin
            VATAmount := 0;
            TempTotalPurchaseLine.Init();
            CurrentPurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
            CurrentPurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
            if CurrentPurchaseLine.FindFirst() then begin
                DocumentTotals.PurchaseCalculateTotalsWithInvoiceRounding(CurrentPurchaseLine, VATAmount, TempTotalPurchaseLine);
                exit(TempTotalPurchaseLine."Amount Including VAT");
            end;
        end;
        exit(0);
    end;

    local procedure AssertExpectedError(DataExch: Record "Data Exch."; MessageType: Option; Message: Text)
    var
        ErrorMessage: Record "Error Message";
        IncomingDocument: Record "Incoming Document";
    begin
        IncomingDocument.Get(DataExch."Incoming Entry No.");
        ErrorMessage.SetRange("Context Record ID", IncomingDocument.RecordId);
        ErrorMessage.SetFilter("Message", StrSubstNo('*%1*', Message));
        ErrorMessage.SetRange("Message Type", MessageType);
        Assert.IsTrue(not ErrorMessage.IsEmpty(), StrSubstNo('Expected message ''%1'' not found', Message));
    end;

    local procedure AssertWarning(DataExch: Record "Data Exch."; WarningMessage: Text)
    var
        ErrorMessage: Record "Error Message";
    begin
        AssertExpectedError(DataExch, ErrorMessage."Message Type"::Warning, WarningMessage);
    end;
}

