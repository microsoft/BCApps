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
                field("Line No."; Rec."Line No.") { }
                field("Buy-from Vendor No."; Rec."Buy-from Vendor No.") { }
                field(Type; Rec.Type) { }
                field("No."; Rec."No.") { }
                field(Description; Rec.Description) { }
                field("Variant Code"; Rec."Variant Code") { }
                field(Quantity; Rec.Quantity) { }
                field("Unit of Measure Code"; Rec."Unit of Measure Code") { }
                field("Qty. per Unit of Measure"; Rec."Qty. per Unit of Measure") { }
                field("Quantity (Base)"; Rec."Quantity (Base)") { }
                field("Prod. Order No."; Rec."Prod. Order No.") { }
                field("Prod. Order Line No."; Rec."Prod. Order Line No.") { }
                field("Routing No."; Rec."Routing No.") { }
                field("Routing Reference No."; Rec."Routing Reference No.") { }
                field("Operation No."; Rec."Operation No.") { }
                field("Work Center No."; Rec."Work Center No.") { }
                field("Responsibility Center"; Rec."Responsibility Center") { }
            }
        }
    }
}
