// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
table 50114 "Report Filename Record Buffer"
{
    // The records an administrator can test a pattern against, so that choosing one is possible
    // at all.
    //
    // Test Pattern used to ask the platform for the kind of record's own lookup window, by
    // passing page zero to Page.RunModal with a RecordRef carried in a Variant. That opens the
    // right page - Posted Sales Invoices, for a pattern about sales invoices - but it opens it
    // as an ordinary list: the full ribbon, a Close button, and no way to accept a row. It
    // never returns LookupOK, so nothing ever came back and the button looked broken while
    // doing exactly what it was told. Base Application's four uses of page zero all pass a
    // Record known at compile time, not a reference to a table known only at run time; the one
    // that passes a reference is no evidence that it works.
    //
    // Lookup mode is only reliable when it is set rather than inferred: a Page variable with
    // LookupMode(true). That needs a page known at compile time, so the page has to be ours,
    // and its source has to be a buffer this feature fills from whichever table the pattern
    // names. That is the same shape as the three lookups in this feature that already work -
    // the report lookup, the kinds lookup and the field lookup.
    //
    // The chosen record is carried as a RecordId rather than as text. The page that opens it
    // cannot hold a RecordRef across two trigger invocations, and the previous answer to that
    // was to write out the primary key, hand back the string, and split it again later - which
    // broke for any key value containing the separator. A RecordId is a value, it survives
    // being held on a page, and it identifies the record exactly.

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
