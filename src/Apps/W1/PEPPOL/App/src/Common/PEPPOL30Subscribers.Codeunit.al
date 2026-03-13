// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

using Microsoft.Foundation.Company;

codeunit 37217 "PEPPOL 3.0 Subscribers"
{
    InherentEntitlements = X;
    InherentPermissions = X;
    Access = Internal;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company-Initialize", OnCompanyInitialize, '', false, false)]
    local procedure CompanyInitialize_OnAfterInitElectronicFormats()
    var
        PEPPOL30Initialize: Codeunit "PEPPOL30 Initialize";
    begin
        PEPPOL30Initialize.CreateElectronicDocumentFormats();
    end;



}