// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Ledger;

using Microsoft.Finance.Dimension;

page 167 "Item Ledger Entries Preview"
{
    Caption = 'Item Ledger Entries Preview';
    DataCaptionFields = "Item No.";
    Editable = false;
    PageType = List;
    SourceTable = "Item Ledger Entry";
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
                field("Entry Type"; Rec."Entry Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies which type of transaction the entry is created from.';
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
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    Visible = false;
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
                field("Expiration Date"; Rec."Expiration Date")
                {
                    ApplicationArea = ItemTracking;
                    Visible = false;
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    Visible = ItemTrackingVisible;
                }
                field("Lot No."; Rec."Lot No.")
                {
                    ApplicationArea = ItemTracking;
                    Visible = ItemTrackingVisible;
                }
                field("Package No."; Rec."Package No.")
                {
                    ApplicationArea = ItemTracking;
                    Visible = ItemTrackingVisible;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Invoiced Quantity"; Rec."Invoiced Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = true;
                }
                field("Remaining Quantity"; Rec."Remaining Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = true;
                }
                field("Shipped Qty. Not Returned"; Rec."Shipped Qty. Not Returned")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Reserved Quantity"; Rec."Reserved Quantity")
                {
                    ApplicationArea = Reservation;
                    Visible = false;
                }
                field("Qty. per Unit of Measure"; Rec."Qty. per Unit of Measure")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field(SalesAmountExpected; SalesAmountExpected)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    Caption = 'Sales Amount (Expected)';
                    ToolTip = 'Specifies the expected sales amount in LCY. Choose the field to see the value entries that make up this amount.';
                    Visible = false;
                }
                field(SalesAmountActual; SalesAmountActual)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    Caption = 'Sales Amount (Actual)';
                    ToolTip = 'Specifies the sum of the actual sales amounts if you post.';
                }
                field(CostAmountExpected; CostAmountExpected)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    Caption = 'Cost Amount (Expected)';
                    ToolTip = 'Specifies the expected cost amount of the item. Expected costs are calculated from yet non-invoiced documents.';
                    Visible = false;
                }
                field(CostAmountActual; CostAmountActual)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    Caption = 'Cost Amount (Actual)';
                    ToolTip = 'Specifies the sum of the actual cost amounts if you post.';
                }
                field(CostAmountNonInvtbl; CostAmountNonInvtbl)
                {
                    ApplicationArea = ItemCharges;
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    Caption = 'Cost Amount (Non-Invtbl.)';
                    ToolTip = 'Specifies the sum of the non-inventoriable cost amounts if you post. Typical non-inventoriable costs come from item charges.';
                }
                field(CostAmountExpectedACY; CostAmountExpectedACY)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    Caption = 'Cost Amount (Expected) (ACY)';
                    ToolTip = 'Specifies the expected cost amount of the item. Expected costs are calculated from yet non-invoiced documents.';
                    Visible = false;
                }
                field(CostAmountActualACY; CostAmountActualACY)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    Caption = 'Cost Amount (Actual) (ACY)';
                    ToolTip = 'Specifies the actual cost amount of the item.';
                    Visible = false;
                }
                field(CostAmountNonInvtblACY; CostAmountNonInvtblACY)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    Caption = 'Cost Amount (Non-Invtbl.) (ACY)';
                    ToolTip = 'Specifies the sum of the non-inventoriable cost amounts if you post. Typical non-inventoriable costs come from item charges.';
                    Visible = false;
                }
                field("Completely Invoiced"; Rec."Completely Invoiced")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field(Open; Rec.Open)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the entry has been fully applied to.';
                }
                field("Drop Shipment"; Rec."Drop Shipment")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Assemble to Order"; Rec."Assemble to Order")
                {
                    ApplicationArea = Assembly;
                    Visible = false;
                }
                field("Applied Entry to Adjust"; Rec."Applied Entry to Adjust")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
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
                field("Order Line No."; Rec."Order Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Prod. Order Comp. Line No."; Rec."Prod. Order Comp. Line No.")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
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
            group("Ent&ry")
            {
                Caption = 'Ent&ry';
                Image = Entry;
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
                    end;
                }
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
            group("&Application")
            {
                Caption = '&Application';
                Image = Apply;
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        CalcAmounts();
    end;

    trigger OnOpenPage()
    begin
        SetDimVisibility();
    end;

    var
        TempValueEntry: Record "Value Entry" temporary;
        DimensionSetIDFilter: Page "Dimension Set ID Filter";
        SalesAmountExpected: Decimal;
        SalesAmountActual: Decimal;
        CostAmountExpected: Decimal;
        CostAmountActual: Decimal;
        CostAmountNonInvtbl: Decimal;
        CostAmountExpectedACY: Decimal;
        CostAmountActualACY: Decimal;
        CostAmountNonInvtblACY: Decimal;

    protected var
        Dim1Visible: Boolean;
        Dim2Visible: Boolean;
        Dim3Visible: Boolean;
        Dim4Visible: Boolean;
        Dim5Visible: Boolean;
        Dim6Visible: Boolean;
        Dim7Visible: Boolean;
        Dim8Visible: Boolean;
        ItemTrackingVisible: Boolean;

    local procedure SetDimVisibility()
    var
        DimensionManagement: Codeunit DimensionManagement;
    begin
        DimensionManagement.UseShortcutDims(Dim1Visible, Dim2Visible, Dim3Visible, Dim4Visible, Dim5Visible, Dim6Visible, Dim7Visible, Dim8Visible);
    end;

    procedure Set(var TempItemLedgerEntry2: Record "Item Ledger Entry" temporary; var TempValueEntry2: Record "Value Entry" temporary)
    begin
        ItemTrackingVisible := false;
        if TempItemLedgerEntry2.FindSet() then
            repeat
                Rec := TempItemLedgerEntry2;
                Rec.Insert();
                if Rec.TrackingExists() then
                    ItemTrackingVisible := true;
            until TempItemLedgerEntry2.Next() = 0;

        if TempValueEntry2.FindSet() then
            repeat
                TempValueEntry := TempValueEntry2;
                TempValueEntry.Insert();
            until TempValueEntry2.Next() = 0;
    end;

    local procedure CalcAmounts()
    begin
        SalesAmountExpected := 0;
        SalesAmountActual := 0;
        CostAmountExpected := 0;
        CostAmountActual := 0;
        CostAmountNonInvtbl := 0;
        CostAmountExpectedACY := 0;
        CostAmountActualACY := 0;
        CostAmountNonInvtblACY := 0;

        TempValueEntry.SetFilter("Item Ledger Entry No.", '%1', Rec."Entry No.");
        if TempValueEntry.FindSet() then
            repeat
                SalesAmountExpected += TempValueEntry."Sales Amount (Expected)";
                SalesAmountActual += TempValueEntry."Sales Amount (Actual)";
                CostAmountExpected += TempValueEntry."Cost Amount (Expected)";
                CostAmountActual += TempValueEntry."Cost Amount (Actual)";
                CostAmountNonInvtbl += TempValueEntry."Cost Amount (Non-Invtbl.)";
                CostAmountExpectedACY += TempValueEntry."Cost Amount (Expected) (ACY)";
                CostAmountActualACY += TempValueEntry."Cost Amount (Actual) (ACY)";
                CostAmountNonInvtblACY += TempValueEntry."Cost Amount (Non-Invtbl.)(ACY)";
            until TempValueEntry.Next() = 0;
    end;
}
