// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Posting;

page 5608 "FA Posting Type Setup"
{
    Caption = 'FA Posting Type Setup';
    DataCaptionFields = "Depreciation Book Code";
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "FA Posting Type Setup";
    AboutTitle = 'About FA Posting Type Setup';
    AboutText = 'With the **FA Posting Type Setup**, you can define how to handle the Write-Down, Appreciation, Custom 1, and Custom 2 posting types that you use when posting to fixed assets. You can define individual definitions for each depreciation book you set up.';

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
                    Visible = false;
                }
                field("FA Posting Type"; Rec."FA Posting Type")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Part of Book Value"; Rec."Part of Book Value")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Part of Depreciable Basis"; Rec."Part of Depreciable Basis")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Include in Depr. Calculation"; Rec."Include in Depr. Calculation")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Include in Gain/Loss Calc."; Rec."Include in Gain/Loss Calc.")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Reverse before Disposal"; Rec."Reverse before Disposal")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Acquisition Type"; Rec."Acquisition Type")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Depreciation Type"; Rec."Depreciation Type")
                {
                    ApplicationArea = FixedAssets;
                }
                field(Sign; Rec.Sign)
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

