// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Bank.Payment;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.HumanResources.Payables;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.Receivables;

codeunit 16 "Gen. Jnl.-Show CT Entries"
{
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnRun(Rec, IsHandled);
        if IsHandled then
            exit;

        if not (Rec."Document Type" in [Rec."Document Type"::Payment, Rec."Document Type"::Refund, Rec."Document Type"::" "]) then
            exit;
        if not (Rec."Account Type" in [Rec."Account Type"::Customer, Rec."Account Type"::Vendor, Rec."Account Type"::Employee]) then
            exit;

        SetFiltersOnCreditTransferEntry(Rec, CreditTransferEntry);

        PAGE.Run(PAGE::"Credit Transfer Reg. Entries", CreditTransferEntry);
    end;

    var
        CreditTransferEntry: Record "Credit Transfer Entry";

    procedure SetFiltersOnCreditTransferEntry(var GenJournalLine: Record "Gen. Journal Line"; var CreditTransferEntry: Record "Credit Transfer Entry")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        FoundCorrespondingLedgerEntry: Boolean;
    begin
        CreditTransferEntry.Reset();
        FoundCorrespondingLedgerEntry := false;
        case GenJournalLine."Account Type" of
            GenJournalLine."Account Type"::Vendor:
                begin
                    CreditTransferEntry.SetRange("Account Type", CreditTransferEntry."Account Type"::Vendor);
                    if (GenJournalLine."Applies-to Doc. No." <> '') or (GenJournalLine."Applies-to ID" <> '') then begin
                        VendorLedgerEntry.SetRange("Vendor No.", GenJournalLine."Account No.");
                        if GenJournalLine."Applies-to Doc. No." <> '' then begin
                            VendorLedgerEntry.SetRange("Document Type", GenJournalLine."Applies-to Doc. Type");
                            VendorLedgerEntry.SetRange("Document No.", GenJournalLine."Applies-to Doc. No.");
                        end;
                        if GenJournalLine."Applies-to ID" <> '' then begin
                            VendorLedgerEntry.SetCurrentKey("Vendor No.", "Applies-to ID", Open, Positive, "Due Date");
                            VendorLedgerEntry.SetRange("Applies-to ID", GenJournalLine."Applies-to ID");
                        end;
                        if VendorLedgerEntry.FindFirst() then begin
                            CreditTransferEntry.SetRange("Applies-to Entry No.", VendorLedgerEntry."Entry No.");
                            FoundCorrespondingLedgerEntry := true;
                        end;
                    end;
                end;
            GenJournalLine."Account Type"::Customer:
                begin
                    CreditTransferEntry.SetRange("Account Type", CreditTransferEntry."Account Type"::Customer);
                    if (GenJournalLine."Applies-to Doc. No." <> '') or (GenJournalLine."Applies-to ID" <> '') then begin
                        CustLedgerEntry.SetRange("Customer No.", GenJournalLine."Account No.");
                        if GenJournalLine."Applies-to Doc. No." <> '' then begin
                            CustLedgerEntry.SetRange("Document Type", GenJournalLine."Applies-to Doc. Type");
                            CustLedgerEntry.SetRange("Document No.", GenJournalLine."Applies-to Doc. No.");
                        end;
                        if GenJournalLine."Applies-to ID" <> '' then
                            CustLedgerEntry.SetRange("Applies-to ID", GenJournalLine."Applies-to ID");
                        if CustLedgerEntry.FindFirst() then begin
                            CreditTransferEntry.SetRange("Applies-to Entry No.", CustLedgerEntry."Entry No.");
                            FoundCorrespondingLedgerEntry := true;
                        end;
                    end;
                end;
            GenJournalLine."Account Type"::Employee:
                begin
                    CreditTransferEntry.SetRange("Account Type", CreditTransferEntry."Account Type"::Employee);
                    if (GenJournalLine."Applies-to Doc. No." <> '') or (GenJournalLine."Applies-to ID" <> '') then begin
                        EmployeeLedgerEntry.SetRange("Employee No.", GenJournalLine."Account No.");
                        if GenJournalLine."Applies-to Doc. No." <> '' then begin
                            EmployeeLedgerEntry.SetRange("Document Type", GenJournalLine."Applies-to Doc. Type");
                            EmployeeLedgerEntry.SetRange("Document No.", GenJournalLine."Applies-to Doc. No.");
                        end;
                        if GenJournalLine."Applies-to ID" <> '' then
                            EmployeeLedgerEntry.SetRange("Applies-to ID", GenJournalLine."Applies-to ID");
                        if EmployeeLedgerEntry.FindFirst() then begin
                            CreditTransferEntry.SetRange("Applies-to Entry No.", EmployeeLedgerEntry."Entry No.");
                            FoundCorrespondingLedgerEntry := true;
                        end;
                    end;
                end;
            else
                OnSetFiltersOnCreditTransferEntryOnCaseElse(GenJournalLine, CreditTransferEntry, FoundCorrespondingLedgerEntry);
        end;
        CreditTransferEntry.SetRange("Account No.", GenJournalLine."Account No.");
        if not FoundCorrespondingLedgerEntry then
            CreditTransferEntry.SetRange("Applies-to Entry No.", 0);
        GeneralLedgerSetup.Get();
        CreditTransferEntry.SetFilter(
          "Currency Code", '''%1''|''%2''', GenJournalLine."Currency Code", GeneralLedgerSetup.GetCurrencyCode(GenJournalLine."Currency Code"));
        CreditTransferEntry.SetRange(Canceled, false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetFiltersOnCreditTransferEntryOnCaseElse(var GenJournalLine: Record "Gen. Journal Line"; var CreditTransferEntry: Record "Credit Transfer Entry"; var FoundCorrespondingLedgerEntry: Boolean)
    begin
    end;
}

