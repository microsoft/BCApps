// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CostAccounting.Setup;

page 1113 "Cost Accounting Setup"
{
    ApplicationArea = CostAccounting;
    Caption = 'Cost Accounting Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Cost Accounting Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Starting Date for G/L Transfer"; Rec."Starting Date for G/L Transfer")
                {
                    ApplicationArea = CostAccounting;
                    MultiLine = true;
                    ToolTip = 'Specifies the starting date of when general ledger entries are transferred to cost accounting.';

                    trigger OnValidate()
                    begin
                        if not Confirm(Text001, true, Rec."Starting Date for G/L Transfer") then
                            Error(Text003);
                        Rec.Modify();
                    end;
                }
                field("Align G/L Account"; Rec."Align G/L Account")
                {
                    ApplicationArea = CostAccounting;
                    MultiLine = true;
                    ToolTip = 'Specifies how changes in the chart of accounts are carried over to the chart of cost types.';
                }
                field("Align Cost Center Dimension"; Rec."Align Cost Center Dimension")
                {
                    ApplicationArea = Dimensions;
                    MultiLine = true;
                    ToolTip = 'Specifies how changes in dimensions are carried over to the chart of cost centers.';
                }
                field("Align Cost Object Dimension"; Rec."Align Cost Object Dimension")
                {
                    ApplicationArea = Dimensions;
                    MultiLine = true;
                    ToolTip = 'Specifies how changes in dimensions are carried over to the chart of cost centers.';
                }
                field("Auto Transfer from G/L"; Rec."Auto Transfer from G/L")
                {
                    ApplicationArea = CostAccounting;
                    MultiLine = true;
                    ToolTip = 'Specifies that the cost accounting is updated in the general ledger after every posting.';

                    trigger OnValidate()
                    begin
                        if Rec."Auto Transfer from G/L" then
                            if not Confirm(Text002, true) then
                                Error(Text003);
                    end;
                }
                field("Check G/L Postings"; Rec."Check G/L Postings")
                {
                    ApplicationArea = CostAccounting;
                    MultiLine = true;
                    ToolTip = 'Specifies if the predefined cost center or cost object already exists in cost accounting when you post to the general ledger.';
                }
            }
            group(Allocation)
            {
                Caption = 'Allocation';
                field("Last Allocation ID"; Rec."Last Allocation ID")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies a number series for allocations.';
                }
                field("Last Allocation Doc. No."; Rec."Last Allocation Doc. No.")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the last document number that is assigned to all the entries that were generated with the same allocation ID during allocation.';
                }
            }
            group("Cost Accounting Dimensions")
            {
                Caption = 'Cost Accounting Dimensions';
                field("Cost Center Dimension"; Rec."Cost Center Dimension")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the cost center code. The code serves as a default value for cost posting that is captured later in the cost journal.';
                }
                field("Cost Object Dimension"; Rec."Cost Object Dimension")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the cost object code. The code serves as a default value for cost posting that is captured later in the cost journal.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(UpdateCostAcctgDimensions)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Update Cost Acctg. Dimensions';
                    Image = CostAccountingDimensions;
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = New;
                    ToolTip = 'Update existing cost center and cost object dimensions to the new cost center and cost object dimensions.';

                    trigger OnAction()
                    begin
                        REPORT.RunModal(REPORT::"Update Cost Acctg. Dimensions");
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'This field specifies that only general ledger entries from this posting date are transferred to Cost Accounting.\\Are you sure that you want to set the date to %1?';
#pragma warning restore AA0470
        Text002: Label 'All previous general ledger entries will be transferred to Cost Accounting. Do you want to continue?';
        Text003: Label 'The change was canceled.';
#pragma warning restore AA0074
}

