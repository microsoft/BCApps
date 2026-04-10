// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Ledger;

using System.Diagnostics;

/// <summary>
/// Handles editing of G/L entries with validation and change logging capabilities.
/// Provides controlled modification of limited G/L entry fields with audit trail tracking.
/// </summary>
/// <remarks>
/// TableNo = G/L Entry. Validates critical fields remain unchanged during edit operations.
/// Includes event subscriber for automatic change logging of G/L Entry modifications.
/// Extensibility: OnBeforeGLLedgEntryModify event for custom validation logic.
/// </remarks>
codeunit 115 "G/L Entry-Edit"
{
    EventSubscriberInstance = Manual;
    Permissions = TableData "G/L Entry" = m;
    TableNo = "G/L Entry";

    trigger OnRun()
    var
        GLEntryEdit: Codeunit "G/L Entry-Edit";
    begin
        BindSubscription(GLEntryEdit);
        GLEntry := Rec;
        GLEntry.LockTable();
        GLEntry.Find();
        GLEntry.Description := Rec.Description;
        OnBeforeGLLedgEntryModify(GLEntry, Rec);
        GLEntry.TestField("Entry No.", Rec."Entry No.");
        GLEntry.TestField("Posting Date", Rec."Posting Date");
        GLEntry.TestField(Amount, Rec.Amount);
        GLEntry.TestField("Document No.", Rec."Document No.");
        GLEntry.TestField("VAT Amount", Rec."VAT Amount");
        GLEntry.TestField("Debit Amount", Rec."Debit Amount");
        GLEntry.TestField("Credit Amount", Rec."Credit Amount");
        GLEntry.Modify(true);
        Rec := GLEntry;
    end;

    var
        GLEntry: Record "G/L Entry";

    /// <summary>
    /// Integration event raised before modifying a G/L entry.
    /// </summary>
    /// <param name="GLEntry">G/L entry being modified</param>
    /// <param name="FromGLEntry">G/L entry with new values</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGLLedgEntryModify(var GLEntry: Record "G/L Entry"; FromGLEntry: Record "G/L Entry")
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Change Log Management", 'OnAfterIsAlwaysLoggedTable', '', false, false)]
    local procedure OnAfterIsAlwaysLoggedTable(TableID: Integer; var AlwaysLogTable: Boolean)
    begin
        if TableID = DATABASE::"G/L Entry" then
            AlwaysLogTable := true;
    end;
}

