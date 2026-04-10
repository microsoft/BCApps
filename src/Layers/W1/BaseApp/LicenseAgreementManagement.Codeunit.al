// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft;

using Microsoft.Foundation.Company;
using System.Environment;

codeunit 853 "License Agreement Management"
{
    Permissions = tabledata "License Agreement" = r;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        PartnerAgreementNotAcceptedErr: Label 'Partner Agreement has not been accepted.';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LogInManagement", 'OnShowTermsAndConditions', '', false, false)]
    local procedure OnShowTermsAndConditionsSubscriber()
    var
        LicenseAgreement: Record "License Agreement";
        CompanyInformationMgt: Codeunit "Company Information Mgt.";
    begin
        if GuiAllowed then
            if not CompanyInformationMgt.IsDemoCompany() then
                if LicenseAgreement.Get() then
                    if LicenseAgreement.GetActive() and not LicenseAgreement.Accepted then begin
                        PAGE.RunModal(PAGE::"Additional Customer Terms");
                        LicenseAgreement.Get();
                        if not LicenseAgreement.Accepted then
                            Error(PartnerAgreementNotAcceptedErr)
                    end;
    end;
}

