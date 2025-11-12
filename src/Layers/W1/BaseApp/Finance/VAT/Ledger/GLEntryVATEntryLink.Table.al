// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Ledger;

using Microsoft.Finance.GeneralLedger.Ledger;

table 253 "G/L Entry - VAT Entry Link"
{
    Caption = 'G/L Entry - VAT Entry Link';
    Permissions = TableData "G/L Entry - VAT Entry Link" = rimd;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "G/L Entry No."; Integer)
        {
            Caption = 'G/L Entry No.';
            TableRelation = "G/L Entry"."Entry No.";
        }
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
    }

    fieldgroups
    {
    }

    procedure InsertLink(GLEntryNo: Integer; VATEntryNo: Integer)
    var
        GLEntryVatEntryLink: Record "G/L Entry - VAT Entry Link";
    begin
        GLEntryVatEntryLink.InsertLinkSelf(GLEntryNo, VATEntryNo);
    end;

    procedure InsertLinkSelf(GLEntryNo: Integer; VATEntryNo: Integer)
    begin
        Init();
        "G/L Entry No." := GLEntryNo;
        "VAT Entry No." := VATEntryNo;
        Insert();

        OnInsertLink(Rec);
    end;

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

    [IntegrationEvent(false, false)]
    local procedure OnInsertLink(var GLEntryVATEntryLink: Record "G/L Entry - VAT Entry Link")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAdjustGLAccountNoOnVATEntryOnInsertLink(var GLEntryVATEntryLink: Record "G/L Entry - VAT Entry Link"; var IsHandled: Boolean)
    begin
    end;
}

