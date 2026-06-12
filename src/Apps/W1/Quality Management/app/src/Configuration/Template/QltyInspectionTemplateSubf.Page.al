// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.Template;

using Microsoft.QualityManagement.Configuration.Result;
using Microsoft.QualityManagement.Document;

/// <summary>
/// This subform is used on the template card to help configure which tests should be defined on a template.
/// </summary>
page 20403 "Qlty. Inspection Template Subf"
{
    AutoSplitKey = true;
    Caption = 'Quality Inspection Template Subform';
    DelayedInsert = true;
    LinksAllowed = false;
    PageType = ListPart;
    ShowFilter = false;
    SourceTable = "Qlty. Inspection Template Line";
    ApplicationArea = QualityManagement;

    layout
    {
        area(Content)
        {
            repeater(GroupTemplateLines)
            {
                ShowCaption = false;

                field("Line No."; Rec."Line No.")
                {
                    StyleExpr = RowStyleText;
                    Editable = false;
                    Visible = false;
                }
                field("Test Code"; Rec."Test Code")
                {
                    StyleExpr = RowStyleText;
                    AboutTitle = 'Test Code';
                    AboutText = 'Here you can add tests that should be performed during inspections.';

                    trigger OnValidate()
                    begin
                        Rec.EnsureResultsExist(Rec."Test Code" <> xRec."Test Code");
                        UpdateRowData();
                        CurrPage.Update(true);
                    end;
                }
                field(Description; Rec.Description)
                {
                    StyleExpr = RowStyleText;
                }
                field("Test Value Type"; Rec."Test Value Type")
                {
                    Visible = false;
                    StyleExpr = RowStyleText;
                }
                field("Allowable Values"; Rec."Allowable Values")
                {
                    StyleExpr = RowStyleText;
                }
                field("Default Value"; Rec."Default Value")
                {
                    StyleExpr = RowStyleText;
                }
                field("Expression Formula"; Rec."Expression Formula")
                {
                    StyleExpr = RowStyleText;
                    Editable = IsExpressionFormulaEditable;
                    Visible = false;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    StyleExpr = RowStyleText;
                }
                field(Field1; MatrixArrayConditionCellData[1])
                {
                    CaptionClass = '3,' + StrSubstNo(ConditionLbl, MatrixArrayCaptionSet[1]);
                    ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 1.';
                    Visible = Visible1;
                    Editable = Editable1;

                    trigger OnValidate()
                    begin
                        UpdateMatrixDataCondition(1);
                    end;

                    trigger OnAssistEdit()
                    begin
                        if not Editable1 then
                            exit;
                        AssistEditCondition(1);
                    end;
                }
                field(Field1_Desc; MatrixArrayConditionDescriptionCellData[1])
                {
                    CaptionClass = '3,' + StrSubstNo(DescriptionLbl, MatrixArrayCaptionSet[1]);
                    ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 1.';
                    Visible = Visible1;
                    Editable = Editable1;

                    trigger OnValidate()
                    begin
                        UpdateMatrixDataConditionDescription(1);
                    end;

                    trigger OnAssistEdit()
                    begin
                        if not Editable1 then
                            exit;

                        AssistEditConditionDescription(1);
                    end;
                }
                field(Field2; MatrixArrayConditionCellData[2])
                {
                    CaptionClass = '3,' + StrSubstNo(ConditionLbl, MatrixArrayCaptionSet[2]);
                    ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 2.';
                    Visible = Visible2;
                    Editable = Editable2;

                    trigger OnValidate()
                    begin
                        UpdateMatrixDataCondition(2);
                    end;

                    trigger OnAssistEdit()
                    begin
                        if not Editable2 then
                            exit;

                        AssistEditCondition(2);
                    end;
                }
                field(Field2_Desc; MatrixArrayConditionDescriptionCellData[2])
                {
                    CaptionClass = '3,' + StrSubstNo(DescriptionLbl, MatrixArrayCaptionSet[2]);
                    ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 2.';
                    Visible = Visible2;
                    Editable = Editable2;

                    trigger OnValidate()
                    begin
                        UpdateMatrixDataConditionDescription(2);
                    end;

                    trigger OnAssistEdit()
                    begin
                        if not Editable2 then
                            exit;

                        AssistEditConditionDescription(2);
                    end;
                }
                field(Field3; MatrixArrayConditionCellData[3])
                {
                    CaptionClass = '3,' + StrSubstNo(ConditionLbl, MatrixArrayCaptionSet[3]);
                    ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 3.';
                    Visible = Visible3;
                    Editable = Editable3;

                    trigger OnValidate()
                    begin
                        UpdateMatrixDataCondition(3);
                    end;

                    trigger OnAssistEdit()
                    begin
                        if not Editable3 then
                            exit;

                        AssistEditCondition(3);
                    end;
                }
                field(Field3_Desc; MatrixArrayConditionDescriptionCellData[3])
                {
                    CaptionClass = '3,' + StrSubstNo(DescriptionLbl, MatrixArrayCaptionSet[3]);
                    ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 3.';
                    Visible = Visible3;
                    Editable = Editable3;

                    trigger OnValidate()
                    begin
                        UpdateMatrixDataConditionDescription(3);
                    end;

                    trigger OnAssistEdit()
                    begin
                        if not Editable3 then
                            exit;

                        AssistEditConditionDescription(3);
                    end;
                }
                field(Field4; MatrixArrayConditionCellData[4])
                {
                    CaptionClass = '3,' + StrSubstNo(ConditionLbl, MatrixArrayCaptionSet[4]);
                    ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 4.';
                    Visible = Visible4;
                    Editable = Editable4;

                    trigger OnValidate()
                    begin
                        UpdateMatrixDataCondition(4);
                    end;

                    trigger OnAssistEdit()
                    begin
                        if not Editable4 then
                            exit;

                        AssistEditCondition(4);
                    end;
                }
                field(Field4_Desc; MatrixArrayConditionDescriptionCellData[4])
                {
                    CaptionClass = '3,' + StrSubstNo(DescriptionLbl, MatrixArrayCaptionSet[4]);
                    ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 4.';
                    Visible = Visible4;
                    Editable = Editable4;

                    trigger OnValidate()
                    begin
                        UpdateMatrixDataConditionDescription(4);
                    end;

                    trigger OnAssistEdit()
                    begin
                        if not Editable4 then
                            exit;

                        AssistEditConditionDescription(4);
                    end;
                }
                field(Field5; MatrixArrayConditionCellData[5])
                {
                    CaptionClass = '3,' + StrSubstNo(ConditionLbl, MatrixArrayCaptionSet[5]);
                    ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 5.';
                    Visible = Visible5;
                    Editable = Editable5;

                    trigger OnValidate()
                    begin
                        UpdateMatrixDataCondition(5);
                    end;

                    trigger OnAssistEdit()
                    begin
                        if not Editable5 then
                            exit;

                        AssistEditCondition(5);
                    end;
                }
                field(Field5_Desc; MatrixArrayConditionDescriptionCellData[5])
                {
                    CaptionClass = '3,' + StrSubstNo(DescriptionLbl, MatrixArrayCaptionSet[5]);
                    ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 5.';
                    Visible = Visible5;
                    Editable = Editable5;

                    trigger OnValidate()
                    begin
                        UpdateMatrixDataConditionDescription(5);
                    end;

                    trigger OnAssistEdit()
                    begin
                        if not Editable5 then
                            exit;

                        AssistEditConditionDescription(5);
                    end;
                }
                field(Field6; MatrixArrayConditionCellData[6])
                {
                    CaptionClass = '3,' + StrSubstNo(ConditionLbl, MatrixArrayCaptionSet[6]);
                    ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 6.';
                    Visible = Visible6;
                    Editable = Editable6;

                    trigger OnValidate()
                    begin
                        UpdateMatrixDataCondition(6);
                    end;

                    trigger OnAssistEdit()
                    begin
                        if not Editable6 then
                            exit;

                        AssistEditCondition(6);
                    end;
                }
                field(Field6_Desc; MatrixArrayConditionDescriptionCellData[6])
                {
                    CaptionClass = '3,' + StrSubstNo(DescriptionLbl, MatrixArrayCaptionSet[6]);
                    ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 6.';
                    Visible = Visible6;
                    Editable = Editable6;

                    trigger OnValidate()
                    begin
                        UpdateMatrixDataConditionDescription(6);
                    end;

                    trigger OnAssistEdit()
                    begin
                        if not Editable6 then
                            exit;

                        AssistEditConditionDescription(6);
                    end;
                }
                field(Field7; MatrixArrayConditionCellData[7])
                {
                    CaptionClass = '3,' + StrSubstNo(ConditionLbl, MatrixArrayCaptionSet[7]);
                    ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 7.';
                    Visible = Visible7;
                    Editable = Editable7;

                    trigger OnValidate()
                    begin
                        UpdateMatrixDataCondition(7);
                    end;

                    trigger OnAssistEdit()
                    begin
                        if not Editable7 then
                            exit;

                        AssistEditCondition(7);
                    end;
                }
                field(Field7_Desc; MatrixArrayConditionDescriptionCellData[7])
                {
                    CaptionClass = '3,' + StrSubstNo(DescriptionLbl, MatrixArrayCaptionSet[7]);
                    ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 7.';
                    Visible = Visible7;
                    Editable = Editable7;

                    trigger OnValidate()
                    begin
                        UpdateMatrixDataConditionDescription(7);
                    end;

                    trigger OnAssistEdit()
                    begin
                        if not Editable7 then
                            exit;

                        AssistEditConditionDescription(7);
                    end;
                }
                field(Field8; MatrixArrayConditionCellData[8])
                {
                    CaptionClass = '3,' + StrSubstNo(ConditionLbl, MatrixArrayCaptionSet[8]);
                    ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 8.';
                    Visible = Visible8;
                    Editable = Editable8;

                    trigger OnValidate()
                    begin
                        UpdateMatrixDataCondition(8);
                    end;

                    trigger OnAssistEdit()
                    begin
                        if not Editable8 then
                            exit;

                        AssistEditCondition(8);
                    end;
                }
                field(Field8_Desc; MatrixArrayConditionDescriptionCellData[8])
                {
                    CaptionClass = '3,' + StrSubstNo(DescriptionLbl, MatrixArrayCaptionSet[8]);
                    ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 8.';
                    Visible = Visible8;
                    Editable = Editable8;

                    trigger OnValidate()
                    begin
                        UpdateMatrixDataConditionDescription(8);
                    end;

                    trigger OnAssistEdit()
                    begin
                        if not Editable8 then
                            exit;

                        AssistEditConditionDescription(8);
                    end;
                }
                field(Field9; MatrixArrayConditionCellData[9])
                {
                    CaptionClass = '3,' + StrSubstNo(ConditionLbl, MatrixArrayCaptionSet[9]);
                    ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 9.';
                    Visible = Visible9;
                    Editable = Editable9;

                    trigger OnValidate()
                    begin
                        UpdateMatrixDataCondition(9);
                    end;

                    trigger OnAssistEdit()
                    begin
                        if not Editable9 then
                            exit;

                        AssistEditCondition(9);
                    end;
                }
                field(Field9_Desc; MatrixArrayConditionDescriptionCellData[9])
                {
                    CaptionClass = '3,' + StrSubstNo(DescriptionLbl, MatrixArrayCaptionSet[9]);
                    ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 9.';
                    Visible = Visible9;
                    Editable = Editable9;

                    trigger OnValidate()
                    begin
                        UpdateMatrixDataConditionDescription(9);
                    end;

                    trigger OnAssistEdit()
                    begin
                        if not Editable9 then
                            exit;

                        AssistEditConditionDescription(9);
                    end;
                }
                field(Field10; MatrixArrayConditionCellData[10])
                {
                    CaptionClass = '3,' + StrSubstNo(ConditionLbl, MatrixArrayCaptionSet[10]);
                    ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 10.';
                    Visible = Visible10;
                    Editable = Editable10;

                    trigger OnValidate()
                    begin
                        UpdateMatrixDataCondition(10);
                    end;

                    trigger OnAssistEdit()
                    begin
                        if not Editable10 then
                            exit;

                        AssistEditCondition(10);
                    end;
                }
                field(Field10_Desc; MatrixArrayConditionDescriptionCellData[10])
                {
                    CaptionClass = '3,' + StrSubstNo(DescriptionLbl, MatrixArrayCaptionSet[10]);
                    ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 10.';
                    Visible = Visible10;
                    Editable = Editable10;

                    trigger OnValidate()
                    begin
                        UpdateMatrixDataConditionDescription(10);
                    end;

                    trigger OnAssistEdit()
                    begin
                        if not Editable10 then
                            exit;

                        AssistEditConditionDescription(10);
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(AddMultipleTests)
            {
                AccessByPermission = tabledata "Qlty. Inspection Template Line" = I;
                Caption = 'Select tests';
                ToolTip = 'Add two or more tests to this template, by selecting from the full list of quality tests. Tests that already exist in the template are skipped.';
                Ellipsis = true;
                Image = SelectMore;
                Enabled = Rec."Template Code" <> '';

                trigger OnAction()
                begin
                    Rec.SelectMultipleTests(Rec."Template Code");
                end;
            }
        }
    }

    var
        QltyResultConditionMgmt: Codeunit "Qlty. Result Condition Mgmt.";
        MatrixSourceRecordId: array[10] of RecordId;
        RowStyle: Option None,Standard,StandardAccent,Strong,StrongAccent,Attention,AttentionAccent,Favorable,Unfavorable,Ambiguous,Subordinate;
        RowStyleText: Text;
        MatrixArrayConditionCellData: array[10] of Text;
        MatrixArrayConditionDescriptionCellData: array[10] of Text;
        MatrixArrayCaptionSet: array[10] of Text;
        Visible1, Visible2, Visible3, Visible4, Visible5, Visible6, Visible7, Visible8, Visible9, Visible10 : Boolean;
        Editable1, Editable2, Editable3, Editable4, Editable5, Editable6, Editable7, Editable8, Editable9, Editable10 : Boolean;
        IsExpressionFormulaEditable: Boolean;
        DescriptionLbl: Label '%1 Description', Comment = '%1 = Matrix field caption';
        ConditionLbl: Label '%1 Condition', Comment = '%1 = Matrix field caption';

    trigger OnOpenPage()
    var
        MatrixVisibleState: array[10] of Boolean;
    begin
        // Column visibility and captions are page-wide and driven by the global set of promoted results, so they only need to be computed once when the page opens.
        QltyResultConditionMgmt.GetDefaultPromotedResults(true, MatrixSourceRecordId, MatrixArrayConditionCellData, MatrixArrayConditionDescriptionCellData, MatrixArrayCaptionSet, MatrixVisibleState);
        Visible1 := MatrixVisibleState[1];
        Visible2 := MatrixVisibleState[2];
        Visible3 := MatrixVisibleState[3];
        Visible4 := MatrixVisibleState[4];
        Visible5 := MatrixVisibleState[5];
        Visible6 := MatrixVisibleState[6];
        Visible7 := MatrixVisibleState[7];
        Visible8 := MatrixVisibleState[8];
        Visible9 := MatrixVisibleState[9];
        Visible10 := MatrixVisibleState[10];
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        exit(Rec.Find(Which));
    end;

    trigger OnAfterGetRecord()
    var
        DuplicateTestCheckQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
    begin
        UpdateRowData();

        RowStyle := RowStyle::None;
        DuplicateTestCheckQltyInspectionTemplateLine.SetRange("Template Code", Rec."Template Code");
        DuplicateTestCheckQltyInspectionTemplateLine.SetRange("Test Code", Rec."Test Code");
        DuplicateTestCheckQltyInspectionTemplateLine.SetFilter("Line No.", '<>%1', Rec."Line No.");
        if not DuplicateTestCheckQltyInspectionTemplateLine.IsEmpty() then
            RowStyle := RowStyle::Unfavorable;

        RowStyleText := Format(RowStyle);
    end;

    local procedure UpdateRowData()
    var
        DummyMatrixArrayCaptionSet: array[10] of Text;
        DummyMatrixVisibleState: array[10] of Boolean;
        RowIsLabel: Boolean;
    begin
        Rec.CalcFields("Test Value Type");
        RowIsLabel := Rec."Test Value Type" = Rec."Test Value Type"::"Value Type Label";

        // Label rows never have promoted result condition records, so just blank the per-row cell data instead.
        if RowIsLabel then begin
            Clear(MatrixSourceRecordId);
            Clear(MatrixArrayConditionCellData);
            Clear(MatrixArrayConditionDescriptionCellData);
        end else
            // Refresh the per-row condition values and source RecordIds so OnValidate/OnAssistEdit on each cell operates on the correct underlying configuration record.
            QltyResultConditionMgmt.GetPromotedResultsForTemplateLine(Rec, MatrixSourceRecordId, MatrixArrayConditionCellData, MatrixArrayConditionDescriptionCellData, DummyMatrixArrayCaptionSet, DummyMatrixVisibleState);

        Editable1 := Visible1 and not RowIsLabel;
        Editable2 := Visible2 and not RowIsLabel;
        Editable3 := Visible3 and not RowIsLabel;
        Editable4 := Visible4 and not RowIsLabel;
        Editable5 := Visible5 and not RowIsLabel;
        Editable6 := Visible6 and not RowIsLabel;
        Editable7 := Visible7 and not RowIsLabel;
        Editable8 := Visible8 and not RowIsLabel;
        Editable9 := Visible9 and not RowIsLabel;
        Editable10 := Visible10 and not RowIsLabel;

        IsExpressionFormulaEditable := Rec."Test Value Type" = Rec."Test Value Type"::"Value Type Text Expression";
    end;

    local procedure UpdateMatrixDataCondition(Matrix: Integer)
    var
        QltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        OldQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
    begin
        QltyIResultConditConf.Get(MatrixSourceRecordId[Matrix]);
        OldQltyIResultConditConf := QltyIResultConditConf;
        if StrLen(MatrixArrayConditionCellData[Matrix]) > MaxStrLen(QltyIResultConditConf.Condition) then
            MatrixArrayConditionCellData[Matrix] := CopyStr(MatrixArrayConditionCellData[Matrix], 1, MaxStrLen(QltyIResultConditConf.Condition));
        QltyIResultConditConf.Validate(Condition, MatrixArrayConditionCellData[Matrix]);
        if OldQltyIResultConditConf.Condition = OldQltyIResultConditConf."Condition Description" then begin
            MatrixArrayConditionDescriptionCellData[Matrix] := MatrixArrayConditionCellData[Matrix];

            if StrLen(MatrixArrayConditionDescriptionCellData[Matrix]) > MaxStrLen(QltyIResultConditConf."Condition Description") then
                MatrixArrayConditionDescriptionCellData[Matrix] := CopyStr(MatrixArrayConditionDescriptionCellData[Matrix], 1, MaxStrLen(QltyIResultConditConf."Condition Description"));

            QltyIResultConditConf.Validate("Condition Description", MatrixArrayConditionDescriptionCellData[Matrix]);
        end;
        QltyIResultConditConf.Modify(true);
        CurrPage.Update(true);
    end;

    local procedure UpdateMatrixDataConditionDescription(Matrix: Integer)
    var
        QltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        OldQltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
    begin
        QltyIResultConditConf.Get(MatrixSourceRecordId[Matrix]);
        OldQltyIResultConditConf := QltyIResultConditConf;
        if StrLen(MatrixArrayConditionDescriptionCellData[Matrix]) > MaxStrLen(QltyIResultConditConf."Condition Description") then
            MatrixArrayConditionDescriptionCellData[Matrix] := CopyStr(MatrixArrayConditionDescriptionCellData[Matrix], 1, MaxStrLen(QltyIResultConditConf."Condition Description"));

        QltyIResultConditConf.Validate("Condition Description", MatrixArrayConditionDescriptionCellData[Matrix]);
        QltyIResultConditConf.Modify(true);
        CurrPage.Update(false);
    end;

    /// <summary>
    /// Starts the assist-edit dialog for the result condition description.
    /// </summary>
    /// <param name="Matrix"></param>
    procedure AssistEditCondition(Matrix: Integer)
    var
        QltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        QltyInspectionTemplateEdit: Page "Qlty. Inspection Template Edit";
        Expression: Text;
    begin
        Expression := MatrixArrayConditionCellData[Matrix];
        QltyInspectionTemplateEdit.RestrictTestsToThoseOnTemplate(Rec."Template Code");
        if QltyInspectionTemplateEdit.RunModalWith(Database::"Qlty. Inspection Header", '', Expression) in [Action::LookupOK, Action::OK, Action::Yes] then begin
            MatrixArrayConditionCellData[Matrix] := CopyStr(Expression, 1, MaxStrLen(QltyIResultConditConf.Condition));
            UpdateMatrixDataCondition(Matrix);
        end;
    end;

    /// <summary>
    /// Starts the assist edit dialog for the result condition description
    /// </summary>
    /// <param name="Matrix"></param>
    procedure AssistEditConditionDescription(Matrix: Integer)
    var
        QltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        QltyInspectionTemplateEdit: Page "Qlty. Inspection Template Edit";
        Expression: Text;
    begin
        Expression := MatrixArrayConditionDescriptionCellData[Matrix];
        QltyInspectionTemplateEdit.RestrictTestsToThoseOnTemplate(Rec."Template Code");
        if QltyInspectionTemplateEdit.RunModalWith(Database::"Qlty. Inspection Header", '', Expression) in [Action::LookupOK, Action::OK, Action::Yes] then begin
            MatrixArrayConditionDescriptionCellData[Matrix] := CopyStr(Expression, 1, MaxStrLen(QltyIResultConditConf.Condition));
            UpdateMatrixDataConditionDescription(Matrix);
        end;
    end;
}
