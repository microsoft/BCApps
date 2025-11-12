// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CostAccounting.Budget;

using Microsoft.CostAccounting.Account;
using Microsoft.CostAccounting.Setup;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.Finance.GeneralLedger.Setup;

report 1136 "Copy Cost Acctg. Budget to G/L"
{
    Caption = 'Copy Cost Acctg. Budget to G/L';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Cost Budget Entry"; "Cost Budget Entry")
        {
            DataItemTableView = sorting("Budget Name", "Cost Type No.", Date);
            RequestFilterFields = "Budget Name", "Cost Type No.", "Cost Center Code", "Cost Object Code", Date;

            trigger OnAfterGetRecord()
            var
                TempDimSetEntry: Record "Dimension Set Entry" temporary;
            begin
                GLBudgetEntryTarget.Init();
                GLBudgetEntryTarget."Budget Name" := GLBudgetNameTarget.Name;

                // Get corresponding G/L account
                if not CostType.Get("Cost Type No.") then begin
                    NoSkipped := NoSkipped + 1;
                    CurrReport.Skip();
                end;

                GLAcc.SetFilter("No.", '%1', CostType."G/L Account Range");
                OnCostBudgetEntryOnAfterGetRecordOnAfterGLAccSetfilter(CostType, GLAcc);
                if not GLAcc.FindFirst() then begin
                    NoSkipped := NoSkipped + 1;
                    CurrReport.Skip();
                end;
                GLBudgetEntryTarget."G/L Account No." := GLAcc."No.";
                GLBudgetEntryTarget.Date := Date;

                CostAccSetup.Get();
                if CostAccMgt.CostCenterExistsAsDimValue("Cost Center Code") then
                    GLBudgetEntryTarget.UpdateDimSet(TempDimSetEntry, CostAccSetup."Cost Center Dimension", "Cost Center Code");
                if CostAccMgt.CostObjectExistsAsDimValue("Cost Object Code") then
                    GLBudgetEntryTarget.UpdateDimSet(TempDimSetEntry, CostAccSetup."Cost Object Dimension", "Cost Object Code");
                GLBudgetEntryTarget."Dimension Set ID" := DimMgt.GetDimensionSetID(TempDimSetEntry);
                UpdateBudgetDimensions(GLBudgetEntryTarget);
                OnAfterUpdateBudgetDimensions(GLBudgetEntryTarget);

                GLBudgetEntryTarget.Description :=
                  CopyStr(StrSubstNo(Text006, GetFilter("Budget Name")), 1, MaxStrLen(GLBudgetEntryTarget.Description));
                GLBudgetEntryTarget."User ID" := CopyStr(UserId(), 1, MaxStrLen(GLBudgetEntryTarget."User ID"));

                // Amt * req. window factor
                GLBudgetEntryTarget.Amount := Round(Amount * Factor, 0.01);
                OnAfterGetRecordOnAfterGLBudgetEntryTargetPopulated(GLBudgetEntryTarget, "Cost Budget Entry");

                // Create entries according to "copies". Increment date.
                for i := 1 to NoOfCopies do begin
                    LastEntryNo := LastEntryNo + 1;
                    GLBudgetEntryTarget."Entry No." := LastEntryNo;

                    // Prepare date for next entry
                    if DateChange <> '' then
                        GLBudgetEntryTarget.Date := CalcDate(DateFormula, GLBudgetEntryTarget.Date);

                    GLBudgetEntryTarget.Insert();

                    NoInserted := NoInserted + 1;
                    if (NoInserted mod 100) = 0 then
                        Window.Update(3, NoInserted);
                end;
            end;

            trigger OnPostDataItem()
            begin
                Window.Close();

                if NoInserted = 0 then begin
                    Message(Text010, NoSkipped);
                    Error('');
                end;

                if not Confirm(Text007, true, NoInserted, GLBudgetNameTarget.Name, NoSkipped) then
                    Error('');
            end;

            trigger OnPreDataItem()
            begin
                if Factor <= 0 then
                    Error(Text000);

                if NoOfCopies < 1 then
                    Error(Text001);

                if (NoOfCopies > 1) and (DateChange = '') then
                    Error(Text002);

                if GetFilter("Budget Name") = '' then
                    Error(Text008);

                if GLBudgetNameTarget.Name = '' then
                    Error(Text009);

                if not Confirm(Text004, false, GetFilter("Budget Name"), GLBudgetNameTarget.Name, Factor, NoOfCopies, GetFilter(Date), DateChange) then
                    Error('');

                LockTable();

                LastEntryNo := GLBudgetEntryTarget.GetLastEntryNo();

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
                    field("Allocation Target Budget Name"; GLBudgetNameTarget.Name)
                    {
                        ApplicationArea = CostAccounting;
                        Caption = 'Allocation Target Budget Name';
                        Lookup = true;
                        TableRelation = "G/L Budget Name";
                        ToolTip = 'Specifies a general ledger budget name.';
                    }
                    field("Amount multiplication factor"; Factor)
                    {
                        ApplicationArea = CostAccounting;
                        Caption = 'Amount multiplication factor';
                        ToolTip = 'Specifies the amount multiplication factor. Enter a 1.00 if you want to copy the values 1:1. The value 1.05 increases the budget figures by 5 percent.';
                    }
                    field("No. of Copies"; NoOfCopies)
                    {
                        ApplicationArea = CostAccounting;
                        Caption = 'No. of Copies';
                        ToolTip = 'Specifies how many times the cost accounting budget is copied.';
                    }
                    field("Date Change Formula"; DateChange)
                    {
                        ApplicationArea = CostAccounting;
                        Caption = 'Date Change Formula';
                        DateFormula = true;
                        ToolTip = 'Specifies how the dates on the entries that are copied will be changed. For example, to copy last week''s budget to this week, use the formula 1W, which is one week.';

                        trigger OnValidate()
                        begin
                            Evaluate(DateFormula, DateChange);
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            GLBudgetNameTarget.Init();
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

    protected var
        GLBudgetNameTarget: Record "G/L Budget Name";

    var
        GLBudgetEntryTarget: Record "G/L Budget Entry";
        CostType: Record "Cost Type";
        GLAcc: Record "G/L Account";
        CostAccSetup: Record "Cost Accounting Setup";
        CostAccMgt: Codeunit "Cost Account Mgt";
        DimMgt: Codeunit DimensionManagement;
        DateFormula: DateFormula;
        Window: Dialog;
        DateChange: Code[10];
        LastEntryNo: Integer;
        NoOfCopies: Integer;
        Factor: Decimal;
        i: Integer;
        NoSkipped: Integer;
        NoInserted: Integer;

#pragma warning disable AA0074
        Text000: Label 'The multiplication factor must not be 0 or less than 0.';
        Text001: Label 'Number of copies must be at least 1.';
        Text002: Label 'If more than one copy is created, a formula for date change must be defined.';
#pragma warning disable AA0470
        Text004: Label 'Cost budget "%1" will be copied to G/L budget "%2". The budget amounts will be multiplied by factor %3. \%4 copies will be created and the posting will be increased from the range of "%5" to "%6".\\Do you want do copy the budget?', Comment = '%3=multiplication factor (decimal);%4=No of copies (integer)';
        Text005: Label 'Copying budget entries\No of entries #1#####\No of copies  #2#####\Copied        #3#####';
#pragma warning restore AA0470
        Text006: Label 'Copy of cost budget %1', Comment = '%1 - Budget Name.';
#pragma warning disable AA0470
        Text007: Label '%1 entries generated in budget %2.\\%3 entries were skipped because there were no corresponding G/L accounts defined.\\Copy entries?', Comment = '%2=budget name;%3=integer value';
#pragma warning restore AA0470
        Text008: Label 'Define name of source budget.';
        Text009: Label 'Define name of target budget.';
#pragma warning disable AA0470
        Text010: Label 'No entries were copied. %1 entries were skipped because no corresponding general ledger accounts were defined.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure UpdateBudgetDimensions(var GLBudgetEntry: Record "G/L Budget Entry")
    var
        GLSetup: Record "General Ledger Setup";
        GLBudgetName: Record "G/L Budget Name";
        DimSetEntry: Record "Dimension Set Entry";
    begin
        GLSetup.Get();
        GLBudgetName.Get(GLBudgetEntry."Budget Name");

        GLBudgetEntry."Global Dimension 1 Code" := '';
        GLBudgetEntry."Global Dimension 2 Code" := '';
        GLBudgetEntry."Budget Dimension 1 Code" := '';
        GLBudgetEntry."Budget Dimension 2 Code" := '';
        GLBudgetEntry."Budget Dimension 3 Code" := '';
        GLBudgetEntry."Budget Dimension 4 Code" := '';

        if DimSetEntry.Get(GLBudgetEntry."Dimension Set ID", GLSetup."Global Dimension 1 Code") then
            GLBudgetEntry."Global Dimension 1 Code" := DimSetEntry."Dimension Value Code";
        if DimSetEntry.Get(GLBudgetEntry."Dimension Set ID", GLSetup."Global Dimension 2 Code") then
            GLBudgetEntry."Global Dimension 2 Code" := DimSetEntry."Dimension Value Code";
        if DimSetEntry.Get(GLBudgetEntry."Dimension Set ID", GLBudgetName."Budget Dimension 1 Code") then
            GLBudgetEntry."Budget Dimension 1 Code" := DimSetEntry."Dimension Value Code";
        if DimSetEntry.Get(GLBudgetEntry."Dimension Set ID", GLBudgetName."Budget Dimension 2 Code") then
            GLBudgetEntry."Budget Dimension 2 Code" := DimSetEntry."Dimension Value Code";
        if DimSetEntry.Get(GLBudgetEntry."Dimension Set ID", GLBudgetName."Budget Dimension 3 Code") then
            GLBudgetEntry."Budget Dimension 3 Code" := DimSetEntry."Dimension Value Code";
        if DimSetEntry.Get(GLBudgetEntry."Dimension Set ID", GLBudgetName."Budget Dimension 4 Code") then
            GLBudgetEntry."Budget Dimension 4 Code" := DimSetEntry."Dimension Value Code";
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateBudgetDimensions(var GLBudgetEntryTarget: Record "G/L Budget Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRecordOnAfterGLBudgetEntryTargetPopulated(var GLBudgetEntryTarget: Record "G/L Budget Entry"; CostBudgetEntry: Record "Cost Budget Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCostBudgetEntryOnAfterGetRecordOnAfterGLAccSetfilter(var CostType: Record "Cost Type"; var GLAccount: Record "G/L Account")
    begin
    end;
}

