// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

page 6502 "Item Tracking Codes"
{
    AdditionalSearchTerms = 'serial number codes,lot number  codes,defect  codes';
    ApplicationArea = ItemTracking;
    Caption = 'Item Tracking Codes';
    CardPageID = "Item Tracking Code Card";
    Editable = false;
    PageType = List;
    SourceTable = "Item Tracking Code";
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
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the code of the record.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies a description of the item tracking code.';
                }
                field("SN Specific Tracking"; Rec."SN Specific Tracking")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies that when handling an outbound unit of the item in question, you must always specify which existing serial number to handle.';
                }
                field("Lot Specific Tracking"; Rec."Lot Specific Tracking")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies that when handling an outbound unit, always specify which existing lot number to handle.';
                }
                field("Package Specific Tracking"; Rec."Package Specific Tracking")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies that when handling an outbound unit, always specify which existing package number to handle.';
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

    trigger OnOpenPage()
    begin
    end;
}

