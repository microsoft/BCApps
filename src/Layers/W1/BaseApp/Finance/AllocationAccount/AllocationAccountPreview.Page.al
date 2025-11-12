// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AllocationAccount;

page 2674 "Allocation Account Preview"
{
    PageType = Worksheet;
    SourceTable = "Allocation Line";
    DeleteAllowed = false;
    Caption = 'Allocation Account Preview';

    layout
    {
        area(Content)
        {
            group(MainGroup)
            {
                ShowCaption = false;
                field(AmountToAllocate; AmountToAllocate)
                {
                    Caption = 'Amount to Allocate';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the amount to be allocated to the Destination Account.';
                    trigger OnValidate()
                    begin
                        UpdateData()
                    end;
                }
                field(PostingDate; PostingDate)
                {
                    Caption = 'Posting Date';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date on which the allocation is posted.';
                    trigger OnValidate()
                    begin
                        UpdateData()
                    end;
                }
            }

            repeater(MainContent)
            {
                Editable = false;
                field(DestinationAccountNumber; Rec."Destination Account Number")
                {
                    Caption = 'Destination Account No.';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the Destination Account.';
                }
                field(DestinationAccountName; Rec."Destination Account Name")
                {
                    Caption = 'Destination Account Name';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the Destination Account.';
                    Editable = false;
                }
                field(Amount; Rec.Amount)
                {
                    Caption = 'Amount';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the amount to be allocated to the Destination Account.';
                }
                field(BreakdownAccountNumber; Rec."Breakdown Account Number")
                {
                    Caption = 'Breakdown Account No.';
                    ApplicationArea = All;
                    Visible = not FixedAllocation;
                    ToolTip = 'Specifies the number of the Breakdown Account that is used to calculate the amount to be distributed to the destination account.';
                }
                field("Breakdown Account Name"; Rec."Breakdown Account Name")
                {
                    Caption = 'Breakdown Account Name';
                    ApplicationArea = All;
                    Visible = not FixedAllocation;
                    ToolTip = 'Specifies the name of the Breakdown Account that is used to calculate the amount to be distributed to the destination account.';
                }
                field(BreakdownAccountBalance; Rec."Breakdown Account Balance")
                {
                    Caption = 'Breakdown Account Balance';
                    ApplicationArea = All;
                    Visible = not FixedAllocation;
                    ToolTip = 'Specifies the balance of the Breakdown Account that is used to calculate the amount to be distributed to the destination account.';
                }
                field(Percentage; Rec.Percentage)
                {
                    Caption = 'Percentage';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the percentage that is used to calculate the amount to be assinged to the destination account.';
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        AllocationAccountMgt: Codeunit "Allocation Account Mgt.";
    begin
        PostingDate := WorkDate();
        AmountToAllocate := AllocationAccountMgt.GetDefaultAmountForPreview();
        UpdateData();
    end;

    local procedure UpdateData()
    var
        AllocationAccountMgt: Codeunit "Allocation Account Mgt.";
    begin
        Rec.DeleteAll();
        if FixedAllocation then
            AllocationAccountMgt.GenerateFixedAllocationLines(AllocationAccount, Rec, AmountToAllocate, 0, '')
        else
            AllocationAccountMgt.GenerateVariableAllocationLines(AllocationAccount, Rec, AmountToAllocate, PostingDate, 0, '');

        Rec.FindFirst();
        CurrPage.Update(false);
    end;

    internal procedure UpdateAllocationAccount(var NewAllocationAccount: Record "Allocation Account")
    begin
        AllocationAccount := NewAllocationAccount;
    end;

    internal procedure SetFixedAllocation(NewFixedAllocation: boolean)
    begin
        FixedAllocation := NewFixedAllocation;
    end;

    var
        AllocationAccount: Record "Allocation Account";
        AmountToAllocate: Decimal;
        PostingDate: Date;
        FixedAllocation: Boolean;
}
