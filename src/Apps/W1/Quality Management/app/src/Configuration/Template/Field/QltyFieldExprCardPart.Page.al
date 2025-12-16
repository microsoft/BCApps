// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.Template.Field;

using Microsoft.QualityManagement.Configuration.Result;
using Microsoft.QualityManagement.Utilities;

/// <summary>
/// Used to help with expression configuration.
/// </summary>
page 20467 "Qlty. Field Expr. Card Part"
{
    Caption = 'Quality Field Expression Card Part';
    PageType = CardPart;
    SourceTable = "Qlty. Field";
    LinksAllowed = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ApplicationArea = QualityManagement;

    layout
    {
        area(Content)
        {
            field("Code"; Rec.Code)
            {
                Editable = false;
                AboutTitle = 'Code';
                AboutText = 'The short code to identify the test field. You can enter a maximum of 20 characters, both numbers and letters.';
            }
            field(Description; Rec.Description)
            {
                Visible = false;
                AboutTitle = 'Description';
                AboutText = 'The friendly description for the Field. You can enter a maximum of 100 characters, both numbers and letters.';
            }
            field("Expression Formula"; Rec."Expression Formula")
            {
                AboutTitle = 'Expression Formula';
                AboutText = 'Used with expression field types, this contains the formula for the expression content.';
                MultiLine = true;

                trigger OnAssistEdit()
                begin
                    Rec.AssistEditExpressionFormula();
                end;
            }
            field("Default Value"; Rec."Default Value")
            {
                AboutTitle = 'Default Value';
                AboutText = 'A default value to set on the test.';

                trigger OnAssistEdit()
                begin
                    Rec.AssistEditDefaultValue();
                end;
            }
            field("Allowable Values"; Rec."Allowable Values")
            {
                AboutTitle = 'Allowable Values';
                AboutText = 'What the staff inspector can enter and the range of information they can put in. For example if you want a measurement such as a percentage that collects between 0 and 100 you would enter 0..100. This is not the pass or acceptable condition, these are just the technically possible values that the inspector can enter. You would then enter a passing condition in your result conditions. If you had a result of Pass being 80 to 100, you would then configure 80..100 for that result.';

                trigger OnAssistEdit()
                begin
                    Rec.AssistEditAllowableValues();
                end;
            }
            field(ChooseUOM; QltyField."Unit of Measure Code")
            {
                ShowCaption = true;
            }
            group(GroupSeparator_a)
            {
                Caption = ' ';
            }
            label(lblInfo)
            {
                Caption = ' ';
            }
            group(SettingsForPassConditions)
            {
                Caption = 'Field Conditions';

                label(lblInfo2)
                {
                    ApplicationArea = All;
                    Caption = 'In this section you will define conditions for results, such as pass results.';
                }
                group(SettingsForNothingVisible)
                {
                    ShowCaption = true;
                    Visible = not Visible1;
                    Caption = ' ';

                    label(lblgrpNothingVisibleInfo)
                    {
                        ApplicationArea = All;
                        Caption = 'There are no results available to display.';
                    }
                }
                group(SettingsForVisible1)
                {
                    ShowCaption = false;
                    Visible = Visible1;
                    Caption = ' ';

                    label(Visible1lblInfo)
                    {
                        ApplicationArea = All;
                        Caption = ' ';
                    }
                    group(SettingsForVisible1Advanced)
                    {
                        ShowCaption = false;
                        Caption = ' ';

                        field(Field1; MatrixArrayConditionCellData[1])
                        {
                            ColumnSpan = 2;
                            CaptionClass = '3,' + MatrixArrayCaptionSet[1] + ' Cond.';
                            ToolTip = 'Specifies a field condition for a promoted result. This is dynamic based on the promoted results, this is result condition 1';
                            Editable = Visible1;

                            trigger OnValidate()
                            begin
                                HandleFieldValidateAdvancedSyntax(1);
                            end;
                        }
                    }
                    field(Field1_Desc; MatrixArrayConditionDescriptionCellData[1])
                    {
                        ColumnSpan = 2;
                        CaptionClass = '3,' + MatrixArrayCaptionSet[1] + ' Desc.';
                        ToolTip = 'Specifies a field condition for a promoted result. This is dynamic based on the promoted results, this is result condition 1';
                        Editable = Visible1;

                        trigger OnValidate()
                        begin
                            HandleFieldValidateConditionDescription(1);
                        end;
                    }
                }
                group(SettingsForVisible2)
                {
                    ShowCaption = false;
                    Visible = Visible2;

                    group(SettingsForVisible2Advanced)
                    {
                        ShowCaption = false;

                        field(Field2; MatrixArrayConditionCellData[2])
                        {
                            CaptionClass = '3,' + MatrixArrayCaptionSet[2] + ' Cond.';
                            ToolTip = 'Specifies a field condition for a promoted result. This is dynamic based on the promoted results, this is result condition 2';
                            Editable = Visible2;

                            trigger OnValidate()
                            begin
                                HandleFieldValidateAdvancedSyntax(2);
                            end;
                        }
                    }
                    field(Field2_Desc; MatrixArrayConditionDescriptionCellData[2])
                    {
                        CaptionClass = '3,' + MatrixArrayCaptionSet[2] + ' Desc.';
                        ToolTip = 'Specifies a field condition for a promoted result. This is dynamic based on the promoted results, this is result condition 2';
                        Editable = Visible2;

                        trigger OnValidate()
                        begin
                            HandleFieldValidateConditionDescription(2);
                        end;
                    }
                }
                group(SettingsForVisible3)
                {
                    ShowCaption = false;
                    Visible = Visible3;

                    group(SettingsForVisible3Advanced)
                    {
                        ShowCaption = false;
                        field(Field3; MatrixArrayConditionCellData[3])
                        {
                            CaptionClass = '3,' + MatrixArrayCaptionSet[3] + ' Cond.';
                            ToolTip = 'Specifies a field condition for a promoted result. This is dynamic based on the promoted results, this is result condition 1';
                            Editable = Visible3;

                            trigger OnValidate()
                            begin
                                HandleFieldValidateAdvancedSyntax(3);
                            end;
                        }
                    }
                    field(Field3_Desc; MatrixArrayConditionDescriptionCellData[3])
                    {
                        CaptionClass = '3,' + MatrixArrayCaptionSet[3] + ' Desc.';
                        ToolTip = 'Specifies a field condition for a promoted result. This is dynamic based on the promoted results, this is result condition 3';
                        Editable = Visible3;

                        trigger OnValidate()
                        begin
                            HandleFieldValidateConditionDescription(3);
                        end;
                    }
                }
                group(SettingsForVisible4)
                {
                    ShowCaption = false;
                    Visible = Visible4;

                    field(Field4_Desc; MatrixArrayConditionDescriptionCellData[4])
                    {
                        CaptionClass = '3,' + MatrixArrayCaptionSet[4] + ' Desc.';
                        ToolTip = 'Specifies a field condition for a promoted result. This is dynamic based on the promoted results, this is result condition 3';
                        Editable = Visible4;

                        trigger OnValidate()
                        begin
                            HandleFieldValidateConditionDescription(4);
                        end;
                    }
                    group(SettingsForVisible4Advanced)
                    {
                        ShowCaption = false;

                        field(Field4; MatrixArrayConditionCellData[4])
                        {
                            CaptionClass = '3,' + MatrixArrayCaptionSet[4] + ' Cond.';
                            ToolTip = 'Specifies a field condition for a promoted result. This is dynamic based on the promoted results, this is result condition 1';
                            Editable = Visible4;

                            trigger OnValidate()
                            begin
                                HandleFieldValidateAdvancedSyntax(4);
                            end;
                        }
                    }
                }
                group(SettingsForVisible5)
                {
                    ShowCaption = false;
                    Visible = Visible5;

                    field(Field5_Desc; MatrixArrayConditionDescriptionCellData[5])
                    {
                        CaptionClass = '3,' + MatrixArrayCaptionSet[5] + ' Desc.';
                        ToolTip = 'Specifies a field condition for a promoted result. This is dynamic based on the promoted results, this is result condition 3';
                        Editable = Visible5;

                        trigger OnValidate()
                        begin
                            HandleFieldValidateConditionDescription(5);
                        end;
                    }
                    group(SettingsForVisible5Advanced)
                    {
                        ShowCaption = false;

                        field(Field5; MatrixArrayConditionCellData[5])
                        {
                            CaptionClass = '3,' + MatrixArrayCaptionSet[5] + ' Cond.';
                            ToolTip = 'Specifies a field condition for a promoted result. This is dynamic based on the promoted results, this is result condition 1';
                            Editable = Visible5;

                            trigger OnValidate()
                            begin
                                HandleFieldValidateAdvancedSyntax(5);
                            end;
                        }
                    }
                }
                group(SettingsForVisible6)
                {
                    ShowCaption = false;
                    Visible = Visible6;

                    field(Field6_Desc; MatrixArrayConditionDescriptionCellData[6])
                    {
                        CaptionClass = '3,' + MatrixArrayCaptionSet[6] + ' Desc.';
                        ToolTip = 'Specifies a field condition for a promoted result. This is dynamic based on the promoted results, this is result condition 3';
                        Editable = Visible6;

                        trigger OnValidate()
                        begin
                            HandleFieldValidateConditionDescription(6);
                        end;
                    }
                    group(SettingsForVisible6Advanced)
                    {
                        ShowCaption = false;

                        field(Field6; MatrixArrayConditionCellData[6])
                        {
                            CaptionClass = '3,' + MatrixArrayCaptionSet[6] + ' Cond.';
                            ToolTip = 'Specifies a field condition for a promoted result. This is dynamic based on the promoted results, this is result condition 1';
                            Editable = Visible6;

                            trigger OnValidate()
                            begin
                                HandleFieldValidateAdvancedSyntax(6);
                            end;
                        }
                    }
                }
                group(SettingsForVisible7)
                {
                    ShowCaption = false;
                    Visible = Visible7;

                    field(Field7_Desc; MatrixArrayConditionDescriptionCellData[7])
                    {
                        CaptionClass = '3,' + MatrixArrayCaptionSet[7] + ' Desc.';
                        ToolTip = 'Specifies a field condition for a promoted result. This is dynamic based on the promoted results, this is result condition 3';
                        Editable = Visible7;

                        trigger OnValidate()
                        begin
                            HandleFieldValidateConditionDescription(7);
                        end;
                    }
                    group(SettingsForVisible7Advanced)
                    {
                        ShowCaption = false;

                        field(Field7; MatrixArrayConditionCellData[7])
                        {
                            CaptionClass = '3,' + MatrixArrayCaptionSet[7] + ' Cond.';
                            ToolTip = 'Specifies a field condition for a promoted result. This is dynamic based on the promoted results, this is result condition 1';
                            Editable = Visible7;

                            trigger OnValidate()
                            begin
                                HandleFieldValidateAdvancedSyntax(7);
                            end;
                        }
                    }
                }
                group(SettingsForVisible8)
                {
                    ShowCaption = false;
                    Visible = Visible8;

                    field(Field8_Desc; MatrixArrayConditionDescriptionCellData[8])
                    {
                        CaptionClass = '3,' + MatrixArrayCaptionSet[8] + ' Desc.';
                        ToolTip = 'Specifies a field condition for a promoted result. This is dynamic based on the promoted results, this is result condition 3';
                        Editable = Visible8;

                        trigger OnValidate()
                        begin
                            HandleFieldValidateConditionDescription(8);
                        end;
                    }
                    group(SettingsForVisible8Advanced)
                    {
                        ShowCaption = false;

                        field(Field8; MatrixArrayConditionCellData[8])
                        {
                            CaptionClass = '3,' + MatrixArrayCaptionSet[8] + ' Cond.';
                            ToolTip = 'Specifies a field condition for a promoted result. This is dynamic based on the promoted results, this is result condition 1';
                            Editable = Visible8;

                            trigger OnValidate()
                            begin
                                HandleFieldValidateAdvancedSyntax(8);
                            end;
                        }
                    }
                }
                group(SettingsForVisible9)
                {
                    ShowCaption = false;
                    Visible = Visible9;

                    field(Field9_Desc; MatrixArrayConditionDescriptionCellData[9])
                    {
                        CaptionClass = '3,' + MatrixArrayCaptionSet[9] + ' Desc.';
                        ToolTip = 'Specifies a field condition for a promoted result. This is dynamic based on the promoted results, this is result condition 3';
                        Editable = Visible9;

                        trigger OnValidate()
                        begin
                            HandleFieldValidateConditionDescription(9);
                        end;
                    }
                    group(SettingsForVisible9Advanced)
                    {
                        ShowCaption = false;

                        field(Field9; MatrixArrayConditionCellData[9])
                        {
                            CaptionClass = '3,' + MatrixArrayCaptionSet[9] + ' Cond.';
                            ToolTip = 'Specifies a field condition for a promoted result. This is dynamic based on the promoted results, this is result condition 1';
                            Editable = Visible9;

                            trigger OnValidate()
                            begin
                                HandleFieldValidateAdvancedSyntax(9);
                            end;
                        }
                    }
                }
                group(SettingsForVisible10)
                {
                    ShowCaption = false;
                    Visible = Visible10;
                    field(Field10_Desc; MatrixArrayConditionDescriptionCellData[10])
                    {
                        CaptionClass = '3,' + MatrixArrayCaptionSet[10] + ' Desc.';
                        ToolTip = 'Specifies a field condition for a promoted result. This is dynamic based on the promoted results, this is result condition 3';
                        Editable = Visible10;

                        trigger OnValidate()
                        begin
                            HandleFieldValidateConditionDescription(10);
                        end;
                    }
                    group(SettingsForVisible10Advanced)
                    {
                        ShowCaption = false;
                        field(Field10; MatrixArrayConditionCellData[10])
                        {
                            CaptionClass = '3,' + MatrixArrayCaptionSet[10] + ' Cond.';
                            ToolTip = 'Specifies a field condition for a promoted result. This is dynamic based on the promoted results, this is result condition 1';
                            Editable = Visible10;

                            trigger OnValidate()
                            begin
                                HandleFieldValidateAdvancedSyntax(10);
                            end;
                        }
                    }
                }
            }
        }
    }

    var
        QltyField: Record "Qlty. Field";
        QltyResultConditionMgmt: Codeunit "Qlty. Result Condition Mgmt.";
        QltyMiscHelpers: Codeunit "Qlty. Misc Helpers";
        MatrixSourceRecordId: array[10] of RecordId;
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
        MatrixMinValue: array[10] of Decimal;
        MatrixMaxValue: array[10] of Decimal;
        MatrixArrayConditionCellData: array[10] of Text;
        MatrixArrayConditionDescriptionCellData: array[10] of Text;
        MatrixArrayCaptionSet: array[10] of Text;
        MatrixVisibleState: array[10] of Boolean;

    procedure LoadExistingField(CurrentField: Code[20]; Update: Boolean)
    begin
        if Rec.Code <> CurrentField then
            if Rec.Get(CurrentField) then;
        Clear(MatrixMinValue);
        Clear(MatrixMaxValue);
        Clear(MatrixArrayConditionCellData);
        Clear(MatrixArrayConditionDescriptionCellData);
        Clear(MatrixArrayCaptionSet);
        Clear(MatrixVisibleState);

        Clear(QltyField);
        if CurrentField = '' then
            exit;

        if not QltyField.Get(CurrentField) then begin
            QltyField.Init();
            QltyField.Code := CurrentField;
            QltyField.Insert();
        end;
        QltyField.SetRecFilter();
        UpdateRowData();
        if Update then
            CurrPage.Update(false);
    end;

    trigger OnInit()
    begin
        Visible1 := true;
        Visible2 := true;
        Visible3 := true;
        Visible4 := true;
        Visible5 := true;
        Visible6 := true;
        Visible7 := true;
        Visible8 := true;
        Visible9 := true;
        Visible10 := true;
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateRowData();
    end;

    local procedure UpdateRowData()
    var
        Iterator: Integer;
    begin
        Clear(MatrixMinValue);
        Clear(MatrixMaxValue);
        Clear(MatrixVisibleState);
        Clear(MatrixArrayConditionCellData);
        Clear(MatrixArrayConditionDescriptionCellData);
        Clear(MatrixArrayCaptionSet);

        if QltyField.Code = '' then
            exit;

        QltyResultConditionMgmt.GetPromotedResultsForField(QltyField, MatrixSourceRecordId, MatrixArrayConditionCellData, MatrixArrayConditionDescriptionCellData, MatrixArrayCaptionSet, MatrixVisibleState);
        for Iterator := 1 to ArrayLen(MatrixArrayConditionCellData) do
            QltyMiscHelpers.AttemptSplitSimpleRangeIntoMinMax(MatrixArrayConditionCellData[Iterator], MatrixMinValue[Iterator], MatrixMaxValue[Iterator]);

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

    local procedure HandleFieldValidateAdvancedSyntax(piMatrix: Integer)
    var
        QltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
    begin
        QltyIResultConditConf.Get(MatrixSourceRecordId[piMatrix]);
        QltyIResultConditConf.Validate(Condition, MatrixArrayConditionCellData[piMatrix]);
        QltyMiscHelpers.AttemptSplitSimpleRangeIntoMinMax(QltyIResultConditConf.Condition, MatrixMinValue[piMatrix], MatrixMaxValue[piMatrix]);
        QltyIResultConditConf.Modify(true);
        LoadExistingField(QltyField.Code, true);
        CurrPage.Update(false);
    end;

    local procedure HandleFieldValidateConditionDescription(piMatrix: Integer)
    var
        QltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
    begin
        QltyIResultConditConf.Get(MatrixSourceRecordId[piMatrix]);
        QltyIResultConditConf.Validate("Condition Description", MatrixArrayConditionDescriptionCellData[piMatrix]);
        QltyIResultConditConf.Modify(true);
        LoadExistingField(QltyField.Code, true);
        CurrPage.Update(false);
    end;
}
