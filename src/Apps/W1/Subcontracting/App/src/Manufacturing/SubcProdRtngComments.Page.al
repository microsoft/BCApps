// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

page 20577 "Subc. Prod. Rtng. Comments"
{
    ApplicationArea = Subcontracting;
    AutoSplitKey = true;
    Caption = 'Subcontracting Production Order Routing Comments';
    DataCaptionFields = Status, "Prod. Order No.", "Routing No.", "Operation No.";
    LinksAllowed = false;
    MultipleNewLines = true;
    PageType = List;
    SourceTable = "Subc. Prod. Rtng. Comment";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Status; Rec.Status)
                {
                    Visible = false;
                }
                field("Prod. Order No."; Rec."Prod. Order No.")
                {
                    Visible = false;
                }
                field("Routing Reference No."; Rec."Routing Reference No.")
                {
                    Visible = false;
                }
                field("Routing No."; Rec."Routing No.")
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