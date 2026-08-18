// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

codeunit 13918 "E-Doc. Import Subscribers DE"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"E-Document Import Helper", OnGetReceivingCompanyRegistrationNo, '', false, false)]
    local procedure GetReceivingCompanyRegistrationNo(EDocument: Record "E-Document"; var ReceivingCompanyRegistrationNo: Text[20])
    begin
        ReceivingCompanyRegistrationNo := EDocument."Receiving Company Reg. No. DE";
    end;
}