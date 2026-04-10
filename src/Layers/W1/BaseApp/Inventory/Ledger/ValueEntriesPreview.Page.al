// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Ledger;

using Microsoft.Finance.Dimension;
using System.Security.User;

page 5807 "Value Entries Preview"
{
    Caption = 'Value Entries Preview';
    Editable = false;
    PageType = List;
    SourceTable = "Value Entry";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Valuation Date"; Rec."Valuation Date")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Item Ledger Entry Type"; Rec."Item Ledger Entry Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Entry Type"; Rec."Entry Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Variance Type"; Rec."Variance Type")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field(Adjustment; Rec.Adjustment)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Document Line No."; Rec."Document Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Item Charge No."; Rec."Item Charge No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Return Reason Code"; Rec."Return Reason Code")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Sales Amount (Expected)"; Rec."Sales Amount (Expected)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the expected price of the item for a sales entry, which means that it has not been invoiced yet.';
                    Visible = false;
                }
                field("Sales Amount (Actual)"; Rec."Sales Amount (Actual)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the price of the item for a sales entry.';
                }
                field("Cost Amount (Expected)"; Rec."Cost Amount (Expected)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the expected cost of the items, which is calculated by multiplying the Cost per Unit by the Valued Quantity.';
                }
                field("Cost Amount (Actual)"; Rec."Cost Amount (Actual)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the cost of invoiced items.';
                }
                field("Cost Amount (Non-Invtbl.)"; Rec."Cost Amount (Non-Invtbl.)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the non-inventoriable cost, that is an item charge assigned to an outbound entry.';
                }
                field("Cost Posted to G/L"; Rec."Cost Posted to G/L")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Expected Cost Posted to G/L"; Rec."Expected Cost Posted to G/L")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Cost Amount (Expected) (ACY)"; Rec."Cost Amount (Expected) (ACY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the expected cost of the items in the additional reporting currency.';
                    Visible = false;
                }
                field("Cost Amount (Actual) (ACY)"; Rec."Cost Amount (Actual) (ACY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the cost of the items that have been invoiced, if you post in an additional reporting currency.';
                    Visible = false;
                }
                field("Cost Amount (Non-Invtbl.)(ACY)"; Rec."Cost Amount (Non-Invtbl.)(ACY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the non-inventoriable cost, that is an item charge assigned to an outbound entry in the additional reporting currency.';
                    Visible = false;
                }
                field("Cost Posted to G/L (ACY)"; Rec."Cost Posted to G/L (ACY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount that has been posted to the general ledger if you post in an additional reporting currency.';
                    Visible = false;
                }
                field("Item Ledger Entry Quantity"; Rec."Item Ledger Entry Quantity")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Valued Quantity"; Rec."Valued Quantity")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Invoiced Quantity"; Rec."Invoiced Quantity")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Cost per Unit"; Rec."Cost per Unit")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Cost per Unit (ACY)"; Rec."Cost per Unit (ACY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the cost of one unit of the item in the entry.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    Visible = false;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Discount Amount"; Rec."Discount Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Salespers./Purch. Code"; Rec."Salespers./Purch. Code")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation(Rec."User ID");
                    end;
                }
                field("Source Posting Group"; Rec."Source Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Source Code"; Rec."Source Code")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Gen. Bus. Posting Group"; Rec."Gen. Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Gen. Prod. Posting Group"; Rec."Gen. Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Global Dimension 1 Code"; Rec."Global Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = Dim1Visible;
                }
                field("Global Dimension 2 Code"; Rec."Global Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = Dim2Visible;
                }
                field("Source Type"; Rec."Source Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Source No."; Rec."Source No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Order Type"; Rec."Order Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies which type of transaction the entry is created from.';
                }
                field("Order No."; Rec."Order No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Valued By Average Cost"; Rec."Valued By Average Cost")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Job Task No."; Rec."Job Task No.")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Job Ledger Entry No."; Rec."Job Ledger Entry No.")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Dimension Set ID"; Rec."Dimension Set ID")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
                field("Shortcut Dimension 3 Code"; Rec."Shortcut Dimension 3 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    Visible = Dim3Visible;
                }
                field("Shortcut Dimension 4 Code"; Rec."Shortcut Dimension 4 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    Visible = Dim4Visible;
                }
                field("Shortcut Dimension 5 Code"; Rec."Shortcut Dimension 5 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    Visible = Dim5Visible;
                }
                field("Shortcut Dimension 6 Code"; Rec."Shortcut Dimension 6 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    Visible = Dim6Visible;
                }
                field("Shortcut Dimension 7 Code"; Rec."Shortcut Dimension 7 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    Visible = Dim7Visible;
                }
                field("Shortcut Dimension 8 Code"; Rec."Shortcut Dimension 8 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    Visible = Dim8Visible;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            action(SetDimensionFilter)
            {
                ApplicationArea = Dimensions;
                Caption = 'Set Dimension Filter';
                Ellipsis = true;
                Image = "Filter";
                ToolTip = 'Limit the entries according to the dimension filters that you specify. NOTE: If you use a high number of dimension combinations, this function may not work and can result in a message that the SQL server only supports a maximum of 2100 parameters.';

                trigger OnAction()
                begin
                    Rec.SetFilter("Dimension Set ID", DimensionSetIDFilter.LookupFilter());
                end;
            }
        }
    }

    var
        DimensionSetIDFilter: Page "Dimension Set ID Filter";

    trigger OnOpenPage()
    begin
        SetDimVisibility();
    end;

    protected var
        Dim1Visible: Boolean;
        Dim2Visible: Boolean;
        Dim3Visible: Boolean;
        Dim4Visible: Boolean;
        Dim5Visible: Boolean;
        Dim6Visible: Boolean;
        Dim7Visible: Boolean;
        Dim8Visible: Boolean;

    local procedure SetDimVisibility()
    var
        DimensionManagement: Codeunit DimensionManagement;
    begin
        DimensionManagement.UseShortcutDims(Dim1Visible, Dim2Visible, Dim3Visible, Dim4Visible, Dim5Visible, Dim6Visible, Dim7Visible, Dim8Visible);
    end;

    procedure Set(var TempValueEntry: Record "Value Entry" temporary)
    begin
        if TempValueEntry.Find('-') then
            repeat
                Rec := TempValueEntry;
                Rec.Insert();
            until TempValueEntry.Next() = 0;

        OnAfterSet(Rec, TempValueEntry);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSet(var ValueEntry: Record "Value Entry"; var TempValueEntry: Record "Value Entry" temporary)
    begin
    end;
}

