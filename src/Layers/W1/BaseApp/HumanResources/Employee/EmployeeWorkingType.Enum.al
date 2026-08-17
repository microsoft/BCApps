// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Employee;

enum 5511 "Employee Working Type"
{
    Caption = 'Employee Working Type';
    Extensible = true;

    value(0; Week)
    {
        Caption = 'Week';
    }
    value(1; Month)
    {
        Caption = 'Month';
    }
    value(2; Year)
    {
        Caption = 'Year';
    }
}