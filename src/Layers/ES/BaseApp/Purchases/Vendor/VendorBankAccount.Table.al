// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

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
                TestField("CCC Bank Account No.", '');
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
                CompanyInfo: Record "Company Information";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateIBAN(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                CompanyInfo.CheckIBAN(IBAN);
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
        field(10700; "CCC Bank No."; Text[4])
        {
            Caption = 'CCC Bank No.';
            Numeric = true;

            trigger OnValidate()
            begin
                "CCC Bank No." := PrePadString("CCC Bank No.", MaxStrLen("CCC Bank No."));
                BuildCCC();
            end;
        }
        field(10701; "CCC Bank Branch No."; Text[4])
        {
            Caption = 'CCC Bank Branch No.';
            Numeric = true;

            trigger OnValidate()
            begin
                "CCC Bank Branch No." := PrePadString("CCC Bank Branch No.", MaxStrLen("CCC Bank Branch No."));
                BuildCCC();
            end;
        }
        field(10702; "CCC Control Digits"; Text[2])
        {
            Caption = 'CCC Control Digits';
            Numeric = true;

            trigger OnValidate()
            begin
                "CCC Control Digits" := PrePadString("CCC Control Digits", MaxStrLen("CCC Control Digits"));
                BuildCCC();
            end;
        }
        field(10703; "CCC Bank Account No."; Text[10])
        {
            Caption = 'CCC Bank Account No.';
            Numeric = true;

            trigger OnValidate()
            begin
                "CCC Bank Account No." := PrePadString("CCC Bank Account No.", MaxStrLen("CCC Bank Account No."));
                BuildCCC();
            end;
        }
        field(10704; "CCC No."; Text[20])
        {
            Caption = 'CCC No.';
            Numeric = true;

            trigger OnValidate()
            begin
                "CCC Bank No." := CopyStr("CCC No.", 1, 4);
                "CCC Bank Branch No." := CopyStr("CCC No.", 5, 4);
                "CCC Control Digits" := CopyStr("CCC No.", 9, 2);
                "CCC Bank Account No." := CopyStr("CCC No.", 11, 23);
            end;
        }
        field(10705; "Use For Electronic Payments"; Boolean)
        {
            Caption = 'Use For Electronic Payments';

            trigger OnValidate()
            var
                VendBankAcc: Record "Vendor Bank Account";
                Text1100000: Label 'Use for Electronic Payments can  be checked for only one of the Vendor''s Bank Accounts. ';
            begin
                VendBankAcc.SetRange(VendBankAcc."Vendor No.", "Vendor No.");
                VendBankAcc.SetRange(VendBankAcc."Use For Electronic Payments", true);
                if VendBankAcc.FindFirst() then
                    if (VendBankAcc.Count = 1) and "Use For Electronic Payments" then
                        if xRec."Use For Electronic Payments" <> "Use For Electronic Payments" then
                            Error(Text1100000);
            end;
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

    trigger OnRename()
    begin
        if Vendor.Get("Vendor No.") then begin
            Vendor."Preferred Bank Account Code" := Code;
            Vendor.Modify();
        end;
    end;

    var
        PostCode: Record "Post Code";
        Vendor: Record Vendor;
        BankAccIdentifierIsEmptyErr: Label 'You must specify either a Bank Account No. or an IBAN.';
        BankAccDeleteErr: Label 'You cannot delete this bank account because it is associated with one or more open ledger entries.';

    [Scope('OnPrem')]
    procedure BuildCCC()
    begin
        "CCC No." := "CCC Bank No." + "CCC Bank Branch No." + "CCC Control Digits" + "CCC Bank Account No.";
        if "CCC No." <> '' then
            TestField("Bank Account No.", '');
    end;

    [Scope('OnPrem')]
    procedure PrePadString(InString: Text[250]; MaxLen: Integer): Text[250]
    begin
        exit(PadStr('', MaxLen - StrLen(InString), '0') + InString);
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
}
