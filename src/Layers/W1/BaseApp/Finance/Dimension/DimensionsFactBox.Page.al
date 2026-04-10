// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

/// <summary>
/// FactBox control displaying default dimensions and dimension values for master records.
/// Provides read-only view of dimension configuration in a compact FactBox format for integration with other pages.
/// </summary>
/// <remarks>
/// Used as a FactBox on various master record pages to show associated default dimensions without requiring navigation.
/// Displays dimension codes and values in a repeater control optimized for space-efficient viewing.
/// </remarks>
page 9083 "Dimensions FactBox"
{
    Caption = 'Dimensions';
    Editable = false;
    PageType = ListPart;
    SourceTable = "Default Dimension";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Dimension Code"; Rec."Dimension Code")
                {
                    ApplicationArea = Dimensions;
                }
                field("Dimension Value Code"; Rec."Dimension Value Code")
                {
                    ApplicationArea = Dimensions;
                }
                field("Value Posting"; Rec."Value Posting")
                {
                    ApplicationArea = Dimensions;
                }
            }
        }
    }

    actions
    {
    }
}

