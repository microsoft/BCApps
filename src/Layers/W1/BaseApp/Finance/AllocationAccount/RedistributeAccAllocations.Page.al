// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AllocationAccount;

page 2678 "Redistribute Acc. Allocations"
{
    PageType = Worksheet;
    SourceTable = "Allocation Line";
    Caption = 'Change Allocations';
    AutoSplitKey = true;

    layout
    {
        area(Content)
        {
            group(MainGroup)
            {
                ShowCaption = false;
                field(AmountToAllocate; AmountToAllocate)
                {
                    Caption = 'Original Amount to Allocate';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the amount to be allocated to the Destination Account.';
                    Editable = false;
                }
                field(PostingDate; PostingDate)
                {
                    Caption = 'Posting Date';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the date on which the allocation is posted.';
                    Editable = false;
                }
                field(RemainingAmountToAllocate; DifferenceAmount)
                {
                    Caption = 'Remaining Amount to Allocate';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the remaining amount to be allocated to one of the lines.';
                    StyleExpr = DifferenceAmountStyle;
                    Editable = false;
                }
                field(QuantityToAllocate; QuantityToAllocate)
                {
                    Caption = 'Quantity to Allocate';
                    ApplicationArea = All;
                    Visible = QuantityVisible;
                    ToolTip = 'Specifies the quantity to be allocated to the Destination Account.';
                    Editable = false;
                }
                field(QuantityToAllocateDifference; QuantityToAllocateDifference)
                {
                    Caption = 'Remaining Quantity to Allocate';
                    ApplicationArea = All;
                    Visible = QuantityVisible;
                    ToolTip = 'Specifies the remaining quantity to be allocated to one of the lines.';
                    StyleExpr = DifferenceQuantityStyle;
                    Editable = false;
                }
            }

            repeater(MainContent)
            {
                field(DestinationAccountType; Rec."Destination Account Type")
                {
                    Caption = 'Destination Account Type';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of the Destination Account.';

                    trigger OnValidate()
                    begin
                        UpdateDestinationAccountName();
                    end;
                }

                field(DestinationAccountNumber; Rec."Destination Account Number")
                {
                    Caption = 'Destination Account No.';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the Destination Account.';

                    trigger OnValidate()
                    begin
                        UpdateDestinationAccountName();
                    end;
                }

                field("Destination Account Name"; Rec."Destination Account Name")
                {
                    Caption = 'Destination Account Name';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the Destination Account.';
                    Editable = false;
                }
                field(Quantity; Rec.Quantity)
                {
                    Caption = 'Quantity';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the quantity to be allocated to the Destination Account.';
                    Visible = QuantityVisible;
                    trigger OnValidate()
                    begin
                        CalculateDifference();
                    end;
                }
                field(Amount; Rec.Amount)
                {
                    Caption = 'Amount';
                    Editable = not QuantityVisible;
                    ApplicationArea = All;
                    ToolTip = 'Specifies the amount to be allocated to the Destination Account.';

                    trigger OnValidate()
                    begin
                        CalculateDifference();
                    end;
                }
            }
        }
    }
    actions
    {
        area(processing)
        {
            action(ResetToDefault)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Reset to Default';
                Image = Restore;
#pragma warning disable AA0219
                ToolTip = 'Resets the allocation lines to the original allocation.';
#pragma warning restore AA0219

                Scope = Page;

                trigger OnAction()
                begin
                    Rec.ResetToDefault(Rec, ParentSystemId, ParentTableId);
                    Rec.Reset();
                    Modified := false;
                    if Rec.FindFirst() then;
                    CurrPage.Update(false);
                    DifferenceAmount := 0;
                    DifferenceAmountStyle := '';
                end;
            }
            action(Dimensions)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Dimensions';
                Image = Dimensions;
                ShortCutKey = 'Shift+Ctrl+D';
#pragma warning disable AA0219
                ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to journal lines to distribute costs and analyze transaction history.';
#pragma warning restore AA0219

                trigger OnAction()
                begin
                    Rec.ShowDimensions();
                    if Rec."Dimension Set ID" <> xRec."Dimension Set ID" then begin
                        Modified := true;
                        Rec.Modify();
                    end;
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(ResetToDefault_Promoted; ResetToDefault)
                {
                }
                actionref(Dimensions_Promoted; Dimensions)
                {
                }
            }
        }
    }
    trigger OnOpenPage()
    begin
        Rec.GetOrGenerateAllocationLines(Rec, ParentSystemId, ParentTableId, AmountToAllocate, PostingDate);
        Rec.Reset();
        if Rec.FindFirst() then
            Rec.SetRange("Allocation Account No.", Rec."Allocation Account No.");

        QuantityVisible := Rec.GetQuantityVisible(Rec);
        if QuantityVisible then
            Rec.GetQuantityDataForRedistributePage(Rec, ParentSystemId, ParentTableId, AmountPerUnit, QuantityToAllocate);
    end;

    trigger OnAfterGetRecord()
    begin
        UpdateDestinationAccountName();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        CalculateDifference();
        UpdateDestinationAccountName();
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Modified := true;
        exit(true);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Modified := true;
        exit(true);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        Modified := true;
        exit(true);
    end;

    procedure SetParentSystemId(NewParentSystemId: Guid)
    begin
        ParentSystemId := NewParentSystemId;
    end;

    procedure SetParentTableId(NewParentTableId: Integer)
    begin
        ParentTableId := NewParentTableId;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction in [CloseAction::Cancel, CloseAction::LookupCancel] then
            exit(true);

        if Modified then
            if Confirm(SaveChangesQst) then
                Rec.SaveChangesToAllocationLines(Rec, ParentSystemId, ParentTableId, AmountToAllocate);

        exit(true);
    end;

    local procedure CalculateDifference()
    var
        TotalsAllocationLine: Record "Allocation Line";
    begin
        TotalsAllocationLine.Copy(Rec, true);

        if QuantityVisible then begin
            TotalsAllocationLine.CalcSums(Quantity);
            QuantityToAllocateDifference := QuantityToAllocate - TotalsAllocationLine.Quantity;
            if QuantityToAllocateDifference <> 0 then
                DifferenceQuantityStyle := 'Attention'
            else
                DifferenceQuantityStyle := '';

            TotalsAllocationLine.Amount := TotalsAllocationLine.Quantity * AmountPerUnit;
            Rec.Amount := Rec.Quantity * AmountPerUnit;
        end else
            TotalsAllocationLine.CalcSums(Amount);

        DifferenceAmount := AmountToAllocate - TotalsAllocationLine.Amount;
        if DifferenceAmount <> 0 then
            DifferenceAmountStyle := 'Attention'
        else
            DifferenceAmountStyle := '';
    end;

    local procedure UpdateDestinationAccountName()
    var
        AllocAccountDistribution: Record "Alloc. Account Distribution";
    begin
        Rec."Destination Account Name" := AllocAccountDistribution.LookupDistributionAccountName(Rec."Destination Account Type", Rec."Destination Account Number");
    end;

    var
        DifferenceAmountStyle: Text;
        DifferenceQuantityStyle: Text;
        DifferenceAmount: Decimal;
        AmountToAllocate: Decimal;
        QuantityToAllocate: Decimal;
        QuantityToAllocateDifference: Decimal;
        AmountPerUnit: Decimal;
        PostingDate: Date;
        ParentSystemId: Guid;
        ParentTableId: Integer;
        Modified: Boolean;
        QuantityVisible: Boolean;
        SaveChangesQst: Label 'Do you want to save the changes?';
}
