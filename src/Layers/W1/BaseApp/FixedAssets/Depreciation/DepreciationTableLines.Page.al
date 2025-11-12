// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Depreciation;

page 5660 "Depreciation Table Lines"
{
    Caption = 'Lines';
    DelayedInsert = true;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Depreciation Table Line";
    AboutTitle = 'About Depreciation Table Line';
    AboutText = 'In the **Depreciation Table Line**, you specify information about the number of depreciation periods, depreciation percentage to apply to the period and the no. of units produced by the asset during the period.';

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Period No."; Rec."Period No.")
                {
                    ApplicationArea = FixedAssets;
                    AboutTitle = 'Enter Period No.';
                    AboutText = 'Specifies the number of the depreciation period.';
                    ToolTip = 'Specifies the number of the depreciation period that this line applies to.';
                }
                field("Period Depreciation %"; Rec."Period Depreciation %")
                {
                    ApplicationArea = FixedAssets;
                    AboutTitle = 'Enter Period Depreciation %';
                    AboutText = 'Specifies the depreciation percentage to apply to the period for this line.';
                    ToolTip = 'Specifies the depreciation percentage to apply to the period for this line.';
                }
                field("No. of Units in Period"; Rec."No. of Units in Period")
                {
                    ApplicationArea = FixedAssets;
                    AboutTitle = 'Enter No. of Units in Period';
                    AboutText = 'Specifies the no. of units produced by the asset during the period to calculate the depreciation.';
                    ToolTip = 'Specifies the units produced by the asset this depreciation table applies to, during the period when this line applies.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.NewRecord();
    end;
}

