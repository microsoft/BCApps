// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Wizard;

enum 99001012 "Prod. Definition Source"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; Empty)
    {
        Caption = ' ', Locked = true;
    }
    value(1; Item)
    {
        Caption = 'Item';
    }
    value(2; StockkeepingUnit)
    {
        Caption = 'Stockkeeping Unit';
    }
    value(3; SalesLine)
    {
        Caption = 'Sales Line';
    }
    value(4; PurchaseLine)
    {
        Caption = 'Purchase Line';
    }
}