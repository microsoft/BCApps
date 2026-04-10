// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Bank.Ledger;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.HumanResources.Payables;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.Receivables;

/// <summary>
/// Displays ledger entries related to general journal line accounts for transaction history and verification.
/// Shows appropriate ledger entries based on account type including G/L, customer, vendor, bank, and fixed asset entries.
/// </summary>
/// <remarks>
/// Core functionality for viewing historical ledger entries associated with journal line accounts.
/// Account type-specific entry display: G/L entries, customer ledger entries, vendor ledger entries, bank entries, FA entries.
/// Key features: Account-filtered entry display, most recent entry positioning, extensible via integration events.
/// Integration: Provides seamless navigation from journal lines to corresponding posted ledger entries.
/// </remarks>
codeunit 14 "Gen. Jnl.-Show Entries"
{
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        case Rec."Account Type" of
            Rec."Account Type"::"G/L Account":
                begin
                    GLEntry.SetCurrentKey("G/L Account No.", "Posting Date");
                    GLEntry.SetRange("G/L Account No.", Rec."Account No.");
                    if GLEntry.FindLast() then;
                    OnBeforeShowGLEntries(Rec, GLEntry, IsHandled);
                    if not IsHandled then
                        PAGE.Run(PAGE::"General Ledger Entries", GLEntry);
                end;
            Rec."Account Type"::Customer:
                begin
                    CustLedgEntry.SetCurrentKey("Customer No.", "Posting Date");
                    CustLedgEntry.SetRange("Customer No.", Rec."Account No.");
                    if CustLedgEntry.FindLast() then;
                    OnBeforeShowCustomerLedgerEntries(Rec, CustLedgEntry, IsHandled);
                    if not IsHandled then
                        PAGE.Run(PAGE::"Customer Ledger Entries", CustLedgEntry);
                end;
            Rec."Account Type"::Vendor:
                begin
                    VendLedgEntry.SetCurrentKey("Vendor No.", "Posting Date");
                    VendLedgEntry.SetRange("Vendor No.", Rec."Account No.");
                    if VendLedgEntry.FindLast() then;
                    OnBeforeShowVendorLedgerEntries(Rec, VendLedgEntry, IsHandled);
                    if not IsHandled then
                        PAGE.Run(PAGE::"Vendor Ledger Entries", VendLedgEntry);
                end;
            Rec."Account Type"::Employee:
                begin
                    EmplLedgEntry.SetCurrentKey("Employee No.", "Posting Date");
                    EmplLedgEntry.SetRange("Employee No.", Rec."Account No.");
                    if EmplLedgEntry.FindLast() then;
                    OnBeforeShowEmployeeLedgerEntries(Rec, EmplLedgEntry, IsHandled);
                    if not IsHandled then
                        PAGE.Run(PAGE::"Employee Ledger Entries", EmplLedgEntry);
                end;
            Rec."Account Type"::"Bank Account":
                begin
                    BankAccLedgEntry.SetCurrentKey("Bank Account No.", "Posting Date");
                    BankAccLedgEntry.SetRange("Bank Account No.", Rec."Account No.");
                    if BankAccLedgEntry.FindLast() then;
                    OnBeforeShowBankAccountLedgerEntries(Rec, BankAccLedgEntry, IsHandled);
                    if not IsHandled then
                        PAGE.Run(PAGE::"Bank Account Ledger Entries", BankAccLedgEntry);
                end;
            Rec."Account Type"::"Fixed Asset":
                if Rec."FA Posting Type" <> Rec."FA Posting Type"::Maintenance then begin
                    FALedgEntry.SetCurrentKey("FA No.", "Depreciation Book Code", "FA Posting Date");
                    FALedgEntry.SetRange("FA No.", Rec."Account No.");
                    if Rec."Depreciation Book Code" <> '' then
                        FALedgEntry.SetRange("Depreciation Book Code", Rec."Depreciation Book Code");
                    if FALedgEntry.FindLast() then;
                    OnBeforeShowFALedgerEntries(Rec, FALedgEntry, IsHandled);
                    if not IsHandled then
                        PAGE.Run(PAGE::"FA Ledger Entries", FALedgEntry);
                end else begin
                    MaintenanceLedgEntry.SetCurrentKey("FA No.", "Depreciation Book Code", "FA Posting Date");
                    MaintenanceLedgEntry.SetRange("FA No.", Rec."Account No.");
                    if Rec."Depreciation Book Code" <> '' then
                        MaintenanceLedgEntry.SetRange("Depreciation Book Code", Rec."Depreciation Book Code");
                    if MaintenanceLedgEntry.FindLast() then;
                    OnBeforeShowMaintenanceLedgerEntries(Rec, MaintenanceLedgEntry, IsHandled);
                    if not IsHandled then
                        PAGE.Run(PAGE::"Maintenance Ledger Entries", MaintenanceLedgEntry);
                end;
            Rec."Account Type"::"IC Partner":
                Error(Text001);
        end;

        OnAfterRun(Rec);
    end;

    var
        GLEntry: Record "G/L Entry";
        EmplLedgEntry: Record "Employee Ledger Entry";
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        BankAccLedgEntry: Record "Bank Account Ledger Entry";
        FALedgEntry: Record "FA Ledger Entry";
        MaintenanceLedgEntry: Record "Maintenance Ledger Entry";
#pragma warning disable AA0074
        Text001: Label 'Intercompany partners do not have ledger entries.';
#pragma warning restore AA0074

    /// <summary>
    /// Integration event raised after completing ledger entry display operations.
    /// Enables custom processing after standard ledger entry display logic completes.
    /// </summary>
    /// <param name="GenJournalLine">General journal line context that triggered entry display</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterRun(GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Integration event raised before displaying G/L entries for G/L account type journal lines.
    /// Enables custom handling or bypassing of G/L entry display functionality.
    /// </summary>
    /// <param name="GenJournalLine">General journal line with G/L account context</param>
    /// <param name="GLEntry">G/L entry record positioned for display</param>
    /// <param name="IsHandled">Set to true to skip standard G/L entry display processing</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowGLEntries(GenJournalLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before displaying customer ledger entries for customer account type journal lines.
    /// Enables custom handling or bypassing of customer ledger entry display functionality.
    /// </summary>
    /// <param name="GenJournalLine">General journal line with customer account context</param>
    /// <param name="CustLedgEntry">Customer ledger entry record positioned for display</param>
    /// <param name="IsHandled">Set to true to skip standard customer ledger entry display processing</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowCustomerLedgerEntries(GenJournalLine: Record "Gen. Journal Line"; var CustLedgEntry: Record "Cust. Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before displaying vendor ledger entries for vendor account type journal lines.
    /// Enables custom handling or bypassing of vendor ledger entry display functionality.
    /// </summary>
    /// <param name="GenJournalLine">General journal line with vendor account context</param>
    /// <param name="VendLedgEntry">Vendor ledger entry record positioned for display</param>
    /// <param name="IsHandled">Set to true to skip standard vendor ledger entry display processing</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowVendorLedgerEntries(GenJournalLine: Record "Gen. Journal Line"; var VendLedgEntry: Record "Vendor Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before displaying employee ledger entries for employee account type journal lines.
    /// Enables custom handling or bypassing of employee ledger entry display functionality.
    /// </summary>
    /// <param name="GenJournalLine">General journal line with employee account context</param>
    /// <param name="EmplLedgEntry">Employee ledger entry record positioned for display</param>
    /// <param name="IsHandled">Set to true to skip standard employee ledger entry display processing</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowEmployeeLedgerEntries(GenJournalLine: Record "Gen. Journal Line"; var EmplLedgEntry: Record "Employee Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before displaying bank account ledger entries for bank account type journal lines.
    /// Enables custom handling or bypassing of bank account ledger entry display functionality.
    /// </summary>
    /// <param name="GenJournalLine">General journal line with bank account context</param>
    /// <param name="BankAccLedgEntry">Bank account ledger entry record positioned for display</param>
    /// <param name="IsHandled">Set to true to skip standard bank account ledger entry display processing</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowBankAccountLedgerEntries(GenJournalLine: Record "Gen. Journal Line"; var BankAccLedgEntry: Record "Bank Account Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before displaying fixed asset ledger entries for fixed asset account type journal lines.
    /// Enables custom handling or bypassing of fixed asset ledger entry display functionality.
    /// </summary>
    /// <param name="GenJournalLine">General journal line with fixed asset account context</param>
    /// <param name="FALedgEntry">Fixed asset ledger entry record positioned for display</param>
    /// <param name="IsHandled">Set to true to skip standard FA ledger entry display processing</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowFALedgerEntries(GenJournalLine: Record "Gen. Journal Line"; var FALedgEntry: Record "FA Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before displaying maintenance ledger entries for fixed asset maintenance journal lines.
    /// Enables custom handling or bypassing of maintenance ledger entry display functionality.
    /// </summary>
    /// <param name="GenJournalLine">General journal line with fixed asset maintenance context</param>
    /// <param name="MaintenanceLedgEntry">Maintenance ledger entry record positioned for display</param>
    /// <param name="IsHandled">Set to true to skip standard maintenance ledger entry display processing</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowMaintenanceLedgerEntries(GenJournalLine: Record "Gen. Journal Line"; var MaintenanceLedgEntry: Record "Maintenance Ledger Entry"; var IsHandled: Boolean)
    begin
    end;
}

