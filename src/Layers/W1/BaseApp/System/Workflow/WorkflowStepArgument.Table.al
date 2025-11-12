namespace System.Automation;

using Microsoft.Finance.GeneralLedger.Journal;
using System.Environment;
using System.Environment.Configuration;
using System.Integration;
using System.Reflection;
using System.Security.AccessControl;
using System.Security.User;

table 1523 "Workflow Step Argument"
{
    Caption = 'Workflow Step Argument';
    DataCaptionFields = "General Journal Template Name", "General Journal Batch Name", "Notification User ID";
    LookupPageID = "Workflow Response Options";
    Permissions = TableData "Workflow Step Argument" = rim;
    ReplicateData = true;
    DataClassification = CustomerContent;

    fields
    {
        field(1; ID; Guid)
        {
            Caption = 'ID';
        }
        field(2; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Event,Response';
            OptionMembers = "Event",Response;
            TableRelation = "Workflow Step".Type where(Argument = field(ID));
        }
        field(3; "General Journal Template Name"; Code[10])
        {
            Caption = 'General Journal Template Name';
            TableRelation = "Gen. Journal Template".Name;
        }
        field(4; "General Journal Batch Name"; Code[10])
        {
            Caption = 'General Journal Batch Name';
            TableRelation = "Gen. Journal Batch".Name where("Journal Template Name" = field("General Journal Template Name"));
        }
        field(5; "Notification User ID"; Code[50])
        {
            Caption = 'Notification User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "User Setup"."User ID";
        }
        field(6; "Notification User License Type"; Option)
        {
            CalcFormula = lookup(User."License Type" where("User Name" = field("Notification User ID")));
            Caption = 'Notification User License Type';
            FieldClass = FlowField;
            OptionCaption = 'Full User,Limited User,Device Only User,Windows Group,External User';
            OptionMembers = "Full User","Limited User","Device Only User","Windows Group","External User";
        }
        field(7; "Response Function Name"; Code[128])
        {
            Caption = 'Response Function Name';
            TableRelation = "Workflow Response"."Function Name";
        }
        field(8; "Notify Sender"; Boolean)
        {
            Caption = 'Notify Sender';

            trigger OnValidate()
            begin
                if "Notify Sender" then
                    "Notification User ID" := '';
            end;
        }
        field(9; "Link Target Page"; Integer)
        {
            Caption = 'Link Target Page';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Page));
        }
        field(10; "Custom Link"; Text[250])
        {
            Caption = 'Custom Link';
            ExtendedDatatype = URL;

            trigger OnValidate()
            var
                WebRequestHelper: Codeunit "Web Request Helper";
            begin
                if "Custom Link" <> '' then
                    WebRequestHelper.IsValidUri("Custom Link");
            end;
        }
        field(11; "Event Conditions"; BLOB)
        {
            Caption = 'Event Conditions';
        }
        field(12; "Approver Type"; Enum "Workflow Approver Type")
        {
            Caption = 'Approver Type';
        }
        field(13; "Approver Limit Type"; Enum "Workflow Approver Limit Type")
        {
            Caption = 'Approver Limit Type';
        }
        field(14; "Workflow User Group Code"; Code[20])
        {
            Caption = 'Workflow User Group Code';
            TableRelation = "Workflow User Group".Code;
        }
        field(15; "Due Date Formula"; DateFormula)
        {
            Caption = 'Due Date Formula';

            trigger OnValidate()
            begin
                if CopyStr(Format("Due Date Formula"), 1, 1) = '-' then
                    Error(NoNegValuesErr, FieldCaption("Due Date Formula"));
            end;
        }
        field(16; Message; Text[250])
        {
            Caption = 'Message';
        }
        field(17; "Delegate After"; Option)
        {
            Caption = 'Delegate After';
            OptionCaption = 'Never,1 day,2 days,5 days';
            OptionMembers = Never,"1 day","2 days","5 days";
        }
        field(18; "Show Confirmation Message"; Boolean)
        {
            Caption = 'Show Confirmation Message';
        }
        field(19; "Table No."; Integer)
        {
            Caption = 'Table No.';
        }
        field(20; "Field No."; Integer)
        {
            Caption = 'Field No.';
        }
        field(21; "Field Caption"; Text[80])
        {
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("Table No."),
                                                              "No." = field("Field No.")));
            Caption = 'Field Caption';
            Editable = false;
            FieldClass = FlowField;
        }
        field(22; "Approver User ID"; Code[50])
        {
            Caption = 'Approver User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "User Setup"."User ID";

            trigger OnLookup()
            var
                UserSetup: Record "User Setup";
            begin
                if PAGE.RunModal(PAGE::"Approval User Setup", UserSetup) = ACTION::LookupOK then
                    Validate("Approver User ID", UserSetup."User ID");
            end;
        }
        field(23; "Response Type"; Option)
        {
            Caption = 'Response Type';
            OptionCaption = 'Not Expected,User ID';
            OptionMembers = "Not Expected","User ID";
        }
        field(24; "Response User ID"; Code[50])
        {
            Caption = 'Response User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "User Setup"."User ID";

            trigger OnLookup()
            var
                UserSetup: Record "User Setup";
            begin
                if PAGE.RunModal(PAGE::"User Setup", UserSetup) = ACTION::LookupOK then
                    Validate("Response User ID", UserSetup."User ID");
            end;
        }
        field(25; "Notification Entry Type"; Enum "Notification Entry Type")
        {
            Caption = 'Notification Entry Type';
        }
        field(100; "Response Option Group"; Code[20])
        {
            CalcFormula = lookup("Workflow Response"."Response Option Group" where("Function Name" = field("Response Function Name")));
            Caption = 'Response Option Group';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        CheckEditingIsAllowed();
    end;

    trigger OnInsert()
    begin
        ID := CreateGuid();
    end;

    trigger OnModify()
    begin
        CheckEditingIsAllowed();
    end;

    trigger OnRename()
    begin
        CheckEditingIsAllowed();
    end;

    var
#pragma warning disable AA0470
        NoNegValuesErr: Label '%1 must be a positive value.';
#pragma warning restore AA0470
        SenderTok: Label '<Sender>';

    procedure Clone(): Guid
    var
        WorkflowStepArgument: Record "Workflow Step Argument";
    begin
        CalcFields("Event Conditions");
        WorkflowStepArgument.Copy(Rec);
        WorkflowStepArgument.Insert(true);
        exit(WorkflowStepArgument.ID);
    end;

    [Scope('OnPrem')]
    procedure Equals(WorkflowStepArgument: Record "Workflow Step Argument"): Boolean
    var
        "Field": Record "Field";
        RecRefOfRec: RecordRef;
        RecRefOfArg: RecordRef;
        FieldRefOfRec: FieldRef;
        FieldRefOfArg: FieldRef;
    begin
        RecRefOfArg.GetTable(WorkflowStepArgument);
        RecRefOfRec.GetTable(Rec);
        Field.SetRange(TableNo, DATABASE::"Workflow Step Argument");
        Field.SetFilter(ObsoleteState, '<>%1', Field.ObsoleteState::Removed);
        Field.SetFilter("No.", '<>%1', FieldNo(ID));
        Field.SetFilter(Type, '<>%1', Field.Type::BLOB);
        Field.FindSet();
        repeat
            FieldRefOfArg := RecRefOfArg.Field(Field."No.");
            FieldRefOfRec := RecRefOfRec.Field(Field."No.");
            if FieldRefOfArg.Value <> FieldRefOfRec.Value then
                exit(false);
        until Field.Next() = 0;
        exit(true);
    end;

    procedure GetEventFilters() Filters: Text
    var
        FiltersInStream: InStream;
    begin
        if "Event Conditions".HasValue() then begin
            CalcFields("Event Conditions");
            "Event Conditions".CreateInStream(FiltersInStream, TextEncoding::UTF8);
            FiltersInStream.Read(Filters);
        end;
    end;

    procedure GetNotificationUserId(Variant: Variant): Text[50]
    var
        ApprovalEntry: Record "Approval Entry";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Variant);
        if RecRef.Number = Database::"Approval Entry" then begin
            ApprovalEntry := Variant;
            if "Notification User ID" <> '' then
                exit("Notification User ID");
            if "Notify Sender" then
                exit(ApprovalEntry."Sender ID");
            exit(ApprovalEntry."Approver ID");
        end;

        if "Notify Sender" then
            exit(CopyStr(UserId(), 1, 50));
        exit("Notification User ID");
    end;

