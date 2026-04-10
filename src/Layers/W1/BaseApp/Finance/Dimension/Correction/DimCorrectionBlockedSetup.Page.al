// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension.Correction;

/// <summary>
/// List part page for managing dimensions that are blocked from dimension correction. Displays and allows editing of dimensions that cannot be modified through dimension correction operations.
/// </summary>
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
                }
            }
        }
    }
}
