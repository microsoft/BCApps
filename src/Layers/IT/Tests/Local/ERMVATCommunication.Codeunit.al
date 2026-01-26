codeunit 144118 "ERM VAT Communication"
{
    // 1. Purpose of the test is to Verify G/L entries when Sales Invoice lines are having multiple G/L accounts with same Gen. Bus. Posting Group.
    // 2. Purpose of the test is to Create a Purchase document and post Prepayment Invoice/Credit Memo and verify posted documents and generated entries.
    // 3. Purpose of the test is to Create a Sales document and post Prepayment Invoice/Credit Memo and verify posted documents and generated entries.
    // 
    // Covers Test Cases for WI - 346097
    // -------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                   TFS ID
    // -------------------------------------------------------------------------------------------------------------
    // PostSalesOrderWithMultipleGLAccount                                                                  284677
    // PostPrepaymentPurchaseInvoiceAndCreditMemo                                                           263313
    // PostPrepaymentSalesInvoiceAndCreditMemo                                                              263316

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
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        GenBusPostingGroupErr: Label 'Gen. Bus. Posting Group must be same.';

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesOrderWithMultipleGLAccount()
    var
        GLAccount: Record "G/L Account";
        GLAccount2: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
    begin
        // Purpose of the test is to verify Verify G/L entries when Sales Invoice lines are having multiple G/L accounts with same Gen. Bus. Posting Group.
        // Setup.
        CreateGLAccount(GLAccount);
        CreateGLAccount(GLAccount2);
        CreateSalesOrder(SalesHeader, GLAccount."No.", GLAccount2."No.");

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as ship and invoice.

        // Verify: Verify Gen. Bus. Posting Group on Sales Invoice Line table.
        VerifyGenBusPostingGroupSalesLine(GLAccount."Gen. Bus. Posting Group", GLAccount2."Gen. Bus. Posting Group", DocumentNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure PostPrepaymentPurchaseInvoiceAndCreditMemo()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchaseHeader: Record "Purchase Header";
    begin
        // Purpose of the test is to Create a Purchase document and post Prepayment Invoice/Credit Memo and verify posted documents and generated entries.
        // Setup.
        CreatePurchaseOrder(PurchaseHeader);
        LibraryPurchase.PostPrepaymentInvoice(PurchaseHeader);

        // Exercise.
        PostPrepaymentPurchaseCreditMemo(PurchaseHeader);

        // Verify: Verify Field on Purch. Cr. Memo Hdr. table.
        PurchCrMemoHdr.SetRange("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchCrMemoHdr.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        PurchCrMemoHdr.FindFirst();
        PurchCrMemoHdr.TestField("Individual Person", PurchaseHeader."Individual Person");
        PurchCrMemoHdr.TestField(Resident, PurchaseHeader.Resident);
        PurchCrMemoHdr.TestField("First Name", PurchaseHeader."First Name");
        PurchCrMemoHdr.TestField("Last Name", PurchaseHeader."Last Name");
        PurchCrMemoHdr.TestField("Date of Birth", PurchaseHeader."Date of Birth");
        PurchCrMemoHdr.TestField("Refers to Period", PurchaseHeader."Refers to Period");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure PostPrepaymentSalesInvoiceAndCreditMemo()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        // Purpose of the test is to Create a Sales document and post Prepayment Invoice/Credit Memo and verify posted documents and generated entries.
        // Setup.
        CreateSalesPrepaymentInvoice(SalesHeader);
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // Exercise.
        PostPrepaymentSalesCreditMemo(SalesHeader."No.");

        // Verify: Verify Field on Sales Cr.Memo Header table.
        SalesCrMemoHeader.SetRange("Prepayment Order No.", SalesHeader."No.");
        SalesCrMemoHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesCrMemoHeader.FindFirst();
        SalesCrMemoHeader.TestField("Individual Person", SalesHeader."Individual Person");
        SalesCrMemoHeader.TestField(Resident, SalesHeader.Resident);
        SalesCrMemoHeader.TestField("First Name", SalesHeader."First Name");
        SalesCrMemoHeader.TestField("Last Name", SalesHeader."Last Name");
        SalesCrMemoHeader.TestField("Date of Birth", SalesHeader."Date of Birth");
        SalesCrMemoHeader.TestField("Refers to Period", SalesHeader."Refers to Period");
    end;

    local procedure CreateCustomer(VATBusPostingGroup: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Individual Person", true);
        Customer.Validate(Resident, Customer.Resident::"Non-Resident");
        Customer.Validate("Date of Birth", WorkDate());
        Customer.Validate("First Name", Customer."No.");
        Customer.Validate("Last Name", Customer."No.");
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateVendor(VATBusPostingGroup: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Individual Person", true);
        Vendor.Validate(Resident, Vendor.Resident::"Non-Resident");
        Vendor.Validate("Date of Birth", WorkDate());
        Vendor.Validate("First Name", Vendor."No.");
        Vendor.Validate("Last Name", Vendor."No.");
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateGLAccount(var GLAccount: Record "G/L Account")
    var
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
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

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        UpdateVATPostingSetup(VATPostingSetup);
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor(VATPostingSetup."VAT Bus. Posting Group"));
        PurchaseHeader.Validate("Transport Method", CreateTransportMethod());
        PurchaseHeader.Validate("Prepmt. CM Refers to Period", PurchaseHeader."Prepmt. CM Refers to Period"::"Current Calendar Year");
        PurchaseHeader.Validate("Prepayment %", LibraryRandom.RandDecInRange(10, 100, 2));
        PurchaseHeader.Validate("Prepayment Due Date", WorkDate());
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"),
          LibraryRandom.RandDec(10, 2));  // Taking random Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));  // Taking random Quantity.
        PurchaseLine.Validate("Service Tariff No.", CreateServiceTariffNumber());
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; GLAccount: Code[20]; GLAccount2: Code[20])
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        CreateSalesLine(SalesHeader, SalesLine.Type::"G/L Account", GLAccount, '');  // Using Blank Service Tariff No.
        CreateSalesLine(SalesHeader, SalesLine.Type::"G/L Account", GLAccount2, '');  // Using Blank Service Tariff No.
    end;

    local procedure CreateSalesPrepaymentInvoice(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        UpdateVATPostingSetup(VATPostingSetup);
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer(VATPostingSetup."VAT Bus. Posting Group"));
        SalesHeader.Validate("Transport Method", CreateTransportMethod());
        SalesHeader.Validate("Prepmt. CM Refers to Period", SalesHeader."Prepmt. CM Refers to Period"::Current);
        SalesHeader.Validate("Prepayment %", LibraryRandom.RandDecInRange(10, 100, 2));
        SalesHeader.Modify(true);
        CreateSalesLine(
          SalesHeader, SalesLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"), CreateServiceTariffNumber());
    end;

    local procedure CreateSalesLine(SalesHeader: Record "Sales Header"; Type: Enum "Sales Line Type"; No: Code[20]; ServiceTariffNo: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, No, LibraryRandom.RandDec(10, 2));  // Taking random Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));  // Taking random Quantity.
        SalesLine.Validate("Service Tariff No.", ServiceTariffNo);
        SalesLine.Modify(true);
    end;

    local procedure CreateServiceTariffNumber(): Code[10]
    var
        ServiceTariffNumber: Record "Service Tariff Number";
    begin
        LibraryITLocalization.CreateServiceTariffNumber(ServiceTariffNumber);
        exit(ServiceTariffNumber."No.");
    end;

    local procedure CreateTransportMethod(): Code[10]
    var
        TransportMethod: Record "Transport Method";
    begin
        LibraryITLocalization.CreateTransportMethod(TransportMethod);
        exit(TransportMethod.Code);
    end;

    local procedure PostPrepaymentPurchaseCreditMemo(PurchaseHeader: Record "Purchase Header")
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        PurchInvHeader.SetRange("Prepayment Order No.", PurchaseHeader."No.");
        PurchInvHeader.SetRange("Buy-from Vendor No.", PurchaseHeader."Buy-from Vendor No.");
        PurchInvHeader.FindFirst();
        PurchInvHeader.CalcFields("Amount Including VAT");
        PurchaseOrder.OpenEdit();
        PurchaseOrder.FILTER.SetFilter("No.", PurchaseHeader."No.");
        PurchaseOrder."Vendor Cr. Memo No.".SetValue(PurchaseHeader."No.");
        PurchaseOrder."Check Total".SetValue(PurchInvHeader."Amount Including VAT");
        PurchaseOrder.PostPrepaymentCreditMemo.Invoke();
    end;

    local procedure PostPrepaymentSalesCreditMemo(No: Code[20])
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", No);
        SalesOrder.PostPrepaymentCreditMemo.Invoke();
    end;

    local procedure UpdateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.CreateGLAccount(GLAccount);
        VATPostingSetup.Validate("EU Service", true);
        VATPostingSetup.Validate("Sales Prepayments Account", GLAccount."No.");
        VATPostingSetup.Validate("Purch. Prepayments Account", GLAccount."No.");
        VATPostingSetup.Modify(true);
    end;

    local procedure VerifyGenBusPostingGroupSalesLine(GenBusPostingGroup: Code[20]; GenBusPostingGroup2: Code[20]; DocumentNo: Code[20])
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.FindFirst();
        Assert.AreEqual(GenBusPostingGroup, SalesInvoiceLine."Gen. Bus. Posting Group", GenBusPostingGroupErr);
        SalesInvoiceLine.Next();
        Assert.AreEqual(GenBusPostingGroup2, SalesInvoiceLine."Gen. Bus. Posting Group", GenBusPostingGroupErr);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

