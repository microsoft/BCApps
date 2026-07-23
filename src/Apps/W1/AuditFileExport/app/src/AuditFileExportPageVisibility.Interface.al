// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AuditFileExport;

interface "Audit File Export Page Visibility"
{
    /// <summary>
    /// Allows implementations to modify the visibility of fields and actions on the Audit File Export Doc. Card page.
    /// The page initializes all visibility to true before calling this method.
    /// Implementations can selectively hide elements by setting dictionary values to false.
    /// </summary>
    /// <param name="FieldVisibility">Dictionary with field control names as keys and visibility state as values.</param>
    /// <param name="ActionVisibility">Dictionary with action control names as keys and visibility state as values.</param>
    procedure GetUIVisibility(var FieldVisibility: Dictionary of [Text, Boolean]; var ActionVisibility: Dictionary of [Text, Boolean])
}
