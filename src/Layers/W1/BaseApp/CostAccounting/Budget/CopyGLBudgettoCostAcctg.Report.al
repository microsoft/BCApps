// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CostAccounting.Budget;

using Microsoft.CostAccounting.Account;
using Microsoft.CostAccounting.Setup;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Budget;

report 1135 "Copy G/L Budget to Cost Acctg."
{
    Caption = 'Copy G/L Budget to Cost Acctg.';
    ProcessingOnly = true;

    dataset
    {
        dataitem("G/L Budget Entry"; "G/L Budget Entry")
        {
            DataItemTableView = sorting("Budget Name", "G/L Account No.", Date);
            RequestFilterFields = "Budget Name", "G/L Account No.", Date, "Global Dimension 1 Code", "Global Dimension 2 Code", "Budget Dimension 1 Code", "Budget Dimension 2 Code", "Budget Dimension 3 Code", "Budget Dimension 4 Code";

            trigger OnAfterGetRecord()
            begin
                CostBudgetEntry.Init();
                CostBudgetEntry."Entry No." := NextEntryNo;

                CostBudgetEntry."Budget Name" := CostBudgetEntryTarget."Budget Name";

                if DateFormulaChange <> '' then
                    CostBudgetEntry.Date := CalcDate(DateFormula, Date)
                else
                    CostBudgetEntry.Date := Date;

                if CostBudgetEntryTarget."Cost Type No." <> '' then
                    CostBudgetEntry."Cost Type No." := CostBudgetEntryTarget."Cost Type No."
                else begin
                    if not GLAccount.Get("G/L Account No.") or (GLAccount."Cost Type No." = '') then begin
                        NoSkipped := NoSkipped + 1;
                        CurrReport.Skip();
                    end;
                    CostBudgetEntry."Cost Type No." := GLAccount."Cost Type No.";
                end;

                if CostBudgetEntryTarget."Cost Center Code" <> '' then
                    CostBudgetEntry."Cost Center Code" := CostBudgetEntryTarget."Cost Center Code"
                else begin
                    CostBudgetEntry."Cost Center Code" := CostAccMgt.GetCostCenterCodeFromDimSet("Dimension Set ID");
                    if not CostAccMgt.CostCenterExists(CostBudgetEntry."Cost Center Code") then
                        CostBudgetEntry."Cost Center Code" := '';
                end;

                if CostBudgetEntry."Cost Center Code" = '' then
                    if CostBudgetEntryTarget."Cost Object Code" <> '' then
                        CostBudgetEntry."Cost Object Code" := CostBudgetEntryTarget."Cost Object Code"
                    else begin
                        CostBudgetEntry."Cost Object Code" := CostAccMgt.GetCostObjectCodeFromDimSet("Dimension Set ID");
                        if not CostAccMgt.CostObjectExists(CostBudgetEntry."Cost Object Code") then
                            CostBudgetEntry."Cost Object Code" := '';
                    end;

                if (CostBudgetEntry."Cost Center Code" = '') and (CostBudgetEntry."Cost Object Code" = '') then begin
                    NoSkipped := NoSkipped + 1;
                    CurrReport.Skip();
                end;

                CostBudgetEntry.Amount := Amount;
                CostBudgetEntry.Description := Description;
                TotalAmount := TotalAmount + Amount;

                OnAfterGetRecordOnBeforeCostBudgetEntryInsert(CostBudgetEntry);
                CostBudgetEntry.Insert();
                NextEntryNo := NextEntryNo + 1;

                NoInserted := NoInserted + 1;
                if (NoInserted mod 100) = 0 then
                    Window.Update(2, NoInserted);
            end;

            trigger OnPostDataItem()
            begin
                LastGLBudgetEntryNo := "Entry No.";
                Window.Close();

                if NoInserted = 0 then begin
                    Message(Text006, NoSkipped);
                    Error('');
                end;

                if not Confirm(Text003, true, NoInserted, CostBudgetEntryTarget."Budget Name", NoSkipped) then
                    Error('');

                OnPostDataItemOnAfterConfirmCopyBudget(CostBudgetEntry, CostBudgetEntryTarget);

                LastCostBudgetEntryNo := NextEntryNo - 1;

                CostBudgetRegister.LockTable();
                if CostBudgetRegister.FindLast() then
                    LastRegisterNo := CostBudgetRegister."No.";

                CostBudgetRegister.Init();
                CostBudgetRegister."No." := LastRegisterNo + 1;
                CostBudgetRegister."Journal Batch Name" := '';
                CostBudgetRegister."Cost Budget Name" := CostBudgetEntryTarget."Budget Name";
                CostBudgetRegister.Source := CostBudgetRegister.Source::"Transfer from G/L Budget";
                CostBudgetRegister."From Budget Entry No." := FirstGLBudgetEntryNo;
                CostBudgetRegister."To Budget Entry No." := LastGLBudgetEntryNo;
                CostBudgetRegister."From Cost Budget Entry No." := FirstCostBudgetEntryNo;
                CostBudgetRegister."To Cost Budget Entry No." := LastCostBudgetEntryNo;
                CostBudgetRegister."No. of Entries" := NoInserted;
                CostBudgetRegister.Amount := TotalAmount;
                CostBudgetRegister."User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
                CostBudgetRegister."Processed Date" := Today;
                CostBudgetRegister.Insert();
            end;

            trigger OnPreDataItem()
            begin
                if GetFilter("Budget Name") = '' then
                    Error(Text004);

                if CostBudgetEntryTarget."Budget Name" = '' then
                    Error(Text005);

                if not Confirm(Text000, true, GetFilter("Budget Name"), CostBudgetEntryTarget."Budget Name") then
                    Error('');

                LockTable();

                NextEntryNo := CostBudgetEntry.GetLastEntryNo() + 1;

                Window.Open(Text002);

                Window.Update(1, Count);

                FirstCostBudgetEntryNo := NextEntryNo;
                FindFirst();
                FirstGLBudgetEntryNo := "Entry No.";
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    group("Copy to...")
                    {
                        Caption = 'Copy to...';
                        field("Budget Name"; CostBudgetEntryTarget."Budget Name")
                        {
                            ApplicationArea = CostAccounting;
                            Caption = 'Budget Name';
                            Lookup = true;
                            TableRelation = "Cost Budget Name";
                            ToolTip = 'Specifies the name of the budget.';
                        }
                        field("Cost Type No."; CostBudgetEntryTarget."Cost Type No.")
                        {
                            ApplicationArea = CostAccounting;
                            Caption = 'Cost Type No.';
                            Lookup = true;
                            TableRelation = "Cost Type";
                            ToolTip = 'Specifies the cost type number for the general ledger budget figure.';
                        }
                        field("Cost Center Code"; CostBudgetEntryTarget."Cost Center Code")
                        {
                            ApplicationArea = CostAccounting;
                            Caption = 'Cost Center Code';
                            Lookup = true;
                            TableRelation = "Cost Center";
                            ToolTip = 'Specifies the cost center code that applies.';
                        }
                        field("Cost Object Code"; CostBudgetEntryTarget."Cost Object Code")
                        {
                            ApplicationArea = CostAccounting;
                            Caption = 'Cost Object Code';
                            Lookup = true;
                            TableRelation = "Cost Object";
                            ToolTip = 'Specifies the code of the cost element.';
                        }
                    }
                    field("Date Change Formula"; DateFormulaChange)
                    {
                        ApplicationArea = CostAccounting;
                        Caption = 'Date Change Formula';
                        DateFormula = true;
                        ToolTip = 'Specifies how the dates on the entries that are copied will be changed. For example, to copy last week''s budget to this week, use the formula 1W, which is one week.';

                        trigger OnValidate()
                        begin
                            Evaluate(DateFormula, DateFormulaChange);
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            CostBudgetEntryTarget.Init();
        end;
    }

    labels
    {
    }

    protected var
        CostBudgetEntryTarget: Record "Cost Budget Entry";

    var
        CostBudgetEntry: Record "Cost Budget Entry";
        GLAccount: Record "G/L Account";
        CostBudgetRegister: Record "Cost Budget Register";
        CostAccMgt: Codeunit "Cost Account Mgt";
        DateFormula: DateFormula;
        Window: Dialog;
        DateFormulaChange: Code[10];
        NextEntryNo: Integer;
        NoInserted: Integer;
        NoSkipped: Integer;
        FirstGLBudgetEntryNo: Integer;
        LastGLBudgetEntryNo: Integer;
        FirstCostBudgetEntryNo: Integer;
        LastCostBudgetEntryNo: Integer;
        TotalAmount: Decimal;
        LastRegisterNo: Integer;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Do you want to copy the general ledger budget "%1" to cost budget "%2"?';
        Text002: Label 'Copying budget entries\No of entries #1#####\Copied        #2#####';
        Text003: Label '%1 entries generated in budget %2.\\%3 entries were skipped because there were either no corresponding G/L accounts defined or cost center and cost object were missing.\\Copy budget?', Comment = '%2=budget name;%3=integer value';
#pragma warning restore AA0470
        Text004: Label 'Define name of source budget.';
        Text005: Label 'Define name of target budget.';
#pragma warning disable AA0470
        Text006: Label 'No entries were copied. %1 entries were skipped because no corresponding general ledger accounts were defined or because cost center and cost object were missing.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordOnBeforeCostBudgetEntryInsert(var CostBudgetEntry: Record "Cost Budget Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnPostDataItemOnAfterConfirmCopyBudget(var CostBudgetEntry: Record "Cost Budget Entry"; CostBudgetEntryTarget: Record "Cost Budget Entry")
    begin
    end;
}

