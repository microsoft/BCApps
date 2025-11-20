// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Test;

using System.Environment.Configuration;
using Microsoft.Inventory.Item;
using Microsoft.Assembly.Document;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.BOM;
using Microsoft.Assembly.Setup;
using Microsoft.Warehouse.Structure;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Journal;
using Microsoft.Purchases.Document;
using Microsoft.Inventory.Setup;

codeunit 137912 "SCM Assembly Availability II"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Assembly] [SCM]
        Initialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPlanning: Codeunit "Library - Planning";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        TestMethodName: Text[30];
        Step: Integer;
        SubStep: Integer;
        SupplyDate1: Date;
        SupplyQty1: Decimal;
        SupplyDate2: Date;
        SupplyQty2: Decimal;
        DemandDate: Date;
        DemandQty: Decimal;
        OldDueDate: Date;
        NewDueDate: Date;
        OldEndDate: Date;
        NewEndDate: Date;
        OldStartDate: Date;
        NewStartDate: Date;
        NewLineDueDate: Date;
        Initialized: Boolean;

        FirstNumber: Label '137912-001';
        CnfmUpdateLocationOnLines: Label 'Do you want to update the Location Code on the lines?';
        CnfmChangeOfItemNo: Label 'Changing Item No. will change all the lines. Do you want to change the Item No.';
        CnfmRefreshLines: Label 'This assembly order may have customized lines. Are you sure that you want to reset the lines according to the assembly BOM?';
        TestMethodVSTF238977: Label 'TestMethod: VSTF238977';
        TestVSTF257960A: Label 'VSTF257960A';
        CnfmStartingDateChanged: Label 'You have modified the Starting Date from %1 to %2. Do you want to update the Ending Date from %3 to %4 and the Due Date from %5 to %6?';
        CnfmEndingDateChanged: Label 'You have modified the Ending Date from %1 to %2. Do you want to update the Due Date from %3 to %4?';
        ErrEndDateBeforeStartDate: Label 'Ending Date %1 is before Starting Date %2.';
        ErrDueDateBeforeEndDate: Label 'Due Date %1 is before Ending Date %2.';
        ErrLineDueDateBeforeStartDate: Label 'Due Date cannot be later than %1 because the Starting Date is set to %2.';
        MsgDueDateBeforeWDFromLine: Label 'Due Date %1 is before work date %2.';
        MsgDueDateBeforeWDFromHeader: Label 'Due Date %1 is before work date %2 in one or more of the assembly lines.';
        TestVSTF257960B: Label 'VSTF257960B';
        TestDataConsistencyCheck: Label 'DataConsistencyCheck';
        TestVSTF266309: Label 'VSTF266309';
        TestMsgAvailConfirm: Label 'Availability warning at step = %1.';

    [Normal]
    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Assembly Availability II");
        LibrarySetupStorage.Restore();
        if Initialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Assembly Availability II");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibrarySetupStorage.SaveInventorySetup();

        Initialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Assembly Availability II");
    end;

    [Test]
    [HandlerFunctions('UpdateLocationOnLines,DueDateBeforeWorkDateMsgHandler')]
    [Scope('OnPrem')]
    procedure ChangeLocCheckDueDateNoLineUpd()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        AsmHeader: Record "Assembly Header";
        AsmLine: Record "Assembly Line";
        Location: Record Location;
        OldDueDate: Date;
        OldLineLocation: Code[10];
        VariantCode: Code[10];
        LeadTimeText: Text[2];
    begin
        Initialize();
        TestMethodName := 'ChangeLocCheckDueDateNoLineUpd';
        MockAsmItem(ParentItem, ChildItem, 1);
        Step := 1;
        MockAsmOrder(AsmHeader, ParentItem, 1, WorkDate(), '');
        AsmHeader.Validate("Due Date", GetDate('1M', AsmHeader."Due Date"));
        AsmHeader.Modify(true);
        OldDueDate := AsmHeader."Due Date";
        AsmLine.Get(AsmHeader."Document Type", AsmHeader."No.", 10000); // get first line
        OldLineLocation := AsmLine."Location Code";

        // create a location and then an SKU with lead time = 1M
        LeadTimeText := '5D';
        MockSKUWithLeadTime(ParentItem, Location, LeadTimeText, VariantCode);

        // update location on asm header, but DO NOT UPDATE on lines.
        Step := 2;
        AsmHeader.Validate("Location Code", Location.Code);
        AsmHeader.Modify(true);
        AsmHeader.Validate("Variant Code", VariantCode);
        AsmHeader.Modify(true);
        Assert.AreEqual(GetDate('-' + LeadTimeText, OldDueDate), AsmHeader."Starting Date", 'Starting dates are not equal.');
        Assert.AreEqual(GetDate('-' + LeadTimeText, OldDueDate), AsmHeader."Ending Date", 'Ending dates are not equal.');
        AsmLine.Get(AsmHeader."Document Type", AsmHeader."No.", 10000); // get first line
        Assert.AreEqual(OldLineLocation, AsmLine."Location Code", 'Line location is not updated.');
        Assert.AreEqual(AsmHeader."Starting Date", AsmLine."Due Date", 'Line Due dates are not equal.');
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('UpdateLocationOnLines,DueDateBeforeWorkDateMsgHandler')]
    [Scope('OnPrem')]
    procedure ChangeLocCheckDueDateLineUpd()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        AsmHeader: Record "Assembly Header";
        AsmLine: Record "Assembly Line";
        Location: Record Location;
        OldDueDate: Date;
        VariantCode: Code[10];
        LeadTimeText: Text[2];
    begin
        Initialize();
        TestMethodName := 'ChangeLocCheckDueDateLineUpd';
        MockAsmItem(ParentItem, ChildItem, 1);
        Step := 1;
        MockAsmOrder(AsmHeader, ParentItem, 1, WorkDate(), '');
        AsmHeader.Validate("Due Date", GetDate('1M', AsmHeader."Due Date"));
        AsmHeader.Modify(true);
        OldDueDate := AsmHeader."Due Date";
        AsmLine.Get(AsmHeader."Document Type", AsmHeader."No.", 10000); // get first line

        // create a location and then an SKU with lead time = 1M
        LeadTimeText := '5D';
        MockSKUWithLeadTime(ParentItem, Location, LeadTimeText, VariantCode);

        // update location on asm header, but DO UPDATE on lines.
        Step := 2;
        AsmHeader.Validate("Location Code", Location.Code);
        AsmHeader.Modify(true);
        AsmHeader.Validate("Variant Code", VariantCode);
        AsmHeader.Modify(true);
        Assert.AreEqual(GetDate('-' + LeadTimeText, OldDueDate), AsmHeader."Starting Date", 'Starting dates are not equal.');
        Assert.AreEqual(GetDate('-' + LeadTimeText, OldDueDate), AsmHeader."Ending Date", 'Ending dates are not equal.');
        AsmLine.Get(AsmHeader."Document Type", AsmHeader."No.", 10000); // get first line
        Assert.AreEqual(AsmHeader."Location Code", AsmLine."Location Code", 'Line location is updated.');
        Assert.AreEqual(AsmHeader."Starting Date", AsmLine."Due Date", 'Line Due dates are not equal.');
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('UpdateLocationOnLines,DueDateBeforeWorkDateMsgHandler')]
    [Scope('OnPrem')]
    procedure ValidateLocAfterSKUNewDueDate()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        AsmHeader: Record "Assembly Header";
        AsmLine: Record "Assembly Line";
        Location: Record Location;
        StockkeepingUnit: Record "Stockkeeping Unit";
        OldDueDate: Date;
        VariantCode: Code[10];
        LeadTimeText: Text[30];
        LeadTime: DateFormula;
    begin
        Initialize();
        TestMethodName := 'ValidateLocAfterSKUNewDueDate';
        MockAsmItem(ParentItem, ChildItem, 1);
        Step := 1;
        MockAsmOrder(AsmHeader, ParentItem, 1, WorkDate(), '');
        AsmHeader.Validate("Due Date", GetDate('1M', AsmHeader."Due Date"));
        AsmHeader.Modify(true);

        // set a variant and location SKU with no lead time.
        Step := 2;
        MockSKUWithLeadTime(ParentItem, Location, '0D', VariantCode);
        AsmHeader.Validate("Location Code", Location.Code);
        AsmHeader.Modify(true);
        AsmHeader.Validate("Variant Code", VariantCode);
        AsmHeader.Modify(true);

        OldDueDate := AsmHeader."Due Date";
        AsmLine.Get(AsmHeader."Document Type", AsmHeader."No.", 10000); // get first line

        // set SKU for parent with lead time = 5D.
        StockkeepingUnit.Get(Location.Code, ParentItem."No.", AsmHeader."Variant Code");
        LeadTimeText := '5D';
        Evaluate(LeadTime, '<' + LeadTimeText + '>');
        StockkeepingUnit.Validate("Safety Lead Time", LeadTime);
        StockkeepingUnit.Modify(true);

        // update location on asm header, but DO UPDATE on lines.
        Step := 3;
        AsmHeader.Validate("Location Code", Location.Code); // expect no update warning on the validate - dont handle in ConfirmHandler
        AsmHeader.Modify(true);
        Assert.AreEqual(GetDate('-' + LeadTimeText, OldDueDate), AsmHeader."Starting Date", 'Starting dates are not equal.');
        Assert.AreEqual(GetDate('-' + LeadTimeText, OldDueDate), AsmHeader."Ending Date", 'Ending dates are not equal.');
        AsmLine.Get(AsmHeader."Document Type", AsmHeader."No.", 10000); // get first line
        Assert.AreEqual(AsmHeader."Location Code", AsmLine."Location Code", 'Line location is updated.');
        Assert.AreEqual(AsmHeader."Starting Date", AsmLine."Due Date", 'Line Due dates are not equal.');
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('UpdateLocationOnLines,DueDateBeforeWorkDateMsgHandler')]
    [Scope('OnPrem')]
    procedure ChangeVariantNoLocUpdConfirm()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        AsmHeader: Record "Assembly Header";
        AsmLine: Record "Assembly Line";
        LocationHeader: Record Location;
        LocationLine: Record Location;
        VariantCode: Code[10];
    begin
        Initialize();
        TestMethodName := 'ChangeVariantNoLocUpdConfirm';
        MockAsmItem(ParentItem, ChildItem, 1);
        Step := 1;
        MockAsmOrder(AsmHeader, ParentItem, 1, WorkDate(), '');

        // set a variant and location SKU with no lead time.
        Step := 2;
        MockSKUWithLeadTime(ParentItem, LocationHeader, '0D', VariantCode);
        AsmHeader.Validate("Location Code", LocationHeader.Code);
        AsmHeader.Modify(true);

        // set line with different location code
        AsmLine.Get(AsmHeader."Document Type", AsmHeader."No.", 10000); // get first line
        MockLocation(LocationLine);
        AsmLine.Validate("Location Code", LocationLine.Code);
        AsmLine.Modify(true);

        // change variant code on header
        Step := 3;
        AsmHeader.Validate("Variant Code", VariantCode); // expect no update warning on location - dont handle in ConfirmHandler
        AsmHeader.Modify(true);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('UpdateLocationOnLines,DueDateBeforeWorkDateMsgHandler')]
    [Scope('OnPrem')]
    procedure DataConsistencyCheck()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        AsmHeader: Record "Assembly Header";
        Location: Record Location;
    begin
        Initialize();
        TestMethodName := TestDataConsistencyCheck;
        MockAsmItem(ParentItem, ChildItem, 1);
        Step := 1;
        MockAsmOrder(AsmHeader, ParentItem, 1, WorkDate(), '');

        // change location code on the header
        Step := 2;
        MockLocation(Location);
        // make the availability confirmation appear, and there change lines
        AsmHeader.Validate("Location Code", Location.Code);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('ConfirmChangeOfItem,DueDateBeforeWorkDateMsgHandler')]
    [Scope('OnPrem')]
    procedure ValidateItemNoToParentItem()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        ParentParentItem: Record Item;
        AsmHeader: Record "Assembly Header";
        AsmLine: Record "Assembly Line";
        BOMComponent: Record "BOM Component";
    begin
        Initialize();
        TestMethodName := 'ValidateItemNoToParentItem';
        MockAsmItem(ParentItem, ChildItem, 1);
        AddItemToInventory(ChildItem, '', '', 1);
        Step := 1;
        MockAsmOrder(AsmHeader, ParentItem, 1, WorkDate(), '');

        // create parent of parent item
        MockItem(ParentParentItem);
        ParentParentItem.Validate("Replenishment System", ParentParentItem."Replenishment System"::Assembly);
        ParentParentItem.Modify(true);
        LibraryInventory.CreateBOMComponent(BOMComponent, ParentParentItem."No.", BOMComponent.Type::Item,
          ParentItem."No.", 1, ParentItem."Base Unit of Measure");

        // change asm header from parent item to parent of parent item
        Step := 2;
        AsmHeader.Validate("Item No.", ParentParentItem."No."); // should show availability warning
        AsmHeader.Modify(true);

        // verify lines have been changed.
        AsmLine.Get(AsmHeader."Document Type", AsmHeader."No.", 10000); // get first line
        Assert.AreEqual(ParentItem."No.", AsmLine."No.", 'Asm line should have parent item.');
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('DueDateBeforeWorkDateMsgHandler')]
    [Scope('OnPrem')]
    procedure VSTF238472()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        AsmHeader: Record "Assembly Header";
    begin
        Initialize();
        TestMethodName := 'VSTF238472';
        // Create an "assembled item" with one comp (Qty per =2)
        MockAsmItem(ParentItem, ChildItem, 2);
        Step := 1;
        // Create a new assembly order for the new item. Qty = 2
        MockAsmOrder(AsmHeader, ParentItem, 2, WorkDate(), ''); // avail warning should open
        Step := 2;
        // Select Unit of measure field on the assembly order header and without changing something, press tab.
        AsmHeader.Validate("Unit of Measure Code"); // should not open avail warning
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('DueDateBeforeWorkDateMsgHandler')]
    [Scope('OnPrem')]
    procedure VSTF231811()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        AsmHeader: Record "Assembly Header";
        AsmLine: Record "Assembly Line";
    begin
        Initialize();
        TestMethodName := 'VSTF231811';
        // Create assembled item with one comp (qty per = 2).
        MockAsmItem(ParentItem, ChildItem, 2);
        // Add 2 PCS of component to inventory
        AddItemToInventory(ChildItem, '', '', 2);
        // Create assembly order. Qty = 1
        MockAsmOrder(AsmHeader, ParentItem, 1, WorkDate(), '');
        AsmLine.Get(AsmHeader."Document Type", AsmHeader."No.", 10000); // get first line
        // Change the Qty per on the line to 3.
        AsmLine.Validate("Quantity per", 3);
        Assert.IsTrue(AsmLine."Avail. Warning", 'Avail. warning should be Yes');
        // Change the Qty per on the line back to 2 (or 1).
        AsmLine.Validate("Quantity per", 2);
        Assert.IsFalse(AsmLine."Avail. Warning", 'Avail. warning should be No');
        AsmLine.Validate("Quantity per", 1);
        Assert.IsFalse(AsmLine."Avail. Warning", 'Avail. warning should be No');
    end;

    [Test]
    [HandlerFunctions('ConfirmRefreshLines,DueDateBeforeWorkDateMsgHandler')]
    [Scope('OnPrem')]
    procedure VSTF255987()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        AsmHeader: Record "Assembly Header";
        AsmLine: Record "Assembly Line";
    begin
        Initialize();
        TestMethodName := 'VSTF255987';
        // Create assembled item with one comp (qty per = 1).
        MockAsmItem(ParentItem, ChildItem, 1);
        Step := 1;
        // Create assembly order. Qty = 1
        MockAsmOrder(AsmHeader, ParentItem, 1, WorkDate(), '');
        AsmLine.Get(AsmHeader."Document Type", AsmHeader."No.", 10000); // get first line
        Step := 2;
        // Change the Qty per on the line to 3.
        AsmLine.Validate("Quantity per", 3); // accept avail. warning by handler
        AsmLine.Modify(true);
        Step := 3;
        // Refresh Asm header.
        AsmHeader.RefreshBOM(); // say No to confirm - expect no avail. warning
        // verify line has NOT been changed.
        AsmLine.Get(AsmHeader."Document Type", AsmHeader."No.", 10000); // get first line
        Assert.AreEqual(3, AsmLine."Quantity per", 'Quantity per should be the same as set above. Assert at Step = ' + Format(Step));
        Step := 4;
        // Refresh Asm header.
        AsmHeader.RefreshBOM(); // say Yes to confirm - expect avail. warning
        // verify line has been changed.
        AsmLine.Get(AsmHeader."Document Type", AsmHeader."No.", 10000); // get first line
        Assert.AreEqual(1, AsmLine."Quantity per", 'Quantity per should be the same as Assembly BOM. Assert at Step = ' + Format(Step));
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('DateConfirmationHandler')]
    [Scope('OnPrem')]
    procedure VSTF258428()
    var
        ParentItem: Record Item;
        Location: Record Location;
        StockkeepingUnit: Record "Stockkeeping Unit";
        AsmHeader: Record "Assembly Header";
        DTFormula: DateFormula;
        NewStartDate2: Date;
        NewEndDate2: Date;
        NewDueDate2: Date;
    begin
        Initialize();
        TestMethodName := 'VSTF258428';
        Step := 0;

        // Create item KIT with Replenishment System = Assembly
        MockItem(ParentItem);
        ParentItem.Validate("Replenishment System", ParentItem."Replenishment System"::Assembly);
        ParentItem.Modify(true);

        // Create SKU for KIT @ BLUE with Safety Lead Time = 3D and Lead Time Calculation =4D
        MockLocation(Location);
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, Location.Code, ParentItem."No.", '');
        Evaluate(DTFormula, '3D');
        StockkeepingUnit.Validate("Safety Lead Time", DTFormula);
        Evaluate(DTFormula, '4D');
        StockkeepingUnit.Validate("Lead Time Calculation", DTFormula);
        StockkeepingUnit.Modify(true);

        // Change manufacturing Default Safety Lead Time = 2D
        LibraryPlanning.SetDefaultSafetyLeadTime('2D');

        // Create asm order for KIT with due date = WorkDate(), Location=Blank.
        MockAsmOrder(AsmHeader, ParentItem, 1, WorkDate(), '');
        Assert.AreEqual(WorkDate(), AsmHeader."Due Date", 'Due Date = WorkDate');
        Evaluate(DTFormula, '-2D');
        Assert.AreEqual(CalcDate(DTFormula, WorkDate()), AsmHeader."Ending Date", 'Ending Date = WorkDate() - 2D');
        Assert.AreEqual(AsmHeader."Ending Date", AsmHeader."Starting Date", 'Starting Date = Ending Date');

        // Change location code on header = BLUE
        AsmHeader.Validate("Location Code", Location.Code);
        Assert.AreEqual(WorkDate(), AsmHeader."Due Date", 'Due Date = WorkDate');
        Evaluate(DTFormula, '-3D');
        Assert.AreEqual(
          CalcDate(DTFormula, AsmHeader."Due Date"), AsmHeader."Ending Date", 'Ending Date = Due date - 3D (SKU safety lead time)');
        Evaluate(DTFormula, '-4D');
        Assert.AreEqual(
          CalcDate(DTFormula, AsmHeader."Ending Date"), AsmHeader."Starting Date",
          'Starting Date = Ending Date - 4D (SKU Lead Time Calculation)');

        // Extension based on repro of Bug 257960
        // Change due date on header = WorkDate() + 1M
        Step := 1;
        Evaluate(DTFormula, '+1M');
        AsmHeader.Validate("Due Date", CalcDate(DTFormula, WorkDate()));
        Evaluate(DTFormula, '-3D');
        Assert.AreEqual(
          CalcDate(DTFormula, AsmHeader."Due Date"), AsmHeader."Ending Date", 'Ending Date = Due date - 3D (SKU safety lead time)');
        Evaluate(DTFormula, '-4D');
        Assert.AreEqual(
          CalcDate(DTFormula, AsmHeader."Ending Date"), AsmHeader."Starting Date",
          'Starting Date = Ending Date - 4D (SKU Lead Time Calculation)');
        // Change starting date to WorkDate() - 2D
        Step := 2;
        Evaluate(DTFormula, '-2D');
        NewStartDate2 := CalcDate(DTFormula, WorkDate());
        Evaluate(DTFormula, '+4D');
        NewEndDate2 := CalcDate(DTFormula, NewStartDate2);
        Evaluate(DTFormula, '+3D');
        NewDueDate2 := CalcDate(DTFormula, NewEndDate2);
        SetGlobalDates(AsmHeader, NewDueDate2, NewEndDate2, NewStartDate2, NewStartDate2);
        AsmHeader.Validate("Starting Date", NewStartDate);
        Assert.AreEqual(NewEndDate, AsmHeader."Ending Date", 'Ending Date = Starting date + 4D (SKU Lead Time Calculation)');
        Assert.AreEqual(NewDueDate, AsmHeader."Due Date", 'Due Date = Ending date + 3D (SKU safety lead time)');
        // Change Due date to WORKDATE and then Change Ending Date to WORKDATE.
        Step := 3;
        AsmHeader.Validate("Due Date", WorkDate());
        Step := 4;
        NewEndDate2 := WorkDate();
        Evaluate(DTFormula, '-4D');
        NewStartDate2 := CalcDate(DTFormula, NewEndDate2);
        Evaluate(DTFormula, '+3D');
        NewDueDate2 := CalcDate(DTFormula, NewEndDate2);
        SetGlobalDates(AsmHeader, NewDueDate2, NewEndDate2, NewStartDate2, NewStartDate2);
        AsmHeader.Validate("Ending Date", NewEndDate);
        Assert.AreEqual(NewStartDate, AsmHeader."Starting Date", 'Starting Date = Ending date - 4D (SKU Lead Time Calculation)');
        Assert.AreEqual(NewDueDate, AsmHeader."Due Date", 'Due Date = Ending date + 3D (SKU safety lead time)');
    end;

    [Test]
    [HandlerFunctions('VSTF238977ConfirmHandler')]
    [Scope('OnPrem')]
    procedure VSTF238977()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        AsmHeader: Record "Assembly Header";
        AsmLine: Record "Assembly Line";
    begin
        Initialize();
        TestMethodName := TestMethodVSTF238977;
        // Create assembled item with one comp (qty per = 1).
        MockAsmItem(ParentItem, ChildItem, 1);
        // Make purchase order for 10 PCS with expected rcpt date = WorkDate() + 1M
        MockPurchOrder(ChildItem."No.", 10, '', CalcDate('<+1M>', WorkDate()));
        // Create assembly order. Qty = 1
        Step := 1;
        MockAsmOrder(AsmHeader, ParentItem, 1, LibraryPlanning.SetSafetyWorkDate(), ''); // to avoid the message about due date being before work date
        Step := 2;
        // Set due date on the line to 1W before the expected rcpt date of the purchase
        AsmHeader.Validate("Starting Date", CalcDate('<+1M-1W>', WorkDate()));
        AsmLine.Get(AsmHeader."Document Type", AsmHeader."No.", 10000); // get the only line
        Assert.AreEqual(true, AsmLine."Avail. Warning", '');
        // Set due date on the line to 1W after the expected rcpt date of the purchase
        AsmHeader.Validate("Starting Date", CalcDate('<+1M+1W>', WorkDate()));
        AsmLine.Get(AsmHeader."Document Type", AsmHeader."No.", 10000); // get the only line
        Assert.AreEqual(false, AsmLine."Avail. Warning", '');
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure VSTF238977ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [Test]
    [HandlerFunctions('DateConfirmationHandler,DueDateBeforeWorkDateMsgHandler')]
    [Scope('OnPrem')]
    procedure VSTF257960A()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        BOMComponent: Record "BOM Component";
        Location: Record Location;
        StockkeepingUnit: Record "Stockkeeping Unit";
        AsmHeader: Record "Assembly Header";
        AsmLine: Record "Assembly Line";
        SafetyLeadTime: DateFormula;
        LeadTimeCalc: DateFormula;
        LeadTimeOffset: DateFormula;
        OldWorkDate: Date;
        DTFormula: DateFormula;
        ExpDueDate: Date;
        ExpEndDate: Date;
        ExpStartDate: Date;
        ExpLineDueDate: Date;
        SavedDueDate: Date;
        SavedEndDate: Date;
        SavedStartDate: Date;
        SavedLineDueDate: Date;
    begin
        Initialize();
        TestMethodName := TestVSTF257960A;
        Step := 0;
        OldWorkDate := WorkDate();
        WorkDate := CalcDate('<CY-1Y+7D>', WorkDate());

        // SETUP
        Evaluate(SafetyLeadTime, '<1D>');
        Evaluate(LeadTimeCalc, '<4D>');
        Evaluate(LeadTimeOffset, '<1D>');
        // Create item KIT with Replenishment System = Assembly with components and lead time offset
        MockAsmItem(ParentItem, ChildItem, 1);
        BOMComponent.Get(ParentItem."No.", 10000);
        BOMComponent.Validate("Lead-Time Offset", LeadTimeOffset);
        BOMComponent.Modify(true);
        // Make enough inventory for component.
        MockLocation(Location);
        AddItemToInventory(ChildItem, Location.Code, '', 10);
        // Create SKU for KIT @ BLUE with Safety Lead Time and Lead Time Calculation
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, Location.Code, ParentItem."No.", '');
        StockkeepingUnit.Validate("Safety Lead Time", SafetyLeadTime);
        StockkeepingUnit.Validate("Lead Time Calculation", LeadTimeCalc);
        StockkeepingUnit.Modify(true);
        // Create asm order for KIT with due date = WorkDate() + 8D
        Step := 1;
        Evaluate(DTFormula, '<+8D>');
        ExpDueDate := CalcDate(DTFormula, WorkDate());
        MockAsmOrder(AsmHeader, ParentItem, 1, ExpDueDate, Location.Code);
        ExpEndDate := ShiftDateBackBy(SafetyLeadTime, ExpDueDate);
        ExpStartDate := ShiftDateBackBy(LeadTimeCalc, ExpEndDate);
        ExpLineDueDate := ShiftDateBackBy(LeadTimeOffset, ExpStartDate);
        SetGlobalDates(AsmHeader, ExpDueDate, ExpEndDate, ExpStartDate, ExpLineDueDate);
        VSTF257960AVerifyDates(AsmHeader, ExpDueDate, ExpEndDate, ExpStartDate, ExpLineDueDate);
        SavedDueDate := AsmHeader."Due Date";
        SavedEndDate := AsmHeader."Ending Date";
        SavedStartDate := AsmHeader."Starting Date";
        AsmLine.Get(AsmHeader."Document Type", AsmHeader."No.", 10000);
        SavedLineDueDate := AsmLine."Due Date";
        Commit(); // save the state as the rest of the test method uses this data.

        // EXERCISE
        // Push starting date 2 days in the future.
        Step := 2;
        Evaluate(DTFormula, '<+2D>');
        ExpStartDate := CalcDate(DTFormula, AsmHeader."Starting Date");
        ExpEndDate := CalcDate(LeadTimeCalc, ExpStartDate);
        ExpDueDate := CalcDate(SafetyLeadTime, ExpEndDate);
        ExpLineDueDate := ShiftDateBackBy(LeadTimeOffset, ExpStartDate);
        SetGlobalDates(AsmHeader, ExpDueDate, ExpEndDate, ExpStartDate, ExpLineDueDate);
        AsmHeader.Validate("Starting Date", ExpStartDate);
        VSTF257960AVerifyDates(AsmHeader, ExpDueDate, ExpEndDate, ExpStartDate, ExpLineDueDate);
        // revert back to original setup
        asserterror Error('');

        // Push starting date by 6 days in the future.
        Step := 3;
        Evaluate(DTFormula, '<+6D>');
        ExpStartDate := CalcDate(DTFormula, AsmHeader."Starting Date");
        ExpEndDate := CalcDate(LeadTimeCalc, ExpStartDate);
        ExpDueDate := CalcDate(SafetyLeadTime, ExpEndDate);
        ExpLineDueDate := ShiftDateBackBy(LeadTimeOffset, ExpStartDate);
        SetGlobalDates(AsmHeader, ExpDueDate, ExpEndDate, ExpStartDate, ExpLineDueDate);
        asserterror AsmHeader.Validate("Starting Date", ExpStartDate);
        Assert.IsTrue(StrPos(GetLastErrorText, StrSubstNo(ErrEndDateBeforeStartDate, AsmHeader."Ending Date", ExpStartDate)) > 0, '');

        // Pull starting date by 1D in the past.
        Step := 4;
        Evaluate(DTFormula, '<-1D>');
        ExpStartDate := CalcDate(DTFormula, AsmHeader."Starting Date");
        ExpEndDate := CalcDate(LeadTimeCalc, ExpStartDate);
        ExpDueDate := CalcDate(SafetyLeadTime, ExpEndDate);
        ExpLineDueDate := ShiftDateBackBy(LeadTimeOffset, ExpStartDate);
        SetGlobalDates(AsmHeader, ExpDueDate, ExpEndDate, ExpStartDate, ExpLineDueDate);
        AsmHeader.Validate("Starting Date", ExpStartDate);
        VSTF257960AVerifyDates(AsmHeader, ExpDueDate, ExpEndDate, ExpStartDate, ExpLineDueDate);
        // revert back to original setup
        asserterror Error('');

        // Pull ending date by 1D in the past.
        Step := 5;
        Evaluate(DTFormula, '<-1D>');
        ExpEndDate := CalcDate(DTFormula, AsmHeader."Ending Date");
        ExpStartDate := ShiftDateBackBy(LeadTimeCalc, ExpEndDate);
        ExpDueDate := CalcDate(SafetyLeadTime, ExpEndDate);
        ExpLineDueDate := ShiftDateBackBy(LeadTimeOffset, ExpStartDate);
        SetGlobalDates(AsmHeader, ExpDueDate, ExpEndDate, ExpStartDate, ExpLineDueDate);
        AsmHeader.Validate("Ending Date", ExpEndDate);
        VSTF257960AVerifyDates(AsmHeader, ExpDueDate, ExpEndDate, ExpStartDate, ExpLineDueDate);
        // revert back to original setup
        asserterror Error('');

        // Push ending date by 2D in the future.
        Step := 6;
        Evaluate(DTFormula, '<+2D>');
        ExpEndDate := CalcDate(DTFormula, AsmHeader."Ending Date");
        ExpStartDate := ShiftDateBackBy(LeadTimeCalc, ExpEndDate);
        ExpDueDate := CalcDate(SafetyLeadTime, ExpEndDate);
        ExpLineDueDate := ShiftDateBackBy(LeadTimeOffset, ExpStartDate);
        SetGlobalDates(AsmHeader, ExpDueDate, ExpEndDate, ExpStartDate, ExpLineDueDate);
        asserterror AsmHeader.Validate("Ending Date", ExpEndDate);
        Assert.IsTrue(StrPos(GetLastErrorText, StrSubstNo(ErrDueDateBeforeEndDate, AsmHeader."Due Date", ExpEndDate)) > 0, '');

        // Push line due date by 2D in the future.
        Step := 6;
        Evaluate(DTFormula, '<+2D>');
        AsmLine.Get(AsmHeader."Document Type", AsmHeader."No.", 10000);
        ExpLineDueDate := CalcDate(DTFormula, AsmLine."Due Date");
        SetGlobalDates(AsmHeader, ExpDueDate, ExpEndDate, ExpStartDate, ExpLineDueDate);
        asserterror AsmLine.Validate("Due Date", ExpLineDueDate);
        Assert.IsTrue(
          StrPos(
            GetLastErrorText,
            StrSubstNo(ErrLineDueDateBeforeStartDate,
              ShiftDateBackBy(LeadTimeOffset, AsmHeader."Starting Date"), AsmHeader."Starting Date")) > 0, '');

        // Pull start date by 1D in the past (say No to confirm) and then reset it back to its old value- no confirms expected the second time.
        Step := 7;
        Evaluate(DTFormula, '<-1D>');
        ExpStartDate := CalcDate(DTFormula, AsmHeader."Starting Date");
        ExpEndDate := CalcDate(LeadTimeCalc, ExpStartDate);
        ExpDueDate := CalcDate(SafetyLeadTime, ExpEndDate);
        ExpLineDueDate := ShiftDateBackBy(LeadTimeOffset, ExpStartDate);
        SetGlobalDates(AsmHeader, ExpDueDate, ExpEndDate, ExpStartDate, ExpLineDueDate);
        AsmHeader.Validate("Starting Date", ExpStartDate);
        VSTF257960AVerifyDates(AsmHeader, SavedDueDate, SavedEndDate, ExpStartDate, ExpLineDueDate);
        Step := 8;
        AsmHeader.Validate("Starting Date", SavedStartDate); // no confirm expected
        VSTF257960AVerifyDates(AsmHeader, SavedDueDate, SavedEndDate, SavedStartDate, SavedLineDueDate);
        // revert back to original setup
        asserterror Error('');

        // Set start date = WorkDate and verify message coming up
        Step := 9;
        ExpStartDate := WorkDate();
        ExpEndDate := CalcDate(LeadTimeCalc, ExpStartDate);
        ExpDueDate := CalcDate(SafetyLeadTime, ExpEndDate);
        ExpLineDueDate := ShiftDateBackBy(LeadTimeOffset, ExpStartDate);
        SetGlobalDates(AsmHeader, ExpDueDate, ExpEndDate, ExpStartDate, ExpLineDueDate);
        AsmHeader.Validate("Starting Date", ExpStartDate);
        VSTF257960AVerifyDates(AsmHeader, SavedDueDate, SavedEndDate, ExpStartDate, ExpLineDueDate);
        // revert back to original setup
        asserterror Error('');

        // Set a date before workdate on AsmLine and verify message
        Step := 10;
        AsmHeader.Get(AsmHeader."Document Type", AsmHeader."No.");
        AsmLine.Get(AsmHeader."Document Type", AsmHeader."No.", 10000);
        Evaluate(DTFormula, '<-1D>');
        ExpLineDueDate := CalcDate(DTFormula, WorkDate());
        AsmLine.Validate("Due Date", ExpLineDueDate);
        AsmLine.Modify(true);
        VSTF257960AVerifyDates(AsmHeader, SavedDueDate, SavedEndDate, SavedStartDate, ExpLineDueDate);
        // revert back to original setup
        asserterror Error('');

        WorkDate := OldWorkDate;
    end;

    local procedure VSTF257960AVerifyDates(AsmHeader: Record "Assembly Header"; DueDate: Date; EndDate: Date; StartDate: Date; LineDueDate: Date)
    var
        AsmLine: Record "Assembly Line";
    begin
        Assert.AreEqual(DueDate, AsmHeader."Due Date", 'Due Date not OK.');
        Assert.AreEqual(EndDate, AsmHeader."Ending Date", 'Ending Date not OK.');
        Assert.AreEqual(StartDate, AsmHeader."Starting Date", 'Starting Date not OK.');
        AsmLine.Get(AsmHeader."Document Type", AsmHeader."No.", 10000); // first line
        Assert.AreEqual(LineDueDate, AsmLine."Due Date", 'Line Due Date not OK.');
    end;

    [Test]
    [HandlerFunctions('VSTF257960BDateMsgHandler,UpdateLocationOnLines')]
    [Scope('OnPrem')]
    procedure VSTF257960B()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        Location: Record Location;
        AsmHeader: Record "Assembly Header";
        DTFormula: DateFormula;
    begin
        Initialize();
        TestMethodName := TestVSTF257960B;
        Step := 0;
        // Create assembled item with one comp (qty per = 1).
        MockAsmItem(ParentItem, ChildItem, 1);
        // Make sure that safety lead time for parent = 1D
        Evaluate(DTFormula, '<+1D>');
        ParentItem.Validate("Safety Lead Time", DTFormula);
        ParentItem.Modify(true);
        // Create two locations and put in enough inventory for Child Item in both empty and new location
        AddItemToInventory(ChildItem, '', '', 1);
        MockLocation(Location);
        AddItemToInventory(ChildItem, Location.Code, '', 1);
        // Create asm order for 1 PCS of Parent on Location 1
        Step := 1;
        MockAsmOrder(AsmHeader, ParentItem, 1, WorkDate(), ''); // expected message about Due Date before work date from header only
        Step := 2;
        AsmHeader.Validate("Location Code", Location.Code); // expected message about Due Date before work date from header only
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure VSTF257960BDateMsgHandler(Msg: Text[1024])
    var
        MessageTextFromHeader: Text[1024];
        DTFormula: DateFormula;
    begin
        Evaluate(DTFormula, '<-1D>');
        MessageTextFromHeader := StrSubstNo(MsgDueDateBeforeWDFromHeader, CalcDate(DTFormula, WorkDate()), WorkDate());
        case Step of
            1, 2:
                begin
                    Assert.AreEqual(MessageTextFromHeader, Msg, '');
                    exit;
                end;
        end;
        Assert.Fail(Format(Step));
    end;

    [Test]
    [HandlerFunctions('AssemblyAvailabilityCheckModalPageHandler,SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure VSTF266309()
    var
        AssemblySetup: Record "Assembly Setup";
        ParentItem: Record Item;
        ChildItem: Record Item;
        AsmHeader: Record "Assembly Header";
        AsmLine: Record "Assembly Line";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        AsmOrder: TestPage "Assembly Order";
        ZeroDF: DateFormula;
    begin
        Initialize();
        TestMethodName := TestVSTF266309;
        Step := 0;
        // Set Assembly setup to show no warning
        AssemblySetup.Get();
        AssemblySetup.Validate("Stockout Warning", false);
        AssemblySetup.Modify(true);
        // Create assembled item with one comp (qty per = 1).
        MockAsmItem(ParentItem, ChildItem, 1);
        Evaluate(ZeroDF, '<0D>');
        ParentItem.Validate("Safety Lead Time", ZeroDF);
        ParentItem.Modify(true);
        // Create asm order for 1 PCS of Parent
        Step := 1;
        MockAsmOrder(AsmHeader, ParentItem, 1, WorkDate(), ''); // no availability check expected
        AsmLine.Get(AsmHeader."Document Type", AsmHeader."No.", 10000); // first line
        // Show availability from line
        Step := 2;
        AsmLine.ShowAvailabilityWarning(); // line availability warning expected
        Assert.IsTrue(AsmLine."Avail. Warning", ''); // expect availability warning
        // Show availability from header
        AsmOrder.Trap();
        PAGE.Run(PAGE::"Assembly Order", AsmHeader);
        Step := 3;
        AsmOrder.ShowAvailability.Invoke(); // availability warning expected
        asserterror Error(''); // to undo changes made to Setup table.
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('DueDateBeforeWorkDateMsgHandler')]
    [Scope('OnPrem')]
    procedure VSTF267434()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        Location: Record Location;
        Bin: Record Bin;
        AsmHeader: Record "Assembly Header";
        AsmLine: Record "Assembly Line";
    begin
        Initialize();

        // Create assembled item with one comp (qty per = 1).
        MockAsmItem(ParentItem, ChildItem, 1);

        // Create Bin Mandatory location with To-Assembly Bin filled in
        MockLocation(Location);
        Location."Bin Mandatory" := true;
        LibraryWarehouse.CreateBin(Bin, Location.Code, FirstNumber, '', '');
        Location."To-Assembly Bin Code" := Bin.Code;
        Location.Modify();

        // Add 2 PCS of component to inventory
        AddItemToInventory(ChildItem, Location.Code, Bin.Code, 2);

        // Change manufacturing Default Safety Lead Time = 2D
        LibraryPlanning.SetDefaultSafetyLeadTime('1D');

        // Create asm order
        Clear(AsmHeader);
        AsmHeader."Document Type" := AsmHeader."Document Type"::Order;
        AsmHeader.Insert(true);
        AsmHeader.Validate("Due Date", WorkDate());
        AsmHeader.Validate("Location Code", Location.Code);
        AsmHeader.Validate("Item No.", ParentItem."No.");
        AsmHeader.Validate(Quantity, 1);
        AsmHeader.Modify(true);
        // verify that the bin code on the line is To-Asm Bin Code
        AsmLine.SetRange("Document Type", AsmHeader."Document Type");
        AsmLine.SetRange("Document No.", AsmHeader."No.");
        AsmLine.FindLast();
        Assert.AreEqual(Bin.Code, AsmLine."Bin Code", '');
    end;

    local procedure ShiftDateBackBy(Offset: DateFormula; RefDate: Date): Date
    begin
        exit(RefDate - (CalcDate(Offset, WorkDate()) - WorkDate()));
    end;

    local procedure SetGlobalDates(AsmHeader: Record "Assembly Header"; NewDueDate2: Date; NewEndDate2: Date; NewStartDate2: Date; NewLineDueDate2: Date)
    begin
        OldDueDate := AsmHeader."Due Date";
        OldEndDate := AsmHeader."Ending Date";
        OldStartDate := AsmHeader."Starting Date";
        NewDueDate := NewDueDate2;
        NewEndDate := NewEndDate2;
        NewStartDate := NewStartDate2;
        NewLineDueDate := NewLineDueDate2;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure DateConfirmationHandler(Question: Text[1024]; var Reply: Boolean)
    var
        StartDateChangedText: Text[1024];
        EndDateChangedText: Text[1024];
    begin
        StartDateChangedText :=
          StrSubstNo(CnfmStartingDateChanged, OldStartDate, NewStartDate, OldEndDate, NewEndDate, OldDueDate, NewDueDate);
        EndDateChangedText := StrSubstNo(CnfmEndingDateChanged, OldEndDate, NewEndDate, OldDueDate, NewDueDate);
        case TestMethodName of
            'VSTF258428':
                case Step of
                    2:
                        begin
                            Assert.IsTrue(
                              StrPos(Question, StartDateChangedText) > 0, StrSubstNo('Wrong Question: %1 \Expected: %2', Question, StartDateChangedText));
                            Reply := true;
                            exit;
                        end;
                    4:
                        begin
                            Assert.IsTrue(
                              StrPos(Question, EndDateChangedText) > 0, StrSubstNo('Wrong Question: %1 \Expected: %2', Question, EndDateChangedText));
                            Reply := true;
                            exit;
                        end;
                end;
            TestVSTF257960A:
                case Step of
                    2:
                        begin
                            Assert.IsTrue(
                              StrPos(Question, StartDateChangedText) > 0, StrSubstNo('Wrong Question: %1 \Expected: %2', Question, StartDateChangedText));
                            Reply := true;
                            exit;
                        end;
                    3:
                        begin
                            Assert.IsTrue(
                              StrPos(Question, StartDateChangedText) > 0, StrSubstNo('Wrong Question: %1 \Expected: %2', Question, StartDateChangedText));
                            Reply := false;
                            exit;
                        end;
                    4:
                        begin
                            Assert.IsTrue(
                              StrPos(Question, StartDateChangedText) > 0, StrSubstNo('Wrong Question: %1 \Expected: %2', Question, StartDateChangedText));
                            Reply := true;
                            exit;
                        end;
                    5:
                        begin
                            Assert.IsTrue(
                              StrPos(Question, EndDateChangedText) > 0, StrSubstNo('Wrong Question: %1 \Expected: %2', Question, EndDateChangedText));
                            Reply := true;
                            exit;
                        end;
                    6:
                        begin
                            Assert.IsTrue(
                              StrPos(Question, EndDateChangedText) > 0, StrSubstNo('Wrong Question: %1 \Expected: %2', Question, EndDateChangedText));
                            Reply := false;
                            exit;
                        end;
                    7:
                        begin
                            Assert.IsTrue(
                              StrPos(Question, StartDateChangedText) > 0, StrSubstNo('Wrong Question: %1 \Expected: %2', Question, StartDateChangedText));
                            Reply := false;
                            exit;
                        end;
                    9:
                        begin
                            Assert.IsTrue(
                              StrPos(Question, StartDateChangedText) > 0, StrSubstNo('Wrong Question: %1 \Expected: %2', Question, StartDateChangedText));
                            Reply := false;
                            exit;
                        end;
                end;
        end;
        Assert.Fail(StrSubstNo('Confirmation dialog at step = %1 not expected.', Step));
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure DueDateBeforeWorkDateMsgHandler(Msg: Text[1024])
    var
        MessageTextFromHeader: Text[1024];
        MessageTextFromLine: Text[1024];
    begin
        MessageTextFromHeader := StrSubstNo(MsgDueDateBeforeWDFromHeader, NewLineDueDate, WorkDate());
        MessageTextFromLine := StrSubstNo(MsgDueDateBeforeWDFromLine, NewLineDueDate, WorkDate());
        case TestMethodName of
            TestVSTF257960A:
                case Step of
                    1, 9:
                        begin
                            Assert.IsTrue(
                              StrPos(Msg, MessageTextFromHeader) > 0, StrSubstNo('Wrong message: %1 \Expected: %2', Msg, MessageTextFromHeader));
                            exit;
                        end;
                    10:
                        begin
                            Assert.IsTrue(
                              StrPos(Msg, MessageTextFromLine) > 0, StrSubstNo('Wrong message: %1 \Expected: %2', Msg, MessageTextFromLine));
                            exit;
                        end;
                end;
            else
                exit; // for other test methods.
        end;

        Assert.Fail(StrSubstNo('Message at Step %1 not expected.', Step));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailWarningConfirm(var AssemblyAvailability: Page "Assembly Availability"; var Response: Action)
    var
        AsmHeader: Record "Assembly Header";
        AsmLine: Record "Assembly Line";
        NewChildItem: Record Item;
    begin
        case TestMethodName of
            'ChangeLocCheckDueDateNoLineUpd',
          'ChangeLocCheckDueDateLineUpd':
                if Step in [1, 2] then begin
                    Response := ACTION::Yes;
                    exit;
                end;
            'ValidateLocAfterSKUNewDueDate',
          'ChangeVariantNoLocUpdConfirm':
                if Step in [1, 2, 3] then begin
                    Response := ACTION::Yes;
                    exit;
                end;
            TestDataConsistencyCheck:
                case Step of
                    1:
                        begin
                            Response := ACTION::Yes;
                            exit;
                        end;
                    2:
                        begin
                            // get assembly line for this header and modify it
                            AsmHeader.Init();
                            AssemblyAvailability.GetRecord(AsmHeader);
                            AsmLine.Get(AsmHeader."Document Type", AsmHeader."No.", 10000); // get first asm line
                            AsmLine.Validate(Type, AsmLine.Type::Item);
                            MockItem(NewChildItem);
                            AsmLine.Validate("No.", NewChildItem."No.");
                            AsmLine.Modify(true);
                            // now respond by Yes.
                            Response := ACTION::Yes;
                            exit;
                        end;
                end;
            'ValidateItemNoToParentItem':
                if Step = 2 then begin
                    Response := ACTION::Yes;
                    exit;
                end;
            'VSTF238472':
                if Step = 1 then begin
                    Response := ACTION::Yes;
                    exit;
                end;
            'EarliestDatesCheck':
                if Step = 1 then begin
                    Response := ACTION::Yes;
                    exit;
                end;
            'VSTF255987':
                case Step of
                    1, 4:
                        begin
                            Response := ACTION::Yes;
                            exit;
                        end;
                end;
            TestMethodVSTF238977:
                if Step in [1, 2] then begin
                    Response := ACTION::Yes;
                    exit;
                end;
            TestVSTF266309:
                if Step = 3 then begin
                    Response := ACTION::Yes;
                    exit;
                end;
        end;
        Assert.Fail(StrSubstNo(TestMsgAvailConfirm, Step));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure UpdateLocationOnLines(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(Question, CnfmUpdateLocationOnLines) > 0, 'Wrong Confirm Question: ' + Question);
        case TestMethodName of
            'ChangeLocCheckDueDateNoLineUpd':
                if Step = 2 then begin
                    Reply := false;
                    exit;
                end;
            'ChangeLocCheckDueDateLineUpd',
          'ValidateLocAfterSKUNewDueDate',
          'ChangeVariantNoLocUpdConfirm',
          TestDataConsistencyCheck,
          TestVSTF257960B:
                if Step = 2 then begin
                    Reply := true;
                    exit;
                end;
        end;
        Assert.Fail('Location update confirm should not appear on step = ' + Format(Step));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmChangeOfItem(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(Question, CnfmChangeOfItemNo) > 0, 'Wrong Confirm Question: ' + Question);
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmRefreshLines(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(Question, CnfmRefreshLines) > 0, Question);
        case TestMethodName of
            'VSTF255987':
                case Step of
                    3:
                        begin
                            Reply := false;
                            exit;
                        end;
                    4:
                        begin
                            Reply := true;
                            exit;
                        end;
                end;
        end;
        Assert.Fail('Refresh confirm should not appear on step = ' + Format(Step));
    end;

    [Test]
    [HandlerFunctions('EarliestDatesCheckTestPage,DueDateBeforeWorkDateMsgHandler,EarliestDatesCheckAvailabilityTestPageNotificationHandler')]
    [Scope('OnPrem')]
    procedure EarliestDatesCheck()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        AsmHeader: Record "Assembly Header";
        AsmLine: Record "Assembly Line";
        Location: Record Location;
        ItemUOM: Record "Item Unit of Measure";
        UnitOfMeasure: Record "Unit of Measure";
        LeadTime: DateFormula;
    begin
        Initialize();
        // 1. Create item X with 2 UOMs (BOX = 5, PCS = 1). Set replenishment system = Assembly.
        // 2. Create SKU at BLUE with Safety Lead Time = 3D
        // 3. Change manufacturing default safety lead time = 2D
        // 4. Create item Y and post 2 PCS at BLUE.
        // 5. Create purchase order for 10 PCS at BLUE with Expected receipt date = 1M from WORKDATE
        // 6. Create asm order at BLUE for location X: 1 PCS.
        // 7. Add asm line for 1 PCS of item Y, also at BLUE.
        // 8. Change UOM in header from PCS to BOX.

        TestMethodName := 'EarliestDatesCheck';
        // Create assembled item without comp.
        MockItem(ParentItem);
        ParentItem.Validate("Replenishment System", ParentItem."Replenishment System"::Assembly);
        ParentItem.Modify(true);

        // Set dates
        LibraryPlanning.SetDefaultSafetyLeadTime('2D');
        MockLocation(Location);
        MockSKU(ParentItem, Location.Code, '3D', '4D');

        // add 2 PCS of child to inventory
        MockItem(ChildItem);
        AddItemToInventory(ChildItem, Location.Code, '', 2);

        // Create supply for next month for 10 PCS of child
        MockPurchOrder(ChildItem."No.", 10, Location.Code, CalcDate('<+1M>', WorkDate()));

        // Create asm order
        Step := 1;
        MockAsmOrder(AsmHeader, ParentItem, 1, WorkDate(), '');
        Step := 2;
        AsmHeader.Validate("Location Code", Location.Code);
        AsmHeader.Modify(true);
        // edit the production lead time on the asm line to 5D
        LibraryAssembly.CreateAssemblyLine(AsmHeader, AsmLine, "BOM Component Type"::Item, ChildItem."No.", '', 1, 1, '');
        AsmLine.Validate("Location Code", Location.Code);
        Evaluate(LeadTime, '5D');
        AsmLine.Validate("Lead-Time Offset", LeadTime);
        AsmLine.Modify(true);

        // Now change UOM on header to BOX (= 5 PCS)
        UnitOfMeasure.FindLast();
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, ParentItem."No.", UnitOfMeasure.Code, 5);
        Step := 3;
        AsmHeader.Validate("Unit of Measure Code", UnitOfMeasure.Code); // avail warning should open - make check
        AsmHeader.Modify();
        Commit();
        NotificationLifecycleMgt.RecallAllNotifications();
        Step := 4;
        AsmHeader.ShowAvailability();
        ClearLastError();

        // set data back to original
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure EarliestDatesCheckAvailabilityTestPageNotificationHandler(var Notification: Notification): Boolean
    var
        AssemblyLineManagement: Codeunit "Assembly Line Management";
    begin
        Commit();
        AssemblyLineManagement.ShowNotificationDetails(Notification);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EarliestDatesCheckTestPage(var AsmAvailabilityCheck: TestPage "Assembly Availability Check")
    var
        ExpectedPageToAppear: Boolean;
    begin
        if Step = 3 then
            exit;
        if Step = 4 then
            CAWVerifyAvailCheckWarningPage(AsmAvailabilityCheck, ExpectedPageToAppear, CalcDate('<+1M>', WorkDate()),
              2 / 5, 0, 0, 0); // (2 / 5) because 2 are in inventory & 5 is Qty per UOM
        if not ExpectedPageToAppear then
            Assert.Fail('Availability warning should not appear on Step = ' + Format(Step));
    end;

    [Test]
    [HandlerFunctions('CAWTestAvailWarningPage,EarliestDatesCheckAvailabilityTestPageNotificationHandler,DueDateBeforeWorkDateMsgHandler')]
    [Scope('OnPrem')]
    procedure CheckAvailWarning()
    begin
        Initialize();
        TestMethodName := 'CheckAvailWarning';

        // Change manufacturing Default Safety Lead Time = 2D
        LibraryPlanning.SetDefaultSafetyLeadTime('1D');

        // Steps 1 to 3 are for case when no other demand exists
        SupplyDate1 := GetDate('-1W', WorkDate());
        SupplyQty1 := 2;
        SupplyDate2 := GetDate('+3W', WorkDate());
        SupplyQty2 := 4;

        Step := 1; // Asm order created before 1st supply
        CAWLaunchTest(GetDate('-1W', SupplyDate1));
        Step := 2; // Asm order created between 1st & 2nd supply
        CAWLaunchTest(GetDate('+1W+1D', SupplyDate1)); // 1D is added to avoid getting the "Due Date is before Work Date message"
        Step := 3; // Asm order created after 2nd supply
        CAWLaunchTest(GetDate('+1W', SupplyDate2));

        // Steps 4 to 6 for case when asm demand exists before 1st supply
        DemandDate := GetDate('-2W', SupplyDate1);
        DemandQty := 1;

        Step := 4; // Asm order created between asm demand and 1st supply
        CAWLaunchTest(GetDate('-1W', SupplyDate1));
        Step := 5; // Asm order created between 1st and 2nd supply
        CAWLaunchTest(GetDate('+1W+1D', SupplyDate1)); // 1D is added to avoid getting the "Due Date is before Work Date message"
        Step := 6; // Asm order created after 2nd supply
        CAWLaunchTest(GetDate('+1W', SupplyDate2));

        // Steps 7 to 9 for case when asm demand between 1st and 2nd supply
        DemandDate := GetDate('+2W', SupplyDate1);
        DemandQty := 1;

        Step := 7; // Asm order created between asm demand and 1st supply
        CAWLaunchTest(GetDate('+1W+1D', SupplyDate1)); // 1D is added to avoid getting the "Due Date is before Work Date message"
        Step := 8; // Asm order created between asm demand and 2nd supply
        CAWLaunchTest(GetDate('+1W', DemandDate));
        Step := 9; // Asm order created after 2nd supply
        CAWLaunchTest(GetDate('+1W', SupplyDate2));

        // Steps 10 to 12 for case when asm demand lies after 2nd supply
        DemandDate := GetDate('+2W', SupplyDate2);
        DemandQty := 1;

        Step := 10; // Asm order created between 1st and 2nd supply
        CAWLaunchTest(GetDate('+1W+1D', SupplyDate1)); // 1D is added to avoid getting the "Due Date is before Work Date message"
        Step := 11; // Asm order created between asm demand and 2nd supply
        CAWLaunchTest(GetDate('+1W', SupplyDate2));
        Step := 12; // Asm order created after asm demand
        CAWLaunchTest(GetDate('+1W', DemandDate));
    end;

    local procedure CAWLaunchTest(AsmDueDate: Date)
    begin
        SubStep := 1; // Make asm order for qty less than 1st supply
        CAWCreateDataAndExercise(SupplyQty1 - 1, AsmDueDate);
        SubStep := 2; // Make asm order for qty = 1st supply
        CAWCreateDataAndExercise(SupplyQty1, AsmDueDate);
        SubStep := 3; // Make asm order for qty > 1st supply
        CAWCreateDataAndExercise(SupplyQty1 + 1, AsmDueDate);
        SubStep := 4; // Make asm order for qty = 2nd supply
        CAWCreateDataAndExercise(SupplyQty2, AsmDueDate);
        SubStep := 5; // Make asm order for qty = 1st + 2nd supply
        CAWCreateDataAndExercise(SupplyQty1 + SupplyQty2, AsmDueDate);
        SubStep := 6; // Make asm order for qty > 1st + 2nd supply
        CAWCreateDataAndExercise(SupplyQty1 + SupplyQty2 + 1, AsmDueDate);
    end;

    local procedure CAWCreateDataAndExercise(AsmQty: Decimal; AsmDueDate: Date)
    var
        AsmHeader2: Record "Assembly Header";
        AsmLine2: Record "Assembly Line";
        AsmHeader: Record "Assembly Header";
        ChildItem: Record Item;
        ParentItem: Record Item;
        BOMComponent: Record "BOM Component";
    begin
        MockItem(ChildItem);
        // make purchase as supply for Supply 1
        MockPurchOrder(ChildItem."No.", SupplyQty1, '', SupplyDate1);
        // make assembly as supply for Supply 2
        LibraryAssembly.CreateAssemblyHeader(AsmHeader2, SupplyDate2, ChildItem."No.", '', SupplyQty2, '');

        // make assembly order as demand
        MockItem(ParentItem);
        ParentItem.Validate("Replenishment System", ParentItem."Replenishment System"::Assembly);
        ParentItem.Modify(true);
        if DemandDate <> 0D then begin
            LibraryAssembly.CreateAssemblyHeader(AsmHeader2, DemandDate, ParentItem."No.", '', DemandQty, '');
            LibraryAssembly.CreateAssemblyLine(AsmHeader2, AsmLine2, "BOM Component Type"::Item, ChildItem."No.", '', DemandQty, 1, '');
        end;

        // make the Assembly list- the reason it wasnt above because it throws up availability warning.
        LibraryInventory.CreateBOMComponent(BOMComponent, ParentItem."No.", BOMComponent.Type::Item,
          ChildItem."No.", 1, ChildItem."Base Unit of Measure");

        if (Step = 1) or
           ((Step = 2) and (SubStep in [3, 4, 5, 6])) or
           ((Step = 3) and (SubStep in [6])) or
           (Step = 4) or
           ((Step = 5) and (SubStep in [2, 3, 4, 5, 6])) or
           ((Step = 6) and (SubStep in [5, 6])) or
           ((Step = 7) and (SubStep in [2, 3, 4, 5, 6])) or
           ((Step = 8) and (SubStep in [2, 3, 4, 5, 6])) or
           ((Step = 9) and (SubStep in [5, 6])) or
           ((Step = 10) and (SubStep in [3, 4, 5, 6])) or
           ((Step = 11) and (SubStep in [5, 6])) or
           ((Step = 12) and (SubStep in [5, 6]))
        then
            MockAsmOrder(AsmHeader, ParentItem, AsmQty, AsmDueDate, '') //no more errors related to availability
        else begin
            asserterror
            begin
                MockAsmOrder(AsmHeader, ParentItem, AsmQty, AsmDueDate, ''); // verification that avail warning does not appear.
                Error(''); // this is done so that the assembly order just created goes away, else it will contribute to demand.
            end;
            Assert.AreEqual('', GetLastErrorText, 'Unexpected error: ' + GetLastErrorText);
        end;
        ClearLastError();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CAWTestAvailWarningPage(var AsmAvailabilityCheck: TestPage "Assembly Availability Check")
    var
        ExpectedPageToAppear: Boolean;
    begin
        case Step of
            1:
                case SubStep of
                    1, 2:
                        CAWVerifyAvailCheckWarningPage(AsmAvailabilityCheck, ExpectedPageToAppear, SupplyDate1, 0, 0, 0, 0);
                    3, 4, 5:
                        CAWVerifyAvailCheckWarningPage(AsmAvailabilityCheck, ExpectedPageToAppear, SupplyDate2, 0, 0, 0, 0);
                    6:
                        CAWVerifyAvailCheckWarningPage(AsmAvailabilityCheck, ExpectedPageToAppear, 0D, 0, 0, 0, 0);
                end;
            2:
                case SubStep of
                    3, 4, 5:
                        CAWVerifyAvailCheckWarningPage(AsmAvailabilityCheck, ExpectedPageToAppear, SupplyDate2, SupplyQty1, 0, SupplyQty1, 0);
                    6:
                        CAWVerifyAvailCheckWarningPage(AsmAvailabilityCheck, ExpectedPageToAppear, 0D, SupplyQty1, 0, SupplyQty1, 0);
                end;
            3:
                case SubStep of
                    6:
                        CAWVerifyAvailCheckWarningPage(AsmAvailabilityCheck, ExpectedPageToAppear, 0D, SupplyQty1 + SupplyQty2, 0, SupplyQty1 + SupplyQty2, 0);
                end;
            4:
                case SubStep of
                    1:
                        CAWVerifyAvailCheckWarningPage(AsmAvailabilityCheck, ExpectedPageToAppear, SupplyDate1, 0, DemandQty, 0, DemandQty);
                    2, 3, 4:
                        CAWVerifyAvailCheckWarningPage(AsmAvailabilityCheck, ExpectedPageToAppear, SupplyDate2, 0, DemandQty, 0, DemandQty);
                    5, 6:
                        CAWVerifyAvailCheckWarningPage(AsmAvailabilityCheck, ExpectedPageToAppear, 0D, 0, DemandQty, 0, DemandQty);
                end;
            5:
                case SubStep of
                    2, 3, 4:
                        CAWVerifyAvailCheckWarningPage(AsmAvailabilityCheck, ExpectedPageToAppear, SupplyDate2, SupplyQty1 - DemandQty,
                          DemandQty, SupplyQty1, DemandQty);
                    5, 6:
                        CAWVerifyAvailCheckWarningPage(AsmAvailabilityCheck, ExpectedPageToAppear, 0D, SupplyQty1 - DemandQty,
                          DemandQty, SupplyQty1, DemandQty);
                end;
            6:
                case SubStep of
                    5, 6:
                        CAWVerifyAvailCheckWarningPage(AsmAvailabilityCheck, ExpectedPageToAppear, 0D, SupplyQty1 + SupplyQty2 - DemandQty,
                          DemandQty, SupplyQty1 + SupplyQty2, DemandQty);
                end;
            7:
                case SubStep of
                    2, 3, 4:
                        CAWVerifyAvailCheckWarningPage(
                          AsmAvailabilityCheck, ExpectedPageToAppear, SupplyDate2, SupplyQty1 - DemandQty, 0, SupplyQty1, DemandQty);
                    5, 6:
                        CAWVerifyAvailCheckWarningPage(
                          AsmAvailabilityCheck, ExpectedPageToAppear, 0D, SupplyQty1 - DemandQty, 0, SupplyQty1, DemandQty);
                end;
            8:
                case SubStep of
                    2, 3, 4:
                        CAWVerifyAvailCheckWarningPage(AsmAvailabilityCheck, ExpectedPageToAppear, SupplyDate2, SupplyQty1 - DemandQty,
                          DemandQty, SupplyQty1, DemandQty);
                    5, 6:
                        CAWVerifyAvailCheckWarningPage(AsmAvailabilityCheck, ExpectedPageToAppear, 0D, SupplyQty1 - DemandQty, DemandQty, SupplyQty1, DemandQty);
                end;
            9:
                case SubStep of
                    5, 6:
                        CAWVerifyAvailCheckWarningPage(AsmAvailabilityCheck, ExpectedPageToAppear, 0D, SupplyQty1 + SupplyQty2 - DemandQty,
                          DemandQty, SupplyQty1 + SupplyQty2, DemandQty);
                end;
            10:
                case SubStep of
                    3, 4:
                        CAWVerifyAvailCheckWarningPage(AsmAvailabilityCheck, ExpectedPageToAppear, SupplyDate2, SupplyQty1, 0, SupplyQty1, 0);
                    5:
                        CAWVerifyAvailCheckWarningPage(AsmAvailabilityCheck, ExpectedPageToAppear, SupplyDate2, SupplyQty1, 0, SupplyQty1, 0);
                    6:
                        CAWVerifyAvailCheckWarningPage(AsmAvailabilityCheck, ExpectedPageToAppear, 0D, SupplyQty1, 0, SupplyQty1, 0);
                end;
            11:
                case SubStep of
                    5, 6:
                        CAWVerifyAvailCheckWarningPage(
                          AsmAvailabilityCheck, ExpectedPageToAppear, 0D, SupplyQty1 + SupplyQty2 - DemandQty, 0, SupplyQty1 + SupplyQty2, DemandQty);
                end;
            12:
                case SubStep of
                    5, 6:
                        CAWVerifyAvailCheckWarningPage(AsmAvailabilityCheck, ExpectedPageToAppear, 0D, SupplyQty1 + SupplyQty2 - DemandQty,
                          DemandQty, SupplyQty1 + SupplyQty2, DemandQty);
                end;
        end;
        if not ExpectedPageToAppear then
            Assert.Fail('Availability warning should not appear on Step = ' + Format(Step) +
              ' and SubStep = ' + Format(SubStep));
    end;

    [Scope('OnPrem')]
    procedure CAWVerifyAvailWarningPage(var AsmAvailability: TestPage "Assembly Availability"; var ExpectedPageToAppear: Boolean; ExpectedLineAvailDate: Date; ExpectedAbleToAssemble: Decimal; ExpectedHeaderSchRcpt: Decimal; ExpectedLineSchRcpt: Decimal; ExpectedLineGrossReq: Decimal)
    var
        InventorySetup: Record "Inventory Setup";
        StockkeepingUnit: Record "Stockkeeping Unit";
        HdrEarliestDateOffset: Text[30];
        ExpectedAvailDate: Date;
        ActualAbleToAssemble: Decimal;
        ActualEarliestAvailDate: Date;
        ActualGrossReq: Decimal;
        ActualSchRcpt: Decimal;
        ActualLineEarliestAvailDate: Date;
        ActualLineSchRcpt: Decimal;
        ActualLineGrossReq: Decimal;
        StepInfo: Text[30];
        DF: DateFormula;
    begin
        ExpectedPageToAppear := true;
        Evaluate(ActualAbleToAssemble, AsmAvailability.AbleToAssemble.Value);
        ActualEarliestAvailDate := AsmAvailability.EarliestAvailableDate.AsDate();
        AsmAvailability.AssemblyLineAvail.First();
        Evaluate(ActualLineSchRcpt, AsmAvailability.AssemblyLineAvail.ScheduledReceipt.Value);
        Evaluate(ActualLineGrossReq, AsmAvailability.AssemblyLineAvail.GrossRequirement.Value);
        ActualLineEarliestAvailDate := AsmAvailability.AssemblyLineAvail.EarliestAvailableDate.AsDate();
        StepInfo := 'Step = ' + Format(Step) + '; SubStep = ' + Format(SubStep);
        Assert.AreEqual(ExpectedAbleToAssemble, ActualAbleToAssemble, 'Incorrect Able to Assemble Qty. ' + StepInfo);
        Evaluate(ActualGrossReq, AsmAvailability.GrossRequirement.Value);
        Assert.AreEqual(0, ActualGrossReq, 'Incorrect Gross Req in Header. ' + StepInfo); // always zero in these test methods
        Evaluate(ActualSchRcpt, AsmAvailability.ScheduledReceipts.Value);
        Assert.AreEqual(ExpectedHeaderSchRcpt, ActualSchRcpt, 'Incorrect Scheduled Receipt in Header. ' + StepInfo);
        InventorySetup.Get();
        if StockkeepingUnit.Get(AsmAvailability."Location Code".Value, AsmAvailability."Item No.".Value,
             AsmAvailability."Variant Code".Value)
        then
            ;
        if ExpectedLineAvailDate > 0D then begin
            AddToDateOffsetText(HdrEarliestDateOffset, InventorySetup."Default Safety Lead Time", false);
            AddToDateOffsetText(HdrEarliestDateOffset, StockkeepingUnit."Safety Lead Time", true);
            AddToDateOffsetText(HdrEarliestDateOffset, StockkeepingUnit."Lead Time Calculation", false);
            Evaluate(DF, AsmAvailability.AssemblyLineAvail."Lead-Time Offset".Value);
            AddToDateOffsetText(HdrEarliestDateOffset, DF, false);
            Evaluate(DF, HdrEarliestDateOffset);
            ExpectedAvailDate := CalcDate(DF, ExpectedLineAvailDate);
        end;
        Assert.AreEqual(ExpectedAvailDate, ActualEarliestAvailDate, 'Incorrect earliest availability date. ' + StepInfo);
        Assert.AreEqual(ExpectedLineSchRcpt, ActualLineSchRcpt, 'Incorrect line scheduled receipt. ' + StepInfo);
        Assert.AreEqual(ExpectedLineGrossReq, ActualLineGrossReq, 'Incorrect line gross requirement. ' + StepInfo);
        Assert.AreEqual(ExpectedLineAvailDate, ActualLineEarliestAvailDate, 'Incorrect line available date. ' + StepInfo);
    end;

    [Scope('OnPrem')]
    procedure CAWVerifyAvailCheckWarningPage(var AsmAvailabilityCheck: TestPage "Assembly Availability Check"; var ExpectedPageToAppear: Boolean; ExpectedLineAvailDate: Date; ExpectedAbleToAssemble: Decimal; ExpectedHeaderSchRcpt: Decimal; ExpectedLineSchRcpt: Decimal; ExpectedLineGrossReq: Decimal)
    var
        InventorySetup: Record "Inventory Setup";
        StockkeepingUnit: Record "Stockkeeping Unit";
        HdrEarliestDateOffset: Text[30];
        ExpectedAvailDate: Date;
        ActualAbleToAssemble: Decimal;
        ActualEarliestAvailDate: Date;
        ActualGrossReq: Decimal;
        ActualSchRcpt: Decimal;
        ActualLineEarliestAvailDate: Date;
        ActualLineSchRcpt: Decimal;
        ActualLineGrossReq: Decimal;
        StepInfo: Text[30];
        DF: DateFormula;
    begin
        ExpectedPageToAppear := true;
        Evaluate(ActualAbleToAssemble, AsmAvailabilityCheck.AbleToAssemble.Value);
        ActualEarliestAvailDate := AsmAvailabilityCheck.EarliestAvailableDate.AsDate();
        AsmAvailabilityCheck.AssemblyLineAvail.First();
        Evaluate(ActualLineSchRcpt, AsmAvailabilityCheck.AssemblyLineAvail.ScheduledReceipt.Value);
        Evaluate(ActualLineGrossReq, AsmAvailabilityCheck.AssemblyLineAvail.GrossRequirement.Value);
        ActualLineEarliestAvailDate := AsmAvailabilityCheck.AssemblyLineAvail.EarliestAvailableDate.AsDate();
        StepInfo := 'Step = ' + Format(Step) + '; SubStep = ' + Format(SubStep);
        Assert.AreEqual(ExpectedAbleToAssemble, ActualAbleToAssemble, 'Incorrect Able to Assemble Qty. ' + StepInfo);
        Evaluate(ActualGrossReq, AsmAvailabilityCheck.GrossRequirement.Value);
        Assert.AreEqual(0, ActualGrossReq, 'Incorrect Gross Req in Header. ' + StepInfo); // always zero in these test methods
        Evaluate(ActualSchRcpt, AsmAvailabilityCheck.ScheduledReceipts.Value);
        Assert.AreEqual(ExpectedHeaderSchRcpt, ActualSchRcpt, 'Incorrect Scheduled Receipt in Header. ' + StepInfo);
        InventorySetup.Get();
        if StockkeepingUnit.Get(AsmAvailabilityCheck."Location Code".Value, AsmAvailabilityCheck."Item No.".Value,
             AsmAvailabilityCheck."Variant Code".Value)
        then
            ;
        if ExpectedLineAvailDate > 0D then begin
            AddToDateOffsetText(HdrEarliestDateOffset, InventorySetup."Default Safety Lead Time", false);
            AddToDateOffsetText(HdrEarliestDateOffset, StockkeepingUnit."Safety Lead Time", true);
            AddToDateOffsetText(HdrEarliestDateOffset, StockkeepingUnit."Lead Time Calculation", false);
            Evaluate(DF, AsmAvailabilityCheck.AssemblyLineAvail."Lead-Time Offset".Value);
            AddToDateOffsetText(HdrEarliestDateOffset, DF, false);
            Evaluate(DF, HdrEarliestDateOffset);
            ExpectedAvailDate := CalcDate(DF, ExpectedLineAvailDate);
        end;
        Assert.AreEqual(ExpectedAvailDate, ActualEarliestAvailDate, 'Incorrect earliest availability date. ' + StepInfo);
        Assert.AreEqual(ExpectedLineSchRcpt, ActualLineSchRcpt, 'Incorrect line scheduled receipt. ' + StepInfo);
        Assert.AreEqual(ExpectedLineGrossReq, ActualLineGrossReq, 'Incorrect line gross requirement. ' + StepInfo);
        Assert.AreEqual(ExpectedLineAvailDate, ActualLineEarliestAvailDate, 'Incorrect line available date. ' + StepInfo);
    end;

    local procedure AddToDateOffsetText(var OffsetText: Text[30]; NewOffset: DateFormula; Replace: Boolean)
    var
        ZeroDF: DateFormula;
    begin
        if NewOffset <> ZeroDF then
            if OffsetText = '' then
                OffsetText := Format(NewOffset)
            else
                if Replace then
                    OffsetText := Format(NewOffset)
                else
                    OffsetText += '+' + Format(NewOffset);
    end;

    local procedure MockItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
    end;

    local procedure MockSKU(Item: Record Item; LocationCode: Code[10]; LeadTime: Text[30]; LeadTimeCalc: Text[30]): Code[10]
    var
        ItemVariant: Record "Item Variant";
        StockkeepingUnit: Record "Stockkeeping Unit";
        DF: DateFormula;
    begin
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, LocationCode, Item."No.", ItemVariant.Code);
        Evaluate(DF, LeadTime);
        StockkeepingUnit.Validate("Safety Lead Time", DF);
        Evaluate(DF, LeadTimeCalc);
        StockkeepingUnit.Validate("Lead Time Calculation", DF);
        StockkeepingUnit.Modify(true);
        exit(ItemVariant.Code);
    end;

    local procedure MockLocation(var Location: Record Location)
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
    end;

    local procedure AddItemToInventory(Item: Record Item; LocationCode: Code[10]; BinCode: Code[20]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        ItemJournalTemplate.SetRange(Type, ItemJournalTemplate.Type::Item);
        ItemJournalTemplate.SetRange(Recurring, false);
        ItemJournalTemplate.FindFirst();
        ItemJournalBatch.SetRange("Journal Template Name", ItemJournalTemplate.Name);
        ItemJournalBatch.FindFirst();

        ItemJournalLine.SetRange("Journal Template Name", ItemJournalTemplate.Name);
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.DeleteAll();
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    local procedure MockAsmItem(var ParentItem: Record Item; var ChildItem: Record Item; QtyPer: Decimal)
    var
        BOMComponent: Record "BOM Component";
    begin
        MockItem(ChildItem);
        MockItem(ParentItem);
        ParentItem.Validate("Replenishment System", ParentItem."Replenishment System"::Assembly);
        ParentItem.Modify(true);
        LibraryInventory.CreateBOMComponent(BOMComponent, ParentItem."No.", BOMComponent.Type::Item,
          ChildItem."No.", QtyPer, ChildItem."Base Unit of Measure");
    end;

    local procedure MockAsmOrder(var AsmHeader: Record "Assembly Header"; ParentItem: Record Item; Qty: Decimal; DueDate: Date; LocationCode: Code[10])
    begin
        Clear(AsmHeader);
        AsmHeader."Document Type" := AsmHeader."Document Type"::Order;
        AsmHeader.Insert(true);
        AsmHeader.Validate("Due Date", DueDate);
        AsmHeader.Validate("Location Code", LocationCode);
        AsmHeader.Validate("Item No.", ParentItem."No.");
        AsmHeader.Validate(Quantity, Qty);
        AsmHeader.Modify(true);
        AsmHeader.Validate("Item No."); // setting qty above leads to creation of asm lines here.
        AsmHeader.Modify(true); // to clear the LinesAlreadyUpdated flag.
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    local procedure MockSKUWithLeadTime(Item: Record Item; var Location: Record Location; LeadTimeText: Text[30]; var VariantCode: Code[10])
    begin
        MockLocation(Location);
        VariantCode := MockSKU(Item, Location.Code, LeadTimeText, '');
    end;

    local procedure MockPurchOrder(ItemNo: Code[20]; Qty: Decimal; LocationCode: Code[10]; ExpectedRcptDate: Date)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', ItemNo, Qty, LocationCode, ExpectedRcptDate);
    end;

    local procedure GetDate(DateText: Text[31]; RefDate: Date): Date
    var
        DF: DateFormula;
    begin
        Evaluate(DF, '<' + DateText + '>');
        exit(CalcDate(DF, RefDate));
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MsgHandler(MsgText: Text)
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AssemblyAvailabilityCheckModalPageHandler(var AssemblyAvailability: TestPage "Assembly Availability Check")
    begin
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure RecallNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendNotificationHandler(var Notification: Notification): Boolean
    begin
    end;
}

