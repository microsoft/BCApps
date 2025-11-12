// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CostAccounting.Budget;

using Microsoft.CostAccounting.Setup;
using Microsoft.Finance.GeneralLedger.Budget;

report 1139 "Delete Cost Budget Entries"
{
    Caption = 'Delete Cost Budget Entries';
    Permissions = TableData "G/L Budget Entry" = rm;
    ProcessingOnly = true;

    dataset
    {
        dataitem("Cost Budget Register"; "Cost Budget Register")
        {
            DataItemTableView = sorting("No.") order(descending);

            trigger OnAfterGetRecord()
            begin
                Window.Update(1, "No.");

                if Closed then
                    Error(Text007, "No.");

                if Source = Source::Allocation then begin
                    CostBudgetEntry.SetRange("Allocated with Journal No.", "No.");
                    CostBudgetEntry.ModifyAll(Allocated, false);
                    CostBudgetEntry.ModifyAll("Allocated with Journal No.", 0);
                    CostBudgetEntry.SetRange("Allocated with Journal No.");
                end;

                CostBudgetEntry.SetRange("Entry No.", "From Cost Budget Entry No.", "To Cost Budget Entry No.");
                CostBudgetEntry.DeleteAll();
                CostBudgetEntry.Reset();
            end;

            trigger OnPostDataItem()
            var
                CostAccSetup: Record "Cost Accounting Setup";
            begin
                DeleteAll();
                Reset();
                SetRange(Source, Source::Allocation);

                if FindLast() then begin
                    CostBudgetEntry.Get("To Cost Budget Entry No.");
                    CostAccSetup.Get();
                    CostAccSetup."Last Allocation Doc. No." := CostBudgetEntry."Document No.";
                    CostAccSetup.Modify();
                end;
            end;

            trigger OnPreDataItem()
            begin
                // Sort descending. Registers are deleted backwards
                SetRange("No.", CostBudgetRegister2."No.", CostBudgetRegister3."No.");
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(FromRegisterNo; CostBudgetRegister2."No.")
                    {
                        ApplicationArea = CostAccounting;
                        Caption = 'From Register No.';
                        Lookup = true;
                        TableRelation = "Cost Budget Register" where(Closed = const(false));
                        ToolTip = 'Specifies the starting posted register number to determine the starting point for the deletion of register numbers.';
                    }
                    field(ToRegisterNo; CostBudgetRegister3."No.")
                    {
                        ApplicationArea = CostAccounting;
                        Caption = 'To Register No.';
                        Editable = false;
                        TableRelation = "Cost Budget Register" where(Closed = const(false));
                        ToolTip = 'Specifies that the last posted register number is filled in automatically. You cannot change the contents of this field.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            CostBudgetRegister2.FindLast();
            CostBudgetRegister3.FindLast();
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        if CostBudgetRegister2."No." > CostBudgetRegister3."No." then
            Error(Text000);

        if not Confirm(Text001, false, CostBudgetRegister2."No.", CostBudgetRegister3."No.") then
            Error('');

        if not Confirm(Text004) then
            Error('');

        Window.Open(Text005 +
          Text006);
    end;

    var
        CostBudgetRegister2: Record "Cost Budget Register";
        CostBudgetRegister3: Record "Cost Budget Register";
        CostBudgetEntry: Record "Cost Budget Entry";
        Window: Dialog;

#pragma warning disable AA0074
        Text000: Label 'From Register No. must not be higher than To Register No..';
#pragma warning disable AA0470
        Text001: Label 'All corresponding cost budget entries and budget register entries will be deleted. Do you want to delete cost budget register %1 to %2?';
#pragma warning restore AA0470
        Text004: Label 'Are you sure?';
        Text005: Label 'Delete cost register\';
#pragma warning disable AA0470
        Text006: Label 'Register  no.      #1######';
        Text007: Label 'Register %1 can no longer be deleted because it is marked as closed.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure InitializeRequest(FromEntryNo: Integer; ToEntryNo: Integer)
    begin
        CostBudgetRegister2."No." := FromEntryNo;
        CostBudgetRegister3."No." := ToEntryNo;
    end;
}

