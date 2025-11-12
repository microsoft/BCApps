// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Registration;

using Microsoft.CRM.Contact;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

table 381 "VAT Registration No. Format"
{
    Caption = 'VAT Registration No. Format';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            Editable = false;
            NotBlank = true;
            TableRelation = "Country/Region";
            ToolTip = 'Specifies the country/region of the address.';
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; Format; Text[20])
        {
            Caption = 'Format';
            ToolTip = 'Specifies a format for a country''s/region''s VAT registration number.';
        }
    }

    keys
    {
        key(Key1; "Country/Region Code", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'The entered VAT Registration number is not in agreement with the format specified for Country/Region Code %1.\';
        Text001: Label 'The following formats are acceptable: %1', Comment = '1 - format list';
        Text002: Label 'This VAT registration number has already been entered for the following customers:\ %1';
        Text003: Label 'This VAT registration number has already been entered for the following vendors:\ %1';
        Text004: Label 'This VAT registration number has already been entered for the following contacts:\ %1';
#pragma warning restore AA0470
        Text005: Label 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
#pragma warning restore AA0074
        VATRegistrationNumberErr: Label 'The entered VAT Registration number for %1 %2 is not in agreement with the format specified for Country/Region Code %3.\', Comment = '%1 - Record Type, %2 - Record No., %3 - Country Region Code';

    procedure Test(VATRegNo: Text[20]; CountryCode: Code[10]; Number: Code[20]; TableID: Option): Boolean
    var
        CompanyInfo: Record "Company Information";
        Customer: Record Customer;
        Vendor: Record Vendor;
        Contact: Record Contact;
        Check: Boolean;
        Finish: Boolean;
        TextString: Text;
        ErrorMsg: Text;
        IsHandled: Boolean;
    begin
        VATRegNo := UpperCase(VATRegNo);
        if VATRegNo = '' then
            exit;

        Check := true;
        IsHandled := false;
        OnBeforeTest(VATRegNo, CountryCode, Number, TableID, Check, IsHandled);
        if IsHandled then
            exit(true);

        if CountryCode = '' then begin
            if not CompanyInfo.Get() then
                exit;
            SetRange("Country/Region Code", CompanyInfo."Country/Region Code");
        end else
            SetRange("Country/Region Code", CountryCode);
        SetFilter(Format, '<> %1', '');
        if FindSet() then
            repeat
                AppendString(TextString, Finish, Format);
                Check := Compare(VATRegNo, Format);
            until Check or (Next() = 0);

        if not Check then begin
            case TableID of
                DATABASE::Customer:
                    if Customer.Get(Number) then
                        ErrorMsg := StrSubstNo(VATRegistrationNumberErr, Customer.TableCaption, Customer."No.", "Country/Region Code");
                DATABASE::Vendor:
                    if Vendor.Get(Number) then
                        ErrorMsg := StrSubstNo(VATRegistrationNumberErr, Vendor.TableCaption, Vendor."No.", "Country/Region Code");
                DATABASE::Contact:
                    if Contact.Get(Number) then
                        ErrorMsg := StrSubstNo(VATRegistrationNumberErr, Contact.TableCaption, Contact."No.", "Country/Region Code");
                else begin
                    IsHandled := false;
                    OnConstructErrorMessageIfNotCheck(VATRegistrationNumberErr, Number, TableID, ErrorMsg, IsHandled);
                    if not IsHandled then
                        ErrorMsg := StrSubstNo(Text000, "Country/Region Code");
                end;
            end;
            Error('%1%2', ErrorMsg, StrSubstNo(Text001, TextString));
        end;

        case TableID of
            DATABASE::Customer:
                CheckCust(VATRegNo, Number);
            DATABASE::Vendor:
                CheckVendor(VATRegNo, Number);
            DATABASE::Contact:
                CheckContact(VATRegNo, Number);
            else
                OnTestTable(VATRegNo, CountryCode, Number, TableID);
        end;
        exit(true);
    end;

    local procedure CheckCust(VATRegNo: Text[20]; Number: Code[20])
    var
        Cust: Record Customer;
        Check: Boolean;
        Finish: Boolean;
        TextString: Text;
        CustomerIdentification: Text[100];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckCust(VATRegNo, Number, IsHandled);
        if IsHandled then
            exit;

        Check := true;
        TextString := '';
        Cust.SetCurrentKey("VAT Registration No.");
        Cust.SetRange("VAT Registration No.", VATRegNo);
        Cust.SetFilter("No.", '<>%1', Number);
        OnCheckCustOnBeforeCustFindSet(Cust);
        if Cust.FindSet() then begin
            Check := false;
            Finish := false;
            repeat
                CustomerIdentification := Cust."No.";
                AppendString(TextString, Finish, CustomerIdentification);
            until (Cust.Next() = 0) or Finish;
        end;
        OnCheckCustOnBeforeCheck(VATRegNo, Number, TextString, Check);
        if not Check then
            ShowCheckCustMessage(TextString);
    end;

    local procedure ShowCheckCustMessage(TextString: Text)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowCheckCustMessage(TextString, IsHandled);
        if IsHandled then
            exit;

        Message(StrSubstNo(Text002, TextString));
    end;

    local procedure CheckVendor(VATRegNo: Text[20]; Number: Code[20])
    var
        Vend: Record Vendor;
        Check: Boolean;
        Finish: Boolean;
        TextString: Text;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckVend(VATRegNo, Number, IsHandled);
        if IsHandled then
            exit;

        Check := true;
        TextString := '';
        Vend.SetCurrentKey("VAT Registration No.");
        Vend.SetRange("VAT Registration No.", VATRegNo);
        Vend.SetFilter("No.", '<>%1', Number);
        OnCheckVendOnBeforeVendFindSet(Vend);
        if Vend.FindSet() then begin
            Check := false;
            Finish := false;
            repeat
                AppendString(TextString, Finish, Vend."No.");
            until (Vend.Next() = 0) or Finish;
        end;
        OnCheckVendorOnBeforeCheck(VATRegNo, Number, TextString, Check);
        if not Check then
            ShowCheckVendMessage(TextString);
    end;

    local procedure ShowCheckVendMessage(TextString: Text)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowCheckVendMessage(TextString, IsHandled);
        if IsHandled then
            exit;

        Message(StrSubstNo(Text003, TextString));
    end;

    local procedure CheckContact(VATRegNo: Text[20]; Number: Code[20])
    var
        Cont: Record Contact;
        Check: Boolean;
        Finish: Boolean;
        TextString: Text;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckContact(VATRegNo, Number, IsHandled);
        if IsHandled then
            exit;

        Check := true;
        TextString := '';
        Cont.SetCurrentKey("VAT Registration No.");
        Cont.SetRange("VAT Registration No.", VATRegNo);
        Cont.SetFilter("No.", '<>%1', Number);
        if Cont.FindSet() then begin
            Check := false;
            Finish := false;
            repeat
                AppendString(TextString, Finish, Cont."No.");
            until (Cont.Next() = 0) or Finish;
        end;
        OnCheckContactOnBeforeCheck(VATRegNo, Number, TextString, Check);
        if not Check then
            Message(StrSubstNo(Text004, TextString));
    end;

    procedure Compare(VATRegNo: Text[20]; Format: Text[20]): Boolean
    var
        i: Integer;
        Cf: Text[1];
        Ce: Text[1];
        Check: Boolean;
    begin
        Check := true;
        if StrLen(VATRegNo) = StrLen(Format) then
            for i := 1 to StrLen(VATRegNo) do begin
                Cf := CopyStr(Format, i, 1);
                Ce := CopyStr(VATRegNo, i, 1);
                case Cf of
                    '#':
                        if not ((Ce >= '0') and (Ce <= '9')) then
                            Check := false;
                    '@':
                        if StrPos(Text005, UpperCase(Ce)) = 0 then
                            Check := false;
                    else
                        if not ((Cf = Ce) or (Cf = '?')) then
                            Check := false
                end;
            end
        else
            Check := false;
        exit(Check);
    end;

    local procedure AppendString(var String: Text; var Finish: Boolean; AppendText: Text)
    begin
        case true of
            Finish:
                exit;
            String = '':
                String := AppendText;
            StrLen(String) + StrLen(AppendText) + 5 <= 250:
                String += ', ' + AppendText;
            else begin
                String += '...';
                Finish := true;
            end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCust(VATRegNo: Text[20]; Number: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowCheckCustMessage(TextString: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowCheckVendMessage(TextString: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckVend(VATRegNo: Text[20]; Number: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckContact(VATRegNo: Text[20]; Number: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTest(VATRegNo: Text[20]; CountryCode: Code[10]; Number: Code[20]; TableID: Option; Check: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckContactOnBeforeCheck(VATRegNo: Text[20]; Number: Code[20]; TextString: Text; var Check: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckCustOnBeforeCustFindSet(var Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckCustOnBeforeCheck(VATRegNo: Text[20]; Number: Code[20]; TextString: Text; var Check: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckVendOnBeforeVendFindSet(var Vendor: Record Vendor)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckVendorOnBeforeCheck(VATRegNo: Text[20]; Number: Code[20]; TextString: Text; var Check: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTestTable(VATRegNo: Text[20]; CountryCode: Code[10]; Number: Code[20]; TableID: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnConstructErrorMessageIfNotCheck(ErrorMessageLbl: Text; Number: Code[20]; TableID: Option; var ErrorMsg: Text; var IsHandled: Boolean)
    begin
    end;
}

