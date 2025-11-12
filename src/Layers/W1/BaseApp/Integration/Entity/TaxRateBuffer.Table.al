// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Entity;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Setup;

table 5502 "Tax Rate Buffer"
{
    Caption = 'Tax Rate Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Tax Area ID"; Guid)
        {
            Caption = 'Tax Area ID';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(2; "Tax Group ID"; Guid)
        {
            Caption = 'Tax Group ID';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(3; "Tax Rate"; Decimal)
        {
            Caption = 'Tax Rate';
            DataClassification = SystemMetadata;
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Tax Area ID", "Tax Group ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        RecordMustBeTemporaryErr: Label 'Tax Rate Buffer Entity must be used as a temporary record.';

    procedure LoadRecords()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if not IsTemporary then
            Error(RecordMustBeTemporaryErr);

        if GeneralLedgerSetup.UseVat() then
            LoadVATRates()
        else
            LoadSalesTaxRates();
    end;

    local procedure LoadVATRates()
    var
        TempTaxAreaBuffer: Record "Tax Area Buffer" temporary;
        TempTaxGroupBuffer: Record "Tax Group Buffer" temporary;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        if not VATPostingSetup.FindSet() then
            exit;

        TempTaxGroupBuffer.LoadRecords();
        TempTaxAreaBuffer.LoadRecords();

        repeat
            InsertTaxRate(
              VATPostingSetup."VAT Prod. Posting Group", VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT %",
              TempTaxAreaBuffer, TempTaxGroupBuffer);
        until VATPostingSetup.Next() = 0;
    end;

    local procedure LoadSalesTaxRates()
    var
        TempTaxAreaBuffer: Record "Tax Area Buffer" temporary;
        TempSearchTaxAreaBuffer: Record "Tax Area Buffer" temporary;
        TempTaxGroupBuffer: Record "Tax Group Buffer" temporary;
        DummyTaxDetail: Record "Tax Detail";
        TaxGroupsForTaxAreas: Query "Tax Groups For Tax Areas";
        TaxRate: Decimal;
    begin
        TempTaxAreaBuffer.LoadRecords();
        if not TempTaxAreaBuffer.Find('-') then
            exit;

        TempSearchTaxAreaBuffer.Copy(TempTaxAreaBuffer, true);
        TempTaxGroupBuffer.LoadRecords();

        repeat
            TaxGroupsForTaxAreas.SetRange(Tax_Area_Code, TempTaxAreaBuffer.Code);
            if not TaxGroupsForTaxAreas.Open() then
                exit;

            if not TaxGroupsForTaxAreas.Read() then
                exit;

            repeat
                TaxRate := DummyTaxDetail.GetSalesTaxRate(TempTaxAreaBuffer.Code, TaxGroupsForTaxAreas.Tax_Group_Code, WorkDate(), true);
                InsertTaxRate(
                  TaxGroupsForTaxAreas.Tax_Group_Code, TempTaxAreaBuffer.Code, TaxRate, TempSearchTaxAreaBuffer, TempTaxGroupBuffer);
            until not TaxGroupsForTaxAreas.Read();
        until TempTaxAreaBuffer.Next() = 0;
    end;

    local procedure FindTaxGroupByCode(TaxGroupCode: Code[20]; var TempTaxGroupBuffer: Record "Tax Group Buffer" temporary): Boolean
    begin
        TempTaxGroupBuffer.SetRange(Code, TaxGroupCode);
        exit(TempTaxGroupBuffer.FindFirst());
    end;

    local procedure FindTaxAreaByCode(TaxAreaCode: Code[20]; var TempTaxAreaBuffer: Record "Tax Area Buffer" temporary): Boolean
    begin
        TempTaxAreaBuffer.SetRange(Code, TaxAreaCode);
        exit(TempTaxAreaBuffer.FindFirst());
    end;

    local procedure InsertTaxRate(TaxGroupCode: Code[20]; TaxAreaCode: Code[20]; TaxRate: Decimal; var TempTaxAreaBuffer: Record "Tax Area Buffer" temporary; var TempTaxGroupBuffer: Record "Tax Group Buffer" temporary)
    begin
        Clear(Rec);
        if TaxGroupCode <> '' then
            if FindTaxGroupByCode(TaxGroupCode, TempTaxGroupBuffer) then
                Validate("Tax Group ID", TempTaxGroupBuffer.Id)
            else
                exit;

        if TaxAreaCode <> '' then
            if FindTaxAreaByCode(TaxAreaCode, TempTaxAreaBuffer) then
                Validate("Tax Area ID", TempTaxAreaBuffer.Id)
            else
                exit;

        Validate("Tax Rate", TaxRate);
        if not Insert(true) then
            Modify(true);
    end;
}

