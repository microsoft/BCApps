// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

interface "MCP Server Features"
{
    Access = Internal;

    /// <summary>
    /// Activates or deactivates the feature for the specified MCP configuration.
    /// </summary>
    procedure SetActive(ConfigId: Guid; Active: Boolean);

    /// <summary>
    /// Returns whether the feature is currently active for the specified MCP configuration.
    /// </summary>
    procedure IsActive(ConfigId: Guid): Boolean;

    /// <summary>
    /// Returns whether the feature exposes additional settings (drives the Configure action).
    /// </summary>
    procedure HasSettings(): Boolean;

    /// <summary>
    /// Opens the feature's settings dialog. No-op when HasSettings() returns false.
    /// </summary>
    procedure OpenSettings(ConfigId: Guid);

    /// <summary>
    /// Returns the description shown for the feature in the Server Features list.
    /// </summary>
    procedure Description(): Text[500];

    /// <summary>
    /// Appends the feature's system tools to the buffer. Called only when the feature is active.
    /// </summary>
    procedure LoadSystemTools(var MCPSystemTool: Record "MCP System Tool");

    /// <summary>
    /// Returns true and the parent feature when this is a sub-feature. The Server Features list shows
    /// a sub-feature indented beneath its parent.
    /// </summary>
    procedure TryGetParentFeature(var ParentFeature: Enum "MCP Server Feature"): Boolean;
}
