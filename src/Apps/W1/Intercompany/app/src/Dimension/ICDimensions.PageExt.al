// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

using Microsoft.Intercompany.GLAccount;

/// <summary>
/// Extends the Dimensions page with Intercompany-specific functionality.
/// Adds field and actions for mapping dimensions to intercompany dimensions.
/// </summary>
pageextension 8401 "IC Dimensions" extends Dimensions
{
    layout
    {
        addafter("Blocked")
        {
            field("Map-to IC Dimension Code"; Rec."Map-to IC Dimension Code")
            {
                ApplicationArea = Dimensions;
                Visible = false;
                ToolTip = 'Specifies which intercompany dimension corresponds to the dimension on the line. When you enter a dimension code on an intercompany sales or purchase line, the program will put the corresponding intercompany dimension code on the line that is sent to your intercompany partner.';
            }
        }
    }

    actions
    {
        addlast(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(MapToICDimWithSameCode)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Map to IC Dim. with Same Code';
                    Image = MapDimensions;
                    ToolTip = 'Specify which intercompany dimension corresponds to the dimension on the line. When you enter a dimension code on an intercompany sales or purchase line, the program will put the corresponding intercompany dimension code on the line that is sent to your intercompany partner.';

                    trigger OnAction()
                    var
                        Dimension: Record Dimension;
                        ICMapping: Codeunit "IC Mapping";
                    begin
                        CurrPage.SetSelectionFilter(Dimension);
                        if Dimension.Find('-') and Confirm(AreYouSureYouWantToMapTheSelectedLinesQst) then
                            repeat
                                ICMapping.MapOutgoingICDimensions(Dimension);
                            until Dimension.Next() = 0;
                    end;
                }
            }
        }
    }

    var
        AreYouSureYouWantToMapTheSelectedLinesQst: Label 'Are you sure you want to map the selected lines?';
}
