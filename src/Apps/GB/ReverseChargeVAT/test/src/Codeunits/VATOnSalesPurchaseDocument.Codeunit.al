namespace Microsoft.Finance.VAT.Setup;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Setup;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
#if not CLEAN27
using Microsoft.Sales.History;
#endif
using Microsoft.Sales.Setup;
#if not CLEAN27
using System.Environment.Configuration;
#endif
using System.TestLibraries.Utilities;

codeunit 144013 "VAT On Sales/Purchase Document"
{

    Subtype = Test;
    TestType = Uncategorized;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Sales] [Reverse Charge]
    end;

    var
#if not CLEAN27
        OriginalFeatureDataUpdateStatus: Record "Feature Data Update Status";
#endif
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
#if not CLEAN27
        Assert: Codeunit Assert;
#endif
        isInitialized: Boolean;
#if not CLEAN27
        FeatureStatusExisted: Boolean;
        FeatureStatusChanged: Boolean;
        NotSubjectToReverseChargeErr: Label 'is not subjected to Reverse Charge';
#endif

    [Test]
    procedure AddReverseChargeItemToSalesLine()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
    begin
        // [FEATURE] [Sales] [Reverse Charge]
        // [SCENARIO 281088] "Reverse Charge Item" is TRUE in Sales Line when set Item with "Reverse Charge Applies" = TRUE
        Initialize();

        // [GIVEN] "Item" with "Reverse Charge Applies"=TRUE
        CreateItemReverseChargeApplies(Item);
        LibrarySales.CreateCustomerWithVATRegNo(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");

        // [WHEN] "Item" is added to "Sales Line" by "No."
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 0);

        // [THEN] "Sales Line"."Reverse charge item"=TRUE
        SalesLine.TestField("Reverse Charge Item GB", true);
#if not CLEAN27
        RestoreReverseChargeFeatureStatus();
#endif
    end;

    [Test]
    procedure ClearReverseChargeItemFromSalesLine()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
    begin
        // [FEATURE] [Sales] [Reverse Charge]
        // [SCENARIO 281088] "Reverse Charge Item" is FALSE in Sales Line when "No." set to <blank>
        Initialize();

        // [GIVEN] "Item" with "Reverse Charge Applies"=TRUE
        CreateItemReverseChargeApplies(Item);
        LibrarySales.CreateCustomerWithVATRegNo(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");

        // [WHEN] "Item" is added to "Sales Line" by "No." and then removed
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 0);
        SalesLine.Validate("No.", '');

        // [THEN] "Sales Line"."Reverse charge item"=FALSE
        SalesLine.TestField("Reverse Charge Item GB", false);
#if not CLEAN27
        RestoreReverseChargeFeatureStatus();
#endif
    end;

    [Test]
    procedure AddGLAccountToSalesLine()
    var
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        GLAccountNo: Code[20];
    begin
        // [FEATURE] [Sales] [Reverse Charge]
        // [SCENARIO 281088] "Reverse Charge Item" is FALSE in Sales Line "Type" <> Item
        Initialize();

        // [GIVEN] "G/L Account"
        LibrarySales.CreateCustomerWithVATRegNo(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        GLAccountNo := LibraryERM.CreateGLAccountWithSalesSetup();

        // [WHEN] "G/L Account" is added to "Sales Line" by "No."
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccountNo, 0);

        // [THEN] "Sales Line"."Reverse charge item"=FALSE
        SalesLine.TestField("Reverse Charge Item GB", false);
#if not CLEAN27
        RestoreReverseChargeFeatureStatus();
