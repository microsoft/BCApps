// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Receivables;

/// <summary>
/// Manages the Applies-to ID field on customer ledger entries to mark entries for application during payment processing.
/// </summary>
codeunit 101 "Cust. Entry-SetAppl.ID"
{
    Permissions = TableData "Cust. Ledger Entry" = rimd;

    trigger OnRun()
    begin
    end;

    var
        CustEntryApplID: Code[50];

    /// <summary>
    /// Sets or clears the Applies-to ID on the specified customer ledger entries for application processing.
    /// </summary>
    /// <param name="CustLedgEntry">Specifies the customer ledger entries to set the Applies-to ID on.</param>
    /// <param name="ApplyingCustLedgEntry">Specifies the customer ledger entry that is applying to other entries.</param>
    /// <param name="AppliesToID">Specifies the Applies-to ID to set on the entries.</param>
    procedure SetApplId(var CustLedgEntry: Record "Cust. Ledger Entry"; ApplyingCustLedgEntry: Record "Cust. Ledger Entry"; AppliesToID: Code[50])
    var
        TempCustLedgEntry: Record "Cust. Ledger Entry" temporary;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetApplId(CustLedgEntry, ApplyingCustLedgEntry, AppliesToID, CustEntryApplID, IsHandled);
        if IsHandled then
            exit;
        CustLedgEntry.ReadIsolation(IsolationLevel::UpdLock);
        if CustLedgEntry.FindSet() then begin
            // Make Applies-to ID
            if CustLedgEntry."Applies-to ID" <> '' then
                CustEntryApplID := ''
            else begin
                CustEntryApplID := AppliesToID;
                if CustEntryApplID = '' then begin
                    CustEntryApplID := UserId;
                    if CustEntryApplID = '' then
                        CustEntryApplID := '***';
                end;
            end;
            repeat
                TempCustLedgEntry := CustLedgEntry;
                TempCustLedgEntry.Insert();
            until CustLedgEntry.Next() = 0;
        end;

        if TempCustLedgEntry.FindSet() then
            repeat
                UpdateCustLedgerEntry(TempCustLedgEntry, ApplyingCustLedgEntry, AppliesToID);
            until TempCustLedgEntry.Next() = 0;
    end;

    local procedure UpdateCustLedgerEntry(var TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary; ApplyingCustLedgerEntry: Record "Cust. Ledger Entry"; AppliesToID: Code[50])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateCustLedgerEntry(TempCustLedgerEntry, ApplyingCustLedgerEntry, AppliesToID, IsHandled, CustEntryApplID);
        if IsHandled then
            exit;

        CustLedgerEntry.Copy(TempCustLedgerEntry);
        CustLedgerEntry.TestField(Open, true);
        CustLedgerEntry."Applies-to ID" := CustEntryApplID;
        if CustLedgerEntry."Applies-to ID" = '' then begin
            CustLedgerEntry."Accepted Pmt. Disc. Tolerance" := false;
            CustLedgerEntry."Accepted Payment Tolerance" := 0;
        end;
        if ((CustLedgerEntry."Amount to Apply" <> 0) and (CustEntryApplID = '')) or
           (CustEntryApplID = '')
        then
            CustLedgerEntry."Amount to Apply" := 0
        else
            if CustLedgerEntry."Amount to Apply" = 0 then begin
                CustLedgerEntry.CalcFields("Remaining Amount");
                CustLedgerEntry."Amount to Apply" := CustLedgerEntry."Remaining Amount"
            end;

        if CustLedgerEntry."Entry No." = ApplyingCustLedgerEntry."Entry No." then
            CustLedgerEntry."Applying Entry" := ApplyingCustLedgerEntry."Applying Entry";
        OnUpdateCustLedgerEntryOnBeforeCustLedgerEntryModify(CustLedgerEntry, TempCustLedgerEntry, ApplyingCustLedgerEntry, AppliesToID);
        CustLedgerEntry.Modify();

        OnAfterUpdateCustLedgerEntry(CustLedgerEntry, TempCustLedgerEntry, ApplyingCustLedgerEntry, AppliesToID);
    end;

    /// <summary>
    /// Removes the Applies-to ID from customer ledger entries that match the specified ID.
    /// </summary>
    /// <param name="CustLedgerEntry">Specifies the customer ledger entries to remove the Applies-to ID from.</param>
    /// <param name="AppliestoID">Specifies the Applies-to ID to match and remove.</param>
    procedure RemoveApplId(var CustLedgerEntry: Record "Cust. Ledger Entry"; AppliestoID: Code[50])
    begin
        if CustLedgerEntry.FindSet() then
            repeat
                if CustLedgerEntry."Applies-to ID" = AppliestoID then begin
                    CustLedgerEntry."Applies-to ID" := '';
                    CustLedgerEntry."Accepted Pmt. Disc. Tolerance" := false;
                    CustLedgerEntry."Accepted Payment Tolerance" := 0;
                    CustLedgerEntry."Amount to Apply" := 0;
                    CustLedgerEntry.Modify();
                end;
            until CustLedgerEntry.Next() = 0;
    end;

    /// <summary>
    /// Raised before updating a customer ledger entry with the Applies-to ID.
    /// </summary>
    /// <param name="TempCustLedgerEntry">The temporary customer ledger entry to update.</param>
    /// <param name="ApplyingCustLedgerEntry">The applying customer ledger entry.</param>
    /// <param name="AppliesToID">The Applies-to ID being set.</param>
    /// <param name="IsHandled">Set to true to skip default processing.</param>
    /// <param name="CustEntryApplID">The calculated customer entry application ID.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateCustLedgerEntry(var TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary; ApplyingCustLedgerEntry: Record "Cust. Ledger Entry"; AppliesToID: Code[50]; var IsHandled: Boolean; var CustEntryApplID: Code[50]);
    begin
    end;

    /// <summary>
    /// Raised after updating a customer ledger entry with the Applies-to ID.
    /// </summary>
    /// <param name="CustLedgerEntry">The updated customer ledger entry.</param>
    /// <param name="TempCustLedgerEntry">The temporary customer ledger entry.</param>
    /// <param name="ApplyingCustLedgerEntry">The applying customer ledger entry.</param>
    /// <param name="AppliesToID">The Applies-to ID that was set.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateCustLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; var TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary; ApplyingCustLedgerEntry: Record "Cust. Ledger Entry"; AppliesToID: Code[50]);
    begin
    end;

    /// <summary>
    /// Raised before modifying the customer ledger entry during the update process.
    /// </summary>
    /// <param name="CustLedgerEntry">The customer ledger entry to modify.</param>
    /// <param name="TempCustLedgerEntry">The temporary customer ledger entry.</param>
    /// <param name="ApplyingCustLedgerEntry">The applying customer ledger entry.</param>
    /// <param name="AppliesToID">The Applies-to ID being set.</param>
    [IntegrationEvent(false, false)]
    local procedure OnUpdateCustLedgerEntryOnBeforeCustLedgerEntryModify(var CustLedgerEntry: Record "Cust. Ledger Entry"; var TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary; ApplyingCustLedgerEntry: Record "Cust. Ledger Entry"; AppliesToID: Code[50]);
    begin
    end;

    /// <summary>
    /// Raised before setting the Applies-to ID on customer ledger entries.
    /// </summary>
    /// <param name="CustLedgEntry">The customer ledger entries to update.</param>
    /// <param name="ApplyingCustLedgEntry">The applying customer ledger entry.</param>
    /// <param name="AppliesToID">The Applies-to ID to set.</param>
    /// <param name="CustEntryApplID">The calculated customer entry application ID.</param>
    /// <param name="IsHandled">Set to true to skip default processing.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetApplId(var CustLedgEntry: Record "Cust. Ledger Entry"; ApplyingCustLedgEntry: Record "Cust. Ledger Entry"; var AppliesToID: Code[50]; var CustEntryApplID: Code[50]; var IsHandled: Boolean);
    begin
    end;
}

