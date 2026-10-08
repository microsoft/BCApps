// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Payables;

codeunit 114 "Empl. Entry-Edit"
{
    Permissions = TableData "Employee Ledger Entry" = rm,
                  TableData "Detailed Employee Ledger Entry" = rm;
    TableNo = "Employee Ledger Entry";

    trigger OnRun()
    begin
        EmplLedgEntry := Rec;
        EmplLedgEntry.LockTable();
        EmplLedgEntry.Find();
        if EmplLedgEntry.Open then begin
            EmplLedgEntry."Applies-to ID" := Rec."Applies-to ID";
            EmplLedgEntry.Validate("Payment Method Code", Rec."Payment Method Code");
            EmplLedgEntry.Validate("Amount to Apply", Rec."Amount to Apply");
            EmplLedgEntry.Validate("Applying Entry", Rec."Applying Entry");
            EmplLedgEntry.Validate("Message to Recipient", Rec."Message to Recipient");
        end;
        EmplLedgEntry.Validate("Exported to Payment File", Rec."Exported to Payment File");
        EmplLedgEntry.Validate("Creditor No.", Rec."Creditor No.");
        EmplLedgEntry.Validate("Payment Reference", Rec."Payment Reference");
        OnBeforeEmplLedgEntryModify(EmplLedgEntry, Rec);
        EmplLedgEntry.TestField("Entry No.", Rec."Entry No.");
        EmplLedgEntry.Modify();
        Rec := EmplLedgEntry;
    end;

    var
        EmplLedgEntry: Record "Employee Ledger Entry";

    [IntegrationEvent(false, false)]
    local procedure OnBeforeEmplLedgEntryModify(var EmplLedgEntry: Record "Employee Ledger Entry"; FromEmplLedgEntry: Record "Employee Ledger Entry")
    begin
    end;
}

