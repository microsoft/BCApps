// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Check;

using Microsoft.Bank.Reconciliation;

/// <summary>
/// Provides interface for applying check ledger entries to bank account reconciliation lines.
/// Enables users to match checks with bank statement entries for accurate reconciliation.
/// </summary>
/// <remarks>
/// Source Table: Check Ledger Entry (272). Integrates with Bank Account Reconciliation.
/// Supports manual check matching and automated statement reconciliation processes.
/// </remarks>
page 382 "Apply Check Ledger Entries"
{
    Caption = 'Apply Check Ledger Entries';
    PageType = Worksheet;
    SourceTable = "Check Ledger Entry";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(LineApplied; LineApplied)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Applied';
                    ToolTip = 'Specifies if the check ledger entry has been applied.';

                    trigger OnValidate()
                    begin
                        LineAppliedOnPush();
                    end;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the posting date of the check ledger entry.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the document type linked to the check ledger entry. For example, Payment.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the document number on the check ledger entry.';
                }
                field("Check Date"; Rec."Check Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the check date if a check is printed.';
                }
                field("Check No."; Rec."Check No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the check number if a check is printed.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount on the check ledger entry.';
                }
                field("Check Type"; Rec."Check Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the type check, such as Manual.';
                }
                field(Open; Rec.Open)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies whether the entry has been fully applied to.';
                }
                field("Statement Status"; Rec."Statement Status")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies that the structure of the lines is based on the chart of cost types. You define up to seven cost centers and cost objects that appear as columns in the report.';
                    Visible = false;
                }
                field("Statement No."; Rec."Statement No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the bank account statement that the check ledger entry has been applied to, if the Statement Status is Bank Account Ledger Applied or Check Ledger Applied.';
                    Visible = false;
                }
                field("Statement Line No."; Rec."Statement Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the statement line that the check ledger entry has been applied to, if the Statement Status is Bank Account Ledger Applied or Check Ledger Applied.';
                    Visible = false;
                }
            }
            group(Control25)
            {
                ShowCaption = false;
#pragma warning disable AA0100
                field("BankAccReconLine.""Statement Amount"""; BankAccReconLine."Statement Amount")
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Statement Amount';
                    Editable = false;
                    ToolTip = 'Specifies the amount that was applied in the selected check ledger entry line.';
                }
                field(AppliedAmount; BankAccReconLine."Applied Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Applied Amount';
                    Editable = false;
                    ToolTip = 'Specifies the amount that was applied by the check ledger entry in the selected line.';
                }
                field("BankAccReconLine.Difference"; BankAccReconLine.Difference)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Difference';
                    Editable = false;
                    ToolTip = 'Specifies the difference between the applied amount and the statement amount in the selected line.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        LineApplied :=
          (Rec."Statement Status" = Rec."Statement Status"::"Check Entry Applied") and
          (Rec."Statement No." = BankAccReconLine."Statement No.") and
          (Rec."Statement Line No." = BankAccReconLine."Statement Line No.");
    end;

    trigger OnAfterGetRecord()
    begin
        LineApplied :=
          (Rec."Statement Status" = Rec."Statement Status"::"Check Entry Applied") and
          (Rec."Statement No." = BankAccReconLine."Statement No.") and
          (Rec."Statement Line No." = BankAccReconLine."Statement Line No.");
    end;

    var
        CheckLedgEntry: Record "Check Ledger Entry";
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        CheckSetStmtNo: Codeunit "Check Entry Set Recon.-No.";
        ChangeAmount: Boolean;
        LineApplied: Boolean;

    /// <summary>
    /// Initializes the page with bank account reconciliation line information.
    /// Sets up context for check entry application and amount change handling.
    /// </summary>
    /// <param name="NewBankAccReconLine">Bank reconciliation line to apply check entries against</param>
    procedure SetStmtLine(NewBankAccReconLine: Record "Bank Acc. Reconciliation Line")
    begin
        BankAccReconLine := NewBankAccReconLine;
        ChangeAmount := BankAccReconLine."Statement Amount" = 0;
    end;

    /// <summary>
    /// Toggles the application status of a check ledger entry to a bank reconciliation line.
    /// Updates statement numbers and reconciliation status based on current application state.
    /// </summary>
    local procedure LineAppliedOnPush()
    begin
        CheckLedgEntry.Copy(Rec);
        CheckSetStmtNo.ToggleReconNo(CheckLedgEntry, BankAccReconLine, ChangeAmount);
        CurrPage.Update();
    end;
}

