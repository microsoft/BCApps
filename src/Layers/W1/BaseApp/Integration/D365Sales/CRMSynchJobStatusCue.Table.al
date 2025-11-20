// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Dataverse;

using System.Threading;

table 5370 "CRM Synch. Job Status Cue"
{
    Caption = 'CRM Synch. Job Status Cue';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(2; "Failed Synch. Jobs"; Integer)
        {
            CalcFormula = count("Job Queue Entry" where("Object ID to Run" = field("Object ID to Run"),
                                                         Status = const(Error),
                                                         "Last Ready State" = field("Date Filter")));
            Caption = 'Failed Synch. Jobs';
            FieldClass = FlowField;
        }
        field(6; "Date Filter"; DateTime)
        {
            Caption = 'Date Filter';
            Editable = false;
            FieldClass = FlowFilter;
        }
        field(7; "Reset Date"; DateTime)
        {
            Caption = 'Reset Date';
        }
        field(8; "Object ID to Run"; Integer)
        {
            Caption = 'Object ID to Run';
            FieldClass = FlowFilter;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

