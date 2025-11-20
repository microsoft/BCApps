// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Sales.Receivables;

codeunit 401 "Sales Header Apply"
{
    TableNo = "Sales Header";

    trigger OnRun()
    begin
        SalesHeader.Copy(Rec);
        BilToCustNo := SalesHeader."Bill-to Customer No.";
        CustLedgEntry.SetCurrentKey("Customer No.", Open);
        CustLedgEntry.SetRange("Customer No.", BilToCustNo);
        CustLedgEntry.SetRange(Open, true);
        OnRunOnAfterFilterCustLedgEntry(CustLedgEntry, SalesHeader);
        if SalesHeader."Applies-to ID" = '' then
            SalesHeader."Applies-to ID" := SalesHeader."No.";
        if SalesHeader."Applies-to ID" = '' then
            Error(
              Text000,
              SalesHeader.FieldCaption("No."), SalesHeader.FieldCaption("Applies-to ID"));
        ApplyCustEntries.SetSales(SalesHeader, CustLedgEntry, SalesHeader.FieldNo("Applies-to ID"));
        ApplyCustEntries.SetRecord(CustLedgEntry);
        ApplyCustEntries.SetTableView(CustLedgEntry);
        ApplyCustEntries.LookupMode(true);
        OK := ApplyCustEntries.RunModal() = ACTION::LookupOK;
        Clear(ApplyCustEntries);
        if not OK then
            exit;
        CustLedgEntry.Reset();
        CustLedgEntry.SetCurrentKey("Customer No.", Open);
        CustLedgEntry.SetRange("Customer No.", BilToCustNo);
        CustLedgEntry.SetRange(Open, true);
        CustLedgEntry.SetRange("Applies-to ID", SalesHeader."Applies-to ID");
        OnRunOnBeforeCustLedgEntryFindFirst(CustLedgEntry);
        if CustLedgEntry.FindFirst() then begin
            SalesHeader."Applies-to Doc. Type" := SalesHeader."Applies-to Doc. Type"::" ";
            SalesHeader."Applies-to Doc. No." := '';
        end else
            SalesHeader."Applies-to ID" := '';

        SalesHeader.Modify();
    end;

    var
        SalesHeader: Record "Sales Header";
        CustLedgEntry: Record "Cust. Ledger Entry";
        ApplyCustEntries: Page "Apply Customer Entries";
        BilToCustNo: Code[20];
        OK: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'You must specify %1 or %2.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterFilterCustLedgEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeCustLedgEntryFindFirst(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;
}

