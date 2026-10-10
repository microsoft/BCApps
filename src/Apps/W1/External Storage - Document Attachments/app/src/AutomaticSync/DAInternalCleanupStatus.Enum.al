// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExternalStorage.DocumentAttachments;

enum 8750 "DA Internal Cleanup Status"
{
    Access = Internal;
    Extensible = false;

    value(0; "Not Requested") { Caption = 'Not Requested'; }
    value(1; Pending) { Caption = 'Pending'; }
    value(2; "In Progress") { Caption = 'In Progress'; }
    value(3; "Retry Due") { Caption = 'Retry Due'; }
    value(4; Blocked) { Caption = 'Blocked'; }
    value(5; Completed) { Caption = 'Completed'; }
    value(6; Cancelled) { Caption = 'Cancelled'; }
}
