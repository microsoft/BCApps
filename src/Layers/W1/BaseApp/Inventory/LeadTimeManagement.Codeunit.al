// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory;

using Microsoft.Foundation.Calendar;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Transfer;

codeunit 5404 "Lead-Time Management"
{

    trigger OnRun()
    begin
    end;

    var
        InvtSetup: Record "Inventory Setup";
        Location: Record Location;
        Item: Record Item;
        TempSKU: Record "Stockkeeping Unit" temporary;
        CalChange: Record "Customized Calendar Change";
        LeadTimeCalcNegativeErr: Label 'The amount of time to replenish the item must not be negative.';
        GetPlanningParameters: Codeunit "Planning-Get Parameters";
        CalendarMgmt: Codeunit "Calendar Management";
        ManualScheduling: Boolean;

    procedure PurchaseLeadTime(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; VendorNo: Code[20]) Result: Code[20]
    var
        ItemVend: Record "Item Vendor";
    begin
        // Returns the leadtime in a date formula

        GetItem(ItemNo);
        ItemVend."Vendor No." := VendorNo;
        ItemVend."Variant Code" := VariantCode;
        Item.FindItemVend(ItemVend, LocationCode);
        Result := Format(ItemVend."Lead Time Calculation");

        OnAfterPurchaseLeadTime(ItemVend, Result);
    end;

    procedure ManufacturingLeadTime(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]) Result: Code[20]
    begin
        // Returns the leadtime in a date formula

        GetPlanningParameters.SetManualScheduling(ManualScheduling);
        GetPlanningParameters.AtSKU(TempSKU, ItemNo, VariantCode, LocationCode);
        Result := Format(TempSKU."Lead Time Calculation");
        OnAfterManufacturingLeadTime(TempSKU, Result);
    end;

    procedure SetManualScheduling(NewManualScheduling: Boolean)
    begin
        ManualScheduling := NewManualScheduling;
    end;

    procedure WhseOutBoundHandlingTime(LocationCode: Code[10]): Code[10]
    begin
        // Returns the outbound warehouse handling time in a date formula

        if LocationCode = '' then begin
            InvtSetup.Get();
            exit(Format(InvtSetup."Outbound Whse. Handling Time"));
        end;

        GetLocation(LocationCode);
        exit(Format(Location."Outbound Whse. Handling Time"));
    end;

    procedure WhseInBoundHandlingTime(LocationCode: Code[10]) Result: Code[10]
    var
        IsHandled: Boolean;
    begin
        // Returns the inbound warehouse handling time in a date formula
        IsHandled := false;
        OnBeforeWhseInBoundHandlingTime(LocationCode, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if LocationCode = '' then begin
            InvtSetup.Get();
            exit(Format(InvtSetup."Inbound Whse. Handling Time"));
        end;

        GetLocation(LocationCode);
        exit(Format(Location."Inbound Whse. Handling Time"));
    end;

    procedure SafetyLeadTime(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]) Result: Code[20]
    begin
        // Returns the safety lead time in a date formula

        GetPlanningParameters.SetManualScheduling(ManualScheduling);
        GetPlanningParameters.AtSKU(TempSKU, ItemNo, VariantCode, LocationCode);
        Result := Format(TempSKU."Safety Lead Time");
        OnAfterSafetyLeadTime(TempSKU, Result);
    end;

#if not CLEAN25
    [Obsolete('Replaced by procedure GetPlannedEndingDate()', '25.0')]
    procedure PlannedEndingDate(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; DueDate: Date; VendorNo: Code[20]; RefOrderType: Option " ",Purchase,"Prod. Order",Transfer,Assembly) Result: Date
    var
        IsHandled: Boolean;
    begin
        exit(GetPlannedEndingDate(ItemNo, LocationCode, VariantCode, DueDate, VendorNo, "Requisition Ref. Order Type".FromInteger(RefOrderType)));
    end;
#endif

    procedure GetPlannedEndingDate(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; DueDate: Date; VendorNo: Code[20]; RefOrderType: Enum "Requisition Ref. Order Type") Result: Date
    var
        CustomCalendarChange: array[2] of Record "Customized Calendar Change";
        TransferRoute: Record "Transfer Route";
        DateFormula: DateFormula;
        PlannedReceiptDate: Date;
        OrgDateExpression: Text[30];
        CheckBothCalendars: Boolean;
        IsHandled: Boolean;
    begin
