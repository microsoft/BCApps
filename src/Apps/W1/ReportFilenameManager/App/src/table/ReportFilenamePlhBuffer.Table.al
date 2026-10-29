// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting.FileNaming;

table 8128 "Report Filename Plh. Buffer"
{
    // The placeholders available for one pattern. Which ones are listed depends on metadata only,
    // not on the records in the database.

    Caption = 'Report Filename Placeholder Buffer';
    TableType = Temporary;
    DataClassification = SystemMetadata;
    Access = Internal;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; Source; Enum "Report Filename Plh. Source")
        {
            Caption = 'Source';
            ToolTip = 'Specifies where the placeholder gets its value from: a field on the record, a filter set when the report is run, a value Business Central computes, or a field on a related table.';
        }
        field(3; Placeholder; Text[100])
        {
            Caption = 'Placeholder';
            ToolTip = 'Specifies the placeholder to enter in the file name pattern.';
        }
        field(4; Description; Text[250])
        {
            Caption = 'Description';
            ToolTip = 'Specifies what the value is, such as the field it is read from.';
        }
        field(5; Example; Text[250])
        {
            Caption = 'Example';
            ToolTip = 'Specifies an example of the form this placeholder''s value takes. It is worked out from the field''s type, not read from any record.';
        }
        field(10; "Over Several Records"; Text[250])
        {
            Caption = 'Over Several Records';
            ToolTip = 'Specifies what this placeholder produces when the report is run for several records at once. A value read from the records becomes a first-to-last range. A value that cannot represent the whole run says so.';
        }
        field(6; "Field No."; Integer)
        {
            Caption = 'Field No.';
        }
        field(7; Indentation; Integer)
        {
            Caption = 'Indentation';
        }
        field(8; "Group Name"; Text[100])
        {
            Caption = 'Group';
        }
        field(9; "Sort Order"; Integer)
        {
            // Display order, kept separate from Source because enum ordinals are not positions.
            Caption = 'Sort Order';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        // Tree order. Grouped by Group Name first, so a related table's fields stay under its row
        // even when another placeholder, such as "[Customer Posting Group]", shares its prefix.
        key(Tree; "Sort Order", Source, "Group Name", Indentation, Placeholder)
        {
        }
    }

    /// <summary>
    /// True for a top-level related-table row: a tree branch with nothing to insert.
    /// </summary>
    internal procedure IsRelatedTableRow(): Boolean
    begin
        exit((Source = Source::"Related Field") and (Indentation = 0));
    end;
}
