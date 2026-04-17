// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

/// <summary>
/// Severity of a signal finding or line entry on a Performance Analysis.
/// </summary>
enum 5476 "Perf. Analysis Severity"
{
    Access = Public;
    Extensible = false;

    value(0; Info) { Caption = 'Info'; }
    value(1; Warning) { Caption = 'Warning'; }
    value(2; Critical) { Caption = 'Critical'; }
}
