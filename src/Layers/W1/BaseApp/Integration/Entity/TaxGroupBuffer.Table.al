// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Entity;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Setup;

table 5480 "Tax Group Buffer"
{
    Caption = 'Tax Group Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            DataClassification = SystemMetadata;
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = SystemMetadata;
        }
        field(8000; Id; Guid)
        {
            Caption = 'Id';
            DataClassification = SystemMetadata;
        }
        field(8005; "Last Modified DateTime"; DateTime)
        {
            Caption = 'Last Modified DateTime';
            DataClassification = SystemMetadata;
        }
        field(9600; Type; Enum "Tax Buffer Type")
        {
            Caption = 'Type';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; Id)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnRename()
    begin
        Error(CannotChangeIDErr);
    end;

    var
        CannotChangeIDErr: Label 'The id cannot be changed.', Locked = true;
        RecordMustBeTemporaryErr: Label 'Tax Group Entity must be used as a temporary record.';

    procedure PropagateInsert()
    begin
        PropagateUpdate(true);
    end;

    procedure PropagateModify()
    begin
        PropagateUpdate(false);
    end;

    local procedure PropagateUpdate(InsertRec: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        TaxGroup: Record "Tax Group";
    begin
        if not IsTemporary then
            Error(RecordMustBeTemporaryErr);

        if GeneralLedgerSetup.UseVat() then begin
            if InsertRec then begin
                VATProductPostingGroup.TransferFields(Rec, true);
                VATProductPostingGroup.Insert(true)
            end else begin
                if xRec.Code <> Code then begin
                    VATProductPostingGroup.Get(xRec.Code);
                    VATProductPostingGroup.Rename(Code);
                end;

                VATProductPostingGroup.TransferFields(Rec, true);
                VATProductPostingGroup.Modify(true);
            end;

            UpdateFromVATProductPostingGroup(VATProductPostingGroup);
        end else begin
            if InsertRec then begin
                TaxGroup.TransferFields(Rec, true);
                TaxGroup.Insert(true)
            end else begin
                if xRec.Code <> Code then begin
                    TaxGroup.Get(xRec.Code);
                    TaxGroup.Rename(true)
                end;

                TaxGroup.TransferFields(Rec, true);
                TaxGroup.Modify(true);
            end;

            UpdateFromTaxGroup(TaxGroup);
        end;
    end;

    procedure PropagateDelete()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        TaxGroup: Record "Tax Group";
    begin
        if GeneralLedgerSetup.UseVat() then begin
            VATProductPostingGroup.Get(Code);
            VATProductPostingGroup.Delete(true);
        end else begin
            TaxGroup.Get(Code);
            TaxGroup.Delete(true);
        end;
    end;

    procedure LoadRecords(): Boolean
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if not IsTemporary then
            Error(RecordMustBeTemporaryErr);

        if GeneralLedgerSetup.UseVat() then
            LoadFromVATProductPostingGroup()
        else
            LoadFromTaxGroup();

        exit(FindFirst());
    end;

    local procedure LoadFromTaxGroup()
    var
        TaxGroup: Record "Tax Group";
    begin
        if not TaxGroup.FindSet() then
            exit;

        repeat
            UpdateFromTaxGroup(TaxGroup);
            Insert();
        until TaxGroup.Next() = 0;
    end;

    local procedure LoadFromVATProductPostingGroup()
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        if not VATProductPostingGroup.FindSet() then
            exit;

        repeat
            UpdateFromVATProductPostingGroup(VATProductPostingGroup);
            Insert();
        until VATProductPostingGroup.Next() = 0;
    end;

    procedure GetCodesFromTaxGroupId(TaxGroupID: Guid; var SalesTaxGroupCode: Code[20]; var VATProductPostingGroupCode: Code[20])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        TaxGroup: Record "Tax Group";
    begin
        Clear(SalesTaxGroupCode);
        Clear(VATProductPostingGroupCode);

        if IsNullGuid(TaxGroupID) then
            exit;

        if GeneralLedgerSetup.UseVat() then begin
            if VATProductPostingGroup.GetBySystemId(TaxGroupID) then
                VATProductPostingGroupCode := VATProductPostingGroup.Code;

            exit;
        end;

        if TaxGroup.GetBySystemId(TaxGroupID) then
            SalesTaxGroupCode := TaxGroup.Code;
    end;

    local procedure UpdateFromVATProductPostingGroup(var VATProductPostingGroup: Record "VAT Product Posting Group")
    begin
        TransferFields(VATProductPostingGroup, true);
        Id := VATProductPostingGroup.SystemId;
        Type := Type::VAT;
    end;

    local procedure UpdateFromTaxGroup(var TaxGroup: Record "Tax Group")
    begin
        TransferFields(TaxGroup, true);
        Id := TaxGroup.SystemId;
        Type := Type::"Sales Tax";
    end;
}

