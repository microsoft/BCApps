// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;

/// <summary>
/// Builds the CompanyMetadata JSON payload the platform reads at report run time. Typed setters
/// centralize the wire keys so the subscriber never hand-writes raw key strings (a silent key
/// mismatch would just yield blank fields). Keys mirror the platform ReportInformationStrings and
/// are scoped by the &lt;CompanyMetadata&gt; container emitted into BCReportInformation.
/// </summary>
codeunit 9666 "Company Metadata Builder"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        Payload: JsonObject;
        AddressLines: JsonArray;

    procedure SetName(Value: Text)
    begin
        this.Put('CompanyName', Value);
    end;

    procedure SetDisplayName(Value: Text)
    begin
        this.Put('CompanyDisplayName', Value);
    end;

    procedure AddAddressLine(Value: Text)
    begin
        // Empty lines are skipped by the platform repeater, but keep the array clean here too.
        if Value <> '' then
            this.AddressLines.Add(Value);
    end;

    procedure SetPhone(Value: Text)
    begin
        this.Put('CompanyPhone', Value);
    end;

    procedure SetPhoneCaption(Value: Text)
    begin
        this.Put('CompanyPhoneCaption', Value);
    end;

    procedure SetFaxNo(Value: Text)
    begin
        this.Put('CompanyFaxNo', Value);
    end;

    procedure SetFaxNoCaption(Value: Text)
    begin
        this.Put('CompanyFaxNoCaption', Value);
    end;

    procedure SetEmail(Value: Text)
    begin
        this.Put('CompanyEmail', Value);
    end;

    procedure SetEmailCaption(Value: Text)
    begin
        this.Put('CompanyEmailCaption', Value);
    end;

    procedure SetHomePage(Value: Text)
    begin
        this.Put('CompanyHomePage', Value);
    end;

    procedure SetHomePageCaption(Value: Text)
    begin
        this.Put('CompanyHomePageCaption', Value);
    end;

    procedure SetLogo(Base64Value: Text)
    begin
        this.Put('CompanyLogo', Base64Value);
    end;

    procedure SetVATRegistrationNo(Value: Text)
    begin
        this.Put('CompanyVATRegistrationNo', Value);
    end;

    procedure SetVATRegistrationNoCaption(Value: Text)
    begin
        this.Put('CompanyVATRegistrationNoCaption', Value);
    end;

    procedure SetRegistrationNo(Value: Text)
    begin
        this.Put('CompanyRegistrationNo', Value);
    end;

    procedure SetRegistrationNoCaption(Value: Text)
    begin
        this.Put('CompanyRegistrationNoCaption', Value);
    end;

    procedure SetBankName(Value: Text)
    begin
        this.Put('CompanyBankName', Value);
    end;

    procedure SetBankNameCaption(Value: Text)
    begin
        this.Put('CompanyBankNameCaption', Value);
    end;

    procedure SetBankAccountNo(Value: Text)
    begin
        this.Put('CompanyBankAccountNo', Value);
    end;

    procedure SetBankAccountNoCaption(Value: Text)
    begin
        this.Put('CompanyBankAccountNoCaption', Value);
    end;

    procedure SetBankBranchNo(Value: Text)
    begin
        this.Put('CompanyBankBranchNo', Value);
    end;

    procedure SetBankBranchNoCaption(Value: Text)
    begin
        this.Put('CompanyBankBranchNoCaption', Value);
    end;

    procedure SetIBAN(Value: Text)
    begin
        this.Put('CompanyIBAN', Value);
    end;

    procedure SetIBANCaption(Value: Text)
    begin
        this.Put('CompanyIBANCaption', Value);
    end;

    procedure SetBankSWIFT(Value: Text)
    begin
        this.Put('CompanyBankSWIFT', Value);
    end;

    procedure SetBankSWIFTCaption(Value: Text)
    begin
        this.Put('CompanyBankSWIFTCaption', Value);
    end;

    procedure SetGiroNo(Value: Text)
    begin
        this.Put('CompanyGiroNo', Value);
    end;

    procedure SetGiroNoCaption(Value: Text)
    begin
        this.Put('CompanyGiroNoCaption', Value);
    end;

    /// <summary>
    /// Populates the company block from a Company Information record: name, the formatted address
    /// (via the country/region address format), and the phone/fax/email/home page, VAT/registration,
    /// bank, and giro fields with their captions. Display name and logo are set separately by the
    /// caller because they are not plain Company Information fields.
    /// </summary>
    /// <param name="CompanyInfo">The Company Information record to read the company block from.</param>
    procedure PopulateFromCompanyInformation(var CompanyInfo: Record "Company Information")
    var
        FormatAddress: Codeunit "Format Address";
        AddrArray: array[8] of Text[100];
        Index: Integer;
    begin
        this.SetName(CompanyInfo.Name);

        FormatAddress.Company(AddrArray, CompanyInfo);
        for Index := 1 to ArrayLen(AddrArray) do
            this.AddAddressLine(AddrArray[Index]);

        this.SetPhone(CompanyInfo."Phone No.");
        this.SetPhoneCaption(CompanyInfo.FieldCaption("Phone No."));
        this.SetFaxNo(CompanyInfo."Fax No.");
        this.SetFaxNoCaption(CompanyInfo.FieldCaption("Fax No."));
        this.SetEmail(CompanyInfo."E-Mail");
        this.SetEmailCaption(CompanyInfo.FieldCaption("E-Mail"));
        this.SetHomePage(CompanyInfo."Home Page");
        this.SetHomePageCaption(CompanyInfo.FieldCaption("Home Page"));
        this.SetVATRegistrationNo(CompanyInfo."VAT Registration No.");
        this.SetVATRegistrationNoCaption(CompanyInfo.FieldCaption("VAT Registration No."));
        this.SetRegistrationNo(CompanyInfo."Registration No.");
        this.SetRegistrationNoCaption(CompanyInfo.FieldCaption("Registration No."));
        this.SetBankName(CompanyInfo."Bank Name");
        this.SetBankNameCaption(CompanyInfo.FieldCaption("Bank Name"));
        this.SetBankAccountNo(CompanyInfo."Bank Account No.");
        this.SetBankAccountNoCaption(CompanyInfo.FieldCaption("Bank Account No."));
        this.SetBankBranchNo(CompanyInfo."Bank Branch No.");
        this.SetBankBranchNoCaption(CompanyInfo.FieldCaption("Bank Branch No."));
        this.SetIBAN(CompanyInfo.IBAN);
        this.SetIBANCaption(CompanyInfo.FieldCaption(IBAN));
        this.SetBankSWIFT(CompanyInfo."SWIFT Code");
        this.SetBankSWIFTCaption(CompanyInfo.FieldCaption("SWIFT Code"));
        this.SetGiroNo(CompanyInfo."Giro No.");
        this.SetGiroNoCaption(CompanyInfo.FieldCaption("Giro No."));
    end;

    /// <summary>
    /// Merges the built payload (including the address-line repeater) into the JsonObject the
    /// platform passed to the subscriber. Modifies the passed object in place.
    /// </summary>
    procedure WriteTo(var CompanyMetadata: JsonObject)
    var
        JToken: JsonToken;
        KeyText: Text;
    begin
        // Idempotent: safe even if WriteTo is called more than once on the same builder instance.
        if this.Payload.Contains('CompanyAddressLines') then
            this.Payload.Replace('CompanyAddressLines', this.AddressLines)
        else
            this.Payload.Add('CompanyAddressLines', this.AddressLines);
        foreach KeyText in this.Payload.Keys() do begin
            this.Payload.Get(KeyText, JToken);
            if CompanyMetadata.Contains(KeyText) then
                CompanyMetadata.Replace(KeyText, JToken)
            else
                CompanyMetadata.Add(KeyText, JToken);
        end;
    end;

    local procedure Put(KeyText: Text; Value: Text)
    begin
        if this.Payload.Contains(KeyText) then
            this.Payload.Replace(KeyText, Value)
        else
            this.Payload.Add(KeyText, Value);
    end;
}
