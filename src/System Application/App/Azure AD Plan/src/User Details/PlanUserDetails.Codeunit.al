// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Azure.Identity;

using System.Security.User;

codeunit 776 "Plan User Details"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"User Details", 'OnAddUserDetails', '', false, false)]
    local procedure AddPlanUserDetails(UserSecId: Guid; var UserDetails: Record "User Details")
    var
        PlanIds: Codeunit "Plan Ids";
        AzureADPlan: Codeunit "Azure AD Plan";
        UsersInPlans: Query "Users in Plans";
        UserPlansTextBuilder: TextBuilder;
    begin
        UsersInPlans.SetRange(User_Security_ID, UserSecId);
        if UsersInPlans.Open() then
            while UsersInPlans.Read() do begin
                UserPlansTextBuilder.Append(UsersInPlans.Plan_Name);
                UserPlansTextBuilder.Append(' ; ');
            end;

        UserDetails."User Plans" := CopyStr(UserPlansTextBuilder.ToText().TrimEnd(' ; '), 1, MaxStrLen(UserDetails."User Plans"));
        UserDetails."Is Delegated" := AzureADPlan.IsPlanAssignedToUser(PlanIds.GetDelegatedAdminPlanId(), UserSecId) or
                                      AzureADPlan.IsPlanAssignedToUser(PlanIds.GetHelpDeskPlanId(), UserSecId) or
                                      AzureADPlan.IsPlanAssignedToUser(PlanIds.GetD365AdminPartnerPlanId(), UserSecId) or
                                      AzureADPlan.IsPlanAssignedToUser(PlanIds.GetDelegatedBCAdminPlanId(), UserSecId);

        UserDetails."Has M365 Plan" := AzureADPlan.IsPlanAssignedToUser(PlanIds.GetMicrosoft365PlanId(), UserSecId);

        UsersInPlans.SetFilter(Plan_Name, '*Essential*');
        UserDetails."Has Essential Plan" := UsersInPlans.Open() and UsersInPlans.Read();

        UsersInPlans.SetFilter(Plan_Name, '*Premium*');
        UserDetails."Has Premium Plan" := UsersInPlans.Open() and UsersInPlans.Read();

        UserDetails."Has Essential Or Premium Plan" := UserDetails."Has Essential Plan" or UserDetails."Has Premium Plan";
    end;
}