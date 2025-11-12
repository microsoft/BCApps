// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

enum 5002000 ColumnHeaderDateType
{
    value(0; Blank)
    {
        Caption = ' ';
    }
    value(1; Weekday)
    {
        Caption = 'Weekday';
    }
    value(2; Week)
    {
        Caption = 'Week';
    }
    value(3; Month)
    {
        Caption = 'Month';
    }
    value(4; MonthAndYear)
    {
        Caption = 'Month and Year';
    }
    value(5; Quarter)
    {
        Caption = 'Quarter';
    }
    value(6; QuarterAndYear)
    {
        Caption = 'Quarter and Year';
    }
    value(7; Year)
    {
        Caption = 'Year';
    }
    value(10; FullDate)
    {
        Caption = 'Full Date';
    }
}