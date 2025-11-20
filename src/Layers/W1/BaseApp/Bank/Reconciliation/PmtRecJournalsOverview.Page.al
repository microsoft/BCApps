// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Bank.BankAccount;
using System.Telemetry;

page 1293 "Pmt. Rec. Journals Overview"
{
    Caption = 'Unprocessed Payments';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Bank Acc. Reconciliation";
    SourceTableView = where("Statement Type" = const("Payment Application"));

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
                    ToolTip = 'Specifies the number of the bank account that you want to reconcile with the bank''s statement.';
                }
                field("Total Difference"; Rec."Total Difference")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Remaining Amount to Apply';
                    ToolTip = 'Specifies the sum of values in the Difference field on all lines in the Bank Acc. Reconciliation window that belong to the bank account reconciliation.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Bank Account Card")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Bank Account Card';
                Image = BankAccount;
                RunObject = Page "Payment Bank Account Card";
                RunPageLink = "No." = field("Bank Account No.");
                ToolTip = 'View or edit information about the bank account that is related to the payment reconciliation journal.';
            }
            action(ViewJournal)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'View Journal';
                Image = OpenWorksheet;
                ShortCutKey = 'Return';
                ToolTip = 'View the payment reconciliation lines from the bank statement for the account. This information can help when posting the transactions recorded by the bank that have not yet been recorded.';

                trigger OnAction()
                var
                    BankAccReconciliation: Record "Bank Acc. Reconciliation";
                begin
                    if not BankAccReconciliation.Get(Rec."Statement Type", Rec."Bank Account No.", Rec."Statement No.") then
                        exit;

                    Rec.OpenList(Rec);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Bank Account Card_Promoted"; "Bank Account Card")
                {
                }
                actionref(ViewJournal_Promoted; ViewJournal)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        FeatureTelemetry.LogUptake('0000KM7', Rec.GetBankReconciliationTelemetryFeatureName(), Enum::"Feature Uptake Status"::Discovered);
        FeatureTelemetry.LogUptake('0000KM8', Rec.GetBankReconciliationTelemetryFeatureName(), Enum::"Feature Uptake Status"::"Set up");
    end;
}

