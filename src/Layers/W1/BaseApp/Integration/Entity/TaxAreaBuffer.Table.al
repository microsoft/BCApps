// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Entity;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Setup;

table 5504 "Tax Area Buffer"
{
    Caption = 'Tax Area Buffer';
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
        field(10; "Last Modified Date Time"; DateTime)
        {
            Caption = 'Last Modified Date Time';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(8000; Id; Guid)
        {
            Caption = 'Id';
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
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        TaxArea: Record "Tax Area";
    begin
        if not IsTemporary then
            Error(RecordMustBeTemporaryErr);

        if GeneralLedgerSetup.UseVat() then begin
            if InsertRec then begin
                VATBusinessPostingGroup.TransferFields(Rec, true);
                VATBusinessPostingGroup.Insert(true)
            end else begin
                if xRec.Code <> Code then begin
                    VATBusinessPostingGroup.Get(xRec.Code);
                    VATBusinessPostingGroup.Rename(Code)
                end;

                VATBusinessPostingGroup.TransferFields(Rec, true);
                VATBusinessPostingGroup.Modify(true);
            end;

            UpdateFromVATBusinessPostingGroup(VATBusinessPostingGroup);
        end else begin
            if InsertRec then begin
                TaxArea.TransferFields(Rec, true);
                TaxArea.Insert(true)
            end else begin
                if xRec.Code <> Code then begin
                    TaxArea.Get(xRec.Code);
                    TaxArea.Rename(Code);
                end;

                TaxArea.TransferFields(Rec, true);
                TaxArea.Modify(true);
            end;

            UpdateFromTaxArea(TaxArea);
        end;
    end;

    procedure PropagateDelete()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        TaxArea: Record "Tax Area";
    begin
        if GeneralLedgerSetup.UseVat() then begin
            VATBusinessPostingGroup.Get(Code);
            VATBusinessPostingGroup.Delete(true);
        end else begin
            TaxArea.Get(Code);
            TaxArea.Delete(true);
        end;
    end;

    procedure LoadRecords(): Boolean
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if not IsTemporary then
            Error(RecordMustBeTemporaryErr);

        if GeneralLedgerSetup.UseVat() then
            LoadFromVATBusinessPostingGroup()
        else
            LoadFromTaxArea();

        exit(FindFirst());
    end;

    local procedure LoadFromTaxArea()
    var
        TaxArea: Record "Tax Area";
    begin
        if not TaxArea.FindSet() then
            exit;

        repeat
            UpdateFromTaxArea(TaxArea);
            Insert();
        until TaxArea.Next() = 0;
    end;

    local procedure LoadFromVATBusinessPostingGroup()
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
    begin
        if not VATBusinessPostingGroup.FindSet() then
            exit;

        repeat
            UpdateFromVATBusinessPostingGroup(VATBusinessPostingGroup);
            Insert();
        until VATBusinessPostingGroup.Next() = 0;
    end;

    local procedure UpdateFromVATBusinessPostingGroup(var VATBusinessPostingGroup: Record "VAT Business Posting Group")
    begin
        TransferFields(VATBusinessPostingGroup, true);
        Type := Type::VAT;
        Id := VATBusinessPostingGroup.SystemId;
    end;

    local procedure UpdateFromTaxArea(var TaxArea: Record "Tax Area")
    begin
        TransferFields(TaxArea, true);
        Type := Type::"Sales Tax";
        Id := TaxArea.SystemId;
        Description := TaxArea.GetDescriptionInCurrentLanguageFullLength();
    end;

    procedure GetTaxAreaDisplayName(TaxAreaId: Guid): Text
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        TaxArea: Record "Tax Area";
    begin
        if IsNullGuid(TaxAreaId) then
            exit('');

        if GeneralLedgerSetup.UseVat() then begin
            if VATBusinessPostingGroup.GetBySystemId(TaxAreaId) then
                exit(VATBusinessPostingGroup.Description);
        end else
            if TaxArea.GetBySystemId(TaxAreaId) then
                exit(TaxArea.GetDescriptionInCurrentLanguageFullLength());

        exit('');
    end;
}

