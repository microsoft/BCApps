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

    var
        Payload: JsonObject;
        AddressLines: JsonArray;

    procedure SetName(Value: Text)
    begin
        Put('CompanyName', Value);
    end;

    procedure SetDisplayName(Value: Text)
    begin
        Put('CompanyDisplayName', Value);
    end;

    procedure AddAddressLine(Value: Text)
    begin
        // Empty lines are skipped by the platform repeater, but keep the array clean here too.
        if Value <> '' then
            AddressLines.Add(Value);
    end;

    procedure SetPhone(Value: Text)
    begin
        Put('CompanyPhone', Value);
    end;

    procedure SetPhoneCaption(Value: Text)
    begin
        Put('CompanyPhoneCaption', Value);
    end;

    procedure SetFaxNo(Value: Text)
    begin
        Put('CompanyFaxNo', Value);
    end;

    procedure SetFaxNoCaption(Value: Text)
    begin
        Put('CompanyFaxNoCaption', Value);
    end;

    procedure SetEmail(Value: Text)
    begin
        Put('CompanyEmail', Value);
    end;

    procedure SetEmailCaption(Value: Text)
    begin
        Put('CompanyEmailCaption', Value);
    end;

    procedure SetHomePage(Value: Text)
    begin
        Put('CompanyHomePage', Value);
    end;

    procedure SetHomePageCaption(Value: Text)
    begin
        Put('CompanyHomePageCaption', Value);
    end;

    procedure SetLogo(Base64Value: Text)
    begin
        Put('CompanyLogo', Base64Value);
    end;

    procedure SetVATRegistrationNo(Value: Text)
    begin
        Put('CompanyVATRegistrationNo', Value);
    end;

    procedure SetVATRegistrationNoCaption(Value: Text)
    begin
        Put('CompanyVATRegistrationNoCaption', Value);
    end;

    procedure SetRegistrationNo(Value: Text)
    begin
        Put('CompanyRegistrationNo', Value);
    end;

    procedure SetRegistrationNoCaption(Value: Text)
    begin
        Put('CompanyRegistrationNoCaption', Value);
    end;

    procedure SetBankName(Value: Text)
    begin
        Put('CompanyBankName', Value);
    end;

    procedure SetBankNameCaption(Value: Text)
    begin
        Put('CompanyBankNameCaption', Value);
    end;

    procedure SetBankAccountNo(Value: Text)
    begin
        Put('CompanyBankAccountNo', Value);
    end;

    procedure SetBankAccountNoCaption(Value: Text)
    begin
        Put('CompanyBankAccountNoCaption', Value);
    end;

    procedure SetBankBranchNo(Value: Text)
    begin
        Put('CompanyBankBranchNo', Value);
    end;

    procedure SetBankBranchNoCaption(Value: Text)
    begin
        Put('CompanyBankBranchNoCaption', Value);
    end;

    procedure SetIBAN(Value: Text)
    begin
        Put('CompanyIBAN', Value);
    end;

    procedure SetIBANCaption(Value: Text)
    begin
        Put('CompanyIBANCaption', Value);
    end;

    procedure SetBankSWIFT(Value: Text)
    begin
        Put('CompanyBankSWIFT', Value);
    end;

    procedure SetBankSWIFTCaption(Value: Text)
    begin
        Put('CompanyBankSWIFTCaption', Value);
    end;

    procedure SetGiroNo(Value: Text)
    begin
        Put('CompanyGiroNo', Value);
    end;

    procedure SetGiroNoCaption(Value: Text)
    begin
        Put('CompanyGiroNoCaption', Value);
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
        Payload.Add('CompanyAddressLines', AddressLines);
        foreach KeyText in Payload.Keys() do begin
            Payload.Get(KeyText, JToken);
            if CompanyMetadata.Contains(KeyText) then
                CompanyMetadata.Replace(KeyText, JToken)
            else
                CompanyMetadata.Add(KeyText, JToken);
        end;
    end;

    local procedure Put(KeyText: Text; Value: Text)
    begin
        if Payload.Contains(KeyText) then
            Payload.Replace(KeyText, Value)
        else
            Payload.Add(KeyText, Value);
    end;
}
