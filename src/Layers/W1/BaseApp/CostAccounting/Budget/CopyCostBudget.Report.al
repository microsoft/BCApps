// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CostAccounting.Budget;

using Microsoft.CostAccounting.Account;
using Microsoft.CostAccounting.Setup;

report 1134 "Copy Cost Budget"
{
    Caption = 'Copy Cost Budget';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Cost Budget Entry"; "Cost Budget Entry")
        {
            DataItemTableView = sorting("Budget Name", "Cost Type No.", Date);
            RequestFilterFields = "Budget Name", "Cost Type No.", "Cost Center Code", "Cost Object Code", Date;

            trigger OnAfterGetRecord()
            var
                CostAccMgt: Codeunit "Cost Account Mgt";
            begin
                if "Entry No." > LastEntryNo then
                    CurrReport.Break();

                CostBudgetEntryTarget := "Cost Budget Entry";

                CostBudgetEntryTarget.Description := StrSubstNo(Text006, GetFilter("Budget Name"));
                CostBudgetEntryTarget."Budget Name" := CostBudgetEntryReqForm."Budget Name";

                if CostBudgetEntryReqForm."Cost Type No." <> '' then
                    CostBudgetEntryTarget."Cost Type No." := CostBudgetEntryReqForm."Cost Type No.";
                if CostBudgetEntryReqForm."Cost Center Code" <> '' then
                    CostBudgetEntryTarget."Cost Center Code" := CostBudgetEntryReqForm."Cost Center Code";
                if CostBudgetEntryReqForm."Cost Object Code" <> '' then
                    CostBudgetEntryTarget."Cost Object Code" := CostBudgetEntryReqForm."Cost Object Code";

                CostBudgetEntryTarget.Amount := Round(Amount * Factor, 0.01);
                CostBudgetEntryTarget.Allocated := false;
                OnAfterGetRecordOnAfterCostBudgetEntryTargetPopulated(CostBudgetEntryTarget, "Cost Budget Entry");

                for i := 1 to NoOfCopies do begin
                    CostBudgetEntryTarget."Entry No." := NextEntryNo;
                    NextEntryNo := NextEntryNo + 1;
                    if DateChangeFormula <> '' then
                        CostBudgetEntryTarget.Date := CalcDate(DateFormula, CostBudgetEntryTarget.Date);
                    OnAfterGetRecordOnBeforeCostBudgetEntryTargetInsert(CostBudgetEntryTarget);
                    CostBudgetEntryTarget.Insert();
                    NoInserted := NoInserted + 1;

                    if CostBudgetRegNo = 0 then
                        CostBudgetRegNo :=
                          CostAccMgt.InsertCostBudgetRegister(
                            CostBudgetEntryTarget."Entry No.", CostBudgetEntryTarget."Budget Name", CostBudgetEntryTarget.Amount)
                    else
                        CostAccMgt.UpdateCostBudgetRegister(
                          CostBudgetRegNo, CostBudgetEntryTarget."Entry No.", CostBudgetEntryTarget.Amount);

                    if (NoInserted mod 100) = 0 then
                        Window.Update(3, NoInserted);
                end;
            end;

            trigger OnPostDataItem()
            begin
                Window.Close();

                if NoInserted = 0 then begin
                    Message(Text010);
                    Error('');
                end;

                if not Confirm(Text007, true, NoInserted, CostBudgetNameTarget.Name) then
                    Error('');
            end;

            trigger OnPreDataItem()
            begin
                if Factor = 0 then
                    Error(Text000);

                if NoOfCopies < 1 then
                    Error(Text001);

                if (NoOfCopies > 1) and (DateChangeFormula = '') then
                    Error(Text002);

                if GetFilter("Budget Name") = '' then
                    Error(Text008);

                if CostBudgetEntryReqForm."Budget Name" = '' then
                    Error(Text009);

                if CostBudgetEntryReqForm."Budget Name" <> '' then
                    CostBudgetNameTarget.Get(CostBudgetEntryReqForm."Budget Name")
                else
                    CostBudgetNameTarget.Get(GetFilter("Budget Name"));

                if not Confirm(
                     Text004, false, GetFilter("Budget Name"), CostBudgetNameTarget.Name, Factor, NoOfCopies, GetFilter(Date), DateChangeFormula)
                then
                    Error('');

                LockTable();

                LastEntryNo := CostBudgetEntryTarget.GetLastEntryNo();
                NextEntryNo := LastEntryNo + 1;

                Window.Open(Text005);

                Window.Update(1, Count);
                Window.Update(2, NoOfCopies);
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
                        field("Budget Name"; CostBudgetEntryReqForm."Budget Name")
                        {
                            ApplicationArea = CostAccounting;
                            Caption = 'Budget Name';
                            Lookup = true;
                            TableRelation = "Cost Budget Name";
                            ToolTip = 'Specifies the name of the budget.';
                        }
                        field("Cost Type No."; CostBudgetEntryReqForm."Cost Type No.")
                        {
                            ApplicationArea = CostAccounting;
                            Caption = 'Cost Type No.';
                            Lookup = true;
                            TableRelation = "Cost Type";
                            ToolTip = 'Specifies the cost type number.';
                        }
                        field("Cost Center Code"; CostBudgetEntryReqForm."Cost Center Code")
                        {
                            ApplicationArea = CostAccounting;
                            Caption = 'Cost Center Code';
                            Lookup = true;
                            TableRelation = "Cost Center";
                            ToolTip = 'Specifies the cost center code that applies.';
                        }
                        field("Cost Object Code"; CostBudgetEntryReqForm."Cost Object Code")
                        {
                            ApplicationArea = CostAccounting;
                            Caption = 'Cost Object Code';
                            Lookup = true;
                            TableRelation = "Cost Object";
                            ToolTip = 'Specifies the code of the cost element.';
                        }
                    }
                    field("Amount multiplication factor"; Factor)
                    {
                        ApplicationArea = CostAccounting;
                        Caption = 'Amount multiplication factor';
                        ToolTip = 'Specifies an adjustment factor that multiplies the amounts you want to copy. By entering an adjustment factor, you can increase or decrease the amounts that are to be copied to the new budget.';
                    }
                    field("No. of Copies"; NoOfCopies)
                    {
                        ApplicationArea = CostAccounting;
                        Caption = 'No. of Copies';
                        ToolTip = 'Specifies how many times the cost budget is copied.';
                    }
                    field("Date Change Formula"; DateChangeFormula)
                    {
                        ApplicationArea = CostAccounting;
                        Caption = 'Date Change Formula';
                        DateFormula = true;
                        ToolTip = 'Specifies how the dates on the entries that are copied will be changed. Use a date formula; for example, to copy last week''s budget to this week, use the formula 1W (one week).';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            CostBudgetEntryReqForm.Init();
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        if NoOfCopies = 0 then
            NoOfCopies := 1;
        if Factor = 0 then
            Factor := 1;
    end;

    trigger OnPreReport()
    begin
        Evaluate(DateFormula, DateChangeFormula);
    end;

    var
        CostBudgetEntryReqForm: Record "Cost Budget Entry";
        CostBudgetEntryTarget: Record "Cost Budget Entry";
        CostBudgetNameTarget: Record "Cost Budget Name";
        DateFormula: DateFormula;
        Window: Dialog;
        DateChangeFormula: Code[10];
        LastEntryNo: Integer;
        NextEntryNo: Integer;
        NoOfCopies: Integer;
        Factor: Decimal;
        i: Integer;
        NoInserted: Integer;
        CostBudgetRegNo: Integer;

#pragma warning disable AA0074
        Text000: Label 'The multiplication factor must not be 0.';
        Text001: Label 'Number of copies must be at least 1.';
        Text002: Label 'If more than one copy is created, a formula for date change must be defined.';
#pragma warning disable AA0470
        Text004: Label 'Budget %1 will be copied to Budget %2. The budget amounts will be multiplied by a factor of %3. \%4 copies will be created and the date from range %5 will be incremented by %6.\\Do you want do copy the budget?', Comment = '%3=multiplication factor (decimal);%4=No of copies (integer)';
        Text005: Label 'Copying budget entries\No of entries #1#####\No of copies  #2#####\Copied        #3#####';
#pragma warning restore AA0470
        Text006: Label 'Copy of cost budget %1', Comment = '%1 - Budget Name.';
#pragma warning disable AA0470
        Text007: Label '%1 entries generated in budget %2.\\Do you want to copy entries?';
#pragma warning restore AA0470
        Text008: Label 'Define name of source budget.';
        Text009: Label 'Define name of target budget.';
        Text010: Label 'No entries were copied.';
#pragma warning restore AA0074

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordOnAfterCostBudgetEntryTargetPopulated(var CostBudgetEntryTarget: Record "Cost Budget Entry"; CostBudgetEntry: Record "Cost Budget Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordOnBeforeCostBudgetEntryTargetInsert(var CostBudgetEntryTarget: Record "Cost Budget Entry")
    begin
    end;
}

