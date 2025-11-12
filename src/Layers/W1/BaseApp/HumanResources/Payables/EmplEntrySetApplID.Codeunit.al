// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Payables;

codeunit 112 "Empl. Entry-SetAppl.ID"
{
    Permissions = TableData "Employee Ledger Entry" = rimd;

    trigger OnRun()
    begin
    end;

    var
        EmplEntryApplID: Code[50];

    procedure SetApplId(var EmplLedgEntry: Record "Employee Ledger Entry"; ApplyingEmplLedgEntry: Record "Employee Ledger Entry"; AppliesToID: Code[50])
    var
        TempEmplLedgEntry: Record "Employee Ledger Entry" temporary;
        EmplLedgEntryToUpdate: Record "Employee Ledger Entry";
    begin
        EmplLedgEntry.LockTable();
        if EmplLedgEntry.FindSet() then begin
            // Make Applies-to ID
            if EmplLedgEntry."Applies-to ID" <> '' then
                EmplEntryApplID := ''
            else begin
                EmplEntryApplID := AppliesToID;
                if EmplEntryApplID = '' then begin
                    EmplEntryApplID := CopyStr(UserId(), 1, 50);
                    if EmplEntryApplID = '' then
                        EmplEntryApplID := '***';
                end;
            end;
            repeat
                TempEmplLedgEntry := EmplLedgEntry;
                TempEmplLedgEntry.Insert();
            until EmplLedgEntry.Next() = 0;
        end;

        if TempEmplLedgEntry.FindSet() then
            repeat
                EmplLedgEntryToUpdate.Copy(TempEmplLedgEntry);
                EmplLedgEntryToUpdate.TestField(Open, true);
                EmplLedgEntryToUpdate."Applies-to ID" := EmplEntryApplID;

                if ((EmplLedgEntryToUpdate."Amount to Apply" <> 0) and (EmplEntryApplID = '')) or
                   (EmplEntryApplID = '')
                then
                    EmplLedgEntryToUpdate."Amount to Apply" := 0
                else
                    if EmplLedgEntryToUpdate."Amount to Apply" = 0 then begin
                        EmplLedgEntryToUpdate.CalcFields("Remaining Amount");
                        if EmplLedgEntryToUpdate."Remaining Amount" <> 0 then
                            EmplLedgEntryToUpdate."Amount to Apply" := EmplLedgEntryToUpdate."Remaining Amount";
                    end;

                if EmplLedgEntryToUpdate."Entry No." = ApplyingEmplLedgEntry."Entry No." then
                    EmplLedgEntryToUpdate."Applying Entry" := ApplyingEmplLedgEntry."Applying Entry";
                EmplLedgEntryToUpdate.Modify();
                OnSetApplIdOnAfterEmplLedgEntryToUpdateModify(EmplLedgEntryToUpdate, TempEmplLedgEntry, ApplyingEmplLedgEntry, AppliesToID);
            until TempEmplLedgEntry.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetApplIdOnAfterEmplLedgEntryToUpdateModify(var EmplLedgerEntry: Record "Employee Ledger Entry"; var TempEmplLedgEntry: Record "Employee Ledger Entry" temporary; ApplyingEmplLedgEntry: Record "Employee Ledger Entry"; AppliesToID: Code[50])
    begin
    end;
}

