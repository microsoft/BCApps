// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Test;

using Microsoft.Manufacturing.Capacity;
using System.TestLibraries.Utilities;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Document;
using Microsoft.Inventory.Ledger;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Sales.Setup;
using Microsoft.Inventory.Journal;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.Journal;
using Microsoft.Manufacturing.Forecast;
using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.Routing;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Setup;
using Microsoft.Sales.Document;
using Microsoft.Manufacturing.Setup;
using Microsoft.Warehouse.Structure;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Location;
using Microsoft.Finance.Dimension;
using Microsoft.Inventory.Posting;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Transfer;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Warehouse.Request;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Inventory.Planning;
using Microsoft.Warehouse.Activity;
using Microsoft.Manufacturing.Reports;

codeunit 137404 "SCM Manufacturing"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Manufacturing] [SCM]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        CalendarAbsenceManagement: Codeunit "Calendar Absence Management";
        CalendarManagement: Codeunit "Shop Calendar Management";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryRandom: Codeunit "Library - Random";
        ProductionBOMCopy: Codeunit "Production BOM-Copy";
        DateChangeFormula: DateFormula;
        ExchangeNo: Code[20];
        ItemNo2: Code[20];
        LocationCode2: Code[10];
        ProductionForecastName2: Code[20];
        WithNo: Code[20];
        WorkCenterNo2: Code[20];
        CreateNewVersion: Boolean;
        DeleteExchangedComponent: Boolean;
        isInitialized: Boolean;
        BlankDeleteBeforeDateErr: Label 'You must enter the date to delete before.';
        CopyDocumentErr: Label 'Production Order was not copied successfully.';
        MustNotExistErr: Label '%1 must not exist.', Comment = '%1: Table caption "Production BOM Line".';
        ProductionBOMStatusErr: Label 'The maximum number of BOM levels, %1, was exceeded. The process stopped at item number %2, BOM header number %3, BOM level %4.', Comment = '%1 = Max. Level Value, %2 = Item No. Value, %3 = Bom Header No. Value, %4 = Level Value';
        StartingDateMustNotBeBlankErr: Label 'The Starting Date field must not be blank.';
        MustEnterStartingDateErr: Label 'You must enter a Starting Date.';
        MustFillStartingDateFieldErr: Label 'You must fill in the starting date field.';
        EndingTimeValidationErr: Label 'Validation error for Field: EndingTime,  Message = ''The ending time must be later than the starting time.''';
        UnknownErr: Label 'Unknown Error.';
        Capacity2: Decimal;
        GLB_ItemTrackingQty: Integer;
        GLB_SerialNo: Code[50];
        ItemTrackingMode: Option " ","Assign Lot No.","Select Entries","Update Quantity","Manual Lot No.";
        DocumentNoDoesNotExistErr: Label 'Document No. %1 does not exist.', Comment = '%1: Document number (Code)';
        ExpectedQuantityErr: Label 'Quantity must be %1.', Comment = '%1: Quantity (decimal value)';
        ModifyRtngErr: Label 'You cannot modify Routing No. %1 because there is at least one %2 associated with it.';
        DeleteRtngErr: Label 'You cannot delete Prod. Order Line %1 because there is at least one %2 associated with it.';
        CapLedgEntryTxt: Label 'Capacity Ledger Entry';
        ItemLedgEntryTxt: Label 'Item Ledger Entry';
        ReservationDateConflictTxt: Label 'The change causes a date conflict with an existing reservation';
        ReservDateConflictErr: Label 'The change leads to a date conflict with existing reservations.';
        ProdOrdRtngLnExistErr: Label 'Production Order Routing Lines exist, contrary to the expected result.';
        ProdOrdRtngLnWrongRoutingNoErr: Label 'Production Order Routing Lines were found with an incorrect Routing No.';
        ProdOrdRtngLnNotExistErr: Label 'Production Order Routing Lines do not exist, contrary to the expected result.';
        WorkShiftShouldExistErr: Label 'The work shift start from %1 with allocated time %2 on %3 should exist';
        WorkShiftShouldNotExistErr: Label 'The work shift for non-working day should not exist';
        ProdOrderStartingDateErr: Label 'The Production Order''s Starting Date is wrong with Forward refreshing when setup time ends at Midnight ';
        ProdOrderLineBinCodeErr: Label 'Wrong "Prod. Order Line" BinCode value';
        IsNotOnInventoryErr: Label 'You have insufficient quantity of Item %1 on inventory.';
        WrongDateTimeErr: Label 'Wrong %1 in Prod. Order Line.';
        ProdBOMVersionMustExistErr: Label '''Exchange Production BOM Item'' batch job must create one Production BOM Version';
        ProdBOMVersionMustNotExistErr: Label 'Production BOM Version must not have been created';
        StartingDateTimeErr: Label 'Starting Date-Time is incorrect';
        EndingDateTimeErr: Label 'Ending Date-Time is incorrect';
        EntryOfTypeNotFoundErr: Label 'Not found Item Ledger Entry of type %1', Comment = '%1 = Item Ledger Entry Type';
        CannotUnapplyItemLedgEntryErr: Label 'You cannot proceed with the posting as it will result in negative inventory';
        WrongNumberOfMessagesErr: Label 'Only one warning should be raised.';
        CannotDeleteItemIfProdBOMVersionExistsErr: Label 'You cannot delete %1 %2 because there are one or more certified production BOM version that include this item.', Comment = '%1 - Tablecaption, %2 - No.';
        WrongProdOrderLinesCountErr: Label 'Wrong number of production order lines created';
        DueDateEmptyErr: Label 'Due Date must have a value in Production Order';
        CircularRefInBOMErr: Label 'The production BOM %1 has a circular reference. Pay attention to the production BOM %2 that closes the loop.', Comment = '%1 = Production BOM No., %2 = Production BOM No.';
        ExpectedWhsePickMsg: Label 'Expected a Warehouse Pick Request associated with the Production Order Component Line, since the line has a positive remaining quantity';
        DidntExpectWhsePickMsg: Label 'Did not expect a Warehouse Pick Request associated with the Production Order Component Line, since the line doesn''t have a postitive remaining quantity';
        ProdOrderNoHandlerErr: Label 'Prod. Order No. must be %1, actual value is %2.', Comment = '%1: Expected Prod. Order No. Value; %2: Actual Prod. Order No. Value.';
        ProdOrderStatusHandlerErr: Label 'Prod. Order Status must be %1, actual value is %2.', Comment = '%1: Expected Prod. Order Status Value; %2: Actual Prod. Order Status Value.';
        ItemLedgerEntryMustBeFoundErr: Label 'Item Ledger Entry must be found.';
        ValueMustBeEqualErr: Label '%1 field value must be equal to %2 in %3', Comment = '%1 = Field Name, %2 = Expected Value, %3 = Page Name';
        CaptionMustBeEqualErr: Label '%1 caption must be equal to %2 in %3', Comment = '%1 = Field Caption, %2 = Expected Caption Name, %3 = Page Name';
        ActionMustBeVisibleErr: Label 'Action %1 must be visible in %2', Comment = ' %1 = Action Name , %2 = Page Name';
        PreviousSetLbl: Label 'Previous Set';
        NextSetLbl: Label 'Next Set';
        FieldMustNotBeVisibleErr: Label '%1 must not be visible in %2', Comment = ' %1 = Field Name , %2 = Page Name';

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,OutputJournalItemtrackingPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure OutputJournalApplyUnapply()
    var
        ProductionOrder: Record "Production Order";
        ItemLedgerEntryPositive: Record "Item Ledger Entry";
        ItemLedgerEntryNegative: Record "Item Ledger Entry";
        OutputQuantity: Integer;
        ExpectedILETxt: Label 'Expected ILE within filter %1 after posting/reverse posting to output journal',
            Comment = '%1: Table filters';
    begin
        // [FEATURE] [Item Tracking]
        // [GIVEN] Production Order with serial tracked item

        Initialize();
        OutputQuantity := LibraryRandom.RandInt(6);
        CreateReleasedProductionOrder(ProductionOrder);
        SetQuantity(ProductionOrder, OutputQuantity);
        SetItemTrackingCodeSerialSpecific(ProductionOrder."Source No.");

        // [WHEN] Post- and reverse posting in Output Journal
        PostOutputJournalWithIT(ProductionOrder, OutputQuantity);
        PostOutputJournalWithIT(ProductionOrder, -OutputQuantity);
        PostOutputJournalWithIT(ProductionOrder, OutputQuantity);
        PostOutputJournalWithIT(ProductionOrder, -OutputQuantity);

        // [THEN] Correct number of positive Item Ledger Entries from posting
        VerifyILEs(ItemLedgerEntryPositive, ProductionOrder."Source No.", 1, '=0', OutputQuantity * 2);

        // [THEN] Correct number of negative Item Ledger Entries from reverse posting
        VerifyILEs(ItemLedgerEntryPositive, ProductionOrder."Source No.", -1, '<>0', OutputQuantity * 2);

        repeat
            // [THEN] Positive ILE has negative one applied to it
            ItemLedgerEntryNegative.SetRange("Serial No.", ItemLedgerEntryPositive."Serial No.");
            ItemLedgerEntryNegative.SetRange("Applies-to Entry", ItemLedgerEntryPositive."Entry No.");
            Assert.IsTrue(ItemLedgerEntryNegative.IsEmpty,
              StrSubstNo(ExpectedILETxt, ItemLedgerEntryNegative.GetFilters()));
        until ItemLedgerEntryPositive.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('CopyProductionOrderDocumentHandler')]
    [Scope('OnPrem')]
    procedure CopyPlannedProductionOrder()
    var
        ProductionOrder: Record "Production Order";
    begin
        // [FEATURE] [Copy Production Order]
        // [SCENARIO] Verify that a Planned Production Order can be copied into a Released Production Order.
        Initialize();
        CopyProductionOrder(ProductionOrder.Status::Planned);
    end;

    [Test]
    [HandlerFunctions('CopyProductionOrderDocumentHandler')]
    [Scope('OnPrem')]
    procedure CopyFirmPlannedProductionOrder()
    var
        ProductionOrder: Record "Production Order";
    begin
        // [FEATURE] [Copy Production Order]
        // [SCENARIO] Verify that a Firm Planned Production Order can be copied into a Released Production Order.
        Initialize();
        CopyProductionOrder(ProductionOrder.Status::"Firm Planned");
    end;

    [Test]
    [HandlerFunctions('CopyProductionOrderDocumentHandler')]
    [Scope('OnPrem')]
    procedure CopyReleasedProductionOrder()
    var
        ProductionOrder: Record "Production Order";
    begin
        // [FEATURE] [Copy Production Order]
        // [SCENARIO] Verify that a Released Production Order can be copied into a Released Production Order.
        Initialize();
        CopyProductionOrder(ProductionOrder.Status::Released);
    end;

    local procedure CopyProductionOrder(Status: Enum "Production Order Status")
    var
        ProductionOrder: Record "Production Order";
        NewProductionOrder: Record "Production Order";
        NoOfRowsBeforeCopy: Integer;
    begin
        // Setup: Create a Production Order and create a Released Production Order in which previous Production Order is to be copied.
        CreateAndRefreshProductionOrder(ProductionOrder, Status);
        NoOfRowsBeforeCopy := CreateReleasedProductionOrder(NewProductionOrder);

        // Exercise: Run Copy Production Order and Copy previously created Production Order into Released Production Order.
        RunCopyProductionDocument(ProductionOrder.Status, ProductionOrder."No.", NewProductionOrder);

        // Verify: Verify that No. of rows in the Released Production Order Lines gets increased.
        VerifyProdOrderLinesIncreaseAfterCopy(NewProductionOrder, NoOfRowsBeforeCopy);
    end;

    [Test]
    [HandlerFunctions('CopyProductionOrderDocumentHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure CopyFinishedProductionOrder()
    var
        ProductionOrder: Record "Production Order";
        NewProductionOrder: Record "Production Order";
        NoOfRowsBeforeCopy: Integer;
    begin
        // [FEATURE] [Copy Production Order]
        // [SCENARIO] Verify that a Finished Production Order can be copied into a Released Production Order.

        // [GIVEN] Create a Finished Production Order and create a Released Production Order in which Finished Production Order is to be copied.
        Initialize();
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released);
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");
        NoOfRowsBeforeCopy := CreateReleasedProductionOrder(NewProductionOrder);

        // [WHEN] Run Copy Production Order and Copy Finished Production Order.
        RunCopyProductionDocument(ProductionOrder.Status::Finished, ProductionOrder."No.", NewProductionOrder);

        // [THEN] Verify that No. of rows in the Released Production Order Lines gets increased.
        VerifyProdOrderLinesIncreaseAfterCopy(NewProductionOrder, NoOfRowsBeforeCopy);
    end;

    [Test]
    [HandlerFunctions('ImplementRegisteredAbsenceHandler')]
    [Scope('OnPrem')]
    procedure ImplementRegisteredAbsenceReport()
    var
        RegisteredAbsence: Record "Registered Absence";
        WorkCenter: Record "Work Center";
    begin
        // [FEATURE] [Capacity] [Absence]
        // [SCENARIO] Check the functionality of Report Implement Registered Absence.

        // [GIVEN] Create Work Center Group, Work Center and Registered Absence for the new Work Center.
        Initialize();
        CreateWorkCenterWithWorkCenterGroup(WorkCenter, '');
        LibraryManufacturing.CreateRegisteredAbsence(
          RegisteredAbsence, RegisteredAbsence."Capacity Type"::"Work Center", WorkCenter."No.", WorkDate(), GetRoundedTime(WorkDate()),
          GetRoundedTime(WorkDate()));
        RegisteredAbsence.Validate(Capacity, LibraryRandom.RandDec(10, 2));  // Taking Random value for Capacity.
        RegisteredAbsence.Modify(true);

        // [WHEN] Run the Report Implement Registered Absence using the Handler.
        RunImplementRegisteredAbsenceReport(RegisteredAbsence);

        // [THEN] Verify that the Calendar Absence entry gets created for the new Work Center.
        VerifyCalendarAbsenceEntry(WorkCenter."No.", RegisteredAbsence);
    end;

    [Test]
    [HandlerFunctions('OptionDialog')]
    [Scope('OnPrem')]
    procedure ItemReclassJournal()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        ItemJournalLine: Record "Item Journal Line";
        ItemNo: Code[20];
        ComponentNo: Code[20];
        ItemQuantity: Decimal;
        ComponentQuantity: Decimal;
        OldStockoutWarning: Boolean;
        OldCreditWarnings: Option;
    begin
        // [FEATURE] [Production BOM] [Item Reclassification]
        // [SCENARIO] Test Explode BOM functionality on Item Reclass Journal.

        // [GIVEN] Update Sales and Receivable Setup. Create Item and Component. Create BOM Component.
        Initialize();
        UpdateSalesReceivableSetup(OldCreditWarnings, OldStockoutWarning, SalesReceivablesSetup."Credit Warnings"::"No Warning", false);
        CreateItemAndItemComponent(ItemNo, ComponentNo);
        SetItemAndComponentQuantity(ItemQuantity, ComponentQuantity);
        CreateBOMComponent(ItemNo, ComponentNo, ComponentQuantity);

        // [WHEN] Create Item Reclass Journal Line and perform Explode BOM functionality.
        CreateItemReclassJournalLine(ItemJournalLine, ItemNo, ItemQuantity);
        CODEUNIT.Run(CODEUNIT::"Item Jnl.-Explode BOM", ItemJournalLine);

        // [THEN] Verify data on Item Reclass Journal.
        VerifyComponentOnItemReclassJournal(ComponentNo, ItemQuantity * ComponentQuantity);

        // Teardown: Rollback Sales and Receivable Setup.
        UpdateSalesReceivableSetup(OldCreditWarnings, OldStockoutWarning, OldCreditWarnings, OldStockoutWarning);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WorkCenterAbsenceUpdate()
    var
        CalendarAbsenceEntry: Record "Calendar Absence Entry";
        WorkCenter: Record "Work Center";
    begin
        // [FEATURE] [Capacity] [Absence]
        // [SCENARIO] Updated field should become True when we perform Update action on Absence entry invoked by Work Center.

        // [GIVEN] Create a Work Center with new Work Center Group and a Calendar Absence entry for the new Work Center taking Random value for Capacity.
        Initialize();
        CreateWorkCenterWithWorkCenterGroup(WorkCenter, '');

        // Generating Random value for StartingTime and EndingTime as their value is not important for the test.Taking Random value for Capacity.
        LibraryManufacturing.CreateCalendarAbsenceEntry(
          CalendarAbsenceEntry, CalendarAbsenceEntry."Capacity Type"::"Work Center", WorkCenter."No.", WorkDate(), Time, Time,
          LibraryRandom.RandDec(10, 2));

        // [WHEN] Perform action Update for the Calendar Absence entry created.
        CalendarAbsenceManagement.UpdateAbsence(CalendarAbsenceEntry);

        // [THEN] Verify that the Updated field becomes True in the Calendar Absence entry.
        CalendarAbsenceEntry.TestField(Updated, true);
    end;

    [Test]
    [HandlerFunctions('RecalculateCalendarReportHandler')]
    [Scope('OnPrem')]
    procedure RecalculateWorkCenterCalendarWithAbsence()
    var
        CalendarEntry: Record "Calendar Entry";
        CalendarAbsenceEntry: Record "Calendar Absence Entry";
        ShopCalendarWorkingDays: Record "Shop Calendar Working Days";
        WorkCenter: Record "Work Center";
        ExpectedCapacityTotal: Decimal;
    begin
        // [FEATURE] [Capacity] [Absence]
        // [SCENARIO] Verify Capacity(Total) field on Calendar entry after recalculating Work Center Calendar with Absence entry.

        // [GIVEN] Create a Shop Calendar, a Work Center and an Absence entry for the Work Center.
        Initialize();
        CreateWorkCenterWithWorkCenterGroup(WorkCenter, CreateShopCalendarCodeWithAllDaysWorking(ShopCalendarWorkingDays));
        LibraryManufacturing.CreateCalendarAbsenceEntry(
          CalendarAbsenceEntry, CalendarAbsenceEntry."Capacity Type"::"Work Center", WorkCenter."No.", WorkDate(),
          ShopCalendarWorkingDays."Starting Time",
          ShopCalendarWorkingDays."Ending Time", LibraryRandom.RandDec(10, 2));  // Taking Random value for Capacity.
        CalendarAbsenceManagement.UpdateAbsence(CalendarAbsenceEntry);

        // [GIVEN] Update the new Work Center with important values and Calculate the Work Center Calendar.
        ModifyWorkCenterAndCalculateCalendar(WorkCenter, CalendarAbsenceEntry.Capacity);

        // [WHEN] Run Report Recalculate Calendar.
        ExpectedCapacityTotal :=
          ((ShopCalendarWorkingDays."Ending Time" - ShopCalendarWorkingDays."Starting Time") /
           CalendarManagement.TimeFactor(WorkCenter."Unit of Measure Code")) * (WorkCenter.Capacity - CalendarAbsenceEntry.Capacity);
        GetCalendarEntry(CalendarEntry, CalendarEntry."Capacity Type"::"Work Center", WorkCenter."No.");
        RunRecalculateCalendarReport(CalendarEntry);

        // [THEN] Verify the value of Capacity(Total) on Calendar entry.
        VerifyCalendarEntry(WorkCenter."No.", ExpectedCapacityTotal);
    end;

    [Test]
    [HandlerFunctions('RecalculateCalendarReportHandler')]
    [Scope('OnPrem')]
    procedure RecalculateWorkCenterCalendarWithNullStaringTimeInAbsence()
    var
        CalendarEntry: Record "Calendar Entry";
        CalendarAbsenceEntry: Record "Calendar Absence Entry";
        CalendarAbsenceEntry2: Record "Calendar Absence Entry";
        ShopCalendarWorkingDays: Record "Shop Calendar Working Days";
        WorkCenter: Record "Work Center";
        ExpectedCapacityTotal: Decimal;
    begin
        // [FEATURE] [Capacity] [Absence]
        // [SCENARIO] Verify that Capacity(Total) on Calendar entry is calculated based on Absence entry having Starting and Ending Time and it ignores the Absence entry where Starting Time is null.

        // [GIVEN] Create a Shop Calendar, a Work Center and two Absence entries for the Work Center.
        Initialize();
        CreateWorkCenterWithWorkCenterGroup(WorkCenter, CreateShopCalendarCodeWithAllDaysWorking(ShopCalendarWorkingDays));
        LibraryManufacturing.CreateCalendarAbsenceEntry(
          CalendarAbsenceEntry, CalendarAbsenceEntry."Capacity Type"::"Work Center", WorkCenter."No.", WorkDate(),
          ShopCalendarWorkingDays."Starting Time", ShopCalendarWorkingDays."Ending Time",
          LibraryRandom.RandDec(10, 2));  // Taking Random value for Capacity.
        LibraryManufacturing.CreateCalendarAbsenceEntry(
          CalendarAbsenceEntry2, CalendarAbsenceEntry."Capacity Type"::"Work Center", WorkCenter."No.", WorkDate(), 0T,
          ShopCalendarWorkingDays."Ending Time",
          LibraryRandom.RandDec(10, 2));  // Taking Random value for Capacity.

        // [GIVEN] Calculate the Work Center Calendar.
        ModifyWorkCenterAndCalculateCalendar(WorkCenter, CalendarAbsenceEntry.Capacity);
        ExpectedCapacityTotal :=
          ((ShopCalendarWorkingDays."Ending Time" - ShopCalendarWorkingDays."Starting Time") /
           CalendarManagement.TimeFactor(WorkCenter."Unit of Measure Code")) * (WorkCenter.Capacity - CalendarAbsenceEntry.Capacity);

        // [WHEN] Run Report Recalculate Calendar.
        GetCalendarEntry(CalendarEntry, CalendarEntry."Capacity Type"::"Work Center", WorkCenter."No.");
        RunRecalculateCalendarReport(CalendarEntry);

        // [THEN] Verify the value of Capacity(Total) on Calendar entry.
        VerifyCalendarEntry(WorkCenter."No.", ExpectedCapacityTotal);
    end;

    [Test]
    [HandlerFunctions('RegAbsFromWorkCenterReportHandler')]
    [Scope('OnPrem')]
    procedure RegisteredAbsenceFromWorkCenterReportWithBlankData()
    var
        RegAbsFromWorkCenter: Report "Reg. Abs. (from Work Center)";
    begin
        // [FEATURE] [Capacity] [Absence]
        // [SCENARIO] Error message should be generated when Registered Absence From Work Center Report is run with blank data.

        // [GIVEN] Set ShowError as True so that it does not enters data in the Handler.
        Initialize();
        LibraryVariableStorage.Enqueue(true);  // ShowError := true;

        // [WHEN] Run the Registered Absence From Work Center Report with blank data and catch the Error.
        Commit();
        Clear(RegAbsFromWorkCenter);
        asserterror RegAbsFromWorkCenter.Run();

        // [THEN] Verify the error message.
        Assert.AreEqual(StrSubstNo(StartingDateMustNotBeBlankErr), GetLastErrorText, UnknownErr);
    end;

    [Test]
    [HandlerFunctions('RegAbsFromWorkCenterReportHandler')]
    [Scope('OnPrem')]
    procedure RegisteredAbsenceFromWorkCenterReportWithOverwriteFalse()
    var
        WorkCenter: Record "Work Center";
        CapacityValue: Decimal;
        Capacity: Decimal;
        Date: Date;
    begin
        // [FEATURE] [Capacity] [Absence]
        // [SCENARIO] Registered Absence should not get overwritten when Registered Absence From Work Center Report is run with Overwrite = False.

        // [GIVEN] Create a Work Center with Work Center Group and create a Registered Absence.
        Initialize();
        CreateWorkCenterWithWorkCenterGroup(WorkCenter, '');

        // These variables are made Global as they are used in the Handler and CreateRegisteredAbsence helper method.
        LibraryVariableStorage.Enqueue(false);  // ShowError = false
        LibraryVariableStorage.Enqueue(false);  // OverWrite := false;
        Date := CalcDate('<' + Format(LibraryRandom.RandInt(-10)) + 'D>', WorkDate());
        Capacity := CreateRegisteredAbsenceAndEnqueueTime(WorkCenter, Date);
        CapacityValue := LibraryRandom.RandDec(10, 2);  // Taking Random value for Capacity.
        LibraryVariableStorage.Enqueue(CapacityValue);

        // [WHEN] Run Registered Absence From Work Center Report with Overwrite as False.
        RunRegAbsFromWorkCenterReport(WorkCenter."No.");

        // [THEN] Verify that the previous Registered Absence does not gets Overwritten with the new Absence created by running the Report.
        VerifyEntryInRegisteredAbsence(WorkCenter."No.", Date, Capacity);
        VerifyEntryInRegisteredAbsence(WorkCenter."No.", WorkDate(), CapacityValue);
    end;

    [Test]
    [HandlerFunctions('RegAbsFromWorkCenterReportHandler')]
    [Scope('OnPrem')]
    procedure RegisteredAbsenceFromWorkCenterReportWithOverwriteTrue()
    var
        WorkCenter: Record "Work Center";
        CapacityValue: Decimal;
        Date: Date;
    begin
        // [FEATURE] [Capacity] [Absence]
        // [SCENARIO] Registered Absence should get overwritten when Registered Absence From Work Center Report is run with Overwrite = True.

        // [GIVEN] Create a Work Center with Work Center Group and create a Registered Absence.
        Initialize();
        CreateWorkCenterWithWorkCenterGroup(WorkCenter, '');

        // These variables are made Global as they are used in the Handler and CreateRegisteredAbsence helper method.
        LibraryVariableStorage.Enqueue(false);  // ShowError = false
        LibraryVariableStorage.Enqueue(true);   // OverWrite := true;

        Date := CalcDate('<' + Format(LibraryRandom.RandInt(-10)) + 'D>', WorkDate());
        CreateRegisteredAbsenceAndEnqueueTime(WorkCenter, Date);
        CapacityValue := LibraryRandom.RandDec(10, 2);  // Taking Random value for Capacity.
        LibraryVariableStorage.Enqueue(CapacityValue);

        // [WHEN] Run Registered Absence From Work Center Report with Overwrite as True.
        RunRegAbsFromWorkCenterReport(WorkCenter."No.");

        // [THEN] Verify that the previous Registered Absence gets Overwritten with the new Absence created by running the Report.
        VerifyEntryInRegisteredAbsence(WorkCenter."No.", WorkDate(), CapacityValue);
    end;

    [Test]
    [HandlerFunctions('RegAbsFromMachineCenterEndingTimeErrorReportHandler')]
    [Scope('OnPrem')]
    procedure RegisteredAbsenceFromMachineCenterReportWithStartingDateError()
    var
        RegAbsFromMachineCtr: Report "Reg. Abs. (from Machine Ctr.)";
    begin
        // [FEATURE] [Capacity] [Absence]
        // [SCENARIO] Error message should be generated when Registered Absence From Machine Center Report is run with blank Starting Date.

        // [GIVEN] Set ShowError as True so that it does not enters data in the Handler.
        Initialize();
        LibraryVariableStorage.Enqueue(true);  // ShowError := true;

        // [WHEN] Run the Registered Absence From Machine Center report with blank data and catch the Error.
        Commit();
        Clear(RegAbsFromMachineCtr);
        asserterror RegAbsFromMachineCtr.Run();

        // [THEN] Verify the error message.
        Assert.AreEqual(StrSubstNo(StartingDateMustNotBeBlankErr), GetLastErrorText, UnknownErr);
    end;

    [Test]
    [HandlerFunctions('RegAbsFromMachineCenterEndingTimeErrorReportHandler')]
    [Scope('OnPrem')]
    procedure RegisteredAbsenceFromMachineCenterReportWithTimeError()
    var
        WorkCenter: Record "Work Center";
        RegAbsFromMachineCtr: Report "Reg. Abs. (from Machine Ctr.)";
        StartingTime: Time;
        EndingTime: Time;
    begin
        // [FEATURE] [Capacity] [Absence]
        // [SCENARIO] Error message should be generated when Registered Absence From Machine Center Report is run with Starting Time later than the Ending Time.

        // [GIVEN] Create a Work Center with Work Center Group. Set EndingTimeError as True so that it does not enters other values besides Times in the handler. Set Ending Time and Starting Time.
        Initialize();
        LibraryVariableStorage.Enqueue(false);  // ShowError := false;
        WorkCenter.Init();  // Required to initialize the Variable.
        EndingTime := CalculateRandomTime();
        StartingTime := CalculateEndingTime(WorkCenter, EndingTime + 10000);  // StartingTime must be Greater than EndingTime to Generate the Error.

        LibraryVariableStorage.Enqueue(StartingTime);
        LibraryVariableStorage.Enqueue(EndingTime);

        // [WHEN] Run the Registered Absence From Machine Center report and catch the Error.
        Commit();
        Clear(RegAbsFromMachineCtr);
        asserterror RegAbsFromMachineCtr.Run();

        // [THEN] Verify the error message.
        Assert.AreEqual(StrSubstNo(EndingTimeValidationErr), GetLastErrorText, UnknownErr);
    end;

    [Test]
    [HandlerFunctions('RegAbsFromMachineCenterReportHandler')]
    [Scope('OnPrem')]
    procedure RegisteredAbsenceFromMachineCenterReportWithOverwriteFalse()
    var
        WorkCenter: Record "Work Center";
        MachineCenterNo: Code[20];
        CapacityValue: Decimal;
        Capacity: Decimal;
        Date: Date;
    begin
        // [FEATURE] [Capacity] [Absence]
        // [SCENARIO] Registered Absence should not get overwritten when Registered Absence From Machine Center Report is run with Overwrite = False.

        // [GIVEN] Create a Machine Center with Work Center Group and create a Registered Absence.
        Initialize();
        CreateWorkCenterWithWorkCenterGroup(WorkCenter, '');
        MachineCenterNo := CreateMachineCenter(WorkCenter."No.");

        // These variables are made Global as they are used in the Handler and CreateRegisteredAbsence helper method.
        LibraryVariableStorage.Enqueue(false);  // ShowError = false
        Date := CalcDate('<' + Format(LibraryRandom.RandInt(-10)) + 'D>', WorkDate());
        Capacity := CreateMachineCenterRegAbsenceAndEnqueueTime(WorkCenter, MachineCenterNo, Date);
        CapacityValue := LibraryRandom.RandDec(10, 2);  // Taking Random value for Capacity.
        LibraryVariableStorage.Enqueue(CapacityValue);
        LibraryVariableStorage.Enqueue(false);  // OverWrite := false;

        // [WHEN] Run Registered Absence From Machine Center Report with Overwrite as False.
        RunRegAbsFromMachineCenterReport(MachineCenterNo);

        // [THEN] Verify that the previous Registered Absence does not gets Overwritten with the new Absence created by running the Report.
        VerifyEntryInRegisteredAbsence(MachineCenterNo, Date, Capacity);
        VerifyEntryInRegisteredAbsence(MachineCenterNo, WorkDate(), CapacityValue);
    end;

    [Test]
    [HandlerFunctions('RegAbsFromMachineCenterReportHandler')]
    [Scope('OnPrem')]
    procedure RegisteredAbsenceFromMachineCenterReportWithOverwriteTrue()
    var
        WorkCenter: Record "Work Center";
        MachineCenterNo: Code[20];
        CapacityValue: Decimal;
        Date: Date;
    begin
        // [FEATURE] [Capacity] [Absence]
        // [SCENARIO] Registered Absence should get overwritten when Registered Absence From Machine Center Report is run with Overwrite = True.

        // [GIVEN] Create a Machine Center with Work Center Group and create a Registered Absence.
        Initialize();
        CreateWorkCenterWithWorkCenterGroup(WorkCenter, '');
        MachineCenterNo := CreateMachineCenter(WorkCenter."No.");

        // These variables are made Global as they are used in the Handler and CreateRegisteredAbsence helper method.
        LibraryVariableStorage.Enqueue(false);  // ShowError = false
        Date := CalcDate('<' + Format(LibraryRandom.RandInt(-10)) + 'D>', WorkDate());
        CreateMachineCenterRegAbsenceAndEnqueueTime(WorkCenter, MachineCenterNo, Date);
        CapacityValue := LibraryRandom.RandDec(10, 2);  // Taking Random value for Capacity.
        LibraryVariableStorage.Enqueue(CapacityValue);
        LibraryVariableStorage.Enqueue(true);   // OverWrite := true;

        // [WHEN] Run Registered Absence From Machine Center Report with Overwrite as True.
        RunRegAbsFromMachineCenterReport(MachineCenterNo);

        // [THEN] Verify that the previous Registered Absence gets Overwritten with the new Absence created by running the Report.
        VerifyEntryInRegisteredAbsence(MachineCenterNo, WorkDate(), CapacityValue);
    end;

    [Test]
    [HandlerFunctions('RecalculateCalendarReportHandler')]
    [Scope('OnPrem')]
    procedure RecalculateMachineCenterCalendarReport()
    var
        CalendarEntry: Record "Calendar Entry";
        MachineCenter: Record "Machine Center";
        ShopCalendar: Record "Shop Calendar";
        WorkCenter: Record "Work Center";
        Capacity: Decimal;
        ExpectedCapacityTotal: Decimal;
    begin
        // [FEATURE] [Capacity] [Shop Calendar]
        // [SCENARIO] Check the functionality of Recalculate Calendar for Machine Center.

        // [GIVEN] Create a Work Center and Machine Center. Calculate Calendar for Machine Center and modify the Capacity value for it.
        Initialize();
        ShopCalendar.FindFirst();
        CreateWorkCenterWithWorkCenterGroup(WorkCenter, ShopCalendar.Code);
        MachineCenter.Get(CreateMachineCenter(WorkCenter."No."));
        Capacity := ModifyCapacityOfMachineCenter(MachineCenter."No.");
        LibraryManufacturing.CalculateMachCenterCalendar(
          MachineCenter, WorkDate(), CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'Y>', WorkDate()));

        // [WHEN] Run Report Recalculate Calendar for the new Machine Center.
        GetCalendarEntry(CalendarEntry, CalendarEntry."Capacity Type"::"Machine Center", MachineCenter."No.");

        // Capacity(Total) is the multiplication of Capacity with the Shift Time.
        ExpectedCapacityTotal :=
          ((CalendarEntry."Ending Time" - CalendarEntry."Starting Time") /
           CalendarManagement.TimeFactor(WorkCenter."Unit of Measure Code")) * Capacity;
        RunRecalculateCalendarReport(CalendarEntry);

        // [THEN] Verify that Recalculate Calendar report updates the Calandar Entry according to the modified Capacity value.
        GetCalendarEntry(CalendarEntry, CalendarEntry."Capacity Type"::"Machine Center", MachineCenter."No.");
        CalendarEntry.TestField("Capacity (Total)", ExpectedCapacityTotal);
    end;

    [Test]
    [HandlerFunctions('WorkCenterCalendarMatrixHandler')]
    [Scope('OnPrem')]
    procedure CalculatedCapacityOnWorkCenterCalendarMatrix()
    var
        WorkCenter: Record "Work Center";
        ShopCalendarWorkingDays: Record "Shop Calendar Working Days";
    begin
        // [FEATURE] [Capacity]
        // [SCENARIO] Test and Verify Calculated Capacity on Work Center Calendar Matrix Page.

        // [GIVEN] Create Work Center with Work Center Group.
        Initialize();
        CreateWorkCenterWithWorkCenterGroup(WorkCenter, CreateShopCalendarCodeWithAllDaysWorking(ShopCalendarWorkingDays));

        // [WHEN] Calculate Work Center Calendar.
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, WorkDate(), WorkDate());
        WorkCenterNo2 := WorkCenter."No.";  // Use WorkCenterNo2 as global for Handler.

        // [THEN] Verify Calculated Capacity on WorkCenterCalendarMatrixHandler function and verification is done in Handler.
        VerifyCalculatedCapacity();
    end;

    [Test]
    [HandlerFunctions('ProductionJournalHandler,ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure ExpectedCapacityNeedOnProductionOrderStatistics()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        ProductionJournalMgt: Codeunit "Production Journal Mgt";
    begin
        // [FEATURE] [Capacity]
        // [SCENARIO] Test and Verify Expected Capacity Need on Production Order Statistics.

        // [GIVEN] Create Initial Setup for Released Production Order.
        Initialize();
        CreateInitialSetupForReleasedProductionOrder(ProductionOrder, ProdOrderComponent);

        // [WHEN] Open and post Production Journal. Posting is done in ProductionJournalHandler function.
        ProductionJournalMgt.Handling(ProductionOrder, ProdOrderComponent."Prod. Order Line No.");

        // [THEN] Verify Expected Capacity Need on Production Order Statistics.
        VerifyProductionOrderStatistics(ProductionOrder."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhsePickRequestUpdatedOnUpdatingProdOrderCompLine()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // [FEATURE] [Warehouse Pick Request] 
        // [SCENARIO] Verify that WhsePickRequest gets deleted and recreated when "Remaining Quantity" on the ProdOrderCompLine changes between 0 and positive values

        // [GIVEN] Released Production Order with location code set to a location that requires pick
        Initialize();
        CreateProdOrderCompLineWithLocationRequirePick(ProductionOrder, ProdOrderComponent);

        // Set positive remaining qty and verify that whse pick request exists
        VerifyWhsePickRequestOnPositiveRemQty(ProductionOrder, ProdOrderComponent);

        // Set 0 remaining qty and check that request is deleted
        VerifyNoWhsePickRequestOnZeroRemQty(ProductionOrder, ProdOrderComponent);

        // Set positive remaining qty again and verify that whse pick exists again
        VerifyWhsePickRequestOnPositiveRemQty(ProductionOrder, ProdOrderComponent);
    end;

    [Test]
    [HandlerFunctions('ProductionJournalHandler,ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure ConsumptionPostedByProductionJournal()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ProductionJournalMgt: Codeunit "Production Journal Mgt";
    begin
        // [FEATURE] [Production Journal]
        // [SCENARIO] Test and Verify Consumption posted by Production Journal.

        // [GIVEN] Create Initial Setup for Released Production Order.
        Initialize();
        CreateInitialSetupForReleasedProductionOrder(ProductionOrder, ProdOrderComponent);

        // [WHEN] Open and post Production Journal. Posting is done in ProductionJournalHandler function.
        ProductionJournalMgt.Handling(ProductionOrder, ProdOrderComponent."Prod. Order Line No.");

        // [THEN] Verify Consumption Entry on Item Ledger.
        VerifyItemLedgerEntry(
          ProdOrderComponent."Item No.", ItemLedgerEntry."Entry Type"::Consumption, -ProdOrderComponent."Expected Quantity");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CapacityLedgerEntryAfterPostingCapacityJournal()
    var
        ShopCalendarWorkingDays: Record "Shop Calendar Working Days";
        WorkCenter: Record "Work Center";
        Quantity: Decimal;
    begin
        // [FEATURE] [Capacity] [Capacity Journal]
        // [SCENARIO] Verify Capacity Ledger Entry after posting Capacity Journal Line.

        // [GIVEN] Create Work Center with Work Center Group.
        Initialize();
        CreateWorkCenterWithWorkCenterGroup(WorkCenter, CreateShopCalendarCodeWithAllDaysWorking(ShopCalendarWorkingDays));
        Quantity := LibraryRandom.RandInt(5); // Use random value for Quantity.

        // [WHEN] Create and post Capacity Journal.
        CreateAndPostCapacityJournal(Quantity, WorkCenter."No.");

        // [THEN] Verify Capacity Ledger Entry.
        VerifyCapacityLedgerEntry(WorkCenter."No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('CopyProductionForecastHandler')]
    [Scope('OnPrem')]
    procedure CopyProductionForecastNameWithBlankDescription()
    var
        ProductionForecastEntry: Record "Production Forecast Entry";
    begin
        // [FEATURE] [Production Forecast]
        // [SCENARIO] Test and verify functionality of Copy Production Forecast report with blank Production Forecast Name.

        Initialize();

        // [WHEN] Run Copy Production Forecast report with blank Production Forecast Name.
        // [THEN] Error is thrown because blank production forecast name is not allowed.
        asserterror RunCopyProductionForecast(ProductionForecastEntry);

        // [THEN] Verify that new lines are not created with blank demand forecast name.
        ProductionForecastEntry.SetRange("Production Forecast Name", '');
        Assert.RecordCount(ProductionForecastEntry, 0);
    end;

    [Test]
    [HandlerFunctions('CopyProductionForecastHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure CopyProductionForecastEntry()
    var
        ProductionForecastName: Record "Production Forecast Name";
        ProductionForecastEntry: Record "Production Forecast Entry";
    begin
        // [FEATURE] [Production Forecast]
        // [SCENARIO] Test and verify functionality of Copy Production Forecast report with Production Forecast Entry.

        // [GIVEN] Create Production Forecast Name and Production Forecast Entry.
        Initialize();
        LibraryManufacturing.CreateProductionForecastName(ProductionForecastName);
        CreateProductionForecastEntry(ProductionForecastEntry, ProductionForecastName.Name);
        LibraryManufacturing.CreateProductionForecastName(ProductionForecastName);
        ProductionForecastName2 := ProductionForecastName.Name;  // Use ProductionForecastName2 as global for handler.
        ItemNo2 := ProductionForecastEntry."Item No.";  // Use ItemNo2 as global for handler.
        LocationCode2 := ProductionForecastEntry."Location Code";  // Use LocationCode2 as global for handler.
        Evaluate(DateChangeFormula, '<' + Format(LibraryRandom.RandInt(5)) + 'D>');  // Use DateChangeFormula as global for handler and taking random value.

        // [WHEN] Run Copy Production Forecast report.
        ProductionForecastEntry.SetRange("Production Forecast Name", ProductionForecastEntry."Production Forecast Name");
        RunCopyProductionForecast(ProductionForecastEntry);

        // [THEN] Verify Production Forecast Entry must be copied.
        VerifyProductionForecastEntry(ProductionForecastEntry);
    end;

    [Test]
    [HandlerFunctions('CopyProductionForecastHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure CopyProductionForecastEntryWithItemVariantCode()
    var
        ProductionForecastName: Record "Production Forecast Name";
        ProductionForecastEntry: Record "Production Forecast Entry";
        ItemVariant: Record "Item Variant";
        Item2: Record Item;
    begin
        // [FEATURE] [Production Forecast]
        // [SCENARIO] Test and verify functionality of Copy Production Forecast report with Production Forecast Entry where 'Variant Code' is defined.

        // [GIVEN] Create Production Forecast Name and Production Forecast Entry where 'Variant Code' for the item is set.
        Initialize();
        LibraryManufacturing.CreateProductionForecastName(ProductionForecastName);
        CreateProductionForecastEntry(ProductionForecastEntry, ProductionForecastName.Name);
        LibraryInventory.CreateItemVariant(ItemVariant, ProductionForecastEntry."Item No.");
        ProductionForecastEntry.Validate("Variant Code", ItemVariant.Code);
        ProductionForecastEntry.Modify(true);

        LibraryManufacturing.CreateProductionForecastName(ProductionForecastName);
        ProductionForecastName2 := ProductionForecastName.Name;  // Use ProductionForecastName2 as global for handler.
        ItemNo2 := ProductionForecastEntry."Item No.";  // Use ItemNo2 as global for handler.
        LocationCode2 := ProductionForecastEntry."Location Code";  // Use LocationCode2 as global for handler.
        Evaluate(DateChangeFormula, '<' + Format(LibraryRandom.RandInt(5)) + 'D>');  // Use DateChangeFormula as global for handler and taking random value.

        // [WHEN] Run Copy Production Forecast report.
        ProductionForecastEntry.SetRange("Production Forecast Name", ProductionForecastEntry."Production Forecast Name");
        RunCopyProductionForecast(ProductionForecastEntry);

        // [THEN] Verify Production Forecast Entry must be copied.
        VerifyProductionForecastEntry(ProductionForecastEntry);

        // [WHEN] Run Copy Production Forecast report for the 2nd item with no variants.
        LibraryInventory.CreateItem(Item2);
        ItemNo2 := Item2."No.";
        RunCopyProductionForecast(ProductionForecastEntry);

        // [THEN] Production Forecast Entry should not contain the 2nd item with the variant code.
        ProductionForecastEntry.Reset();
        ProductionForecastEntry.SetRange("Production Forecast Name", ProductionForecastName2);
        ProductionForecastEntry.SetRange("Item No.", Item2."No.");
        ProductionForecastEntry.SetRange("Variant Code", ItemVariant.Code);
        Assert.RecordCount(ProductionForecastEntry, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandForecastEntriesEditabilityTest()
    var
        ProductionForecastName: Record "Production Forecast Name";
        DemandForecastEntries: TestPage "Demand Forecast Entries";
        DemandForecastNames: TestPage "Demand Forecast Names";
    begin
        // [FEATURE] [Production Forecast]
        // [SCENARIO] Test and verify Demand Forecast Entries page.

        // [GIVEN] Create Production Forecast Name.
        Initialize();
        LibraryManufacturing.CreateProductionForecastName(ProductionForecastName);

        // [GIVEN] Open DemandForecastNames page.
        DemandForecastNames.OpenView();
        DemandForecastNames.GoToRecord(ProductionForecastName);

        // [WHEN] "Demand Forecast Entries" action is invoked.
        DemandForecastEntries.Trap();
        DemandForecastNames."Demand Forecast Entries".Invoke();

        // [THEN] 'Demand Forecast Entries' page opens and needed fields are editable
        DemandForecastEntries.Edit().Invoke();
        Assert.IsTrue(DemandForecastEntries."Production Forecast Name".Editable(), 'Field is expected to be not editable');
        Assert.IsTrue(DemandForecastEntries."Item No.".Editable(), 'Field is expected to be editable');
        Assert.IsTrue(DemandForecastEntries.Description.Editable(), 'Field is expected to be editable');
        Assert.IsTrue(DemandForecastEntries."Variant Code".Editable(), 'Field is expected to be editable');
        Assert.IsTrue(DemandForecastEntries."Location Code".Editable(), 'Field is expected to be editable');
        Assert.IsTrue(DemandForecastEntries."Forecast Quantity (Base)".Editable(), 'Field is expected to be editable');
        Assert.IsTrue(DemandForecastEntries."Forecast Date".Editable(), 'Field is expected to be editable');
        Assert.IsTrue(DemandForecastEntries."Forecast Quantity".Editable(), 'Field is expected to be editable');
        Assert.IsTrue(DemandForecastEntries."Unit of Measure Code".Editable(), 'Field is expected to be editable');
        Assert.IsTrue(DemandForecastEntries."Component Forecast".Editable(), 'Field is expected to be editable');
    end;

    [Test]
    [HandlerFunctions('ExchangeProductionBOMItemErrorHandler')]
    [Scope('OnPrem')]
    procedure ExchangeProductionBOMItemError()
    begin
        // [FEATURE] [Production BOM] [Exchange Production BOM Item]
        // [SCENARIO] Exchange Production BOM Item report throws an error when executed with the blank "Starting Date"

        Initialize();

        // [WHEN] Run Exchange Production BOM Item report with blank Starting Date.
        asserterror RunExchangeProductionBOMItemReport();

        // [THEN] Error message: "You must enter a Starting Date."
        Assert.AreEqual(StrSubstNo(MustEnterStartingDateErr), GetLastErrorText, UnknownErr);
    end;

    [Test]
    [HandlerFunctions('ExchangeProductionBOMItemHandler')]
    [Scope('OnPrem')]
    procedure ExchangeProductionBOMItemWithCreateNewVersion()
    var
        Item: Record Item;
        Item2: Record Item;
    begin
        // [FEATURE] [Production BOM] [Exchange Production BOM Item]
        // [SCENARIO] Item must be exchanged by Exchange Production BOM Item report, where "Create New Version" is Yes, "Delete Exchanged Component" is No

        // [GIVEN] Create two Items with Routing and Production BOM.
        Initialize();
        Item.Get(CreateItemWithRoutingAndProductionBOM());
        Item2.Get(CreateItemWithRoutingAndProductionBOM());
        ExchangeNo := FindProductionBOMComponent(Item."Production BOM No.");  // Use ExchangeNo as global for handler.
        WithNo := FindProductionBOMComponent(Item2."Production BOM No.");  // Use WithNo as global for handler.
        CreateNewVersion := true;  // Use CreateNewVersion as global for handler.
        DeleteExchangedComponent := false;

        // [WHEN] Run Exchange Production BOM Item report with Create New Version as true and Delete Exchanged Component as false.
        RunExchangeProductionBOMItemReport();

        // [THEN] Item has been exchanged.
        VerifyProductionBOMLineNotExists(Item."Production BOM No.", FindLastBOMVersionCode(Item."Production BOM No."), ExchangeNo);
        VerifyProductionBOMLineExists(Item."Production BOM No.", FindLastBOMVersionCode(Item."Production BOM No."), WithNo);
    end;

    [Test]
    [HandlerFunctions('ExchangeProductionBOMItemHandler')]
    [Scope('OnPrem')]
    procedure ExchangeProductionBOMItemWithDeleteExchangedComponent()
    var
        Item: Record Item;
        Item2: Record Item;
    begin
        // [FEATURE] [Production BOM] [Exchange Production BOM Item]
        // [SCENARIO] Item must be removed from BOM by Exchange Production BOM Item report, where "Create New Version" is No, "Delete Exchanged Component" is Yes

        // [GIVEN] Create two Items with Routing and Production BOM. Run Exchange Production BOM Item report with Create New Version as true and Delete Exchanged Component as false.
        Initialize();
        Item.Get(CreateItemWithRoutingAndProductionBOM());
        Item2.Get(CreateItemWithRoutingAndProductionBOM());
        ExchangeNo := FindProductionBOMComponent(Item."Production BOM No.");  // Use ExchangeNo as global for handler.
        WithNo := FindProductionBOMComponent(Item2."Production BOM No.");  // Use WithNo as global for handler.
        // BOM Comment is required for IN localization
        CreateCommentLineForProductionBOM(Item."Production BOM No.");

        // [WHEN] Run Exchange Production BOM Item report with Create New Version as false and Delete Exchanged Component as true.
        CreateNewVersion := false;  // Use CreateNewVersion as global for handler.
        DeleteExchangedComponent := true;
        RunExchangeProductionBOMItemReport();

        // [THEN] Exchanged Item has been removed from the BOM.
        VerifyProductionBOMLineNotExists(Item."Production BOM No.", '', ExchangeNo);
        VerifyProductionBOMLineExists(Item."Production BOM No.", '', WithNo);
    end;

    [Test]
    [HandlerFunctions('ExchangeProductionBOMItemHandler')]
    [Scope('OnPrem')]
    procedure ExchangeProductionBOMRollback()
    var
        ParentItemNoRouting: Record Item;
        ParentItemWithRouting: Record Item;
        ComponentItem: array[10] of Record Item;
        ExchangeItem: Record Item;
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        ProductionBOMHeaderNoRouting: Record "Production BOM Header";
        ProductionBOMHeaderWithRouting: Record "Production BOM Header";
        RoutingLinkCode: array[10] of Code[10];
        RoutingNo: Code[20];
    begin
        // [FEATURE] [Production BOM] [Exchange Production BOM Item]
        // [SCENARIO] Changes are rolled back if the Exchange Production BOM Item report encounters an error

        Initialize();

        // [GIVEN] Create Routing
        RoutingNo := CreateRoutingWithRoutingLinkCode();
        RoutingLine.SetRange("Routing No.", RoutingNo);
        RoutingLine.FindFirst();

        // [GIVEN] Create Items and Production BOM
        LibraryInventory.CreateItem(ParentItemNoRouting);
        LibraryInventory.CreateItem(ParentItemWithRouting);
        LibraryInventory.CreateItem(ComponentItem[1]);
        LibraryInventory.CreateItem(ComponentItem[2]);
        LibraryInventory.CreateItem(ExchangeItem);

        // [GIVEN] Assign Production BOM and Routing to Parent
        // [GIVEN] Create first Production BOM without Routing Link
        RoutingLinkCode[1] := '';
        CreateProdBOMMultipleLinesRoutingLink(
          ProductionBOMHeaderNoRouting, ComponentItem, RoutingLinkCode, ParentItemNoRouting."Base Unit of Measure");
        // [GIVEN] Create second Production BOM with Routing Link for first line only
        RoutingLinkCode[1] := RoutingLine."Routing Link Code";
        CreateProdBOMMultipleLinesRoutingLink(
          ProductionBOMHeaderWithRouting, ComponentItem, RoutingLinkCode, ParentItemWithRouting."Base Unit of Measure");
        ParentItemNoRouting.Validate("Production BOM No.", ProductionBOMHeaderNoRouting."No.");
        ParentItemNoRouting.Modify(true);
        ParentItemWithRouting.Validate("Routing No.", RoutingNo);
        ParentItemWithRouting.Validate("Production BOM No.", ProductionBOMHeaderWithRouting."No.");
        ParentItemWithRouting.Modify(true);

        // [GIVEN] Remove Routing Link from Routing Line to enforce error in ProductionBOMHeaderWithRouting
        RoutingHeader.Get(RoutingNo);
        ModifyRoutingStatus(RoutingHeader, RoutingHeader.Status::"Under Development");
        RoutingLine.Validate("Routing Link Code", '');
        RoutingLine.Modify(true);
        ModifyRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);

        // Define Parameters for RequestPageHandler
        // [GIVEN] Exchange second ComponentItem with ExchangeItem in Production BOM
        ExchangeNo := ComponentItem[2]."No.";
        WithNo := ExchangeItem."No.";
        CreateNewVersion := false;
        DeleteExchangedComponent := true;

        // [WHEN] Run Exchange Production BOM Item report
        asserterror RunExchangeProductionBOMItemReport();

        // [THEN] Production Order Status is Certified, the previous component lines have been restored and the lines for exchange item have been rolled back
        ProductionBOMHeaderNoRouting.Find('=');
        ProductionBOMHeaderNoRouting.TestField(Status, ProductionBOMHeaderNoRouting.Status::Certified);
        VerifyProductionBOMLineExists(ProductionBOMHeaderNoRouting."No.", '', ComponentItem[1]."No.");
        VerifyProductionBOMLineExists(ProductionBOMHeaderNoRouting."No.", '', ComponentItem[2]."No.");
        VerifyProductionBOMLineNotExists(ProductionBOMHeaderNoRouting."No.", '', ExchangeItem."No.");
        ProductionBOMHeaderWithRouting.Find('=');
        ProductionBOMHeaderWithRouting.TestField(Status, ProductionBOMHeaderWithRouting.Status::Certified);
        VerifyProductionBOMLineExists(ProductionBOMHeaderWithRouting."No.", '', ComponentItem[1]."No.");
        VerifyProductionBOMLineExists(ProductionBOMHeaderWithRouting."No.", '', ComponentItem[2]."No.");
        VerifyProductionBOMLineNotExists(ProductionBOMHeaderWithRouting."No.", '', ExchangeItem."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ParentItemInProductionBOMLineError()
    var
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        // [FEATURE] [Production BOM]
        // [SCENARIO] Validate error message when Status is set to Certified in Production BOM on adding Parent Item in BOM Line.

        // [GIVEN] Create Item and Production BOM. Add Parent Item as a Component in BOM.
        Initialize();
        Item.Get(CreateItemWithRoutingAndProductionBOM());
        AddParentItemAsBOMComponent(ProductionBOMHeader, ProductionBOMLine, Item);

        // [WHRN] Change the Status of Production BOM and catch the error.
        asserterror ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);

        // [THEN] Status error in Production BOM when Status is set to Certified.
        Assert.AreEqual(StrSubstNo(ProductionBOMStatusErr, 50, '', Item."No.", 1), GetLastErrorText, UnknownErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ParentItemInProductionBOMLineUnderDevelopment()
    var
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        // [FEATURE] [Production BOM]
        // [SCENARIO] Status can be set to Under Development on adding Parent Item in BOM Line and Certified on deleting the Parent Item from BOM Line.

        // [GIVEN] Create Item and Production BOM. Add Parent Item in Production BOM Line and set Status as Under Development.
        Initialize();
        Item.Get(CreateItemWithRoutingAndProductionBOM());
        AddParentItemAsBOMComponent(ProductionBOMHeader, ProductionBOMLine, Item);
        CreateCommentLineForItem(Item."No.");
        // [WHEN] Delete Production BOM Line with Parent Item and set Production BOM status as Certified.
        ProductionBOMLine.Delete(true);
        ModifyStatusInProductionBOM(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);

        // [THEN] Verify that the Status in Production BOM is Certified.
        ProductionBOMHeader.TestField(Status, ProductionBOMHeader.Status::Certified);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateWorkCenterCalendarReportWithBlankStartingDate()
    var
        ShopCalendarWorkingDays: Record "Shop Calendar Working Days";
        WorkCenter: Record "Work Center";
    begin
        // [FEATURE] [Capacity] [Shop Calendar]
        // [SCENARIO] Verify error message on running Calculate Work Center Calendar report with blank Starting date.

        // [GIVEN] Create Work Center with Work Center Group.
        Initialize();
        CreateWorkCenterWithWorkCenterGroup(WorkCenter, CreateShopCalendarCodeWithAllDaysWorking(ShopCalendarWorkingDays));

        // [WHEN] Run Calculate Work Center Calendar Report with blank Starting date.
        asserterror LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, 0D, WorkDate());

        // [THEN] Error message that Starting Date must have a value.
        Assert.AreEqual(StrSubstNo(MustFillStartingDateFieldErr), GetLastErrorText, UnknownErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateWorkCenterCalendarReport()
    var
        CalendarEntry: Record "Calendar Entry";
        ShopCalendarWorkingDays: Record "Shop Calendar Working Days";
        WorkCenter: Record "Work Center";
        ExpectedCapacityTotal: Decimal;
    begin
        // [FEATURE] [Capacity] [Shop Calendar]
        // [SCENARIO] Verify the functionality of Calculate Work Center Calendar report.

        // [GIVEN] Create Work Center with Work Center Group.
        Initialize();
        CreateWorkCenterWithWorkCenterGroup(WorkCenter, CreateShopCalendarCodeWithAllDaysWorking(ShopCalendarWorkingDays));
        ModifyCapacityOfWorkCenter(WorkCenter);

        // [WHEN] Calculate Work Center Calendar. Store the expected value for Capacity Total in a variable.
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, WorkDate(), WorkDate());
        GetCalendarEntry(CalendarEntry, CalendarEntry."Capacity Type"::"Work Center", WorkCenter."No.");
        ExpectedCapacityTotal :=
          ((CalendarEntry."Ending Time" - CalendarEntry."Starting Time") /
           CalendarManagement.TimeFactor(WorkCenter."Unit of Measure Code")) * WorkCenter.Capacity;

        // [THEN] Capacity Total on Calendar entry.
        VerifyCalendarEntry(WorkCenter."No.", ExpectedCapacityTotal);
    end;

    [Test]
    [HandlerFunctions('DeleteExpiredComponentsHandler')]
    [Scope('OnPrem')]
    procedure DeleteExpiredComponentsReportWithError()
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        // [FEATURE] [Delete Expired Components]
        // [SCENARIO] Test the functionality of Delete Expired Components report with blank Delete Before Date.

        Initialize();

        // [WHEN] Run Delete Expired Components report with blank Delete Before Date.
        LibraryVariableStorage.Enqueue(true);  // ShowError := true;
        asserterror RunDeleteExpiredComponentsReport(ProductionBOMHeader);

        // [THEN] Verify blank Delete Before Date error message.
        Assert.AreEqual(StrSubstNo(BlankDeleteBeforeDateErr), GetLastErrorText, UnknownErr);
    end;

    [Test]
    [HandlerFunctions('DeleteExpiredComponentsHandler')]
    [Scope('OnPrem')]
    procedure DeleteExpiredComponentsReport()
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        // [FEATURE] [Delete Expired Components]
        // [SCENARIO] Test the functionality of Delete Expired Components report.

        // [GIVEN] Create and modify Production BOM.
        Initialize();
        CreateAndModifyProductionBOM(ProductionBOMHeader);

        // [WHEN]  Run Delete Expired Components report.
        LibraryVariableStorage.Enqueue(false);  // ShowError := false;
        ProductionBOMHeader.SetRange("No.", ProductionBOMHeader."No.");
        RunDeleteExpiredComponentsReport(ProductionBOMHeader);

        // [THEN] Verify expired component must not exist.
        Assert.IsFalse(
          FindProductionBOMLine(ProductionBOMLine, ProductionBOMHeader."No."), StrSubstNo(MustNotExistErr, ProductionBOMLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshPlanningLine()
    var
        RequisitionLine: Record "Requisition Line";
        Direction: Option Forward,Backward;
    begin
        // [FEATURE] [Planning Worksheet]
        // [SCENARIO] Test and verify Starting Date and Ending Date after refreshing Planning Line.

        // [GIVEN] Create Requisition Line.
        Initialize();
        CreateRequisitionLine(RequisitionLine);

        // [WHEN] Refresh Planning Line.
        LibraryPlanning.RefreshPlanningLine(RequisitionLine, Direction::Backward, true, true);

        // [THEN] Verify Starting Date and Ending Date after refreshing Planning Line.
        RequisitionLine.Find();
        RequisitionLine.TestField("Starting Date", WorkDate());
        RequisitionLine.TestField("Ending Date", WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeletePlanningWorksheetLines()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        // [FEATURE] [Planning Worksheet]
        // [SCENARIO] Test and verify Delete Planning Worksheet Lines functionality after Calculate Regenerative Plan.

        // [GIVEN] Create Item with Lot for Lot Reordering Policy and Safety Stock Quantity.
        Initialize();
        CreateItemWithLotForLotReorderingPolicyAndSafetyStockQuantity(Item);
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());
        RequisitionLine.SetRange("No.", Item."No.");
        RequisitionLine.FindFirst();

        // [WHEN] Delete all Planning Worksheet Lines.
        RequisitionLine.DeleteAll(true);

        // [THEN] Verify all Planning Worksheet Lines must be deleted.
        Assert.AreEqual(0, RequisitionLine.Count, StrSubstNo(MustNotExistErr, RequisitionLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshingPlanningLinesWithMultipleBOMVersions()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionBOMVersion1: Record "Production BOM Version";
        ProductionBOMVersion2: Record "Production BOM Version";
        Components1: Dictionary of [Code[20], Decimal];
        Components2: Dictionary of [Code[20], Decimal];
        Direction: Option Forward,Backward;
        ChildBOMNo: Code[20];
        ItemNo: Code[20];
    begin
        // [FEATURE] [Planning Worksheet] [Production BOM Version]
        // [SCENARIO] When refreshing planning lines, system should consider selected BOM version.
        Initialize();

        // [GIVEN] Create Item with Lot for Lot Reordering Policy and Prod. Order Replanisment System.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item.Modify();

        // [GIEN] Create Child Production BOM with random item and qty. 
        ChildBOMNo := CreateProductionBOM(Item."Base Unit of Measure");

        // [GIVEN] Create Production BOM Header and two same Production BOM Versions and certify all.
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");

        CreateProductionBOMVersion(ProductionBOMVersion1, ProductionBOMHeader."No.", Item."Base Unit of Measure", 0D, ProductionBOMLine.Type::"Production BOM", ChildBOMNo, 1);
        ModifyProductionBOMVersionStatus(ProductionBOMVersion1, ProductionBOMVersion1.Status::Certified);

        CreateProductionBOMVersion(ProductionBOMVersion2, ProductionBOMHeader."No.", Item."Base Unit of Measure", 0D, ProductionBOMLine.Type::"Production BOM", ChildBOMNo, 1);
        ModifyProductionBOMVersionStatus(ProductionBOMVersion2, ProductionBOMVersion2.Status::Certified);

        ModifyStatusInProductionBOM(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);

        // [GIVEN] Update Item with Production BOM No. 
        Item.Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item.Modify();
        Commit();

        // [GIVEN] Create Requisition Worksheet Line for Item. Last Production BOM Version should be selected.
        CreateRequisitionWorksheetLineForItem(Item, RequisitionLine);
        RequisitionLine.TestField("Production BOM Version Code", ProductionBOMVersion2."Version Code");

        //[GIVEN] Refresh Planning Line and get Components.
        LibraryPlanning.RefreshPlanningLine(RequisitionLine, Direction::Backward, true, true);
        GetReqLineComponents(Components1, RequisitionLine);
        Assert.IsTrue(Components1.Count > 0, 'Components1 should not be empty');

        // [WHEN] Change Production BOM Version Code in Requisition Line and Refresh Planning Line.
        RequisitionLine.Validate("Production BOM Version Code", ProductionBOMVersion1."Version Code");
        RequisitionLine.Modify();
        LibraryPlanning.RefreshPlanningLine(RequisitionLine, Direction::Backward, true, true);

        // [THEN] Components after refreshing Planning Line should be the same like for first version.
        GetReqLineComponents(Components2, RequisitionLine);

        foreach ItemNo in Components1.Keys do begin
            Assert.IsTrue(Components2.ContainsKey(ItemNo), 'Component ' + ItemNo + ' should be present in Components2');
            Assert.AreEqual(Components1.Get(ItemNo), Components2.Get(ItemNo), 'Component ' + ItemNo + ' should have the same quantity');
        end;

    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure CalculateConsumptionAfterRefreshProductionOrder()
    var
        InventorySetup: Record "Inventory Setup";
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        // [FEATURE] [Consumption Journal]
        // [SCENARIO] Validate Consumption Journal After release Production Order and calculate Consumption.

        // [GIVEN] Create and Release Production Order.
        InventorySetup.Get();
        UpdateInventorySetup(true, true);
        CreateInitialSetupForReleasedProductionOrder(ProductionOrder, ProdOrderComponent);

        // [WHEN] Run Calculate Consumption report.
        CalculateConsumptionJournal(ItemJournalBatch, ProductionOrder."No.");

        // [THEN] Verify consumption journal line
        VerifyItemJournalLine(
          ItemJournalBatch, ProductionOrder."No.", ProdOrderComponent."Item No.", ProdOrderComponent."Expected Quantity");

        // Tear Down : Set Default value of Inventory Setup.
        UpdateInventorySetup(InventorySetup."Expected Cost Posting to G/L", InventorySetup."Automatic Cost Posting");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure OutputJournalAfterCalculateConsumption()
    var
        InventorySetup: Record "Inventory Setup";
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        // [FEATURE] [Output Journal]
        // [SCENARIO] Validate Output Journal after Posting Consumption Journal.

        // [GIVEN] Create and Release Production Order and Calculate Consumption Journal.
        InventorySetup.Get();
        UpdateInventorySetup(true, true);
        CreateInitialSetupForReleasedProductionOrder(ProductionOrder, ProdOrderComponent);
        CreateAndPostConsumptionJournal(ProductionOrder."No.");

        // [WHEN] Create Output Journal with Explode Routing.
        OutputJournalExplodeRouting(ItemJournalBatch, ProductionOrder);

        // [THEN] Output Journal.
        VerifyItemJournalLine(ItemJournalBatch, ProductionOrder."No.", ProductionOrder."Source No.", ProductionOrder.Quantity);

        // Tear Down : Set Default value of Inventory Setup.
        UpdateInventorySetup(InventorySetup."Expected Cost Posting to G/L", InventorySetup."Automatic Cost Posting");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure GLEntryAfterPostOutputJournal()
    var
        InventorySetup: Record "Inventory Setup";
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        // [FEATURE] [Output Journal]
        // [SCENARIO] Validate G/L Entry after posting output Journal.

        // [GIVEN] Create and Release Production Order, Calculate Consumption Journal and create Output Journal.
        InventorySetup.Get();
        UpdateInventorySetup(true, true);
        CreateInitialSetupForReleasedProductionOrder(ProductionOrder, ProdOrderComponent);
        CreateAndPostConsumptionJournal(ProductionOrder."No.");
        OutputJournalExplodeRouting(ItemJournalBatch, ProductionOrder);

        // [WHEN] Post Output Journal.
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [THEN] Verify G/L Entry.
        VerifyGLEntry(ProductionOrder."Inventory Posting Group", ProductionOrder."No.");

        // Tear Down : Set Default value of Inventory Setup.
        UpdateInventorySetup(InventorySetup."Expected Cost Posting to G/L", InventorySetup."Automatic Cost Posting");
    end;

    [Test]
    [HandlerFunctions('ProductionJournalHandler,ConfirmHandlerTrue,MessageHandler,ViewAppliedEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure QuantityOnAppliedEntriesAfterApplicationWorkSheet()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        SalesHeader: Record "Sales Header";
        ProductionJournalMgt: Codeunit "Production Journal Mgt";
        ApplicationWorksheet: TestPage "Application Worksheet";
        Quantity: Decimal;
    begin
        // [FEATURE] [Application Worksheet]
        // [SCENARIO] Check the Quantity on View Applied Item Entries After Application Worksheet.

        // [GIVEN] Create and Release Production Order, Quantity = "Q1". Open and post Production Journal.
        Initialize();
        CreateInitialSetupForReleasedProductionOrder(ProductionOrder, ProdOrderComponent);
        ProductionJournalMgt.Handling(ProductionOrder, ProdOrderComponent."Prod. Order Line No.");
        // [GIVEN] Create and post sales order. Quantity = "Q2" < "Q1".
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateAndPostSalesOrder(SalesHeader, ProductionOrder."Source No.", Quantity);
        LibraryVariableStorage.Enqueue(ProductionOrder."Source No.");
        LibraryVariableStorage.Enqueue(-1 * Quantity);
        ApplicationWorksheet.OpenEdit();
        ApplicationWorksheet.FILTER.SetFilter("Item No.", ProductionOrder."Source No.");

        // [WHEN] Open View Applied Entries Page.
        ApplicationWorksheet.AppliedEntries.Invoke();

        // [THEN] "Applied Quantity" = "Q2"
        // Verification done in ViewAppliedEntriesPageHandler.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocumentNoOnItemLedgerEntry()
    var
        Item: Record Item;
        Item2: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ProductionOrder: Record "Production Order";
        DocumentNo: Code[20];
        Quantity: Decimal;
        OldDocNoIsProdOrderNo: Boolean;
    begin
        // [FEATURE] [Output Journal]
        // [SCENARIO] Check Document No. on Item Ledger Entry when Field Doc. No. Is Prod. Order No. is False on Manufacturing Setup.

        // [GIVEN] Create and Release Production Order, Update Manufacturing Setup and Production Order Component.
        Initialize();
        OldDocNoIsProdOrderNo := UpdateManufacturingSetup(false);
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateMultipleItemsWithReorderingPolicy(Item, Item2, Quantity);
        CreateAndPostItemJournalLine(
          ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LibraryRandom.RandDec(1000, 2), WorkDate(), '');
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item2."No.", Quantity);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        UpdateProductionOrderComponent(ProductionOrder."No.", Item."No.");

        // [WHEN] Create and Post Output Journal.
        DocumentNo := CreateAndPostOutputJournal(ProductionOrder."No.");

        // [THEN] Document No. exist on Item ledger Entry.
        VerifyDocumentNoExistOnItemLedgerEntry(DocumentNo);

        // Tear Down.
        RestoreManufacturingSetup(OldDocNoIsProdOrderNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuantityOnProductionOrderLine()
    var
        Item: Record Item;
        Item2: Record Item;
        Item3: Record Item;
        Item4: Record Item;
        ProductionOrder: Record "Production Order";
        InvtPostingGroupCode: Code[20];
    begin
        // [FEATURE] [Production Order]
        // [SCENARIO] Quantity on Prod. Order Line should be equal to Qty. on Component Lines.

        // Setup.
        Initialize();
        InvtPostingGroupCode :=
          CreateItemWithReorderingPolicyAndInventoryPostingGroup(
            Item, Item."Replenishment System"::"Prod. Order", Item."Manufacturing Policy"::"Make-to-Order");
        CreateItemWithReorderingPolicy(
          Item2, Item2."Replenishment System"::"Prod. Order", Item2."Manufacturing Policy"::"Make-to-Order", InvtPostingGroupCode,
          CreateProductionBOMForSingleItem(LibraryInventory.CreateItem(Item3), Item."Base Unit of Measure"), '');
        CreateItemWithReorderingPolicy(
          Item4, Item4."Replenishment System"::"Prod. Order", Item4."Manufacturing Policy"::"Make-to-Order", InvtPostingGroupCode,
          CreateProductionBOMForSingleItem(Item2."No.", Item2."Base Unit of Measure"), '');
        UpdateProductionBOMOnParentItem(Item, Item2."No.", Item4."No.");

        // Exercise:  Create and refresh Production Order.
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.",
          LibraryRandom.RandDec(10, 2));
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // Verify: Verify Quantity on Prod. Order Line.
        Item4.CalcFields("Qty. on Component Lines");
        VerifyQuantityOnProdOrderLine(ProductionOrder.Status, ProductionOrder."No.", Item4."No.", Item4."Qty. on Component Lines");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExpectedQuantityOnProductionOrderComponenent()
    var
        Item: Record Item;
        Item2: Record Item;
        Item3: Record Item;
        Item4: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        InvtPostingGroupCode: Code[20];
    begin
        // [FEATURE] [Production Order]
        // [SCENARIO] Check Expected Quantity and Remaining Quantity on Prod. Order Component.

        // [GIVEN] Create and refresh Production Order.
        Initialize();
        InvtPostingGroupCode :=
          CreateItemWithReorderingPolicyAndInventoryPostingGroup(
            Item, Item."Replenishment System"::"Prod. Order", Item."Manufacturing Policy"::"Make-to-Order");
        CreateItemWithReorderingPolicy(
          Item2, Item2."Replenishment System"::"Prod. Order", Item2."Manufacturing Policy"::"Make-to-Order", InvtPostingGroupCode,
          CreateProductionBOMForSingleItem(LibraryInventory.CreateItem(Item3), Item."Base Unit of Measure"), '');
        CreateItemWithReorderingPolicy(
          Item4, Item4."Replenishment System"::"Prod. Order", Item4."Manufacturing Policy"::"Make-to-Order", InvtPostingGroupCode,
          CreateProductionBOMForSingleItem(Item2."No.", Item2."Base Unit of Measure"), '');
        UpdateProductionBOMOnParentItem(Item, Item2."No.", Item4."No.");
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.",
          LibraryRandom.RandDec(10, 2));
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [WHEN] Delete Component on Prod. Order Line.
        FindProductionOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.", Item4."No.");
        ProdOrderLine.Delete(true);

        // [THEN] Verify Quantity on Prod. Order Line.Expected Quantity and Remaining Quantity on Prod. Order Component.
        FindProductionOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.", Item2."No.");
        VerifyExpectedQuantityOnProdOrderComponent(Item3, ProductionOrder."No.", ProdOrderLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ProductionJournalHandler,ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure ChangeRtngOnProdOrdLnWithPostedOutput()
    var
        ProdOrdLn: Record "Prod. Order Line";
    begin
        // [FEATURE] [Production Order]
        // [SCENARIO] Check error when modifying routing No. on posted Prod. Order line

        // [GIVEN] Create 2 released prod. order lines, post output for the first line
        Initialize();
        SetupProdOrdLnWithPostedOutput(ProdOrdLn);

        // Get the first Prod. order line
        ProdOrdLn.Get(ProdOrdLn.Status, ProdOrdLn."Prod. Order No.", ProdOrdLn."Line No.");

        // [WHEN] Change Routing No. on the first line
        asserterror ProdOrdLn.Validate("Routing No.", CreateRouting());

        // [THEN] Error message: "You cannot modify Routing No.".
        Assert.AreEqual(StrSubstNo(ModifyRtngErr, ProdOrdLn."Routing No.", CapLedgEntryTxt), GetLastErrorText, '');
    end;

    [Test]
    [HandlerFunctions('ProductionJournalHandler,ConfirmHandlerTrue,MessageHandler')]
    [Scope('OnPrem')]
    procedure DeleteProdOrdLnWithPostedOutput()
    var
        ProdOrdLn: Record "Prod. Order Line";
    begin
        // [FEATURE] [Production Order]
        // [SCENARIO] Check error when deleting posted Prod. Order line

        // [GIVEN] Create 2 released prod. order lines, post output for the first line
        Initialize();
        SetupProdOrdLnWithPostedOutput(ProdOrdLn);

        // Get the first Prod. order line
        ProdOrdLn.Get(ProdOrdLn.Status, ProdOrdLn."Prod. Order No.", ProdOrdLn."Line No.");

        // [WHEN] Delete the first production order line
        asserterror ProdOrdLn.Delete(true);

        // [THEN] Error message: "You cannot delete Prod. Order Line"
        Assert.AreEqual(StrSubstNo(DeleteRtngErr, ProdOrdLn."Line No.", ItemLedgEntryTxt), GetLastErrorText, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeRtngOnProdOrdLn()
    var
        Item: Record Item;
        ProdOrdLn: Record "Prod. Order Line";
        ProdOrd: Record "Production Order";
        ProdOrdRtngLn: Record "Prod. Order Routing Line";
    begin
        // [FEATURE] [Production Order]
        // [SCENARIO] Production Order Routing Lines should be be deleted for the specific production order line when the Routing No. is changed

        Initialize();
        Item.Get(CreateItemWithRoutingAndProductionBOM());

        // [GIVEN] Create a released Prod. Order, create 2 Prod. Order lines, calculate routings
        SetupProdOrdWithRtng(ProdOrd, Item."No.");

        // Find the first Prod. Order Line
        FindProductionOrderLine(ProdOrdLn, ProdOrd.Status, ProdOrd."No.", Item."No.");

        // Check Table 5409 (Prod. Order Routing Line) has Routing Lines for the first Prod. Order Line
        Assert.IsTrue(FindProductionOrderRoutingLine(ProdOrdRtngLn, ProdOrdLn), ProdOrdRtngLnNotExistErr);

        // [WHEN] Change the Routing No. of the first Prod. Order line
        ProdOrdLn.Validate("Routing No.", CreateRouting());

        // [THEN] Table 5409 (Prod. Order Routing Line) has no Routing Lines for the first Prod. Order Line
        Assert.IsFalse(FindProductionOrderRoutingLine(ProdOrdRtngLn, ProdOrdLn), ProdOrdRtngLnExistErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeRtngOnProdOrdLnThroughItem()
    var
        Item: Record Item;
        ProdOrdLn: Record "Prod. Order Line";
        ProdOrd: Record "Production Order";
        ProdOrdRtngLn: Record "Prod. Order Routing Line";
    begin
        // [FEATURE] [Production Order]
        // [SCENARIO] Production Order Routing Lines should be be deleted for the specific production order line when the Routing No. is changed

        Initialize();
        Item.Get(CreateItemWithRoutingAndProductionBOM());

        // [GIVEN] Create a released Prod. Order, create 2 Prod. Order lines, calculate routings
        SetupProdOrdWithRtng(ProdOrd, Item."No.");

        // Find the first Prod. Order Line
        FindProductionOrderLine(ProdOrdLn, ProdOrd.Status, ProdOrd."No.", Item."No.");

        // Check Table 5409 (Prod. Order Routing Line) has Routing Lines for the first Prod. Order Line
        Assert.IsTrue(FindProductionOrderRoutingLine(ProdOrdRtngLn, ProdOrdLn), ProdOrdRtngLnNotExistErr);

        // [GIVEN] The Routing No is changed on the item of the first line
        Item.Get(ProdOrdLn."Item No.");
        Item.Validate("Routing No.", CreateRouting());
        Item.Modify();

        // [WHEN] The item no is validated on the line again
        ProdOrdLn.Validate("Item No.", Item."No.");

        // [THEN] Table 5409 (Prod. Order Routing Line) has no Routing Lines for the first Prod. Order Line
        Assert.IsFalse(FindProductionOrderRoutingLine(ProdOrdRtngLn, ProdOrdLn), ProdOrdRtngLnExistErr);

        // [WHEN] The routing is now refreshed with "CalcLines = true" and "CalcRoutings = true"
        LibraryManufacturing.RefreshProdOrder(ProdOrd, false, true, true, false, false); // Select Calculating Lines when Refreshing Order

        // [THEN] Table 5409 (Prod. Order Routing Line) has Routing Lines with the new Routing No.
        FindProductionOrderRoutingLine(ProdOrdRtngLn, ProdOrdLn);
        Assert.AreEqual(Item."Routing No.", ProdOrdRtngLn."Routing No.", ProdOrdRtngLnWrongRoutingNoErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateWaitingTimeIncludingWeekendWithMultipleCalendars()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        DueDate: Date;
        WaitTime: Integer;
    begin
        // Check Starting Date Time is calculated correctly for the Prod. Order Routing Line in a backward calculated Scenario
        // if the prior Prod. Order Routing Line is scheduled at non-Working Day for the calculated Prod. Order Routing Line with waiting time >= 5 Days
        Initialize();

        // Setup: Get the Waiting Days for routing line
        WaitTime := LibraryRandom.RandIntInRange(5, 9);

        // Create 2 Work Centers, one with all days working Calender, the other with Monday ~ Friday working Calender
        // Create Routing with 2 routing Lines, using the 2 created work centers. Create Production Item, calculate Prod. Order Due Date
        DueDate := SetupForCalculateWaitingTimeWithMultipleCalendars(Item, WorkCenter, WaitTime);

        // Exercise: Create Released Production Order, set Due Date and Refresh Production Order
        CreateAndRefreshProdOrderWithSpecificDueDate(ProductionOrder, Item."No.", DueDate, LibraryRandom.RandDec(10, 2), false);

        // Verify: Find the routing line with Monday ~ Friday working days and check the start Date-Time and Ending Date-time,
        // because WaitTime >= 5 DAYS, then duration between starting date and ending date will include weekend
        VerifyDateTimeOnProdOrderRoutingLine(ProductionOrder, Item."Routing No.", WorkCenter."No.", WaitTime);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateWaitingTimeWithMultipleCalendars()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        DueDate: Date;
        WaitTime: Integer;
    begin
        // Check Starting Date Time is calculated correctly for the Prod. Order Routing Line in a backward calculated Scenario
        // if the prior Prod. Order Routing Line is scheduled at non-Working Day for the calculated Prod. Order Routing Line with waiting time < 5 Days
        Initialize();

        // Setup: Get the Waiting Days for routing line
        WaitTime := LibraryRandom.RandInt(4); // Get the Wait Days for routing line

        // Create 2 Work Centers, one with all days working Calender, the other with Monday ~ Friday working Calender
        // Create Routing with 2 routing Lines, using the 2 created work centers. Create Production Item, calculate Prod. Order Due Date
        DueDate := SetupForCalculateWaitingTimeWithMultipleCalendars(Item, WorkCenter, WaitTime);

        // Exercise: Create Released Production Order, set Due Date and Refresh Production Order
        CreateAndRefreshProdOrderWithSpecificDueDate(ProductionOrder, Item."No.", DueDate, LibraryRandom.RandDec(10, 2), false);

        // Verify: Find the routing line with Monday ~ Friday working days and check the start Date-Time and Ending Date-time,
        VerifyDateTimeOnProdOrderRoutingLine(ProductionOrder, Item."Routing No.", WorkCenter."No.", WaitTime);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateProdOrderCapactiyNeedWithWorkShiftEndAtMidnight()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
        RoutingLine: Record "Routing Line";
        FirstDate: Date;
        StartingTime: Time;
        ChangeShiftTime: Time;
        EndingTime: Time;
        MinutesFactor: Integer;
        Precision: Decimal;
    begin
        // Check Prod. Order Capactiy Need is calculated correctly when there is work shift ending at midnight

        // Setup: Define the starting time and ending time for work shift
        Initialize();
        StartingTime := 083000T; // 8:30 AM is not important, just define the starting time for the first work shift
        ChangeShiftTime := 130000T; // 1:00 PM is not important, just define the ending time for the first work shift and the starting time for the second work shift
        EndingTime := 235959T; // Define the ending time for the second work shift, it needs to be very close to midnight

        // Create shop calendar, working days starts from Monday to Friday with 2 work shifts every day
        // Create Work Center, use the shop calendar created above
        // Update Calendar Rounding Precision for the work center to 0.1, otherwise the ending time in Prod. Order Capacity Need cannot reach 12:00:00,
        // then the issue mentioned in NAVSE TFS342243 cannot be reproed
        Precision := 0.1;
        CreateWorkCenterWithCalendarCodeAndRoundingPrecision(
          WorkCenter, CreateShopCalendarWithTwoWorkShifts(StartingTime, ChangeShiftTime, EndingTime), Precision);

        // Create Production Item with Routing, use the work center created above in routing line and set run time
        CreateProductionItemWithRouting(Item, RoutingLine, WorkCenter."No.");

        MinutesFactor := 60000; // Converting milliseconds to minutes needs to divide milliseconds with this factor

        // Exercise: Create Released Production Order, Refresh Production Order with Forward Direction
        // Since Unit Of Measure for Run Time on routing line is Minutes, thus change the unit of time that can
        // be allocated every day (EndingTime - StartingTime) to Minutes by dividing MinutesFactor.
        // Set the item quantity to make it needs capacity allocated in work center for more than 1 week
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.",
          Round((EndingTime - StartingTime) / MinutesFactor / RoutingLine."Run Time") * LibraryRandom.RandIntInRange(5, 15));
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, true, true, true, true, false);
        FirstDate := GetProdOrderCapacityNeedDate(WorkCenter."No.");

        // Verify: Verify Prod. Order Capactiy Need is correct
        // Verify the 2nd work shift starting from 1:00:00 PM is allocated for the first working day
        Assert.IsTrue(
          ProdOrderCapacityNeedExist(
            WorkCenter."No.", FirstDate, ChangeShiftTime, Round((EndingTime - ChangeShiftTime) / MinutesFactor, Precision)),
          StrSubstNo(WorkShiftShouldExistErr, ChangeShiftTime, Round((EndingTime - ChangeShiftTime) / MinutesFactor, Precision), FirstDate));

        // Verify no work time is allocated for next Saturday
        FilteringOnProdOrderCapacityNeed(ProdOrderCapacityNeed, WorkCenter."No.", CalcDate('<WD6>', FirstDate));
        Assert.IsTrue(ProdOrderCapacityNeed.IsEmpty, WorkShiftShouldNotExistErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateProdOrderCapactiyNeedWithWorkShiftEndAtMidnightInPlanningRoutingLine()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
        RoutingLine: Record "Routing Line";
        RequisitionLine: Record "Requisition Line";
        PlanningRoutingLine: Record "Planning Routing Line";
        FirstDate: Date;
        StartingTime: Time;
        ChangeShiftTime: Time;
        EndingTime: Time;
        MinutesFactor: Integer;
        Precision: Decimal;
    begin
        // Check Prod. Order Capactiy Need is calculated correctly when modifying Starting time in Planning Routing Line with work shift ending at midnight

        // Setup: Define the starting time and ending time for work shift
        Initialize();
        StartingTime := 083000T; // 8:30 AM is not important, just define the starting time for the first work shift
        ChangeShiftTime := 130000T; // 1:00 PM is not important, just define the ending time for the first work shift and the starting time for the second work shift
        EndingTime := 235959T; // Define the ending time for the second work shift, it needs to be very close to midnight

        // Create shop calendar, working days starts from Monday to Friday with 2 work shifts every day
        // Create Work Center, use the shop calendar created above
        // Update Calendar Rounding Precision for the work center to 0.1, otherwise the ending time in Prod. Order Capacity Need cannot reach 12:00:00,
        // then the issue mentioned in NAVSE TFS342243 cannot be reproed
        Precision := 0.1;
        CreateWorkCenterWithCalendarCodeAndRoundingPrecision(
          WorkCenter, CreateShopCalendarWithTwoWorkShifts(StartingTime, ChangeShiftTime, EndingTime), Precision);

        // Create Production Item with Routing, use the work center created above in routing line and set run time
        CreateProductionItemWithRouting(Item, RoutingLine, WorkCenter."No.");
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order"); // Modify the replenishment system for calculating Order Planning
        Item.Modify(true);

        MinutesFactor := 60000; // Converting milliseconds to minutes needs to divide milliseconds with this factor

        // Create a Sales Order for the item, set the item quantity to make it needs capacity allocated in work center for more than 1 week
        CreateSalesOrder(
          SalesHeader, Item."No.",
          Round((EndingTime - StartingTime) / MinutesFactor / RoutingLine."Run Time", Precision) *
          LibraryRandom.RandIntInRange(5, 15));

        // Calculate Order Planning for Sales Demand, that will generate Planning Routing Line for the item
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);
        FindPlanningRoutingLine(PlanningRoutingLine, WorkCenter."No.", RoutingLine."Operation No.");

        // Exercise: Modify the starting time on Planning Routing Line to make it in the first work shift
        PlanningRoutingLine.Validate("Starting Time", StartingTime + LibraryRandom.RandInt(ChangeShiftTime - StartingTime));
        PlanningRoutingLine.Modify(true);

        FirstDate := GetProdOrderCapacityNeedDate(WorkCenter."No.");

        // Verify: Verify Prod. Order Capactiy Need is correct
        // Verify the 2nd work shift starting from 1:00:00 PM is allocated for the first working day
        Assert.IsTrue(
          ProdOrderCapacityNeedExist(
            WorkCenter."No.", FirstDate, ChangeShiftTime, Round((EndingTime - ChangeShiftTime) / MinutesFactor, Precision)),
          StrSubstNo(WorkShiftShouldExistErr, ChangeShiftTime, Round((EndingTime - ChangeShiftTime) / MinutesFactor, Precision), FirstDate));

        // Verify no work time is allocated for next Saturday
        FilteringOnProdOrderCapacityNeed(ProdOrderCapacityNeed, WorkCenter."No.", CalcDate('<WD6>', FirstDate));
        Assert.IsTrue(ProdOrderCapacityNeed.IsEmpty, WorkShiftShouldNotExistErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateProdOrderStartingDateWithRoutingSetupTimeEndAtMidnight()
    var
        WorkCenter: Record "Work Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        RoutingLine: Record "Routing Line";
        ProdOrderLine: Record "Prod. Order Line";
        InventorySetup: Record "Inventory Setup";
        DueDate: Date;
        StartingTime: Time;
        EndingTime: Time;
        Precision: Decimal;
        ShopCalendarCode: Code[10];
    begin
        // Check the Starting Date on Prod. Order Line is calculated correctly when routing's setup time ends at midnight

        // Setup: Define the starting time and ending time for work shift
        Initialize();

        StartingTime := 083000T; // 8:30 AM is not important, just define the starting time for the work shift
        EndingTime := 235959T; // Define the ending time for work shift, it needs to be very close to midnight

        // Create shop calendar, working days starts from Monday to Friday with 1 work shift every day
        // Create Work Center, use the shop calendar created above
        // Update Calendar Rounding Precision for the work center to 0.1, otherwise the setup ending time in Prod. Order Capacity Need cannot reach 12:00:00,
        Precision := 0.1;
        ShopCalendarCode := CreateShopCalendar(StartingTime, EndingTime);

        // Create working days in weekend so that after Forward refreshing Prod. Order, the Starting Date on Prod. Orde Line plus
        // InventorySetup."Default Safety Lead Time" will equal the original Due Date of Prod. Order
        CreateShopCalendarWeekendWorkingDays(ShopCalendarCode, StartingTime, EndingTime);
        CreateWorkCenterWithCalendarCodeAndRoundingPrecision(WorkCenter, ShopCalendarCode, Precision);

        // Create Production Item with Routing, use the work center created above in routing line and modify setup time
        // The setup time equals the work time that can be allocated in a day with minuites unit of measure
        CreateProductionItemWithRouting(Item, RoutingLine, WorkCenter."No.");
        ModifySetupTimeOnRoutingLine(RoutingLine, Round((EndingTime - StartingTime) / (60 * 1000), Precision)); // Divisor 60 * 1000 is for converting millisecond to minute

        // Create Released Production Order
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.",
          LibraryRandom.RandInt(10));
        DueDate := ProductionOrder."Due Date";

        // Exercise: Refresh Production Order with Forward Direction
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, true, true, true, true, false);

        // Find the Prod. Order Line calculated by refreshing the production order
        FindProductionOrderLine(ProdOrderLine, ProductionOrder.Status::Released, ProductionOrder."No.", Item."No.");
        InventorySetup.Get();

        // Verify: The Starting Date on Prod. Orde Line should be ahead of the original Due Date of Prod. Order by Default Safety Lead Time
        Assert.AreEqual(
          DueDate, CalcDate(InventorySetup."Default Safety Lead Time", ProdOrderLine."Starting Date"),
          ProdOrderStartingDateErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckWaitTimeOnProdOrderRoutingLineWithoutCapacityConstrained()
    var
        RoutingLine: Record "Routing Line";
        RoutingLine2: Record "Routing Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProdOrderRoutingLine2: Record "Prod. Order Routing Line";
        ShopCalendarWorkingDays: Record "Shop Calendar Working Days";
    begin
        // Check Wait Time on Prod. Order Routing Line is not Capacity constrained.

        // Setup: Create Production item, 1 routing header with 2 routing lines, set the wait time of the
        // first routing line to 1 ~ 2 days so that the second routing line will start on Monday if first routing line starts on Friday.
        // Create and Refresh Released Production Order, 2 Prod. Order Routing Lines will be generated
        Initialize();
        SetupWaitTimeOnProdOrderRtngLnWithoutCapactityConstrained(RoutingLine, RoutingLine2);

        // Exercise: Find the 1st Prod. Order Routing Line and modify the Starting Date to Friday
        FindProdOrderRoutingLine(ProdOrderRoutingLine, RoutingLine."Work Center No.", RoutingLine."Operation No.");
        ModifyStartingDateOnProdOrderRtngLn(ProdOrderRoutingLine, CalcDate('<WD5>', WorkDate()));

        // Verify: Verify Ending Date Time on the 1st Prod. Order Routing Line
        ProdOrderRoutingLine.TestField(
          "Ending Date-Time", ProdOrderRoutingLine."Starting Date-Time" + ProdOrderRoutingLine."Wait Time" * 60 * 1000); // Wait Time is not capacity contrained

        FindProdOrderRoutingLine(ProdOrderRoutingLine2, RoutingLine2."Work Center No.", RoutingLine2."Operation No."); // Find the second Prod. Order Routing Line

        // Find ShopCalendarWorkingDays of Monday for the work center on the 2nd routing line
        FindShopCalendarWorkingDaysForWorkCenter(
          ShopCalendarWorkingDays, ProdOrderRoutingLine2."Work Center No.", ShopCalendarWorkingDays.Day::Monday);

        // Verify Starting Date Time on the 2nd Prod. Order Routing Line, it should be in the next working day (Monday) at its starting time
        ProdOrderRoutingLine2.TestField(
          "Starting Date-Time",
          CreateDateTime(CalcDate('<WD1>', ProdOrderRoutingLine."Ending Date"), ShopCalendarWorkingDays."Starting Time"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckWaitTimeOnPlanningRoutingLineWithoutCapacityConstrained()
    var
        RoutingLine: Record "Routing Line";
        RoutingLine2: Record "Routing Line";
        ShopCalendarWorkingDays: Record "Shop Calendar Working Days";
        PlanningRoutingLine: Record "Planning Routing Line";
        PlanningRoutingLine2: Record "Planning Routing Line";
    begin
        // Check Wait Time on Planning Routing Line is not Capacity constrained.

        // Setup: Create Production item, 1 routing header with 2 routing lines, set the wait time of the
        // first routing line to 1 ~ 2 days so that the second routing line will start on Monday if first routing line starts on Friday.
        // Create a Sales Order for the item. Calculate Order Planning for Sales Demand, that will generate Planning Routing Line for the item
        Initialize();
        SetupWaitTimeOnPlanningRtngLnWithoutCapactityConstrained(RoutingLine, RoutingLine2);

        // Exercise: Find the 1st Planning Routing Line and modify the starting Date to Friday
        FindPlanningRoutingLine(PlanningRoutingLine, RoutingLine."Work Center No.", RoutingLine."Operation No.");
        ModifyStartingDateOnPlanningRtngLn(PlanningRoutingLine, CalcDate('<WD5>', WorkDate()));

        // Verify: Verify Ending Date Time on the 1st Planning Routing Line
        PlanningRoutingLine.TestField(
          "Ending Date-Time", PlanningRoutingLine."Starting Date-Time" + PlanningRoutingLine."Wait Time" * 60 * 1000); // Wait Time is not capacity contrained

        FindPlanningRoutingLine(PlanningRoutingLine2, RoutingLine2."Work Center No.", RoutingLine2."Operation No."); // Find the second Planning Routing Line

        // Find ShopCalendarWorkingDays of Monday for the work center on the 2nd routing line
        FindShopCalendarWorkingDaysForWorkCenter(
          ShopCalendarWorkingDays, PlanningRoutingLine2."Work Center No.", ShopCalendarWorkingDays.Day::Monday);

        // Verify Starting Date Time on the 2nd Planning Routing Line, it should be in the next working day (Monday) at its starting time
        PlanningRoutingLine2.TestField(
          "Starting Date-Time",
          CreateDateTime(CalcDate('<WD1>', PlanningRoutingLine."Ending Date"), ShopCalendarWorkingDays."Starting Time"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckWaitTimeStartingOnWeekendOnProdOrdRtngLnWithoutCapConstrained()
    var
        RoutingLine: Record "Routing Line";
        RoutingLine2: Record "Routing Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProdOrderRoutingLine2: Record "Prod. Order Routing Line";
        ShopCalendarWorkingDays: Record "Shop Calendar Working Days";
    begin
        // Check Wait Time on Prod. Order Routing Line is not Capacity constrained with backward calculation when multiple routing lines exist.

        // Setup: Create Production item, 1 routing header with 2 routing lines, set the wait time of the second
        // routing line to 1 ~ 2 days so that the first routing line will end on Friday if second routing line starts on Monday.
        // Create and Refresh Released Production Order, 2 Prod. Order Routing Lines will be generated.
        Initialize();
        SetupWaitTimeOnProdOrderRtngLnForBackwardCalculation(RoutingLine, RoutingLine2);
        FindProdOrderRoutingLine(ProdOrderRoutingLine2, RoutingLine2."Work Center No.", RoutingLine2."Operation No."); // Find the 2nd Prod. Order Routing Line

        // Exercise: Modify the Ending Date to Monday
        ModifyEndingDateOnProdOrderRtngLn(ProdOrderRoutingLine2, CalcDate('<WD1>', WorkDate()));

        // Verify: Verify Starting Date Time on the 2nd Prod. Order Routing Line, the Starting Date is weekend since the Wait Time is 1 ~ 2 days
        ProdOrderRoutingLine2.TestField(
          "Starting Date-Time", ProdOrderRoutingLine2."Ending Date-Time" - ProdOrderRoutingLine2."Wait Time" * 60 * 1000); // Wait Time is not capacity contrained

        FindProdOrderRoutingLine(ProdOrderRoutingLine, RoutingLine."Work Center No.", RoutingLine."Operation No."); // Find the 1st Prod. Order Routing Line

        // Find ShopCalendarWorkingDays of Friday for the work center on the 1st routing line
        FindShopCalendarWorkingDaysForWorkCenter(
          ShopCalendarWorkingDays, ProdOrderRoutingLine."Work Center No.", ShopCalendarWorkingDays.Day::Friday);

        // Verify Ending Date Time on the 1st Prod. Order Routing Line, it should be in the last working day (Friday) at its ending time
        ProdOrderRoutingLine.TestField(
          "Ending Date-Time",
          CreateDateTime(CalcDate('<-WD5>', ProdOrderRoutingLine2."Starting Date"), ShopCalendarWorkingDays."Ending Time"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckWaitTimeStartingOnWeekendOnPlanningRtngLnWithoutCapConstrained()
    var
        RoutingLine: Record "Routing Line";
        RoutingLine2: Record "Routing Line";
        PlanningRoutingLine: Record "Planning Routing Line";
        PlanningRoutingLine2: Record "Planning Routing Line";
        ShopCalendarWorkingDays: Record "Shop Calendar Working Days";
    begin
        // Check Wait Time on Planning Routing Line is not Capacity constrained with backward calculation when multiple routing lines exist.

        // Setup: Create Production item, 1 routing header with 2 routing lines, set the wait time of the second
        // routing line to 1 ~ 2 days so that the first routing line will end on Friday if second routing line starts on Monday.
        // Create a Sales Order for the item. Calculate Order Planning for Sales Demand, that will generate Planning Routing Line for the item.
        Initialize();
        SetupWaitTimeOnPlanningRtngLnForBackwardCalculation(RoutingLine, RoutingLine2);
        FindPlanningRoutingLine(PlanningRoutingLine2, RoutingLine2."Work Center No.", RoutingLine2."Operation No."); // Find the 2nd Planning Routing Line

        // Exercise: Modify the Ending Date to Monday
        ModifyEndingDateOnPlanningRtngLn(PlanningRoutingLine2, CalcDate('<WD1>', WorkDate()));

        // Verify: Verify Starting Date on the 2nd Planning Routing Line, the Starting Date is weekend since the Wait Time is 1 ~ 2 days
        PlanningRoutingLine2.TestField(
            "Starting Date-Time", PlanningRoutingLine2."Ending Date-Time" - PlanningRoutingLine2."Wait Time" * 60 * 1000);

        FindPlanningRoutingLine(PlanningRoutingLine, RoutingLine."Work Center No.", RoutingLine."Operation No."); // Find the 1st Planning Routing Line

        // Find ShopCalendarWorkingDays of Friday for the work center on the 1st routing line
        FindShopCalendarWorkingDaysForWorkCenter(
          ShopCalendarWorkingDays, PlanningRoutingLine."Work Center No.", ShopCalendarWorkingDays.Day::Friday);

        // Verify Ending Date Time on the 1st Planning Routing Line, it should be in the last working day (Friday) at its ending time
        PlanningRoutingLine.TestField(
          "Ending Date-Time",
          CreateDateTime(CalcDate('<-WD5>', PlanningRoutingLine2."Starting Date"), ShopCalendarWorkingDays."Ending Time"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckBackwardCalculatedWaitTimeOnProdOrdRtngLnWithoutCapConstrained()
    var
        RoutingLine: Record "Routing Line";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        // Check Wait Time on Prod. Order Routing Line is not Capacity constrained with backward calculation when wait time exceeds 1 week.

        // Setup: Create Work Center and Production item, set wait time on routing line to 1 ~ 2 weeks.
        Initialize();
        CreateWorkCenterAndProductionItem(Item, RoutingLine);

        // Exercise: Create and Refresh Released Production Order.
        CreateAndRefreshProdOrderWithSpecificItem(ProductionOrder, Item."No.", false);
        FindProdOrderRoutingLine(ProdOrderRoutingLine, RoutingLine."Work Center No.", RoutingLine."Operation No."); // Find the Prod. Order Routing Line

        // Verify: Verify Starting Date Time on the Prod. Order Routing Line
        ProdOrderRoutingLine.TestField(
          "Starting Date-Time", ProdOrderRoutingLine."Ending Date-Time" - ProdOrderRoutingLine."Wait Time" * 60 * 1000); // Wait Time is not capacity contrained
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckBackwardCalculatedWaitTimeOnPlanningRtngLnWithoutCapConstrained()
    var
        Item: Record Item;
        RoutingLine: Record "Routing Line";
        PlanningRoutingLine: Record "Planning Routing Line";
    begin
        // [FEATURE] [Order Planning] [Capacity]
        // [SCENARIO] Check Wait Time on Planning Routing Line is not Capacity constrained with backward calculation when wait time exceeds 1 week.

        // [GIVEN] Create Work Center and Production item, set wait time on routing line to 1 ~ 2 weeks.
        Initialize();
        CreateWorkCenterAndProductionItem(Item, RoutingLine);

        // [WHEN] Create Sales Order and calculate order planning
        CreateSalesOrderAndCalculateOrderPlan(Item, Item."Replenishment System"::"Prod. Order");
        FindPlanningRoutingLine(PlanningRoutingLine, RoutingLine."Work Center No.", RoutingLine."Operation No."); // Find the Planning Routing Line

        // [THEN] Verify Starting Date Time on the Prod. Order Routing Line
        PlanningRoutingLine.TestField(
          "Starting Date-Time", PlanningRoutingLine."Ending Date-Time" - PlanningRoutingLine."Wait Time" * 60 * 1000); // Wait Time is not capacity contrained
    end;

    [Test]
    [HandlerFunctions('MachineCenterPageHandler')]
    [Scope('OnPrem')]
    procedure CheckProdOrderLineBinCodeFromMachineCenterThroughWorkCenter()
    var
        ProdOrderLine: Record "Prod. Order Line";
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        CalculateProdOrder: Codeunit "Calculate Prod. Order";
        RoutingRefNo: Integer;
    begin
        // [FEATURE] [Production Order] [Capacity] [Warehouse] [Bin]
        // [SCENARIO 360750.2] Move Job from Work Center To Machine Center with different Bin Code
        Initialize();

        // [GIVEN] Create ProdOrderLine for White Location, Routing Line with Bin Code and Update Work Center With another Bin Code
        CreateProdOrderLineWithWhiteLocationAndUpdateWorkCenterBinCode(ProdOrderLine, WorkCenter, RoutingRefNo);
        // [GIVEN] Create Machine Center with Different Bin Code and update Prod ORder Routing Line
        CreateMachineCenterAndUpdateProdOderRtngLine(MachineCenter, ProdOrderRtngLine, WorkCenter, ProdOrderLine, RoutingRefNo);

        // [WHEN] Find and set ProdOrderLine Bin Code from Work Center through Routing Line
        CalculateProdOrder.AssignProdOrderLineBinCodeFromProdRtngLineMachineCenter(ProdOrderRtngLine);

        // [THEN] ProdOrderLine's BinCode is same as Machine Center's Bin Code
        VerifyProdOrderLineBinCode(ProdOrderLine, MachineCenter."From-Production Bin Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckProdOrderLineBinCodeFromWorkCenterThroughRoutingLine()
    var
        ProdOrderLine: Record "Prod. Order Line";
        WorkCenter: Record "Work Center";
        CalculateProdOrder: Codeunit "Calculate Prod. Order";
        RoutingRefNo: Integer;
    begin
        // [FEATURE] [Production Order] [Capacity] [Warehouse] [Bin]
        // [SCENARIO 360750.3] ProdOrderLine gets BinCode from Work Center thorugh Routing Line with different Bin Code
        Initialize();

        // [GIVEN] Create ProdOrderLine for White Location, Routing Line with Bin Code and Update Work Center With another Bin Code
        CreateProdOrderLineWithWhiteLocationAndUpdateWorkCenterBinCode(ProdOrderLine, WorkCenter, RoutingRefNo);

        // [WHEN] Find and set ProdOrderLine Bin Code from Work Center through Routing Line
        CalculateProdOrder.FindAndSetProdOrderLineBinCodeFromProdRoutingLines(
          ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", RoutingRefNo);

        // [THEN] ProdOrderLine's BinCode is same as Work Center's Bin Code
        VerifyProdOrderLineBinCode(ProdOrderLine, WorkCenter."From-Production Bin Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckProdOrderLineBinCodeFromWorkCenterAfterRoutingChange()
    var
        ProdOrderLine: Record "Prod. Order Line";
        WorkCenter: Record "Work Center";
        WorkCenter2: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        Bin: Record Bin;
        CalculateProdOrder: Codeunit "Calculate Prod. Order";
        RoutingRefNo: Integer;
    begin
        // [FEATURE] [Production Order] [Routing] [Warehouse] [Bin]
        // [SCENARIO 360750.3] ProdOrderLine gets BinCode after change of Routing No. from Work Center with different Bin Code
        Initialize();

        // [GIVEN] Create ProdOrderLine for White Location, Work Centers/Routings with From-Production Bin Code
        CreateProdOrderLineWithWhiteLocationAndUpdateWorkCenterBinCode(ProdOrderLine, WorkCenter, RoutingRefNo);

        // [GIVEN] Create Work Centers/Routings with different From-Production Bin Code
        LibraryManufacturing.CreateWorkCenter(WorkCenter2);
        WorkCenter2.Validate("Location Code", WorkCenter."Location Code");
        LibraryWarehouse.CreateBin(
          Bin, WorkCenter."Location Code", LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), DATABASE::Bin), '', '');
        WorkCenter2.Validate("From-Production Bin Code", Bin.Code);
        WorkCenter2.Modify();
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLineSetup(RoutingLine, RoutingHeader, WorkCenter2."No.", '001', 1, 1);
        RoutingHeader.Validate(Status, "Routing Status"::Certified);
        RoutingHeader.Modify();

        // [WHEN] Find and set ProdOrderLine Bin Code from Work Center through Routing Line
        CalculateProdOrder.FindAndSetProdOrderLineBinCodeFromProdRoutingLines(
          ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", RoutingRefNo);

        // [WHEN] Change Routing in Prod. Order Line, therefore change Work Center and update Bin Code
        ProdOrderLine.Validate("Routing No.", RoutingHeader."No.");
        ProdOrderLine.Modify();

        // [THEN] Verify "Bin Code" in ProdOrderLine is same as another Work Center's Bin Code
        ProdOrderLine.TestField("Bin Code", WorkCenter2."From-Production Bin Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VariantFilterIsUsedToCalculateProdForecastQtyOnItem()
    var
        ProductionForecastName: Record "Production Forecast Name";
        ProductionForecastEntry: Record "Production Forecast Entry";
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ForecastWithoutVariantCode: Decimal;
        ForecastWithVariantCode: Decimal;
    begin
        // [FEATURE] [Production Forecast]
        // [SCENARIO] Variant filter on item is used to calculate the prodution forecast quantity 

        // [GIVEN] Create Production Forecast Name, create Production Forecast Entry for a item with 'Variant Code' = ''.
        Initialize();
        LibraryManufacturing.CreateProductionForecastName(ProductionForecastName);
        CreateProductionForecastEntry(ProductionForecastEntry, ProductionForecastName.Name);

        // [GIVEN] Create a item variant
        LibraryInventory.CreateItemVariant(ItemVariant, ProductionForecastEntry."Item No.");

        // [GIVEN] Create a Production Forecast Entry for the item of a particulat variant
        ForecastWithoutVariantCode := ProductionForecastEntry."Forecast Quantity (Base)";
        ForecastWithVariantCode := LibraryRandom.RandDec(100, 2);

        Item.Get(ProductionForecastEntry."Item No.");
        clear(ProductionForecastEntry);
        LibraryManufacturing.CreateProductionForecastEntry(ProductionForecastEntry, ProductionForecastName.Name, Item."No.", ItemVariant.Code, CreateLocation(), WorkDate(), true);
        ProductionForecastEntry.Validate("Forecast Quantity (Base)", ForecastWithVariantCode);
        ProductionForecastEntry.Modify(true);

        // [WHEN] Variant Filter is not set and 'Prod. Forecast Quantity (Base)' is calculated
        Item.SetRange("Variant Filter");
        Item.CalcFields("Prod. Forecast Quantity (Base)");

        // [THEN] 'Prod. Forecast Quantity (Base)' is the sum of both entries (with variant code and without)
        Item.TestField("Prod. Forecast Quantity (Base)", ForecastWithoutVariantCode + ForecastWithVariantCode);

        // [WHEN] variant Filter is set and 'Prod. Forecast Qty. (Base)- is calculated
        Item.SetRange("Variant Filter", ItemVariant.Code);
        Item.CalcFields("Prod. Forecast Quantity (Base)");

        // [THEN] 'Prod. Forecast Quantity (Base)' is same as the qty. set on forecast entry where the 'Variant Code' is same as the code in 'Variant Filter'
        Item.TestField("Prod. Forecast Quantity (Base)", ForecastWithVariantCode);
    end;

    [Test]
    [HandlerFunctions('ProdOrderRoutingHandler')]
    [Scope('OnPrem')]
    procedure ChangeProdOrderRtngLineFromProdBinCode()
    var
        ProdOrderLine: Record "Prod. Order Line";
        WorkCenter: Record "Work Center";
        RoutingRefNo: Integer;
    begin
        // [FEATURE] [Production Order] [Warehouse] [Bin]
        // [SCENARIO] Verify ProdOrderLine's BinCode changes after ProdOrderRtngLine update

        Initialize();
        CreateProdOrderLineWithWhiteLocationAndUpdateWorkCenterBinCode(ProdOrderLine, WorkCenter, RoutingRefNo);

        LibraryVariableStorage.Enqueue(WorkCenter."No.");
        ProdOrderLine.ShowRouting(); // set WorkCenterNo in ProdOrderRoutingHandler

        VerifyProdOrderLineBinCode(ProdOrderLine, WorkCenter."From-Production Bin Code");
    end;

    [Test]
    [HandlerFunctions('ReservationHandler')]
    [Scope('OnPrem')]
    procedure CircularReferenceConsumptionNotAllowedWithReservation()
    var
        ProductionOrder: Record "Production Order";
    begin
        // [FEATURE] [Cost Application] [Reservation]
        // [SCENARIO 360892] It is not allowed to post consumption that leads to circular reference in cost application if component is reserved
        Initialize();

        // [GIVEN] Two production orders consuming each other's produced items
        // [GIVEN] Consumption for the first order is posted
        CreateProdOrdersWithCrossReference(ProductionOrder);

        // [GIVEN] Component for the second order is reserved
        ReserveComponentForProdOrder(ProductionOrder.Status, ProductionOrder."No.");

        // [WHEN] Consumption of the reserved component is posted
        asserterror CreateAndPostConsumptionJournal(ProductionOrder."No.");

        // [THEN] Posting is not allowed
        VerifyComponentNotOnInventoryError(ProductionOrder.Status, ProductionOrder."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CircularReferenceConsumptionNotAllowedWithoutReservation()
    var
        ProductionOrder: Record "Production Order";
    begin
        // [FEATURE] [Cost Application]
        // [SCENARIO 360892] It is not allowed to post consumption that leads to circular reference in cost application if component is not reserved
        Initialize();

        // [GIVEN] Two production orders consuming each other's produced items
        // [GIVEN] Consumption for the first order is posted
        CreateProdOrdersWithCrossReference(ProductionOrder);

        // [WHEN] Consumption of the reserved component is posted
        asserterror CreateAndPostConsumptionJournal(ProductionOrder."No.");

        // [THEN] Posting is not allowed
        VerifyComponentNotOnInventoryError(ProductionOrder.Status, ProductionOrder."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckBackwardCalculatedTimeOnProdOrdCapConstrained()
    var
        WorkCenter1: Record "Work Center";
        WorkCenter2: Record "Work Center";
        RoutingLink: Record "Routing Link";
        Item: Record Item;
        UpperComponentItem: Record Item;
        LowerComponentItem: Record Item;
        ProductionOrder: Record "Production Order";
        Capacity: Integer;
    begin
        // [FEATURE] [Routing] [Refresh Production Order]
        // [SCENARIO 361976] Check Date-Time calculation when refreshing back Production Order with concurrent capacity workcenters.

        // [GIVEN] Create two workcenters with concurrent capacities > 1.
        Initialize();
        Capacity := 10; // Capacity 10 needed for test.
        CreateWorkCenterWithCapacity(WorkCenter1, Capacity);
        CreateWorkCenterWithCapacity(WorkCenter2, Capacity);

        // [GIVEN] Create two production Items, one is a component for another.
        // [GIVEN] Each Item with a route having different workcenters, and concurrent capacities > 1.
        LibraryInventory.CreateItem(LowerComponentItem);
        LibraryInventory.CreateItem(UpperComponentItem);
        LibraryManufacturing.CreateRoutingLink(RoutingLink);
        CreateRoutingAndBOM(UpperComponentItem."No.", LowerComponentItem."No.", WorkCenter1."No.", Capacity, RoutingLink.Code);
        LibraryInventory.CreateItem(Item);
        CreateRoutingAndBOM(Item."No.", UpperComponentItem."No.", WorkCenter2."No.", Capacity, RoutingLink.Code);

        // [GIVEN] Create Production order for top Item.
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item,
          Item."No.", LibraryRandom.RandIntInRange(10, 20));

        // [WHEN] Refresh Production Order (back)
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [THEN] Routing time calculated backwards line by line: [finish time] - [work time] = [start time]; [next line finish time] = [start time], so on.
        VerifyProdOrderDateTimes(ProductionOrder, Capacity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckEndingDateTimeAfterRefreshingPOForwardWhenOperationDoesNotHaveAnyTimeDefined()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        WorkCenter: Record "Work Center";
        WorkCenter2: Record "Work Center";
        ItemNo: Code[20];
        RoutingNo: Code[20];
        PrevOperationEndingDateTime: DateTime;
    begin
        // [FEATURE] [Routing] [Refresh Production Order]
        // [SCENARIO 362347] Operation starting date-time is set to ending date-time when operation does not have any time defined after refreshing Production Order Forward
        Initialize();

        // [GIVEN] Item with Routing of two Routing Lines with different Work Centers.
        ItemNo := CreateItemWithRoutingAndTwoWorkCenters(WorkCenter, WorkCenter2, RoutingNo);
        // [GIVEN] Calculate Calendar for Work Center in first Routing Line and Reset Time in last Routing Line
        LibraryManufacturing.CalculateWorkCenterCalendar(
            WorkCenter, CalcDate('<-1D>', WorkDate()), CalcDate('<1D>', WorkDate()));
        ResetRunTimeOnRoutingLine(RoutingNo, WorkCenter2."No.");

        // [GIVEN] Released Production Order
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo,
            LibraryRandom.RandDec(10, 2));

        // [WHEN] Refresh Production Order. Calculate Forward
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, true, true, true, false, false);

        // [THEN] Prod Order Routing Line has Starting Date-Time equal to Ending Date-Time
        FindProdOrderRtngLn(ProdOrderRoutingLine, ProductionOrder.Status::Released, ProductionOrder."No.", RoutingNo, WorkCenter."No.");
        PrevOperationEndingDateTime := ProdOrderRoutingLine."Ending Date-Time";

        FindProdOrderRtngLn(ProdOrderRoutingLine, ProductionOrder.Status::Released, ProductionOrder."No.", RoutingNo, WorkCenter2."No.");
        Assert.AreEqual(PrevOperationEndingDateTime, ProdOrderRoutingLine."Starting Date-Time", StartingDateTimeErr);
        Assert.AreEqual(ProdOrderRoutingLine."Starting Date-Time", ProdOrderRoutingLine."Ending Date-Time", EndingDateTimeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckEndingDateTimeAfterRefreshingPOBackwardWhenOperationDoesNotHaveAnyTimeDefined()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        WorkCenter: Record "Work Center";
        WorkCenter2: Record "Work Center";
        ItemNo: Code[20];
        RoutingNo: Code[20];
        NextOperationEndingDateTime: DateTime;
    begin
        // [FEATURE] [Routing] [Refresh Production Order]
        // [SCENARIO 362347] Operation ending date-time is set to starting date-time when operation does not have any time defined after refreshing Production Order Backward
        Initialize();

        // [GIVEN] Item with Routing of two Routing Lines with different Work Centers.
        ItemNo := CreateItemWithRoutingAndTwoWorkCenters(WorkCenter, WorkCenter2, RoutingNo);
        // [GIVEN] Calculate Calendar for Work Center in last Routing Line and Reset Time in first Routing Line
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter2, CalcDate('<-1D>', WorkDate()), CalcDate('<1D>', WorkDate()));
        ResetRunTimeOnRoutingLine(RoutingNo, WorkCenter."No.");

        // [GIVEN] Released Production Order
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo,
            LibraryRandom.RandDec(10, 2));

        // [WHEN] Refresh Production Order. Calculate Backward
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, false, false);

        // [THEN] Prod Order Routing Line has Ending Date-Time equal to Starting Date-Time
        FindProdOrderRtngLn(ProdOrderRoutingLine, ProductionOrder.Status::Released, ProductionOrder."No.", RoutingNo, WorkCenter2."No.");
        NextOperationEndingDateTime := ProdOrderRoutingLine."Starting Date-Time";

        FindProdOrderRtngLn(ProdOrderRoutingLine, ProductionOrder.Status::Released, ProductionOrder."No.", RoutingNo, WorkCenter."No.");
        Assert.AreEqual(NextOperationEndingDateTime, ProdOrderRoutingLine."Ending Date-Time", EndingDateTimeErr);
        Assert.AreEqual(ProdOrderRoutingLine."Ending Date-Time", ProdOrderRoutingLine."Starting Date-Time", StartingDateTimeErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler2')]
    [Scope('OnPrem')]
    procedure ProdOrderEndingDateBeforeComponentReceiptDateAllowedWithWarning()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        MessageCount: Integer;
    begin
        // [FEATURE] [Manufacturing] [Production Order]
        // [SCENARIO 361467] Warning is raised when Ending Date on prod. order line is set earlier than Expected Receipt Date of the component reserved for this line
        Initialize();

        // [GIVEN] Purchased Item.
        // [GIVEN] Produced item and component item, both with manufacturing policy "Make to Order"
        // [GIVEN] Multi-level production order is created. Component is reserved with Expected Receipt Date = WORKDATE
        CreateAndRefreshProdOrderForMakeToOrderItem(ProductionOrder);

        // [WHEN] Manufacturing Ending Date is set to WorkDate() - 1 day
        LibraryVariableStorage.Enqueue(ReservationDateConflictTxt);
        LibraryVariableStorage.Enqueue(0);
        FindProductionOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.", ProductionOrder."Source No.");
        ProdOrderLine.Validate("Ending Date", CalcDate('<-1D>', ProdOrderLine."Ending Date"));

        // [THEN] One warning message is raised.
        MessageCount := LibraryVariableStorage.DequeueInteger();
        Assert.AreEqual(1, MessageCount, WrongNumberOfMessagesErr);

        // Text verification is done in MessageHandler2
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdOrderCompDueDateBeforeComponentReceiptDateIsNotAllowed()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        MfgReservCheckDateConfl: Codeunit "Mfg. ReservCheckDateConfl";
    begin
        // [FEATURE] [Manufacturing] [Production Order]
        // [SCENARIO 361467] Error is raised when Ending Date on Prod. Order Component is explicitly set earlier than the date on which it is reserved for a parent Prod. Order Line.
        Initialize();

        // [GIVEN] Purchased Item.
        // [GIVEN] Produced item and component item, both with manufacturing policy "Make to Order"
        // [GIVEN] Multi-level production order is created. Component is reserved with Expected Receipt Date = WORKDATE
        CreateAndRefreshProdOrderForMakeToOrderItem(ProductionOrder);

        // [WHEN] Due Date for the component item is shifted one day earlier.
        FindProdOrderComponent(ProdOrderComponent, ProductionOrder.Status, ProductionOrder."No.");
        ProdOrderComponent."Due Date" := CalcDate('<-1D>', ProdOrderComponent."Due Date");
        asserterror MfgReservCheckDateConfl.ProdOrderComponentCheck(ProdOrderComponent, true, true);

        // [THEN] Error message is raised.
        Assert.ExpectedError(ReservDateConflictErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckDateTimeIsUpdatedOnProdOrderAfterCarryingOutPlanningWorksheet()
    var
        RequisitionLine: Record "Requisition Line";
        ProdOrder: Record "Production Order";
    begin
        // [FEATURE] [Production Order] [Planning Worksheet] [Date-time]
        // [SCENARIO 364536] Starting- and Ending Date-time on Planned Production Prder should be updated after Carrying out message from Planning Worksheet
        Initialize();

        // [GIVEN] Requisition Line with Starting Date = "X1", Starting Time = "Y1", Ending Date = "X2", Ending Time = "Y2"
        CreateRequisitionLineWithDates(RequisitionLine);

        // [WHEN] Carry Out Action Message
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);
        // [THEN] Production Order is created with Starting Date-Time = "X1 Y1", Ending Date-time = "X2 Y2"
        ProdOrder.SetRange("Source No.", RequisitionLine."No.");
        ProdOrder.FindFirst();
        Assert.AreEqual(CreateDateTime(ProdOrder."Starting Date", ProdOrder."Starting Time"), ProdOrder."Starting Date-Time", StartingDateTimeErr);
        Assert.AreEqual(CreateDateTime(ProdOrder."Ending Date", ProdOrder."Ending Time"), ProdOrder."Ending Date-Time", EndingDateTimeErr);
    end;

    [Test]
    [HandlerFunctions('ExchangeProductionBOMItemHandler')]
    [Scope('OnPrem')]
    procedure ExchangeBOMItemCreateNewVersionWithPhantomBOM()
    var
        UnitOfMeasure: Record "Unit of Measure";
        ProdBOMLine: Record "Production BOM Line";
        ParentProdBOMVersion: Record "Production BOM Version";
        ParentBOMNo: Code[20];
        ChildItemNo: Code[20];
        PhantomBOMNo: Code[20];
    begin
        // [FEATURE] [Production BOM] [Exchange Production BOM Item]
        // [SCENARIO] Exchange Production BOM Item creates new version for phantom BOM, but not for its parent BOM if BOM's active version doesn't contain exchanged item

        // [GIVEN] Production BOM with 1 component "I1"
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        ParentBOMNo := CreateProductionBOM(UnitOfMeasure.Code);
        ChildItemNo := FindProductionBOMComponent(ParentBOMNo);

        // [GIVEN] Version of the BOM with a phantom BOM including the same component "I1" as a child
        // [GIVEN] BOM version structiure: BOM -> Phantom BOM -> Component I1
        PhantomBOMNo := CreateProductionBOMForSingleItem(ChildItemNo, UnitOfMeasure.Code);
        CreateProductionBOMVersion(
          ParentProdBOMVersion, ParentBOMNo, UnitOfMeasure.Code, WorkDate(), ProdBOMLine.Type::"Production BOM", PhantomBOMNo, 1);
        ModifyProductionBOMVersionStatus(ParentProdBOMVersion, ParentProdBOMVersion.Status::Certified);

        // [GIVEN] Item "I2"
        // [WHEN] Run "Exchange Production BOM Item" to replace item "I1" with "I2" and "Create New Version" option
        RunExchangeProdBOMItemReportWithParameters(ChildItemNo, LibraryInventory.CreateItemNo(), true, false);

        // [THEN] Version for parent BOM has not been created
        ParentProdBOMVersion.SetRange("Production BOM No.", ParentBOMNo);
        ParentProdBOMVersion.SetFilter("Version Code", '<>%1', ParentProdBOMVersion."Version Code");
        Assert.AreEqual(0, ParentProdBOMVersion.Count, ProdBOMVersionMustNotExistErr);

        // [THEN] New version of the phantom BOM has been created
        ParentProdBOMVersion.SetRange("Production BOM No.", PhantomBOMNo);
        Assert.AreEqual(1, ParentProdBOMVersion.Count, ProdBOMVersionMustExistErr);
    end;

    [Test]
    [HandlerFunctions('ExchangeProductionBOMItemHandler')]
    [Scope('OnPrem')]
    procedure ExchangeBOMItemCreateNewVersionCopiesActiveBOMVersion()
    var
        UnitOfMeasure: Record "Unit of Measure";
        ProdBomVersion: Record "Production BOM Version";
        ProdBOMHeader: Record "Production BOM Header";
        Components: array[3] of Code[20];
    begin
        // [FEATURE] [Production BOM] [Exchange Production BOM Item]
        // [SCENARIO] Exchange Production BOM Item creates new version of production BOM based on the active BOM version

        // [GIVEN] Production BOM with 1 component "I1"
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        ProdBOMHeader.Get(CreateProductionBOM(UnitOfMeasure.Code));
        Components[1] := FindProductionBOMComponent(ProdBOMHeader."No.");
        Components[2] := LibraryInventory.CreateItemNo();

        // Production BOM version with 2 components: "I1" and "I2", active on the WORKDATE
        CreateProductionBOMVersionWithTwoComponents(
          ProdBomVersion, ProdBOMHeader, ProdBOMHeader."Unit of Measure Code", WorkDate(), Components[1], Components[2]);

        // [GIVEN] Item "I3"
        Components[3] := LibraryInventory.CreateItemNo();

        // [WHEN] Run "Exchange Production BOM Item" to replace item "I1" with "I3" and "Create New Version" option
        RunExchangeProdBOMItemReportWithParameters(Components[1], Components[3], true, false);

        // [THEN] New version created containing two items: "I2" and "I3"
        VerifyProductionBOMLineExists(
          ProdBomVersion."Production BOM No.", FindLastBOMVersionCode(ProdBomVersion."Production BOM No."), Components[2]);
        VerifyProductionBOMLineExists(
          ProdBomVersion."Production BOM No.", FindLastBOMVersionCode(ProdBomVersion."Production BOM No."), Components[3]);
    end;

    [Test]
    [HandlerFunctions('ExchangeProductionBOMItemHandler')]
    [Scope('OnPrem')]
    procedure ExchangeBOMItemCreateNewVersionCopiesBaseListIfVersionInactive()
    var
        UnitOfMeasure: Record "Unit of Measure";
        ProdBomVersion: Record "Production BOM Version";
        ProdBOMHeader: Record "Production BOM Header";
        Components: array[3] of Code[20];
    begin
        // [FEATURE] [Production BOM] [Exchange Production BOM Item]
        // [SCENARIO] Exchange Production BOM Item creates new version of production BOM based on the BOM list if the BOM version is inactive

        // [GIVEN] Production BOM with 1 component "I1"
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        ProdBOMHeader.Get(CreateProductionBOM(UnitOfMeasure.Code));
        Components[1] := FindProductionBOMComponent(ProdBOMHeader."No.");
        Components[2] := LibraryInventory.CreateItemNo();

        // Production BOM version with 2 components: "I1" and "I2", active on WorkDate() + 1 day
        CreateProductionBOMVersionWithTwoComponents(
          ProdBomVersion, ProdBOMHeader, ProdBOMHeader."Unit of Measure Code", CalcDate('<1D>', WorkDate()), Components[1], Components[2]);

        // [GIVEN] Item "I3"
        Components[3] := LibraryInventory.CreateItemNo();

        // [WHEN] Run "Exchange Production BOM Item" to replace item "I1" with "I3" and "Create New Version" option
        RunExchangeProdBOMItemReportWithParameters(Components[1], Components[3], true, false);

        // [THEN] New version created contains item "I3", but does no have "I2"
        VerifyProductionBOMLineNotExists(
          ProdBomVersion."Production BOM No.", FindLastBOMVersionCode(ProdBomVersion."Production BOM No."), Components[2]);
        VerifyProductionBOMLineExists(
          ProdBomVersion."Production BOM No.", FindLastBOMVersionCode(ProdBomVersion."Production BOM No."), Components[3]);
    end;

    [Test]
    [HandlerFunctions('DummyProdOrderRoutingHandler')]
    [Scope('OnPrem')]
    procedure ProdOrderRoutingPageDoesNotUpdateBinCodeInMultilevelOrder()
    var
        ProdOrderLine: array[2] of Record "Prod. Order Line";
        WorkCenter: Record "Work Center";
        ProdOrderComponent: Record "Prod. Order Component";
        Location: Record Location;
        Bin: array[2] of Record Bin;
        RoutingRefNo: Integer;
    begin
        // [FEATURE] [Warehouse] [Bin] [Routing]
        // [SCENARIO 360012] Bin Code is not updated in a prod. order line when opening prod. order routing page if "Planning Level Code" > 0

        // [GIVEN] Create location "L" with 2 bins: "B1" and "B2". Set "From-Production Bin Code" = "B2"
        // [GIVEN] Create multilevel production order on location "L"
        CreateProdOrderLineWithWhiteLocationAndUpdateWorkCenterBinCode(ProdOrderLine[1], WorkCenter, RoutingRefNo);

        Location.Get(ProdOrderLine[1]."Location Code");
        LibraryWarehouse.CreateBin(Bin[1], Location.Code, LibraryUtility.GenerateGUID(), '', '');
        LibraryWarehouse.CreateBin(Bin[2], Location.Code, LibraryUtility.GenerateGUID(), '', '');
        Location."From-Production Bin Code" := Bin[2].Code;
        Location.Modify();

        ProdOrderLine[2] := ProdOrderLine[1];
        ProdOrderLine[2]."Line No." := ProdOrderLine[1]."Line No." + 10000;
        ProdOrderLine[2]."Planning Level Code" := ProdOrderLine[1]."Planning Level Code" + 1;
        ProdOrderLine[2]."Bin Code" := Bin[1].Code;
        ProdOrderLine[2].Insert();

        // [GIVEN] Set bin code = "B1" on production order line
        FindProductionOrderComponent(ProdOrderComponent, ProdOrderLine[1].Status, ProdOrderLine[1]."Prod. Order No.");
        ProdOrderComponent."Bin Code" := Bin[1].Code;
        ProdOrderComponent."Supplied-by Line No." := ProdOrderLine[2]."Line No.";
        ProdOrderComponent.Modify();

        // [WHEN] Open prod. order routing for the low-level line
        ProdOrderLine[2].ShowRouting();
        ProdOrderLine[2].Find();

        // [THEN] Bin code in production order line is "B1"
        ProdOrderLine[2].TestField("Bin Code", ProdOrderComponent."Bin Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GlobalDimensionsInOutputJournalLineAreUpdatedOnExplodingRouting()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemJournalBatch: Record "Item Journal Batch";
        DimensionValue: array[2] of Record "Dimension Value";
    begin
        // [FEATURE] [Item Journal] [Dimension]
        // [SCENARIO 380531] Shortcut Dimension 1 & 2 codes are populated from Prod. Order Line on exploding Routing in Output Journal.
        Initialize();

        // [GIVEN] Global Dimension Values "GV1" and "GV2".
        // [GIVEN] Production Item "I" with Routing and BOM.
        // [GIVEN] Prod. Order Line of Item "I" with Global Dimensions Values "GV1" and "GV2".
        CreateProdOrderLineWithGlobalDims(ProductionOrder, ProdOrderLine, DimensionValue);

        // [WHEN] Create Output Journal Line and explode Routing.
        OutputJournalExplodeRouting(ItemJournalBatch, ProductionOrder);

        // [THEN] All Output Journal Lines have Shortcut Dimension 1 & 2 codes populated with "GV1" and "GV2" values correspondingly.
        VerifyGlobalDimensionCodesInItemJournalBatch(ItemJournalBatch, DimensionValue[1].Code, DimensionValue[2].Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GlobalDimensionsInOutputJournalLineAreUpdatedOnValidatingWorkCenterNo()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        DimensionValue: array[2] of Record "Dimension Value";
    begin
        // [FEATURE] [Item Journal] [Dimension]
        // [SCENARIO 380531] Shortcut Dimension 1 & 2 codes are populated from Prod. Order Line on validating Work/Machine Center in Output Journal.
        Initialize();

        // [GIVEN] Global Dimension Values "GV1" and "GV2".
        // [GIVEN] Production Item "I" with Routing and BOM.
        // [GIVEN] Prod. Order Line of Item "I" with Global Dimensions Values "GV1" and "GV2".
        CreateProdOrderLineWithGlobalDims(ProductionOrder, ProdOrderLine, DimensionValue);

        // [GIVEN] Output Journal Line with Production Order No. and Routing fields populated.
        CreateOutputJournal(ItemJournalBatch, ItemJournalLine, ProductionOrder."No.");
        PopulateRoutingOnOutputJournalLine(ItemJournalLine, ProdOrderRoutingLine, ProdOrderLine);

        // [WHEN] Validate production capacity No. on the Output Line.
        ItemJournalLine.Validate("No.", ProdOrderRoutingLine."No.");

        // [THEN] Output Journal Line has Shortcut Dimension 1 & 2 codes populated with "GV1" and "GV2" values correspondingly.
        ItemJournalLine.TestField("Shortcut Dimension 1 Code", DimensionValue[1].Code);
        ItemJournalLine.TestField("Shortcut Dimension 2 Code", DimensionValue[2].Code);
    end;

    [Test]
    [HandlerFunctions('ProductionJournalHandler,ConfirmHandlerTrue,MessageHandler,ViewAppliedEntriesPageHandler2,ViewAppliedEntriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure ApplicationWorkSheetUndoManualChanges()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        SalesHeader: Record "Sales Header";
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        ProductionJournalMgt: Codeunit "Production Journal Mgt";
        ApplicationWorksheet: TestPage "Application Worksheet";
    begin
        // [FEATURE] [Manufacturing] [Application Worksheet]
        // [SCENARIO 375807] User actions in Application Worksheet cannot result in negative Item Ledger Entries of type Consumption.

        // [GIVEN] Purchased Item, Consumption posted (applied to purchase) and Sales Order posted (negative).
        Initialize();
        CreateInitialSetupForReleasedProductionOrder(ProductionOrder, ProdOrderComponent);
        ProductionJournalMgt.Handling(ProductionOrder, ProdOrderComponent."Prod. Order Line No.");
        CreateAndPostSalesOrder(
          SalesHeader, ProdOrderComponent."Item No.", ProdOrderComponent."Expected Quantity");

        SaveExistingILEs(TempItemLedgEntry, ProdOrderComponent."Item No.");

        // [GIVEN] In Application Worksheet Consumption unapplied, Sale applied to Purchase
        ApplicationWorksheet.OpenEdit();
        ApplicationWorksheet.FILTER.SetFilter("Item No.", ProdOrderComponent."Item No.");

        ApplicationWorksheet.First();
        while ApplicationWorksheet."Entry Type".AsInteger() <> TempItemLedgEntry."Entry Type"::Consumption.AsInteger() do
            if not ApplicationWorksheet.Next() then
                Error(EntryOfTypeNotFoundErr, TempItemLedgEntry."Entry Type"::Consumption);
        ApplicationWorksheet.AppliedEntries.Invoke();

        ApplicationWorksheet.First();
        while ApplicationWorksheet."Entry Type".AsInteger() <> TempItemLedgEntry."Entry Type"::Sale.AsInteger() do
            if not ApplicationWorksheet.Next() then
                Error(EntryOfTypeNotFoundErr, TempItemLedgEntry."Entry Type"::Sale);
        ApplicationWorksheet.UnappliedEntries.Invoke();

        Commit();

        // [GIVEN] 'Reapply All' gives an error, due to negative Consumption entry.
        asserterror ApplicationWorksheet.Reapply.Invoke(); // Reapply All
        Assert.ExpectedError(CannotUnapplyItemLedgEntryErr);

        // [WHEN] 'Undo Manual Changes' invoked.
        ApplicationWorksheet.UndoApplications.Invoke();

        // [THEN] Item Ledger Entries are reverted to previous state.
        VerifyExistingILEs(TempItemLedgEntry, ProdOrderComponent."Item No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemLedgEntryUndoApplicationPositive()
    var
        PositiveItemLedgEntry: Record "Item Ledger Entry";
        NegativeItemLedgEntry: Record "Item Ledger Entry";
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        ItemNo: Code[20];
    begin
        // [FEATURE] [Manufacturing] [Application Worksheet]
        // [SCENARIO 375807] Item Ledger Entries are reverted to previous state after ReApply negative entry to positive one with LogApply and UndoApplications.

        // [GIVEN] Item with 2 Item Ledger Entries: positive "P" and negative "N", not applied.
        Initialize();
        ItemNo := PrepareUndoApplication();
        FindILE(PositiveItemLedgEntry, ItemNo, PositiveItemLedgEntry."Entry Type"::Purchase);
        FindILE(NegativeItemLedgEntry, ItemNo, NegativeItemLedgEntry."Entry Type"::Sale);
        Unapply(PositiveItemLedgEntry."Entry No.", NegativeItemLedgEntry."Entry No.");

        SaveExistingILEs(TempItemLedgEntry, ItemNo);

        // [GIVEN] Reapply "N" to "P" and log.
        ItemJnlPostLine.ReApply(PositiveItemLedgEntry, NegativeItemLedgEntry."Entry No.");
        ItemJnlPostLine.LogApply(PositiveItemLedgEntry, NegativeItemLedgEntry);

        // [WHEN] Undo applications.
        ItemJnlPostLine.UndoApplications();

        // [THEN] "P" and "N" are reverted to previous state.
        VerifyExistingILEs(TempItemLedgEntry, ItemNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemLedgEntryUndoApplicationNegative()
    var
        PositiveItemLedgEntry: Record "Item Ledger Entry";
        NegativeItemLedgEntry: Record "Item Ledger Entry";
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        ItemNo: Code[20];
    begin
        // [FEATURE] [Manufacturing] [Application Worksheet]
        // [SCENARIO 375807] Item Ledger Entries are reverted to previous state after ReApply positive entry to negative one with LogApply and UndoApplications.

        // [GIVEN] Item with 2 Item Ledger Entries: positive "P" and negative "N", not applied.
        Initialize();
        ItemNo := PrepareUndoApplication();
        FindILE(PositiveItemLedgEntry, ItemNo, PositiveItemLedgEntry."Entry Type"::Purchase);
        FindILE(NegativeItemLedgEntry, ItemNo, NegativeItemLedgEntry."Entry Type"::Sale);
        Unapply(PositiveItemLedgEntry."Entry No.", NegativeItemLedgEntry."Entry No.");
        FindILE(NegativeItemLedgEntry, ItemNo, NegativeItemLedgEntry."Entry Type"::Sale);

        SaveExistingILEs(TempItemLedgEntry, ItemNo);

        // [GIVEN] Reapply "P" to "N" and log.
        ItemJnlPostLine.ReApply(NegativeItemLedgEntry, PositiveItemLedgEntry."Entry No.");
        ItemJnlPostLine.LogApply(NegativeItemLedgEntry, PositiveItemLedgEntry);

        // [WHEN] Undo applications.
        ItemJnlPostLine.UndoApplications();

        // [THEN] "P" and "N" are reverted to previous state.
        VerifyExistingILEs(TempItemLedgEntry, ItemNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemLedgEntryUndoUnapplicationPositive()
    var
        PositiveItemLedgEntry: Record "Item Ledger Entry";
        NegativeItemLedgEntry: Record "Item Ledger Entry";
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        ItemApplnEntry: Record "Item Application Entry";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        ItemNo: Code[20];
    begin
        // [FEATURE] [Manufacturing] [Application Worksheet]
        // [SCENARIO 375807] Item Ledger Entries are reverted to previous state after UnApply with LogUnapply and UndoApplications.

        // [GIVEN] Item with 2 Item Ledger Entries: positive "P" and negative "N", fully applied.
        Initialize();
        ItemNo := PrepareUndoApplication();
        FindILE(PositiveItemLedgEntry, ItemNo, PositiveItemLedgEntry."Entry Type"::Purchase);
        FindILE(NegativeItemLedgEntry, ItemNo, NegativeItemLedgEntry."Entry Type"::Sale);

        SaveExistingILEs(TempItemLedgEntry, ItemNo);
        // [GIVEN] Unapply "N" and "P" and log.
        ItemApplnEntry.SetRange("Inbound Item Entry No.", PositiveItemLedgEntry."Entry No.");
        ItemApplnEntry.SetRange("Outbound Item Entry No.", NegativeItemLedgEntry."Entry No.");
        ItemApplnEntry.FindFirst();
        ItemJnlPostLine.UnApply(ItemApplnEntry);
        ItemJnlPostLine.LogUnapply(ItemApplnEntry);

        // [WHEN] Undo unapplication.
        ItemJnlPostLine.UndoApplications();

        // [THEN] "P" and "N" are reverted to previous state.
        VerifyExistingILEs(TempItemLedgEntry, ItemNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteItemExistingInCertifiedProdBOMVersionIsNotAllowed()
    var
        Item: Record Item;
        ProductionBOMVersion: Record "Production BOM Version";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 381274] User should not be able to delete Item if it is added to Production BOM Version with Status = "Certified"
        Initialize();

        // [GIVEN] Certified Production BOM Version for Item "X"
        LibraryInventory.CreateItem(Item);
        MockProdBOMHeaderWithVersionForItem(ProductionBOMVersion, Item."No.", ProductionBOMVersion.Status::Certified);

        // [WHEN] Delete Item "X"
        asserterror Item.Delete(true);

        // [THEN] Error raised that you cannot delete Item because it exists in certified Production BOM Version
        Assert.ExpectedError(StrSubstNo(CannotDeleteItemIfProdBOMVersionExistsErr, Item.TableCaption(), Item."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteItemExistingInNotCertifiedProdBOMVersionIsAllowed()
    var
        Item: Record Item;
        ProductionBOMVersion: Record "Production BOM Version";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 381274] User should be able to delete Item if it is added to Production BOM Version with Status = "Under Development"
        Initialize();

        // [GIVEN] Production BOM Version with Status = "Under Development" for Item "X"
        LibraryInventory.CreateItem(Item);
        MockProdBOMHeaderWithVersionForItem(ProductionBOMVersion, Item."No.", ProductionBOMVersion.Status::"Under Development");

        // [WHEN] Delete Item "X"
        Item.Delete(true);

        // [THEN] Item "X" successfully deleted
        Assert.IsFalse(Item.Find(), 'Item should be deleted');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshProductionOrderWithSourceTypeSalesHeaderTwoLinesDifferentLocations()
    var
        SalesLine: array[2] of Record "Sales Line";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        Item: array[2] of Record Item;
        BOMNo: Code[20];
        i: Integer;
    begin
        // [FEATURE] [Production Order] [Source Type]
        // [SCENARIO 381335] Production Order can be refreshed when it has "Source Type" = "Sales Header", corresponding Sales Order contains two lines with different locations and one item is BOM component of another.
        Initialize();
        // [GIVEN] Two Items A and B with "Replenishment System" = "Prod. Order" and "Manufacturing Policy" = "Make-to-Order"
        for i := 1 to 2 do
            CreateItemWithReplenishmentSystemAndManufacturingPolicy(
              Item[i], Item[i]."Replenishment System"::"Prod. Order", Item[i]."Manufacturing Policy"::"Make-to-Order");

        // [GIVEN] Item A is the BOM component of Item B
        BOMNo := CreateProductionBOMForSingleItem(Item[1]."No.", Item[1]."Base Unit of Measure");
        Item[2].Validate("Production BOM No.", BOMNo);
        Item[2].Modify(true);

        // [GIVEN] Released Sales Order S with two lines for items A and B, locations in lines are different
        CreateSalesOrderLinesAtLocations(SalesLine, Item, 2, true);

        // [GIVEN] Released Production Order P with "Source Type" = "Sales Header", "Source No." = S."No."
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released,
          ProductionOrder."Source Type"::"Sales Header", SalesLine[1]."Document No.", LibraryRandom.RandInt(5));

        // [WHEN] Refresh Production Order P
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        for i := 1 to 2 do begin
            // [THEN] Production Order Line L with corresponding Location Code for each Item A and B exists
            FindProdOrderLineByItemNoLocationCodeAndPlanningLevelCode(ProdOrderLine, Item[i]."No.", SalesLine[i]."Location Code", 0);

            // [THEN] Locations and Quantities in L are corresponding to the ones of Sales Order S lines
            ProdOrderLine.TestField(Quantity, SalesLine[i].Quantity);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshProductionOrderMultiLevelStructureWithSourceTypeSalesHeaderMultipleLinesAtDifferentLocations()
    var
        SalesLine: array[4] of Record "Sales Line";
        ProductionOrder: Record "Production Order";
        Item: array[4] of Record Item;
        i: Integer;
    begin
        // [FEATURE] [Production Order] [Source Type]
        // [SCENARIO 382024] Multi-level structure is created according to the BOM and the locations for a Production Order where a Sales Order with different locations in lines is a Source.
        Initialize();

        // [GIVEN] 4 Items with "Replenishment System" = "Prod. Order", "Manufacturing Policy" = "Make-to-Order" : I1, I2, I3, I4.
        for i := 1 to 4 do
            CreateItemWithReplenishmentSystemAndManufacturingPolicy(
              Item[i], Item[i]."Replenishment System"::"Prod. Order", Item[i]."Manufacturing Policy"::"Make-to-Order");

        // [GIVEN] I2 has I3 and I4 as BOM components B-2-3, B-2-4.
        SetNewProductionBOMToItemForArrayOfChildItems(Item[2], Item, 3, 4);

        // [GIVEN] I1 has I2, I3 and I4 as BOM components B-1-2, B-1-3, B-1-4.
        SetNewProductionBOMToItemForArrayOfChildItems(Item[1], Item, 2, 4);

        // [GIVEN] Released Sales Order S with 4 lines SL_A_I1, SL_B_I2, SL_C_I3, SL_D_I4 for Items I1, I2, I3, I4 at 4 different locations A, B, C, D.
        CreateSalesOrderLinesAtLocations(SalesLine, Item, 4, true);

        // [GIVEN] Released Production Order P with "Source Type" = "Sales Header", "Source No." = S."No."
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released,
          ProductionOrder."Source Type"::"Sales Header", SalesLine[1]."Document No.", LibraryRandom.RandInt(5));

        // [WHEN] Refresh Production Order P
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [THEN] Production Order has 9 Lines at Location A - D for the component I1 - I4 with Planning Level Code 0 - 2 :

        // [THEN] Planning Level Code 0 for Locations A - D for Items I1 - I4 : PL-A-0-I1, PL-B-0-I2, PL-C-0-I3, PL-D-0-I4
        // [THEN] Planning Level Code 1 for Locations A - B for Items I2 - I4 :            PL-A-1-I2, PL-B-1-I3, PL-B-1-I4
        // [THEN] Planning Level Code 2 for Location      A for Items I3 - I4 :                       PL-A-2-I3, PL-A-2-I4

        // [THEN] PL-A-0-I1."Quantity (Base)" = SL_A_I1."Quantity (Base)"
        // [THEN] PL-B-0-I2."Quantity (Base)" = SL_B_I2."Quantity (Base)"
        // [THEN] PL-C-0-I3."Quantity (Base)" = SL_C_I3."Quantity (Base)"
        // [THEN] PL-D-0-I4."Quantity (Base)" = SL_D_I4."Quantity (Base)"
        // [THEN] PL-A-1-I2."Quantity (Base)" = SL_A_I1."Quantity (Base)" * B-1-2."Quantity per"
        // [THEN] PL-B-1-I3."Quantity (Base)" = SL_B_I2."Quantity (Base)" * B-1-3."Quantity per"
        // [THEN] PL-B-1-I4."Quantity (Base)" = SL_B_I2."Quantity (Base)" * B-1-4."Quantity per"
        // [THEN] PL-A-2-I3."Quantity (Base)" = SL_A_I1."Quantity (Base)" * B-1-2."Quantity per" * B-2-3."Quantity per"
        // [THEN] PL-A-2-I4."Quantity (Base)" = SL_A_I1."Quantity (Base)" * B-1-2."Quantity per" * B-2-4."Quantity per"

        VerifyProductionOrderLineToSalesLineMultiLevelStructureWhenAllLocationsAreDifferent(Item, SalesLine, 0, 1, 0, 0);
        VerifyProductionOrderLineToSalesLineMultiLevelStructureWhenAllLocationsAreDifferent(Item, SalesLine, 0, 2, 0, 0);
        VerifyProductionOrderLineToSalesLineMultiLevelStructureWhenAllLocationsAreDifferent(Item, SalesLine, 0, 3, 0, 0);
        VerifyProductionOrderLineToSalesLineMultiLevelStructureWhenAllLocationsAreDifferent(Item, SalesLine, 0, 4, 0, 0);
        VerifyProductionOrderLineToSalesLineMultiLevelStructureWhenAllLocationsAreDifferent(Item, SalesLine, 1, 1, 2, 0);
        VerifyProductionOrderLineToSalesLineMultiLevelStructureWhenAllLocationsAreDifferent(Item, SalesLine, 1, 2, 3, 0);
        VerifyProductionOrderLineToSalesLineMultiLevelStructureWhenAllLocationsAreDifferent(Item, SalesLine, 1, 2, 4, 0);
        VerifyProductionOrderLineToSalesLineMultiLevelStructureWhenAllLocationsAreDifferent(Item, SalesLine, 2, 1, 2, 3);
        VerifyProductionOrderLineToSalesLineMultiLevelStructureWhenAllLocationsAreDifferent(Item, SalesLine, 2, 1, 2, 4);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshProductionOrderMultiLevelStructureCollapsingWithSourceTypeSalesHeaderMultipleLinesAtOneLocation()
    var
        SalesLine: array[2] of Record "Sales Line";
        ProductionBOMLine: array[2] of Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        Item: array[3] of Record Item;
        i: Integer;
    begin
        // [FEATURE] [Production Order] [Source Type]
        // [SCENARIO 382024] Multi-level structure is created according to the BOM where a Sales Order with lines at one location is a Source, component line of Production Order is collapsed.
        Initialize();

        // [GIVEN] 3 Items with "Replenishment System" = "Prod. Order", "Manufacturing Policy" = "Make-to-Order" : I1, I2, I3.
        for i := 1 to 3 do
            CreateItemWithReplenishmentSystemAndManufacturingPolicy(
              Item[i], Item[i]."Replenishment System"::"Prod. Order", Item[i]."Manufacturing Policy"::"Make-to-Order");

        // [GIVEN] I1 has I3 as a BOM component BL1.
        SetNewProductionBOMToItemForArrayOfChildItems(Item[1], Item, 3, 3);

        // [GIVEN] I2 also has I3 as a BOM component BL2.
        SetNewProductionBOMToItemForArrayOfChildItems(Item[2], Item, 3, 3);

        // [GIVEN] Released Sales Order S with 2 lines SL1 and SL2  for Items I1 and I2 at one location.
        CreateSalesOrderLinesAtLocations(SalesLine, Item, 2, false);

        // [GIVEN] Released Production Order P with "Source Type" = "Sales Header", "Source No." = S."No."
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released,
          ProductionOrder."Source Type"::"Sales Header", SalesLine[1]."Document No.", LibraryRandom.RandInt(5));

        // [WHEN] Refresh Production Order P
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [THEN] Production Order Line PL1 for I1 has "Planning Level Code" = 0 and PL1."Quantity (Base)" = SL1."Quantity (Base)".
        FindProdOrderLineByItemNoLocationCodeAndPlanningLevelCode(ProdOrderLine, Item[1]."No.", SalesLine[1]."Location Code", 0);
        Assert.RecordCount(ProdOrderLine, 1);
        ProdOrderLine.TestField("Quantity (Base)", SalesLine[1]."Quantity (Base)");

        // [THEN] Production Order Line PL2 for I2 has "Planning Level Code" = 0 and PL2."Quantity (Base)" = SL2."Quantity (Base)".
        FindProdOrderLineByItemNoLocationCodeAndPlanningLevelCode(ProdOrderLine, Item[2]."No.", SalesLine[2]."Location Code", 0);
        Assert.RecordCount(ProdOrderLine, 1);
        ProdOrderLine.TestField("Quantity (Base)", SalesLine[2]."Quantity (Base)");

        for i := 1 to 2 do
            FindProductionBOMLine(ProductionBOMLine[i], Item[i]."Production BOM No.");

        // [THEN] Production Order Line for PL3 the component I3 has Planning Level Code = 1 and PL3."Quantity (Base)" = [BL1."Quantity per" * SL1."Quantity (Base)"  + BL2."Quantity per" * SL2."Quantity (Base)"].
        FindProdOrderLineByItemNoLocationCodeAndPlanningLevelCode(ProdOrderLine, Item[3]."No.", SalesLine[i]."Location Code", 1);
        Assert.RecordCount(ProdOrderLine, 1);
        ProdOrderLine.TestField(
          "Quantity (Base)", SalesLine[1]."Quantity (Base)" * ProductionBOMLine[1]."Quantity per" +
          SalesLine[2]."Quantity (Base)" * ProductionBOMLine[2]."Quantity per");
    end;

    [Test]
    [HandlerFunctions('ExchangeProductionBOMItemHandler')]
    [Scope('OnPrem')]
    procedure ExchangeBOMItemCreateNewVersionWhenVersionCodeIsIncompatibleWithINCSTRFunction()
    var
        UnitOfMeasure: Record "Unit of Measure";
        ProdBomVersion: Record "Production BOM Version";
        ProdBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        Components: array[3] of Code[20];
    begin
        // [FEATURE] [Production BOM] [Exchange Production BOM Item]
        // [SCENARIO 381449] Exchange Production BOM Item creates new version of production BOM based on the active BOM version when INCSTR function for "Version Code" returns the value which already exists for "Production BOM No."
        // [GIVEN] Production BOM with component "I1"
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        ProdBOMHeader.Get(CreateProductionBOM(UnitOfMeasure.Code));
        Components[1] := FindProductionBOMComponent(ProdBOMHeader."No.");

        // [GIVEN] Items "I2" and "I3"
        Components[2] := LibraryInventory.CreateItemNo();
        Components[3] := LibraryInventory.CreateItemNo();

        // [GIVEN] Production BOM version with "Version Code" = '9'
        CreateNamedProductionBOMVersion(
          ProdBomVersion, ProdBOMHeader."No.", ProdBOMHeader."Unit of Measure Code",
          WorkDate(), ProductionBOMLine.Type::Item, Components[1], 1, '9');

        // [WHEN] Run "Exchange Production BOM Item" twice with "Create New Version" option to replace item "I1" with "I2" first time and to replace item "I2" with "I3" second time
        RunExchangeProdBOMItemReportWithParameters(Components[1], Components[2], true, false);
        RunExchangeProdBOMItemReportWithParameters(Components[2], Components[3], true, false);

        // [THEN] New version with "Version Code" = '11' created containing item "I3"
        ProductionBOMLine.SetRange("Production BOM No.", ProdBOMHeader."No.");
        ProductionBOMLine.SetRange("Version Code", '11');
        ProductionBOMLine.SetRange(Type, ProductionBOMLine.Type::Item);
        ProductionBOMLine.SetRange("No.", Components[3]);
        Assert.RecordIsNotEmpty(ProductionBOMLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultDimensionsForWorkcenterInvokedFromListAreFiltered()
    var
        WorkCenter: Record "Work Center";
        DefaultDimension: Record "Default Dimension";
        WorkCenterList: TestPage "Work Center List";
        DefaultDimensions: TestPage "Default Dimensions";
    begin
        // [FEATURE] [Work Center] [Default Dimension] [UI]
        // [SCENARIO 204230] Set of default dimensions filtered by current Work Center No. should be invoked when clicking on Dimension-Single button on Work Center list page.
        Initialize();

        // [GIVEN] Work Center "X" with default dimension code "DCod" and value "DVal".
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryDimension.CreateDefaultDimensionWithNewDimValue(
          DefaultDimension, DATABASE::"Work Center", WorkCenter."No.", DefaultDimension."Value Posting"::" ");

        // [GIVEN] List of work centers is opened. Work Center "X" is selected on the list.
        WorkCenterList.OpenView();
        WorkCenterList.GotoRecord(WorkCenter);
        DefaultDimensions.Trap();

        // [WHEN] Click on "Dimensions-Single" button on the page's ribbon.
        WorkCenterList."Dimensions-Single".Invoke();

        // [THEN] Default Dimensions page is opened.
        // [THEN] Dimension "DCod" with "DVal" value is shown.
        DefaultDimensions.Last();
        DefaultDimensions."Dimension Code".AssertEquals(DefaultDimension."Dimension Code");
        DefaultDimensions."Dimension Value Code".AssertEquals(DefaultDimension."Dimension Value Code");

        // [THEN] No other dimension codes and values are shown on the page.
        Assert.IsFalse(DefaultDimensions.Previous(), 'Wrong set of default dimensions is shown for the work center');

        // [THEN] The page is filtered by Work Center table ID and the number of work center "X".
        Assert.AreEqual(
          Format(DATABASE::"Work Center"), DefaultDimensions.FILTER.GetFilter("Table ID"),
          'Default dimensions are filtered by wrong table ID.');
        Assert.AreEqual(
          WorkCenter."No.", DefaultDimensions.FILTER.GetFilter("No."), 'Default dimensions are filtered by wrong work center no.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ConsumeCapacityOnCCRWorkCenterBetweenAllocatedTimeBackwardPlanning()
    var
        RoutingHeader: Record "Routing Header";
        Item: Record Item;
        ProductionOrder: array[3] of Record "Production Order";
    begin
        // [FEATURE] [Production Order] [Capacity Constrained Resource]
        // [SCENARIO] When a capacity constrained resource has allocated capacity on the beginning and end of a day, new capacity should be allocated before the last allocated time on the same date on backward planning

        Initialize();

        // [GIVEN] Work center "CCR" configured as a capacity constrained resource with 8-hour working day from 08:00 to 16:00, 100% capacity
        CreateRoutingOnCapacityConstrainedWorkCenter(RoutingHeader, LibraryRandom.RandIntInRange(10, 20));

        // [GIVEN] Item produced on the capacity constrained work center, Run Time = 10 minutes
        CreateItemWithRouting(Item, RoutingHeader."No.");

        // [GIVEN] Create and refresh a production order that will consume 10 minutes on the "CCR" work center: from 23.01.2019 15:50 to 23.01.2019 16:00
        CreateAndRefreshProductionOrderWithItem(ProductionOrder[1], ProductionOrder[1].Status::Released, Item."No.", 1);
        // [GIVEN] Create and refresh a production order, set starting time to 08:00. New order will consume 10 minutes on the "CCR" work center: from 23.01.2019 08:00 to 23.01.2019 08:10
        CreateReleasedProdOrderWithCustomStartingTime(ProductionOrder[2], Item."No.", 1, 080000T);

        // [WHEN] Create and refresh backward the third prodution order.
        CreateAndRefreshProductionOrderWithItem(ProductionOrder[3], ProductionOrder[3].Status::Released, Item."No.", 1);

        // [THEN] The last order consumes available capacity between the first two orders. Starting time = 15:40, Ending time = 15:50
        ProductionOrder[3].CalcFields("Allocated Capacity Need");
        ProductionOrder[3].TestField("Starting Date", ProductionOrder[1]."Starting Date");
        ProductionOrder[3].TestField("Ending Date", ProductionOrder[1]."Ending Date");
        ProductionOrder[3].TestField(
          "Starting Time", ProductionOrder[1]."Starting Time" - ProductionOrder[3]."Allocated Capacity Need" * 60000);
        ProductionOrder[3].TestField("Ending Time", ProductionOrder[1]."Starting Time");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ConsumeCapacityOnCCRWorkCenterBetweenAllocatedTimeForwardPlanning()
    var
        RoutingHeader: Record "Routing Header";
        Item: Record Item;
        ProductionOrder: array[3] of Record "Production Order";
    begin
        // [FEATURE] [Production Order] [Capacity Constrained Resource]
        // [SCENARIO] When a capacity constrained resource has allocated capacity on the beginning and end of a day, new capacity should be allocated after the first allocated time on the same date on forward planning

        Initialize();

        // [GIVEN] Work center "CCR" configured as a capacity constrained resource with 8-hour working day from 08:00 to 16:00, 100% capacity
        CreateRoutingOnCapacityConstrainedWorkCenter(RoutingHeader, LibraryRandom.RandIntInRange(10, 20));

        // [GIVEN] Item produced on the capacity constrained work center, Run Time = 10 minutes
        CreateItemWithRouting(Item, RoutingHeader."No.");

        // [GIVEN] Create and refresh a production order that will consume 10 minutes on the "CCR" work center: from 23.01.2019 15:50 to 23.01.2019 16:00
        CreateAndRefreshProductionOrderWithItem(ProductionOrder[1], ProductionOrder[1].Status::Released, Item."No.", 1);
        // [GIVEN] Create and refresh a production order, set starting time to 08:00. New order will consume 10 minutes on the "CCR" work center: from 23.01.2019 08:00 to 23.01.2019 08:10
        CreateReleasedProdOrderWithCustomStartingTime(ProductionOrder[2], Item."No.", 1, 080000T);

        // Create the third production order, set starting time = 08:00
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder[3], ProductionOrder[3].Status::Released, ProductionOrder[3]."Source Type"::Item, Item."No.", 1);

        // [WHEN] Refresh the prodution order forward.
        LibraryManufacturing.RefreshProdOrder(ProductionOrder[3], true, true, true, true, false);

        // [THEN] The last order consumes available capacity between the first two orders. Starting time = 08:00, Ending time = 08:20
        ProductionOrder[3].Find();
        ProductionOrder[3].CalcFields("Allocated Capacity Need");
        ProductionOrder[3].TestField("Starting Date", ProductionOrder[2]."Starting Date");
        ProductionOrder[3].TestField("Ending Date", ProductionOrder[2]."Ending Date");
        ProductionOrder[3].TestField("Starting Time", ProductionOrder[2]."Starting Time");
        ProductionOrder[3].TestField(
          "Ending Time", ProductionOrder[2]."Ending Time" + ProductionOrder[3]."Allocated Capacity Need" * 60000);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderPlanningCreatesSeparateProdOrderLinesForLocations()
    var
        Item: array[4] of Record Item;
        Location: array[2] of Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ProductionOrder: Record "Production Order";
    begin
        // [FEATURE] [Location] [Sales Order Planning]
        // [SCENARIO 216835] Sales order planning should create a separate production order line for a manufactured subcomponent when sold items are on different locations

        // [GIVEN] Low-level component "C"
        LibraryInventory.CreateItem(Item[1]);

        // [GIVEN] Mid-level component "M" with "Make-to-Order" manufacturing policy. Component "M" includes the item "C" in its production BOM
        CreateItemWithReorderingPolicy(
          Item[2], Item[2]."Replenishment System"::"Prod. Order", Item[2]."Manufacturing Policy"::"Make-to-Order", '',
          CreateProductionBOMForSingleItem(Item[1]."No.", Item[1]."Base Unit of Measure"), '');

        // [GIVEN] High-level products "P1" and "P2", both having manufacturing policy "Make-to-Order" and including the component "M"
        CreateItemWithReorderingPolicy(
          Item[3], Item[3]."Replenishment System"::"Prod. Order", Item[3]."Manufacturing Policy"::"Make-to-Order", '',
          CreateProductionBOMForSingleItem(Item[2]."No.", Item[2]."Base Unit of Measure"), '');

        CreateItemWithReorderingPolicy(
          Item[4], Item[4]."Replenishment System"::"Prod. Order", Item[4]."Manufacturing Policy"::"Make-to-Order", '',
          CreateProductionBOMForSingleItem(Item[2]."No.", Item[2]."Base Unit of Measure"), '');

        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[1]);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[2]);

        // [GIVEN] Sales order with two lines: the first line with item "P1" on location "BLUE", the second - item "P2" on location "RED"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item[3]."No.", 10);
        SalesLine.Validate("Location Code", Location[1].Code);
        SalesLine.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item[4]."No.", 10);
        SalesLine.Validate("Location Code", Location[2].Code);
        SalesLine.Modify(true);

        // [WHEN] Run "Create Production Order" from the sales order
        LibraryManufacturing.CreateProductionOrderFromSalesOrder(
            SalesHeader, ProductionOrder.Status::Released, "Create Production Order Type"::ProjectOrder);

        // [THEN] Production order with 4 lines is created:
        // [THEN] 1 production order line for item "P1" on "BLUE" location
        VerifyProdOrderLinesCount(Item[3]."No.", Location[1].Code, '', 1);
        // [THEN] 1 production order line for item "P2" on "RED" location
        VerifyProdOrderLinesCount(Item[4]."No.", Location[2].Code, '', 1);
        // [THEN] 1 production order line for item "M" on "BLUE" location
        VerifyProdOrderLinesCount(Item[2]."No.", Location[1].Code, '', 1);
        // [THEN] 1 production order line for item "M" on "RED" location
        VerifyProdOrderLinesCount(Item[2]."No.", Location[2].Code, '', 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderPlanningCreatesSeparateProdOrderLinesForVariants()
    var
        Item: array[4] of Record Item;
        ItemVariant: array[2] of Record "Item Variant";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ProductionOrder: Record "Production Order";
    begin
        // [FEATURE] [Item Variant] [Sales Order Planning]
        // [SCENARIO 216835] Sales order planning should create a separate production order line for a manufactured subcomponent when the sold item is presented in different variants in sales order lines

        // [GIVEN] Low-level component "C"
        LibraryInventory.CreateItem(Item[1]);

        // [GIVEN] Mid-level component "M" with "Make-to-Order" manufacturing policy. Component "M" includes the item "C" in its production BOM
        CreateItemWithReorderingPolicy(
          Item[2], Item[2]."Replenishment System"::"Prod. Order", Item[2]."Manufacturing Policy"::"Make-to-Order", '',
          CreateProductionBOMForSingleItem(Item[1]."No.", Item[1]."Base Unit of Measure"), '');

        // [GIVEN] Item "M" has two variants "V1" and "V2"
        LibraryInventory.CreateItemVariant(ItemVariant[1], Item[2]."No.");
        LibraryInventory.CreateItemVariant(ItemVariant[2], Item[2]."No.");

        // [GIVEN] High-level product "P1" has manufacturing policy "Make-to-Order" and includs the component "M" in variant "V1"
        CreateProductionBOMForSingleItemWithVariant(
          Item[3], Item[2]."Base Unit of Measure", Item[2]."No.", ItemVariant[1].Code, LibraryRandom.RandInt(20));

        // [GIVEN] High-level product "P2" has manufacturing policy "Make-to-Order" and includs the component "M" in variant "V2"
        CreateProductionBOMForSingleItemWithVariant(
          Item[4], Item[2]."Base Unit of Measure", Item[2]."No.", ItemVariant[2].Code, LibraryRandom.RandInt(20));

        // [GIVEN] Sales order with two lines: the first line with item "P1", the second - item "P2"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item[3]."No.", 10);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item[4]."No.", 10);

        // [WHEN] Run "Create Production Order" from the sales order
        LibraryManufacturing.CreateProductionOrderFromSalesOrder(
            SalesHeader, ProductionOrder.Status::Released, "Create Production Order Type"::ProjectOrder);

        // [THEN] Production order with 4 lines is created:
        // [THEN] 1 production order line for item "P1"
        VerifyProdOrderLinesCount(Item[3]."No.", '', '', 1);
        // [THEN] 1 production order line for item "P1"
        VerifyProdOrderLinesCount(Item[3]."No.", '', '', 1);
        // [THEN] 1 production order line for item "M", variant "V1"
        VerifyProdOrderLinesCount(Item[2]."No.", '', ItemVariant[1].Code, 1);
        // [THEN] 1 production order line for item "M", variant "V2"
        VerifyProdOrderLinesCount(Item[2]."No.", '', ItemVariant[2].Code, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ModifyReleasedProdOrderConsumptionPosted()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        // [FEATURE] [Production Order] [Component]
        // [SCENARIO 224311] Validate field "Item No." in table "Prod. Order Component" after consumption for the line has been posted; error must occur.

        Initialize();

        // [GIVEN] Create & Release "Prod. Order" for 10 pcs of single item.
        CreateInitialSetupForReleasedProductionOrder(ProductionOrder, ProdOrderComponent);
        CalculateConsumptionJournal(ItemJournalBatch, ProductionOrder."No.");
        ItemJournalLine.Reset();
        ItemJournalLine.SetRange("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.SetRange("Order No.", ProductionOrder."No.");
        ItemJournalLine.SetRange("Entry Type", ItemJournalLine."Entry Type"::Consumption);
        ItemJournalLine.FindFirst();

        // [GIVEN] Change "Quantity" in production journal from 10 to 5 pcs and post it
        ItemJournalLine.Validate(Quantity, ItemJournalLine.Quantity / 2);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [GIVEN] Set "Quantity per" field into 0 in "Prod. Order Component" table in order to modify "Item No." field next
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.FindFirst();
        ProdOrderComponent.Validate("Quantity per", 0);
        ProdOrderComponent.Modify(true);

        // [WHEN] Trying to set "Item No." field into any other in "Prod. Order Component" table
        asserterror ProdOrderComponent.Validate("Item No.", LibraryInventory.CreateItemNo());

        // [THEN] Error message: "Act. Consumption (Qty)" must be equal to '0'...
        Assert.ExpectedTestFieldError(ProdOrderComponent.FieldCaption("Act. Consumption (Qty)"), Format(0));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInitManufacturingSetup()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 255348] Init value in "Doc No is Prod Order" field should be Yes in Manufacturing Setup

        // [WHEN] Manufacturing Setup is being initialized
        ManufacturingSetup.Init();

        // [THEN] "Doc No is Prod Order" = Yes
        ManufacturingSetup.TestField("Doc. No. Is Prod. Order No.", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshProdOrderWithDueDateEmpty()
    var
        ProductionOrder: Record "Production Order";
    begin
        // [FEATURE] [Production Order] [Refresh Production Order]
        // [SCENARIO 277108] Production Order Refresh trial must lead to an error if Due Date is empty.

        Initialize();

        // [GIVEN] Create a Production Order
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released,
          ProductionOrder."Source Type"::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));

        // [GIVEN] Set Due Date field to void
        ProductionOrder.Validate("Due Date", 0D);
        ProductionOrder.Modify(true);

        // [WHEN] Refresh the Production Order, direction - Forward
        asserterror LibraryManufacturing.RefreshProdOrder(ProductionOrder, true, true, true, true, false);

        // [THEN] Expected error occurs
        Assert.ExpectedError(DueDateEmptyErr);
    end;

    [Test]
    [HandlerFunctions('ExchangeProductionBOMItemHandler')]
    [Scope('OnPrem')]
    procedure ExchangeBOMItemCopiesPositionFields()
    var
        UnitOfMeasure: Record "Unit of Measure";
        ProductionBOMLine: Record "Production BOM Line";
        ProdBomVersion: Record "Production BOM Version";
        ProdBOMHeader: Record "Production BOM Header";
        Components: array[3] of Code[20];
    begin
        // [FEATURE] [Production BOM] [Exchange Production BOM Item]
        // [SCENARIO 320350] When Exchange Production BOM item replaces a component with another one, Position fields are copied
        Initialize();

        // [GIVEN] Created Production BOM with 1 component
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        ProdBOMHeader.Get(CreateProductionBOM(UnitOfMeasure.Code));
        Components[1] := FindProductionBOMComponent(ProdBOMHeader."No.");
        Components[2] := LibraryInventory.CreateItemNo();

        // [GIVEN] Created Production BOM version with 2 components
        CreateProductionBOMVersionWithTwoComponents(
          ProdBomVersion, ProdBOMHeader, ProdBOMHeader."Unit of Measure Code", WorkDate(), Components[1], Components[2]);

        // [GIVEN] Set Position fields on the initial Producion BOM Line
        FindProductionBOMLineByNo(ProductionBOMLine, ProdBomVersion."Production BOM No.",
          FindFirstBOMVersionCode(ProdBomVersion."Production BOM No."), Components[1]);
        ModifyProductionBOMVersionStatus(ProdBomVersion, ProdBomVersion.Status::"Under Development");
        SetProducionBOMLinePositionFields(ProductionBOMLine);
        ModifyProductionBOMVersionStatus(ProdBomVersion, ProdBomVersion.Status::Certified);

        // [WHEN] Run "Exchange Production BOM Item" to replace item "I1" with "I3" and "Create New Version" option
        Components[3] := LibraryInventory.CreateItemNo();
        RunExchangeProdBOMItemReportWithParameters(Components[1], Components[3], true, false);

        // [THEN] Position fields are transferred to the new Producion BOM Line
        VerifyProductionBOMLinePositionFields(
          ProductionBOMLine, ProdBOMHeader."No.", FindLastBOMVersionCode(ProdBomVersion."Production BOM No."), Components[3]);
    end;

    [Test]
    [HandlerFunctions('ExchangeProductionBOMItemHandler')]
    [Scope('OnPrem')]
    procedure ExchangeBOMItemWithEmptyItemNoRemovesBOMLines()
    var
        Item: Record Item;
        ProductionBOMLine: Record "Production BOM Line";
    begin
        // [FEATURE] [Production BOM] [Exchange Production BOM Item]
        // [SCENARIO 320350] When Exchange Production BOM item with empty Item No. without creating new version, it removes Production BOM Line with that Item
        Initialize();

        // [GIVEN] Create Item with Routing and Production BOM
        Item.Get(CreateItemWithRoutingAndProductionBOM());
        ExchangeNo := FindProductionBOMComponent(Item."Production BOM No.");

        // [GIVEN] Set Position fields on the initial Producion BOM Line
        FindProductionBOMLineByNo(ProductionBOMLine, Item."Production BOM No.", '', ExchangeNo);
        SetProducionBOMLinePositionFields(ProductionBOMLine);

        // [WHEN] Run "Exchange Production BOM Item" to replace item "I1" with empty Item No. and without "Create New Version"
        RunExchangeProdBOMItemReportWithParameters(ExchangeNo, '', false, true);

        // [THEN] Verify that Producion BOM Line is not existing anymore
        asserterror VerifyProductionBOMLinePositionFields(ProductionBOMLine, Item."Production BOM No.", '', ExchangeNo);
    end;

    [Test]
    [HandlerFunctions('ExchangeProductionBOMItemHandler')]
    [Scope('OnPrem')]
    procedure ExchangeBOMItemWithEmptyItemNoRemovesBOMLines2()
    var
        Item: Record Item;
        ProductionBOMLine: Record "Production BOM Line";
    begin
        // [FEATURE] [Production BOM] [Exchange Production BOM Item]
        // [SCENARIO 320350] When Exchange Production BOM item with empty Item No. without creating new version, it removes Production BOM Line with that Item
        Initialize();

        // [GIVEN] Create Item with Routing and Production BOM
        Item.Get(CreateItemWithRoutingAndProductionBOM());
        ExchangeNo := FindProductionBOMComponent(Item."Production BOM No.");

        // [GIVEN] Set Position fields on the initial Producion BOM Line
        FindProductionBOMLineByNo(ProductionBOMLine, Item."Production BOM No.", '', ExchangeNo);
        SetProducionBOMLinePositionFields(ProductionBOMLine);

        // Check number of lines before replacing "I1" with empty Item No. and without "Create New Version"
        ProductionBOMLine.Reset();
        ProductionBOMLine.SetRange("Production BOM No.", Item."Production BOM No.");
        ProductionBOMLine.SetRange("Version Code", '');
        Assert.AreEqual(1, ProductionBOMLine.Count(), 'Unexpected number of Production BOM Lines, must be 1.');

        // [WHEN] Run "Exchange Production BOM Item" to replace item "I1" with empty Item No. and without "Create New Version"
        RunExchangeProdBOMItemReportWithParameters(ExchangeNo, '', false, true);

        // [THEN] Verify that Producion BOM Line is not existing anymore
        ProductionBOMLine.Reset();
        ProductionBOMLine.SetRange("Production BOM No.", Item."Production BOM No.");
        ProductionBOMLine.SetRange("Version Code", '');
        Assert.AreEqual(0, ProductionBOMLine.Count(), 'Unexpected number of Production BOM Lines, must be 0.');
    end;

    [Test]
    [HandlerFunctions('ExchangeProductionBOMItemHandler')]
    [Scope('OnPrem')]
    procedure ExchangeBOMItemCopiesPositionFieldsDeleteExchangedComponent()
    var
        Item: Record Item;
        Item2: Record Item;
        ProductionBOMLine: Record "Production BOM Line";
    begin
        // [FEATURE] [Production BOM] [Exchange Production BOM Item]
        // [SCENARIO 320350] When Exchange Production BOM item replaces a component with another one, deleting previous line, Position fields are copied
        Initialize();

        // [GIVEN] Create two Items with Routing and Production BOM. Run Exchange Production BOM Item report with Create New Version as true and Delete Exchanged Component as false.
        Item.Get(CreateItemWithRoutingAndProductionBOM());
        Item2.Get(CreateItemWithRoutingAndProductionBOM());
        ExchangeNo := FindProductionBOMComponent(Item."Production BOM No.");  // Use ExchangeNo as global for handler.
        WithNo := FindProductionBOMComponent(Item2."Production BOM No.");  // Use WithNo as global for handler.

        // [GIVEN] Set Position fields on the initial Producion BOM Line
        FindProductionBOMLineByNo(ProductionBOMLine, Item."Production BOM No.", '', ExchangeNo);
        SetProducionBOMLinePositionFields(ProductionBOMLine);

        // [WHEN] Run "Exchange Production BOM Item" with Delete Exchanged Component option
        CreateNewVersion := false;  // Use CreateNewVersion as global for handler.
        DeleteExchangedComponent := true;
        RunExchangeProductionBOMItemReport();

        // [THEN] Position fields are transferred to the new Producion BOM Line
        VerifyProductionBOMLinePositionFields(ProductionBOMLine, Item."Production BOM No.", '', WithNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalendarEntryCaptionWhenFilterIsBlank()
    var
        CalendarEntry: Record "Calendar Entry";
        CaptionText: Text;
    begin
        // [FEATURE] [UT] [Calendar Entry]
        // [SCENARIO 320796] Call Caption from Calendar Entry when Work Center No contains '&'
        Initialize();

        // [GIVEN] Calendar Entry without Filter set to "No."
        CalendarEntry.SetRange("No.");

        // [WHEN] Call Caption from Calendar Entry
        CaptionText := CalendarEntry.Caption();

        // [THEN] Caption returns <blank> text
        Assert.AreEqual('', CaptionText, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalendarEntryCaptionWhenWorkCenterHasComplexNo()
    var
        WorkCenter: Record "Work Center";
        CalendarEntry: Record "Calendar Entry";
        WorkCenterNo: Code[20];
        WorkCenterName: Text;
        CaptionText: Text;
    begin
        // [FEATURE] [UT] [Calendar Entry] [Work Center]
        // [SCENARIO 320796] Call Caption from Calendar Entry when Work Center No contains '&'
        Initialize();
        WorkCenterNo := CopyStr(
            LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(WorkCenter."No."), 0), 1, MaxStrLen(WorkCenter."No."));
        WorkCenterNo[MaxStrLen(WorkCenter."No.") div 2] := '&';
        WorkCenterName := LibraryUtility.GenerateGUID();

        // [GIVEN] Work Center with No. = 'APG-LACK & PACKAGING' (20 symbols and one symbol is '&') and Name 'XXX'
        WorkCenter.Init();
        WorkCenter."No." := WorkCenterNo;
        WorkCenter.Name := CopyStr(WorkCenterName, 1, MaxStrLen(WorkCenter.Name));
        WorkCenter.Insert();

        // [GIVEN] Calendar Entry with Filter on this No.
        CalendarEntry.SetRange("No.", WorkCenterNo);

        // [WHEN] Call Caption from Calendar Entry
        CaptionText := CalendarEntry.Caption();

        // [THEN] Caption returns 'APG-LACK & PACKAGING XXX'
        Assert.AreEqual(StrSubstNo('%1 %2', WorkCenterNo, WorkCenterName), CaptionText, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalendarEntryCaptionWhenMachineCenterHasComplexNo()
    var
        MachineCenter: Record "Machine Center";
        CalendarEntry: Record "Calendar Entry";
        MachineCenterNo: Code[20];
        MachineCenterName: Text;
        CaptionText: Text;
    begin
        // [FEATURE] [UT] [Calendar Entry] [Machine Center]
        // [SCENARIO 320796] Call Caption from Calendar Entry when Machine Center No contains '&'
        Initialize();
        MachineCenterNo := CopyStr(
            LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(MachineCenter."No."), 0), 1, MaxStrLen(MachineCenter."No."));
        MachineCenterNo[MaxStrLen(MachineCenter."No.") div 2] := '&';
        MachineCenterName := LibraryUtility.GenerateGUID();

        // [GIVEN] Machine Center with No. = 'APG-LACK & PACKAGING' (20 symbols and one symbol is '&') and Name 'XXX'
        MachineCenter.Init();
        MachineCenter."No." := MachineCenterNo;
        MachineCenter.Name := CopyStr(MachineCenterName, 1, MaxStrLen(MachineCenter.Name));
        MachineCenter.Insert();

        // [GIVEN] Calendar Entry with Filter on this No. and Capacity Type Machine Center
        CalendarEntry."Capacity Type" := CalendarEntry."Capacity Type"::"Machine Center";
        CalendarEntry.SetRange("No.", MachineCenterNo);

        // [WHEN] Call Caption from Calendar Entry
        CaptionText := CalendarEntry.Caption();

        // [THEN] Caption returns 'APG-LACK & PACKAGING XXX'
        Assert.AreEqual(StrSubstNo('%1 %2', MachineCenterNo, MachineCenterName), CaptionText, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BinCodeClearedWhenSelectingLocationOnCompDifferentFromRouting()
    var
        LocationYellow: Record Location;
        LocationRed: Record Location;
        Bin: Record Bin;
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // [FEATURE] [Work Center] [Bin] [Location] [Prod. Order Component] [Routing]
        // [SCENARIO 376698] Change location code on prod. order component to a value different from location code on routing line.
        Initialize();

        // [GIVEN] Production item with BOM and routing.
        Item.Get(CreateItemWithRoutingAndProductionBOM());

        // [GIVEN] Location "Yellow" with bins, location "Red" without bins.
        LibraryWarehouse.CreateLocationWMS(LocationYellow, true, false, false, false, false);
        LibraryWarehouse.CreateBin(Bin, LocationYellow.Code, LibraryUtility.GenerateGUID(), '', '');
        LibraryWarehouse.CreateLocation(LocationRed);

        // [GIVEN] Production order on location "Yellow", refresh.
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", 1);
        ProductionOrder.Validate("Location Code", LocationYellow.Code);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, true);

        // [GIVEN] Set bin code on prod. order routing line.
        FindProductionOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.", Item."No.");
        FindProductionOrderRoutingLine(ProdOrderRoutingLine, ProdOrderLine);
        ProdOrderRoutingLine.Validate("To-Production Bin Code", Bin.Code);
        ProdOrderRoutingLine.Modify(true);

        // [GIVEN] Set bin code on prod. order component.
        FindProdOrderComponent(ProdOrderComponent, ProductionOrder.Status, ProductionOrder."No.");
        ProdOrderComponent.Validate("Bin Code", Bin.Code);
        ProdOrderComponent.Modify(true);

        // [GIVEN] Change location code on the prod. order line to "Red".
        ProdOrderLine.Validate("Location Code", LocationRed.Code);
        ProdOrderLine.Modify(true);

        // [WHEN] Change location code on prod. order component to "Red".
        ProdOrderComponent.Validate("Location Code", LocationRed.Code);

        // [THEN] The location code has been changed with no error.
        // [THEN] Bin Code on the prod. order component is reset to blank.
        ProdOrderComponent.TestField("Location Code", LocationRed.Code);
        ProdOrderComponent.TestField("Bin Code", '');
    end;

    [Test]
    procedure DateTimeAfterPlanningProdOrderForwardWhenOperationTimeIsBlank()
    var
        Item: Record Item;
        WorkCenter: Record "Work Center";
        WorkCenter2: Record "Work Center";
        PlanningRoutingLine: Record "Planning Routing Line";
        RoutingNo: Code[20];
        PrevOperationEndingDateTime: DateTime;
    begin
        // [FEATURE] [Routing] [Planning]
        // [SCENARIO 397481] Starting Date-Time = Ending Date-Time on planning routing line with zero operation time when planned forward.
        Initialize();

        // [GIVEN] Item with routing of two routing lines with different work centers "WC1" and "WC2".
        // [GIVEN] Set reordering policy to "Fixed Reorder Qty." to enable forward planning.
        Item.Get(CreateItemWithRoutingAndTwoWorkCenters(WorkCenter, WorkCenter2, RoutingNo));
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Fixed Reorder Qty.");
        Item.Validate("Reorder Point", 100);
        Item.Validate("Reorder Quantity", 200);
        Item.Modify(true);

        // [GIVEN] Calculate calendar and zero out run time on routing line for work center "WC2".
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, WorkDate() - 10, WorkDate() + 10);
        ResetRunTimeOnRoutingLine(RoutingNo, WorkCenter2."No.");

        // [WHEN] Calculate regenerative plan.
        Item.SetRecFilter();
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());

        // [THEN] Starting Date-Time = Ending Date-Time on the work center "WC2" and are equal to Ending Date-Time of work center "WC1".
        PlanningRoutingLine.SetRange("Work Center No.", WorkCenter."No.");
        PlanningRoutingLine.FindFirst();
        PrevOperationEndingDateTime := PlanningRoutingLine."Ending Date-Time";

        PlanningRoutingLine.SetRange("Work Center No.", WorkCenter2."No.");
        PlanningRoutingLine.FindFirst();
        Assert.AreEqual(PrevOperationEndingDateTime, PlanningRoutingLine."Starting Date-Time", StartingDateTimeErr);
        Assert.AreEqual(PrevOperationEndingDateTime, PlanningRoutingLine."Ending Date-Time", EndingDateTimeErr);
    end;

    [Test]
    procedure DateTimeAfterPlanningProdOrderBackwardWhenOperationTimeIsBlank()
    var
        Item: Record Item;
        WorkCenter: Record "Work Center";
        WorkCenter2: Record "Work Center";
        SalesHeader: Record "Sales Header";
        PlanningRoutingLine: Record "Planning Routing Line";
        RoutingNo: Code[20];
        NextOperationEndingDateTime: DateTime;
    begin
        // [FEATURE] [Routing] [Planning]
        // [SCENARIO 397481] Starting Date-Time = Ending Date-Time on planning routing line with zero operation time when planned backward.
        Initialize();

        // [GIVEN] Item with routing of two routing lines with different work centers "WC1" and "WC2".
        // [GIVEN] Set reordering policy to "Order" to enable backward planning.
        Item.Get(CreateItemWithRoutingAndTwoWorkCenters(WorkCenter, WorkCenter2, RoutingNo));
        Item.Validate("Reordering Policy", Item."Reordering Policy"::Order);
        Item.Modify(true);

        // [GIVEN] Calculate calendar and zero out run time on routing line for work center "WC1".
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter2, WorkDate() - 10, WorkDate() + 10);
        ResetRunTimeOnRoutingLine(RoutingNo, WorkCenter."No.");

        // [GIVEN] Create sales order to make a demand.
        CreateSalesOrder(SalesHeader, Item."No.", LibraryRandom.RandInt(10));

        // [WHEN] Calculate regenerative plan.
        Item.SetRecFilter();
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());

        // [THEN] Starting Date-Time = Ending Date-Time on the work center "WC1" and are equal to Starting Date-Time of work center "WC2".
        PlanningRoutingLine.SetRange("Work Center No.", WorkCenter2."No.");
        PlanningRoutingLine.FindFirst();
        NextOperationEndingDateTime := PlanningRoutingLine."Starting Date-Time";

        PlanningRoutingLine.SetRange("Work Center No.", WorkCenter."No.");
        PlanningRoutingLine.FindFirst();
        Assert.AreEqual(NextOperationEndingDateTime, PlanningRoutingLine."Starting Date-Time", StartingDateTimeErr);
        Assert.AreEqual(NextOperationEndingDateTime, PlanningRoutingLine."Ending Date-Time", EndingDateTimeErr);
    end;

    [Test]
    procedure ErrorOnCertifyProductionBOMWithCircularReferenceOneLevel()
    var
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        // [FEATURE] [Production BOM]
        // [SCENARIO 410142] Error on certify production BOM with one-level circular reference.
        Initialize();

        // [GIVEN] Disable dynamic low-level code in Manufacturing Setup.
        UpdateDynamicLowLevelCodeInMfgSetup(false);

        // [GIVEN] Create production BOM that refers to itself.
        LibraryInventory.CreateItem(Item);
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::"Production BOM", ProductionBOMHeader."No.", 1);

        // [WHEN] Try to certify the production BOM.
        asserterror LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);

        // [THEN] "The production BOM contains a circular reference" error message is shown.
        Assert.ExpectedError(StrSubstNo(CircularRefInBOMErr, ProductionBOMHeader."No.", ProductionBOMHeader."No."));
    end;

    [Test]
    procedure ErrorOnCertifyProductionBOMWithCircularReferenceThreeLevels()
    var
        Item: Record Item;
        ProductionBOMHeader: array[3] of Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        // [FEATURE] [Production BOM]
        // [SCENARIO 410142] Error on certify production BOM with three-levels circular reference.
        Initialize();

        // [GIVEN] Disable dynamic low-level code in Manufacturing Setup.
        UpdateDynamicLowLevelCodeInMfgSetup(false);

        // [GIVEN] Create production BOMs "A", "B", and "C".
        // [GIVEN] Production BOM "A" refers to "B", "B" refers to "C", and "C" refers to "A".
        LibraryInventory.CreateItem(Item);
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader[1], Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader[2], Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader[3], Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader[1], ProductionBOMLine, '', ProductionBOMLine.Type::"Production BOM", ProductionBOMHeader[2]."No.", 1);
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader[2], ProductionBOMLine, '', ProductionBOMLine.Type::"Production BOM", ProductionBOMHeader[3]."No.", 1);
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader[3], ProductionBOMLine, '', ProductionBOMLine.Type::"Production BOM", ProductionBOMHeader[1]."No.", 1);

        // [GIVEN] Certify production BOMs "C" and "B".
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader[3], ProductionBOMHeader[3].Status::Certified);
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader[2], ProductionBOMHeader[2].Status::Certified);

        // [WHEN] Try to certify the production BOM "A".
        asserterror LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader[1], ProductionBOMHeader[1].Status::Certified);

        // [THEN] "The production BOM contains a circular reference" error message is shown.
        Assert.ExpectedError(StrSubstNo(CircularRefInBOMErr, ProductionBOMHeader[1]."No.", ProductionBOMHeader[3]."No."));
    end;

    [Test]
    procedure ErrorOnCertifyProductionBOMWithCircularReferenceAndVersion()
    var
        Item: Record Item;
        ProductionBOMHeader: array[2] of Record "Production BOM Header";
        ProductionBOMVersion: Record "Production BOM Version";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        // [FEATURE] [Production BOM]
        // [SCENARIO 410142] Error on certify production BOM with version and circular reference.
        Initialize();

        // [GIVEN] Disable dynamic low-level code in Manufacturing Setup.
        UpdateDynamicLowLevelCodeInMfgSetup(false);

        // [GIVEN] Create production BOMs "A" and "B".
        // [GIVEN] Create BOM version "B+" for the BOM "B".
        // [GIVEN] Production BOM "A" refers to "B", "B" refers to an item, but version "B+" refers to "A".
        LibraryInventory.CreateItem(Item);
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader[1], Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader[2], Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader[1], ProductionBOMLine, '', ProductionBOMLine.Type::"Production BOM", ProductionBOMHeader[2]."No.", 1);
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader[2], ProductionBOMLine, '', ProductionBOMLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        LibraryManufacturing.CreateProductionBOMVersion(
          ProductionBOMVersion, ProductionBOMHeader[2]."No.", LibraryUtility.GenerateGUID(), Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader[2], ProductionBOMLine, ProductionBOMVersion."Version Code",
          ProductionBOMLine.Type::"Production BOM", ProductionBOMHeader[1]."No.", 1);

        // [GIVEN] Certify production BOM "B" and version "B+".
        ProductionBOMVersion.Validate(Status, ProductionBOMVersion.Status::Certified);
        ProductionBOMVersion.Modify(true);
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader[2], ProductionBOMHeader[2].Status::Certified);

        // [WHEN] Try to certify the production BOM "A".
        asserterror LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader[1], ProductionBOMHeader[1].Status::Certified);

        // [THEN] "The production BOM contains a circular reference" error message is shown.
        Assert.ExpectedError(StrSubstNo(CircularRefInBOMErr, ProductionBOMHeader[1]."No.", ProductionBOMHeader[2]."No."));
    end;

    [Test]
    [HandlerFunctions('BOMStructurePageHandler')]
    procedure ErrorOnShowBOMStructureWithCircularReference()
    var
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        BOMStructure: Page "BOM Structure";
    begin
        // [FEATURE] [Production BOM]
        // [SCENARIO 410142] Error on show BOM structure with circular reference.
        Initialize();

        // [GIVEN] Disable dynamic low-level code in Manufacturing Setup.
        UpdateDynamicLowLevelCodeInMfgSetup(false);

        // [GIVEN] Certified production BOM that refers to itself. Do not validate Status, assume that the looping BOM existed before the fix.
        LibraryInventory.CreateItem(Item);
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::"Production BOM", ProductionBOMHeader."No.", 1);
        ProductionBOMHeader.Status := ProductionBOMHeader.Status::Certified;
        ProductionBOMHeader.Modify();

        // [GIVEN] Assign the production BOM to an item.
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item.Modify(true);

        // [WHEN] Open "BOM Structure" for the item.
        Item.SetRecFilter();
        BOMStructure.InitItem(Item);
        asserterror BOMStructure.Run();

        // [THEN] "The production BOM contains a circular reference" error message is shown.
        Assert.ExpectedError(StrSubstNo(CircularRefInBOMErr, ProductionBOMHeader."No.", ProductionBOMHeader."No."));
    end;

    [Test]
    procedure NoErrorOnSameBOMInDifferentBranchesInBOMTree()
    var
        Item: Record Item;
        ProductionBOMHeader: array[3] of Record "Production BOM Header";
        ProductionBOMLine: array[2] of Record "Production BOM Line";
    begin
        // [FEATURE] [Production BOM]
        // [SCENARIO 425674] No error when the same production BOM no. is present in unrelated branches in BOM tree.
        Initialize();

        UpdateDynamicLowLevelCodeInMfgSetup(false);

        // [GIVEN] Certified production BOM "A", component type = Item, component no. = <some item>.
        LibraryInventory.CreateItem(Item);
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader[1], Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader[1], ProductionBOMLine[1], '', ProductionBOMLine[1].Type::Item, Item."No.", 1);
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader[1], ProductionBOMHeader[1].Status::Certified);

        // [GIVEN] Certified production BOM "B", component type = Production BOM, component no. = BOM "A".
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader[2], Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader[2], ProductionBOMLine[1], '', ProductionBOMLine[1].Type::"Production BOM", ProductionBOMHeader[1]."No.", 1);
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader[2], ProductionBOMHeader[2].Status::Certified);

        // [GIVEN] Production BOM "C" with two lines:
        // [GIVEN] Line 1. Type = Production BOM, No. = BOM "A".
        // [GIVEN] Line 2. Type = Production BOM, No. = BOM "B" (whose component is BOM "A")
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader[3], Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader[3], ProductionBOMLine[1], '', ProductionBOMLine[1].Type::"Production BOM", ProductionBOMHeader[1]."No.", 1);
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader[3], ProductionBOMLine[2], '', ProductionBOMLine[2].Type::"Production BOM", ProductionBOMHeader[2]."No.", 1);

        // [WHEN] Certify production BOM "C".
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader[3], ProductionBOMHeader[3].Status::Certified);

        // [THEN] BOM "C" is certified successfully.
        ProductionBOMHeader[3].TestField(Status, ProductionBOMHeader[3].Status::Certified);
    end;

    [Test]
    [HandlerFunctions('ExchangeProductionBOMItemHandler')]
    procedure PositionCopiedFromDeletedLineWhenExchangeBOMWithDeletion()
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        NewProductionBOMLine: Record "Production BOM Line";
        ItemNo: Code[20];
    begin
        // [FEATURE] [Production BOM] [Exchange Production BOM Item]
        // [SCENARIO 430176] When Exchange Production BOM Item replaces a component with another one, the Position fields are copied from the deleted BOM line.
        Initialize();

        ExchangeNo := LibraryInventory.CreateItemNo();
        ItemNo := LibraryInventory.CreateItemNo();
        WithNo := LibraryInventory.CreateItemNo();

        LibraryManufacturing.CreateCertifProdBOMWithTwoComp(ProductionBOMHeader, ExchangeNo, ItemNo, 1);
        FindProductionBOMLineByNo(ProductionBOMLine, ProductionBOMHeader."No.", '', ItemNo);
        SetProducionBOMLinePositionFields(ProductionBOMLine);
        FindProductionBOMLineByNo(ProductionBOMLine, ProductionBOMHeader."No.", '', ExchangeNo);
        SetProducionBOMLinePositionFields(ProductionBOMLine);

        CreateNewVersion := false;
        DeleteExchangedComponent := true;
        RunExchangeProductionBOMItemReport();

        FindProductionBOMLineByNo(NewProductionBOMLine, ProductionBOMHeader."No.", '', WithNo);
        NewProductionBOMLine.TestField("Line No.", ProductionBOMLine."Line No.");
        NewProductionBOMLine.TestField(Position, ProductionBOMLine.Position);
        NewProductionBOMLine.TestField("Position 2", ProductionBOMLine."Position 2");
        NewProductionBOMLine.TestField("Position 3", ProductionBOMLine."Position 3");
    end;

    [Test]
    [HandlerFunctions('ExchangeProductionBOMItemHandler')]
    procedure PositionCopiedFromLastLineWhenExchangeBOMWithoutDeletion()
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        NewProductionBOMLine: Record "Production BOM Line";
        ItemNo: Code[20];
    begin
        // [FEATURE] [Production BOM] [Exchange Production BOM Item]
        // [SCENARIO 430176] When Exchange Production BOM Item adds a component, the Position fields are copied from the last BOM line.
        Initialize();

        ExchangeNo := LibraryInventory.CreateItemNo();
        ItemNo := LibraryInventory.CreateItemNo();
        WithNo := LibraryInventory.CreateItemNo();

        LibraryManufacturing.CreateCertifProdBOMWithTwoComp(ProductionBOMHeader, ExchangeNo, ItemNo, 1);
        FindProductionBOMLineByNo(ProductionBOMLine, ProductionBOMHeader."No.", '', ExchangeNo);
        SetProducionBOMLinePositionFields(ProductionBOMLine);
        FindProductionBOMLineByNo(ProductionBOMLine, ProductionBOMHeader."No.", '', ItemNo);
        SetProducionBOMLinePositionFields(ProductionBOMLine);

        CreateNewVersion := false;
        DeleteExchangedComponent := false;
        RunExchangeProductionBOMItemReport();

        FindProductionBOMLineByNo(NewProductionBOMLine, ProductionBOMHeader."No.", '', WithNo);
        NewProductionBOMLine.TestField("Line No.", ProductionBOMLine."Line No." + 10000);
        NewProductionBOMLine.TestField(Position, ProductionBOMLine.Position);
        NewProductionBOMLine.TestField("Position 2", ProductionBOMLine."Position 2");
        NewProductionBOMLine.TestField("Position 3", ProductionBOMLine."Position 3");
    end;

    [Test]
    procedure ConsideringAbsenceForConstrainedCapacityCalculateForward()
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
    begin
        // [FEATURE] [Capacity] [Absence] [Capacity Constrained Resource]
        // [SCENARIO 437415] Respect absence period when calculating capacity need with direction = "Forward" for a constrained resource.
        Initialize();

        // [GIVEN] Work center "W" with calendar.
        // [GIVEN] Register absence on WorkDate from 8AM till 12AM.
        // [GIVEN] Make the work center "W" a constrained resource with maximum load = 90%.
        // [GIVEN] Create routing with "W".
        CreateRoutingWithCapacityConstrainedWorkCenterAndAbsence(RoutingHeader, RoutingLine, 120000T);

        // [GIVEN] Create item and select the routing.
        CreateItemWithRouting(Item, RoutingHeader."No.");

        // [WHEN] Create and refresh production order with Due Date = "WorkDate" and Scheduling Direction = "Forward".
        CreateAndRefreshProdOrderWithSpecificDueDate(
          ProductionOrder, Item."No.", WorkDate(), LibraryRandom.RandIntInRange(1000, 2000), true);

        // [THEN] No Prod. Order Capacity Need for the absence period is created.
        FilteringOnProdOrderCapacityNeed(ProdOrderCapacityNeed, RoutingLine."No.", WorkDate());
        ProdOrderCapacityNeed.FindFirst();
        Assert.IsTrue(ProdOrderCapacityNeed."Starting Time" >= 120000T, '');
    end;

    [Test]
    procedure ConsideringAbsenceForConstrainedCapacityCalculateBackward()
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
    begin
        // [FEATURE] [Capacity] [Absence] [Capacity Constrained Resource]
        // [SCENARIO 437415] Respect absence period when calculating capacity need with direction = "Backward" for a constrained resource.
        Initialize();

        // [GIVEN] Work center "W" with calendar.
        // [GIVEN] Register absence on WorkDate from 8AM till 12AM.
        // [GIVEN] Make the work center "W" a constrained resource with maximum load = 90%.
        // [GIVEN] Create routing with "W".
        CreateRoutingWithCapacityConstrainedWorkCenterAndAbsence(RoutingHeader, RoutingLine, 120000T);

        // [GIVEN] Create item and select the routing.
        CreateItemWithRouting(Item, RoutingHeader."No.");

        // [WHEN] Create and refresh production order with Due Date = "WorkDate" and Scheduling Direction = "Backward".
        CreateAndRefreshProdOrderWithSpecificDueDate(
          ProductionOrder, Item."No.", WorkDate() + 1, LibraryRandom.RandIntInRange(1000, 2000), false);

        // [THEN] No Prod. Order Capacity Need for the absence period is created.
        FilteringOnProdOrderCapacityNeed(ProdOrderCapacityNeed, RoutingLine."No.", WorkDate());
        ProdOrderCapacityNeed.FindFirst();
        Assert.IsTrue(ProdOrderCapacityNeed."Starting Time" >= 120000T, '');
    end;

    [Test]
    [HandlerFunctions('ProdOrderCompAndRoutingHandler')]
    [Scope('OnPrem')]
    procedure ProdOrderCompAndRoutingOnReleasedPlannedProdOrders()
    var
        ProductionOrder: Record "Production Order";
    begin
        // [SCENARIO 453061] "Production Order - Comp. and Routing" of "Released Production Orders" Page should run "Prod. Order Comp. and Routing" Report with filters
        Initialize();

        // [GIVEN] Create a Production Order
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released,
          ProductionOrder."Source Type"::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));

        // [WHEN] Refresh the Production Order, direction - Forward
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [THEN] Verify Report "Prod. Order Comp. and Routing" filters
        VerifyRelProductionOrderPage(ProductionOrder);
    end;

    [Test]
    [HandlerFunctions('ReservationHandler,ReserveOptionDialog')]
    [Scope('OnPrem')]
    procedure PartialPostingTransferWithReservation()
    var
        BLUELocation: Record Location;
        SILVERLocation: Record Location;
        InTransitLocation: Record Location;
        Item: Record Item;
        ComponentItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
        ReservationEntry: Record "Reservation Entry";
        TransferOrder: TestPage "Transfer Order";
    begin
        // [SCENARIO] Partial posting of transfer orders with reservation, splits reservation accordingly.
        // https://dynamicssmb2.visualstudio.com/Dynamics%20SMB/_workitems/edit/500993
        Initialize();

        // [GIVEN] Create and setup locations.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(BLUELocation); // From locaiton
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(SILVERLocation); // To location
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation); // Transit location

        // [GIVEN] Create item to produce and component item with reserve as optional.
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(ComponentItem);
        ComponentItem.Validate(Reserve, ComponentItem.Reserve::Optional);
        ComponentItem.Modify(true);

        // [GIVEN] Create a released production order where there is a need for 10 component item.
        CreateAndRefreshProductionOrderWithItem(ProductionOrder, Enum::"Production Order Status"::Released, Item."No.", 1);
        ProductionOrder.Validate("Due Date", CalcDate('<+1M+1D>', WorkDate()));
        ProductionOrder.Modify(true);

        FindProductionOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.", Item."No.");
        ProdOrderLine.Validate(Quantity, 10);
        ProdOrderLine.Modify(true);
        CreateProdOrderComponent(ProdOrderComponent, Enum::"Production Order Status"::Released, ProductionOrder."No.", ProdOrderLine."Line No.", ComponentItem."No.", SILVERLocation.Code, 1);
        ProdOrderComponent.Validate("Due Date", CalcDate('<+1M>', WorkDate()));
        ProdOrderComponent.Modify(true);

        // [GIVEN] Add 3 positive adjustment lines to component in BLUE location and post them.
        SelectItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.", ComponentItem."No.", 5);
        ItemJournalLine.Validate("Posting Date", CalcDate('<+7D>', WorkDate()));
        ItemJournalLine.Validate("Location Code", BLUELocation.Code);
        ItemJournalLine.Modify(true);
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.", ComponentItem."No.", 3);
        ItemJournalLine.Validate("Posting Date", CalcDate('<+7D>', WorkDate()));
        ItemJournalLine.Validate("Location Code", BLUELocation.Code);
        ItemJournalLine.Modify(true);
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.", ComponentItem."No.", 2);
        ItemJournalLine.Validate("Posting Date", CalcDate('<+7D>', WorkDate()));
        ItemJournalLine.Validate("Location Code", BLUELocation.Code);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [GIVEN] Create transfer order to transfer 10 component items from BLUE to SILVER location.
        LibraryInventory.CreateTransferHeader(TransferHeader, BLUELocation.Code, SILVERLocation.Code, InTransitLocation.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, ComponentItem."No.", 10);
        TransferLine.Validate("Shipment Date", CalcDate('<+14D>', WorkDate()));
        TransferLine.Validate("Qty. to Ship", 6);
        TransferLine.Modify(true);

        // [GIVEN] Reserve all 10 component items bound for SILVER location .
        TransferOrder.OpenEdit();
        TransferOrder.GoToRecord(TransferHeader);

        LibraryVariableStorage.Enqueue(2); // Inbound    
        TransferOrder.TransferLines.Reserve.Invoke();
        LibraryVariableStorage.Enqueue(1); // Outbound    
        TransferOrder.TransferLines.Reserve.Invoke();
        TransferOrder.Close();

        // [WHEN] Post the transfer order partially. Ship and post only 6 component items.
        LibraryInventory.PostTransferHeader(TransferHeader, true, true);

        // [THEN] 3 reservation entries are created for the 3 positive adjustment lines in SILVER location.
        ReservationEntry.SetRange("Item No.", ComponentItem."No.");
        ReservationEntry.SetRange("Location Code", SILVERLocation.Code);
        ReservationEntry.SetRange("Source Type", Database::"Prod. Order Component");
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Reservation);
        ReservationEntry.SetRange("Source ID", ProductionOrder."No.");
        ReservationEntry.SetRange("Source Prod. Order Line", ProdOrderLine."Line No.");
        Assert.RecordCount(ReservationEntry, 3);

        // [THEN] Reservation entry 5, 3, 2 are split into 5, 1, 4 where 5 and 1 are received in the SILVER location.
        // [THEN] Reservation entries received on the SILVER side do not have the 'Expected Receipt Date' set as it is already received.
        // [THEN] Reservation entry for 4 is is still expected to be received on the 'Expected Receipt Date' on SILVER location and is reflected in the Reservation Entry. 
        ReservationEntry.SetRange(Quantity, -5);
        Assert.RecordCount(ReservationEntry, 1);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Expected Receipt Date", 0D);
        ReservationEntry.SetRange(Quantity, -1);
        Assert.RecordCount(ReservationEntry, 1);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Expected Receipt Date", 0D);
        ReservationEntry.SetRange(Quantity, -4);
        Assert.RecordCount(ReservationEntry, 1);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Expected Receipt Date", TransferLine."Shipment Date");

        // [WHEN] Change the shipment date to 2 days back and post 2 more component items.
        TransferLine.Find();
        TransferLine.Validate("Shipment Date", CalcDate('<-2D>', TransferLine."Shipment Date"));
        TransferLine.Validate("Qty. to Ship", 2);
        TransferLine.Modify(true);
        LibraryInventory.PostTransferHeader(TransferHeader, true, true);

        // [THEN] Previously not received Reservation entry with qty. 4 is split into 2 with qty. 2.
        ReservationEntry.SetRange("Item No.", ComponentItem."No.");
        ReservationEntry.SetRange("Location Code", SILVERLocation.Code);
        ReservationEntry.SetRange("Source Type", Database::"Prod. Order Component");
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Reservation);
        ReservationEntry.SetRange("Source ID", ProductionOrder."No.");
        ReservationEntry.SetRange("Source Prod. Order Line", ProdOrderLine."Line No.");
        ReservationEntry.SetRange(Quantity);
        Assert.RecordCount(ReservationEntry, 4);

        ReservationEntry.SetRange(Quantity, -2);
        Assert.RecordCount(ReservationEntry, 2);

        // [WHEN] Posting consumption journal on the 8 component items.
        CalculateConsumptionJournal(ItemJournalBatch, ProductionOrder."No.");
        ItemJournalLine.Reset();
        ItemJournalLine.SetRange("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.SetRange("Order No.", ProductionOrder."No.");
        ItemJournalLine.SetRange("Entry Type", ItemJournalLine."Entry Type"::Consumption);
        ItemJournalLine.FindFirst();

        // [THEN] Postig consumption journal on the 8 component items succeeds.
        ItemJournalLine.Validate(Quantity, 8);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ItemTrackingAssignLotNoPageHandler,ProductionJournalPageHandlerOnlyConsumption,ConfirmHandlerTrue,MessageHandler')]
    procedure ConsumptionIsPostedForMultipleILEsOfSameLotNo()
    var
        CompItem, ProdItem : Record Item;
        Location: Record Location;
        UnitOfMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemTrackingCode: Record "Item Tracking Code";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        ItemLedgerEntry: Record "Item Ledger Entry";
        LotNo: Code[10];
        Quantity: Decimal;
        ReleasedProdOrder: TestPage "Released Production Order";
    begin
        // [SCENARIO 501830] Consumption is posted against multiple Item Ledger Entries of same Lot No. when you post Production Journal from a Released Production Order.
        Initialize();

        // [GIVEN] Create Item Tracking Code.
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);

        // [GIVEN] Create Unit of Measure.
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);

        // [GIVEN] Create Component Item with Unit of Measure.
        CreateItemWithUOM(CompItem, UnitOfMeasure, ItemUnitOfMeasure);
        CompItem.Validate("Replenishment System", CompItem."Replenishment System"::Purchase);
        CompItem.Validate(Reserve, CompItem.Reserve::Always);
        CompItem.Validate("Flushing Method", CompItem."Flushing Method"::Manual);
        CompItem.Validate("Item Tracking Code", ItemTrackingCode.Code);
        CompItem.Modify(true);

        // [GIVEN] Create Location with Inventory Posting Setup.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Create Production Item with Unit of Measure.
        CreateItemWithUOM(ProdItem, UnitOfMeasure, ItemUnitOfMeasure);

        // [GIVEN] Generate and save Lot No. and Quantity in two different Variable.
        LotNo := Format(LibraryRandom.RandText(4));
        Quantity := LibraryRandom.RandIntInRange(35, 35);

        // [GIVEN] Create and Post three Item Journal Lines with same Lot No.
        CreateAndPostItemJournalLineWithLotNo(CompItem."No.", LibraryRandom.RandIntInRange(5, 5), LotNo, '', Location.Code, true);
        CreateAndPostItemJournalLineWithLotNo(CompItem."No.", LibraryRandom.RandIntInRange(10, 10), LotNo, '', Location.Code, true);
        CreateAndPostItemJournalLineWithLotNo(CompItem."No.", LibraryRandom.RandIntInRange(20, 20), LotNo, '', Location.Code, true);

        // [GIVEN] Create a production BOM for the Production Item.
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, ItemUnitOfMeasure.Code);
        LibraryManufacturing.CreateProductionBOMLine(
            ProductionBOMHeader,
            ProductionBOMLine,
            '',
            ProductionBOMLine.Type::Item,
            CompItem."No.",
            LibraryRandom.RandIntInRange(1, 1));

        // [GIVEN] Validate Unit of Measure in Production BOM.
        ProductionBOMLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        ProductionBOMLine.Modify(true);

        // [GIVEN] Change Status of Production BOM.
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);

        // [GIVEN] Validate Replenishment System and Production BOM No. in Production Item.
        ProdItem.Validate("Replenishment System", ProdItem."Replenishment System"::"Prod. Order");
        ProdItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProdItem.Modify(true);

        // [GIVEN] Create and Refresh Production Order.
        CreateAndRefreshProdOrder(
            ProductionOrder,
            ProductionOrder.Status::Released,
            ProdItem."No.",
            Quantity,
            Location.Code,
            '');

        // [GIVEN] Open Released Production Order page and run Production Journal action.
        ReleasedProdOrder.OpenEdit();
        ReleasedProdOrder.GoToRecord(ProductionOrder);
        LibraryVariableStorage.Enqueue(Quantity);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Lot No.");
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Quantity);
        ReleasedProdOrder.ProdOrderLines.ProductionJournal.Invoke();

        // [WHEN] Find Item Ledger Entry.
        ItemLedgerEntry.SetRange("Item No.", CompItem."No.");
        ItemLedgerEntry.SetRange(Quantity, -Quantity);

        // [VERIFY] Item Ledger Entry is found.
        Assert.IsFalse(ItemLedgerEntry.IsEmpty(), ItemLedgerEntryMustBeFoundErr);
    end;

    [Test]
    [HandlerFunctions('ProdBOMVersionComparisonHandlerForActionSet')]
    [Scope('OnPrem')]
    procedure PreviousSetAndNextSetActionMustBeVisibleInProdBOMMatrPerVersionMatrPageFromProductionBOMPage()
    var
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMVersion: Record "Production BOM Version";
        ProductionBOM: TestPage "Production BOM";
        ProductionBOMNo: Code[20];
    begin
        // [SCENARIO 335050] Verify that "Prod. BOM Version Comparison" page has "Previous Set" and "Next Set" action must be visible When executing the "Prod. BOM Version Comparison" from "Production BOM" page.
        Initialize();

        // [GIVEN] Create a Unit of Measure.
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);

        // [GIVEN] Create five Items.
        CreateSetofItems(Item, 5);

        // [GIVEN] Create a Production BOM with five Items.
        ProductionBOMNo := CreateProductionBOMForSetOfItems(Item, UnitOfMeasure.Code);

        // [GIVEN] Get the Production BOM.
        ProdBOMHeader.Get(ProductionBOMNo);

        // [GIVEN] Create a Production BOM Version.  
        LibraryManufacturing.CreateProductionBOMVersion(ProdBomVersion, ProductionBOMNo, LibraryUtility.GenerateGUID(), UnitOfMeasure.Code);

        // [GIVEN] Copy BOM for Production BOM Version.
        ProductionBOMCopy.CopyBOM(ProdBomVersion."Production BOM No.", '', ProdBOMHeader, ProdBomVersion."Version Code");

        // [GIVEN] Open Production BOM page.
        ProductionBOM.OpenEdit();
        ProductionBOM.GoToRecord(ProdBOMHeader);

        // [WHEN] Executing the "Prod. BOM Version Comparison" action in Production BOM page.
        ProductionBOM."Prod. BOM Version Comparison".Invoke();

        // [THEN] Verify that "Prod. BOM Version Comparison" page has "Previous Set" and "Next Set" action must be visible through "ProdBOMVersionComparisonHandlerForActionSet" handler.
        ProductionBOM.Close();
    end;

    [Test]
    [HandlerFunctions('ProdBOMVersionComparisonHandlerForBOMVersion')]
    [Scope('OnPrem')]
    procedure VerifyProdBOMVersionDetailMustBeshownOnProdBOMMatPerVerMatrPageFromProductionBOMPage()
    var
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMVersion: Record "Production BOM Version";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionBOM: TestPage "Production BOM";
        ProductionBOMNo: Code[20];
    begin
        // [SCENARIO 335050] Verify that Production BOM and each Production BOM version must be shown on "Prod. BOM Matr. per Version Matr." page When executing the "Prod. BOM Version Comparison" action from "Production BOM" page.
        Initialize();

        // [GIVEN] Create a Unit of Measure.
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);

        // [GIVEN] Create five Items.
        CreateSetofItems(Item, 5);

        // [GIVEN] Create a Production BOM with five Items.
        ProductionBOMNo := CreateProductionBOMForSetOfItems(Item, UnitOfMeasure.Code);

        // [GIVEN] Get the Production BOM Header.
        ProdBOMHeader.Get(ProductionBOMNo);

        // [GIVEN] Create a Production BOM Version.  
        LibraryManufacturing.CreateProductionBOMVersion(ProdBomVersion, ProductionBOMNo, LibraryUtility.GenerateGUID(), UnitOfMeasure.Code);

        // [GIVEN] Copy BOM for Production BOM Version.
        ProductionBOMCopy.CopyBOM(ProdBomVersion."Production BOM No.", '', ProdBOMHeader, ProdBomVersion."Version Code");

        // [GIVEN] Find the Production BOM Version Line.
        FindProductionBOMVersionLine(ProductionBOMLine, ProductionBOMNo, ProdBOMVersion."Version Code");

        // [GIVEN] Enqueue Quantity of Production BOM Line.
        LibraryVariableStorage.Enqueue(ProductionBOMLine.Quantity);

        // [GIVEN] Modify the Quantity of Production BOM Version Line.
        ProductionBOMLine.Validate(Quantity, LibraryRandom.RandInt(1000));
        ProductionBOMLine.Modify(true);

        // [GIVEN] Enqueue Quantity, "Version Code" and "Production BOM No." of Production BOM Version Line.
        LibraryVariableStorage.Enqueue(ProductionBOMLine.Quantity);
        LibraryVariableStorage.Enqueue(ProductionBOMLine."Version Code");
        LibraryVariableStorage.Enqueue(ProductionBOMLine."Production BOM No.");

        // [GIVEN] Open Production BOM page.
        ProductionBOM.OpenEdit();
        ProductionBOM.GoToRecord(ProdBOMHeader);

        // [WHEN] Executing the "Prod. BOM Version Comparison" action in Production BOM page.
        ProductionBOM."Prod. BOM Version Comparison".Invoke();

        // [THEN] Verify that Production BOM and each Production BOM version must be shown on "Prod. BOM Matr. per Version Matr." page through ProdBOMVersionComparisonHandlerForBOMVersion handler.
        ProductionBOM.Close();
    end;

    [Test]
    [HandlerFunctions('ProdBOMVersionComparisonListHandlerForActionSet')]
    [Scope('OnPrem')]
    procedure PreviousSetAndNextSetActionMustBeVisibleInProdBOMMatrPerVersionMatrPageFromProductionBOMListPage()
    var
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMVersion: Record "Production BOM Version";
        ProductionBOMList: TestPage "Production BOM List";
        ProductionBOMNo: Code[20];
    begin
        // [SCENARIO 335050] Verify that "Prod. BOM Version Comparison" page has "Previous Set" and "Next Set" action must be visible When executing the "Prod. BOM Version Comparison" from "Production BOM List" page.
        Initialize();

        // [GIVEN] Create a Unit of Measure.
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);

        // [GIVEN] Create five Items.
        CreateSetofItems(Item, 5);

        // [GIVEN] Create a Production BOM with five Items.
        ProductionBOMNo := CreateProductionBOMForSetOfItems(Item, UnitOfMeasure.Code);

        // [GIVEN] Get the Production BOM.
        ProdBOMHeader.Get(ProductionBOMNo);

        // [GIVEN] Create a Production BOM Version.  
        LibraryManufacturing.CreateProductionBOMVersion(ProdBomVersion, ProductionBOMNo, LibraryUtility.GenerateGUID(), UnitOfMeasure.Code);

        // [GIVEN] Copy BOM for Production BOM Version.
        ProductionBOMCopy.CopyBOM(ProdBomVersion."Production BOM No.", '', ProdBOMHeader, ProdBomVersion."Version Code");

        // [GIVEN] Open Production BOM page.
        ProductionBOMList.OpenEdit();
        ProductionBOMList.GoToRecord(ProdBOMHeader);

        // [WHEN] Executing the "Prod. BOM Version Comparison" action in Production BOM List page.
        ProductionBOMList."Prod. BOM Version Comparison".Invoke();

        // [THEN] Verify that "Prod. BOM Version Comparison" page has "Previous Set" and "Next Set" action must be visible through "ProdBOMVersionComparisonListHandlerForActionSet" handler.
        ProductionBOMList.Close();
    end;

    [Test]
    [HandlerFunctions('ProdBOMVersionComparisonListHandlerForBOMVersion')]
    [Scope('OnPrem')]
    procedure VerifyProdBOMVersionDetailMustBeShownOnProdBOMMatPerVerMatrPageFromProductionBOMListPage()
    var
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMVersion: Record "Production BOM Version";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionBOMList: TestPage "Production BOM List";
        ProductionBOMNo: Code[20];
    begin
        // [SCENARIO 335050] Verify that Production BOM and each Production BOM version must be shown on "Prod. BOM Matr. per Version Matr." page When executing the "Prod. BOM Version Comparison" action from "Production BOM List" page.
        Initialize();

        // [GIVEN] Create a Unit of Measure.
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);

        // [GIVEN] Create five Items.
        CreateSetofItems(Item, 5);

        // [GIVEN] Create a Production BOM with five Items.
        ProductionBOMNo := CreateProductionBOMForSetOfItems(Item, UnitOfMeasure.Code);

        // [GIVEN] Get the Production BOM Header.
        ProdBOMHeader.Get(ProductionBOMNo);

        // [GIVEN] Create a Production BOM Version.  
        LibraryManufacturing.CreateProductionBOMVersion(ProdBomVersion, ProductionBOMNo, LibraryUtility.GenerateGUID(), UnitOfMeasure.Code);

        // [GIVEN] Copy BOM for Production BOM Version.
        ProductionBOMCopy.CopyBOM(ProdBomVersion."Production BOM No.", '', ProdBOMHeader, ProdBomVersion."Version Code");

        // [GIVEN] Find the Production BOM Version Line.
        FindProductionBOMVersionLine(ProductionBOMLine, ProductionBOMNo, ProdBOMVersion."Version Code");

        // [GIVEN] Enqueue Quantity of Production BOM Line.
        LibraryVariableStorage.Enqueue(ProductionBOMLine.Quantity);

        // [GIVEN] Modify the Quantity of Production BOM Version Line.
        ProductionBOMLine.Validate(Quantity, LibraryRandom.RandInt(1000));
        ProductionBOMLine.Modify(true);

        // [GIVEN] Enqueue Quantity, "Version Code" and "Production BOM No." of Production BOM Version Line.
        LibraryVariableStorage.Enqueue(ProductionBOMLine.Quantity);
        LibraryVariableStorage.Enqueue(ProductionBOMLine."Version Code");
        LibraryVariableStorage.Enqueue(ProductionBOMLine."Production BOM No.");

        // [GIVEN] Open Production BOM page.
        ProductionBOMList.OpenEdit();
        ProductionBOMList.GoToRecord(ProdBOMHeader);

        // [WHEN] Executing the "Prod. BOM Version Comparison" action in Production BOM List page.
        ProductionBOMList."Prod. BOM Version Comparison".Invoke();

        // [THEN] Verify that Production BOM and each Production BOM version must be shown on "Prod. BOM Matr. per Version Matr." page through ProdBOMVersionComparisonListHandlerForBOMVersion handler.
        ProductionBOMList.Close();
    end;

    [Test]
    [HandlerFunctions('ProdBOMVersionComparisonListHandlerForBOMWithoutVersion')]
    procedure VerifyProdBOMDetailMustBeShownOnProdBOMComparisonPage()
    var
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
        ProdBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionBOMList: TestPage "Production BOM List";
        ProductionBOMNo: Code[20];
    begin
        // [SCENARIO 566038] Verify that Production BOM Comparison must show BOM quantities when there are no versions.
        Initialize();

        // [GIVEN] Create a Unit of Measure.
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);

        // [GIVEN] Create five Items.
        CreateSetofItems(Item, 5);

        // [GIVEN] Create a Production BOM with five Items.
        ProductionBOMNo := CreateProductionBOMForSetOfItems(Item, UnitOfMeasure.Code);

        // [GIVEN] Get the Production BOM Header.
        ProdBOMHeader.Get(ProductionBOMNo);

        // [GIVEN] Find the Production BOM Line.
        FindProductionBOMVersionLine(ProductionBOMLine, ProductionBOMNo, '');

        // [GIVEN] Modify the Quantity of Production BOM Line.
        ProductionBOMLine.Quantity := LibraryRandom.RandInt(1000);
        ProductionBOMLine.Modify();

        // [GIVEN] Enqueue Quantity, "Production BOM No." of Production BOM Version Line.
        LibraryVariableStorage.Enqueue(ProductionBOMLine.Quantity);
        LibraryVariableStorage.Enqueue(ProductionBOMLine."Production BOM No.");

        // [GIVEN] Open Production BOM page.
        ProductionBOMList.OpenEdit();
        ProductionBOMList.GoToRecord(ProdBOMHeader);

        // [WHEN] Executing the "Prod. BOM Version Comparison" action in Production BOM List page.
        ProductionBOMList."Prod. BOM Version Comparison".Invoke();

        // [THEN] Verify that Production BOM Comparison must show BOM quantities when there are no versions through ProdBOMVersionComparisonListHandlerForBOMWithoutVersion handler.
        ProductionBOMList.Close();
    end;

    [Test]
    procedure RoutingLineDescRemainSameWithStandardCodeWhenChangeWorkCenter()
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        StandardTask: Record "Standard Task";
        WorkCenter: array[2] of Record "Work Center";
    begin
        // [SCENARIO 335050] Verify that Routing Line desc don't change when update Work Center if Standard Code is not blank.
        Initialize();

        // [GIVEN] Create Standard Task.
        CreateStandardTasks(StandardTask);

        // [GIVEN] Create Work Center.
        LibraryManufacturing.CreateWorkCenter(WorkCenter[1]);
        LibraryManufacturing.CreateWorkCenter(WorkCenter[2]);

        // [GIVEN] Create Routing Header.
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);

        // [GIVEN] Create Routing Line.
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', Format(LibraryRandom.RandInt(100)), RoutingLine.Type::"Work Center", WorkCenter[1]."No.");

        // [GIVEN] Update Standard Task on Routing Line.
        UpdateRoutingLineWithStandardTask(RoutingLine, StandardTask);

        //[WHEN] Change Work Center on Routing Line.
        ModifyRoutingLineWorkCenter(RoutingLine, WorkCenter[2]."No.");

        // [THEN] Verify that Routing Line desc same as Standard Code desciption.
        Assert.IsTrue((StandardTask.Description = RoutingLine.Description), '');
    end;

    [Test]
    procedure RoutingLineDescRemainSameWithStandardCodeWhenChangeWorkCenterOnProductionOrder()
    var
        Item, CompItem : Record Item;
        productionBomHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        ShopCalendarWorkingDays: Record "Shop Calendar Working Days";
        StandardTask: Record "Standard Task";
        WorkCenter: array[2] of Record "Work Center";
    begin
        // [SCENARIO 335050] Verify that Routing Line desc don't change when update Work Center if Standard Code is not blank on Released Production Order.
        Initialize();

        // [GIVEN] Create Standard Task.   
        CreateStandardTasks(StandardTask);

        // [GIVEN] Create Work Center and Work Center Calendar.
        LibraryManufacturing.CreateWorkCenter(WorkCenter[1]);
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter[1], CalcDate('<-1Y>', WorkDate()), CalcDate('<1Y>', WorkDate()));
        CreateWorkCenterWithWorkCenterGroup(WorkCenter[2], CreateShopCalendarCodeWithAllDaysWorking(ShopCalendarWorkingDays));

        // // [GIVEN] Production BOM with 1 component "I1"
        LibraryInventory.CreateItem(CompItem);
        LibraryManufacturing.CreateCertifiedProductionBOM(productionBOmHeader, CompItem."No.", 1);

        // [GIVEN] Create Routing Header and Line.
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLineSetup(
            RoutingLine, RoutingHeader,
            WorkCenter[1]."No.", LibraryUtility.GenerateRandomCode(RoutingLine.FieldNo("Operation No."), DATABASE::"Routing Line"),
            1, 1);

        // [GIVEN] Update Standard Task on Routing Line.
        UpdateRoutingLineWithStandardTask(RoutingLine, StandardTask);

        // [GIVEN] Certify Routing.
        ChangeRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);

        // [GIVEN] Create Item with Production BOM and Routing.
        LibraryManufacturing.CreateItemManufacturing(
            Item,
            Item."Costing Method"::Standard,
            LibraryRandom.RandDec(100, 2),
            Item."Reordering Policy"::Order,
            Item."Flushing Method"::Backward,
            RoutingHeader."No.",
            productionBomHeader."No.");

        // [GIVEN] Create and Refresh Production Order.
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder,
            ProductionOrder.Status::Released,
            ProductionOrder."Source Type"::Item,
            Item."No.",
            LibraryRandom.RandInt(5));
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [GIVEN] Find Production Order Routing Line.
        FindProdOrderRoutingLine(ProdOrderRoutingLine, RoutingLine."Work Center No.", RoutingLine."Operation No.");

        //[WHEN] Change Work Center on Production Order Routing Line.
        ModifyWorkCenterOnProdOrderRtngLn(ProdOrderRoutingLine, WorkCenter[2]."No.");

        //[THEN] Verify that Routing Line desc same as Standard Code desciption.
        Assert.IsTrue((StandardTask.Description = ProdOrderRoutingLine.Description), '');
    end;

    [Test]
    [HandlerFunctions('ExchangeProductionBOMRequestPageDefaultValueCheckHandler')]
    procedure ExchangeProductionBOMRequestPageDefaultValueCheck()
    begin
        // [SCENARIO 563372] UX improvement for Tooltips and Setting Request Page fields(Exchange Type,With Type) Default Value.
        Initialize();

        // [WHEN] Run Exchange Production BOM Item report with blank Starting Date.
        RunExchangeProductionBOMItemReport();
    end;

    [Test]
    [HandlerFunctions('RunExchangeProdBOMItemReportWithStartDateParameter')]
    procedure ExchangeProductionBOMItemShouldSetEndingDate()
    var
        Item: array[5] of Record Item;
        MainItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        i: Integer;
    begin
        // [SCENARIO 592157] Replacing a component in a Production BOM should set the Ending Date of the replaced component.
        Initialize();

        LibraryInventory.CreateItem(MainItem);
        MainItem.Validate("Replenishment System", MainItem."Replenishment System"::"Prod. Order");
        MainItem.Modify(true);

        // [GIVEN] Create a Production BOM Header
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, MainItem."Base Unit of Measure");

        // [GIVEN] Create Items
        for i := 1 to 5 do
            LibraryInventory.CreateItem(Item[i]);

        // [GIVEN] Add only Items[1..4] to the BOM
        for i := 1 to 4 do
            LibraryManufacturing.CreateProductionBOMLine(
                ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item[i]."No.", LibraryRandom.RandIntInRange(10, 20));

        // [GIVEN] Certify BOM and assign to Main Item
        ModifyStatusInProductionBOM(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);
        MainItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        MainItem.Modify(true);

        // [GIVEN] Enqueue parameter values for report
        EnqueueExchProdBOMItemReportParameter(Item[1]."No.", Item[5]."No.", Today);

        // [WHEN] Run the Exchange Production BOM Item report
        RunExchangeProductionBOMItemReport();

        // [THEN] Validate that the replaced item has an Ending Date of (StartDate - 1)
        ValidateEndingDateSet(ProductionBOMHeader."No.", Item[1]."No.", Today);

        // [AND] Ensure no test artifacts are left behind
        LibraryVariableStorage.AssertEmpty();
    end;


    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Manufacturing");
        // Clear global variables.
        Clear(WorkCenterNo2);
        Clear(Capacity2);
        Clear(ProductionForecastName2);
        Clear(ItemNo2);
        Clear(LocationCode2);
        Clear(DateChangeFormula);
        Clear(ExchangeNo);
        Clear(WithNo);
        Clear(CreateNewVersion);
        Clear(DeleteExchangedComponent);
        Clear(GLB_ItemTrackingQty);
        Clear(GLB_SerialNo);
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Manufacturing");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        LibrarySetupStorage.SaveInventorySetup();
        LibrarySetupStorage.SaveManufacturingSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Manufacturing");
    end;

    local procedure PrepareUndoApplication(): Code[20]
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Decimal;
    begin
        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandDecInRange(10, 20, 2);

        CreateAndPostItemJournalLine(
          ItemJournalLine, ItemJournalLine."Entry Type"::Purchase, Item."No.",
          Quantity, WorkDate(), '');
        CreateAndPostItemJournalLine(
          ItemJournalLine, ItemJournalLine."Entry Type"::Sale, Item."No.",
          Quantity, WorkDate(), '');

        exit(Item."No.");
    end;

    local procedure FindILE(var ItemLedgEntry: Record "Item Ledger Entry"; ItemNo: Code[20]; EntryType: Enum "Item Ledger Document Type")
    begin
        ItemLedgEntry.SetRange("Item No.", ItemNo);
        ItemLedgEntry.SetRange("Entry Type", EntryType);
        ItemLedgEntry.FindFirst();
    end;

    local procedure Unapply(PositiveILENo: Integer; NegativeILENo: Integer)
    var
        ItemApplnEntry: Record "Item Application Entry";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
    begin
        ItemApplnEntry.SetRange("Inbound Item Entry No.", PositiveILENo);
        ItemApplnEntry.SetRange("Outbound Item Entry No.", NegativeILENo);
        ItemApplnEntry.FindFirst();
        ItemJnlPostLine.UnApply(ItemApplnEntry);
    end;

    local procedure SaveExistingILEs(var TempItemLedgEntry: Record "Item Ledger Entry" temporary; ItemNo: Code[20])
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemLedgEntry.SetRange("Item No.", ItemNo);
        ItemLedgEntry.FindSet();
        repeat
            TempItemLedgEntry := ItemLedgEntry;
            TempItemLedgEntry.Insert();
        until ItemLedgEntry.Next() = 0;
    end;

    local procedure AddParentItemAsBOMComponent(var ProductionBOMHeader: Record "Production BOM Header"; var ProductionBOMLine: Record "Production BOM Line"; Item: Record Item)
    begin
        ProductionBOMHeader.Get(Item."Production BOM No.");
        ModifyStatusInProductionBOM(ProductionBOMHeader, ProductionBOMHeader.Status::"Under Development");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item."No.", LibraryRandom.RandDec(100, 2));  // Taking Random Quantity.
    end;

    local procedure AddRoutingLine(var RoutingLine: Record "Routing Line"; RoutingNo: Code[20]; WorkCenterNo: Code[20]; OperationNo: Integer)
    var
        RoutingHeader: Record "Routing Header";
    begin
        RoutingHeader.Get(RoutingNo);
        ModifyRoutingStatus(RoutingHeader, RoutingHeader.Status::"Under Development");
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '', Format(OperationNo), RoutingLine.Type::"Work Center", WorkCenterNo);
        ModifyRunTimeOnRoutingLine(RoutingLine, LibraryRandom.RandInt(200));
        ModifyRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);
    end;

    local procedure CalculateRandomTime() RandomTime: Time
    begin
        Evaluate(RandomTime, Format(LibraryRandom.RandInt(23)));  // Use Random Values for Custom Time.
    end;

    local procedure CreateAndModifyProductionBOM(var ProductionBOMHeader: Record "Production BOM Header")
    var
        UnitOfMeasure: Record "Unit of Measure";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        ProductionBOMHeader.Get(CreateProductionBOM(UnitOfMeasure.Code));
        ModifyStatusInProductionBOM(ProductionBOMHeader, ProductionBOMHeader.Status::New);
        FindProductionBOMLine(ProductionBOMLine, ProductionBOMHeader."No.");
        ProductionBOMLine.Validate("Ending Date", CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));  // Use random Ending Date.
        ProductionBOMLine.Modify(true);
    end;

    local procedure CreateAndPostCapacityJournal(Quantity: Decimal; WorkCenterNo: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        SelectItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::Capacity);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Output, '', 0); // Zero used for Quantity.
        ItemJournalLine.Validate(Type, ItemJournalLine.Type::"Work Center");
        ItemJournalLine.Validate("No.", WorkCenterNo);
        ItemJournalLine.Validate("Stop Time", Quantity);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateAndPostConsumptionJournal(ProductionOrderNo: Code[20])
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        CalculateConsumptionJournal(ItemJournalBatch, ProductionOrderNo);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateAndPostItemJournalLine(ItemJournalLine: Record "Item Journal Line"; EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; Quantity: Decimal; PostingDate: Date; LocationCode: Code[10])
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        SelectItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, EntryType, ItemNo, Quantity);
        ItemJournalLine.Validate("Posting Date", PostingDate);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateAndRefreshProductionOrder(var ProductionOrder: Record "Production Order"; Status: Enum "Production Order Status"): Code[20]
    begin
        CreateAndRefreshProductionOrderWithItem(
          ProductionOrder, Status, CreateItemWithRoutingAndProductionBOM(), LibraryRandom.RandDecInRange(11, 20, 2));
        exit(ProductionOrder."No.");
    end;

    local procedure CreateAndRefreshProductionOrderWithItem(var ProductionOrder: Record "Production Order"; Status: Enum "Production Order Status"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, Status, ProductionOrder."Source Type"::Item, ItemNo, Quantity);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        ProductionOrder.Find();
    end;

    local procedure CreateAndRefreshProdOrderWithSpecificDueDate(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; DueDate: Date; Qty: Decimal; Forward: Boolean)
    var
        RlsdProdOrder: TestPage "Released Production Order";
    begin
        // Create Released Production Order
        LibraryManufacturing.CreateProductionOrder(ProductionOrder,
          ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, Qty);

        // Set Due Date and Refresh Production Order
        // Use page to modify Due Date of Production Order, since using Validate method on Production Order Record cannot work
        RlsdProdOrder.OpenEdit();
        RlsdProdOrder.FILTER.SetFilter("No.", ProductionOrder."No.");
        RlsdProdOrder."Due Date".SetValue(DueDate);
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, Forward, true, true, true, false);
    end;

    local procedure CreateBOMComponent(ParentItemNo: Code[20]; ItemNo: Code[20]; QuantityPer: Decimal)
    var
        BOMComponent: Record "BOM Component";
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        LibraryInventory.CreateBOMComponent(
          BOMComponent, ParentItemNo, BOMComponent.Type::Item, Item."No.", QuantityPer, Item."Base Unit of Measure");
    end;

    local procedure CreateCommentLineForProductionBOM(ProductionBOMNo: Code[20])
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMNo);
        ProductionBOMLine.FindFirst();
        LibraryManufacturing.CreateProductionBOMCommentLine(ProductionBOMLine);
    end;

    local procedure CreateCommentLineForItem(No: Code[20])
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        ProductionBOMLine.SetRange("No.", No);
        ProductionBOMLine.FindFirst();
        LibraryManufacturing.CreateProductionBOMCommentLine(ProductionBOMLine);
    end;

    local procedure CreateSalesOrderLinesAtLocations(var SalesLine: array[4] of Record "Sales Line"; var Item: array[4] of Record Item; SalesLineCount: Integer; DifferentLocations: Boolean)
    var
        SalesHeader: Record "Sales Header";
        Location: Record Location;
        LocationCode: Code[10];
        i: Integer;
    begin
        if not DifferentLocations then begin
            LibraryWarehouse.CreateLocation(Location);
            LocationCode := Location.Code;
        end;

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        for i := 1 to SalesLineCount do begin
            if DifferentLocations then begin
                LibraryWarehouse.CreateLocation(Location);
                LocationCode := Location.Code;
            end;
            LibrarySales.CreateSalesLine(SalesLine[i], SalesHeader, SalesLine[i].Type::Item, Item[i]."No.", LibraryRandom.RandInt(20));
            SalesLine[i].Validate("Location Code", LocationCode);
            SalesLine[i].Validate("Unit Price", LibraryRandom.RandDec(10, 2));
            SalesLine[i].Modify(true);
        end;
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CalculateConsumptionJournal(var ItemJournalBatch: Record "Item Journal Batch"; ProductionOrderNo: Code[20])
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        SelectItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::Consumption);
        LibraryManufacturing.CalculateConsumption(ProductionOrderNo, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CalculateEndingTime(WorkCenter: Record "Work Center"; StartingTime: Time) EndingTime: Time
    begin
        EndingTime := StartingTime + LibraryRandom.RandInt(5) * CalendarManagement.TimeFactor(WorkCenter."Unit of Measure Code");  // Adding Random value to Starting Time as Ending Time should be later than the Starting Time.
        if EndingTime < StartingTime then
            EndingTime := 235959T;  // Replace UpdatedTime with Maximum Time.
    end;

    local procedure CreateInitialSetupForReleasedProductionOrder(var ProductionOrder: Record "Production Order"; var ProdOrderComponent: Record "Prod. Order Component")
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released);
        FindProductionOrderComponent(ProdOrderComponent, ProductionOrder.Status, ProductionOrder."No.");
        CreateAndPostItemJournalLine(
          ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", ProdOrderComponent."Item No.",
          ProdOrderComponent."Expected Quantity", WorkDate(), '');
    end;

    local procedure CreateItemAndItemComponent(var ItemNo: Code[20]; var ComponentNo: Code[20])
    begin
        ItemNo := CreateItemWithRoutingAndProductionBOM();
        ComponentNo := CreateItemWithRoutingAndProductionBOM();
    end;

    local procedure CreateItemReclassJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; Quantity: Decimal)
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        SelectItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::Transfer);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemJournalLine."Entry Type"::" ", ItemNo,
          Quantity);
    end;

    local procedure CreateItemWithLotForLotReorderingPolicyAndSafetyStockQuantity(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item.Validate("Safety Stock Quantity", LibraryRandom.RandDec(100, 2));  // Use random value for Safety Stock Quantity.
        Item.Modify(true);
    end;

    local procedure CreateItemWithRouting(var Item: Record Item; RoutingNo: Code[20])
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Routing No.", RoutingNo);
        Item.Modify(true);
    end;

    local procedure CreateItemWithRoutingAndProductionBOM(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 2));  // Use random value for Unit Price.
        Item.Validate("Unit Cost", LibraryRandom.RandDec(100, 2));  // Use random value for Unit Cost.
        Item.Validate("Production BOM No.", CreateProductionBOM(Item."Base Unit of Measure"));
        Item.Validate("Routing No.", CreateRouting());
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateItemWithRoutingAndTwoWorkCenters(var WorkCenter: Record "Work Center"; var WorkCenter2: Record "Work Center"; var RoutingNo: Code[20]): Code[20]
    var
        Item: Record Item;
        ShopCalendarWorkingDays: Record "Shop Calendar Working Days";
    begin
        CreateWorkCenterWithWorkCenterGroup(WorkCenter, CreateShopCalendarCodeWithAllDaysWorking(ShopCalendarWorkingDays));
        CreateWorkCenterWithWorkCenterGroup(WorkCenter2, CreateShopCalendarCodeWithAllDaysWorking(ShopCalendarWorkingDays));

        RoutingNo := CreateCertifiedRoutingWithTwoLines(WorkCenter."No.", WorkCenter2."No.");

        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Routing No.", RoutingNo);
        Item.Modify();
        exit(Item."No.");
    end;

    local procedure CreateItemWithReorderingPolicy(var Item: Record Item; ReplenishmentSystem: Enum "Replenishment System"; ManufacturingPolicy: Enum "Manufacturing Policy"; InventoryPostingGroup: Code[20]; ProductionBOMNo: Code[20]; RoutingNo: Code[20])
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::Order);
        Item.Validate("Manufacturing Policy", ManufacturingPolicy);
        if InventoryPostingGroup <> '' then
            Item.Validate("Inventory Posting Group", InventoryPostingGroup);
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Validate("Routing No.", RoutingNo);
        Item.Modify(true);
    end;

    local procedure CreateItemWithReplenishmentSystemAndManufacturingPolicy(var Item: Record Item; ReplenishmentSystem: Enum "Replenishment System"; ManufacturingPolicy: Enum "Manufacturing Policy")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Manufacturing Policy", ManufacturingPolicy);
        Item.Modify(true);
    end;

    local procedure CreateMultipleItemsWithReorderingPolicy(var Item: Record Item; var Item2: Record Item; Quantity: Decimal)
    var
        InventoryPostingGroup: Record "Inventory Posting Group";
        BlankLocation: Record Location;
    begin
        LibraryInventory.CreateInventoryPostingGroup(InventoryPostingGroup);
        BlankLocation.Init();
        LibraryInventory.UpdateInventoryPostingSetup(BlankLocation);
        CreateItemWithReorderingPolicy(
          Item, Item."Replenishment System"::Purchase, Item."Manufacturing Policy"::"Make-to-Stock",
          InventoryPostingGroup.Code, '', '');
        CreateItemWithReorderingPolicy(
          Item2, Item."Replenishment System"::"Prod. Order", Item2."Manufacturing Policy"::"Make-to-Stock",
          InventoryPostingGroup.Code,
          CreateProductionBOMLineForSelectedItem(Item."No.", Item."Base Unit of Measure", Quantity), CreateRoutingWithRoutingLinkCode());
    end;

    local procedure CreateItemWithReorderingPolicyAndInventoryPostingGroup(var Item: Record Item; ReplenishmentSystem: Enum "Replenishment System"; ManufacturingPolicy: Enum "Manufacturing Policy"): Code[20]
    var
        InventoryPostingGroup: Record "Inventory Posting Group";
        BlankLocation: Record Location;
    begin
        LibraryInventory.CreateInventoryPostingGroup(InventoryPostingGroup);
        BlankLocation.Init();
        LibraryInventory.UpdateInventoryPostingSetup(BlankLocation);
        CreateItemWithReorderingPolicy(Item, ReplenishmentSystem, ManufacturingPolicy, InventoryPostingGroup.Code, '', '');
        exit(InventoryPostingGroup.Code);
    end;

    local procedure CreateLocation(): Code[10]
    var
        Location: Record Location;
    begin
        LibraryWarehouse.CreateLocation(Location);
        exit(Location.Code);
    end;

    local procedure CreateProdOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; ProdOrderStatus: Enum "Production Order Status"; ProdOrderNo: Code[20]; ProdOrderLineNo: Integer; ItemNo: Code[20]; LocationCode: Code[10]; QtyPer: Decimal)
    begin
        LibraryManufacturing.CreateProductionOrderComponent(ProdOrderComponent, ProdOrderStatus, ProdOrderNo, ProdOrderLineNo);
        ProdOrderComponent.Validate("Item No.", ItemNo);
        ProdOrderComponent.Validate("Quantity per", QtyPer);
        ProdOrderComponent.Validate("Location Code", LocationCode);
        ProdOrderComponent.Modify(true);
    end;

    local procedure CreateWhiteLocation(var Location: Record Location)
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Bin Mandatory", true);
        Location.Validate("Require Receive", true);
        Location.Validate("Require Shipment", true);
        Location.Validate("Require Put-away", true);
        Location.Validate("Require Pick", true);
        Location.Modify(true);
    end;

    local procedure CreateOutputJournal(var ItemJournalBatch: Record "Item Journal Batch"; var ItemJournalLine: Record "Item Journal Line"; ProductionOrderNo: Code[20])
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        SelectItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::Output);
        ItemJournalTemplate.Get(ItemJournalBatch."Journal Template Name");
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryManufacturing.CreateOutputJournal(ItemJournalLine, ItemJournalTemplate, ItemJournalBatch, '', ProductionOrderNo);
    end;

    local procedure CreateAndPostOutputJournal(ProductionOrderNo: Code[20]): Code[20]
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateOutputJournal(ItemJournalBatch, ItemJournalLine, ProductionOrderNo);
        LibraryManufacturing.OutputJnlExplodeRoute(ItemJournalLine);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        exit(ItemJournalLine."Document No.");
    end;

    local procedure CreateProductionBOM(UnitOfMeasureCode: Code[10]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        exit(CreateProductionBOMForSingleItem(Item."No.", UnitOfMeasureCode));
    end;

    local procedure CreateProductionBOMVersion(var ProdBomVersion: Record "Production BOM Version"; ProductionBOMNo: Code[20]; UnitOfMeasureCode: Code[10]; StartingDate: Date; Type: Enum "Production BOM Line Type"; No: Code[20]; Quantity: Decimal)
    var
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMLine: Record "Production BOM Line";
    begin
        ProdBOMHeader.Get(ProductionBOMNo);
        LibraryManufacturing.CreateProductionBOMVersion(ProdBomVersion, ProductionBOMNo, LibraryUtility.GenerateGUID(), UnitOfMeasureCode);
        ProdBomVersion.Validate("Starting Date", StartingDate);
        LibraryManufacturing.CreateProductionBOMLine(ProdBOMHeader, ProdBOMLine, ProdBomVersion."Version Code", Type, No, Quantity);
    end;

    local procedure CreateNamedProductionBOMVersion(var ProdBomVersion: Record "Production BOM Version"; ProductionBOMNo: Code[20]; UnitOfMeasureCode: Code[10]; StartingDate: Date; Type: Enum "Production BOM Line Type"; No: Code[20]; Quantity: Decimal; Version: Code[20])
    var
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMLine: Record "Production BOM Line";
    begin
        ProdBOMHeader.Get(ProductionBOMNo);
        LibraryManufacturing.CreateProductionBOMVersion(ProdBomVersion, ProductionBOMNo, Version, UnitOfMeasureCode);
        ProdBomVersion.Validate("Starting Date", StartingDate);
        LibraryManufacturing.CreateProductionBOMLine(ProdBOMHeader, ProdBOMLine, ProdBomVersion."Version Code", Type, No, Quantity);
    end;

    local procedure CreateProductionBOMWithComponent(UnitOfMeasureCode: Code[10]; ComponentItemNo: Code[20]; RoutingLinkCode: Code[10]): Code[20]
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, UnitOfMeasureCode);

        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ComponentItemNo, 1);
        // Qty per = 1
        ProductionBOMLine.Validate("Routing Link Code", RoutingLinkCode);
        ProductionBOMLine.Modify(true);

        ModifyStatusInProductionBOM(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);
        exit(ProductionBOMHeader."No.");
    end;

    local procedure CreateProductionForecastEntry(var ProductionForecastEntry: Record "Production Forecast Entry"; ProductionForecastName: Code[10])
    var
        Item: Record Item;
    begin
        LibraryManufacturing.CreateProductionForecastEntry(
          ProductionForecastEntry, ProductionForecastName, LibraryInventory.CreateItem(Item), CreateLocation(), WorkDate(), true);
        ProductionForecastEntry.Validate("Forecast Quantity (Base)", LibraryRandom.RandDec(100, 2));  // Use random value for Forecast Quantity Base.
        ProductionForecastEntry.Modify(true);
    end;

    local procedure CreateRegisteredAbsence(CapacityType: Enum "Capacity Type"; No: Code[20]; Date: Date; StartingTime: Time; EndingTime: Time): Decimal
    var
        RegisteredAbsence: Record "Registered Absence";
    begin
        LibraryManufacturing.CreateRegisteredAbsence(RegisteredAbsence, CapacityType, No, Date, StartingTime, EndingTime);
        RegisteredAbsence.Validate(Capacity, 100 + LibraryRandom.RandDec(10, 2));  // Taking Random value for Capacity.
        RegisteredAbsence.Modify(true);
        exit(RegisteredAbsence.Capacity);
    end;

    local procedure CreateRegisteredAbsenceAndEnqueueTime(WorkCenter: Record "Work Center"; Date: Date): Decimal
    var
        StartingTime: Time;
        EndingTime: Time;
    begin
        StartingTime := CalculateRandomTime();
        EndingTime := CalculateEndingTime(WorkCenter, StartingTime);

        LibraryVariableStorage.Enqueue(StartingTime);
        LibraryVariableStorage.Enqueue(EndingTime);

        exit(CreateRegisteredAbsence(Enum::"Capacity Type"::"Work Center", WorkCenter."No.", Date, StartingTime, EndingTime));
    end;

    local procedure CreateMachineCenterRegAbsenceAndEnqueueTime(WorkCenter: Record "Work Center"; MachineCenterNo: Code[20]; Date: Date): Decimal
    var
        StartingTime: Time;
        EndingTime: Time;
    begin
        StartingTime := CalculateRandomTime();
        EndingTime := CalculateEndingTime(WorkCenter, StartingTime);

        LibraryVariableStorage.Enqueue(StartingTime);
        LibraryVariableStorage.Enqueue(EndingTime);

        exit(CreateRegisteredAbsence(Enum::"Capacity Type"::"Machine Center", MachineCenterNo, Date, StartingTime, EndingTime));
    end;

    local procedure CreateReleasedProductionOrder(var ProductionOrder: Record "Production Order"): Integer
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released);
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        exit(ProdOrderLine.Count);
    end;

    local procedure CreateRequisitionLine(var RequisitionLine: Record "Requisition Line")
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        Item: Record Item;
    begin
        CreateRequisitionWorksheetName(RequisitionWkshName);
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
        RequisitionLine.Validate(Type, RequisitionLine.Type::Item);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Modify();
        RequisitionLine.Validate("No.", Item."No.");
        RequisitionLine.Validate("Ending Date", WorkDate());
        RequisitionLine.Validate("Due Date", CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));  // Use random Due Date.
        RequisitionLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));  // Use random Quantity.
        RequisitionLine.Modify(true);
    end;

    local procedure CreateRequisitionLineWithDates(var RequisitionLine: Record "Requisition Line")
    begin
        CreateRequisitionLine(RequisitionLine);
        RequisitionLine.Validate("Action Message", RequisitionLine."Action Message"::New);
        RequisitionLine.Validate("Starting Date", WorkDate());
        RequisitionLine.Validate("Starting Time", Time);
        RequisitionLine.Validate("Ending Date", WorkDate() + 1);
        RequisitionLine.Validate("Ending Time", Time + 1);
        RequisitionLine.Modify(true);
    end;

    local procedure CreateCertifiedRoutingWithTwoLines(WorkCenterNo: Code[20]; WorkCenterNo2: Code[20]): Code[20]
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);

        LibraryManufacturing.CreateRoutingLine(
            RoutingHeader, RoutingLine, '', LibraryUtility.GenerateGUID(), RoutingLine.Type::"Work Center", WorkCenterNo);
        RoutingLine.Validate("Run Time", LibraryRandom.RandInt(10));
        RoutingLine.Modify();

        LibraryManufacturing.CreateRoutingLine(
            RoutingHeader, RoutingLine, '', LibraryUtility.GenerateGUID(), RoutingLine.Type::"Work Center", WorkCenterNo2);
        RoutingLine.Validate("Run Time", LibraryRandom.RandInt(10));
        RoutingLine.Modify();

        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
        exit(RoutingHeader."No.");
    end;

    local procedure CreateProductionBOMForSingleItem(ItemNo: Code[20]; UnitOfMeasureCode: Code[10]): Code[20]
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, UnitOfMeasureCode);
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ItemNo, LibraryRandom.RandDec(100, 2));
        ModifyStatusInProductionBOM(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);
        exit(ProductionBOMHeader."No.");
    end;

    local procedure CreateProductionBOMForSetOfItems(var Item: Record Item; UnitOfMeasureCode: Code[10]): Code[20]
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, UnitOfMeasureCode);
        if Item.FindSet() then
            repeat
                LibraryManufacturing.CreateProductionBOMLine(
                  ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(10, 20));
            until Item.Next() = 0;
        ModifyStatusInProductionBOM(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);
        exit(ProductionBOMHeader."No.");
    end;

    local procedure CreateProductionBOMForSingleItemNonCertified(var ProductionBOMHeader: Record "Production BOM Header"; UnitOfMeasureCode: Code[10]; ItemNo: Code[20]; Qty: Decimal)
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, UnitOfMeasureCode);
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ItemNo, Qty);
    end;

    local procedure CreateProductionBOMForSingleItemWithVariant(var Item: Record Item; UnitOfMeasureCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; Qty: Decimal)
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        CreateProductionBOMForSingleItemNonCertified(ProductionBOMHeader, UnitOfMeasureCode, ItemNo, Qty);

        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMHeader."No.");
        ProductionBOMLine.FindFirst();
        ProductionBOMLine.Validate("Variant Code", VariantCode);
        ProductionBOMLine.Modify(true);

        ModifyStatusInProductionBOM(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);

        CreateItemWithReorderingPolicy(
          Item, Item."Replenishment System"::"Prod. Order", Item."Manufacturing Policy"::"Make-to-Order", '',
          ProductionBOMLine."Production BOM No.", '');
    end;

    local procedure SetNewProductionBOMToItemForArrayOfChildItems(var ParentItem: Record Item; ChildItem: array[4] of Record Item; FromChildNo: Integer; ToChildNo: Integer)
    var
        TempChildSetItem: Record Item temporary;
        i: Integer;
    begin
        for i := FromChildNo to ToChildNo do begin
            TempChildSetItem := ChildItem[i];
            TempChildSetItem.Insert();
        end;
        ParentItem.Validate(
          "Production BOM No.", CreateProductionBOMForSetOfItems(TempChildSetItem, ParentItem."Base Unit of Measure"));
        ParentItem.Modify(true);
    end;

    local procedure CreateProductionBOMVersionWithTwoComponents(var ProdBOMVersion: Record "Production BOM Version"; var ProdBOMHeader: Record "Production BOM Header"; UnitOfMeasureCode: Code[10]; StartingDate: Date; ComponentCode1: Code[20]; ComponentCode2: Code[20])
    var
        ProdBOMLine: Record "Production BOM Line";
    begin
        CreateProductionBOMVersion(
          ProdBOMVersion, ProdBOMHeader."No.", UnitOfMeasureCode, StartingDate, ProdBOMLine.Type::Item, ComponentCode1, 1);
        LibraryManufacturing.CreateProductionBOMLine(
          ProdBOMHeader, ProdBOMLine, ProdBOMVersion."Version Code", ProdBOMLine.Type::Item, ComponentCode2, 1);
        ModifyProductionBOMVersionStatus(ProdBOMVersion, ProdBOMVersion.Status::Certified);
    end;

    local procedure CreateProdOrderLineWithWhiteLocationAndUpdateWorkCenterBinCode(var ProdOrderLine: Record "Prod. Order Line"; var WorkCenter: Record "Work Center"; var RoutingRefNo: Integer)
    var
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        Location: Record Location;
        Bin: Record Bin;
    begin
        CreateWhiteLocation(Location);
        LibraryWarehouse.CreateBin(
          Bin, Location.Code, LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), DATABASE::Bin), '', '');

        CreateReleasedProductionOrder(ProductionOrder);
        FindFirstProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");
        UpdateProdOrderLineLocationCode(ProdOrderLine, Location.Code);

        FindProductionOrderRoutingLine(ProdOrderRoutingLine, ProdOrderLine);
        ProdOrderRoutingLine."From-Production Bin Code" := LibraryUtility.GenerateGUID();
        ProdOrderRoutingLine.Modify();
        UpdateWorkCenterLocationCodeAndFromProdBinCode(WorkCenter, ProdOrderRoutingLine."Work Center No.", Location.Code, Bin.Code);
        RoutingRefNo := ProdOrderRoutingLine."Routing Reference No.";
    end;

    local procedure CreateReleasedProdOrderWithCustomStartingTime(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; Quantity: Decimal; StartingTime: Time)
    begin
        CreateAndRefreshProductionOrderWithItem(ProductionOrder, ProductionOrder.Status::Released, ItemNo, Quantity);
        ProductionOrder.Validate("Starting Time", StartingTime);
        ProductionOrder.Modify(true);
    end;

    local procedure CreateProdOrderLineWithGlobalDims(var ProductionOrder: Record "Production Order"; var ProdOrderLine: Record "Prod. Order Line"; var DimensionValue: array[2] of Record "Dimension Value")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        LibraryDimension.CreateDimensionValue(DimensionValue[1], GeneralLedgerSetup."Global Dimension 1 Code");
        LibraryDimension.CreateDimensionValue(DimensionValue[2], GeneralLedgerSetup."Global Dimension 2 Code");

        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released);
        FindFirstProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");
        SetGlobalDimsOnProdOrderLine(ProdOrderLine."Dimension Set ID", DimensionValue);
        ProdOrderLine.Modify(true);
    end;

    local procedure CreateRequisitionWorksheetName(var RequisitionWkshName: Record "Requisition Wksh. Name")
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        ReqWkshTemplate.SetRange(Type, ReqWkshTemplate.Type::Planning);
        RequisitionWkshName.SetRange(Recurring, false);
        ReqWkshTemplate.FindFirst();
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
    end;

    local procedure CreateRouting(): Code[20]
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
    begin
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '', Format(LibraryRandom.RandInt(100)), RoutingLine.Type::"Work Center", WorkCenter."No.");
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
        exit(RoutingHeader."No.");
    end;

    local procedure CreateRoutingOnCapacityConstrainedWorkCenter(var RoutingHeader: Record "Routing Header"; RunTime: Integer)
    var
        WorkCenter: Record "Work Center";
        RoutingLine: Record "Routing Line";
    begin
        CreateWorkCenterCapacityConstrained(WorkCenter);

        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '', LibraryUtility.GenerateGUID(), RoutingLine.Type::"Work Center", WorkCenter."No.");
        RoutingLine.Validate("Run Time", RunTime);
        RoutingLine.Modify(true);

        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
    end;

    local procedure CreateRoutingWithWorkCenter(WorkCenterNo: Code[20]; ConcurrentCapacities: Integer; RoutingLinkCode: Code[10]): Code[20]
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);

        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '', Format(LibraryRandom.RandInt(100)), RoutingLine.Type::"Work Center", WorkCenterNo);
        RoutingLine.Validate("Setup Time", 1);
        RoutingLine.Validate("Run Time", 1);
        RoutingLine.Validate("Concurrent Capacities", ConcurrentCapacities);
        RoutingLine.Validate("Routing Link Code", RoutingLinkCode);
        RoutingLine.Modify(true);

        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
        exit(RoutingHeader."No.");
    end;

    local procedure CreateShopCalendarCodeWithAllDaysWorking(var ShopCalendarWorkingDays: Record "Shop Calendar Working Days"): Code[10]
    var
        ShopCalendarWorkingDays2: Record "Shop Calendar Working Days";
        ShopCalendarCode: Code[10];
    begin
        ShopCalendarCode := LibraryManufacturing.UpdateShopCalendarWorkingDays();
        ShopCalendarWorkingDays.SetRange("Shop Calendar Code", ShopCalendarCode);
        ShopCalendarWorkingDays.FindFirst();
        LibraryManufacturing.CreateShopCalendarWorkingDays(
          ShopCalendarWorkingDays2, ShopCalendarCode, ShopCalendarWorkingDays.Day::Saturday, ShopCalendarWorkingDays."Work Shift Code",
          080000T, 160000T);
        LibraryManufacturing.CreateShopCalendarWorkingDays(
          ShopCalendarWorkingDays2, ShopCalendarCode, ShopCalendarWorkingDays.Day::Sunday, ShopCalendarWorkingDays."Work Shift Code",
          080000T, 160000T);
        exit(ShopCalendarCode);
    end;

    local procedure CreateWorkCenterWithWorkCenterGroup(var WorkCenter: Record "Work Center"; ShopCalendarCode: Code[10])
    begin
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        WorkCenter.Validate("Shop Calendar Code", ShopCalendarCode);
        WorkCenter.Modify(true);
    end;

    local procedure CreateWorkCenterWithCapacity(var WorkCenter: Record "Work Center"; CapacityToSet: Integer)
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        ShopCalendarWorkingDays: Record "Shop Calendar Working Days";
    begin
        LibraryManufacturing.CreateCapacityUnitOfMeasure(
          CapacityUnitOfMeasure, CapacityUnitOfMeasure.Type::Hours);
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        WorkCenter.Validate("Unit of Measure Code", CapacityUnitOfMeasure.Code);
        WorkCenter.Validate("Shop Calendar Code", CreateShopCalendarCodeWithAllDaysWorking(ShopCalendarWorkingDays));
        WorkCenter.Validate(Capacity, CapacityToSet);
        WorkCenter.Modify(true);

        LibraryManufacturing.CalculateWorkCenterCalendar(
          WorkCenter, CalcDate('<-1M>', WorkDate()), CalcDate('<+1M>', WorkDate()));
    end;

    local procedure CreateWorkCenterWithCalendarCode(var WorkCenter: Record "Work Center"; ShopCalendarCode: Code[10])
    begin
        CreateWorkCenterWithWorkCenterGroup(WorkCenter, '');
        WorkCenter.Validate("Shop Calendar Code", ShopCalendarCode);
        WorkCenter.Modify(true);
    end;

    local procedure CreateWorkCenterWithCalendarCodeAndRoundingPrecision(var WorkCenter: Record "Work Center"; ShopCalendarCode: Code[10]; Precision: Decimal)
    begin
        CreateWorkCenterWithCalendarCode(WorkCenter, ShopCalendarCode);
        WorkCenter.Validate("Calendar Rounding Precision", Precision);
        WorkCenter.Modify(true);
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, CalcDate('<-1M>', WorkDate()), CalcDate('<+1M>', WorkDate()));
    end;

    local procedure CreateMachineCenterAndUpdateProdOderRtngLine(var MachineCenter: Record "Machine Center"; var ProdOrderRtngLine: Record "Prod. Order Routing Line"; WorkCenter: Record "Work Center"; ProdOrderLine: Record "Prod. Order Line"; RoutingRefNo: Integer)
    var
        Bin: Record Bin;
    begin
        LibraryWarehouse.CreateBin(
          Bin, WorkCenter."Location Code", LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), DATABASE::Bin), '', '');

        LibraryManufacturing.CreateMachineCenter(MachineCenter, WorkCenter."No.", LibraryRandom.RandDec(10, 2));
        MachineCenter.Validate("From-Production Bin Code", Bin.Code);
        MachineCenter.Modify();

        ProdOrderRtngLine.SetRange(Status, ProdOrderLine.Status);
        ProdOrderRtngLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderRtngLine.SetRange("Routing Reference No.", RoutingRefNo);
        ProdOrderRtngLine.FindLast();
    end;

    local procedure CreateMachineCenter(WorkCenterNo: Code[20]): Code[20]
    var
        MachineCenter: Record "Machine Center";
    begin
        LibraryManufacturing.CreateMachineCenter(MachineCenter, WorkCenterNo, LibraryRandom.RandDec(10, 2));  // Taking Random value for Capacity.
        exit(MachineCenter."No.")
    end;

    local procedure CreateAndPostSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        CreateSalesOrder(SalesHeader, ItemNo, Quantity);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(10, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateProductionBOMLineForSelectedItem(ItemNo: Code[20]; UnitOfMeasureCode: Code[10]; Quantity: Decimal): Code[20]
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, UnitOfMeasureCode);
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ItemNo, Quantity);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
        exit(ProductionBOMHeader."No.");
    end;

    local procedure CreateRoutingWithRoutingLinkCode(): Code[20]
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
        RoutingLink: Record "Routing Link";
    begin
        WorkCenter.FindFirst();
        RoutingLink.FindFirst();
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '', Format(LibraryRandom.RandInt(100)), RoutingLine.Type::"Work Center", WorkCenter."No.");
        RoutingLine.Validate("Routing Link Code", RoutingLink.Code);
        RoutingLine.Modify(true);
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
        exit(RoutingHeader."No.");
    end;

    local procedure CreateRoutingWithCapacityConstrainedWorkCenterAndAbsence(var RoutingHeader: Record "Routing Header"; var RoutingLine: Record "Routing Line"; AbsenceEndingTime: Time)
    var
        WorkCenter: Record "Work Center";
        ShopCalendarWorkingDays: Record "Shop Calendar Working Days";
        CalendarAbsenceEntry: Record "Calendar Absence Entry";
        CapacityConstrainedResource: Record "Capacity Constrained Resource";
    begin
        CreateWorkCenterWithWorkCenterGroup(WorkCenter, CreateShopCalendarCodeWithAllDaysWorking(ShopCalendarWorkingDays));

        LibraryManufacturing.CreateCalendarAbsenceEntry(
          CalendarAbsenceEntry, CalendarAbsenceEntry."Capacity Type"::"Work Center", WorkCenter."No.", WorkDate(),
          ShopCalendarWorkingDays."Starting Time", AbsenceEndingTime, 1);
        CalendarAbsenceManagement.UpdateAbsence(CalendarAbsenceEntry);
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, CalcDate('<-CY>', WorkDate()), CalcDate('<CY>', WorkDate()));

        LibraryManufacturing.CreateCapacityConstrainedResource(
          CapacityConstrainedResource, CapacityConstrainedResource."Capacity Type"::"Work Center", WorkCenter."No.");
        CapacityConstrainedResource.Validate("Critical Load %", LibraryRandom.RandIntInRange(90, 99));
        CapacityConstrainedResource.Modify(true);

        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', Format(1), RoutingLine.Type::"Work Center", WorkCenter."No.");
        RoutingLine.Validate("Run Time", LibraryRandom.RandInt(10));
        RoutingLine.Modify(true);
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
    end;

    local procedure CreateMultipleProductionBOMLines(ItemNo: Code[20]; ItemNo2: Code[20]; UnitOfMeasureCode: Code[10]; Quantity: Decimal): Code[20]
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, UnitOfMeasureCode);
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ItemNo, Quantity);
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ItemNo2, Quantity);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
        exit(ProductionBOMHeader."No.");
    end;

    local procedure CreateProdBOMMultipleLinesRoutingLink(var ProductionBOMHeader: Record "Production BOM Header"; Item: array[10] of Record Item; RoutingLinkCode: array[10] of Code[10]; UnitOfMeasureCode: Code[10])
    var
        ProductionBOMLine: Record "Production BOM Line";
        ItemArrayCounter: Integer;
        ItemArrayLength: Integer;
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, UnitOfMeasureCode);
        ItemArrayLength := ArrayLen(Item);
        for ItemArrayCounter := 1 to ItemArrayLength do
            if Item[ItemArrayCounter]."No." <> '' then begin
                LibraryManufacturing.CreateProductionBOMLine(
                  ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item,
                  Item[ItemArrayCounter]."No.", LibraryRandom.RandInt(100));
                if RoutingLinkCode[ItemArrayCounter] <> '' then begin
                    ProductionBOMLine.Validate("Routing Link Code", RoutingLinkCode[ItemArrayCounter]);
                    ProductionBOMLine.Modify();
                end;
            end;
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure CreateShopCalendar(StartingTime: Time; EndingTime: Time): Code[10]
    var
        ShopCalendar: Record "Shop Calendar";
        ShopCalendarCode: Code[10];
    begin
        ShopCalendarCode := LibraryManufacturing.CreateShopCalendarCode(ShopCalendar);
        CreateShopCalendarWorkingDays(ShopCalendarCode, StartingTime, EndingTime);
        exit(ShopCalendarCode);
    end;

    local procedure CreateShopCalendarWorkingDays(ShopCalendarCode: Code[10]; StartingTime: Time; EndingTime: Time)
    var
        ShopCalendarWorkingDays: Record "Shop Calendar Working Days";
        WorkShift: Record "Work Shift";
        WorkShiftCode: Code[10];
    begin
        ShopCalendarWorkingDays.SetRange("Shop Calendar Code", ShopCalendarCode);
        WorkShiftCode := LibraryManufacturing.CreateWorkShiftCode(WorkShift);
        LibraryManufacturing.CreateShopCalendarWorkingDays(
          ShopCalendarWorkingDays, ShopCalendarCode, ShopCalendarWorkingDays.Day::Monday, WorkShiftCode, StartingTime, EndingTime);
        LibraryManufacturing.CreateShopCalendarWorkingDays(
          ShopCalendarWorkingDays, ShopCalendarCode, ShopCalendarWorkingDays.Day::Tuesday, WorkShiftCode, StartingTime, EndingTime);
        LibraryManufacturing.CreateShopCalendarWorkingDays(
          ShopCalendarWorkingDays, ShopCalendarCode, ShopCalendarWorkingDays.Day::Wednesday, WorkShiftCode, StartingTime, EndingTime);
        LibraryManufacturing.CreateShopCalendarWorkingDays(
          ShopCalendarWorkingDays, ShopCalendarCode, ShopCalendarWorkingDays.Day::Thursday, WorkShiftCode, StartingTime, EndingTime);
        LibraryManufacturing.CreateShopCalendarWorkingDays(
          ShopCalendarWorkingDays, ShopCalendarCode, ShopCalendarWorkingDays.Day::Friday, WorkShiftCode, StartingTime, EndingTime);
    end;

    local procedure CreateShopCalendarWeekendWorkingDays(ShopCalendarCode: Code[10]; StartingTime: Time; EndingTime: Time)
    var
        ShopCalendarWorkingDays: Record "Shop Calendar Working Days";
        WorkShift: Record "Work Shift";
        WorkShiftCode: Code[10];
    begin
        WorkShiftCode := LibraryManufacturing.CreateWorkShiftCode(WorkShift);
        LibraryManufacturing.CreateShopCalendarWorkingDays(
          ShopCalendarWorkingDays, ShopCalendarCode, ShopCalendarWorkingDays.Day::Saturday, WorkShiftCode, StartingTime, EndingTime);
        LibraryManufacturing.CreateShopCalendarWorkingDays(
          ShopCalendarWorkingDays, ShopCalendarCode, ShopCalendarWorkingDays.Day::Sunday, WorkShiftCode, StartingTime, EndingTime);
    end;

    local procedure CreateShopCalendarWithTwoWorkShifts(StartingTime: Time; ChangeShiftTime: Time; EndingTime: Time): Code[10]
    var
        ShopCalendarCode: Code[10];
    begin
        ShopCalendarCode := CreateShopCalendar(StartingTime, ChangeShiftTime);
        CreateShopCalendarWorkingDays(ShopCalendarCode, ChangeShiftTime, EndingTime);
        exit(ShopCalendarCode);
    end;

    local procedure CreateProdOrderWithComponentAndPostOutput(var ProductionOrder: Record "Production Order"; OutputItemNo: Code[20]; ComponentItemNo: Code[20]; ProdLocationCode: Code[10]; ComponentLocationCode: Code[10])
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, OutputItemNo, 1);
        ProductionOrder.Validate("Location Code", ProdLocationCode);
        ProductionOrder.Modify(true);

        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        FindProductionOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.", OutputItemNo);
        CreateProdOrderComponent(
          ProdOrderComponent, ProdOrderLine.Status, ProdOrderLine."Prod. Order No.",
          ProdOrderLine."Line No.", ComponentItemNo, ComponentLocationCode, 1);

        CreateAndPostOutputJournal(ProductionOrder."No.");

        TransferItem(OutputItemNo, 1, ProdLocationCode, ComponentLocationCode);
    end;

    local procedure CreateProdOrdersWithCrossReference(var OpenProdOrder: Record "Production Order")
    var
        Item: array[2] of Record Item;
        Location: array[2] of Record Location;
        ProductionOrder: array[2] of Record "Production Order";
    begin
        LibraryInventory.CreateItem(Item[1]);
        LibraryInventory.CreateItem(Item[2]);

        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[1]);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[2]);

        // 1st prod. order produces item[1] and consumes item[2], 2nd produces item[2] and consumes item[1]
        CreateProdOrderWithComponentAndPostOutput(ProductionOrder[1], Item[1]."No.", Item[2]."No.", Location[1].Code, Location[2].Code);
        CreateProdOrderWithComponentAndPostOutput(ProductionOrder[2], Item[2]."No.", Item[1]."No.", Location[1].Code, Location[2].Code);

        // Component for the 2nd production order is consumed, 1st is left on inventory
        CreateAndPostConsumptionJournal(ProductionOrder[2]."No.");
        OpenProdOrder := ProductionOrder[1];
    end;

    local procedure CreateProductionItemWithRouting(var Item: Record Item; var RoutingLine: Record "Routing Line"; WorkCenterNo: Code[20])
    var
        RoutingHeader: Record "Routing Header";
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
    begin
        // Create Routing, set work center and run time in routing line
        RoutingHeader.Get(CreateRouting());
        RoutingLine.SetRange("Routing No.", RoutingHeader."No.");
        RoutingLine.FindFirst();
        LibraryManufacturing.CreateCapacityUnitOfMeasure(CapacityUnitOfMeasure, CapacityUnitOfMeasure.Type::Minutes); // Create Unit Of Measure (Minutes) for Run Time on routing line
        ModifyWorkCenterAndRunTimeOnRoutingLine(
          RoutingLine, WorkCenterNo, CapacityUnitOfMeasure.Code, LibraryRandom.RandInt(200));

        // Create Production Item
        LibraryInventory.CreateItem(Item);
        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Modify(true);
    end;

    local procedure CreateProductionItemWithMultipleRoutingLines(var RoutingLine: Record "Routing Line"; var RoutingLine2: Record "Routing Line"; var Item: Record Item)
    var
        WorkCenter: Record "Work Center";
        OperationNo: Integer;
    begin
        CreateWorkCenterWithCalendarCode(WorkCenter, LibraryManufacturing.UpdateShopCalendarWorkingDays());
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, CalcDate('<-1M>', WorkDate()), CalcDate('<+1M>', WorkDate()));

        // Create Production Item with Routing, use the work center created above in routing line
        CreateProductionItemWithRouting(Item, RoutingLine, WorkCenter."No.");
        Evaluate(OperationNo, RoutingLine."Operation No.");
        AddRoutingLine(
          RoutingLine2, RoutingLine."Routing No.", WorkCenter."No.", OperationNo + LibraryRandom.RandInt(20)); // Add the second routing line
    end;

    local procedure CreateAndRefreshProdOrderWithSpecificItem(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; Forward: Boolean)
    begin
        // Create Released Production Order
        LibraryManufacturing.CreateProductionOrder(ProductionOrder,
          ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, LibraryRandom.RandDec(10, 2));
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, Forward, true, true, true, false);
    end;

    local procedure CreateAndRefreshProdOrderForMakeToOrderItem(var ProductionOrder: Record "Production Order")
    var
        ParentItem: Record Item;
        CompItem: Record Item;
        PurchasedItem: Record Item;
        InvtPostingGroupCode: Code[20];
    begin
        LibraryInventory.CreateItem(PurchasedItem);

        InvtPostingGroupCode :=
          CreateItemWithReorderingPolicyAndInventoryPostingGroup(
            CompItem, CompItem."Replenishment System"::"Prod. Order", CompItem."Manufacturing Policy"::"Make-to-Order");

        CreateItemWithReorderingPolicy(
          ParentItem, ParentItem."Replenishment System"::"Prod. Order", ParentItem."Manufacturing Policy"::"Make-to-Order",
          InvtPostingGroupCode, CreateMultipleProductionBOMLines(
            CompItem."No.", PurchasedItem."No.", CompItem."Base Unit of Measure", LibraryRandom.RandDec(100, 2)), '');

        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ParentItem."No.",
          LibraryRandom.RandDec(10, 2));
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateSalesOrderAndCalculateOrderPlan(Item: Record Item; ReplenishmentSystem: Enum "Replenishment System")
    var
        SalesHeader: Record "Sales Header";
        RequisitionLine: Record "Requisition Line";
    begin
        Item.Validate("Replenishment System", ReplenishmentSystem); // Modify the replenishment system for calculating Order Planning
        Item.Modify(true);
        CreateSalesOrder(SalesHeader, Item."No.", LibraryRandom.RandInt(10)); // Create a Sales Order for the item

        // Calculate Order Planning for Sales Demand, that will generate Planning Routing Line for the item
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);
    end;

    local procedure CreateWorkCenterAndProductionItem(var Item: Record Item; var RoutingLine: Record "Routing Line")
    var
        WorkCenter: Record "Work Center";
    begin
        // Create Production Item with two Routing Lines, the 1st one contains only run time, the second one contains only wait time
        CreateWorkCenterWithCalendarCode(WorkCenter, LibraryManufacturing.UpdateShopCalendarWorkingDays());
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, CalcDate('<-1M>', WorkDate()), CalcDate('<+1M>', WorkDate()));

        // Create Production Item with Routing, use the work center created above in routing line
        CreateProductionItemWithRouting(Item, RoutingLine, WorkCenter."No.");

        ModifyRunTimeOnRoutingLine(RoutingLine, 0); // Set run time to 0 for the convenience of calculating the starting datetime of the routing line with a random Quantity of items to produce
        ModifyWaitTimeOnRoutingLine(RoutingLine, LibraryRandom.RandIntInRange(7, 14) * 24 * 60); // Set wait time to 1 ~ 2 weeks
    end;

    local procedure CreateWorkCenterCapacityConstrained(var WorkCenter: Record "Work Center")
    var
        CapacityConstrainedResource: Record "Capacity Constrained Resource";
        ShopCalendarWorkingDays: Record "Shop Calendar Working Days";
    begin
        CreateWorkCenterWithWorkCenterGroup(WorkCenter, CreateShopCalendarCodeWithAllDaysWorking(ShopCalendarWorkingDays));
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, CalcDate('<-1W>', WorkDate()), CalcDate('<1W>', WorkDate()));
        LibraryManufacturing.CreateCapacityConstrainedResource(
          CapacityConstrainedResource, CapacityConstrainedResource."Capacity Type"::"Work Center", WorkCenter."No.");
    end;

    local procedure FilteringOnProdOrderCapacityNeed(var ProdOrderCapacityNeed: Record "Prod. Order Capacity Need"; WorkCenterNo: Code[20]; Date: Date)
    begin
        ProdOrderCapacityNeed.SetRange("No.", WorkCenterNo);
        ProdOrderCapacityNeed.SetRange(Date, Date);
    end;

    local procedure FindLastBOMVersionCode(ProdBOMNo: Code[20]): Code[20]
    var
        ProductionBOMVersion: Record "Production BOM Version";
    begin
        ProductionBOMVersion.SetRange("Production BOM No.", ProdBOMNo);
        ProductionBOMVersion.FindLast();
        exit(ProductionBOMVersion."Version Code");
    end;

    local procedure FindFirstBOMVersionCode(ProdBOMNo: Code[20]): Code[20]
    var
        ProductionBOMVersion: Record "Production BOM Version";
    begin
        ProductionBOMVersion.SetRange("Production BOM No.", ProdBOMNo);
        ProductionBOMVersion.FindFirst();
        exit(ProductionBOMVersion."Version Code");
    end;

    local procedure FindProductionOrderLine(var ProdOrderLine: Record "Prod. Order Line"; Status: Enum "Production Order Status"; ProdOrderNo: Code[20]; ItemNo: Code[20])
    begin
        ProdOrderLine.SetRange(Status, Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderLine.SetRange("Item No.", ItemNo);
        ProdOrderLine.FindFirst();
    end;

    local procedure FindFirstProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProdOrderStatus: Enum "Production Order Status"; ProdOrderNo: Code[20])
    begin
        ProdOrderLine.SetRange(Status, ProdOrderStatus);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderLine.FindFirst();
    end;

    local procedure FindProdOrderLineByItemNoLocationCodeAndPlanningLevelCode(var ProdOrderLine: Record "Prod. Order Line"; ItemNo: Code[20]; LocationCode: Code[10]; PlanningLevelCode: Integer)
    begin
        ProdOrderLine.SetRange("Item No.", ItemNo);
        ProdOrderLine.SetRange("Location Code", LocationCode);
        ProdOrderLine.SetRange("Planning Level Code", PlanningLevelCode);
        ProdOrderLine.FindFirst();
    end;

    local procedure GetQuantityPerFromProductionBOMLineByNo(var ProductionBOMLine: Record "Production BOM Line"; No: Code[20]): Decimal
    begin
        ProductionBOMLine.SetRange(Type, ProductionBOMLine.Type::Item);
        ProductionBOMLine.SetRange("No.", No);
        ProductionBOMLine.FindFirst();
        exit(ProductionBOMLine."Quantity per");
    end;

    local procedure FillTempBufOfProductionBOMLinesByBOMNo(var ProductionBOMLineBuf: Record "Production BOM Line"; BOMNo: Code[20])
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        ProductionBOMLine.SetRange("Production BOM No.", BOMNo);
        if ProductionBOMLine.FindSet() then
            repeat
                ProductionBOMLineBuf := ProductionBOMLine;
                ProductionBOMLineBuf.Insert();
            until ProductionBOMLine.Next() = 0;
    end;

    local procedure FindProductionBOMComponent(ProductionBOMNo: Code[20]): Code[20]
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMNo);
        ProductionBOMLine.FindFirst();
        exit(ProductionBOMLine."No.");
    end;

    local procedure FindProductionBOMLine(var ProductionBOMLine: Record "Production BOM Line"; ProductionBOMNo: Code[20]): Boolean
    begin
        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMNo);
        exit(ProductionBOMLine.FindFirst())
    end;

    local procedure FindProductionBOMLineByNo(var ProductionBOMLine: Record "Production BOM Line"; ProdBOMHeaderNo: Code[20]; ProdBomVersion: Code[20]; Component: Code[20]): Boolean
    begin
        ProductionBOMLine.SetRange("Production BOM No.", ProdBOMHeaderNo);
        ProductionBOMLine.SetRange("Version Code", ProdBomVersion);
        ProductionBOMLine.SetRange("No.", Component);
        ProductionBOMLine.FindFirst();
    end;

    local procedure FindProductionOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; ProductionOrderStatus: Enum "Production Order Status"; ProductionOrderNo: Code[20])
    begin
        ProdOrderComponent.SetRange(Status, ProductionOrderStatus);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrderNo);
        ProdOrderComponent.FindFirst();
    end;

    local procedure FindProductionOrderRoutingLine(var ProdOrdRtngLn: Record "Prod. Order Routing Line"; ProdOrdLn: Record "Prod. Order Line"): Boolean
    begin
        ProdOrdRtngLn.SetRange(Status, ProdOrdLn.Status);
        ProdOrdRtngLn.SetRange("Prod. Order No.", ProdOrdLn."Prod. Order No.");
        ProdOrdRtngLn.SetRange("Routing Reference No.", ProdOrdLn."Line No.");
        exit(ProdOrdRtngLn.FindFirst())
    end;

    local procedure FindProdOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; ProdOrderStatus: Enum "Production Order Status"; ProdOrderNo: Code[20])
    begin
        ProdOrderComponent.SetRange(Status, ProdOrderStatus);
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderComponent.FindFirst();
    end;

    local procedure FindPlanningRoutingLine(var PlanningRoutingLine: Record "Planning Routing Line"; WorkCenterNo: Code[20]; OperationNo: Code[10])
    begin
        PlanningRoutingLine.SetRange("Work Center No.", WorkCenterNo);
        PlanningRoutingLine.SetRange("Operation No.", OperationNo);
        PlanningRoutingLine.FindFirst();
    end;

    local procedure FindFirstProdOrderRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ProductionOrderStatus: Enum "Production Order Status"; ProductionOrderNo: Code[20])
    begin
        ProdOrderRoutingLine.SetRange(Status, ProductionOrderStatus);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrderNo);
        ProdOrderRoutingLine.FindFirst();
    end;

    local procedure FindProdOrderRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; WorkCenterNo: Code[20]; OperationNo: Code[10])
    begin
        ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenterNo);
        ProdOrderRoutingLine.SetRange("Operation No.", OperationNo);
        ProdOrderRoutingLine.FindFirst();
    end;

    local procedure FindProdOrderRtngLn(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ProductionOrderStatus: Enum "Production Order Status"; ProductionOrderNo: Code[20]; RoutingNo: Code[20]; WorkCenterNo: Code[20])
    begin
        ProdOrderRoutingLine.SetRange(Status, ProductionOrderStatus);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrderNo);
        ProdOrderRoutingLine.SetRange("Routing No.", RoutingNo);
        ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenterNo);
        ProdOrderRoutingLine.FindFirst();
    end;

    local procedure FindShopCalendarWorkingDaysForWorkCenter(var ShopCalendarWorkingDays: Record "Shop Calendar Working Days"; WorkCenterNo: Code[20]; Day: Option)
    var
        WorkCenter: Record "Work Center";
    begin
        WorkCenter.Get(WorkCenterNo);
        ShopCalendarWorkingDays.SetRange("Shop Calendar Code", WorkCenter."Shop Calendar Code");
        ShopCalendarWorkingDays.SetRange(Day, Day);
        ShopCalendarWorkingDays.FindFirst();
    end;

    local procedure GetCalendarEntry(var CalendarEntry: Record "Calendar Entry"; CapacityType: Enum "Capacity Type"; No: Code[20])
    begin
        CalendarEntry.SetRange("Capacity Type", CapacityType);
        CalendarEntry.SetRange("No.", No);
        CalendarEntry.FindFirst();
    end;

    local procedure GetRoundedTime(Date2: Date): Time
    begin
        exit(DT2Time(RoundDateTime(CreateDateTime(Date2, Time))));  // Rounding the Time for successfull verification.
    end;

    local procedure GetProdOrderCapacityNeedDate(WorkCenterNo: Code[20]): Date
    var
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
    begin
        ProdOrderCapacityNeed.SetRange("No.", WorkCenterNo);
        ProdOrderCapacityNeed.FindFirst();
        exit(ProdOrderCapacityNeed.Date);
    end;

    local procedure MockProdBOMHeaderWithVersionForItem(var ProductionBOMVersion: Record "Production BOM Version"; ItemNo: Code[20]; VersionStatus: Enum "BOM Status")
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        ProductionBOMHeader.Init();
        ProductionBOMHeader."No." := LibraryUtility.GenerateGUID();
        ProductionBOMHeader.Status := ProductionBOMHeader.Status::"Under Development";
        ProductionBOMHeader.Insert();
        ProductionBOMVersion.Init();
        ProductionBOMVersion."Production BOM No." := ProductionBOMHeader."No.";
        ProductionBOMVersion."Version Code" := LibraryUtility.GenerateGUID();
        ProductionBOMVersion.Status := VersionStatus;
        ProductionBOMVersion.Insert();
        MockProdBOMLine(ItemNo, ProductionBOMHeader."No.", ProductionBOMVersion."Version Code");
    end;

    local procedure MockProdBOMLine(ItemNo: Code[20]; ProdBOMHeaderNo: Code[20]; VersionNo: Code[20])
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        ProductionBOMLine.Init();
        ProductionBOMLine."Production BOM No." := ProdBOMHeaderNo;
        ProductionBOMLine."Version Code" := VersionNo;
        ProductionBOMLine.Type := ProductionBOMLine.Type::Item;
        ProductionBOMLine."No." := ItemNo;
        ProductionBOMLine.Insert();
    end;

    local procedure ModifyCapacityOfMachineCenter(MachineCenterNo: Code[20]): Decimal
    var
        MachineCenter: Record "Machine Center";
    begin
        MachineCenter.Get(MachineCenterNo);
        MachineCenter.Validate(Capacity, LibraryRandom.RandDec(10, 2));  // Taking Random value for Capacity.
        MachineCenter.Modify(true);
        exit(MachineCenter.Capacity);
    end;

    local procedure ModifyCapacityOfWorkCenter(var WorkCenter: Record "Work Center")
    begin
        WorkCenter.Validate(Capacity, LibraryRandom.RandDec(10, 2));  // Taking Random value for Capacity.
        WorkCenter.Modify(true);
    end;

    local procedure ModifyStatusInProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; Status: Enum "BOM Status")
    begin
        ProductionBOMHeader.Validate(Status, Status);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure ModifyProductionBOMVersionStatus(var ProdBomVersion: Record "Production BOM Version"; Status: Enum "BOM Status")
    begin
        ProdBomVersion.Validate(Status, Status);
        ProdBomVersion.Modify(true);
    end;

    local procedure ModifyWorkCenterAndCalculateCalendar(var WorkCenter: Record "Work Center"; AbsenceCapacity: Decimal)
    begin
        WorkCenter.Validate(Capacity, AbsenceCapacity + LibraryRandom.RandDec(10, 2));  // Adding Random value to Absence Capacity as Work Center Capacity should be greater than it.
        WorkCenter.Modify(true);
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, WorkDate(), WorkDate());
    end;

    local procedure ModifyRoutingStatus(var RoutingHeader: Record "Routing Header"; Status: Enum "Routing Status")
    begin
        RoutingHeader.Validate(Status, Status);
        RoutingHeader.Modify(true);
    end;

    local procedure ModifyWorkCenterAndWaitTimeOnRoutingLine(var RoutingLine: Record "Routing Line"; WorkCenterNo: Code[20]; CapacityUomCode: Code[10]; WaitTime: Integer)
    var
        RoutingHeader: Record "Routing Header";
    begin
        RoutingHeader.Get(RoutingLine."Routing No.");
        RoutingHeader.Validate(Status, RoutingHeader.Status::"Under Development");
        RoutingHeader.Modify(true);

        RoutingLine.Validate("No.", WorkCenterNo);
        RoutingLine.Validate("Wait Time", WaitTime);
        RoutingLine.Validate("Wait Time Unit of Meas. Code", CapacityUomCode);
        RoutingLine.Modify(true);

        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
    end;

    local procedure ModifyWorkCenterAndRunTimeOnRoutingLine(var RoutingLine: Record "Routing Line"; WorkCenterNo: Code[20]; CapacityUomCode: Code[10]; RunTime: Integer)
    var
        RoutingHeader: Record "Routing Header";
    begin
        RoutingHeader.Get(RoutingLine."Routing No.");
        ModifyRoutingStatus(RoutingHeader, RoutingHeader.Status::"Under Development");

        RoutingLine.Validate("No.", WorkCenterNo);
        RoutingLine.Validate("Run Time", RunTime);
        RoutingLine.Validate("Run Time Unit of Meas. Code", CapacityUomCode);
        RoutingLine.Modify(true);

        ModifyRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);
    end;

    local procedure ModifySetupTimeOnRoutingLine(var RoutingLine: Record "Routing Line"; SetupTime: Decimal)
    var
        RoutingHeader: Record "Routing Header";
    begin
        RoutingHeader.Get(RoutingLine."Routing No.");
        ModifyRoutingStatus(RoutingHeader, RoutingHeader.Status::"Under Development");
        RoutingLine.Validate("Setup Time", SetupTime);
        RoutingLine.Modify(true);
        ModifyRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);
    end;

    local procedure ModifyWaitTimeOnRoutingLine(var RoutingLine: Record "Routing Line"; WaitTime: Decimal)
    var
        RoutingHeader: Record "Routing Header";
    begin
        RoutingHeader.Get(RoutingLine."Routing No.");
        ModifyRoutingStatus(RoutingHeader, RoutingHeader.Status::"Under Development");
        RoutingLine.Validate("Wait Time", WaitTime);
        RoutingLine.Modify(true);
        ModifyRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);
    end;

    local procedure ModifyRunTimeOnRoutingLine(var RoutingLine: Record "Routing Line"; RunTime: Decimal)
    var
        RoutingHeader: Record "Routing Header";
    begin
        RoutingHeader.Get(RoutingLine."Routing No.");
        ModifyRoutingStatus(RoutingHeader, RoutingHeader.Status::"Under Development");
        RoutingLine.Validate("Run Time", RunTime);
        RoutingLine.Modify(true);
        ModifyRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);
    end;

    local procedure ModifyStartingDateOnProdOrderRtngLn(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; Date: Date)
    begin
        ProdOrderRoutingLine.Validate("Starting Date", Date);
        ProdOrderRoutingLine.Modify(true);
    end;

    local procedure ModifyEndingDateOnProdOrderRtngLn(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; Date: Date)
    begin
        ProdOrderRoutingLine.Validate("Ending Date", Date);
        ProdOrderRoutingLine.Modify(true);
    end;

    local procedure ModifyStartingDateOnPlanningRtngLn(var PlanningRoutingLine: Record "Planning Routing Line"; Date: Date)
    begin
        PlanningRoutingLine.Validate("Starting Date", Date);
        PlanningRoutingLine.Modify(true);
    end;

    local procedure ModifyEndingDateOnPlanningRtngLn(var PlanningRoutingLine: Record "Planning Routing Line"; Date: Date)
    begin
        PlanningRoutingLine.Validate("Ending Date", Date);
        PlanningRoutingLine.Modify(true);
    end;

    local procedure OutputJournalExplodeRouting(var ItemJournalBatch: Record "Item Journal Batch"; ProductionOrder: Record "Production Order")
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateOutputJournal(ItemJournalBatch, ItemJournalLine, ProductionOrder."No.");
        LibraryManufacturing.OutputJnlExplodeRoute(ItemJournalLine);
    end;

    local procedure PopulateRoutingOnOutputJournalLine(var ItemJournalLine: Record "Item Journal Line"; var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ProdOrderLine: Record "Prod. Order Line")
    begin
        FindFirstProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderLine.Status, ProdOrderLine."Prod. Order No.");
        ItemJournalLine.Validate("Routing No.", ProdOrderRoutingLine."Routing No.");
        ItemJournalLine.Validate("Routing Reference No.", ProdOrderRoutingLine."Routing Reference No.");
        ItemJournalLine.Validate("Item No.", ProdOrderLine."Item No.");
        ItemJournalLine.Validate("Operation No.", ProdOrderRoutingLine."Operation No.");
        ItemJournalLine.Validate(Type, ProdOrderRoutingLine.Type);
    end;

    local procedure ProdOrderCapacityNeedExist(ItemNo: Code[20]; CapacityDate: Date; StartingTime: Time; AllocatedTime: Decimal): Boolean
    var
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
    begin
        ProdOrderCapacityNeed.SetRange("No.", ItemNo);
        ProdOrderCapacityNeed.SetRange(Date, CapacityDate);
        ProdOrderCapacityNeed.SetRange("Starting Time", StartingTime);
        ProdOrderCapacityNeed.SetRange("Allocated Time", AllocatedTime);
        exit(not ProdOrderCapacityNeed.IsEmpty);
    end;

    local procedure ResetRunTimeOnRoutingLine(RoutingNo: Code[20]; WorkCenterNo: Code[20])
    var
        RoutingLine: Record "Routing Line";
    begin
        RoutingLine.SetRange("Routing No.", RoutingNo);
        RoutingLine.SetRange("Work Center No.", WorkCenterNo);
        RoutingLine.FindFirst();
        RoutingLine."Run Time" := 0;
        RoutingLine.Modify();
    end;

    local procedure ReserveComponentForProdOrder(ProdOrderStatus: Enum "Production Order Status"; ProdOrderNo: Code[20])
    var
        ProdOrderComponent: Record "Prod. Order Component";
        Reservation: Page Reservation;
    begin
        FindProdOrderComponent(ProdOrderComponent, ProdOrderStatus, ProdOrderNo);
        Reservation.SetReservSource(ProdOrderComponent);
        Reservation.RunModal();
    end;

    local procedure RestoreManufacturingSetup(DocNoIsProdOrderNo: Boolean)
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();
        ManufacturingSetup.Validate("Doc. No. Is Prod. Order No.", DocNoIsProdOrderNo);
        ManufacturingSetup.Modify(true);
    end;

    local procedure RunCopyProductionDocument(ProdOrderStatus: Enum "Production Order Status"; ProdOrderNo: Code[20]; NewProductionOrder: Record "Production Order")
    var
        CopyProductionOrderDocument: Report "Copy Production Order Document";
    begin
        Clear(CopyProductionOrderDocument);
        CopyProductionOrderDocument.SetProdOrder(NewProductionOrder);
        LibraryVariableStorage.Enqueue(ProdOrderStatus);
        LibraryVariableStorage.Enqueue(ProdOrderNo);
        CopyProductionOrderDocument.Run();
    end;

    local procedure RunCopyProductionForecast(var ProductionForecastEntry: Record "Production Forecast Entry")
    var
        CopyProductionForecast: Report "Copy Production Forecast";
    begin
        Commit();  // Commit required for batch job report.
        Clear(CopyProductionForecast);
        CopyProductionForecast.SetTableView(ProductionForecastEntry);
        CopyProductionForecast.Run();
    end;

    local procedure RunDeleteExpiredComponentsReport(var ProductionBOMHeader: Record "Production BOM Header")
    var
        DeleteExpiredComponents: Report "Delete Expired Components";
    begin
        Commit();  // Commit required for batch job.
        Clear(DeleteExpiredComponents);
        DeleteExpiredComponents.SetTableView(ProductionBOMHeader);
        DeleteExpiredComponents.Run();
    end;

    local procedure RunExchangeProductionBOMItemReport()
    var
        ExchangeProductionBOMItem: Report "Exchange Production BOM Item";
    begin
        Clear(ExchangeProductionBOMItem);
        Commit();  // Commit required for batch job report.
        ExchangeProductionBOMItem.Run();
    end;

    local procedure RunExchangeProdBOMItemReportWithParameters(ItemToExchangeNo: Code[20]; NewItemNo: Code[20]; CreateVersion: Boolean; DeleteExchangedComp: Boolean)
    begin
        ExchangeNo := ItemToExchangeNo;
        WithNo := NewItemNo;
        CreateNewVersion := CreateVersion;
        DeleteExchangedComponent := DeleteExchangedComp;
        RunExchangeProductionBOMItemReport();
    end;

    local procedure RunImplementRegisteredAbsenceReport(RegisteredAbsence: Record "Registered Absence")
    var
        ImplementRegisteredAbsence: Report "Implement Registered Absence";
    begin
        Commit();  // Commit is required to run the Report.
        RegisteredAbsence.SetRange("No.", RegisteredAbsence."No.");
        Clear(ImplementRegisteredAbsence);
        ImplementRegisteredAbsence.SetTableView(RegisteredAbsence);
        ImplementRegisteredAbsence.Run();
    end;

    local procedure RunRecalculateCalendarReport(var CalendarEntry: Record "Calendar Entry")
    var
        RecalculateCalendar: Report "Recalculate Calendar";
    begin
        Clear(RecalculateCalendar);
        Commit();  // COMMIT is required to run the Report.
        RecalculateCalendar.SetTableView(CalendarEntry);
        RecalculateCalendar.Run();
    end;

    local procedure RunRegAbsFromMachineCenterReport(MachineCenterNo: Code[20])
    var
        MachineCenter: Record "Machine Center";
        RegAbsFromMachineCtr: Report "Reg. Abs. (from Machine Ctr.)";
    begin
        MachineCenter.SetRange("No.", MachineCenterNo);
        Clear(RegAbsFromMachineCtr);
        RegAbsFromMachineCtr.SetTableView(MachineCenter);
        Commit();  // COMMIT is required to run the Report.
        RegAbsFromMachineCtr.Run();
    end;

    local procedure RunRegAbsFromWorkCenterReport(WorkCenterNo: Code[20])
    var
        WorkCenter: Record "Work Center";
        RegAbsFromWorkCenter: Report "Reg. Abs. (from Work Center)";
    begin
        WorkCenter.SetRange("No.", WorkCenterNo);
        Clear(RegAbsFromWorkCenter);
        RegAbsFromWorkCenter.SetTableView(WorkCenter);
        Commit();  // COMMIT is required to run the Report.
        RegAbsFromWorkCenter.Run();
    end;

    local procedure SelectItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; ItemJournalTemplateType: Enum "Item Journal Template Type")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplateType);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplateType, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure SetItemAndComponentQuantity(var ItemQuantity: Decimal; var ComponentQuantity: Decimal)
    begin
        // Use random values for Item and Component Quantity.
        ItemQuantity := LibraryRandom.RandDec(100, 2);
        ComponentQuantity := LibraryRandom.RandDec(100, 2);
    end;

    local procedure SetItemTrackingCodeSerialSpecific(ItemNo: Code[20])
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, false);

        Item.Get(ItemNo);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Modify(true);
    end;

    local procedure SetGlobalDimsOnProdOrderLine(var DimensionSetID: Integer; var DimensionValue: array[2] of Record "Dimension Value")
    begin
        DimensionSetID :=
          LibraryDimension.CreateDimSet(DimensionSetID, DimensionValue[1]."Dimension Code", DimensionValue[1].Code);
        DimensionSetID :=
          LibraryDimension.CreateDimSet(DimensionSetID, DimensionValue[2]."Dimension Code", DimensionValue[2].Code);
    end;

    local procedure SetupProdOrdWithRtng(var ProdOrd: Record "Production Order"; ItemNo: Code[20])
    var
        RlsdProdOrd: TestPage "Released Production Order";
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProdOrd, ProdOrd.Status::Released, ProdOrd."Source Type"::Item, ItemNo,
          LibraryRandom.RandDec(10, 2));  // Taking Random Quantity.
        RlsdProdOrd.OpenEdit();
        RlsdProdOrd.FILTER.SetFilter("No.", ProdOrd."No.");
        // Create Released Prod. Order Lines
        RlsdProdOrd.ProdOrderLines."Item No.".SetValue(ItemNo);
        RlsdProdOrd.ProdOrderLines.Quantity.SetValue(ProdOrd.Quantity / 2);
        RlsdProdOrd.ProdOrderLines.Next();
        RlsdProdOrd.ProdOrderLines."Item No.".SetValue(ItemNo);
        RlsdProdOrd.ProdOrderLines.Quantity.SetValue(ProdOrd.Quantity / 2);

        LibraryManufacturing.RefreshProdOrder(ProdOrd, false, false, true, false, false); // Select Calculating Lines when Refreshing Order
    end;

    local procedure SetupProdOrdLnWithPostedOutput(var ProdOrdLn: Record "Prod. Order Line")
    var
        Item: Record Item;
        ProdOrd: Record "Production Order";
        ProdJnlMgt: Codeunit "Production Journal Mgt";
    begin
        Item.Get(CreateItemWithRoutingAndProductionBOM());

        // Create a released Prod. Order, create 2 Prod. Order lines, calculate routings
        SetupProdOrdWithRtng(ProdOrd, Item."No.");

        // Find the first Prod. Order Line
        FindProductionOrderLine(ProdOrdLn, ProdOrd.Status, ProdOrd."No.", Item."No.");

        // Open and post Production Journal. Posting is done in ProductionJournalHandler function.
        ProdJnlMgt.Handling(ProdOrd, ProdOrdLn."Line No.");
    end;

    local procedure SetupForCalculateWaitingTimeWithMultipleCalendars(var Item: Record Item; var WorkCenter: Record "Work Center"; WaitTime: Integer): Date
    var
        ShopCalendarWorkingDays: Record "Shop Calendar Working Days";
        AllDaysWorkingWorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        RoutingLine2: Record "Routing Line";
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        InventorySetup: Record "Inventory Setup";
        StartingDate: Date;
    begin
        // Create Work Center with all days working Calender
        CreateWorkCenterWithCalendarCode(AllDaysWorkingWorkCenter, CreateShopCalendarCodeWithAllDaysWorking(ShopCalendarWorkingDays));

        // Create Work Center with Monday ~ Friday working Calender
        // The Ending Time of the Monday ~ Friday working Calendar cannot equal that of the Calender with all days working (4:00PM),
        // otherwise the issue mentioned in TFS48588 can not be reproed. It is not easy to set proper random value
        // for starting time and ending time, so use 11:00PM as ending time, and 8:00AM as starting time
        CreateWorkCenterWithCalendarCode(WorkCenter, CreateShopCalendar(080000T, 230000T));
        StartingDate := CalcDate('<WD6>', WorkDate()); // Get a Weekend Date, this will be the starting date for the routing line with weekend work day calendar
        LibraryManufacturing.CalculateWorkCenterCalendar(
          AllDaysWorkingWorkCenter, CalcDate('<-1M>', StartingDate), CalcDate('<+1M>', StartingDate)); // Calculate working days needed by the test
        LibraryManufacturing.CalculateWorkCenterCalendar(
          WorkCenter, CalcDate('<-1M>', StartingDate), CalcDate('<1M>', StartingDate)); // Calculate working days needed by the test

        LibraryManufacturing.CreateCapacityUnitOfMeasure(CapacityUnitOfMeasure, CapacityUnitOfMeasure.Type::Days); // Create Unit Of Measure (Days) for Wait Time on routing line

        // Create Routing with 2 routing lines
        RoutingHeader.Get(CreateRouting());
        RoutingHeader.Validate(Status, RoutingHeader.Status::"Under Development");
        RoutingHeader.Modify(true);
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '', Format(LibraryRandom.RandInt(100)), RoutingLine.Type::"Work Center", WorkCenter."No.");
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);

        // Set Monday ~ Friday working calendar to the first routing line, set all days working calendar to the second routing line
        // Set wait time for both lines
        RoutingLine2.SetRange("Routing No.", RoutingHeader."No.");
        RoutingLine2.FindSet();
        ModifyWorkCenterAndWaitTimeOnRoutingLine(RoutingLine2, WorkCenter."No.", CapacityUnitOfMeasure.Code, WaitTime);
        RoutingLine2.Next();
        ModifyWorkCenterAndWaitTimeOnRoutingLine(RoutingLine2, AllDaysWorkingWorkCenter."No.", CapacityUnitOfMeasure.Code, WaitTime);

        // Create Production Item
        LibraryInventory.CreateItem(Item);
        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Modify(true);

        // Calculate the due date of prod. order, since the ending date - starting date = WaitTime + 1 for the last routing line,
        // the ending date of the last routing line + Default Safety Lead Time = the prod. order due date
        // so use below formula to calculate prod. due date
        InventorySetup.Get();
        exit(CalcDate(InventorySetup."Default Safety Lead Time", CalcDate('<+' + Format(WaitTime + 1) + 'D>', StartingDate)));
    end;

    local procedure SetupWaitTimeOnProdOrderRtngLnWithoutCapactityConstrained(var RoutingLine: Record "Routing Line"; var RoutingLine2: Record "Routing Line")
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
    begin
        CreateProductionItemWithMultipleRoutingLines(RoutingLine, RoutingLine2, Item);
        ModifyRunTimeOnRoutingLine(RoutingLine, 0); // Set run time to 0 for the convenience of calculating the ending datetime of the routing line with a random Quantity of items to produce
        ModifyWaitTimeOnRoutingLine(RoutingLine, LibraryRandom.RandIntInRange(24 * 60, 48 * 60)); // Set wait time to 1 ~ 2 days
        CreateAndRefreshProdOrderWithSpecificItem(ProductionOrder, Item."No.", false); // Create and Refresh Released Production Order
    end;

    local procedure SetupWaitTimeOnPlanningRtngLnWithoutCapactityConstrained(var RoutingLine: Record "Routing Line"; var RoutingLine2: Record "Routing Line")
    var
        Item: Record Item;
    begin
        CreateProductionItemWithMultipleRoutingLines(RoutingLine, RoutingLine2, Item);
        ModifyRunTimeOnRoutingLine(RoutingLine, 0); // Set run time to 0 for the convenience of calculating the ending datetime of the routing line with a random Quantity of items to produce
        ModifyWaitTimeOnRoutingLine(RoutingLine, LibraryRandom.RandIntInRange(24 * 60, 48 * 60)); // Set wait time to 1 ~ 2 days
        CreateSalesOrderAndCalculateOrderPlan(Item, Item."Replenishment System"::"Prod. Order");
    end;

    local procedure SetupWaitTimeOnProdOrderRtngLnForBackwardCalculation(var RoutingLine: Record "Routing Line"; var RoutingLine2: Record "Routing Line")
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
    begin
        CreateProductionItemWithMultipleRoutingLines(RoutingLine, RoutingLine2, Item);
        ModifyRunTimeOnRoutingLine(RoutingLine2, 0); // Set run time to 0 for the convenience of calculating the starting datetime of the routing line with a random Quantity of items to produce
        ModifyWaitTimeOnRoutingLine(RoutingLine2, LibraryRandom.RandIntInRange(24 * 60, 48 * 60)); // Set wait time to 1 ~ 2 days
        CreateAndRefreshProdOrderWithSpecificItem(ProductionOrder, Item."No.", false); // Create and Refresh Released Production Order
    end;

    local procedure SetupWaitTimeOnPlanningRtngLnForBackwardCalculation(var RoutingLine: Record "Routing Line"; var RoutingLine2: Record "Routing Line")
    var
        Item: Record Item;
    begin
        CreateProductionItemWithMultipleRoutingLines(RoutingLine, RoutingLine2, Item);
        ModifyRunTimeOnRoutingLine(RoutingLine2, 0); // Set run time to 0 for the convenience of calculating the starting datetime of the routing line with a random Quantity of items to produce
        ModifyWaitTimeOnRoutingLine(RoutingLine2, LibraryRandom.RandIntInRange(24 * 60, 48 * 60)); // Set wait time to 1 ~ 2 days
        CreateSalesOrderAndCalculateOrderPlan(Item, Item."Replenishment System"::"Prod. Order");
    end;

    local procedure TransferItem(ItemNo: Code[20]; Qty: Decimal; FromLocationCode: Code[10]; ToLocationCode: Code[10])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemReclassJournalLine(ItemJournalLine, ItemNo, Qty);
        ItemJournalLine.Validate("Entry Type", ItemJournalLine."Entry Type"::Transfer);
        ItemJournalLine.Validate("Location Code", FromLocationCode);
        ItemJournalLine.Validate("New Location Code", ToLocationCode);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure UpdateInventorySetup(ExpectedCostPostingtoGL: Boolean; AutomaticCostPosting: Boolean)
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.Validate("Expected Cost Posting to G/L", ExpectedCostPostingtoGL);
        InventorySetup.Validate("Automatic Cost Posting", AutomaticCostPosting);
        InventorySetup.Modify(true);
    end;

    local procedure UpdateManufacturingSetup(NewDocNoIsProdOrderNo: Boolean) OldDocNoIsProdOrderNo: Boolean
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();
        OldDocNoIsProdOrderNo := ManufacturingSetup."Doc. No. Is Prod. Order No.";
        RestoreManufacturingSetup(NewDocNoIsProdOrderNo);
    end;

    local procedure UpdateDynamicLowLevelCodeInMfgSetup(DynamicLowLevelCode: Boolean)
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();
        ManufacturingSetup."Dynamic Low-Level Code" := DynamicLowLevelCode;
        ManufacturingSetup.Modify(true);
    end;

    local procedure UpdateProductionOrderComponent(ProductionOrderNo: Code[20]; ItemNo: Code[20])
    var
        ProdOrderComponent: Record "Prod. Order Component";
        RoutingLink: Record "Routing Link";
    begin
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrderNo);
        ProdOrderComponent.SetRange("Item No.", ItemNo);
        ProdOrderComponent.FindFirst();
        RoutingLink.FindFirst();
        ProdOrderComponent.Validate("Flushing Method", ProdOrderComponent."Flushing Method"::Backward);
        ProdOrderComponent.Validate("Routing Link Code", RoutingLink.Code);
        ProdOrderComponent.Modify(true);
    end;

    local procedure UpdateSalesReceivableSetup(var OldCreditWarnings: Option; var OldStockoutWarning: Boolean; NewCreditWarnings: Option; NewStockoutWarning: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        OldCreditWarnings := SalesReceivablesSetup."Credit Warnings";
        OldStockoutWarning := SalesReceivablesSetup."Stockout Warning";
        SalesReceivablesSetup.Validate("Credit Warnings", NewCreditWarnings);
        SalesReceivablesSetup.Validate("Stockout Warning", NewStockoutWarning);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdateProductionBOMOnParentItem(var Item: Record Item; ItemNo: Code[20]; ItemNo2: Code[20])
    begin
        Item.Validate(
          "Production BOM No.",
          CreateMultipleProductionBOMLines(ItemNo, ItemNo2, Item."Base Unit of Measure", LibraryRandom.RandDec(10, 2)));
        Item.Modify(true);
    end;

    local procedure UpdateProdOrderLineLocationCode(var ProdOrderLine: Record "Prod. Order Line"; LocationCode: Code[10])
    begin
        ProdOrderLine.Validate("Location Code", LocationCode);
        ProdOrderLine.Modify();
    end;

    local procedure UpdateWorkCenterLocationCodeAndFromProdBinCode(var WorkCenter: Record "Work Center"; WorkCenterNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20])
    begin
        WorkCenter.Get(WorkCenterNo);
        WorkCenter.Validate("Location Code", LocationCode);
        WorkCenter.Validate("From-Production Bin Code", BinCode);
        WorkCenter.Modify();
    end;

    local procedure VerifyCalculatedCapacity()
    var
        WorkCenter: Record "Work Center";
        ShopCalendarWorkingDays: Record "Shop Calendar Working Days";
        WorkCenterCalendar: TestPage "Work Center Calendar";
    begin
        WorkCenter.Get(WorkCenterNo2);
        ShopCalendarWorkingDays.SetRange("Shop Calendar Code", WorkCenter."Shop Calendar Code");
        ShopCalendarWorkingDays.SetRange(Day, Date2DWY(WorkDate(), 1) - 1);  // Indexing for Days start from 0-6.
        if ShopCalendarWorkingDays.FindFirst() then
            Capacity2 :=
              (ShopCalendarWorkingDays."Ending Time" - ShopCalendarWorkingDays."Starting Time") /
              CalendarManagement.TimeFactor(WorkCenter."Unit of Measure Code"); // Use Capacity2 as global for Handler.
        WorkCenterCalendar.OpenEdit();
        WorkCenterCalendar.ShowMatrix.Invoke();
    end;

    local procedure VerifyCalendarAbsenceEntry(WorkCenterNo: Code[20]; RegisteredAbsence: Record "Registered Absence")
    var
        CalendarAbsenceEntry: Record "Calendar Absence Entry";
    begin
        CalendarAbsenceEntry.SetFilter("Work Center No.", WorkCenterNo);
        CalendarAbsenceEntry.FindFirst();
        CalendarAbsenceEntry.TestField(Date, RegisteredAbsence.Date);
        CalendarAbsenceEntry.TestField(Capacity, RegisteredAbsence.Capacity);
        CalendarAbsenceEntry.TestField("Starting Time", RegisteredAbsence."Starting Time");
        CalendarAbsenceEntry.TestField("Ending Time", RegisteredAbsence."Ending Time");
    end;

    local procedure VerifyCalendarEntry(WorkCenterNo: Code[20]; CapacityTotal: Decimal)
    var
        CalendarEntry: Record "Calendar Entry";
    begin
        GetCalendarEntry(CalendarEntry, CalendarEntry."Capacity Type"::"Work Center", WorkCenterNo);
        CalendarEntry.TestField("Capacity (Total)", CapacityTotal);
    end;

    local procedure VerifyCapacityLedgerEntry(WorkCenterNo: Code[20]; Quantity: Decimal)
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
    begin
        CapacityLedgerEntry.SetRange("No.", WorkCenterNo);
        CapacityLedgerEntry.FindFirst();
        CapacityLedgerEntry.TestField(Quantity, Quantity);
    end;

    local procedure VerifyComponentNotOnInventoryError(ProdOrderStatus: Enum "Production Order Status"; ProdOrderNo: Code[20])
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        FindProdOrderComponent(ProdOrderComponent, ProdOrderStatus, ProdOrderNo);
        Assert.ExpectedError(StrSubstNo(IsNotOnInventoryErr, ProdOrderComponent."Item No."));
    end;

    local procedure VerifyComponentOnItemReclassJournal(ComponentNo: Code[20]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.SetRange("Item No.", ComponentNo);
        ItemJournalLine.FindFirst();
        ItemJournalLine.TestField(Quantity, Quantity);
    end;

    local procedure CreateProdOrderCompLineWithLocationRequirePick(var ProductionOrder: Record "Production Order"; var ProdOrderComponent: Record "Prod. Order Component")
    var
        ProdOrderLine: Record "Prod. Order Line";
        Location: Record Location;
    begin
        CreateWhiteLocation(Location);
        CreateReleasedProductionOrder(ProductionOrder);
        ProductionOrder.Validate("Location Code", Location.Code);
        ProductionOrder.Modify();
        FindFirstProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");
        FindProductionOrderComponent(ProdOrderComponent, ProductionOrder.Status, ProductionOrder."No.");
        ProdOrderComponent.Validate("Location Code", Location.Code);
        ProdOrderComponent.Modify();
    end;

    local procedure VerifyWhsePickRequestOnPositiveRemQty(var ProductionOrder: Record "Production Order"; var ProdOrderComponent: Record "Prod. Order Component")
    begin
        // [When] Production Order Component Line has a positive Remaining Quantity (Set through Quantity Per)
        ProdOrderComponent.Validate("Quantity per", 1);
        ProdOrderComponent.Modify(true);

        // [Then] There is a warehouse pick request associated with the Production Order Component Line
        Assert.IsTrue(WhsePickRequestExistsForReleasedProdOrder(ProductionOrder."No.", ProdOrderComponent."Location Code"), ExpectedWhsePickMsg);
    end;

    local procedure VerifyNoWhsePickRequestOnZeroRemQty(var ProductionOrder: Record "Production Order"; var ProdOrderComponent: Record "Prod. Order Component")
    begin
        // [When] Production Order Component Line has a 0 Remaining Quantity (Set through Quantity Per)
        ProdOrderComponent.Validate("Quantity per", 0);
        ProdOrderComponent.Modify(true);

        // [Then] There is no warehouse pick request associated with the Production Order Component Line
        Assert.IsFalse(WhsePickRequestExistsForReleasedProdOrder(ProductionOrder."No.", ProdOrderComponent."Location Code"), DidntExpectWhsePickMsg);
    end;

    local procedure WhsePickRequestExistsForReleasedProdOrder(DocNo: Code[20]; LocationCode: Code[10]): Boolean
    var
        WhsePickRequest: Record "Whse. Pick Request";
    begin
        WhsePickRequest.SetRange("Document Type", "Warehouse Pick Request Document Type"::Production);
        WhsePickRequest.SetRange("Document No.", DocNo);
        WhsePickRequest.SetRange("Document Subtype", "Production Order Status"::Released);
        WhsePickRequest.SetRange("Location Code", LocationCode);
        exit(not WhsePickRequest.IsEmpty());
    end;

    local procedure VerifyGlobalDimensionCodesInItemJournalBatch(ItemJournalBatch: Record "Item Journal Batch"; ShortcutDimension1Code: Code[20]; ShortcutDimension2Code: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.FindSet();
        repeat
            ItemJournalLine.TestField("Shortcut Dimension 1 Code", ShortcutDimension1Code);
            ItemJournalLine.TestField("Shortcut Dimension 2 Code", ShortcutDimension2Code);
        until ItemJournalLine.Next() = 0;
    end;

    local procedure VerifyItemJournalLine(ItemJournalBatch: Record "Item Journal Batch"; ProductionOrderNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.FindFirst();
        ItemJournalLine.TestField("Document No.", ProductionOrderNo);
        ItemJournalLine.TestField("Item No.", ItemNo);
        ItemJournalLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyEntryInRegisteredAbsence(No: Code[20]; Date: Date; Capacity: Decimal)
    var
        RegisteredAbsence: Record "Registered Absence";
    begin
        RegisteredAbsence.SetRange("No.", No);
        RegisteredAbsence.SetRange(Date, Date);
        RegisteredAbsence.FindFirst();
        RegisteredAbsence.TestField(Capacity, Capacity);
    end;

    local procedure VerifyGLEntry(InventoryPostingGroupCode: Code[20]; ProductionOrderNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
        InventoryPostingSetup: Record "Inventory Posting Setup";
    begin
        InventoryPostingSetup.SetRange("Invt. Posting Group Code", InventoryPostingGroupCode);
        InventoryPostingSetup.FindFirst();
        GLEntry.SetRange("Document No.", ProductionOrderNo);
        GLEntry.FindFirst();
        GLEntry.TestField("G/L Account No.", InventoryPostingSetup."Inventory Account (Interim)");
    end;

    local procedure VerifyItemLedgerEntry(ItemNo: Code[20]; EntryType: Enum "Item Ledger Document Type"; Quantity: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField(Quantity, Quantity);
    end;

    local procedure VerifyProdOrderLinesIncreaseAfterCopy(ProductionOrder: Record "Production Order"; NoOfRowsBeforeCopy: Integer)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        Assert.IsTrue(ProdOrderLine.Count > NoOfRowsBeforeCopy, CopyDocumentErr);
    end;

    local procedure VerifyProductionForecastEntry(ProductionForecastEntry: Record "Production Forecast Entry")
    var
        ProductionForecastEntry2: Record "Production Forecast Entry";
    begin
        ProductionForecastEntry2.SetRange("Production Forecast Name", ProductionForecastName2);
        ProductionForecastEntry2.FindFirst();
        ProductionForecastEntry2.TestField("Item No.", ProductionForecastEntry."Item No.");
        ProductionForecastEntry2.TestField("Forecast Date", CalcDate(DateChangeFormula, WorkDate()));
        ProductionForecastEntry2.TestField("Forecast Quantity", ProductionForecastEntry."Forecast Quantity");
        ProductionForecastEntry2.TestField("Location Code", ProductionForecastEntry."Location Code");
        ProductionForecastEntry2.TestField("Variant Code", ProductionForecastEntry."Variant Code");
        ProductionForecastEntry2.TestField("Component Forecast", ProductionForecastEntry."Component Forecast");
    end;

    local procedure VerifyProductionOrderStatistics(ProductionOrderNo: Code[20])
    var
        ProdOrderLine: Record "Prod. Order Line";
        ReleasedProductionOrders: TestPage "Released Production Orders";
        ProductionOrderStatistics: TestPage "Production Order Statistics";
    begin
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrderNo);
        ProdOrderLine.FindFirst();
        ReleasedProductionOrders.OpenView();
        ReleasedProductionOrders.FILTER.SetFilter("No.", ProductionOrderNo);
        ProductionOrderStatistics.Trap();
        ReleasedProductionOrders.Statistics.Invoke();
        ProductionOrderStatistics.ExpCapNeed.AssertEquals(
          (ProdOrderLine."Ending Date-Time" - ProdOrderLine."Starting Date-Time") /
          CalendarManagement.TimeFactor(Format(ProductionOrderStatistics.CapacityUoM)));
    end;

    local procedure VerifyProdOrderLineBinCode(var ProdOrderLine: Record "Prod. Order Line"; WorkCenterBinCode: Code[20])
    begin
        ProdOrderLine.Find();
        Assert.AreEqual(WorkCenterBinCode, ProdOrderLine."Bin Code", ProdOrderLineBinCodeErr);
    end;

    local procedure VerifyProdOrderLinesCount(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; ExpectedCount: Integer)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange("Item No.", ItemNo);
        ProdOrderLine.SetRange("Location Code", LocationCode);
        ProdOrderLine.SetRange("Variant Code", VariantCode);
        Assert.AreEqual(ExpectedCount, ProdOrderLine.Count, WrongProdOrderLinesCountErr);
    end;

    local procedure VerifyILEs(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemNo: Code[20]; Quantity: Integer; AppliesToEntryFilter: Text[100]; "Count": Integer)
    var
        MissingILEErr: Label 'Missing or excess Item Ledger Entries after reverse posting to Output Journal, under filters %1',
            Comment = '%1: Table filters';
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetFilter("Applies-to Entry", AppliesToEntryFilter);
        ItemLedgerEntry.SetRange(Quantity, Quantity);
        ItemLedgerEntry.FindSet();
        // Output Qty. * two normal postings
        Assert.AreEqual(Count, ItemLedgerEntry.Count, StrSubstNo(MissingILEErr, ItemLedgerEntry.GetFilters));
    end;

    local procedure VerifyDocumentNoExistOnItemLedgerEntry(DocumentNo: Code[20])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Document No.", DocumentNo);
        if ItemLedgerEntry.IsEmpty() then
            Error(DocumentNoDoesNotExistErr, DocumentNo);
    end;

    local procedure VerifyQuantityOnProdOrderLine(Status: Enum "Production Order Status"; ProductionOrderNo: Code[20]; ItemNo: Code[20]; QtyOnComponentLines: Decimal)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        FindProductionOrderLine(ProdOrderLine, Status, ProductionOrderNo, ItemNo);
        ProdOrderLine.TestField(Quantity, QtyOnComponentLines);
    end;

    local procedure VerifyExpectedQuantityOnProdOrderComponent(Item: Record Item; ProductionOrderNo: Code[20]; ProdOrderLineQuantity: Decimal)
    var
        ProdOrderComponent: Record "Prod. Order Component";
        ExpectedQuantity: Decimal;
    begin
        ProdOrderComponent.SetRange(Status, ProdOrderComponent.Status::Released);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrderNo);
        ProdOrderComponent.SetRange("Item No.", Item."No.");
        ProdOrderComponent.FindFirst();
        ExpectedQuantity := ProdOrderComponent."Quantity per" * ProdOrderLineQuantity;
        Assert.AreNearlyEqual(
          ExpectedQuantity, ProdOrderComponent."Expected Quantity", Item."Rounding Precision",
          StrSubstNo(ExpectedQuantityErr, ExpectedQuantity));
        Assert.AreNearlyEqual(
          ExpectedQuantity, ProdOrderComponent."Remaining Quantity", Item."Rounding Precision",
          StrSubstNo(ExpectedQuantityErr, ExpectedQuantity));
    end;

    local procedure VerifyDateTimeOnProdOrderRoutingLine(ProductionOrder: Record "Production Order"; RoutingNo: Code[20]; WorkCenterNo: Code[20]; WaitTime: Integer)
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        // Verify: Find the routing line with Monday ~ Friday working days
        ProdOrderRoutingLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange("Routing No.", RoutingNo);
        ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenterNo);
        ProdOrderRoutingLine.FindFirst();

        // Verify the start Date-Time and Ending Date-time
        Assert.AreEqual(
          CalcDate('<+' + Format(WaitTime) + 'D>', ProdOrderRoutingLine."Starting Date"),
          ProdOrderRoutingLine."Ending Date", '');

        // The starting time will be equal to ending time
        ProdOrderRoutingLine.TestField("Starting Time", ProdOrderRoutingLine."Ending Time");
    end;

    local procedure VerifyProductionBOMLineExists(ProductionBOMNo: Code[20]; VersionCode: Code[20]; No: Code[20]): Boolean
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        ProductionBOMLine.Init();
        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMNo);
        ProductionBOMLine.SetRange("Version Code", VersionCode);
        ProductionBOMLine.SetRange("No.", No);
        Assert.RecordIsNotEmpty(ProductionBOMLine);
    end;

    local procedure VerifyProductionBOMLineNotExists(ProductionBOMNo: Code[20]; VersionCode: Code[20]; No: Code[20])
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        ProductionBOMLine.Init();
        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMNo);
        ProductionBOMLine.SetRange("Version Code", VersionCode);
        ProductionBOMLine.SetRange("No.", No);
        Assert.RecordIsEmpty(ProductionBOMLine);
    end;

    local procedure VerifyExistingILEs(var TempItemLedgEntry: Record "Item Ledger Entry" temporary; ItemNo: Code[20])
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemLedgEntry.SetRange("Item No.", ItemNo);
        ItemLedgEntry.FindSet();
        repeat
            TempItemLedgEntry.Get(ItemLedgEntry."Entry No.");
            ItemLedgEntry.TestField("Remaining Quantity", TempItemLedgEntry."Remaining Quantity");
        until ItemLedgEntry.Next() = 0;
    end;

    local procedure VerifyProductionOrderLineToSalesLineMultiLevelStructureWhenAllLocationsAreDifferent(var Item: array[4] of Record Item; var SalesLine: array[4] of Record "Sales Line"; PlanningLevelCode: Integer; SalesLineAndTopLevelItemIndex: Integer; LevelOneItemIndex: Integer; LevelTwoItemIndex: Integer)
    var
        ProdOrderLine: Record "Prod. Order Line";
        TempProductionBOMLine: array[2] of Record "Production BOM Line" temporary;
        ProdOrderItemIndex: Integer;
        LevelOneMultiplicator: Decimal;
        LevelTwoMultiplicator: Decimal;
        i: Integer;
    begin
        for i := 1 to 2 do
            FillTempBufOfProductionBOMLinesByBOMNo(TempProductionBOMLine[i], Item[i]."Production BOM No.");

        LevelOneMultiplicator := 1;
        LevelTwoMultiplicator := 1;

        case PlanningLevelCode of
            0:
                ProdOrderItemIndex := SalesLineAndTopLevelItemIndex;
            1:
                begin
                    ProdOrderItemIndex := LevelOneItemIndex;
                    LevelOneMultiplicator := GetQuantityPerFromProductionBOMLineByNo(
                        TempProductionBOMLine[SalesLineAndTopLevelItemIndex], Item[LevelOneItemIndex]."No.");
                end;
            2:
                begin
                    ProdOrderItemIndex := LevelTwoItemIndex;
                    LevelOneMultiplicator :=
                      GetQuantityPerFromProductionBOMLineByNo(
                        TempProductionBOMLine[SalesLineAndTopLevelItemIndex], Item[LevelOneItemIndex]."No.");
                    LevelTwoMultiplicator :=
                      GetQuantityPerFromProductionBOMLineByNo(
                        TempProductionBOMLine[LevelOneItemIndex], Item[LevelTwoItemIndex]."No.");
                end;
        end;

        FindProdOrderLineByItemNoLocationCodeAndPlanningLevelCode(
          ProdOrderLine, Item[ProdOrderItemIndex]."No.",
          SalesLine[SalesLineAndTopLevelItemIndex]."Location Code", PlanningLevelCode);

        Assert.RecordCount(ProdOrderLine, 1);

        ProdOrderLine.TestField(
          "Quantity (Base)",
          SalesLine[SalesLineAndTopLevelItemIndex]."Quantity (Base)" * LevelOneMultiplicator * LevelTwoMultiplicator);
    end;

    local procedure VerifyProductionBOMLinePositionFields(ProductionBOMLine1: Record "Production BOM Line"; ProdBOMHeaderNo: Code[20]; ProdBomVersion: Code[20]; Component: Code[20])
    var
        ProductionBOMLine2: Record "Production BOM Line";
    begin
        FindProductionBOMLineByNo(ProductionBOMLine2, ProdBOMHeaderNo, ProdBomVersion, Component);
        ProductionBOMLine2.TestField(Position, ProductionBOMLine1.Position);
        ProductionBOMLine2.TestField("Position 2", ProductionBOMLine1."Position 2");
        ProductionBOMLine2.TestField("Position 3", ProductionBOMLine1."Position 3");
    end;

    local procedure GetReqLineComponents(var Components: Dictionary of [Code[20], Decimal]; RequisitionLine: Record "Requisition Line")
    var
        PlanningComponent: Record "Planning Component";
    begin
        Clear(Components);

        PlanningComponent.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningComponent.SetRange("Worksheet Batch Name", RequisitionLine."Journal Batch Name");
        PlanningComponent.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        if PlanningComponent.FindSet() then
            repeat
                Components.Add(PlanningComponent."Item No.", PlanningComponent.Quantity);
            until PlanningComponent.Next() = 0;
    end;

    local procedure CreateRequisitionWorksheetLineForItem(Item: Record Item; var RequisitionLine: Record "Requisition Line")
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        CreateRequisitionWorksheetName(RequisitionWkshName);
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
        RequisitionLine.Validate(Type, RequisitionLine.Type::Item);
        RequisitionLine.Validate("No.", Item."No.");
        RequisitionLine.Validate("Ending Date", WorkDate());
        RequisitionLine.Validate("Due Date", CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));  // Use random Due Date.
        RequisitionLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));  // Use random Quantity.
        RequisitionLine.Modify(true);
    end;

    local procedure SetProducionBOMLinePositionFields(var ProductionBOMLine: Record "Production BOM Line")
    var
        ProdBOMHeader: Record "Production BOM Header";
    begin
        ProdBOMHeader.SetRange("No.", ProductionBOMLine."Production BOM No.");
        ProdBOMHeader.FindFirst();
        ModifyStatusInProductionBOM(ProdBOMHeader, ProdBOMHeader.Status::"Under Development");
        ProductionBOMLine.Validate(Position, LibraryUtility.GenerateRandomXMLText(10));
        ProductionBOMLine.Validate("Position 2", LibraryUtility.GenerateRandomXMLText(10));
        ProductionBOMLine.Validate("Position 3", LibraryUtility.GenerateRandomXMLText(10));
        ProductionBOMLine.Modify(true);
        ModifyStatusInProductionBOM(ProdBOMHeader, ProdBOMHeader.Status);
    end;

    local procedure CreateSetofItems(var Item: Record Item; ItemsCount: Integer)
    var
        i: Integer;
    begin
        for i := 1 to ItemsCount do
            LibraryInventory.CreateItem(Item);
    end;

    local procedure FindProductionBOMVersionLine(var ProductionBOMLine: Record "Production BOM Line"; ProdBOMHeaderNo: Code[20]; ProdBOMVersion: Code[20])
    begin
        ProductionBOMLine.SetRange("Production BOM No.", ProdBOMHeaderNo);
        ProductionBOMLine.SetRange("Version Code", ProdBOMVersion);
        ProductionBOMLine.FindFirst();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CopyProductionOrderDocumentHandler(var CopyProductionOrderDocument: TestRequestPage "Copy Production Order Document")
    begin
        CopyProductionOrderDocument.Status.SetValue(LibraryVariableStorage.DequeueInteger());
        CopyProductionOrderDocument.DocumentNo.SetValue(LibraryVariableStorage.DequeueText());
        CopyProductionOrderDocument.IncludeHeader.SetValue(true);
        CopyProductionOrderDocument.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ImplementRegisteredAbsenceHandler(var ImplementRegisteredAbsence: TestRequestPage "Implement Registered Absence")
    begin
        ImplementRegisteredAbsence.Overwrite.SetValue(true);
        ImplementRegisteredAbsence.OK().Invoke();
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure RecalculateCalendarReportHandler(var RecalculateCalendar: Report "Recalculate Calendar")
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RegAbsFromWorkCenterReportHandler(var RegAbsFromWorkCenter: TestRequestPage "Reg. Abs. (from Work Center)")
    var
        ShowError: Boolean;
    begin
        RegAbsFromWorkCenter.StartingDate.SetValue(Format(0D));

        ShowError := LibraryVariableStorage.DequeueBoolean();
        if not ShowError then begin
            RegAbsFromWorkCenter.Overwrite.SetValue(LibraryVariableStorage.DequeueBoolean());
            RegAbsFromWorkCenter.StartingTime.SetValue(Format(LibraryVariableStorage.DequeueTime()));
            RegAbsFromWorkCenter.EndingTime.SetValue(Format(LibraryVariableStorage.DequeueTime()));
            RegAbsFromWorkCenter.StartingDate.SetValue(Format(WorkDate()));
            RegAbsFromWorkCenter.EndingDate.SetValue(Format(WorkDate()));
            RegAbsFromWorkCenter.Capacity.SetValue(LibraryVariableStorage.DequeueDecimal());

        end;
        RegAbsFromWorkCenter.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RegAbsFromMachineCenterReportHandler(var RegAbsFromMachineCenter: TestRequestPage "Reg. Abs. (from Machine Ctr.)")
    var
        ShowError: Boolean;
    begin
        ShowError := LibraryVariableStorage.DequeueBoolean();

        if not ShowError then begin
            RegAbsFromMachineCenter.StartingTime.SetValue(Format(LibraryVariableStorage.DequeueTime()));
            RegAbsFromMachineCenter.EndingTime.SetValue(Format(LibraryVariableStorage.DequeueTime()));
        end;

        RegAbsFromMachineCenter.StartingDate.SetValue(Format(WorkDate()));
        RegAbsFromMachineCenter.EndingDate.SetValue(Format(WorkDate()));
        RegAbsFromMachineCenter.Capacity.SetValue(LibraryVariableStorage.DequeueDecimal());
        RegAbsFromMachineCenter.Overwrite.SetValue(LibraryVariableStorage.DequeueBoolean());

        RegAbsFromMachineCenter.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RegAbsFromMachineCenterEndingTimeErrorReportHandler(var RegAbsFromMachineCenter: TestRequestPage "Reg. Abs. (from Machine Ctr.)")
    var
        ShowError: Boolean;
    begin
        RegAbsFromMachineCenter.StartingDate.SetValue(Format(0D));

        ShowError := LibraryVariableStorage.DequeueBoolean();

        if not ShowError then begin
            RegAbsFromMachineCenter.StartingTime.SetValue(Format(LibraryVariableStorage.DequeueTime()));
            RegAbsFromMachineCenter.EndingTime.SetValue(Format(LibraryVariableStorage.DequeueTime()));
        end;

        RegAbsFromMachineCenter.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WorkCenterCalendarMatrixHandler(var WorkCenterCalendarMatrix: TestPage "Work Center Calendar Matrix")
    begin
        WorkCenterCalendarMatrix.Filter.SetFilter("No.", WorkCenterNo2);
        WorkCenterCalendarMatrix.Field1.AssertEquals(Capacity2);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProductionJournalHandler(var ProductionJournal: TestPage "Production Journal")
    begin
        ProductionJournal.Last();
        ProductionJournal."Setup Time".SetValue(LibraryRandom.RandInt(5));  // Use random Setup Time value is not important.
        ProductionJournal."Run Time".SetValue(LibraryRandom.RandInt(5));  // Use random Run Time value is not important.
        ProductionJournal.Post.Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CopyProductionForecastHandler(var CopyProductionForecast: TestRequestPage "Copy Production Forecast")
    begin
        CopyProductionForecast.ProductionForecastName.SetValue(ProductionForecastName2);
        CopyProductionForecast.ItemNo.SetValue(ItemNo2);
        CopyProductionForecast.LocationCode.SetValue(LocationCode2);
        CopyProductionForecast.ComponentForecast.SetValue(true);
        CopyProductionForecast.DateChangeFormula.SetValue(DateChangeFormula);
        CopyProductionForecast.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ExchangeProductionBOMItemHandler(var ExchangeProductionBOMItem: TestRequestPage "Exchange Production BOM Item")
    begin
        ExchangeProductionBOMItem.ExchangeType.SetValue(1);  // Use 1 for Item.
        ExchangeProductionBOMItem.ExchangeNo.SetValue(ExchangeNo);
        ExchangeProductionBOMItem.WithType.SetValue(1);   // Use 1 for Item.
        ExchangeProductionBOMItem.WithNo.SetValue(WithNo);
        ExchangeProductionBOMItem."Create New Version".SetValue(CreateNewVersion);
        ExchangeProductionBOMItem.StartingDate.SetValue(Format(WorkDate()));
        ExchangeProductionBOMItem.Recertify.SetValue(true);
        ExchangeProductionBOMItem.CopyRoutingLink.SetValue(true);
        ExchangeProductionBOMItem."Delete Exchanged Component".SetValue(DeleteExchangedComponent);

        ExchangeProductionBOMItem.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ExchangeProductionBOMItemErrorHandler(var ExchangeProductionBOMItem: TestRequestPage "Exchange Production BOM Item")
    begin
        ExchangeProductionBOMItem.StartingDate.SetValue('');
        ExchangeProductionBOMItem.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DeleteExpiredComponentsHandler(var DeleteExpiredComponents: TestRequestPage "Delete Expired Components")
    var
        ShowError: Boolean;
    begin
        ShowError := LibraryVariableStorage.DequeueBoolean();
        if not ShowError then
            DeleteExpiredComponents.DeleteBefore.SetValue(Format(WorkDate()));
        DeleteExpiredComponents.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler2(Message: Text[1024])
    var
        MessageCount: Integer;
    begin
        Assert.IsTrue(StrPos(Message, LibraryVariableStorage.DequeueText()) > 0, Message);
        MessageCount := LibraryVariableStorage.DequeueInteger();
        MessageCount += 1;
        LibraryVariableStorage.Enqueue(MessageCount);
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure OptionDialog(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 1;  // Use 1 for Copy Dimensions from BOM.
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure ReserveOptionDialog(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin

        Choice := LibraryVariableStorage.DequeueInteger();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure OutputJournalItemtrackingPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        i: Integer;
    begin
        for i := 1 to Abs(GLB_ItemTrackingQty) do begin
            ItemTrackingLines."Serial No.".SetValue(GLB_SerialNo);
            ItemTrackingLines."Quantity (Base)".SetValue(GLB_ItemTrackingQty / Abs(GLB_ItemTrackingQty));
            ItemTrackingLines.Next();
            Commit();
            GLB_SerialNo := IncStr(GLB_SerialNo);
        end;
    end;

    local procedure PostOutputJournalWithIT(ProductionOrder: Record "Production Order"; Quantity: Integer)
    var
        ItemJournalLine: Record "Item Journal Line";
        OutputJournal: TestPage "Output Journal";
    begin
        ItemJournalLine.DeleteAll();
        Commit();

        OutputJournal.OpenEdit();
        OutputJournal."Order No.".SetValue(ProductionOrder."No.");
        OutputJournal."Item No.".SetValue(ProductionOrder."Source No.");
        OutputJournal."Operation No.".SetValue(FindOperationNo(ProductionOrder));
        OutputJournal."Output Quantity".SetValue(Quantity);

        GLB_ItemTrackingQty := Quantity;
        GLB_SerialNo := 'OUTPUT_REVERT_SN1';

        OutputJournal."Item Tracking Lines".Invoke(); // Jump to: OutputJournalItemtrackingPageHandler
        Commit();
        OutputJournal.Post.Invoke();
    end;

    local procedure SetQuantity(var ProductionOrder: Record "Production Order"; Quantity: Integer)
    begin
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
        ProductionOrder.Validate(Quantity, Quantity);
        ProductionOrder.Modify(true);
    end;

    local procedure FindOperationNo(ProductionOrder: Record "Production Order"): Code[10]
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.FindFirst();
        exit(ProdOrderRoutingLine."Operation No.");
    end;

    local procedure VerifyRelProductionOrderPage(ProductionOrder: Record "Production Order")
    var
        RelProdOrders: TestPage "Released Production Orders";
    begin
        RelProdOrders.OpenView();
        RelProdOrders.GoToRecord(ProductionOrder);
        LibraryVariableStorage.Enqueue(ProductionOrder."No.");
        LibraryVariableStorage.Enqueue(ProductionOrder.Status.AsInteger());
        RelProdOrders."Production Order - Comp. and Routing".Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ViewAppliedEntriesPageHandler(var ViewAppliedEntries: TestPage "View Applied Entries")
    var
        AppliedQuantity: Variant;
        ItemNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(ItemNo);
        LibraryVariableStorage.Dequeue(AppliedQuantity);
        ViewAppliedEntries.FILTER.SetFilter("Item No.", ItemNo);
        ViewAppliedEntries.ApplQty.AssertEquals(AppliedQuantity);
        ViewAppliedEntries.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ViewAppliedEntriesPageHandler2(var ViewAppliedEntries: TestPage "View Applied Entries")
    begin
        ViewAppliedEntries.RemoveAppButton.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ViewAppliedEntriesModalPageHandler(var ViewAppliedEntries: TestPage "View Applied Entries")
    begin
        ViewAppliedEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProdOrderRoutingHandler(var ProdOrderRouting: TestPage "Prod. Order Routing")
    var
        Variant: Variant;
    begin
        LibraryVariableStorage.Dequeue(Variant);
        ProdOrderRouting."No.".SetValue(Variant);
        ProdOrderRouting.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DummyProdOrderRoutingHandler(var ProdOrderRouting: TestPage "Prod. Order Routing")
    begin
        ProdOrderRouting.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure MachineCenterPageHandler(var MachineCenter: TestPage "Machine Center List")
    begin
        MachineCenter.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationHandler(var ReservationPage: TestPage Reservation)
    begin
        ReservationPage.First();
        ReservationPage."Auto Reserve".Invoke();
        ReservationPage.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingAssignLotNoPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        DequeueVariable: Variant;
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        ItemTrackingMode := DequeueVariable;
        case ItemTrackingMode of
            ItemTrackingMode::"Assign Lot No.":
                begin
                    ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
                    LibraryVariableStorage.Dequeue(DequeueVariable);
                    ItemTrackingLines."Quantity (Base)".SetValue(DequeueVariable);
                end;
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProductionJournalPageHandlerOnlyConsumption(var ProductionJournal: TestPage "Production Journal")
    var
        EntryType: Enum "Item Ledger Entry Type";
    begin
        Assert.IsTrue(ProductionJournal.FindFirstField(ProductionJournal."Entry Type", EntryType::Output), '');
        ProductionJournal."Output Quantity".SetValue(0);
        Assert.IsTrue(ProductionJournal.FindFirstField(ProductionJournal."Entry Type", EntryType::Consumption), '');
        ProductionJournal.Quantity.SetValue(LibraryVariableStorage.DequeueDecimal());
        ProductionJournal.ItemTrackingLines.Invoke();
        ProductionJournal.Post.Invoke();
    end;

    [PageHandler]
    procedure BOMStructurePageHandler(var BOMStructure: TestPage "BOM Structure")
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ProdOrderCompAndRoutingHandler(var ProdOrderCompAndRouting: TestRequestPage "Prod. Order Comp. and Routing")
    var
        ExpectedProdOrderNo: Code[20];
        ExpectedProdOrderStatus: Integer;
    begin
        ExpectedProdOrderNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(ExpectedProdOrderNo));
        ExpectedProdOrderStatus := LibraryVariableStorage.DequeueInteger();

        Assert.IsTrue(
            ProdOrderCompAndRouting."Production Order".GetFilter("No.") = ExpectedProdOrderNo,
            StrSubstNo(
                ProdOrderNoHandlerErr,
                ProdOrderCompAndRouting."Production Order".GetFilter("No."),
                ExpectedProdOrderNo));
        Assert.IsTrue(
            ProdOrderCompAndRouting."Production Order".GetFilter(Status) = Format(ExpectedProdOrderStatus),
            StrSubstNo(
                ProdOrderStatusHandlerErr,
                ProdOrderCompAndRouting."Production Order".GetFilter(Status),
                Format(ExpectedProdOrderStatus)));
    end;

    local procedure CreateRoutingAndBOM(ItemNo: Code[20]; ComponentNo: Code[20]; WorkCenterNo: Code[20]; ConcurrentCapacities: Integer; RoutingLinkCode: Code[10])
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Item.Validate(
          "Production BOM No.",
          CreateProductionBOMWithComponent(Item."Base Unit of Measure", ComponentNo, RoutingLinkCode));
        Item.Validate(
          "Routing No.",
          CreateRoutingWithWorkCenter(WorkCenterNo, ConcurrentCapacities, RoutingLinkCode));
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Manufacturing Policy", Item."Manufacturing Policy"::"Make-to-Order");
        Item.Modify(true);
    end;

    local procedure VerifyProdOrderDateTimes(ProductionOrder: Record "Production Order"; WorkCenterCapacity: Integer)
    var
        ProdOrderLine: Record "Prod. Order Line";
        ExpStartDateTime: DateTime;
        ExpEndDateTime: DateTime;
    begin
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindSet();
        ExpStartDateTime := ProdOrderLine."Ending Date-Time";
        repeat
            ExpEndDateTime := ExpStartDateTime;
            Assert.AreEqual(
              DT2Date(ExpEndDateTime), DT2Date(ProdOrderLine."Ending Date-Time"), StrSubstNo(WrongDateTimeErr, ProdOrderLine.FieldCaption("Ending Date")));
            Assert.AreEqual(
              DT2Time(ExpEndDateTime), DT2Time(ProdOrderLine."Ending Date-Time"), StrSubstNo(WrongDateTimeErr, ProdOrderLine.FieldCaption("Ending Time")));
            ExpStartDateTime := ExpEndDateTime - ((3600 * 1000) * (1 + ProdOrderLine.Quantity / WorkCenterCapacity));
            Assert.AreEqual(
              DT2Date(ExpStartDateTime), DT2Date(ProdOrderLine."Starting Date-Time"), StrSubstNo(WrongDateTimeErr, ProdOrderLine.FieldCaption("Starting Date")));
            Assert.AreEqual(
              DT2Time(ExpStartDateTime), DT2Time(ProdOrderLine."Starting Date-Time"), StrSubstNo(WrongDateTimeErr, ProdOrderLine.FieldCaption("Starting Time")));
        until ProdOrderLine.Next() = 0;
    end;

    local procedure CreateItemWithUOM(
        var Item: Record Item;
        var UnitOfMeasure: Record "Unit of Measure";
        var ItemUnitOfMeasure: Record "Item Unit of Measure")
    begin
        LibraryInventory.CreateItem(Item);

        LibraryInventory.CreateItemUnitOfMeasure(
            ItemUnitOfMeasure,
            Item."No.",
            UnitOfMeasure.Code,
            LibraryRandom.RandInt(0));

        Item.Validate("Base Unit of Measure", UnitOfMeasure.Code);
        Item.Modify(true);
    end;

    local procedure CreateAndPostItemJournalLineWithLotNo(
        ItemNo: Code[20];
        Quantity: Decimal;
        LotNo: Code[50];
        BinCode: Code[20];
        LocationCode: Code[10];
        Tracking: Boolean)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalLine(ItemJournalLine, ItemNo, Quantity, BinCode, LocationCode);
        if Tracking then begin
            LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Lot No.");
            LibraryVariableStorage.Enqueue(LotNo);
            LibraryVariableStorage.Enqueue(Quantity);
            ItemJournalLine.OpenItemTrackingLines(false);
        end;
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; Quantity: Decimal; BinCode: Code[20]; LocationCode: Code[10])
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(
            ItemJournalLine,
            ItemJournalBatch."Journal Template Name",
            ItemJournalBatch.Name,
            ItemJournalLine."Entry Type"::"Positive Adjmt.",
            ItemNo,
            Quantity);

        ItemJournalLine.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateAndRefreshProdOrder(var ProductionOrder: Record "Production Order"; Status: Enum "Production Order Status"; SourceNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; BinCode: Code[20])
    begin
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, Status, ProductionOrder."Source Type"::Item, SourceNo, Quantity);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Validate("Bin Code", BinCode);
        ProductionOrder.Modify(true);

        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure ModifyWorkCenterOnProdOrderRtngLn(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; WorkCenterNo: Code[20])
    begin
        ProdOrderRoutingLine.Validate("Work Center No.", WorkCenterNo);
        ProdOrderRoutingLine.Modify(true);
    end;

    local procedure ChangeRoutingStatus(var RoutingHeader: Record "Routing Header"; NewStatus: Enum "Routing Status")
    begin
        RoutingHeader.Validate(Status, NewStatus);
        RoutingHeader.Modify(true);
    end;

    local procedure UpdateRoutingLineWithStandardTask(var RoutingLine: Record "Routing Line"; StandardTask: Record "Standard Task")
    begin
        RoutingLine.Validate("Standard Task Code", StandardTask."Code");
        RoutingLine.Modify(true);
    end;

    local procedure ModifyRoutingLineWorkCenter(var RoutingLine: Record "Routing Line"; WorkCenterNo: Code[20])
    begin
        RoutingLine.Validate("Work Center No.", WorkCenterNo);
        RoutingLine.Modify(true);
    end;

    local procedure CreateStandardTasks(var StandardTask: Record "Standard Task")
    begin
        LibraryManufacturing.CreateStandardTask(StandardTask);
        UpdateStandardTaskDesc(StandardTask);
    end;

    local procedure UpdateStandardTaskDesc(var StandardTask: Record "Standard Task")
    begin
        standardTask.Validate("Description", Format(LibraryRandom.RandText(50)));
        standardTask.Modify(true);
    end;

    local procedure EnqueueExchProdBOMItemReportParameter(ExchangeItemNo: Code[20]; ReplaceItemNo: Code[20]; StartDate: Date)
    begin
        LibraryVariableStorage.Enqueue(ExchangeItemNo);
        LibraryVariableStorage.Enqueue(ReplaceItemNo);
        LibraryVariableStorage.Enqueue(StartDate);
    end;

    local procedure ValidateEndingDateSet(ProdBOMHeaderNo: Code[20]; ItemNo: Code[20]; StartingDate: Date)
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        ProductionBOMLine.SetRange("Production BOM No.", ProdBOMHeaderNo);
        ProductionBOMLine.SetRange("No.", ItemNo);
        ProductionBOMLine.FindFirst();
        Assert.AreEqual(StartingDate - 1, ProductionBOMLine."Ending Date", 'Ending Date is not correctly set on the Production BOM line.')
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProdBOMVersionComparisonHandlerForActionSet(var ProdBOMVersionComparison: TestPage "Prod. BOM Version Comparison")
    begin
        Assert.IsTrue(ProdBOMVersionComparison."Previous Set".Visible(), StrSubstNo(ActionMustBeVisibleErr, PreviousSetLbl, ProdBOMVersionComparison.Caption()));
        Assert.IsTrue(ProdBOMVersionComparison."Next Set".Visible(), StrSubstNo(ActionMustBeVisibleErr, NextSetLbl, ProdBOMVersionComparison.Caption()));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProdBOMVersionComparisonHandlerForBOMVersion(var ProdBOMVersionComparison: TestPage "Prod. BOM Version Comparison")
    var
        ExpectedValueForField1: Integer;
        ExpectedCaptionForField1: Code[20];
        ExpectedCaptionForBOMField1: Code[20];
        ExpectedValueForBOMField1: Integer;
    begin
        ProdBOMVersionComparison.First();

        ExpectedValueForBOMField1 := LibraryVariableStorage.DequeueInteger();
        ExpectedValueForField1 := LibraryVariableStorage.DequeueInteger();
        ExpectedCaptionForField1 := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(ExpectedCaptionForField1));
        ExpectedCaptionForBOMField1 := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(ExpectedCaptionForBOMField1));

        Assert.AreEqual(ExpectedValueForField1, ProdBOMVersionComparison.Field1.AsInteger(), StrSubstNo(ValueMustBeEqualErr, ProdBOMVersionComparison.Field1.Caption(), ExpectedValueForField1, ProdBOMVersionComparison.Caption()));
        Assert.AreEqual(ExpectedCaptionForField1, ProdBOMVersionComparison.Field1.Caption(), StrSubstNo(CaptionMustBeEqualErr, ProdBOMVersionComparison.Field1.Caption(), ExpectedCaptionForField1, ProdBOMVersionComparison.Caption()));
        Assert.AreEqual(ExpectedCaptionForBOMField1, ProdBOMVersionComparison.BOMField1.Caption(), StrSubstNo(CaptionMustBeEqualErr, ProdBOMVersionComparison.BOMField1.Caption(), ExpectedCaptionForBOMField1, ProdBOMVersionComparison.BOMField1.Caption()));
        Assert.AreEqual(ExpectedValueForBOMField1, ProdBOMVersionComparison.BOMField1.AsInteger(), StrSubstNo(ValueMustBeEqualErr, ProdBOMVersionComparison.BOMField1.Caption(), ExpectedValueForBOMField1, ProdBOMVersionComparison.Caption()));
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ProdBOMVersionComparisonListHandlerForActionSet(var ProdBOMVersionComparison: TestPage "Prod. BOM Version Comparison")
    begin
        Assert.IsTrue(ProdBOMVersionComparison."Previous Set".Visible(), StrSubstNo(ActionMustBeVisibleErr, PreviousSetLbl, ProdBOMVersionComparison.Caption()));
        Assert.IsTrue(ProdBOMVersionComparison."Next Set".Visible(), StrSubstNo(ActionMustBeVisibleErr, NextSetLbl, ProdBOMVersionComparison.Caption()));
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ProdBOMVersionComparisonListHandlerForBOMVersion(var ProdBOMVersionComparison: TestPage "Prod. BOM Version Comparison")
    var
        ExpectedValueForField1: Integer;
        ExpectedCaptionForField1: Code[20];
        ExpectedCaptionForBOMField1: Code[20];
        ExpectedValueForBOMField1: Integer;
    begin
        ProdBOMVersionComparison.First();

        ExpectedValueForBOMField1 := LibraryVariableStorage.DequeueInteger();
        ExpectedValueForField1 := LibraryVariableStorage.DequeueInteger();
        ExpectedCaptionForField1 := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(ExpectedCaptionForField1));
        ExpectedCaptionForBOMField1 := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(ExpectedCaptionForBOMField1));

        Assert.AreEqual(ExpectedValueForField1, ProdBOMVersionComparison.Field1.AsInteger(), StrSubstNo(ValueMustBeEqualErr, ProdBOMVersionComparison.Field1.Caption(), ExpectedValueForField1, ProdBOMVersionComparison.Caption()));
        Assert.AreEqual(ExpectedCaptionForField1, ProdBOMVersionComparison.Field1.Caption(), StrSubstNo(CaptionMustBeEqualErr, ProdBOMVersionComparison.Field1.Caption(), ExpectedCaptionForField1, ProdBOMVersionComparison.Caption()));
        Assert.AreEqual(ExpectedCaptionForBOMField1, ProdBOMVersionComparison.BOMField1.Caption(), StrSubstNo(CaptionMustBeEqualErr, ProdBOMVersionComparison.BOMField1.Caption(), ExpectedCaptionForBOMField1, ProdBOMVersionComparison.BOMField1.Caption()));
        Assert.AreEqual(ExpectedValueForBOMField1, ProdBOMVersionComparison.BOMField1.AsInteger(), StrSubstNo(ValueMustBeEqualErr, ProdBOMVersionComparison.BOMField1.Caption(), ExpectedValueForBOMField1, ProdBOMVersionComparison.Caption()));
    end;

    [PageHandler]
    procedure ProdBOMVersionComparisonListHandlerForBOMWithoutVersion(var ProdBOMVersionComparison: TestPage "Prod. BOM Version Comparison")
    var
        ExpectedCaptionForBOMField1: Code[20];
        ExpectedValueForBOMField1: Integer;
    begin
        ProdBOMVersionComparison.First();

        ExpectedValueForBOMField1 := LibraryVariableStorage.DequeueInteger();
        ExpectedCaptionForBOMField1 := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(ExpectedCaptionForBOMField1));

        Assert.IsFalse(ProdBOMVersionComparison.Field1.Visible(), StrSubstNo(FieldMustNotBeVisibleErr, ProdBOMVersionComparison.Field1.Caption(), ProdBOMVersionComparison.Caption()));
        Assert.AreEqual(ExpectedCaptionForBOMField1, ProdBOMVersionComparison.BOMField1.Caption(), StrSubstNo(CaptionMustBeEqualErr, ProdBOMVersionComparison.BOMField1.Caption(), ExpectedCaptionForBOMField1, ProdBOMVersionComparison.BOMField1.Caption()));
        Assert.AreEqual(ExpectedValueForBOMField1, ProdBOMVersionComparison.BOMField1.AsInteger(), StrSubstNo(ValueMustBeEqualErr, ProdBOMVersionComparison.BOMField1.Caption(), ExpectedValueForBOMField1, ProdBOMVersionComparison.Caption()));
    end;

    [RequestPageHandler]
    procedure ExchangeProductionBOMRequestPageDefaultValueCheckHandler(var ExchangeProductionBOMItem: TestRequestPage "Exchange Production BOM Item")
    var
        Item: Record Item;
        ProductionBOMLineType: Enum "Production BOM Line Type";
    begin
        ExchangeProductionBOMItem.ExchangeType.AssertEquals(ProductionBOMLineType::Item);// [THEN] Verify ExchangeType Default Type is ITEM
        Item.Reset();
        if Item.FindFirst() then;
        ExchangeProductionBOMItem.ExchangeNo.SetValue(Item."No.");
        ExchangeProductionBOMItem.WithType.AssertEquals(ProductionBOMLineType::Item);// [THEN] Verify WithType Default Type is ITEM
        ExchangeProductionBOMItem.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure RunExchangeProdBOMItemReportWithStartDateParameter(var ExchangeProductionBOMItem: TestRequestPage "Exchange Production BOM Item")
    var
        FromProductionBOMLineType: Enum "Production BOM Line Type";
        ExchangeItemNo: Variant;
        ReplaceItemNo: Variant;
        StartDate: Variant;
    begin
        ExchangeItemNo := LibraryVariableStorage.DequeueText();
        ReplaceItemNo := LibraryVariableStorage.DequeueText();
        StartDate := LibraryVariableStorage.DequeueDate();
        ExchangeProductionBOMItem.ExchangeType.SetValue(FromProductionBOMLineType::Item);
        ExchangeProductionBOMItem.ExchangeNo.SetValue(ExchangeItemNo);
        ExchangeProductionBOMItem.WithType.SetValue(FromProductionBOMLineType::Item);
        ExchangeProductionBOMItem.WithNo.SetValue(ReplaceItemNo);
        ExchangeProductionBOMItem."Create New Version".SetValue(false);
        ExchangeProductionBOMItem."Delete Exchanged Component".SetValue(false);
        ExchangeProductionBOMItem.Recertify.SetValue(true);
        ExchangeProductionBOMItem.CopyRoutingLink.SetValue(true);
        ExchangeProductionBOMItem.StartingDate.SetValue(StartDate);
        ExchangeProductionBOMItem.OK().Invoke();
    end;
}

