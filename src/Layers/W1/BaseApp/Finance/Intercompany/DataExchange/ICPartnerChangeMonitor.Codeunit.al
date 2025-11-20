// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.DataExchange;

using System.Security.User;
using System.Security.AccessControl;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Intercompany.Partner;
using Microsoft.Utilities;
using System.Telemetry;
using System.Environment;

codeunit 489 "IC Partner Change Monitor"
{

    local procedure HasSensitiveFieldsSet(var ICPartner: Record "IC Partner"): Boolean
    var
        SensitiveFieldsUsed: Boolean;
    begin
        SensitiveFieldsUsed := not (IsNullGuid(ICPartner."Token Endpoint Key") and
                                    IsNullGuid(ICPartner."Token Key") and
                                    IsNullGuid(ICPartner."Redirect Url key") and
                                    IsNullGuid(ICPartner."Client Secret Key") and
                                    IsNullGuid(ICPartner."Client Id Key") and
                                    IsNullGuid(ICPartner."Company Id Key") and
                                    IsNullGuid(ICPartner."Connection Url Key"));
        exit(SensitiveFieldsUsed);
    end;

    internal procedure CheckHasPermissionsToChangeSensitiveFields()
    var
        DummyAccessControl: Record "Access Control";
        UserPermissions: Codeunit "User Permissions";
        CurrentModuleInfo: ModuleInfo;
    begin
        if not GuiAllowed() then
            exit;

        if UserPermissions.IsSuper(UserSecurityId()) then
            exit;

        NavApp.GetCurrentModuleInfo(CurrentModuleInfo);
        if not UserPermissions.HasUserPermissionSetAssigned(UserSecurityId(), CompanyName(), ICCompanySetupPermissionSetNameTxt, DummyAccessControl.Scope::System, CurrentModuleInfo.Id) then
            Error(YouMustHaveICPartnerEditPermissionToChangeSensitiveFieldsErr, ICCompanySetupPermissionSetNameTxt);
    end;

    internal procedure RegisterActivity(var ICPartner: Record "IC Partner"; Context: Text[30]; ActivityDescription: Text; ActivityMessage: Text)
    var
        ActivityLog: Record "Activity Log";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
        EnvironmentInformation: Codeunit "Environment Information";
        CustomDimensions: Dictionary of [Text, Text];
    begin
        if not EnvironmentInformation.IsSaaSInfrastructure() then
            exit;

        if Context = InsertICPartnerContextTok then
            FeatureTelemetry.LogUptake('0000LKT', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up")
        else
            FeatureTelemetry.LogUptake('0000LKU', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Used);

        CustomDimensions.Add('Context', Context);
        CustomDimensions.Add('Activity Description', ActivityDescription);
        CustomDimensions.Add('Activity Message', ActivityMessage);
        FeatureTelemetry.LogUsage('0000LKV', ICMapping.GetFeatureTelemetryName(), ICCompanySetupPermissionSetNameTxt, CustomDimensions);
        ActivityLog.LogActivityForUser(ICPartner.RecordId, ActivityLog.Status::Success, Context, ActivityDescription, ActivityMessage, UserId);
        Session.LogSecurityAudit(Context, SecurityOperationResult::Success, (ActivityDescription + ActivityMessage), AuditCategory::UserManagement);
    end;

    var
        YouMustHaveICPartnerEditPermissionToChangeSensitiveFieldsErr: Label 'To modify sensitive Cross-Environment Setup values, you must be assigned the %1 or SUPER permission set.', Comment = '%1 - Name of permission set';
        ICCompanySetupPermissionSetNameTxt: Label 'D365 IC Partner Edit', Locked = true;
        InsertICPartnerContextTok: Label 'Insert new IC Partner', Locked = true;
        InsertICPartnerDescriptionTxt: Label 'A new IC Partner was inserted.';
        ModifyICPartnerContextTok: Label 'Modify IC Partner', Locked = true;
        ModifyICPartnerDescriptionTxt: Label 'Sensible fields in IC Partner were modified.';
        DeleteICPartnerContextTok: Label 'Delete IC Partner', Locked = true;
        DeleteICPartnerDescriptionTxt: Label 'An IC Partner was deleted.';
        ICPartnerDetailsTxt: Label 'IC Partner Code: %1, IC Partner System ID: %2.', Comment = '%1 = Code of IC Partner, %2 = System ID of the IC Partner';


    [EventSubscriber(ObjectType::Table, Database::"IC Partner", 'OnBeforeInsertEvent', '', false, false)]
    local procedure CheckPermissionsBeforeInsert(RunTrigger: Boolean; var Rec: Record "IC Partner")
    begin
        if Rec.IsTemporary() then
            exit;

        if HasSensitiveFieldsSet(Rec) then
            CheckHasPermissionsToChangeSensitiveFields();

        RegisterActivity(Rec, InsertICPartnerContextTok, InsertICPartnerDescriptionTxt, StrSubstNo(ICPartnerDetailsTxt, Rec.Code, Rec.SystemId));
    end;

    [EventSubscriber(ObjectType::Table, Database::"IC Partner", 'OnBeforeModifyEvent', '', false, false)]
    local procedure CheckPermissionsOnBeforeModifyEvent(RunTrigger: Boolean; var Rec: Record "IC Partner"; var xRec: Record "IC Partner")
    begin
        if HasSensitiveFieldsSet(Rec) then
            CheckHasPermissionsToChangeSensitiveFields();

        if HasSensitiveFieldsSet(xRec) then
            CheckHasPermissionsToChangeSensitiveFields();

        if not xRec.IsTemporary() then
            if not xRec.Find() then
                exit;

        if HasSensitiveFieldsSet(xRec) then begin
            CheckHasPermissionsToChangeSensitiveFields();
            RegisterActivity(Rec, ModifyICPartnerContextTok, ModifyICPartnerDescriptionTxt, StrSubstNo(ICPartnerDetailsTxt, Rec.Code, Rec.SystemId));
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"IC Partner", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure CheckPermissionsOnBeforeDeleteEvent(RunTrigger: Boolean; var Rec: Record "IC Partner")
    begin
        if HasSensitiveFieldsSet(Rec) then
            CheckHasPermissionsToChangeSensitiveFields();

        RegisterActivity(Rec, DeleteICPartnerContextTok, DeleteICPartnerDescriptionTxt, StrSubstNo(ICPartnerDetailsTxt, Rec.Code, Rec.SystemId));
    end;

    [EventSubscriber(ObjectType::Table, Database::"IC Partner", 'OnBeforeRenameEvent', '', false, false)]
    local procedure CheckPermissionsOnBeforeRenameEvent(RunTrigger: Boolean; var Rec: Record "IC Partner")
    begin
        if HasSensitiveFieldsSet(Rec) then
            CheckHasPermissionsToChangeSensitiveFields();
    end;
}
