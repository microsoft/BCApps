namespace System.Security.AccessControl;

page 9874 "Permission Set By Sec. Group"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Permission Set by Security Group';
    AboutTitle = 'About Permission Set by Security Group';
    AboutText = 'Get an overview of how permission sets are assigned to your security groups. Tip: If you go into analysis mode, you can analyze data in other ways than what you see in the list.';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    UsageCategory = Lists;
    PageType = Worksheet;
    SourceTable = "Aggregate Permission Set";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                Caption = 'Permission Set';
                field("Role ID"; Rec."Role ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Permission Set';
                    Editable = false;
                    ToolTip = 'Specifies the permission set.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the name of the record.';
                }
                field("App ID"; Rec."App ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Extension ID';
                    ToolTip = 'Specifies the unique identifier for the extension.';
                    Visible = false;
                }
                field("App Name"; Rec."App Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Extension Name';
                    ToolTip = 'Specifies the name of an extension.';
                }
                field(AllUsersHavePermission; AllGroupsHavePermission)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'All Security Groups';
                    ToolTip = 'Specifies if the user is a member of all security groups.';

                    trigger OnValidate()
                    begin
                        if AllGroupsHavePermission then
                            if not Confirm(AllUserGrpGetsPermissionQst) then
                                Error('');

                        SetColumnPermission(0, AllGroupsHavePermission);
                        CurrPage.Update(false);
                    end;
                }
                field(Column1; SecurityGroupHasPermissionSet[1])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + SecurityGroupCodeArr[1];
                    ToolTip = 'Specifies if the user has this permission set.';
                    Visible = NoOfRecords >= 1;

                    trigger OnValidate()
                    begin
                        SetColumnPermission(1, SecurityGroupHasPermissionSet[1]);
                    end;
                }
                field(Column2; SecurityGroupHasPermissionSet[2])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + SecurityGroupCodeArr[2];
                    ToolTip = 'Specifies if the user has this permission set.';
                    Visible = NoOfRecords >= 2;

                    trigger OnValidate()
                    begin
                        SetColumnPermission(2, SecurityGroupHasPermissionSet[2]);
                    end;
                }
                field(Column3; SecurityGroupHasPermissionSet[3])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + SecurityGroupCodeArr[3];
                    ToolTip = 'Specifies if the user has this permission set.';
                    Visible = NoOfRecords >= 3;

                    trigger OnValidate()
                    begin
                        SetColumnPermission(3, SecurityGroupHasPermissionSet[3]);
                    end;
                }
                field(Column4; SecurityGroupHasPermissionSet[4])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + SecurityGroupCodeArr[4];
                    ToolTip = 'Specifies if the user has this permission set.';
                    Visible = NoOfRecords >= 4;

                    trigger OnValidate()
                    begin
                        SetColumnPermission(4, SecurityGroupHasPermissionSet[4]);
                    end;
                }
                field(Column5; SecurityGroupHasPermissionSet[5])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + SecurityGroupCodeArr[5];
                    ToolTip = 'Specifies if the user has this permission set.';
                    Visible = NoOfRecords >= 5;

                    trigger OnValidate()
                    begin
                        SetColumnPermission(5, SecurityGroupHasPermissionSet[5]);
                    end;
                }
                field(Column6; SecurityGroupHasPermissionSet[6])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + SecurityGroupCodeArr[6];
                    ToolTip = 'Specifies if the user has this permission set.';
                    Visible = NoOfRecords >= 6;

                    trigger OnValidate()
                    begin
                        SetColumnPermission(6, SecurityGroupHasPermissionSet[6]);
                    end;
                }
                field(Column7; SecurityGroupHasPermissionSet[7])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + SecurityGroupCodeArr[7];
                    ToolTip = 'Specifies if the user has this permission set.';
                    Visible = NoOfRecords >= 7;

                    trigger OnValidate()
                    begin
                        SetColumnPermission(7, SecurityGroupHasPermissionSet[7]);
                    end;
                }
                field(Column8; SecurityGroupHasPermissionSet[8])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + SecurityGroupCodeArr[8];
                    ToolTip = 'Specifies if the user has this permission set.';
                    Visible = NoOfRecords >= 8;

                    trigger OnValidate()
                    begin
                        SetColumnPermission(8, SecurityGroupHasPermissionSet[8]);
                    end;
                }
                field(Column9; SecurityGroupHasPermissionSet[9])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + SecurityGroupCodeArr[9];
                    ToolTip = 'Specifies if the user has this permission set.';
                    Visible = NoOfRecords >= 9;

                    trigger OnValidate()
                    begin
                        SetColumnPermission(9, SecurityGroupHasPermissionSet[9]);
                    end;
                }
                field(Column10; SecurityGroupHasPermissionSet[10])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + SecurityGroupCodeArr[10];
                    ToolTip = 'Specifies if the user has this permission set.';
                    Visible = NoOfRecords >= 10;

                    trigger OnValidate()
                    begin
                        SetColumnPermission(10, SecurityGroupHasPermissionSet[10]);
                    end;
                }
            }
        }
        area(factboxes)
        {
            part(ExpandedPermissions; "Expanded Permissions FactBox")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Permissions';
                Editable = false;
                SubPageLink = "Role ID" = field("Role ID"),
                              "App ID" = field("App ID");
            }
        }
    }

    actions
    {
        area(navigation)
        {
            action(Permissions)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Permissions';
                Image = Permission;
                ToolTip = 'View or edit which feature objects that users need to access and set up the related permissions in permission sets that you can assign to the users of the database.';

                trigger OnAction()
                var
                    PermissionSetRelation: Codeunit "Permission Set Relation";
                begin
                    PermissionSetRelation.OpenPermissionSetPage(Rec.Name, Rec."Role ID", Rec."App ID", Rec.Scope);
                end;
            }
        }
        area(processing)
        {
            action(CopyPermissionSet)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Copy Permission Set';
                Ellipsis = true;
                Enabled = CanManageUsersOnTenant;
                Image = Copy;
                ToolTip = 'Create a copy of the selected permission set with a name that you specify.';

                trigger OnAction()
                var
                    AggregatePermissionSet: Record "Aggregate Permission Set";
                begin
                    AggregatePermissionSet.SetRange(Scope, Rec.Scope);
                    AggregatePermissionSet.SetRange("App ID", Rec."App ID");
                    AggregatePermissionSet.SetRange("Role ID", Rec."Role ID");

                    Report.RunModal(Report::"Copy Permission Set", true, true, AggregatePermissionSet);
                end;
            }
            action(AllColumnsLeft)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'All Columns Left';
                Image = PreviousSet;
                ToolTip = 'Jump to the left-most column.';

                trigger OnAction()
                begin
                    PermissionPagesMgt.AllColumnsLeft();
                end;
            }
            action(ColumnLeft)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Column Left';
                Image = PreviousRecord;
                ToolTip = 'Jump one column to the left.';

                trigger OnAction()
                begin
                    PermissionPagesMgt.ColumnLeft();
                end;
            }
            action(ColumnRight)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Column Right';
                Image = NextRecord;
                ToolTip = 'Jump one column to the right.';

                trigger OnAction()
                begin
                    PermissionPagesMgt.ColumnRight();
                end;
            }
            action(AllColumnsRight)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'All Columns Right';
                Image = NextSet;
                ToolTip = 'Jump to the right-most column.';

                trigger OnAction()
                begin
                    PermissionPagesMgt.AllColumnsRight();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(Permissions_Promoted; Permissions)
                {
                }
                actionref(CopyPermissionSet_Promoted; CopyPermissionSet)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Browse', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(AllColumnsLeft_Promoted; AllColumnsLeft)
                {
                }
                actionref(ColumnLeft_Promoted; ColumnLeft)
                {
                }
                actionref(ColumnRight_Promoted; ColumnRight)
                {
                }
                actionref(AllColumnsRight_Promoted; AllColumnsRight)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        FindSecurityGroups();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        FindSecurityGroups();
    end;

    trigger OnInit()
    var
        [SecurityFiltering(SecurityFilter::Ignored)]
        AccessControl: Record "Access Control";
    begin
        PermissionPagesMgt.DisallowEditingPermissionSetsForNonAdminUsers();
        CanManageUsersOnTenant := AccessControl.WritePermission();
    end;

    trigger OnOpenPage()
    begin
        SecurityGroup.GetGroups(SecurityGroupBuffer);
        NoOfRecords := SecurityGroupBuffer.Count();
        PermissionPagesMgt.Init(NoOfRecords, ArrayLen(SecurityGroupCodeArr));
    end;

    var
        PermissionPagesMgt: Codeunit "Permission Pages Mgt.";
        AllGroupsHavePermission: Boolean;
        CanManageUsersOnTenant: Boolean;
        NoOfRecords: Integer;
        SecurityGroupCodeArr: array[10] of Code[20];
        SecurityGroupHasPermissionSet: array[10] of Boolean;
        AllUserGrpGetsPermissionQst: Label 'Are you sure you want to add this permission set to all security groups?';

    local procedure FindSecurityGroups()
    var
        LocalSecurityGroupBuffer: Record "Security Group Buffer";
        i: Integer;
    begin
        LocalSecurityGroupBuffer.Copy(SecurityGroupBuffer, true);
        Clear(SecurityGroupCodeArr);
        Clear(SecurityGroupHasPermissionSet);
        AllGroupsHavePermission := true;
        if LocalSecurityGroupBuffer.FindSet() then
            repeat
                i += 1;
                if PermissionPagesMgt.IsInColumnsRange(i) then begin
                    SecurityGroupCodeArr[i - PermissionPagesMgt.GetOffset()] := LocalSecurityGroupBuffer.Code;
                    SecurityGroupHasPermissionSet[i - PermissionPagesMgt.GetOffset()] := SecurityGroupHasPermission(Rec, LocalSecurityGroupBuffer."Group User SID");
                    AllGroupsHavePermission := AllGroupsHavePermission and SecurityGroupHasPermissionSet[i - PermissionPagesMgt.GetOffset()];
                end else
                    if AllGroupsHavePermission then
                        AllGroupsHavePermission := SecurityGroupHasPermission(Rec, LocalSecurityGroupBuffer."Group User SID");
            until (LocalSecurityGroupBuffer.Next() = 0) or (PermissionPagesMgt.IsPastColumnRange(i) and not AllGroupsHavePermission);
    end;

    local procedure SecurityGroupHasPermission(var AggregatePermissionSet: Record "Aggregate Permission Set"; GroupUserSID: Guid): Boolean
    var
        AccessControl: Record "Access Control";
    begin
        AccessControl.SetRange("User Security ID", GroupUserSID);
        AccessControl.SetRange("Role ID", AggregatePermissionSet."Role ID");
        AccessControl.SetRange("App ID", AggregatePermissionSet."App ID");
        AccessControl.SetRange(Scope, AggregatePermissionSet.Scope);
        exit(not AccessControl.IsEmpty);
    end;

    local procedure SetColumnPermission(ColumnNo: Integer; UserHasPermission: Boolean)
    var
        LocalSecurityGroupBuffer: Record "Security Group Buffer";
    begin
        LocalSecurityGroupBuffer.Copy(SecurityGroupBuffer, true);
        if ColumnNo > 0 then begin
            SetSecurityGroupPermission(SecurityGroupCodeArr[ColumnNo], UserHasPermission);
            AllGroupsHavePermission := AllGroupsHavePermission and UserHasPermission;
        end else
            if LocalSecurityGroupBuffer.FindSet() then
                repeat
                    SetSecurityGroupPermission(LocalSecurityGroupBuffer.Code, UserHasPermission);
                until LocalSecurityGroupBuffer.Next() = 0;
    end;

    local procedure SetSecurityGroupPermission(SecurityGroupCode: Code[20]; DoesSecurityGroupHavePermission: Boolean)
    var
        LocalSecurityGroupBuffer: Record "Security Group Buffer";
        AccessControl: Record "Access Control";
    begin
        LocalSecurityGroupBuffer.Copy(SecurityGroupBuffer, true);
        LocalSecurityGroupBuffer.Get(SecurityGroupCode);

        if AccessControl.Get(LocalSecurityGroupBuffer."Group User SID", Rec."Role ID", '', Rec.Scope, Rec."App ID") then begin
            if not DoesSecurityGroupHavePermission then
                AccessControl.Delete(true);
            exit;
        end;
        if not DoesSecurityGroupHavePermission then
            exit;
        AccessControl.Init();
        AccessControl."User Security ID" := LocalSecurityGroupBuffer."Group User SID";
        AccessControl."Role ID" := Rec."Role ID";
        AccessControl."App ID" := Rec."App ID";
        AccessControl.Scope := Rec.Scope;
        AccessControl.Insert(true);
    end;

    var
        SecurityGroupBuffer: Record "Security Group Buffer";
        SecurityGroup: Codeunit "Security Group";
}
