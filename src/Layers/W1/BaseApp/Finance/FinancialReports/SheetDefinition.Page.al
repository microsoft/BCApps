// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

page 8363 "Sheet Definition"
{
    ApplicationArea = Basic, Suite;
    AnalysisModeEnabled = false;
    AutoSplitKey = true;
    Caption = 'Financial Report Sheet Definition';
    MultipleNewLines = true;
    PageType = Worksheet;
    SourceTable = "Sheet Definition Line";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Description; Description)
            {
                Caption = 'Description';
                ToolTip = 'Specifies the description of the sheet definition. The description is not shown on the final report but is used to provide more context when using the definition.';

                trigger OnValidate()
                var
                    SheetDefName: Record "Sheet Definition Name";
                begin
                    SheetDefName.Get(DefinitionName);
                    SheetDefName.Validate(Description, Description);
                    SheetDefName.Modify();
                end;
            }
            field(InternalDescription; InternalDescription)
            {
                Caption = 'Internal Description';
                MultiLine = true;
                ToolTip = 'Specifies the internal description of the sheet definition. The internal description is not shown on the final report but is used to provide more context when using the definition.';

                trigger OnValidate()
                var
                    SheetDefName: Record "Sheet Definition Name";
                begin
                    SheetDefName.Get(DefinitionName);
                    SheetDefName.Validate("Internal Description", InternalDescription);
                    SheetDefName.Modify();
                end;
            }
            field(SheetType; SheetTypeText)
            {
                Caption = 'Sheet Type';
                ToolTip = 'Specifies how the financial report sheets will be totaled by. If you select Custom, then you can set up a combination of fields to total by on a sheet-by-sheet basis. Otherwise, sheets are automatically created and totaled by each dimension value or business unit.';

                trigger OnLookup(var Text: Text): Boolean
                var
                    SheetDefName: Record "Sheet Definition Name";
                begin
                    SheetDefName.Get(DefinitionName);
                    exit(SheetDefName.LookupSheetSheetType(Text));
                end;

                trigger OnValidate()
                var
                    SheetDefName: Record "Sheet Definition Name";
                begin
                    SheetDefName.Get(DefinitionName);
                    SheetDefName.Validate("Sheet Type", SheetDefName.TextToSheetType(SheetTypeText));
                    SheetType := SheetDefName."Sheet Type";
                    SheetDefName.Modify();
                    CurrPage.Update(false);
                end;
            }
            repeater(Group)
            {
                Enabled = SheetType = SheetType::Custom;
                field("Sheet Header"; Rec."Sheet Header")
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
        SheetDefName: Record "Sheet Definition Name";
    begin
        if Rec.GetFilter(Name) <> '' then begin
            DefinitionName := Rec.GetRangeMin(Name);
            CurrPage.Caption(DefinitionName);
            SheetDefName.Get(DefinitionName);
            Description := SheetDefName.Description;
            InternalDescription := SheetDefName."Internal Description";
            SheetType := SheetDefName."Sheet Type";
            SheetTypeText := SheetDefName.SheetTypeToText(SheetType);
        end;
    end;

    var
        DefinitionName: Code[10];
        Description: Text[100];
        InternalDescription: Text[250];
        SheetType: Enum "Sheet Type";
        SheetTypeText: Text;
}