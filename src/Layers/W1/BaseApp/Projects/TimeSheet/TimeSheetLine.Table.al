// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.TimeSheet;

using Microsoft.Assembly.Document;
using Microsoft.HumanResources.Absence;
using Microsoft.HumanResources.Employee;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Projects.Resources.Setup;
using Microsoft.Utilities;
using System.Security.User;

table 951 "Time Sheet Line"
{
    Caption = 'Time Sheet Line';
    Permissions = TableData Employee = r;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Time Sheet No."; Code[20])
        {
            Caption = 'Time Sheet No.';
            TableRelation = "Time Sheet Header";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Time Sheet Starting Date"; Date)
        {
            Caption = 'Time Sheet Starting Date';
            Editable = false;
        }
        field(5; Type; Enum "Time Sheet Line Type")
        {
            Caption = 'Type';

            trigger OnValidate()
            begin
                TestStatus();
                if Type = Type::"Assembly Order" then
                    FieldError(Type);
                if Type <> xRec.Type then begin
                    TimeSheetDetail.SetRange("Time Sheet No.", "Time Sheet No.");
                    TimeSheetDetail.SetRange("Time Sheet Line No.", "Line No.");
                    if not TimeSheetDetail.IsEmpty() then
                        TimeSheetDetail.DeleteAll();
                    "Job No." := '';
                    Clear("Job Id");
                    "Job Task No." := '';
                    "Cause of Absence Code" := '';
                    Description := '';
                    "Assembly Order No." := '';
                    "Assembly Order Line No." := 0;
                    OnValidateTypeOnAfterClearFields(Rec);

                    UpdateApproverID();
                    if Type = Type::Absence then
                        CheckIsEmployeeLinkedToResource();
                end;
            end;
        }
        field(6; "Job No."; Code[20])
        {
            Caption = 'Project No.';
            TableRelation = Job where(Status = filter(Open));

            trigger OnValidate()
            begin
                if "Job No." <> '' then begin
                    TestField(Type, Type::Job);
                    Job.Get("Job No.");
                    if Job.Blocked = Job.Blocked::All then
                        Job.TestBlocked();
                    if Job.Status = Job.Status::Completed then
                        Job.TestStatusCompleted();
                end;
                Validate("Job Task No.", '');
                UpdateApproverID();
                UpdateJobId();
            end;
        }
        field(7; "Job Task No."; Code[20])
        {
            Caption = 'Project Task No.';
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."), "Job Task Type" = filter(Posting));

            trigger OnValidate()
            begin
                if "Job Task No." <> '' then begin
                    TestField(Type, Type::Job);
                    JobTask.Get("Job No.", "Job Task No.");
                    JobTask.TestField("Job Task Type", JobTask."Job Task Type"::Posting);
                    Description := JobTask.Description;
                end;
            end;
        }
        field(9; "Cause of Absence Code"; Code[10])
        {
            Caption = 'Cause of Absence Code';
            TableRelation = "Cause of Absence";

            trigger OnValidate()
            var
                CauseOfAbsence: Record "Cause of Absence";
            begin
                if "Cause of Absence Code" <> '' then begin
                    TestField(Type, Type::Absence);
                    CauseOfAbsence.Get("Cause of Absence Code");
                    Description := CauseOfAbsence.Description;
                    CheckIsEmployeeLinkedToResource();
                end;
            end;
        }
        field(10; Description; Text[100])
        {
            Caption = 'Description';

            trigger OnValidate()
            begin
                TestStatus();
            end;
        }
        field(11; "Work Type Code"; Code[10])
        {
            Caption = 'Work Type Code';
            TableRelation = "Work Type";

            trigger OnValidate()
            begin
                if ("Work Type Code" <> xRec."Work Type Code") and ("Work Type Code" <> '') then
                    CheckWorkType();
            end;
        }
        field(12; "Approver ID"; Code[50])
        {
            Caption = 'Approver ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = "User Setup";
        }
        field(13; "Service Order No."; Code[20])
        {
            Caption = 'Service Order No.';
        }
        field(14; "Service Order Line No."; Integer)
        {
            Caption = 'Service Order Line No.';
        }
        field(15; "Total Quantity"; Decimal)
        {
            CalcFormula = sum("Time Sheet Detail".Quantity where("Time Sheet No." = field("Time Sheet No."),
                                                                  "Time Sheet Line No." = field("Line No.")));
            Caption = 'Total Quantity';
            Editable = false;
            FieldClass = FlowField;
        }
        field(17; Chargeable; Boolean)
        {
            Caption = 'Chargeable';
            InitValue = true;
        }
        field(18; "Assembly Order No."; Code[20])
        {
            Caption = 'Assembly Order No.';
            Editable = false;
            TableRelation = if (Posted = const(false)) "Assembly Header"."No." where("Document Type" = const(Order));
        }
        field(19; "Assembly Order Line No."; Integer)
        {
            Caption = 'Assembly Order Line No.';
            Editable = false;
        }
        field(20; Status; Enum "Time Sheet Status")
        {
            Caption = 'Status';
            Editable = false;
        }
        field(21; "Approved By"; Code[50])
        {
            Caption = 'Approved By';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = "User Setup";
        }
        field(22; "Approval Date"; Date)
        {
            Caption = 'Approval Date';
            Editable = false;
        }
        field(23; Posted; Boolean)
        {
            Caption = 'Posted';
            Editable = false;
        }
        field(26; Comment; Boolean)
        {
            CalcFormula = exist("Time Sheet Comment Line" where("No." = field("Time Sheet No."),
                                                                 "Time Sheet Line No." = field("Line No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(8002; "Job Id"; Guid)
        {
            Caption = 'Project Id';
            DataClassification = SystemMetadata;
            TableRelation = Job.SystemId;
        }
    }

    keys
    {
        key(Key1; "Time Sheet No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; Type)
        {
        }
        key(Key3; "Time Sheet No.", Status, Posted)
        {
        }
        key(Key4; Type, "Job No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; Type, Description, "Total Quantity", Status)
        {
        }
        fieldgroup(Brick; Type, Description, "Total Quantity", Status)
        {
        }
    }

    trigger OnDelete()
    var
        TimeSheetCommentLine: Record "Time Sheet Comment Line";
        Resource: Record Resource;
    begin
        TestStatus();

        GetTimeSheetResource(Resource);
        CheckResourcePrivacyBlocked(Resource);
        Resource.TestField(Blocked, false);

        TimeSheetDetail.SetRange("Time Sheet No.", "Time Sheet No.");
        TimeSheetDetail.SetRange("Time Sheet Line No.", "Line No.");
        TimeSheetDetail.DeleteAll();

        TimeSheetCommentLine.SetRange("No.", "Time Sheet No.");
        TimeSheetCommentLine.SetRange("Time Sheet Line No.", "Line No.");
        TimeSheetCommentLine.DeleteAll();
    end;

    trigger OnInsert()
    var
        Resource: Record Resource;
    begin
        GetTimeSheetResource(Resource);
        CheckResourcePrivacyBlocked(Resource);
        Resource.TestField(Blocked, false);

        UpdateApproverID();
        "Time Sheet Starting Date" := TimeSheetHeader."Starting Date";
    end;

    trigger OnModify()
    var
        Resource: Record Resource;
    begin
        GetTimeSheetResource(Resource);
        CheckResourcePrivacyBlocked(Resource);
        Resource.TestField(Blocked, false);

        UpdateDetails();
    end;

    var
        ResourcesSetup: Record "Resources Setup";
        Job: Record Job;
        JobTask: Record "Job Task";
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetDetail: Record "Time Sheet Detail";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'There is no employee linked with resource %1.';
        Text002: Label 'Status must be Open or Rejected in line with Time Sheet No.=''%1'', Line No.=''%2''.';
#pragma warning restore AA0470
        Text005: Label 'Select a type before you enter an activity.';
#pragma warning restore AA0074
        PrivacyBlockedErr: Label 'You cannot use resource %1 because they are marked as blocked due to privacy.', Comment = '%1=resource no.';

    procedure TestStatus()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestStatus(IsHandled, Rec);
        if IsHandled then
            exit;

        if not (Status in [Status::Open, Status::Rejected]) then
            Error(
              Text002,
              "Time Sheet No.",
              "Line No.");
    end;

    local procedure CheckIsEmployeeLinkedToResource()
    var
        Resource: Record Resource;
        Employee: Record Employee;
    begin
        GetTimeSheetResource(Resource);
        Resource.TestField("Base Unit of Measure");
        Resource.TestField(Type, Resource.Type::Person);
        Employee.Reset();
        Employee.SetRange("Resource No.", TimeSheetHeader."Resource No.");
        if Employee.IsEmpty() then
            Error(Text001, TimeSheetHeader."Resource No.");
    end;

    local procedure UpdateDetails()
    var
        TimeSheetDetail: Record "Time Sheet Detail";
    begin
        TimeSheetDetail.SetRange("Time Sheet No.", "Time Sheet No.");
        TimeSheetDetail.SetRange("Time Sheet Line No.", "Line No.");
        if TimeSheetDetail.FindSet(true) then
            repeat
                TimeSheetDetail.CopyFromTimeSheetLine(Rec);
                TimeSheetDetail.Modify(true);
            until TimeSheetDetail.Next() = 0;
    end;

    local procedure GetTimeSheetResource(var Resource: Record Resource)
    begin
        TimeSheetHeader.Get("Time Sheet No.");
        Resource.Get(TimeSheetHeader."Resource No.");
    end;

    local procedure GetJobApproverID() ApproverID: Code[50]
    var
        Resource: Record Resource;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetJobApproverID(ApproverID, IsHandled);
        if IsHandled then
            exit(ApproverID);

        Job.Get("Job No.");
        Job.TestField("Person Responsible");
        Resource.Get(Job."Person Responsible");
        Resource.TestField("Time Sheet Owner User ID");
        exit(Resource."Time Sheet Owner User ID");
    end;

    procedure UpdateApproverID()
    var
        Resource: Record Resource;
    begin
        ResourcesSetup.Get();
        GetTimeSheetResource(Resource);
        if (Type = Type::Job) and ("Job No." <> '') and
           (((Resource.Type = Resource.Type::Person) and
             (ResourcesSetup."Time Sheet by Job Approval" = ResourcesSetup."Time Sheet by Job Approval"::Always)) or
            ((Resource.Type = Resource.Type::Machine) and
             (ResourcesSetup."Time Sheet by Job Approval" in [ResourcesSetup."Time Sheet by Job Approval"::"Machine Only",
                                                              ResourcesSetup."Time Sheet by Job Approval"::Always])))
        then
            "Approver ID" := GetJobApproverID()
        else
            SetApproverIDFromResource(Resource);
        OnAfterUpdateApproverID(Rec);
    end;

    local procedure SetApproverIDFromResource(Resource: Record Resource)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetApproverIDFromResource(Resource, IsHandled);
        if IsHandled then
            exit;

        Resource.TestField("Time Sheet Approver User ID");
        "Approver ID" := Resource."Time Sheet Approver User ID";
    end;

    local procedure CheckWorkType()
    var
        Resource: Record Resource;
        WorkType: Record "Work Type";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckWorkType(Rec, IsHandled);
        if IsHandled then
            exit;

        if WorkType.Get("Work Type Code") then begin
            GetTimeSheetResource(Resource);
            WorkType.TestField("Unit of Measure Code", Resource."Base Unit of Measure");
        end;
    end;

    procedure ShowLineDetails(ManagerRole: Boolean)
    var
        TimeSheetLineResDetail: Page "Time Sheet Line Res. Detail";
        TimeSheetLineJobDetail: Page "Time Sheet Line Job Detail";
        TimeSheetLineAssembDetail: Page "Time Sheet Line Assemb. Detail";
        TimeSheetLineAbsenceDetail: Page "Time Sheet Line Absence Detail";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowLineDetails(Rec, IsHandled, ManagerRole);
        if IsHandled then
            exit;

        case Type of
            Type::Resource:
                begin
                    TimeSheetLineResDetail.SetParameters(Rec, ManagerRole);
                    if TimeSheetLineResDetail.RunModal() = ACTION::OK then
                        TimeSheetLineResDetail.GetRecord(Rec);
                end;
            Type::Job:
                begin
                    TimeSheetLineJobDetail.SetParameters(Rec, ManagerRole);
                    if TimeSheetLineJobDetail.RunModal() = ACTION::OK then
                        TimeSheetLineJobDetail.GetRecord(Rec);
                end;
            Type::Absence:
                begin
                    TimeSheetLineAbsenceDetail.SetParameters(Rec, ManagerRole);
                    if TimeSheetLineAbsenceDetail.RunModal() = ACTION::OK then
                        TimeSheetLineAbsenceDetail.GetRecord(Rec);
                end;
            Type::"Assembly Order":
                begin
                    TimeSheetLineAssembDetail.SetParameters(Rec);
                    if TimeSheetLineAssembDetail.RunModal() = ACTION::OK then
                        TimeSheetLineAssembDetail.GetRecord(Rec);
                end;
            else
                Error(Text005);
        end;
        Modify();
    end;

    procedure GetAllowEdit(FldNo: Integer; ManagerRole: Boolean) AllowEdit: Boolean
    begin
        if ManagerRole then
            AllowEdit := (FldNo in [FieldNo("Work Type Code"), FieldNo(Chargeable)]) and (Status = Status::Submitted)
        else
            AllowEdit := Status in [Status::Open, Status::Rejected];

        OnAfterGetAllowEdit(FldNo, ManagerRole, AllowEdit);
    end;

    local procedure CheckResourcePrivacyBlocked(Resource: Record Resource)
    begin
        if Resource."Privacy Blocked" then
            Error(PrivacyBlockedErr, Resource."No.");
    end;

    procedure CheckIfTimeSheetLineLinkExist(Job: Record Job)
    var
        TimeSheetLineExistsForJobErr: Label 'One or more unposted Time Sheet lines exists for the project %1.\\You must post or delete the time sheet lines before you can change the project status.', Comment = '%1 = Project No.';
    begin
        if Job.Status = Job.Status::Open then
            exit;

        SetCurrentKey(Type, "Job No.");
        SetRange(Type, Type::Job);
        SetRange("Job No.", Job."No.");
        SetRange(Posted, false);
        if not IsEmpty() then
            Error(TimeSheetLineExistsForJobErr, Job."No.");
    end;

    [Scope('OnPrem')]
    procedure UpdateJobId()
    var
        Job: Record Job;
    begin
        if "Job No." = '' then begin
            Clear("Job Id");
            exit;
        end;

        if not Job.Get("Job No.") then
            exit;

        "Job Id" := Job.SystemId;
    end;

    procedure SetExclusionTypeFilter()
    begin
        SetFilter(Type, '<>%1', Type::"Assembly Order");

        OnAfterSetExclusionTypeFilter(Rec);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateApproverID(var TimeSheetLine: Record "Time Sheet Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeTestStatus(var IsHandled: Boolean; var TimeSheetLine: Record "Time Sheet Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeGetJobApproverID(var ApproverID: Code[50]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeSetApproverIDFromResource(Resource: Record Resource; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowLineDetails(var TimeSheetLine: Record "Time Sheet Line"; var IsHandled: Boolean; ManagerRole: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterGetAllowEdit(FldNo: Integer; ManagerRole: Boolean; var AllowEdit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckWorkType(var TimeSheetLine: Record "Time Sheet Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateTypeOnAfterClearFields(var TimeSheetLine: Record "Time Sheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetExclusionTypeFilter(var TimeSheetLine: Record "Time Sheet Line")
    begin
    end;
}

