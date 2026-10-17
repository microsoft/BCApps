// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
table 50112 "Report Filename Table Buffer"
{
    // The kinds of record a report can actually be about, so the lookup offers those and
    // nothing else.
    //
    // The lookup used to run straight over Table Metadata with no filter, which offered every
    // table in the system - buffers, session tables, setup tables, things no report is ever
    // about. Choosing one produced a pattern that could never match anything, and it
    // contradicted the rule the rest of this feature keeps: offer only what compiled metadata
    // says is real.
    //
    // A buffer rather than a filter on Table Metadata, because the set is derived by walking
    // every report's first data item and a filter listing several hundred table numbers would
    // be both enormous and fragile.

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
