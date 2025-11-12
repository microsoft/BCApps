// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Bank.BankAccount;
using System.Telemetry;

page 1294 "Pmt. Reconciliation Journals"
{
    AdditionalSearchTerms = 'payment application,payment processing,bank reconciliation';
    ApplicationArea = Basic, Suite;
    Caption = 'Payment Reconciliation Journals';
    InsertAllowed = false;
    PageType = List;
    AboutTitle = 'About Payment Reconciliation Journals';
    AboutText = 'Register and reconcile incoming and outgoing payments by importing bank statements, automatically matching transactions to open customer, vendor, and bank ledger entries, and reviewing or adjusting matches before posting to close entries and update bank account balances.';
    SourceTable = "Bank Acc. Reconciliation";
    SourceTableView = where("Statement Type" = const("Payment Application"));
    UsageCategory = Lists;

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
                    Editable = false;
                    ToolTip = 'Specifies the number of the bank account that you want to reconcile with the bank''s statement.';
                }
                field("Statement No."; Rec."Statement No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the bank account statement.';
                }
                field("Total Transaction Amount"; Rec."Total Transaction Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the sum of values in the Statement Amount field on all the lines in the Bank Acc. Reconciliation and Payment Reconciliation Journal windows.';
                }
                field("Total Difference"; Rec."Total Difference")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Caption = 'Remaining Amount to Apply';
                    Editable = false;
                    Style = Unfavorable;
                    StyleExpr = true;
                    ToolTip = 'Specifies the total amount that exists on the bank account per the last time it was reconciled.';
                }
                field("Copy VAT Setup to Jnl. Line"; Rec."Copy VAT Setup to Jnl. Line")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the program to calculate VAT for accounts and balancing accounts on the journal line of the selected bank account reconciliation.';
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
            group(Process)
            {
                Caption = 'Process';
                Image = "Action";
                action(ImportBankTransactionsToNew)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Import Bank Transactions';
                    Ellipsis = true;
                    Image = Import;
                    ToolTip = 'To start the process of reconciling new payments, import a bank feed or electronic file containing the related bank transactions.';

                    trigger OnAction()
                    begin
                        Rec.ImportAndProcessToNewStatement();
                    end;
                }
                action(EditJournal)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Edit Journal';
                    Image = OpenWorksheet;
                    ShortCutKey = 'Return';
                    ToolTip = 'Modify an existing payment reconciliation journal for a bank account.';

                    trigger OnAction()
                    var
                        BankAccReconciliation: Record "Bank Acc. Reconciliation";
                    begin
                        if not BankAccReconciliation.Get(Rec."Statement Type", Rec."Bank Account No.", Rec."Statement No.") then
                            exit;

                        Rec.OpenWorksheet(Rec);
                    end;
                }
                action(NewJournal)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&New Journal';
                    Ellipsis = true;
                    Image = NewDocument;
                    ToolTip = 'Create a payment reconciliation journal for a bank account to set up payments that have been recorded as transactions in an electronic bank and need to be applied to related open entries.';

                    trigger OnAction()
                    begin
                        Rec.OpenNewWorksheet();
                    end;
                }
            }
            group(Bank)
            {
                Caption = 'Bank';
                action("Bank Account Card")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank Account Card';
                    Image = BankAccount;
                    RunObject = Page "Payment Bank Account Card";
                    RunPageLink = "No." = field("Bank Account No.");
                    ToolTip = 'View or edit information about the bank account that is related to the payment reconciliation journal.';
                }
                action("List of Bank Accounts")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'List of Bank Accounts';
                    Image = List;
                    RunObject = Page "Payment Bank Account List";
                    ToolTip = 'View and edit information about the bank accounts that are associated with the payment reconciliation journals that you use to reconcile payment transactions.';
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(EditJournal_Promoted; EditJournal)
                {
                }
                actionref(ImportBankTransactionsToNew_Promoted; ImportBankTransactionsToNew)
                {
                }
                actionref(NewJournal_Promoted; NewJournal)
                {
                }
                group(Category_Category4)
                {
                    Caption = 'Bank', Comment = 'Generated from the PromotedActionCategories property index 3.';

                    actionref("Bank Account Card_Promoted"; "Bank Account Card")
                    {
                    }
                    actionref("List of Bank Accounts_Promoted"; "List of Bank Accounts")
                    {
                    }
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnOpenPage()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        FeatureTelemetry.LogUptake('0000KMG', Rec.GetPaymentRecJournalTelemetryFeatureName(), Enum::"Feature Uptake Status"::Discovered);
        FeatureTelemetry.LogUptake('0000KMH', Rec.GetPaymentRecJournalTelemetryFeatureName(), Enum::"Feature Uptake Status"::"Set up");
    end;
}

