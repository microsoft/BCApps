// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Test;

using Microsoft.Sales.History;
using Microsoft.Sales.Document;
using System.Globalization;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Tracking;
using Microsoft.Assembly.Document;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Sales.Setup;
using Microsoft.Assembly.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Inventory.Ledger;

codeunit 137307 "SCM Assembly Reports"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Assembly] [Reports] [SCM]
        IsInitialized := false;
    end;

    var
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        AssemblyTemplate: Code[10];
        AssemblyBatch: Code[10];
        SerialNoCode: Code[10];
        LotNoCode: Code[10];
        ResourceNo: Code[20];
        BlueLocation: Code[10];
        SalesOrderNo: Code[20];
        ShipmentNo: Code[20];
        SerialNoComponentQuantity: Decimal;
        LotNoComponentQuantity: Integer;
        SN: Code[5];
        OldSalesOrderNoSeriesName: Code[20];
        OldInvoiceNoSeriesName: Code[20];
        OldStockoutWarning: Boolean;
        OldAssemblyOrderNoSeries: Code[20];
        OldCreditWarning: Integer;
        StockoutWarningSet: Boolean;
        SetupDataInitialized: Boolean;
        SellToCustomerNo: Code[20];
        NoSeriesName: Code[20];
        AssemblyItemNo: array[6] of Code[20];
        UsedVariantCode: array[4] of Code[10];
        SalesShipmentNo: Code[20];
        IsInitialized: Boolean;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Assembly Reports");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Assembly Reports");

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Assembly Reports");
    end;

    [Test]
    [HandlerFunctions('ReportHandlerSalesShipment,MsgHandler')]
    [Scope('OnPrem')]
    procedure VerifyShipmentPrint()
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesHeader: Record "Sales Header";
        SalesShipment: Report "Sales - Shipment";
        Language: Codeunit Language;
        ActualReportLanguage: Integer;
        ActualGlobalLanguage: Integer;
    begin
        Initialize();
        CleanSetupData();
        CheckInit();
        SalesOrderNo := CreateAssemblySalesDocument(1, "Assembly Document Type"::Order, false);
        SalesHeader.Get(SalesHeader."Document Type"::Order, SalesOrderNo);
        ActualReportLanguage := Language.GetLanguageIdOrDefault(SalesHeader."Language Code");
        ActualGlobalLanguage := GlobalLanguage;
        SetAssemblyTrackingInfo(SalesOrderNo);
        ShipmentNo := PostOrderAsShip(SalesOrderNo, 1);
        SalesShipmentHeader.SetRange("No.", ShipmentNo);
        if ActualReportLanguage <> ActualGlobalLanguage then
            GlobalLanguage(ActualReportLanguage);
        SalesShipment.InitializeRequest(0, false, false, false, true, true);
        SalesShipment.SetTableView(SalesShipmentHeader);
        Commit();
        SalesShipment.Run();
        VerifySalesShipmentLines(SalesShipment.BlanksForIndent());
        if ActualReportLanguage <> ActualGlobalLanguage then
            GlobalLanguage(ActualGlobalLanguage);
        CleanSetupData();
    end;

    local procedure VerifySalesShipmentLines(Blanks: Text[10])
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_SalesShptLine', AssemblyItemNo[1]);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('Description_SalesShptLine', UsedVariantCode[1]);
        LibraryReportDataset.AssertCurrentRowValueEquals('Qty_SalesShptLine', 1);

        LibraryReportDataset.Reset();
        LibraryReportDataset.SetRange('PostedAsmLineItemNo', Blanks + AssemblyItemNo[5]);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('PostedAsmLineQuantity', 2);

        LibraryReportDataset.Reset();
        LibraryReportDataset.SetRange('PostedAsmLineItemNo', Blanks + AssemblyItemNo[6]);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('PostedAsmLineQuantity', 8);
    end;

    local procedure InsertReservationEntry(ItemJournalLine: Record "Item Journal Line"; SerialNo: Code[10]; LotNo: Code[10])
    var
        ReservationEntry: Record "Reservation Entry";
        NextEntryNo: Integer;
    begin
        ReservationEntry.Reset();
        NextEntryNo := 1;
        if ReservationEntry.FindLast() then
            NextEntryNo := ReservationEntry."Entry No." + 1;
        ReservationEntry.Init();
        ReservationEntry."Entry No." := NextEntryNo;
        ReservationEntry.Positive := true;
        ReservationEntry."Item No." := ItemJournalLine."Item No.";
        if LotNo = '' then
            ReservationEntry.Validate("Quantity (Base)", 1)
        else
            ReservationEntry.Validate("Quantity (Base)", ItemJournalLine."Quantity (Base)");
        ReservationEntry.Validate("Reservation Status", ReservationEntry."Reservation Status"::Prospect);
        ReservationEntry."Creation Date" := WorkDate();
        ReservationEntry."Source Type" := DATABASE::"Item Journal Line";
        ReservationEntry."Source ID" := AssemblyTemplate;
        ReservationEntry."Source Batch Name" := AssemblyBatch;
        ReservationEntry."Source Ref. No." := ItemJournalLine."Line No.";
        ReservationEntry."Expected Receipt Date" := WorkDate();
        ReservationEntry."Serial No." := SerialNo;
        ReservationEntry."Lot No." := LotNo;
        ReservationEntry."Qty. per Unit of Measure" := 1;
        ReservationEntry.Quantity := 1;
        if LotNo = '' then
            ReservationEntry."Item Tracking" := ReservationEntry."Item Tracking"::"Serial No."
        else
            ReservationEntry."Item Tracking" := ReservationEntry."Item Tracking"::"Lot No.";
        ReservationEntry.Insert();
    end;

    local procedure GetSerialNoLotNoCode()
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        ItemTrackingCode.SetRange("SN Specific Tracking", true);
        ItemTrackingCode.SetRange("Lot Specific Tracking", false);
        ItemTrackingCode.FindFirst();
        SerialNoCode := ItemTrackingCode.Code;

        ItemTrackingCode.SetRange("SN Specific Tracking", false);
        ItemTrackingCode.SetRange("Lot Specific Tracking", true);
        ItemTrackingCode.FindFirst();
        LotNoCode := ItemTrackingCode.Code;
    end;

    local procedure SetAssemblyTrackingInfo(SalesOrderNo: Code[20])
    var
        SalesLine: Record "Sales Line";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        Assert: Codeunit Assert;
        i: Integer;
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", SalesOrderNo);
        SalesLine.FindFirst();
        Assert.IsTrue(SalesLine.AsmToOrderExists(AssemblyHeader), 'No assembly order found for the sales line');
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        Assert.AreEqual(2, AssemblyLine.Count, 'Wrong number of assembly lines for sales order line.');
        AssemblyLine.FindSet();
        for i := 1 to 2 do begin
            SN := IncStr(SN);
            InsertAssemblyLineTrackingInfo(AssemblyLine, SN, '');
        end;
        AssemblyLine.Next();
        InsertAssemblyLineTrackingInfo(AssemblyLine, '', 'LOT001');
    end;

    local procedure InsertAssemblyLineTrackingInfo(AssemblyLine: Record "Assembly Line"; SerialNo: Code[10]; LotNo: Code[10])
    var
        ReservationEntry: Record "Reservation Entry";
        NextEntry: Integer;
    begin
        NextEntry := 0;
        if ReservationEntry.FindLast() then
            NextEntry := ReservationEntry."Entry No.";
        ReservationEntry.Init();
        NextEntry += 1;
        ReservationEntry."Entry No." := NextEntry;
        ReservationEntry."Creation Date" := WorkDate();
        ReservationEntry."Location Code" := BlueLocation;
        ReservationEntry."Qty. per Unit of Measure" := 1;
        if LotNo = '' then begin
            ReservationEntry."Item No." := AssemblyItemNo[5];
            ReservationEntry."Item Tracking" := ReservationEntry."Item Tracking"::"Serial No.";
            ReservationEntry."Qty. to Handle (Base)" := -1;
            ReservationEntry."Qty. to Invoice (Base)" := -1;
            ReservationEntry.Quantity := -1;
            ReservationEntry."Quantity (Base)" := -1;
            ReservationEntry."Reservation Status" := ReservationEntry."Reservation Status"::Surplus;
            ReservationEntry."Serial No." := SerialNo;
            ReservationEntry."Shipment Date" := WorkDate();
            ReservationEntry."Source ID" := AssemblyLine."Document No.";
            ReservationEntry."Source Ref. No." := AssemblyLine."Line No.";
            ReservationEntry."Source Subtype" := 1;
            // Order
            ReservationEntry."Source Type" := DATABASE::"Assembly Line";
        end else begin
            ReservationEntry."Item No." := AssemblyItemNo[6];
            ReservationEntry."Item Tracking" := ReservationEntry."Item Tracking"::"Lot No.";
            ReservationEntry."Qty. to Handle (Base)" := -8;
            ReservationEntry."Qty. to Invoice (Base)" := -8;
            ReservationEntry.Quantity := -8;
            ReservationEntry."Quantity (Base)" := -8;
            ReservationEntry."Reservation Status" := ReservationEntry."Reservation Status"::Surplus;
            ReservationEntry."Lot No." := LotNo;
            ReservationEntry."Shipment Date" := WorkDate();
            ReservationEntry."Source ID" := AssemblyLine."Document No.";
            ReservationEntry."Source Ref. No." := AssemblyLine."Line No.";
            ReservationEntry."Source Subtype" := 1;
            // Order
            ReservationEntry."Source Type" := DATABASE::"Assembly Line";
        end;
        ReservationEntry.Insert();
    end;

    local procedure CheckInit()
    var
        BOMComponent: Record "BOM Component";
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        i: Integer;
    begin
        if not SetupDataInitialized then begin
            CreateTestNoSeriesBackupData();
            BlueLocation := LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
            GetResource();
            SellToCustomerNo := LibrarySales.CreateCustomerNo();
            LibraryERMCountryData.CreateVATData();
            LibraryERMCountryData.UpdateSalesReceivablesSetup();
            LibraryERMCountryData.UpdateGeneralPostingSetup();
            SetupDataInitialized := true;
        end;
        CreateAssemblyItem();
        GetSKU();
        ProvideAssemblyComponentSupply();
        BOMComponent.SetRange("Parent Item No.", AssemblyItemNo[1]);
        BOMComponent.DeleteAll(true);
        GetSerialNoLotNoCode();
        // Create serialno item and provide supply
        AssemblyItemNo[5] := LibraryAssembly.CreateItem(Item, "Costing Method"::FIFO, "Replenishment System"::" ", '', '');
        Item.Get(AssemblyItemNo[5]);
        Item."Item Tracking Code" := SerialNoCode;
        Item.Modify();
        SerialNoComponentQuantity := 6; // Quantity to put in stock of the serial no. item
        CreateAssemblyComponent(AssemblyItemNo[1], AssemblyItemNo[5], 2, 5, 1);  // Quantity = SerialNoComponentQuantity, Line = 5, Type = 1 = item
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, AssemblyTemplate, AssemblyBatch, "Item Ledger Document Type"::" ", AssemblyItemNo[5], SerialNoComponentQuantity);
        ItemJournalLine.Validate("Location Code", BlueLocation);
        ItemJournalLine.Modify();
        SN := 'SN000';
        for i := 1 to SerialNoComponentQuantity do begin
            SN := IncStr(SN);
            InsertReservationEntry(ItemJournalLine, SN, '');
        end;
        SN := 'SN000';
        LibraryInventory.PostItemJournalLine(AssemblyTemplate, AssemblyBatch);
        // Create LotNo Item and provide supply
        AssemblyItemNo[6] := LibraryAssembly.CreateItem(Item, "Costing Method"::FIFO, "Replenishment System"::" ", '', '');
        Item.Get(AssemblyItemNo[6]);
        Item."Item Tracking Code" := LotNoCode;
        Item.Validate("Replenishment System", Item."Replenishment System"::Assembly);
        Item.Modify();
        LotNoComponentQuantity := 8;
        CreateAssemblyComponent(AssemblyItemNo[1], AssemblyItemNo[6], LotNoComponentQuantity, 6, 1);  // Quantity = LotNoComponentQuantity, Line = 6, Type = 1 = item
        LibraryInventory.CreateItemJournalLine(
            ItemJournalLine, AssemblyTemplate, AssemblyBatch, "Item Ledger Document Type"::" ", AssemblyItemNo[6], 100);
        ItemJournalLine.Validate("Location Code", BlueLocation);
        ItemJournalLine.Modify();
        InsertReservationEntry(ItemJournalLine, '', 'LOT001');
        LibraryInventory.PostItemJournalLine(AssemblyTemplate, AssemblyBatch);
    end;

    local procedure CleanSetupData()
    var
        SalesSetup: Record "Sales & Receivables Setup";
        AssemblySetup: Record "Assembly Setup";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        Clear(LibraryReportDataset);

        if not SetupDataInitialized then
            exit;

        SalesSetup.Get();
        if OldSalesOrderNoSeriesName <> '' then begin
            SalesSetup.Validate("Order Nos.", OldSalesOrderNoSeriesName);
            OldSalesOrderNoSeriesName := '';
        end;
        if OldInvoiceNoSeriesName <> '' then begin
            SalesSetup.Validate("Posted Invoice Nos.", OldInvoiceNoSeriesName);
            OldInvoiceNoSeriesName := '';
        end;
        if StockoutWarningSet then begin
            SalesSetup.Validate("Stockout Warning", OldStockoutWarning);
            StockoutWarningSet := false;
        end;
        SalesSetup."Credit Warnings" := OldCreditWarning;
        SalesSetup.Validate("Customer Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesSetup.Modify();
        if OldAssemblyOrderNoSeries <> '' then begin
            AssemblySetup.Get();
            AssemblySetup."Assembly Order Nos." := OldAssemblyOrderNoSeries;
            AssemblySetup.Modify();
        end;

        if ItemJournalBatch.Get(AssemblyTemplate, AssemblyBatch) then
            ItemJournalBatch.Delete(true);

        SetupDataInitialized := false;
    end;

    local procedure CreateTestNoSeriesBackupData()
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        SalesSetup: Record "Sales & Receivables Setup";
        AssemblySetup: Record "Assembly Setup";
    begin
        // No. series
        NoSeriesName := 'ASMB__TEST';
        Clear(NoSeries);
        NoSeries.Init();
        NoSeries.Code := NoSeriesName;
        NoSeries.Description := NoSeriesName;
        NoSeries."Default Nos." := true;
        if NoSeries.Insert() then begin
            NoSeriesLine.Init();
            NoSeriesLine."Series Code" := NoSeriesName;
            NoSeriesLine."Line No." := 10000;
            NoSeriesLine."Starting No." := 'X00001';
            NoSeriesLine."Ending No." := 'X99999';
            NoSeriesLine."Increment-by No." := 1;
            NoSeriesLine.Insert();
        end;
        // Setup data
        SalesSetup.Get();
        OldSalesOrderNoSeriesName := SalesSetup."Order Nos.";
        OldInvoiceNoSeriesName := SalesSetup."Posted Invoice Nos.";
        OldStockoutWarning := SalesSetup."Stockout Warning";
        StockoutWarningSet := true;
        SalesSetup."Stockout Warning" := false;
        OldCreditWarning := SalesSetup."Credit Warnings";
        SalesSetup."Credit Warnings" := SalesSetup."Credit Warnings"::"No Warning";
        SalesSetup."Order Nos." := NoSeriesName;
        SalesSetup."Posted Invoice Nos." := NoSeriesName;
        SalesSetup.Modify();
        AssemblySetup.Get();
        OldAssemblyOrderNoSeries := AssemblySetup."Assembly Order Nos.";
        AssemblySetup."Assembly Order Nos." := NoSeriesName;
        AssemblySetup.Modify();
    end;

    local procedure CreateAssemblyItem()
    var
        Item: Record Item;
        LibraryAssembly: Codeunit "Library - Assembly";
        i: Integer;
    begin
        LibraryAssembly.CreateItem(Item, "Costing Method"::FIFO, "Replenishment System"::Assembly, '', '');
        Item.Validate("Replenishment System", Item."Replenishment System"::Assembly);
        Item.Validate("Assembly Policy", Item."Assembly Policy"::"Assemble-to-Order");
        Item.Modify();
        AssemblyItemNo[1] := Item."No.";
        CreateVariant(1);
        for i := 2 to 4 do begin
            LibraryAssembly.CreateItem(Item, "Costing Method"::FIFO, "Replenishment System"::" ", '', '');
            AssemblyItemNo[i] := Item."No.";
            CreateVariant(i);
            CreateAssemblyComponent(AssemblyItemNo[1], AssemblyItemNo[i], i, i, 1);
        end;
        CreateAssemblyComponent(AssemblyItemNo[1], '', 0, 5, 0);         // Comment line
        CreateAssemblyComponent(AssemblyItemNo[1], ResourceNo, 1, 6, 2); // Resource line
    end;

    local procedure CreateVariant(VariantNo: Integer)
    var
        ItemVariant: Record "Item Variant";
    begin
        UsedVariantCode[VariantNo] := 'TESTVAR_ ' + Format(VariantNo);
        ItemVariant.Init();
        ItemVariant."Item No." := AssemblyItemNo[VariantNo];
        ItemVariant.Code := UsedVariantCode[VariantNo];
        ItemVariant.Description := UsedVariantCode[VariantNo];
        ItemVariant.Insert();
    end;

    local procedure CreateAssemblyComponent(ParentItemNo: Code[20]; ChildNo: Code[20]; Quantity: Decimal; Line: Integer; Type: Option " ",Item,Resource)
    var
        BOMComponent: Record "BOM Component";
    begin
        BOMComponent.Init();
        BOMComponent."Parent Item No." := ParentItemNo;
        BOMComponent."Line No." := (Line - 1) * 10000;
        case Type of
            Type::" ":
                begin
                    BOMComponent.Type := BOMComponent.Type::" ";
                    BOMComponent.Description := 'Empty Line';
                end;
            Type::Item:
                BOMComponent.Type := BOMComponent.Type::Item;
            Type::Resource:
                BOMComponent.Type := BOMComponent.Type::Resource;
        end;
        if Type <> Type::" " then begin
            BOMComponent.Validate("No.", ChildNo);
            BOMComponent.Validate("Quantity per", Quantity);
            if Line < 5 then
                BOMComponent.Validate("Variant Code", UsedVariantCode[Line]);
        end;
        BOMComponent.Insert(true);
    end;

    local procedure GetResource()
    var
        Resource: Record Resource;
        LibraryResource: Codeunit "Library - Resource";
    begin
        LibraryResource.CreateResourceNew(Resource);
        ResourceNo := Resource."No.";
    end;

    local procedure ProvideAssemblyComponentSupply()
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        LibraryInventory: Codeunit "Library - Inventory";
        i: Integer;
    begin
        ItemJournalTemplate.SetRange(Type, ItemJournalTemplate.Type::Item);
        ItemJournalTemplate.SetRange(Recurring, false);
        ItemJournalTemplate.FindFirst();
        AssemblyTemplate := ItemJournalTemplate.Name;
        Clear(ItemJournalBatch);
        ItemJournalBatch."Journal Template Name" := AssemblyTemplate;
        i := 1;
        while ItemJournalBatch.Get(AssemblyTemplate, 'B' + Format(i)) do
            i += 1;
        ItemJournalBatch.Name := 'B' + Format(i);
        AssemblyBatch := ItemJournalBatch.Name;
        ItemJournalBatch.Insert(true);
        for i := 2 to 4 do begin
            LibraryInventory.CreateItemJournalLine(
                ItemJournalLine, ItemJournalTemplate.Name, AssemblyBatch, "Item Ledger Document Type"::" ", AssemblyItemNo[i], 1000);
            ItemJournalLine.Validate("Location Code", BlueLocation);
            ItemJournalLine.Validate("Variant Code", UsedVariantCode[i]);
            ItemJournalLine.Modify();
        end;
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, AssemblyBatch);
    end;

    local procedure CreateAssemblySalesDocument(AssemblyItemQuantity: Decimal; DocumentType: Enum "Assembly Document Type"; CustomizeOrder: Boolean): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        NoSeries: Codeunit "No. Series";
        LibrarySales: Codeunit "Library - Sales";
    begin
        SalesHeader.Init();
        case DocumentType of
            DocumentType::Quote:
                SalesHeader."Document Type" := SalesHeader."Document Type"::Quote;
            DocumentType::Order:
                SalesHeader."Document Type" := SalesHeader."Document Type"::Order;
            DocumentType::"Blanket Order":
                SalesHeader."Document Type" := SalesHeader."Document Type"::"Blanket Order";
        end;
        SalesHeader."No." := NoSeries.GetNextNo(NoSeriesName, Today());
        SalesHeader.Insert(true);
        SalesHeader.Validate("Sell-to Customer No.", SellToCustomerNo);
        SalesHeader.Validate("Location Code", BlueLocation);
        SalesHeader.Modify();
        if AssemblyItemQuantity > 0 then begin
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, "Sales Line Type"::Item, AssemblyItemNo[1], AssemblyItemQuantity); // 2 -> Item
            SalesLine.Validate("Location Code", BlueLocation);
            SalesLine.Validate("Variant Code", UsedVariantCode[1]);
            SalesLine.Modify(true);
            if CustomizeOrder then
                CustomizeAssemblyOrder(SalesLine);
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, "Sales Line Type"::Resource, ResourceNo, 1);                           // 3 -> Resource
        end;
        exit(SalesHeader."No.");
    end;

    local procedure CustomizeAssemblyOrder(SalesLine: Record "Sales Line")
    var
        AsmHeader: Record "Assembly Header";
        AsmLine: Record "Assembly Line";
        i: Integer;
        LineNo: Integer;
    begin
        if not SalesLine.AsmToOrderExists(AsmHeader) then
            exit;
        LineNo := 50000;
        for i := 4 downto 2 do begin
            LineNo += 10000;
            Clear(AsmLine);
            AsmLine."Document Type" := AsmHeader."Document Type";
            AsmLine."Document No." := AsmHeader."No.";
            AsmLine."Line No." := LineNo;
            AsmLine.Insert(true);
            AsmLine.Type := AsmLine.Type::Item;
            AsmLine.Validate("No.", AssemblyItemNo[i]);
            AsmLine.Validate(Quantity, 10 * i);
            AsmLine.Validate("Quantity per", i);
            AsmLine.Validate("Variant Code", UsedVariantCode[i]);
            AsmLine.Modify(true);
        end;
    end;

    local procedure PostOrderAsShip(NonEmptySalesOrderNo: Code[20]; QtyToShip: Decimal): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentHeader: Record "Sales Shipment Header";
        LibrarySales: Codeunit "Library - Sales";
    begin
        SalesLine.Get(SalesLine."Document Type"::Order, NonEmptySalesOrderNo, GetFirstItemLineNo(NonEmptySalesOrderNo));
        SalesLine.Validate("Qty. to Ship", QtyToShip);
        SalesLine.Modify(true);
        SalesHeader.Get(SalesHeader."Document Type"::Order, NonEmptySalesOrderNo);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        SalesShipmentHeader.SetCurrentKey("Order No.");
        SalesShipmentHeader.SetRange("Order No.", NonEmptySalesOrderNo);
        SalesShipmentHeader.FindFirst();
        SalesShipmentNo := SalesShipmentHeader."No.";
        exit(SalesShipmentNo);
    end;

    local procedure GetSKU()
    var
        SKU: Record "Stockkeeping Unit";
        i: Integer;
    begin
        for i := 1 to 4 do begin
            SKU.Init();
            SKU."Location Code" := BlueLocation;
            SKU."Item No." := AssemblyItemNo[1];
            SKU."Variant Code" := UsedVariantCode[i];
            if SKU.Insert(true) then;
            SKU.Validate("Unit Cost", (i + 1) * 10);
            SKU.Modify(true);
        end;
    end;

    local procedure GetFirstItemLineNo(OrderNo: Code[20]): Integer
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", OrderNo);
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        if not SalesLine.FindFirst() then
            exit(0);
        exit(SalesLine."Line No.");
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReportHandlerSalesShipment(var SalesShipment: TestRequestPage "Sales - Shipment")
    begin
        SalesShipment.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MsgHandler(Message: Text[1024])
    begin
    end;
}
