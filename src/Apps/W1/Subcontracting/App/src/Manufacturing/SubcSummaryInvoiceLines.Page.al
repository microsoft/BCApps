// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Purchases.History;

page 20581 "Subc. Summary Invoice Lines"
{
    Caption = 'Subcontracting Invoice Lines';
    PageType = List;
    SourceTable = "Purch. Inv. Line";
    ApplicationArea = Subcontracting;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Document No."; Rec."Document No.") { }
                field("Line No."; Rec."Line No.")
                {
                    ToolTip = 'Specifies the line number within the posted purchase invoice.';
                }
                field("Buy-from Vendor No."; Rec."Buy-from Vendor No.") { }
                field(Type; Rec.Type) { }
                field("No."; Rec."No.") { }
                field(Description; Rec.Description) { }
                field("Variant Code"; Rec."Variant Code") { }
                field(Quantity; Rec.Quantity) { }
                field("Unit of Measure Code"; Rec."Unit of Measure Code") { }
                field("Qty. per Unit of Measure"; Rec."Qty. per Unit of Measure")
                {
                    ToolTip = 'Specifies how many base units are in one document unit of measure.';
                }
                field("Quantity (Base)"; Rec."Quantity (Base)")
                {
                    ToolTip = 'Specifies the invoiced quantity in the item base unit of measure.';
                }
                field("Prod. Order No."; Rec."Prod. Order No.")
                {
                    ToolTip = 'Specifies the production order linked to this invoice line.';
                }
                field("Prod. Order Line No."; Rec."Prod. Order Line No.")
                {
                    ToolTip = 'Specifies the production order line linked to this invoice line.';
                }
                field("Routing No."; Rec."Routing No.")
                {
                    ToolTip = 'Specifies the routing linked to this invoice line.';
                }
                field("Routing Reference No."; Rec."Routing Reference No.")
                {
                    ToolTip = 'Specifies the routing reference number linked to this invoice line.';
                }
                field("Operation No."; Rec."Operation No.")
                {
                    ToolTip = 'Specifies the routing operation linked to this invoice line.';
                }
                field("Work Center No."; Rec."Work Center No.")
                {
                    ToolTip = 'Specifies the work center linked to this invoice line.';
                }
                field("Responsibility Center"; Rec."Responsibility Center")
                {
                    ToolTip = 'Specifies the responsibility center assigned to this invoice line.';
                }
            }
        }
    }
}
