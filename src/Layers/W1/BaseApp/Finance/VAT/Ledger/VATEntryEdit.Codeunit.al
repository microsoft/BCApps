// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Ledger;

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

    procedure SetGLAccountNo(var VATEntryModify: Record "VAT Entry"; GLAccountNo: Code[20])
    begin
        VATEntryModify."G/L Acc. No." := GLAccountNo;
        VATEntryModify.Modify();
    end;

    procedure SetGLAccountNo(VATEntryNo: Integer; GLAccountNo: Code[20])
    begin
        VATEntry.SetRange("Entry No.", VATEntryNo);
        VATEntry.ModifyAll("G/L Acc. No.", GLAccountNo, false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVATEntryModify(var VATEntry: Record "VAT Entry"; FromVATEntry: Record "VAT Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterVATEntryModify(var VATEntry: Record "VAT Entry"; FromVATEntry: Record "VAT Entry")
    begin
    end;
}

