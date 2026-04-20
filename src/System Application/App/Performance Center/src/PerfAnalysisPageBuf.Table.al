// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

/// <summary>
/// Temporary buffer used by <c>Perf. Analysis Page Lookup</c> so the lookup can be searched
/// and sorted on its display column (which combines caption, page type, and id).
/// </summary>
table 8406 "Perf. Analysis Page Buf"
{
    Access = Internal;
    DataClassification = SystemMetadata;
    Caption = 'Performance Analysis Page Buffer';
    TableType = Temporary;
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;

    fields
    {
        field(1; "Page Id"; Integer) { Caption = 'Page Id'; }
        field(2; Display; Text[500]) { Caption = 'Page'; }
        field(3; "Page Type"; Text[30]) { Caption = 'Page Type'; }
        field(4; Name; Text[250]) { Caption = 'Name'; }
    }

    keys
    {
        key(PK; "Page Id") { Clustered = true; }
        key(ByDisplay; Display) { }
    }
}
