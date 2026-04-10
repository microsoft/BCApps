// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

enum 130 "Incoming Document Status"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "New") { Caption = 'New'; }
    value(1; "Released") { Caption = 'Released'; }
    value(2; "Rejected") { Caption = 'Rejected'; }
    value(3; "Posted") { Caption = 'Posted'; }
    value(4; "Created") { Caption = 'Created'; }
    value(5; "Failed") { Caption = 'Failed'; }
    value(6; "Pending Approval") { Caption = 'Pending Approval'; }
}
