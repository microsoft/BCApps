// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Wizard;

enum 99001010 "Prod. Definition Display"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; Hide)
    {
        Caption = 'Hide';
    }
    value(1; Show)
    {
        Caption = 'Show';
    }
    value(2; Edit)
    {
        Caption = 'Edit';
    }
}