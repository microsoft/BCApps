// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Journal;

using System.Reflection;

page 5631 "FA Journal Template List"
{
    Caption = 'FA Journal Template List';
    Editable = false;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "FA Journal Template";
    AboutTitle = 'About FA Journal Template List';
    AboutText = 'With the **FA Journal Template List** you can review all the templates created related to the fixed assets process.';

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
                field(Recurring; Rec.Recurring)
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;
                }
                field("Source Code"; Rec."Source Code")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = FixedAssets;
                    Visible = false;
                }
                field("Page ID"; Rec."Page ID")
                {
                    ApplicationArea = FixedAssets;
                    LookupPageID = Objects;
                    Visible = false;
                }
                field("Test Report ID"; Rec."Test Report ID")
                {
                    ApplicationArea = FixedAssets;
                    LookupPageID = Objects;
                    Visible = false;
                }
                field("Posting Report ID"; Rec."Posting Report ID")
                {
                    ApplicationArea = FixedAssets;
                    LookupPageID = Objects;
                    Visible = false;
                }
                field("Force Posting Report"; Rec."Force Posting Report")
                {
                    ApplicationArea = FixedAssets;
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

