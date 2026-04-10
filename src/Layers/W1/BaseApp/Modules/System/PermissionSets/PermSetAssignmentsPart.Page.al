namespace System.Security.AccessControl;

using System.Agents;
using System.Security.User;

page 9876 "Perm. Set Assignments Part"
{
    Caption = 'User Permission Set Assignments';
    PageType = ListPart;
    Editable = false;
    DeleteAllowed = false;
    SourceTable = "Access Control";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Role ID"; Rec."Role ID")
                {
                    Caption = 'Permission Set';
                    ApplicationArea = All;
                    Editable = false;
                    Visible = false;
                    NotBlank = true;
                    ToolTip = 'Specifies a permission set that defines the role.';
                }
                field(UserName; Rec."User Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'User Name';
                    ShowMandatory = true;
                    TableRelation = User;
                    NotBlank = true;
                    ToolTip = 'Specifies the name of the user.';
                }
                field("Company Name"; Rec."Company Name")
                {
                    ApplicationArea = All;
                    Caption = 'Company';
                    ToolTip = 'Specifies the company that the permission set applies to.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(EditList)
            {
                Caption = 'Edit list';
                ApplicationArea = Basic, Suite;
                Enabled = true;
                Image = Users;
                ToolTip = 'View the assignees of the permission set.';

                trigger OnAction()
                var
                    AccessControl: Record "Access Control";
                    PermissionSetAssignments: Page "Permission Set Assignments";
                begin
                    AccessControl.Copy(Rec);
                    AccessControl.FilterGroup(4);
                    PermissionSetAssignments.SetTableView(AccessControl);
                    PermissionSetAssignments.SetCurrentRoleId(AccessControl.GetFilter("Role ID"));
                    PermissionSetAssignments.Run();
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        AgentUtilities: Codeunit "Agent Utilities";
    begin
        AgentUtilities.BlockPageFromBeingOpenedByAgent();

        FilterOutSpecialUsers(Rec);
    end;

    local procedure FilterOutSpecialUsers(var AccessControl: Record "Access Control")
    var
        User: Record User;
        UserSelection: Codeunit "User Selection";
        FilterTextBuilder: TextBuilder;
    begin
        UserSelection.FilterSystemUserAndGroupUsers(User);
        repeat
            FilterTextBuilder.Append(User."User Security ID");
            FilterTextBuilder.Append('|');
        until User.Next() = 0;

        AccessControl.FilterGroup(2);
        AccessControl.SetFilter("User Security ID", FilterTextBuilder.ToText().TrimEnd('|'));
        AccessControl.FilterGroup(0);
    end;
}
