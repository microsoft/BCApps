// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

/// <summary>
/// This enum controls the execution context
/// </summary>

enum 6280 "Database Act. Monitor Context"
{
    Extensible = true;

    value(0; "Current Session")
    {
    }

    value(1; "All Sessions")
    {
    }
}