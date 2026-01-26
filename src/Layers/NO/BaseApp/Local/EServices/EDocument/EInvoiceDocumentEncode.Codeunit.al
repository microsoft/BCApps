// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;

codeunit 10610 "E-Invoice Document Encode"
{

    trigger OnRun()
    begin
    end;

    var
        CompanyInfo: Record "Company Information";
        GLSetup: Record "General Ledger Setup";
        WrongLengthErr: Label 'should be %1 characters long';
        CompanyInfoRead: Boolean;
        GLSetupRead: Boolean;

    procedure DateToText(VarDate: Date): Text[20]
    begin
        if VarDate = 0D then
            exit('1753-01-01');
        exit(Format(VarDate, 0, '<Year4>-<Month,2>-<Day,2>'));
    end;

    procedure BooleanToText(VarBoolean: Boolean): Text[5]
    begin
        case VarBoolean of
            true:
                exit('true');
            false:
                exit('false');
        end;
    end;

    procedure DecimalToText(VarDecimal: Decimal): Text[30]
    begin
        exit(Format(VarDecimal, 0, '<Precision,2:2><Sign><Integer><Decimals><Comma,.>'));
    end;

    procedure DecimalExtToText(VarDecimal: Decimal): Text[30]
    begin
        exit(Format(VarDecimal, 0, '<Precision,2:5><Sign><Integer><Decimals><Comma,.>'));
    end;

    procedure IntegerToText(VarInteger: Integer): Text[250]
    begin
        exit(Format(VarInteger, 0, '<Sign><Integer,2><Filler Character,0>'));
    end;

    procedure IsValidEANNo(EAN: Code[13]; AllowEmpty: Boolean): Boolean
    begin
        case true of
            EAN = '':
                exit(AllowEmpty);
            StrLen(EAN) <> 13:
                exit(false);
            Format(StrCheckSum(CopyStr(EAN, 1, 12), '131313131313')) <> Format(EAN[13]):
                exit(false);
            else
                exit(true);
        end;
    end;

    procedure CheckCurrencyCode(CurrencyCode: Code[10]): Boolean
    begin
        exit(StrLen(CurrencyCode) = 3);
    end;

    procedure DecimalToPromille(Decimal: Decimal): Text[4]
    begin
        exit(Format(Abs(Decimal * 10), 0, '<Integer,4><Filler Character,0>'));
    end;

    procedure GetEInvoiceCountryRegionCode(CountryRegionCode: Code[10]): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        if CountryRegionCode = '' then begin
            ReadCompanyInfo();
            CompanyInfo.TestField("Country/Region Code");
            CountryRegionCode := CompanyInfo."Country/Region Code";
        end;

        CountryRegion.Get(CountryRegionCode);
        if StrLen(CountryRegion.Code) <> 2 then
            CountryRegion.FieldError(Code, StrSubstNo(WrongLengthErr, 2));
        exit(CountryRegion.Code);
    end;

    procedure GetEInvoiceCurrencyCode(CurrencyCode: Code[10]): Code[10]
    var
        Currency: Record Currency;
    begin
        if CurrencyCode = '' then begin
            ReadGLSetup();
            GLSetup.TestField("LCY Code");
            CurrencyCode := GLSetup."LCY Code";
        end;

        if not Currency.Get(CurrencyCode) then begin
            if StrLen(CurrencyCode) <> 3 then
                GLSetup.FieldError("LCY Code", StrSubstNo(WrongLengthErr, 3));
            exit(CurrencyCode);
        end;

        if StrLen(Currency.Code) <> 3 then
            Currency.FieldError(Code, StrSubstNo(WrongLengthErr, 3));
        exit(Currency.Code);
    end;

    procedure ReadCompanyInfo()
    begin
        if not CompanyInfoRead then begin
            CompanyInfo.Get();
            CompanyInfoRead := true;
        end;
    end;

    procedure ReadGLSetup()
    begin
        if not GLSetupRead then begin
            GLSetup.Get();
            GLSetupRead := true;
        end;
    end;

    procedure GetBBANNo(BBANNo: Text[50]): Text[50]
    begin
        if BBANNo = '' then
            exit('');

        BBANNo := DelChr(BBANNo, '=', DelChr(BBANNo, '=', '0123456789'));

        exit(BBANNo);
    end;

    procedure GetVATRegNo(VATRegNo: Text[20]; PartyTaxScheme: Boolean): Text[30]
    begin
        if VATRegNo = '' then
            exit('');

        VATRegNo := DelChr(VATRegNo, '=', DelChr(VATRegNo, '=', '0123456789'));
        if PartyTaxScheme then
            VATRegNo += 'MVA';

        exit(VATRegNo);
    end;
}

