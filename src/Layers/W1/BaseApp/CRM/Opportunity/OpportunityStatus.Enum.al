// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Opportunity;

enum 5092 "Opportunity Status"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Not Started") { Caption = 'Not Started'; }
    value(1; "In Progress") { Caption = 'In Progress'; }
    value(2; "Won") { Caption = 'Won'; }
    value(3; "Lost") { Caption = 'Lost'; }
}
