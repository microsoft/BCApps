// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

/// <summary>
/// Enum that defines the types of MCP configuration warnings.
/// </summary>
enum 8350 "MCP Config Warning Type" implements "MCP Config Warning"
{
    Access = Internal;
    Extensible = false;

    /// <summary>
    /// Warning type for when an object referenced by a tool is missing.
    /// </summary>
    value(0; "Missing Object")
    {
        Caption = 'Missing Object';
        Implementation = "MCP Config Warning" = "MCP Config Missing Object";
    }
    /// <summary>
    /// Warning type for when a parent object is missing for a child API page.
    /// </summary>
    value(1; "Missing Parent Object")
    {
        Caption = 'Missing Parent Object';
        Implementation = "MCP Config Warning" = "MCP Config Missing Parent";
    }
}
