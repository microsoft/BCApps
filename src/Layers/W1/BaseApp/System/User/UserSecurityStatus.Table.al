namespace System.Security.User;

using Microsoft.Integration.Dataverse;
using Microsoft.Integration.SyncEngine;
using Microsoft.Utilities;
using System.Security.AccessControl;

table 9062 "User Security Status"
{
    Caption = 'User Security Status';
    DataPerCompany = false;
    LookupPageID = "User Security Status List";
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "User Security ID"; Guid)
        {
            Caption = 'User Security ID';
            TableRelation = User."User Security ID";
        }
        field(2; "User Name"; Code[50])
        {
            CalcFormula = lookup(User."User Name" where("User Security ID" = field("User Security ID")));
            Caption = 'User Name';
            FieldClass = FlowField;
        }
        field(3; "Full Name"; Text[80])
        {
            CalcFormula = lookup(User."Full Name" where("User Security ID" = field("User Security ID")));
            Caption = 'Full Name';
            FieldClass = FlowField;
        }
        field(13; Reviewed; Boolean)
        {
            Caption = 'Reviewed';
        }
#if not CLEANSCHEMA25
        field(15; "Belongs to User Group"; Boolean)
        {
            CalcFormula = exist("User Group Member" where("User Security ID" = field("User Security ID")));
            Caption = 'Belongs to User Group';
            FieldClass = FlowField;
            ObsoleteReason = 'User group membership cannot be calculated via a flow field in the new user group system.';
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
        }
#endif
        field(20; "Users - To review"; Integer)
        {
            CalcFormula = count("User Security Status" where(Reviewed = const(false),
                                                              "User Security ID" = filter(<> '{00000000-0000-0000-0000-000000000000}')));
            Caption = 'Users - To review';
            FieldClass = FlowField;
        }
#if not CLEANSCHEMA25
        field(22; "Users - Not Group Members"; Integer)
        {
            Caption = 'Users - Not Group Members';
            FieldClass = FlowField;
            ObsoleteReason = 'User group membership cannot be calculated via a flow field in the new user group system.';
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
        }
#endif
        field(25; "CDS Integration Errors"; Integer)
        {
            CalcFormula = count("Integration Synch. Job Errors");
            Caption = 'Dataverse Integration Errors';
            FieldClass = FlowField;
        }
        field(26; "Coupled Data Synch Errors"; Integer)
        {
            CalcFormula = count("CRM Integration Record" where(Skipped = const(true)));
            Caption = 'Coupled Data Synch Errors';
            FieldClass = FlowField;
        }
        field(27; "User Exists"; Boolean)
        {
            CalcFormula = exist(User where("User Security ID" = field("User Security ID")));
            Caption = 'User Exists';
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "User Security ID")
        {
            Clustered = true;
        }
        key(Key2; Reviewed)
        {
        }
    }

    fieldgroups
    {
    }

    var
        UserNotReviewedTxt: Label 'User %1: not reviewed.', Comment = '%1 = user name';
        UserReviewedTxt: Label 'User %1: reviewed.', Comment = '%1: User name';
        SecurityActivityTok: Label 'User review';
        SecurityContextTok: Label 'Security administration';

    procedure KeepOnlyEnabledUsers()
    var
        User: Record User;
        UserSecurityStatus: Record "User Security Status";
    begin
        User.SetRange(State, User.State::Disabled);
        if not User.FindSet() then
            exit;
        repeat
            if UserSecurityStatus.Get(User."User Security ID") then
                UserSecurityStatus.Delete();
        until User.Next() = 0;
    end;

    procedure LoadUsers()
    var
        User: Record User;
        UserSecurityStatus: Record "User Security Status";
        UserSelection: Codeunit "User Selection";
    begin
        User.SetRange(State, User.State::Enabled);
        UserSelection.FilterSystemUserAndGroupUsers(User);
        if not User.FindSet() then
            exit;

        repeat
            if not UserSecurityStatus.Get(User."User Security ID") then begin
                UserSecurityStatus.Init();
                UserSecurityStatus."User Security ID" := User."User Security ID";
                UserSecurityStatus.Reviewed := false;
                UserSecurityStatus.Insert();
            end;
        until User.Next() = 0;
    end;

    procedure LogUserReviewActivity()
    var
        ActivityLog: Record "Activity Log";
        ActivityMessage: Text[250];
    begin
        CalcFields("User Name");
        if Reviewed then
            ActivityMessage := StrSubstNo(UserReviewedTxt, "User Name")
        else
            ActivityMessage := StrSubstNo(UserNotReviewedTxt, "User Name");
        ActivityLog.LogActivity(RecordId, ActivityLog.Status::Success, SecurityContextTok, SecurityActivityTok, ActivityMessage);
    end;
}
