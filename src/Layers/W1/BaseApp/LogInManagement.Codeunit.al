// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Environment;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Inventory.Item;
using Microsoft.Projects.TimeSheet;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.Azure.Identity;
using System.Environment.Configuration;
using System.Globalization;
using System.Security.AccessControl;
using System.Security.User;
using System.Reflection;

codeunit 40 LogInManagement
{
    Permissions = TableData "Company Information" = r,
                  TableData "G/L Entry" = r,
                  TableData "General Ledger Setup" = r,
                  TableData Customer = r,
                  TableData Vendor = r,
                  TableData Item = r,
                  TableData User = r,
                  TableData "User Personalization" = rm,
                  TableData "User Time Register" = rimd,
                  TableData "My Customer" = rimd,
                  TableData "My Vendor" = rimd,
                  TableData "My Item" = rimd,
                  TableData "My Account" = rimd,
                  TableData "Windows Language" = r;
    SingleInstance = true;
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
    end;

    var
        PasswordChangeNeededErr: Label 'You must change the password before you can continue.';
        GLSetup: Record "General Ledger Setup";
        [SecurityFiltering(SecurityFilter::Filtered)]
        User: Record User;
        LogInWorkDate: Date;
        LogInDate: Date;
        LogInTime: Time;
        GLSetupRead: Boolean;

    [Scope('OnPrem')]
    procedure CompanyOpen()
    var
        ClientTypeManagement: Codeunit "Client Type Management";
        AzureADPlan: Codeunit "Azure AD Plan";
        ExperienceTier: Codeunit "Experience Tier";
        CurrentDate: Date;
    begin
        OnShowTermsAndConditions();

        if GuiAllowed and (ClientTypeManagement.GetCurrentClientType() <> ClientType::Background) then
            LogInStart();

        if ClientTypeManagement.GetCurrentClientType() in [ClientType::Api, ClientType::ODataV4] then
            if GetCurrentDateInUserTimeZone(CurrentDate) then
                WorkDate := CurrentDate;

        if AzureADPlan.CheckMixedPlansExist() then
            ExperienceTier.CheckExperienceTier();
    end;

    procedure CompanyClose()
    var
        ClientTypeManagement: Codeunit "Client Type Management";
    begin
        OnBeforeCompanyClose();
        if GuiAllowed or (ClientTypeManagement.GetCurrentClientType() in [ClientType::Web, ClientType::Phone, ClientType::Tablet]) then
            LogInEnd();
        OnAfterCompanyClose();
    end;

    local procedure LogInStart()
    var
        Language: Record "Windows Language";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        IdentityManagement: Codeunit "Identity Management";
        LanguageManagement: Codeunit Language;
    begin
        Language.SetRange("Localization Exist", true);
        Language.SetRange("Globally Enabled", true);
        Language."Language ID" := GlobalLanguage;

        if not Language.Find() then begin
            Language."Language ID" := WindowsLanguage();
            if not Language.Find() then
                Language."Language ID" := LanguageManagement.GetDefaultApplicationLanguageId();
        end;
        GlobalLanguage := Language."Language ID";

        // Check if the logged in user must change login before allowing access.
        if not User.IsEmpty() then begin
            if IdentityManagement.IsUserNamePasswordAuthentication() then begin
                User.SetRange("User Security ID", UserSecurityId());
                User.FindFirst();
                if User."Change Password" then begin
                    REPORT.Run(REPORT::"Change Password");
                    SelectLatestVersion();
                    User.FindFirst();
                    if User."Change Password" then
                        Error(PasswordChangeNeededErr);
                end;
            end;

            User.SetRange("User Security ID");
        end;

        UpdateUserPersonalization();

        LogInDate := Today;
        LogInTime := Time;
        LogInWorkDate := 0D;

        WorkDate := GetDefaultWorkDate();

        ApplicationAreaMgmtFacade.SetupApplicationArea();
    end;

    local procedure LogInEnd()
    var
        UserSetup: Record "User Setup";
        UserTimeRegister: Record "User Time Register";
        LogOutDate: Date;
        LogOutTime: Time;
        Minutes: Integer;
        UserSetupFound: Boolean;
        RegisterTime: Boolean;
    begin
        OnBeforeLogInEnd(LogInDate, LogInTime);

        if LogInDate = 0D then
            exit;

        if LogInWorkDate <> 0D then
            if LogInWorkDate = LogInDate then
                WorkDate := Today
            else
                WorkDate := LogInWorkDate;

        if UserId <> '' then begin
            if UserSetup.Get(UserId) then begin
                UserSetupFound := true;
                RegisterTime := UserSetup."Register Time";
                OnLogInEndOnAfterGetUserSetupRegisterTime(UserSetup);
            end;
            if not UserSetupFound then
                if GetGLSetup() then
                    RegisterTime := GLSetup."Register Time";
            if RegisterTime then begin
                LogOutDate := Today;
                LogOutTime := Time;
                if (LogOutDate > LogInDate) or (LogOutDate = LogInDate) and (LogOutTime > LogInTime) then
                    Minutes := Round((1440 * (LogOutDate - LogInDate)) + ((LogOutTime - LogInTime) / 60000), 1);
                if Minutes = 0 then
                    Minutes := 1;
                UserTimeRegister.Init();
                UserTimeRegister."User ID" := CopyStr(UserId(), 1, MaxStrLen(UserTimeRegister."User ID"));
                UserTimeRegister.Date := LogInDate;
                UserTimeRegister.LockTable();
                if UserTimeRegister.Find() then begin
                    UserTimeRegister.Minutes := UserTimeRegister.Minutes + Minutes;
                    OnLoginEndOnBeforeModify(UserTimeRegister, LogOutTime, LogOutDate);
                    UserTimeRegister.Modify();
                end else begin
                    UserTimeRegister.Minutes := Minutes;
                    OnLoginEndOnBeforeInsert(UserTimeRegister, LogInTime, LogOutTime, LogOutDate);
                    UserTimeRegister.Insert();
                end;
            end;
        end;
    end;

    local procedure GetGLSetup(): Boolean
    begin
        if not GLSetupRead then
            GLSetupRead := GLSetup.Get();
        exit(GLSetupRead);
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"G/L Entry", 'r')]
    procedure GetDefaultWorkDate(): Date
    var
        GLEntry: Record "G/L Entry";
        CompanyInformationMgt: Codeunit "Company Information Mgt.";
    begin
        if CompanyInformationMgt.IsDemoCompany() then begin
            GLEntry.SetCurrentKey("Posting Date");
            GLEntry.SecurityFiltering(SecurityFilter::Ignored);
            if GLEntry.FindLast() then begin
                LogInWorkDate := NormalDate(GLEntry."Posting Date");
                exit(NormalDate(GLEntry."Posting Date"));
            end;
        end;

        exit(WorkDate());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"UI Helper Triggers", 'GetSystemIndicator', '', false, false)]
    local procedure OnGetSystemIndicator(var Text: Text[250]; var Style: Option Standard,Accent1,Accent2,Accent3,Accent4,Accent5,Accent6,Accent7,Accent8,Accent9)
    begin
        GetSystemIndicator(Text, Style);
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Company Information", 'r')]
    [InherentPermissions(PermissionObjectType::Table, Database::"Company Information", 'X')]
    local procedure GetSystemIndicator(var Text: Text[250]; var Style: Option Standard,Accent1,Accent2,Accent3,Accent4,Accent5,Accent6,Accent7,Accent8,Accent9)
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.SetLoadFields("System Indicator", "System Indicator Style", "Custom System Indicator Text");
        if CompanyInformation.Get() then;
        CompanyInformation.GetSystemIndicator(Text, Style);
    end;

    local procedure UpdateUserPersonalization()
    var
        UserPersonalization: Record "User Personalization";
        AllProfile: Record "All Profile";
        AllObjWithCaption: Record AllObjWithCaption;
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        if not UserPersonalization.Get(UserSecurityId()) then
            exit;

        if AllProfile.Get(UserPersonalization.Scope, UserPersonalization."App ID", UserPersonalization."Profile ID") then begin
            AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Page);
            AllObjWithCaption.SetRange("Object Subtype", 'RoleCenter');
            AllObjWithCaption.SetRange("Object ID", AllProfile."Role Center ID");
            if AllObjWithCaption.IsEmpty() then begin
                Clear(UserPersonalization."Profile ID");
                Clear(UserPersonalization."App ID");
                Clear(UserPersonalization.Scope);
                UserPersonalization.Modify();
                Commit();
            end;
        end else
            if EnvironmentInfo.IsSaaS() then begin
                AllProfile.Reset();
                ConfPersonalizationMgt.GetDefaultProfileID(UserSecurityId(), AllProfile);

                if not AllProfile.IsEmpty() then begin
                    UserPersonalization."Profile ID" := AllProfile."Profile ID";
                    UserPersonalization.Scope := AllProfile.Scope;
                    UserPersonalization."App ID" := AllProfile."App ID";
                    UserPersonalization.Modify();
                end else begin
                    Clear(UserPersonalization."Profile ID");
                    Clear(UserPersonalization."App ID");
                    Clear(UserPersonalization.Scope);
                    UserPersonalization.Modify();
                end;
            end;
    end;

    [TryFunction]
    local procedure GetCurrentDateInUserTimeZone(var CurrentDate: Date)
    var
        TypeHelper: Codeunit "Type Helper";
    begin
        CurrentDate := DT2Date(TypeHelper.GetCurrentDateTimeInUserTimeZone());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterInitialization', '', false, false)]
    local procedure OnCompanyOpen()
    begin
        CompanyOpen();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company Triggers", 'OnCompanyClose', '', false, false)]
    local procedure OnCompanyClose()
    begin
        CompanyClose();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCompanyClose()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCompanyClose()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLogInEndOnAfterGetUserSetupRegisterTime(var UserSetup: Record "User Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowTermsAndConditions()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLoginEndOnBeforeModify(var UserTimeRegister: Record "User Time Register"; LogOutTime: Time; LogOutDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLoginEndOnBeforeInsert(var UserTimeRegister: Record "User Time Register"; LogInTime: Time; LogOutTime: Time; LogOutDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLogInEnd(var LogInDate: Date; var LogInTime: Time)
    begin
    end;
}
