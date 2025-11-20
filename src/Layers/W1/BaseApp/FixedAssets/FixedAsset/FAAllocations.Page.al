// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.FixedAsset;

using Microsoft.Finance.Dimension;

page 5623 "FA Allocations"
{
    AutoSplitKey = true;
    Caption = 'FA Allocations';
    DataCaptionFields = "Code", "Allocation Type";
    PageType = Worksheet;
    SourceTable = "FA Allocation";
    AboutTitle = 'About FA Allocations';
    AboutText = 'The **FA Allocations** are used to allocate transactions to various departments or projects. Allocation is applied to fixed asset classes, not to individual assets.';

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Account No."; Rec."Account No.")
                {
                    ApplicationArea = FixedAssets;
                    AboutTitle = 'Manage Account No.';
                    AboutText = 'Choose the G/L Account No. on which the allocation value will be posted.';
                    ToolTip = 'Specifies the account number to allocate to for the fixed asset allocation type on this line.';
                }
                field("Account Name"; Rec."Account Name")
                {
                    ApplicationArea = FixedAssets;
                    DrillDown = false;
                    ToolTip = 'Specifies the name of the account on this allocation line.';
                }
                field("Allocation %"; Rec."Allocation %")
                {
                    ApplicationArea = FixedAssets;
                    AboutTitle = 'Manage Allocation Percentage';
                    AboutText = 'Specify the allocation percentage to calculate the amount during the transactions.';
                    ToolTip = 'Specifies the percentage to use when allocating the amount for the allocation type.';
                }
            }
            group(Control18)
            {
                ShowCaption = false;
                field(AllocationPct; AllocationPct + Rec."Allocation %" - xRec."Allocation %")
                {
                    ApplicationArea = All;
                    Caption = 'Allocation %';
                    DecimalPlaces = 1 : 1;
                    Editable = false;
                    ToolTip = 'Specifies the allocation percentage that has accumulated on the line.';
                    Visible = AllocationPctVisible;
                }
                field(TotalAllocationPct; TotalAllocationPct + Rec."Allocation %" - xRec."Allocation %")
                {
                    ApplicationArea = All;
                    Caption = 'Total Alloc. %';
                    DecimalPlaces = 1 : 1;
                    Editable = false;
                    ToolTip = 'Specifies the total allocation percentage for the accounts in the FA Allocations window.';
                    Visible = TotalAllocationPctVisible;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
                        CurrPage.SaveRecord();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        UpdateAllocationPct();
    end;

    trigger OnInit()
    begin
        TotalAllocationPctVisible := true;
        AllocationPctVisible := true;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        UpdateAllocationPct();
    end;

    var
        ShowAllocationPct: Boolean;
        ShowTotalAllocationPct: Boolean;

    protected var
        AllocationPct: Decimal;
        TotalAllocationPct: Decimal;
        AllocationPctVisible: Boolean;
        TotalAllocationPctVisible: Boolean;

    local procedure UpdateAllocationPct()
    var
        FAAllocation: Record "FA Allocation";
    begin
        FAAllocation.CopyFilters(Rec);
        ShowTotalAllocationPct := FAAllocation.CalcSums("Allocation %");
        if ShowTotalAllocationPct then begin
            TotalAllocationPct := FAAllocation."Allocation %";
            if Rec."Line No." = 0 then
                TotalAllocationPct := TotalAllocationPct + xRec."Allocation %";
        end;

        if Rec."Line No." <> 0 then begin
            FAAllocation.SetRange("Line No.", 0, Rec."Line No.");
            ShowAllocationPct := FAAllocation.CalcSums("Allocation %");
            if ShowAllocationPct then
                AllocationPct := FAAllocation."Allocation %";
        end else begin
            FAAllocation.SetRange("Line No.", 0, xRec."Line No.");
            ShowAllocationPct := FAAllocation.CalcSums("Allocation %");
            if ShowAllocationPct then begin
                AllocationPct := FAAllocation."Allocation %";
                FAAllocation.CopyFilters(Rec);
                FAAllocation := xRec;
                if FAAllocation.Next() = 0 then
                    AllocationPct := AllocationPct + xRec."Allocation %";
            end;
        end;

        AllocationPctVisible := ShowAllocationPct;
        TotalAllocationPctVisible := ShowTotalAllocationPct;
    end;
}

