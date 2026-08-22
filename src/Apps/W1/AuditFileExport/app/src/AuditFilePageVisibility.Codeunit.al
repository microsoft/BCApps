// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AuditFileExport;

codeunit 5310 "Audit File Page Visibility" implements "Audit File Export Page Visibility"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure GetUIVisibility(var FieldVisibility: Dictionary of [Text, Boolean]; var ActionVisibility: Dictionary of [Text, Boolean])
    begin
        // Default implementation: no-op
        // All fields and actions are pre-initialized to visible (true) by the page,
        // so the default format keeps everything visible.
    end;
}
