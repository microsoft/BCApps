// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

table 8361 "Financial Report Export Log"
{
    Caption = 'Financial Report Export Log';
    DataClassification = CustomerContent;
    LookupPageId = "Financial Report Export Logs";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Entry No.';
            ToolTip = 'Specifies the entry number.';
        }
        field(2; "Financial Report Name"; Code[10])
        {
            Caption = 'Financial Report Name';
            TableRelation = "Financial Report";
            ToolTip = 'Specifies the financial report name.';
        }
        field(3; "Financial Report Schedule Code"; Code[20])
        {
            Caption = 'Financial Report Schedule Code';
            TableRelation = "Financial Report Schedule".Code where("Financial Report Name" = field("Financial Report Name"));
            ToolTip = 'Specifies the financial report schedule code.';
        }
        field(4; "Start Date/Time"; DateTime)
        {
            Caption = 'Start Date/Time';
            ToolTip = 'Specifies the start date and time when the schedule was processed.';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(PerSchedule; "Financial Report Name", "Financial Report Schedule Code", "Start Date/Time") { }
    }
}