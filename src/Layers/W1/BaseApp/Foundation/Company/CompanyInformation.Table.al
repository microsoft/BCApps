// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Company;

using Microsoft.Bank.Setup;
using Microsoft.EServices.OnlineMap;
using Microsoft.Finance.VAT.Registration;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Calendar;
using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Pricing.Calculation;
using Microsoft.Utilities;
using System.Email;
using System.Globalization;
using System.Utilities;

table 79 "Company Information"
{
    Caption = 'Company Information';
    InherentEntitlements = X;
    InherentPermissions = X;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
        }
        field(2; Name; Text[100])
        {
            Caption = 'Name';
        }
        field(3; "Name 2"; Text[50])
        {
            Caption = 'Name 2';
        }
        field(4; Address; Text[100])
        {
            Caption = 'Address';
        }
        field(5; "Address 2"; Text[50])
        {
            Caption = 'Address 2';
        }
        field(6; City; Text[30])
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
                OnBeforeValidateCity(Rec, IsHandled);
                if not IsHandled then
                    PostCode.ValidateCity(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(7; "Phone No."; Text[30])
        {
            Caption = 'Phone No.';
            ExtendedDatatype = PhoneNo;
        }
        field(8; "Phone No. 2"; Text[30])
        {
            Caption = 'Phone No. 2';
            ExtendedDatatype = PhoneNo;
        }
        field(9; "Telex No."; Text[30])
        {
            Caption = 'Telex No.';
        }
        field(10; "Fax No."; Text[30])
        {
            Caption = 'Fax No.';
        }
        field(11; "Giro No."; Text[20])
        {
            Caption = 'Giro No.';
        }
        field(12; "Bank Name"; Text[100])
        {
            Caption = 'Bank Name';
        }
        field(13; "Bank Branch No."; Text[20])
        {
            Caption = 'Bank Branch No.';
        }
        field(14; "Bank Account No."; Text[30])
        {
            Caption = 'Bank Account No.';
        }
        field(15; "Payment Routing No."; Text[20])
        {
            Caption = 'Payment Routing No.';
        }
        field(17; "Customs Permit No."; Text[10])
        {
            Caption = 'Customs Permit No.';
        }
        field(18; "Customs Permit Date"; Date)
        {
            Caption = 'Customs Permit Date';
        }
        field(19; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';

            trigger OnValidate()
            var
                VATRegNoFormat: Record "VAT Registration No. Format";
                VATRegistrationLog: Record "VAT Registration Log";
                VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config";
                VATRegistrationLogMgt: Codeunit "VAT Registration Log Mgt.";
                ResultRecordRef: RecordRef;
            begin
                "VAT Registration No." := UpperCase("VAT Registration No.");
                if "VAT Registration No." = xRec."VAT Registration No." then
                    exit;
                if not VATRegNoFormat.Test("VAT Registration No.", "Country/Region Code", '', DATABASE::"Company Information") then
                    exit;
                if "Country/Region Code" = '' then
                    exit;
                if VATRegNoSrvConfig.VATRegNoSrvIsEnabled() then begin
                    VATRegistrationLogMgt.ValidateVATRegNoWithVIES(
                        ResultRecordRef, Rec, "Primary Key",
                        VATRegistrationLog."Account Type"::"Company Information".AsInteger(), "Country/Region Code");
                    ResultRecordRef.SetTable(Rec);
                end;
            end;
        }
        field(20; "Registration No."; Text[20])
        {
            Caption = 'Registration No.';
        }
        field(21; "Telex Answer Back"; Text[20])
        {
            Caption = 'Telex Answer Back';
        }
        field(22; "Ship-to Name"; Text[100])
        {
            Caption = 'Ship-to Name';
        }
        field(23; "Ship-to Name 2"; Text[50])
        {
            Caption = 'Ship-to Name 2';
        }
        field(24; "Ship-to Address"; Text[100])
        {
            Caption = 'Ship-to Address';
        }
        field(25; "Ship-to Address 2"; Text[50])
        {
            Caption = 'Ship-to Address 2';
        }
        field(26; "Ship-to City"; Text[30])
        {
            Caption = 'Ship-to City';
            TableRelation = if ("Ship-to Country/Region Code" = const('')) "Post Code".City
            else
            if ("Ship-to Country/Region Code" = filter(<> '')) "Post Code".City where("Country/Region Code" = field("Ship-to Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode("Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code");
            end;

            trigger OnValidate()
            begin
                PostCode.ValidateCity(
                  "Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(27; "Ship-to Contact"; Text[100])
        {
            Caption = 'Ship-to Contact';
        }
        field(28; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        field(29; Picture; BLOB)
        {
            Caption = 'Picture';
            SubType = Bitmap;

            trigger OnValidate()
            begin
                PictureUpdated := true;
            end;
        }
        field(30; "Post Code"; Code[20])
        {
            Caption = 'Post Code';
            TableRelation = if ("Country/Region Code" = const('')) "Post Code".Code
            else
            if ("Country/Region Code" = filter(<> '')) "Post Code".Code where("Country/Region Code" = field("Country/Region Code"));
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
                OnBeforeValidatePostCode(Rec, IsHandled);
                if not IsHandled then
                    PostCode.ValidatePostCode(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(31; County; Text[30])
        {
            CaptionClass = '5,1,' + "Country/Region Code";
            Caption = 'County';
        }
        field(32; "Ship-to Post Code"; Code[20])
        {
            Caption = 'Ship-to Post Code';
            TableRelation = if ("Ship-to Country/Region Code" = const('')) "Post Code".Code
            else
            if ("Ship-to Country/Region Code" = filter(<> '')) "Post Code".Code where("Country/Region Code" = field("Ship-to Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode("Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code");
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnbeforeValidateShipToPostCode(Rec, IsHandled);
                if not IsHandled then
                    PostCode.ValidatePostCode(
                        "Ship-to City", "Ship-to Post Code", "Ship-to County", "Ship-to Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(33; "Ship-to County"; Text[30])
        {
            CaptionClass = '5,4,' + "Ship-to Country/Region Code";
            Caption = 'Ship-to County';
        }
        field(34; "E-Mail"; Text[80])
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
        field(35; "Home Page"; Text[255])
#if not CLEAN27
#pragma warning restore AS0086
#endif
        {
            Caption = 'Home Page';
            ExtendedDatatype = URL;
        }
        field(36; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";

            trigger OnValidate()
            begin
                PostCode.CheckClearPostCodeCityCounty(City, "Post Code", County, "Country/Region Code", xRec."Country/Region Code");
            end;
        }
        field(37; "Ship-to Country/Region Code"; Code[10])
        {
            Caption = 'Ship-to Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(38; IBAN; Code[50])
        {
            Caption = 'IBAN';

            trigger OnValidate()
            begin
                CheckIBAN(IBAN);
            end;
        }
        field(39; "SWIFT Code"; Code[20])
        {
            Caption = 'SWIFT Code';
            TableRelation = "SWIFT Code";
            ValidateTableRelation = false;
        }
        field(40; "Industrial Classification"; Text[30])
        {
            Caption = 'Industrial Classification';
        }
        field(46; "System Indicator"; Option)
        {
            Caption = 'System Indicator';
            OptionCaption = 'None,Custom';
            OptionMembers = "None","Custom";
        }
        field(47; "Custom System Indicator Text"; Text[250])
        {
            Caption = 'Custom System Indicator Text';
        }
        field(48; "System Indicator Style"; Option)
        {
            Caption = 'System Indicator Style';
            OptionCaption = 'Standard,Accent1,Accent2,Accent3,Accent4,Accent5,Accent6,Accent7,Accent8,Accent9';
            OptionMembers = Standard,Accent1,Accent2,Accent3,Accent4,Accent5,Accent6,Accent7,Accent8,Accent9;
        }
        field(50; "Allow Blank Payment Info."; Boolean)
        {
            Caption = 'Allow Blank Payment Info.';
        }
        field(51; "Contact Person"; Text[50])
        {
            Caption = 'Contact Person';
        }
        field(52; "Ship-to Phone No."; Text[30])
        {
            Caption = 'Ship-to Phone No.';
            ExtendedDatatype = PhoneNo;
        }
        field(60; "Pricing Implementation"; Enum "Pricing Implementation")
        {
            Caption = 'Pricing Implementation';

            trigger OnValidate()
            var
                FeaturePriceCalculation: Codeunit "Feature - Price Calculation";
            begin
                if "Pricing Implementation" = xRec."Pricing Implementation" then
                    exit;

                if "Pricing Implementation" = "Pricing Implementation"::"Extended Pricing" then
                    FeaturePriceCalculation.CopyBasicPricingData("Pricing Implementation", true);
            end;
        }
        field(90; GLN; Code[13])
        {
            Caption = 'GLN';
            Numeric = true;

            trigger OnValidate()
            var
                GLNCalculator: Codeunit "GLN Calculator";
            begin
                if GLN <> '' then
                    if not GLNCalculator.IsValidCheckDigit13(GLN) then
                        Error(GLNCheckDigitErr, FieldCaption(GLN));
            end;
        }
        field(92; "EORI Number"; Text[40])
        {
            Caption = 'EORI Number';
        }
        field(95; "Use GLN in Electronic Document"; Boolean)
        {
            Caption = 'Use GLN in Electronic Documents';
        }
        field(96; "Picture - Last Mod. Date Time"; DateTime)
        {
            Caption = 'Picture - Last Mod. Date Time';
            Editable = false;
        }
        field(98; "Last Modified Date Time"; DateTime)
        {
            Caption = 'Last Modified Date Time';
            Editable = false;
        }
        field(99; "Created DateTime"; DateTime)
        {
            Caption = 'Created DateTime';
            Editable = false;
        }
        field(100; "Demo Company"; Boolean)
        {
            Caption = 'Demo Company';
            Editable = false;
        }
        field(200; "Alternative Language Code"; Code[10])
        {
            Caption = 'Alternative Language Code';
            TableRelation = Language;
        }
        field(300; "Brand Color Value"; Code[10])
        {
            Caption = 'Brand Color Value';

            trigger OnValidate()
            var
                O365BrandColor: Record "O365 Brand Color";
            begin
                O365BrandColor.FindColor(O365BrandColor, "Brand Color Value");
                Validate("Brand Color Code", O365BrandColor.Code);
            end;
        }
        field(301; "Brand Color Code"; Code[20])
        {
            Caption = 'Brand Color Code';
            TableRelation = "O365 Brand Color";

            trigger OnValidate()
            begin
                SetBrandColorValue();
            end;
        }
        field(5700; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            TableRelation = "Responsibility Center".Code;
            ValidateTableRelation = true;
        }
        field(5791; "Check-Avail. Period Calc."; DateFormula)
        {
            AccessByPermission = TableData Item = R;
            Caption = 'Check-Avail. Period Calc.';
        }
        field(5792; "Check-Avail. Time Bucket"; Enum "Analysis Period Type")
        {
            AccessByPermission = TableData Item = R;
            Caption = 'Check-Avail. Time Bucket';
        }
        field(7600; "Base Calendar Code"; Code[10])
        {
            Caption = 'Base Calendar Code';
            TableRelation = "Base Calendar";
        }
        field(7601; "Cal. Convergence Time Frame"; DateFormula)
        {
            AccessByPermission = TableData "Base Calendar" = R;
            Caption = 'Cal. Convergence Time Frame';
            InitValue = '1Y';
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        "Last Modified Date Time" := CurrentDateTime;
        if PictureUpdated then
            "Picture - Last Mod. Date Time" := "Last Modified Date Time";
    end;

    trigger OnModify()
    begin
        "Last Modified Date Time" := CurrentDateTime;
        if PictureUpdated then
            "Picture - Last Mod. Date Time" := "Last Modified Date Time";
    end;

    var
        PostCode: Record "Post Code";
        PictureUpdated: Boolean;
        RecordHasBeenRead: Boolean;

        NotValidIBANErr: Label 'The number %1 that you entered may not be a valid International Bank Account Number (IBAN). Do you want to continue?', Comment = '%1 - an actual IBAN';
        NoPaymentInfoQst: Label 'No payment information is provided in %1. Do you want to update it now?', Comment = '%1 = Company Information';
#pragma warning disable AA0470
        NoPaymentInfoMsg: Label 'No payment information is provided in %1. Review the report.';
        GLNCheckDigitErr: Label 'The %1 is not valid.';
#pragma warning restore AA0470
        DevBetaModeTxt: Label 'DEV_BETA', Locked = true;
        ContactUsFullTxt: Label 'Questions? Contact us at %1 or %2.', Comment = '%1 = phone number, %2 = email';
        ContactUsShortTxt: Label 'Questions? Contact us at %1.', Comment = '%1 = phone number or email';
        AlTelemetryCategoryTxt: Label 'AL CompanyInfo', Locked = true;
        EmptyCountryRegionErr: Label 'Country/Region code is not set, falling back to application default: %1.', Locked = true;

    procedure CheckIBAN(IBANCode: Code[100])
    var
        OriginalIBANCode: Code[100];
        Modulus97: Integer;
        I: Integer;
    begin
        OnBeforeCheckIBAN(IBANCode);

        if IBANCode = '' then
            exit;
        OriginalIBANCode := IBANCode;
        IBANCode := DelChr(IBANCode);
        Modulus97 := 97;
        if (StrLen(IBANCode) <= 5) or (StrLen(IBANCode) > 34) then
            IBANError(OriginalIBANCode);
        if IsDigit(IBANCode[1]) or IsDigit(IBANCode[2]) then
            IBANError(OriginalIBANCode);
        ConvertIBAN(IBANCode);
        while StrLen(IBANCode) > 6 do
            IBANCode := CalcModulus(CopyStr(IBANCode, 1, 6), Modulus97) + CopyStr(IBANCode, 7);
        Evaluate(I, IBANCode);
        if (I mod Modulus97) <> 1 then
            IBANError(OriginalIBANCode);
    end;

    procedure ConvertIBAN(var IBANCode: Code[100])
    var
        I: Integer;
    begin
        IBANCode := CopyStr(IBANCode, 5) + CopyStr(IBANCode, 1, 4);
        I := 0;
        while I < StrLen(IBANCode) do begin
            I := I + 1;
            if ConvertLetter(IBANCode, CopyStr(IBANCode, I, 1), I) then
                I := 0;
        end;
    end;

    procedure CalcModulus(Number: Code[10]; Modulus97: Integer): Code[10]
    var
        I: Integer;
    begin
        Evaluate(I, Number);
        I := I mod Modulus97;
        if I = 0 then
            exit('');
        exit(Format(I));
    end;

    procedure ConvertLetter(var IBANCode: Code[100]; Letter: Code[1]; LetterPlace: Integer): Boolean
    var
        Letter2: Code[2];
        LetterCharInt: Integer;
    begin
        // CFR assumes letter to number conversion where A = 10, B = 11, ... , Y = 34, Z = 35
        // We must ignore country alphabet feature like Estonian
        LetterCharInt := Letter[1];
        if LetterCharInt in [65 .. 90] then begin
            Letter2 := Format(LetterCharInt - 55, 9);
            case LetterPlace of
                1:
                    IBANCode := Letter2 + CopyStr(IBANCode, 2);
                StrLen(IBANCode):
                    IBANCode := CopyStr(IBANCode, 1, LetterPlace - 1) + Letter2;
                else
                    IBANCode :=
                      CopyStr(IBANCode, 1, LetterPlace - 1) + Letter2 + CopyStr(IBANCode, LetterPlace + 1);
            end;
            exit(true);
        end;
        if IsDigit(Letter[1]) then
            exit(false);

        IBANError(IBANCode);
    end;

    procedure IsDigit(LetterChar: Char): Boolean
    var
        Letter: Code[1];
    begin
        Letter[1] := LetterChar;
        exit((Letter >= '0') and (Letter <= '9'))
    end;

    procedure IBANError(WrongIBAN: Text)
    var
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        OnBeforeIBANError(IsHandled, WrongIBAN);
        if IsHandled then
            exit;
        if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(NotValidIBANErr, WrongIBAN), true) then
            Error('');
    end;

    procedure DisplayMap()
    var
        OnlineMapManagement: Codeunit "Online Map Management";
    begin
        OnlineMapManagement.MakeSelectionIfMapEnabled(Database::"Company Information", GetPosition());
    end;

    local procedure IsPaymentInfoAvailble(): Boolean
    begin
        exit(
          (("Giro No." + IBAN + "Bank Name" + "Bank Branch No." + "Bank Account No." + "SWIFT Code") <> '') or
          "Allow Blank Payment Info.");
    end;

    procedure GetRegistrationNumber() Result: Text
    begin
        Result := "Registration No.";
        OnAfterGetRegistrationNumber(Result);
    end;

    procedure GetRegistrationNumberLbl() Result: Text
    begin
        Result := FieldCaption("Registration No.");
        OnAfterGetRegistrationNumberLbl(Result);
    end;

    procedure GetVATRegistrationNumber() Result: Text
    begin
        Result := "VAT Registration No.";
        OnAfterGetVATRegistrationNumber(Result);
    end;

    procedure GetVATRegistrationNumberLbl() Result: Text
    var
        IsHandled: Boolean;
    begin
        if Name = '' then // Is the record loaded?
            Get();

        IsHandled := false;
        OnBeforeGetVATRegistrationNumberLbl(Result, IsHandled);
        if IsHandled then
            exit(Result);

        if "VAT Registration No." = '' then
            exit('');
        exit(FieldCaption("VAT Registration No."));
    end;

    procedure GetRecordOnce()
    begin
        if RecordHasBeenRead then
            exit;
        Get();
        RecordHasBeenRead := true;
    end;

    procedure VerifyAndSetPaymentInfo()
    var
        ConfirmManagement: Codeunit "Confirm Management";
        CompanyInformationPage: Page "Company Information";
    begin
        Get();
        if IsPaymentInfoAvailble() then
            exit;
        if GuiAllowed then begin
            if ConfirmManagement.GetResponseOrDefault(StrSubstNo(NoPaymentInfoQst, TableCaption), true) then begin
                CompanyInformationPage.SetRecord(Rec);
                CompanyInformationPage.Editable(true);
                if CompanyInformationPage.RunModal() = ACTION::OK then
                    CompanyInformationPage.GetRecord(Rec);
            end;
            if not IsPaymentInfoAvailble() then
                Message(NoPaymentInfoMsg, TableCaption);
        end else
            Error(NoPaymentInfoMsg, TableCaption);
    end;

    procedure GetSystemIndicator(var Text: Text[250]; var Style: Option Standard,Accent1,Accent2,Accent3,Accent4,Accent5,Accent6,Accent7,Accent8,Accent9)
    begin
        Style := "System Indicator Style";
        case "System Indicator" of
            "System Indicator"::None:
                Text := '';
            "System Indicator"::"Custom":
                Text := "Custom System Indicator Text";
        end;
        OnAfterGetSystemIndicator(Text, Style)
    end;

    procedure GetCountryRegionCode(CountryRegionCode: Code[10]): Code[10]
    begin
        case CountryRegionCode of
            '', "Country/Region Code":
                exit("Country/Region Code");
            else
                exit(CountryRegionCode);
        end;
    end;

    procedure GetCompanyCountryRegionCode(): Code[10]
    var
        MediaResourcesMgt: Codeunit "Media Resources Mgt.";
        CountryRegionCode: Code[10];
    begin
        if "Country/Region Code" <> '' then
            exit("Country/Region Code");

        CountryRegionCode := UpperCase(MediaResourcesMgt.ReadTextFromMediaResource('ApplicationCountry'));

        Session.LogMessage('00007HP', StrSubstNo(EmptyCountryRegionErr, CountryRegionCode), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AlTelemetryCategoryTxt);

        exit(CountryRegionCode);
    end;

    procedure GetDevBetaModeTxt(): Text[250]
    begin
        exit(DevBetaModeTxt);
    end;

    procedure GetContactUsText(): Text
    begin
        if ("Phone No." <> '') and ("E-Mail" <> '') then
            exit(StrSubstNo(ContactUsFullTxt, "Phone No.", "E-Mail"));

        if "Phone No." <> '' then
            exit(StrSubstNo(ContactUsShortTxt, "Phone No."));

        if "E-Mail" <> '' then
            exit(StrSubstNo(ContactUsShortTxt, "E-Mail"));

        exit('');
    end;

    local procedure SetBrandColorValue()
    var
        O365BrandColor: Record "O365 Brand Color";
    begin
        if "Brand Color Code" <> '' then begin
            O365BrandColor.Get("Brand Color Code");
            "Brand Color Value" := O365BrandColor."Color Value";
        end else
            "Brand Color Value" := '';
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSystemIndicator(var Text: Text[250]; var Style: Option Standard,Accent1,Accent2,Accent3,Accent4,Accent5,Accent6,Accent7,Accent8,Accent9)
    begin
    end;

    procedure SetPictureFromBlob(TempBlob: Codeunit "Temp Blob")
    var
        RecordRef: RecordRef;
    begin
        RecordRef.GetTable(Rec);
        TempBlob.ToRecordRef(RecordRef, FieldNo(Picture));
        RecordRef.SetTable(Rec);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeIBANError(var IsHandled: Boolean; WrongIBAN: Text)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterGetRegistrationNumber(var Result: Text)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterGetRegistrationNumberLbl(var Result: Text)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterGetVATRegistrationNumber(var Result: Text)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeGetVATRegistrationNumberLbl(var Result: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckIBAN(IBANCode: Code[100])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateCity(var CompanyInformation: Record "Company Information"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePostCode(var CompanyInformation: Record "Company Information"; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN27
    [Obsolete('This event is never raised.', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShipToCity(var CompanyInformation: Record "Company Information"; var IsHandled: Boolean)
    begin
    end;
#endif
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShipToPostCode(var CompanyInformation: Record "Company Information"; var IsHandled: Boolean)
    begin
    end;
}