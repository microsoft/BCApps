// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

enum 6751 "Reminder Log Status"
{
    Extensible = true;

    value(0; " ")
    {
    }
    value(1; "Running")
    {
        Caption = 'Running';
    }
    value(2; Failed)
    {
        Caption = 'Failed';
    }
    value(3; Completed)
    {
        Caption = 'Completed';
    }
}