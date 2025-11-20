namespace System.Security.User;

using System.Visualization;
using System.Security.AccessControl;

/// <summary>
/// Modifies the behavior of security group factboxes on the user card for better performance.
/// </summary>
pageextension 9807 "User Card Perf. Factboxes" extends "User Card"
{
    layout
    {
        addbefore("Inherited Permission Sets")
        {
            part("Inherited Permission Sets Loading"; "Loading View Part")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Permission Sets from Security Groups';
                Visible = AreLoadingFactboxesVisible;
            }
            part("User Security Groups Loading"; "Loading View Part")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Security Group Memberships';
                Visible = AreLoadingFactboxesVisible;
            }
        }
        modify("Inherited Permission Sets")
        {
            Visible = AreFactboxesVisible;
        }
        modify("User Security Groups")
        {
            Visible = AreFactboxesVisible;
        }
        modify("Windows User Name")
        {
            trigger OnAfterValidate()
            begin
                // "User Security Groups" part is updated as part of this refresh as well
                CurrPage."Inherited Permission Sets".Page.Refresh();
            end;
        }
    }

    trigger OnOpenPage()
    var
        SecurityGroupMemberBufferSourceRec: Record "Security Group Member Buffer";
        UserPermissions: Codeunit "User Permissions";
    begin
        CanManageUsersOnTenant := UserPermissions.CanManageUsersOnTenant(UserSecurityId());

        if UserSecurityGroupsPBT.IsFetchingGroupsPerUserAvailable() then begin
            // When using Entra groups, skip loading data inside the parts and just show the loading text, as the data will be added by a page background task.
            CurrPage."User Security Groups".Page.SetInitializedByCaller();
            CurrPage."Inherited Permission Sets".Page.SetInitializedByCaller();
        end else begin
            // When using Windows groups, set "User Security Groups" to refresh as part of "Inherited Permission Sets" refresh (to avoid fetching security group memberships twice).
            CurrPage."User Security Groups".Page.GetSourceRecord(SecurityGroupMemberBufferSourceRec);
            CurrPage."Inherited Permission Sets".Page.SetRecordToRefresh(SecurityGroupMemberBufferSourceRec);
        end;
    end;

    trigger OnAfterGetCurrRecord()
    var
        Parameters: Dictionary of [Text, Text];
        Skip: Boolean;
    begin
        IsOwnUser := Rec."User Security ID" = UserSecurityId();
        if not UserSecurityGroupsPBT.ShouldEnqueueBackgroundTask(Rec, Parameters) then begin
            UpdateVisibility(true);
            exit;
        end;

        UpdateVisibility(false);

        UserSecurityGroupsPBT.OnBeforeEnqueueBackgroundTask(Skip);
        if Skip then
            exit;

        CurrPage.EnqueueBackgroundTask(SecurityGroupTaskId, Codeunit::"User Security Groups PBT", Parameters);
    end;

    trigger OnPageBackgroundTaskCompleted(TaskId: Integer; Results: Dictionary of [Text, Text])
    begin
        if SecurityGroupTaskId <> TaskId then
            exit;

        RefreshFactboxes(Results);
    end;

    internal procedure RefreshFactboxes(Results: Dictionary of [Text, Text])
    var
        ResultsSecurityGroupMemberBuffer: Record "Security Group Member Buffer";
    begin
        UpdateVisibility(true);

        if not UserSecurityGroupsPBT.GetSecurityGroupMemberBuffer(Results, ResultsSecurityGroupMemberBuffer) then
            exit;

        CurrPage."User Security Groups".Page.Refresh(ResultsSecurityGroupMemberBuffer);
        CurrPage."Inherited Permission Sets".Page.Refresh(ResultsSecurityGroupMemberBuffer);
    end;

    local procedure UpdateVisibility(IsDataForCurrentUserReady: Boolean)
    begin
        AreFactboxesVisible := (CanManageUsersOnTenant or IsOwnUser) and IsDataForCurrentUserReady;
        AreLoadingFactboxesVisible := (CanManageUsersOnTenant or IsOwnUser) and (not IsDataForCurrentUserReady);
        CurrPage.Update(false);
    end;

    var
        UserSecurityGroupsPBT: Codeunit "User Security Groups PBT";
        CanManageUsersOnTenant: Boolean;
        IsOwnUser: Boolean;
        AreFactboxesVisible: Boolean;
        AreLoadingFactboxesVisible: Boolean;
        SecurityGroupTaskId: Integer;
}