// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
enum 50114 "Report Filename Run Scope"
{
    // How much of the table a report run covers, which is the first thing an administrator has
    // to say before a file name can be worked out.
    //
    // Test Pattern used to ask this with two fields side by side - one record, or the records
    // the run covers - and set one to clear the other. They were alternatives presented as
    // additions: the screen showed two boxes that could never both hold a value. Saying which
    // of the three it is, and then saying which ones, matches what the page always did.
    //
    // Three values rather than two, because covering everything was expressible only by opening
    // the filter page and leaving it empty - which is not something anybody would guess.

    // Not extensible: an internal enum cannot be reached by another extension, so declaring it
    // extensible would promise something impossible.
    Extensible = false;
    Caption = 'Report Filename Run Scope';
    Access = Internal;

    value(0; "One Record")
    {
        Caption = 'One Record';
    }
    value(1; "Some Records")
    {
        Caption = 'Some Records';
    }
    value(2; "Every Record")
    {
        Caption = 'Every Record';
    }
}
