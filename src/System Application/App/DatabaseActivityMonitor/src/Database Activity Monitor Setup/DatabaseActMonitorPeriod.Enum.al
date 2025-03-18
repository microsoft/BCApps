// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

/// <summary>
/// This enum controls the execution context
/// </summary>

enum 6281 "Database Act. Monitor Period"
{
    Extensible = true;

    value(0; "10 Minutes")
    {
    }
    value(1; "1 Hour")
    {
    }
    value(2; "12 Hours")
    {
    }
    value(3; "24 Hours")
    {
    }
}