codeunit 148000 "SII Period Tests"
{
    // // [FEATURE] [SII]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibrarySII: Codeunit "Library - SII";
        IsInitialized: Boolean;
        UploadType: Option Regular,Intracommunity,RetryAccepted;
        IncorrectXMLDocErr: Label 'The XML document was not generated properly.';

    [Test]
    procedure SalesInvoiceQuarterPeriod()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [SCENARIO 557603] The Periodo XML node in the Sales Invoice XML file is generated correctly for the Quarterly Tax Period
        Initialize();

        // [GIVEN] Tax period is set to Quarterly in SII Setup
        SetTaxPeriod(Enum::"SII Tax Period"::Quarterly);

        // [GIVEN] Posted sales invoice with "Posting Date" = 12.12.2024
        PostSalesDocWithInvOrCrMemoType(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, LibrarySales.CreateCustomerNo(), 0);

        // [WHEN] Create SII xml
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] 'sii:Periodo' is '4T' in the xml file
        LibrarySII.ValidateElementByName(
            XMLDoc, 'sii:Periodo',
            Format((Date2DMY(CustLedgerEntry."Posting Date", 2) - 1) div 3 + 1) + 'T');
    end;

    [Test]
    procedure SalesCrMemoQuarterPeriod()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [SCENARIO 557603] The Periodo XML node in the Sales Credit Memo XML file is generated correctly for the Quarterly Tax Period

        Initialize();

        // [GIVEN] Tax period is set to Quarterly in SII Setup
        SetTaxPeriod(Enum::"SII Tax Period"::Quarterly);

        // [GIVEN] Posted sales credit memo with "Posting Date" = 12.12.2024
        PostSalesDocWithInvOrCrMemoType(CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", LibrarySales.CreateCustomerNo(), 0);

        // [WHEN] Create SII xml
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] 'sii:Periodo' is '4T' in the xml file
        LibrarySII.ValidateElementByName(
            XMLDoc, 'sii:Periodo',
            Format((Date2DMY(CustLedgerEntry."Posting Date", 2) - 1) div 3 + 1) + 'T');
    end;

    [Test]
    procedure SalesRemovalCrMemoQuarterPeriod()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [SCENARIO 557603] The Periodo XML node in the removal Sales Credit Memo XML file is generated correctly for the Quarterly Tax Period

        Initialize();

        // [GIVEN] Tax period is set to Quarterly in SII Setup
        SetTaxPeriod(Enum::"SII Tax Period"::Quarterly);

        // [GIVEN] Posted removal sales credit memo with "Posting Date" = 12.12.2024
        PostSalesDocWithInvOrCrMemoType(CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", LibrarySales.CreateCustomerNo(), CustLedgerEntry."Correction Type"::Removal);

        // [WHEN] Create SII xml
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] 'sii:Periodo' is '4T' in the xml file
        LibrarySII.ValidateElementByName(
            XMLDoc, 'sii:Periodo',
            Format((Date2DMY(CustLedgerEntry."Posting Date", 2) - 1) div 3 + 1) + 'T');
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();
        LibraryTestInitialize.OnTestInitialize(Codeunit::"SII Period Tests");
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"SII Period Tests");
        LibrarySII.InitSetup(true, false);
        LibrarySII.BindSubscriptionJobQueue();
        LibrarySetupStorage.Save(Database::"VAT Setup");
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"SII Period Tests");
    end;

    local procedure SetTaxPeriod(TaxPeriod: Enum "SII Tax Period")
    var
        SIISetup: Record "SII Setup";
    begin
        SIISetup.Get();
        SIISetup.Validate("Tax Period", TaxPeriod);
        SIISetup.Modify(true);
    end;

    local procedure PostSalesDocWithInvOrCrMemoType(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocType: Enum "Sales Document Type"; CustNo: Code[20]; CorrType: Option)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, CustNo);
        SalesHeader.Validate("Correction Type", CorrType);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), LibraryRandom.RandInt(100));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocType, LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;
}

