// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExciseTaxes;

page 7418 "Excise Tax Rates"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "Excise Tax Rate";
    DataCaptionExpression = GetCaption();
    Caption = 'Excise Duty Rates';
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Rates)
            {
                field("Excise Tax Type Code"; Rec."Excise Tax Type Code")
                {
                    ToolTip = 'Specifies the excise tax type code.';
                    Editable = false;
                    Visible = false;
                }
                field("Source Type"; Rec."Source Type")
                {
                    ToolTip = 'Specifies whether this rate applies to an Item or Fixed Asset.';

                    trigger OnValidate()
                    begin
                        SetControlAppearance();
                    end;
                }
                field("Source No."; Rec."Source No.")
                {
                    Visible = false;
                    ToolTip = 'Specifies the Item or Fixed Asset number.';
                }
                field("Item Category Code"; Rec."Item Category Code")
                {
                    Enabled = ItemCategoryEnabled;
                    ToolTip = 'Specifies the item category that this rate applies to. Leave it blank to apply the rate to all item categories.';
                }
                field("Excise Calculation Type"; Rec."Excise Calculation Type")
                {
                    ToolTip = 'Specifies whether the excise duty is calculated per unit, as a percentage of the taxable amount, or as a combination of both.';

                    trigger OnValidate()
                    begin
                        SetControlAppearance();
                    end;
                }
                field("Excise Duty"; Rec."Excise Duty")
                {
                    Editable = ExciseDutyRateEditable;
                    ToolTip = 'Specifies the excise duty.';
                }
                field("Excise Duty %"; Rec."Excise Duty %")
                {
                    Editable = ExciseDutyPercentEditable;
                    ToolTip = 'Specifies the percentage of the taxable amount that is charged as excise duty.';
                }
                field("Effective From Date"; Rec."Effective From Date")
                {
                    ToolTip = 'Specifies when this excise duty becomes effective.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetControlAppearance();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        SetControlAppearance();
    end;

    var
        ItemCategoryEnabled: Boolean;
        ExciseDutyRateEditable: Boolean;
        ExciseDutyPercentEditable: Boolean;
        EntryPermissionsCaptionLbl: Label '%1 for Tax Type: %2', Comment = '%1=Current Rec TableCaption, %2=Excise Tax Type Code';

    local procedure GetCaption(): Text[100]
    begin
        exit(StrSubstNo(EntryPermissionsCaptionLbl, Rec.TableCaption, Rec."Excise Tax Type Code"));
    end;

    local procedure SetControlAppearance()
    begin
        ItemCategoryEnabled := Rec."Source Type" = Rec."Source Type"::Item;
        ExciseDutyRateEditable := Rec."Excise Calculation Type" in [Rec."Excise Calculation Type"::"Specific per Unit", Rec."Excise Calculation Type"::Hybrid];
        ExciseDutyPercentEditable := Rec."Excise Calculation Type" in [Rec."Excise Calculation Type"::"Ad valorem", Rec."Excise Calculation Type"::Hybrid];
    end;
}