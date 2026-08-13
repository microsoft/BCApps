// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.AuditCodes;

using Microsoft.Foundation.Company;

codeunit 12102 "Business Activity Code Mgt."
{
    procedure Validate(Code: Code[10])
    var
        CompanyInformation: Record "Company Information";
        BusinessActivityValidator: Interface "Business Activity Validator";
        BusActivityCodeValidatorDefault: Codeunit "Bus. Activity Validator Def.";
        IsHandled: Boolean;
    begin
        if Code = '' then
            exit;

        CompanyInformation.Get();
        OnGetValidator(CompanyInformation."Country/Region Code", BusinessActivityValidator, IsHandled);
        if not IsHandled then
            BusinessActivityValidator := BusActivityCodeValidatorDefault;

        BusinessActivityValidator.Validate(Code);
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnGetValidator(CountryRegionCode: Code[10]; var BusinessActivityValidator: Interface "Business Activity Validator"; var IsHandled: Boolean)
    begin
    end;
}