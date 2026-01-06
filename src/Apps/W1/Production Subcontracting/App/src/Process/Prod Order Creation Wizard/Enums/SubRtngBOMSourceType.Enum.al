// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

enum 99001506 "Sub. RtngBOMSourceType"
{
    Extensible = true;

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
}