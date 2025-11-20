// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.TimeSheet;

using Microsoft.Projects.Resources.Resource;
using Microsoft.Projects.Resources.Setup;
using System.Security.User;

table 950 "Time Sheet Header"
{
    Caption = 'Time Sheet Header';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(3; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
        }
        field(4; "Ending Date"; Date)
        {
            Caption = 'Ending Date';
        }
        field(5; "Resource No."; Code[20])
        {
            Caption = 'Resource No.';
            TableRelation = Resource;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                ResourcesSetup.Get();
                if "Resource No." <> '' then begin
                    Resource.Get("Resource No.");
                    CheckResourcePrivacyBlocked(Resource);

                    IsHandled := false;
                    OnValidateResourceNoOnBeforeTestFields(Resource, IsHandled);
                    if IsHandled then
                        exit;

                    Resource.TestField(Blocked, false);
                    Resource.TestField("Time Sheet Owner User ID");
                    Resource.TestField("Time Sheet Approver User ID");
                    "Owner User ID" := Resource."Time Sheet Owner User ID";
                    "Approver User ID" := Resource."Time Sheet Approver User ID";
                end;
            end;
        }
        field(6; "Resource Name"; Text[100])
        {
            Caption = 'Resource Name';
            FieldClass = FlowField;
            CalcFormula = lookup(Resource.Name where("No." = field("Resource No.")));
            Editable = false;
        }
        field(7; "Owner User ID"; Code[50])
        {
            Caption = 'Owner User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "User Setup";
        }
        field(8; "Approver User ID"; Code[50])
        {
            Caption = 'Approver User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "User Setup";
        }
        field(10; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
        field(11; "Unit of Measure"; Code[10])
        {
            CalcFormula = lookup(Resource."Base Unit of Measure" where("No." = field("Resource No.")));
            Caption = 'Unit of Measure';
            FieldClass = FlowField;
            Editable = false;
        }
        field(12; "Open Exists"; Boolean)
        {
            CalcFormula = exist("Time Sheet Line" where("Time Sheet No." = field("No."),
                                                         Status = const(Open)));
            Caption = 'Open Exists';
            Editable = false;
            FieldClass = FlowField;
        }
        field(13; "Submitted Exists"; Boolean)
        {
            CalcFormula = exist("Time Sheet Line" where("Time Sheet No." = field("No."),
                                                         Status = const(Submitted)));
            Caption = 'Submitted Exists';
            Editable = false;
            FieldClass = FlowField;
        }
        field(14; "Rejected Exists"; Boolean)
        {
            CalcFormula = exist("Time Sheet Line" where("Time Sheet No." = field("No."),
                                                         Status = const(Rejected)));
            Caption = 'Rejected Exists';
            Editable = false;
            FieldClass = FlowField;
        }
        field(15; "Approved Exists"; Boolean)
        {
            CalcFormula = exist("Time Sheet Line" where("Time Sheet No." = field("No."),
                                                         Status = const(Approved)));
            Caption = 'Approved Exists';
            Editable = false;
            FieldClass = FlowField;
        }
        field(16; "Posted Exists"; Boolean)
        {
            CalcFormula = exist("Time Sheet Posting Entry" where("Time Sheet No." = field("No.")));
            Caption = 'Posted Exists';
            Editable = false;
            FieldClass = FlowField;
        }
        field(18; "Lines Exist"; Boolean)
        {
            CalcFormula = exist("Time Sheet Line" where("Time Sheet No." = field("No.")));
            Caption = 'Lines Exist';
            Editable = false;
            FieldClass = FlowField;
        }
        field(20; Quantity; Decimal)
        {
            CalcFormula = sum("Time Sheet Detail".Quantity where("Time Sheet No." = field("No."),
                                                                  Status = field("Status Filter"),
                                                                  "Job No." = field("Job No. Filter"),
                                                                  "Job Task No." = field("Job Task No. Filter"),
                                                                  Date = field("Date Filter"),
                                                                  Posted = field("Posted Filter"),
                                                                  Type = field("Type Filter")));
            Caption = 'Quantity';
            FieldClass = FlowField;
        }
        field(21; "Posted Quantity"; Decimal)
        {
            CalcFormula = sum("Time Sheet Posting Entry".Quantity where("Time Sheet No." = field("No.")));
            Caption = 'Posted Quantity';
            FieldClass = FlowField;
        }
        field(26; Comment; Boolean)
        {
            CalcFormula = exist("Time Sheet Comment Line" where("No." = field("No."),
                                                                 "Time Sheet Line No." = const(0)));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(30; "Status Filter"; Enum "Time Sheet Status")
        {
            Caption = 'Status Filter';
            FieldClass = FlowFilter;
        }
        field(31; "Job No. Filter"; Code[20])
        {
            Caption = 'Project No. Filter';
            FieldClass = FlowFilter;
        }
        field(32; "Job Task No. Filter"; Code[20])
        {
            Caption = 'Project Task No. Filter';
            FieldClass = FlowFilter;
        }
        field(33; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(34; "Posted Filter"; Boolean)
        {
            Caption = 'Posted Filter';
            FieldClass = FlowFilter;
        }
        field(35; "Type Filter"; Enum "Time Sheet Line Type")
        {
            Caption = 'Type Filter';
            FieldClass = FlowFilter;
        }
        field(40; "Quantity Open"; Decimal)
        {
            CalcFormula = sum("Time Sheet Detail".Quantity where("Time Sheet No." = field("No."),
                                                         Status = const(Open)));
            Caption = 'Quantity Open';
            Editable = false;
            FieldClass = FlowField;
        }
        field(41; "Quantity Submitted"; Decimal)
        {
            CalcFormula = sum("Time Sheet Detail".Quantity where("Time Sheet No." = field("No."),
                                                         Status = const(Submitted)));
            Caption = 'Quantity Submitted';
            Editable = false;
            FieldClass = FlowField;
        }
        field(42; "Quantity Approved"; Decimal)
        {
            CalcFormula = sum("Time Sheet Detail".Quantity where("Time Sheet No." = field("No."),
                                                         Status = const(Approved)));
            Caption = 'Quantity Approved';
            Editable = false;
            FieldClass = FlowField;
        }
        field(43; "Quantity Rejected"; Decimal)
        {
            CalcFormula = sum("Time Sheet Detail".Quantity where("Time Sheet No." = field("No."),
                                                         Status = const(Rejected)));
            Caption = 'Quantity Rejected';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Resource No.", "Starting Date")
        {
        }
        key(Key3; "Owner User ID")
        {
        }
        key(Key4; "Approver User ID")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", "Starting Date", "Ending Date", "Resource No.")
        {
        }
        fieldgroup(Brick; "No.", "Starting Date", "Ending Date", "Resource No.", Quantity)
        {
        }
    }

    trigger OnDelete()
    var
        TimeSheetCommentLine: Record "Time Sheet Comment Line";
    begin
        if "Resource No." <> '' then begin
            Resource.Get("Resource No.");
            CheckResourcePrivacyBlocked(Resource);
            Resource.TestField(Blocked, false);
        end;

        TimeSheetLine.SetRange("Time Sheet No.", "No.");
        TimeSheetLine.DeleteAll(true);

        TimeSheetCommentLine.SetRange("No.", "No.");
        TimeSheetCommentLine.SetRange("Time Sheet Line No.", 0);
        TimeSheetCommentLine.DeleteAll();

        RemoveFromMyTimeSheets();
    end;

    trigger OnInsert()
    begin
        if "Resource No." <> '' then begin
            Resource.Get("Resource No.");
            CheckResourcePrivacyBlocked(Resource);
            Resource.TestField(Blocked, false);
            if Resource."Time Sheet Owner User ID" <> '' then
                AddToMyTimeSheets(Resource."Time Sheet Owner User ID");
        end;
    end;

    trigger OnModify()
    begin
        if "Resource No." <> '' then begin
            Resource.Get("Resource No.");
            CheckResourcePrivacyBlocked(Resource);
            Resource.TestField(Blocked, false);
        end;
    end;

    trigger OnRename()
    begin
        if "Resource No." <> '' then begin
            Resource.Get("Resource No.");
            CheckResourcePrivacyBlocked(Resource);
            Resource.TestField(Blocked, false);
        end;
    end;

    var
        Resource: Record Resource;
        ResourcesSetup: Record "Resources Setup";
        TimeSheetLine: Record "Time Sheet Line";
        TimeSheetMgt: Codeunit "Time Sheet Management";

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label '%1 does not contain lines.';
#pragma warning restore AA0470
        Text002: Label 'No time sheets are available. The time sheet administrator must create time sheets before you can access them in this window.';
#pragma warning restore AA0074
        PrivacyBlockedErr: Label 'You cannot use resource %1 because they are marked as blocked due to privacy.', Comment = '%1=resource no.';

    procedure CalcQtyWithStatus(Status: Enum "Time Sheet Status"): Decimal
    begin
        SetRange("Status Filter", Status);
        CalcFields(Quantity);
        exit(Quantity);
    end;

    procedure Check()
    begin
        TimeSheetLine.SetRange("Time Sheet No.", "No.");
        if TimeSheetLine.FindSet() then
            repeat
                CheckTimeSheetLine(TimeSheetLine);
            until TimeSheetLine.Next() = 0
        else
            Error(Text001, "No.");
    end;

    local procedure CheckTimeSheetLine(TimeSheetLine: Record "Time Sheet Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckTimeSheetLine(TimeSheetLine, IsHandled);
        if IsHandled then
            exit;

        TimeSheetLine.TestField(Status, TimeSheetLine.Status::Approved);
        TimeSheetLine.TestField(Posted, true);
    end;

    procedure GetLastLineNo(): Integer
    begin
        TimeSheetLine.Reset();
        TimeSheetLine.SetRange("Time Sheet No.", "No.");
        if TimeSheetLine.FindLast() then;
        exit(TimeSheetLine."Line No.");
    end;

    procedure FindLastTimeSheetNo(FilterFieldNo: Integer): Code[20]
    begin
        Reset();
        SetCurrentKey("Resource No.", "Starting Date");

        TimeSheetMgt.FilterTimeSheets(Rec, FilterFieldNo);
        SetFilter("Starting Date", '%1..', WorkDate());
        if FindFirst() then
            exit("No.");

        SetRange("Starting Date");
        SetRange("Ending Date");
        if FindLast() then
            exit("No.");

        Error(Text002);
    end;

    procedure FindCurrentTimeSheetNo(FilterFieldNo: Integer): Code[20]
    begin
        Reset();
        SetCurrentKey("Resource No.", "Starting Date");

        TimeSheetMgt.FilterTimeSheets(Rec, FilterFieldNo, true);
        if Rec.IsEmpty then
            Error(Text002);

        SetFilter("Starting Date", '..%1', WorkDate());
        if FindLast() then
            exit("No.");
    end;

    procedure FindTimeSheetList(FilterFieldNo: Integer): Code[20]
    begin
        Reset();
        SetCurrentKey("Resource No.", "Starting Date");

        TimeSheetMgt.FilterTimeSheets(Rec, FilterFieldNo);
    end;

    local procedure AddToMyTimeSheets(UserID: Code[50])
    var
        MyTimeSheets: Record "My Time Sheets";
    begin
        MyTimeSheets.Init();
        MyTimeSheets."User ID" := UserId;
        MyTimeSheets."Time Sheet No." := "No.";
        MyTimeSheets."Start Date" := "Starting Date";
        MyTimeSheets."End Date" := "Ending Date";
        MyTimeSheets.Comment := Comment;
        MyTimeSheets.Insert();
    end;

    local procedure RemoveFromMyTimeSheets()
    var
        MyTimeSheets: Record "My Time Sheets";
    begin
        MyTimeSheets.SetRange("Time Sheet No.", "No.");
        if MyTimeSheets.FindFirst() then
            MyTimeSheets.DeleteAll();
    end;

    local procedure CheckResourcePrivacyBlocked(Resource: Record Resource)
    begin
        if Resource."Privacy Blocked" then
            Error(PrivacyBlockedErr, Resource."No.");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckTimeSheetLine(TimeSheetLine: Record "Time Sheet Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnValidateResourceNoOnBeforeTestFields(Resource: Record Resource; var IsHandled: Boolean)
    begin
    end;
}

