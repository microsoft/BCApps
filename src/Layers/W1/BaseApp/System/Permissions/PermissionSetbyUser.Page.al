namespace System.Security.AccessControl;

using System.Environment;
using System.Security.User;

page 9816 "Permission Set by User"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Permission Set by User';
    AboutTitle = 'About Permission Set by User';
    AboutText = 'Get an overview of how permission sets are assigned to your users within a company. Tip: If you go into analysis mode, you can analyze data in other ways than what you see in the list.';
    DataCaptionExpression = SelectedCompany;
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    UsageCategory = Lists;
    PageType = Worksheet;
    Permissions = TableData "Access Control" = rimd;
    SourceTable = "Aggregate Permission Set";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(SelectedCompany; SelectedCompany)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Company Name';
                    TableRelation = Company;
                    ToolTip = 'Specifies the name of the company.';

                    trigger OnValidate()
                    begin
                        UpdateCompany();
                    end;
                }
                field(ShowDomainName; ShowDomainName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show Domain Name';
                    ToolTip = 'Specifies the domain name together with the user name for Windows user accounts, for example, DOMAIN\UserName.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(false);
                    end;
                }
            }
            repeater(Group)
            {
                Caption = 'Permission Set';
                field("Role ID"; Rec."Role ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Permission Set';
                    ToolTip = 'Specifies the permission set.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the record.';
                }
                field("App ID"; Rec."App ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Extension ID';
                    ToolTip = 'Specifies the unique identifier for the extension. A unique identifier will be generated if a value is not provided.';
                    Visible = false;
                }
                field("App Name"; Rec."App Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Extension Name';
                    ToolTip = 'Specifies the name of the extension.';
                }
                field(AllUsersHavePermission; AllUsersHavePermission)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'All Users';
                    ToolTip = 'Specifies that the permission set will be assigned to all users.';

                    trigger OnValidate()
                    begin
                        SetColumnPermission(0, AllUsersHavePermission);
                        CurrPage.Update(false);
                    end;
                }
                field(Column1; UserHasPermissionSet[1])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + UserNameCode[1];
                    Visible = NoOfRecords >= 1;

                    trigger OnValidate()
                    begin
                        SetColumnPermission(1, UserHasPermissionSet[1]);
                    end;
                }
                field(Column2; UserHasPermissionSet[2])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + UserNameCode[2];
                    Visible = NoOfRecords >= 2;

                    trigger OnValidate()
                    begin
                        SetColumnPermission(2, UserHasPermissionSet[2]);
                    end;
                }
                field(Column3; UserHasPermissionSet[3])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + UserNameCode[3];
                    Visible = NoOfRecords >= 3;

                    trigger OnValidate()
                    begin
                        SetColumnPermission(3, UserHasPermissionSet[3]);
                    end;
                }
                field(Column4; UserHasPermissionSet[4])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + UserNameCode[4];
                    Visible = NoOfRecords >= 4;

                    trigger OnValidate()
                    begin
                        SetColumnPermission(4, UserHasPermissionSet[4]);
                    end;
                }
                field(Column5; UserHasPermissionSet[5])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + UserNameCode[5];
                    Visible = NoOfRecords >= 5;

                    trigger OnValidate()
                    begin
                        SetColumnPermission(5, UserHasPermissionSet[5]);
                    end;
                }
                field(Column6; UserHasPermissionSet[6])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + UserNameCode[6];
                    Visible = NoOfRecords >= 6;

                    trigger OnValidate()
                    begin
                        SetColumnPermission(6, UserHasPermissionSet[6]);
                    end;
                }
                field(Column7; UserHasPermissionSet[7])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + UserNameCode[7];
                    Visible = NoOfRecords >= 7;

                    trigger OnValidate()
                    begin
                        SetColumnPermission(7, UserHasPermissionSet[7]);
                    end;
                }
                field(Column8; UserHasPermissionSet[8])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + UserNameCode[8];
                    Visible = NoOfRecords >= 8;

                    trigger OnValidate()
                    begin
                        SetColumnPermission(8, UserHasPermissionSet[8]);
                    end;
                }
                field(Column9; UserHasPermissionSet[9])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + UserNameCode[9];
                    Visible = NoOfRecords >= 9;

                    trigger OnValidate()
                    begin
                        SetColumnPermission(9, UserHasPermissionSet[9]);
                    end;
                }
                field(Column10; UserHasPermissionSet[10])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + UserNameCode[10];
                    Visible = NoOfRecords >= 10;

                    trigger OnValidate()
                    begin
                        SetColumnPermission(10, UserHasPermissionSet[10]);
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
                Image = Copy;
                ToolTip = 'Create a copy of the selected permission set with a name that you specify.';

                trigger OnAction()
                var
                    AggregatePermissionSet: Record "Aggregate Permission Set";
                begin
                    AggregatePermissionSet.SetRange(Scope, Rec.Scope);
                    AggregatePermissionSet.SetRange("App ID", Rec."App ID");
                    AggregatePermissionSet.SetRange("Role ID", Rec."Role ID");

                    REPORT.RunModal(REPORT::"Copy Permission Set", true, true, AggregatePermissionSet);
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

    trigger OnAfterGetCurrRecord()
    begin
        FindUsers();
    end;

    trigger OnAfterGetRecord()
    begin
        FindUsers();
    end;

    trigger OnInit()
    begin
        PermissionPagesMgt.DisallowEditingPermissionSetsForNonAdminUsers();
    end;

    trigger OnOpenPage()
    var
        User: Record User;
    begin
        SelectedCompany := CompanyName();
        UpdateCompany();
        UserSelection.FilterSystemUserAndGroupUsers(User);
        NoOfRecords := User.Count();
        PermissionPagesMgt.Init(NoOfRecords, ArrayLen(UserNameCode));
    end;

    protected var
        AllUsersHavePermission: Boolean;

    var
        Company: Record Company;
        PermissionPagesMgt: Codeunit "Permission Pages Mgt.";
        UserSelection: Codeunit "User Selection";
        UserSecurityIDArr: array[10] of Guid;
        NoOfRecords: Integer;
        SelectedCompany: Text[30];
        ShowDomainName: Boolean;
        UserNameCode: array[10] of Code[50];
        UserHasPermissionSet: array[10] of Boolean;

    protected procedure SetUserPermission(UserSecurityID: Guid; UserHasPermission: Boolean)
    var
        AccessControl: Record "Access Control";
    begin
        if AccessControl.Get(UserSecurityID, Rec."Role ID", '', Rec.Scope, Rec."App ID") or
           AccessControl.Get(UserSecurityID, Rec."Role ID", Company.Name, Rec.Scope, Rec."App ID")
        then begin
            if not UserHasPermission then
                AccessControl.Delete(true);
            exit;
        end;
        if not UserHasPermission then
            exit;
        AccessControl.Init();
        AccessControl."User Security ID" := UserSecurityID;
        AccessControl."Role ID" := Rec."Role ID";
        AccessControl."Company Name" := Company.Name;
        AccessControl.Scope := Rec.Scope;
        AccessControl."App ID" := Rec."App ID";
        AccessControl.Insert();
    end;

    local procedure FindUsers()
    var
        User: Record User;
        i: Integer;
        j: Integer;
    begin
        Clear(UserNameCode);
        Clear(UserHasPermissionSet);
        User.SetCurrentKey("User Name");
        AllUsersHavePermission := true;
        UserSelection.FilterSystemUserAndGroupUsers(User);
        if User.FindSet() then
            repeat
                i += 1;
                if PermissionPagesMgt.IsInColumnsRange(i) then begin
                    UserSecurityIDArr[i - PermissionPagesMgt.GetOffset()] := User."User Security ID";
                    j := 0;
                    if not ShowDomainName then begin
                        j := StrPos(User."User Name", '\');
                        if j < 0 then
                            j := 0;
                    end;
                    UserNameCode[i - PermissionPagesMgt.GetOffset()] := CopyStr(User."User Name", j + 1, MaxStrLen(UserNameCode[1]));
                    UserHasPermissionSet[i - PermissionPagesMgt.GetOffset()] := UserHasPermission(Rec, User);
                    AllUsersHavePermission := AllUsersHavePermission and UserHasPermissionSet[i - PermissionPagesMgt.GetOffset()];
                end else
                    if AllUsersHavePermission then
                        AllUsersHavePermission := UserHasPermission(Rec, User);
            until (User.Next() = 0) or (PermissionPagesMgt.IsPastColumnRange(i) and not AllUsersHavePermission);
    end;

    local procedure UserHasPermission(var AggregatePermissionSet: Record "Aggregate Permission Set"; var User: Record User): Boolean
    var
        AccessControl: Record "Access Control";
    begin
        AccessControl.SetRange("User Security ID", User."User Security ID");
        AccessControl.SetRange("Role ID", AggregatePermissionSet."Role ID");
        AccessControl.SetFilter("Company Name", '%1|%2', '', Company.Name);
        AccessControl.SetRange(Scope, AggregatePermissionSet.Scope);
        AccessControl.SetRange("App ID", AggregatePermissionSet."App ID");
        exit(not AccessControl.IsEmpty);
    end;

    local procedure SetColumnPermission(ColumnNo: Integer; UserHasPermission: Boolean)
    var
        User: Record User;
    begin
        if ColumnNo > 0 then begin
            SetUserPermission(UserSecurityIDArr[ColumnNo], UserHasPermission);
            AllUsersHavePermission := AllUsersHavePermission and UserHasPermission;
        end else begin
            UserSelection.FilterSystemUserAndGroupUsers(User);
            if User.FindSet() then
                repeat
                    SetUserPermission(User."User Security ID", UserHasPermission);
                until User.Next() = 0;
        end;
    end;

    local procedure UpdateCompany()
    begin
        Company.Name := SelectedCompany;
        if SelectedCompany <> '' then begin
            Company.Find('=<>');
            SelectedCompany := Company.Name;
        end;
        CurrPage.Update(false);
    end;
}