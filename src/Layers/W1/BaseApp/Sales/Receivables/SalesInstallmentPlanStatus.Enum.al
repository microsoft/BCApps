// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Receivables;

enum 8841 "Sales Installment Plan Status"
{
    Extensible = false;

    value(0; Draft)
    {
        Caption = 'Draft';
    }
    value(1; Posted)
    {
        Caption = 'Posted';
    }
}
