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
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    StyleExpr = RowStyleText;
                    AboutTitle = 'Unit of Measure Code';
                    AboutText = 'The unit of measure for the measurement.';
                }
                field(Field1; MatrixArrayConditionCellData[1])
                {
                    CaptionClass = '3,' + StrSubstNo(ConditionLbl, MatrixArrayCaptionSet[1]);
                    ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 1';
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
                    CaptionClass = '3,' + StrSubstNo(DescriptionLbl, MatrixArrayCaptionSet[1]);
                    ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 1';
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
                    CaptionClass = '3,' + StrSubstNo(ConditionLbl, MatrixArrayCaptionSet[2]);
                    ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 2';
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
                    CaptionClass = '3,' + StrSubstNo(DescriptionLbl, MatrixArrayCaptionSet[2]);
                    ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 2';
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
                    CaptionClass = '3,' + StrSubstNo(ConditionLbl, MatrixArrayCaptionSet[3]);
                    ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 3';
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
                    CaptionClass = '3,' + StrSubstNo(DescriptionLbl, MatrixArrayCaptionSet[3]);
                    ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 3';
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
                    CaptionClass = '3,' + StrSubstNo(ConditionLbl, MatrixArrayCaptionSet[4]);
                    ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 4';
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
                    CaptionClass = '3,' + StrSubstNo(DescriptionLbl, MatrixArrayCaptionSet[4]);
                    ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 4';
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
                    CaptionClass = '3,' + StrSubstNo(ConditionLbl, MatrixArrayCaptionSet[5]);
                    ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 5';
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
                    CaptionClass = '3,' + StrSubstNo(DescriptionLbl, MatrixArrayCaptionSet[5]);
                    ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 5';
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
                    CaptionClass = '3,' + StrSubstNo(ConditionLbl, MatrixArrayCaptionSet[6]);
                    ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 6';
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
                    CaptionClass = '3,' + StrSubstNo(DescriptionLbl, MatrixArrayCaptionSet[6]);
                    ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 6';
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
                    CaptionClass = '3,' + StrSubstNo(ConditionLbl, MatrixArrayCaptionSet[7]);
                    ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 7';
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
                    CaptionClass = '3,' + StrSubstNo(DescriptionLbl, MatrixArrayCaptionSet[7]);
                    ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 7';
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
                    CaptionClass = '3,' + StrSubstNo(ConditionLbl, MatrixArrayCaptionSet[8]);
                    ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 8';
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
                    CaptionClass = '3,' + StrSubstNo(DescriptionLbl, MatrixArrayCaptionSet[8]);
                    ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 8';
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
                    CaptionClass = '3,' + StrSubstNo(ConditionLbl, MatrixArrayCaptionSet[9]);
                    ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 9';
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
                    CaptionClass = '3,' + StrSubstNo(DescriptionLbl, MatrixArrayCaptionSet[9]);
                    ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 9';
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
                    CaptionClass = '3,' + StrSubstNo(ConditionLbl, MatrixArrayCaptionSet[10]);
                    ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 10';
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
                    CaptionClass = '3,' + StrSubstNo(DescriptionLbl, MatrixArrayCaptionSet[10]);
                    ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 10';
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

    var
        CachedQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyResultConditionMgmt: Codeunit "Qlty. Result Condition Mgmt.";
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
        DescriptionLbl: Label '%1 Description', Comment = '%1 = Matrix field caption';
        ConditionLbl: Label '%1 Condition', Comment = '%1 = Matrix field caption';

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        if Rec."Template Code" <> CachedQltyInspectionTemplateHdr.Code then begin
            Clear(CachedQltyInspectionTemplateHdr);
            if Rec."Template Code" <> '' then
                if CachedQltyInspectionTemplateHdr.Get(Rec."Template Code") then;
        end;
        Rec.EnsureResultsExist(false);
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        Clear(CachedQltyInspectionTemplateHdr);
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

    trigger OnAfterGetCurrRecord()
    begin
        UpdateRowData();
    end;

    local procedure UpdateRowData()
    begin
        Rec.CalcFields("Test Value Type");

        if (CachedQltyInspectionTemplateHdr.Code <> Rec."Template Code") and (Rec."Template Code" <> '') then
            if CachedQltyInspectionTemplateHdr.Get(Rec."Template Code") then;

        QltyResultConditionMgmt.GetPromotedResultsForTemplateLine(Rec, MatrixSourceRecordId, MatrixArrayConditionCellData, MatrixArrayConditionDescriptionCellData, MatrixArrayCaptionSet, MatrixVisibleState);
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
