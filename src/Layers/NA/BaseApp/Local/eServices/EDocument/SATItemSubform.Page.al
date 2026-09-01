// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using Microsoft.Inventory.Item;

page 27013 "SAT Item Subform"
{
    Caption = 'SAT Item Subform';
    PageType = ListPart;
    SourceTable = Item;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved item.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the involved item.';
                }
                field("SAT Item Classification"; Rec."SAT Item Classification")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the SAT classification of the involved item.';
                }
            }
        }
    }

    actions
    {
    }
}

