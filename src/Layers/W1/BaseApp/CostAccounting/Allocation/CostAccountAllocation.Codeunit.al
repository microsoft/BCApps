// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CostAccounting.Allocation;

using Microsoft.CostAccounting.Budget;
using Microsoft.CostAccounting.Ledger;
using Microsoft.CostAccounting.Setup;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Foundation.Period;
using Microsoft.HumanResources.Employee;
using Microsoft.Inventory.Ledger;

codeunit 1104 "Cost Account Allocation"
{

    trigger OnRun()
    begin
        ConfirmCalcAllocationKeys();
    end;

    var
        AccPeriod: Record "Accounting Period";
        DimensionManagement: Codeunit DimensionManagement;
        Window: Dialog;
        StartDate: Date;
        EndDate: Date;
        TotalShare: Decimal;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'The dynamic shares of all allocation keys will be newly calculated. \The date filter is the current work date %1.\\Do you want to start the job?';
        Text001: Label 'Update allocation keys\Allocation Targets #1########\Actual ID          #2########\Actual Line No.      #3########';
        Text002: Label '%1 allocation keys updated.';
        Text003: Label 'The next accounting period for workdate %1 is not defined.\Verify the accounting period setup.';
        Text004: Label 'Previous year is not defined in accounting period.\ID %1, line no. %2.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure ConfirmCalcAllocationKeys()
    var
        NoCalculated: Integer;
    begin
        if not Confirm(Text000, true, WorkDate()) then
            Error('');

        NoCalculated := CalcAllocationKeys();

        Message(Text002, NoCalculated);
    end;

    procedure CalcAllocationKeys() NoCalculated: Integer
    var
        CostAllocationSource: Record "Cost Allocation Source";
        CostAllocationTarget: Record "Cost Allocation Target";
    begin
        Window.Open(Text001);

        CostAllocationTarget.SetFilter(Base, '<>%1', CostAllocationTarget.Base::Static);
        Window.Update(1, Format(CostAllocationTarget.Count));
        if CostAllocationSource.FindSet() then
            repeat
                Window.Update(2, CostAllocationSource.ID);

                CostAllocationTarget.Reset();
                CostAllocationTarget.SetRange(ID, CostAllocationSource.ID);
                CostAllocationTarget.SetFilter(Base, '<>%1', CostAllocationTarget.Base::Static);
                if CostAllocationTarget.FindSet() then
                    repeat
                        Window.Update(3, Format(CostAllocationTarget."Line No."));
                        CalcLineShare(CostAllocationTarget);
                        NoCalculated := NoCalculated + 1;
                    until CostAllocationTarget.Next() = 0;
                CostAllocationTarget.Validate(Share);
            until CostAllocationSource.Next() = 0;
        Window.Close();

        exit(NoCalculated);
    end;

    procedure CalcAllocationKey(var CostAllocationSource: Record "Cost Allocation Source")
    var
        CostAllocationTarget: Record "Cost Allocation Target";
    begin
        OnBeforeCalcAllocationKey(CostAllocationSource);

        CostAllocationTarget.Reset();
        CostAllocationTarget.SetRange(ID, CostAllocationSource.ID);
        CostAllocationTarget.SetFilter(Base, '<>%1', CostAllocationTarget.Base::Static);
        if CostAllocationTarget.FindSet() then
            repeat
                CalcLineShare(CostAllocationTarget);
            until CostAllocationTarget.Next() = 0;

        CostAllocationTarget.Validate(Share);

        OnAfterCalcAllocationKey(CostAllocationSource);
    end;

    procedure CalcLineShare(var CostAllocationTarget: Record "Cost Allocation Target")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcLineShare(CostAllocationTarget, IsHandled);
        if IsHandled then
            exit;

        TotalShare := 0;
        CalcDateFilter(CostAllocationTarget);

        case CostAllocationTarget.Base of
            CostAllocationTarget.Base::"G/L Entries":
                CalcGLEntryShare(CostAllocationTarget);
            CostAllocationTarget.Base::"G/L Budget Entries":
                CalcGLBudgetEntryShare(CostAllocationTarget);
            CostAllocationTarget.Base::"Cost Type Entries":
                CalcCostEntryShare(CostAllocationTarget);
            CostAllocationTarget.Base::"Cost Budget Entries":
                CalcCostBudgetEntryShare(CostAllocationTarget);
            CostAllocationTarget.Base::"No of Employees":
                CalcEmployeeCountShare(CostAllocationTarget);
            CostAllocationTarget.Base::"Items Sold (Qty.)":
                CalcItemSoldQtyShare(CostAllocationTarget);
            CostAllocationTarget.Base::"Items Purchased (Qty.)":
                CalcItemPurchasedQtyShare(CostAllocationTarget);
            CostAllocationTarget.Base::"Items Sold (Amount)":
                CalcItemSoldAmtShare(CostAllocationTarget);
            CostAllocationTarget.Base::"Items Purchased (Amount)":
                CalcItemPurchasedAmtShare(CostAllocationTarget);
        end;

        if TotalShare <> CostAllocationTarget.Share then begin
            CostAllocationTarget.Share := Abs(Round(TotalShare, 0.00001));
            CostAllocationTarget.Modify();
        end;
    end;

    local procedure CalcGLEntryShare(CostAllocationTarget: Record "Cost Allocation Target")
    var
        GLEntry: Record "G/L Entry";
        DimFilter: Text;
    begin
        GLEntry.SetCurrentKey("Posting Date", "G/L Account No.", "Dimension Set ID");
        GLEntry.SetRange("Posting Date", StartDate, EndDate);
        GLEntry.SetFilter("G/L Account No.", CostAllocationTarget."No. Filter");
        TotalShare := 0;
        if SetCostAccDimFilters(CostAllocationTarget) then
            foreach DimFilter in DimensionManagement.GetDimSetFilters() do begin
                GLEntry.SetFilter("Dimension Set ID", DimFilter);
                GLEntry.CalcSums(Amount);
                TotalShare += GLEntry.Amount;
            end
        else begin
            GLEntry.CalcSums(Amount);
            TotalShare := GLEntry.Amount;
        end;
    end;

    local procedure CalcGLBudgetEntryShare(CostAllocationTarget: Record "Cost Allocation Target")
    var
        GLBudgetEntry: Record "G/L Budget Entry";
        DimFilter: Text;
    begin
        GLBudgetEntry.SetCurrentKey("G/L Account No.", Date, "Budget Name", "Dimension Set ID");
        GLBudgetEntry.SetFilter("G/L Account No.", CostAllocationTarget."No. Filter");
        GLBudgetEntry.SetFilter("Budget Name", CostAllocationTarget."Group Filter");
        GLBudgetEntry.SetRange(Date, StartDate, EndDate);
        TotalShare := 0;
        if SetCostAccDimFilters(CostAllocationTarget) then
            foreach DimFilter in DimensionManagement.GetDimSetFilters() do begin
                GLBudgetEntry.SetFilter("Dimension Set ID", DimFilter);
                GLBudgetEntry.CalcSums(Amount);
                TotalShare += GLBudgetEntry.Amount;
            end
        else begin
            GLBudgetEntry.CalcSums(Amount);
            TotalShare := GLBudgetEntry.Amount;
        end;
    end;

    local procedure CalcCostEntryShare(CostAllocationTarget: Record "Cost Allocation Target")
    var
        CostEntry: Record "Cost Entry";
    begin
        CostEntry.SetCurrentKey("Cost Type No.", "Posting Date", "Cost Center Code", "Cost Object Code");
        CostEntry.SetFilter("Cost Type No.", CostAllocationTarget."No. Filter");
        CostEntry.SetFilter("Cost Center Code", CostAllocationTarget."Cost Center Filter");
        CostEntry.SetFilter("Cost Object Code", CostAllocationTarget."Cost Object Filter");
        CostEntry.SetRange("Posting Date", StartDate, EndDate);
        CostEntry.CalcSums(Amount);
        TotalShare := CostEntry.Amount;
    end;

    local procedure CalcCostBudgetEntryShare(CostAllocationTarget: Record "Cost Allocation Target")
    var
        CostBudgetEntry: Record "Cost Budget Entry";
    begin
        CostBudgetEntry.SetCurrentKey("Budget Name", "Cost Type No.", "Cost Center Code", "Cost Object Code", Date);
        CostBudgetEntry.SetFilter("Cost Type No.", CostAllocationTarget."No. Filter");
        CostBudgetEntry.SetFilter("Cost Center Code", CostAllocationTarget."Cost Center Filter");
        CostBudgetEntry.SetFilter("Cost Object Code", CostAllocationTarget."Cost Object Filter");
        CostBudgetEntry.SetRange(Date, StartDate, EndDate);
        CostBudgetEntry.SetFilter("Budget Name", CostAllocationTarget."Group Filter");
        CostBudgetEntry.CalcSums(Amount);
        TotalShare := CostBudgetEntry.Amount;
    end;

    local procedure CalcEmployeeCountShare(CostAllocationTarget: Record "Cost Allocation Target")
    var
        Employee: Record Employee;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcEmployeeCountShare(CostAllocationTarget, TotalShare, StartDate, EndDate, IsHandled);
        if IsHandled then
            exit;

        Employee.SetCurrentKey(Status);
        Employee.SetRange(Status, Employee.Status::Active);
        Employee.SetFilter("Cost Center Code", CostAllocationTarget."Cost Center Filter");
        Employee.SetFilter("Cost Object Code", CostAllocationTarget."Cost Object Filter");
        TotalShare := Employee.Count();
    end;

    local procedure CalcItemSoldQtyShare(CostAllocationTarget: Record "Cost Allocation Target")
    var
        ValueEntry: Record "Value Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcItemSoldQtyShare(CostAllocationTarget, ValueEntry, IsHandled);
        if IsHandled then
            exit;

        CalcItemShare(CostAllocationTarget, ValueEntry."Item Ledger Entry Type"::Sale, ValueEntry.FieldNo("Invoiced Quantity"));
    end;

    local procedure CalcItemSoldAmtShare(CostAllocationTarget: Record "Cost Allocation Target")
    var
        ValueEntry: Record "Value Entry";
    begin
        CalcItemShare(CostAllocationTarget, ValueEntry."Item Ledger Entry Type"::Sale, ValueEntry.FieldNo("Sales Amount (Actual)"));
    end;

    local procedure CalcItemPurchasedQtyShare(CostAllocationTarget: Record "Cost Allocation Target")
    var
        ValueEntry: Record "Value Entry";
    begin
        CalcItemShare(CostAllocationTarget, ValueEntry."Item Ledger Entry Type"::Purchase, ValueEntry.FieldNo("Invoiced Quantity"));
    end;

    local procedure CalcItemPurchasedAmtShare(CostAllocationTarget: Record "Cost Allocation Target")
    var
        ValueEntry: Record "Value Entry";
    begin
        CalcItemShare(CostAllocationTarget, ValueEntry."Item Ledger Entry Type"::Purchase, ValueEntry.FieldNo("Purchase Amount (Actual)"));
    end;

    local procedure CalcItemShare(CostAllocationTarget: Record "Cost Allocation Target"; EntryType: Enum "Item Ledger Entry Type"; SumFieldNo: Integer)
    var
        ValueEntry: Record "Value Entry";
        DimFilter: Text;
    begin
        ValueEntry.SetCurrentKey("Item Ledger Entry Type", "Posting Date", "Item No.", "Inventory Posting Group", "Dimension Set ID");
        ValueEntry.SetRange("Item Ledger Entry Type", EntryType);
        ValueEntry.SetRange("Posting Date", StartDate, EndDate);
        ValueEntry.SetFilter("Item No.", CostAllocationTarget."No. Filter");
        ValueEntry.SetFilter("Inventory Posting Group", CostAllocationTarget."Group Filter");
        TotalShare := 0;
        if SetCostAccDimFilters(CostAllocationTarget) then
            foreach DimFilter in DimensionManagement.GetDimSetFilters() do begin
                ValueEntry.SetFilter("Dimension Set ID", DimFilter);
                TotalShare += SumValueEntryField(ValueEntry, SumFieldNo);
            end
        else
            TotalShare := SumValueEntryField(ValueEntry, SumFieldNo);
    end;

    local procedure SumValueEntryField(var ValueEntry: Record "Value Entry"; SumFieldNo: Integer): Decimal
    begin
        case SumFieldNo of
            ValueEntry.FieldNo("Invoiced Quantity"):
                begin
                    ValueEntry.CalcSums("Invoiced Quantity");
                    exit(ValueEntry."Invoiced Quantity");
                end;
            ValueEntry.FieldNo("Sales Amount (Actual)"):
                begin
                    ValueEntry.CalcSums("Sales Amount (Actual)");
                    exit(ValueEntry."Sales Amount (Actual)");
                end;
            ValueEntry.FieldNo("Purchase Amount (Actual)"):
                begin
                    ValueEntry.CalcSums("Purchase Amount (Actual)");
                    exit(ValueEntry."Purchase Amount (Actual)");
                end;
        end;
        OnAfterSumValueEntryField(ValueEntry, SumFieldNo);
    end;

    local procedure CalcDateFilter(CostAllocationTarget: Record "Cost Allocation Target")
    var
        PeriodStart: Date;
        NextPeriodStart: Date;
        LastPeriodStart: Date;
        LastYearPeriodStart: Date;
        LastYearNextPeriodStart: Date;
        YearStart: Date;
        NextYearStart: Date;
        LastYearStart: Date;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcDateFilter(CostAllocationTarget, StartDate, EndDate, IsHandled);
        if IsHandled then
            exit;

        AccPeriod.Reset();
        StartDate := 0D;
        EndDate := DMY2Date(31, 12, 9999);

        if AccPeriod.IsEmpty() then
            exit;

        if CostAllocationTarget."Date Filter Code" = "Cost Allocation Target Period"::" " then
            exit;

        AccPeriod.SetFilter("Starting Date", '>%1', WorkDate());
        if not AccPeriod.Find('-') then
            Error(Text003, WorkDate());

        AccPeriod.SetFilter("Starting Date", '>%1', WorkDate());
        AccPeriod.Find('-');
        NextPeriodStart := AccPeriod."Starting Date";
        AccPeriod.SetRange("Starting Date");

        AccPeriod.Next(-1);
        PeriodStart := AccPeriod."Starting Date";

        AccPeriod.Next(-1);
        LastPeriodStart := AccPeriod."Starting Date";

        AccPeriod.SetFilter("Starting Date", '>%1', CalcDate('<-1Y>', WorkDate()));
        AccPeriod.Find('-');
        LastYearNextPeriodStart := AccPeriod."Starting Date";
        AccPeriod.SetRange("Starting Date");

        if AccPeriod.Next(-1) = 0 then
            if CostAllocationTarget."Date Filter Code" in
               [CostAllocationTarget."Date Filter Code"::"Period of Last Year", CostAllocationTarget."Date Filter Code"::"Last Fiscal Year"]
            then
                Error(Text004, CostAllocationTarget.ID, CostAllocationTarget."Line No.");
        LastYearPeriodStart := AccPeriod."Starting Date";

        AccPeriod.SetRange("New Fiscal Year", true);
        AccPeriod.SetFilter("Starting Date", '>%1', WorkDate());
        AccPeriod.Find('-');
        NextYearStart := AccPeriod."Starting Date";
        AccPeriod.SetRange("Starting Date");

        AccPeriod.Next(-1);
        YearStart := AccPeriod."Starting Date";

        if AccPeriod.Next(-1) = 0 then
            if CostAllocationTarget."Date Filter Code" in
               [CostAllocationTarget."Date Filter Code"::"Period of Last Year", CostAllocationTarget."Date Filter Code"::"Last Fiscal Year"]
            then
                Error(Text004, CostAllocationTarget.ID, CostAllocationTarget."Line No.");
        LastYearStart := AccPeriod."Starting Date";

        case CostAllocationTarget."Date Filter Code" of
            CostAllocationTarget."Date Filter Code"::Week:
                begin
                    StartDate := CalcDate('<-CW>', WorkDate());
                    EndDate := CalcDate('<CW>', WorkDate());
                end;
            CostAllocationTarget."Date Filter Code"::"Last Week":
                begin
                    StartDate := CalcDate('<-CW-1W>', WorkDate());
                    EndDate := CalcDate('<CW-1W>', WorkDate());
                end;
            CostAllocationTarget."Date Filter Code"::Month:
                begin
                    StartDate := CalcDate('<-CM>', WorkDate());
                    EndDate := CalcDate('<CM>', WorkDate());
                end;
            CostAllocationTarget."Date Filter Code"::"Last Month":
                begin
                    StartDate := CalcDate('<-CM-1M>', WorkDate());
                    EndDate := CalcDate('<CM>', StartDate);
                end;
            CostAllocationTarget."Date Filter Code"::"Month of Last Year":
                begin
                    StartDate := CalcDate('<-CM-1Y>', WorkDate());
                    EndDate := CalcDate('<CM-1Y>', WorkDate());
                end;
            CostAllocationTarget."Date Filter Code"::Year:
                begin
                    StartDate := CalcDate('<-CY>', WorkDate());
                    EndDate := CalcDate('<CY>', WorkDate());
                end;
            CostAllocationTarget."Date Filter Code"::"Last Year":
                begin
                    StartDate := CalcDate('<-CY-1Y>', WorkDate());
                    EndDate := CalcDate('<CY-1Y>', WorkDate());
                end;
            CostAllocationTarget."Date Filter Code"::Period:
                begin
                    StartDate := PeriodStart;
                    EndDate := NextPeriodStart - 1;
                end;
            CostAllocationTarget."Date Filter Code"::"Last Period":
                begin
                    StartDate := LastPeriodStart;
                    EndDate := PeriodStart - 1;
                end;
            CostAllocationTarget."Date Filter Code"::"Period of Last Year":
                begin
                    StartDate := LastYearPeriodStart;
                    EndDate := LastYearNextPeriodStart - 1;
                end;
            CostAllocationTarget."Date Filter Code"::"Fiscal Year":
                begin
                    StartDate := YearStart;
                    EndDate := NextYearStart - 1;
                end;
            CostAllocationTarget."Date Filter Code"::"Last Fiscal Year":
                begin
                    StartDate := LastYearStart;
                    EndDate := YearStart - 1;
                end;
        end;
    end;

    local procedure SetCostAccDimFilters(CostAllocationTarget: Record "Cost Allocation Target") FilterSet: Boolean
    var
        CostAccSetup: Record "Cost Accounting Setup";
    begin
        CostAccSetup.Get();
        DimensionManagement.ClearDimSetFilter();
        FilterSet :=
          SetDimFilter(CostAccSetup."Cost Center Dimension", CostAllocationTarget."Cost Center Filter") or
          SetDimFilter(CostAccSetup."Cost Object Dimension", CostAllocationTarget."Cost Object Filter");
    end;

    local procedure SetDimFilter(DimCode: Code[20]; DimFilter: Text[250]): Boolean
    begin
        if DimFilter <> '' then begin
            DimensionManagement.GetDimSetIDsForFilter(DimCode, DimFilter);
            exit(true);
        end;
    end;

    procedure GetTotalShare(var ControlTotalShare: Decimal)
    begin
        ControlTotalShare := TotalShare;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcAllocationKey(var CostAllocationSource: Record "Cost Allocation Source")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcAllocationKey(var CostAllocationSource: Record "Cost Allocation Source")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcDateFilter(var CostAllocationTarget: Record "Cost Allocation Target"; var StartDate: Date; var EndDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcLineShare(var CostAllocationTarget: Record "Cost Allocation Target"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcEmployeeCountShare(CostAllocationTarget: Record "Cost Allocation Target"; var TotalShare: Decimal; StartDate: Date; EndDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcItemSoldQtyShare(var CostAllocationTarget: Record "Cost Allocation Target"; var ValueEntry: Record "Value Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSumValueEntryField(var ValueEntry: Record "Value Entry"; SumFieldNo: Integer)
    begin
    end;
}

