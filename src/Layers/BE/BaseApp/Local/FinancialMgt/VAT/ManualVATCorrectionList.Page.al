// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

page 11303 "Manual VAT Correction List"
{
    Caption = 'Manual VAT Correction List';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Manual VAT Correction";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Row No."; Rec."Row No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the VAT row to which the VAT correction applies.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the posting date of the VAT correction.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the VAT correction. For example, if the corrected total of the VAT amount is 1000 instead of 1200, enter 200.';
                }
                field("Additional-Currency Amount"; Rec."Additional-Currency Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the VAT correction in the additional reporting currency.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        if CorrStatementLineNo <> 0 then
            Rec."Statement Line No." := CorrStatementLineNo;
    end;

    var
        CorrStatementLineNo: Integer;

    procedure SetCorrStatementLineNo(LineNo: Integer)
    begin
        CorrStatementLineNo := LineNo;
    end;
}