#endif
    end;

    [Test]
    procedure CheckInvoiceWithReverseChargeItems()
    var
        Item: Record Item;
        Customer: Record Customer;
        GLSetup: Record "General Ledger Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [Sales] [Reverse Charge]
        // [SCENARIO 281088] Reverse Charge VAT Entry created when post Sales Invoice with Reverse Charge Item and amount above threshold amount
        Initialize();

        // [GIVEN] Item "X" with "Reverse Charge Item" option enabled
        CreateItemReverseChargeApplies(Item);
        // [GIVEN] "Threshold Amount" is "N" in General Ledger Setup
        ModifyGLSetupReverseCharge(GLSetup);
        // [GIVEN] VAT Posting Setup with "Reverse Charge VAT" VAT Calculation Type
        CreateVATPostingSetupReverseCharge(Item."VAT Prod. Posting Group", VATPostingSetup);
        // [GIVEN] Customer with "VAT Bus. Posting Group" from VAT Posting Setup
        LibrarySales.CreateCustomerWithVATRegNo(Customer);
        // [GIVEN] "Reverse Charge VAT Posting Gr." in Sales Setup from VAT Posting Setup
        ModifySalesSetupReverseCharge(VATPostingSetup."VAT Bus. Posting Group", Customer."VAT Bus. Posting Group");
        // [GIVEN] Sales Invoice with Item "X" and amount > "N"
        CreateInvoiceWithReverseChargeItem(Item."No.", Customer."No.", GLSetup."Threshold Amount GB", SalesHeader);

        // [WHEN] Sales Invoice posted
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] VAT Entry created with "Reverse Charge VAT" posting setup
        VerifyVATEntryVATPostingGroupsAndType(VATPostingSetup, InvoiceNo);
#if not CLEAN27
        RestoreReverseChargeFeatureStatus();
#endif
    end;

    [Test]
    procedure AddItemToSalesLine()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
    begin
        // [FEATURE] [Sales] [Reverse Charge]
        // [SCENARIO 281088] "Reverse Charge Item" is FALSE in Sales Line when set Item with "Reverse Charge Applies" = FALSE
        Initialize();

        // [GIVEN] "Item" with "Reverse Charge Applies"=FALSE
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateCustomerWithVATRegNo(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");

        // [WHEN] "Item" is added to "Sales Line" by "No."
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 0);

        // [THEN] "Sales Line"."Reverse charge item"=FALSE
        SalesLine.TestField("Reverse Charge Item GB", false);
#if not CLEAN27
        RestoreReverseChargeFeatureStatus();
#endif
    end;

#if not CLEAN27
    [Test]
    procedure PostSalesOrderWithGBOnlyReverseChargeItem()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [SCENARIO 654053] A GB reverse-charge order posts when only the new item flag is set.
        Initialize();

        // [GIVEN] The GB feature is enabled and an order contains an item with only the GB reverse-charge flag.
        SetReverseChargeFeatureEnabled(true);
        CreateReverseChargeSalesOrder(SalesHeader, SalesLine, VATPostingSetup, false, true);

#pragma warning disable AL0432
        SalesLine.TestField("Reverse Charge Item", false);
#pragma warning restore AL0432
        SalesLine.TestField("Reverse Charge Item GB", true);

        // [WHEN] The order is shipped and invoiced.
        // [THEN] The posted invoice records GB reverse charge and excludes VAT from the amount including VAT.
        PostAndVerifyGBReverseChargeOrder(SalesHeader, SalesLine, VATPostingSetup);

        RestoreReverseChargeFeatureStatus();
    end;

    [Test]
    procedure PostPartialSalesOrderWithGBOnlyReverseChargeItem()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [SCENARIO 654053] A partial invoice at the threshold records only the invoiced reverse-charge amount.
        Initialize();

        // [GIVEN] The GB feature is enabled and an order contains a GB reverse-charge item.
        SetReverseChargeFeatureEnabled(true);
        CreateReverseChargeSalesOrder(SalesHeader, SalesLine, VATPostingSetup, false, true);
        // [GIVEN] One of the two units is to be shipped and invoiced, reaching the reverse-charge threshold.
        SalesLine.Validate("Qty. to Ship", 1);
        SalesLine.Validate("Qty. to Invoice", 1);
        SalesLine.Modify(true);

        // [WHEN] The order is partially shipped and invoiced.
        // [THEN] The posted invoice records GB reverse charge for only the invoiced quantity.
        PostAndVerifyGBReverseChargeOrder(SalesHeader, SalesLine, VATPostingSetup);

        RestoreReverseChargeFeatureStatus();
    end;

    [Test]
    procedure PostGBReverseChargeOrderIgnoresLegacyPostingGroup()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesSetup: Record "Sales & Receivables Setup";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [SCENARIO 654053] An existing line with both flags set uses only the new posting setup.
        Initialize();

        // [GIVEN] The GB feature is enabled and an order contains an item with both reverse-charge flags.
        SetReverseChargeFeatureEnabled(true);
        CreateReverseChargeSalesOrder(SalesHeader, SalesLine, VATPostingSetup, true, true);
        // [GIVEN] The existing line retains the legacy flag and the legacy posting group conflicts with the GB setup.
