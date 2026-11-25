// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Transfer;

pageextension 20582 "Subc. Pstd. Trans. Shpt. Sub." extends "Posted Transfer Shpt. Subform"
{
    layout
    {
        addlast(Control1)
        {
            field(SubcWIPStatus; WIPStatus)
            {
                ApplicationArea = Subcontracting;
                Caption = 'WIP Status';
                Editable = false;
                ToolTip = 'Specifies the processing state carried by the posted WIP movement.';
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Clear(WIPStatus);
        if Rec."Subc. State Tracked" and Rec."Transfer WIP Item" then
            WIPStatus := Format(Rec."Subc. WIP State");
    end;

    var
        WIPStatus: Text;
}
