// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Journal;

page 5638 "FA Reclass. Jnl. Template List"
{
    Caption = 'FA Reclass. Jnl. Template List';
    Editable = false;
    PageType = List;
    SourceTable = "FA Reclass. Journal Template";
    AnalysisModeEnabled = false;
    AboutTitle = 'About FA ReclassJnl Template List';
    AboutText = 'With the **FA ReclassJnl Template List** you can review all the templates created related to the Fixed Asset Reclassification process.';

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Rec.Name)
                {
                    ApplicationArea = FixedAssets;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = FixedAssets;
                }
                field("Page ID"; Rec."Page ID")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;
                }
                field("Page Caption"; Rec."Page Caption")
                {
                    ApplicationArea = FixedAssets;
                    DrillDown = false;
                    Visible = false;
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

