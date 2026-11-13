// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.AuditCodes;

using Microsoft.Foundation.Company;

codeunit 12102 "Business Activity Code Mgt."
{
    /// <summary>
    /// Validates a nonempty business activity code using the validator selected for the company's country or region.
    /// </summary>
    /// <param name="Code">The business activity code to validate. Empty codes are accepted without validation.</param>
    procedure Validate(Code: Code[10])
    var
        CompanyInformation: Record "Company Information";
        BusActivityValidatorDef: Codeunit "Bus. Activity Validator Def.";
        BusinessActivityValidator: Interface "Business Activity Validator";
        IsHandled: Boolean;
    begin
        if Code = '' then
            exit;

        CompanyInformation.SetLoadFields("Country/Region Code");
        CompanyInformation.Get();
        IsHandled := false;
        OnBeforeValidate(CompanyInformation."Country/Region Code", BusinessActivityValidator, IsHandled);
        if not IsHandled then
            BusinessActivityValidator := BusActivityValidatorDef;

        BusinessActivityValidator.Validate(Code);
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnBeforeValidate(CountryRegionCode: Code[10]; var BusinessActivityValidator: Interface "Business Activity Validator"; var IsHandled: Boolean)
    begin
    end;
}