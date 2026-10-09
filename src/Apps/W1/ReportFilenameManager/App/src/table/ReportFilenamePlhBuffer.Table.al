// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
table 50113 "Report Filename Plh. Buffer"
{
    // Holds the placeholders available for one pattern, so the administrator picks from a list
    // rather than knowing what to type. Populated from compiled metadata, so the same
    // pattern offers the same placeholders in an empty database as in production.

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
            // Presentation order, held apart from Source. Sorting by Source put the computed values
            // third because of the order the enum happens to declare them in, and an enum
            // ordinal is an identity, not a position - the computed values belong first,
            // because they are the short list that works anywhere.
            Caption = 'Sort Order';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        // The order the tree is shown in, and the reason the group name is a field of its own
        // rather than something read back out of the placeholder text. Sorting a tree by placeholder alone
        // does not work: "[Customer Posting Group]" sorts between "[Customer]" and
        // "[Customer.Name]", because a space sorts before a full stop - which would put an
        // unrelated row inside a table's children and break the contiguity a tree needs.
        // Grouping first and indenting second makes the order independent of how the text reads.
        key(Tree; "Sort Order", Source, "Group Name", Indentation, Placeholder)
        {
        }
    }

    /// <summary>
    /// Whether this row stands for a related table rather than for a placeholder. Asked in one place
    /// so the picker, the refusal message and the proof all agree on what a branch is: a row of
    /// the related kind sitting at the top level, which is the only row that has children under
    /// it and the only one with nothing to insert.
    /// </summary>
    /// <returns>True when the row is a branch of the tree and not a placeholder.</returns>
    internal procedure IsRelatedTableRow(): Boolean
    begin
        exit((Source = Source::"Related Field") and (Indentation = 0));
    end;
}
