// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

page 20576 "Subc. Routing Comments"
{
    ApplicationArea = Subcontracting;
    AutoSplitKey = true;
    Caption = 'Subcontracting Routing Comments';
    DataCaptionFields = "Routing No.", "Version Code", "Operation No.";
    LinksAllowed = false;
    MultipleNewLines = true;
    PageType = List;
    SourceTable = "Subc. Routing Comment Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Routing No."; Rec."Routing No.")
                {
                    Visible = false;
                }
                field("Version Code"; Rec."Version Code")
                {
                    Visible = false;
                }
                field("Operation No."; Rec."Operation No.")
                {
                    Visible = false;
                }
                field("Line No."; Rec."Line No.")
                {
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                }
                field("Description 2"; Rec."Description 2")
                {
                    Visible = false;
                }
            }
        }
    }
}