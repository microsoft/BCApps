// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Environment.Configuration;

using Microsoft.Foundation.Company;

codeunit 9275 "My Settings"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure SetExperienceToEssential(SelectedProfileID: Text[30])
    var
        ExperienceTierSetup: Record "Experience Tier Setup";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        CompanyInformationMgt: Codeunit "Company Information Mgt.";
    begin
        if CompanyInformationMgt.IsDemoCompany() then
            if ExperienceTierSetup.Get(CompanyName) then
                if ExperienceTierSetup.Basic then
                    if (SelectedProfileID = TeamMemberTxt) or
                       (SelectedProfileID = AccountantTxt) or
                       (SelectedProfileID = ProjectManagerTxt)
                    then begin
                        Message(ExperienceMsg);
                        ApplicationAreaMgmtFacade.SaveExperienceTierCurrentCompany(ExperienceTierSetup.FieldCaption(Essential));
                    end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"User Settings", 'OnUpdateUserSettings', '', false, false)]
    local procedure OnUpdateUserSettings(OldSettings: Record "User Settings"; NewSettings: Record "User Settings")
    begin
        if OldSettings."Profile ID" <> NewSettings."Profile ID" then
            SetExperienceToEssential(NewSettings."Profile ID");
    end;

    var
        AccountantTxt: Label 'ACCOUNTANT', Comment = 'Please translate all caps';
        ProjectManagerTxt: Label 'PROJECT MANAGER', Comment = 'Please translate all caps';
        TeamMemberTxt: Label 'TEAM MEMBER', Comment = 'Please translate all caps';
        ExperienceMsg: Label 'You are changing to a Role Center that has more functionality. To display the full functionality for this role, your Experience setting will be set to Essential.';
}
