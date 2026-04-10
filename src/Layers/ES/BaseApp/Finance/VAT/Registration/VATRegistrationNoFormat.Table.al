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

/// <summary>
/// Defines country-specific VAT registration number formats for validation and duplicate checking.
/// Provides pattern matching capabilities and business rules enforcement for VAT numbers across different jurisdictions.
/// </summary>
table 381 "VAT Registration No. Format"
{
    Caption = 'VAT Registration No. Format';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Country or region code that determines the applicable VAT registration number format rules.
        /// </summary>
        field(1; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            Editable = false;
            NotBlank = true;
            TableRelation = "Country/Region";
            ToolTip = 'Specifies the country/region of the address.';
        }
        /// <summary>
        /// Line number for multiple format definitions within the same country/region.
        /// </summary>
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        /// <summary>
        /// Pattern definition for valid VAT registration number format using # for digits, @ for letters, and ? for any character.
        /// </summary>
        field(3; Format; Text[20])
        {
            Caption = 'Format';
            ToolTip = 'Specifies a format for a country''s/region''s VAT registration number.';
        }
        field(10700; "Check VAT Registration No."; Boolean)
        {
            Caption = 'Check VAT Registration No.';
            InitValue = true;
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
        Text1100000: Label 'The VAT Registration number is not valid.';
        Text1100001: Label 'Do you still want to save it?';
        Text1100002: Label 'The update has been interrupted to respect the warning.';
        Text1100003: Label 'The length of the number exceeds the maximum limit of %1 characters.';
        Text1100004: Label 'The first character (T Element) of the number is invalid.';
        Text1100005: Label 'There should not be any alphabetic characters in the mid part of the number.';
        Text1100006: Label 'The control element is not correct.';
#pragma warning restore AA0074
        VATRegistrationNumberErr: Label 'The entered VAT Registration number for %1 %2 is not in agreement with the format specified for Country/Region Code %3.\', Comment = '%1 - Record Type, %2 - Record No., %3 - Country Region Code';

    /// <summary>
    /// Validates VAT registration number format and checks for duplicates across customer, vendor, and contact records.
    /// </summary>
    /// <param name="VATRegNo">VAT registration number to validate</param>
    /// <param name="CountryCode">Country/region code for format validation</param>
    /// <param name="Number">Record number to exclude from duplicate checking</param>
    /// <param name="TableID">Table identifier for record type validation</param>
    /// <returns>True if validation passes, otherwise triggers error</returns>
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
        ValidationCheck: Boolean;
    begin
        if (VATRegNo = '') or (not GuiAllowed) then
            exit;

        Check := true;
        ValidationCheck := false;
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
                if "Check VAT Registration No." then
                    ValidationCheck := true;
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

        if ValidationCheck then
            CheckConfirmVATRegNo(VATRegNo);

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
        OnCheckContactOnBeforeContactFindSet(Cont);
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

    /// <summary>
    /// Compares VAT registration number against specified format pattern using wildcard matching.
    /// </summary>
    /// <param name="VATRegNo">VAT registration number to validate</param>
    /// <param name="Format">Format pattern with # for digits, @ for letters, ? for any character</param>
    /// <returns>True if VAT number matches the format pattern</returns>
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

    local procedure CheckConfirmVATRegNo(VATRegNo: Text[20])
    var
        ErrorText: Text[120];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckConfirmVATRegNo(VATRegNo, IsHandled);
        if IsHandled then
            exit;

        ErrorText := '';
        if not ValidateVATRegNo(VATRegNo, ErrorText) then
            if not Confirm(Text1100000 + '\' + ErrorText + '\\' + Text1100001, false) then
                Error(Text1100002);
    end;

    procedure ValidateVATRegNo(VATRegNo: Text[20]; var ErrorText: Text[120]): Boolean
    var
        VATRegNoType: Option ,CIF,NIF,NIE;
        C: Text[1];
        ReplacementChar: Text[1];
        ControlElement: Text[2];
        ReturnValue: Boolean;
        MaxLength: Integer;
        StartPos: Integer;
        CurrentPos: Integer;
    begin
        MaxLength := 9;
        ErrorText := '';
        ReturnValue := true;

        VATRegNo := UpperCase(DelChr(VATRegNo, '<>', ' '));
        if StrLen(VATRegNo) <= MaxLength then begin
            // fill with '0' from the left if required
            C := CopyStr(VATRegNo, 1, 1);
            if (C >= '0') and (C <= '9') then
                StartPos := 1
            else
                StartPos := 2;
            while StrLen(VATRegNo) < MaxLength do
                VATRegNo := InsStr(VATRegNo, '0', StartPos);

            // verify type of VAT Reg. No.
            case C of
                'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'J', 'K', 'N', 'P', 'Q', 'R', 'S', 'U', 'V', 'W':
                    VATRegNoType := VATRegNoType::CIF;
                '0' .. '9', 'L', 'M':
                    VATRegNoType := VATRegNoType::NIF;
                'X', 'Y', 'Z':
                    VATRegNoType := VATRegNoType::NIE;
                else begin
                    ErrorText := Text1100004;
                    ReturnValue := false;
                end;
            end;

            // verify chars 2..MaxLength-1; must be numeric
            if ReturnValue <> false then begin
                CurrentPos := 2;
                repeat
                    C := CopyStr(VATRegNo, CurrentPos, 1);
                    if not ((C >= '0') and (C <= '9')) then
                        ReturnValue := false;
                    CurrentPos := CurrentPos + 1;
                until CurrentPos > MaxLength - 1;
                if ReturnValue = false then
                    ErrorText := StrSubstNo(Text1100005, 2, StrLen(VATRegNo) - 1);
            end;

            // calculate & compare Control digit
            if ReturnValue <> false then begin
                if (VATRegNoType = VATRegNoType::NIF) or (VATRegNoType = VATRegNoType::NIE) then begin
                    C := CopyStr(VATRegNo, 1, 1);
                    ReplacementChar := '';
                    case C of
                        'L', 'M':
                            ReplacementChar := '0';
                        'X':
                            ReplacementChar := '0';
                        'Y':
                            ReplacementChar := '1';
                        'Z':
                            ReplacementChar := '2';
                    end;
                    if ReplacementChar <> '' then
                        VATRegNo := ReplacementChar + DelStr(VATRegNo, 1, 1);
                end;
                case VATRegNoType of
                    VATRegNoType::CIF:
                        ControlElement := CalculateControlElement(CopyStr(VATRegNo, 1, 8), 1);
                    VATRegNoType::NIF:
                        ControlElement := CalculateControlElement(CopyStr(VATRegNo, 1, 8), 2);
                    VATRegNoType::NIE:
                        ControlElement := CalculateControlElement(CopyStr(VATRegNo, 1, 8), 3);
                end;
                case StrLen(ControlElement) of
                    1:
                        ReturnValue := CopyStr(VATRegNo, StrLen(VATRegNo), 1) = ControlElement;
                    2:
                        begin
                            ReturnValue := CopyStr(VATRegNo, StrLen(VATRegNo), 1) = CopyStr(ControlElement, 1, 1);
                            if ReturnValue = false then
                                ReturnValue := CopyStr(VATRegNo, StrLen(VATRegNo), 1) = CopyStr(ControlElement, 2, 1);
                        end
                end;
                // if this is not a valid CIF, then it could be a special NIF
                if (ReturnValue = false) and (VATRegNoType = VATRegNoType::CIF) then begin
                    C := CopyStr(VATRegNo, 1, 1);
                    if C = 'K' then begin
                        VATRegNo := '0' + DelStr(VATRegNo, 1, 1);
                        ControlElement := CalculateControlElement(CopyStr(VATRegNo, 1, 8), 2);
                        ReturnValue := CopyStr(VATRegNo, StrLen(VATRegNo), 1) = ControlElement;
                    end;
                end;

                // Checksum not equal with calculated result
                if ReturnValue = false then
                    ErrorText := Text1100006;
            end;
        end else begin
            // exceeds max length of 9 chars
            ErrorText := StrSubstNo(Text1100003, MaxLength);
            ReturnValue := false;
        end;

        exit(ReturnValue);
    end;

    local procedure CalculateControlElement(VATRegNo: Text[20]; Type: Integer): Text[2]
    var
        ReturnValue: Text[2];
        ElementT: Text[1];
        x: Integer;
        ExprA: Integer;
        ExprB: Integer;
        ExprC: Integer;
        Result: Integer;
    begin
        ReturnValue := '';
        case Type of
            1:
                begin  // CIF
                    ElementT := CopyStr(VATRegNo, 1, 1);
                    VATRegNo := CopyStr(VATRegNo, 2, 7);
                    ExprA := 0;
                    ExprB := 0;
                    ExprC := 0;
                    for x := 1 to StrLen(VATRegNo) do begin
                        Evaluate(Result, CopyStr(VATRegNo, x, 1));
                        case true of
                            x mod 2 = 0:
                                ExprA := ExprA + Result;
                            x mod 2 = 1:
                                ExprB := ExprB + (Result * 2) mod 10 + ((Result * 2) div 10);
                        end;
                    end;
                    ExprC := 10 - ((ExprA + ExprB) mod 10);
                    case ElementT of
                        'K', 'P', 'Q', 'S':
                            ReturnValue := CopyStr('ABCDEFGHIJ', ExprC, 1);
                        'A', 'B', 'E', 'H':
                            ReturnValue := SYSTEM.Format(ExprC);
                        else
                            ReturnValue := CopyStr('ABCDEFGHIJ', ExprC, 1) + SYSTEM.Format(ExprC mod 10);
                    end;
                end;
            2, 3:
                begin  // NIF,NIE
                    Evaluate(Result, VATRegNo);
                    ReturnValue := CopyStr('TRWAGMYFPDXBNJZSQVHLCKE', (Result mod 23) + 1, 1)
                end;
        end;
        exit(ReturnValue);
    end;

    /// <summary>
    /// Integration event raised before validating customer VAT registration number for duplicates.
    /// </summary>
    /// <param name="VATRegNo">VAT registration number being validated</param>
    /// <param name="Number">Customer number to exclude from validation</param>
    /// <param name="IsHandled">Set to true to skip standard validation</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCust(VATRegNo: Text[20]; Number: Code[20]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before displaying customer VAT registration number duplicate warning message.
    /// </summary>
    /// <param name="TextString">Message text to display</param>
    /// <param name="IsHandled">Set to true to skip standard message display</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowCheckCustMessage(TextString: Text; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before displaying vendor VAT registration number duplicate warning message.
    /// </summary>
    /// <param name="TextString">Message text to display</param>
    /// <param name="IsHandled">Set to true to skip standard message display</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowCheckVendMessage(TextString: Text; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before validating vendor VAT registration number for duplicates.
    /// </summary>
    /// <param name="VATRegNo">VAT registration number being validated</param>
    /// <param name="Number">Vendor number to exclude from validation</param>
    /// <param name="IsHandled">Set to true to skip standard validation</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckVend(VATRegNo: Text[20]; Number: Code[20]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before validating contact VAT registration number for duplicates.
    /// </summary>
    /// <param name="VATRegNo">VAT registration number being validated</param>
    /// <param name="Number">Contact number to exclude from validation</param>
    /// <param name="IsHandled">Set to true to skip standard validation</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckContact(VATRegNo: Text[20]; Number: Code[20]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before VAT registration number format validation begins.
    /// </summary>
    /// <param name="VATRegNo">VAT registration number to validate</param>
    /// <param name="CountryCode">Country/region code for format validation</param>
    /// <param name="Number">Record number being validated</param>
    /// <param name="TableID">Table identifier for record type</param>
    /// <param name="Check">Validation result flag</param>
    /// <param name="IsHandled">Set to true to skip standard validation</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckConfirmVATRegNo(VATRegNo: Text[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTest(VATRegNo: Text[20]; CountryCode: Code[10]; Number: Code[20]; TableID: Option; Check: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before contact VAT registration number duplicate validation.
    /// </summary>
    /// <param name="VATRegNo">VAT registration number being validated</param>
    /// <param name="Number">Contact number being validated</param>
    /// <param name="TextString">Message text for duplicate entries</param>
    /// <param name="Check">Validation result flag</param>
    [IntegrationEvent(false, false)]
    local procedure OnCheckContactOnBeforeCheck(VATRegNo: Text[20]; Number: Code[20]; TextString: Text; var Check: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before customer record filtering for VAT registration number duplicate checking.
    /// </summary>
    /// <param name="Customer">Customer record with applied filters for validation</param>
    [IntegrationEvent(false, false)]
    local procedure OnCheckCustOnBeforeCustFindSet(var Customer: Record Customer)
    begin
    end;

    /// <summary>
    /// Integration event raised before customer VAT registration number duplicate validation.
    /// </summary>
    /// <param name="VATRegNo">VAT registration number being validated</param>
    /// <param name="Number">Customer number being validated</param>
    /// <param name="TextString">Message text for duplicate entries</param>
    /// <param name="Check">Validation result flag</param>
    [IntegrationEvent(false, false)]
    local procedure OnCheckCustOnBeforeCheck(VATRegNo: Text[20]; Number: Code[20]; TextString: Text; var Check: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before vendor record filtering for VAT registration number duplicate checking.
    /// </summary>
    /// <param name="Vendor">Vendor record with applied filters for validation</param>
    [IntegrationEvent(false, false)]
    local procedure OnCheckVendOnBeforeVendFindSet(var Vendor: Record Vendor)
    begin
    end;

    /// <summary>
    /// Integration event raised before vendor VAT registration number duplicate validation.
    /// </summary>
    /// <param name="VATRegNo">VAT registration number being validated</param>
    /// <param name="Number">Vendor number being validated</param>
    /// <param name="TextString">Message text for duplicate entries</param>
    /// <param name="Check">Validation result flag</param>
    [IntegrationEvent(false, false)]
    local procedure OnCheckVendorOnBeforeCheck(VATRegNo: Text[20]; Number: Code[20]; TextString: Text; var Check: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised during VAT registration number validation for custom table types.
    /// </summary>
    /// <param name="VATRegNo">VAT registration number being validated</param>
    /// <param name="CountryCode">Country/region code for format validation</param>
    /// <param name="Number">Record number being validated</param>
    /// <param name="TableID">Table identifier for custom record type</param>
    [IntegrationEvent(false, false)]
    local procedure OnTestTable(VATRegNo: Text[20]; CountryCode: Code[10]; Number: Code[20]; TableID: Option)
    begin
    end;

    /// <summary>
    /// Integration event raised to construct custom error message for VAT registration number validation failures.
    /// </summary>
    /// <param name="ErrorMessageLbl">Base error message label</param>
    /// <param name="Number">Record number being validated</param>
    /// <param name="TableID">Table identifier for record type</param>
    /// <param name="ErrorMsg">Constructed error message</param>
    /// <param name="IsHandled">Set to true if custom error message is provided</param>
    [IntegrationEvent(false, false)]
    local procedure OnConstructErrorMessageIfNotCheck(ErrorMessageLbl: Text; Number: Code[20]; TableID: Option; var ErrorMsg: Text; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before contact record filtering for VAT registration number duplicate checking.
    /// </summary>
    /// <param name="Contact">Contact record with applied filters for validation</param>
    [IntegrationEvent(false, false)]
    local procedure OnCheckContactOnBeforeContactFindSet(var Contact: Record Contact)
    begin
    end;
}

