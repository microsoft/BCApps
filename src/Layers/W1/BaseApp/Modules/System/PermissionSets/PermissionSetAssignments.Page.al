namespace System.Security.AccessControl;

using System.Agents;
using System.Security.User;

page 9875 "Permission Set Assignments"
{
    Caption = 'Permission Set Assignments';
    PageType = List;
    SourceTable = "Access Control";
    DelayedInsert = true;

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
                field(UserName; UserName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'User Name';
                    Lookup = true;
                    LookupPageID = Users;
                    ShowMandatory = true;
                    TableRelation = User;
                    NotBlank = true;
                    ToolTip = 'Specifies the name of the user.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        User: Record User;
                        UserSelection: Codeunit "User Selection";
                    begin
                        if UserSelection.Open(User) then begin
                            if User."User Security ID" = Rec."User Security ID" then
                                exit;
                            if Rec.Get(User."User Security ID", Rec."Role ID", Rec."Company Name", Rec.Scope, Rec."App ID") then
                                exit;

                            Rec.Validate("User Security ID", User."User Security ID");
                            UpdateUserName();
                        end;
                    end;

                    trigger OnValidate()
                    var
                        User: Record User;
                    begin
                        if UserName = '' then
                            exit;

                        User.SetRange("User Name", UserName);
                        User.FindFirst();
                        Rec.Validate("User Security ID", User."User Security ID");
                    end;
                }
                field("Company Name"; Rec."Company Name")
                {
                    ApplicationArea = All;
                    Caption = 'Company';
                    ToolTip = 'Specifies the company that the permission set applies to.';

                    trigger OnValidate()
                    begin
                        if UserName = '' then
                            Error(EmptyUserNameErr);
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        AgentUtilities: Codeunit "Agent Utilities";
    begin
        AgentUtilities.BlockPageFromBeingOpenedByAgent();

        CurrPage.Caption := RoleIdFilter;
    end;

    trigger OnAfterGetRecord()
    begin
        UpdateUserName();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        exit(not IsNullGuid(Rec."User Security ID"));
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Rec.TestField("User Name");
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        UserName := '';
    end;

    local procedure UpdateUserName()
    begin
        Rec.CalcFields("User Name");
        UserName := Rec."User Name";
    end;

    internal procedure SetCurrentRoleId(CurrentRoleIdFilter: Text)
    begin
        RoleIdFilter := CurrentRoleIdFilter;
    end;

    var
        RoleIdFilter: Text;
        UserName: Code[50];
        EmptyUserNameErr: Label 'The User Name field must be filled in.';
}
