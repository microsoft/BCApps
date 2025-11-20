// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.TimeSheet;

using Microsoft.Assembly.Document;
using Microsoft.HumanResources.Absence;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Resources.Resource;

table 952 "Time Sheet Detail"
{
    Caption = 'Time Sheet Detail';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Time Sheet No."; Code[20])
        {
            Caption = 'Time Sheet No.';
            TableRelation = "Time Sheet Header";
        }
        field(2; "Time Sheet Line No."; Integer)
        {
            Caption = 'Time Sheet Line No.';
        }
        field(3; Date; Date)
        {
            Caption = 'Date';
        }
        field(4; Type; Enum "Time Sheet Line Type")
        {
            Caption = 'Type';
        }
        field(5; "Resource No."; Code[20])
        {
            Caption = 'Resource No.';
            TableRelation = Resource;
        }
        field(6; "Job No."; Code[20])
        {
            Caption = 'Project No.';
            TableRelation = Job;
        }
        field(7; "Job Task No."; Code[20])
        {
            Caption = 'Project Task No.';
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));
        }
        field(9; "Cause of Absence Code"; Code[10])
        {
            Caption = 'Cause of Absence Code';
            TableRelation = "Cause of Absence";
        }
        field(15; Quantity; Decimal)
        {
            Caption = 'Quantity';
            Editable = false;
        }
        field(16; "Posted Quantity"; Decimal)
        {
            Caption = 'Posted Quantity';
        }
        field(18; "Assembly Order No."; Code[20])
        {
            Caption = 'Assembly Order No.';
            TableRelation = if (Posted = const(false)) "Assembly Header"."No." where("Document Type" = const(Order));
        }
        field(19; "Assembly Order Line No."; Integer)
        {
            Caption = 'Assembly Order Line No.';
        }
        field(20; Status; Enum "Time Sheet Status")
        {
            Caption = 'Status';
        }
        field(23; Posted; Boolean)
        {
            Caption = 'Posted';
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(8001; "Last Modified DateTime"; DateTime)
        {
            Caption = 'Last Modified DateTime';
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
        key(Key1; "Time Sheet No.", "Time Sheet Line No.", Date)
        {
            Clustered = true;
        }
        key(Key2; Type, "Job No.", "Job Task No.", Status, Posted)
        {
            IncludedFields = Quantity;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        TimeSheetMgt.CheckAccPeriod(Date);
        SetLastModifiedDateTime();
        SetDimension();
    end;

    trigger OnModify()
    begin
        TimeSheetMgt.CheckAccPeriod(Date);
        SetLastModifiedDateTime();
    end;

    trigger OnRename()
    begin
        SetLastModifiedDateTime();
    end;

    var
        TimeSheetMgt: Codeunit "Time Sheet Management";

    procedure CopyFromTimeSheetLine(TimeSheetLine: Record "Time Sheet Line")
    begin
        "Time Sheet No." := TimeSheetLine."Time Sheet No.";
        "Time Sheet Line No." := TimeSheetLine."Line No.";
        Type := TimeSheetLine.Type;
        "Job No." := TimeSheetLine."Job No.";
        "Job Id" := TimeSheetLine."Job Id";
        "Job Task No." := TimeSheetLine."Job Task No.";
        "Cause of Absence Code" := TimeSheetLine."Cause of Absence Code";
        "Assembly Order No." := TimeSheetLine."Assembly Order No.";
        "Assembly Order Line No." := TimeSheetLine."Assembly Order Line No.";
        Status := TimeSheetLine.Status;
        "Dimension Set ID" := TimeSheetLine."Dimension Set ID";

        OnAfterCopyFromTimeSheetLine(Rec, TimeSheetLine);
    end;

    procedure SetDimension()
    var
        TimeSheetLine: Record "Time Sheet Line";
    begin
        if TimeSheetLine.Get("Time Sheet No.", "Time Sheet Line No.") then
            if "Dimension Set ID" = 0 then
                "Dimension Set ID" := TimeSheetLine."Dimension Set ID";
    end;

    procedure GetMaxQtyToPost(): Decimal
    begin
        exit(Quantity - "Posted Quantity");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromTimeSheetLine(var TimeSheetDetail: Record "Time Sheet Detail"; TimeSheetLine: Record "Time Sheet Line")
    begin
    end;

    local procedure SetLastModifiedDateTime()
    begin
        "Last Modified DateTime" := CurrentDateTime;
    end;
}
