// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CostAccounting.Ledger;

using Microsoft.CostAccounting.Setup;
using Microsoft.Finance.GeneralLedger.Ledger;

report 1130 "Delete Cost Entries"
{
    Caption = 'Delete Cost Entries';
    Permissions = TableData "G/L Entry" = rm;
    ProcessingOnly = true;

    dataset
    {
        dataitem("Cost Register"; "Cost Register")
        {
            DataItemTableView = sorting("No.") order(descending);

            trigger OnAfterGetRecord()
            var
                CostEntry: Record "Cost Entry";
            begin
                Window.Update(1, "No.");

                if Closed then
                    Error(Text007, "No.");

                if Source = Source::Allocation then begin
                    CostEntry.SetCurrentKey("Allocated with Journal No.");
                    CostEntry.SetRange("Allocated with Journal No.", "No.");
                    CostEntry.ModifyAll(Allocated, false);
                    CostEntry.ModifyAll("Allocated with Journal No.", 0);
                end;

                CostEntry.Reset();
                CostEntry.SetRange("Entry No.", "From Cost Entry No.", "To Cost Entry No.");
                CostEntry.DeleteAll();
            end;

            trigger OnPostDataItem()
            var
                CostEntry: Record "Cost Entry";
            begin
                DeleteAll();
                Reset();
                SetRange(Source, Source::Allocation);
                if FindLast() then begin
                    CostEntry.Get("To Cost Entry No.");
                    CostAccSetup.Get();
                    CostAccSetup."Last Allocation Doc. No." := CostEntry."Document No.";
                    CostAccSetup.Modify();
                end;
            end;

            trigger OnPreDataItem()
            begin
                SetRange("No.", CostRegister2."No.", CostRegister3."No.");
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
                    field(FromRegisterNo; CostRegister2."No.")
                    {
                        ApplicationArea = CostAccounting;
                        Caption = 'From Register No.';
                        Lookup = true;
                        TableRelation = "Cost Register" where(Closed = const(false));
                        ToolTip = 'Specifies the starting posted register number to determine the starting point for the deletion of register numbers.';
                    }
                    field(ToRegisterNo; CostRegister3."No.")
                    {
                        ApplicationArea = CostAccounting;
                        Caption = 'To Register No.';
                        Editable = false;
                        TableRelation = "Cost Register" where(Closed = const(false));
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
            CostRegister2.FindLast();
            CostRegister3.FindLast();
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    var
        CostRegister: Record "Cost Register";
    begin
        if CostRegister2."No." > CostRegister3."No." then
            Error(Text000);

        if not Confirm(Text001, false, CostRegister2."No.", CostRegister3."No.") then
            Error('');

        if not Confirm(Text004) then
            Error('');

        CostRegister.FindLast();
        if CostRegister."No." > CostRegister3."No." then
            Error(CostRegisterHasBeenModifiedErr, CostRegister."No.");

        Window.Open(Text005 +
          Text006);
    end;

    var
        CostRegister2: Record "Cost Register";
        CostRegister3: Record "Cost Register";
        CostAccSetup: Record "Cost Accounting Setup";
        Window: Dialog;

#pragma warning disable AA0074
        Text000: Label 'From Register No. must not be higher than To Register No..';
#pragma warning disable AA0470
        Text001: Label 'All corresponding cost entries and register entries will be deleted. Do you want to delete cost register %1 to %2?';
#pragma warning restore AA0470
        Text004: Label 'Are you sure?';
        Text005: Label 'Delete cost register\';
#pragma warning disable AA0470
        Text006: Label 'Register  no.      #1######';
        Text007: Label 'Register %1 can no longer be deleted because it is marked as closed.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0470
        CostRegisterHasBeenModifiedErr: Label 'Another user has modified the cost register. The To Register No. field must be equal to %1.\Run the Delete Cost Entries batch job again.';
#pragma warning restore AA0470

    procedure InitializeRequest(NewFromRegisterNo: Integer; NewToRegisterNo: Integer)
    begin
        CostRegister2."No." := NewFromRegisterNo;
        CostRegister3."No." := NewToRegisterNo;
    end;
}

