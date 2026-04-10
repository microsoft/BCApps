// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.RoleCenters;

using Microsoft.Foundation.NoSeries;
using Microsoft.Integration.Dataverse;
using Microsoft.Integration.SyncEngine;
using System.Security.User;
using System.Threading;

table 9059 "Administration Cue"
{
    Caption = 'Administration Cue';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
        }
        field(2; "Job Queue Entries Until Today"; Integer)
        {
            CalcFormula = count("Job Queue Entry" where("Earliest Start Date/Time" = field("Date Filter2"),
                                                         "Expiration Date/Time" = field("Date Filter3")));
            Caption = 'Job Queue Entries Until Today';
            FieldClass = FlowField;
        }
        field(3; "User Posting Period"; Integer)
        {
            CalcFormula = count("User Setup" where("Allow Posting To" = field("Date Filter")));
            Caption = 'User Posting Period';
            FieldClass = FlowField;
        }
        field(4; "No. Series Period"; Integer)
        {
            CalcFormula = count("No. Series Line" where("Last Date Used" = field("Date Filter")));
            Caption = 'No. Series Period';
            FieldClass = FlowField;
        }
        field(20; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            Editable = false;
            FieldClass = FlowFilter;
        }
        field(21; "Date Filter2"; DateTime)
        {
            Caption = 'Date Filter2';
            Editable = false;
            FieldClass = FlowFilter;
        }
        field(22; "Date Filter3"; DateTime)
        {
            Caption = 'Date Filter3';
            Editable = false;
            FieldClass = FlowFilter;
        }
        field(23; "User ID Filter"; Code[50])
        {
            Caption = 'User ID Filter';
            FieldClass = FlowFilter;
        }
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
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

