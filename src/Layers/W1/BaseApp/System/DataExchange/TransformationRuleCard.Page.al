// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.IO;

using System.Reflection;

page 1238 "Transformation Rule Card"
{
    Caption = 'Transformation Rule Card';
    PageType = Card;
    SourceTable = "Transformation Rule";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies rules for how text that was imported from an external file is transformed to a supported value that can be mapped to the specified field in Business Central.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies rules for how text that was imported from an external file is transformed to a supported value that can be mapped to the specified field in Business Central.';
                }
                field("Transformation Type"; Rec."Transformation Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies rules for how text that was imported from an external file is transformed to a supported value that can be mapped to the specified field in Business Central.';

                    trigger OnValidate()
                    begin
                        UpdateEnabled();
                    end;
                }
                field("Next Transformation Rule"; Rec."Next Transformation Rule")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the transformation rule that takes the result of this rule and transforms the value.';

                    trigger OnAssistEdit()
                    begin
                        Rec.EditNextTransformationRule();
                    end;
                }
                group(Control19)
                {
                    ShowCaption = false;
                    Visible = IsFindValueVisible;

                    field("Find Value"; Rec."Find Value")
                    {
                        ApplicationArea = Basic, Suite;
                        ShowMandatory = IsFindValueVisible;
                        ToolTip = 'Specifies in the Transformation Rule table the rules for how text that was imported from an external file is transformed to a supported value that can be mapped to the specified field in Microsoft Dynamics 365.';
                    }
                }
                group(Control20)
                {
                    ShowCaption = false;
                    Visible = IsReplaceValueVisible;

                    field("Replace Value"; Rec."Replace Value")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies rules for how text that was imported from an external file is transformed to a supported value that can be mapped to the specified field in Dynamics 365.';
                    }
                }
                group(Control21)
                {
                    ShowCaption = false;
                    Visible = IsStartPositionVisible;
                    field("Start Position"; Rec."Start Position")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies rules for how text that was imported from an external file is transformed to a supported value that can be mapped to the specified field in Dynamics 365.';
                    }
                    field("Starting Text"; Rec."Starting Text")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the first part of text that was imported from an external file to be transformed to a supported value by mapping to the specified field in Dynamics 365.';
                    }
                }
                group(Control22)
                {
                    ShowCaption = false;
                    Visible = IsEndPositionVisible;
                    field(Length; Rec.Length)
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the length of one item unit when measured in the specified unit of measure.';
                    }
                    field("Ending Text"; Rec."Ending Text")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the last part of text that was imported from an external file to be transformed to a supported value by mapping to the specified field in Dynamics 365.';
                    }
                }
                group(Control23)
                {
                    ShowCaption = false;
                    Visible = IsDataFormatVisible;
                    field("Data Format"; Rec."Data Format")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies in the Transformation Rule table the rules for how text that was imported from an external file is transformed to a supported value that can be mapped to the specified field in Microsoft Dynamics 365.';
                    }
                }
                group(Control24)
                {
                    ShowCaption = false;
                    Visible = IsDataFormatVisible;
                    field("Data Formatting Culture"; Rec."Data Formatting Culture")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies in the Transformation Rule table the rules for how text that was imported from an external file is transformed to a supported value that can be mapped to the specified field in Microsoft Dynamics 365.';
                    }
                }
                group(LookupGroup)
                {
                    Caption = 'Field Lookup Options';
                    Visible = IsFieldLookupVisible;
                    field("Table ID"; Rec."Table ID")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the ID of the table to get the record for the field lookup.';
                    }
                    field("Table Caption"; Rec."Table Caption")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the caption of the table to get the record for the field lookup.';
                    }
                    field("Source Field ID"; Rec."Source Field ID")
                    {
                        ApplicationArea = Basic, Suite;
                        LookupPageId = "Fields Lookup";
                        ToolTip = 'Specifies the ID of the field to find the record for the field lookup.';
                    }
                    field("Source Field Caption"; Rec."Source Field Caption")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the caption of the field to find the record for the field lookup.';
                    }
                    field("Target Field ID"; Rec."Target Field ID")
                    {
                        ApplicationArea = Basic, Suite;
                        LookupPageId = "Fields Lookup";
                        ToolTip = 'Specifies the ID of the field to get the value for the field lookup.';
                    }
                    field("Target Field Caption"; Rec."Target Field Caption")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the caption of the field to get the value for the field lookup.';
                    }
                    field("Field Lookup Rule"; Rec."Field Lookup Rule")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the type of the field lookup. In case of Target the value from the Target Field ID will be taken as is, even if it is blank. In case of Original If Target Is Blank the original value will be taken if target one is blank.';
                    }
                }

                group(ExtractFromDate)
                {
                    Caption = 'Extract From Date';
                    Visible = IsExtractFromDateVisible;
                    field("Extract From Date Type"; Rec."Extract From Date Type")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies what should be extracted from the date.';
                    }
                }
                group(RoundGroup)
                {
                    Caption = 'Round Options';
                    Visible = IsRoundVisible;

                    field(Precision; Rec.Precision)
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies rounding precision.';
                    }
                    field(Direction; Rec.Direction)
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies rounding direction.';
                    }
                }
            }
            group(Test)
            {
                Caption = 'Test';
                field(TestText; TestText)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Test Text';
                    MultiLine = true;
                    ToolTip = 'Specifies rules for how text that was imported from an external file is transformed to a supported value that can be mapped to the specified field in Dynamics 365.';
                }
                group(Control18)
                {
                    ShowCaption = false;
                    field(ResultText; ResultText)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Result';
                        Editable = false;
                        ToolTip = 'Specifies rules for how text that was imported from an external file is transformed to a supported value that can be mapped to the specified field in Dynamics 365.';
                    }
                    field(UpdateResultLbl; UpdateResultLbl)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        ShowCaption = false;

                        trigger OnDrillDown()
                        begin
                            ResultText := Rec.TransformText(TestText);
                        end;
                    }
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        UpdateEnabled();
    end;

    var
        TestText, ResultText : Text;
        UpdateResultLbl: Label 'Update';

    protected var
        VisibleTransformationRuleGroups: List of [Enum "Transformation Rule Group"];
        IsDataFormatVisible, IsFindValueVisible, IsReplaceValueVisible, IsStartPositionVisible, IsEndPositionVisible, IsFieldLookupVisible, IsExtractFromDateVisible, IsRoundVisible : Boolean;

    local procedure UpdateEnabled()
    var
        TransformationRule: Interface "Transformation Rule";
    begin
        IsDataFormatVisible := Rec.IsDataFormatUpdateAllowed();

        Clear(VisibleTransformationRuleGroups);
        TransformationRule := Rec."Transformation Type";
        TransformationRule.GetVisibleGroups(Rec, VisibleTransformationRuleGroups);
        IsFindValueVisible := VisibleTransformationRuleGroups.Contains(Enum::"Transformation Rule Group"::"Find Value");
        IsReplaceValueVisible := VisibleTransformationRuleGroups.Contains(Enum::"Transformation Rule Group"::"Replace Value");
        IsStartPositionVisible := VisibleTransformationRuleGroups.Contains(Enum::"Transformation Rule Group"::"Start Position");
        IsEndPositionVisible := VisibleTransformationRuleGroups.Contains(Enum::"Transformation Rule Group"::"End Position");
        IsFieldLookupVisible := VisibleTransformationRuleGroups.Contains(Enum::"Transformation Rule Group"::"Field Lookup");
        IsExtractFromDateVisible := VisibleTransformationRuleGroups.Contains(Enum::"Transformation Rule Group"::"Extract from Date");
        IsRoundVisible := VisibleTransformationRuleGroups.Contains(Enum::"Transformation Rule Group"::Round);

        OnAfterUpdateEnabled(Rec, VisibleTransformationRuleGroups);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateEnabled(TransformationRule: Record "Transformation Rule"; var VisibleTransformationRuleGroups: List of [Enum "Transformation Rule Group"])
    begin
    end;
}
