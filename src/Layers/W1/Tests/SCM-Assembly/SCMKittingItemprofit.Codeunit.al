// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Test;

using System.TestLibraries.Utilities;
using Microsoft.Assembly.Setup;
using Microsoft.Sales.Setup;
using Microsoft.Inventory.Ledger;
using Microsoft.Assembly.History;
using Microsoft.Assembly.Reports;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.BOM;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Assembly.Document;
using Microsoft.Sales.Document;
using Microsoft.Assembly.Posting;
using Microsoft.Sales.History;

codeunit 137312 "SCM Kitting - Item profit"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Assembly] [SCM]
        isInitialized := false;
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        GenProdPostingGr: Code[20];
        AsmInvtPostingGr: Code[20];
        CompInvtPostingGr: Code[20];
        UndoShipmMsg: Label 'Do you really want to undo the selected Shipment lines?';
        TotalSaleTxt: Label 'Directly';
        TotalAssemblyTxt: Label 'In Assembly';
        AssemblyTxt: Label 'Assembly';

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Kitting - Item profit");
        // Initialize setup.
        ClearLastError();
        LibraryVariableStorage.Clear();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Kitting - Item profit");

        // Setup Demonstration data.
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateInventoryPostingSetup();
        SetupAssembly();
        LibraryAssembly.SetupPostingToGL(GenProdPostingGr, AsmInvtPostingGr, CompInvtPostingGr, '');
        LibraryCosting.AdjustCostItemEntries('', '');

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Kitting - Item profit");
    end;

    [Normal]
    local procedure SetupAssembly()
    var
        AssemblySetup: Record "Assembly Setup";
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        AssemblySetup.Get();
        AssemblySetup.Validate("Assembly Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        AssemblySetup.Validate("Posted Assembly Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        AssemblySetup.Validate("Default Location for Orders", '');
        AssemblySetup.Validate("Stockout Warning", false);
        AssemblySetup.Modify(true);

        SalesSetup.Get();
        SalesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesSetup.Validate("Invoice Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesSetup.Validate("Posted Invoice Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesSetup.Validate("Posted Shipment Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesSetup.Validate("Stockout Warning", false);
        SalesSetup.Validate("Credit Warnings", SalesSetup."Credit Warnings"::"No Warning");
        SalesSetup.Modify(true);
    end;

    local procedure FindATO(ItemLedgEntry: Record "Item Ledger Entry"): Code[20]
    var
        PostedATOLink: Record "Posted Assemble-to-Order Link";
        ItemApplnEntry: Record "Item Application Entry";
    begin
        if not ItemLedgEntry."Assemble to Order" then
            exit('');

        if ItemLedgEntry."Document Type" <> ItemLedgEntry."Document Type"::"Sales Shipment" then
            exit('');

        PostedATOLink.SetCurrentKey("Document Type", "Document No.", "Document Line No.");
        PostedATOLink.SetRange("Document Type", PostedATOLink."Document Type"::"Sales Shipment");
        PostedATOLink.SetRange("Document No.", ItemLedgEntry."Document No.");
        PostedATOLink.SetRange("Document Line No.", ItemLedgEntry."Document Line No.");
        if PostedATOLink.FindFirst() then
            exit(PostedATOLink."Assembly Order No.");

        if ItemLedgEntry.Correction then
            if ItemApplnEntry.AppliedFromEntryExists(ItemLedgEntry."Entry No.") then begin
                ItemLedgEntry.Get(ItemApplnEntry."Outbound Item Entry No.");
                exit(FindATO(ItemLedgEntry));
            end;
    end;

    local procedure ProcessILEsToTemp(var TempATOSalesBuffer: Record "ATO Sales Buffer" temporary; var Item: Record Item)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        ItemLedgerEntry.SetFilter("Location Code", Item.GetFilter("Location Filter"));
        ItemLedgerEntry.SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
        ItemLedgerEntry.SetFilter("Posting Date", Item.GetFilter("Date Filter"));
        if ItemLedgerEntry.FindSet() then
            repeat
                ItemLedgerEntry.CalcFields(
                  "Cost Amount (Expected)", "Cost Amount (Actual)", "Sales Amount (Expected)", "Sales Amount (Actual)");
                // IF ATO entry then process the components, otherwise add the ledger entry itself
                if ItemLedgerEntry."Assemble to Order" then
                    ProcessComponentsToList(TempATOSalesBuffer, ItemLedgerEntry."Item No.", FindATO(ItemLedgerEntry),
                      CalculateProfit(ItemLedgerEntry."Sales Amount (Expected)" + ItemLedgerEntry."Sales Amount (Actual)",
                        -(ItemLedgerEntry."Cost Amount (Expected)" + ItemLedgerEntry."Cost Amount (Actual)")))
                else
                    AddSaleToList(TempATOSalesBuffer, ItemLedgerEntry);
            until ItemLedgerEntry.Next() = 0;
    end;

    local procedure ProcessComponentsToList(var TempATOSalesBuffer: Record "ATO Sales Buffer" temporary; ParentItemNo: Code[20]; OrderNo: Code[20]; ParentProfit: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::"Assembly Consumption");
        ItemLedgerEntry.SetRange("Order No.", OrderNo);
        ItemLedgerEntry.SetRange("Order Type", ItemLedgerEntry."Order Type"::Assembly);
        ItemLedgerEntry.SetRange("Source No.", ParentItemNo);
        if ItemLedgerEntry.FindSet() then
            repeat
                ItemLedgerEntry.CalcFields(
                  "Cost Amount (Expected)", "Cost Amount (Actual)", "Sales Amount (Expected)", "Sales Amount (Actual)");
                AddATOConsumptionToList(TempATOSalesBuffer, ParentProfit, ItemLedgerEntry, TempATOSalesBuffer.Type::Assembly);
                AddATOConsumptionToList(TempATOSalesBuffer, ParentProfit, ItemLedgerEntry, TempATOSalesBuffer.Type::"Total Assembly");
            until ItemLedgerEntry.Next() = 0;
    end;

    local procedure AddSaleToList(var TempATOSalesBuffer: Record "ATO Sales Buffer" temporary; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        Clear(TempATOSalesBuffer);
        TempATOSalesBuffer.SetRange(Type, TempATOSalesBuffer.Type::"Total Sale");
        TempATOSalesBuffer.SetRange("Item No.", ItemLedgerEntry."Item No.");
        if TempATOSalesBuffer.FindFirst() then begin
            TempATOSalesBuffer.Quantity += -ItemLedgerEntry.Quantity;
            TempATOSalesBuffer."Sales Cost" += -(ItemLedgerEntry."Cost Amount (Expected)" + ItemLedgerEntry."Cost Amount (Actual)");
            TempATOSalesBuffer."Sales Amount" += ItemLedgerEntry."Sales Amount (Expected)" + ItemLedgerEntry."Sales Amount (Actual)";
            TempATOSalesBuffer."Profit %" := CalculateProfit(TempATOSalesBuffer."Sales Amount", TempATOSalesBuffer."Sales Cost");
            TempATOSalesBuffer.Modify(true);
        end else begin
            TempATOSalesBuffer.Reset();
            TempATOSalesBuffer.Type := TempATOSalesBuffer.Type::"Total Sale";
            TempATOSalesBuffer."Order No." := '';
            TempATOSalesBuffer."Item No." := ItemLedgerEntry."Item No.";
            TempATOSalesBuffer."Parent Item No." := '';
            TempATOSalesBuffer."Parent Description" := '';
            TempATOSalesBuffer.Quantity := -ItemLedgerEntry.Quantity;
            TempATOSalesBuffer."Sales Cost" := -(ItemLedgerEntry."Cost Amount (Expected)" + ItemLedgerEntry."Cost Amount (Actual)");
            TempATOSalesBuffer."Sales Amount" := ItemLedgerEntry."Sales Amount (Expected)" + ItemLedgerEntry."Sales Amount (Actual)";
            TempATOSalesBuffer."Profit %" := CalculateProfit(TempATOSalesBuffer."Sales Amount", TempATOSalesBuffer."Sales Cost");
            TempATOSalesBuffer.Insert(true);
        end;
    end;

    local procedure AddATOConsumptionToList(var TempATOSalesBuffer: Record "ATO Sales Buffer" temporary; ParentProfit: Decimal; ItemLedgerEntry: Record "Item Ledger Entry"; EntryType: Option ,Sale,"Total Sale",Assembly,"Total Assembly")
    begin
        Clear(TempATOSalesBuffer);
        TempATOSalesBuffer.SetRange(Type, EntryType);
        TempATOSalesBuffer.SetRange("Item No.", ItemLedgerEntry."Item No.");
        if EntryType <> TempATOSalesBuffer.Type::"Total Assembly" then
            TempATOSalesBuffer.SetRange("Parent Item No.", ItemLedgerEntry."Source No.");

        if TempATOSalesBuffer.FindFirst() then begin
            TempATOSalesBuffer.Quantity += -ItemLedgerEntry.Quantity;
            TempATOSalesBuffer."Sales Cost" += -(ItemLedgerEntry."Cost Amount (Expected)" + ItemLedgerEntry."Cost Amount (Actual)");
            TempATOSalesBuffer."Sales Amount" +=
              CalculateSalesAmount(-(ItemLedgerEntry."Cost Amount (Expected)" + ItemLedgerEntry."Cost Amount (Actual)"), ParentProfit);
            TempATOSalesBuffer."Profit %" := CalculateProfit(TempATOSalesBuffer."Sales Amount", TempATOSalesBuffer."Sales Cost");
            TempATOSalesBuffer.Modify(true);
        end else begin
            TempATOSalesBuffer.Reset();
            TempATOSalesBuffer.Type := EntryType;
            if EntryType <> TempATOSalesBuffer.Type::"Total Assembly" then begin
                TempATOSalesBuffer."Order No." := '';
                TempATOSalesBuffer."Parent Item No." := ItemLedgerEntry."Source No.";
                TempATOSalesBuffer."Parent Description" := GetItemDescription(TempATOSalesBuffer."Parent Item No.");
            end else begin
                TempATOSalesBuffer."Order No." := '';
                TempATOSalesBuffer."Parent Item No." := ItemLedgerEntry."Item No.";
                TempATOSalesBuffer."Parent Description" := '';
            end;
            TempATOSalesBuffer."Item No." := ItemLedgerEntry."Item No.";
            TempATOSalesBuffer.Quantity := -ItemLedgerEntry.Quantity;
            TempATOSalesBuffer."Sales Cost" := -(ItemLedgerEntry."Cost Amount (Expected)" + ItemLedgerEntry."Cost Amount (Actual)");
            TempATOSalesBuffer."Sales Amount" := CalculateSalesAmount(TempATOSalesBuffer."Sales Cost", ParentProfit);
            TempATOSalesBuffer."Profit %" := ParentProfit;
            TempATOSalesBuffer.Insert(true);
        end;
    end;

    local procedure CalculateProfit(SalesAmount: Decimal; SalesCost: Decimal): Decimal
    begin
        if SalesAmount <> 0 then
            exit(Round((SalesAmount - SalesCost) / SalesAmount * 100));

        exit(0)
    end;

    local procedure CalculateSalesAmount(SalesCost: Decimal; Profit: Decimal): Decimal
    begin
        if Profit <> 100 then
            exit(Round(100 * SalesCost / (100 - Profit)));

        exit(0)
    end;

    local procedure GetItemDescription(ItemNo: Code[20]): Text[50]
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo); // let it fail if doesn't exist

        exit(Item.Description);
    end;

    local procedure GetNoOfRowsForItemAndType(var TempATOSalesBuffer: Record "ATO Sales Buffer" temporary; ItemNo: Code[20]; Type: Option; ShowAsmInfo: Boolean): Integer
    var
        ATOSalesBuffer: Record "ATO Sales Buffer";
        NoOfRows: Integer;
    begin
        NoOfRows := 0;

        ATOSalesBuffer.Copy(TempATOSalesBuffer);
        TempATOSalesBuffer.Reset();
        TempATOSalesBuffer.SetRange("Item No.", ItemNo);
        TempATOSalesBuffer.SetRange(Type, TempATOSalesBuffer.Type::Assembly);
        TempATOSalesBuffer.SetFilter(Quantity, '<>%1', 0);

        case Type of
            ATOSalesBuffer.Type::"Total Assembly":
                NoOfRows := 1;
            ATOSalesBuffer.Type::"Total Sale":
                begin
                    TempATOSalesBuffer.SetRange(Type, TempATOSalesBuffer.Type::Assembly);
                    if IsATOComp(ItemNo) or (not TempATOSalesBuffer.IsEmpty) then
                        NoOfRows := 1;
                end;
            ATOSalesBuffer.Type::Assembly:
                begin
                    TempATOSalesBuffer.SetRange(Type, TempATOSalesBuffer.Type::Assembly);
                    if ShowAsmInfo and (not TempATOSalesBuffer.IsEmpty) then
                        NoOfRows := TempATOSalesBuffer.Count();
                    TempATOSalesBuffer.Copy(ATOSalesBuffer);
                end;
        end;

        exit(NoOfRows);
    end;

    local procedure IsATOComp(ItemNo: Code[20]): Boolean
    var
        BOMComponent: Record "BOM Component";
        ParentItem: Record Item;
    begin
        // Search all the asm BOM lists and find at least one parent having Assembly-policy = Assemble-to-Order
        BOMComponent.SetRange("No.", ItemNo);
        BOMComponent.SetRange(Type, BOMComponent.Type::Item);
        if BOMComponent.FindSet() then
            repeat
                ParentItem.Get(BOMComponent."Parent Item No.");
                if ParentItem."Assembly Policy" = ParentItem."Assembly Policy"::"Assemble-to-Order" then
                    exit(true);
            until BOMComponent.Next() = 0;

        exit(false);
    end;

    local procedure RunReportAndProcessEntries(var TempATOSalesBuffer: Record "ATO Sales Buffer" temporary; var Item: Record Item; ShowAsmInfo: Boolean)
    var
        ShowGraphAs: Option Quantity,Sales,ProfitPct;
    begin
        LibraryCosting.AdjustCostItemEntries(Item.GetFilter("No."), '');
        Commit();
        RunReportAndOpenFile(Item, ShowGraphAs::Quantity, ShowAsmInfo);
        ProcessILEsToTemp(TempATOSalesBuffer, Item);
    end;

    local procedure RunReportAndOpenFile(var Item: Record Item; ShowGraphAs: Option Quantity,Sales,ProfitPct; ShowAsmInfo: Boolean)
    begin
        LibraryVariableStorage.Enqueue(ShowGraphAs);
        LibraryVariableStorage.Enqueue(ShowAsmInfo);
        REPORT.Run(REPORT::"Assemble to Order - Sales", true, false, Item);
    end;

    local procedure GetItemsFromAsmListAsFilter(Item: Record Item): Text
    var
        BOMComponent: Record "BOM Component";
        Filters: Text;
    begin
        Filters := Format(Item."No.");
        BOMComponent.SetRange("Parent Item No.", Item."No.");
        BOMComponent.SetRange(Type, BOMComponent.Type::Item);
        if BOMComponent.FindSet() then
            repeat
                Filters += Format('|' + BOMComponent."No.");
            until BOMComponent.Next() = 0;

        exit(Filters);
    end;

    local procedure CreateAssemblyList(ParentItem: Record Item; CostingMethod: Enum "Costing Method"; UnitCost: Decimal; NoOfComponents: Integer; NoOfResources: Integer; NoOfTexts: Integer; QtyPer: Decimal)
    var
        Item: Record Item;
        Resource: Record Resource;
        BOMComponent: Record "BOM Component";
        CompCount: Integer;
    begin
        // Add components - qty per is increasing same as no of components
        for CompCount := 1 to NoOfComponents do begin
            Clear(Item);
            LibraryInventory.CreateItem(Item);
            Item.Validate("Costing Method", CostingMethod);
            Item.Validate("Unit Cost", UnitCost);
            Item.Modify(true);
            AddComponentToAssemblyList(
              BOMComponent, "BOM Component Type"::Item, Item."No.", ParentItem."No.", '',
              BOMComponent."Resource Usage Type"::Direct, Item."Base Unit of Measure", QtyPer);
        end;

        // Add resources - qty per is increasing same as no of components
        for CompCount := 1 to NoOfResources do begin
            LibraryAssembly.CreateResource(Resource, true, GenProdPostingGr);
            AddComponentToAssemblyList(
              BOMComponent, BOMComponent.Type::Resource, Resource."No.", ParentItem."No.", '',
              BOMComponent."Resource Usage Type"::Direct, Resource."Base Unit of Measure", QtyPer);
        end;

        // Add simple text
        for CompCount := 1 to NoOfTexts do
            AddComponentToAssemblyList(BOMComponent, BOMComponent.Type::" ", '', ParentItem."No.", '',
              BOMComponent."Resource Usage Type"::Direct, '', QtyPer);
    end;

    local procedure AddComponentToAssemblyList(var BOMComponent: Record "BOM Component"; ComponentType: Enum "BOM Component Type"; ComponentNo: Code[20]; ParentItemNo: Code[20]; VariantCode: Code[10]; ResourceUsage: Option; UOM: Code[10]; QuantityPer: Decimal)
    begin
        LibraryInventory.CreateBOMComponent(BOMComponent, ParentItemNo, ComponentType, ComponentNo, QuantityPer, UOM);
        if ComponentType = BOMComponent.Type::Resource then
            BOMComponent.Validate("Resource Usage Type", ResourceUsage);
        BOMComponent.Validate("Variant Code", VariantCode);
        if ComponentNo = '' then
            BOMComponent.Validate(Description,
              LibraryUtility.GenerateRandomCode(BOMComponent.FieldNo(Description), DATABASE::"BOM Component"));
        BOMComponent.Modify(true);
    end;

    local procedure CreateAssemblyOrder(var AssemblyHeader: Record "Assembly Header"; ParentItem: Record Item; LocationCode: Code[10]; BinCode: Code[20]; VariantCode: Code[10]; DueDate: Date; Quantity: Decimal)
    begin
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, DueDate, ParentItem."No.", LocationCode, Quantity, VariantCode);
        AssemblyHeader.Validate("Bin Code", BinCode);
        AssemblyHeader.Modify(true);
    end;

    local procedure CreateAssembledItem(var Item: Record Item; AssemblyPolicy: Enum "Assembly Policy"; CostingMethod: Enum "Costing Method"; UnitCost: Decimal; NoOfComponents: Integer; NoOfResources: Integer; NoOfTexts: Integer; QtyPer: Decimal)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::Assembly);
        Item.Validate("Assembly Policy", AssemblyPolicy);
        Item.Validate("Costing Method", CostingMethod);
        Item.Validate("Unit Cost", UnitCost);
        Item.Modify(true);
        CreateAssemblyList(Item, CostingMethod, UnitCost, NoOfComponents, NoOfResources, NoOfTexts, QtyPer);
    end;

    local procedure CreateSaleDocType(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; ItemNo: Code[20]; VariantCode: Code[10]; UnitPrice: Decimal; SalesQty: Decimal; ShipmentDate: Date; LocationCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        Clear(SalesHeader);
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, '');
        SalesHeader.Validate("Location Code", LocationCode);
        SalesHeader.Validate("Shipment Date", ShipmentDate);
        SalesHeader.Validate("Posting Date", ShipmentDate);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLineWithShipmentDate(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, ShipmentDate, SalesQty);
        SalesLine.Validate("Variant Code", VariantCode);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; VariantCode: Code[10]; UnitPrice: Decimal; SalesQty: Decimal; ShipmentDate: Date; LocationCode: Code[10])
    begin
        CreateSaleDocType(
          SalesHeader, SalesHeader."Document Type"::Order, ItemNo, VariantCode, UnitPrice, SalesQty, ShipmentDate, LocationCode);
    end;

    local procedure CreateAndPostATO(Item: Record Item; OrderQty: Decimal; DueDate: Date; ATOPercentage: Decimal): Code[20]
    var
        SalesHeader: Record "Sales Header";
        AssemblyHeader: Record "Assembly Header";
        SalesLine: Record "Sales Line";
    begin
        CreateSalesOrder(SalesHeader, Item."No.", '', LibraryRandom.RandDec(100, 2), OrderQty, DueDate, '');
        FindSOL(SalesHeader, SalesLine, 1);
        if Item."Assembly Policy" <> Item."Assembly Policy"::"Assemble-to-Order" then begin
            SalesLine.Validate("Qty. to Assemble to Order", ATOPercentage / 100 * SalesLine.Quantity);
            SalesLine.Modify(true);
        end;

        SalesLine.AsmToOrderExists(AssemblyHeader);
        LibraryAssembly.AddCompInventoryToBin(AssemblyHeader, WorkDate(), 0, '', '');
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, false));
    end;

    local procedure CreateAndPostATS(Item: Record Item; OrderQty: Decimal; DueDate: Date; ATSPercentage: Decimal): Code[20]
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        CreateAssemblyOrder(AssemblyHeader, Item, '', '', '', DueDate, OrderQty);
        LibraryAssembly.AddCompInventoryToBin(AssemblyHeader, WorkDate(), 0, '', '');
        PostAssemblyOrderQty(AssemblyHeader, ATSPercentage / 100 * OrderQty);

        exit(AssemblyHeader."No.");
    end;

    local procedure FindSOL(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; SOLIndex: Integer)
    begin
        Clear(SalesLine);
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindSet(true);

        if SOLIndex > 1 then
            SalesLine.Next(SOLIndex - 1);
    end;

    local procedure FindSalesLine(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.FindFirst();
    end;

    local procedure FindComponent(Item: Record Item; var BOMComponent: Record "BOM Component"; ComponentIndex: Integer)
    begin
        BOMComponent.SetRange("Parent Item No.", Item."No.");
        BOMComponent.Validate(Type, BOMComponent.Type::Item);
        BOMComponent.FindSet(true);

        if ComponentIndex > 1 then
            BOMComponent.Next(ComponentIndex - 1);
    end;

    local procedure PostAssemblyOrderQty(var AssemblyHeader: Record "Assembly Header"; Qty: Decimal)
    var
        AssemblyPost: Codeunit "Assembly-Post";
    begin
        Clear(AssemblyPost);
        AssemblyHeader.Validate("Quantity to Assemble", Qty);
        AssemblyHeader.Modify(true);

        AssemblyPost.Run(AssemblyHeader);
    end;

    local procedure ValidateReportLines(var TempATOSalesBuffer: Record "ATO Sales Buffer" temporary; var Item: Record Item; ShowAsmInfo: Boolean)
    var
        ActualNoOfRows: Integer;
        NoOfRows: Integer;
    begin
        LibraryReportDataset.LoadDataSetFile();
        TempATOSalesBuffer.Reset();
        TempATOSalesBuffer.SetFilter("Item No.", Item.GetFilter("No."));
        TempATOSalesBuffer.SetFilter(Quantity, '<>%1', 0);

        if TempATOSalesBuffer.FindSet() then
            repeat
                LibraryReportDataset.SetRange('Item_No', TempATOSalesBuffer."Item No.");
                NoOfRows :=
                  GetNoOfRowsForItemAndType(TempATOSalesBuffer, TempATOSalesBuffer."Item No.", TempATOSalesBuffer.Type, ShowAsmInfo);
                ActualNoOfRows := 0;
                case TempATOSalesBuffer.Type of
                    TempATOSalesBuffer.Type::"Total Sale":
                        ValidateReportLine(ActualNoOfRows, TempATOSalesBuffer, TotalSaleTxt, ShowAsmInfo);
                    TempATOSalesBuffer.Type::"Total Assembly":
                        ValidateReportLine(ActualNoOfRows, TempATOSalesBuffer, TotalAssemblyTxt, ShowAsmInfo);
                    TempATOSalesBuffer.Type::Assembly:
                        ValidateReportLine(ActualNoOfRows, TempATOSalesBuffer, AssemblyTxt, ShowAsmInfo);
                end;

                Assert.AreEqual(NoOfRows, ActualNoOfRows,
                  'Wrong no. of rows for item ' + TempATOSalesBuffer."Item No." + ' and type ' + Format(TempATOSalesBuffer.Type));
            until TempATOSalesBuffer.Next() = 0;
    end;

    [Normal]
    local procedure ValidateReportLine(var ActualNoOfRows: Integer; ATOSalesBuffer: Record "ATO Sales Buffer"; SalesBufferTypeFilter: Text; ShowAsmInfo: Boolean)
    var
        VarText: Variant;
        VarDecimal: Variant;
        SalesBufferType: Text;
        ParentItemNo: Text;
        SalesCost: Decimal;
        SalesAmt: Decimal;
    begin
        ActualNoOfRows := 0;

        while LibraryReportDataset.GetNextRow() do begin
            LibraryReportDataset.FindCurrentRowValue('Type', VarText);
            Evaluate(SalesBufferType, VarText);

            if SalesBufferType = SalesBufferTypeFilter then begin
                ActualNoOfRows += 1;

                if (SalesBufferTypeFilter = AssemblyTxt) and ShowAsmInfo then begin
                    LibraryReportDataset.FindCurrentRowValue('ParentItemNo', VarText);
                    Evaluate(ParentItemNo, VarText);
                end;

                if (ParentItemNo = ATOSalesBuffer."Parent Item No.") or (ParentItemNo = '') then begin
                    LibraryReportDataset.AssertCurrentRowValueEquals('Quantity', ATOSalesBuffer.Quantity);
                    LibraryReportDataset.FindCurrentRowValue('SalesCost', VarDecimal);
                    SalesCost := VarDecimal;
                    Assert.AreNearlyEqual(
                      ATOSalesBuffer."Sales Cost", SalesCost, 100 * LibraryERM.GetAmountRoundingPrecision(), 'Wrong sales cost.');

                    LibraryReportDataset.FindCurrentRowValue('SalesAmt', VarDecimal);
                    SalesAmt := VarDecimal;
                    Assert.AreNearlyEqual(
                      ATOSalesBuffer."Sales Amount", SalesAmt, 100 * LibraryERM.GetAmountRoundingPrecision(), 'Wrong sales amt.');

                    LibraryReportDataset.AssertCurrentRowValueEquals('ProfitPct', ATOSalesBuffer."Profit %");
                end;
            end;
        end;
    end;

    local procedure ValidateNoFileCreated(var TempATOSalesBuffer: Record "ATO Sales Buffer" temporary; var Item: Record Item)
    begin
        Commit();
        RunReportAndProcessEntries(TempATOSalesBuffer, Item, true);
        LibraryReportDataset.LoadDataSetFile();
        Assert.IsFalse(LibraryReportDataset.GetNextRow(), 'Report should be empty.');
    end;

    local procedure WithAndWithoutATO(FullPosting: Boolean; IsATO: Boolean; ShouldInvoice: Boolean)
    var
        TempATOSalesBuffer: Record "ATO Sales Buffer" temporary;
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OrderQty: Decimal;
        DueDate: Date;
    begin
        Initialize();

        // Create AO
        CreateAssembledItem(
          Item, Item."Assembly Policy"::"Assemble-to-Order", Item."Costing Method"::FIFO, LibraryRandom.RandDec(100, 2),
          LibraryRandom.RandInt(3), LibraryRandom.RandInt(3), LibraryRandom.RandInt(3),
          LibraryRandom.RandDec(100, 2));
        OrderQty := LibraryRandom.RandDec(100, 2) + 1;
        DueDate := CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate());

        if IsATO then begin
            CreateSalesOrder(SalesHeader, Item."No.", '', LibraryRandom.RandDec(100, 2), OrderQty, DueDate, '');
            FindSOL(SalesHeader, SalesLine, 1);
            SalesLine.AsmToOrderExists(AssemblyHeader);
        end else
            CreateAssemblyOrder(AssemblyHeader, Item, '', '', '', DueDate, OrderQty);

        // Add enough inventory for comp and post
        LibraryAssembly.AddCompInventoryToBin(AssemblyHeader, WorkDate(), 0, '', '');

        if FullPosting then begin
            if IsATO then
                LibrarySales.PostSalesDocument(SalesHeader, true, ShouldInvoice)
            else
                PostAssemblyOrderQty(AssemblyHeader, OrderQty)
        end else
            if IsATO then begin
                SalesLine.Find();
                SalesLine.Validate("Qty. to Ship", Round(SalesLine."Qty. to Ship" / 2, 0.00001));
                SalesLine.Modify(true);
                LibrarySales.PostSalesDocument(SalesHeader, true, ShouldInvoice);
                AssemblyHeader.Find();
            end else
                PostAssemblyOrderQty(AssemblyHeader, OrderQty / 2);

        // Exercise
        Item.SetFilter("No.", GetItemsFromAsmListAsFilter(Item));
        if IsATO then begin
            RunReportAndProcessEntries(TempATOSalesBuffer, Item, true);
            // Validate
            ValidateReportLines(TempATOSalesBuffer, Item, true);
        end else
            ValidateNoFileCreated(TempATOSalesBuffer, Item);
    end;

    [Test]
    [HandlerFunctions('AssembleToOrderSalesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ATOFullInvoice()
    begin
        WithAndWithoutATO(true, true, true);
    end;

    local procedure UpdateSalesLine(SalesHeader: Record "Sales Header"; VATIdentifier: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        FindSalesLine(SalesHeader, SalesLine);
        SalesLine.Validate("VAT Identifier", VATIdentifier);
        SalesLine.Modify(true);
    end;

    [Test]
    [HandlerFunctions('AssembleToOrderSalesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ATOPartialInvoice()
    begin
        WithAndWithoutATO(false, true, true);
    end;

    [Test]
    [HandlerFunctions('AssembleToOrderSalesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ATOFullNotInvoiced()
    begin
        WithAndWithoutATO(true, true, false);
    end;

    [Test]
    [HandlerFunctions('AssembleToOrderSalesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ATOPartialNotInvoiced()
    begin
        WithAndWithoutATO(false, true, false);
    end;

    [Test]
    [HandlerFunctions('AssembleToOrderSalesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure NoATOFullPosting()
    begin
        WithAndWithoutATO(true, false, false);
    end;

    [Test]
    [HandlerFunctions('AssembleToOrderSalesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure NoATOPartialPosting()
    begin
        WithAndWithoutATO(false, false, false);
    end;

    local procedure SaleAndATOOrATS(AssemblyPolicy: Enum "Assembly Policy"; ATO: Boolean; ShowDetails: Boolean)
    var
        TempATOSalesBuffer: Record "ATO Sales Buffer" temporary;
        BOMComponent: Record "BOM Component";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
    begin
        Initialize();

        // Create ATO item
        CreateAssembledItem(Item, AssemblyPolicy, Item."Costing Method"::FIFO, LibraryRandom.RandDec(100, 2),
          LibraryRandom.RandInt(3), LibraryRandom.RandInt(3), LibraryRandom.RandInt(3),
          LibraryRandom.RandDec(100, 2));
        if ATO then
            CreateAndPostATO(
              Item, LibraryRandom.RandDec(100, 2) + 1, CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate()),
              100);

        // Find a component and sell it
        FindComponent(Item, BOMComponent, 1);
        CreateSalesOrder(
          SalesHeader, BOMComponent."No.", '', LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2),
          CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate()), '');
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // Exercise - for the component only
        Item.SetFilter("No.", BOMComponent."No.");
        RunReportAndProcessEntries(TempATOSalesBuffer, Item, ShowDetails);

        // Validate
        ValidateReportLines(TempATOSalesBuffer, Item, ShowDetails);
    end;

    [Test]
    [HandlerFunctions('AssembleToOrderSalesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SaleAndATO()
    var
        Item: Record Item;
    begin
        SaleAndATOOrATS(Item."Assembly Policy"::"Assemble-to-Order", true, true);
    end;

    [Test]
    [HandlerFunctions('AssembleToOrderSalesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SaleAndATSasATO()
    var
        Item: Record Item;
    begin
        SaleAndATOOrATS(Item."Assembly Policy"::"Assemble-to-Stock", true, true);
    end;

    [Test]
    [HandlerFunctions('AssembleToOrderSalesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SaleAndATONoDetails()
    var
        Item: Record Item;
    begin
        SaleAndATOOrATS(Item."Assembly Policy"::"Assemble-to-Order", true, false);
    end;

    [Test]
    [HandlerFunctions('AssembleToOrderSalesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SaleAndATSasATONoDetails()
    var
        Item: Record Item;
    begin
        SaleAndATOOrATS(Item."Assembly Policy"::"Assemble-to-Stock", true, false);
    end;

    [Test]
    [HandlerFunctions('AssembleToOrderSalesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnlySaleATS()
    var
        Item: Record Item;
    begin
        SaleAndATOOrATS(Item."Assembly Policy"::"Assemble-to-Order", false, true);
    end;

    [Test]
    [HandlerFunctions('AssembleToOrderSalesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnlySaleATO()
    var
        Item: Record Item;
    begin
        SaleAndATOOrATS(Item."Assembly Policy"::"Assemble-to-Order", true, true);
    end;

    [Test]
    [HandlerFunctions('AssembleToOrderSalesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ATSAndATOFIFO()
    var
        Item: Record Item;
    begin
        ATSAndATO(Item."Costing Method"::FIFO);
    end;

    [Test]
    [HandlerFunctions('AssembleToOrderSalesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ATSAndATOLIFO()
    var
        Item: Record Item;
    begin
        ATSAndATO(Item."Costing Method"::LIFO);
    end;

    [Test]
    [HandlerFunctions('AssembleToOrderSalesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ATSAndATOStandard()
    var
        Item: Record Item;
    begin
        ATSAndATO(Item."Costing Method"::Standard);
    end;

    [Test]
    [HandlerFunctions('AssembleToOrderSalesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ATSAndATOAverage()
    var
        Item: Record Item;
    begin
        ATSAndATO(Item."Costing Method"::Average);
    end;

    local procedure ATSAndATO(CostingMethod: Enum "Costing Method")
    var
        TempATOSalesBuffer: Record "ATO Sales Buffer" temporary;
        Item: Record Item;
    begin
        Initialize();

        // Create item
        CreateAssembledItem(Item, Item."Assembly Policy"::"Assemble-to-Stock", CostingMethod, LibraryRandom.RandDec(100, 2),
          LibraryRandom.RandInt(3), LibraryRandom.RandInt(3), LibraryRandom.RandInt(3),
          LibraryRandom.RandDec(100, 2));
        CreateAndPostATO(
          Item, LibraryRandom.RandDec(100, 2) + 1, CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate()), 100);
        CreateAndPostATS(
          Item, LibraryRandom.RandDec(100, 2) + 1, CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate()), 100);

        // Exercise - all items from asm list
        Item.SetFilter("No.", GetItemsFromAsmListAsFilter(Item));
        RunReportAndProcessEntries(TempATOSalesBuffer, Item, true);

        // Validate
        ValidateReportLines(TempATOSalesBuffer, Item, true);
    end;

    [Test]
    [HandlerFunctions('AssembleToOrderSalesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TwoATOSameParent()
    var
        TempATOSalesBuffer: Record "ATO Sales Buffer" temporary;
        Item: Record Item;
    begin
        Initialize();

        // Create item
        CreateAssembledItem(
          Item, Item."Assembly Policy"::"Assemble-to-Order", Item."Costing Method"::FIFO, LibraryRandom.RandDec(100, 2),
          LibraryRandom.RandInt(3), LibraryRandom.RandInt(3), LibraryRandom.RandInt(3),
          LibraryRandom.RandDec(100, 2));
        CreateAndPostATO(
          Item, LibraryRandom.RandDec(100, 2) + 1, CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate()), 100);
        CreateAndPostATO(
          Item, LibraryRandom.RandDec(100, 2) + 1, CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate()), 100);

        // Exercise - all items from asm list
        Item.SetFilter("No.", GetItemsFromAsmListAsFilter(Item));
        RunReportAndProcessEntries(TempATOSalesBuffer, Item, true);

        // Validate
        ValidateReportLines(TempATOSalesBuffer, Item, true);
    end;

    [Test]
    [HandlerFunctions('AssembleToOrderSalesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TwoATODifferentParentDetail()
    begin
        TwoATODifferentParent(true);
    end;

    [Test]
    [HandlerFunctions('AssembleToOrderSalesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TwoATODifferentParentNoDetail()
    begin
        TwoATODifferentParent(false);
    end;

    local procedure TwoATODifferentParent(ShowDetails: Boolean)
    var
        TempATOSalesBuffer: Record "ATO Sales Buffer" temporary;
        BOMComponent: Record "BOM Component";
        Item1: Record Item;
        Item2: Record Item;
    begin
        Initialize();

        // Create item
        CreateAssembledItem(
          Item1, Item1."Assembly Policy"::"Assemble-to-Order", Item1."Costing Method"::FIFO, LibraryRandom.RandDec(100, 2),
          LibraryRandom.RandInt(3), LibraryRandom.RandInt(3), LibraryRandom.RandInt(3),
          LibraryRandom.RandDec(100, 2));
        FindComponent(Item1, BOMComponent, 1);
        CreateAssembledItem(
          Item2, Item2."Assembly Policy"::"Assemble-to-Order", Item2."Costing Method"::FIFO, LibraryRandom.RandDec(100, 2),
          LibraryRandom.RandInt(3), LibraryRandom.RandInt(3), LibraryRandom.RandInt(3),
          LibraryRandom.RandDec(100, 2));
        AddComponentToAssemblyList(
          BOMComponent, BOMComponent.Type::Item, BOMComponent."No.", Item2."No.", '',
          BOMComponent."Resource Usage Type"::Direct, BOMComponent."Unit of Measure Code", LibraryRandom.RandDec(100, 2));
        // Create ATOs
        CreateAndPostATO(
          Item1, LibraryRandom.RandDec(100, 2) + 1, CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate()), 100);
        CreateAndPostATO(
          Item2, LibraryRandom.RandDec(100, 2) + 1, CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate()), 100);

        // Exercise - all items from asm list
        Item1.SetFilter("No.", BOMComponent."No.");
        RunReportAndProcessEntries(TempATOSalesBuffer, Item1, ShowDetails);

        // Validate
        ValidateReportLines(TempATOSalesBuffer, Item1, ShowDetails);
    end;

    [Test]
    [HandlerFunctions('AssembleToOrderSalesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ATOOutsideDateFilter()
    var
        TempATOSalesBuffer: Record "ATO Sales Buffer" temporary;
        BOMComponent: Record "BOM Component";
        Item1: Record Item;
    begin
        Initialize();

        // Create item
        CreateAssembledItem(
          Item1, Item1."Assembly Policy"::"Assemble-to-Order", Item1."Costing Method"::FIFO, LibraryRandom.RandDec(100, 2),
          LibraryRandom.RandInt(3), LibraryRandom.RandInt(3), LibraryRandom.RandInt(3),
          LibraryRandom.RandDec(100, 2));
        FindComponent(Item1, BOMComponent, 1);

        // Create ATOs
        CreateAndPostATO(
          Item1, LibraryRandom.RandDec(100, 2) + 1, CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate()), 100);

        // Exercise - only BOM component and outside the date range
        Item1.SetFilter("No.", BOMComponent."No.");
        Item1.SetFilter("Date Filter", '%1..', CalcDate('<+1Y>', WorkDate()));
        ValidateNoFileCreated(TempATOSalesBuffer, Item1);
    end;

    [Test]
    [HandlerFunctions('AssembleToOrderSalesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ATOOneEntryOutsideDateFilter()
    var
        TempATOSalesBuffer: Record "ATO Sales Buffer" temporary;
        BOMComponent: Record "BOM Component";
        Item1: Record Item;
        DueDate: Date;
    begin
        Initialize();

        // Create item
        CreateAssembledItem(
          Item1, Item1."Assembly Policy"::"Assemble-to-Order", Item1."Costing Method"::FIFO, LibraryRandom.RandDec(100, 2),
          LibraryRandom.RandInt(3), LibraryRandom.RandInt(3), LibraryRandom.RandInt(3),
          LibraryRandom.RandDec(100, 2));
        FindComponent(Item1, BOMComponent, 1);
        DueDate := CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate());

        // Create ATOs
        CreateAndPostATO(Item1, LibraryRandom.RandDec(100, 2) + 1, DueDate, 100);
        CreateAndPostATO(
          Item1, LibraryRandom.RandDec(100, 2) + 1, CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', DueDate), 100);

        // Exercise - only BOM component and one entry outside the date range
        Item1.SetFilter("No.", BOMComponent."No.");
        Item1.SetFilter("Date Filter", '%1..%2', DueDate, DueDate);
        RunReportAndProcessEntries(TempATOSalesBuffer, Item1, true);

        // Validate
        ValidateReportLines(TempATOSalesBuffer, Item1, true);
    end;

    [Test]
    [HandlerFunctions('AssembleToOrderSalesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ATONoComponents()
    var
        TempATOSalesBuffer: Record "ATO Sales Buffer" temporary;
        Item: Record Item;
    begin
        Initialize();

        // Create item
        CreateAssembledItem(
          Item, Item."Assembly Policy"::"Assemble-to-Order", Item."Costing Method"::FIFO, LibraryRandom.RandDec(100, 2),
          0, LibraryRandom.RandInt(3), LibraryRandom.RandInt(3), LibraryRandom.RandDec(100, 2));

        // Create ATOs
        CreateAndPostATO(
          Item, LibraryRandom.RandDec(100, 2) + 1, CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate()), 100);

        // Exercise - all items from asm list
        Item.SetFilter("No.", GetItemsFromAsmListAsFilter(Item));
        ValidateNoFileCreated(TempATOSalesBuffer, Item);
    end;

    [Test]
    [HandlerFunctions('AssembleToOrderSalesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CostZero()
    var
        TempATOSalesBuffer: Record "ATO Sales Buffer" temporary;
        Item1: Record Item;
    begin
        Initialize();

        // Create item - Cost of components is 0
        CreateAssembledItem(Item1, Item1."Assembly Policy"::"Assemble-to-Order", Item1."Costing Method"::FIFO, 0,
          LibraryRandom.RandInt(3), LibraryRandom.RandInt(3), LibraryRandom.RandInt(3),
          LibraryRandom.RandDec(100, 2));

        // Create ATOs
        CreateAndPostATO(
          Item1, LibraryRandom.RandDec(100, 2) + 1, CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate()), 100);

        // Exercise - only BOM component and one entry outside the date range
        Item1.SetFilter("No.", GetItemsFromAsmListAsFilter(Item1));
        RunReportAndProcessEntries(TempATOSalesBuffer, Item1, true);

        // Validate
        ValidateReportLines(TempATOSalesBuffer, Item1, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,AssembleToOrderSalesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Undo()
    var
        Item: Record Item;
        SalesShipmentLine: Record "Sales Shipment Line";
        TempATOSalesBuffer: Record "ATO Sales Buffer" temporary;
    begin
        Initialize();

        // Create ATO and post ATS
        CreateAssembledItem(
          Item, Item."Assembly Policy"::"Assemble-to-Order", Item."Costing Method"::FIFO, LibraryRandom.RandDec(100, 2),
          LibraryRandom.RandInt(3), LibraryRandom.RandInt(3), LibraryRandom.RandInt(3),
          LibraryRandom.RandDec(100, 2));
        CreateAndPostATO(
          Item, LibraryRandom.RandDec(100, 2) + 1, CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate()), 100);

        // Undo shipment
        SalesShipmentLine.SetRange("No.", Item."No.");
        SalesShipmentLine.FindFirst();
        LibraryVariableStorage.Enqueue(UndoShipmMsg); // Msg to the confirm handler
        LibrarySales.UndoSalesShipmentLine(SalesShipmentLine); // Calls the confirm handler

        // Exercise - verify no printout
        Item.SetFilter("No.", GetItemsFromAsmListAsFilter(Item));
        ValidateNoFileCreated(TempATOSalesBuffer, Item);
    end;

    [Test]
    [HandlerFunctions('PostedSalesDocumentLinesHandler,AssembleToOrderSalesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ATOAndSalesReturn()
    var
        Item: Record Item;
        BOMComponent: Record "BOM Component";
        TempATOSalesBuffer: Record "ATO Sales Buffer" temporary;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        Initialize();

        // Create ATO item
        CreateAssembledItem(
          Item, Item."Assembly Policy"::"Assemble-to-Order", Item."Costing Method"::FIFO, LibraryRandom.RandDec(100, 2),
          LibraryRandom.RandInt(3), LibraryRandom.RandInt(3), LibraryRandom.RandInt(3),
          LibraryRandom.RandDec(100, 2));
        FindComponent(Item, BOMComponent, 1);

        // Sell component
        CreateSalesOrder(SalesHeader, BOMComponent."No.", '', LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2) + 1,
          CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate()), '');
        FindSalesLine(SalesHeader, SalesLine);
        LibraryVariableStorage.Enqueue(LibrarySales.PostSalesDocument(SalesHeader, true, false)); // Posted Document No. is used in page handler.

        // Create Sales Return for the sale
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", SalesHeader."Sell-to Customer No.");
        GetPostedDocumentLines(SalesHeader."No."); // Calls PostedSalesDocumentLinesHandler
        UpdateSalesLine(SalesHeader, SalesLine."VAT Identifier");
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // Exercise - component only - verify no printout
        Item.SetFilter("No.", BOMComponent."No.");
        ValidateNoFileCreated(TempATOSalesBuffer, Item);

        // Create ATO
        CreateAndPostATO(
          Item, LibraryRandom.RandDec(100, 2) + 1, CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate()), 100);

        // Exercise - all asm "tree"
        Item.SetFilter("No.", GetItemsFromAsmListAsFilter(Item));
        RunReportAndProcessEntries(TempATOSalesBuffer, Item, true);

        // Validate
        ValidateReportLines(TempATOSalesBuffer, Item, true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesDocumentLinesHandler(var PostedSalesDocumentLines: TestPage "Posted Sales Document Lines")
    var
        DocumentNo: Variant;
        DocumentType: Option "Posted Shipments","Posted Invoices","Posted Return Receipts","Posted Cr. Memos";
    begin
        LibraryVariableStorage.Dequeue(DocumentNo);
        PostedSalesDocumentLines.PostedShipmentsBtn.SetValue(Format(DocumentType::"Posted Shipments"));
        PostedSalesDocumentLines.PostedShpts.FILTER.SetFilter("Document No.", DocumentNo);
        PostedSalesDocumentLines.OK().Invoke();
    end;

    local procedure GetPostedDocumentLines(No: Code[20])
    var
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        SalesReturnOrder.OpenEdit();
        SalesReturnOrder.FILTER.SetFilter("No.", No);
        SalesReturnOrder.GetPostedDocumentLinesToReverse.Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var reply: Boolean)
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);  // Dequeue variable.
        Assert.IsTrue(StrPos(Question, ExpectedMessage) > 0, Question);
        reply := true;
    end;

    [Test]
    [HandlerFunctions('AssembleToOrderSalesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ATOSalesInvoice()
    var
        TempATOSalesBuffer: Record "ATO Sales Buffer" temporary;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesShptLine: Record "Sales Shipment Line";
        SalesGetShipment: Codeunit "Sales-Get Shipment";
    begin
        Initialize();

        // Create ATO item
        CreateAssembledItem(
          Item, Item."Assembly Policy"::"Assemble-to-Order", Item."Costing Method"::FIFO, LibraryRandom.RandDec(100, 2),
          LibraryRandom.RandInt(3), LibraryRandom.RandInt(3), LibraryRandom.RandInt(3),
          LibraryRandom.RandDec(100, 2));

        // ATO order
        CreateAndPostATO(
          Item, LibraryRandom.RandDec(100, 2) + 1, CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate()), 100);

        // Create Sales invoice and post it
        SalesShptLine.SetRange("No.", Item."No.");
        SalesShptLine.FindFirst();
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, SalesShptLine."Sell-to Customer No.");
        SalesHeader.Validate("No. Series", SalesHeader."Posting No. Series"); // Required for IT
        SalesHeader.Modify(true);
        SalesGetShipment.SetSalesHeader(SalesHeader);

        SalesGetShipment.CreateInvLines(SalesShptLine);
        LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // Exercise
        Item.SetFilter("No.", GetItemsFromAsmListAsFilter(Item));
        RunReportAndProcessEntries(TempATOSalesBuffer, Item, true);

        // Validate
        ValidateReportLines(TempATOSalesBuffer, Item, true);
    end;

    [Test]
    [HandlerFunctions('AssembleToOrderSalesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure LevelATO()
    var
        TempATOSalesBuffer: Record "ATO Sales Buffer" temporary;
        Item1: Record Item;
        Item: Record Item;
        BOMComponent: Record "BOM Component";
    begin
        Initialize();

        // Create item - Cost of components is 0
        CreateAssembledItem(Item1, Item1."Assembly Policy"::"Assemble-to-Order", Item1."Costing Method"::FIFO, 0,
          LibraryRandom.RandInt(3), LibraryRandom.RandInt(3), LibraryRandom.RandInt(3),
          LibraryRandom.RandDec(100, 2));
        FindComponent(Item1, BOMComponent, 1);
        Item.Get(BOMComponent."No.");
        CreateAssemblyList(
          Item, Item."Costing Method"::FIFO, LibraryRandom.RandDec(100, 2), LibraryRandom.RandInt(3),
          LibraryRandom.RandInt(3), LibraryRandom.RandInt(3),
          LibraryRandom.RandDec(100, 2));

        // Create ATOs
        CreateAndPostATO(
          Item, LibraryRandom.RandDec(100, 2) + 1, CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate()), 100);

        // Exercise - all items in the asm "trees"
        Item1.SetFilter("No.", GetItemsFromAsmListAsFilter(Item1) + '|' + GetItemsFromAsmListAsFilter(Item));
        RunReportAndProcessEntries(TempATOSalesBuffer, Item1, true);

        // Validate
        ValidateReportLines(TempATOSalesBuffer, Item1, true);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AssembleToOrderSalesRequestPageHandler(var AssembleToOrderSales: TestRequestPage "Assemble to Order - Sales")
    var
        ShowGraphAs: Variant;
        ShowAsmInfo: Variant;
    begin
        LibraryVariableStorage.Dequeue(ShowGraphAs);
        LibraryVariableStorage.Dequeue(ShowAsmInfo);

        AssembleToOrderSales.ShowChartAs.SetValue(ShowGraphAs);
        AssembleToOrderSales.ShowAsmDetails.SetValue(ShowAsmInfo);
        AssembleToOrderSales.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