#if not CLEAN25
        // Returns Ending Date calculated backward from Due Date
        IsHandled := false;
        OnBeforePlannedEndingDate(ItemNo, LocationCode, VariantCode, DueDate, VendorNo, RefOrderType.AsInteger(), Result, IsHandled);
        if IsHandled then
            exit(Result);
#endif
        // Returns Ending Date calculated backward from Due Date
        IsHandled := false;
        OnBeforeGetPlannedEndingDate(ItemNo, LocationCode, VariantCode, DueDate, VendorNo, RefOrderType, Result, IsHandled);
        if IsHandled then
            exit(Result);

        GetPlanningParameters.SetManualScheduling(ManualScheduling);
        GetPlanningParameters.AtSKU(TempSKU, ItemNo, VariantCode, LocationCode);

        if RefOrderType = RefOrderType::Transfer then begin
            Evaluate(DateFormula, WhseInBoundHandlingTime(LocationCode));
            TransferRoute.GetTransferRoute(
              TempSKU."Transfer-from Code", LocationCode, TransferRoute."In-Transit Code", TransferRoute."Shipping Agent Code", TransferRoute."Shipping Agent Service Code");
            TransferRoute.CalcPlanReceiptDateBackward(
              PlannedReceiptDate, DueDate, DateFormula, LocationCode, TransferRoute."Shipping Agent Code", TransferRoute."Shipping Agent Service Code");
            exit(PlannedReceiptDate);
        end;
#if not CLEAN25
        OnPlannedEndingDateOnBeforeFormatDateFormula(TempSKU, RefOrderType.AsInteger(), ItemNo, DueDate);
#endif
        OnGetPlannedEndingDateOnBeforeFormatDateFormula(TempSKU, RefOrderType, ItemNo, DueDate);
        FormatDateFormula(TempSKU."Safety Lead Time");
        OrgDateExpression := InternalLeadTimeDays(WhseInBoundHandlingTime(LocationCode) + Format(TempSKU."Safety Lead Time"));
        CustomCalendarChange[1].SetSource(CalChange."Source Type"::Location, LocationCode, '', '');
        if (VendorNo <> '') and (RefOrderType = RefOrderType::Purchase) then begin
            CustomCalendarChange[2].SetSource(CalChange."Source Type"::Vendor, VendorNo, '', '');
            CheckBothCalendars := true;
        end else
            CustomCalendarChange[2].SetSource(CalChange."Source Type"::Location, LocationCode, '', '');
        exit(CalendarMgmt.CalcDateBOC2(OrgDateExpression, DueDate, CustomCalendarChange, CheckBothCalendars));
    end;

#if not CLEAN25
    [Obsolete('Replaced by procedure GetPlannedStartingDate()', '25.0')]
    procedure PlannedStartingDate(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; VendorNo: Code[20]; LeadTime: Code[20]; RefOrderType: Option " ",Purchase,"Prod. Order",Transfer,Assembly; EndingDate: Date) Result: Date
    begin
        exit(GetPlannedStartingDate(ItemNo, LocationCode, VariantCode, VendorNo, LeadTime, "Requisition Ref. Order Type".FromInteger(RefOrderType), EndingDate));
    end;
#endif

    procedure GetPlannedStartingDate(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; VendorNo: Code[20]; LeadTime: Code[20]; RefOrderType: Enum "Requisition Ref. Order Type"; EndingDate: Date) Result: Date
    var
        CustomCalendarChange: array[2] of Record "Customized Calendar Change";
        TransferRoute: Record "Transfer Route";
        ShippingTime: DateFormula;
        PlannedShipmentDate: Date;
        CheckBothCalendars: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
#if not CLEAN25
        OnBeforePlannedStartingDate(ItemNo, LocationCode, VariantCode, VendorNo, LeadTime, RefOrderType.AsInteger(), EndingDate, Result, IsHandled);
