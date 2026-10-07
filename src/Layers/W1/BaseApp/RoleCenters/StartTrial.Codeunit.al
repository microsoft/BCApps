// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.RoleCenters;

using Microsoft.Finance.RoleCenters;
using System.Environment;
using System.Environment.Configuration;
using System.Reflection;

codeunit 1449 "Start Trial"
{
    Access = Public;

    trigger OnRun()
    begin
        StartTrial()
    end;

    local procedure StartTrial()
    var
        RoleCenterNotifications: Record "Role Center Notifications";
        RoleCenterNotificationMgt: Codeunit "Role Center Notification Mgt.";
        CompanyName: Text;
    begin
        if not FindNonEvaluationCompany(CompanyName) then
            error('');

        RoleCenterNotifications.SetEvaluationNotificationState(RoleCenterNotifications."Evaluation Notification State"::Clicked);
        Commit();
        RoleCenterNotificationMgt.DisableEvaluationNotification();
        ChangeCompanyAndRestartSession(CompanyName);
    end;

    local procedure ChangeCompanyAndRestartSession(CompanyName: Text)
    var
        SessionSetting: SessionSettings;
    begin
        SessionSetting.Init();
        SessionSetting.Company(CompanyName);
        SetProfileForNewSession(SessionSetting);
        SessionSetting.RequestSessionUpdate(true)
    end;

    local procedure FindNonEvaluationCompany(var CompanyName: Text): Boolean
    var
        Company: Record Company;
    begin
        Company.SetRange("Evaluation Company", false);

        if Company.FindFirst() then begin
            CompanyName := Company.Name;
            exit(true);
        end;

        exit(false);
    end;

    local procedure SetProfileForNewSession(var SessionSettings: SessionSettings)
    var
        UserPersonalization: Record "User Personalization";
        AllProfile: Record "All Profile";
    begin
        // if the user is starting the trial from an evaluation company where they were currently on the 'Business Manager Evaluation' 
        // role center, they should be redirected to the Business Manager role center in the production company
        if not UserPersonalization.Get(UserSecurityId()) then
            exit;

        if UserPersonalization."Profile ID" <> 'BUSINESS MANAGER EVALUATION' then
            exit;

        AllProfile.SetRange("Role Center ID", Page::"Business Manager Role Center");
        if AllProfile.FindFirst() then begin
            SessionSettings.ProfileId := AllProfile."Profile ID";
            SessionSettings.ProfileAppId := AllProfile."App ID";
#pragma warning disable AL0667
            SessionSettings.ProfileSystemScope := (AllProfile.Scope = AllProfile.Scope::System);
#pragma warning restore AL0667
        end;
    end;
}
