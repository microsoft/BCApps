// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Analysis;

using Microsoft.Finance.FinancialReports;
using System.Visualization;

/// <summary>
/// Stores user-specific configuration settings for the sales by customer group chart.
/// </summary>
table 1319 "Sales by Cust. Grp.Chart Setup"
{
    Caption = 'Sales by Cust. Grp.Chart Setup';
    LookupPageID = "Account Schedule Chart List";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Specifies the unique identifier of the user who owns this chart configuration.
        /// </summary>
        field(1; "User ID"; Text[132])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        /// <summary>
        /// Specifies the starting date for the data displayed in the sales by customer group chart.
        /// </summary>
        field(31; "Start Date"; Date)
        {
            Caption = 'Start Date';

            trigger OnValidate()
            begin
                TestField("Start Date");
            end;
        }
        /// <summary>
        /// Specifies the time interval used for grouping data in the chart, such as day, week, month, quarter, or year.
        /// </summary>
        field(41; "Period Length"; Option)
        {
            Caption = 'Period Length';
            OptionCaption = 'Day,Week,Month,Quarter,Year';
            OptionMembers = Day,Week,Month,Quarter,Year;
        }
    }

    keys
    {
        key(Key1; "User ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    /// <summary>
    /// Navigates the chart period forward or backward based on the specified direction.
    /// </summary>
    /// <param name="Which">The navigation direction: Next or Previous.</param>
    procedure SetPeriod(Which: Option " ",Next,Previous)
    var
        BusinessChartBuffer: Record "Business Chart Buffer";
    begin
        if Which = Which::" " then
            exit;

        Get(UserId);
        BusinessChartBuffer."Period Length" := "Period Length";
        case Which of
            Which::Previous:
                "Start Date" := CalcDate('<-1D>', BusinessChartBuffer.CalcFromDate("Start Date"));
            Which::Next:
                "Start Date" := CalcDate('<1D>', BusinessChartBuffer.CalcToDate("Start Date"));
        end;
        Modify();
    end;

    /// <summary>
    /// Updates the period length setting for the chart display.
    /// </summary>
    /// <param name="PeriodLength">The period length to use (Day, Week, Month, Quarter, or Year).</param>
    procedure SetPeriodLength(PeriodLength: Option)
    begin
        Get(UserId);
        "Period Length" := PeriodLength;
        Modify(true);
    end;
}

