// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.Template.Field;

using Microsoft.QualityManagement.Configuration.Grade;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Utilities;

/// <summary>
/// A card part to assist with numerical configuration.
/// </summary>
page 20434 "Qlty. Field Number Card Part"
{
    Caption = 'Quality Field Number Card Part';
    PageType = CardPart;
    LinksAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    ApplicationArea = QualityManagement;

    layout
    {
        area(Content)
        {
            field("Default Value"; DefaultValue)
            {
                Caption = 'Default Value';
                ToolTip = 'Specifies a default value to set on the test.';
                AboutTitle = 'Default Value';
                AboutText = 'A default value to set on the test.';

                trigger OnValidate()
                begin
                    ValidateDefaultValue();
                end;

                trigger OnAssistEdit()
                begin
                    AssistEditDefaultValue();
                end;
            }
            group(SettingsForAllowedValues)
            {
                Caption = 'What are the allowed values?';
                AboutTitle = 'Allowed Values';
                AboutText = 'Allowed values are not what defines a "Pass" state. Allowed values are possible values. For example, if you were collecting a thickness measurement then you might have allowed values between 1 and 100, however "Pass" conditions values would potentially be a different number range, such as between 10 and 20.';

                field(ChooseRangeType; RangeNumberType)
                {
                    OptionCaption = 'A range of numbers,Advanced';
                    Caption = 'Is this a range of numbers?';
                    ShowCaption = true;
                    ToolTip = 'Specifies if this a range of numbers, or something more complex.';

                    trigger OnValidate()
                    begin
                        HandleFieldValidateNumberRangeType();
                    end;
                }
            }
            group(SettingsForSimpleRange)
            {
                Caption = 'Set the range of allowed values';
                InstructionalText = 'Enter the minimum and maximum allowed values. Allowed values are possible values. For example, if you were collecting a thickness measurement then you might have allowed values between 1 and 100. "Pass" conditions values would potentially be a different number range, such as between 10 and 20.';
                Visible = ShowSimpleRange;

                field(ChooseMinAllowed; MinAllowed)
                {
                    ToolTip = 'Specifies the minimum allowed value for this field. This is not the "Pass" state.';
                    Caption = 'Minimum';
                    ShowCaption = true;
                    AutoFormatType = 0;
                    ShowMandatory = true;

                    trigger OnValidate()
                    begin
                        HandleFieldValidateAllowedRanges();
                    end;
                }
                field(ChooseMaxAllowed; MaxAllowed)
                {
                    ToolTip = 'Specifies the maximum allowed value for this field. This is not the "Pass" state.';
                    Caption = 'Maximum';
                    ShowCaption = true;
                    AutoFormatType = 0;
                    ShowMandatory = true;

                    trigger OnValidate()
                    begin
                        HandleFieldValidateAllowedRanges();
                    end;
                }
            }
            group(AdvancedConfiguration)
            {
                Caption = 'Advanced Configuration for Allowed Values';
                InstructionalText = 'Enter the allowed number syntax. For example 1 through 3 would be 1..3. More than 5 would be >5. 1 or 2 would be 1|2. Full details are available at https://learn.microsoft.com/en-ca/dynamics365/business-central/ui-enter-criteria-filters';
                AboutTitle = 'Advanced range.';
                AboutText = 'Enter the allowed number syntax. For example 1 through 3 would be 1..3. More than 5 would be >5. 1 or 2 would be 1|2. Full details are available at https://learn.microsoft.com/en-ca/dynamics365/business-central/ui-enter-criteria-filters';
                Visible = ShowAdvanced;

                field(ChooseAdvanced; AdvancedRange)
                {
                    ToolTip = 'Enter the allowed number syntax. For example 1 through 3 would be 1..3. More than 5 would be >5. 1 or 2 would be 1|2. Full details are available at https://learn.microsoft.com/en-ca/dynamics365/business-central/ui-enter-criteria-filters';
                    Caption = 'Advanced Range';
                    ShowCaption = false;
                    ShowMandatory = true;

                    trigger OnAssistEdit()
                    begin
                        HandleAssistEditAdvancedAllowableValuesRange();
                    end;

                    trigger OnValidate()
                    begin
                        HandleFieldValidateAllowedRanges();
                    end;
                }

            }
            group(GroupSeparator_a)
            {
                Caption = ' ';
            }
            label(lblInfo)
            {
                ApplicationArea = All;
                Caption = ' ';
            }
            group(SettingsForPassConditions)
            {
                Caption = 'Field Conditions';

                label(lblInfo2)
                {
                    ApplicationArea = All;
                    Caption = 'In this section you will define conditions for grades, such as pass grades.';
                }
                group(SettingsForNothingVisible)
                {
                    ShowCaption = true;
                    Visible = not Visible1;
                    Caption = ' ';
                    label(lblgrpNothingVisibleInfo)
                    {
                        ApplicationArea = All;
                        Caption = 'There are no grades available to display.';
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
                        Visible = ShowAdvanced;
                        ShowCaption = false;
                        Caption = ' ';

                        field(Field1; MatrixArrayConditionCellData[1])
                        {
                            ColumnSpan = 2;
                            ApplicationArea = All;
                            CaptionClass = '3,' + MatrixArrayCaptionSet[1] + ' Cond.';
                            ToolTip = 'Specifies a field condition for a promoted grade. This is dynamic based on the promoted grades, this is grade condition 1';
                            Editable = Visible1;

                            trigger OnValidate()
                            begin
                                HandleFieldValidateAdvancedSyntax(1);
                            end;

                            trigger OnAssistEdit()
                            begin
                                AssistEditCondition(1);
                            end;
                        }
                    }
                    group(SettingsForVisible1Easy)
                    {
                        Visible = ShowSimpleRange;
                        ShowCaption = false;
                        Caption = ' ';

                        field(ChooseMin1; MatrixMinValue[1])
                        {
                            ColumnSpan = 2;
                            ApplicationArea = All;
                            ToolTip = 'Specifies the minimum allowed value for this grade. ';
                            CaptionClass = '3,' + MatrixArrayCaptionSet[1] + ' Min';
                            AutoFormatType = 0;
                            DecimalPlaces = 0 : 5;
                            ShowCaption = true;
                            ShowMandatory = true;

                            trigger OnValidate()
                            begin
                                HandleFieldValidateEasyGrade();
                            end;
                        }
                        field(ChooseMax1; MatrixMaxValue[1])
                        {
                            ColumnSpan = 2;
                            ApplicationArea = All;
                            ToolTip = 'Specifies the maximum allowed value for this grade.';
                            CaptionClass = '3,' + MatrixArrayCaptionSet[1] + ' Max';
                            AutoFormatType = 0;
                            DecimalPlaces = 0 : 5;
                            ShowCaption = true;
                            ShowMandatory = true;

                            trigger OnValidate()
                            begin
                                HandleFieldValidateEasyGrade();
                            end;
                        }
                    }
                    field(Field1_Desc; MatrixArrayConditionDescriptionCellData[1])
                    {
                        ColumnSpan = 2;
                        ApplicationArea = All;
                        CaptionClass = '3,' + MatrixArrayCaptionSet[1] + ' Desc.';
                        ToolTip = 'Specifies a field condition for a promoted grade. This is dynamic based on the promoted grades, this is grade condition 1';
                        Editable = Visible1;

                        trigger OnValidate()
                        begin
                            HandleFieldValidateConditionDescription(1);
                        end;

                        trigger OnAssistEdit()
                        begin
                            AssistEditConditionDescription(1);
                        end;
                    }
                }
                group(SettingsForVisible2)
                {
                    ShowCaption = false;
                    Visible = Visible2;
                    Caption = ' ';

                    group(SettingsForVisible2Advanced)
                    {
                        Visible = ShowAdvanced;
                        ShowCaption = false;

                        field(Field2; MatrixArrayConditionCellData[2])
                        {
                            ApplicationArea = All;
                            CaptionClass = '3,' + MatrixArrayCaptionSet[2] + ' Cond.';
                            ToolTip = 'Specifies a field condition for a promoted grade. This is dynamic based on the promoted grades, this is grade condition 2';
                            Editable = Visible2;

                            trigger OnValidate()
                            begin
                                HandleFieldValidateAdvancedSyntax(2);
                            end;

                            trigger OnAssistEdit()
                            begin
                                AssistEditCondition(2);
                            end;
                        }
                    }
                    group(SettingsForVisible2Easy)
                    {
                        Visible = ShowSimpleRange;
                        ShowCaption = false;

                        field(ChooseMin2; MatrixMinValue[2])
                        {
                            ToolTip = 'Specifies the minimum allowed value for this grade. ';
                            CaptionClass = '3,' + MatrixArrayCaptionSet[2] + ' Min';
                            ShowCaption = true;
                            ShowMandatory = true;
                            AutoFormatType = 0;
                            DecimalPlaces = 0 : 5;

                            trigger OnValidate()
                            begin
                                HandleFieldValidateEasyGrade();
                            end;
                        }
                        field(ChooseMax2; MatrixMaxValue[2])
                        {
                            ToolTip = 'Specifies the maximum allowed value for this grade.';
                            CaptionClass = '3,' + MatrixArrayCaptionSet[2] + ' Max';
                            ShowCaption = true;
                            ShowMandatory = true;
                            AutoFormatType = 0;
                            DecimalPlaces = 0 : 5;

                            trigger OnValidate()
                            begin
                                HandleFieldValidateEasyGrade();
                            end;
                        }
                    }
                    field(Field2_Desc; MatrixArrayConditionDescriptionCellData[2])
                    {
                        CaptionClass = '3,' + MatrixArrayCaptionSet[2] + ' Desc.';
                        ToolTip = 'Specifies a field condition for a promoted grade. This is dynamic based on the promoted grades, this is grade condition 2';
                        Editable = Visible2;

                        trigger OnValidate()
                        begin
                            HandleFieldValidateConditionDescription(2);
                        end;

                        trigger OnAssistEdit()
                        begin
                            AssistEditConditionDescription(2);
                        end;
                    }
                }
                group(SettingsForVisible3)
                {
                    ShowCaption = false;
                    Visible = Visible3;
                    Caption = ' ';

                    group(SettingsForVisible3Advanced)
                    {
                        Visible = ShowAdvanced;
                        ShowCaption = false;
                        field(Field3; MatrixArrayConditionCellData[3])
                        {
                            CaptionClass = '3,' + MatrixArrayCaptionSet[3] + ' Cond.';
                            ToolTip = 'Specifies a field condition for a promoted grade. This is dynamic based on the promoted grades, this is grade condition 1';
                            Editable = Visible3;

                            trigger OnValidate()
                            begin
                                HandleFieldValidateAdvancedSyntax(3);
                            end;

                            trigger OnAssistEdit()
                            begin
                                AssistEditCondition(3);
                            end;
                        }
                    }
                    group(SettingsForVisible3Easy)
                    {
                        Visible = ShowSimpleRange;
                        ShowCaption = false;

                        field(ChooseMin3; MatrixMinValue[3])
                        {
                            ToolTip = 'Specifies the minimum allowed value for this grade. ';
                            CaptionClass = '3,' + MatrixArrayCaptionSet[3] + ' Min';
                            ShowCaption = true;
                            ShowMandatory = true;
                            AutoFormatType = 0;
                            DecimalPlaces = 0 : 5;

                            trigger OnValidate()
                            begin
                                HandleFieldValidateEasyGrade();
                            end;
                        }
                        field(ChooseMax3; MatrixMaxValue[3])
                        {
                            ToolTip = 'Specifies the maximum allowed value for this grade.';
                            CaptionClass = '3,' + MatrixArrayCaptionSet[3] + ' Max';
                            ShowCaption = true;
                            ShowMandatory = true;
                            AutoFormatType = 0;
                            DecimalPlaces = 0 : 5;

                            trigger OnValidate()
                            begin
                                HandleFieldValidateEasyGrade();
                            end;
                        }
                    }
                    field(Field3_Desc; MatrixArrayConditionDescriptionCellData[3])
                    {
                        CaptionClass = '3,' + MatrixArrayCaptionSet[3] + ' Desc.';
                        ToolTip = 'Specifies a field condition for a promoted grade. This is dynamic based on the promoted grades, this is grade condition 3';
                        Editable = Visible3;

                        trigger OnValidate()
                        begin
                            HandleFieldValidateConditionDescription(3);
                        end;

                        trigger OnAssistEdit()
                        begin
                            AssistEditConditionDescription(3);
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
                        ToolTip = 'Specifies a field condition for a promoted grade. This is dynamic based on the promoted grades, this is grade condition 3';
                        Editable = Visible4;

                        trigger OnValidate()
                        begin
                            HandleFieldValidateConditionDescription(4);
                        end;

                        trigger OnAssistEdit()
                        begin
                            AssistEditConditionDescription(4);
                        end;
                    }
                    group(SettingsForVisible4Advanced)
                    {
                        Visible = ShowAdvanced;
                        ShowCaption = false;

                        field(Field4; MatrixArrayConditionCellData[4])
                        {
                            CaptionClass = '3,' + MatrixArrayCaptionSet[4] + ' Cond.';
                            ToolTip = 'Specifies a field condition for a promoted grade. This is dynamic based on the promoted grades, this is grade condition 1';
                            Editable = Visible4;

                            trigger OnValidate()
                            begin
                                HandleFieldValidateAdvancedSyntax(4);
                            end;

                            trigger OnAssistEdit()
                            begin
                                AssistEditCondition(4);
                            end;
                        }
                    }
                    group(SettingsForVisible4Easy)
                    {
                        Visible = ShowSimpleRange;
                        ShowCaption = false;

                        field(ChooseMin4; MatrixMinValue[4])
                        {
                            ToolTip = 'Specifies the minimum allowed value for this grade. ';
                            CaptionClass = '3,' + MatrixArrayCaptionSet[4] + ' Min';
                            ShowCaption = true;
                            ShowMandatory = true;
                            AutoFormatType = 0;
                            DecimalPlaces = 0 : 5;

                            trigger OnValidate()
                            begin
                                HandleFieldValidateEasyGrade();
                            end;
                        }
                        field(ChooseMax4; MatrixMaxValue[4])
                        {
                            ToolTip = 'Specifies the maximum allowed value for this grade.';
                            CaptionClass = '3,' + MatrixArrayCaptionSet[4] + ' Max';
                            ShowCaption = true;
                            ShowMandatory = true;
                            AutoFormatType = 0;
                            DecimalPlaces = 0 : 5;

                            trigger OnValidate()
                            begin
                                HandleFieldValidateEasyGrade();
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
                        ToolTip = 'Specifies a field condition for a promoted grade. This is dynamic based on the promoted grades, this is grade condition 3';
                        Editable = Visible5;

                        trigger OnValidate()
                        begin
                            HandleFieldValidateConditionDescription(5);
                        end;

                        trigger OnAssistEdit()
                        begin
                            AssistEditConditionDescription(5);
                        end;
                    }
                    group(SettingsForVisible5Advanced)
                    {
                        Visible = ShowAdvanced;
                        ShowCaption = false;

                        field(Field5; MatrixArrayConditionCellData[5])
                        {
                            CaptionClass = '3,' + MatrixArrayCaptionSet[5] + ' Cond.';
                            ToolTip = 'Specifies a field condition for a promoted grade. This is dynamic based on the promoted grades, this is grade condition 1';
                            Editable = Visible5;

                            trigger OnValidate()
                            begin
                                HandleFieldValidateAdvancedSyntax(5);
                            end;

                            trigger OnAssistEdit()
                            begin
                                AssistEditCondition(5);
                            end;
                        }
                    }
                    group(SettingsForVisible5Easy)
                    {
                        Visible = ShowSimpleRange;
                        ShowCaption = false;

                        field(ChooseMin5; MatrixMinValue[5])
                        {
                            ToolTip = 'Specifies the minimum allowed value for this grade. ';
                            CaptionClass = '3,' + MatrixArrayCaptionSet[5] + ' Min';
                            ShowCaption = true;
                            ShowMandatory = true;
                            AutoFormatType = 0;
                            DecimalPlaces = 0 : 5;

                            trigger OnValidate()
                            begin
                                HandleFieldValidateEasyGrade();
                            end;
                        }
                        field(ChooseMax5; MatrixMaxValue[5])
                        {
                            ToolTip = 'Specifies the maximum allowed value for this grade.';
                            CaptionClass = '3,' + MatrixArrayCaptionSet[5] + ' Max';
                            ShowCaption = true;
                            ShowMandatory = true;
                            AutoFormatType = 0;
                            DecimalPlaces = 0 : 5;

                            trigger OnValidate()
                            begin
                                HandleFieldValidateEasyGrade();
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
                        ToolTip = 'Specifies a field condition for a promoted grade. This is dynamic based on the promoted grades, this is grade condition 3';
                        Editable = Visible6;

                        trigger OnValidate()
                        begin
                            HandleFieldValidateConditionDescription(6);
                        end;

                        trigger OnAssistEdit()
                        begin
                            AssistEditConditionDescription(6);
                        end;
                    }
                    group(SettingsForVisible6Advanced)
                    {
                        Visible = ShowAdvanced;
                        ShowCaption = false;

                        field(Field6; MatrixArrayConditionCellData[6])
                        {
                            CaptionClass = '3,' + MatrixArrayCaptionSet[6] + ' Cond.';
                            ToolTip = 'Specifies a field condition for a promoted grade. This is dynamic based on the promoted grades, this is grade condition 1';
                            Editable = Visible6;

                            trigger OnValidate()
                            begin
                                HandleFieldValidateAdvancedSyntax(6);
                            end;

                            trigger OnAssistEdit()
                            begin
                                AssistEditCondition(6);
                            end;
                        }
                    }
                    group(SettingsForVisible6Easy)
                    {
                        Visible = ShowSimpleRange;
                        ShowCaption = false;

                        field(ChooseMin6; MatrixMinValue[6])
                        {
                            ToolTip = 'Specifies the minimum allowed value for this grade. ';
                            CaptionClass = '3,' + MatrixArrayCaptionSet[6] + ' Min';
                            ShowCaption = true;
                            ShowMandatory = true;
                            AutoFormatType = 0;
                            DecimalPlaces = 0 : 5;

                            trigger OnValidate()
                            begin
                                HandleFieldValidateEasyGrade();
                            end;
                        }
                        field(ChooseMax6; MatrixMaxValue[6])
                        {
                            ToolTip = 'Specifies the maximum allowed value for this grade.';
                            CaptionClass = '3,' + MatrixArrayCaptionSet[6] + ' Max';
                            ShowCaption = true;
                            ShowMandatory = true;
                            AutoFormatType = 0;
                            DecimalPlaces = 0 : 5;

                            trigger OnValidate()
                            begin
                                HandleFieldValidateEasyGrade();
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
                        ToolTip = 'Specifies a field condition for a promoted grade. This is dynamic based on the promoted grades, this is grade condition 3';
                        Editable = Visible7;

                        trigger OnValidate()
                        begin
                            HandleFieldValidateConditionDescription(7);
                        end;

                        trigger OnAssistEdit()
                        begin
                            AssistEditConditionDescription(7);
                        end;
                    }
                    group(SettingsForVisible7Advanced)
                    {
                        Visible = ShowAdvanced;
                        ShowCaption = false;

                        field(Field7; MatrixArrayConditionCellData[7])
                        {
                            CaptionClass = '3,' + MatrixArrayCaptionSet[7] + ' Cond.';
                            ToolTip = 'Specifies a field condition for a promoted grade. This is dynamic based on the promoted grades, this is grade condition 1';
                            Editable = Visible7;

                            trigger OnValidate()
                            begin
                                HandleFieldValidateAdvancedSyntax(7);
                            end;

                            trigger OnAssistEdit()
                            begin
                                AssistEditCondition(7);
                            end;
                        }
                    }
                    group(SettingsForVisible7Easy)
                    {
                        Visible = ShowSimpleRange;
                        ShowCaption = false;

                        field(ChooseMin7; MatrixMinValue[7])
                        {
                            ToolTip = 'Specifies the minimum allowed value for this grade. ';
                            CaptionClass = '3,' + MatrixArrayCaptionSet[7] + ' Min';
                            ShowCaption = true;
                            ShowMandatory = true;
                            AutoFormatType = 0;
                            DecimalPlaces = 0 : 5;

                            trigger OnValidate()
                            begin
                                HandleFieldValidateEasyGrade();
                            end;
                        }
                        field(ChooseMax7; MatrixMaxValue[7])
                        {
                            ToolTip = 'Specifies the maximum allowed value for this grade.';
                            CaptionClass = '3,' + MatrixArrayCaptionSet[7] + ' Max';
                            ShowCaption = true;
                            ShowMandatory = true;
                            AutoFormatType = 0;
                            DecimalPlaces = 0 : 5;

                            trigger OnValidate()
                            begin
                                HandleFieldValidateEasyGrade();
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
                        ToolTip = 'Specifies a field condition for a promoted grade. This is dynamic based on the promoted grades, this is grade condition 3';
                        Editable = Visible8;

                        trigger OnValidate()
                        begin
                            HandleFieldValidateConditionDescription(8);
                        end;

                        trigger OnAssistEdit()
                        begin
                            AssistEditConditionDescription(8);
                        end;
                    }
                    group(SettingsForVisible8Advanced)
                    {
                        Visible = ShowAdvanced;
                        ShowCaption = false;

                        field(Field8; MatrixArrayConditionCellData[8])
                        {
                            CaptionClass = '3,' + MatrixArrayCaptionSet[8] + ' Cond.';
                            ToolTip = 'Specifies a field condition for a promoted grade. This is dynamic based on the promoted grades, this is grade condition 1';
                            Editable = Visible8;

                            trigger OnValidate()
                            begin
                                HandleFieldValidateAdvancedSyntax(8);
                            end;

                            trigger OnAssistEdit()
                            begin
                                AssistEditCondition(8);
                            end;
                        }
                    }
                    group(SettingsForVisible8Easy)
                    {
                        Visible = ShowSimpleRange;
                        ShowCaption = false;

                        field(ChooseMin8; MatrixMinValue[8])
                        {
                            ToolTip = 'Specifies the minimum allowed value for this grade. ';
                            CaptionClass = '3,' + MatrixArrayCaptionSet[8] + ' Min';
                            ShowCaption = true;
                            ShowMandatory = true;
                            AutoFormatType = 0;
                            DecimalPlaces = 0 : 5;

                            trigger OnValidate()
                            begin
                                HandleFieldValidateEasyGrade();
                            end;
                        }
                        field(ChooseMax8; MatrixMaxValue[8])
                        {
                            ToolTip = 'Specifies the maximum allowed value for this grade.';
                            CaptionClass = '3,' + MatrixArrayCaptionSet[8] + ' Max';
                            ShowCaption = true;
                            ShowMandatory = true;
                            AutoFormatType = 0;
                            DecimalPlaces = 0 : 5;

                            trigger OnValidate()
                            begin
                                HandleFieldValidateEasyGrade();
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
                        ToolTip = 'Specifies a field condition for a promoted grade. This is dynamic based on the promoted grades, this is grade condition 3';
                        Editable = Visible9;

                        trigger OnValidate()
                        begin
                            HandleFieldValidateConditionDescription(9);
                        end;

                        trigger OnAssistEdit()
                        begin
                            AssistEditConditionDescription(9);
                        end;
                    }
                    group(SettingsForVisible9Advanced)
                    {
                        Visible = ShowAdvanced;
                        ShowCaption = false;

                        field(Field9; MatrixArrayConditionCellData[9])
                        {
                            CaptionClass = '3,' + MatrixArrayCaptionSet[9] + ' Cond.';
                            ToolTip = 'Specifies a field condition for a promoted grade. This is dynamic based on the promoted grades, this is grade condition 1';
                            Editable = Visible9;

                            trigger OnValidate()
                            begin
                                HandleFieldValidateAdvancedSyntax(9);
                            end;

                            trigger OnAssistEdit()
                            begin
                                AssistEditCondition(9);
                            end;
                        }
                    }
                    group(SettingsForVisible9Easy)
                    {
                        Visible = ShowSimpleRange;
                        ShowCaption = false;

                        field(ChooseMin9; MatrixMinValue[9])
                        {
                            ToolTip = 'Specifies the minimum allowed value for this grade. ';
                            CaptionClass = '3,' + MatrixArrayCaptionSet[9] + ' Min';
                            ShowCaption = true;
                            ShowMandatory = true;
                            AutoFormatType = 0;
                            DecimalPlaces = 0 : 5;

                            trigger OnValidate()
                            begin
                                HandleFieldValidateEasyGrade();
                            end;
                        }
                        field(ChooseMax9; MatrixMaxValue[9])
                        {
                            ToolTip = 'Specifies the maximum allowed value for this grade.';
                            CaptionClass = '3,' + MatrixArrayCaptionSet[9] + ' Max';
                            ShowCaption = true;
                            ShowMandatory = true;
                            AutoFormatType = 0;
                            DecimalPlaces = 0 : 5;

                            trigger OnValidate()
                            begin
                                HandleFieldValidateEasyGrade();
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
                        ToolTip = 'Specifies a field condition for a promoted grade. This is dynamic based on the promoted grades, this is grade condition 3';
                        Editable = Visible10;

                        trigger OnValidate()
                        begin
                            HandleFieldValidateConditionDescription(10);
                        end;

                        trigger OnAssistEdit()
                        begin
                            AssistEditConditionDescription(10);
                        end;
                    }
                    group(SettingsForVisible10Advanced)
                    {
                        Visible = ShowAdvanced;
                        ShowCaption = false;

                        field(Field10; MatrixArrayConditionCellData[10])
                        {
                            CaptionClass = '3,' + MatrixArrayCaptionSet[10] + ' Cond.';
                            ToolTip = 'Specifies a field condition for a promoted grade. This is dynamic based on the promoted grades, this is grade condition 1';
                            Editable = Visible10;

                            trigger OnValidate()
                            begin
                                HandleFieldValidateAdvancedSyntax(10);
                            end;

                            trigger OnAssistEdit()
                            begin
                                AssistEditCondition(10);
                            end;
                        }
                    }
                    group(SettingsForVisible10Easy)
                    {
                        Visible = ShowSimpleRange;
                        ShowCaption = false;

                        field(ChooseMin10; MatrixMinValue[10])
                        {
                            ToolTip = 'Specifies the minimum allowed value for this grade. ';
                            CaptionClass = '3,' + MatrixArrayCaptionSet[10] + ' Min';
                            ShowCaption = true;
                            ShowMandatory = true;
                            AutoFormatType = 0;
                            DecimalPlaces = 0 : 5;

                            trigger OnValidate()
                            begin
                                HandleFieldValidateEasyGrade();
                            end;
                        }
                        field(ChooseMax10; MatrixMaxValue[10])
                        {
                            ToolTip = 'Specifies the maximum allowed value for this grade.';
                            CaptionClass = '3,' + MatrixArrayCaptionSet[10] + ' Max';
                            ShowCaption = true;
                            ShowMandatory = true;
                            AutoFormatType = 0;
                            DecimalPlaces = 0 : 5;

                            trigger OnValidate()
                            begin
                                HandleFieldValidateEasyGrade();
                            end;
                        }
                    }
                }
            }
            group(SettingsForUOM)
            {
                Caption = 'Unit of Measure';
                AboutTitle = 'Unit of Measure';
                AboutText = 'Optionally set the unit of measure for the field';

                field(ChooseUOM; QltyField."Unit of Measure Code")
                {
                    Caption = 'Optionally set the unit of measure for the field';
                    ShowCaption = true;
                    AssistEdit = true;
                    DrillDown = false;

                    trigger OnValidate()
                    begin
                        QltyField.Modify();
                        LoadExistingField(QltyField.Code);
                    end;

                    trigger OnAssistEdit()
                    var
                        QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
                    begin
                        QltyFilterHelpers.AssistEditUnitOfMeasure(QltyField."Unit of Measure Code");
                        QltyField.Modify();
                        LoadExistingField(QltyField.Code);
                    end;
                }
            }
        }
    }

    var
        QltyField: Record "Qlty. Field";
        QltyGradeConditionMgmt: Codeunit "Qlty. Grade Condition Mgmt.";
        QltyValueParsing: Codeunit "Qlty. Value Parsing";
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
        RangeNumberType: Option "A range of numbers","Advanced";
        ShowSimpleRange: Boolean;
        ShowAdvanced: Boolean;
        MinAllowed: Decimal;
        MaxAllowed: Decimal;
        AdvancedRange: Text;
        DefaultValue: Text[250];
        MatrixMinValue: array[10] of Decimal;
        MatrixMaxValue: array[10] of Decimal;
        MatrixArrayConditionCellData: array[10] of Text;
        MatrixArrayConditionDescriptionCellData: array[10] of Text;
        MatrixArrayCaptionSet: array[10] of Text;
        MatrixVisibleState: array[10] of Boolean;
        QltyFieldIds: List of [Code[20]];
        SimpleRangeTok: Label '%1..%2', Locked = true, Comment = '%1=Min, %2=max';
        RangeNonZeroTok: Label '<>0', Locked = true;
        RangeNonZeroHumanDescriptionTok: Label 'Any entered value.', Locked = true;
        RangeHumanDescriptionTok: Label '%1 to %2', Locked = true, Comment = '%1=Min, %2=max';
        DefaultRangeTok: Label '1..100', Locked = true;

    procedure LoadExistingField(CurrentField: Code[20])
    begin
        Clear(MinAllowed);
        Clear(MaxAllowed);
        Clear(AdvancedRange);
        Clear(MatrixMinValue);
        Clear(MatrixMaxValue);
        Clear(MatrixArrayConditionCellData);
        Clear(MatrixArrayConditionDescriptionCellData);
        Clear(MatrixArrayCaptionSet);
        Clear(MatrixVisibleState);

        if CurrentField = '' then
            exit;

        if not QltyField.Get(CurrentField) then begin
            QltyField.Init();
            QltyField.Code := CurrentField;
            QltyField.Insert();
        end;
        QltyField.SetRecFilter();
        UpdateRowData();
        ReverseEngineerAllowedValuesMinMax();
        HandleFieldValidateNumberRangeType();
        CurrPage.Update(false);
    end;

    trigger OnInit()
    begin
        ShowSimpleRange := true;
        ShowAdvanced := false;
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

    trigger OnOpenPage()
    begin
        ReverseEngineerAllowedValuesMinMax();
        UpdateFieldVisibilityState();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateRowData();
        ReverseEngineerAllowedValuesMinMax();
    end;

    trigger OnAfterGetRecord()
    begin
        UpdateFieldVisibilityState();
    end;

    local procedure ReverseEngineerAllowedValuesMinMax()
    begin
        Clear(MinAllowed);
        Clear(MaxAllowed);
        Clear(AdvancedRange);

        RangeNumberType := RangeNumberType::"A range of numbers";
        if QltyFieldIds.Contains(QltyField.Code) then
            RangeNumberType := RangeNumberType::Advanced;

        AdvancedRange := QltyField."Allowable Values";

        if QltyField.Code = '' then
            exit;

        if AdvancedRange = '' then
            if QltyField."Wizard Internal" = QltyField."Wizard Internal"::"In Progress" then
                AdvancedRange := DefaultRangeTok;

        if QltyValueParsing.AttemptSplitSimpleRangeIntoMinMax(AdvancedRange, MinAllowed, MaxAllowed) then begin
            if not QltyFieldIds.Contains(QltyField.Code) then
                RangeNumberType := RangeNumberType::"A range of numbers";
        end else
            RangeNumberType := RangeNumberType::Advanced;

        if AdvancedRange.IndexOfAny('[]{}><+*/()') > 0 then
            RangeNumberType := RangeNumberType::Advanced;

        if AdvancedRange.IndexOf('..') = 0 then
            RangeNumberType := RangeNumberType::Advanced;

        UpdateFieldVisibilityState();
    end;

    local procedure HandleAssistEditAdvancedAllowableValuesRange()
    var
        QltyInspectionTemplateEdit: Page "Qlty. Inspection Template Edit";
        Expression: Text;
    begin
        Expression := AdvancedRange;

        if QltyInspectionTemplateEdit.RunModalWith(Database::"Qlty. Inspection Test Header", '', Expression) in [Action::LookupOK, Action::OK, Action::Yes] then
            AdvancedRange := Expression;

        HandleFieldValidateAllowedRanges();
    end;

    local procedure HandleFieldValidateAllowedRanges()
    begin
        if RangeNumberType = RangeNumberType::"A range of numbers" then
            AdvancedRange := StrSubstNo(SimpleRangeTok, Format(MinAllowed, 0, 9), Format(MaxAllowed, 0, 9));

        QltyField.Get(QltyField.Code);
        QltyField."Allowable Values" := CopyStr(AdvancedRange, 1, MaxStrLen(QltyField."Allowable Values"));
        QltyField.Modify();
        LoadExistingField(QltyField.Code);
        UpdateFieldVisibilityState();
    end;

    local procedure HandleFieldValidateEasyGrade()
    var
        QltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        Iterator: Integer;
        Condition: Text;
        ConditionDesc: Text;
    begin
        for Iterator := 1 to ArrayLen(MatrixSourceRecordId) do
            if MatrixVisibleState[Iterator] then begin
                QltyIGradeConditionConf.Get(MatrixSourceRecordId[Iterator]);
                if (MatrixMinValue[Iterator] = 0) and (MatrixMaxValue[Iterator] = 0) then begin
                    Condition := RangeNonZeroTok;
                    ConditionDesc := RangeNonZeroHumanDescriptionTok;
                end else begin
                    Condition := StrSubstNo(SimpleRangeTok, Format(MatrixMinValue[Iterator], 0, 9), Format(MatrixMaxValue[Iterator], 0, 9));
                    ConditionDesc := StrSubstNo(RangeHumanDescriptionTok, MatrixMinValue[Iterator], MatrixMaxValue[Iterator]);
                end;
                QltyIGradeConditionConf.Condition := CopyStr(Condition, 1, MaxStrLen(QltyIGradeConditionConf.Condition));
                MatrixArrayConditionCellData[Iterator] := QltyIGradeConditionConf.Condition;
                QltyIGradeConditionConf."Condition Description" := CopyStr(ConditionDesc, 1, MaxStrLen(QltyIGradeConditionConf."Condition Description"));
                QltyIGradeConditionConf.Modify();
            end;

        UpdateRowData();
    end;

    procedure AssistEditCondition(Matrix: Integer)
    var
        QltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        QltyInspectionTemplateEdit: Page "Qlty. Inspection Template Edit";
        Expression: Text;
    begin
        Expression := MatrixArrayConditionCellData[Matrix];
        if QltyInspectionTemplateEdit.RunModalWith(Database::"Qlty. Inspection Test Header", '', Expression) in [Action::LookupOK, Action::OK, Action::Yes] then begin
            MatrixArrayConditionCellData[Matrix] := CopyStr(Expression, 1, MaxStrLen(QltyIGradeConditionConf.Condition));
            HandleFieldValidateAdvancedSyntax(Matrix);
        end;
    end;

    procedure AssistEditConditionDescription(Matrix: Integer)
    var
        QltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
        QltyInspectionTemplateEdit: Page "Qlty. Inspection Template Edit";
        Expression: Text;
    begin
        Expression := MatrixArrayConditionDescriptionCellData[Matrix];
        if QltyInspectionTemplateEdit.RunModalWith(Database::"Qlty. Inspection Test Header", '', Expression) in [Action::LookupOK, Action::OK, Action::Yes] then begin
            MatrixArrayConditionDescriptionCellData[Matrix] := CopyStr(Expression, 1, MaxStrLen(QltyIGradeConditionConf.Condition));
            HandleFieldValidateConditionDescription(Matrix);
        end;
    end;

    local procedure HandleFieldValidateNumberRangeType()
    begin
        if RangeNumberType = RangeNumberType::Advanced then begin
            if not QltyFieldIds.Contains(QltyField.Code) then
                QltyFieldIds.Add(QltyField.Code);
        end else
            if QltyFieldIds.Contains(QltyField.Code) then
                QltyFieldIds.Remove(QltyField.Code);

        UpdateFieldVisibilityState();
    end;

    local procedure UpdateFieldVisibilityState()
    begin
        ShowSimpleRange := RangeNumberType = RangeNumberType::"A range of numbers";
        ShowAdvanced := not ShowSimpleRange;
    end;

    local procedure UpdateRowData()
    var
        Iterator: Integer;
    begin
        if QltyField.Code = '' then
            exit;

        Clear(MatrixMinValue);
        Clear(MatrixMaxValue);
        Clear(AdvancedRange);
        Clear(MatrixVisibleState);
        Clear(MatrixArrayConditionCellData);
        Clear(MatrixArrayConditionDescriptionCellData);
        Clear(MatrixArrayCaptionSet);

        ReverseEngineerAllowedValuesMinMax();

        QltyGradeConditionMgmt.GetPromotedGradesForField(QltyField, MatrixSourceRecordId, MatrixArrayConditionCellData, MatrixArrayConditionDescriptionCellData, MatrixArrayCaptionSet, MatrixVisibleState);
        for Iterator := 1 to ArrayLen(MatrixArrayConditionCellData) do
            QltyValueParsing.AttemptSplitSimpleRangeIntoMinMax(MatrixArrayConditionCellData[Iterator], MatrixMinValue[Iterator], MatrixMaxValue[Iterator]);

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

    local procedure HandleFieldValidateAdvancedSyntax(Matrix: Integer)
    var
        QltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
    begin
        QltyIGradeConditionConf.Get(MatrixSourceRecordId[Matrix]);
        QltyIGradeConditionConf.Validate(Condition, MatrixArrayConditionCellData[Matrix]);
        QltyValueParsing.AttemptSplitSimpleRangeIntoMinMax(QltyIGradeConditionConf.Condition, MatrixMinValue[Matrix], MatrixMaxValue[Matrix]);
        QltyIGradeConditionConf.Modify(true);
        LoadExistingField(QltyField.Code);
        CurrPage.Update(false);
    end;

    local procedure HandleFieldValidateConditionDescription(Matrix: Integer)
    var
        QltyIGradeConditionConf: Record "Qlty. I. Grade Condition Conf.";
    begin
        QltyIGradeConditionConf.Get(MatrixSourceRecordId[Matrix]);
        QltyIGradeConditionConf.Validate("Condition Description", MatrixArrayConditionDescriptionCellData[Matrix]);
        QltyIGradeConditionConf.Modify(true);
        LoadExistingField(QltyField.Code);
        CurrPage.Update(false);
    end;

    procedure GetAllowableValues(): Text
    begin
        exit(AdvancedRange);
    end;

    /// <summary>
    /// Validates the default value.
    /// </summary>
    protected procedure ValidateDefaultValue()
    begin
        QltyField.Validate("Default Value", DefaultValue);
        QltyField.Modify();
    end;

    /// <summary>
    /// Assist-Edits the default value.
    /// </summary>
    protected procedure AssistEditDefaultValue()
    begin
        QltyField.AssistEditDefaultValue();
        QltyField.Modify();
    end;
}
