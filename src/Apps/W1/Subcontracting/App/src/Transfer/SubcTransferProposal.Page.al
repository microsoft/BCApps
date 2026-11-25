// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

page 20582 "Subc. Transfer Proposal"
{
    Caption = 'Subcontracting Transfer Proposal';
    PageType = List;
    SourceTable = "Subc. Transfer Proposal";
    SourceTableTemporary = true;
    InsertAllowed = false;
    DeleteAllowed = false;
    ApplicationArea = Subcontracting;
    layout
    {
        area(Content)
        {
            repeater(Quantities)
            {
                field("Item No."; Rec."Item No.") { Editable = false; ToolTip = 'Specifies the item to transfer.'; }
                field("Variant Code"; Rec."Variant Code") { Editable = false; ToolTip = 'Specifies the variant to transfer.'; }
                field("Production Order No."; Rec."Production Order No.") { Editable = false; ToolTip = 'Specifies the production order.'; }
                field("Production Order Line No."; Rec."Production Order Line No.") { Editable = false; ToolTip = 'Specifies the production order line.'; }
                field("Operation No."; Rec."Operation No.") { Editable = false; ToolTip = 'Specifies the routing operation.'; }
                field("WIP Status"; Rec."WIP Status") { Editable = false; ToolTip = 'Specifies whether the WIP is unprocessed or processed. This field is blank for components and legacy WIP.'; }
                field("WIP Cohort"; Rec."WIP Cohort") { Editable = false; ToolTip = 'Specifies whether this WIP uses legacy custody or processing-state tracking.'; }
                field("Unit of Measure Code"; Rec."Unit of Measure Code") { Editable = false; ToolTip = 'Specifies the unit used for all quantities on this row.'; }
                field("Available Quantity"; Rec."Available Quantity") { Editable = false; ToolTip = 'Specifies the available quantity after open transfer allocations.'; }
                field("Quantity on Transfer"; Rec."Quantity on Transfer") { Editable = false; ToolTip = 'Specifies the unshipped quantity already assigned to transfers.'; }
                field("Quantity to Transfer"; Rec."Quantity to Transfer") { ToolTip = 'Specifies the quantity to transfer, up to the available quantity.'; }
            }
        }
    }

    internal procedure SetRows(var Rows: Record "Subc. Transfer Proposal" temporary)
    begin
        Rec.Copy(Rows, true);
    end;
}
