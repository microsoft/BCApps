// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting.FileNaming;

table 8127 "Report Filename Table Buffer"
{
    // Tables that some non-processing report is about (Report Filename Mgt.SubjectTableNo), each
    // with its number of reports, which a filter on Table Metadata could not carry.

    Caption = 'Report Filename Table Buffer';
    TableType = Temporary;
    Access = Internal;
    Extensible = false;

    fields
    {
        field(1; "Table No."; Integer)
        {
            Caption = 'Table No.';
        }
        field(2; "Table Caption"; Text[250])
        {
            Caption = 'Table Caption';
            ToolTip = 'Specifies the table a pattern would apply to.';
        }
        field(3; "Report Count"; Integer)
        {
            Caption = 'Reports';
            ToolTip = 'Specifies how many reports are based on this table.';
        }
    }

    keys
    {
        key(PK; "Table No.")
        {
            Clustered = true;
        }
        key(ByName; "Table Caption")
        {
        }
    }
}
