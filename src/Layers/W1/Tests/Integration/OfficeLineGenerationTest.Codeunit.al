namespace Microsoft.CRM.Outlook;

using Microsoft.Integration.Entity;
using Microsoft.Integration.Graph;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using System.TestLibraries.Utilities;

codeunit 139061 "Office Line Generation Test"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [Outlook Add-in] [Suggested Line Items]
    end;

    var
        LibraryAssert: Codeunit "Library Assert";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        OfficeLineGenerationTest: Codeunit "Office Line Generation Test";
        AggregateDocumentNo: Code[20];
        AggregateUpdateCount: Integer;
        IsInitialized: Boolean;

    [Test]
    procedure SalesSuggestedLinesUpdateAggregateOnce()
    var
        Item: array[2] of Record Item;
        SalesHeader: Record "Sales Header";
        SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate";
        SalesLine: Record "Sales Line";
        TempOfficeSuggestedLineItem: Record "Office Suggested Line Item" temporary;
        OfficeLineGeneration: Codeunit "Office Line Generation";
        HeaderRecRef: RecordRef;
        AddedCount: Integer;
    begin
        // [SCENARIO] Suggested sales lines update the invoice aggregate once after the final line is inserted.
        Initialize();
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(Item[1], 10, 5);
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(Item[2], 20, 10);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        CreateSuggestedLine(TempOfficeSuggestedLineItem, 10000, Item[1]."No.", 2);
        CreateSuggestedLine(TempOfficeSuggestedLineItem, 20000, Item[2]."No.", 3);
        HeaderRecRef.GetTable(SalesHeader);
        OfficeLineGenerationTest.StartAggregateUpdateCount(SalesHeader."No.");

        TempOfficeSuggestedLineItem.FindSet();
        OfficeLineGeneration.InsertLineItemsAndUpdateAggregate(TempOfficeSuggestedLineItem, HeaderRecRef, AddedCount);

        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        LibraryAssert.AreEqual(2, AddedCount, 'Unexpected number of added sales lines.');
        LibraryAssert.AreEqual(2, SalesLine.Count(), 'Unexpected number of sales lines.');
        SalesLine.CalcSums("Line Amount");
        SalesInvoiceEntityAggregate.Get(SalesHeader."No.", false);
        LibraryAssert.AreEqual(SalesLine."Line Amount", SalesInvoiceEntityAggregate."Subtotal Amount", 'The sales invoice aggregate has incorrect totals.');
        LibraryAssert.AreEqual(1, OfficeLineGenerationTest.GetAggregateUpdateCount(), 'The sales invoice aggregate should be updated once.');
    end;

    [Test]
    procedure PurchaseSuggestedLinesUpdateAggregateOnce()
    var
        Item: array[2] of Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
        PurchaseLine: Record "Purchase Line";
        TempOfficeSuggestedLineItem: Record "Office Suggested Line Item" temporary;
        OfficeLineGeneration: Codeunit "Office Line Generation";
        HeaderRecRef: RecordRef;
        AddedCount: Integer;
    begin
        // [SCENARIO] Suggested purchase lines update the invoice aggregate once after the final line is inserted.
        Initialize();
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(Item[1], 10, 5);
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(Item[2], 20, 10);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        CreateSuggestedLine(TempOfficeSuggestedLineItem, 10000, Item[1]."No.", 2);
        CreateSuggestedLine(TempOfficeSuggestedLineItem, 20000, Item[2]."No.", 3);
        HeaderRecRef.GetTable(PurchaseHeader);
        OfficeLineGenerationTest.StartAggregateUpdateCount(PurchaseHeader."No.");

        TempOfficeSuggestedLineItem.FindSet();
        OfficeLineGeneration.InsertLineItemsAndUpdateAggregate(TempOfficeSuggestedLineItem, HeaderRecRef, AddedCount);

        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        LibraryAssert.AreEqual(2, AddedCount, 'Unexpected number of added purchase lines.');
        LibraryAssert.AreEqual(2, PurchaseLine.Count(), 'Unexpected number of purchase lines.');
        PurchaseLine.CalcSums("Line Amount");
        PurchInvEntityAggregate.Get(PurchaseHeader."No.", false);
        LibraryAssert.AreEqual(PurchaseLine."Line Amount", PurchInvEntityAggregate.Amount, 'The purchase invoice aggregate has incorrect totals.');
        LibraryAssert.AreEqual(1, OfficeLineGenerationTest.GetAggregateUpdateCount(), 'The purchase invoice aggregate should be updated once.');
    end;

    [Test]
    procedure SuggestedLinesRollBackWhenFinalLineFails()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempOfficeSuggestedLineItem: Record "Office Suggested Line Item" temporary;
        OfficeLineGeneration: Codeunit "Office Line Generation";
        HeaderRecRef: RecordRef;
        AddedCount: Integer;
    begin
        // [SCENARIO] An invalid final suggested line rolls back earlier lines in the batch.
        Initialize();
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        CreateSuggestedLine(TempOfficeSuggestedLineItem, 10000, Item."No.", 1);
        CreateSuggestedLine(TempOfficeSuggestedLineItem, 20000, CopyStr(Format(CreateGuid()), 1, 20), 1);
        HeaderRecRef.GetTable(SalesHeader);

        TempOfficeSuggestedLineItem.FindSet();
        asserterror OfficeLineGeneration.InsertLineItemsAndUpdateAggregate(TempOfficeSuggestedLineItem, HeaderRecRef, AddedCount);
        LibraryAssert.ExpectedErrorCannotFind(Database::Item);

        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        LibraryAssert.IsTrue(SalesLine.IsEmpty(), 'Suggested lines should be rolled back when the final line fails.');
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Office Line Generation Test");
        AggregateDocumentNo := '';
        AggregateUpdateCount := 0;

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Office Line Generation Test");
        BindSubscription(OfficeLineGenerationTest);
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Office Line Generation Test");
    end;

    local procedure CreateSuggestedLine(var TempOfficeSuggestedLineItem: Record "Office Suggested Line Item" temporary; LineNo: Integer; ItemNo: Code[20]; Quantity: Integer)
    begin
        TempOfficeSuggestedLineItem.Init();
        TempOfficeSuggestedLineItem."Line No." := LineNo;
        TempOfficeSuggestedLineItem.Add := true;
        TempOfficeSuggestedLineItem."Item No." := ItemNo;
        TempOfficeSuggestedLineItem.Quantity := Quantity;
        TempOfficeSuggestedLineItem.Insert();
    end;

    local procedure StartAggregateUpdateCount(DocumentNo: Code[20])
    begin
        AggregateDocumentNo := DocumentNo;
        AggregateUpdateCount := 0;
    end;

    local procedure GetAggregateUpdateCount(): Integer
    begin
        exit(AggregateUpdateCount);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Invoice Entity Aggregate", 'OnAfterModifyEvent', '', false, false)]
    local procedure CountSalesAggregateUpdate(var Rec: Record "Sales Invoice Entity Aggregate"; var xRec: Record "Sales Invoice Entity Aggregate"; RunTrigger: Boolean)
    begin
        if (AggregateDocumentNo <> '') and (Rec."No." = AggregateDocumentNo) and not Rec.Posted then
            AggregateUpdateCount += 1;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purch. Inv. Entity Aggregate", 'OnAfterModifyEvent', '', false, false)]
    local procedure CountPurchaseAggregateUpdate(var Rec: Record "Purch. Inv. Entity Aggregate"; var xRec: Record "Purch. Inv. Entity Aggregate"; RunTrigger: Boolean)
    begin
        if (AggregateDocumentNo <> '') and (Rec."No." = AggregateDocumentNo) and not Rec.Posted then
            AggregateUpdateCount += 1;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Graph Mgt - General Tools", 'OnGetIsAPIEnabled', '', false, false)]
    local procedure EnableAPI(var Handled: Boolean; var IsAPIEnabled: Boolean)
    begin
        Handled := true;
        IsAPIEnabled := true;
    end;
}