// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.Template.Test;

using Microsoft.QualityManagement.Configuration.Result;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Utilities;

/// <summary>
/// A card part to assist with numerical configuration.
/// </summary>
page 20434 "Qlty. Test Number Card Part"
{
    Caption = 'Quality Test Number Card Part';
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
                    ToolTip = 'Specifies the minimum allowed value for this test. This is not the "Pass" state.';
                    Caption = 'Minimum';
                    ShowCaption = true;
                    AutoFormatType = 0;
                    ShowMandatory = true;

                    trigger OnValidate()
                    begin
                        HandleTestValidateAllowedRanges();
                    end;
                }
                field(ChooseMaxAllowed; MaxAllowed)
                {
                    ToolTip = 'Specifies the maximum allowed value for this test. This is not the "Pass" state.';
                    Caption = 'Maximum';
                    ShowCaption = true;
                    AutoFormatType = 0;
                    ShowMandatory = true;

                    trigger OnValidate()
                    begin
                        HandleTestValidateAllowedRanges();
                    end;
                }
            }
            group(AdvancedConfiguration)
            {
                Caption = 'Advanced Configuration for Allowed Values';
                InstructionalText = 'Enter the allowed number syntax. For example 1 through 3 would be 1..3. More than 5 would be >5. 1 or 2 would be 1|2.';
                AboutTitle = 'Advanced range.';
                AboutText = 'Enter the allowed number syntax. For example 1 through 3 would be 1..3. More than 5 would be >5. 1 or 2 would be 1|2.';
                Visible = ShowAdvanced;

                field(ChooseAdvanced; AdvancedRange)
                {
                    ToolTip = 'Enter the allowed number syntax. For example 1 through 3 would be 1..3. More than 5 would be >5. 1 or 2 would be 1|2.';
                    Caption = 'Advanced Range';
                    ShowCaption = false;
                    ShowMandatory = true;

                    trigger OnAssistEdit()
                    begin
                        HandleAssistEditAdvancedAllowableValuesRange();
                    end;

                    trigger OnValidate()
                    begin
                        HandleTestValidateAllowedRanges();
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
                        Visible = ShowAdvanced;
                        ShowCaption = false;
                        Caption = ' ';

                        field(Field1; MatrixArrayConditionCellData[1])
                        {
                            ColumnSpan = 2;
                            ApplicationArea = All;
                            CaptionClass = '3,' + StrSubstNo(ConditionLbl, MatrixArrayCaptionSet[1]);
                            ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 1';
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
                            ToolTip = 'Specifies the minimum allowed value for this result.';
                            CaptionClass = '3,' + StrSubstNo(MinLbl, MatrixArrayCaptionSet[1]);
                            AutoFormatType = 0;
                            DecimalPlaces = 0 : 5;
                            ShowCaption = true;
                            ShowMandatory = true;

                            trigger OnValidate()
                            begin
                                HandleFieldValidateEasyResult();
                            end;
                        }
                        field(ChooseMax1; MatrixMaxValue[1])
                        {
                            ColumnSpan = 2;
                            ApplicationArea = All;
                            ToolTip = 'Specifies the maximum allowed value for this result.';
                            CaptionClass = '3,' + StrSubstNo(MaxLbl, MatrixArrayCaptionSet[1]);
                            AutoFormatType = 0;
                            DecimalPlaces = 0 : 5;
                            ShowCaption = true;
                            ShowMandatory = true;

                            trigger OnValidate()
                            begin
                                HandleFieldValidateEasyResult();
                            end;
                        }
                    }
                    field(Field1_Desc; MatrixArrayConditionDescriptionCellData[1])
                    {
                        ColumnSpan = 2;
                        ApplicationArea = All;
                        CaptionClass = '3,' + StrSubstNo(DescriptionLbl, MatrixArrayCaptionSet[1]);
                        ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 1';
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
                            CaptionClass = '3,' + StrSubstNo(ConditionLbl, MatrixArrayCaptionSet[2]);
                            ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 2';
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
                            ToolTip = 'Specifies the minimum allowed value for this result.';
                            CaptionClass = '3,' + StrSubstNo(MinLbl, MatrixArrayCaptionSet[2]);
                            ShowCaption = true;
                            ShowMandatory = true;
                            AutoFormatType = 0;
                            DecimalPlaces = 0 : 5;

                            trigger OnValidate()
                            begin
                                HandleFieldValidateEasyResult();
                            end;
                        }
                        field(ChooseMax2; MatrixMaxValue[2])
                        {
                            ToolTip = 'Specifies the maximum allowed value for this result.';
                            CaptionClass = '3,' + StrSubstNo(MaxLbl, MatrixArrayCaptionSet[2]);
                            ShowCaption = true;
                            ShowMandatory = true;
                            AutoFormatType = 0;
                            DecimalPlaces = 0 : 5;

                            trigger OnValidate()
                            begin
                                HandleFieldValidateEasyResult();
                            end;
                        }
                    }
                    field(Field2_Desc; MatrixArrayConditionDescriptionCellData[2])
                    {
                        CaptionClass = '3,' + StrSubstNo(DescriptionLbl, MatrixArrayCaptionSet[2]);
                        ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 2';
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
                            CaptionClass = '3,' + StrSubstNo(ConditionLbl, MatrixArrayCaptionSet[3]);
                            ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 1';
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
                            ToolTip = 'Specifies the minimum allowed value for this result.';
                            CaptionClass = '3,' + StrSubstNo(MinLbl, MatrixArrayCaptionSet[3]);
                            ShowCaption = true;
                            ShowMandatory = true;
                            AutoFormatType = 0;
                            DecimalPlaces = 0 : 5;

                            trigger OnValidate()
                            begin
                                HandleFieldValidateEasyResult();
                            end;
                        }
                        field(ChooseMax3; MatrixMaxValue[3])
                        {
                            ToolTip = 'Specifies the maximum allowed value for this result.';
                            CaptionClass = '3,' + StrSubstNo(MaxLbl, MatrixArrayCaptionSet[3]);
                            ShowCaption = true;
                            ShowMandatory = true;
                            AutoFormatType = 0;
                            DecimalPlaces = 0 : 5;

                            trigger OnValidate()
                            begin
                                HandleFieldValidateEasyResult();
                            end;
                        }
                    }
                    field(Field3_Desc; MatrixArrayConditionDescriptionCellData[3])
                    {
                        CaptionClass = '3,' + StrSubstNo(DescriptionLbl, MatrixArrayCaptionSet[3]);
                        ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 3';
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
                        CaptionClass = '3,' + StrSubstNo(DescriptionLbl, MatrixArrayCaptionSet[4]);
                        ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 3';
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
                            CaptionClass = '3,' + StrSubstNo(ConditionLbl, MatrixArrayCaptionSet[4]);
                            ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 1';
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
                            ToolTip = 'Specifies the minimum allowed value for this result.';
                            CaptionClass = '3,' + StrSubstNo(MinLbl, MatrixArrayCaptionSet[4]);
                            ShowCaption = true;
                            ShowMandatory = true;
                            AutoFormatType = 0;
                            DecimalPlaces = 0 : 5;

                            trigger OnValidate()
                            begin
                                HandleFieldValidateEasyResult();
                            end;
                        }
                        field(ChooseMax4; MatrixMaxValue[4])
                        {
                            ToolTip = 'Specifies the maximum allowed value for this result.';
                            CaptionClass = '3,' + StrSubstNo(MaxLbl, MatrixArrayCaptionSet[4]);
                            ShowCaption = true;
                            ShowMandatory = true;
                            AutoFormatType = 0;
                            DecimalPlaces = 0 : 5;

                            trigger OnValidate()
                            begin
                                HandleFieldValidateEasyResult();
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
                        CaptionClass = '3,' + StrSubstNo(DescriptionLbl, MatrixArrayCaptionSet[5]);
                        ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 3';
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
                            CaptionClass = '3,' + StrSubstNo(ConditionLbl, MatrixArrayCaptionSet[5]);
                            ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 1';
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
                            ToolTip = 'Specifies the minimum allowed value for this result.';
                            CaptionClass = '3,' + StrSubstNo(MinLbl, MatrixArrayCaptionSet[5]);
                            ShowCaption = true;
                            ShowMandatory = true;
                            AutoFormatType = 0;
                            DecimalPlaces = 0 : 5;

                            trigger OnValidate()
                            begin
                                HandleFieldValidateEasyResult();
                            end;
                        }
                        field(ChooseMax5; MatrixMaxValue[5])
                        {
                            ToolTip = 'Specifies the maximum allowed value for this result.';
                            CaptionClass = '3,' + StrSubstNo(MaxLbl, MatrixArrayCaptionSet[5]);
                            ShowCaption = true;
                            ShowMandatory = true;
                            AutoFormatType = 0;
                            DecimalPlaces = 0 : 5;

                            trigger OnValidate()
                            begin
                                HandleFieldValidateEasyResult();
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
                        CaptionClass = '3,' + StrSubstNo(DescriptionLbl, MatrixArrayCaptionSet[6]);
                        ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 3';
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
                            CaptionClass = '3,' + StrSubstNo(ConditionLbl, MatrixArrayCaptionSet[6]);
                            ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 1';
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
                            ToolTip = 'Specifies the minimum allowed value for this result.';
                            CaptionClass = '3,' + StrSubstNo(MinLbl, MatrixArrayCaptionSet[6]);
                            ShowCaption = true;
                            ShowMandatory = true;
                            AutoFormatType = 0;
                            DecimalPlaces = 0 : 5;

                            trigger OnValidate()
                            begin
                                HandleFieldValidateEasyResult();
                            end;
                        }
                        field(ChooseMax6; MatrixMaxValue[6])
                        {
                            ToolTip = 'Specifies the maximum allowed value for this result.';
                            CaptionClass = '3,' + StrSubstNo(MaxLbl, MatrixArrayCaptionSet[6]);
                            ShowCaption = true;
                            ShowMandatory = true;
                            AutoFormatType = 0;
                            DecimalPlaces = 0 : 5;

                            trigger OnValidate()
                            begin
                                HandleFieldValidateEasyResult();
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
                        CaptionClass = '3,' + StrSubstNo(DescriptionLbl, MatrixArrayCaptionSet[7]);
                        ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 3';
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
                            CaptionClass = '3,' + StrSubstNo(ConditionLbl, MatrixArrayCaptionSet[7]);
                            ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 1';
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
                            ToolTip = 'Specifies the minimum allowed value for this result.';
                            CaptionClass = '3,' + StrSubstNo(MinLbl, MatrixArrayCaptionSet[7]);
                            ShowCaption = true;
                            ShowMandatory = true;
                            AutoFormatType = 0;
                            DecimalPlaces = 0 : 5;

                            trigger OnValidate()
                            begin
                                HandleFieldValidateEasyResult();
                            end;
                        }
                        field(ChooseMax7; MatrixMaxValue[7])
                        {
                            ToolTip = 'Specifies the maximum allowed value for this result.';
                            CaptionClass = '3,' + StrSubstNo(MaxLbl, MatrixArrayCaptionSet[7]);
                            ShowCaption = true;
                            ShowMandatory = true;
                            AutoFormatType = 0;
                            DecimalPlaces = 0 : 5;

                            trigger OnValidate()
                            begin
                                HandleFieldValidateEasyResult();
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
                        CaptionClass = '3,' + StrSubstNo(DescriptionLbl, MatrixArrayCaptionSet[8]);
                        ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 3';
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
                            CaptionClass = '3,' + StrSubstNo(ConditionLbl, MatrixArrayCaptionSet[8]);
                            ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 1';
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
                            ToolTip = 'Specifies the minimum allowed value for this result.';
                            CaptionClass = '3,' + StrSubstNo(MinLbl, MatrixArrayCaptionSet[8]);
                            ShowCaption = true;
                            ShowMandatory = true;
                            AutoFormatType = 0;
                            DecimalPlaces = 0 : 5;

                            trigger OnValidate()
                            begin
                                HandleFieldValidateEasyResult();
                            end;
                        }
                        field(ChooseMax8; MatrixMaxValue[8])
                        {
                            ToolTip = 'Specifies the maximum allowed value for this result.';
                            CaptionClass = '3,' + StrSubstNo(MaxLbl, MatrixArrayCaptionSet[8]);
                            ShowCaption = true;
                            ShowMandatory = true;
                            AutoFormatType = 0;
                            DecimalPlaces = 0 : 5;

                            trigger OnValidate()
                            begin
                                HandleFieldValidateEasyResult();
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
                        CaptionClass = '3,' + StrSubstNo(DescriptionLbl, MatrixArrayCaptionSet[9]);
                        ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 3';
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
                            CaptionClass = '3,' + StrSubstNo(ConditionLbl, MatrixArrayCaptionSet[9]);
                            ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 1';
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
                            ToolTip = 'Specifies the minimum allowed value for this result.';
                            CaptionClass = '3,' + StrSubstNo(MinLbl, MatrixArrayCaptionSet[9]);
                            ShowCaption = true;
                            ShowMandatory = true;
                            AutoFormatType = 0;
                            DecimalPlaces = 0 : 5;

                            trigger OnValidate()
                            begin
                                HandleFieldValidateEasyResult();
                            end;
                        }
                        field(ChooseMax9; MatrixMaxValue[9])
                        {
                            ToolTip = 'Specifies the maximum allowed value for this result.';
                            CaptionClass = '3,' + StrSubstNo(MaxLbl, MatrixArrayCaptionSet[9]);
                            ShowCaption = true;
                            ShowMandatory = true;
                            AutoFormatType = 0;
                            DecimalPlaces = 0 : 5;

                            trigger OnValidate()
                            begin
                                HandleFieldValidateEasyResult();
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
                        CaptionClass = '3,' + StrSubstNo(DescriptionLbl, MatrixArrayCaptionSet[10]);
                        ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 3';
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
                            CaptionClass = '3,' + StrSubstNo(ConditionLbl, MatrixArrayCaptionSet[10]);
                            ToolTip = 'Specifies a test condition for a promoted result. This is dynamic based on the promoted results, this is result condition 1';
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
                            ToolTip = 'Specifies the minimum allowed value for this result.';
                            CaptionClass = '3,' + StrSubstNo(MinLbl, MatrixArrayCaptionSet[10]);
                            ShowCaption = true;
                            ShowMandatory = true;
                            AutoFormatType = 0;
                            DecimalPlaces = 0 : 5;

                            trigger OnValidate()
                            begin
                                HandleFieldValidateEasyResult();
                            end;
                        }
                        field(ChooseMax10; MatrixMaxValue[10])
                        {
                            ToolTip = 'Specifies the maximum allowed value for this result.';
                            CaptionClass = '3,' + StrSubstNo(MaxLbl, MatrixArrayCaptionSet[10]);
                            ShowCaption = true;
                            ShowMandatory = true;
                            AutoFormatType = 0;
                            DecimalPlaces = 0 : 5;

                            trigger OnValidate()
                            begin
                                HandleFieldValidateEasyResult();
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

                field(ChooseUOM; QltyTest."Unit of Measure Code")
                {
                    Caption = 'Optionally set the unit of measure for the field';
                    ShowCaption = true;
                    AssistEdit = true;
                    DrillDown = false;

                    trigger OnValidate()
                    begin
                        QltyTest.Modify();
                        LoadExistingTest(QltyTest.Code);
                    end;

                    trigger OnAssistEdit()
                    var
                        QltyFilterHelpers: Codeunit "Qlty. Filter Helpers";
                    begin
                        QltyFilterHelpers.AssistEditUnitOfMeasure(QltyTest."Unit of Measure Code");
                        QltyTest.Modify();
                        LoadExistingTest(QltyTest.Code);
                    end;
                }
            }
        }
    }

    var
        QltyTest: Record "Qlty. Test";
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
        QltyTestIds: List of [Code[20]];
        SimpleRangeTok: Label '%1..%2', Locked = true, Comment = '%1=Min, %2=Max';
        RangeNonZeroTok: Label '<>0', Locked = true;
        RangeNonZeroHumanDescriptionTok: Label 'Any entered value.', Locked = true;
        RangeHumanDescriptionTok: Label '%1 to %2', Locked = true, Comment = '%1=Min, %2=Max';
        DefaultRangeTok: Label '1..100', Locked = true;
        DescriptionLbl: Label '%1 Description', Comment = '%1 = Matrix field caption';
        ConditionLbl: Label '%1 Condition', Comment = '%1 = Matrix field caption';
        MinLbl: Label '%1 Min', Comment = '%1 = Matrix field caption';
        MaxLbl: Label '%1 Max', Comment = '%1 = Matrix field caption';

    procedure LoadExistingTest(CurrentTest: Code[20])
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

        if CurrentTest = '' then
            exit;

        if not QltyTest.Get(CurrentTest) then begin
            QltyTest.Init();
            QltyTest.Code := CurrentTest;
            QltyTest.Insert();
        end;
        QltyTest.SetRecFilter();
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
        if QltyTestIds.Contains(QltyTest.Code) then
            RangeNumberType := RangeNumberType::Advanced;

        AdvancedRange := QltyTest."Allowable Values";

        if QltyTest.Code = '' then
            exit;

        if AdvancedRange = '' then
            if QltyTest."Wizard Internal" = QltyTest."Wizard Internal"::"In Progress" then
                AdvancedRange := DefaultRangeTok;

        if QltyMiscHelpers.AttemptSplitSimpleRangeIntoMinMax(AdvancedRange, MinAllowed, MaxAllowed) then begin
            if not QltyTestIds.Contains(QltyTest.Code) then
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

        if QltyInspectionTemplateEdit.RunModalWith(Database::"Qlty. Inspection Header", '', Expression) in [Action::LookupOK, Action::OK, Action::Yes] then
            AdvancedRange := Expression;

        HandleTestValidateAllowedRanges();
    end;

    local procedure HandleTestValidateAllowedRanges()
    begin
        if RangeNumberType = RangeNumberType::"A range of numbers" then
            AdvancedRange := StrSubstNo(SimpleRangeTok, Format(MinAllowed, 0, 9), Format(MaxAllowed, 0, 9));

        QltyTest.Get(QltyTest.Code);
        QltyTest."Allowable Values" := CopyStr(AdvancedRange, 1, MaxStrLen(QltyTest."Allowable Values"));
        QltyTest.Modify();
        LoadExistingTest(QltyTest.Code);
        UpdateFieldVisibilityState();
    end;

    local procedure HandleFieldValidateEasyResult()
    var
        QltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
        Iterator: Integer;
        Condition: Text;
        ConditionDesc: Text;
    begin
        for Iterator := 1 to ArrayLen(MatrixSourceRecordId) do
            if MatrixVisibleState[Iterator] then begin
                QltyIResultConditConf.Get(MatrixSourceRecordId[Iterator]);
                if (MatrixMinValue[Iterator] = 0) and (MatrixMaxValue[Iterator] = 0) then begin
                    Condition := RangeNonZeroTok;
                    ConditionDesc := RangeNonZeroHumanDescriptionTok;
                end else begin
                    Condition := StrSubstNo(SimpleRangeTok, Format(MatrixMinValue[Iterator], 0, 9), Format(MatrixMaxValue[Iterator], 0, 9));
                    ConditionDesc := StrSubstNo(RangeHumanDescriptionTok, MatrixMinValue[Iterator], MatrixMaxValue[Iterator]);
                end;
                QltyIResultConditConf.Condition := CopyStr(Condition, 1, MaxStrLen(QltyIResultConditConf.Condition));
                MatrixArrayConditionCellData[Iterator] := QltyIResultConditConf.Condition;
                QltyIResultConditConf."Condition Description" := CopyStr(ConditionDesc, 1, MaxStrLen(QltyIResultConditConf."Condition Description"));
                QltyIResultConditConf.Modify();
            end;

        UpdateRowData();
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
            HandleFieldValidateAdvancedSyntax(Matrix);
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
            HandleFieldValidateConditionDescription(Matrix);
        end;
    end;

    local procedure HandleFieldValidateNumberRangeType()
    begin
        if RangeNumberType = RangeNumberType::Advanced then begin
            if not QltyTestIds.Contains(QltyTest.Code) then
                QltyTestIds.Add(QltyTest.Code);
        end else
            if QltyTestIds.Contains(QltyTest.Code) then
                QltyTestIds.Remove(QltyTest.Code);

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
        if QltyTest.Code = '' then
            exit;

        Clear(MatrixMinValue);
        Clear(MatrixMaxValue);
        Clear(AdvancedRange);
        Clear(MatrixVisibleState);
        Clear(MatrixArrayConditionCellData);
        Clear(MatrixArrayConditionDescriptionCellData);
        Clear(MatrixArrayCaptionSet);

        ReverseEngineerAllowedValuesMinMax();

        QltyResultConditionMgmt.GetPromotedResultsForTest(QltyTest, MatrixSourceRecordId, MatrixArrayConditionCellData, MatrixArrayConditionDescriptionCellData, MatrixArrayCaptionSet, MatrixVisibleState);
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

    local procedure HandleFieldValidateAdvancedSyntax(Matrix: Integer)
    var
        QltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
    begin
        QltyIResultConditConf.Get(MatrixSourceRecordId[Matrix]);
        QltyIResultConditConf.Validate(Condition, MatrixArrayConditionCellData[Matrix]);
        QltyMiscHelpers.AttemptSplitSimpleRangeIntoMinMax(QltyIResultConditConf.Condition, MatrixMinValue[Matrix], MatrixMaxValue[Matrix]);
        QltyIResultConditConf.Modify(true);
        LoadExistingTest(QltyTest.Code);
        CurrPage.Update(false);
    end;

    local procedure HandleFieldValidateConditionDescription(Matrix: Integer)
    var
        QltyIResultConditConf: Record "Qlty. I. Result Condit. Conf.";
    begin
        QltyIResultConditConf.Get(MatrixSourceRecordId[Matrix]);
        QltyIResultConditConf.Validate("Condition Description", MatrixArrayConditionDescriptionCellData[Matrix]);
        QltyIResultConditConf.Modify(true);
        LoadExistingTest(QltyTest.Code);
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
        QltyTest.Validate("Default Value", DefaultValue);
        QltyTest.Modify();
    end;

    /// <summary>
    /// Assist-Edits the default value.
    /// </summary>
    protected procedure AssistEditDefaultValue()
    begin
        QltyTest.AssistEditDefaultValue();
        QltyTest.Modify();
    end;
}
