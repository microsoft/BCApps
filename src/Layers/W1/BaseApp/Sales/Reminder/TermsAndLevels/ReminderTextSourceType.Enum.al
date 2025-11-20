// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

enum 1890 "Reminder Text Source Type"
{
    Extensible = true;

    value(0; "Reminder Term")
    {
        Caption = 'Reminder Term';
    }
    value(1; "Reminder Level")
    {
        Caption = 'Reminder Level';
    }
}