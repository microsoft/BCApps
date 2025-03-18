// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

report 6280 "Database Activity Log"
{
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    DefaultRenderingLayout = ExportExcelLayout;

    dataset
    {
        dataitem(DataItemName; "Database Activity Log")
        {
            column(Transaction_Order; "Transaction Order")
            {
            }
            column(Trigger_Name; "Trigger Name")
            {
            }
            column(Table_ID; "Table ID")
            {
            }
            column(Table_Name; "Table Name")
            {
            }
            column(Call_Stack; "Call Stack")
            {
            }
        }
    }

    rendering
    {
        layout(ExportExcelLayout)
        {
            Type = Excel;
            LayoutFile = 'TransactionsLog.xlsx';
        }
    }
}