#pragma warning disable AL0432
        SalesLine.TestField("Reverse Charge Item", false);
        SalesLine."Reverse Charge Item" := true;
        SalesLine.Modify(true);
        SalesSetup.Get();
        SalesSetup."Reverse Charge VAT Posting Gr." := SalesHeader."VAT Bus. Posting Group";
        SalesSetup.Modify(true);
#pragma warning restore AL0432

        // [WHEN] The order is shipped and invoiced.
        // [THEN] The posted invoice uses the GB reverse-charge posting setup, not the legacy posting group.
        PostAndVerifyGBReverseChargeOrder(SalesHeader, SalesLine, VATPostingSetup);

        RestoreReverseChargeFeatureStatus();
    end;

    [Test]
    procedure PostLegacyReverseChargeOrderWithFeatureDisabled()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceLine: Record "Sales Invoice Line";
        VATPostingSetup: Record "VAT Posting Setup";
        ExpectedReverseCharge: Decimal;
        InvoiceNo: Code[20];
    begin
        // [SCENARIO 654053] Disabling the new feature preserves legacy item copying and posting.
        Initialize();

        // [GIVEN] The GB feature is disabled and an order contains an item with only the legacy reverse-charge flag.
        SetReverseChargeFeatureEnabled(false);
        CreateReverseChargeSalesOrder(SalesHeader, SalesLine, VATPostingSetup, true, false);
#pragma warning disable AL0432
        SalesLine.TestField("Reverse Charge Item", true);
#pragma warning restore AL0432
        SalesLine.TestField("Reverse Charge Item GB", false);
        ExpectedReverseCharge := SalesLine."Amount Including VAT" - SalesLine.Amount;

        // [WHEN] The order is shipped and invoiced.
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The invoice records legacy reverse charge, no GB reverse charge, and an amount including VAT equal to the amount.
        VerifyVATEntryVATPostingGroupsAndType(VATPostingSetup, InvoiceNo);
        SalesInvoiceLine.Get(InvoiceNo, SalesLine."Line No.");
#pragma warning disable AL0432
        SalesInvoiceLine.TestField("Reverse Charge", ExpectedReverseCharge);
#pragma warning restore AL0432
        SalesInvoiceLine.TestField("Reverse Charge GB", 0);
        SalesInvoiceLine.TestField("Amount Including VAT", SalesInvoiceLine.Amount);
        RestoreReverseChargeFeatureStatus();
    end;

    [Test]
    procedure FeatureDisabledRejectsGBOnlyReverseChargeItem()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [SCENARIO 654053] A populated GB flag does not bypass legacy validation when the feature is disabled.
        Initialize();

        // [GIVEN] The GB feature is disabled and a sales line has only the GB reverse-charge flag.
        SetReverseChargeFeatureEnabled(false);
        CreateReverseChargeSalesOrder(SalesHeader, SalesLine, VATPostingSetup, false, true);
        SalesLine."Reverse Charge Item GB" := true;

        // [WHEN] The reverse-charge VAT business posting group is validated on the line.
        asserterror SalesLine.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");

        // [THEN] The line is rejected as not subject to reverse charge.
        Assert.ExpectedError(NotSubjectToReverseChargeErr);
        RestoreReverseChargeFeatureStatus();
    end;

    [Test]
    procedure FeatureEnabledRejectsLegacyOnlyReverseChargeItem()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [SCENARIO 654053] A populated legacy flag does not bypass the new GB item validation.
        Initialize();

        // [GIVEN] The GB feature is enabled and a sales line has only the legacy reverse-charge flag.
        SetReverseChargeFeatureEnabled(true);
        CreateReverseChargeSalesOrder(SalesHeader, SalesLine, VATPostingSetup, true, false);
