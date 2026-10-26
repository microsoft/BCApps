// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting.FileNaming;

table 8129 "Report Filename Record Buffer"
{
    // Records to test a pattern against, for tables with no lookup page (Table Metadata's
    // LookupPageID is 0). Each record is held by its RecordId.

    Caption = 'Report Filename Record Buffer';
    TableType = Temporary;
    Access = Internal;
    Extensible = false;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Record ID"; RecordId)
        {
            Caption = 'Record ID';
        }
        field(3; Description; Text[250])
        {
            Caption = 'Record';
            ToolTip = 'Specifies which record it is, by the values of its key fields.';
        }
        field(4; Details; Text[250])
        {
            Caption = 'Description';
            ToolTip = 'Specifies what the record is called, such as a customer''s name beside an invoice number.';
        }
        field(5; More; Text[250])
        {
            Caption = 'Date';
            ToolTip = 'Specifies the first date on the record, for telling apart two records that are otherwise alike.';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(ByDescription; Description)
        {
        }
    }
}
