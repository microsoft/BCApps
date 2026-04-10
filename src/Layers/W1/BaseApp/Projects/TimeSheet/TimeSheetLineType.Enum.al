// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.TimeSheet;

enum 952 "Time Sheet Line Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Resource") { Caption = 'Resource'; }
    value(2; "Job") { Caption = 'Project'; }
    value(3; "Service") { Caption = 'Service'; }
    value(4; "Absence") { Caption = 'Absence'; }
    value(5; "Assembly Order") { Caption = 'Assembly Order'; }
}
