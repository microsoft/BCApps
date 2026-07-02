// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Security.AccessControl;

table 30432 "User Permissions Buffer"
{
    Caption = 'User Permissions Buffer';
    DataClassification = CustomerContent;
    TableType = Temporary;
    InherentPermissions = RIMDX;
    InherentEntitlements = RIMDX;

    fields
    {
        field(1; "User Security ID"; Guid)
        {
            Caption = 'User Security ID';
        }
        field(2; "Role ID"; Code[20])
        {
            Caption = 'Role ID';
            TableRelation = "Aggregate Permission Set"."Role ID";
        }
        field(3; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'User,Security Group';
            OptionMembers = User,SecurityGroup;
        }
        field(4; SecurityGroupCode; Code[20])
        {
            Caption = 'Security Group Code';
        }
        field(5; "Company Name"; Text[30])
        {
            Caption = 'Company Name';
            TableRelation = System.Environment.Company.Name;
        }
        field(6; "Role Name"; Text[30])
        {
            CalcFormula = lookup("Aggregate Permission Set".Name where(Scope = field(Scope),
                                                                        "App ID" = field("App ID"),
                                                                        "Role ID" = field("Role ID")));
            Caption = 'Role Name';
            FieldClass = FlowField;
        }
        field(7; Scope; Option)
        {
            Caption = 'Scope';
            OptionCaption = 'System,Tenant';
            OptionMembers = System,Tenant;
            TableRelation = "Aggregate Permission Set".Scope;
        }
        field(8; "App ID"; Guid)
        {
            Caption = 'App ID';
            TableRelation = "Aggregate Permission Set"."App ID";
        }
        field(9; "App Name"; Text[250])
        {
            CalcFormula = lookup("Aggregate Permission Set"."App Name" where(Scope = field(Scope),
                                                                              "App ID" = field("App ID"),
                                                                              "Role ID" = field("Role ID")));
            Caption = 'App Name';
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "User Security ID", "Role ID", Type)
        {
            Clustered = true;
        }
    }

    /// <summary>
    /// Fills the buffer with user permission data from Access Control and Security Group Member records.
    /// </summary>
    procedure FillBuffer()
    var
        User: Record User;
        AccessControl: Record "Access Control";
        SecurityGroupMemberBuffer: Record "Security Group Member Buffer";
        SecurityGroup: Codeunit "Security Group";
    begin
        SecurityGroup.GetMembers(SecurityGroupMemberBuffer);

        User.SetLoadFields("User Security ID");
        if User.FindSet() then
            repeat
                Rec.Init();
                Rec."User Security ID" := User."User Security ID";
                AccessControl.SetRange("User Security ID", User."User Security ID");
                AccessControl.SetLoadFields("Role ID", Scope, "App ID", "Company Name");
                if AccessControl.FindSet() then
                    repeat
                        InsertRecord(Rec, AccessControl, Rec.Type::User);
                    until AccessControl.Next() = 0;

                SecurityGroupMemberBuffer.SetRange("User Security ID", User."User Security ID");
                if SecurityGroupMemberBuffer.FindSet() then
                    repeat
                        AccessControl.SetRange("User Security ID", SecurityGroupMemberBuffer."User Security ID");
                        if AccessControl.FindSet() then
                            repeat
                                Rec.SecurityGroupCode := SecurityGroupMemberBuffer."Security Group Code";
                                InsertRecord(Rec, AccessControl, Rec.Type::SecurityGroup);
                            until AccessControl.Next() = 0;
                    until SecurityGroupMemberBuffer.Next() = 0;
            until User.Next() = 0;
    end;

    /// <summary>
    /// Inserts an access control record into the user permissions buffer.
    /// </summary>
    /// <param name="UserPermissionBuffer">The buffer record to populate and insert.</param>
    /// <param name="AccessControl">The access control record to copy data from.</param>
    /// <param name="UserType">The type of user (User or SecurityGroup).</param>
    procedure InsertRecord(var UserPermissionBuffer: Record "User Permissions Buffer"; AccessControl: Record "Access Control"; UserType: Option)
    begin
        UserPermissionBuffer."Role ID" := AccessControl."Role ID";
        UserPermissionBuffer.Type := UserType;
        UserPermissionBuffer.Scope := AccessControl.Scope;
        UserPermissionBuffer."App ID" := AccessControl."App ID";
        UserPermissionBuffer."Company Name" := AccessControl."Company Name";
        UserPermissionBuffer.Insert();
    end;
}