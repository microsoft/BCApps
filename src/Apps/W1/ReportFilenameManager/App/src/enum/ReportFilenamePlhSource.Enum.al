// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
enum 50112 "Report Filename Plh. Source"
{
    // Where a placeholder gets its value, which is also what decides whether it can be offered
    // at all: a placeholder is listed only when compiled metadata says where it would come from.
    //
    // Shown as the Source column of Available Placeholders. It was captioned Kind, which is a
    // word Business Central never uses as a caption, and which sat beside the Kind of Document
    // placeholder meaning something else entirely.

    // Not extensible: an internal enum cannot be reached by another extension, so declaring
    // it extensible would promise something impossible.
    Extensible = false;
    Caption = 'Report Filename Placeholder Source';
    Access = Internal;

    value(0; "Record Field")
    {
        Caption = 'Field';
    }
    value(1; "Request Filter")
    {
        Caption = 'Filter';
    }
    value(2; Computed)
    {
        Caption = 'Computed';
    }
    value(3; "Related Field")
    {
        // Labels both the row standing for a related table and the fields shown under it. It was
        // "One relation away", which named the mechanism rather than what the row is.
        Caption = 'Related Field';
    }
}
