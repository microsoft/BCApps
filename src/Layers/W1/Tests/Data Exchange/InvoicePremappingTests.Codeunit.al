codeunit 139157 "Invoice Premapping Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Data Exchange] [Intermediate Data Import] [Pre-map Incoming Purch. Doc]
    end;

    var
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemReference: Codeunit "Library - Item Reference";
        InvalidCompanyInfoGLNTxt: Label 'The customer''s GLN %1 on the incoming document does not match the GLN in the Company Information window.', Locked = true;
        InvalidCompanyInfoVATRegNoTxt: Label 'The customer''s VAT registration number %1 on the incoming document does not match the VAT Registration No. in the Company Information window.', Locked = true;
        CurrencyCodeMissingTxt: Label 'The currency code is missing on the incoming document.', Locked = true;
        CurrencyCodeDifferentTxt: Label 'The currency code %1 must not be different from the currency code %2 on the incoming document.', Locked = true;
        ItemCurrencyCodeDifferentTxt: Label 'The currency code %1 on invoice line no. %2 must not be different from the currency code %3 on the incoming document.', Locked = true;
        BuyFromVendorNotFoundTxt: Label 'Cannot find buy-from vendor ''%1'' based on the vendor''s GLN %2 or VAT registration number %3 on the incoming document. Make sure that a card for the vendor exists with the corresponding GLN or VAT Registration No.', Locked = true;
        PayToVendorNotFoundTxt: Label 'Cannot find pay-to vendor ''%1'' based on the vendor''s GLN %2 or VAT registration number %3 on the incoming document. Make sure that a card for the vendor exists with the corresponding GLN or VAT Registration No.', Locked = true;
        ItemNotFoundTxt: Label 'Cannot find item ''%1'' based on the vendor %2 item number %3 or GTIN %4 on the incoming document. Make sure that a card for the item exists with the corresponding item reference or GTIN.', Locked = true;
        ItemNotFoundByGTINErr: Label 'Cannot find item ''%1'' based on GTIN %2 on the incoming document. Make sure that a card for the item exists with the corresponding GTIN.', Comment = '%1 Vendor item name (e.g. Bicycle - may be another language),%2 item bar code (GTIN)';
        ItemNotFoundByVendorItemNoErr: Label 'Cannot find item ''%1'' based on the vendor %2 item number %3 on the incoming document. Make sure that a card for the item exists with the corresponding item reference.', Comment = '%1 Vendor item name (e.g. Bicycle - may be another language),%2 Vendor''''s number,%3 Vendor''''s item number';
        UOMNotFoundTxt: Label 'Cannot find unit of measure %1. Make sure that the unit of measure exists.', Comment = '%1 International Standard Code or Code or Description for Unit of Measure';
        VendorNotFoundByNameAndAddressTxt: Label 'Cannot find vendor based on the vendor''s name ''%1'' and street name ''%2'' on the incoming document. Make sure that a card for the vendor exists with the corresponding name.', Locked = true;
        InvalidCompanyInfoNameTxt: Label 'The customer name ''%1'' on the incoming document does not match the name in the Company Information window.', Comment = '%1 = customer name';
        InvalidGLNTxt: Label 'BADGLN', Locked = true;
        InvalidVATRegNoTxt: Label 'BADVATREGNO', Locked = true;
        InvalidCurrencyTxt: Label 'BADCURRENCY', Locked = true;
        InvalidVATAmtTxt: Label 'BADVAT', Locked = true;
        InvalidItemTxt: Label 'BADITEM', Locked = true;
        ItemNameTxt: Label 'ITEMNAME', Locked = true;
        InvalidUOMTxt: Label 'BADUOM', Locked = true;
        LibraryRandom: Codeunit "Library - Random";
        InvalidItem2Txt: Label 'BADITEM2', Locked = true;
        ExpectedErrorMsgNotFoundErr: Label 'Expected error message ''%1'' was not logged in table ''%2''.', Comment = '%1 - error message,%2 - table caption';
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        YouMustFirstPostTheRelatedInvoiceErr: Label 'The incoming document references invoice %1 from the vendor. You must post related purchase invoice %2 before you create a new purchase document from this incoming document.', Comment = '%1 - vendor invoice no.,%2 posted purchase invoice no.';
        UnableToFindRelatedInvoiceErr: Label 'The incoming document references invoice %1 from the vendor, but no purchase invoice exists for %1.', Comment = '%1 - vendor invoice no.';
        UnableToFindAppropriateAccountErr: Label 'Cannot find an appropriate G/L account for the line with description ''%1''. Choose the Map Text to Account button, and then map the core part of ''%1'' to the relevant G/L account.', Comment = '%1 - arbitrary text';

    local procedure SetupTestTables(var DataExch: Record "Data Exch.")
    var
        BuyFromVendor: Record Vendor;
        PayToVendor: Record Vendor;
        Item1: Record Item;
        Item2: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        Qty: Decimal;
        Description: Text[100];
    begin
        SetupDataExchTable(DataExch);
        SetupValidIntermediateTable(DataExch, BuyFromVendor, PayToVendor, Item1, Item2, UnitOfMeasure, Qty, Description);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSuccessfulInvoicePremappingWithGLNAndItemBarCode()
    var
        BuyFromVendor: Record Vendor;
        PayToVendor: Record Vendor;
        Item1: Record Item;
        Item2: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        DataExch: Record "Data Exch.";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Qty: Decimal;
        Description: Text[100];
    begin
        // Setup
        Initialize();
        SetupDataExchTable(DataExch);
        SetupValidIntermediateTable(DataExch, BuyFromVendor, PayToVendor, Item1, Item2, UnitOfMeasure, Qty, Description);

        // Excercise
        CODEUNIT.Run(CODEUNIT::"Pre-map Incoming Purch. Doc", DataExch);

        // Verify
        Assert.AreEqual(BuyFromVendor."No.",
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."), 1), '');
        Assert.AreEqual(PayToVendor."No.",
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Pay-to Vendor No."), 1), '');
        Assert.AreEqual(Item1."No.",
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo("No."), 2), '');
        Assert.AreEqual(UnitOfMeasure.Code,
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo("Unit of Measure Code"), 2), '');
        Assert.AreEqual(Format(Qty, 0, 9),
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo(Quantity), 2), '');
        Assert.AreEqual(Item2."No.",
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo("No."), 3), '');
        Assert.AreEqual(UnitOfMeasure.Code,
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo("Unit of Measure Code"), 3), '');
        Assert.AreEqual(Format(Qty, 0, 9),
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo(Quantity), 3), '');
        Assert.AreEqual(Description,
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo(Description), 4), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSuccessfulInvoicePremappingWithVATRegNoAndVendorItemNo()
    var
        BuyFromVendor: Record Vendor;
        PayToVendor: Record Vendor;
        Item1: Record Item;
        Item2: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        DataExch: Record "Data Exch.";
        CompanyInfo: Record "Company Information";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        Qty: Decimal;
        Description: Text[100];
    begin
        // Setup
        Initialize();
        SetupDataExchTable(DataExch);
        SetupValidIntermediateTable(DataExch, BuyFromVendor, PayToVendor, Item1, Item2, UnitOfMeasure, Qty, Description);

        // Remove Item Bar Codes and GLN to force VAT Reg No Lookup and Item Reference Table Lookup
        UpdateIntermediateTableRow(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo("No."), '');
        UpdateIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."), InvalidGLNTxt);
        UpdateIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Pay-to Vendor No."), InvalidGLNTxt);
        UpdateIntermediateTableRow(DataExch, DATABASE::"Company Information", CompanyInfo.FieldNo(GLN), '');

        // Excercise
        CODEUNIT.Run(CODEUNIT::"Pre-map Incoming Purch. Doc", DataExch);

        // Verify
        Assert.AreEqual(BuyFromVendor."No.",
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."), 1), '');
        Assert.AreEqual(PayToVendor."No.",
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Pay-to Vendor No."), 1), '');
        Assert.AreEqual(Item1."No.",
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo("No."), 2), '');
        Assert.AreEqual(UnitOfMeasure.Code,
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo("Unit of Measure Code"), 2), '');
        Assert.AreEqual(Format(Qty, 0, 9),
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo(Quantity), 2), '');
        Assert.AreEqual(Item2."No.",
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo("No."), 3), '');
        Assert.AreEqual(UnitOfMeasure.Code,
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo("Unit of Measure Code"), 3), '');
        Assert.AreEqual(Format(Qty, 0, 9),
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo(Quantity), 3), '');
        Assert.AreEqual(Description,
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo(Description), 4), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSuccessfulInvoicePremappingWithVATRegNoAndVendorItemNoDeleted()
    var
        BuyFromVendor: Record Vendor;
        PayToVendor: Record Vendor;
        Item1: Record Item;
        Item2: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        DataExch: Record "Data Exch.";
        CompanyInfo: Record "Company Information";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        Qty: Decimal;
        Description: Text[100];
    begin
        // Setup
        Initialize();
        SetupDataExchTable(DataExch);
        SetupValidIntermediateTable(DataExch, BuyFromVendor, PayToVendor, Item1, Item2, UnitOfMeasure, Qty, Description);

        // Remove Item Bar Codes and GLN to force VAT Reg No Lookup and Item Reference Table Lookup
        DeleteIntermediateTableRow(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo("No."));
        UpdateIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."), InvalidGLNTxt);
        UpdateIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Pay-to Vendor No."), InvalidGLNTxt);
        DeleteIntermediateTableRow(DataExch, DATABASE::"Company Information", CompanyInfo.FieldNo(GLN));

        // Excercise
        CODEUNIT.Run(CODEUNIT::"Pre-map Incoming Purch. Doc", DataExch);

        // Verify
        Assert.AreEqual(BuyFromVendor."No.",
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."), 1), '');
        Assert.AreEqual(PayToVendor."No.",
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Pay-to Vendor No."), 1), '');
        Assert.AreEqual(Item1."No.",
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo("No."), 2), '');
        Assert.AreEqual(UnitOfMeasure.Code,
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo("Unit of Measure Code"), 2), '');
        Assert.AreEqual(Format(Qty, 0, 9),
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo(Quantity), 2), '');
        Assert.AreEqual(Item2."No.",
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo("No."), 3), '');
        Assert.AreEqual(UnitOfMeasure.Code,
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo("Unit of Measure Code"), 3), '');
        Assert.AreEqual(Format(Qty, 0, 9),
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo(Quantity), 3), '');
        Assert.AreEqual(Description,
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo(Description), 4), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSuccessfulInvoicePremappingWithUnknownGLNAndKnownVATRegNoAndVendorItemNo()
    var
        BuyFromVendor: Record Vendor;
        PayToVendor: Record Vendor;
        Item1: Record Item;
        Item2: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        DataExch: Record "Data Exch.";
        CompanyInfo: Record "Company Information";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        Qty: Decimal;
        Description: Text[100];
    begin
        // Setup
        Initialize();
        SetupDataExchTable(DataExch);
        SetupValidIntermediateTable(DataExch, BuyFromVendor, PayToVendor, Item1, Item2, UnitOfMeasure, Qty, Description);

        // Remove Item Bar Codes and GLN to force VAT Reg No Lookup and Item Reference Table Lookup
        UpdateIntermediateTableRow(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo("No."), '');
        UpdateIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."), '');
        UpdateIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Pay-to Vendor No."), '');
        UpdateIntermediateTableRow(DataExch, DATABASE::"Company Information", CompanyInfo.FieldNo(GLN), '');

        // Excercise
        CODEUNIT.Run(CODEUNIT::"Pre-map Incoming Purch. Doc", DataExch);

        // Verify
        Assert.AreEqual(BuyFromVendor."No.",
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."), 1), '');
        Assert.AreEqual(PayToVendor."No.",
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Pay-to Vendor No."), 1), '');
        Assert.AreEqual(Item1."No.",
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo("No."), 2), '');
        Assert.AreEqual(UnitOfMeasure.Code,
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo("Unit of Measure Code"), 2), '');
        Assert.AreEqual(Format(Qty, 0, 9),
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo(Quantity), 2), '');
        Assert.AreEqual(Item2."No.",
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo("No."), 3), '');
        Assert.AreEqual(UnitOfMeasure.Code,
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo("Unit of Measure Code"), 3), '');
        Assert.AreEqual(Format(Qty, 0, 9),
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo(Quantity), 3), '');
        Assert.AreEqual(Description,
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo(Description), 4), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSuccessfulInvoicePremappingWithVendorDataFromIncomingDocument()
    var
        IncomingDocument: Record "Incoming Document";
        VendorBankAccount: Record "Vendor Bank Account";
        DataExch: Record "Data Exch.";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        GLEntry: Record "G/L Entry";
    begin
        // Setup
        Initialize();
        SetupTestTables(DataExch);
        IncomingDocument.Get(DataExch."Incoming Entry No.");

        // Excercise
        ModifyOCRData(IncomingDocument);
        CODEUNIT.Run(CODEUNIT::"Pre-map Incoming Purch. Doc", DataExch);

        // Verify that modified OCR values are in the intermediate data import table
        IncomingDocument.Get(DataExch."Incoming Entry No.");
        Assert.AreEqual(IncomingDocument."Vendor Name",
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor Name"), 1), '');
        Assert.AreEqual(IncomingDocument."Vendor VAT Registration No.",
          GetIntermediateTableRow(DataExch, DATABASE::Vendor, Vendor.FieldNo("VAT Registration No."), 1), '');
        Assert.AreEqual(IncomingDocument."Vendor IBAN",
          GetIntermediateTableRow(DataExch, DATABASE::"Vendor Bank Account", VendorBankAccount.FieldNo(IBAN), 1), '');
        Assert.AreEqual(IncomingDocument."Vendor Bank Branch No.",
          GetIntermediateTableRow(DataExch, DATABASE::"Vendor Bank Account", VendorBankAccount.FieldNo("Bank Branch No."), 1), '');
        Assert.AreEqual(IncomingDocument."Vendor Bank Account No.",
          GetIntermediateTableRow(DataExch, DATABASE::"Vendor Bank Account", VendorBankAccount.FieldNo("Bank Account No."), 1), '');
        Assert.AreEqual(IncomingDocument."Vendor Invoice No.",
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Vendor Invoice No."), 1), '');
        Assert.AreEqual(IncomingDocument."Currency Code",
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Currency Code"), 1), '');
        Assert.AreEqual(Format(IncomingDocument."Document Date", 0, 9),
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Document Date"), 1), '');
        Assert.AreEqual(Format(IncomingDocument."Due Date", 0, 9),
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Due Date"), 1), '');
        Assert.AreEqual(IncomingDocument."Order No.",
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Vendor Order No."), 1), '');
        Assert.AreEqual(DelChr(Format(IncomingDocument."Amount Incl. VAT", 0, 9), '>', '0'),
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Amount Including VAT"), 1), '');
        Assert.AreEqual(DelChr(Format(IncomingDocument."Amount Excl. VAT", 0, 9), '>', '0'),
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo(Amount), 1), '');
        Assert.AreEqual(DelChr(Format(IncomingDocument."VAT Amount", 0, 9), '>', '0'),
          GetIntermediateTableRow(DataExch, DATABASE::"G/L Entry", GLEntry.FieldNo("VAT Amount"), 1), '');
        Assert.IsTrue(IncomingDocument."OCR Data Corrected", '');
    end;

    [Test]
    [HandlerFunctions('HandleCompanyInformation')]
    [Scope('OnPrem')]
    procedure TestCompanyInfoGLNMismatch()
    var
        DataExch: Record "Data Exch.";
        CompanyInformation: Record "Company Information";
    begin
        // Setup
        Initialize();
        SetupTestTables(DataExch);

        // modify gln value in intermediate table
        UpdateIntermediateTableRow(DataExch, DATABASE::"Company Information", CompanyInformation.FieldNo(GLN), InvalidGLNTxt);

        // Excercise
        CODEUNIT.Run(CODEUNIT::"Pre-map Incoming Purch. Doc", DataExch);
        AssertExpectedError(DataExch, StrSubstNo(InvalidCompanyInfoGLNTxt, InvalidGLNTxt));
    end;

    [Test]
    [HandlerFunctions('HandleCompanyInformation')]
    [Scope('OnPrem')]
    procedure TestCompanyInfoVATMismatch()
    var
        DataExch: Record "Data Exch.";
        CompanyInformation: Record "Company Information";
    begin
        // Setup
        Initialize();
        SetupTestTables(DataExch);

        // modify vat reg no value in intermediate table
        UpdateIntermediateTableRow(DataExch, DATABASE::"Company Information", CompanyInformation.FieldNo("VAT Registration No."),
          InvalidVATRegNoTxt);

        // Excercise
        CODEUNIT.Run(CODEUNIT::"Pre-map Incoming Purch. Doc", DataExch);

        AssertExpectedError(DataExch, StrSubstNo(InvalidCompanyInfoVATRegNoTxt, InvalidVATRegNoTxt));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCompanyInfoVATTwoLinesWithSecondCorrect()
    var
        DataExch: Record "Data Exch.";
        CompanyInformation: Record "Company Information";
    begin
        // [SCENARIO 302420] No error on import two Intermediate Data Import lines of company's VAT Reg No. when correct value is in the second line
        Initialize();

        // [GIVEN] Data Exchange Definition with Intermediate Data Import of two lines for company's VAT Registration No.
        // [GIVEN] First line has tax scheme ID value '45678911', second line has VAT Registration No. value 'NL012345678'
        SetupTestTables(DataExch);
        DeleteIntermediateTableRow(DataExch, DATABASE::"Company Information", CompanyInformation.FieldNo("VAT Registration No."));
        CompanyInformation.Get();
        CompanyInformation."VAT Registration No." := LibraryUtility.GenerateGUID();
        CompanyInformation.Modify();
        InsertIntermediateTableRow(
          DataExch, DATABASE::"Company Information", CompanyInformation.FieldNo("VAT Registration No."), InvalidVATRegNoTxt);
        InsertIntermediateTableRow(
          DataExch, DATABASE::"Company Information", CompanyInformation.FieldNo("VAT Registration No."),
          CompanyInformation."VAT Registration No.");

        // [WHEN] Run "Pre-map Incoming Purch. Doc"
        CODEUNIT.Run(CODEUNIT::"Pre-map Incoming Purch. Doc", DataExch);

        // [THEN] No error messages generated for company's "VAT Registration No." field
        VerifyNoErrorMessages(
          DataExch."Incoming Entry No.", DATABASE::"Company Information", CompanyInformation.FieldNo("VAT Registration No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCompanyInfoVATTwoLinesWithFirstCorrect()
    var
        DataExch: Record "Data Exch.";
        CompanyInformation: Record "Company Information";
    begin
        // [SCENARIO 302420] No error on import two Intermediate Data Import lines of company's VAT Reg No. when correct value is in the first line
        Initialize();

        // [GIVEN] Data Exchange Definition with Intermediate Data Import of two lines for company's VAT Registration No.
        // [GIVEN] First line has VAT Registration No. value 'NL012345678', second line has tax scheme ID value '45678911'
        SetupTestTables(DataExch);
        DeleteIntermediateTableRow(DataExch, DATABASE::"Company Information", CompanyInformation.FieldNo("VAT Registration No."));
        CompanyInformation.Get();
        CompanyInformation."VAT Registration No." := LibraryUtility.GenerateGUID();
        CompanyInformation.Modify();
        InsertIntermediateTableRow(
          DataExch, DATABASE::"Company Information", CompanyInformation.FieldNo("VAT Registration No."),
          CompanyInformation."VAT Registration No.");
        InsertIntermediateTableRow(
          DataExch, DATABASE::"Company Information", CompanyInformation.FieldNo("VAT Registration No."), InvalidVATRegNoTxt);

        // [WHEN] Run "Pre-map Incoming Purch. Doc"
        CODEUNIT.Run(CODEUNIT::"Pre-map Incoming Purch. Doc", DataExch);

        // [THEN] No error messages generated for company's "VAT Registration No." field
        VerifyNoErrorMessages(
          DataExch."Incoming Entry No.", DATABASE::"Company Information", CompanyInformation.FieldNo("VAT Registration No."));
    end;

    [Test]
    [HandlerFunctions('HandleCompanyInformation')]
    [Scope('OnPrem')]
    procedure TestCompanyInfoNameMismatch()
    var
        DataExch: Record "Data Exch.";
        CompanyInformation: Record "Company Information";
    begin
        // Setup
        Initialize();
        SetupTestTables(DataExch);

        // modify gln value in intermediate table
        DeleteIntermediateTableRow(DataExch, DATABASE::"Company Information", CompanyInformation.FieldNo(GLN));
        DeleteIntermediateTableRow(DataExch, DATABASE::"Company Information", CompanyInformation.FieldNo("VAT Registration No."));
        UpdateIntermediateTableRow(DataExch, DATABASE::"Company Information", CompanyInformation.FieldNo(Name), InvalidGLNTxt);

        // Excercise
        CODEUNIT.Run(CODEUNIT::"Pre-map Incoming Purch. Doc", DataExch);
        AssertExpectedError(DataExch, StrSubstNo(InvalidCompanyInfoNameTxt, InvalidGLNTxt));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDocumentCurrencyCodeMissing()
    var
        DataExch: Record "Data Exch.";
        PurchaseHeader: Record "Purchase Header";
    begin
        // Setup
        Initialize();
        SetupTestTables(DataExch);

        // remove document currency value in intermediate table
        UpdateIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Currency Code"), '');

        // Excercise
        CODEUNIT.Run(CODEUNIT::"Pre-map Incoming Purch. Doc", DataExch);
        AssertExpectedError(DataExch, StrSubstNo(CurrencyCodeMissingTxt));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCurrencyMismatchOnHeader()
    var
        DataExch: Record "Data Exch.";
        PurchaseHeader: Record "Purchase Header";
        DocumentCurrency: Text;
    begin
        // Setup
        Initialize();
        SetupTestTables(DataExch);
        DocumentCurrency := GetIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Currency Code"), 1);

        // insert intermediate table row with invalid currency
        InsertIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Tax Area Code"),
          InvalidCurrencyTxt);

        // Excercise
        CODEUNIT.Run(CODEUNIT::"Pre-map Incoming Purch. Doc", DataExch);
        AssertExpectedError(DataExch, StrSubstNo(CurrencyCodeDifferentTxt, InvalidCurrencyTxt, DocumentCurrency));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestItemCurrencyMismatch()
    var
        DataExch: Record "Data Exch.";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        DocumentCurrency: Text;
    begin
        // Setup
        Initialize();
        SetupTestTables(DataExch);
        DocumentCurrency := GetIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Currency Code"), 1);

        // modify item currency value in intermediate table
        UpdateIntermediateTableRow(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo("Currency Code"), InvalidCurrencyTxt);

        // Excercise
        CODEUNIT.Run(CODEUNIT::"Pre-map Incoming Purch. Doc", DataExch);
        AssertExpectedError(DataExch, StrSubstNo(ItemCurrencyCodeDifferentTxt, InvalidCurrencyTxt, 2, DocumentCurrency));
    end;

    [Test]
    [HandlerFunctions('HandleVendorList')]
    [Scope('OnPrem')]
    procedure TestBuyFromUnknownGLNEmptyVATRegNo()
    var
        DataExch: Record "Data Exch.";
        PurchaseHeader: Record "Purchase Header";
        BuyFromVendor: Record Vendor;
        PayToVendor: Record Vendor;
        Item1: Record Item;
        Item2: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        Qty: Decimal;
        Description: Text[100];
    begin
        // Setup
        Initialize();
        SetupDataExchTable(DataExch);
        SetupValidIntermediateTable(DataExch, BuyFromVendor, PayToVendor, Item1, Item2, UnitOfMeasure, Qty, Description);

        // modify gln value in intermediate table
        UpdateIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."), InvalidGLNTxt);
        UpdateIntermediateTableRow(DataExch, DATABASE::Vendor, BuyFromVendor.FieldNo("VAT Registration No."), '');

        // Excercise
        CODEUNIT.Run(CODEUNIT::"Pre-map Incoming Purch. Doc", DataExch);

        // Verify
        AssertExpectedError(DataExch, StrSubstNo(BuyFromVendorNotFoundTxt, BuyFromVendor.Name, InvalidGLNTxt, ''));
    end;

    [Test]
    [HandlerFunctions('HandleVendorList')]
    [Scope('OnPrem')]
    procedure TestBuyFromUnknownGLNNoVATRegNo()
    var
        DataExch: Record "Data Exch.";
        PurchaseHeader: Record "Purchase Header";
        BuyFromVendor: Record Vendor;
        PayToVendor: Record Vendor;
        Item1: Record Item;
        Item2: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        Qty: Decimal;
        Description: Text[100];
    begin
        // Setup
        Initialize();
        SetupDataExchTable(DataExch);
        SetupValidIntermediateTable(DataExch, BuyFromVendor, PayToVendor, Item1, Item2, UnitOfMeasure, Qty, Description);

        // modify gln value in intermediate table
        UpdateIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."), InvalidGLNTxt);
        DeleteIntermediateTableRow(DataExch, DATABASE::Vendor, BuyFromVendor.FieldNo("VAT Registration No."));

        // Excercise
        CODEUNIT.Run(CODEUNIT::"Pre-map Incoming Purch. Doc", DataExch);

        // Verify
        AssertExpectedError(DataExch, StrSubstNo(BuyFromVendorNotFoundTxt, BuyFromVendor.Name, InvalidGLNTxt, ''));
    end;

    [Test]
    [HandlerFunctions('HandleVendorList')]
    [Scope('OnPrem')]
    procedure TestBuyFromNoGLNUnknownVATRegNo()
    var
        DataExch: Record "Data Exch.";
        PurchaseHeader: Record "Purchase Header";
        BuyFromVendor: Record Vendor;
        PayToVendor: Record Vendor;
        Item1: Record Item;
        Item2: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        Qty: Decimal;
        Description: Text[100];
    begin
        // Setup
        Initialize();
        SetupDataExchTable(DataExch);
        SetupValidIntermediateTable(DataExch, BuyFromVendor, PayToVendor, Item1, Item2, UnitOfMeasure, Qty, Description);

        // modify vat reg no value in intermediate table
        UpdateIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."), '');
        UpdateIntermediateTableRow(DataExch, DATABASE::Vendor, BuyFromVendor.FieldNo("VAT Registration No."), InvalidVATAmtTxt);

        // Excercise
        CODEUNIT.Run(CODEUNIT::"Pre-map Incoming Purch. Doc", DataExch);

        // Verify
        AssertExpectedError(DataExch, StrSubstNo(BuyFromVendorNotFoundTxt, BuyFromVendor.Name, '', InvalidVATAmtTxt));
    end;

    [Test]
    [HandlerFunctions('HandleVendorList')]
    [Scope('OnPrem')]
    procedure TestBuyFromUnknownGLNUnknownVATRegNo()
    var
        DataExch: Record "Data Exch.";
        PurchaseHeader: Record "Purchase Header";
        BuyFromVendor: Record Vendor;
        PayToVendor: Record Vendor;
        Item1: Record Item;
        Item2: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        Qty: Decimal;
        Description: Text[100];
    begin
        // Setup
        Initialize();
        SetupDataExchTable(DataExch);
        SetupValidIntermediateTable(DataExch, BuyFromVendor, PayToVendor, Item1, Item2, UnitOfMeasure, Qty, Description);

        // modify gln and vat reg no value in intermediate table
        UpdateIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."), InvalidGLNTxt);
        UpdateIntermediateTableRow(DataExch, DATABASE::Vendor, BuyFromVendor.FieldNo("VAT Registration No."), InvalidVATAmtTxt);

        // Excercise
        CODEUNIT.Run(CODEUNIT::"Pre-map Incoming Purch. Doc", DataExch);
        AssertExpectedError(DataExch, StrSubstNo(BuyFromVendorNotFoundTxt, BuyFromVendor.Name, InvalidGLNTxt, InvalidVATAmtTxt));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBuyFromWithNoGLNAndNoVATRegNo()
    var
        BuyFromVendor: Record Vendor;
        PayToVendor: Record Vendor;
        Item1: Record Item;
        Item2: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        DataExch: Record "Data Exch.";
        PurchaseHeader: Record "Purchase Header";
        Qty: Decimal;
        Description: Text[100];
    begin
        // Setup
        Initialize();
        SetupDataExchTable(DataExch);
        SetupValidIntermediateTable(DataExch, BuyFromVendor, PayToVendor, Item1, Item2, UnitOfMeasure, Qty, Description);

        // modify gln and vat reg value in intermediate table
        DeleteIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."));
        DeleteIntermediateTableRow(DataExch, DATABASE::Vendor, BuyFromVendor.FieldNo("VAT Registration No."));

        // Excercise - this is valid
        CODEUNIT.Run(CODEUNIT::"Pre-map Incoming Purch. Doc", DataExch);

        // Verify
        // when GLN and VAT Reg. No are not there - the vendor will be found by name and address
        Assert.AreEqual(BuyFromVendor."No.",
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."), 1), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBuyFromFoundByIBAN()
    var
        BuyFromVendor: Record Vendor;
        PayToVendor: Record Vendor;
        Item1: Record Item;
        Item2: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        DataExch: Record "Data Exch.";
        PurchaseHeader: Record "Purchase Header";
        VendorBankAccount: Record "Vendor Bank Account";
        Qty: Decimal;
        Description: Text[100];
    begin
        // Setup
        Initialize();
        SetupDataExchTable(DataExch);
        SetupValidIntermediateTable(DataExch, BuyFromVendor, PayToVendor, Item1, Item2, UnitOfMeasure, Qty, Description);
        VendorBankAccount.Init();
        VendorBankAccount."Vendor No." := BuyFromVendor."No.";
        VendorBankAccount.Code := LibraryUtility.GenerateGUID();
        VendorBankAccount.IBAN := LibraryUtility.GenerateGUID();
        VendorBankAccount.Insert(true);

        // delete gln and vat reg value from intermediate table
        DeleteIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."));
        DeleteIntermediateTableRow(DataExch, DATABASE::Vendor, BuyFromVendor.FieldNo("VAT Registration No."));
        InsertIntermediateTableRow(DataExch, DATABASE::"Vendor Bank Account", VendorBankAccount.FieldNo(IBAN), VendorBankAccount.IBAN);

        // Excercise - this is valid
        CODEUNIT.Run(CODEUNIT::"Pre-map Incoming Purch. Doc", DataExch);

        // Verify
        // when GLN and VAT Reg. No are not there - the vendor will be found by IBAN
        Assert.AreEqual(BuyFromVendor."No.",
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."), 1), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBuyFromFoundByBankAccountNo()
    var
        BuyFromVendor: Record Vendor;
        PayToVendor: Record Vendor;
        Item1: Record Item;
        Item2: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        DataExch: Record "Data Exch.";
        PurchaseHeader: Record "Purchase Header";
        VendorBankAccount: Record "Vendor Bank Account";
        Qty: Decimal;
        Description: Text[100];
    begin
        // Setup
        Initialize();
        SetupDataExchTable(DataExch);
        SetupValidIntermediateTable(DataExch, BuyFromVendor, PayToVendor, Item1, Item2, UnitOfMeasure, Qty, Description);
        VendorBankAccount.Init();
        VendorBankAccount."Vendor No." := BuyFromVendor."No.";
        VendorBankAccount.Code := LibraryUtility.GenerateGUID();
        VendorBankAccount."Bank Branch No." := LibraryUtility.GenerateGUID();
        VendorBankAccount."Bank Account No." := LibraryUtility.GenerateGUID();
        VendorBankAccount.Insert(true);

        // delete gln and vat reg value from intermediate table
        DeleteIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."));
        DeleteIntermediateTableRow(DataExch, DATABASE::Vendor, BuyFromVendor.FieldNo("VAT Registration No."));
        InsertIntermediateTableRow(DataExch, DATABASE::"Vendor Bank Account",
          VendorBankAccount.FieldNo("Bank Branch No."), VendorBankAccount."Bank Branch No.");
        InsertIntermediateTableRow(DataExch, DATABASE::"Vendor Bank Account",
          VendorBankAccount.FieldNo("Bank Account No."), VendorBankAccount."Bank Account No.");

        // Excercise - this is valid
        CODEUNIT.Run(CODEUNIT::"Pre-map Incoming Purch. Doc", DataExch);

        // Verify
        // when GLN and VAT Reg. No are not there - the vendor will be found by bank account no
        Assert.AreEqual(BuyFromVendor."No.",
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."), 1), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBuyFromFoundByPhoneNo()
    var
        BuyFromVendor: Record Vendor;
        PayToVendor: Record Vendor;
        Item1: Record Item;
        Item2: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        DataExch: Record "Data Exch.";
        PurchaseHeader: Record "Purchase Header";
        Qty: Decimal;
        Description: Text[100];
    begin
        // Setup
        Initialize();
        SetupDataExchTable(DataExch);
        SetupValidIntermediateTable(DataExch, BuyFromVendor, PayToVendor, Item1, Item2, UnitOfMeasure, Qty, Description);
        BuyFromVendor."Phone No." := Format(LibraryRandom.RandIntInRange(1000000, 9999999));
        BuyFromVendor.Modify(true);

        // delete gln and vat reg value from intermediate table
        DeleteIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."));
        DeleteIntermediateTableRow(DataExch, DATABASE::Vendor, BuyFromVendor.FieldNo("VAT Registration No."));
        InsertIntermediateTableRow(DataExch, DATABASE::Vendor,
          BuyFromVendor.FieldNo("Phone No."), BuyFromVendor."Phone No.");

        // Excercise - this is valid
        CODEUNIT.Run(CODEUNIT::"Pre-map Incoming Purch. Doc", DataExch);

        // Verify
        // when GLN and VAT Reg. No are not there - the vendor will be found by phone no
        Assert.AreEqual(BuyFromVendor."No.",
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."), 1), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBuyFromWithNoGLNAndNoVATRegNoCaseInsensitive()
    var
        BuyFromVendor: Record Vendor;
        PayToVendor: Record Vendor;
        Item1: Record Item;
        Item2: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        DataExch: Record "Data Exch.";
        PurchaseHeader: Record "Purchase Header";
        Qty: Decimal;
        Description: Text[100];
    begin
        // Setup
        Initialize();
        SetupDataExchTable(DataExch);
        SetupValidIntermediateTable(DataExch, BuyFromVendor, PayToVendor, Item1, Item2, UnitOfMeasure, Qty, Description);

        // lowercase vendor name
        BuyFromVendor.Name := LowerCase(BuyFromVendor.Name);
        BuyFromVendor.Modify();

        // modify gln and vat reg value in intermediate table. also, modify vendor name to be uppercase
        DeleteIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."));
        DeleteIntermediateTableRow(DataExch, DATABASE::Vendor, BuyFromVendor.FieldNo("VAT Registration No."));
        UpdateIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor Name"),
          UpperCase(BuyFromVendor.Name));

        // Excercise - this is valid
        CODEUNIT.Run(CODEUNIT::"Pre-map Incoming Purch. Doc", DataExch);

        // Verify
        // when GLN and VAT Reg. No are not there - the vendor will be found by name and address
        Assert.AreEqual(BuyFromVendor."No.",
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."), 1), '');
    end;

    [Test]
    [HandlerFunctions('HandleVendorList')]
    [Scope('OnPrem')]
    procedure TestBuyFromWithNoGLNAndNoVATRegNoAndBadName()
    var
        BuyFromVendor: Record Vendor;
        PayToVendor: Record Vendor;
        Item1: Record Item;
        Item2: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        DataExch: Record "Data Exch.";
        PurchaseHeader: Record "Purchase Header";
        Qty: Decimal;
        Description: Text[100];
    begin
        // Setup
        Initialize();
        SetupDataExchTable(DataExch);
        SetupValidIntermediateTable(DataExch, BuyFromVendor, PayToVendor, Item1, Item2, UnitOfMeasure, Qty, Description);

        // modify gln and vat reg value in intermediate table
        DeleteIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."));
        DeleteIntermediateTableRow(DataExch, DATABASE::Vendor, BuyFromVendor.FieldNo("VAT Registration No."));
        UpdateIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor Name"), InvalidGLNTxt);

        // Excercise - this is valid
        CODEUNIT.Run(CODEUNIT::"Pre-map Incoming Purch. Doc", DataExch);

        // Verify
        AssertExpectedError(DataExch, StrSubstNo(VendorNotFoundByNameAndAddressTxt, InvalidGLNTxt, BuyFromVendor.Address));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPayToWithEmptyGLNAndVATRegNo()
    var
        BuyFromVendor: Record Vendor;
        PayToVendor: Record Vendor;
        Item1: Record Item;
        Item2: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        DataExch: Record "Data Exch.";
        PurchaseHeader: Record "Purchase Header";
        Qty: Decimal;
        Description: Text[100];
    begin
        // Setup
        Initialize();
        SetupDataExchTable(DataExch);
        SetupValidIntermediateTable(DataExch, BuyFromVendor, PayToVendor, Item1, Item2, UnitOfMeasure, Qty, Description);

        // uppercase vendor name
        PayToVendor.Name := UpperCase(PayToVendor.Name);
        PayToVendor.Modify();

        // modify gln and vat reg value in intermediate table and lowercase the pay-to vendor name
        UpdateIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Pay-to Vendor No."), '');
        UpdateIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("VAT Registration No."), '');
        UpdateIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Pay-to Name"),
          LowerCase(PayToVendor.Name));

        // Excercise - this is valid
        CODEUNIT.Run(CODEUNIT::"Pre-map Incoming Purch. Doc", DataExch);

        // Verify
        // when GLN and VAT Reg. No are not there - the vendor will be found by name and address
        Assert.AreEqual(PayToVendor."No.",
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Pay-to Vendor No."), 1), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPayToWithEmptyGLNAndVATRegNoCaseInsensitive()
    var
        BuyFromVendor: Record Vendor;
        PayToVendor: Record Vendor;
        Item1: Record Item;
        Item2: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        DataExch: Record "Data Exch.";
        PurchaseHeader: Record "Purchase Header";
        Qty: Decimal;
        Description: Text[100];
    begin
        // Setup
        Initialize();
        SetupDataExchTable(DataExch);
        SetupValidIntermediateTable(DataExch, BuyFromVendor, PayToVendor, Item1, Item2, UnitOfMeasure, Qty, Description);

        // modify gln and vat reg value in intermediate table
        UpdateIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Pay-to Vendor No."), '');
        UpdateIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("VAT Registration No."), '');

        // Excercise - this is valid
        CODEUNIT.Run(CODEUNIT::"Pre-map Incoming Purch. Doc", DataExch);

        // Verify
        // when GLN and VAT Reg. No are not there - the vendor will be found by name and address
        Assert.AreEqual(PayToVendor."No.",
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Pay-to Vendor No."), 1), '');
    end;

    [Test]
    [HandlerFunctions('HandleVendorList')]
    [Scope('OnPrem')]
    procedure TestPayToWithEmptyGLNUnknownVATRegNo()
    var
        DataExch: Record "Data Exch.";
        PurchaseHeader: Record "Purchase Header";
        BuyFromVendor: Record Vendor;
        PayToVendor: Record Vendor;
        Item1: Record Item;
        Item2: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        Qty: Decimal;
        Description: Text[100];
    begin
        // Setup
        Initialize();
        SetupDataExchTable(DataExch);
        SetupValidIntermediateTable(DataExch, BuyFromVendor, PayToVendor, Item1, Item2, UnitOfMeasure, Qty, Description);

        // modify gln at vat reg value in intermediate table
        UpdateIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Pay-to Vendor No."), '');
        UpdateIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("VAT Registration No."),
          InvalidVATAmtTxt);

        // Excercise
        CODEUNIT.Run(CODEUNIT::"Pre-map Incoming Purch. Doc", DataExch);
        AssertExpectedError(DataExch, StrSubstNo(PayToVendorNotFoundTxt, PayToVendor.Name, '', InvalidVATAmtTxt));
    end;

    [Test]
    [HandlerFunctions('HandleVendorList')]
    [Scope('OnPrem')]
    procedure TestPayToWithNoGLNAndNoVATRegNoAndBadName()
    var
        BuyFromVendor: Record Vendor;
        PayToVendor: Record Vendor;
        Item1: Record Item;
        Item2: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        DataExch: Record "Data Exch.";
        PurchaseHeader: Record "Purchase Header";
        Qty: Decimal;
        Description: Text[100];
    begin
        // Setup
        Initialize();
        SetupDataExchTable(DataExch);
        SetupValidIntermediateTable(DataExch, BuyFromVendor, PayToVendor, Item1, Item2, UnitOfMeasure, Qty, Description);

        // modify gln and vat reg value in intermediate table
        DeleteIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Pay-to Vendor No."));
        DeleteIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("VAT Registration No."));
        UpdateIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Pay-to Name"), InvalidGLNTxt);

        // Excercise - this is valid
        CODEUNIT.Run(CODEUNIT::"Pre-map Incoming Purch. Doc", DataExch);

        // Verify
        AssertExpectedError(DataExch, StrSubstNo(VendorNotFoundByNameAndAddressTxt, InvalidGLNTxt, PayToVendor.Address));
    end;

    [Test]
    [HandlerFunctions('HandleItemList')]
    [Scope('OnPrem')]
    procedure TestUnknownItemByGTINAndVendorItemNo()
    var
        BuyFromVendor: Record Vendor;
        PayToVendor: Record Vendor;
        Item1: Record Item;
        Item2: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        DataExch: Record "Data Exch.";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        Qty: Decimal;
        Description: Text[100];
    begin
        // Setup
        Initialize();
        SetupDataExchTable(DataExch);
        SetupValidIntermediateTable(DataExch, BuyFromVendor, PayToVendor, Item1, Item2, UnitOfMeasure, Qty, Description);

        // modify item bar no and item reference no value in intermediate table
        DeleteIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."));
        DeleteIntermediateTableRow(DataExch, DATABASE::Vendor, BuyFromVendor.FieldNo("VAT Registration No."));
        UpdateIntermediateTableRow(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo("No."), InvalidItemTxt);
        UpdateIntermediateTableRow(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo("Item Reference No."),
          InvalidItem2Txt);

        // Excercise
        CODEUNIT.Run(CODEUNIT::"Pre-map Incoming Purch. Doc", DataExch);
        AssertExpectedError(DataExch, StrSubstNo(ItemNotFoundTxt, ItemNameTxt, BuyFromVendor."No.", InvalidItem2Txt, InvalidItemTxt));
    end;

    [Test]
    [HandlerFunctions('HandleItemList')]
    [Scope('OnPrem')]
    procedure TestUnknownItemByGTIN()
    var
        BuyFromVendor: Record Vendor;
        PayToVendor: Record Vendor;
        Item1: Record Item;
        Item2: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        DataExch: Record "Data Exch.";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        Qty: Decimal;
        Description: Text[100];
    begin
        // Setup
        Initialize();
        SetupDataExchTable(DataExch);
        SetupValidIntermediateTable(DataExch, BuyFromVendor, PayToVendor, Item1, Item2, UnitOfMeasure, Qty, Description);

        // modify item bar no and item reference no value in intermediate table
        DeleteIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."));
        DeleteIntermediateTableRow(DataExch, DATABASE::Vendor, BuyFromVendor.FieldNo("VAT Registration No."));
        UpdateIntermediateTableRow(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo("No."), InvalidItemTxt);
        DeleteIntermediateTableRow(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo("Item Reference No."));

        // Excercise
        CODEUNIT.Run(CODEUNIT::"Pre-map Incoming Purch. Doc", DataExch);
        AssertExpectedError(DataExch, StrSubstNo(ItemNotFoundByGTINErr, ItemNameTxt, InvalidItemTxt));
    end;

    [Test]
    [HandlerFunctions('HandleItemList')]
    [Scope('OnPrem')]
    procedure TestUnknownItemByVendorItemNo()
    var
        BuyFromVendor: Record Vendor;
        PayToVendor: Record Vendor;
        Item1: Record Item;
        Item2: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        DataExch: Record "Data Exch.";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        Qty: Decimal;
        Description: Text[100];
    begin
        // Setup
        Initialize();
        SetupDataExchTable(DataExch);
        SetupValidIntermediateTable(DataExch, BuyFromVendor, PayToVendor, Item1, Item2, UnitOfMeasure, Qty, Description);

        // modify item bar no and item reference no value in intermediate table
        DeleteIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."));
        DeleteIntermediateTableRow(DataExch, DATABASE::Vendor, BuyFromVendor.FieldNo("VAT Registration No."));
        DeleteIntermediateTableRow(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo("No."));
        UpdateIntermediateTableRow(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo("Item Reference No."),
          InvalidItem2Txt);

        // Excercise
        CODEUNIT.Run(CODEUNIT::"Pre-map Incoming Purch. Doc", DataExch);
        AssertExpectedError(DataExch, StrSubstNo(ItemNotFoundByVendorItemNoErr, ItemNameTxt, BuyFromVendor."No.", InvalidItem2Txt));
    end;

    [Test]
    [HandlerFunctions('HandleUnitsOfMeasure')]
    [Scope('OnPrem')]
    procedure TestUnknownUnitOfMeasure()
    var
        DataExch: Record "Data Exch.";
        PurchaseLine: Record "Purchase Line";
    begin
        // Setup
        Initialize();
        SetupTestTables(DataExch);

        // modify unit of measure value in intermediate table
        UpdateIntermediateTableRow(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo("Unit of Measure Code"), InvalidUOMTxt);

        // Excercise
        CODEUNIT.Run(CODEUNIT::"Pre-map Incoming Purch. Doc", DataExch);
        AssertExpectedError(DataExch, StrSubstNo(UOMNotFoundTxt, InvalidUOMTxt));
    end;

    [Test]
    [HandlerFunctions('HandleUnitsOfMeasure,HandleCompanyInformation')]
    [Scope('OnPrem')]
    procedure TestMultipleErrorMessages()
    var
        DataExch: Record "Data Exch.";
        PurchaseLine: Record "Purchase Line";
        CompanyInformation: Record "Company Information";
    begin
        // Setup
        Initialize();
        SetupTestTables(DataExch);

        // modify unit of measure value in intermediate table
        UpdateIntermediateTableRow(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo("Unit of Measure Code"), InvalidUOMTxt);
        // modify customer gln value in intermediate table
        UpdateIntermediateTableRow(DataExch, DATABASE::"Company Information", CompanyInformation.FieldNo(GLN), InvalidGLNTxt);

        // Excercise
        CODEUNIT.Run(CODEUNIT::"Pre-map Incoming Purch. Doc", DataExch);

        // Excercise
        AssertExpectedError(DataExch, StrSubstNo(UOMNotFoundTxt, InvalidUOMTxt));
        AssertExpectedError(DataExch, StrSubstNo(InvalidCompanyInfoGLNTxt, InvalidGLNTxt));
    end;

    [Test]
    [HandlerFunctions('HandleTextToAccountMappingWksh')]
    [Scope('OnPrem')]
    procedure TestInvoicePremappingNonItemLinesMissingSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        BuyFromVendor: Record Vendor;
        PayToVendor: Record Vendor;
        DataExch: Record "Data Exch.";
        UnitOfMeasure: Record "Unit of Measure";
        Qty: Decimal;
        Description: Text[100];
    begin
        // Setup
        Initialize();
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Debit Acc. for Non-Item Lines", '');
        PurchasesPayablesSetup.Modify(true);
        SetupDataExchTable(DataExch);
        SetupValidNonItemIntermediateTable(DataExch, BuyFromVendor, PayToVendor, UnitOfMeasure, Qty, Description);

        // Excercise
        CODEUNIT.Run(CODEUNIT::"Pre-map Incoming Purch. Doc", DataExch);
        AssertExpectedError(
          DataExch, StrSubstNo(UnableToFindAppropriateAccountErr, Description));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInvoicePremappingNonItemLinesToGLAccount()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        BuyFromVendor: Record Vendor;
        PayToVendor: Record Vendor;
        DataExch: Record "Data Exch.";
        UnitOfMeasure: Record "Unit of Measure";
        PurchaseLine: Record "Purchase Line";
        TextToAccountMapping: Record "Text-to-Account Mapping";
        Qty: Decimal;
        Line1Desc: Text[100];
        MappingText: Text[50];
    begin
        // Setup
        Initialize();
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Debit Acc. for Non-Item Lines", '');
        PurchasesPayablesSetup.Modify(true);
        SetupDataExchTable(DataExch);
        MappingText := 'luxury';
        Line1Desc := 'Something ' + UpperCase(MappingText);
        SetupValidNonItemIntermediateTable(DataExch, BuyFromVendor, PayToVendor, UnitOfMeasure, Qty, Line1Desc);

        CreateAccountMapping(TextToAccountMapping, MappingText,
          TextToAccountMapping."Bal. Source Type"::"G/L Account", '', BuyFromVendor."No.");

        // Excercise
        CODEUNIT.Run(CODEUNIT::"Pre-map Incoming Purch. Doc", DataExch);

        // Verify
        Assert.AreEqual(Line1Desc,
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo(Description), 2), '');
        Assert.AreEqual(UnitOfMeasure.Code,
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo("Unit of Measure Code"), 2), '');
        Assert.AreEqual(Format(Qty, 0, 9),
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo(Quantity), 2), '');
        Assert.AreEqual(Format(PurchaseLine.Type::"G/L Account", 0, 9),
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo(Type), 2), '');
        Assert.AreEqual(TextToAccountMapping."Debit Acc. No.",
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo("No."), 2), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSuccessfullInvoicePremappingNonItemLines()
    var
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        BuyFromVendor: Record Vendor;
        PayToVendor: Record Vendor;
        DataExch: Record "Data Exch.";
        PurchaseLine: Record "Purchase Line";
        UnitOfMeasure: Record "Unit of Measure";
        Qty: Decimal;
        Description: Text[100];
    begin
        // Setup
        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        GLAccount.Get(LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale));

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Debit Acc. for Non-Item Lines", GLAccount."No.");
        PurchasesPayablesSetup.Modify(true);

        SetupDataExchTable(DataExch);
        SetupValidNonItemIntermediateTable(DataExch, BuyFromVendor, PayToVendor, UnitOfMeasure, Qty, Description);

        // Excercise
        CODEUNIT.Run(CODEUNIT::"Pre-map Incoming Purch. Doc", DataExch);

        // Verify
        Assert.AreEqual(Description,
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo(Description), 2), '');
        Assert.AreEqual(UnitOfMeasure.Code,
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo("Unit of Measure Code"), 2), '');
        Assert.AreEqual(Format(Qty, 0, 9),
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo(Quantity), 2), '');
        Assert.AreEqual(Format(PurchaseLine.Type::"G/L Account", 0, 9),
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo(Type), 2), '');
        Assert.AreEqual(GLAccount."No.",
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo("No."), 2), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSuccessfullInvoicePremappingNoLines()
    var
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        TextToAccountMapping: Record "Text-to-Account Mapping";
        BuyFromVendor: Record Vendor;
        PayToVendor: Record Vendor;
        DataExch: Record "Data Exch.";
        PurchaseLine: Record "Purchase Line";
        IntermediateDataImport: Record "Intermediate Data Import";
        PurchaseHeader: Record "Purchase Header";
        UnitOfMeasure: Record "Unit of Measure";
        Qty: Decimal;
        TotalAmountExclVAT: Decimal;
        VendorInvoiceNo: Code[20];
        Description: Text[100];
    begin
        // Setup
        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        GLAccount.Get(LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale));

        SetupDataExchTable(DataExch);
        SetupValidNonItemIntermediateTable(DataExch, BuyFromVendor, PayToVendor, UnitOfMeasure, Qty, Description);

        TextToAccountMapping.Init();
        TextToAccountMapping."Mapping Text" := LowerCase(BuyFromVendor.Name);
        TextToAccountMapping."Bal. Source Type" := TextToAccountMapping."Bal. Source Type"::Vendor;
        TextToAccountMapping."Bal. Source No." := BuyFromVendor."No.";
        TextToAccountMapping."Debit Acc. No." := GLAccount."No.";
        TextToAccountMapping.Insert();
        // delete all invoice lines from intermediate table
        IntermediateDataImport.SetRange("Data Exch. No.", DataExch."Entry No.");
        IntermediateDataImport.SetRange("Parent Record No.", 1);
        IntermediateDataImport.DeleteAll();
        // add total amount excl VAT to the header fields
        TotalAmountExclVAT := LibraryRandom.RandDecInRange(1, 100, 2);
        InsertIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo(Amount),
          Format(TotalAmountExclVAT, 0, 9));
        VendorInvoiceNo := LibraryUtility.GenerateGUID();
        InsertIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Vendor Invoice No."),
          VendorInvoiceNo);

        // Excercise
        CODEUNIT.Run(CODEUNIT::"Pre-map Incoming Purch. Doc", DataExch);

        // Verify that despite no lines are imported, one line for Total Amount Excl VAT was created
        Description := BuyFromVendor.Name;
        Assert.AreEqual(Description,
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo(Description), 1), '');
        Assert.AreEqual('1',
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo(Quantity), 1), '');
        Assert.AreEqual(Format(PurchaseLine.Type::"G/L Account", 0, 9),
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo(Type), 1), '');
        Assert.AreEqual(GLAccount."No.",
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo("No."), 1), '');
        Assert.AreEqual(Format(TotalAmountExclVAT, 0, 9),
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo("Direct Unit Cost"), 1), '');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('DataExchDefCardHandler')]
    procedure TestMissingDocumentTypeInDataExchangeDefinition()
    var
        DataExch: Record "Data Exch.";
        PurchaseHeader: Record "Purchase Header";
        PreMapIncomingPurchDoc: Codeunit "Pre-map Incoming Purch. Doc";
    begin
        // Setup
        Initialize();
        SetupTestTables(DataExch);

        // remove document type from intermediate table
        DeleteIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Document Type"));

        // Excercise
        CODEUNIT.Run(CODEUNIT::"Pre-map Incoming Purch. Doc", DataExch);

        // Verify
        AssertExpectedError(DataExch, PreMapIncomingPurchDoc.ConstructDocumenttypeUnknownErr());
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('DataExchDefCardHandler')]
    procedure TestUnsupportedDocumentTypeInDataExchangeDefinition()
    var
        DataExch: Record "Data Exch.";
        PurchaseHeader: Record "Purchase Header";
        PreMapIncomingPurchDoc: Codeunit "Pre-map Incoming Purch. Doc";
    begin
        // Setup
        Initialize();
        SetupTestTables(DataExch);

        // remove document type from intermediate table
        UpdateIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Document Type"), InvalidUOMTxt);

        // Excercise
        CODEUNIT.Run(CODEUNIT::"Pre-map Incoming Purch. Doc", DataExch);

        // Verify
        AssertExpectedError(DataExch, PreMapIncomingPurchDoc.ConstructDocumenttypeUnknownErr());
    end;

    [Test]
    [HandlerFunctions('HandlePurchaseInvoicesList')]
    [Scope('OnPrem')]
    procedure TestUnableToFindReferencedInvoice()
    var
        DataExch: Record "Data Exch.";
        PurchaseHeader: Record "Purchase Header";
        VendorInvoiceNo: Code[10];
    begin
        // Setup
        Initialize();
        SetupTestTables(DataExch);
        VendorInvoiceNo := LibraryUtility.GenerateGUID();

        // change document type to "Credit Memo" in intermediate table
        UpdateIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Document Type"),
          Format(PurchaseHeader."Document Type"::"Credit Memo"));
        InsertIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Applies-to Doc. Type"),
          Format(PurchaseHeader."Applies-to Doc. Type"::Invoice));
        InsertIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Applies-to Doc. No."),
          VendorInvoiceNo);

        // Excercise
        CODEUNIT.Run(CODEUNIT::"Pre-map Incoming Purch. Doc", DataExch);

        // Verify
        AssertExpectedError(DataExch, StrSubstNo(UnableToFindRelatedInvoiceErr, VendorInvoiceNo));
    end;

    [Test]
    [HandlerFunctions('HandlePurchaseInvoiceCard')]
    [Scope('OnPrem')]
    procedure TestReferencedInvoiceMustBePosted()
    var
        DataExch: Record "Data Exch.";
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        VendorInvoiceNo: Code[10];
    begin
        // Setup
        Initialize();
        SetupTestTables(DataExch);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        VendorInvoiceNo := LibraryUtility.GenerateGUID();
        PurchaseHeader."Vendor Invoice No." := VendorInvoiceNo;
        PurchaseHeader.Modify();

        // change document type to "Credit Memo" in intermediate table
        UpdateIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Document Type"),
          Format(PurchaseHeader."Document Type"::"Credit Memo"));
        InsertIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Applies-to Doc. Type"),
          Format(PurchaseHeader."Applies-to Doc. Type"::Invoice));
        InsertIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Applies-to Doc. No."),
          VendorInvoiceNo);

        // Excercise
        CODEUNIT.Run(CODEUNIT::"Pre-map Incoming Purch. Doc", DataExch);

        // Verify
        LibraryVariableStorage.Enqueue(VendorInvoiceNo);
        AssertExpectedError(DataExch, StrSubstNo(YouMustFirstPostTheRelatedInvoiceErr, VendorInvoiceNo, PurchaseHeader."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAppliesToReferencedInvoice()
    var
        DataExch: Record "Data Exch.";
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        VendorInvoiceNo: Code[35];
        PostedPurchaseInvoiceNo: Code[20];
        ExpectedDocumentType: Integer;
    begin
        // Setup
        Initialize();
        SetupTestTables(DataExch);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchaseDocumentWithItem(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice,
          Vendor."No.", Item."No.", 1, '', Today);
        VendorInvoiceNo := LibraryUtility.GenerateGUID();
        PurchaseHeader."Vendor Invoice No." := VendorInvoiceNo;
        PurchaseHeader.Modify();
        PostedPurchaseInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // change document type to "Credit Memo" in intermediate table
        UpdateIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Document Type"),
          Format(PurchaseHeader."Document Type"::"Credit Memo"));
        InsertIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Applies-to Doc. No."),
          VendorInvoiceNo);

        // Excercise
        CODEUNIT.Run(CODEUNIT::"Pre-map Incoming Purch. Doc", DataExch);

        // Verify that the created purchase credit memo has the correct Applies-to Doc. No
        ExpectedDocumentType := PurchaseHeader."Applies-to Doc. Type"::Invoice.AsInteger();
        Assert.AreEqual(PostedPurchaseInvoiceNo,
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Applies-to Doc. No."), 1), '');
        Assert.AreEqual(Format(ExpectedDocumentType),
          GetIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Applies-to Doc. Type"), 1), '');
    end;

    [Test]
    procedure FindBuyFromVendorByGLNWhenNonBlockedVendor();
    var
        DataExch: Record "Data Exch.";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        VendorGLN: Text[13];
        NonBlockedVendorNo: Code[20];
    begin
        // [SCENARIO 418945] When multiple vendors have the same GLN and one has Blocked = "", non-blocked Vendor is selected for Purchase Invoice created from Incoming Document.
        Initialize();
        SetupTestTables(DataExch);

        // [GIVEN] Three Vendors with GLN = "A". Vendor "V1" has Blocked = All, "V2" has Blocked = "", "V3" has Blocked = Payment.
        // [GIVEN] Incoming Document with Vendor No. = "A".
        VendorGLN := CreateValidGLN();
        CreateVendor(Vendor, "Vendor Blocked"::All, '', '', '', '', VendorGLN);
        CreateVendor(Vendor, "Vendor Blocked"::" ", '', '', '', '', VendorGLN);
        NonBlockedVendorNo := Vendor."No.";
        CreateVendor(Vendor, "Vendor Blocked"::Payment, '', '', '', '', VendorGLN);

        UpdateIntermediateTableRow(DataExch, Database::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."), VendorGLN);

        // [WHEN] Run codeunit Pre-map Incoming Purch. Doc, which is run when Purchase Invoice is created from Incoming Document.
        Codeunit.Run(Codeunit::"Pre-map Incoming Purch. Doc", DataExch);

        // [THEN] Non-blocked Vendor "V2" is selected for Purchase Invoice.
        Assert.AreEqual(
            Format(NonBlockedVendorNo), GetIntermediateTableRow(DataExch, Database::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."), 1), '');

        // tear down
        Vendor.SetRange(GLN, VendorGLN);
        Vendor.DeleteAll();
    end;

    [Test]
    procedure FindBuyFromVendorByGLNWhenBlockedPaymentVendor();
    var
        DataExch: Record "Data Exch.";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        VendorGLN: Text[13];
    begin
        // [SCENARIO 418945] When multiple vendors have the same GLN and they only has Blocked = Payment/All, Vendor with Blocked "Payment" is selected for Purchase Invoice created from Incoming Document.
        Initialize();
        SetupTestTables(DataExch);

        // [GIVEN] Two Vendors with GLN = "A". Vendor "V1" has Blocked = All, "V2" has Blocked = Payment.
        // [GIVEN] Incoming Document with Vendor No. = "A".
        VendorGLN := CreateValidGLN();
        CreateVendor(Vendor, "Vendor Blocked"::All, '', '', '', '', VendorGLN);
        CreateVendor(Vendor, "Vendor Blocked"::Payment, '', '', '', '', VendorGLN);

        UpdateIntermediateTableRow(DataExch, Database::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."), VendorGLN);

        // [WHEN] Run codeunit Pre-map Incoming Purch. Doc, which is run when Purchase Invoice is created from Incoming Document.
        Codeunit.Run(Codeunit::"Pre-map Incoming Purch. Doc", DataExch);

        // [THEN] Vendor "V2" with Blocked = Payment is selected for Purchase Invoice.
        Assert.AreEqual(
            Format(Vendor."No."), GetIntermediateTableRow(DataExch, Database::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."), 1), '');

        // tear down
        Vendor.SetRange(GLN, VendorGLN);
        Vendor.DeleteAll();
    end;

    [Test]
    procedure FindBuyFromVendorByGLNWhenBlockedAllVendor();
    var
        DataExch: Record "Data Exch.";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        VendorGLN: Text[13];
        FirstVendorNo: Code[20];
    begin
        // [SCENARIO 418945] When multiple vendors have the same GLN and they only has Blocked = All, first Vendor with Blocked "All" is selected for Purchase Invoice created from Incoming Document.
        Initialize();
        SetupTestTables(DataExch);

        // [GIVEN] Two Vendors with GLN = "A". Both Vendor "V1" and "V2" has Blocked = All.
        // [GIVEN] Incoming Document with Vendor No. = "A".
        VendorGLN := CreateValidGLN();
        CreateVendor(Vendor, "Vendor Blocked"::All, '', '', '', '', VendorGLN);
        FirstVendorNo := Vendor."No.";
        CreateVendor(Vendor, "Vendor Blocked"::All, '', '', '', '', VendorGLN);

        UpdateIntermediateTableRow(DataExch, Database::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."), VendorGLN);

        // [WHEN] Run codeunit Pre-map Incoming Purch. Doc, which is run when Purchase Invoice is created from Incoming Document.
        Codeunit.Run(Codeunit::"Pre-map Incoming Purch. Doc", DataExch);

        // [THEN] First blocked Vendor "V1" is selected for Purchase Invoice.
        Assert.AreEqual(
            Format(FirstVendorNo), GetIntermediateTableRow(DataExch, Database::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."), 1), '');

        // tear down
        Vendor.SetRange(GLN, VendorGLN);
        Vendor.DeleteAll();
    end;

    [Test]
    procedure FindBuyFromVendorByVATWhenNonBlockedVendor();
    var
        DataExch: Record "Data Exch.";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        VatRegNo: Text[20];
        NonBlockedVendorNo: Code[20];
    begin
        // [SCENARIO 418945] When multiple vendors have the same VAT and one has Blocked = "", non-blocked Vendor is selected for Purchase Invoice created from Incoming Document.
        Initialize();
        SetupTestTables(DataExch);

        // [GIVEN] Three Vendors with blank GLN and VAT Registration No. = "A". Vendor "V1" has Blocked = All, "V2" has Blocked = "", "V3" has Blocked = Payment.
        // [GIVEN] Incoming Document with Vendor No. = "" and Vendor VAT Registration No. = "A".
        VatRegNo := LibraryUtility.GenerateGUID();
        CreateVendor(Vendor, "Vendor Blocked"::All, '', '', '', VatRegNo, '');
        CreateVendor(Vendor, "Vendor Blocked"::" ", '', '', '', VatRegNo, '');
        NonBlockedVendorNo := Vendor."No.";
        CreateVendor(Vendor, "Vendor Blocked"::Payment, '', '', '', VatRegNo, '');

        DeleteIntermediateTableRow(DataExch, Database::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."));
        UpdateIntermediateTableRow(DataExch, Database::Vendor, Vendor.FieldNo("VAT Registration No."), VatRegNo);

        // [WHEN] Run codeunit Pre-map Incoming Purch. Doc, which is run when Purchase Invoice is created from Incoming Document.
        Codeunit.Run(Codeunit::"Pre-map Incoming Purch. Doc", DataExch);

        // [THEN] Non-blocked Vendor "V2" is selected for Purchase Invoice.
        Assert.AreEqual(
            Format(NonBlockedVendorNo), GetIntermediateTableRow(DataExch, Database::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."), 1), '');
    end;

    [Test]
    procedure FindBuyFromVendorByVATWhenBlockedPaymentVendor();
    var
        DataExch: Record "Data Exch.";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        VatRegNo: Text[20];
    begin
        // [SCENARIO 418945] When multiple vendors have the same VAT and they only has Blocked = Payment/All, Vendor with Blocked "Payment" is selected for Purchase Invoice created from Incoming Document.
        Initialize();
        SetupTestTables(DataExch);

        // [GIVEN] Two Vendors with blank GLN and with VAT Registration No. = "A". Vendor "V1" has Blocked = All, "V2" has Blocked = Payment.
        // [GIVEN] Incoming Document with Vendor No. = "" and Vendor VAT Registration No. = "A".
        VatRegNo := LibraryUtility.GenerateGUID();
        CreateVendor(Vendor, "Vendor Blocked"::All, '', '', '', VatRegNo, '');
        CreateVendor(Vendor, "Vendor Blocked"::Payment, '', '', '', VatRegNo, '');

        DeleteIntermediateTableRow(DataExch, Database::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."));
        UpdateIntermediateTableRow(DataExch, Database::Vendor, Vendor.FieldNo("VAT Registration No."), VatRegNo);

        // [WHEN] Run codeunit Pre-map Incoming Purch. Doc, which is run when Purchase Invoice is created from Incoming Document.
        Codeunit.Run(Codeunit::"Pre-map Incoming Purch. Doc", DataExch);

        // [THEN] Vendor "V2" with Blocked = Payment is selected for Purchase Invoice.
        Assert.AreEqual(
            Format(Vendor."No."), GetIntermediateTableRow(DataExch, Database::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."), 1), '');
    end;

    [Test]
    procedure FindBuyFromVendorByVATWhenBlockedAllVendor();
    var
        DataExch: Record "Data Exch.";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        VatRegNo: Text[20];
        FirstVendorNo: Code[20];
    begin
        // [SCENARIO 418945] When multiple vendors have the same VAT and they only has Blocked = All, first Vendor with Blocked "All" is selected for Purchase Invoice created from Incoming Document.
        Initialize();
        SetupTestTables(DataExch);

        // [GIVEN] Two Vendors with blank GLN and with VAT Registration No. = "A". Both Vendor "V1" and "V2" has Blocked = All.
        // [GIVEN] Incoming Document with Vendor No. = "" and Vendor VAT Registration No. = "A".
        VatRegNo := LibraryUtility.GenerateGUID();
        CreateVendor(Vendor, "Vendor Blocked"::All, '', '', '', VatRegNo, '');
        FirstVendorNo := Vendor."No.";
        CreateVendor(Vendor, "Vendor Blocked"::All, '', '', '', VatRegNo, '');

        DeleteIntermediateTableRow(DataExch, Database::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."));
        UpdateIntermediateTableRow(DataExch, Database::Vendor, Vendor.FieldNo("VAT Registration No."), VatRegNo);

        // [WHEN] Run codeunit Pre-map Incoming Purch. Doc, which is run when Purchase Invoice is created from Incoming Document.
        Codeunit.Run(Codeunit::"Pre-map Incoming Purch. Doc", DataExch);

        // [THEN] First blocked Vendor "V1" is selected for Purchase Invoice.
        Assert.AreEqual(
            Format(FirstVendorNo), GetIntermediateTableRow(DataExch, Database::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."), 1), '');
    end;

    [Test]
    procedure FindBuyFromVendorByPhoneNoWhenNonBlockedVendor();
    var
        DataExch: Record "Data Exch.";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PhoneNo: Text[30];
        NonBlockedVendorNo: Code[20];
    begin
        // [SCENARIO 418945] When multiple vendors have the same Phone No. and one has Blocked = "", non-blocked Vendor is selected for Purchase Invoice created from Incoming Document.
        Initialize();
        SetupTestTables(DataExch);

        // [GIVEN] Three Vendors with blank GLN and VAT, and with Phone No. = "A". Vendor "V1" has Blocked = All, "V2" has Blocked = "", "V3" has Blocked = Payment.
        // [GIVEN] Incoming Document with Vendor No. = "", Vendor VAT Registration No. = "" and Vendor Phone No. = "A".
        PhoneNo := LibraryUtility.GenerateRandomNumericText(5) + CopyStr(LibraryUtility.GenerateGUID(), 3);
        CreateVendor(Vendor, "Vendor Blocked"::All, '', '', PhoneNo, '', '');
        CreateVendor(Vendor, "Vendor Blocked"::" ", '', '', PhoneNo, '', '');
        NonBlockedVendorNo := Vendor."No.";
        CreateVendor(Vendor, "Vendor Blocked"::Payment, '', '', PhoneNo, '', '');

        DeleteIntermediateTableRow(DataExch, Database::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."));
        DeleteIntermediateTableRow(DataExch, Database::Vendor, Vendor.FieldNo("VAT Registration No."));
        InsertIntermediateTableRow(DataExch, Database::Vendor, Vendor.FieldNo("Phone No."), PhoneNo);

        // [WHEN] Run codeunit Pre-map Incoming Purch. Doc, which is run when Purchase Invoice is created from Incoming Document.
        Codeunit.Run(Codeunit::"Pre-map Incoming Purch. Doc", DataExch);

        // [THEN] Non-blocked Vendor "V2" is selected for Purchase Invoice.
        Assert.AreEqual(
            Format(NonBlockedVendorNo), GetIntermediateTableRow(DataExch, Database::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."), 1), '');
    end;

    [Test]
    procedure FindBuyFromVendorByPhoneNoWhenBlockedPaymentVendor();
    var
        DataExch: Record "Data Exch.";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PhoneNo: Text[30];
    begin
        // [SCENARIO 418945] When multiple vendors have the same Phone No. and they only has Blocked = Payment/All, Vendor with Blocked "Payment" is selected for Purchase Invoice created from Incoming Document.
        Initialize();
        SetupTestTables(DataExch);

        // [GIVEN] Two Vendors with blank GLN and VAT, and with Phone No. = "A". Vendor "V1" has Blocked = All, "V2" has Blocked = Payment.
        // [GIVEN] Incoming Document with Vendor No. = "", Vendor VAT Registration No. = "" and Vendor Phone No. = "A".
        PhoneNo := LibraryUtility.GenerateRandomNumericText(5) + CopyStr(LibraryUtility.GenerateGUID(), 3);
        CreateVendor(Vendor, "Vendor Blocked"::All, '', '', PhoneNo, '', '');
        CreateVendor(Vendor, "Vendor Blocked"::Payment, '', '', PhoneNo, '', '');

        DeleteIntermediateTableRow(DataExch, Database::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."));
        DeleteIntermediateTableRow(DataExch, Database::Vendor, Vendor.FieldNo("VAT Registration No."));
        InsertIntermediateTableRow(DataExch, Database::Vendor, Vendor.FieldNo("Phone No."), PhoneNo);

        // [WHEN] Run codeunit Pre-map Incoming Purch. Doc, which is run when Purchase Invoice is created from Incoming Document.
        Codeunit.Run(Codeunit::"Pre-map Incoming Purch. Doc", DataExch);

        // [THEN] Vendor "V2" with Blocked = Payment is selected for Purchase Invoice.
        Assert.AreEqual(
            Format(Vendor."No."), GetIntermediateTableRow(DataExch, Database::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."), 1), '');
    end;

    [Test]
    procedure FindBuyFromVendorByPhoneNoWhenBlockedAllVendor();
    var
        DataExch: Record "Data Exch.";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PhoneNo: Text[30];
        FirstVendorNo: Code[20];
    begin
        // [SCENARIO 418945] When multiple vendors have the same Phone No. and they only has Blocked = All, first Vendor with Blocked "All" is selected for Purchase Invoice created from Incoming Document.
        Initialize();
        SetupTestTables(DataExch);

        // [GIVEN] Two Vendors with blank GLN and VAT, and with Phone No. = "A". Both Vendor "V1" and "V2" has Blocked = All.
        // [GIVEN] Incoming Document with Vendor No. = "", Vendor VAT Registration No. = "" and Vendor Phone No. = "A".
        PhoneNo := LibraryUtility.GenerateRandomNumericText(5) + CopyStr(LibraryUtility.GenerateGUID(), 3);
        CreateVendor(Vendor, "Vendor Blocked"::All, '', '', PhoneNo, '', '');
        FirstVendorNo := Vendor."No.";
        CreateVendor(Vendor, "Vendor Blocked"::All, '', '', PhoneNo, '', '');

        DeleteIntermediateTableRow(DataExch, Database::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."));
        DeleteIntermediateTableRow(DataExch, Database::Vendor, Vendor.FieldNo("VAT Registration No."));
        InsertIntermediateTableRow(DataExch, Database::Vendor, Vendor.FieldNo("Phone No."), PhoneNo);

        // [WHEN] Run codeunit Pre-map Incoming Purch. Doc, which is run when Purchase Invoice is created from Incoming Document.
        Codeunit.Run(Codeunit::"Pre-map Incoming Purch. Doc", DataExch);

        // [THEN] First blocked Vendor "V1" is selected for Purchase Invoice.
        Assert.AreEqual(
            Format(FirstVendorNo), GetIntermediateTableRow(DataExch, Database::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."), 1), '');
    end;

    [Test]
    procedure FindBuyFromVendorByNameWhenNonBlockedVendor();
    var
        DataExch: Record "Data Exch.";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        VendorName: Text[100];
        NonBlockedVendorNo: Code[20];
    begin
        // [SCENARIO 418945] When multiple vendors have the same Name and blank Address and one has Blocked = "", non-blocked Vendor is selected for Purchase Invoice created from Incoming Document.
        Initialize();
        SetupTestTables(DataExch);

        // [GIVEN] Three Vendors with blank GLN and VAT, and with Name = "A", Address = "". Vendor "V1" has Blocked = All, "V2" has Blocked = "", "V3" has Blocked = Payment.
        // [GIVEN] Incoming Document with Vendor No. = "", Vendor VAT Registration No. = "" and Vendor Name = "A", Vendor Address = "".
        VendorName := LibraryUtility.GenerateGUID();
        CreateVendor(Vendor, "Vendor Blocked"::All, VendorName, '', '', '', '');
        CreateVendor(Vendor, "Vendor Blocked"::" ", VendorName, '', '', '', '');
        NonBlockedVendorNo := Vendor."No.";
        CreateVendor(Vendor, "Vendor Blocked"::Payment, VendorName, '', '', '', '');

        DeleteIntermediateTableRow(DataExch, Database::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."));
        DeleteIntermediateTableRow(DataExch, Database::Vendor, Vendor.FieldNo("VAT Registration No."));
        UpdateIntermediateTableRow(DataExch, Database::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor Name"), VendorName);
        DeleteIntermediateTableRow(DataExch, Database::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Address"));

        // [WHEN] Run codeunit Pre-map Incoming Purch. Doc, which is run when Purchase Invoice is created from Incoming Document.
        Codeunit.Run(Codeunit::"Pre-map Incoming Purch. Doc", DataExch);

        // [THEN] Non-blocked Vendor "V2" is selected for Purchase Invoice.
        Assert.AreEqual(
            Format(NonBlockedVendorNo), GetIntermediateTableRow(DataExch, Database::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."), 1), '');
    end;

    [Test]
    procedure FindBuyFromVendorByNameAndAddressWhenNonBlockedVendor();
    var
        DataExch: Record "Data Exch.";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        VendorName: Text[100];
        VendorAddress: Text[100];
        NonBlockedVendorNo: Code[20];
    begin
        // [SCENARIO 418945] When multiple vendors have the same Name and Address and one has Blocked = "", non-blocked Vendor is selected for Purchase Invoice created from Incoming Document.
        Initialize();
        SetupTestTables(DataExch);

        // [GIVEN] Three Vendors with blank GLN and VAT, and with Name = "A", Address = "B". Vendor "V1" has Blocked = All, "V2" has Blocked = "", "V3" has Blocked = Payment.
        // [GIVEN] Incoming Document with Vendor No. = "", Vendor VAT Registration No. = "" and Vendor Name = "A", Vendor Address = "B".
        VendorName := LibraryUtility.GenerateGUID();
        VendorAddress := LibraryUtility.GenerateGUID();
        CreateVendor(Vendor, "Vendor Blocked"::All, VendorName, VendorAddress, '', '', '');
        CreateVendor(Vendor, "Vendor Blocked"::" ", VendorName, VendorAddress, '', '', '');
        NonBlockedVendorNo := Vendor."No.";
        CreateVendor(Vendor, "Vendor Blocked"::Payment, VendorName, VendorAddress, '', '', '');

        DeleteIntermediateTableRow(DataExch, Database::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."));
        DeleteIntermediateTableRow(DataExch, Database::Vendor, Vendor.FieldNo("VAT Registration No."));
        UpdateIntermediateTableRow(DataExch, Database::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor Name"), VendorName);
        UpdateIntermediateTableRow(DataExch, Database::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Address"), VendorAddress);

        // [WHEN] Run codeunit Pre-map Incoming Purch. Doc, which is run when Purchase Invoice is created from Incoming Document.
        Codeunit.Run(Codeunit::"Pre-map Incoming Purch. Doc", DataExch);

        // [THEN] Non-blocked Vendor "V2" is selected for Purchase Invoice.
        Assert.AreEqual(
            Format(NonBlockedVendorNo), GetIntermediateTableRow(DataExch, Database::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."), 1), '');
    end;

    [Test]
    procedure FindBuyFromVendorByIBANWhenNonBlockedVendor();
    var
        DataExch: Record "Data Exch.";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        VendorBankAccount: Record "Vendor Bank Account";
        VendorIBAN: Text[20];
        NonBlockedVendorNo: Code[20];
    begin
        // [SCENARIO 418945] When multiple vendors have the same IBAN and one has Blocked = "", non-blocked Vendor is selected for Purchase Invoice created from Incoming Document.
        Initialize();
        SetupTestTables(DataExch);

        // [GIVEN] Three Vendors with blank GLN and VAT. Each has Vendor Bank Account with IBAN = "A". Vendor "V1" has Blocked = All, "V2" has Blocked = "", "V3" has Blocked = Payment.
        // [GIVEN] Incoming Document with Vendor No. = "", Vendor VAT Registration No. = "" and Vendor IBAN = "A".
        VendorIBAN := LibraryUtility.GenerateGUID();
        CreateVendorWithBankAccount(Vendor, "Vendor Blocked"::All, VendorIBAN, '', '');
        CreateVendorWithBankAccount(Vendor, "Vendor Blocked"::" ", VendorIBAN, '', '');
        NonBlockedVendorNo := Vendor."No.";
        CreateVendorWithBankAccount(Vendor, "Vendor Blocked"::Payment, VendorIBAN, '', '');

        DeleteIntermediateTableRow(DataExch, Database::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."));
        DeleteIntermediateTableRow(DataExch, Database::Vendor, Vendor.FieldNo("VAT Registration No."));
        InsertIntermediateTableRow(DataExch, Database::"Vendor Bank Account", VendorBankAccount.FieldNo(IBAN), VendorIBAN);

        // [WHEN] Run codeunit Pre-map Incoming Purch. Doc, which is run when Purchase Invoice is created from Incoming Document.
        Codeunit.Run(Codeunit::"Pre-map Incoming Purch. Doc", DataExch);

        // [THEN] Non-blocked Vendor "V2" is selected for Purchase Invoice.
        Assert.AreEqual(
            Format(NonBlockedVendorNo), GetIntermediateTableRow(DataExch, Database::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."), 1), '');
    end;

    [Test]
    procedure FindBuyFromVendorByIBANWhenBlockedPaymentVendor();
    var
        DataExch: Record "Data Exch.";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        VendorBankAccount: Record "Vendor Bank Account";
        VendorIBAN: Text[20];
    begin
        // [SCENARIO 418945] When multiple vendors have the same IBAN and they only has Blocked = Payment/All, Vendor with Blocked "Payment" is selected for Purchase Invoice created from Incoming Document.
        Initialize();
        SetupTestTables(DataExch);

        // [GIVEN] Two Vendors with blank GLN and VAT. Each has Vendor Bank Account with IBAN = "A". Vendor "V1" has Blocked = All, "V2" has Blocked = Payment.
        // [GIVEN] Incoming Document with Vendor No. = "", Vendor VAT Registration No. = "" and Vendor IBAN = "A".
        VendorIBAN := LibraryUtility.GenerateGUID();
        CreateVendorWithBankAccount(Vendor, "Vendor Blocked"::All, VendorIBAN, '', '');
        CreateVendorWithBankAccount(Vendor, "Vendor Blocked"::Payment, VendorIBAN, '', '');

        DeleteIntermediateTableRow(DataExch, Database::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."));
        DeleteIntermediateTableRow(DataExch, Database::Vendor, Vendor.FieldNo("VAT Registration No."));
        InsertIntermediateTableRow(DataExch, Database::"Vendor Bank Account", VendorBankAccount.FieldNo(IBAN), VendorIBAN);

        // [WHEN] Run codeunit Pre-map Incoming Purch. Doc, which is run when Purchase Invoice is created from Incoming Document.
        Codeunit.Run(Codeunit::"Pre-map Incoming Purch. Doc", DataExch);

        // [THEN] Vendor "V2" with Blocked = Payment is selected for Purchase Invoice.
        Assert.AreEqual(
            Format(Vendor."No."), GetIntermediateTableRow(DataExch, Database::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."), 1), '');
    end;

    [Test]
    procedure FindBuyFromVendorByIBANWhenBlockedAllVendor();
    var
        DataExch: Record "Data Exch.";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        VendorBankAccount: Record "Vendor Bank Account";
        VendorIBAN: Text[20];
        FirstVendorNo: Code[20];
    begin
        // [SCENARIO 418945] When multiple vendors have the same GLN and they only has Blocked = All, Vendor with Blocked "All" is selected for Purchase Invoice created from Incoming Document.
        Initialize();
        SetupTestTables(DataExch);

        // [GIVEN] Two Vendors with blank GLN and VAT. Each has Vendor Bank Account with IBAN = "A". Both Vendor "V1" and "V2" has Blocked = All.
        // [GIVEN] Incoming Document with Vendor No. = "", Vendor VAT Registration No. = "" and Vendor IBAN = "A".
        VendorIBAN := LibraryUtility.GenerateGUID();
        CreateVendorWithBankAccount(Vendor, "Vendor Blocked"::All, VendorIBAN, '', '');
        FirstVendorNo := Vendor."No.";
        CreateVendorWithBankAccount(Vendor, "Vendor Blocked"::All, VendorIBAN, '', '');

        DeleteIntermediateTableRow(DataExch, Database::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."));
        DeleteIntermediateTableRow(DataExch, Database::Vendor, Vendor.FieldNo("VAT Registration No."));
        InsertIntermediateTableRow(DataExch, Database::"Vendor Bank Account", VendorBankAccount.FieldNo(IBAN), VendorIBAN);

        // [WHEN] Run codeunit Pre-map Incoming Purch. Doc, which is run when Purchase Invoice is created from Incoming Document.
        Codeunit.Run(Codeunit::"Pre-map Incoming Purch. Doc", DataExch);

        // [THEN] First blocked Vendor "V1" is selected for Purchase Invoice.
        Assert.AreEqual(
            Format(FirstVendorNo), GetIntermediateTableRow(DataExch, Database::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."), 1), '');
    end;

    [Test]
    procedure FindBuyFromVendorByBankBranchAndAccountNoWhenNonBlockedVendor();
    var
        DataExch: Record "Data Exch.";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        VendorBankAccount: Record "Vendor Bank Account";
        BankBranchNo: Text[20];
        BankAccNo: Text[30];
        NonBlockedVendorNo: Code[20];
    begin
        // [SCENARIO 418945] When multiple vendors have the same Bank Branch No. and Bank Account No. and one has Blocked = "", non-blocked Vendor is selected for Purchase Invoice created from Incoming Document.
        Initialize();
        SetupTestTables(DataExch);

        // [GIVEN] Three Vendors with blank GLN and VAT. Each has Vendor Bank Account with IBAN = "", Bank Branch No. = "A", Bank Account No. = "B".
        // [GIVEN] Vendor "V1" has Blocked = All, "V2" has Blocked = "", "V3" has Blocked = Payment.
        // [GIVEN] Incoming Document with Vendor No. = "", Vendor VAT Registration No. = "" and Vendor IBAN = "", Vendor Bank Branch No. = "A", Vendor Bank Account No. = "B".
        BankBranchNo := LibraryUtility.GenerateGUID();
        BankAccNo := LibraryUtility.GenerateGUID();
        CreateVendorWithBankAccount(Vendor, "Vendor Blocked"::All, '', BankBranchNo, BankAccNo);
        CreateVendorWithBankAccount(Vendor, "Vendor Blocked"::" ", '', BankBranchNo, BankAccNo);
        NonBlockedVendorNo := Vendor."No.";
        CreateVendorWithBankAccount(Vendor, "Vendor Blocked"::Payment, '', BankBranchNo, BankAccNo);

        DeleteIntermediateTableRow(DataExch, Database::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."));
        DeleteIntermediateTableRow(DataExch, Database::Vendor, Vendor.FieldNo("VAT Registration No."));
        InsertIntermediateTableRow(DataExch, Database::"Vendor Bank Account", VendorBankAccount.FieldNo("Bank Branch No."), BankBranchNo);
        InsertIntermediateTableRow(DataExch, Database::"Vendor Bank Account", VendorBankAccount.FieldNo("Bank Account No."), BankAccNo);

        // [WHEN] Run codeunit Pre-map Incoming Purch. Doc, which is run when Purchase Invoice is created from Incoming Document.
        Codeunit.Run(Codeunit::"Pre-map Incoming Purch. Doc", DataExch);

        // [THEN] Non-blocked Vendor "V2" is selected for Purchase Invoice.
        Assert.AreEqual(
            Format(NonBlockedVendorNo), GetIntermediateTableRow(DataExch, Database::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."), 1), '');
    end;

    [Test]
    procedure FindPayToVendorByGLNWhenNonBlockedVendor();
    var
        DataExch: Record "Data Exch.";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        VendorGLN: Text[13];
        NonBlockedVendorNo: Code[20];
    begin
        // [SCENARIO 418945] When multiple vendors have the same GLN and one has Blocked = "", non-blocked Vendor is selected as Pay-to Vendor for Purchase Invoice created from Incoming Document.
        Initialize();
        SetupTestTables(DataExch);

        // [GIVEN] Three Vendors with GLN = "A". Vendor "V1" has Blocked = All, "V2" has Blocked = "", "V3" has Blocked = Payment.
        // [GIVEN] Incoming Document with Pay-to Vendor No. = "A".
        VendorGLN := CreateValidGLN();
        CreateVendor(Vendor, "Vendor Blocked"::All, '', '', '', '', VendorGLN);
        CreateVendor(Vendor, "Vendor Blocked"::" ", '', '', '', '', VendorGLN);
        NonBlockedVendorNo := Vendor."No.";
        CreateVendor(Vendor, "Vendor Blocked"::Payment, '', '', '', '', VendorGLN);

        UpdateIntermediateTableRow(DataExch, Database::"Purchase Header", PurchaseHeader.FieldNo("Pay-to Vendor No."), VendorGLN);

        // [WHEN] Run codeunit Pre-map Incoming Purch. Doc, which is run when Purchase Invoice is created from Incoming Document.
        Codeunit.Run(Codeunit::"Pre-map Incoming Purch. Doc", DataExch);

        // [THEN] Non-blocked Vendor "V2" is selected as Pay-to Vendor for Purchase Invoice.
        Assert.AreEqual(
            Format(NonBlockedVendorNo), GetIntermediateTableRow(DataExch, Database::"Purchase Header", PurchaseHeader.FieldNo("Pay-to Vendor No."), 1), '');

        // tear down
        Vendor.SetRange(GLN, VendorGLN);
        Vendor.DeleteAll();
    end;

    [Test]
    procedure FindPayToVendorByVATWhenNonBlockedVendor();
    var
        DataExch: Record "Data Exch.";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        VatRegNo: Text[20];
        NonBlockedVendorNo: Code[20];
    begin
        // [SCENARIO 418945] When multiple vendors have the same VAT and one has Blocked = "", non-blocked Vendor is selected as Pay-to Vendor for Purchase Invoice created from Incoming Document.
        Initialize();
        SetupTestTables(DataExch);

        // [GIVEN] Three Vendors with blank GLN and VAT Registration No. = "A". Vendor "V1" has Blocked = All, "V2" has Blocked = "", "V3" has Blocked = Payment.
        // [GIVEN] Incoming Document with Pay-to Vendor No. = "" and VAT Registration No. = "A".
        VatRegNo := LibraryUtility.GenerateGUID();
        CreateVendor(Vendor, "Vendor Blocked"::All, '', '', '', VatRegNo, '');
        CreateVendor(Vendor, "Vendor Blocked"::" ", '', '', '', VatRegNo, '');
        NonBlockedVendorNo := Vendor."No.";
        CreateVendor(Vendor, "Vendor Blocked"::Payment, '', '', '', VatRegNo, '');

        DeleteIntermediateTableRow(DataExch, Database::"Purchase Header", PurchaseHeader.FieldNo("Pay-to Vendor No."));
        UpdateIntermediateTableRow(DataExch, Database::"Purchase Header", PurchaseHeader.FieldNo("VAT Registration No."), VatRegNo);

        // [WHEN] Run codeunit Pre-map Incoming Purch. Doc, which is run when Purchase Invoice is created from Incoming Document.
        Codeunit.Run(Codeunit::"Pre-map Incoming Purch. Doc", DataExch);

        // [THEN] Non-blocked Vendor "V2" is selected as Pay-to Vendor for Purchase Invoice.
        Assert.AreEqual(
            Format(NonBlockedVendorNo), GetIntermediateTableRow(DataExch, Database::"Purchase Header", PurchaseHeader.FieldNo("Pay-to Vendor No."), 1), '');
    end;

    [Test]
    procedure FindPayToVendorByNameAndAddressWhenNonBlockedVendor();
    var
        DataExch: Record "Data Exch.";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        VendorName: Text[100];
        VendorAddress: Text[100];
        NonBlockedVendorNo: Code[20];
    begin
        // [SCENARIO 418945] When multiple vendors have the same Name and Address and one has Blocked = "", non-blocked Vendor is selected as Pay-to Vendor for Purchase Invoice created from Incoming Document.
        Initialize();
        SetupTestTables(DataExch);

        // [GIVEN] Three Vendors with blank GLN and VAT, and with Name = "A", Address = "B". Vendor "V1" has Blocked = All, "V2" has Blocked = "", "V3" has Blocked = Payment.
        // [GIVEN] Incoming Document with Pay-to Vendor No. = "", VAT Registration No. = "" and Pay-to Vendor Name = "A", Pay-to Vendor Address = "B".
        VendorName := LibraryUtility.GenerateGUID();
        VendorAddress := LibraryUtility.GenerateGUID();
        CreateVendor(Vendor, "Vendor Blocked"::All, VendorName, VendorAddress, '', '', '');
        CreateVendor(Vendor, "Vendor Blocked"::" ", VendorName, VendorAddress, '', '', '');
        NonBlockedVendorNo := Vendor."No.";
        CreateVendor(Vendor, "Vendor Blocked"::Payment, VendorName, VendorAddress, '', '', '');

        DeleteIntermediateTableRow(DataExch, Database::"Purchase Header", PurchaseHeader.FieldNo("Pay-to Vendor No."));
        DeleteIntermediateTableRow(DataExch, Database::"Purchase Header", PurchaseHeader.FieldNo("VAT Registration No."));
        UpdateIntermediateTableRow(DataExch, Database::"Purchase Header", PurchaseHeader.FieldNo("Pay-to Name"), VendorName);
        InsertIntermediateTableRow(DataExch, Database::"Purchase Header", PurchaseHeader.FieldNo("Pay-to Address"), VendorAddress);

        // [WHEN] Run codeunit Pre-map Incoming Purch. Doc, which is run when Purchase Invoice is created from Incoming Document.
        Codeunit.Run(Codeunit::"Pre-map Incoming Purch. Doc", DataExch);

        // [THEN] Non-blocked Vendor "V2" is selected as Pay-to Vendor for Purchase Invoice.
        Assert.AreEqual(
            Format(NonBlockedVendorNo), GetIntermediateTableRow(DataExch, Database::"Purchase Header", PurchaseHeader.FieldNo("Pay-to Vendor No."), 1), '');
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Invoice Premapping Tests");
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateVendor(var Vendor: Record Vendor; BlockedValue: Enum "Vendor Blocked"; VendorName: Text[100]; VendorAddress: Text[100]; PhoneNo: Text[30]; VATNo: Text[20]; VendorGLN: Code[13])
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate(Name, VendorName);
        Vendor.Validate(Address, VendorAddress);
        Vendor.Validate("Phone No.", PhoneNo);
        Vendor."VAT Registration No." := VATNo;   // to avoid validation warnings
        Vendor.Validate(GLN, VendorGLN);
        Vendor.Validate(Blocked, BlockedValue);
        Vendor.Modify(true);
    end;

    local procedure CreateVendorWithBankAccount(var Vendor: Record Vendor; BlockedValue: Enum "Vendor Blocked"; VendorIBAN: Code[50]; BankBranchNo: Text[20]; BankAccNo: Text[30])
    var
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        CreateVendor(Vendor, BlockedValue, '', '', '', '', '');
        CreateVendorBankAccount(VendorBankAccount, Vendor."No.", VendorIBAN, BankBranchNo, BankAccNo);
    end;

    local procedure CreateVendorBankAccount(var VendorBankAccount: Record "Vendor Bank Account"; VendorNo: Code[20]; VendorIBAN: Code[50]; BankBranchNo: Text[20]; BankAccNo: Text[30])
    begin
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, VendorNo);
        VendorBankAccount."Bank Branch No." := BankBranchNo;
        VendorBankAccount."Bank Account No." := BankAccNo;
        VendorBankAccount.IBAN := VendorIBAN;
        VendorBankAccount.Modify(false);
    end;

    local procedure CreateValidGLN(): Code[13]
    var
        FirstPart: Text;
        CheckDigit: Text;
    begin
        FirstPart := LibraryUtility.GenerateRandomNumericText(12);
        CheckDigit := Format(StrCheckSum(FirstPart, '131313131313'));
        exit(CopyStr(FirstPart + CheckDigit, 1, 13));
    end;

    local procedure SetupDataExchTable(var DataExch: Record "Data Exch.")
    var
        IncomingDocument: Record "Incoming Document";
        DataExchDef: Record "Data Exch. Def";
        EntryNo: Integer;
        IncomingDocEntryNo: Integer;
    begin
        IncomingDocEntryNo := 1;
        if IncomingDocument.FindLast() then
            IncomingDocEntryNo += IncomingDocument."Entry No.";

        IncomingDocument.Init();
        IncomingDocument."Entry No." := IncomingDocEntryNo;
        IncomingDocument.Insert();

        DataExchDef.Init();
        DataExchDef.Code := LibraryUtility.GenerateGUID();
        DataExchDef.Insert();

        EntryNo := 1;

        if DataExch.FindLast() then
            EntryNo += DataExch."Entry No.";

        DataExch.Init();
        DataExch."Entry No." := EntryNo;
        DataExch."Incoming Entry No." := IncomingDocument."Entry No.";
        DataExch."Data Exch. Def Code" := DataExchDef.Code;
        DataExch.Insert();
    end;

    local procedure SetupValidIntermediateTable(DataExch: Record "Data Exch."; var BuyFromVendor: Record Vendor; var PayToVendor: Record Vendor; var Item1: Record Item; var Item2: Record Item; var UnitOfMeasure: Record "Unit of Measure"; var Qty: Decimal; var Description: Text[100])
    var
        PurchaseHeader: Record "Purchase Header";
        DocumentCurrency: Code[20];
    begin
        DocumentCurrency := LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("Currency Code"), DATABASE::"Purchase Header");
        InsertHeaderToIntermediateTable(DataExch, BuyFromVendor, PayToVendor, DocumentCurrency);

        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        UnitOfMeasure."International Standard Code" :=
          LibraryUtility.GenerateRandomCode(UnitOfMeasure.FieldNo("International Standard Code"), DATABASE::"Unit of Measure");
        UnitOfMeasure.Modify();

        // Create lines
        Qty := LibraryRandom.RandDec(100, 2);
        InsertItemToIntermediateTable(DataExch, Item1, DocumentCurrency, BuyFromVendor, UnitOfMeasure, 2, Qty);
        InsertItemToIntermediateTable(DataExch, Item2, DocumentCurrency, BuyFromVendor, UnitOfMeasure, 3, Qty);
        InsertDescriptionLineToIntermediateTable(DataExch, 4, Description);
    end;

    local procedure InsertHeaderToIntermediateTable(DataExch: Record "Data Exch."; var BuyFromVendor: Record Vendor; var PayToVendor: Record Vendor; DocumentCurrency: Code[20])
    var
        CompanyInfo: Record "Company Information";
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        PreMapIncomingPurchDoc: Codeunit "Pre-map Incoming Purch. Doc";
    begin
        CompanyInfo.Get();
        CompanyInfo.GLN := LibraryUtility.GenerateGUID();
        CompanyInfo."VAT Registration No." := LibraryERM.GenerateVATRegistrationNo(CompanyInfo."Country/Region Code");
        CompanyInfo.Modify(true);

        InsertIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Document Type"),
          PreMapIncomingPurchDoc.GetDocumentTypeOptionCaption(PurchaseHeader."Document Type"::Invoice.AsInteger()));
        InsertIntermediateTableRow(DataExch, DATABASE::"Company Information", CompanyInfo.FieldNo(Name), CompanyInfo.Name);
        InsertIntermediateTableRow(DataExch, DATABASE::"Company Information", CompanyInfo.FieldNo(Address), CompanyInfo.Address);
        InsertIntermediateTableRow(DataExch, DATABASE::"Company Information", CompanyInfo.FieldNo(GLN), CompanyInfo.GLN);
        InsertIntermediateTableRow(DataExch, DATABASE::"Company Information", CompanyInfo.FieldNo("VAT Registration No.")
          , CompanyInfo."VAT Registration No.");

        InsertIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Currency Code"), DocumentCurrency);
        InsertIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Tax Area Code")
          , DocumentCurrency);

        LibraryPurchase.CreateVendor(BuyFromVendor);
        BuyFromVendor.GLN := LibraryUtility.GenerateGUID();
        BuyFromVendor."VAT Registration No." := LibraryUtility.GenerateGUID();
        BuyFromVendor.Address := LibraryUtility.GenerateRandomCode(BuyFromVendor.FieldNo(Address), DATABASE::Vendor);
        BuyFromVendor.Name := LibraryUtility.GenerateRandomCode(BuyFromVendor.FieldNo(Name), DATABASE::Vendor);
        BuyFromVendor.Modify(true);

        InsertIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor No."),
          BuyFromVendor.GLN);
        InsertIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Vendor Name"),
          BuyFromVendor.Name);
        InsertIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Buy-from Address"),
          BuyFromVendor.Address);
        InsertIntermediateTableRow(DataExch, DATABASE::Vendor, Vendor.FieldNo("VAT Registration No."),
          BuyFromVendor."VAT Registration No.");

        LibraryPurchase.CreateVendor(PayToVendor);
        PayToVendor.GLN := LibraryUtility.GenerateGUID();
        PayToVendor."VAT Registration No." := LibraryUtility.GenerateGUID();
        PayToVendor.Name := LibraryUtility.GenerateRandomCode(PayToVendor.FieldNo(Name), DATABASE::Vendor);
        PayToVendor.Modify(true);

        InsertIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Pay-to Vendor No."), PayToVendor.GLN);
        InsertIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Pay-to Name"), PayToVendor.Name);
        InsertIntermediateTableRow(DataExch, DATABASE::"Purchase Header", PurchaseHeader.FieldNo("VAT Registration No."),
          PayToVendor."VAT Registration No.");
    end;

    local procedure InsertItemToIntermediateTable(var DataExch: Record "Data Exch."; var Item: Record Item; DocumentCurrency: Text[250]; BuyFromVendor: Record Vendor; UnitOfMeasure: Record "Unit of Measure"; RowNo: Integer; Qty: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
        ItemReference: Record "Item Reference";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        InsertIntermediateTableRowWithRecordNo(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo("Currency Code"),
          DocumentCurrency, RowNo, 1);

        LibraryInventory.CreateItem(Item);
        Item.GTIN := LibraryUtility.GenerateRandomCode(Item.FieldNo(GTIN), DATABASE::Item);
        Item.Modify();
        InsertIntermediateTableRowWithRecordNo(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo("No."),
          Item.GTIN, RowNo, 1);

        LibraryItemReference.CreateItemReference(
          ItemReference, Item."No.", ItemReference."Reference Type"::Vendor, BuyFromVendor."No.");
        InsertIntermediateTableRowWithRecordNo(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo("Item Reference No."),
          ItemReference."Reference No.", RowNo, 1);
        InsertIntermediateTableRowWithRecordNo(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo(Description),
          ItemNameTxt, RowNo, 1);

        VATPostingSetup.Get(BuyFromVendor."VAT Bus. Posting Group", Item."VAT Prod. Posting Group");
        InsertIntermediateTableRowWithRecordNo(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo("VAT %"),
          Format(VATPostingSetup."VAT %"), RowNo, 1);
        InsertIntermediateTableRowWithRecordNo(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo("Unit of Measure Code"),
          UnitOfMeasure."International Standard Code", RowNo, 1);
        InsertIntermediateTableRowWithRecordNo(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo(Quantity),
          Format(Qty, 0, 9), RowNo, 1);
    end;

    local procedure InsertDescriptionLineToIntermediateTable(var DataExch: Record "Data Exch."; RowNo: Integer; var Description: Text[100])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Only Type and Description should be filled in for this line
        InsertIntermediateTableRowWithRecordNo(DataExch, DATABASE::"Purchase Line",
          PurchaseLine.FieldNo(Type), Format(PurchaseLine.Type::" ", 0, 9), RowNo, 1);
        if Description = '' then
            Description := LibraryUtility.GenerateRandomCode(PurchaseLine.FieldNo(Description), DATABASE::"Purchase Line");
        InsertIntermediateTableRowWithRecordNo(DataExch, DATABASE::"Purchase Line",
          PurchaseLine.FieldNo(Description), Description, RowNo, 1);
    end;

    local procedure InsertNonItemToIntermediateTable(var DataExch: Record "Data Exch."; UnitOfMeasure: Record "Unit of Measure"; DocumentCurrency: Text[250]; RowNo: Integer; Qty: Decimal; Description: Text[250])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        InsertIntermediateTableRowWithRecordNo(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo("Currency Code"),
          DocumentCurrency, RowNo, 1);
        InsertIntermediateTableRowWithRecordNo(DataExch, DATABASE::"Purchase Line",
          PurchaseLine.FieldNo(Description), Description, RowNo, 1);
        InsertIntermediateTableRowWithRecordNo(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo(Quantity),
          Format(Qty, 0, 9), RowNo, 1);
        InsertIntermediateTableRowWithRecordNo(DataExch, DATABASE::"Purchase Line", PurchaseLine.FieldNo("Unit of Measure Code"),
          UnitOfMeasure."International Standard Code", RowNo, 1);
    end;

    local procedure SetupValidNonItemIntermediateTable(DataExch: Record "Data Exch."; var BuyFromVendor: Record Vendor; var PayToVendor: Record Vendor; var UnitOfMeasure: Record "Unit of Measure"; var Qty: Decimal; var Description: Text[100])
    var
        PurchaseHeader: Record "Purchase Header";
        DocumentCurrency: Code[20];
    begin
        DocumentCurrency := LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("Currency Code"), DATABASE::"Purchase Header");
        InsertHeaderToIntermediateTable(DataExch, BuyFromVendor, PayToVendor, DocumentCurrency);

        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        UnitOfMeasure."International Standard Code" :=
          LibraryUtility.GenerateRandomCode(UnitOfMeasure.FieldNo("International Standard Code"), DATABASE::"Unit of Measure");
        UnitOfMeasure.Modify();

        // Create lines
        InsertDescriptionLineToIntermediateTable(DataExch, 1, Description);
        Qty := LibraryRandom.RandDec(100, 2);
        InsertNonItemToIntermediateTable(DataExch, UnitOfMeasure, DocumentCurrency, 2, Qty, Description);
    end;

    local procedure InsertIntermediateTableRow(DataExch: Record "Data Exch."; TableID: Integer; FieldID: Integer; Value: Text[250])
    begin
        InsertIntermediateTableRowWithRecordNo(DataExch, TableID, FieldID, Value, 1, 0);
    end;

    local procedure InsertIntermediateTableRowWithRecordNo(DataExch: Record "Data Exch."; TableID: Integer; FieldID: Integer; Value: Text[250]; RecordNo: Integer; ParentRecordNo: Integer)
    var
        IntermediateDataImport: Record "Intermediate Data Import";
    begin
        IntermediateDataImport.Init();
        IntermediateDataImport."Data Exch. No." := DataExch."Entry No.";
        IntermediateDataImport."Table ID" := TableID;
        IntermediateDataImport."Record No." := RecordNo;
        IntermediateDataImport."Field ID" := FieldID;
        IntermediateDataImport.Value := Value;
        IntermediateDataImport."Parent Record No." := ParentRecordNo;
        IntermediateDataImport.Insert();
    end;

    local procedure UpdateIntermediateTableRow(DataExch: Record "Data Exch."; TableNo: Integer; FieldNo: Integer; Value: Text[250])
    var
        IntermediateDataImport: Record "Intermediate Data Import";
    begin
        IntermediateDataImport.SetRange("Data Exch. No.", DataExch."Entry No.");
        IntermediateDataImport.SetRange("Table ID", TableNo);
        IntermediateDataImport.SetRange("Field ID", FieldNo);
        IntermediateDataImport.FindFirst();
        IntermediateDataImport.Value := Value;
        IntermediateDataImport.Modify();
    end;

    local procedure DeleteIntermediateTableRow(DataExch: Record "Data Exch."; TableNo: Integer; FieldNo: Integer)
    var
        IntermediateDataImport: Record "Intermediate Data Import";
    begin
        IntermediateDataImport.SetRange("Data Exch. No.", DataExch."Entry No.");
        IntermediateDataImport.SetRange("Table ID", TableNo);
        IntermediateDataImport.SetRange("Field ID", FieldNo);
        IntermediateDataImport.DeleteAll();
    end;

    local procedure GetIntermediateTableRow(DataExch: Record "Data Exch."; TableNo: Integer; FieldNo: Integer; RecordNo: Integer): Text
    var
        IntermediateDataImport: Record "Intermediate Data Import";
    begin
        IntermediateDataImport.SetRange("Data Exch. No.", DataExch."Entry No.");
        IntermediateDataImport.SetRange("Table ID", TableNo);
        IntermediateDataImport.SetRange("Field ID", FieldNo);
        IntermediateDataImport.SetRange("Record No.", RecordNo);
        IntermediateDataImport.FindFirst();
        exit(IntermediateDataImport.Value);
    end;

    local procedure ModifyOCRData(var IncomingDocument: Record "Incoming Document")
    var
        Currency: Record Currency;
        OCRDataCorrection: TestPage "OCR Data Correction";
    begin
        OCRDataCorrection.OpenEdit();
        OCRDataCorrection.GotoRecord(IncomingDocument);
        OCRDataCorrection."Vendor Bank Branch No.".SetValue(LibraryUtility.GenerateGUID());
        OCRDataCorrection."Vendor Bank Account No.".SetValue(LibraryUtility.GenerateGUID());
        OCRDataCorrection."Vendor Name".SetValue(LibraryUtility.GenerateGUID());
        OCRDataCorrection."Vendor IBAN".SetValue(LibraryUtility.GenerateGUID());
        OCRDataCorrection."Vendor VAT Registration No.".SetValue(LibraryUtility.GenerateGUID());
        OCRDataCorrection."Vendor Invoice No.".SetValue(LibraryUtility.GenerateGUID());
        OCRDataCorrection."Document Date".SetValue(LibraryRandom.RandDateFrom(Today, 10));
        OCRDataCorrection."Due Date".SetValue(LibraryRandom.RandDateFrom(Today + 10, 20));
        OCRDataCorrection."Order No.".SetValue(LibraryUtility.GenerateGUID());
        LibraryERM.CreateCurrency(Currency);
        OCRDataCorrection."Currency Code".SetValue(Currency.Code);
        OCRDataCorrection."Amount Excl. VAT".SetValue(LibraryRandom.RandDec(1000, 2));
        OCRDataCorrection."Amount Incl. VAT".SetValue(LibraryRandom.RandDec(1000, 2));
        OCRDataCorrection."VAT Amount".SetValue(LibraryRandom.RandDec(1000, 2));
        OCRDataCorrection.OK().Invoke();
    end;

    local procedure VerifyNoErrorMessages(EntryNo: Integer; TableNo: Integer; FieldNo: Integer)
    var
        ErrorMessage: Record "Error Message";
        IncomingDocument: Record "Incoming Document";
    begin
        IncomingDocument.Get(EntryNo);
        ErrorMessage.SetRange("Context Record ID", IncomingDocument.RecordId);
        ErrorMessage.SetRange("Table Number", TableNo);
        ErrorMessage.SetRange("Field Number", FieldNo);
        Assert.RecordIsEmpty(ErrorMessage);
    end;

    local procedure AssertExpectedError(DataExch: Record "Data Exch."; ExpectedError: Text)
    var
        IncomingDocument: Record "Incoming Document";
        ErrorMessage: Record "Error Message";
        ErrorMessages: TestPage "Error Messages";
    begin
        IncomingDocument.Get(DataExch."Incoming Entry No.");
        ErrorMessage.SetRange("Context Record ID", IncomingDocument.RecordId);
        ErrorMessage.SetFilter("Message", ExpectedError);
        Assert.IsTrue(ErrorMessage.FindFirst(), StrSubstNo(ExpectedErrorMsgNotFoundErr, ExpectedError, ErrorMessage.TableCaption()));
        ErrorMessages.Trap();
        ErrorMessage.SetContext(IncomingDocument);
        ErrorMessage.ShowErrorMessages(false);
        ErrorMessages.FindFirstField(Description, ExpectedError);
        ErrorMessages.Source.DrillDown();
        ErrorMessages.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure HandleVendorList(var VendorLookup: TestPage "Vendor Lookup")
    begin
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure HandleCompanyInformation(var CompanyInformation: TestPage "Company Information")
    begin
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure HandleItemList(var ItemLookup: TestPage "Item Lookup")
    begin
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure HandleUnitsOfMeasure(var UnitsOfMeasure: TestPage "Units of Measure")
    begin
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure HandleTextToAccountMappingWksh(var TextToAccountMappingWksh: TestPage "Text-to-Account Mapping Wksh.")
    begin
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure HandlePurchaseInvoiceCard(var PurchaseInvoice: TestPage "Purchase Invoice")
    var
        VendorInvoiceNoVar: Variant;
    begin
        LibraryVariableStorage.Dequeue(VendorInvoiceNoVar);
        Assert.AreEqual(VendorInvoiceNoVar, PurchaseInvoice."Vendor Invoice No.".Value, '');
    end;

    [PageHandler]
    procedure DataExchDefCardHandler(var DataExchDefCard: TestPage "Data Exch Def Card")
    begin
        DataExchDefCard.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure HandlePurchaseInvoicesList(var PostedPurchaseInvoices: TestPage "Posted Purchase Invoices")
    begin
    end;

    local procedure CreateAccountMapping(var TextToAccMapping: Record "Text-to-Account Mapping"; Keyword: Text[50]; BalSourceType: Option; BalSourceNo: Code[20]; VendorNo: Code[20])
    var
        GLAccount: Record "G/L Account";
        LastLineNo: Integer;
    begin
        if TextToAccMapping.FindLast() then
            LastLineNo := TextToAccMapping."Line No.";

        TextToAccMapping.Init();
        TextToAccMapping.Validate("Line No.", LastLineNo + 1);
        TextToAccMapping.Validate("Mapping Text", Keyword);
        LibraryERM.CreateGLAccount(GLAccount);
        TextToAccMapping.Validate("Vendor No.", VendorNo);
        TextToAccMapping.Validate("Debit Acc. No.", GLAccount."No.");
        LibraryERM.CreateGLAccount(GLAccount);
        TextToAccMapping.Validate("Credit Acc. No.", GLAccount."No.");
        TextToAccMapping.Validate("Bal. Source Type", BalSourceType);
        TextToAccMapping.Validate("Bal. Source No.", BalSourceNo);

        TextToAccMapping.Insert(true);
    end;
}

