// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Employee;

enum 5510 "Employee Time Reg. Status"
{
    Extensible = false;
    AssignmentCompatibility = true;

    value(0; Open)
    {
        Caption = 'Open';
    }
    value(1; Submitted)
    {
        Caption = 'Submitted';
    }
    value(2; Rejected)
    {
        Caption = 'Rejected';
    }
    value(3; Approved)
    {
        Caption = 'Approved';
    }
}