#pragma warning disable AL0432
        SalesLine."Reverse Charge Item" := true;
#pragma warning restore AL0432

        // [WHEN] The reverse-charge VAT business posting group is validated on the line.
        asserterror SalesLine.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");

        // [THEN] The line is rejected as not subject to reverse charge.
        Assert.ExpectedError(NotSubjectToReverseChargeErr);
        RestoreReverseChargeFeatureStatus();
    end;

    [Test]
    procedure PostGBReverseChargeOrderBelowThreshold()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceLine: Record "Sales Invoice Line";
        VATPostingSetup: Record "VAT Posting Setup";
        ExpectedAmountIncludingVAT: Decimal;
        InvoiceNo: Code[20];
    begin
        // [SCENARIO 654053] A GB reverse-charge item below the threshold retains normal sales VAT.
        Initialize();

        // [GIVEN] The GB feature is enabled and a GB reverse-charge order is below the threshold.
        SetReverseChargeFeatureEnabled(true);
        CreateReverseChargeSalesOrder(SalesHeader, SalesLine, VATPostingSetup, false, true);
        SalesLine.Validate("Unit Price", 100);
        SalesLine.Modify(true);
        VATPostingSetup.Get(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group");
        ExpectedAmountIncludingVAT := SalesLine."Amount Including VAT";

        // [WHEN] The order is shipped and invoiced.
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The posted invoice retains normal VAT and has no GB reverse-charge amount.
        VerifyVATEntryVATPostingGroupsAndType(VATPostingSetup, InvoiceNo);
        SalesInvoiceLine.Get(InvoiceNo, SalesLine."Line No.");
        SalesInvoiceLine.TestField("Reverse Charge GB", 0);
        SalesInvoiceLine.TestField("Amount Including VAT", ExpectedAmountIncludingVAT);
        RestoreReverseChargeFeatureStatus();
    end;

    [Test]
    procedure PostGBReverseChargeOrderWithZeroQuantityLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ZeroQuantitySalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [SCENARIO 654053] A zero-quantity reverse-charge line does not divide by zero during posting.
        Initialize();

        // [GIVEN] The GB feature is enabled and a GB reverse-charge order also contains a zero-quantity line.
        SetReverseChargeFeatureEnabled(true);
        CreateReverseChargeSalesOrder(SalesHeader, SalesLine, VATPostingSetup, false, true);
        LibrarySales.CreateSalesLine(ZeroQuantitySalesLine, SalesHeader, ZeroQuantitySalesLine.Type::Item, SalesLine."No.", 0);
        ZeroQuantitySalesLine.Validate("Unit Price", 1000);
        ZeroQuantitySalesLine.Modify(true);
        ZeroQuantitySalesLine.TestField("Reverse Charge Item GB", true);

        // [WHEN] The order is shipped and invoiced.
        // [THEN] The nonzero line posts its GB reverse charge without a division-by-zero error.
        PostAndVerifyGBReverseChargeOrder(SalesHeader, SalesLine, VATPostingSetup);

        RestoreReverseChargeFeatureStatus();
    end;

    local procedure SetReverseChargeFeatureEnabled(FeatureEnabled: Boolean)
    var
        FeatureKey: Record "Feature Key";
        FeatureDataUpdateStatus: Record "Feature Data Update Status";
    begin
        RestoreReverseChargeFeatureStatus();
        FeatureKey.Get('VATReverseCharge');
        FeatureStatusExisted := OriginalFeatureDataUpdateStatus.Get(FeatureKey.ID, CompanyName());
        if not FeatureStatusExisted then begin
            OriginalFeatureDataUpdateStatus.Init();
            OriginalFeatureDataUpdateStatus."Feature Key" := FeatureKey.ID;
            OriginalFeatureDataUpdateStatus."Company Name" :=
                CopyStr(CompanyName(), 1, MaxStrLen(OriginalFeatureDataUpdateStatus."Company Name"));
        end;
        FeatureDataUpdateStatus := OriginalFeatureDataUpdateStatus;
        if FeatureEnabled then
            FeatureDataUpdateStatus."Feature Status" := FeatureDataUpdateStatus."Feature Status"::Complete
        else
            FeatureDataUpdateStatus."Feature Status" := FeatureDataUpdateStatus."Feature Status"::Disabled;
        if FeatureStatusExisted then
            FeatureDataUpdateStatus.Modify()
        else
            FeatureDataUpdateStatus.Insert();
        FeatureStatusChanged := true;
    end;

    local procedure RestoreReverseChargeFeatureStatus()
    var
        FeatureDataUpdateStatus: Record "Feature Data Update Status";
    begin
        if not FeatureStatusChanged then
            exit;

        if FeatureStatusExisted then begin
            FeatureDataUpdateStatus.Get(OriginalFeatureDataUpdateStatus."Feature Key", OriginalFeatureDataUpdateStatus."Company Name");
            FeatureDataUpdateStatus."Feature Status" := OriginalFeatureDataUpdateStatus."Feature Status";
            FeatureDataUpdateStatus.Modify();
        end else
            if FeatureDataUpdateStatus.Get(OriginalFeatureDataUpdateStatus."Feature Key", OriginalFeatureDataUpdateStatus."Company Name") then
                FeatureDataUpdateStatus.Delete();
        FeatureStatusChanged := false;
    end;

    local procedure CreateReverseChargeSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var ReverseChargeVATPostingSetup: Record "VAT Posting Setup"; LegacyReverseChargeItem: Boolean; GBReverseChargeItem: Boolean)
    var
        Item: Record Item;
        Customer: Record Customer;
        GLSetup: Record "General Ledger Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        DomesticVATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
            DomesticVATPostingSetup, DomesticVATPostingSetup."VAT Calculation Type"::"Normal VAT", 20);
        CreateVATPostingSetupReverseCharge(DomesticVATPostingSetup."VAT Prod. Posting Group", ReverseChargeVATPostingSetup);
        ModifySalesSetupReverseCharge(
            ReverseChargeVATPostingSetup."VAT Bus. Posting Group", DomesticVATPostingSetup."VAT Bus. Posting Group");
        GLSetup.Get();
        GLSetup."Threshold applies GB" := true;
        GLSetup."Threshold Amount GB" := 1000;
