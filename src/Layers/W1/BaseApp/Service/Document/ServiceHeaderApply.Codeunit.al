// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Sales.Receivables;

codeunit 5971 "Service Header Apply"
{
    TableNo = "Service Header";

    trigger OnRun()
    begin
        ServHeader.Copy(Rec);
        BilToCustNo := ServHeader."Bill-to Customer No.";
        CustLedgEntry.SetCurrentKey("Customer No.", Open);
        CustLedgEntry.SetRange("Customer No.", BilToCustNo);
        CustLedgEntry.SetRange(Open, true);
        OnRunOnAfterSetCustLedgEntryFilters(CustLedgEntry, ServHeader);
        if ServHeader."Applies-to ID" = '' then
            ServHeader."Applies-to ID" := ServHeader."No.";
        if ServHeader."Applies-to ID" = '' then
            Error(Text000, ServHeader.FieldCaption("No."), ServHeader.FieldCaption("Applies-to ID"));

        ServApplyCustEntries.SetService(ServHeader, CustLedgEntry, ServHeader.FieldNo("Applies-to ID"));
        ServApplyCustEntries.SetRecord(CustLedgEntry);
        ServApplyCustEntries.SetTableView(CustLedgEntry);
        ServApplyCustEntries.LookupMode(true);
        OK := ServApplyCustEntries.RunModal() = ACTION::LookupOK;
        Clear(ServApplyCustEntries);
        if not OK then
            exit;
        CustLedgEntry.Reset();
        CustLedgEntry.SetCurrentKey("Customer No.", Open);
        CustLedgEntry.SetRange("Customer No.", BilToCustNo);
        CustLedgEntry.SetRange(Open, true);
        CustLedgEntry.SetRange("Applies-to ID", ServHeader."Applies-to ID");
        if CustLedgEntry.FindFirst() then begin
            ServHeader."Applies-to Doc. Type" := ServHeader."Applies-to Doc. Type"::" ";
            ServHeader."Applies-to Doc. No." := '';
        end else
            ServHeader."Applies-to ID" := '';

        ServHeader.Modify();
    end;

    var
        ServHeader: Record "Service Header";
        CustLedgEntry: Record "Cust. Ledger Entry";
        ServApplyCustEntries: Page "Serv. Apply Customer Entries";
        BilToCustNo: Code[20];
        OK: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'You must specify %1 or %2.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterSetCustLedgEntryFilters(var CustLedgEntry: Record "Cust. Ledger Entry"; ServiceHeader: Record "Service Header")
    begin
    end;
}

