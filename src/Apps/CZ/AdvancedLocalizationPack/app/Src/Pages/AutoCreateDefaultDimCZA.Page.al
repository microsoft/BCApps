// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

page 31292 "Auto. Create Default Dim. CZA"
{
    Caption = 'Auto. Create Default Dimensions';
    PageType = List;
    ApplicationArea = Dimensions;
    UsageCategory = Administration;
    SourceTable = "Auto. Create Default Dim. CZA";
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Table ID"; Rec."Table ID")
                {
                    ToolTip = 'Specifies the table that the automatic dimension creation applies to.';
                }
                field("Table Caption"; Rec."Table Caption")
                {
                    ToolTip = 'Specifies the caption of the table that the automatic dimension creation applies to.';
                }
                field("Dimension Code"; Rec."Dimension Code")
                {
                    ToolTip = 'Specifies the dimension code that is created automatically.';
                }
                field("Dim. Description Field ID"; Rec."Dim. Description Field ID")
                {
                    ToolTip = 'Specifies the ID of the field on the master table that provides the dimension value description.';
                }
                field("Dim. Description Fld. Name"; Rec."Dim. Description Fld. Name")
                {
                    ToolTip = 'Specifies the name of the field on the master table that provides the dimension value description.';
                    Visible = false;
                    DrillDown = false;
                }
                field("Dim. Description Update"; Rec."Dim. Description Update")
                {
                    ToolTip = 'Specifies the rule for updating the dimension value description.';
                }
                field("Dim. Description Format"; Rec."Dim. Description Format")
                {
                    ToolTip = 'Specifies a description format for the dimension value.';
                }
                field("Auto. Create Value Posting"; Rec."Auto. Create Value Posting")
                {
                    ToolTip = 'Specifies the value posting set on automatically created default dimensions.';
                }
                field("Not Create Default Dimension"; Rec."Not Create Default Dimension")
                {
                    Visible = false;
                    ToolTip = 'Specifies whether to skip creating a default dimension when the record is processed.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(UpdateAutomaticDefaultDimensions)
            {
                ApplicationArea = Dimensions;
                Caption = 'Update automatic default dimensions';
                ToolTip = 'Initialize default dimensions and dimension values for existing master records based on the selected configuration.';
                Image = MapDimensions;

                trigger OnAction()
                var
                    SelectedAutoCreateDefaultDim: Record "Auto. Create Default Dim. CZA";
                    DimensionAutoCreateMgt: Codeunit "Dimension Auto.Create Mgt. CZA";
                begin
                    CurrPage.SetSelectionFilter(SelectedAutoCreateDefaultDim);
                    DimensionAutoCreateMgt.UpdateAutomaticDimValues(SelectedAutoCreateDefaultDim);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(UpdateAutomaticDefaultDimensions_Promoted; UpdateAutomaticDefaultDimensions)
                {
                }
            }
        }
    }
}
