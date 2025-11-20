// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

report 1252 "Match Bank Entries"
{
    Caption = 'Match Bank Entries';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Bank Acc. Reconciliation"; "Bank Acc. Reconciliation")
        {
            DataItemTableView = sorting("Bank Account No.", "Statement No.");

            trigger OnAfterGetRecord()
            begin
                MatchSingle(DateRange);
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Control3)
                {
                    ShowCaption = false;
                    field(DateRange; DateRange)
                    {
                        ApplicationArea = Basic, Suite;
                        BlankZero = true;
                        Caption = 'Transaction Date Tolerance (Days)';
                        MinValue = 0;
                        ToolTip = 'Specifies the span of days before and after the bank account ledger entry posting date within which the function will search for matching transaction dates in the bank statement. If you enter 0 or leave the field blank, then the Match Automatically function will only search for matching transaction dates on the bank account ledger entry posting date.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        DateRange: Integer;
}

