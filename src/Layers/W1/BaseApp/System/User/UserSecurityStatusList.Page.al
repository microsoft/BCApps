namespace System.Security.User;

using System.Azure.Identity;
using System.Environment;
using System.Security.AccessControl;

page 9818 "User Security Status List"
{
    AccessByPermission = TableData User = R;
    ApplicationArea = Basic, Suite;
    Caption = 'User Security Status';
    Editable = false;
    LinksAllowed = false;
    PageType = List;
    RefreshOnActivate = true;
    ShowFilter = false;
    SourceTable = "User Security Status";
    SourceTableView = where("User Security ID" = filter(<> '{00000000-0000-0000-0000-000000000000}'), "User Exists" = const(true));
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("User Name"; Rec."User Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = not Rec.Reviewed;
                    ToolTip = 'Specifies the user''s name. If the user is required to present credentials when starting the client, this is the name that the user must present.';
                }
                field("Full Name"; Rec."Full Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the full name of the user.';
                }
                field(Reviewed; Rec.Reviewed)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if an administrator has reviewed this new user. When a new user is created, this field is empty to indicate that the user must be set up.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Belongs To Subscription Plan"; BelongsToSubscriptionPlan)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Style = Attention;
                    StyleExpr = not BelongsToSubscriptionPlan;
                    ToolTip = 'Specifies that the user is covered by a subscription plan.';
                    Visible = SoftwareAsAService;
                }
            }
        }
        area(factboxes)
        {
            part(Plans; "User Plan Members FactBox")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Plans';
                SubPageLink = "User Security ID" = field("User Security ID");
                Visible = SoftwareAsAService;
            }
            part("Security Groups"; "User Security Groups Part")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Security Groups';
                Editable = false;
                ShowFilter = false;
                SubPageLink = "User Security ID" = field("User Security ID");
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Get Users from Office 365")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Get Users from Office 365';
                Image = Users;
                ToolTip = 'Gets updated information about users from the Office portal.';
                Visible = SoftwareAsAService;

                trigger OnAction()
                var
                    AzureADUserManagement: Codeunit "Azure AD User Management";
                begin
                    AzureADUserManagement.CreateNewUsersFromAzureAD();
                    CurrPage.Update();
                end;
            }
            action("Set as reviewed")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Set as reviewed';
                Image = Approve;
                ToolTip = 'Set the Reviewed field to Yes for this user.';

                trigger OnAction()
                begin
                    ToggleReviewStatus(true);
                end;
            }
            action("Set as not reviewed")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Set as not reviewed';
                Image = Cancel;
                ToolTip = 'Set the Reviewed field to No for this user.';

                trigger OnAction()
                begin
                    ToggleReviewStatus(false);
                end;
            }
            action("Security Group Members")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Security Group Members';
                Image = Users;
                RunObject = Page "Security Group Members";
                RunPageMode = View;
                ToolTip = 'View the members of the security group.';
            }
            action("Manage plan assignments")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Manage plan assignments';
                Image = Reconcile;
                ToolTip = 'View or edit the user''s service plan.';
                Visible = SoftwareAsAService;

                trigger OnAction()
                var
                    PermissionManager: Codeunit "Permission Manager";
                begin
                    HyperLink(PermissionManager.GetOfficePortalUserAdminUrl());
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Get Users from Office 365_Promoted"; "Get Users from Office 365")
                {
                }
                actionref("Set as reviewed_Promoted"; "Set as reviewed")
                {
                }
                actionref("Set as not reviewed_Promoted"; "Set as not reviewed")
                {
                }
                actionref("Security Group Members_Promoted"; "Security Group Members")
                {
                }
                actionref("Manage plan assignments_Promoted"; "Manage plan assignments")
                {
                }
            }
        }
    }

    trigger OnInit()
    var
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        SoftwareAsAService := EnvironmentInfo.IsSaaS();
    end;

    trigger OnAfterGetRecord()
    var
        AzureADPlan: Codeunit "Azure AD Plan";
    begin
        BelongsToSubscriptionPlan := AzureADPlan.DoesUserHavePlans(Rec."User Security ID");
    end;

    local procedure ToggleReviewStatus(ReviewStatus: Boolean)
    var
        UserSecurityStatus: Record "User Security Status";
    begin
        CurrPage.SetSelectionFilter(UserSecurityStatus);
        if not UserSecurityStatus.FindSet() then
            exit;
        repeat
            UserSecurityStatus.Reviewed := ReviewStatus;
            UserSecurityStatus.Modify(true);
            UserSecurityStatus.LogUserReviewActivity();
        until UserSecurityStatus.Next() = 0;
        CurrPage.Update();
    end;

    var
        SoftwareAsAService: Boolean;
        BelongsToSubscriptionPlan: Boolean;
}