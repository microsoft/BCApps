// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

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
