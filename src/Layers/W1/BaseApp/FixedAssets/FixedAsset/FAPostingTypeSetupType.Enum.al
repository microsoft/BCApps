// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Posting;

enum 5614 "FA Posting Type Setup Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Write-Down") { Caption = 'Write-Down'; }
    value(1; Appreciation) { Caption = 'Appreciation'; }
    value(2; "Custom 1") { Caption = 'Custom 1'; }
    value(3; "Custom 2") { Caption = 'Custom 2'; }
}
