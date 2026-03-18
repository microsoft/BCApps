namespace System.Security.AccessControl;

using System;
using System.Azure.Identity;

/// <summary>
/// Gets Microsoft Entra security groups when run from a page background task.
/// </summary>
codeunit 9874 "User Security Groups PBT"
{
    Access = Internal;

    var
        SecurityGroupMemberBuffer: Record "Security Group Member Buffer";
        UserIdsWithFetchedGroups: Dictionary of [Guid, Boolean];

    trigger OnRun()
    var
        Results: Dictionary of [Text, Text];
    begin
        Results := GetBackgroundTaskResult(Page.GetBackgroundParameters());
        Page.SetBackgroundTaskResult(Results);
    end;

    procedure GetBackgroundTaskResult(Parameters: Dictionary of [Text, Text]): Dictionary of [Text, Text]
    var
        Results: Dictionary of [Text, Text];
        UserSecurityIdValue: Guid;
    begin
        UserSecurityIdValue := Parameters.Get(GetUserSecurityIdParameterKey());
        Results := FetchEntraGroups(UserSecurityIdValue);
        Results.Add(GetUserSecurityIdParameterKey(), UserSecurityIdValue);
        exit(Results);
    end;

    local procedure FetchEntraGroups(UserSecId: Guid): Dictionary of [Text, Text]
    var
        AzureADGraphUser: Codeunit "Azure AD Graph User";
        UserSecurityGroups: Dictionary of [Text, Text];
        GraphUserInfo: DotNet UserInfo;
        GroupInfo: DotNet GroupInfo;
    begin
        if not AzureADGraphUser.GetGraphUser(UserSecId, true, GraphUserInfo) then
            // User cannot be found in Microsoft Entra
            exit(UserSecurityGroups);

        if IsNull(GraphUserInfo.Groups()) then
            exit(UserSecurityGroups);

        foreach GroupInfo in GraphUserInfo.Groups() do
            UserSecurityGroups.Add(GroupInfo.ObjectId(), GroupInfo.DisplayName());

        exit(UserSecurityGroups);
    end;

    procedure ShouldEnqueueBackgroundTask(User: Record User; var Parameters: Dictionary of [Text, Text]): Boolean
    begin
        if User.State = User.State::Disabled then
            exit(false);

        if not IsFetchingGroupsPerUserAvailable() then
            exit(false);

        if not IsAnySecurityGroupPresent() then
            exit(false);

        if not ShouldFetchUserMemberships(User."User Security ID") then
            exit(false);

        Parameters.Set(GetUserSecurityIdParameterKey(), user."User Security ID");
        exit(true);
    end;

    procedure IsFetchingGroupsPerUserAvailable(): Boolean
    var
        SecurityGroup: Codeunit "Security Group";
    begin
        exit(not SecurityGroup.IsWindowsAuthentication());
    end;

    procedure GetSecurityGroupMemberBuffer(Results: Dictionary of [Text, Text]; var ResultsSecurityGroupMemberBuffer: Record "Security Group Member Buffer"): Boolean
    var
        SecurityGroup: Codeunit "Security Group";
        GroupId: Text;
        GroupCode: Code[20];
        UserSecId: Guid;
    begin
        UserSecId := Results.Get(GetUserSecurityIdParameterKey());
        Results.Remove(GetUserSecurityIdParameterKey());

        if not ShouldFetchUserMemberships(UserSecId) then
            exit(false);

        SetUserMembershipsFetched(UserSecId);

        foreach GroupId in Results.Keys() do
            if SecurityGroup.GetCode(GroupId, GroupCode) then begin
                SecurityGroupMemberBuffer."Security Group Code" := GroupCode;
                SecurityGroupMemberBuffer."User Security ID" := UserSecId;
                SecurityGroupMemberBuffer."Security Group Name" := Results.Get(GroupId);
                SecurityGroupMemberBuffer.Insert();
            end;

        ResultsSecurityGroupMemberBuffer.Copy(SecurityGroupMemberBuffer, true);
        exit(true);
    end;

    local procedure IsAnySecurityGroupPresent(): Boolean
    var
        SecurityGroupBuffer: Record "Security Group Buffer";
        SecurityGroup: Codeunit "Security Group";
    begin
        SecurityGroup.GetGroups(SecurityGroupBuffer, false);
        exit(not SecurityGroupBuffer.IsEmpty());
    end;

    local procedure ShouldFetchUserMemberships(UserSecId: Guid): Boolean
    begin
        exit(not UserIdsWithFetchedGroups.ContainsKey(UserSecId));
    end;

    local procedure SetUserMembershipsFetched(UserSecId: Guid)
    begin
        UserIdsWithFetchedGroups.Set(UserSecId, true);
    end;

    procedure GetUserSecurityIdParameterKey(): Text
    begin
        exit('UserSecurityId');
    end;

    [InternalEvent(false)]
    procedure OnBeforeEnqueueBackgroundTask(var Skip: Boolean)
    begin
    end;
}