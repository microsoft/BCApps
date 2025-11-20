// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Test;

using Microsoft.Assembly.Setup;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;
using System.Environment.Configuration;
using System.TestLibraries.Utilities;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;
using Microsoft.Assembly.Document;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Inventory.BOM;
using Microsoft.Sales.Document;
using Microsoft.Assembly.History;
using Microsoft.Sales.History;
using Microsoft.Foundation.UOM;
using Microsoft.Projects.Resources.Resource;

codeunit 137311 "SCM Kitting - Printout Reports"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Assembly] [Reports] [SCM]
    end;

    var
        AssemblySetup: Record "Assembly Setup";
        ItemATO: Record Item;
        ItemATS: Record Item;
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        Location: Record Location;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryPostInventoryToGL: Codeunit "Library - Post Inventory to GL";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryDimension: Codeunit "Library - Dimension";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPlanning: Codeunit "Library - Planning";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryResource: Codeunit "Library - Resource";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        WorkDate2: Date;
        MsgUpdateDim: Label 'Do you want to update the Dimensions on the lines?';
        NothingToPostTxt: Label 'There is nothing to post to the general ledger.';
        UpdateDimensionOnLine: Label 'You may have changed a dimension.\\Do you want to update the lines?';

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Kitting - Printout Reports");
        // Initialize setup.
        ClearLastError();
        LibraryVariableStorage.Clear();
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Kitting - Printout Reports");

        // Setup Demonstration data.
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        WorkDate2 := LibraryPlanning.SetSafetyWorkDate(); // to avoid Due Date Before Work Date message.
        LibraryCosting.AdjustCostItemEntries('', '');
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate2, '');

        LibraryAssembly.UpdateAssemblySetup(AssemblySetup, '', AssemblySetup."Copy Component Dimensions from"::"Item/Resource Card",
          LibraryUtility.GetGlobalNoSeriesCode());

        SetupLocation(Location);
        LibraryInventory.ItemJournalSetup(ItemJournalTemplate, ItemJournalBatch);

        LibraryAssembly.SetupAssemblyItem(
          ItemATS, ItemATS."Costing Method"::Standard, ItemATS."Costing Method"::Standard, ItemATS."Replenishment System"::Assembly,
          Location.Code, false,
          LibraryRandom.RandIntInRange(1, 3),
          LibraryRandom.RandIntInRange(1, 3),
          LibraryRandom.RandIntInRange(1, 3),
          LibraryRandom.RandIntInRange(1, 10));
        CreateAndSetVariantsOnAsmListForItem(ItemATS);

        LibraryAssembly.SetupAssemblyItem(
          ItemATO, ItemATO."Costing Method"::Standard, ItemATO."Costing Method"::Standard, ItemATO."Replenishment System"::Assembly,
          Location.Code, false,
          LibraryRandom.RandIntInRange(1, 3),
          LibraryRandom.RandIntInRange(1, 3),
          LibraryRandom.RandIntInRange(1, 3),
          LibraryRandom.RandIntInRange(1, 10));
        CreateAndSetVariantsOnAsmListForItem(ItemATO);

        ItemATO.Validate("Assembly Policy", ItemATO."Assembly Policy"::"Assemble-to-Order");
        ItemATO.Modify(true);



        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Kitting - Printout Reports");
    end;

    local procedure SetupLocation(var Location: Record Location)
    var
        WarehouseEmployee: Record "Warehouse Employee";
        Bin: Record Bin;
    begin
        Clear(Location);
        Location.Init();
        LibraryWarehouse.CreateLocation(Location);

        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // Skip validate trigger for bin mandatory to improve performance.
        Location."Bin Mandatory" := true;
        Location.Modify(true);

        LibraryWarehouse.CreateBin(Bin, Location.Code, 'ToBin', '', '');
        Location.Validate("To-Assembly Bin Code", Bin.Code);
        LibraryWarehouse.CreateBin(Bin, Location.Code, 'FromBin', '', '');
        Location.Validate("From-Assembly Bin Code", Bin.Code);

        Location.Modify(true);
    end;

    [Normal]
    local procedure SetShortcutDimensions(AssemblyHeader: Record "Assembly Header"; Num: Integer)
    var
        DimensionValue: Record "Dimension Value";
        DimensionSetEntry: Record "Dimension Set Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
        ShortcutDimensionCode: Code[20];
        DimensionSetID: Integer;
    begin
        GeneralLedgerSetup.Get();
        if Num = 1 then
            ShortcutDimensionCode := GeneralLedgerSetup."Shortcut Dimension 1 Code"
        else
            ShortcutDimensionCode := GeneralLedgerSetup."Shortcut Dimension 2 Code";

        DimensionSetID := AssemblyHeader."Dimension Set ID";
        LibraryDimension.FindDimensionValue(DimensionValue, ShortcutDimensionCode);
        DimensionSetID := LibraryDimension.CreateDimSet(DimensionSetID, ShortcutDimensionCode, DimensionValue.Code);
        AssemblyHeader.Validate("Dimension Set ID", DimensionSetID);
        AssemblyHeader.Modify(true);

        LibraryDimension.FindDimensionSetEntry(DimensionSetEntry, AssemblyHeader."Dimension Set ID");
        DimensionSetEntry.SetRange("Dimension Code", ShortcutDimensionCode);
        DimensionSetEntry.FindFirst();

        if Num = 1 then
            AssemblyHeader.Validate(
              "Shortcut Dimension 1 Code",
              LibraryDimension.FindDifferentDimensionValue(DimensionSetEntry."Dimension Code", DimensionSetEntry."Dimension Value Code"))
        else
            AssemblyHeader.Validate(
              "Shortcut Dimension 2 Code",
              LibraryDimension.FindDifferentDimensionValue(DimensionSetEntry."Dimension Code", DimensionSetEntry."Dimension Value Code"));
        AssemblyHeader.Modify(true);
    end;

    local procedure CreateAndSetVariantsOnAsmListForItem(Item: Record Item)
    var
        BOMComponent: Record "BOM Component";
        ItemVariant: Record "Item Variant";
    begin
        BOMComponent.SetRange("Parent Item No.", Item."No.");
        BOMComponent.SetRange(Type, BOMComponent.Type::Item);
        if BOMComponent.FindSet() then
            repeat
                LibraryInventory.CreateItemVariant(ItemVariant, BOMComponent."No.");
                BOMComponent.Validate("Variant Code", ItemVariant.Code);
                BOMComponent.Modify(true);
            until BOMComponent.Next() = 0;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure DimensionsChangeConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(Question, MsgUpdateDim) > 0, StrSubstNo('Wrong question: %1', Question));

        Reply := true;
    end;

    [ConfirmHandler]
    procedure ConfirmUpdateDimensionChange(Question: Text[1024]; var Reply: Boolean)
    begin
        if (Question = MsgUpdateDim) or (Question = UpdateDimensionOnLine) then
            Reply := true;
    end;

    [Normal]
    local procedure MakeLongDescriptionOnLine(AssemblyHeader: Record "Assembly Header"; var TempAssemblyLine: Record "Assembly Line" temporary)
    var
        AssemblyLine: Record "Assembly Line";
    begin
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.FindFirst();
        AssemblyLine.Validate(Description, PadStr(LibraryUtility.GenerateGUID(), 49, '.') + '!');
        AssemblyLine.Modify(true);

        TempAssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        TempAssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        TempAssemblyLine.SetRange("No.", AssemblyLine."No.");
        TempAssemblyLine.FindFirst();
        TempAssemblyLine.Validate(Description, AssemblyLine.Description);
        TempAssemblyLine.Modify(true);
    end;

    local procedure ClearJournal(ItemJournalTemplate: Record "Item Journal Template"; ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        Clear(ItemJournalLine);
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalTemplate.Name);
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.DeleteAll();
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo1: Code[20]; ItemNo2: Code[20]; LocationCode: Code[10]; var SalesLine1: Record "Sales Line"; var SalesLine2: Record "Sales Line"; SalesQty: Integer)
    var
        ShipmentDate: Date;
    begin
        ShipmentDate := CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate2);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesHeader.Validate("Location Code", LocationCode);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLineWithShipmentDate(SalesLine1, SalesHeader, SalesLine1.Type::Item, ItemNo1, ShipmentDate, SalesQty);
        if ItemNo2 <> '' then
            LibrarySales.CreateSalesLineWithShipmentDate(SalesLine2, SalesHeader, SalesLine2.Type::Item, ItemNo2, ShipmentDate, SalesQty);
    end;

    [Normal]
    local procedure AddInventoryNonDirectLocation(ItemNo: Code[20]; LocationCode: Code[10]; Qty: Integer; BinCode: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ClearJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Qty);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    [Normal]
    local procedure VerifyPrintoutPostedAO(AssemblyHeaderNo: Code[20]; SalesOrderNo: Code[20]; ShowDimensions: Boolean; Reversed: Boolean)
    var
        PostedAssemblyHeader: Record "Posted Assembly Header";
    begin
        PostedAssemblyHeader.Reset();
        PostedAssemblyHeader.SetRange("Order No.", AssemblyHeaderNo);
        Assert.IsTrue(PostedAssemblyHeader.FindFirst(), 'Assembly order is not posted');

        Commit();
        LibraryVariableStorage.Enqueue(0);
        LibraryVariableStorage.Enqueue(ShowDimensions);
        REPORT.Run(REPORT::"Posted Assembly Order", true, false, PostedAssemblyHeader);

        LibraryReportDataset.LoadDataSetFile();
        VerifyPrintoutPostedAOHeader(PostedAssemblyHeader, SalesOrderNo, ShowDimensions, Reversed);
        VerifyPrintoutPostedAOLines(PostedAssemblyHeader, ShowDimensions);
    end;

    [Normal]
    local procedure VerifyPrintoutPostedAOHeader(PostedAssemblyHeader: Record "Posted Assembly Header"; SalesOrderNo: Code[20]; ShowDimensions: Boolean; Reversed: Boolean)
    var
        PostedSalesShipmentHeader: Record "Sales Shipment Header";
        DimensionSetEntry: Record "Dimension Set Entry";
        UnitOfMeasure: Record "Unit of Measure";
        ExpDimensionLine: array[3] of Text;
        i: Integer;
    begin
        LibraryReportDataset.SetRange('No_PostedAssemblyHeader', PostedAssemblyHeader."No.");
        LibraryReportDataset.GetNextRow();

        if SalesOrderNo <> '' then begin
            PostedSalesShipmentHeader.SetRange("Order No.", SalesOrderNo);
            PostedSalesShipmentHeader.FindFirst();
            LibraryReportDataset.AssertCurrentRowValueEquals('LinkedSalesShipment', PostedSalesShipmentHeader."No.");
        end;

        LibraryReportDataset.AssertCurrentRowValueEquals('OrderNo_PostedAssemblyHeader', PostedAssemblyHeader."Order No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('PostingDate_PostedAssemblyHeader', Format(PostedAssemblyHeader."Posting Date"));
        LibraryReportDataset.AssertCurrentRowValueEquals('ItemNo_PostedAssemblyHeader', PostedAssemblyHeader."Item No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Description_PostedAssemblyHeader', PostedAssemblyHeader.Description);
        LibraryReportDataset.AssertCurrentRowValueEquals('AssembledQuantity_PostedAssemblyHeader', PostedAssemblyHeader.Quantity);
        UnitOfMeasure.Get(PostedAssemblyHeader."Unit of Measure Code");
        LibraryReportDataset.AssertCurrentRowValueEquals('UnitOfMeasure_PostedAssemblyHeader', UnitOfMeasure.Description);
        LibraryReportDataset.AssertCurrentRowValueEquals('Reversed_PostedAssemblyHeader', Format(Reversed));

        LibraryDimension.FindDimensionSetEntry(DimensionSetEntry, PostedAssemblyHeader."Dimension Set ID");
        GetDimensionString(DimensionSetEntry, 75, ExpDimensionLine);

        if ShowDimensions then
            for i := 1 to 3 do
                if ExpDimensionLine[i] <> '' then begin
                    LibraryReportDataset.AssertCurrentRowValueEquals('DimText', ExpDimensionLine[i]);
                    LibraryReportDataset.GetNextRow();
                end;
    end;

    [Normal]
    local procedure VerifyPrintoutPostedAOLines(PostedAssemblyHeader: Record "Posted Assembly Header"; ShowDimensions: Boolean)
    var
        PostedAssemblyLine: Record "Posted Assembly Line";
        DimensionSetEntry: Record "Dimension Set Entry";
        UnitOfMeasure: Record "Unit of Measure";
        DimValue: Variant;
        ExpDimensionLine: array[3] of Text;
        ActDimensionLine: Text;
        i: Integer;
    begin
        PostedAssemblyLine.SetRange("Document No.", PostedAssemblyHeader."No.");
        PostedAssemblyLine.SetRange(Type, PostedAssemblyLine.Type::Item, PostedAssemblyLine.Type::Resource);
        PostedAssemblyLine.FindSet();

        repeat
            LibraryReportDataset.SetRange('LineNo_PostedAssemblyLine', PostedAssemblyLine."Line No.");
            LibraryDimension.FindDimensionSetEntry(DimensionSetEntry, PostedAssemblyLine."Dimension Set ID");
            GetDimensionString(DimensionSetEntry, 75, ExpDimensionLine);

            while LibraryReportDataset.GetNextRow() do begin
                LibraryReportDataset.AssertCurrentRowValueEquals('Type_PostedAssemblyLine', Format(PostedAssemblyLine.Type));
                LibraryReportDataset.AssertCurrentRowValueEquals('No_PostedAssemblyLine', PostedAssemblyLine."No.");
                LibraryReportDataset.AssertCurrentRowValueEquals('Description_PostedAssemblyLine', PostedAssemblyLine.Description);
                LibraryReportDataset.AssertCurrentRowValueEquals('Quantity_PostedAssemblyLine', PostedAssemblyLine.Quantity);
                LibraryReportDataset.AssertCurrentRowValueEquals('Quantityper_PostedAssemblyLine', PostedAssemblyLine."Quantity per");
                UnitOfMeasure.Get(PostedAssemblyLine."Unit of Measure Code"); // the report prints the UOM description
                LibraryReportDataset.AssertCurrentRowValueEquals('UnitOfMeasureDescription_PostedAssemblyLine', UnitOfMeasure.Description);

                if ShowDimensions and (ExpDimensionLine[1] <> '') then begin
                    LibraryReportDataset.FindCurrentRowValue('DimText2', DimValue);
                    ActDimensionLine += Format(DimValue) + '; ';
                end;
            end;

            if ShowDimensions and (ExpDimensionLine[1] <> '') then
                for i := 1 to 3 do
                    if ExpDimensionLine[i] <> '' then
                        Assert.IsTrue(StrPos(DelChr(ActDimensionLine, '=', '; '), DelChr(ExpDimensionLine[i], '=', '; ')) > 0, 'Wrong dim.')
                    else
                        Assert.AreEqual('', DelChr(ActDimensionLine, '=', '; '), 'Dimension should not be printed.');

        until PostedAssemblyLine.Next() = 0;
    end;

    [Normal]
    local procedure GetDimensionString(var DimensionSetEntry: Record "Dimension Set Entry"; MaxLen: Integer; var DimText: array[3] of Text)
    var
        DimTxt: Text;
        Delimeter: Text;
        i: Integer;
    begin
        Clear(DimText);
        if DimensionSetEntry.IsEmpty() then
            exit;

        i := 1;
        repeat
            DimTxt := StrSubstNo('%1 - %2', DimensionSetEntry."Dimension Code", DimensionSetEntry."Dimension Value Code");
            if StrLen(DimText[i] + DimTxt) > MaxLen then begin
                i += 1;
                Delimeter := '';
            end;
            DimText[i] += Delimeter + DimTxt;
            Delimeter := '; ';
        until DimensionSetEntry.Next() = 0;
    end;

    [Normal]
    local procedure CreateATS(Item: Record Item; PostingDate: Date): Code[20]
    var
        AssemblyHeader: Record "Assembly Header";
        TempAssemblyLine: Record "Assembly Line" temporary;
    begin
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate2, Item."No.", Location.Code, LibraryRandom.RandDec(10, 2), '');

        // Set dimensions
        SetShortcutDimensions(AssemblyHeader, 1);
        SetShortcutDimensions(AssemblyHeader, 2);

        // Prepare posting
        AssemblyHeader.Get(AssemblyHeader."Document Type", AssemblyHeader."No.");
        LibraryAssembly.PrepareOrderPosting(AssemblyHeader, TempAssemblyLine, 100, 100, true, WorkDate2);
        MakeLongDescriptionOnLine(AssemblyHeader, TempAssemblyLine);
        AssemblyHeader.Validate("Posting Date", PostingDate);
        AssemblyHeader.Modify(true);
        LibraryAssembly.AddCompInventory(AssemblyHeader, WorkDate2, 0);

        exit(AssemblyHeader."No.");
    end;

    [Normal]
    local procedure PostATS(AssemblyHeaderNo: Code[20])
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, AssemblyHeaderNo);

        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Normal]
    local procedure CreateATO(Item: Record Item; PostingDate: Date; var SalesHeader: Record "Sales Header"): Code[20]
    var
        AssemblyHeader: Record "Assembly Header";
        SalesLine: Record "Sales Line";
        QtyFromStock: Integer;
    begin
        CreateSalesOrder(SalesHeader, Item."No.", '', Location.Code, SalesLine, SalesLine, LibraryRandom.RandIntInRange(5, 10));
        Assert.IsTrue(SalesLine.AsmToOrderExists(AssemblyHeader), 'There is no asm order');

        // Prepare posting
        QtyFromStock := 1;
        SalesLine.Validate("Qty. to Assemble to Order", SalesLine."Qty. to Assemble to Order" - QtyFromStock);
        SalesLine.Modify(true);

        AssemblyHeader.Get(AssemblyHeader."Document Type", AssemblyHeader."No.");
        AssemblyHeader.Validate("Posting Date", PostingDate);
        AssemblyHeader.Modify(true);

        AddInventoryNonDirectLocation(Item."No.", Location.Code, QtyFromStock, Location."From-Assembly Bin Code");
        LibraryAssembly.AddCompInventory(AssemblyHeader, WorkDate2, 0);

        exit(AssemblyHeader."No.");
    end;

    [Normal]
    local procedure PostATO(SalesHeader: Record "Sales Header")
    begin
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmUpdateDimensionChange,PostedAssemblyOrderRequestPageHandler,NothingPostedMessageHandler')]
    [Scope('OnPrem')]
    procedure PrintoutPostedATS()
    var
        AssemblyHeaderNo: Code[20];
        SalesOrderNo: Code[20];
    begin
        // Setup.
        Initialize();

        AssemblyHeaderNo := CreateATS(ItemATS, WorkDate2);
        PostATS(AssemblyHeaderNo);
        SalesOrderNo := '';

        VerifyPrintoutPostedAO(AssemblyHeaderNo, SalesOrderNo, false, false);
    end;

    [Test]
    [HandlerFunctions('PostedAssemblyOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PrintoutPostedATO()
    var
        SalesHeader: Record "Sales Header";
        AssemblyHeaderNo: Code[20];
        SalesOrderNo: Code[20];
    begin
        // Setup.
        Initialize();

        AssemblyHeaderNo := CreateATO(ItemATO, WorkDate2, SalesHeader);
        PostATO(SalesHeader);
        SalesOrderNo := SalesHeader."No.";

        VerifyPrintoutPostedAO(AssemblyHeaderNo, SalesOrderNo, false, false);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('ConfirmUpdateDimensionChange,PostedAssemblyOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PrintoutPostedATSShowDimensions()
    var
        AssemblyHeaderNo: Code[20];
        SalesOrderNo: Code[20];
    begin
        // Setup.
        Initialize();

        AssemblyHeaderNo := CreateATS(ItemATS, WorkDate2);
        PostATS(AssemblyHeaderNo);
        SalesOrderNo := '';

        VerifyPrintoutPostedAO(AssemblyHeaderNo, SalesOrderNo, true, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmUpdateDimensionChange,PostedAssemblyOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PrintoutPostedATSUndo()
    var
        PostedAssemblyHeader: Record "Posted Assembly Header";
        AssemblyHeaderNo: Code[20];
        SalesOrderNo: Code[20];
    begin
        // Setup.
        Initialize();

        AssemblyHeaderNo := CreateATS(ItemATS, WorkDate2 + 1);
        PostATS(AssemblyHeaderNo);

        PostedAssemblyHeader.Reset();
        PostedAssemblyHeader.SetRange("Order No.", AssemblyHeaderNo);
        Assert.IsTrue(PostedAssemblyHeader.FindFirst(), 'Assembly order is not posted');

        LibraryAssembly.UndoPostedAssembly(PostedAssemblyHeader, true, '');
        SalesOrderNo := '';

        VerifyPrintoutPostedAO(AssemblyHeaderNo, SalesOrderNo, false, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmUpdateDimensionChange,PostedAssemblyOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PrintoutPostedATSLongOrders()
    var
        TestItemATS: Record Item;
        AssemblyHeaderNo: Code[20];
        SalesOrderNo: Code[20];
    begin
        // Setup.
        Initialize();

        LibraryAssembly.SetupAssemblyItem(
          TestItemATS, ItemATS."Costing Method"::Standard, ItemATS."Costing Method"::Standard, ItemATS."Replenishment System"::Assembly,
          Location.Code, false,
          LibraryRandom.RandIntInRange(2, 5),
          LibraryRandom.RandIntInRange(1, 3),
          LibraryRandom.RandIntInRange(1, 3),
          LibraryRandom.RandIntInRange(1, 10));

        AssemblyHeaderNo := CreateATS(TestItemATS, WorkDate2 + 1);
        PostATS(AssemblyHeaderNo);
        SalesOrderNo := '';

        VerifyPrintoutPostedAO(AssemblyHeaderNo, SalesOrderNo, false, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmUpdateDimensionChange,AssemblyOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PrintoutAssemblyComponentsATS()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyHeaderNo: Code[20];
    begin
        // Setup.
        Initialize();

        AssemblyHeaderNo := CreateATS(ItemATS, WorkDate2);
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, AssemblyHeaderNo);
        AssemblyHeader.SetRange("Document Type", AssemblyHeader."Document Type"::Order);
        AssemblyHeader.SetRange("No.", AssemblyHeaderNo);

        REPORT.Run(REPORT::"Assembly Order", true, false, AssemblyHeader);

        LibraryReportDataset.LoadDataSetFile();
        VerifyComponentsReportAOHeader(AssemblyHeader);
        VerifyComponentsReportAOLines(AssemblyHeader);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('AssemblyOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PrintoutAssemblyComponentsATO()
    var
        AssemblyHeader: Record "Assembly Header";
        SalesHeader: Record "Sales Header";
        AssemblyHeaderNo: Code[20];
    begin
        // Setup.
        Initialize();

        AssemblyHeaderNo := CreateATO(ItemATO, WorkDate2, SalesHeader);
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, AssemblyHeaderNo);

        REPORT.Run(REPORT::"Assembly Order", true, false, AssemblyHeader);

        LibraryReportDataset.LoadDataSetFile();
        VerifyComponentsReportAOHeader(AssemblyHeader);
        VerifyComponentsReportAOLines(AssemblyHeader);
    end;

    [Test]
    [HandlerFunctions('ConfirmUpdateDimensionChange,AssemblyOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PrintoutAssemblyComponentsLongOrders()
    var
        AssemblyHeader: Record "Assembly Header";
        TestItemATS: Record Item;
        AssemblyHeaderNo: Code[20];
    begin
        // Setup.
        Initialize();

        LibraryAssembly.SetupAssemblyItem(
          TestItemATS, ItemATS."Costing Method"::Standard, ItemATS."Costing Method"::Standard, ItemATS."Replenishment System"::Assembly,
          Location.Code, false,
          LibraryRandom.RandIntInRange(2, 5),
          LibraryRandom.RandIntInRange(1, 3),
          LibraryRandom.RandIntInRange(1, 3),
          LibraryRandom.RandIntInRange(1, 10));

        AssemblyHeaderNo := CreateATS(TestItemATS, WorkDate2 + 1);

        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, AssemblyHeaderNo);
        REPORT.Run(REPORT::"Assembly Order", true, false, AssemblyHeader);

        LibraryReportDataset.LoadDataSetFile();
        VerifyComponentsReportAOHeader(AssemblyHeader);
        VerifyComponentsReportAOLines(AssemblyHeader);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('PickInstructionRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PrintoutSalesOrderPickListATO()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
    begin
        // Setup.
        Initialize();

        CreateATO(ItemATO, WorkDate2, SalesHeader);

        // Add non ATO lines to the Sales Header
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange("No.", SalesHeader."No.");

        // VERIFY: Run report and verify
        Commit();
        REPORT.Run(REPORT::"Pick Instruction", true, false, SalesHeader);

        LibraryReportDataset.LoadDataSetFile();
        VerifySalesPickListReportHeader(SalesHeader);
        VerifySalesPickListReportLines(SalesHeader);
    end;

    [Test]
    [HandlerFunctions('PickInstructionRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PrintoutSalesPickListLongOrders()
    var
        SalesHeader: Record "Sales Header";
        TestItemATO: Record Item;
        "Count": Integer;
    begin
        // Setup.
        Initialize();

        LibraryAssembly.SetupAssemblyItem(
          TestItemATO, ItemATO."Costing Method"::Standard, ItemATO."Costing Method"::Standard, ItemATO."Replenishment System"::Assembly,
          Location.Code, false,
          LibraryRandom.RandIntInRange(3, 5),
          LibraryRandom.RandIntInRange(1, 3),
          LibraryRandom.RandIntInRange(1, 3),
          LibraryRandom.RandIntInRange(1, 10));

        TestItemATO.Validate("Assembly Policy", TestItemATO."Assembly Policy"::"Assemble-to-Order");
        TestItemATO.Modify(true);
        CreateATO(TestItemATO, WorkDate2 + 1, SalesHeader);

        for Count := 1 to 2 do begin
            Clear(TestItemATO);
            LibraryAssembly.SetupAssemblyItem(
              TestItemATO, ItemATO."Costing Method"::Standard, ItemATO."Costing Method"::Standard, ItemATO."Replenishment System"::Assembly,
              Location.Code, false,
              LibraryRandom.RandInt(3),
              LibraryRandom.RandInt(3),
              LibraryRandom.RandInt(3),
              LibraryRandom.RandInt(3));
            TestItemATO.Validate("Assembly Policy", TestItemATO."Assembly Policy"::"Assemble-to-Order");
            TestItemATO.Modify(true);
            AddATOToSalesOrder(TestItemATO, WorkDate2 + 1, SalesHeader);
        end;

        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange("No.", SalesHeader."No.");

        Commit();
        REPORT.Run(REPORT::"Pick Instruction", true, false, SalesHeader);
        LibraryReportDataset.LoadDataSetFile();
        VerifySalesPickListReportHeader(SalesHeader);
        VerifySalesPickListReportLines(SalesHeader);
    end;

    [Test]
    [HandlerFunctions('PickInstructionRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PrintoutSalesOrderPickListWithNoATO()
    var
        Item: Record Item;
        Resource: Record Resource;
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
    begin
        // Setup.
        Initialize();

        // CREATE: Sales order with all line types and verify report
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        Clear(SalesLine);
        Clear(Item);
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 0);

        LibraryResource.FindResource(Resource);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Resource, Resource."No.", LibraryRandom.RandInt(10));
        Clear(SalesLine);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", '', LibraryRandom.RandInt(10));
        Clear(SalesLine);

        // VERIFY: Run report and verify only sales line of item header are displayed.
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange("No.", SalesHeader."No.");

        Commit();
        REPORT.Run(REPORT::"Pick Instruction", true, false, SalesHeader);
        LibraryReportDataset.LoadDataSetFile();

        VerifySalesPickListReportHeader(SalesHeader);
        VerifySalesPickListReportLines(SalesHeader);
    end;

    [Test]
    [HandlerFunctions('PickInstructionRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PrintoutSalesOrderPickListLastLineATO()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        TestItemATO: Record Item;
    begin
        // Setup.
        Initialize();

        // SETUP: Create the ATO item and a regular item
        LibraryInventory.CreateItem(Item);

        LibraryAssembly.SetupAssemblyItem(
          TestItemATO, ItemATO."Costing Method"::Standard, ItemATO."Costing Method"::Standard, ItemATO."Replenishment System"::Assembly,
          Location.Code, false,
          LibraryRandom.RandIntInRange(1, 10),
          LibraryRandom.RandIntInRange(1, 3),
          LibraryRandom.RandIntInRange(1, 3),
          LibraryRandom.RandIntInRange(1, 10));

        TestItemATO.Validate("Assembly Policy", TestItemATO."Assembly Policy"::"Assemble-to-Order");
        TestItemATO.Modify(true);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesHeader.Validate("Location Code", Location.Code);
        SalesHeader.Modify(true);

        // EXECUTE: Add item sales line followed by an ATO item
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        AddATOToSalesOrder(TestItemATO, WorkDate2 + 1, SalesHeader);

        Clear(SalesLine);

        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetRange("No.", TestItemATO."No.");
        SalesLine.FindFirst();

        SalesLine.Validate(Quantity, 0);
        SalesLine.Modify(true);

        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange("No.", SalesHeader."No.");

        // VERIFY: Run report and verify
        Commit();
        REPORT.Run(REPORT::"Pick Instruction", true, false, SalesHeader);
        LibraryReportDataset.LoadDataSetFile();
        VerifySalesPickListReportHeader(SalesHeader);
        VerifySalesPickListReportLines(SalesHeader);
    end;

    [Normal]
    local procedure AddATOToSalesOrder(Item: Record Item; PostingDate: Date; var SalesHeader: Record "Sales Header"): Code[20]
    var
        AssemblyHeader: Record "Assembly Header";
        SalesLine: Record "Sales Line";
        QtyFromStock: Integer;
        ShipmentDate: Date;
    begin
        ShipmentDate := CalcDate('<+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate2);
        LibrarySales.CreateSalesLineWithShipmentDate(
          SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", ShipmentDate, LibraryRandom.RandIntInRange(5, 10));
        Assert.IsTrue(SalesLine.AsmToOrderExists(AssemblyHeader), 'There is no asm order');

        // Prepare posting
        QtyFromStock := 1;
        SalesLine.Validate("Qty. to Assemble to Order", SalesLine."Qty. to Assemble to Order" - QtyFromStock);
        SalesLine.Modify(true);

        AssemblyHeader.Get(AssemblyHeader."Document Type", AssemblyHeader."No.");
        AssemblyHeader.Validate("Posting Date", PostingDate);
        AssemblyHeader.Modify(true);

        AddInventoryNonDirectLocation(Item."No.", Location.Code, QtyFromStock, Location."From-Assembly Bin Code");
        LibraryAssembly.AddCompInventory(AssemblyHeader, WorkDate2, 0);

        exit(AssemblyHeader."No.");
    end;

    [Normal]
    local procedure VerifyComponentsReportAOHeader(var AssemblyHeader: Record "Assembly Header")
    var
        ATOLink: Record "Assemble-to-Order Link";
    begin
        LibraryReportDataset.SetRange('No_AssemblyHeader', AssemblyHeader."No.");
        LibraryReportDataset.GetNextRow();

        if ATOLink.Get(AssemblyHeader."Document Type", AssemblyHeader."No.") then
            LibraryReportDataset.AssertCurrentRowValueEquals('SalesDocNo', ATOLink."Document No.");

        LibraryReportDataset.AssertCurrentRowValueEquals('ItemNo_AssemblyHeader', AssemblyHeader."Item No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Description_AssemblyHeader', AssemblyHeader.Description);
        LibraryReportDataset.AssertCurrentRowValueEquals('Quantity_AssemblyHeader', AssemblyHeader.Quantity);
        LibraryReportDataset.AssertCurrentRowValueEquals('QuantityToAssemble_AssemblyHeader', AssemblyHeader."Quantity to Assemble");
        LibraryReportDataset.AssertCurrentRowValueEquals('UnitOfMeasureCode_AssemblyHeader', AssemblyHeader."Unit of Measure Code");
        LibraryReportDataset.AssertCurrentRowValueEquals('DueDate_AssemblyHeader', Format(AssemblyHeader."Due Date"));
        LibraryReportDataset.AssertCurrentRowValueEquals('StartingDate_AssemblyHeader', Format(AssemblyHeader."Starting Date"));
        LibraryReportDataset.AssertCurrentRowValueEquals('EndingDate_AssemblyHeader', Format(AssemblyHeader."Ending Date"));
        LibraryReportDataset.AssertCurrentRowValueEquals('LocationCode_AssemblyHeader', AssemblyHeader."Location Code");

        if AssemblyHeader."Bin Code" <> '' then
            LibraryReportDataset.AssertCurrentRowValueEquals('BinCode_AssemblyHeader', AssemblyHeader."Bin Code");
    end;

    [Normal]
    local procedure VerifyComponentsReportAOLines(var AssemblyHeader: Record "Assembly Header")
    var
        AssemblyLine: Record "Assembly Line";
    begin
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.SetRange(Type, AssemblyLine.Type::Item, AssemblyLine.Type::Resource);
        AssemblyLine.FindSet();

        repeat
            LibraryReportDataset.SetRange('No_AssemblyLine', AssemblyLine."No.");
            LibraryReportDataset.GetNextRow();
            LibraryReportDataset.AssertCurrentRowValueEquals('Description_AssemblyLine', AssemblyLine.Description);
            LibraryReportDataset.AssertCurrentRowValueEquals('QuantityPer_AssemblyLine', AssemblyLine."Quantity per");
            LibraryReportDataset.AssertCurrentRowValueEquals('Quantity_AssemblyLine', AssemblyLine.Quantity);
            LibraryReportDataset.AssertCurrentRowValueEquals('UnitOfMeasureCode_AssemblyLine', AssemblyLine."Unit of Measure Code");
            LibraryReportDataset.AssertCurrentRowValueEquals('LocationCode_AssemblyLine', AssemblyLine."Location Code");
            LibraryReportDataset.AssertCurrentRowValueEquals('BinCode_AssemblyLine', AssemblyLine."Bin Code");
            LibraryReportDataset.AssertCurrentRowValueEquals('VariantCode_AssemblyLine', AssemblyLine."Variant Code");
            LibraryReportDataset.AssertCurrentRowValueEquals('QuantityToConsume_AssemblyLine', AssemblyLine."Quantity to Consume");
            LibraryReportDataset.AssertCurrentRowValueEquals('DueDate_AssemblyLine', Format(AssemblyLine."Due Date"));
        until AssemblyLine.Next() = 0;
    end;

    [Normal]
    local procedure VerifySalesPickListReportHeader(var SalesHeader: Record "Sales Header")
    begin
        LibraryReportDataset.SetRange('No_SalesHeader', SalesHeader."No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('CustomerNo_SalesHeader', SalesHeader."Sell-to Customer No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('CustomerName_SalesHeader', SalesHeader."Sell-to Customer Name");
    end;

    [Normal]
    local procedure VerifySalesPickListReportLines(var SalesHeader: Record "Sales Header")
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        SalesLine: Record "Sales Line";
        AssembleToOrderLink: Record "Assemble-to-Order Link";
        UnitOfMeasure: Record "Unit of Measure";
        AsmExists: Boolean;
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.FindSet();

        repeat
            LibraryReportDataset.SetRange('LineNo_SalesLine', SalesLine."Line No.");
            LibraryReportDataset.GetNextRow();

            LibraryReportDataset.AssertCurrentRowValueEquals('ItemNo_SalesLine', SalesLine."No.");
            LibraryReportDataset.AssertCurrentRowValueEquals('Description_SalesLine', SalesLine.Description);
            LibraryReportDataset.AssertCurrentRowValueEquals('VariantCode_SalesLine', SalesLine."Variant Code");
            LibraryReportDataset.AssertCurrentRowValueEquals('LocationCode_SalesLine', SalesLine."Location Code");
            LibraryReportDataset.AssertCurrentRowValueEquals('BinCode_SalesLine', SalesLine."Bin Code");
            LibraryReportDataset.AssertCurrentRowValueEquals('ShipmentDate_SalesLine', Format(SalesLine."Shipment Date"));
            LibraryReportDataset.AssertCurrentRowValueEquals('Quantity_SalesLine', SalesLine.Quantity);
            LibraryReportDataset.AssertCurrentRowValueEquals('UnitOfMeasure_SalesLine', SalesLine."Unit of Measure");
            LibraryReportDataset.AssertCurrentRowValueEquals('QuantityToShip_SalesLine', SalesLine."Qty. to Ship");
            LibraryReportDataset.AssertCurrentRowValueEquals('QuantityShipped_SalesLine', SalesLine."Quantity Shipped");
            LibraryReportDataset.AssertCurrentRowValueEquals('QtyToAsm', SalesLine."Qty. to Assemble to Order");

            AsmExists := false;
            AssembleToOrderLink.Reset();
            AssembleToOrderLink.SetCurrentKey(Type, "Document Type", "Document No.", "Document Line No.");
            AssembleToOrderLink.SetRange(Type, AssembleToOrderLink.Type::Sale);
            AssembleToOrderLink.SetRange("Document Type", SalesLine."Document Type");
            AssembleToOrderLink.SetRange("Document No.", SalesLine."Document No.");
            AssembleToOrderLink.SetRange("Document Line No.", SalesLine."Line No.");
            AsmExists := AssembleToOrderLink.FindFirst() and AssemblyHeader.Get(AssembleToOrderLink."Assembly Document Type", AssembleToOrderLink."Assembly Document No.");
            if AsmExists then begin
                // verify the lines
                AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
                AssemblyLine.SetRange(Type, AssemblyLine.Type::Item);
                AssemblyLine.FindSet();

                repeat
                    LibraryReportDataset.SetRange('No_AssemblyLine', AssemblyLine."No.");
                    LibraryReportDataset.GetNextRow();

                    LibraryReportDataset.AssertCurrentRowValueEquals('Description_AssemblyLine', AssemblyLine.Description);
                    LibraryReportDataset.AssertCurrentRowValueEquals('QuantityPer_AssemblyLine', AssemblyLine."Quantity per");
                    LibraryReportDataset.AssertCurrentRowValueEquals('Quantity_AssemblyLine', AssemblyLine.Quantity);
                    UnitOfMeasure.Get(AssemblyLine."Unit of Measure Code");
                    LibraryReportDataset.AssertCurrentRowValueEquals('UnitOfMeasure_AssemblyLine', UnitOfMeasure.Description);
                    LibraryReportDataset.AssertCurrentRowValueEquals('LocationCode_AssemblyLine', AssemblyLine."Location Code");
                    LibraryReportDataset.AssertCurrentRowValueEquals('BinCode_AssemblyLine', AssemblyLine."Bin Code");
                    LibraryReportDataset.AssertCurrentRowValueEquals('VariantCode_AssemblyLine', AssemblyLine."Variant Code");
                    LibraryReportDataset.AssertCurrentRowValueEquals('QuantityToConsume_AssemblyLine', AssemblyLine."Quantity to Consume");
                until AssemblyLine.Next() = 0;
            end;

        until SalesLine.Next() = 0;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PostedAssemblyOrderRequestPageHandler(var PostedAssemblyOrder: TestRequestPage "Posted Assembly Order")
    var
        NoOfCopies: Variant;
        ShowDimensions: Variant;
    begin
        LibraryVariableStorage.Dequeue(NoOfCopies);
        LibraryVariableStorage.Dequeue(ShowDimensions);

        PostedAssemblyOrder."No. of copies".SetValue(NoOfCopies);
        PostedAssemblyOrder."Show Dimensions".SetValue(ShowDimensions);
        PostedAssemblyOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AssemblyOrderRequestPageHandler(var AssemblyOrder: TestRequestPage "Assembly Order")
    begin
        AssemblyOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PickInstructionRequestPageHandler(var PickInstruction: TestRequestPage "Pick Instruction")
    begin
        PickInstruction.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure NothingPostedMessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(NothingToPostTxt, Message);
    end;
}

