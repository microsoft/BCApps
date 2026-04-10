// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Statement;

using Microsoft.Foundation.Reporting;

/// <summary>
/// Displays a list of bank account statements for selection and navigation.
/// Provides overview of all bank statements with key information like statement numbers, dates, and balances.
/// </summary>
/// <remarks>
/// Source Table: Bank Account Statement (275). List page for bank statement overview and navigation.
/// Supports filtering by bank account and statement dates for efficient statement location.
/// Used as lookup and navigation interface for bank statement management workflows.
/// </remarks>
page 389 "Bank Account Statement List"
{
    ApplicationArea = Basic, Suite;
    UsageCategory = Lists;
    Caption = 'Bank Account Statement List';
    CardPageID = "Bank Account Statement";
    Editable = false;
    PageType = List;
    SourceTable = "Bank Account Statement";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Bank Account No."; Rec."Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Bank Account Name"; Rec."Bank Account Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Statement No."; Rec."Statement No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Statement Date"; Rec."Statement Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Balance Last Statement"; Rec."Balance Last Statement")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Statement Ending Balance"; Rec."Statement Ending Balance")
                {
                    ApplicationArea = Basic, Suite;
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
        area(processing)
        {
            group(Functions)
            {
                Caption = 'Functions';
                action(Undo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Undo';
                    Image = Undo;
                    ToolTip = 'Reverse this bank statement and automatically create a new bank reconciliation with the same information so you can correct it before posting. This bank statement will be deleted.';

                    trigger OnAction()
                    var
                        UndoBankStatementYesNo: Codeunit "Undo Bank Statement (Yes/No)";
                    begin
                        UndoBankStatementYesNo.Run(Rec);
                    end;
                }
            }
        }
        area(reporting)
        {
            action(Print)
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                Scope = Repeater;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                var
                    DocPrint: Codeunit "Document-Print";
                begin
                    DocPrint.PrintBankAccStmt(Rec);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Print_Promoted; Print)
                {
                }
                actionref(Undo_Promoted; Undo)
                {
                }
            }
        }
    }
}

