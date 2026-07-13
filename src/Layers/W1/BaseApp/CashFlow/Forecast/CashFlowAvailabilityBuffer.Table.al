// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CashFlow.Forecast;

table 930 "Cash Flow Availability Buffer"
{
    DataClassification = CustomerContent;

    fields
    {
        field(5; "Period Type"; Option)
        {
            Caption = 'Period Type';
            OptionMembers = Day,Week,Month,Quarter,Year,Period;
        }
        field(6; "Period Name"; Text[50])
        {
            Caption = 'Period Name';
        }
        field(7; "Period Start"; Date)
        {
            Caption = 'Period Start';
        }
        field(8; "Period End"; Date)
        {
            Caption = 'Period End';
        }
        field(10; Receivables; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Receivables';
        }
        field(11; "Sales Orders"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Sales Orders';
        }
        field(12; "Service Orders"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Service Orders';
        }
        field(13; "Fixed Assets Disposal"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Fixed Assets Disposal';
        }
        field(14; "Cash Flow Manual Revenues"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Cash Flow Manual Revenues';
        }
        field(15; Payables; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Payables';
        }
        field(16; "Purchase Orders"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Purchase Orders';
        }
        field(17; "Fixed Assets Budget"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Fixed Assets Budget';
        }
        field(18; "Cash Flow Manual Expenses"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Cash Flow Manual Expenses';
        }
        field(19; "G/L Budget"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'G/L Budget';
        }
        field(20; Job; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Project';
        }
        field(21; Tax; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Tax';
        }
        field(22; Total; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Total';
        }
    }

    keys
    {
        key(Key1; "Period Type", "Period Start")
        {
            Clustered = true;
        }
    }
}
