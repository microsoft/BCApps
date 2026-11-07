// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Employee;

enum 5224 "Employee Gender"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ")
    {
    }
    value(1; Female)
    {
        Caption = 'Female';
    }
    value(2; Male)
    {
        Caption = 'Male';
    }
    value(3; "Non-binary")
    {
        Caption = 'Non-binary/gender diverse';
    }
    value(4; "Self-Described")
    {
        Caption = 'Self-Described';
    }
    value(5; "I don’t wish to answer")
    {
        Caption = 'I don''t wish to answer';
    }
}
