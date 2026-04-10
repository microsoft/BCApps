namespace System.Security.AccessControl;

using System.Agents;

page 9817 "Permission Sets FactBox"
{
    Caption = 'Permission Sets';
    Editable = false;
    PageType = ListPart;
    SourceTable = "Access Control";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                Caption = 'User Permissions';
                field(PermissionSet; Rec."Role ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Permission Set';
                    ToolTip = 'Specifies the ID of a security role that has been assigned to this Windows login in the current database.';
                    Style = Unfavorable;
                    StyleExpr = PermissionSetNotFound;

                    trigger OnDrillDown()
                    var
                        PermissionSetRelation: Codeunit "Permission Set Relation";
                    begin
                        PermissionSetRelation.OpenPermissionSetPage('', Rec."Role ID", Rec."App ID", Rec.Scope);
                    end;
                }
                field(Description; Rec."Role Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Description';
                    DrillDown = false;
                    Editable = false;
                    ToolTip = 'Specifies the name of the security role that has been given to this Windows login in the current database.';
                    Visible = false;
                }
                field(Company; Rec."Company Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Company';
                    ToolTip = 'Specifies the name of the company that this role is limited to for this Windows login.';
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        AgentUtilities: Codeunit "Agent Utilities";
    begin
        AgentUtilities.BlockPageFromBeingOpenedByAgent();
    end;

    trigger OnAfterGetRecord()
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
    begin
        if User."User Name" <> '' then
            CurrPage.Caption := User."User Name";

        PermissionSetNotFound := false;
        if not (Rec."Role ID" in ['SUPER', 'SECURITY']) then
            PermissionSetNotFound := not AggregatePermissionSet.Get(Rec.Scope, Rec."App ID", Rec."Role ID");
    end;

    var
        User: Record User;
        PermissionSetNotFound: Boolean;
}
