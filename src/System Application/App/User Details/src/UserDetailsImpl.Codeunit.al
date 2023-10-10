// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.User;
using System.Security.AccessControl;
using System.Azure.Identity;

codeunit 775 "User Details Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure GetUserDetails(var UserDetails: Record "User Details")
    var
        User: Record User;
        LocalUserDetails: Record "User Details";
    begin
        LocalUserDetails.Copy(UserDetails, true);
        LocalUserDetails.Reset();
        LocalUserDetails.DeleteAll();

        User.SetRange("License Type", User."License Type"::"Full User");
        if User.FindSet() then
            repeat
                UserDetails."User Security ID" := User."User Security ID";
                FillInUserDetails(UserDetails);
                UserDetails.Insert();
            until User.Next() = 0;
    end;

    local procedure FillInUserDetails(var UserDetails: Record "User Details")
    var
        AzureADUserManagement: Codeunit "Azure AD User Management";
        PlanIds: Codeunit "Plan Ids";
        AzureADPlan: Codeunit "Azure AD Plan";
        UsersInPlans: Query "Users in Plans";
        UserPlansTextBuilder: TextBuilder;
    begin
        UsersInPlans.SetRange(User_Security_ID, UserDetails."User Security ID");
        if UsersInPlans.Open() then
            while UsersInPlans.Read() do begin
                UserPlansTextBuilder.Append(UsersInPlans.Plan_Name);
                UserPlansTextBuilder.Append(' ; ');
            end;

        UserDetails."User Plans" := CopyStr(UserPlansTextBuilder.ToText().TrimEnd(' ; '), 1, MaxStrLen(UserDetails."User Plans"));
        UserDetails."Is Delegated" := AzureADUserManagement.IsUserDelegated(UserDetails."User Security ID");
        UserDetails."Has M365 Plan" := AzureADPlan.IsPlanAssignedToUser(PlanIds.GetMicrosoft365PlanId(), UserDetails."User Security ID");

        UsersInPlans.SetFilter(Plan_Name, '*Essential*');
        UserDetails."Has Essential Plan" := UsersInPlans.Open() and UsersInPlans.Read();

        UsersInPlans.SetFilter(Plan_Name, '*Premium*');
        UserDetails."Has Premium Plan" := UsersInPlans.Open() and UsersInPlans.Read();

        UserDetails."Has Essential Or Premium Plan" := UserDetails."Has Essential Plan" or UserDetails."Has Premium Plan";
    end;
}