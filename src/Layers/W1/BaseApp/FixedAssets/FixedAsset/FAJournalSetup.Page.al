// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Journal;

page 5609 "FA Journal Setup"
{
    Caption = 'FA Journal Setup';
    DataCaptionFields = "Depreciation Book Code";
    PageType = List;
    SourceTable = "FA Journal Setup";
    AboutTitle = 'About FA Journal Setup';
    AboutText = 'With the **FA Journal Setup** you can manage the user ID-wise batch and template configuration with this the user can use the assigned batch and template only to perform the entries.';

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Depreciation Book Code"; Rec."Depreciation Book Code")
                {
                    ApplicationArea = FixedAssets;
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = FixedAssets;
                }
                field("FA Jnl. Template Name"; Rec."FA Jnl. Template Name")
                {
                    ApplicationArea = FixedAssets;
                }
                field("FA Jnl. Batch Name"; Rec."FA Jnl. Batch Name")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Gen. Jnl. Template Name"; Rec."Gen. Jnl. Template Name")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Gen. Jnl. Batch Name"; Rec."Gen. Jnl. Batch Name")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Insurance Jnl. Template Name"; Rec."Insurance Jnl. Template Name")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Insurance Jnl. Batch Name"; Rec."Insurance Jnl. Batch Name")
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

