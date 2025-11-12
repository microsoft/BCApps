// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension.Correction;

page 2580 "Dim Correction Blocked Setup"
{
    PageType = ListPart;
    SourceTable = "Dim Correction Blocked Setup";
    Caption = 'Dimensions Blocked for Correction';

    layout
    {
        area(Content)
        {
            repeater(BlockedDimensions)
            {
                field(DimensionCode; Rec."Dimension Code")
                {
                    ApplicationArea = All;
                    Caption = 'Dimension Code';
                    ToolTip = 'Specifies the dimension that cannot be used for corrections.';
                }
            }
        }
    }
}
