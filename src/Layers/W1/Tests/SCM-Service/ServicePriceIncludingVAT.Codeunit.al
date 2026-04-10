// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Test;

using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Sales.Customer;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Item;
using Microsoft.Service.Ledger;
using Microsoft.Service.Pricing;

codeunit 136123 "Service Price Including VAT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Price Including VAT] [Service]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryResource: Codeunit "Library - Resource";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        IsInitialized: Boolean;
        ExpectedConfirm: Label 'The Credit Memo doesn''t have a Corrected Invoice No. Do you want to continue?';
        AmountErrorErr: Label '%1 must be equal to %2 in %3.', Comment = '%1:Value1;%2:Value2;%3:TableCaption';

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Service Price Including VAT");
        // Lazy Setup.
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Service Price Including VAT");

        LibraryService.SetupServiceMgtNoSeries();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Service Price Including VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrderPriceIncludingVAT()
    begin
        // Covers Test Case No TC116892.
        // Test Amount Including VAT in Service Line and General Ledger Entry.

        ServiceOrderVAT(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrderPriceExcludingVAT()
    begin
        // Covers Test Case No TC116892.
        // Test Amount Excluding VAT in Service Line and General Ledger Entry.

        ServiceOrderVAT(false);
    end;

    local procedure ServiceOrderVAT(PriceIncludingVAT: Boolean)
    var
        ServiceHeader: Record "Service Header";
        TempServiceLine: Record "Service Line" temporary;
        ServiceLine: Record "Service Line";
    begin
        // 1.Setup: Setup Data for Posting of Service Order.
        Initialize();
        CreateServiceOrder(ServiceHeader, PriceIncludingVAT);
        GetServiceLine(ServiceLine, ServiceHeader);
        CopyServiceLine(TempServiceLine, ServiceLine);

        // 2.Exercise: Create and Post the Service Order as Ship and Invoice.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // 3.Verify: Verify General Ledger Entries.
        VerifyAmountIncludingVAT(TempServiceLine);
        VerifyGeneralLedgerEntry(ServiceHeader."No.");
    end;

    [Test]
    [HandlerFunctions('InvoiceESConfirmHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoPriceIncludingVAT()
    begin
        // Covers document number CU5912-3 - refer to TFS ID 167035.
        // Test Service Ledger Entry after Posting Service Credit Memo with Price Including VAT True.

        CreditMemoVAT(true);
    end;

    [Test]
    [HandlerFunctions('InvoiceESConfirmHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoPriceExcludingVAT()
    begin
        // Covers document number CU5912-3 - refer to TFS ID 167035.
        // Test Service Ledger Entry after Posting Service Credit Memo with Price Including VAT True.

        CreditMemoVAT(false);
    end;

    local procedure CreditMemoVAT(PriceIncludingVAT: Boolean)
    var
        ServiceHeader: Record "Service Header";
        TempServiceLine: Record "Service Line" temporary;
        ServiceLine: Record "Service Line";
    begin
        // 1. Setup: Create Credit Memo with Service Lines of Type Item Resource, Cost, G/L Account and Copy Service Lines in Temporary
        // Table.
        CreateServiceCreditMemo(ServiceHeader, PriceIncludingVAT);
        GetServiceLine(ServiceLine, ServiceHeader);
        CopyServiceLine(TempServiceLine, ServiceLine);

        // 2. Exercise: Post Service Credit Memo.
        ExecuteConfirmHandlerInvoiceES();
        LibraryService.PostServiceOrder(ServiceHeader, false, false, false);

        // 3. Verify: Verify Service Ledger Entry.
        VerifyServiceLedgerEntry(TempServiceLine, ServiceHeader."No.");
    end;

    local procedure CreateAndUpdateServiceLine(ServiceHeader: Record "Service Header"; Type: Enum "Service Line Type"; No: Code[20]; VATPercentage: Integer)
    var
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, Type, No);

        // Use Random because value is not important.
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(100));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandInt(100));
        ServiceLine.Validate("VAT %", VATPercentage);
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceCreditMemo(var ServiceHeader: Record "Service Header"; PriceIncludingVAT: Boolean)
    var
        ServiceLine: Record "Service Line";
        ServiceCost: Record "Service Cost";
        VATPercentage: Integer;
    begin
        // Service Header, Service Line with Type Item, Resource, Cost and G/L Account.
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", '');
        ServiceHeader.Validate("Prices Including VAT", PriceIncludingVAT);
        ServiceHeader.Modify(true);

        CreateServiceCost(ServiceCost);

        if PriceIncludingVAT then
            VATPercentage := 10 + LibraryRandom.RandInt(10);

        CreateAndUpdateServiceLine(ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo(), VATPercentage);
        CreateAndUpdateServiceLine(ServiceHeader, ServiceLine.Type::Resource, LibraryResource.CreateResourceNo(), VATPercentage);
        CreateAndUpdateServiceLine(ServiceHeader, ServiceLine.Type::Cost, ServiceCost.Code, VATPercentage);
        CreateAndUpdateServiceLine(
          ServiceHeader, ServiceLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), VATPercentage);
    end;

    local procedure CreateServiceLine(ServiceHeader: Record "Service Header"; ServiceItemNo: Code[20])
    var
        ServiceLine: Record "Service Line";
        Counter: Integer;
    begin
        // To Create a new Item and Service Lines.

        // Use Random Number Generator to generate 1 to 10 service lines.
        for Counter := 1 to 1 + LibraryRandom.RandInt(9) do begin
            LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());
            ServiceLine.Validate("Service Item No.", ServiceItemNo);

            // Use Random for Quantity, Unit Price and VAT %.
            ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));
            ServiceLine.Validate("Unit Price", LibraryRandom.RandInt(200));
            ServiceLine.Modify(true);
        end;
    end;

    local procedure CreateServiceOrder(var ServiceHeader: Record "Service Header"; PriceIncludingVAT: Boolean)
    var
        Customer: Record Customer;
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
    begin
        // To Create a new Service Header, Service Item.
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        ServiceHeader.Validate("Prices Including VAT", PriceIncludingVAT);
        ServiceHeader.Modify(true);

        LibraryService.CreateServiceItem(ServiceItem, Customer."No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        CreateServiceLine(ServiceHeader, ServiceItem."No.");
    end;

    local procedure CreateServiceCost(var ServiceCost: Record "Service Cost")
    begin
        LibraryService.CreateServiceCost(ServiceCost);
        ServiceCost.Validate("Account No.", LibraryERM.CreateGLAccountWithSalesSetup());
        ServiceCost.Modify(true);
    end;

    local procedure CopyServiceLine(var TempServiceLine: Record "Service Line" temporary; var ServiceLine: Record "Service Line")
    begin
        repeat
            TempServiceLine := ServiceLine;
            TempServiceLine.Insert();
        until ServiceLine.Next() = 0;
    end;

    local procedure ExecuteConfirmHandlerInvoiceES()
    begin
        if Confirm(StrSubstNo(ExpectedConfirm)) then;
    end;

    local procedure GetServiceLine(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header")
    begin
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.FindSet();
    end;

    local procedure VerifyAmountIncludingVAT(var TempServiceLine: Record "Service Line" temporary)
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoiceLine: Record "Service Invoice Line";
    begin
        ServiceInvoiceHeader.SetRange("Order No.", TempServiceLine."Document No.");
        ServiceInvoiceHeader.FindFirst();
        TempServiceLine.FindSet();
        repeat
            ServiceInvoiceLine.Get(ServiceInvoiceHeader."No.", TempServiceLine."Line No.");
            Assert.AreNearlyEqual(
              TempServiceLine."Amount Including VAT", ServiceInvoiceLine."Amount Including VAT", LibraryERM.GetAmountRoundingPrecision(),
              StrSubstNo(
                AmountErrorErr, ServiceInvoiceLine.FieldCaption("Amount Including VAT"), ServiceInvoiceLine."Amount Including VAT",
                ServiceInvoiceLine.TableCaption()));
            Assert.AreNearlyEqual(
              TempServiceLine."Line Amount", ServiceInvoiceLine."Line Amount", LibraryERM.GetAmountRoundingPrecision(),
              StrSubstNo(
                AmountErrorErr, ServiceInvoiceLine.FieldCaption("Line Amount"), ServiceInvoiceLine."Line Amount",
                ServiceInvoiceLine.TableCaption()));
        until TempServiceLine.Next() = 0;
    end;

    local procedure VerifyGeneralLedgerEntry(OrderNo: Code[20])
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        GLEntry: Record "G/L Entry";
    begin
        ServiceInvoiceHeader.SetRange("Order No.", OrderNo);
        ServiceInvoiceHeader.FindFirst();
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Invoice);
        GLEntry.SetRange("Document No.", ServiceInvoiceHeader."No.");
        GLEntry.FindSet();
        repeat
            GLEntry.TestField("Source Type", GLEntry."Source Type"::Customer);
            GLEntry.TestField("Source No.", ServiceInvoiceHeader."Bill-to Customer No.");
            GLEntry.TestField("Posting Date", ServiceInvoiceHeader."Posting Date");
        until GLEntry.Next() = 0;
    end;

    local procedure VerifyServiceLedgerEntry(var TempServiceLine: Record "Service Line" temporary; PreAssignedNo: Code[20])
    var
        ServiceLedgerEntry: Record "Service Ledger Entry";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        ServiceCrMemoHeader.SetRange("Pre-Assigned No.", PreAssignedNo);
        ServiceCrMemoHeader.FindFirst();
        ServiceLedgerEntry.SetRange("Document Type", ServiceLedgerEntry."Document Type"::"Credit Memo");
        ServiceLedgerEntry.SetRange("Document No.", ServiceCrMemoHeader."No.");
        repeat
            ServiceLedgerEntry.SetRange("Document Line No.", TempServiceLine."Line No.");
            ServiceLedgerEntry.FindFirst();
            ServiceLedgerEntry.TestField("No.", TempServiceLine."No.");
            ServiceLedgerEntry.TestField(Quantity, TempServiceLine.Quantity);
            Assert.AreNearlyEqual(
              TempServiceLine."Unit Price" / (1 + TempServiceLine."VAT %" / 100), ServiceLedgerEntry."Unit Price", 0.01,
              'Unit price incorrect');
        until TempServiceLine.Next() = 0;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure InvoiceESConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := (Question = ExpectedConfirm);
    end;
}

