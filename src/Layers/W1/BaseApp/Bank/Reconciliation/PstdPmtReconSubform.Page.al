// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Purchases.Payables;
using Microsoft.Sales.Receivables;

/// <summary>
/// Subform page for posted payment reconciliation lines.
/// Displays reconciliation line details within the posted reconciliation document.
/// </summary>
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
                }
                field("Statement Amount"; Rec."Statement Amount")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Applied Amount"; Rec."Applied Amount")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Difference; Rec.Difference)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Account Type"; Rec."Account Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Account No."; Rec."Account No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Applied Entries"; Rec."Applied Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Related-Party Name"; Rec."Related-Party Name")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Additional Transaction Info"; Rec."Additional Transaction Info")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Applied Document No."; Rec."Applied Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;

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

