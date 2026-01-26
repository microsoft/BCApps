// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Setup;
using Microsoft.Finance.Currency;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Payables;
using System.Email;
using System.Globalization;

table 288 "Vendor Bank Account"
{
    Caption = 'Vendor Bank Account';
    DataCaptionFields = "Vendor No.", "Code", Name;
    DrillDownPageID = "Vendor Bank Account List";
    LookupPageID = "Vendor Bank Account List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            NotBlank = true;
            TableRelation = Vendor;
        }
        field(2; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(3; Name; Text[100])
        {
            Caption = 'Name';

            trigger OnLookup()
            begin
                OnBeforeLookupName(xRec);
            end;
        }
        field(5; "Name 2"; Text[50])
        {
            Caption = 'Name 2';
        }
        field(6; Address; Text[100])
        {
            Caption = 'Address';
        }
        field(7; "Address 2"; Text[50])
        {
            Caption = 'Address 2';
        }
        field(8; City; Text[30])
        {
            Caption = 'City';
            TableRelation = if ("Country/Region Code" = const('')) "Post Code".City
            else
            if ("Country/Region Code" = filter(<> '')) "Post Code".City where("Country/Region Code" = field("Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode(City, "Post Code", County, "Country/Region Code");
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateCity(Rec, PostCode, CurrFieldNo, IsHandled);
                if not IsHandled then
                    PostCode.ValidateCity(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(9; "Post Code"; Code[20])
        {
            Caption = 'Post Code';
            TableRelation = if ("Country/Region Code" = const('')) "Post Code"
            else
            if ("Country/Region Code" = filter(<> '')) "Post Code" where("Country/Region Code" = field("Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode(City, "Post Code", County, "Country/Region Code");
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidatePostCode(Rec, PostCode, CurrFieldNo, IsHandled);
                if not IsHandled then
                    PostCode.ValidatePostCode(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(10; Contact; Text[100])
        {
            Caption = 'Contact';
        }
        field(11; "Phone No."; Text[30])
        {
            Caption = 'Phone No.';
            ExtendedDatatype = PhoneNo;
        }
        field(12; "Telex No."; Text[20])
        {
            Caption = 'Telex No.';
        }
        field(13; "Bank Branch No."; Text[20])
        {
            Caption = 'Bank Branch No.';

            trigger OnValidate()
            begin
                OnValidateBankAccount(Rec, 'Bank Branch No.');
            end;
        }
        field(14; "Bank Account No."; Text[30])
        {
            Caption = 'Bank Account No.';

            trigger OnValidate()
            begin
                ConvertBankAccNo();
                GetBBAN();
                OnValidateBankAccount(Rec, 'Bank Account No.');
            end;
        }
        field(15; "Transit No."; Text[20])
        {
            Caption = 'Transit No.';
        }
        field(16; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(17; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";

            trigger OnValidate()
            begin
                PostCode.CheckClearPostCodeCityCounty(City, "Post Code", County, "Country/Region Code", xRec."Country/Region Code");
            end;
        }
        field(18; County; Text[30])
        {
            CaptionClass = '5,1,' + "Country/Region Code";
            Caption = 'County';
        }
        field(19; "Fax No."; Text[30])
        {
            Caption = 'Fax No.';
        }
        field(20; "Telex Answer Back"; Text[20])
        {
            Caption = 'Telex Answer Back';
        }
        field(21; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
        }
        field(22; "E-Mail"; Text[80])
        {
            Caption = 'Email';
            ExtendedDatatype = EMail;

            trigger OnValidate()
            var
                MailManagement: Codeunit "Mail Management";
            begin
                MailManagement.ValidateEmailAddressField("E-Mail");
            end;
        }
#if not CLEAN27
#pragma warning disable AS0086
#endif
        field(23; "Home Page"; Text[255])
#if not CLEAN27
#pragma warning restore AS0086
#endif
        {
            Caption = 'Home Page';
            ExtendedDatatype = URL;
        }
        field(24; IBAN; Code[50])
        {
            Caption = 'IBAN';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateIBAN(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                CheckIBAN();
            end;
        }
        field(25; "SWIFT Code"; Code[20])
        {
            Caption = 'SWIFT Code';
            TableRelation = "SWIFT Code";
            ValidateTableRelation = false;
        }
        field(1211; "Bank Clearing Code"; Text[50])
        {
            Caption = 'Bank Clearing Code';
        }
        field(1212; "Bank Clearing Standard"; Text[50])
        {
            Caption = 'Bank Clearing Standard';
            TableRelation = "Bank Clearing Standard";
        }
        field(12170; ABI; Code[5])
        {
            Caption = 'ABI';
            TableRelation = "ABI/CAB Codes".ABI;

            trigger OnLookup()
            begin
                if PAGE.RunModal(12179, AbiCabCodes) = ACTION::LookupOK then begin
                    ABI := AbiCabCodes.ABI;
                    CAB := AbiCabCodes.CAB;
                    Name := AbiCabCodes."Bank Description";
                    "Name 2" := AbiCabCodes."Agency Description";
                    Address := AbiCabCodes.Address;
                    City := AbiCabCodes.City;
                    "Post Code" := AbiCabCodes."Post Code";
                    County := AbiCabCodes.County;
                    ConvertBankAccNo();
                    GetBBAN();
                end;
            end;

            trigger OnValidate()
            begin
                AbiCabCodes.CheckABICAB(ABI, CAB);
                ConvertBankAccNo();
                GetBBAN();
            end;
        }
        field(12171; CAB; Code[5])
        {
            Caption = 'CAB';
            TableRelation = "ABI/CAB Codes".CAB where(ABI = field(ABI));

            trigger OnLookup()
            begin
                AbiCabCodes.SetRange(ABI, ABI);
                if PAGE.RunModal(0, AbiCabCodes) = ACTION::LookupOK then begin
                    CAB := AbiCabCodes.CAB;
                    Name := AbiCabCodes."Bank Description";
                    "Name 2" := AbiCabCodes."Agency Description";
                    Address := AbiCabCodes.Address;
                    City := AbiCabCodes.City;
                    "Post Code" := AbiCabCodes."Post Code";
                    County := AbiCabCodes.County;
                    ConvertBankAccNo();
                    GetBBAN();
                end;
                AbiCabCodes.Reset();
            end;

            trigger OnValidate()
            begin
                AbiCabCodes.CheckABICAB(ABI, CAB);
                ConvertBankAccNo();
                GetBBAN();
            end;
        }
        field(12174; BBAN; Code[30])
        {
            Caption = 'BBAN';
        }
    }

    keys
    {
        key(Key1; "Vendor No.", "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", Name)
        {
        }
        fieldgroup(Brick; "Code", Name, "Phone No.", Contact)
        {
        }
    }

    trigger OnDelete()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Vendor: Record Vendor;
    begin
        VendorLedgerEntry.SetRange("Vendor No.", "Vendor No.");
        VendorLedgerEntry.SetRange("Recipient Bank Account", Code);
        VendorLedgerEntry.SetRange(Open, true);
        OnDeleteOnAfterSetFilters(Rec, VendorLedgerEntry);
        if not VendorLedgerEntry.IsEmpty() then
            Error(BankAccDeleteErr);
        if Vendor.Get("Vendor No.") and (Vendor."Preferred Bank Account Code" = Code) then begin
            Vendor."Preferred Bank Account Code" := '';
            Vendor.Modify();
        end;
    end;

    trigger OnModify()
    var
        Confirmed: Boolean;
        SkipConfirm: Boolean;
    begin
        if IBAN = '' then begin
            SkipConfirm := false;
            OnModifyOnIBANIsEmpty(Rec, SkipConfirm);
            if not GuiAllowed or SkipConfirm then
                Confirmed := true
            else
                Confirmed := Confirm(StrSubstNo('%1%2', Text12100, Text12101), false);
            if not Confirmed then begin
                IBAN := xRec.IBAN;
                Modify();
                Commit();
                Error(Text12102);
            end;
        end;
    end;

    var
        PostCode: Record "Post Code";
        AbiCabCodes: Record "ABI/CAB Codes";
        Text12100: Label 'The field IBAN is mandatory. You will not be able to use the account in a payment file until the IBAN is correctly filled in.';
        Text12101: Label '\\Are you sure you want to continue?';
        Text12102: Label 'The action was cancelled by the user.';
        BankAccIdentifierIsEmptyErr: Label 'You must specify either a Bank Account No. or an IBAN.';
        BankAccDeleteErr: Label 'You cannot delete this bank account because it is associated with one or more open ledger entries.';

    [Scope('OnPrem')]
    procedure GetBBAN()
    begin
        if (ABI <> '') and (CAB <> '') and ("Bank Account No." <> '') then
            BBAN := AbiCabCodes.CalcBBAN(ABI, CAB, "Bank Account No.")
        else
            BBAN := '';
        IBAN := '';
        OnAfterGetBBAN(IBAN, Rec);
    end;

    [Scope('OnPrem')]
    procedure ConvertBankAccNo()
    begin
        if (ABI <> '') and (CAB <> '') then
            "Bank Account No." := CopyStr('000000000000' + "Bank Account No.", StrLen('000000000000' + "Bank Account No.") - 11, 12);
    end;

    [Scope('OnPrem')]
    procedure CheckIBAN()
    var
        CompanyInfo: Record "Company Information";
        IBAN2: Code[50];
    begin
        CompanyInfo.CheckIBAN(IBAN);
        if CopyStr(DelChr(IBAN), 1, 2) in ['IT', 'SM'] then begin
            ABI := CopyStr(DelChr(IBAN), 6, 5);
            CAB := CopyStr(DelChr(IBAN), 11, 5);
            "Bank Account No." := CopyStr(DelChr(IBAN), 16, 12);
            AbiCabCodes.CheckABICAB(ABI, CAB);
            ConvertBankAccNo();
            IBAN2 := IBAN;
            GetBBAN();
            IBAN := IBAN2;
        end;
    end;

    procedure GetBankAccountNoWithCheck() AccountNo: Text
    begin
        AccountNo := GetBankAccountNo();
        if AccountNo = '' then
            Error(BankAccIdentifierIsEmptyErr);
    end;

    procedure GetBankAccountNo(): Text
    var
        Handled: Boolean;
        ResultBankAccountNo: Text;
    begin
        OnGetBankAccount(Handled, Rec, ResultBankAccountNo);

        if Handled then exit(ResultBankAccountNo);

        if IBAN <> '' then
            exit(DelChr(IBAN, '=<>'));

        if "Bank Account No." <> '' then
            exit("Bank Account No.");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetBBan(var IBAN: Code[50]; var VendorBankAccount: Record "Vendor Bank Account")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeLookupName(xVendorBankAccount: Record "Vendor Bank Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateBankAccount(var VendorBankAccount: Record "Vendor Bank Account"; FieldToValidate: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateIBAN(var VendorBankAccount: Record "Vendor Bank Account"; var xVendorBankAccount: Record "Vendor Bank Account"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetBankAccount(var Handled: Boolean; VendorBankAccount: Record "Vendor Bank Account"; var ResultBankAccountNo: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateCity(var VendorBankAccount: Record "Vendor Bank Account"; var PostCodeRec: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePostCode(var VendorBankAccount: Record "Vendor Bank Account"; var PostCodeRec: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteOnAfterSetFilters(var VendorBankAccount: Record "Vendor Bank Account"; var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnModifyOnIBANIsEmpty(var VendorBankAccount: Record "Vendor Bank Account"; var SkipConfirm: Boolean)
    begin
    end;
}
