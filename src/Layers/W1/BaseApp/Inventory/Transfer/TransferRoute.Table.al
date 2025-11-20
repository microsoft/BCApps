// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Transfer;

using Microsoft.Foundation.Calendar;
using Microsoft.Foundation.Shipping;
using Microsoft.Inventory.Location;

table 5742 "Transfer Route"
{
    Caption = 'Transfer Route';
    DataCaptionFields = "Transfer-from Code", "Transfer-to Code";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Transfer-from Code"; Code[10])
        {
            Caption = 'Transfer-from Code';
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        field(2; "Transfer-to Code"; Code[10])
        {
            Caption = 'Transfer-to Code';
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        field(4; "In-Transit Code"; Code[10])
        {
            Caption = 'In-Transit Code';
            TableRelation = Location where("Use As In-Transit" = const(true));
        }
        field(5; "Shipping Agent Code"; Code[10])
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            Caption = 'Shipping Agent Code';
            TableRelation = "Shipping Agent";

            trigger OnValidate()
            begin
                if "Shipping Agent Code" <> xRec."Shipping Agent Code" then
                    Validate("Shipping Agent Service Code", '');
            end;
        }
        field(6; "Shipping Agent Service Code"; Code[10])
        {
            Caption = 'Shipping Agent Service Code';
            TableRelation = "Shipping Agent Services".Code where("Shipping Agent Code" = field("Shipping Agent Code"));
        }
    }

    keys
    {
        key(Key1; "Transfer-from Code", "Transfer-to Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        CalChange: Record "Customized Calendar Change";
        ShippingAgentServices: Record "Shipping Agent Services";
        CalendarMgmt: Codeunit "Calendar Management";
        HasTransferRoute: Boolean;
        HasShippingAgentService: Boolean;

#pragma warning disable AA0074
        Text003: Label 'The receipt date must be greater or equal to the shipment date.';
#pragma warning restore AA0074

    procedure GetTransferRoute(TransferFromCode: Code[10]; TransferToCode: Code[10]; var InTransitCode: Code[10]; var ShippingAgentCode: Code[10]; var ShippingAgentServiceCode: Code[10])
    var
        HasGotRecord: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetTransferRoute(Rec, TransferFromCode, TransferToCode, InTransitCode, ShippingAgentCode, ShippingAgentServiceCode, IsHandled);
        if IsHandled then
            exit;

        if ("Transfer-from Code" <> TransferFromCode) or
           ("Transfer-to Code" <> TransferToCode)
        then
            if Get(TransferFromCode, TransferToCode) then
                HasGotRecord := true;

        if HasGotRecord then begin
            InTransitCode := "In-Transit Code";
            ShippingAgentCode := "Shipping Agent Code";
            ShippingAgentServiceCode := "Shipping Agent Service Code";
        end else begin
            InTransitCode := '';
            ShippingAgentCode := '';
            ShippingAgentServiceCode := '';
        end;
    end;

    procedure CalcReceiptDate(ShipmentDate: Date; var ReceiptDate: Date; ShippingTime: DateFormula; OutboundWhseTime: DateFormula; InboundWhseTime: DateFormula; TransferFromCode: Code[10]; TransferToCode: Code[10]; ShippingAgentCode: Code[10]; ShippingAgentServiceCode: Code[10])
    var
        PlannedReceiptDate: Date;
        PlannedShipmentDate: Date;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcReceiptDate(Rec, TransferFromCode, TransferToCode, IsHandled);
        if IsHandled then
            exit;

        if ShipmentDate <> 0D then begin
            // The calculation will run through the following steps:
            // ShipmentDate -> PlannedShipmentDate -> PlannedReceiptDate -> ReceiptDate

            // Calc Planned Shipment Date forward from Shipment Date
            CalcPlanShipmentDateForward(
              ShipmentDate, PlannedShipmentDate, OutboundWhseTime,
              TransferFromCode, ShippingAgentCode, ShippingAgentServiceCode);

            // Calc Planned Receipt Date forward from Planned Shipment Date
            CalcPlannedReceiptDateForward(
              PlannedShipmentDate, PlannedReceiptDate, ShippingTime,
              TransferToCode, ShippingAgentCode, ShippingAgentServiceCode);

            // Calc Receipt Date forward from Planned Receipt Date
            CalcReceiptDateForward(PlannedReceiptDate, ReceiptDate, InboundWhseTime, TransferToCode);

            if ShipmentDate > ReceiptDate then
                Error(Text003);
        end else
            ReceiptDate := 0D;
    end;

    local procedure CalcPlanShipmentDateForward(ShipmentDate: Date; var PlannedShipmentDate: Date; OutboundWhseTime: DateFormula; TransferFromCode: Code[10]; ShippingAgentCode: Code[10]; ShippingAgentServiceCode: Code[10])
    var
        CustomCalendarChange: array[2] of Record "Customized Calendar Change";
    begin
        // Calc Planned Shipment Date forward from Shipment Date
        if ShipmentDate <> 0D then begin
            if Format(OutboundWhseTime) = '' then
                Evaluate(OutboundWhseTime, '<0D>');

            CustomCalendarChange[1].SetSource(CalChange."Source Type"::Location, TransferFromCode, '', '');
            CustomCalendarChange[2].SetSource(CalChange."Source Type"::"Shipping Agent", ShippingAgentCode, ShippingAgentServiceCode, '');
            PlannedShipmentDate := CalendarMgmt.CalcDateBOC(Format(OutboundWhseTime), ShipmentDate, CustomCalendarChange, true);
        end else
            PlannedShipmentDate := 0D;

        OnAfterCalcPlanShipmentDateForward(Rec, ShipmentDate, PlannedShipmentDate, TransferFromCode);
    end;

    procedure CalcPlannedReceiptDateForward(PlannedShipmentDate: Date; var PlannedReceiptDate: Date; ShippingTime: DateFormula; TransferToCode: Code[10]; ShippingAgentCode: Code[10]; ShippingAgentServiceCode: Code[10])
    var
        CustomCalendarChange: array[2] of Record "Customized Calendar Change";
    begin
        // Calc Planned Receipt Date forward from Planned Shipment Date

        if PlannedShipmentDate <> 0D then begin
            if Format(ShippingTime) = '' then
                Evaluate(ShippingTime, '<0D>');

            CustomCalendarChange[1].SetSource(CalChange."Source Type"::"Shipping Agent", ShippingAgentCode, ShippingAgentServiceCode, '');
            CustomCalendarChange[2].SetSource(CalChange."Source Type"::Location, TransferToCode, '', '');
            PlannedReceiptDate := CalendarMgmt.CalcDateBOC(Format(ShippingTime), PlannedShipmentDate, CustomCalendarChange, true);
        end else
            PlannedReceiptDate := 0D;

        OnAfterCalcPlannedReceiptDateForward(Rec, PlannedShipmentDate, PlannedReceiptDate, TransferToCode);
    end;

    procedure CalcReceiptDateForward(PlannedReceiptDate: Date; var ReceiptDate: Date; InboundWhseTime: DateFormula; TransferToCode: Code[10])
    var
        CustomCalendarChange: array[2] of Record "Customized Calendar Change";
    begin
        // Calc Receipt Date forward from Planned Receipt Date

        if PlannedReceiptDate <> 0D then begin
            if Format(InboundWhseTime) = '' then
                Evaluate(InboundWhseTime, '<0D>');

            CustomCalendarChange[1].SetSource(CalChange."Source Type"::Location, TransferToCode, '', '');
            ReceiptDate := CalendarMgmt.CalcDateBOC(Format(InboundWhseTime), PlannedReceiptDate, CustomCalendarChange, false);
        end else
            ReceiptDate := 0D;

        OnAfterCalcReceiptDateForward(Rec, PlannedReceiptDate, ReceiptDate, TransferToCode);
    end;

    procedure CalcShipmentDate(var ShipmentDate: Date; ReceiptDate: Date; ShippingTime: DateFormula; OutboundWhseTime: DateFormula; InboundWhseTime: DateFormula; TransferFromCode: Code[10]; TransferToCode: Code[10]; ShippingAgentCode: Code[10]; ShippingAgentServiceCode: Code[10])
    var
        PlannedReceiptDate: Date;
        PlannedShipmentDate: Date;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcShipmentDate(Rec, ReceiptDate, InboundWhseTime, TransferToCode, ShippingAgentCode, ShippingAgentServiceCode, ShippingTime, TransferFromCode, ShipmentDate, OutboundWhseTime, IsHandled);
        if IsHandled then
            exit;

        if ReceiptDate <> 0D then begin
            // The calculation will run through the following steps:
            // ShipmentDate <- PlannedShipmentDate <- PlannedReceiptDate <- ReceiptDate

            // Calc Planned Receipt Date backward from ReceiptDate
            CalcPlanReceiptDateBackward(
              PlannedReceiptDate, ReceiptDate, InboundWhseTime,
              TransferToCode, ShippingAgentCode, ShippingAgentServiceCode);

            // Calc Planned Shipment Date backward from Planned ReceiptDate
            CalcPlanShipmentDateBackward(
              PlannedShipmentDate, PlannedReceiptDate, ShippingTime,
              TransferFromCode, ShippingAgentCode, ShippingAgentServiceCode);

            // Calc Shipment Date backward from Planned Shipment Date
            CalcShipmentDateBackward(
              ShipmentDate, PlannedShipmentDate, OutboundWhseTime, TransferFromCode);
        end else
            ShipmentDate := 0D;
    end;

    procedure CalcPlanReceiptDateBackward(var PlannedReceiptDate: Date; ReceiptDate: Date; InboundWhseTime: DateFormula; TransferToCode: Code[10]; ShippingAgentCode: Code[10]; ShippingAgentServiceCode: Code[10])
    var
        CustomCalendarChange: array[2] of Record "Customized Calendar Change";
    begin
        // Calc Planned Receipt Date backward from ReceiptDate

        if ReceiptDate <> 0D then begin
            if Format(InboundWhseTime) = '' then
                Evaluate(InboundWhseTime, '<0D>');

            CustomCalendarChange[1].SetSource(CalChange."Source Type"::Location, TransferToCode, '', '');
            CustomCalendarChange[2].SetSource(CalChange."Source Type"::"Shipping Agent", ShippingAgentCode, ShippingAgentServiceCode, '');
            PlannedReceiptDate := CalendarMgmt.CalcDateBOC2(Format(InboundWhseTime), ReceiptDate, CustomCalendarChange, true);
        end else
            PlannedReceiptDate := 0D;

        OnAfterCalcPlanReceiptDateBackward(Rec, PlannedReceiptDate, ReceiptDate, TransferToCode);
    end;

    procedure CalcPlanShipmentDateBackward(var PlannedShipmentDate: Date; PlannedReceiptDate: Date; ShippingTime: DateFormula; TransferFromCode: Code[10]; ShippingAgentCode: Code[10]; ShippingAgentServiceCode: Code[10])
    var
        CustomCalendarChange: array[2] of Record "Customized Calendar Change";
    begin
        // Calc Planned Shipment Date backward from Planned ReceiptDate

        if PlannedReceiptDate <> 0D then begin
            if Format(ShippingTime) = '' then
                Evaluate(ShippingTime, '<0D>');

            CustomCalendarChange[1].SetSource(CalChange."Source Type"::"Shipping Agent", ShippingAgentCode, ShippingAgentServiceCode, '');
            CustomCalendarChange[2].SetSource(CalChange."Source Type"::Location, TransferFromCode, '', '');
            PlannedShipmentDate := CalendarMgmt.CalcDateBOC2(Format(ShippingTime), PlannedReceiptDate, CustomCalendarChange, true);
        end else
            PlannedShipmentDate := 0D;

        OnAfterCalcPlanShipmentDateBackward(Rec, PlannedShipmentDate, PlannedReceiptDate, TransferFromCode);
    end;

    procedure CalcShipmentDateBackward(var ShipmentDate: Date; PlannedShipmentDate: Date; OutboundWhseTime: DateFormula; TransferFromCode: Code[10])
    var
        CustomCalendarChange: array[2] of Record "Customized Calendar Change";
    begin
        // Calc Shipment Date backward from Planned Shipment Date

        if PlannedShipmentDate <> 0D then begin
            if Format(OutboundWhseTime) = '' then
                Evaluate(OutboundWhseTime, '<0D>');

            CustomCalendarChange[1].SetSource(CalChange."Source Type"::Location, TransferFromCode, '', '');
            ShipmentDate := CalendarMgmt.CalcDateBOC2(Format(OutboundWhseTime), PlannedShipmentDate, CustomCalendarChange, false);
        end else
            ShipmentDate := 0D;

        OnAfterCalcShipmentDateBackward(Rec, ShipmentDate, PlannedShipmentDate, TransferFromCode);
    end;

    procedure GetShippingTime(TransferFromCode: Code[10]; TransferToCode: Code[10]; ShippingAgentCode: Code[10]; ShippingAgentServiceCode: Code[10]; var ShippingTime: DateFormula)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetShippingTime(Rec, TransferFromCode, TransferToCode, ShippingAgentCode, ShippingAgentServiceCode, ShippingTime, IsHandled);
        if IsHandled then
            exit;

        if (ShippingAgentServices."Shipping Agent Code" <> ShippingAgentCode) or
           (ShippingAgentServices.Code <> ShippingAgentServiceCode)
        then begin
            if ShippingAgentServices.Get(ShippingAgentCode, ShippingAgentServiceCode) then
                HasShippingAgentService := true;
        end else
            HasShippingAgentService := true;

        if HasShippingAgentService then
            ShippingTime := ShippingAgentServices."Shipping Time"
        else begin
            if ("Transfer-from Code" <> TransferFromCode) or
               ("Transfer-to Code" <> TransferToCode)
            then begin
                if Get(TransferFromCode, TransferToCode) then
                    HasTransferRoute := true;
            end else
                HasTransferRoute := true;
            if HasTransferRoute and
               ShippingAgentServices.Get("Shipping Agent Code", "Shipping Agent Service Code")
            then
                ShippingTime := ShippingAgentServices."Shipping Time"
            else
                Evaluate(ShippingTime, '');
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcShipmentDate(var TransferRoute: Record "Transfer Route"; var ReceiptDate: Date; var InboundWhseTime: DateFormula; var TransferToCode: Code[10]; var ShippingAgentCode: Code[10]; var ShippingAgentServiceCode: Code[10]; var ShippingTime: DateFormula; var TransferFromCode: Code[10]; var ShipmentDate: Date; var OutboundWhseTime: DateFormula; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetTransferRoute(var TransferRoute: Record "Transfer Route"; TransferFromCode: Code[10]; TransferToCode: Code[10]; var InTransitCode: Code[10]; var ShippingAgentCode: Code[10]; var ShippingAgentServiceCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetShippingTime(var TransferRoute: Record "Transfer Route"; TransferFromCode: Code[10]; TransferToCode: Code[10]; ShippingAgentCode: Code[10]; ShippingAgentServiceCode: Code[10]; var ShippingTime: DateFormula; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcReceiptDate(var TransferRoute: Record "Transfer Route"; TransferFromCode: Code[10]; TransferToCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcPlanShipmentDateForward(var TransferRoute: Record "Transfer Route"; var ShipmentDate: Date; var PlannedShipmentDate: Date; TransferFromCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcPlannedReceiptDateForward(var TransferRoute: Record "Transfer Route"; var PlannedShipmentDate: Date; var PlannedReceiptDate: Date; TransferToCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcReceiptDateForward(var TransferRoute: Record "Transfer Route"; var PlannedReceiptDate: Date; var ReceiptDate: Date; TransferToCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcPlanReceiptDateBackward(var TransferRoute: Record "Transfer Route"; var PlannedReceiptDate: Date; var ReceiptDate: Date; TransferToCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcPlanShipmentDateBackward(var TransferRoute: Record "Transfer Route"; var PlannedShipmentDate: Date; var PlannedReceiptDate: Date; TransferFromCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcShipmentDateBackward(var TransferRoute: Record "Transfer Route"; var ShipmentDate: Date; var PlannedShipmentDate: Date; TransferFromCode: Code[10])
    begin
    end;
}

