// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

page 8363 "Dimension Perspective"
{
    ApplicationArea = Basic, Suite;
    AnalysisModeEnabled = false;
    AutoSplitKey = true;
    Caption = 'Financial Report Dimension Perspective';
    MultipleNewLines = true;
    PageType = Worksheet;
    SourceTable = "Dimension Perspective Line";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Description; Description)
            {
                Caption = 'Description';
                ToolTip = 'Specifies the description of the dimension perspective. The description is not shown on the final report but is used to provide more context when using the definition.';

                trigger OnValidate()
                var
                    DimPerspectiveName: Record "Dimension Perspective Name";
                begin
                    DimPerspectiveName.Get(DefinitionName);
                    DimPerspectiveName.Validate(Description, Description);
                    DimPerspectiveName.Modify();
                end;
            }
            field(InternalDescription; InternalDescription)
            {
                Caption = 'Internal Description';
                MultiLine = true;
                ToolTip = 'Specifies the internal description of the dimension perspective. The internal description is not shown on the final report but is used to provide more context when using the definition.';

                trigger OnValidate()
                var
                    DimPerspectiveName: Record "Dimension Perspective Name";
                begin
                    DimPerspectiveName.Get(DefinitionName);
                    DimPerspectiveName.Validate("Internal Description", InternalDescription);
                    DimPerspectiveName.Modify();
                end;
            }
            field(PerspectiveType; PerspectiveTypeText)
            {
                Caption = 'Perspective Type';
                ToolTip = 'Specifies how the financial report dimension perspectives will be totaled by. If you select Custom, then you can set up a combination of fields to total by on a dimension-by-dimension basis. Otherwise, perspectives are automatically created and totaled by each dimension value or business unit.';

                trigger OnLookup(var Text: Text): Boolean
                var
                    DimPerspectiveName: Record "Dimension Perspective Name";
                begin
                    DimPerspectiveName.Get(DefinitionName);
                    exit(DimPerspectiveName.LookupPerspectiveType(Text));
                end;

                trigger OnValidate()
                var
                    DimPerspectiveName: Record "Dimension Perspective Name";
                begin
                    DimPerspectiveName.Get(DefinitionName);
                    DimPerspectiveName.Validate("Perspective Type", DimPerspectiveName.TextToPerspectiveType(PerspectiveTypeText));
                    PerspectiveType := DimPerspectiveName."Perspective Type";
                    DimPerspectiveName.Modify();
                    CurrPage.Update(false);
                end;
            }
            repeater(Group)
            {
                Enabled = PerspectiveType = PerspectiveType::Custom;
                field("Perspective Header"; Rec."Perspective Header")
                {
                    ShowMandatory = true;
                }
                field("Dimension 1 Totaling"; Rec."Dimension 1 Totaling")
                {
                    ApplicationArea = Dimensions;
                }
                field("Dimension 2 Totaling"; Rec."Dimension 2 Totaling")
                {
                    ApplicationArea = Dimensions;
                }
                field("Dimension 3 Totaling"; Rec."Dimension 3 Totaling")
                {
                    ApplicationArea = Dimensions;
                }
                field("Dimension 4 Totaling"; Rec."Dimension 4 Totaling")
                {
                    ApplicationArea = Dimensions;
                }
                field("Dimension 5 Totaling"; Rec."Dimension 5 Totaling")
                {
                    ApplicationArea = Dimensions;
                }
                field("Dimension 6 Totaling"; Rec."Dimension 6 Totaling")
                {
                    ApplicationArea = Dimensions;
                }
                field("Dimension 7 Totaling"; Rec."Dimension 7 Totaling")
                {
                    ApplicationArea = Dimensions;
                }
                field("Dimension 8 Totaling"; Rec."Dimension 8 Totaling")
                {
                    ApplicationArea = Dimensions;
                }
                field("Business Unit Totaling"; Rec."Business Unit Totaling")
                {
                    ApplicationArea = Suite;
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        DimPerspectiveName: Record "Dimension Perspective Name";
    begin
        if Rec.GetFilter(Name) <> '' then begin
            DefinitionName := Rec.GetRangeMin(Name);
            CurrPage.Caption(DefinitionName);
            DimPerspectiveName.Get(DefinitionName);
            Description := DimPerspectiveName.Description;
            InternalDescription := DimPerspectiveName."Internal Description";
            PerspectiveType := DimPerspectiveName."Perspective Type";
            PerspectiveTypeText := DimPerspectiveName.PerspectiveTypeToText(PerspectiveType);
        end;
    end;

    var
        DefinitionName: Code[10];
        Description: Text[100];
        InternalDescription: Text[250];
        PerspectiveType: Enum "Dimension Perspective Type";
        PerspectiveTypeText: Text;
}