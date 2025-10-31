﻿// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.Template;

using Microsoft.QualityManagement.Configuration.Grade;
using Microsoft.QualityManagement.Configuration.Template.Field;
using Microsoft.QualityManagement.Document;

/// <summary>
/// This subform is used on the template card to help configure which fields should be defined on a template.
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
                field("Field Code"; Rec."Field Code")
                {
                    StyleExpr = RowStyleText;

                    trigger OnValidate()
                    begin
                        Rec.EnsureGrades(Rec."Field Code" <> xRec."Field Code");
                        UpdateRowData();
                        CurrPage.Update(true);
                    end;
                }
                field(Description; Rec.Description)
                {
                    StyleExpr = RowStyleText;
                }
                field("Field Type"; Rec."Field Type")
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
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    StyleExpr = RowStyleText;
                    AboutTitle = 'Unit of Measure Code';
                    AboutText = 'The unit of measure for the measurement.';
                }
                field(Field1; MatrixArrayConditionCellData[1])
                {
                    CaptionClass = '3,' + MatrixArrayCaptionSet[1];
                    ToolTip = 'Specifies a field condition for a promoted grade. This is dynamic based on the promoted grades, this is grade condition 1';
                    Visible = Visible1;
                    Editable = Visible1;

                    trigger OnValidate()
                    begin
                        UpdateMatrixDataCondition(1);
                    end;

                    trigger OnAssistEdit()
                    begin
                        AssistEditCondition(1);
                    end;
                }
                field(Field1_Desc; MatrixArrayConditionDescriptionCellData[1])
                {
                    CaptionClass = '3,' + MatrixArrayCaptionSet[1] + ' Desc.';
                    ToolTip = 'Specifies a field condition for a promoted grade. This is dynamic based on the promoted grades, this is grade condition 1';
                    Visible = Visible1;
                    Editable = Visible1;

                    trigger OnValidate()
                    begin
                        UpdateMatrixDataConditionDescription(1);
                    end;

                    trigger OnAssistEdit()
                    begin
                        AssistEditConditionDescription(1);
                    end;
                }
                field(Field2; MatrixArrayConditionCellData[2])
                {
                    CaptionClass = '3,' + MatrixArrayCaptionSet[2];
                    ToolTip = 'Specifies a field condition for a promoted grade. This is dynamic based on the promoted grades, this is grade condition 2';
                    Visible = Visible2;
                    Editable = Visible2;

                    trigger OnValidate()
                    begin
                        UpdateMatrixDataCondition(2);
                    end;

                    trigger OnAssistEdit()
                    begin
                        AssistEditCondition(2);
                    end;
                }
                field(Field2_Desc; MatrixArrayConditionDescriptionCellData[2])
                {
                    CaptionClass = '3,' + MatrixArrayCaptionSet[2] + ' Desc.';
                    ToolTip = 'Specifies a field condition for a promoted grade. This is dynamic based on the promoted grades, this is grade condition 2';
                    Visible = Visible2;
                    Editable = Visible2;

                    trigger OnValidate()
                    begin
                        UpdateMatrixDataConditionDescription(2);
                    end;

                    trigger OnAssistEdit()
                    begin
                        AssistEditConditionDescription(2);
                    end;
                }
                field(Field3; MatrixArrayConditionCellData[3])
                {
                    CaptionClass = '3,' + MatrixArrayCaptionSet[3];
                    ToolTip = 'Specifies a field condition for a promoted grade. This is dynamic based on the promoted grades, this is grade condition 3';
                    Visible = Visible3;
                    Editable = Visible3;

                    trigger OnValidate()
                    begin
                        UpdateMatrixDataCondition(3);
                    end;

                    trigger OnAssistEdit()
                    begin
                        AssistEditCondition(3);
                    end;
                }
                field(Field3_Desc; MatrixArrayConditionDescriptionCellData[3])
                {
                    CaptionClass = '3,' + MatrixArrayCaptionSet[3] + ' Desc.';
                    ToolTip = 'Specifies a field condition for a promoted grade. This is dynamic based on the promoted grades, this is grade condition 3';
                    Visible = Visible3;
                    Editable = Visible3;

                    trigger OnValidate()
                    begin
                        UpdateMatrixDataConditionDescription(3);
                    end;

                    trigger OnAssistEdit()
                    begin
                        AssistEditConditionDescription(3);
                    end;
                }
                field(Field4; MatrixArrayConditionCellData[4])
                {
                    CaptionClass = '3,' + MatrixArrayCaptionSet[4];
                    ToolTip = 'Specifies a field condition for a promoted grade. This is dynamic based on the promoted grades, this is grade condition 4';
                    Visible = Visible4;
                    Editable = Visible4;

                    trigger OnValidate()
                    begin
                        UpdateMatrixDataCondition(4);
                    end;

                    trigger OnAssistEdit()
                    begin
                        AssistEditCondition(4);
                    end;
                }
                field(Field4_Desc; MatrixArrayConditionDescriptionCellData[4])
                {
                    CaptionClass = '3,' + MatrixArrayCaptionSet[4] + ' Desc.';
                    ToolTip = 'Specifies a field condition for a promoted grade. This is dynamic based on the promoted grades, this is grade condition 4';
                    Visible = Visible4;
                    Editable = Visible4;

                    trigger OnValidate()
                    begin
                        UpdateMatrixDataConditionDescription(4);
                    end;

                    trigger OnAssistEdit()
                    begin
                        AssistEditConditionDescription(4);
                    end;
                }
                field(Field5; MatrixArrayConditionCellData[5])
                {
                    CaptionClass = '3,' + MatrixArrayCaptionSet[5];
                    ToolTip = 'Specifies a field condition for a promoted grade. This is dynamic based on the promoted grades, this is grade condition 5';
                    Visible = Visible5;
                    Editable = Visible5;

                    trigger OnValidate()
                    begin
                        UpdateMatrixDataCondition(5);
                    end;

                    trigger OnAssistEdit()
                    begin
                        AssistEditCondition(5);
                    end;
                }
                field(Field5_Desc; MatrixArrayConditionDescriptionCellData[5])
                {
                    CaptionClass = '3,' + MatrixArrayCaptionSet[5] + ' Desc.';
                    ToolTip = 'Specifies a field condition for a promoted grade. This is dynamic based on the promoted grades, this is grade condition 5';
                    Visible = Visible5;
                    Editable = Visible5;

                    trigger OnValidate()
                    begin
                        UpdateMatrixDataConditionDescription(5);
                    end;

                    trigger OnAssistEdit()
                    begin
                        AssistEditConditionDescription(5);
                    end;
                }
                field(Field6; MatrixArrayConditionCellData[6])
                {
                    CaptionClass = '3,' + MatrixArrayCaptionSet[6];
                    ToolTip = 'Specifies a field condition for a promoted grade. This is dynamic based on the promoted grades, this is grade condition 6';
                    Visible = Visible6;
                    Editable = Visible6;

                    trigger OnValidate()
                    begin
                        UpdateMatrixDataCondition(6);
                    end;

                    trigger OnAssistEdit()
                    begin
                        AssistEditCondition(6);
                    end;
                }
                field(Field6_Desc; MatrixArrayConditionDescriptionCellData[6])
                {
                    CaptionClass = '3,' + MatrixArrayCaptionSet[6] + ' Desc.';
                    ToolTip = 'Specifies a field condition for a promoted grade. This is dynamic based on the promoted grades, this is grade condition 6';
                    Visible = Visible6;
                    Editable = Visible6;

                    trigger OnValidate()
                    begin
                        UpdateMatrixDataConditionDescription(6);
                    end;

                    trigger OnAssistEdit()
                    begin
                        AssistEditConditionDescription(6);
                    end;
                }
                field(Field7; MatrixArrayConditionCellData[7])
                {
                    CaptionClass = '3,' + MatrixArrayCaptionSet[7];
                    ToolTip = 'Specifies a field condition for a promoted grade. This is dynamic based on the promoted grades, this is grade condition 7';
                    Visible = Visible7;
                    Editable = Visible7;

                    trigger OnValidate()
                    begin
                        UpdateMatrixDataCondition(7);
                    end;

                    trigger OnAssistEdit()
                    begin
                        AssistEditCondition(7);
                    end;
                }
                field(Field7_Desc; MatrixArrayConditionDescriptionCellData[7])
                {
                    CaptionClass = '3,' + MatrixArrayCaptionSet[7] + ' Desc.';
                    ToolTip = 'Specifies a field condition for a promoted grade. This is dynamic based on the promoted grades, this is grade condition 7';
                    Visible = Visible7;
                    Editable = Visible7;

                    trigger OnValidate()
                    begin
                        UpdateMatrixDataConditionDescription(7);
                    end;

                    trigger OnAssistEdit()
                    begin
                        AssistEditConditionDescription(7);
                    end;
                }
                field(Field8; MatrixArrayConditionCellData[8])
                {
                    CaptionClass = '3,' + MatrixArrayCaptionSet[8];
                    ToolTip = 'Specifies a field condition for a promoted grade. This is dynamic based on the promoted grades, this is grade condition 8';
                    Visible = Visible8;
                    Editable = Visible8;

                    trigger OnValidate()
                    begin
                        UpdateMatrixDataCondition(8);
                    end;

                    trigger OnAssistEdit()
                    begin
                        AssistEditCondition(8);
                    end;
                }
                field(Field8_Desc; MatrixArrayConditionDescriptionCellData[8])
                {
                    CaptionClass = '3,' + MatrixArrayCaptionSet[8] + ' Desc.';
                    ToolTip = 'Specifies a field condition for a promoted grade. This is dynamic based on the promoted grades, this is grade condition 8';
                    Visible = Visible8;
                    Editable = Visible8;

                    trigger OnValidate()
                    begin
                        UpdateMatrixDataConditionDescription(8);
                    end;

                    trigger OnAssistEdit()
                    begin
                        AssistEditConditionDescription(8);
                    end;
                }
                field(Field9; MatrixArrayConditionCellData[9])
                {
                    CaptionClass = '3,' + MatrixArrayCaptionSet[9];
                    ToolTip = 'Specifies a field condition for a promoted grade. This is dynamic based on the promoted grades, this is grade condition 9';
                    Visible = Visible9;
                    Editable = Visible9;

                    trigger OnValidate()
                    begin
                        UpdateMatrixDataCondition(9);
                    end;

                    trigger OnAssistEdit()
                    begin
                        AssistEditCondition(9);
                    end;
                }
                field(Field9_Desc; MatrixArrayConditionDescriptionCellData[9])
                {
                    CaptionClass = '3,' + MatrixArrayCaptionSet[9] + ' Desc.';
                    ToolTip = 'Specifies a field condition for a promoted grade. This is dynamic based on the promoted grades, this is grade condition 9';
                    Visible = Visible9;
                    Editable = Visible9;

                    trigger OnValidate()
                    begin
                        UpdateMatrixDataConditionDescription(9);
                    end;

                    trigger OnAssistEdit()
                    begin
                        AssistEditConditionDescription(9);
                    end;
                }
                field(Field10; MatrixArrayConditionCellData[10])
                {
                    CaptionClass = '3,' + MatrixArrayCaptionSet[10];
                    ToolTip = 'Specifies a field condition for a promoted grade. This is dynamic based on the promoted grades, this is grade condition 10';
                    Visible = Visible10;
                    Editable = Visible10;

                    trigger OnValidate()
                    begin
                        UpdateMatrixDataCondition(10);
                    end;

                    trigger OnAssistEdit()
                    begin
                        AssistEditCondition(10);
                    end;
                }
                field(Field10_Desc; MatrixArrayConditionDescriptionCellData[10])
                {
                    CaptionClass = '3,' + MatrixArrayCaptionSet[10] + ' Desc.';
                    ToolTip = 'Specifies a field condition for a promoted grade. This is dynamic based on the promoted grades, this is grade condition 10';
                    Visible = Visible10;
                    Editable = Visible10;

                    trigger OnValidate()
                    begin
                        UpdateMatrixDataConditionDescription(10);
                    end;

                    trigger OnAssistEdit()
                    begin
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
            action(tNewField)
            {
                Image = Default;
                Caption = 'Add Field(s) To This Template';
                ToolTip = 'Add a new Field or existing Field(s) to this template';
                Scope = Repeater;

                trigger OnAction()
                begin
                    AddFieldWizard();
                end;
            }
            action(tEditField)
            {
                Image = Edit;
                Caption = 'Edit Field';
                ToolTip = 'This will edit your existing selected field.';
                Scope = Repeater;

                trigger OnAction()
                var
                    QltyField: Record "Qlty. Field";
                    QltyFieldWizard: Page "Qlty. Field Wizard";
                begin
                    QltyField.Get(Rec."Field Code");
                    if QltyFieldWizard.RunModalEditExistingField(QltyField) in [Action::OK, Action::LookupOK, Action::Yes] then begin
                        QltyField.Get(QltyField.Code);
                        Rec.Validate("Field Code", QltyField.Code);
                        Rec.Description := QltyField.Description;
                        Rec."Expression Formula" := QltyField."Expression Formula";
                        Rec.EnsureGrades(true);
                        CurrPage.Update(true);
                    end else
                        CurrPage.Update(false);
                end;
            }
        }
    }

    var
        CachedQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyGradeConditionMgmt: Codeunit "Qlty. Grade Condition Mgmt.";
        MatrixSourceRecordId: array[10] of RecordId;
        RowStyle: Option None,Standard,StandardAccent,Strong,StrongAccent,Attention,AttentionAccent,Favorable,Unfavorable,Ambiguous,Subordinate;
        RowStyleText: Text;
        MatrixArrayConditionCellData: array[10] of Text;
        MatrixArrayConditionDescriptionCellData: array[10] of Text;
        MatrixArrayCaptionSet: array[10] of Text;
        MatrixVisibleState: array[10] of Boolean;
        Visible1: Boolean;
        Visible2: Boolean;
        Visible3: Boolean;
        Visible4: Boolean;
        Visible5: Boolean;
        Visible6: Boolean;
        Visible7: Boolean;
        Visible8: Boolean;
        Visible9: Boolean;
        Visible10: Boolean;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        if Rec."Template Code" <> CachedQltyInspectionTemplateHdr.Code then begin
            Clear(CachedQltyInspectionTemplateHdr);
            if Rec."Template Code" <> '' then
                if CachedQltyInspectionTemplateHdr.Get(Rec."Template Code") then;
        end;
        Rec.EnsureGrades(false);
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        Clear(CachedQltyInspectionTemplateHdr);
        exit(Rec.Find(Which));
    end;

    trigger OnAfterGetRecord()
    var
        DuplicateFieldCheckQltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
    begin
        UpdateRowData();
        RowStyle := RowStyle::None;
        DuplicateFieldCheckQltyInspectionTemplateLine.SetRange("Template Code", Rec."Template Code");
        DuplicateFieldCheckQltyInspectionTemplateLine.SetRange("Field Code", Rec."Field Code");
        DuplicateFieldCheckQltyInspectionTemplateLine.SetFilter("Line No.", '<>%1', Rec."Line No.");
        if not DuplicateFieldCheckQltyInspectionTemplateLine.IsEmpty() then
            RowStyle := RowStyle::Unfavorable;

        RowStyleText := Format(RowStyle);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateRowData();
    end;

    local procedure UpdateRowData()
    begin
        Rec.CalcFields("Field Type");

        if (CachedQltyInspectionTemplateHdr.Code <> Rec."Template Code") and (Rec."Template Code" <> '') then
            if CachedQltyInspectionTemplateHdr.Get(Rec."Template Code") then;

        QltyGradeConditionMgmt.GetPromotedGradesForTemplateLine(Rec, MatrixSourceRecordId, MatrixArrayConditionCellData, MatrixArrayConditionDescriptionCellData, MatrixArrayCaptionSet, MatrixVisibleState);
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

    local procedure UpdateMatrixDataCondition(Matrix: Integer)
    var
        QltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        OldQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
    begin
        QltyIGradeConditionConf.Get(MatrixSourceRecordId[Matrix]);
        OldQltyIGradeConditionConf := QltyIGradeConditionConf;
        if StrLen(MatrixArrayConditionCellData[Matrix]) > MaxStrLen(QltyIGradeConditionConf.Condition) then
            MatrixArrayConditionCellData[Matrix] := CopyStr(MatrixArrayConditionCellData[Matrix], 1, MaxStrLen(QltyIGradeConditionConf.Condition));
        QltyIGradeConditionConf.Validate(Condition, MatrixArrayConditionCellData[Matrix]);
        if OldQltyIGradeConditionConf.Condition = OldQltyIGradeConditionConf."Condition Description" then begin
            MatrixArrayConditionDescriptionCellData[Matrix] := MatrixArrayConditionCellData[Matrix];

            if StrLen(MatrixArrayConditionDescriptionCellData[Matrix]) > MaxStrLen(QltyIGradeConditionConf."Condition Description") then
                MatrixArrayConditionDescriptionCellData[Matrix] := CopyStr(MatrixArrayConditionDescriptionCellData[Matrix], 1, MaxStrLen(QltyIGradeConditionConf."Condition Description"));

            QltyIGradeConditionConf.Validate("Condition Description", MatrixArrayConditionDescriptionCellData[Matrix]);
        end;
        QltyIGradeConditionConf.Modify(true);
        CurrPage.Update(true);
    end;

    local procedure UpdateMatrixDataConditionDescription(Matrix: Integer)
    var
        QltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        OldQltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
    begin
        QltyIGradeConditionConf.Get(MatrixSourceRecordId[Matrix]);
        OldQltyIGradeConditionConf := QltyIGradeConditionConf;
        if StrLen(MatrixArrayConditionDescriptionCellData[Matrix]) > MaxStrLen(QltyIGradeConditionConf."Condition Description") then
            MatrixArrayConditionDescriptionCellData[Matrix] := CopyStr(MatrixArrayConditionDescriptionCellData[Matrix], 1, MaxStrLen(QltyIGradeConditionConf."Condition Description"));

        QltyIGradeConditionConf.Validate("Condition Description", MatrixArrayConditionDescriptionCellData[Matrix]);
        QltyIGradeConditionConf.Modify(true);
        CurrPage.Update(false);
    end;

    /// <summary>
    /// Starts the assist-edit dialog for the grade condition description.
    /// </summary>
    /// <param name="Matrix"></param>
    procedure AssistEditCondition(Matrix: Integer)
    var
        QltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        QltyInspectionTemplateEdit: Page "Qlty. Inspection Template Edit";
        Expression: Text;
    begin
        Expression := MatrixArrayConditionCellData[Matrix];
        QltyInspectionTemplateEdit.RestrictFieldsToThoseOnTemplate(Rec."Template Code");
        if QltyInspectionTemplateEdit.RunModalWith(Database::"Qlty. Inspection Test Header", '', Expression) in [Action::LookupOK, Action::OK, Action::Yes] then begin
            MatrixArrayConditionCellData[Matrix] := CopyStr(Expression, 1, MaxStrLen(QltyIGradeConditionConf.Condition));
            UpdateMatrixDataCondition(Matrix);
        end;
    end;

    /// <summary>
    /// Starts the assist edit dialog for the grade condition description
    /// </summary>
    /// <param name="Matrix"></param>
    procedure AssistEditConditionDescription(Matrix: Integer)
    var
        QltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        QltyInspectionTemplateEdit: Page "Qlty. Inspection Template Edit";
        Expression: Text;
    begin
        Expression := MatrixArrayConditionDescriptionCellData[Matrix];
        QltyInspectionTemplateEdit.RestrictFieldsToThoseOnTemplate(Rec."Template Code");
        if QltyInspectionTemplateEdit.RunModalWith(Database::"Qlty. Inspection Test Header", '', Expression) in [Action::LookupOK, Action::OK, Action::Yes] then begin
            MatrixArrayConditionDescriptionCellData[Matrix] := CopyStr(Expression, 1, MaxStrLen(QltyIGradeConditionConf.Condition));
            UpdateMatrixDataConditionDescription(Matrix);
        end;
    end;

    /// <summary>
    /// Use a wizard to add a new field to this template.
    /// </summary>
    procedure AddFieldWizard()
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyFieldWizard: Page "Qlty. Field Wizard";
        OfFieldsToAdd: list of [Code[20]];
        TemplateCode: Code[20];
        FieldCode: Code[20];
        FilterGroupIterator: Integer;
    begin
        FilterGroupIterator := 4;
        repeat
            Rec.FilterGroup(FilterGroupIterator);
            if Rec.GetFilter("Template Code") <> '' then
                TemplateCode := Rec.GetRangeMin("Template Code");

            FilterGroupIterator -= 1;
        until (FilterGroupIterator < 0) or (TemplateCode <> '');
        QltyInspectionTemplateHdr.Get(TemplateCode);
        Rec.FilterGroup(0);
        QltyFieldWizard.RunModal();
        if QltyFieldWizard.GetFieldsToAdd(OfFieldsToAdd) then
            foreach FieldCode in OfFieldsToAdd do
                QltyInspectionTemplateHdr.AddFieldToTemplate(FieldCode);
        CurrPage.Update();
    end;
}
