// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Depreciation;

page 5663 "Depreciation Table List"
{
    ApplicationArea = FixedAssets;
    Caption = 'Depreciation Tables';
    CardPageID = "Depreciation Table Card";
    Editable = false;
    PageType = List;
    SourceTable = "Depreciation Table Header";
    UsageCategory = Administration;
    AboutTitle = 'About Depreciation Table List';
    AboutText = 'Here you overview all registered depreciation tables that you use in the Fixed Asset card to calculate the depreciation.';

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
                field(Description; Rec.Description)
                {
                    ApplicationArea = FixedAssets;
                }
                field("Period Length"; Rec."Period Length")
                {
                    ApplicationArea = FixedAssets;
                }
                field("Total No. of Units"; Rec."Total No. of Units")
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

