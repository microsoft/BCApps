// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Text;

enumextension 60 "Auto Format Ext" extends "Auto Format"
{
    value(1; AmountFormat)
    {
        Caption = 'Amount Format';
    }
    value(2; UnitAmountFormat)
    {
        Caption = 'Unit Amount Format';
    }
    value(4; AmountFormatNoSymbol)
    {
        Caption = 'Amount Format Without Symbol';
    }
    value(5; UnitAmountFormatNoSymbol)
    {
        Caption = 'Unit Amount Format Without Symbol';
    }
    value(10; CurrencySymbolFormat)
    {
        Caption = 'Currency Symbol Format';
    }
}