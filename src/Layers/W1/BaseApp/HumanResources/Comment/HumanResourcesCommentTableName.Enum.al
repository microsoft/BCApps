// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Comment;

#pragma warning disable AL0659
enum 5208 "Human Resources Comment Table Name"
#pragma warning restore AL0659
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Employee") { Caption = 'Employee'; }
    value(1; "Alternative Address") { Caption = 'Alternative Address'; }
    value(2; "Employee Qualification") { Caption = 'Employee Qualification'; }
    value(3; "Employee Relative") { Caption = 'Employee Relative'; }
    value(4; "Employee Absence") { Caption = 'Employee Absence'; }
    value(5; "Misc. Article Information") { Caption = 'Misc. Article Information'; }
    value(6; "Confidential Information") { Caption = 'Confidential Information'; }
}