#pragma warning disable AL0432
        GLSetup."Threshold applies" := true;
        GLSetup."Threshold Amount" := GLSetup."Threshold Amount GB";
#pragma warning restore AL0432
        GLSetup.Modify(true);

        SalesSetup.Get();
#pragma warning disable AL0432
        SalesSetup."Reverse Charge VAT Posting Gr." := ReverseChargeVATPostingSetup."VAT Bus. Posting Group";
        SalesSetup."Domestic Customers" := DomesticVATPostingSetup."VAT Bus. Posting Group";
#pragma warning restore AL0432
        SalesSetup.Modify(true);

        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", DomesticVATPostingSetup."VAT Prod. Posting Group");
        Item."Reverse Charge Applies GB" := GBReverseChargeItem;
#pragma warning disable AL0432
        Item."Reverse Charge Applies" := LegacyReverseChargeItem;
#pragma warning restore AL0432
        Item.Modify(true);

        LibrarySales.CreateCustomerWithVATRegNo(Customer);
        Customer.Validate("VAT Bus. Posting Group", DomesticVATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify(true);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader.Validate("Prices Including VAT", false);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 2);
        SalesLine.Validate("Unit Price", 1000);
        SalesLine.Modify(true);
    end;

    local procedure PostAndVerifyGBReverseChargeOrder(var SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; VATPostingSetup: Record "VAT Posting Setup")
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        ExpectedReverseCharge: Decimal;
        InvoiceNo: Code[20];
    begin
        // [GIVEN] The sales line has a positive domestic VAT amount for the quantity to invoice.
        ExpectedReverseCharge :=
            Round((SalesLine."Amount Including VAT" - SalesLine.Amount) *
                SalesLine."Qty. to Invoice" / SalesLine.Quantity, LibraryERM.GetAmountRoundingPrecision());
        Assert.IsTrue(ExpectedReverseCharge > 0, 'The domestic VAT amount must be positive before posting.');

        // [WHEN] The order is shipped and invoiced.
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The invoice uses the GB reverse-charge posting setup and records reverse charge for the invoiced quantity.
        VerifyVATEntryVATPostingGroupsAndType(VATPostingSetup, InvoiceNo);
        SalesInvoiceLine.Get(InvoiceNo, SalesLine."Line No.");
        SalesInvoiceLine.TestField(Quantity, SalesLine."Qty. to Invoice");
        SalesInvoiceLine.TestField("Reverse Charge Item GB", true);
        SalesInvoiceLine.TestField("Reverse Charge GB", ExpectedReverseCharge);
        SalesInvoiceLine.TestField("Amount Including VAT", SalesInvoiceLine.Amount);
    end;
