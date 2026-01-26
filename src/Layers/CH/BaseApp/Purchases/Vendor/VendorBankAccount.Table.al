// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

using Microsoft.Bank;
using Microsoft.Bank.Payment;
using Microsoft.Bank.Setup;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;
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
        field(11580; "Payment Fee Code"; Option)
        {
            Caption = 'Payment Fee Code';
            InitValue = " ";
            OptionCaption = ' ,Own,Beneficiary,Share';
            OptionMembers = " ",Own,Beneficiary,Share;
        }
        field(3010541; "Clearing No."; Code[5])
        {
            Caption = 'Clearing No.';
            TableRelation = "Bank Directory";

            trigger OnValidate()
            begin
                if "Clearing No." <> '' then begin
                    if "Payment Form" <> "Payment Form"::"Bank Payment Domestic" then
                        Error(Text000);
                    BankDirectory.Get("Clearing No.");
                    Name := BankDirectory.Name;
                    Address := BankDirectory.Address;
                    "Address 2" := BankDirectory."Address 2";
                    "Post Code" := BankDirectory."Post Code";
                    City := BankDirectory.City;
                end;
            end;
        }
        field(3010542; "Payment Form"; Option)
        {
            Caption = 'Payment Form';
            InitValue = ESR;
            OptionCaption = 'ESR,ESR+,Post Payment Domestic,Bank Payment Domestic,Cash Outpayment Order Domestic,Post Payment Abroad,Bank Payment Abroad,SWIFT Payment Abroad,Cash Outpayment Order Abroad';
            OptionMembers = ESR,"ESR+","Post Payment Domestic","Bank Payment Domestic","Cash Outpayment Order Domestic","Post Payment Abroad","Bank Payment Abroad","SWIFT Payment Abroad","Cash Outpayment Order Abroad";

            trigger OnValidate()
            begin
                if "Payment Form" <> xRec."Payment Form" then begin
                    xPmtType := "Payment Form";  // Store
                    Init();
                    "Payment Form" := xPmtType;  // Get
                end;
            end;
        }
        field(3010543; "ESR Type"; Option)
        {
            Caption = 'ESR Type';
            InitValue = " ";
            OptionCaption = ' ,5/15,9/27,9/16';
            OptionMembers = " ","5/15","9/27","9/16";

            trigger OnValidate()
            begin
                if "ESR Type" <> xRec."ESR Type" then begin
                    xPmtType := "Payment Form";  // Store
                    xEsrType := "ESR Type";
                    xBalAccount := "Balance Account No.";
                    xDebitBank := "Debit Bank";
                    Init();
                    "Payment Form" := xPmtType;  // Get
                    "ESR Type" := xEsrType;
                    "Balance Account No." := xBalAccount;
                    "Debit Bank" := xDebitBank;
                end;
            end;
        }
        field(3010544; "Giro Account No."; Code[11])
        {
            Caption = 'Giro Account No.';

            trigger OnValidate()
            begin
                if "Giro Account No." = '' then
                    exit;

                if "Payment Form" <> "Payment Form"::"Post Payment Domestic" then  // EZ Post
                    Error(Text002);

                // Check and expand
                "Giro Account No." := BankMgt.CheckPostAccountNo("Giro Account No.");
            end;
        }
        field(3010545; "ESR Account No."; Code[11])
        {
            Caption = 'ESR Account No.';

            trigger OnValidate()
            begin
                if "ESR Account No." = '' then
                    exit;

                if "Payment Form" > 1 then  // <> ESR, ESR+
                    Error(Text003);

                if "ESR Type" = 0 then
                    Error(Text004);

                // CHeck and expand
                if "ESR Type" in ["ESR Type"::"9/27", "ESR Type"::"9/16"] then
                    "ESR Account No." := BankMgt.CheckPostAccountNo("ESR Account No.");

                if "ESR Type" = "ESR Type"::"5/15" then begin
                    if StrLen("ESR Account No.") <> 5 then
                        Error(Text005);
                    if CopyStr("ESR Account No.", 5, 1) <> BankMgt.CalcCheckDigit(CopyStr("ESR Account No.", 1, 4)) then
                        Error(Text006);
                end;
            end;
        }
        field(3010546; "Bank Identifier Code"; Code[21])
        {
            Caption = 'Bank Identifier Code';
        }
        field(3010547; "Balance Account No."; Code[20])
        {
            Caption = 'Balance Account No.';
            TableRelation = "G/L Account";
        }
        field(3010548; "Invoice No. Startposition"; Integer)
        {
            BlankZero = true;
            Caption = 'Invoice No. Startposition';
            MaxValue = 26;
            MinValue = 0;

            trigger OnValidate()
            begin
                if ("Invoice No. Startposition" > 0) and ("Payment Form" > 1) then
                    Error(Text008);
            end;
        }
        field(3010549; "Invoice No. Length"; Integer)
        {
            BlankZero = true;
            Caption = 'Invoice No. Length';
            MaxValue = 26;
            MinValue = 0;

            trigger OnValidate()
            begin
                if ("Invoice No. Length" > 0) and ("Payment Form" > 1) then
                    Error(Text009);
            end;
        }
        field(3010550; "Debit Bank"; Code[20])
        {
            Caption = 'Debit Bank';
            TableRelation = "DTA Setup";
        }
    }

    keys
    {
        key(Key1; "Vendor No.", "Code")
        {
            Clustered = true;
        }
        key(Key2; "ESR Account No.")
        {
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

    trigger OnRename()
    begin
    end;

    var
        PostCode: Record "Post Code";
        Text000: Label 'The Clearing No is only used with Payment Type EZ Bank.';
        Text002: Label 'The Post Account is only used with domestic post remittance.';
        Text003: Label 'The ESR Account is only used with ESR and ESR+.';
        Text004: Label 'When using an ESR-Account, the ESR-Type must be defined previously.';
        Text005: Label 'The ESR Account for ESR 5/15 must have 5 digits.';
        Text006: Label 'The Checksum for this ESR Account is incorrect.';
        Text008: Label 'The Starting Position of the Invoice is only used for ESR and ESR+.';
        Text009: Label 'The Length of the Invoice is only used for ESR and ESR+.';
        BankDirectory: Record "Bank Directory";
        BankMgt: Codeunit BankMgt;
        xPmtType: Integer;
        xEsrType: Integer;
        xBalAccount: Code[20];
        xDebitBank: Code[20];
        BankAccIdentifierIsEmptyErr: Label 'You must specify either a Bank Account No. or an IBAN.';
        BankAccDeleteErr: Label 'You cannot delete this bank account because it is associated with one or more open ledger entries.';

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
        if ("ESR Account No." <> '') and ("Payment Form" in ["Payment Form"::ESR, "Payment Form"::"ESR+"]) then
            exit(DelChr("ESR Account No.", '=', '-'));

        if ("Giro Account No." <> '') and ("Payment Form" = "Payment Form"::"Post Payment Domestic") then
            exit(DelChr("Giro Account No.", '=', '-'));

        if ("Clearing No." <> '') and ("Payment Form" = "Payment Form"::"Bank Payment Domestic") then
            exit("Clearing No.");

        OnGetBankAccount(Handled, Rec, ResultBankAccountNo);

        if Handled then
            exit(ResultBankAccountNo);

        if IBAN <> '' then
            exit(DelChr(IBAN, '=<>'));

        if "Bank Account No." <> '' then
            exit("Bank Account No.");
    end;

    [Scope('OnPrem')]
    procedure GetPaymentType(var PaymentType: Option; CurrencyCode: Code[10]): Boolean
    var
        DummyPaymentExportData: Record "Payment Export Data";
        CHMgt: Codeunit CHMgt;
        DtaMgt: Codeunit DtaMgt;
        DomesticIBAN: Boolean;
        DomesticCurrency: Boolean;
    begin
        DomesticCurrency := CHMgt.IsDomesticCurrency(CurrencyCode);

        // Payment Type 1
        if ("Payment Form" in ["Payment Form"::ESR, "Payment Form"::"ESR+"]) and
           ("ESR Account No." <> '') and DomesticCurrency
        then begin
            PaymentType := DummyPaymentExportData."Swiss Payment Type"::"1";
            exit(true);
        end;

        // Payment Type 2.1
        if ("Payment Form" = "Payment Form"::"Post Payment Domestic") and ("Giro Account No." <> '') and DomesticCurrency then begin
            PaymentType := DummyPaymentExportData."Swiss Payment Type"::"2.1";
            exit(true);
        end;

        DomesticIBAN := CHMgt.IsDomesticIBAN(IBAN);

        // Payment Type 2.2
        if ("Payment Form" = "Payment Form"::"Bank Payment Domestic") and
           ("Clearing No." <> '') and DomesticCurrency and DomesticIBAN and
           (IBAN <> '')
        then begin
            PaymentType := DummyPaymentExportData."Swiss Payment Type"::"2.2";
            exit(true);
        end;

        // Payment Types 3,4
        if ("Payment Form" = "Payment Form"::"Bank Payment Domestic") and
           DomesticIBAN and ("SWIFT Code" <> '') and
           (IBAN <> '')
        then begin
            if DomesticCurrency then
                PaymentType := DummyPaymentExportData."Swiss Payment Type"::"3"
            else
                PaymentType := DummyPaymentExportData."Swiss Payment Type"::"4";
            exit(true);
        end;

        // Payment Type 5
        if not DomesticIBAN and
           ("Payment Form" = "Payment Form"::"Post Payment Abroad") and
           (DtaMgt.GetIsoCurrencyCode(CurrencyCode) = 'EUR') and
           CHMgt.IsSEPACountry("Country/Region Code") and
           (IBAN <> '')
        then begin
            PaymentType := DummyPaymentExportData."Swiss Payment Type"::"5";
            exit(true);
        end;

        // Payment Type 6
        if not DomesticIBAN and
           ("Payment Form" = "Payment Form"::"Bank Payment Abroad") and
           ((IBAN <> '') or
            ("Bank Account No." <> '')) and
           (("SWIFT Code" <> '') or
            (Name <> '') and (Address <> '') and ("Post Code" <> '') and ("Country/Region Code" <> ''))
        then begin
            PaymentType := DummyPaymentExportData."Swiss Payment Type"::"6";
            exit(true);
        end;

        // Unknown payment type
        exit(false);
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
