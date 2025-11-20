// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Reconciliation;

page 5846 "Inventory Report Entry"
{
    Caption = 'Inventory Report Entry';
    PageType = List;
    SourceTable = "Inventory Report Entry";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the inventory report entry refers to an item or a general ledger account.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a value that depends on the type of the inventory report entry.';
                }
                field(Inventory; Rec.Inventory)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';

                    trigger OnDrillDown()
                    begin
                        GetInvtReport.DrillDownInventory(Rec);
                    end;
                }
                field("Inventory (Interim)"; Rec."Inventory (Interim)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';

                    trigger OnDrillDown()
                    begin
                        GetInvtReport.DrillDownInventoryInterim(Rec);
                    end;
                }
                field("WIP Inventory"; Rec."WIP Inventory")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';

                    trigger OnDrillDown()
                    begin
                        GetInvtReport.DrillDownWIPInventory(Rec);
                    end;
                }
                field("Direct Cost Applied Actual"; Rec."Direct Cost Applied Actual")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';

                    trigger OnDrillDown()
                    begin
                        GetInvtReport.DrillDownDirectCostApplActual(Rec);
                    end;
                }
                field("Overhead Applied Actual"; Rec."Overhead Applied Actual")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';

                    trigger OnDrillDown()
                    begin
                        GetInvtReport.DrillDownOverheadAppliedActual(Rec);
                    end;
                }
                field("Purchase Variance"; Rec."Purchase Variance")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';

                    trigger OnDrillDown()
                    begin
                        GetInvtReport.DrillDownPurchaseVariance(Rec);
                    end;
                }
                field("Inventory Adjmt."; Rec."Inventory Adjmt.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';

                    trigger OnDrillDown()
                    begin
                        GetInvtReport.DrillDownInventoryAdjmt(Rec);
                    end;
                }
                field("Invt. Accrual (Interim)"; Rec."Invt. Accrual (Interim)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';

                    trigger OnDrillDown()
                    begin
                        GetInvtReport.DrillDownInvtAccrualInterim(Rec);
                    end;
                }
                field(COGS; Rec.COGS)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';

                    trigger OnDrillDown()
                    begin
                        GetInvtReport.DrillDownCOGS(Rec);
                    end;
                }
                field("COGS (Interim)"; Rec."COGS (Interim)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';

                    trigger OnDrillDown()
                    begin
                        GetInvtReport.DrillDownCOGSInterim(Rec);
                    end;
                }
                field("Material Variance"; Rec."Material Variance")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';

                    trigger OnDrillDown()
                    begin
                        GetInvtReport.DrillDownMaterialVariance(Rec);
                    end;
                }
                field("Mat. Non-Inventory Variance"; Rec."Mat. Non-Inventory Variance")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';

                    trigger OnDrillDown()
                    begin
                        GetInvtReport.DrillDownMaterialNonInventoryVariance(Rec);
                    end;
                }
                field("Capacity Variance"; Rec."Capacity Variance")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';

                    trigger OnDrillDown()
                    begin
                        GetInvtReport.DrillDownCapVariance(Rec);
                    end;
                }
                field("Subcontracted Variance"; Rec."Subcontracted Variance")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';

                    trigger OnDrillDown()
                    begin
                        GetInvtReport.DrillDownSubcontractedVariance(Rec);
                    end;
                }
                field("Capacity Overhead Variance"; Rec."Capacity Overhead Variance")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';

                    trigger OnDrillDown()
                    begin
                        GetInvtReport.DrillDownCapOverheadVariance(Rec);
                    end;
                }
                field("Mfg. Overhead Variance"; Rec."Mfg. Overhead Variance")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';

                    trigger OnDrillDown()
                    begin
                        GetInvtReport.DrillDownMfgOverheadVariance(Rec);
                    end;
                }
                field("Direct Cost Applied WIP"; Rec."Direct Cost Applied WIP")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';

                    trigger OnDrillDown()
                    begin
                        GetInvtReport.DrillDownDirectCostApplToWIP(Rec);
                    end;
                }
                field("Overhead Applied WIP"; Rec."Overhead Applied WIP")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        GetInvtReport.DrillDownOverheadAppliedToWIP(Rec);
                    end;
                }
                field("Inventory To WIP"; Rec."Inventory To WIP")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';

                    trigger OnDrillDown()
                    begin
                        GetInvtReport.DrillDownInvtToWIP(Rec);
                    end;
                }
                field("WIP To Interim"; Rec."WIP To Interim")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';

                    trigger OnDrillDown()
                    begin
                        GetInvtReport.DrillDownWIPToInvtInterim(Rec);
                    end;
                }
                field("Direct Cost Applied"; Rec."Direct Cost Applied")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';

                    trigger OnDrillDown()
                    begin
                        GetInvtReport.DrillDownDirectCostApplied(Rec);
                    end;
                }
                field("Overhead Applied"; Rec."Overhead Applied")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a value that depends on the type of the inventory period entry.';

                    trigger OnDrillDown()
                    begin
                        GetInvtReport.DrillDownOverheadApplied(Rec);
                    end;
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
    }

    var
        GetInvtReport: Codeunit "Get Inventory Report";
}

