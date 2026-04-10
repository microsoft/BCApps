// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CostAccounting.Allocation;

page 1106 "Cost Allocation Target"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    PageType = ListPart;
    SourceTable = "Cost Allocation Target";

    layout
    {
        area(content)
        {
            repeater(Control5)
            {
                ShowCaption = false;
                field("Target Cost Type"; Rec."Target Cost Type")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the type of target cost.';

                    trigger OnValidate()
                    var
                        TmpCostAllocTarget: Record "Cost Allocation Target";
                    begin
                        TmpCostAllocTarget.CopyFilters(Rec);
                        if TmpCostAllocTarget.IsEmpty() then
                            CurrPage.SaveRecord();
                    end;
                }
                field("Target Cost Center"; Rec."Target Cost Center")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the target cost center.';
                }
                field("Target Cost Object"; Rec."Target Cost Object")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the target cost object.';
                }
                field("Allocation Target Type"; Rec."Allocation Target Type")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies if the allocation comes from both budgeted and actual costs, only budgeted costs, or only actual costs.';
                }
                field("Percent per Share"; Rec."Percent per Share")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the percentage if the chosen Allocation Target Type is Percent per Share.';
                }
                field("Amount per Share"; Rec."Amount per Share")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the amount if the value in the Allocation Target Type field is Amount per Share.';
                }
                field("Static Base"; Rec."Static Base")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies whether or not the base is static.';
                    Visible = false;
                }
                field("Static Weighting"; Rec."Static Weighting")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies whether the values in the static base are weighted.';
                    Visible = false;
                }
                field(Share; Rec.Share)
                {
                    ApplicationArea = CostAccounting;
                    BlankZero = true;
                    ToolTip = 'Specifies the values calculated from the Static Base and Static Weighting fields. ';

                    trigger OnValidate()
                    begin
                        UpdatePage();
                    end;
                }
                field(Percent; Rec.Percent)
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the percentage rate calculated based on all other allocation targets.';
                }
                field(Base; Rec.Base)
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies whether or not the base is static.';
                }
                field("No. Filter"; Rec."No. Filter")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies a filter for the numbers that are included. ';
                }
                field("Date Filter Code"; Rec."Date Filter Code")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies a filter to filter the calculation of the dynamic allocation base by dates. You use the Date Filter Code field to define a dynamic date range without using a static date. If the allocation bases are updated, the date filter is automatically updated by using the work date.';
                }
                field("Cost Center Filter"; Rec."Cost Center Filter")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the cost center code. The code serves as a default value for cost posting that is captured later in the cost journal.';
                }
                field("Cost Object Filter"; Rec."Cost Object Filter")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the cost object code. The code serves as a default value for cost posting that is captured later in the cost journal.';
                }
                field("Group Filter"; Rec."Group Filter")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies a filter so that the dynamic calculation of the Share field is based on the chosen group. Leave the field blank for static allocation.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("Allo&cation")
            {
                Caption = 'Allo&cation';
                Image = Allocate;
                action(AllocationTargetCard)
                {
                    ApplicationArea = CostAccounting;
                    Caption = 'Allocation Target &Card';
                    RunPageOnRec = true;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or edit detailed information about the allocation target.';

                    trigger OnAction()
                    begin
                        ShowAllocTargetCard();
                    end;
                }
            }
        }
    }

    local procedure UpdatePage()
    begin
        CurrPage.Update(false);
    end;

    local procedure ShowAllocTargetCard()
    begin
        PAGE.Run(PAGE::"Cost Allocation Target Card", Rec);
        UpdatePage();
    end;
}

