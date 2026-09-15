// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

table 8375 "Fin. Rep. Package Export Log"
{
    Caption = 'Financial Report Package Export Log';
    DataClassification = CustomerContent;
    LookupPageId = "Fin. Rep. Package Export Logs";
    DrillDownPageId = "Fin. Rep. Package Export Logs";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Entry No.';
            ToolTip = 'Specifies the entry number.';
            DataClassification = SystemMetadata;
        }
        field(2; "Package Code"; Code[20])
        {
            Caption = 'Package Code';
            TableRelation = "Financial Report Package".Code;
            ToolTip = 'Specifies the financial report package that was processed.';
            DataClassification = CustomerContent;
        }
        field(3; "Schedule Code"; Code[20])
        {
            Caption = 'Schedule Code';
            TableRelation = "Fin. Report Package Schedule"."Schedule Code" where("Package Code" = field("Package Code"));
            ToolTip = 'Specifies the financial report package schedule that was processed.';
            DataClassification = CustomerContent;
        }
        field(4; "Start Date/Time"; DateTime)
        {
            Caption = 'Start Date/Time';
            ToolTip = 'Specifies the start date and time when the package was processed.';
            DataClassification = SystemMetadata;
        }
    }
}