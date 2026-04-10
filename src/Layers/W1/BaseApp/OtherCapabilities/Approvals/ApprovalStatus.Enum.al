// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Automation;

enum 455 "Approval Status"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Created") { Caption = 'Created'; }
    value(1; "Open") { Caption = 'Open'; }
    value(2; "Canceled") { Caption = 'Canceled'; }
    value(3; "Rejected") { Caption = 'Rejected'; }
    value(4; "Approved") { Caption = 'Approved'; }
    value(5; " ") { Caption = ' '; }
}
