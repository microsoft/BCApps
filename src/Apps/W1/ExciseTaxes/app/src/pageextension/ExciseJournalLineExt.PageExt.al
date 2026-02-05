// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExciseTaxes;

using Microsoft.Sustainability.ExciseTax;

pageextension 7414 "Excise Journal Line Ext" extends "Sustainability Excise Journal"
{
    layout
    {
        addafter("Posting Date")
        {
            field("Excise Tax Type"; Rec."Excise Tax Type")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the excise tax type for this journal line.';
            }
            field(Quantity; Rec.Quantity)
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the quantity for excise tax calculation.';
            }
            field("Tax Rate %"; Rec."Tax Rate %")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the tax rate percentage applied to this journal line.';
                Editable = false;
            }
            field("Tax Amount"; Rec."Tax Amount")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the calculated excise tax amount for this journal line.';
                Editable = false;
            }
            field("Excise Tax UOM"; Rec."Excise Tax UOM")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the unit of measure for the excise tax quantity.';
            }
            field("Excise Entry Type"; Rec."Excise Entry Type")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies which entry type was used to calculate the quantity from Item Ledger Entries for this journal line.';
            }
        }
    }

    actions
    {
        addlast(processing)
        {
            action(GenerateExciseTaxEntries)
            {
                ApplicationArea = All;
                Caption = 'Generate Excise Tax Entries';
                ToolTip = 'Generate excise tax journal entries based on Item Ledger Entry quantities for the specified date range.';
                Image = CreateDocuments;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                Enabled = IsBatchExciseType;

                trigger OnAction()
                var
                    ExciseTaxReport: Report "Excise Tax Report";
                begin
                    ExciseTaxReport.RunModal();
                end;
            }
        }
        modify(Calculate)
        {
            Enabled = not IsBatchExciseType;
        }
    }

    var
        IsBatchExciseType: Boolean;


    trigger OnAfterGetCurrRecord()
    begin
        UpdateBatchTypeEnabled();
    end;

    local procedure UpdateBatchTypeEnabled()
    var
        ExciseTaxCalculation: Codeunit "Excise Tax Calculation";
    begin
        IsBatchExciseType := false;
        if Rec."Journal Batch Name" = '' then
            exit;

        IsBatchExciseType := ExciseTaxCalculation.IsExciseTaxEntry(Rec);
    end;
}
