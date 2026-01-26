codeunit 144208 "FatturaPA Unit Tests"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [FatturaPA] [UT]
    end;

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryITLocalization: Codeunit "Library - IT Localization";
        IsInitialized: Boolean;

    [Test]
    procedure FCYConvertsToLCYWhenPrepareDocumentToExport()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempFatturaHeader: Record "Fattura Header" temporary;
        TempFatturaLine: Record "Fattura Line" temporary;
        FatturaDocHelper: Codeunit "Fattura Doc. Helper";
        RecRef: RecordRef;
    begin
        // [FEAUTURE] [Sales] [FCY]
        // [SCENARIO 308849] All the FCY amounts of the document converts to LCY when runnning CollectDocumentInformation of "Fattura Doc. Helper" codeunit again posted sales invoice

        Initialize();
        CreateSalesInvoiceFCY(SalesHeader, SalesLine);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        RecRef.GetTable(SalesInvoiceHeader);
        FatturaDocHelper.InitializeErrorLog(SalesInvoiceHeader);
        FatturaDocHelper.CollectDocumentInformation(TempFatturaHeader, TempFatturaLine, RecRef);
        TempFatturaLine.FindFirst();
        Assert.AreEqual(ExchangeToLCYAmount(SalesHeader, SalesLine."Unit Price"), TempFatturaLine."Unit Price", '');
        Assert.AreEqual(ExchangeToLCYAmount(SalesHeader, SalesLine.Amount), TempFatturaLine.Amount, '');
        Assert.AreEqual(ExchangeToLCYAmount(SalesHeader, SalesLine."Amount Including VAT"), TempFatturaHeader."Total Amount", '');
    end;

    [Test]
    procedure FatturaFileNameGotTenCharsFromProgresiveNo()
    var
        CompanyInformation: Record "Company Information";
        FatturaDocHelper: Codeunit "Fattura Doc. Helper";
        ProgressiveNo: Code[10];
        ZeroNo: Code[10];
        BaseString: Text;
    begin
        // [SCENARIO 305855] When a file name generates by function GetFileName of "Fattura Doc. Helper" codeunit it takes ten chars from "Progressive No." passed as parameter

        Initialize();
        ProgressiveNo := CopyStr(LibraryUtility.GenerateRandomText(10), 1, MaxStrLen(ProgressiveNo));
        CompanyInformation.Get();
        BaseString := CopyStr(DelChr(ProgressiveNo, '=', ',?;.:/-_ '), 1, 10);
        ZeroNo := PadStr('', 10 - StrLen(BaseString), '0');
        Assert.AreEqual(
          CompanyInformation."Country/Region Code" + CompanyInformation."Fiscal Code" + '_' + ZeroNo + BaseString,
          FatturaDocHelper.GetFileName(ProgressiveNo), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultipleExtendedTextFattuesLines()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempFatturaHeader: Record "Fattura Header" temporary;
        TempFatturaLine: Record "Fattura Line" temporary;
        FatturaDocHelper: Codeunit "Fattura Doc. Helper";
        RecRef: RecordRef;
    begin
        // [SCENARIO X] Multiple Fattura Line records with "Line Type" = "Extended Text" can be generated

        Initialize();
        CreateSalesDocInvWithMultipleExtTexts(SalesHeader);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        RecRef.GetTable(SalesInvoiceHeader);

        FatturaDocHelper.InitializeErrorLog(SalesInvoiceHeader);
        FatturaDocHelper.CollectDocumentInformation(TempFatturaHeader, TempFatturaLine, RecRef);

        TempFatturaLine.SetRange("Line Type", TempFatturaLine."Line Type"::"Extended Text");
        Assert.RecordCount(TempFatturaLine, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FatturaLineDescriptionGetsResetCorrectly()
    var
        VATPostingSetup: array[2] of Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DummyGLAccount: Record "G/L Account";
        TempFatturaLine: Record "Fattura Line" temporary;
        TempFatturaHeader: Record "Fattura Header" temporary;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Customer: Record Customer;
        FatturaDocHelper: Codeunit "Fattura Doc. Helper";
        RecRef: RecordRef;
        VATRate: array[2] of Decimal;
    begin
        // [SCENARIO 319765] When collecting VAT Fattura Lines for export description gets reset between lines and is blank when expected
        Initialize();

        // [GIVEN] Customer with VAT Business Posting Group
        Customer.Get(CreateCustomerNo());

        // [GIVEN] 2 VAT Posting Setups with the Same VAT Business Posting Group. Different Product Posting Groups: VAT Rate 1 = "10", VAT Rate 2 = "0"
        VATRate[1] := LibraryRandom.RandDec(10, 2);
        CreateTwoVATPostingSetupsWithSameBusPostingGroup(VATPostingSetup, VATRate, Customer."VAT Bus. Posting Group");

        // [GIVEN] Sales Invoice For Customer with 2 lines, 1 line for each Product Posting Group
        CreateFatturaSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup[1],
            DummyGLAccount."Gen. Posting Type"::Sale), LibraryRandom.RandInt(10));
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup[2],
            DummyGLAccount."Gen. Posting Type"::Sale), LibraryRandom.RandInt(10));

        // [GIVEN] Sales Invoice was posted
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        RecRef.GetTable(SalesInvoiceHeader);

        // [WHEN] Run CollectDocumentInformation on this invoice
        FatturaDocHelper.InitializeErrorLog(SalesInvoiceHeader);
        FatturaDocHelper.CollectDocumentInformation(TempFatturaHeader, TempFatturaLine, RecRef);

        // [THEN] Fattura VAT Line for VAT Rate 1 has description = "I"
        VerifyVATLineDescription(TempFatturaLine, VATRate[1], 'I');

        // [THEN] Fattura VAT Line for VAT Rate 2 has description Blank
        VerifyVATLineDescription(TempFatturaLine, VATRate[2], '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FatturaLineGetItemFunction_NotItem()
    var
        FatturaLine: Record "Fattura Line";
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        // [SCENARIO 406393] Function GetItem of Fattura Line table returns false if Type is not item

        Initialize();
        FatturaLine.Type := Format(SalesLine.Type::"G/L Account");
        Assert.IsFalse(FatturaLine.GetItem(Item), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FatturaLineGetItemFunction_ItemNotFound()
    var
        FatturaLine: Record "Fattura Line";
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        // [SCENARIO 406393] Function GetItem of Fattura Line table returns false if Item is not found

        Initialize();
        FatturaLine.Type := Format(SalesLine.Type::Item);
        Assert.IsFalse(FatturaLine.GetItem(Item), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FatturaLineGetItemFunction_ItemHasBlankGTIN()
    var
        FatturaLine: Record "Fattura Line";
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        // [SCENARIO 406393] Function GetItem of Fattura Line table returns false if Item has blank GTIN

        Initialize();
        LibraryInventory.CreateItem(Item);
        FatturaLine.Type := Format(SalesLine.Type::Item);
        FatturaLine."No." := Item."No.";
        Assert.IsFalse(FatturaLine.GetItem(Item), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FatturaLineGetItemFunction_ItemExistsWithGTIN()
    var
        FatturaLine: Record "Fattura Line";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        LineItem: Record Item;
    begin
        // [SCENARIO 406393] Function GetItem of Fattura Line table returns true if Item has GTIN

        Initialize();
        LibraryInventory.CreateItem(Item);
        Item.GTIN := LibraryUtility.GenerateGUID();
        Item.Modify();
        FatturaLine.Type := Format(SalesLine.Type::Item);
        FatturaLine."No." := Item."No.";
        Assert.IsTrue(FatturaLine.GetItem(LineItem), '');
        LineItem.TestField("No.", Item."No.");
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;

        LibraryITLocalization.SetupFatturaPA();
        LibrarySetupStorage.Save(DATABASE::"Company Information");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        IsInitialized := true;
    end;

    local procedure CreateSalesInvoiceFCY(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        CustNo: Code[20];
    begin
        CustNo := CreateCustomerNo();
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustNo);
        SalesHeader.Validate(
          "Payment Terms Code", LibraryITLocalization.CreateFatturaPaymentTermsCode());
        SalesHeader.Validate(
          "Payment Method Code", LibraryITLocalization.CreateFatturaPaymentMethodCode());
        SalesHeader.Validate("Currency Code", LibraryERM.CreateCurrencyWithRandomExchRates());
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(100));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesDocInvWithMultipleExtTexts(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        TransferExtendedText: Codeunit "Transfer Extended Text";
        i: Integer;
    begin
        CreateFatturaSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomerNo());
        for i := 1 to 2 do begin
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItemWithExtendedText(), LibraryRandom.RandInt(100));
            SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
            SalesLine.Modify(true);
            TransferExtendedText.SalesCheckIfAnyExtText(SalesLine, true);
            TransferExtendedText.InsertSalesExtText(SalesLine);
        end;
    end;

    local procedure CreateFatturaSalesHeader(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Payment Terms Code", LibraryITLocalization.CreateFatturaPaymentTermsCode());
        SalesHeader.Validate("Payment Method Code", LibraryITLocalization.CreateFatturaPaymentMethodCode());
        SalesHeader.Modify(true);
    end;

    local procedure CreateCustomerNo(): Code[20]
    var
        Customer: Record Customer;
    begin
        exit(
          LibraryITLocalization.CreateFatturaCustomerNo(
            CopyStr(LibraryUtility.GenerateRandomCode(Customer.FieldNo("PA Code"), DATABASE::Customer), 1, 6)));
    end;

    local procedure CreateTwoVATPostingSetupsWithSameBusPostingGroup(var VATPostingSetup: array[2] of Record "VAT Posting Setup"; VATRate: array[2] of Decimal; VATBusinessPostingGroup: Code[20])
    var
        i: Integer;
    begin
        for i := 1 to ArrayLen(VATPostingSetup) do begin
            LibraryERM.CreateVATPostingSetupWithAccounts(
              VATPostingSetup[i], VATPostingSetup[i]."VAT Calculation Type"::"Normal VAT", VATRate[i]);
            VATPostingSetup[i].Validate("VAT Bus. Posting Group", VATBusinessPostingGroup);
            VATPostingSetup[i].Insert(true);
        end;
    end;

    local procedure CreateItemWithExtendedText(): Code[20]
    var
        Item: Record Item;
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
    begin
        LibraryInventory.CreateItem(Item);
        Item.Rename(PadStr(Item."No.", MaxStrLen(Item."No."), 'X'));
        LibraryInventory.CreateExtendedTextHeaderItem(ExtendedTextHeader, Item."No.");
        ExtendedTextHeader.Validate("Starting Date", WorkDate());
        ExtendedTextHeader.Validate("Ending Date", WorkDate());
        ExtendedTextHeader.Validate("Sales Invoice", true);
        ExtendedTextHeader.Validate("Sales Credit Memo", true);
        ExtendedTextHeader.Validate("Service Invoice", true);
        ExtendedTextHeader.Validate("Service Credit Memo", true);
        ExtendedTextHeader.Modify(true);
        LibraryInventory.CreateExtendedTextLineItem(ExtendedTextLine, ExtendedTextHeader);
        ExtendedTextLine.Validate(Text, CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(ExtendedTextLine.Text)));
        ExtendedTextLine.Modify(true);
        exit(Item."No.");
    end;

    local procedure ExchangeToLCYAmount(SalesHeader: Record "Sales Header"; Amount: Decimal): Decimal
    var
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        Currency.Get(SalesHeader."Currency Code");
        Currency.InitRoundingPrecision();
        exit(
          Round(
            CurrExchRate.ExchangeAmtFCYToLCY(
              SalesHeader."Posting Date", SalesHeader."Currency Code",
              Amount, SalesHeader."Currency Factor"),
            Currency."Amount Rounding Precision"));
    end;

    local procedure VerifyVATLineDescription(var TempFatturaLine: Record "Fattura Line" temporary; VATRate: Decimal; DescriptionText: Text[250])
    begin
        TempFatturaLine.SetRange("Line Type", TempFatturaLine."Line Type"::VAT);
        TempFatturaLine.SetRange("VAT %", VATRate);
        TempFatturaLine.FindFirst();
        TempFatturaLine.TestField(Description, DescriptionText);
    end;
}

