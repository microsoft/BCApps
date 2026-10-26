// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting.FileNaming;

enum 8127 "Report Filename Plh. Source"
{
    // Where a placeholder gets its value.

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
        // Labels both the row standing for a related table and the fields shown under it.
        Caption = 'Related Field';
    }
}
