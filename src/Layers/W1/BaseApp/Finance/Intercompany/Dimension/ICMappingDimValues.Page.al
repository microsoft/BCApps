// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Dimension;

using Microsoft.Finance.Dimension;
using Microsoft.Intercompany.GLAccount;

page 668 "IC Mapping Dim Values"
{
    PageType = ListPlus;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Intercompany Dimension Values Mapping';

    layout
    {
        area(Content)
        {
            group(General)
            {
                ShowCaption = false;
                part(IntercompanyDimValues; "IC Mapping Dim Values Incoming")
                {
                    Caption = 'Intercompany Dimension Values';
                    ApplicationArea = All;
                }
                part(CompanyDimValues; "IC Mapping Dim Values Outgoing")
                {
                    Caption = 'Current Company Dimension Values';
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            group(Functions)
            {
                Caption = 'Functions';
                Image = "Action";
                action(MapICDimensionValuesWithSameCode)
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Map dimension values with same code';
                    Image = MapDimensions;
                    ToolTip = 'Map the selected dimensions values. Only dimension values with the same code, dimension code and dimension type (e.g. Heading) are mapped.';

                    trigger OnAction()
                    var
                        ICDimensionValues: Record "IC Dimension Value";
                        DimensionValues: Record "Dimension Value";
                        ICMapping: Codeunit "IC Mapping";
                        UserSelection: Integer;
                    begin
                        UserSelection := StrMenu(SelectionOptionsQst, 0, MapDimensionValuesInstructionQst);
                        case UserSelection of
                            1:
                                begin
                                    CurrPage.IntercompanyDimValues.Page.GetSelectedLines(ICDimensionValues);
                                    ICMapping.MapICDimensionValues(ICDimensionValues);
                                end;
                            2:
                                begin
                                    CurrPage.CompanyDimValues.Page.GetSelectedLines(DimensionValues);
                                    ICMapping.MapCompanyDimensionValues(DimensionValues);
                                end;
                            3:
                                begin
                                    CurrPage.IntercompanyDimValues.Page.GetSelectedLines(ICDimensionValues);
                                    CurrPage.CompanyDimValues.Page.GetSelectedLines(DimensionValues);
                                    ICMapping.MapICDimensionValues(ICDimensionValues);
                                    ICMapping.MapCompanyDimensionValues(DimensionValues);
                                end;
                        end;
                    end;
                }
                action(RemoveMappingOfICDimensionValues)
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Remove mapping from dimension values';
                    Image = UnLinkAccount;
                    ToolTip = 'Remove the dimension values mapping of the selected entries.';

                    trigger OnAction()
                    var
                        ICDimensionValues: Record "IC Dimension Value";
                        DimensionValues: Record "Dimension Value";
                        ICMapping: Codeunit "IC Mapping";
                        UserSelection: Integer;
                    begin
                        UserSelection := StrMenu(SelectionOptionsQst, 0, RemoveMappingInstructionQst);
                        case UserSelection of
                            1:
                                begin
                                    CurrPage.IntercompanyDimValues.Page.GetSelectedLines(ICDimensionValues);
                                    ICMapping.RemoveICMapping(ICDimensionValues);
                                end;
                            2:
                                begin
                                    CurrPage.CompanyDimValues.Page.GetSelectedLines(DimensionValues);
                                    ICMapping.RemoveCompanyMapping(DimensionValues);
                                end;
                            3:
                                begin
                                    CurrPage.IntercompanyDimValues.Page.GetSelectedLines(ICDimensionValues);
                                    CurrPage.CompanyDimValues.Page.GetSelectedLines(DimensionValues);
                                    ICMapping.RemoveICMapping(ICDimensionValues);
                                    ICMapping.RemoveCompanyMapping(DimensionValues);
                                end;
                        end;
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';
                actionref(MapICDimValuesWithSameCode_Promoted; MapICDimensionValuesWithSameCode)
                {
                }
                actionref(RemoveMappingOfICDimValues_Promoted; RemoveMappingOfICDimensionValues)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        CurrPage.IntercompanyDimValues.Page.SetDimensionFilter(ICDimensionFilter);
        CurrPage.CompanyDimValues.Page.SetDimensionFilter(DimensionFilter);
    end;

    var
        ICDimensionFilter: Record "IC Dimension";
        DimensionFilter: Record Dimension;
        SelectionOptionsQst: Label 'Intercompany Dimension Values,Current Company Dimension Values,Both';
        MapDimensionValuesInstructionQst: Label 'For which of the following tables do you wish to perform the mapping?';
        RemoveMappingInstructionQst: Label 'For which of the following tables do you wish to remove the mapping?';

    procedure RegisterUserSelections(SelectedICDimension: Record "IC Dimension"; SelectedDimension: Record Dimension)
    begin
        ICDimensionFilter := SelectedICDimension;
        DimensionFilter := SelectedDimension;
    end;
}
