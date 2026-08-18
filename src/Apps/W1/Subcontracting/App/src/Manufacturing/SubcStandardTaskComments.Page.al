// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

page 20575 "Subc. Standard Task Comments"
{
    ApplicationArea = Subcontracting;
    AutoSplitKey = true;
    Caption = 'Subcontracting Standard Task Comments';
    DataCaptionFields = "Standard Task Code";
    LinksAllowed = false;
    MultipleNewLines = true;
    PageType = List;
    SourceTable = "Subc. Standard Task Comment";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Standard Task Code"; Rec."Standard Task Code")
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