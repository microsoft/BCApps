// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

using System.Globalization;

page 580 "Dimension Translations"
{
    Caption = 'Dimension Translations';
    DataCaptionFields = "Code";
    PageType = List;
    SourceTable = "Dimension Translation";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Language ID"; Rec."Language ID")
                {
                    ApplicationArea = Dimensions;
                    LookupPageID = "Windows Languages";
                    ToolTip = 'Specifies a language code.';
                }
                field("Language Name"; Rec."Language Name")
                {
                    ApplicationArea = Dimensions;
                    DrillDown = false;
                    Editable = false;
                    ToolTip = 'Specifies the name of the language.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the name of the dimension code.';
                }
                field("Code Caption"; Rec."Code Caption")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the name of the dimension code as you want it to appear as a field name after the Language ID code is selected.';
                }
                field("Filter Caption"; Rec."Filter Caption")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the dimension filter caption.';
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