#endif
        OnBeforeGetPlannedStartingDate(ItemNo, LocationCode, VariantCode, VendorNo, LeadTime, RefOrderType, EndingDate, Result, IsHandled);
        if not IsHandled then begin
            // Returns Starting Date calculated backward from Ending Date

            if RefOrderType = RefOrderType::Transfer then begin
                GetPlanningParameters.AtSKU(TempSKU, ItemNo, VariantCode, LocationCode);

                TransferRoute.GetTransferRoute(
                  TempSKU."Transfer-from Code", LocationCode, TransferRoute."In-Transit Code", TransferRoute."Shipping Agent Code", TransferRoute."Shipping Agent Service Code");
                TransferRoute.GetShippingTime(
                  TempSKU."Transfer-from Code", LocationCode, TransferRoute."Shipping Agent Code", TransferRoute."Shipping Agent Service Code", ShippingTime);
                TransferRoute.CalcPlanShipmentDateBackward(
                  PlannedShipmentDate, EndingDate, ShippingTime,
                  TempSKU."Transfer-from Code", TransferRoute."Shipping Agent Code", TransferRoute."Shipping Agent Service Code");
                exit(PlannedShipmentDate);
            end;
            if DateFormulaIsEmpty(LeadTime) then
                exit(EndingDate);

            if (VendorNo <> '') and (RefOrderType = RefOrderType::Purchase) then begin
                CustomCalendarChange[1].SetSource(CalChange."Source Type"::Vendor, VendorNo, '', '');
                CustomCalendarChange[2].SetSource(CalChange."Source Type"::Location, LocationCode, '', '');
                CheckBothCalendars := true;
            end else
                CustomCalendarChange[1].SetSource(CalChange."Source Type"::Location, LocationCode, '', '');
            Result := CalendarMgmt.CalcDateBOC2(InternalLeadTimeDays(LeadTime), EndingDate, CustomCalendarChange, CheckBothCalendars);
        end;
        OnAfterPlannedStartingDate(LeadTime, EndingDate, CustomCalendarChange, CheckBothCalendars, Result);
    end;

#if not CLEAN25
    [Obsolete('Replaced by procedure GetPlannedEndingDate()', '25.0')]
    procedure PlannedEndingDate(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; VendorNo: Code[20]; LeadTime: Code[20]; RefOrderType: Option " ",Purchase,"Prod. Order",Transfer,Assembly; StartingDate: Date) Result: Date
    begin
        exit(GetPlannedEndingDate(ItemNo, LocationCode, VariantCode, VendorNo, LeadTime, "Requisition Ref. Order Type".FromInteger(RefOrderType), StartingDate));
    end;
#endif

    procedure GetPlannedEndingDate(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; VendorNo: Code[20]; LeadTime: Code[20]; RefOrderType: Enum "Requisition Ref. Order Type"; StartingDate: Date) Result: Date
    var
        CustomCalendarChange: array[2] of Record "Customized Calendar Change";
        TransferRoute: Record "Transfer Route";
        ShippingTime: DateFormula;
        PlannedReceiptDate: Date;
        CheckBothCalendars: Boolean;
        IsHandled: Boolean;
    begin
#if not CLEAN25
        // Returns Ending Date calculated forward from Starting Date
        IsHandled := false;
        OnBeforePlannedEndingDateCalculaterForwardFromStartingDate(ItemNo, LocationCode, VariantCode, VendorNo, LeadTime, RefOrderType.AsInteger(), StartingDate, Result, IsHandled);
        if IsHandled then
            exit(Result);