#endif

    local procedure Initialize()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
#if not CLEAN27
        SetReverseChargeFeatureEnabled(true);
#endif
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();

        if isInitialized then
            exit;
        isInitialized := true;

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Return Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Modify(true);

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Return Receipt on Credit Memo", true);
        SalesReceivablesSetup.Validate("Posted Return Receipt Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Modify(true);

        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
    end;

    local procedure CreateItemReverseChargeApplies(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Reverse Charge Applies GB", true);
        Item.Modify(true);
    end;

    local procedure CreateInvoiceWithReverseChargeItem(ItemNo: Code[20]; CustomerNo: Code[20]; GLThresholdAmount: Decimal; var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandInt(100));

        SalesLine.Validate("Unit Price", GLThresholdAmount + LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateVATPostingSetupReverseCharge(ItemVATProdPostingGroup: Code[20]; var VATPostingSetup: Record "VAT Posting Setup")
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);

        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, ItemVATProdPostingGroup);

        VATPostingSetup.Validate("VAT Identifier", LibraryUtility.GenerateGUID());
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        VATPostingSetup.Modify(true);
    end;

    local procedure ModifySalesSetupReverseCharge(RevChVATBusPostingGroupCode: Code[20]; DomesticVATBusPostingGroupCode: Code[20])
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        SalesSetup.Get();
        SalesSetup.Validate("Reverse Charge VAT Post. Gr.", RevChVATBusPostingGroupCode);
        SalesSetup.Validate("Domestic Customers GB", DomesticVATBusPostingGroupCode);
        SalesSetup.Modify(true);
    end;

    local procedure ModifyGLSetupReverseCharge(var GLSetup: Record "General Ledger Setup")
    begin
        GLSetup.Get();
        GLSetup.Validate("Threshold applies GB", true);
        GLSetup.Validate("Threshold Amount GB", LibraryRandom.RandDec(100, 2));
        GLSetup.Modify(true);
    end;

    local procedure VerifyVATEntryVATPostingGroupsAndType(VATPostingSetup: Record "VAT Posting Setup"; InvoiceNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
#pragma warning disable AA0210
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Invoice);
#pragma warning restore  AA0210
        VATEntry.SetRange("Document No.", InvoiceNo);
        VATEntry.FindFirst();
        VATEntry.TestField("VAT Calculation Type", VATPostingSetup."VAT Calculation Type");
        VATEntry.TestField("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        VATEntry.TestField("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
    end;
}
