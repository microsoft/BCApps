// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Foundation.Enums;
using Microsoft.Foundation.Period;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Setup;
using System.Utilities;

table 5804 "Avg. Cost Adjmt. Entry Point"
{
    Caption = 'Avg. Cost Adjmt. Entry Point';
    LookupPageId = "Avg. Cost Adjmt. Entry Points";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
        }
        field(2; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(3; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
        }
        field(4; "Valuation Date"; Date)
        {
            Caption = 'Valuation Date';
        }
        field(5; "Cost Is Adjusted"; Boolean)
        {
            Caption = 'Cost Is Adjusted';
        }
    }

    keys
    {
        key(Key1; "Item No.", "Variant Code", "Location Code", "Valuation Date")
        {
            Clustered = true;
        }
        key(Key2; "Item No.", "Cost Is Adjusted", "Valuation Date")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        UpdateItem();
    end;

    trigger OnInsert()
    begin
        UpdateItem();
    end;

    trigger OnModify()
    begin
        UpdateItem();
    end;

    var
        Item: Record Item;
        FiscalYearAccPeriod: Record "Accounting Period";

    local procedure UpdateItem()
    begin
        GetItem("Item No.");
        if Item."Cost is Adjusted" then begin
            Item.LockTable();
            Item."Cost is Adjusted" := false;
            Item.Modify();
        end;
    end;

    procedure ValuationExists(ValueEntry: Record "Value Entry"): Boolean
    var
        CalendarPeriod: Record Date;
    begin
        Reset();
        ReadIsolation(IsolationLevel::ReadUncommitted);
        "Item No." := ValueEntry."Item No.";
        "Valuation Date" := ValueEntry."Valuation Date";
        GetItem(ValueEntry."Item No.");
        OnValuationExistsOnAfterGetItem(Item, ValueEntry, Rec);
        if Item."Costing Method" = Item."Costing Method"::Average then begin
            CalendarPeriod."Period Start" := "Valuation Date";
            GetValuationPeriod(CalendarPeriod);
            "Valuation Date" := CalendarPeriod."Period End";
        end;
        if (Item."Costing Method" = Item."Costing Method"::Average) and
           IsAvgCostCalcTypeItem("Valuation Date")
        then begin
            "Location Code" := '';
            "Variant Code" := '';
        end else begin
            "Variant Code" := ValueEntry."Variant Code";
            "Location Code" := ValueEntry."Location Code";
        end;

        exit(Find());
    end;

    procedure PrevValuationAdjusted(ValueEntry: Record "Value Entry") ValuationAdjusted: Boolean
    var
        CopyOfAvgCostAdjmtPoint: Record "Avg. Cost Adjmt. Entry Point";
    begin
        ValuationAdjusted := true;
        if ValueEntry."Valuation Date" = 0D then
            exit(ValuationAdjusted);

        CopyOfAvgCostAdjmtPoint.Copy(Rec);
        Reset();
        SetCurrentKey("Item No.", "Cost Is Adjusted");
        SetRange("Item No.", ValueEntry."Item No.");
        SetRange("Cost Is Adjusted", false);
        SetRange("Valuation Date", 0D, CalcDate('<-1D>', ValueEntry."Valuation Date"));
        ValuationAdjusted := IsEmpty();
        Copy(CopyOfAvgCostAdjmtPoint);
        exit(ValuationAdjusted);
    end;

    procedure UpdateValuationDate(ValueEntry: Record "Value Entry")
    begin
        Rec.ReadIsolation(IsolationLevel::ReadUnCommitted);
        if ValuationExists(ValueEntry) then begin
            if not "Cost Is Adjusted" then
                exit;
            Rec.ReadIsolation(IsolationLevel::UpdLock);
            Rec.Find();
            if not "Cost Is Adjusted" then
                exit;
            "Cost Is Adjusted" := false;
            Modify();
        end else begin
            Init();
            Insert();
        end;

        UpdateNextValuations();
    end;

    local procedure UpdateNextValuations()
    var
        CopyOfAvgCostAdjmtPoint: Record "Avg. Cost Adjmt. Entry Point";
    begin
        CopyOfAvgCostAdjmtPoint.Copy(Rec);
        SetCurrentKey("Item No.", "Cost Is Adjusted");
        SetRange("Item No.", "Item No.");
        SetRange("Cost Is Adjusted", true);
        if true in [Item."Costing Method" <> Item."Costing Method"::Average,
                    not (IsAvgCostCalcTypeItem("Valuation Date") or
                         AvgCostCalcTypeIsChanged("Valuation Date"))]
        then begin
            SetRange("Location Code", "Location Code");
            SetRange("Variant Code", "Variant Code");
        end;
        SetFilter("Valuation Date", '>%1', "Valuation Date");
        ModifyAll("Cost Is Adjusted", false);
        Copy(CopyOfAvgCostAdjmtPoint);
    end;

    procedure AvgCostCalcTypeIsChanged(FromDate: Date): Boolean
    var
        NextFiscalYearAccPeriod: Record "Accounting Period";
    begin
        GetAvgCostCalcTypeIsChgPeriod(NextFiscalYearAccPeriod, FromDate);
        exit(NextFiscalYearAccPeriod."Starting Date" > FromDate);
    end;

    procedure GetAvgCostCalcTypeIsChgPeriod(var NextFiscalYearAccPeriod: Record "Accounting Period"; FromDate: Date)
    begin
        NextFiscalYearAccPeriod.SetRange("New Fiscal Year", true);
        NextFiscalYearAccPeriod.SetFilter("Starting Date", '>%1', FromDate);
        NextFiscalYearAccPeriod.SetFilter("Average Cost Calc. Type", '<>%1', FiscalYearAccPeriod."Average Cost Calc. Type");
    end;

    procedure GetValuationPeriod(var CalendarPeriod: Record Date)
    var
        PeriodMgt: Codeunit PeriodPageManagement;
    begin
        GetFiscalYearAccPeriod("Valuation Date");

        if FiscalYearAccPeriod."Average Cost Period" = FiscalYearAccPeriod."Average Cost Period"::" " then
            FiscalYearAccPeriod.FieldError("Average Cost Period");

        if CalendarPeriod."Period Start" = 0D then begin
            CalendarPeriod."Period End" := 0D;
            exit;
        end;

        if not PeriodMgt.FindDate('', CalendarPeriod, "Analysis Period Type".FromInteger(FiscalYearAccPeriod."Average Cost Period".AsInteger() - 1)) then
            FiscalYearAccPeriod.Get(CalendarPeriod."Period Start");

        if FiscalYearAccPeriod."Average Cost Period" in
           [FiscalYearAccPeriod."Average Cost Period"::Day,
            FiscalYearAccPeriod."Average Cost Period"::"Accounting Period"]
        then
            exit;

        GetFiscalYearAccPeriod(CalendarPeriod."Period End");
        if FiscalYearAccPeriod."Starting Date" in [CalendarPeriod."Period Start" .. CalendarPeriod."Period End"] then
            if "Valuation Date" < FiscalYearAccPeriod."Starting Date" then
                CalendarPeriod."Period End" := CalcDate('<-1D>', FiscalYearAccPeriod."Starting Date")
            else
                CalendarPeriod."Period Start" := FiscalYearAccPeriod."Starting Date";
    end;

    procedure IsAvgCostCalcTypeItem(ValuationDate: Date): Boolean
    begin
        GetFiscalYearAccPeriod(ValuationDate);
        exit(FiscalYearAccPeriod."Average Cost Calc. Type" = FiscalYearAccPeriod."Average Cost Calc. Type"::Item);
    end;

    local procedure GetFiscalYearAccPeriod(ValuationDate: Date)
    var
        AccountingPeriodMgt: Codeunit "Accounting Period Mgt.";
    begin
        if FiscalYearAccPeriod.IsEmpty() then begin
            AccountingPeriodMgt.InitStartYearAccountingPeriod(FiscalYearAccPeriod, ValuationDate);
            exit;
        end;

        FiscalYearAccPeriod.SetRange("New Fiscal Year", true);
        FiscalYearAccPeriod.SetRange("Starting Date", 0D, ValuationDate);
        if not FiscalYearAccPeriod.FindLast() then begin
            FiscalYearAccPeriod.SetRange("Starting Date");
            FiscalYearAccPeriod.FindFirst();
        end;
    end;

    procedure SetAvgCostAjmtFilter(var AvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point")
    var
        NextFiscalYearAccPeriod: Record "Accounting Period";
    begin
        AvgCostAdjmtEntryPoint.Reset();
        AvgCostAdjmtEntryPoint.SetRange("Item No.", "Item No.");
        AvgCostAdjmtEntryPoint.SetRange("Variant Code", "Variant Code");
        AvgCostAdjmtEntryPoint.SetRange("Location Code", "Location Code");
        if AvgCostCalcTypeIsChanged("Valuation Date") then begin
            GetAvgCostCalcTypeIsChgPeriod(NextFiscalYearAccPeriod, "Valuation Date");
            AvgCostAdjmtEntryPoint.SetRange("Valuation Date", "Valuation Date", CalcDate('<-1D>', NextFiscalYearAccPeriod."Starting Date"));
        end else
            AvgCostAdjmtEntryPoint.SetRange("Valuation Date", "Valuation Date", DMY2Date(31, 12, 9999));

        OnAfterSetAvgCostAjmtFilter(AvgCostAdjmtEntryPoint);
    end;

    local procedure GetItem(ItemNo: Code[20])
    begin
        Item.ReadIsolation(IsolationLevel::ReadUncommitted);
        if ItemNo <> Item."No." then
            Item.Get(ItemNo);
    end;

    procedure RunCostAdjustmentUntilValuationDate()
    var
        InventorySetup: Record "Inventory Setup";
        CostAdjustmentParameter: Record "Cost Adjustment Parameter";
        CostAdjustmentParamsMgt: Codeunit "Cost Adjustment Params Mgt.";
        CostAdjustmentItemRunner: Codeunit "Cost Adjustment Item Runner";
    begin
        InventorySetup.Get();
        GetItem("Item No.");
        Item.SetRecFilter();
        Item.SetRange("Date Filter", 0D, "Valuation Date");

        CostAdjustmentParameter."Post to G/L" := InventorySetup."Automatic Cost Posting";
        CostAdjustmentParamsMgt.SetParameters(CostAdjustmentParameter);
        CostAdjustmentItemRunner.SetParameters(CostAdjustmentParamsMgt);
        CostAdjustmentItemRunner.Run(Item);

        Item.Find();
        Item.UpdateCostIsAdjusted();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetAvgCostAjmtFilter(var AvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValuationExistsOnAfterGetItem(var Item: Record Item; ValueEntry: Record "Value Entry"; var AvgCostAdjmtEntryPoint: Record "Avg. Cost Adjmt. Entry Point")
    begin
    end;
}

