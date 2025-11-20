// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Setup;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Inventory.Item;

table 1877 "VAT Setup Posting Groups"
{
    Caption = 'VAT Setup Posting Groups';
    DataClassification = CustomerContent;

    fields
    {
        field(2; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            NotBlank = true;
        }
        field(4; "VAT %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'VAT %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(7; "Sales VAT Account"; Code[20])
        {
            Caption = 'Sales VAT Account';
            TableRelation = "G/L Account";
        }
        field(9; "Purchase VAT Account"; Code[20])
        {
            Caption = 'Purchase VAT Account';
            TableRelation = "G/L Account";
        }
        field(11; "Reverse Chrg. VAT Acc."; Code[20])
        {
            Caption = 'Reverse Chrg. VAT Acc.';
            TableRelation = "G/L Account";
        }
        field(18; "VAT Prod. Posting Grp Desc."; Text[100])
        {
            Caption = 'VAT Prod. Posting Grp Desc.';
        }
        field(19; "VAT Clause Desc"; Text[250])
        {
            Caption = 'VAT Clause Desc';
        }
        field(22; Selected; Boolean)
        {
            Caption = 'Selected';
            FieldClass = Normal;
        }
        field(23; "Application Type"; Option)
        {
            Caption = 'Application Type';
            OptionCaption = ',Items,Services';
            OptionMembers = ,Items,Services;
        }
        field(24; Default; Boolean)
        {
            Caption = 'Default';
        }
    }

    keys
    {
        key(Key1; "VAT Prod. Posting Group", Default)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        FULLNORMTok: Label 'FULL NORM', Comment = 'the same as values in Product posting group';
        FULLREDTok: Label 'FULL RED', Comment = 'the same as values in Product posting group';
        REDUCEDTok: Label 'REDUCED', Comment = 'the same as values in Product posting group';
        SERVNORMTok: Label 'SERV NORM', Comment = 'the same as values in Product posting group';
        SERVREDTok: Label 'SERV RED', Comment = 'the same as values in Product posting group';
        STANDARDTok: Label 'STANDARD', Comment = 'the same as values in Product posting group';
        ZEROTok: Label 'ZERO', Comment = 'the same as values in Product posting group';
        FULLNORMTxt: Label 'VAT Only Invoices 25%';
        FULLREDTxt: Label 'VAT Only Invoices 10%';
        REDUCEDTxt: Label 'Reduced VAT (10%)';
        SERVNORMTxt: Label 'Miscellaneous 25 VAT';
        SERVREDTxt: Label 'Miscellaneous 10 VAT';
        STANDARDTxt: Label 'Standard VAT (25%)';
        ZEROTxt: Label 'No VAT';
        InvalidGLAccountsTxt: Label '%1 is not valid G/L Account.', Comment = '%1 is placeholder for the invalid gl account code';
        VATAssistedAccountsMsg: Label 'You have not assigned general ledger accounts for sales and purchases for all VAT amounts. You won''t be able to calculate and post VAT for the missing accounts. If you''re skipping this step on purpose, you can manually assign accounts later in the VAT Posting Setup page.';

    procedure ValidateVATRates(): Boolean
    var
        VATSetupPostingGroups: Record "VAT Setup Posting Groups";
    begin
        VATSetupPostingGroups.Reset();
        VATSetupPostingGroups.SetRange(Selected, true);
        VATSetupPostingGroups.SetRange(Default, false);
        exit(not VATSetupPostingGroups.IsEmpty);
    end;

    procedure PopulateVATProdGroups()
    var
        VATSetupPostingGroups: Record "VAT Setup Posting Groups";
        Handled: Boolean;
    begin
        SetRange(Default, false);
        DeleteAll();

        SetRange(Default, true);
        if not FindSet() then begin
            OnInitWithStandardValues(Handled, Rec);

            if not Handled then
                InitWithStandardValues();

            FindSet();
        end;

        repeat
            VATSetupPostingGroups.TransferFields(Rec);
            VATSetupPostingGroups.Default := false;
            VATSetupPostingGroups.Insert();
        until Next() = 0;
    end;

    procedure AddOrUpdateProdPostingGrp(ProdGrpCode: Code[20]; GrpDesc: Text[100]; VatRate: Decimal; SalesAccount: Code[20]; PurchAccount: Code[20]; IsService: Boolean; IsDefault: Boolean): Boolean
    var
        GLAccount: Record "G/L Account";
    begin
        if not Get(ProdGrpCode, IsDefault) then begin
            Init();
            "VAT Prod. Posting Group" := ProdGrpCode;
            Default := IsDefault;
            Insert();
        end;

        "VAT Prod. Posting Grp Desc." := GrpDesc;
        if VatRate <> 0 then
            "VAT %" := VatRate;
        if GLAccount.Get(SalesAccount) then
            "Sales VAT Account" := SalesAccount;
        if GLAccount.Get(PurchAccount) then
            "Purchase VAT Account" := PurchAccount;
        "Application Type" := "Application Type"::Items;
        if IsService then
            "Application Type" := "Application Type"::Services;
        Selected := true;
        exit(Modify());
    end;

    procedure CheckExistingItemAndServiceWithVAT(VATProdPostingGroupCode: Code[20]; IsService: Boolean): Boolean
    var
        Item: Record Item;
        Result: Boolean;
    begin
        if IsService then begin
            OnBeforeCheckExistingItemAndServiceWithVAT(VATProdPostingGroupCode, Result);
            exit(Result);
        end;
        Item.SetRange("VAT Prod. Posting Group", VATProdPostingGroupCode);
        exit(not Item.IsEmpty);
    end;

    procedure ValidateGLAccountsExist(var ErrorMessage: Text): Boolean
    var
        VATSetupPostingGroups: Record "VAT Setup Posting Groups";
        GLAccount: Record "G/L Account";
    begin
        if ValidateVATRates() = false then
            exit(false);
        VATSetupPostingGroups.SetRange(Selected, true);
        if not VATSetupPostingGroups.FindSet() then
            exit;

        repeat
            if
               (DelChr(VATSetupPostingGroups."Sales VAT Account", '<>') = '') or
               (DelChr(VATSetupPostingGroups."Purchase VAT Account", '<>') = '')
            then begin
                ErrorMessage := VATAssistedAccountsMsg;
                exit(false);
            end;

            if not GLAccount.Get(VATSetupPostingGroups."Sales VAT Account") then begin
                ErrorMessage := StrSubstNo(InvalidGLAccountsTxt, VATSetupPostingGroups."Sales VAT Account");
                exit(false);
            end;
            if not GLAccount.Get(VATSetupPostingGroups."Purchase VAT Account") then begin
                ErrorMessage := StrSubstNo(InvalidGLAccountsTxt, VATSetupPostingGroups."Purchase VAT Account");
                exit(false);
            end;
        until VATSetupPostingGroups.Next() = 0;
        ErrorMessage := '';
        exit(true);
    end;

    procedure GetLabelTok(LabelName: Text): Code[20]
    begin
        case LabelName of
            'FULLNORMTok':
                exit(FULLNORMTok);
            'FULLREDTok':
                exit(FULLREDTok);
            'SERVNORMTok':
                exit(SERVNORMTok);
            'STANDARDTok':
                exit(STANDARDTok);
            'ZEROTok':
                exit(ZEROTok);
            else
                Error('Labels not found in VATSetupPostingGroups');
        end
    end;

    procedure GetLabelTxt(LabelName: Text): Text[100]
    begin
        case LabelName of
            'FULLNORMTxt':
                exit(FULLNORMTxt);
            'FULLREDTxt':
                exit(FULLREDTxt);
            'SERVNORMTxt':
                exit(SERVNORMTxt);
            'STANDARDTxt':
                exit(STANDARDTxt);
            'ZEROTxt':
                exit(ZEROTxt);
            else
                Error('Labels not found in VATSetupPostingGroups');
        end
    end;

    local procedure InitWithStandardValues()
    begin
        AddOrUpdateProdPostingGrp(FULLNORMTok, FULLNORMTxt, 100, '', '', false, true);
        AddOrUpdateProdPostingGrp(FULLREDTok, FULLREDTxt, 100, '', '', false, true);
        AddOrUpdateProdPostingGrp(REDUCEDTok, REDUCEDTxt, 10, '5611', '5631', false, true);
        AddOrUpdateProdPostingGrp(SERVNORMTok, SERVNORMTxt, 25, '5611', '5631', true, true);
        AddOrUpdateProdPostingGrp(SERVREDTok, SERVREDTxt, 10, '5611', '5631', true, true);
        AddOrUpdateProdPostingGrp(STANDARDTok, STANDARDTxt, 25, '5610', '5630', false, true);
        AddOrUpdateProdPostingGrp(ZEROTok, ZEROTxt, 0, '5610', '5630', false, true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitWithStandardValues(var Handled: Boolean; VATSetupPostingGroups: Record "VAT Setup Posting Groups")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckExistingItemAndServiceWithVAT(VATProdPostingGroupCode: Code[20]; var Result: Boolean)
    begin
    end;
}
