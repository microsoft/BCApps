// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.Period;
using System.Utilities;

page 350 "G/L Acc. Balance/Budget Lines"
{
    Caption = 'Lines';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = ListPart;
    SaveValues = true;
    SourceTable = "G/L Acc. Balance/Budget Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Period Start"; Rec."Period Start")
                {
                    ApplicationArea = Suite;
                    Caption = 'Period Start';
                    Editable = false;
                    ToolTip = 'Specifies the starting date of the period that you want to view.';
                }
                field("Period Name"; Rec."Period Name")
                {
                    ApplicationArea = Suite;
                    Caption = 'Period Name';
                    Editable = false;
                    ToolTip = 'Specifies the name of the period that you want to view.';
                }
                field(DebitAmount; Rec."Debit Amount")
                {
                    ApplicationArea = Suite;
                    AutoFormatType = 1;
                    BlankNumbers = BlankNegAndZero;
                    Caption = 'Actual Debit Amount';
                    DrillDown = true;
                    Editable = false;
                    ToolTip = 'Specifies the total of the debit entries that have been posted to the account.';

                    trigger OnDrillDown()
                    begin
                        BalanceDrillDown();
                    end;
                }
                field(CreditAmount; Rec."Credit Amount")
                {
                    ApplicationArea = Suite;
                    AutoFormatType = 1;
                    BlankNumbers = BlankNegAndZero;
                    Caption = 'Actual Credit Amount';
                    DrillDown = true;
                    Editable = false;
                    ToolTip = 'Specifies the total of the credit entries that have been posted to the account.';

                    trigger OnDrillDown()
                    begin
                        BalanceDrillDown();
                    end;
                }
                field(NetChange; Rec."Net Change")
                {
                    ApplicationArea = Suite;
                    AutoFormatType = 1;
                    BlankZero = true;
                    Caption = 'Net Change';
                    DrillDown = true;
                    Editable = false;
                    ToolTip = 'Specifies the net change in the account balance during the time period in the Date Filter field.';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        BalanceDrillDown();
                    end;
                }
                field(BudgetedDebitAmount; Rec."Budgeted Debit Amount")
                {
                    ApplicationArea = Suite;
                    AutoFormatType = 1;
                    BlankNumbers = BlankNegAndZero;
                    Caption = 'Budgeted Debit Amount';
                    DrillDown = true;
                    ToolTip = 'Specifies the total of the budget debit entries that have been posted to the account.';

                    trigger OnDrillDown()
                    begin
                        BudgetDrillDown();
                    end;

                    trigger OnValidate()
                    begin
                        SetDateFilter();
                        GLAcc.Validate("Budgeted Debit Amount");
                        CalcFormFields();
                    end;
                }
                field(BudgetedCreditAmount; Rec."Budgeted Credit Amount")
                {
                    ApplicationArea = Suite;
                    AutoFormatType = 1;
                    BlankNumbers = BlankNegAndZero;
                    Caption = 'Budgeted Credit Amount';
                    DrillDown = true;
                    ToolTip = 'Specifies the total of the budget credit entries that have been posted to the account.';

                    trigger OnDrillDown()
                    begin
                        BudgetDrillDown();
                    end;

                    trigger OnValidate()
                    begin
                        SetDateFilter();
                        GLAcc.Validate("Budgeted Credit Amount");
                        CalcFormFields();
                    end;
                }
                field(BudgetedAmount; Rec."Budgeted Amount")
                {
                    ApplicationArea = Suite;
                    AutoFormatType = 1;
                    BlankZero = true;
                    Caption = 'Budgeted Amount';
                    DrillDown = true;
                    ToolTip = 'Specifies the total of the budget entries that have been posted to the account.';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        BudgetDrillDown();
                    end;

                    trigger OnValidate()
                    begin
                        SetDateFilter();
                        GLAcc.Validate("Budgeted Amount");
                        CalcFormFields();
                    end;
                }
                field(BudgetPct; Rec."Balance/Budget Pct.")
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    Caption = 'Balance/Budget (%)';
                    DecimalPlaces = 1 : 1;
                    Editable = false;
                    ToolTip = 'Specifies a summary of the debit and credit balances and the budgeted amounts for different time periods for the account that you select in the chart of accounts.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        if DateRec.Get(Rec."Period Type", Rec."Period Start") then;
        SetDateFilter();
        CalcFormFields();
    end;

    trigger OnFindRecord(Which: Text) FoundDate: Boolean
    var
        VariantRec: Variant;
    begin
        VariantRec := Rec;
        FoundDate := PeriodFormLinesMgt.FindDate(VariantRec, DateRec, Which, PeriodType.AsInteger());
        Rec := VariantRec;
    end;

    trigger OnNextRecord(Steps: Integer) ResultSteps: Integer
    var
        VariantRec: Variant;
    begin
        VariantRec := Rec;
        ResultSteps := PeriodFormLinesMgt.NextDate(VariantRec, DateRec, Steps, PeriodType.AsInteger());
        Rec := VariantRec;
    end;

    trigger OnOpenPage()
    begin
        Rec.Reset();
    end;

    var
        AccountingPeriod: Record "Accounting Period";
        DateRec: Record Date;
        PeriodFormLinesMgt: Codeunit "Period Form Lines Mgt.";

    protected var
        GLAcc: Record "G/L Account";
        ClosingEntryFilter: Option Include,Exclude;
        PeriodType: Enum "Analysis Period Type";
        AmountType: Enum "Analysis Amount Type";

    procedure SetLines(var NewGLAcc: Record "G/L Account"; NewPeriodType: Enum "Analysis Period Type"; NewAmountType: Enum "Analysis Amount Type"; NewClosingEntryFilter: Option Include,Exclude)
    begin
        GLAcc.Copy(NewGLAcc);
        Rec.DeleteAll();

        if GLAcc.GetFilter("Date Filter") <> '' then begin
            Rec.FilterGroup(2);
            Rec.SetFilter("Period Start", GLAcc.GetFilter("Date Filter"));
            Rec.FilterGroup(0);
            DateRec.FilterGroup(2);
            DateRec.SetFilter("Period Start", GLAcc.GetFilter("Date Filter"));
            DateRec.FilterGroup(0);
        end;

        PeriodType := NewPeriodType;
        AmountType := NewAmountType;
        ClosingEntryFilter := NewClosingEntryFilter;
        CurrPage.Update(false);
    end;

    local procedure BalanceDrillDown()
    var
        GLEntry: Record "G/L Entry";
    begin
        SetDateFilter();
        GLEntry.Reset();
        GLEntry.SetCurrentKey("G/L Account No.", "Posting Date");
        GLEntry.SetRange("G/L Account No.", GLAcc."No.");
        if GLAcc.Totaling <> '' then
            GLEntry.SetFilter("G/L Account No.", GLAcc.Totaling);
        GLEntry.SetFilter("Posting Date", GLAcc.GetFilter("Date Filter"));
        GLEntry.SetFilter("Global Dimension 1 Code", GLAcc.GetFilter("Global Dimension 1 Filter"));
        GLEntry.SetFilter("Global Dimension 2 Code", GLAcc.GetFilter("Global Dimension 2 Filter"));
        GLEntry.SetFilter("Business Unit Code", GLAcc.GetFilter("Business Unit Filter"));
        OnBalanceDrillDownOnAfterSetFilters(GLEntry, GLAcc);
        PAGE.Run(0, GLEntry);
    end;

    local procedure BudgetDrillDown()
    var
        GLBudgetEntry: Record "G/L Budget Entry";
    begin
        SetDateFilter();
        GLBudgetEntry.Reset();
        GLBudgetEntry.SetCurrentKey("Budget Name", "G/L Account No.", Date);
        GLBudgetEntry.SetFilter("Budget Name", GLAcc.GetFilter("Budget Filter"));
        GLBudgetEntry.SetRange("G/L Account No.", GLAcc."No.");
        if GLAcc.Totaling <> '' then
            GLBudgetEntry.SetFilter("G/L Account No.", GLAcc.Totaling);
        GLBudgetEntry.SetFilter(Date, GLAcc.GetFilter("Date Filter"));
        GLBudgetEntry.SetFilter("Global Dimension 1 Code", GLAcc.GetFilter("Global Dimension 1 Filter"));
        GLBudgetEntry.SetFilter("Global Dimension 2 Code", GLAcc.GetFilter("Global Dimension 2 Filter"));
        GLBudgetEntry.SetFilter("Business Unit Code", GLAcc.GetFilter("Business Unit Filter"));
        OnBudgetDrillDownOnAfterSetFilters(GLBudgetEntry, GLAcc);
        PAGE.Run(0, GLBudgetEntry);
    end;

    local procedure SetDateFilter()
    begin
        if AmountType = AmountType::"Net Change" then
            GLAcc.SetRange("Date Filter", Rec."Period Start", Rec."Period End")
        else
            GLAcc.SetRange("Date Filter", 0D, Rec."Period End");
        if ClosingEntryFilter = ClosingEntryFilter::Exclude then begin
            AccountingPeriod.SetCurrentKey("New Fiscal Year");
            AccountingPeriod.SetRange("New Fiscal Year", true);
            if GLAcc.GetRangeMin("Date Filter") = 0D then
                AccountingPeriod.SetRange("Starting Date", 0D, GLAcc.GetRangeMax("Date Filter"))
            else
                AccountingPeriod.SetRange(
                  "Starting Date",
                  GLAcc.GetRangeMin("Date Filter") + 1,
                  GLAcc.GetRangeMax("Date Filter"));
            if AccountingPeriod.Find('-') then
                repeat
                    GLAcc.SetFilter(
                      "Date Filter", GLAcc.GetFilter("Date Filter") + '&<>%1',
                      ClosingDate(AccountingPeriod."Starting Date" - 1));
                until AccountingPeriod.Next() = 0;
        end else
            GLAcc.SetRange(
              "Date Filter",
              GLAcc.GetRangeMin("Date Filter"),
              ClosingDate(GLAcc.GetRangeMax("Date Filter")));
    end;

    local procedure CalcFormFields()
    begin
        GLAcc.CalcFields("Net Change", "Debit Amount", "Credit Amount", "Budgeted Amount");
        Rec."Debit Amount" := GLAcc."Debit Amount";
        Rec."Credit Amount" := GLAcc."Credit Amount";
        Rec."Net Change" := GLAcc."Net Change";
        Rec."Budgeted Debit Amount" := GLAcc."Budgeted Amount";
        Rec."Budgeted Credit Amount" := -GLAcc."Budgeted Amount";
        Rec."Budgeted Amount" := GLAcc."Budgeted Amount";
        if GLAcc."Budgeted Amount" = 0 then
            Rec."Balance/Budget Pct." := 0
        else
            Rec."Balance/Budget Pct." := Round(GLAcc."Net Change" / GLAcc."Budgeted Amount" * 100);

        OnAfterCalcFormFields(GLAcc, Rec."Balance/Budget Pct.", Rec, ClosingEntryFilter);
    end;

    procedure GetGLAcc(var NewGLAcc: Record "G/L Account")
    begin
        NewGLAcc.Copy(GLAcc);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcFormFields(var GLAccount: Record "G/L Account"; var BudgetPct: Decimal; var GLAccBalanceBudgetBuffer: Record "G/L Acc. Balance/Budget Buffer"; ClosingEntryFilter: Option Include,Exclude)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBalanceDrillDownOnAfterSetFilters(var GLEntry: Record "G/L Entry"; GLAccount: Record "G/L Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBudgetDrillDownOnAfterSetFilters(var GLBudgetEntry: Record "G/L Budget Entry"; GLAccount: Record "G/L Account")
    begin
    end;
}