#if not CLEAN26
    [Obsolete('Use GetNotificationUserId(var Variant: Variant): Text[50] instead.', '26.0')]
    procedure GetNotificationUserID(ApprovalEntry: Record "Approval Entry") NotificationUserID: Text[50]
    begin
        if "Notification User ID" <> '' then
            exit("Notification User ID");
        if "Notify Sender" then
            exit(ApprovalEntry."Sender ID");
        exit(ApprovalEntry."Approver ID");
    end;
#endif
    procedure GetNotificationUserName(): Text
    begin
        if "Notify Sender" then
            exit(SenderTok);
        exit("Notification User ID");
    end;

    procedure SetEventFilters(Filters: Text)
    var
        FiltersOutStream: OutStream;
    begin
        "Event Conditions".CreateOutStream(FiltersOutStream, TextEncoding::UTF8);
        FiltersOutStream.Write(Filters);
        Modify(true);
    end;

    local procedure CheckEditingIsAllowed()
    var
        Workflow: Record Workflow;
        WorkflowStep: Record "Workflow Step";
    begin
        if IsNullGuid(ID) then
            exit;

        WorkflowStep.SetRange(Argument, ID);
        if WorkflowStep.FindFirst() then begin
            Workflow.Get(WorkflowStep."Workflow Code");
            Workflow.CheckEditingIsAllowed();
        end;
    end;

    procedure HideExternalUsers()
    var
        EnvironmentInfo: Codeunit "Environment Information";
        OriginalFilterGroup: Integer;
    begin
        if not EnvironmentInfo.IsSaaS() then
            exit;

        OriginalFilterGroup := FilterGroup;
        FilterGroup := 2;
        CalcFields("Notification User License Type");
        SetFilter("Notification User License Type", '<>%1', "Notification User License Type"::"External User");
        FilterGroup := OriginalFilterGroup;
    end;
}

