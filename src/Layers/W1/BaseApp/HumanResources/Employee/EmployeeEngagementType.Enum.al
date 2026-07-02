// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Employee;

enum 5512 "Employee Engagement Type"
{
    Caption = 'Employee Engagement Type';
    Extensible = true;

    value(0; "Full time")
    {
        Caption = 'Full time';
    }
    value(1; "Part Time")
    {
        Caption = 'Part Time';
    }
    value(2; "Temporary")
    {
        Caption = 'Temporary';
    }
}