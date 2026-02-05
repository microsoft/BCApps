// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExciseTaxes;

page 7412 "Excise Tax Item/FA Rates"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Excise Tax Item/FA Rate";
    DataCaptionExpression = GetCaption();
    Caption = 'Excise Tax Item/FA Rates';
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Rates)
            {
                field("Excise Tax Type Code"; Rec."Excise Tax Type Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the excise tax type code.';
                    Editable = false;
                    Visible = false;
                }
                field("Source Type"; Rec."Source Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether this rate applies to an Item or Fixed Asset.';
                }
                field("Source No."; Rec."Source No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Item or Fixed Asset number.';
                }
                field("Tax Rate %"; Rec."Tax Rate %")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the tax rate percentage.';
                }
                field("Effective From Date"; Rec."Effective From Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when this tax rate becomes effective.';
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