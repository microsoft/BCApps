// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.Period;
using System.Utilities;

/// <summary>
/// Displays G/L account balance analysis across periods with debit/credit breakdown.
/// Provides period-based balance analysis with configurable amount types and closing entry handling.
/// </summary>
page 416 "G/L Account Balance Lines"
{
    Caption = 'Lines';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = ListPart;
    SaveValues = true;
    SourceTable = "G/L Acc. Balance Buffer";
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
                    ApplicationArea = Basic, Suite;
                    Caption = 'Period Start';
                    Editable = false;
                }
                field("Period Name"; Rec."Period Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Period Name';
                    Editable = false;
                }
                field(DebitAmount; Rec."Debit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    BlankNumbers = BlankZero;
                    Caption = 'Debit Amount';
                    DrillDown = true;
                    Editable = false;

                    trigger OnDrillDown()
                    begin
                        BalanceDrillDown();
                    end;
                }
                field(CreditAmount; Rec."Credit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    BlankNumbers = BlankZero;
                    Caption = 'Credit Amount';
                    DrillDown = true;
                    Editable = false;

                    trigger OnDrillDown()
                    begin
                        BalanceDrillDown();
                    end;
                }
                field(NetChange; Rec."Net Change")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    BlankZero = true;
                    Caption = 'Net Change';
                    DrillDown = true;
                    Editable = false;
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        BalanceDrillDown();
                    end;
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
        CalcLine();
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
        PeriodType: Enum "Analysis Period Type";
        AmountType: Enum "Analysis Amount Type";

    protected var
        GLAcc: Record "G/L Account";
        ClosingEntryFilter: Option Include,Exclude;
        DebitCreditTotals: Boolean;

    /// <summary>
    /// Configures the page with G/L account data and analysis parameters for balance display across periods.
    /// </summary>
    /// <param name="NewGLAcc">G/L account record containing the accounts to analyze</param>
    /// <param name="NewPeriodType">Period type for analysis breakdown (Day, Week, Month, Quarter, Year)</param>
    /// <param name="NewAmountType">Amount type for balance calculation (Net Change, Balance at Date)</param>
    /// <param name="NewClosingEntryFilter">Whether to include or exclude closing entries in balance calculation</param>
    /// <param name="NewDebitCreditTotals">Whether to show separate debit and credit totals</param>
    procedure SetLines(var NewGLAcc: Record "G/L Account"; NewPeriodType: Enum "Analysis Period Type"; NewAmountType: Enum "Analysis Amount Type"; NewClosingEntryFilter: Option Include,Exclude; NewDebitCreditTotals: Boolean)
    begin
        GLAcc.Copy(NewGLAcc);
        Rec.DeleteAll();
        PeriodType := NewPeriodType;
        AmountType := NewAmountType;
        ClosingEntryFilter := NewClosingEntryFilter;
        DebitCreditTotals := NewDebitCreditTotals;
        OnAfterSetLinesOnBeforeUpdate();
        CurrPage.Update(false);
    end;

    local procedure BalanceDrillDown()
    var
        GLEntry: Record "G/L Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeBalanceDrillDown(GLAcc, PeriodType, AmountType, ClosingEntryFilter, DebitCreditTotals, IsHandled, DateRec);
        if IsHandled then
            exit;

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
        PAGE.Run(0, GLEntry);
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

    local procedure CalcLine()
    begin
        SetDateFilter();
        if DebitCreditTotals then
            GLAcc.CalcFields("Net Change", "Debit Amount", "Credit Amount")
        else begin
            GLAcc.CalcFields("Net Change");
            if GLAcc."Net Change" > 0 then begin
                GLAcc."Debit Amount" := GLAcc."Net Change";
                GLAcc."Credit Amount" := 0
            end else begin
                GLAcc."Debit Amount" := 0;
                GLAcc."Credit Amount" := -GLAcc."Net Change"
            end
        end;

        Rec."Debit Amount" := GLAcc."Debit Amount";
        Rec."Credit Amount" := GLAcc."Credit Amount";
        Rec."Net Change" := GLAcc."Net Change";

        OnAfterCalcLine(GLAcc, Rec, ClosingEntryFilter, DebitCreditTotals);
    end;

    /// <summary>
    /// Integration event for custom logic before balance drill-down operations.
    /// </summary>
    /// <param name="GLAccount">G/L account being analyzed</param>
    /// <param name="GLPeriodLength">Period type for analysis breakdown</param>
    /// <param name="AmountType">Amount type for balance calculation</param>
    /// <param name="ClosingEntryFilter">Closing entry filter setting</param>
    /// <param name="DebitCreditTotals">Whether debit/credit totals are shown separately</param>
    /// <param name="IsHandled">Set to true to skip standard drill-down logic</param>
    /// <param name="DateRec">Date record for period context</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeBalanceDrillDown(var GLAccount: Record "G/L Account"; GLPeriodLength: Enum "Analysis Period Type"; AmountType: Enum "Analysis Amount Type"; ClosingEntryFilter: Option Include,Exclude; DebitCreditTotals: Boolean; var IsHandled: Boolean; DateRec: Record Date)
    begin
    end;

    /// <summary>
    /// Integration event for custom calculation logic after computing line amounts.
    /// </summary>
    /// <param name="GLAccount">G/L account with calculated amounts</param>
    /// <param name="GLAccBalanceBuffer">Balance buffer record with computed values</param>
    /// <param name="ClosingEntryFilter">Closing entry filter setting</param>
    /// <param name="DebitCreditTotals">Whether debit/credit totals are shown separately</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcLine(var GLAccount: Record "G/L Account"; var GLAccBalanceBuffer: Record "G/L Acc. Balance Buffer"; ClosingEntryFilter: Option Include,Exclude; DebitCreditTotals: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event for custom logic after setting line parameters but before updating the page.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnAfterSetLinesOnBeforeUpdate()
    begin
    end;
}

