// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

/// <summary>
/// This enum has the Run Type of the BCCT Header.
/// </summary>
enum 149033 "BCCT Run Type"
{
    Extensible = false;

    /// <summary>
    /// Specifies that the BCCT Header Run Type is BCCT.
    /// </summary>
    value(0; BCCT)
    {
    }
    /// <summary>
    /// Specifies that the BCCT Header Run Type is PRT.
    /// </summary>
    value(10; PRT)
    {
    }
}