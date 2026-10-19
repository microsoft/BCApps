// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using System.Security.AccessControl;

page 6995 "Expense Agent Access Ctrl"
{
    PageType = ListPart;
    ApplicationArea = All;
    SourceTable = "Expense Agent Access Control";
    Caption = 'Agent Access Control';
    MultipleNewLines = false;
    Extensible = false;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            repeater(Main)
            {
                field(UserName; UserName)
                {
                    Caption = 'User Name';
                    ToolTip = 'Specifies the name of the user that can access the Expense Agent.';
                    TableRelation = User where("License Type" = filter(<> Application & <> "Windows Group" & <> Agent));
                    NotBlank = true;

                    trigger OnValidate()
                    begin
                        ValidateUserName(UserName);
                    end;
                }
                field(UserFullName; UserFullName)
                {
                    Caption = 'User Full Name';
                    ToolTip = 'Specifies the full name of the user that can access the Expense Agent.';
                    Editable = false;
                }
                field(CanConfigureAgent; Rec."Can Configure Agent")
                {
                    Caption = 'Can Configure';
                    ToolTip = 'Specifies whether the user can configure the Expense Agent.';
                }
                field(CanWorkOnBehalf; Rec."Can Work on Behalf")
                {
                    Caption = 'Can Work on Behalf';
                    ToolTip = 'Specifies whether the user can work on behalf of other expense users.';
                }
            }
        }
    }
    trigger OnAfterGetRecord()
    begin
        UpdateGlobalVariables();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        exit(HandleOnInsert());
    end;

    local procedure HandleOnInsert(): Boolean
    var
        UserSecurityID: Guid;
    begin
        // If UserName is already populated, validate it to set User Security ID.
        if (UserName <> '') and IsNullGuid(Rec."User Security ID") then
            if FindUserByName(UserName, UserSecurityID) then
                Rec."User Security ID" := UserSecurityID;

        exit(true);
    end;

    local procedure UpdateGlobalVariables()
    var
        User: Record "User";
    begin
        Clear(UserFullName);
        Clear(UserName);

        if IsNullGuid(Rec."User Security ID") then
            exit;

        if not User.Get(Rec."User Security ID") then
            exit;

        UserName := User."User Name";
        UserFullName := User."Full Name";
    end;

    local procedure ValidateUserName(NewUserName: Text)
    var
        UserSecurityID: Guid;
    begin
        if not FindUserByName(NewUserName, UserSecurityID) then
            exit;

        Rec.Validate("User Security ID", UserSecurityID);
        UpdateGlobalVariables();
    end;

    local procedure FindUserByName(NewUserName: Text; var UserSecurityID: Guid): Boolean
    var
        User: Record "User";
        UserGuid: Guid;
    begin
        if Evaluate(UserGuid, NewUserName) then begin
            if not User.Get(UserGuid) then
                exit(false);
            UserSecurityID := User."User Security ID";
            exit(true);
        end;

        User.SetRange("User Name", NewUserName);
        if not User.FindFirst() then begin
            User.SetFilter("User Name", '@*''''' + NewUserName + '''''*');
            if not User.FindFirst() then
                exit(false);
        end;

        UserSecurityID := User."User Security ID";
        exit(true);
    end;

    var
        UserFullName: Text[80];
        UserName: Code[50];
}
