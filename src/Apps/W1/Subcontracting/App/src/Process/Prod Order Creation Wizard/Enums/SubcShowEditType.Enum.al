// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

enum 99001504 "Subc. Show/Edit Type"
{
    Extensible = true;

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