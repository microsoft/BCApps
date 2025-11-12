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
                    ToolTip = 'Specifies the area of the customer or vendor, for the purpose of reporting to INTRASTAT.';
                }
                field("Field Type"; Rec."Field Type")
                {
                    ApplicationArea = ADCS;
                    ToolTip = 'Specifies the type of data that is defined in the miniform line.';
                }
                field("Table No."; Rec."Table No.")
                {
                    ApplicationArea = ADCS;
                    ToolTip = 'Specifies the number of the table in the program from which the data comes or in which it is entered.';
                }
                field("Field No."; Rec."Field No.")
                {
                    ApplicationArea = ADCS;
                    ToolTip = 'Specifies the number of the field from which the data comes or in which the data is entered.';
                }
                field("Field Length"; Rec."Field Length")
                {
                    ApplicationArea = ADCS;
                    ToolTip = 'Specifies the maximum length of the field value. ';
                }
                field(Text; Rec.Text)
                {
                    ApplicationArea = ADCS;
                    ToolTip = 'Specifies text if the field type is Text.';
                }
                field("Call Miniform"; Rec."Call Miniform")
                {
                    ApplicationArea = ADCS;
                    ToolTip = 'Specifies which miniform will be called when the user on the handheld selects the choice on the line.';
                }
            }
        }
    }

    actions
    {
    }
}

