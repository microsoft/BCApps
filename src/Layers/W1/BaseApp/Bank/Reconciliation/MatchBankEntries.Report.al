// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

/// <summary>
/// Automated matching report for bank reconciliation statements and ledger entries.
/// This report processes bank reconciliation records and applies sophisticated matching algorithms
/// to identify and link bank statement lines with corresponding bank account ledger entries.
/// Supports configurable date tolerance for flexible matching and provides batch processing
/// capability for multiple reconciliation statements.
/// </summary>
/// <remarks>
/// The report uses advanced matching logic based on amounts, dates (within tolerance), document numbers,
/// and text similarity scoring. Designed for batch processing scenarios where multiple reconciliation
/// statements need automated matching without user interaction. Integrates with the same matching
/// engine used by interactive reconciliation pages but operates in a processing-only mode.
/// Used primarily for automated workflows and scheduled processing of bank reconciliation data.
/// </remarks>
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

