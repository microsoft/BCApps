// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Setup;

page 5616 "FA Subclasses"
{
    AdditionalSearchTerms = 'fixed asset subclasses buildings vehicles';
    ApplicationArea = FixedAssets;
    Caption = 'FA Subclasses';
    PageType = List;
    AboutTitle = 'About FA Subclasses';
    AboutText = 'Create and manage fixed asset subclass codes to organize assets into specific categories, such as buildings, vehicles, furniture, or machinery, under top-level fixed asset classes.';
    SourceTable = "FA Subclass";
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
                    ApplicationArea = FixedAssets;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = FixedAssets;
                }
                field("FA Class Code"; Rec."FA Class Code")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Default FA Posting Group"; Rec."Default FA Posting Group")
                {
                    ApplicationArea = FixedAssets;
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

