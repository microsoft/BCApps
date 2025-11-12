// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Dimension;

using Microsoft.Finance.Dimension;
using Microsoft.Intercompany.GLAccount;

page 656 "IC Mapping Dimension"
{
    PageType = ListPlus;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Intercompany Dimension Mapping';

    layout
    {
        area(Content)
        {
            group(General)
            {
                ShowCaption = false;
                part(IntercompanyDimensions; "IC Mapping Dimension Incoming")
                {
                    Caption = 'Intercompany Dimensions';
                    ApplicationArea = All;
                }
                part(CompanyDimensions; "IC Mapping Dimension Outgoing")
                {
                    Caption = 'Current Company Dimensions';
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
                action(MapICDimensionsWithSameCode)
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Map dimensions with same code';
                    Image = MapDimensions;
                    ToolTip = 'Map the selected dimensions with the same code. Dimension values grouped within dimensions will also be mapped. Only dimension values with the same code, dimension code and dimension type (e.g. Heading) are mapped.';

                    trigger OnAction()
                    var
                        ICDimension: Record "IC Dimension";
                        Dimension: Record Dimension;
                        ICMapping: Codeunit "IC Mapping";
                        UserSelection: Integer;
                    begin
                        UserSelection := StrMenu(SelectionOptionsQst, 0, MapDimensionsInstructionQst);
                        case UserSelection of
                            1:
                                begin
                                    CurrPage.IntercompanyDimensions.Page.GetSelectedLines(ICDimension);
                                    ICMapping.MapICDimensions(ICDimension);
                                end;
                            2:
                                begin
                                    CurrPage.CompanyDimensions.Page.GetSelectedLines(Dimension);
                                    ICMapping.MapCompanyDimensions(Dimension);
                                end;
                            3:
                                begin
                                    CurrPage.IntercompanyDimensions.Page.GetSelectedLines(ICDimension);
                                    CurrPage.CompanyDimensions.Page.GetSelectedLines(Dimension);
                                    ICMapping.MapICDimensions(ICDimension);
                                    ICMapping.MapCompanyDimensions(Dimension);
                                end;
                        end;
                    end;
                }
                action(RemoveMappingOfICDimensions)
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Remove mapping from dimensions';
                    Image = UnLinkAccount;
                    ToolTip = 'Remove the existing dimensions mapping. This removal would also affect the mapping of the dimension values.';

                    trigger OnAction()
                    var
                        ICDimension: Record "IC Dimension";
                        Dimension: Record Dimension;
                        ICMapping: Codeunit "IC Mapping";
                        UserSelection: Integer;
                    begin
                        UserSelection := StrMenu(SelectionOptionsQst, 0, RemoveMappingInstructionQst);
                        case UserSelection of
                            1:
                                begin
                                    CurrPage.IntercompanyDimensions.Page.GetSelectedLines(ICDimension);
                                    ICMapping.RemoveICMapping(ICDimension);
                                end;
                            2:
                                begin
                                    CurrPage.CompanyDimensions.Page.GetSelectedLines(Dimension);
                                    ICMapping.RemoveCompanyMapping(Dimension);
                                end;
                            3:
                                begin
                                    CurrPage.IntercompanyDimensions.Page.GetSelectedLines(ICDimension);
                                    CurrPage.CompanyDimensions.Page.GetSelectedLines(Dimension);
                                    ICMapping.RemoveICMapping(ICDimension);
                                    ICMapping.RemoveCompanyMapping(Dimension);
                                end;
                        end;
                    end;
                }
                action(OpenDimensionValuesMapping)
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Dimension Values Mapping';
                    Image = Intercompany;
                    ToolTip = 'Open the mapping between the intercompany dimension values and the dimension values of the current company.';

                    trigger OnAction()
                    var
                        ICDimension: Record "IC Dimension";
                        Dimension: Record Dimension;
                        ICMappingDimValues: Page "IC Mapping Dim Values";
                    begin
                        CurrPage.IntercompanyDimensions.Page.GetSelectedLines(ICDimension);
                        CurrPage.CompanyDimensions.Page.GetSelectedLines(Dimension);
                        if not ICDimension.FindFirst() then
                            exit;
                        if not Dimension.FindFirst() then
                            exit;

                        ICMappingDimValues.RegisterUserSelections(ICDimension, Dimension);
                        ICMappingDimValues.Run();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';
                actionref(MapICDimensionsWithSameCode_Promoted; MapICDimensionsWithSameCode)
                {
                }
                actionref(RemoveMappingOfICDimensions_Promoted; RemoveMappingOfICDimensions)
                {
                }
                actionref(OpenDimensionValuesMapping_Promoted; OpenDimensionValuesMapping)
                {
                }
            }
        }
    }

    var
        SelectionOptionsQst: Label 'Intercompany Dimensions,Current Company Dimensions,Both';
        MapDimensionsInstructionQst: Label 'For which of the following tables do you wish to perform the mapping?';
        RemoveMappingInstructionQst: Label 'For which of the following tables do you wish to remove the mapping?';
}
