// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using Microsoft.Foundation.Company;

codeunit 13916 "E-Doc. Import Subscribers DE"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"E-Document Import Helper", OnBeforeValidateReceivingCompanyInfo, '', false, false)]
    local procedure ValidateReceivingCompanyInfoByRegistrationNo(EDocument: Record "E-Document"; var IsHandled: Boolean)
    var
        CompanyInformation: Record "Company Information";
        EDocumentErrorHelper: Codeunit "E-Document Error Helper";
        InvalidCompanyRegistrationNoErr: Label 'The receiving company registration number %1 does not match Company Information.', Comment = '%1 = Registration No.';
    begin
        if EDocument."Receiving Company Reg. No. DE" = '' then
            exit;

        IsHandled := true;
        CompanyInformation.Get();
        if CompanyInformation."Registration No." <> EDocument."Receiving Company Reg. No. DE" then
            EDocumentErrorHelper.LogErrorMessage(
                EDocument, CompanyInformation, CompanyInformation.FieldNo("Registration No."),
                StrSubstNo(InvalidCompanyRegistrationNoErr, EDocument."Receiving Company Reg. No. DE"));
    end;
}