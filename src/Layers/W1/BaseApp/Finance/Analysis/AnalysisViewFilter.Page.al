// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

/// <summary>
/// Manages filter criteria for analysis views to restrict data included in analysis view updates.
/// Enables configuration of dimension filters and other criteria applied during analysis view processing.
/// </summary>
/// <remarks>
/// Used to define filters that limit which G/L entries and budget entries are included in analysis view calculations.
/// Supports dimension-based filtering and integration with analysis view update processes.
/// </remarks>
page 557 "Analysis View Filter"
{
    Caption = 'Analysis View Filter';
    DataCaptionFields = "Analysis View Code";
    PageType = List;
    SourceTable = "Analysis View Filter";

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
                field("Dimension Value Filter"; Rec."Dimension Value Filter")
                {
                    ApplicationArea = Dimensions;
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

