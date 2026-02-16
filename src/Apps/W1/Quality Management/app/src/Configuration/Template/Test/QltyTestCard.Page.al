// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.Template.Test;

using Microsoft.QualityManagement.Configuration.Result;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Document;

/// <summary>
/// This page lets you define data points, questions, measurements, and entries with their allowable values and default passing thresholds. You can later use these tests in Quality Inspection Templates.
/// </summary>
page 20479 "Qlty. Test Card"
{
    Caption = 'Quality Test';
    AboutTitle = 'Configure Available Tests';
    AboutText = 'This page lets you define data points, questions, measurements, and entries with their allowable values and default passing thresholds. You can later use these tests in Quality Inspection Templates.';
    DeleteAllowed = false;
    PageType = Card;
    SourceTable = "Qlty. Test";
    SourceTableView = sorting(Code);
    UsageCategory = None;
    ApplicationArea = QualityManagement;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("Code"; Rec.Code)
                {
                    AboutTitle = 'Code';
                    AboutText = 'The short code to identify the test. You can enter a maximum of 20 characters, both numbers and letters.';
                }
                field(Description; Rec.Description)
                {
                    AboutTitle = 'Description';
                    AboutText = 'The friendly description for the test. You can enter a maximum of 100 characters, both numbers and letters.';
                    ShowMandatory = true;
                }
                field("Test Value Type"; Rec."Test Value Type")
                {
                    AboutTitle = 'Test Value Type';
                    AboutText = 'Specifies the data type of the values you can enter or select for this test. Use Decimal for numerical measurements. Use Choice to give a list of options to choose from. If you want to choose options from an existing table, use Table Lookup.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field("Expression Formula"; Rec."Expression Formula")
                {
                    AboutTitle = 'Expression Formula';
                    AboutText = 'Used with expression test value types, this contains the formula for the expression content.';
                    MultiLine = true;
                    Editable = IsExpressionFormulaEditable;

                    trigger OnAssistEdit()
                    begin
                        if IsExpressionFormulaEditable then
                            Rec.AssistEditExpressionFormula()
                        else
                            Message(StrSubstNo(NotEditableLbl, Rec.FieldCaption(Rec."Expression Formula"), Rec.FieldCaption(Rec."Test Value Type")));
                    end;
                }
                group(Values)
                {
                    ShowCaption = false;

                    field("Allowable Values"; Rec."Allowable Values")
                    {
                        Editable = IsAllowableValuesEditable;
                        AboutTitle = 'Allowable Values';
                        AboutText = 'What the staff inspector can enter and the range of information they can put in. For example if you want a measurement such as a percentage that collects between 0 and 100 you would enter 0..100. This is not the pass or acceptable condition, these are just the technically possible values that the inspector can enter. You would then enter a passing condition in your result conditions. If you had a result of Pass being 80 to 100, you would then configure 80..100 for that result.';

                        trigger OnAssistEdit()
                        begin
                            Rec.AssistEditAllowableValues();
                        end;
                    }
                    field("Default Value"; Rec."Default Value")
                    {
                        AboutTitle = 'Default Value';
                        AboutText = 'A default value to set on the inspection.';

                        trigger OnAssistEdit()
                        begin
                            Rec.AssistEditDefaultValue();
                        end;
                    }
                    field("Unit of Measure Code"; Rec."Unit of Measure Code")
                    {
                        AboutTitle = 'Unit of Measure Code';
                        AboutText = 'The unit of measure for the measurement.';
                    }
                    field("Case Sensitive"; Rec."Case Sensitive")
                    {
                        AboutTitle = 'Case Sensitivity';
                        AboutText = 'Choose if case sensitivity will be enabled for text based fields.';
                    }
                }
            }
            group(Results)
            {
                Caption = 'Result Conditions';

                group(ResultGroup1)
                {
                    ShowCaption = false;

                    field(Field1; MatrixArrayConditionCellData[1])
                    {
                        CaptionClass = '3,' + StrSubstNo(ConditionLbl, MatrixArrayCaptionSet[1]);
                        ToolTip = 'Specifies the passing condition for this result. If you had a result of Pass being 80 to 100, you would then configure 80..100 here.';
                        AboutTitle = 'Result Condition Expression';
                        AboutText = 'The passing condition for this result. If you had a result of Pass being 80 to 100, you would then configure 80..100 here.';
                        Visible = Visible1;
                        Editable = EditableResult;

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
                        ToolTip = 'Specifies a description for people of this result condition. If you had a result of Pass being 80 to 100, you would put in text describing this. This text will be visible when recording inspections and will show up on the Certificate of Analysis.';
                        AboutTitle = 'Result Condition Description';
                        AboutText = 'A description for people of this result condition. If you had a result of Pass being 80 to 100, you would put in text describing this. This text will be visible when recording inspections and will show up on the Certificate of Analysis.';
                        Visible = Visible1;
                        Editable = EditableResult;

                        trigger OnValidate()
                        begin
                            UpdateMatrixDataConditionDescription(1);
                        end;

                        trigger OnAssistEdit()
                        begin
                            AssistEditConditionDescription(1);
                        end;
                    }
                }
                group(ResultGroup2)
                {
                    ShowCaption = false;

                    field(Field2; MatrixArrayConditionCellData[2])
                    {
                        CaptionClass = '3,' + StrSubstNo(ConditionLbl, MatrixArrayCaptionSet[2]);
                        ToolTip = 'Specifies the passing condition for this result. If you had a result of Pass being 80 to 100, you would then configure 80..100 here.';
                        AboutTitle = 'Result Condition Expression';
                        AboutText = 'The passing condition for this result. If you had a result of Pass being 80 to 100, you would then configure 80..100 here.';
                        Visible = Visible2;
                        Editable = EditableResult;

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
                        ToolTip = 'Specifies a description for people of this result condition. If you had a result of Pass being 80 to 100, you would put in text describing this. This text will be visible when recording inspections and will show up on the Certificate of Analysis.';
                        AboutTitle = 'Result Condition Description';
                        AboutText = 'A description for people of this result condition. If you had a result of Pass being 80 to 100, you would put in text describing this. This text will be visible when recording inspections and will show up on the Certificate of Analysis.';
                        Visible = Visible2;
                        Editable = EditableResult;

                        trigger OnValidate()
                        begin
                            UpdateMatrixDataConditionDescription(2);
                        end;

                        trigger OnAssistEdit()
                        begin
                            AssistEditConditionDescription(2);
                        end;
                    }
                }
                group(ResultGroup3)
                {
                    ShowCaption = false;

                    field(Field3; MatrixArrayConditionCellData[3])
                    {
                        CaptionClass = '3,' + StrSubstNo(ConditionLbl, MatrixArrayCaptionSet[3]);
                        ToolTip = 'Specifies the passing condition for this result. If you had a result of Pass being 80 to 100, you would then configure 80..100 here.';
                        AboutTitle = 'Result Condition Expression';
                        AboutText = 'The passing condition for this result. If you had a result of Pass being 80 to 100, you would then configure 80..100 here.';
                        Visible = Visible3;
                        Editable = EditableResult;

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
                        Editable = EditableResult;
                        ToolTip = 'Specifies a description for people of this result condition. If you had a result of Pass being 80 to 100, you would put in text describing this. This text will be visible when recording inspections and will show up on the Certificate of Analysis.';
                        AboutTitle = 'Result Condition Description';
                        AboutText = 'A description for people of this result condition. If you had a result of Pass being 80 to 100, you would put in text describing this. This text will be visible when recording inspections and will show up on the Certificate of Analysis.';
                        Visible = Visible3;

                        trigger OnValidate()
                        begin
                            UpdateMatrixDataConditionDescription(3);
                        end;

                        trigger OnAssistEdit()
                        begin
                            AssistEditConditionDescription(3);
                        end;
                    }
                }
                group(ResultGroup4)
                {
                    ShowCaption = false;

                    field(Field4; MatrixArrayConditionCellData[4])
                    {
                        CaptionClass = '3,' + StrSubstNo(ConditionLbl, MatrixArrayCaptionSet[4]);
                        ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 4';
                        Visible = Visible4;
                        Editable = EditableResult;

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
                        Editable = EditableResult;

                        trigger OnValidate()
                        begin
                            UpdateMatrixDataConditionDescription(4);
                        end;

                        trigger OnAssistEdit()
                        begin
                            AssistEditConditionDescription(4);
                        end;
                    }
                }
                group(ResultGroup5)
                {
                    ShowCaption = false;

                    field(Field5; MatrixArrayConditionCellData[5])
                    {
                        CaptionClass = '3,' + StrSubstNo(ConditionLbl, MatrixArrayCaptionSet[5]);
                        ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 5';
                        Visible = Visible5;
                        Editable = EditableResult;

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
                        Editable = EditableResult;

                        trigger OnValidate()
                        begin
                            UpdateMatrixDataConditionDescription(5);
                        end;

                        trigger OnAssistEdit()
                        begin
                            AssistEditConditionDescription(5);
                        end;
                    }
                }
                group(ResultGroup6)
                {
                    ShowCaption = false;

                    field(Field6; MatrixArrayConditionCellData[6])
                    {
                        CaptionClass = '3,' + StrSubstNo(ConditionLbl, MatrixArrayCaptionSet[6]);
                        ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 6';
                        Visible = Visible6;
                        Editable = EditableResult;

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
                        Editable = EditableResult;

                        trigger OnValidate()
                        begin
                            UpdateMatrixDataConditionDescription(6);
                        end;

                        trigger OnAssistEdit()
                        begin
                            AssistEditConditionDescription(6);
                        end;
                    }
                }
                group(ResultGroup7)
                {
                    ShowCaption = false;

                    field(Field7; MatrixArrayConditionCellData[7])
                    {
                        CaptionClass = '3,' + StrSubstNo(ConditionLbl, MatrixArrayCaptionSet[7]);
                        ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 7';
                        Visible = Visible7;
                        Editable = EditableResult;

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
                        Editable = EditableResult;

                        trigger OnValidate()
                        begin
                            UpdateMatrixDataConditionDescription(7);
                        end;

                        trigger OnAssistEdit()
                        begin
                            AssistEditConditionDescription(7);
                        end;
                    }
                }
                group(ResultGroup8)
                {
                    ShowCaption = false;

                    field(Field8; MatrixArrayConditionCellData[8])
                    {
                        CaptionClass = '3,' + StrSubstNo(ConditionLbl, MatrixArrayCaptionSet[8]);
                        ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 8';
                        Visible = Visible8;
                        Editable = EditableResult;

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
                        Editable = EditableResult;

                        trigger OnValidate()
                        begin
                            UpdateMatrixDataConditionDescription(8);
                        end;

                        trigger OnAssistEdit()
                        begin
                            AssistEditConditionDescription(8);
                        end;
                    }
                }
                group(ResultGroup9)
                {
                    ShowCaption = false;

                    field(Field9; MatrixArrayConditionCellData[9])
                    {
                        CaptionClass = '3,' + StrSubstNo(ConditionLbl, MatrixArrayCaptionSet[9]);
                        ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 9';
                        Visible = Visible9;
                        Editable = EditableResult;

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
                        Editable = EditableResult;

                        trigger OnValidate()
                        begin
                            UpdateMatrixDataConditionDescription(9);
                        end;

                        trigger OnAssistEdit()
                        begin
                            AssistEditConditionDescription(9);
                        end;
                    }
                }
                group(ResultGroup10)
                {
                    ShowCaption = false;

                    field(Field10; MatrixArrayConditionCellData[10])
                    {
                        CaptionClass = '3,' + StrSubstNo(ConditionLbl, MatrixArrayCaptionSet[10]);
                        ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 10';
                        Visible = Visible10;
                        Editable = EditableResult;

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
                        Editable = EditableResult;

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
            group(TableLookupConfiguration)
            {
                Caption = 'Table Lookup Configuration';

                group(TableLookup)
                {
                    ShowCaption = false;

                    field("Lookup Table No."; Rec."Lookup Table No.")
                    {
                        Editable = IsLookupField;
                        AboutTitle = 'Lookup Table No.';
                        AboutText = 'When using a table lookup as a data type then this defines which table you are looking up. For example, if you want to show a list of available reason codes from the reason code table then you would use table 231 "Reason Code" here.';
                    }
                    field("Lookup Table Name"; Rec."Lookup Table Caption")
                    {
                        Editable = IsLookupField;
                        AboutTitle = 'Lookup Table No.';
                        AboutText = 'The name of the lookup table. When using a table lookup as a data type then this is the name of the table that you are looking up. For example, if you want to show a list of available reason codes from the reason code table then you would use table 231 "Reason Code" here.';
                    }
                    field("Lookup Table Filter"; Rec."Lookup Table Filter")
                    {
                        Editable = IsLookupField;
                        AboutTitle = 'Lookup Table Filter';
                        AboutText = 'This allows you to restrict which data are available from the Lookup Table by using a standard Business Central filter expression. For example if you were using table 231 "Reason Code" as your lookup table and wanted to restrict the options to codes that started with "R" then you could enter: where("Code"=filter(R*))';

                        trigger OnAssistEdit()
                        begin
                            if IsLookupField then
                                Rec.AssistEditLookupTableFilter();
                        end;
                    }
                }
                group(FieldLookup)
                {
                    ShowCaption = false;

                    field("Lookup Field No."; Rec."Lookup Field No.")
                    {
                        Editable = IsLookupField;
                        AboutTitle = 'Lookup Field No.';
                        AboutText = 'This is the field within the Lookup Table to use for the lookup. For example if you had table 231 "Reason Code" as your lookup table, then you could use from the "Reason Code" table field "1" which represents the field "Code" on that table. When someone is recording an inspection, and choosing the test value they would then see as options the values from this field.';
                    }
                    field("Lookup Field Name"; Rec."Lookup Field Caption")
                    {
                        Editable = IsLookupField;
                        AboutTitle = 'Lookup Field Name';
                        AboutText = 'This is the name of the field within the Lookup Table to use for the lookup. For example if you had table 231 "Reason Code" as your lookup table, and also were using field "1" as the Lookup Field (which represents the field "Code" on that table) then this would show "Code"';
                    }
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
        EditableResult: Boolean;
        IsAllowableValuesEditable: Boolean;
        IsLookupField: Boolean;
        DescriptionLbl: Label '%1 Description', Comment = '%1 = Matrix field caption';
        ConditionLbl: Label '%1 Condition', Comment = '%1 = Matrix field caption';
        IsExpressionFormulaEditable: Boolean;
        NotEditableLbl: Label 'The %1 field is not editable for the selected %2.', Comment = '%1 = Expression Formula, %2 = Test Value Type';

    trigger OnOpenPage()
    begin
        UpdateRowData();
    end;

    trigger OnAfterGetRecord()
    begin
        UpdateRowData();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateRowData();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        UpdateRowData();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction in [Action::OK, Action::LookupOK] then
            if Rec.Code <> '' then
                Rec.TestField(Description);
        exit(true);
    end;

    local procedure UpdateRowData()
    begin
        IsAllowableValuesEditable := not (Rec."Test Value Type" in [Rec."Test Value Type"::"Value Type Table Lookup"]);
        IsLookupField := (Rec."Test Value Type" in [Rec."Test Value Type"::"Value Type Table Lookup"]);

        if Rec.Code = '' then
            QltyResultConditionMgmt.GetDefaultPromotedResults(false, MatrixSourceRecordId, MatrixArrayConditionCellData, MatrixArrayConditionDescriptionCellData, MatrixArrayCaptionSet, MatrixVisibleState)
        else begin
            QltyResultConditionMgmt.GetPromotedResultsForTest(Rec, MatrixSourceRecordId, MatrixArrayConditionCellData, MatrixArrayConditionDescriptionCellData, MatrixArrayCaptionSet, MatrixVisibleState);
            if not MatrixVisibleState[1] then
                QltyResultConditionMgmt.GetDefaultPromotedResults(false, MatrixSourceRecordId, MatrixArrayConditionCellData, MatrixArrayConditionDescriptionCellData, MatrixArrayCaptionSet, MatrixVisibleState);
        end;

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

        EditableResult := (Rec.Code <> '') and (CurrPage.Editable) and (Visible1) and (MatrixArrayCaptionSet[1] <> '');

        IsExpressionFormulaEditable := (Rec."Test Value Type" = Rec."Test Value Type"::"Value Type Text Expression");
    end;

    local procedure UpdateMatrixDataCondition(Matrix: Integer)
    var
        QltyInspectionResult: Record "Qlty. Inspection Result";
        QltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
    begin
        case MatrixSourceRecordId[Matrix].TableNo() of
            Database::"Qlty. I. Result Condit. Conf.":
                begin
                    QltyIResultConditConf.Get(MatrixSourceRecordId[Matrix]);

                    if StrLen(MatrixArrayConditionCellData[Matrix]) > MaxStrLen(QltyIResultConditConf.Condition) then
                        MatrixArrayConditionCellData[Matrix] := CopyStr(MatrixArrayConditionCellData[Matrix], 1, MaxStrLen(QltyIResultConditConf.Condition));

                    QltyIResultConditConf.Validate(Condition, MatrixArrayConditionCellData[Matrix]);
                    QltyIResultConditConf.Modify(true);
                end;
            Database::"Qlty. Inspection Result":
                begin
                    QltyInspectionResult.Get(MatrixSourceRecordId[Matrix]);
                    Rec.SetResultCondition(QltyInspectionResult.Code, MatrixArrayConditionCellData[Matrix], true);
                    Rec.Modify();
                end;
        end;
        CurrPage.Update(false);
    end;

    local procedure UpdateMatrixDataConditionDescription(Matrix: Integer)
    var
        QltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        PreferredChange: Text;
    begin
        PreferredChange := MatrixArrayConditionDescriptionCellData[Matrix];
        if MatrixSourceRecordId[Matrix].TableNo() = Database::"Qlty. Inspection Result" then
            UpdateRowData();

        case MatrixSourceRecordId[Matrix].TableNo() of
            Database::"Qlty. I. Result Condit. Conf.":
                begin
                    if StrLen(MatrixArrayConditionDescriptionCellData[Matrix]) > MaxStrLen(QltyIResultConditConf."Condition Description") then
                        MatrixArrayConditionDescriptionCellData[Matrix] := CopyStr(MatrixArrayConditionDescriptionCellData[Matrix], 1, MaxStrLen(QltyIResultConditConf."Condition Description"));

                    QltyIResultConditConf.Get(MatrixSourceRecordId[Matrix]);
                    QltyIResultConditConf.Validate("Condition Description", PreferredChange);
                    QltyIResultConditConf.Modify(true);
                end;
        end;
        CurrPage.Update(false);
    end;

    /// <summary>
    /// Starts the assist edit dialog for condition.
    /// </summary>
    /// <param name="Matrix"></param>
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

    /// <summary>
    /// Starts the assist-edit dialog for the condition description.
    /// </summary>
    /// <param name="Matrix"></param>
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
