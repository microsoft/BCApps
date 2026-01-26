codeunit 144106 "Miscellaneous Bugs IT"
{
    //
    //  1. Test to verify Vendor Bank Account No. on Vendor Bill Card after Insert Line on Manual Vendor Payment Line.
    //  2. Test to verify VAT entry after posting Payment Journal applied to Purchase Prepayment Invoice and Purchase Invoice with Unrealized VAT.
    //  3. Test to verify VAT entry after posting Cash Receipt Journal applied to Sales Prepayment Invoice and Sales Invoice with Unrealized VAT.
    //  4. Test to verify G/L entry after posting Sales Order with Payment Method Code that uses a Balance Account.
    //  5. Test to verify Reporting Tab values on Posted Transfer Shipment page after posting Transfer Order as Ship.
    //  6. Test to verify Description on G/L Book - Print Report after Sales Invoice is posted and Name is updated on Customer.
    //  7. Test to verify Name on VAT Register - Print Report after Sales Invoice is posted and Name is updated on Customer.
    //  8. Test to verify Amount on Intrastat Journal Line after posting the Purchase Invoice and Payment on same Posting Date.
    //  9. Test to verify Amount on Intrastat Journal Line after posting the Purchase Invoice and Payment on different Posting Date.
    //
    // Covers Test Cases for WI - 349083
    // ------------------------------------------------------------------------------------
    // Test Function Name                                                            TFS ID
    // ------------------------------------------------------------------------------------
    // VendorBankAccountNoOnVendorBillCard                                           348345
    // PaymentJournalAppliedToPurchPrepmtInvAndPurchInv
    // CashRcptJournalAppliedToSalesPrepmtInvAndSalesInv                             346203
    // PostSalesOrderPaymentMethodCodeWithBalanceAccount                             348959
    // ReportingValuesOnPostedTransferShipmentPage                                   345104
    //
    // Covers Test Cases for WI - 349772
    // ------------------------------------------------------------------------------------
    // Test Function Name                                                            TFS ID
    // ------------------------------------------------------------------------------------
    // DescriptionOnGLBookPrintReportAfterPostSalesInv
    // NameOnVATRegisterPrintReportAfterPostSalesInv                                 345846
    // AmountOnIntrastatJnlLineWithSamePostingDate
    // AmountOnIntrastatJnlLineWithDiffPostingDate                                   347895

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryITLocalization: Codeunit "Library - IT Localization";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        AmountErr: Label 'Amount must be equal.';
        DescrCap: Label 'Descr';
        NameCap: Label 'Name';

    [Test]
    [HandlerFunctions('ManualVendorPaymentLinePageHandler')]
    [Scope('OnPrem')]
    procedure VendorBankAccountNoOnVendorBillCard()
    var
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        VendorBillHeader: Record "Vendor Bill Header";
        VendorBillCard: TestPage "Vendor Bill Card";
    begin
        // Test to verify Vendor Bank Account No. on Vendor Bill Card after Insert Line on Manual Vendor Payment Line.

        // Setup: Create Vendor, Vendor Bank Account and Vendor Bill Header.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateVendorBankAccount(VendorBankAccount, Vendor."No.");
        CreateVendorBillHeader(VendorBillHeader);
        VendorBillCard.OpenEdit();
        VendorBillCard.GotoRecord(VendorBillHeader);

        // Enqueue values for ManualVendorPaymentLinePageHandler.
        LibraryVariableStorage.Enqueue(VendorBankAccount."Vendor No.");
        LibraryVariableStorage.Enqueue(VendorBankAccount.Code);

        // Exercise.
        VendorBillCard.InsertVendBillLineManual.Invoke();  // Opens ManualVendorPaymentLinePageHandler.

        // Verify.
        VendorBillCard.VendorBillLines."Vendor Bank Acc. No.".AssertEquals(VendorBankAccount.Code);
        VendorBillCard.VendorBillLines."Document Type".AssertEquals('Invoice');
        VendorBillCard.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentJournalAppliedToPurchPrepmtInvAndPurchInv()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        AppliesToDocNo: Code[20];
        OldUnrealizedVAT: Boolean;
    begin
        // Test to verify VAT entry after posting Payment Journal applied to Purchase Prepayment Invoice and Purchase Invoice with Unrealized VAT.

        // Setup: Create and Post Purchase Prepayment Invoice. Post Purchase Invoice. Post Payment Journal applied to Prepayment Invoice.
        Initialize();
        OldUnrealizedVAT := UpdateUnrealizedVATOnGeneralLedgerSetup(true);  // True for Unrealized VAT.
        CreateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", false);  // FALSE for EU Service.
        CreatePurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Order, PurchaseLine.Type::"G/L Account",
          CreateVendor(VATPostingSetup."VAT Bus. Posting Group"),
          CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group"), '', LibraryRandom.RandDec(20, 2));  // Blank value used for Location Code and Random value used for Prepayment Percent.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPrepaymentInvoice(PurchaseHeader);
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);

        // Exercise.
        AppliesToDocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as Receive and Invoice.

        // Verify.
        VerifyVATEntry(
          GetPrepaymentPurchaseInvoiceHeaderNo(PurchaseLine."Buy-from Vendor No."),
          PurchaseLine."Prepmt. Line Amount" * PurchaseLine."VAT %" / 100,
          PurchaseLine."Prepmt. Line Amount");
        VerifyVATEntry(AppliesToDocNo, PurchaseLine."Line Amount" * PurchaseLine."VAT %" / 100, PurchaseLine."Line Amount");

        // Tear Down.
        UpdateUnrealizedVATOnGeneralLedgerSetup(OldUnrealizedVAT);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CashRcptJournalAppliedToSalesPrepmtInvAndSalesInv()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        AppliesToDocNo: Code[20];
        OldUnrealizedVAT: Boolean;
    begin
        // Test to verify VAT entry after posting Cash Receipt Journal applied to Sales Prepayment Invoice and Sales Invoice with Unrealized VAT.

        // Setup: Create and Post Sales Prepayment Invoice. Post Sales Invoice. Post Cash Receipt Journal applied to Prepayment Invoice.
        Initialize();
        OldUnrealizedVAT := UpdateUnrealizedVATOnGeneralLedgerSetup(true);  // True for Unrealized VAT.
        CreateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", false);  // FALSE for EU Service.
        CreateSalesDocument(
          SalesLine, SalesLine."Document Type"::Order, SalesLine.Type::"G/L Account", VATPostingSetup."VAT Bus. Posting Group",
          CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group"), '', LibraryRandom.RandDec(20, 2));  // Blank value used for Payment Method code and Random value used for Prepayment Percent.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // Exercise.
        AppliesToDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify.
        VerifyVATEntry(
          GetPrepaymentSalesInvoiceHeaderNo(SalesLine."Sell-to Customer No."), -SalesLine."Prepmt. Line Amount" * SalesLine."VAT %" / 100,
          -SalesLine."Prepmt. Line Amount");
        VerifyVATEntry(AppliesToDocNo, -SalesLine."Line Amount" * SalesLine."VAT %" / 100, -SalesLine."Line Amount");

        // Tear Down.
        UpdateUnrealizedVATOnGeneralLedgerSetup(OldUnrealizedVAT);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesOrderPaymentMethodCodeWithBalanceAccount()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
    begin
        // Test to verify G/L entry after posting Sales Order with Payment Method Code that uses a Balance Account.

        // Setup: Create Sales Order with Payment Method Code.
        Initialize();
        CreateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", false);  // FALSE for EU Service.
        CreateSalesDocument(
          SalesLine, SalesLine."Document Type"::Order, SalesLine.Type::Item, VATPostingSetup."VAT Bus. Posting Group",
          CreateItem(VATPostingSetup."VAT Prod. Posting Group"), CreatePaymentMethod(), 0);  // Value 0 required for Prepayment Percent.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as Ship and Invoice.

        // Verify.
        VerifyGLEntry(DocumentNo, VATPostingSetup."Sales VAT Account", -SalesLine.Amount * SalesLine."VAT %" / 100);
        VerifyGLEntry(DocumentNo, GeneralPostingSetup."Sales Account", -SalesLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReportingValuesOnPostedTransferShipmentPage()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        TransferRoute: Record "Transfer Route";
        VATPostingSetup: Record "VAT Posting Setup";
        PostedTransferShipment: TestPage "Posted Transfer Shipment";
    begin
        // Test to verify Reporting Tab values on Posted Transfer Shipment page after posting Transfer Order as Ship.

        // Setup: Create Transfer Route. Create and post Purchase Order to update Inventory. Create Transfer Order.
        Initialize();
        CreateTransferRoute(TransferRoute);
        CreateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", false);  // FALSE for EU Service.
        CreatePurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Order, PurchaseLine.Type::Item,
          CreateVendor(VATPostingSetup."VAT Bus. Posting Group"),
          CreateItem(VATPostingSetup."VAT Prod. Posting Group"), TransferRoute."Transfer-from Code", 0);  // Value 0 used for Prepayment Percent.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as Receive and Invoice.
        CreateTransferOrder(TransferHeader, TransferRoute, PurchaseLine."No.", PurchaseLine.Quantity);

        // Exercise.
        LibraryInventory.PostTransferHeader(TransferHeader, true, false);  // Post as Ship.

        // Verify: Reporting tab values on Posted Transfer Shipment page.
        PostedTransferShipment.OpenEdit();
        PostedTransferShipment.FILTER.SetFilter("Transfer Order No.", TransferHeader."No.");
        PostedTransferShipment."Gross Weight".AssertEquals(TransferHeader."Gross Weight");
        PostedTransferShipment."Net Weight".AssertEquals(TransferHeader."Net Weight");
        PostedTransferShipment."Parcel Units".AssertEquals(TransferHeader."Parcel Units");
        PostedTransferShipment.Close();
    end;

    [Test]
    [HandlerFunctions('GLBookPrintRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DescriptionOnGLBookPrintReportAfterPostSalesInv()
    begin
        // Test to verify Description on G/L Book - Print Report after Sales Invoice is posted and Name is updated on Customer.
        PostSalesInvoiceAndUpdateNameOnCustomer(REPORT::"G/L Book - Print", DescrCap);
    end;

    [HandlerFunctions('VATRegisterPrintPageHandler')]
    [Scope('OnPrem')]
    procedure NameOnVATRegisterPrintReportAfterPostSalesInv()
    begin
        // Test to verify Name on VAT Register - Print Report after Sales Invoice is posted and Name is updated on Customer.
        PostSalesInvoiceAndUpdateNameOnCustomer(REPORT::"VAT Register - Print", NameCap);
    end;

    local procedure PostSalesInvoiceAndUpdateNameOnCustomer(ReportID: Integer; NameCaption: Text)
    var
        CompanyInformation: Record "Company Information";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        Name: Text[100];
    begin
        // Setup: Post Sales Invoice, update Name on Customer.
        Initialize();
        CreateVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", false);  // FALSE for EU Service.
        CreateSalesDocument(
          SalesLine, SalesLine."Document Type"::Invoice, SalesLine.Type::Item, VATPostingSetup."VAT Bus. Posting Group",
          CreateItem(VATPostingSetup."VAT Prod. Posting Group"), '', 0);  // Blank for Payment method, 0 required for Prepayment Percent.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        Name := UpdateNameOnCustomer(SalesLine."Sell-to Customer No.");

        // Enqueue values for GLBookPrintRequestPageHandler and VATRegisterPrintPageHandler.
        LibraryVariableStorage.Enqueue(
          LibraryUtility.GenerateRandomCode(CompanyInformation.FieldNo("Register Company No."), DATABASE::"Company Information"));
        LibraryVariableStorage.Enqueue(
          LibraryUtility.GenerateRandomCode(CompanyInformation.FieldNo("Fiscal Code"), DATABASE::"Company Information"));
        LibraryVariableStorage.Enqueue(SalesHeader."Operation Type");
        Commit();  // Commit required.

        // Exercise.
        REPORT.Run(ReportID);

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(NameCaption, Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckDigitVATNoError()
    var
        LocalApplicationManagement: Codeunit LocalApplicationManagement;
        VATRegNo: Code[11];
    begin
        // [FEATURE] [UT] [VAT Registration No.]
        // [SCENARIO 230046] No error for VAT Registration No which has [8][9][10] numbers forming a value > 150 when Run COD12104 "LocalApplicationManagement".CheckDigitVAT()
        Initialize();

        // [GIVEN] Semi-valid Italian VAT Registration No = '00000001511'
        // [GIVEN] length = 11, [8][9][10] numbers form a value 151, [11] number is calculated to pass CheckDigitVAT checks without errors
        VATRegNo := '00000001511';

        // [WHEN] Run CheckDigitVAT function from codeunit LocalApplicationManagement
        LocalApplicationManagement.CheckDigitVAT(VATRegNo);

        // [THEN] No Error Message
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckDigitVATZeroValue()
    var
        LocalApplicationManagement: Codeunit LocalApplicationManagement;
    begin
        // [FEATURE] [UT] [VAT Registration No.]
        // [SCENARIO 300858] No error for blank VAT Registration No when Run COD12104 "LocalApplicationManagement".CheckDigitVAT()
        LocalApplicationManagement.CheckDigitVAT('');
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateGLAccount(VATProdPostingGroup: Code[20]): Code[20]
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateItem(VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreatePaymentMethod(): Code[10]
    var
        Bill: Record Bill;
        GLAccount: Record "G/L Account";
        PaymentMethod: Record "Payment Method";
    begin
        LibraryITLocalization.CreateBill(Bill);
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        PaymentMethod.Validate("Bill Code", Bill.Code);
        PaymentMethod.Validate("Bal. Account No.", GLAccount."No.");
        PaymentMethod.Modify(true);
        exit(PaymentMethod.Code);
    end;

    local procedure CreatePurchaseDocument(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; Type: Enum "Purchase Line Type"; VendorNo: Code[20]; No: Code[20]; LocationCode: Code[10]; PrepaymentPercent: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        NoSeries: Record "No. Series";
        ServiceTariffNumber: Record "Service Tariff Number";
        TransportMethod: Record "Transport Method";
    begin
        LibraryITLocalization.CreateServiceTariffNumber(ServiceTariffNumber);
        TransportMethod.FindFirst();
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Location Code", LocationCode);
        PurchaseHeader.Validate("Prepayment Due Date", WorkDate());
        PurchaseHeader.Validate("Prepayment %", PrepaymentPercent);
        PurchaseHeader.Validate("Payment Method Code", CreatePaymentMethod());
        PurchaseHeader.Validate("Service Tariff No.", ServiceTariffNumber."No.");
        PurchaseHeader.Validate("Transport Method", TransportMethod.Code);
        PurchaseHeader.Validate("Operation Type", GetOperationType(NoSeries."No. Series Type"::Purchase));
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, LibraryRandom.RandDec(10, 2));  // Random value used for Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);

        UpdatePurchasePrepmtAccount(PurchaseHeader."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
    end;

    local procedure UpdatePurchasePrepmtAccount(GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchPrepaymentsGLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(PurchPrepaymentsGLAccount);
        GeneralPostingSetup.Get(GenBusPostingGroup, GenProdPostingGroup);
        GeneralPostingSetup."Purch. Prepayments Account" := PurchPrepaymentsGLAccount."No.";
        GeneralPostingSetup.Modify(true);
    end;

    local procedure CreateSalesDocument(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; Type: Enum "Sales Line Type"; VATBusPostingGroup: Code[20]; No: Code[20]; PaymentMethodCode: Code[10]; PrepaymentPercent: Decimal)
    var
        Customer: Record Customer;
        NoSeries: Record "No. Series";
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Customer.Modify(true);
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, Customer."No.");
        SalesHeader.Validate("Payment Method Code", PaymentMethodCode);
        SalesHeader.Validate("Prepayment %", PrepaymentPercent);
        SalesHeader.Validate("Operation Type", GetOperationType(NoSeries."No. Series Type"::Sales));
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, No, LibraryRandom.RandDec(10, 2));  // Random value used for Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateTransferOrder(var TransferHeader: Record "Transfer Header"; TransferRoute: Record "Transfer Route"; ItemNo: Code[20]; Quantity: Decimal)
    var
        TransferLine: Record "Transfer Line";
    begin
        LibraryInventory.CreateTransferHeader(
          TransferHeader, TransferRoute."Transfer-from Code", TransferRoute."Transfer-to Code", TransferRoute."In-Transit Code");
        TransferHeader.Validate("Gross Weight", LibraryRandom.RandDec(10, 2));
        TransferHeader.Validate("Net Weight", LibraryRandom.RandDec(10, 2));
        TransferHeader.Validate("Parcel Units", LibraryRandom.RandDec(10, 2));
        TransferHeader.Modify(true);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Quantity);
    end;

    local procedure CreateTransferRoute(var TransferRoute: Record "Transfer Route")
    var
        Location: Record Location;
        Location2: Record Location;
        LocationInTransit: Record Location;
    begin
        LibraryWarehouse.CreateTransferLocations(Location, Location2, LocationInTransit);
        LibraryInventory.CreateTransferRoute(TransferRoute, Location.Code, Location2.Code);
        TransferRoute.Validate("In-Transit Code", LocationInTransit.Code);
        TransferRoute.Modify(true);
    end;

    local procedure CreateVendor(VATBusPostingGroup: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateVendorBillHeader(var VendorBillHeader: Record "Vendor Bill Header")
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryITLocalization.CreateVendorBillHeader(VendorBillHeader);
        VendorBillHeader.Validate("Bank Account No.", BankAccount."No.");
        VendorBillHeader.Validate("Payment Method Code", CreatePaymentMethod());
        VendorBillHeader.Validate("Posting Date", WorkDate());
        VendorBillHeader.Modify(true);
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATCalculationType: Enum "Tax Calculation Type"; EUService: Boolean)
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATIdentifier: Record "VAT Identifier";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        VATIdentifier.FindFirst();
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT Calculation Type", VATCalculationType);
        VATPostingSetup.Validate("Purch. Prepayments Account", CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group"));
        VATPostingSetup.Validate("Purchase VAT Account", CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group"));
        VATPostingSetup.Validate("Sales Prepayments Account", CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group"));
        VATPostingSetup.Validate("Sales VAT Account", CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group"));
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group"));
        VATPostingSetup.Validate("VAT %", LibraryRandom.RandDec(10, 2));
        VATPostingSetup.Validate("EU Service", EUService);
        VATPostingSetup.Validate("VAT Identifier", VATIdentifier.Code);
        VATPostingSetup.Modify(true);
    end;

    local procedure GetOperationType(NoSeriesType: Enum "No. Series Type"): Code[10]
    var
        NoSeries: Record "No. Series";
    begin
        NoSeries.SetRange("No. Series Type", NoSeriesType);
        NoSeries.SetRange("Date Order", true);
        NoSeries.FindFirst();
        exit(NoSeries.Code);
    end;

    local procedure GetPrepaymentPurchaseInvoiceHeaderNo(BuyFromVendorNo: Code[20]): Code[20]
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.SetRange("Buy-from Vendor No.", BuyFromVendorNo);
        PurchInvHeader.FindFirst();
        exit(PurchInvHeader."No.");
    end;

    local procedure GetPrepaymentSalesInvoiceHeaderNo(SellToCustomerNo: Code[20]): Code[20]
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", SellToCustomerNo);
        SalesInvoiceHeader.FindFirst();
        exit(SalesInvoiceHeader."No.");
    end;

    local procedure UpdateNameOnCustomer(No: Code[20]) OldName: Text[100]
    var
        Customer: Record Customer;
    begin
        Customer.Get(No);
        OldName := Customer.Name;
        Customer.Validate(Name, Customer.Name + Customer.Name);
        Customer.Modify(true);
    end;

    local procedure UpdateUnrealizedVATOnGeneralLedgerSetup(UnrealizedVAT: Boolean) OldUnrealizedVAT: Boolean
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        OldUnrealizedVAT := GeneralLedgerSetup."Unrealized VAT";
        GeneralLedgerSetup.Validate("Unrealized VAT", UnrealizedVAT);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; GLAccountNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(Amount, GLEntry.Amount, LibraryERM.GetAmountRoundingPrecision(), AmountErr);
    end;

    local procedure VerifyVATEntry(DocumentNo: Code[20]; Amount: Decimal; Base: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindFirst();
        Assert.AreNearlyEqual(Amount, VATEntry.Amount, LibraryERM.GetAmountRoundingPrecision(), AmountErr);
        Assert.AreNearlyEqual(Base, VATEntry.Base, LibraryERM.GetAmountRoundingPrecision(), AmountErr);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure GLBookPrintRequestPageHandler(var GLBookPrint: TestRequestPage "G/L Book - Print")
    var
        FiscalCode: Variant;
        RegisterCompanyNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(RegisterCompanyNo);
        LibraryVariableStorage.Dequeue(FiscalCode);
        GLBookPrint.StartingDate.SetValue(WorkDate());
        GLBookPrint.EndingDate.SetValue(WorkDate());
        GLBookPrint.RegisterCompanyNo.SetValue(RegisterCompanyNo);
        GLBookPrint.FiscalCode.SetValue(FiscalCode);
        GLBookPrint.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ManualVendorPaymentLinePageHandler(var ManualVendorPaymentLine: TestPage "Manual vendor Payment Line")
    var
        VendorNo: Variant;
        VendorBankAccount: Variant;
    begin
        LibraryVariableStorage.Dequeue(VendorNo);
        LibraryVariableStorage.Dequeue(VendorBankAccount);
        ManualVendorPaymentLine.VendorNo.SetValue(VendorNo);
        ManualVendorPaymentLine.DocumentNo.SetValue(LibraryUtility.GenerateGUID());
        ManualVendorPaymentLine.DocumentDate.SetValue(WorkDate());
        ManualVendorPaymentLine.TotalAmount.SetValue(LibraryRandom.RandDec(100, 2));
        ManualVendorPaymentLine.VendorBankAccount.SetValue(VendorBankAccount);
        ManualVendorPaymentLine.InsertLine.Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATRegisterPrintPageHandler(var VATRegisterPrint: TestRequestPage "VAT Register - Print")
    var
        NoSeries: Record "No. Series";
        FiscalCode: Variant;
        OperationType: Variant;
        RegisterCompanyNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(RegisterCompanyNo);
        LibraryVariableStorage.Dequeue(FiscalCode);
        LibraryVariableStorage.Dequeue(OperationType);
        NoSeries.SetRange(Code, OperationType);
        NoSeries.FindFirst();
        VATRegisterPrint.VATRegister.SetValue(NoSeries."VAT Register");
        VATRegisterPrint.PeriodStartingDate.SetValue(WorkDate());
        VATRegisterPrint.PeriodEndingDate.SetValue(WorkDate());
        VATRegisterPrint.RegisterCompanyNo.SetValue(RegisterCompanyNo);
        VATRegisterPrint.FiscalCode.SetValue(FiscalCode);
        VATRegisterPrint.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}
