// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Purchases.Payables;
using Microsoft.Sales.Receivables;

page 1296 "Pstd. Pmt. Recon. Subform"
{
    AutoSplitKey = true;
    Caption = 'Posted Payment Reconciliation Lines';
    DelayedInsert = true;
    Editable = false;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Posted Payment Recon. Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                FreezeColumn = Difference;
                ShowCaption = false;
                field("Transaction Date"; Rec."Transaction Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the payment represented by the journal line was recorded in the bank account.';
                }
                field("Transaction ID"; Rec."Transaction ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the posted payment reconciliation. ';
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the posted payment.';
                }
                field("Statement Amount"; Rec."Statement Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount on the bank transaction that represents the posted payment.';
                }
                field("Applied Amount"; Rec."Applied Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount that was applied to the related invoice or credit memo before this payment was posted.';
                }
                field(Difference; Rec.Difference)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the difference between the amount in the Statement Amount field and the Applied Amount field.';
                }
                field("Account Type"; Rec."Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the account that the payment was posted to.';
                }
                field("Account No."; Rec."Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account number that the payment was posted to.';
                }
                field("Applied Entries"; Rec."Applied Entries")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies which customer or vendor ledger entries were applied in relation to posting the payment.';
                    Visible = false;
                }
                field("Related-Party Name"; Rec."Related-Party Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies information about the customer or vendor that the posted payment was for.';
                    Visible = false;
                }
                field("Additional Transaction Info"; Rec."Additional Transaction Info")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies information about the transaction as recorded on the bank statement line.';
                    Visible = false;
                }
                field("Applied Document No."; Rec."Applied Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the document that the payment is applied to.';

                    trigger OnDrillDown()
                    var
                        CustLedgerEntry: Record "Cust. Ledger Entry";
                        VendorLedgerEntry: Record "Vendor Ledger Entry";
                        FilterValue: Text;
                    begin
                        if Rec."Applied Document No." <> '' then begin
                            FilterValue := ConvertStr(Rec."Applied Document No.", ',', '|');
                            case Rec."Account Type" of
                                Rec."Account Type"::Customer:
                                    begin
                                        CustLedgerEntry.SetFilter("Document No.", FilterValue);
                                        PAGE.RunModal(PAGE::"Customer Ledger Entries", CustLedgerEntry);
                                    end;
                                Rec."Account Type"::Vendor:
                                    begin
                                        VendorLedgerEntry.SetFilter("Document No.", FilterValue);
                                        PAGE.RunModal(PAGE::"Vendor Ledger Entries", VendorLedgerEntry);
                                    end;
                            end;
                        end;
                    end;
                }
            }
        }
    }

    actions
    {
    }
}

