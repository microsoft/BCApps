// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Ledger;

using Microsoft.Finance.GeneralLedger.Ledger;

/// <summary>
/// Link table connecting general ledger entries with their corresponding VAT entries for audit trail and reconciliation.
/// Maintains referential integrity between G/L and VAT posting for accurate financial reporting and compliance tracking.
/// </summary>
/// <remarks>
/// Core integration table for VAT ledger functionality. Supports automatic G/L account number adjustment on VAT entries.
/// Extensible through insertion and adjustment events for custom VAT/G/L integration scenarios.
/// </remarks>
table 253 "G/L Entry - VAT Entry Link"
{
    Caption = 'G/L Entry - VAT Entry Link';
    Permissions = TableData "G/L Entry - VAT Entry Link" = rimd;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// General ledger entry number linking to the corresponding G/L transaction record.
        /// </summary>
        field(1; "G/L Entry No."; Integer)
        {
            Caption = 'G/L Entry No.';
            TableRelation = "G/L Entry"."Entry No.";
        }
        /// <summary>
        /// VAT entry number linking to the corresponding VAT transaction record.
        /// </summary>
        field(2; "VAT Entry No."; Integer)
        {
            Caption = 'VAT Entry No.';
            TableRelation = "VAT Entry"."Entry No.";
        }
    }

    keys
    {
        key(Key1; "G/L Entry No.", "VAT Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "VAT Entry No.")
        {
        }
    }

    fieldgroups
    {
    }

    /// <summary>
    /// Creates a link between a general ledger entry and a VAT entry for audit trail purposes.
    /// </summary>
    /// <param name="GLEntryNo">General ledger entry number to link</param>
    /// <param name="VATEntryNo">VAT entry number to link</param>
    procedure InsertLink(GLEntryNo: Integer; VATEntryNo: Integer)
    var
        GLEntryVatEntryLink: Record "G/L Entry - VAT Entry Link";
    begin
        GLEntryVatEntryLink.InsertLinkSelf(GLEntryNo, VATEntryNo);
    end;

    /// <summary>
    /// Creates a link record in the current instance between a G/L entry and VAT entry.
    /// Raises integration event to notify subscribers of the new link creation.
    /// </summary>
    /// <param name="GLEntryNo">General ledger entry number to link</param>
    /// <param name="VATEntryNo">VAT entry number to link</param>
    procedure InsertLinkSelf(GLEntryNo: Integer; VATEntryNo: Integer)
    begin
        Init();
        "G/L Entry No." := GLEntryNo;
        "VAT Entry No." := VATEntryNo;
        Insert();

        OnInsertLink(Rec);
    end;

    /// <summary>
    /// Creates a link between G/L and VAT entries and automatically adjusts the G/L account number on the VAT entry.
    /// Combines link creation with G/L account synchronization for data consistency.
    /// </summary>
    /// <param name="GLEntryNo">General ledger entry number to link</param>
    /// <param name="VATEntryNo">VAT entry number to link and update</param>
    procedure InsertLinkWithGLAccountSelf(GLEntryNo: Integer; VATEntryNo: Integer)
    var
        IsHandled: Boolean;
    begin
        InsertLinkSelf(GLEntryNo, VATEntryNo);

        IsHandled := false;
        OnBeforeAdjustGLAccountNoOnVATEntryOnInsertLink(Rec, IsHandled);
        if IsHandled then
            exit;

        Rec.AdjustGLAccountNoOnVATEntry();
    end;

    /// <summary>
    /// Updates the G/L account number on the linked VAT entry to match the G/L entry's account.
    /// Ensures consistency between VAT entries and their corresponding G/L account assignments.
    /// </summary>
    procedure AdjustGLAccountNoOnVATEntry()
    var
        GLEntry: Record "G/L Entry";
        VATEntryEdit: Codeunit "VAT Entry - Edit";
    begin
        if Rec.IsTemporary() then
            exit;

        if Rec."G/L Entry No." = 0 then
            exit;

        GLEntry.SetLoadFields("G/L Account No.");
        GLEntry.Get(Rec."G/L Entry No.");
        VATEntryEdit.SetGLAccountNo(Rec."VAT Entry No.", GLEntry."G/L Account No.");
    end;

    /// <summary>
    /// Integration event raised after creating a link between G/L and VAT entries.
    /// Enables custom processing or validation after the link establishment.
    /// </summary>
    /// <param name="GLEntryVATEntryLink">Link record that was created</param>
    [IntegrationEvent(false, false)]
    local procedure OnInsertLink(var GLEntryVATEntryLink: Record "G/L Entry - VAT Entry Link")
    begin
    end;

    /// <summary>
    /// Integration event raised before adjusting G/L account number on VAT entry during link insertion.
    /// Allows custom logic to handle or skip the automatic G/L account adjustment process.
    /// </summary>
    /// <param name="GLEntryVATEntryLink">Link record being processed</param>
    /// <param name="IsHandled">Set to true to skip standard G/L account adjustment</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeAdjustGLAccountNoOnVATEntryOnInsertLink(var GLEntryVATEntryLink: Record "G/L Entry - VAT Entry Link"; var IsHandled: Boolean)
    begin
    end;
}

