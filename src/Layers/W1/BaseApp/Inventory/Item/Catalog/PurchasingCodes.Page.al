// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item.Catalog;

page 5727 "Purchasing Codes"
{
    ApplicationArea = Suite;
    Caption = 'Purchasing Codes';
    PageType = List;
    SourceTable = Purchasing;
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Suite;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Suite;
                }
                field("Drop Shipment"; Rec."Drop Shipment")
                {
                    ApplicationArea = Suite;
                }
                field("Special Order"; Rec."Special Order")
                {
                    ApplicationArea = Suite;
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
}

