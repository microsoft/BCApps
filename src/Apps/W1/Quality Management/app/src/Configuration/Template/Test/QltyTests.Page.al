// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.Template.Test;

using Microsoft.QualityManagement.Configuration.Result;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Document;

/// <summary>
/// This page lets you define data points, questions, measurements, and entries with their allowable values and default passing thresholds. You can later use these tests in Quality Inspection Templates
/// </summary>
page 20401 "Qlty. Tests"
{
    Caption = 'Quality Tests';
    AdditionalSearchTerms = 'Quality measurement';
    AboutTitle = 'About Quality Tests';
    AboutText = 'Create and manage tests for quality inspections, including data points, questions, and measurements. Use these tests in templates to standardize quality checks.';
    CardPageId = "Qlty. Test Card";
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    RefreshOnActivate = true;
    PageType = List;
    SourceTable = "Qlty. Test";
    SourceTableView = sorting(Code);
    UsageCategory = Administration;
    ApplicationArea = QualityManagement;

    layout
    {
        area(Content)
        {
            repeater(GroupTests)
            {
                ShowCaption = false;

                field("Code"; Rec.Code)
                {
                }
                field(Description; Rec.Description)
                {
                    AboutTitle = 'Describe your test';
                    AboutText = 'This description will be visible when recording inspections and will show up on the Certificate of Analysis and other reports.';
                }
                field("Test Value Type"; Rec."Test Value Type")
                {
                }
                field("Allowable Values"; Rec."Allowable Values")
                {
                }
                field("Default Value"; Rec."Default Value")
                {
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                }
                field("Expression Formula"; Rec."Expression Formula")
                {
                }
                field("Case Sensitive"; Rec."Case Sensitive")
                {
                }
                field(Field1; MatrixArrayConditionCellData[1])
                {
                    CaptionClass = '3,' + StrSubstNo(ConditionLbl, MatrixArrayCaptionSet[1]);
                    ToolTip = 'Specifies the passing condition for this result. If you had a result of Pass being 80 to 100, you would then configure 80..100 here.';
                    Visible = Visible1;
                }
                field(Field1_Desc; MatrixArrayConditionDescriptionCellData[1])
                {
                    CaptionClass = '3,' + StrSubstNo(DescriptionLbl, MatrixArrayCaptionSet[1]);
                    ToolTip = 'Specifies a description for people of this result condition. If you had a result of Pass being 80 to 100, you would put in text describing this. This text will be visible when recording inspections and will show up on the Certificate of Analysis.';
                    Visible = Visible1;
                }
                field(Field2; MatrixArrayConditionCellData[2])
                {
                    CaptionClass = '3,' + StrSubstNo(ConditionLbl, MatrixArrayCaptionSet[2]);
                    ToolTip = 'Specifies the passing condition for this result. If you had a result of Pass being 80 to 100, you would then configure 80..100 here.';
                    Visible = Visible2;
                }
                field(Field2_Desc; MatrixArrayConditionDescriptionCellData[2])
                {
                    CaptionClass = '3,' + StrSubstNo(DescriptionLbl, MatrixArrayCaptionSet[2]);
                    ToolTip = 'Specifies a description for people of this result condition. If you had a result of Pass being 80 to 100, you would put in text describing this. This text will be visible when recording inspections and will show up on the Certificate of Analysis.';
                    Visible = Visible2;
                }
                field(Field3; MatrixArrayConditionCellData[3])
                {
                    CaptionClass = '3,' + StrSubstNo(ConditionLbl, MatrixArrayCaptionSet[3]);
                    ToolTip = 'Specifies the passing condition for this result. If you had a result of Pass being 80 to 100, you would then configure 80..100 here.';
                    Visible = Visible3;
                }
                field(Field3_Desc; MatrixArrayConditionDescriptionCellData[3])
                {
                    CaptionClass = '3,' + StrSubstNo(DescriptionLbl, MatrixArrayCaptionSet[3]);
                    ToolTip = 'Specifies a description for people of this result condition. If you had a result of Pass being 80 to 100, you would put in text describing this. This text will be visible when recording inspections and will show up on the Certificate of Analysis.';
                    Visible = Visible3;
                }
                field(Field4; MatrixArrayConditionCellData[4])
                {
                    CaptionClass = '3,' + StrSubstNo(ConditionLbl, MatrixArrayCaptionSet[4]);
                    ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 4';
                    Visible = Visible4;
                }
                field(Field4_Desc; MatrixArrayConditionDescriptionCellData[4])
                {
                    CaptionClass = '3,' + StrSubstNo(DescriptionLbl, MatrixArrayCaptionSet[4]);
                    ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 4';
                    Visible = Visible4;
                }
                field(Field5; MatrixArrayConditionCellData[5])
                {
                    CaptionClass = '3,' + StrSubstNo(ConditionLbl, MatrixArrayCaptionSet[5]);
                    ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 5';
                    Visible = Visible5;
                }
                field(Field5_Desc; MatrixArrayConditionDescriptionCellData[5])
                {
                    CaptionClass = '3,' + StrSubstNo(DescriptionLbl, MatrixArrayCaptionSet[5]);
                    ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 5';
                    Visible = Visible5;
                }
                field(Field6; MatrixArrayConditionCellData[6])
                {
                    CaptionClass = '3,' + StrSubstNo(ConditionLbl, MatrixArrayCaptionSet[6]);
                    ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 6';
                    Visible = Visible6;
                }
                field(Field6_Desc; MatrixArrayConditionDescriptionCellData[6])
                {
                    CaptionClass = '3,' + StrSubstNo(DescriptionLbl, MatrixArrayCaptionSet[6]);
                    ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 6';
                    Visible = Visible6;
                }
                field(Field7; MatrixArrayConditionCellData[7])
                {
                    CaptionClass = '3,' + StrSubstNo(ConditionLbl, MatrixArrayCaptionSet[7]);
                    ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 7';
                    Visible = Visible7;
                }
                field(Field7_Desc; MatrixArrayConditionDescriptionCellData[7])
                {
                    CaptionClass = '3,' + StrSubstNo(DescriptionLbl, MatrixArrayCaptionSet[7]);
                    ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 7';
                    Visible = Visible7;
                }
                field(Field8; MatrixArrayConditionCellData[8])
                {
                    CaptionClass = '3,' + StrSubstNo(ConditionLbl, MatrixArrayCaptionSet[8]);
                    ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 8';
                    Visible = Visible8;
                }
                field(Field8_Desc; MatrixArrayConditionDescriptionCellData[8])
                {
                    CaptionClass = '3,' + StrSubstNo(DescriptionLbl, MatrixArrayCaptionSet[8]);
                    ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 8';
                    Visible = Visible8;
                }
                field(Field9; MatrixArrayConditionCellData[9])
                {
                    CaptionClass = '3,' + StrSubstNo(ConditionLbl, MatrixArrayCaptionSet[9]);
                    ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 9';
                    Visible = Visible9;
                }
                field(Field9_Desc; MatrixArrayConditionDescriptionCellData[9])
                {
                    CaptionClass = '3,' + StrSubstNo(DescriptionLbl, MatrixArrayCaptionSet[9]);
                    ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 9';
                    Visible = Visible9;
                }
                field(Field10; MatrixArrayConditionCellData[10])
                {
                    CaptionClass = '3,' + StrSubstNo(ConditionLbl, MatrixArrayCaptionSet[10]);
                    ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 10';
                    Visible = Visible10;
                }
                field(Field10_Desc; MatrixArrayConditionDescriptionCellData[10])
                {
                    CaptionClass = '3,' + StrSubstNo(DescriptionLbl, MatrixArrayCaptionSet[10]);
                    ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 10';
                    Visible = Visible10;
                }
                field("Lookup Table No."; Rec."Lookup Table No.")
                {
                    Visible = false;
                }
                field("Lookup Table Name"; Rec."Lookup Table Caption")
                {
                    Visible = false;
                }
                field("Lookup Field No."; Rec."Lookup Field No.")
                {
                    Visible = false;
                }
                field("Lookup Field Name"; Rec."Lookup Field Caption")
                {
                    Visible = false;
                }
                field("Lookup Table Filter"; Rec."Lookup Table Filter")
                {
                    Visible = false;
                }
            }
        }
        area(FactBoxes)
        {
            systempart(RecordLinks; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(RecordNotes; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DeleteRecordSafe)
            {
                Caption = 'Delete';
                Image = Delete;
                Scope = Repeater;
                ToolTip = 'Deletes this test. A test can only be deleted if it is not being used on an existing inspection.';

                trigger OnAction()
                begin
                    Rec.CheckDeleteConstraints(true);
                    Rec.Delete(true);
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            actionref(DeleteRecordSafe_Promoted; DeleteRecordSafe)
            {
            }
        }
    }

    var
        QltyResultConditionMgmt: Codeunit "Qlty. Result Condition Mgmt.";
        MatrixSourceRecordId: array[10] of RecordId;
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

    trigger OnOpenPage()
    begin
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        Rec.CheckDeleteConstraints(true);
    end;

    trigger OnAfterGetRecord()
    begin
        UpdateRowData();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateRowData();
    end;

    local procedure UpdateRowData()
    begin
        QltyResultConditionMgmt.GetPromotedResultsForTest(Rec, MatrixSourceRecordId, MatrixArrayConditionCellData, MatrixArrayConditionDescriptionCellData, MatrixArrayCaptionSet, MatrixVisibleState);
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
    begin
        QltyIResultConditConf.Get(MatrixSourceRecordId[Matrix]);
        QltyIResultConditConf.Validate(Condition, MatrixArrayConditionCellData[Matrix]);
        QltyIResultConditConf.Modify(true);
        CurrPage.Update(false);
    end;

    local procedure UpdateMatrixDataConditionDescription(Matrix: Integer)
    var
        QltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
    begin
        QltyIResultConditConf.Get(MatrixSourceRecordId[Matrix]);
        QltyIResultConditConf.Validate("Condition Description", MatrixArrayConditionDescriptionCellData[Matrix]);
        QltyIResultConditConf.Modify(true);
        CurrPage.Update(false);
    end;

    procedure AssistEditCondition(Matrix: Integer)
    var
        QltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        QltyInspectionTemplateEdit: Page "Qlty. Inspection Template Edit";
        Expression: Text;
    begin
        Expression := MatrixArrayConditionCellData[Matrix];
        if QltyInspectionTemplateEdit.RunModalWith(Database::"Qlty. Inspection Header", '', Expression) in [Action::LookupOK, Action::OK, Action::Yes] then begin
            MatrixArrayConditionCellData[Matrix] := CopyStr(Expression, 1, MaxStrLen(QltyIResultConditConf.Condition));
            UpdateMatrixDataCondition(Matrix);
        end;
    end;

    procedure AssistEditConditionDescription(Matrix: Integer)
    var
        QltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        QltyInspectionTemplateEdit: Page "Qlty. Inspection Template Edit";
        Expression: Text;
    begin
        Expression := MatrixArrayConditionDescriptionCellData[Matrix];
        if QltyInspectionTemplateEdit.RunModalWith(Database::"Qlty. Inspection Header", '', Expression) in [Action::LookupOK, Action::OK, Action::Yes] then begin
            MatrixArrayConditionDescriptionCellData[Matrix] := CopyStr(Expression, 1, MaxStrLen(QltyIResultConditConf.Condition));
            UpdateMatrixDataConditionDescription(Matrix);
        end;
    end;
}
