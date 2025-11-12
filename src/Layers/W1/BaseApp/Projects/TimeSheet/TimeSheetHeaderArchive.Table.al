// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.TimeSheet;

using Microsoft.Projects.Resources.Resource;
using System.Security.User;

table 954 "Time Sheet Header Archive"
{
    Caption = 'Time Sheet Header Archive';
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
        field(20; Quantity; Decimal)
        {
            CalcFormula = sum("Time Sheet Detail Archive".Quantity where("Time Sheet No." = field("No."),
                                                                          Status = field("Status Filter"),
                                                                          "Job No." = field("Job No. Filter"),
                                                                          "Job Task No." = field("Job Task No. Filter"),
                                                                          Date = field("Date Filter"),
                                                                          Posted = field("Posted Filter"),
                                                                          Type = field("Type Filter")));
            Caption = 'Quantity';
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
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", "Starting Date", "Ending Date", "Resource No.")
        {
        }
    }

    trigger OnDelete()
    var
        TimeSheetLineArchive: Record "Time Sheet Line Archive";
        TimeSheetCmtLineArchive: Record "Time Sheet Cmt. Line Archive";
    begin
        TimeSheetLineArchive.SetRange("Time Sheet No.", "No.");
        TimeSheetLineArchive.DeleteAll(true);

        TimeSheetCmtLineArchive.SetRange("No.", "No.");
        TimeSheetCmtLineArchive.SetRange("Time Sheet Line No.", 0);
        TimeSheetCmtLineArchive.DeleteAll();
    end;

    var
        TimeSheetMgt: Codeunit "Time Sheet Management";

    procedure FindLastTimeSheetArchiveNo(FilterFieldNo: Integer): Code[20]
    begin
        Reset();
        SetCurrentKey("Resource No.", "Starting Date");

        TimeSheetMgt.FilterTimeSheetsArchive(Rec, FilterFieldNo);
        SetFilter("Starting Date", '%1..', WorkDate());
        if not FindFirst() then begin
            SetRange("Starting Date");
            SetRange("Ending Date");
            FindLast();
        end;
        exit("No.");
    end;
}

