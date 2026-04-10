// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.ADCS;

page 7701 "Miniform Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Miniform Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Area"; Rec.Area)
                {
                    ApplicationArea = ADCS;
                }
                field("Field Type"; Rec."Field Type")
                {
                    ApplicationArea = ADCS;
                }
                field("Table No."; Rec."Table No.")
                {
                    ApplicationArea = ADCS;
                }
                field("Field No."; Rec."Field No.")
                {
                    ApplicationArea = ADCS;
                }
                field("Field Length"; Rec."Field Length")
                {
                    ApplicationArea = ADCS;
                    ToolTip = 'Specifies the maximum length of the field value. ';
                }
                field(Text; Rec.Text)
                {
                    ApplicationArea = ADCS;
                }
                field("Call Miniform"; Rec."Call Miniform")
                {
                    ApplicationArea = ADCS;
                }
            }
        }
    }

    actions
    {
    }
}

