// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Azure.Identity;

using System;
using System.Globalization;
using System.Telemetry;

codeunit 9034 "Azure AD User Subscribers"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    SingleInstance = true;

    var
        AzureADGraphUser: Codeunit "Azure AD Graph User";
        AzureADGraph: Codeunit "Azure AD Graph";
        AzureADPlan: Codeunit "Azure AD Plan";
        Initialized, IsAzure, IsAdmin : Boolean;
        CountryCode: Text;

    local procedure GetInformation()
    var
        PlanIds: Codeunit "Plan Ids";
        UserAccountHelper: DotNet NavUserAccountHelper;
    begin
        if Initialized then
            exit;
        Initialized := true;

        IsAzure := UserAccountHelper.IsAzure();
        if not IsAzure then
            exit;

        IsAdmin := AzureADGraphUser.IsUserDelegatedAdmin() or AzureADPlan.IsPlanAssignedToUser(PlanIds.GetGlobalAdminPlanId()) or AzureADPlan.IsPlanAssignedToUser(PlanIds.GetD365AdminPlanId());
        if TryGetCountryCode() then;
    end;

    [TryFunction]
    local procedure TryGetCountryCode()
    var
        TenantInfo: DotNet TenantInfo;
    begin
        AzureADGraph.GetTenantDetail(TenantInfo);
        if not IsNull(TenantInfo) then
            CountryCode := TenantInfo.CountryLetterCode();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Telemetry Custom Dimensions", OnAddCommonCustomDimensions, '', true, true)]
    local procedure OnAddCommonCustomDimensions(var Sender: Codeunit "Telemetry Custom Dimensions")
    var
        Language: Codeunit Language;
    begin
        GetInformation();

        if not IsAzure then
            exit;

        // Add IsAdmin
        Sender.AddCommonCustomDimension('IsAdmin', Language.ToDefaultLanguage(IsAdmin));

        // Add CountryCode
        if CountryCode <> '' then
            Sender.AddCommonCustomDimension('CountryCode', CountryCode);
    end;
}