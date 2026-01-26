// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Check;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.Receivables;

codeunit 10401 "Print Check Helper"
{

    trigger OnRun()
    begin
    end;

    procedure PrintSettledLoopHelper(var CustLedgEntry: Record "Cust. Ledger Entry"; var VendLedgEntry: Record "Vendor Ledger Entry"; var GenJnlLine: Record "Gen. Journal Line"; BalancingType: Option "G/L Account",Customer,Vendor,"Bank Account",,,Employee; BalancingNo: Code[20]; var FoundLast: Boolean; TestPrint: Boolean; FirstPage: Boolean; var FoundNegative: Boolean; ApplyMethod: Option Payment,OneLineOneEntry,OneLineID,MoreLinesOneEntry)
    begin
        if not TestPrint then
            if FirstPage then begin
                FoundLast := true;
                case ApplyMethod of
                    ApplyMethod::OneLineOneEntry:
                        FoundLast := false;
                    ApplyMethod::OneLineID:
                        case BalancingType of
                            BalancingType::Customer:
                                begin
                                    CustLedgEntry.Reset();
                                    CustLedgEntry.SetCurrentKey("Customer No.", Open, Positive);
                                    CustLedgEntry.SetRange("Customer No.", BalancingNo);
                                    CustLedgEntry.SetRange(Open, true);
                                    CustLedgEntry.SetRange(Positive, true);
                                    CustLedgEntry.SetRange("Applies-to ID", GenJnlLine."Applies-to ID");
                                    FoundLast := not CustLedgEntry.Find('-');
                                    if FoundLast then begin
                                        CustLedgEntry.SetRange(Positive, false);
                                        FoundLast := not CustLedgEntry.Find('-');
                                        FoundNegative := true;
                                    end else
                                        FoundNegative := false;
                                end;
                            BalancingType::Vendor:
                                begin
                                    VendLedgEntry.Reset();
                                    VendLedgEntry.SetCurrentKey("Vendor No.", Open, Positive);
                                    VendLedgEntry.SetRange("Vendor No.", BalancingNo);
                                    VendLedgEntry.SetRange(Open, true);
                                    VendLedgEntry.SetRange(Positive, true);
                                    VendLedgEntry.SetRange("Applies-to ID", GenJnlLine."Applies-to ID");
                                    if GenJnlLine."Remit-to Code" <> '' then
                                        VendLedgEntry.SetRange("Remit-to Code", GenJnlLine."Remit-to Code")
                                    else
                                        VendLedgEntry.SetRange("Remit-to Code", '');

                                    FoundLast := not VendLedgEntry.Find('-');
                                    if FoundLast then begin
                                        VendLedgEntry.SetRange(Positive, false);
                                        FoundLast := not VendLedgEntry.Find('-');
                                        FoundNegative := true;
                                    end else
                                        FoundNegative := false;
                                end;
                        end;
                    ApplyMethod::MoreLinesOneEntry:
                        FoundLast := false;
                end;
            end else
                FoundLast := false;
    end;
}

