// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExciseTaxes;

page 7412 "Excise Tax Item/FA Rates"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "Excise Tax Item/FA Rate";
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
                }
                field("Source No."; Rec."Source No.")
                {
                    Visible = false;
                    ToolTip = 'Specifies the Item or Fixed Asset number.';
                }
                field("Excise Duty"; Rec."Excise Duty")
                {
                    ToolTip = 'Specifies the excise duty.';
                }
                field("Calculation Type"; Rec."Calculation Type")
                {
                    ToolTip = 'Specifies whether the excise duty is calculated as a specific amount per unit, ad valorem (a percentage of value), or a hybrid of both.';
                }
                field("Ad Valorem %"; Rec."Ad Valorem %")
                {
                    ToolTip = 'Specifies the percentage of value used when the calculation type is Ad Valorem or Hybrid.';
                }
                field("Effective From Date"; Rec."Effective From Date")
                {
                    ToolTip = 'Specifies when this excise duty becomes effective.';
                }
            }
        }
    }

    var
        EntryPermissionsCaptionLbl: Label '%1 for Tax Type: %2', Comment = '%1=Current Rec TableCaption, %2=Excise Tax Type Code';

    local procedure GetCaption(): Text[100]
    begin
        exit(StrSubstNo(EntryPermissionsCaptionLbl, Rec.TableCaption, Rec."Excise Tax Type Code"));
    end;
}