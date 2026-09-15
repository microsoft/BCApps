// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

enum 9125 "Company Demo Data Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Evaluation - Contoso Sample Data")
    {
        Caption = 'Evaluation - Contoso Sample Data';
    }
    value(1; "Production - Setup Data Only")
    {
        Caption = 'Production - Setup Data Only';
    }
    value(2; "Create New - No Data")
    {
        Caption = 'Create New - No Data';
    }
}