#endif
        // Returns Ending Date calculated forward from Starting Date
        IsHandled := false;
        OnBeforeGetPlannedEndingDateCalculaterForwardFromStartingDate(ItemNo, LocationCode, VariantCode, VendorNo, LeadTime, RefOrderType, StartingDate, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if RefOrderType = RefOrderType::Transfer then begin
            GetPlanningParameters.AtSKU(TempSKU, ItemNo, VariantCode, LocationCode);

            TransferRoute.GetTransferRoute(
              TempSKU."Transfer-from Code", LocationCode, TransferRoute."In-Transit Code", TransferRoute."Shipping Agent Code", TransferRoute."Shipping Agent Service Code");
            TransferRoute.GetShippingTime(
              TempSKU."Transfer-from Code", LocationCode, TransferRoute."Shipping Agent Code", TransferRoute."Shipping Agent Service Code", ShippingTime);
            TransferRoute.CalcPlannedReceiptDateForward(
              StartingDate, PlannedReceiptDate, ShippingTime, LocationCode, TransferRoute."Shipping Agent Code", TransferRoute."Shipping Agent Service Code");
            exit(PlannedReceiptDate);
        end;
        if DateFormulaIsEmpty(LeadTime) then
            exit(StartingDate);

        if (VendorNo <> '') and (RefOrderType = RefOrderType::Purchase) then begin
            CustomCalendarChange[1].SetSource(CalChange."Source Type"::Vendor, VendorNo, '', '');
            CustomCalendarChange[2].SetSource(CalChange."Source Type"::Location, LocationCode, '', '');
            CheckBothCalendars := true;
        end else
            CustomCalendarChange[1].SetSource(CalChange."Source Type"::Location, LocationCode, '', '');
        exit(CalendarMgmt.CalcDateBOC(LeadTime, StartingDate, CustomCalendarChange, CheckBothCalendars));
    end;

#if not CLEAN25
    [Obsolete('Replaced by procedure GetPlannedDueDate()', '25.0')]
    procedure PlannedDueDate(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; EndingDate: Date; VendorNo: Code[20]; RefOrderType: Option " ",Purchase,"Prod. Order",Transfer,Assembly) Result: Date
    begin
        exit(GetPlannedDueDate(ItemNo, LocationCode, VariantCode, EndingDate, VendorNo, "Requisition Ref. Order Type".FromInteger(RefOrderType)));
    end;
#endif

    procedure GetPlannedDueDate(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; EndingDate: Date; VendorNo: Code[20]; RefOrderType: Enum "Requisition Ref. Order Type") Result: Date
    var
        CustomCalendarChange: array[2] of Record "Customized Calendar Change";
        TransferRoute: Record "Transfer Route";
        DateFormula: DateFormula;
        ReceiptDate: Date;
        OrgDateExpression: Text[30];
        CheckBothCalendars: Boolean;
        IsHandled: Boolean;
    begin
#if not CLEAN25
        // Returns Due Date calculated forward from Ending Date
        IsHandled := false;
        OnBeforePlannedDueDate(ItemNo, LocationCode, VariantCode, EndingDate, VendorNo, RefOrderType.AsInteger(), Result, IsHandled);
        if IsHandled then
            exit(Result);
#endif
        // Returns Due Date calculated forward from Ending Date
        IsHandled := false;
        OnBeforeGetPlannedDueDate(ItemNo, LocationCode, VariantCode, EndingDate, VendorNo, RefOrderType, Result, IsHandled);
        if IsHandled then
            exit(Result);

        GetPlanningParameters.SetManualScheduling(ManualScheduling);
        GetPlanningParameters.AtSKU(TempSKU, ItemNo, VariantCode, LocationCode);
#if not CLEAN25
        OnPlannedDueDateOnBeforeFormatDateFormula(TempSKU, RefOrderType.AsInteger(), EndingDate, ItemNo, LocationCode);
#endif
        OnGetPlannedDueDateOnBeforeFormatDateFormula(TempSKU, RefOrderType, EndingDate, ItemNo, LocationCode);
        FormatDateFormula(TempSKU."Safety Lead Time");

        if RefOrderType = RefOrderType::Transfer then begin
            Evaluate(DateFormula, WhseInBoundHandlingTime(LocationCode));
            TransferRoute.CalcReceiptDateForward(EndingDate, ReceiptDate, DateFormula, LocationCode);
            exit(ReceiptDate);
        end;
        OrgDateExpression := WhseInBoundHandlingTime(LocationCode) + Format(TempSKU."Safety Lead Time");
        CustomCalendarChange[1].SetSource(CalChange."Source Type"::Location, LocationCode, '', '');
        if (VendorNo <> '') and (RefOrderType = RefOrderType::Purchase) then begin
            CustomCalendarChange[2].SetSource(CalChange."Source Type"::Vendor, VendorNo, '', '');
            CheckBothCalendars := true;
        end;
        exit(CalendarMgmt.CalcDateBOC(OrgDateExpression, EndingDate, CustomCalendarChange, CheckBothCalendars));
    end;

    local procedure FormatDateFormula(var DateFormula: DateFormula)
    var
        DateFormulaText: Text;
    begin
        if Format(DateFormula) = '' then
            Evaluate(DateFormula, '<+0D>')
        else
            if not (CopyStr(Format(DateFormula), 1, 1) in ['+', '-']) then begin
                DateFormulaText := '+' + Format(DateFormula); // DateFormula is formated to local language
                Evaluate(DateFormula, DateFormulaText);
            end;
    end;

    local procedure GetItem(ItemNo: Code[20])
    begin
        if ItemNo <> Item."No." then
            Item.Get(ItemNo);
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if Location.Code <> LocationCode then
            Location.Get(LocationCode);
    end;

    local procedure InternalLeadTimeDays(DateFormulaText: Code[30]): Text[20]
    var
        TotalDays: DateFormula;
        DateFormulaLoc: DateFormula;
    begin
        Evaluate(DateFormulaLoc, DateFormulaText);
        Evaluate(TotalDays, '<' + Format(CalcDate(DateFormulaLoc, WorkDate()) - WorkDate()) + 'D>'); // DateFormulaText is formatet to local language
        exit(Format(TotalDays));
    end;

    local procedure DateFormulaIsEmpty(DateFormulaText: Code[30]): Boolean
    var
        DateFormula: DateFormula;
    begin
        if DateFormulaText = '' then
            exit(true);

        Evaluate(DateFormula, DateFormulaText);
        exit(CalcDate(DateFormula, WorkDate()) = WorkDate());
    end;

    procedure CheckLeadTimeIsNotNegative(LeadTimeDateFormula: DateFormula)
    begin
        if CalcDate(LeadTimeDateFormula, WorkDate()) < WorkDate() then
            Error(LeadTimeCalcNegativeErr);
    end;

#if not CLEAN25
    [Obsolete('Replaced by event OnBeforeGetPlannedDueDate()', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforePlannedDueDate(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; EndingDate: Date; VendorNo: Code[20]; RefOrderType: Option " ",Purchase,"Prod. Order",Transfer,Assembly; var Result: Date; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetPlannedDueDate(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; EndingDate: Date; VendorNo: Code[20]; RefOrderType: Enum "Requisition Ref. Order Type"; var Result: Date; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN25
    [Obsolete('Replaced by event OnBeforeGetPlannedEndingDate()', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforePlannedEndingDate(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; DueDate: Date; VendorNo: Code[20]; RefOrderType: Option " ",Purchase,"Prod. Order",Transfer,Assembly; var Result: Date; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetPlannedEndingDate(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; DueDate: Date; VendorNo: Code[20]; RefOrderType: Enum "Requisition Ref. Order Type"; var Result: Date; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN25
    [Obsolete('Replaced by event OnBeforeGetPlannedStartingDate()', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforePlannedStartingDate(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; VendorNo: Code[20]; var LeadTime: Code[20]; RefOrderType: Option " ",Purchase,"Prod. Order",Transfer,Assembly; EndingDate: Date; var Result: Date; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetPlannedStartingDate(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; VendorNo: Code[20]; var LeadTime: Code[20]; RefOrderType: Enum "Requisition Ref. Order Type"; EndingDate: Date; var Result: Date; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN25
    [Obsolete('Replaced by event OnGetPlannedEndingDateOnBeforeFormatDateFormula()', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPlannedDueDateOnBeforeFormatDateFormula(var SKU: Record "Stockkeeping Unit"; RefOrderType: Option " ",Purchase,"Prod. Order",Transfer,Assembly; EndingDate: Date; ItemNo: Code[20]; LocationCode: Code[10]);
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnGetPlannedDueDateOnBeforeFormatDateFormula(var SKU: Record "Stockkeeping Unit"; RefOrderType: Enum "Requisition Ref. Order Type"; EndingDate: Date; ItemNo: Code[20]; LocationCode: Code[10]);
    begin
    end;

#if not CLEAN25
    [Obsolete('Replaced by event OnGetPlannedEndingDateOnBeforeFormatDateFormula()', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnPlannedEndingDateOnBeforeFormatDateFormula(var SKU: Record "Stockkeeping Unit"; RefOrderType: Option " ",Purchase,"Prod. Order",Transfer,Assembly; ItemNo: code[20]; DueDate: Date);
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnGetPlannedEndingDateOnBeforeFormatDateFormula(var SKU: Record "Stockkeeping Unit"; RefOrderType: Enum "Requisition Ref. Order Type"; ItemNo: code[20]; DueDate: Date);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterManufacturingLeadTime(TempStockkeepingUnit: Record "Stockkeeping Unit" temporary; var Result: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPurchaseLeadTime(ItemVend: Record "Item Vendor"; var Result: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPlannedStartingDate(LeadTime: Code[20]; EndingDate: Date; CustomCalendarChange: array[2] of Record "Customized Calendar Change"; CheckBothCalendars: Boolean; var Result: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSafetyLeadTime(TempStockkeepingUnit: Record "Stockkeeping Unit" temporary; var Result: Code[20])
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeWhseInBoundHandlingTime(LocationCode: Code[10]; var InboundWhseHandlingTime: Code[10]; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN25
    [Obsolete('Replaced by event OnBeforeGetPlannedEndingDateCalculaterForwardFromStartingDate()', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforePlannedEndingDateCalculaterForwardFromStartingDate(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; VendorNo: Code[20]; var LeadTime: Code[20]; RefOrderType: Option " ",Purchase,"Prod. Order",Transfer,Assembly; var StartingDate: Date; var Result: Date; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetPlannedEndingDateCalculaterForwardFromStartingDate(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; VendorNo: Code[20]; var LeadTime: Code[20]; RefOrderType: Enum "Requisition Ref. Order Type"; var StartingDate: Date; var Result: Date; var IsHandled: Boolean)
    begin
    end;
}

