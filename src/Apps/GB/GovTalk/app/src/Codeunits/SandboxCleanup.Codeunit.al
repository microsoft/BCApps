// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.GovTalk;

using System.DataAdministration;

#pragma warning disable AA0247
codeunit 10585 "Sandbox Cleanup"
{

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Environment Cleanup", 'OnClearCompanyConfig', '', false, false)]
    local procedure OnClearConfiguration(CompanyName: Text; SourceEnv: Enum "Environment Type"; DestinationEnv: Enum "Environment Type")
    var
        GovTalkSetup: Record "Gov Talk Setup";
        nullGUID: Guid;
    begin
        if CompanyName() <> CompanyName then
            GovTalkSetup.ChangeCompany(CompanyName);

        GovTalkSetup.ModifyAll(Password, nullGUID);
        Session.LogSecurityAudit(GovTalkServiceNameTxt, SecurityOperationResult::Success, StrSubstNo(SecurityAuditSandboxWipedTxt, CompanyName), AuditCategory::UserManagement);
    end;

    var
        GovTalkServiceNameTxt: Label 'GovTalk', Locked = true;
        SecurityAuditSandboxWipedTxt: Label 'GovTalk service passwords were cleared for all users in company %1 as part of environment cleanup.', Locked = true, Comment = '%1 - company name';
}

