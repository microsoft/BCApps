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
                    ToolTip = 'Specifies the code for the depreciation book to which the line will be posted if you have selected Fixed Asset in the Type field for this line.';
                    Visible = false;
                }
                field("FA Posting Type"; Rec."FA Posting Type")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the posting type, if Account Type field contains Fixed Asset.';
                }
                field("Part of Book Value"; Rec."Part of Book Value")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies that entries posted with the FA Posting Type field will be part of the book value.';
                }
                field("Part of Depreciable Basis"; Rec."Part of Depreciable Basis")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies that entries posted with the FA Posting Type field will be part of the depreciable basis.';
                }
                field("Include in Depr. Calculation"; Rec."Include in Depr. Calculation")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies that entries posted with the FA Posting Type field must be included in periodic depreciation calculations.';
                }
                field("Include in Gain/Loss Calc."; Rec."Include in Gain/Loss Calc.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies that entries posted with the FA Posting Type field must be included in the calculation of gain or loss for a sold asset.';
                }
                field("Reverse before Disposal"; Rec."Reverse before Disposal")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies that entries posted with the FA Posting Type field must be reversed (that is, set to zero) before disposal.';
                }
                field("Acquisition Type"; Rec."Acquisition Type")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies that entries posted with the FA Posting Type must be part of the total acquisition for the fixed asset in the Fixed Asset - Book Value 01 report.';
                }
                field("Depreciation Type"; Rec."Depreciation Type")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies that entries posted with the FA Posting Type field will be regarded as part of the total depreciation for the fixed asset.';
                }
                field(Sign; Rec.Sign)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies whether the type in the FA Posting Type field should be a debit or a credit.';
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

