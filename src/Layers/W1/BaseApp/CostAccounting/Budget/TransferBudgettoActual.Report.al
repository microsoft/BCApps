// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CostAccounting.Budget;

using Microsoft.CostAccounting.Journal;
using Microsoft.CostAccounting.Posting;
using Microsoft.Foundation.AuditCodes;

report 1137 "Transfer Budget to Actual"
{
    ApplicationArea = CostAccounting;
    Caption = 'Transfer Budget to Actual';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Cost Budget Entry"; "Cost Budget Entry")
        {
            DataItemTableView = sorting("Budget Name", "Cost Type No.", Date);
            RequestFilterFields = "Budget Name", Date, Allocated, "Cost Type No.", "Cost Center Code", "Cost Object Code";

            trigger OnAfterGetRecord()
            var
                SourceCodeSetup: Record "Source Code Setup";
            begin
                SourceCodeSetup.Get();
                SourceCodeSetup.TestField("Transfer Budget to Actual");
                TempCostJnlLine.Init();
                LastEntryNo := LastEntryNo + 1;
                TempCostJnlLine."Line No." := LastEntryNo;
                TempCostJnlLine."Cost Type No." := "Cost Type No.";
                TempCostJnlLine."Posting Date" := Date;
                TempCostJnlLine."Document No." := "Document No.";
                if TempCostJnlLine."Document No." = '' then
                    TempCostJnlLine."Document No." := 'BUDGET';
                TempCostJnlLine.Description := Description;
                TempCostJnlLine.Amount := Amount;
                TempCostJnlLine."Cost Center Code" := "Cost Center Code";
                TempCostJnlLine."Cost Object Code" := "Cost Object Code";
                TempCostJnlLine."Source Code" := SourceCodeSetup."Transfer Budget to Actual";
                TempCostJnlLine."Allocation Description" := "Allocation Description";
                TempCostJnlLine."Allocation ID" := "Allocation ID";
                TempCostJnlLine.Insert();

                NoInserted := NoInserted + 1;
                if (NoInserted mod 100) = 0 then
                    Window.Update(2, NoInserted);
            end;

            trigger OnPostDataItem()
            begin
                Window.Close();

                if not Confirm(Text004, true, NoInserted) then
                    Error('');

                PostCostJournalLines();
            end;

            trigger OnPreDataItem()
            begin
                if GetFilter("Budget Name") = '' then
                    Error(Text000);

                if GetFilter(Date) = '' then
                    Error(Text001);

                if not Confirm(Text002, true, GetFilter("Budget Name"), GetFilter(Date)) then
                    Error('');

                LockTable();

                Window.Open(Text003);

                Window.Update(1, Count);
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        TempCostJnlLine: Record "Cost Journal Line" temporary;
        Window: Dialog;
        LastEntryNo: Integer;
        NoInserted: Integer;
#pragma warning disable AA0074
        Text000: Label 'Define the name of the source budget.';
        Text001: Label 'Date range must be defined.';
#pragma warning disable AA0470
        Text002: Label 'The cost budget "%1" for the date range of "%2" will be transferred to the actual cost entries. \Do you want to start the job?';
        Text003: Label 'Copying budget entries\No of entries #1#####\Copied        #2#####';
        Text004: Label '%1 budget entries were transferred to actual cost entries.\\Do you want to copy entries?';
#pragma warning restore AA0470
        Text005: Label 'Posting Cost Entries @1@@@@@@@@@@\';
#pragma warning restore AA0074

    local procedure PostCostJournalLines()
    var
        CostJnlLine: Record "Cost Journal Line";
        CAJnlPostLine: Codeunit "CA Jnl.-Post Line";
        Window2: Dialog;
        JournalLineCount: Integer;
        CostJnlLineStep: Integer;
    begin
        TempCostJnlLine.Reset();
        Window2.Open(
          Text005);
        if TempCostJnlLine.Count > 0 then
            JournalLineCount := 10000 * 100000 div TempCostJnlLine.Count();
        if TempCostJnlLine.FindSet() then
            repeat
                CostJnlLineStep := CostJnlLineStep + JournalLineCount;
                Window2.Update(1, CostJnlLineStep div 100000);
                CostJnlLine := TempCostJnlLine;
                CAJnlPostLine.RunWithCheck(CostJnlLine);
            until TempCostJnlLine.Next() = 0;
        Window2.Close();
    end;
}

