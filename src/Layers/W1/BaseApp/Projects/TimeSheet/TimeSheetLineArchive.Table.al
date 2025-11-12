// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.TimeSheet;

using Microsoft.Assembly.Document;
using Microsoft.HumanResources.Absence;
using Microsoft.Projects.Project.Job;
using Microsoft.Utilities;
using System.Security.User;

table 955 "Time Sheet Line Archive"
{
    Caption = 'Time Sheet Line Archive';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Time Sheet No."; Code[20])
        {
            Caption = 'Time Sheet No.';
            TableRelation = "Time Sheet Header Archive";
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
        field(10; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(11; "Work Type Code"; Code[10])
        {
            Caption = 'Work Type Code';
            TableRelation = "Work Type";
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
        field(15; "Total Quantity"; Decimal)
        {
            CalcFormula = sum("Time Sheet Detail Archive".Quantity where("Time Sheet No." = field("Time Sheet No."),
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
            TableRelation = if (Posted = const(false)) "Assembly Header"."No." where("Document Type" = const(Order));
        }
        field(19; "Assembly Order Line No."; Integer)
        {
            Caption = 'Assembly Order Line No.';
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
    }

    keys
    {
        key(Key1; "Time Sheet No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        TimeSheetDetailArchive: Record "Time Sheet Detail Archive";
        TimeSheetCmtLineArchive: Record "Time Sheet Cmt. Line Archive";
    begin
        TimeSheetDetailArchive.SetRange("Time Sheet No.", "Time Sheet No.");
        TimeSheetDetailArchive.SetRange("Time Sheet Line No.", "Line No.");
        TimeSheetDetailArchive.DeleteAll();

        TimeSheetCmtLineArchive.SetRange("No.", "Time Sheet No.");
        TimeSheetCmtLineArchive.SetRange("Time Sheet Line No.", "Line No.");
        TimeSheetCmtLineArchive.DeleteAll();
    end;

    procedure SetExclusionTypeFilter()
    begin
        SetFilter(Type, '<>%1', Type::"Assembly Order");

        OnAfterSetExclusionTypeFilter(Rec);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetExclusionTypeFilter(var TimeSheetLineArchive: Record "Time Sheet Line Archive")
    begin
    end;
}

