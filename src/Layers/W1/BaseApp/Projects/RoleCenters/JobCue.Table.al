// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.RoleCenters;

using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Integration.Dataverse;
using Microsoft.Integration.SyncEngine;

table 9057 "Job Cue"
{
    Caption = 'Project Cue';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
        }
        field(2; "Jobs w/o Resource"; Integer)
        {
            CalcFormula = count(Job where("Scheduled Res. Qty." = filter(0)));
            Caption = 'Projects w/o Resource';
            Editable = false;
            FieldClass = FlowField;
        }
        field(3; "Upcoming Invoices"; Integer)
        {
            CalcFormula = count(Job where(Status = filter(Planning | Quote | Open),
                                           "Next Invoice Date" = field("Date Filter")));
            Caption = 'Upcoming Invoices';
            Editable = false;
            FieldClass = FlowField;
        }
        field(4; "Invoices Due - Not Created"; Integer)
        {
            CalcFormula = count(Job where(Status = const(Open),
                                           "Next Invoice Date" = field("Date Filter2")));
            Caption = 'Invoices Due - Not Created';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; "WIP Not Posted"; Integer)
        {
            CalcFormula = count(Job where("WIP Entries Exist" = const(true)));
            Caption = 'WIP Not Posted';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; "Completed - WIP Not Calculated"; Integer)
        {
            CalcFormula = count(Job where(Status = filter(Completed),
                                           "WIP Completion Calculated" = const(false),
                                           "WIP Completion Posted" = const(false)));
            Caption = 'Completed - WIP Not Calculated';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7; "Available Resources"; Integer)
        {
            CalcFormula = count(Resource where("Qty. on Order (Job)" = filter(0),
                                                "Qty. Quoted (Job)" = filter(0),
#if not CLEAN25
                                                "Qty. on Service Order" = filter(0),
#endif
                                                "Date Filter" = field("Date Filter")));
            Caption = 'Available Resources';
            Editable = false;
            FieldClass = FlowField;
        }
        field(8; "Unassigned Resource Groups"; Integer)
        {
            CalcFormula = count("Resource Group" where("No. of Resources Assigned" = filter(0)));
            Caption = 'Unassigned Resource Groups';
            Editable = false;
            FieldClass = FlowField;
        }
        field(9; "Jobs Over Budget"; Integer)
        {
            CalcFormula = count(Job where("Over Budget" = filter(= true)));
            Caption = 'Projects Over Budget';
            Editable = false;
            FieldClass = FlowField;
        }
        field(20; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            Editable = false;
            FieldClass = FlowFilter;
        }
        field(21; "Date Filter2"; Date)
        {
            Caption = 'Date Filter2';
            Editable = false;
            FieldClass = FlowFilter;
        }
        field(22; "User ID Filter"; Code[50])
        {
            Caption = 'User ID Filter';
            FieldClass = FlowFilter;
        }
#if not CLEANSCHEMA28
        field(24; "Coupled Data Synch Errors"; Integer)
        {
            CalcFormula = count("CRM Integration Record" where(Skipped = const(true)));
            Caption = 'Coupled Data Synch Errors';
            FieldClass = FlowField;
            ObsoleteReason = 'Field Service is moved to Field Service Integration app.';
#if not CLEAN25
            ObsoleteState = Pending;
            ObsoleteTag = '25.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '28.0';
#endif
        }
        field(25; "FS Integration Errors"; Integer)
        {
            CalcFormula = count("Integration Synch. Job Errors");
            Caption = 'Field Service Integration Errors';
            FieldClass = FlowField;
            ObsoleteReason = 'Field Service is moved to Field Service Integration app.';
#if not CLEAN25
            ObsoleteState = Pending;
            ObsoleteTag = '25.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '28.0';
#endif
        }
#endif
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

