// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using System.Security.AccessControl;

table 8390 "Financial Report Audit Log"
{
    Caption = 'Financial Report Audit Log';
    DataClassification = CustomerContent;
    DrillDownPageId = "Financial Report Audit Logs";
    LookupPageId = "Financial Report Audit Logs";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Entry No.';
            ToolTip = 'Specifies the entry number.';
        }
        field(2; "Report Name"; Code[10])
        {
            Caption = 'Financial Report Name';
            TableRelation = "Financial Report";
            Tooltip = 'Specifies the code of the report that was accessed.';
        }
        field(3; "Report Description"; Text[80])
        {
            Calcformula = lookup("Financial Report".Description where(Name = field("Report Name")));
            Caption = 'Financial Report Description';
            Editable = false;
            Fieldclass = FlowField;
            Tooltip = 'Specifies the description of the report that was accessed.';
        }
        field(4; User; Code[50])
        {
            Caption = 'User';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            Tooltip = 'Specifies the user who accessed the report.';
        }
        field(5; Format; Enum "Financial Report Format")
        {
            Caption = 'Format';
            Tooltip = 'Specifies the format in which the report was accessed.';
        }
        field(6; Scheduled; Boolean)
        {
            Caption = 'Scheduled';
            Tooltip = 'Specifies the report was accessed as part of a scheduled export.';
        }
        field(100; "Date Filter Type"; Enum "Fin. Rep. Aud. Log Date Filter")
        {
            Caption = 'Date Filter Type';
            FieldClass = FlowFilter;
            Tooltip = 'Specifies the type of date filter applied.';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(ReportUser; "Report Name", User, SystemCreatedAt)
        {
        }
    }
}