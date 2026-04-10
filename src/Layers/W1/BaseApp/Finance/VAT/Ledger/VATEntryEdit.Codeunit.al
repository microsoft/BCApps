// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Ledger;

/// <summary>
/// Provides controlled editing capabilities for VAT entries with validation and event integration.
/// Handles G/L account number updates and ensures data consistency during VAT entry modifications.
/// </summary>
/// <remarks>
/// Specialized codeunit for VAT entry editing operations with comprehensive validation and event support.
/// Integrates with VAT posting validation and provides extensibility through modification events.
/// </remarks>
codeunit 338 "VAT Entry - Edit"
{
    Permissions = TableData "VAT Entry" = m;
    TableNo = "VAT Entry";

    trigger OnRun()
    begin
        VATEntry := Rec;
        VATEntry.LockTable();
        VATEntry.Find();
        VATEntry.Validate(Type);
        VATEntry."VAT Reporting Date" := Rec."VAT Reporting Date";
        VATEntry."Bill-to/Pay-to No." := Rec."Bill-to/Pay-to No.";
        VATEntry."Ship-to/Order Address Code" := Rec."Ship-to/Order Address Code";
        VATEntry."EU 3-Party Trade" := Rec."EU 3-Party Trade";
        VATEntry."Country/Region Code" := Rec."Country/Region Code";
        VATEntry."VAT Registration No." := Rec."VAT Registration No.";
        OnBeforeVATEntryModify(VATEntry, Rec);
        VATEntry.TestField("Entry No.", Rec."Entry No.");
        VATEntry.TestField("Posting Date", Rec."Posting Date");
        VATEntry.TestField(Amount, Rec.Amount);
        VATEntry.TestField(Base, Rec.Base);
        VATEntry.Modify();
        OnRunOnAfterVATEntryModify(VATEntry, Rec);
        Rec := VATEntry;
    end;

    var
        VATEntry: Record "VAT Entry";

    /// <summary>
    /// Updates the G/L account number on a VAT entry record and saves the changes.
    /// Ensures proper linking between VAT entries and their corresponding G/L accounts.
    /// </summary>
    /// <param name="VATEntryModify">VAT entry record to modify</param>
    /// <param name="GLAccountNo">G/L account number to assign</param>
    procedure SetGLAccountNo(var VATEntryModify: Record "VAT Entry"; GLAccountNo: Code[20])
    begin
        VATEntryModify."G/L Acc. No." := GLAccountNo;
        VATEntryModify.Modify();
    end;

    /// <summary>
    /// Updates the G/L account number for a specific VAT entry identified by entry number.
    /// Performs bulk modification without triggering individual record events.
    /// </summary>
    /// <param name="VATEntryNo">VAT entry number to update</param>
    /// <param name="GLAccountNo">G/L account number to assign</param>
    procedure SetGLAccountNo(VATEntryNo: Integer; GLAccountNo: Code[20])
    begin
        VATEntry.SetRange("Entry No.", VATEntryNo);
        VATEntry.ModifyAll("G/L Acc. No.", GLAccountNo, false);
    end;

    /// <summary>
    /// Integration event raised before modifying a VAT entry during the edit process.
    /// Allows custom validation or additional field updates before the VAT entry is saved.
    /// </summary>
    /// <param name="VATEntry">VAT entry record being modified</param>
    /// <param name="FromVATEntry">Original VAT entry record with new values</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeVATEntryModify(var VATEntry: Record "VAT Entry"; FromVATEntry: Record "VAT Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised after successfully modifying a VAT entry during the edit process.
    /// Enables custom processing or notifications after the VAT entry has been updated and saved.
    /// </summary>
    /// <param name="VATEntry">VAT entry record that was modified</param>
    /// <param name="FromVATEntry">Original VAT entry record that provided the new values</param>
    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterVATEntryModify(var VATEntry: Record "VAT Entry"; FromVATEntry: Record "VAT Entry")
    begin
    end;
}

