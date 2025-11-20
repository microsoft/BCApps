// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.TimeSheet;

using Microsoft.Assembly.Document;
using Microsoft.HumanResources.Absence;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Resources.Resource;

table 956 "Time Sheet Detail Archive"
{
    Caption = 'Time Sheet Detail Archive';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Time Sheet No."; Code[20])
        {
            Caption = 'Time Sheet No.';
            TableRelation = "Time Sheet Header Archive";
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
        field(24; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(25; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
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
            SumIndexFields = Quantity;
        }
    }

    fieldgroups
    {
    }
}

