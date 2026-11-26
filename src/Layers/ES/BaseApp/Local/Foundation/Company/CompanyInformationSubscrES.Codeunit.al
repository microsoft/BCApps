// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Company;

#pragma warning disable AS0088
codeunit 7000099 "Company Information Subscr. ES"
{
    [EventSubscriber(ObjectType::Table, Database::"Company Information", 'OnAfterValidateName', '', true, false)]
    local procedure OnAfterValidateName(var CompanyInformation: Record "Company Information")
    begin
        CompanyInformation."Payment Days Code" := CopyStr(CompanyInformation.Name, 1, 10);
        CompanyInformation."Non-Paymt. Periods Code" := CopyStr(CompanyInformation.Name, 1, 10);
    end;
}
