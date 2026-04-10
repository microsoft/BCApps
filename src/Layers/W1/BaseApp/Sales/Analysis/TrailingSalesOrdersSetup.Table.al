// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Analysis;

using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using System.Visualization;

/// <summary>
/// Stores user-specific configuration settings for the trailing sales orders chart.
/// </summary>
table 760 "Trailing Sales Orders Setup"
{
    Caption = 'Trailing Sales Orders Setup';
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
        }
        /// <summary>
        /// Specifies the time interval used for grouping sales order data in the chart, such as day, week, month, quarter, or year.
        /// </summary>
        field(2; "Period Length"; Option)
        {
            Caption = 'Period Length';
            OptionCaption = 'Day,Week,Month,Quarter,Year';
            OptionMembers = Day,Week,Month,Quarter,Year;
        }
        /// <summary>
        /// Specifies which sales orders to include in the chart: all orders, orders until today, or only delayed orders.
        /// </summary>
        field(3; "Show Orders"; Option)
        {
            Caption = 'Show Orders';
            OptionCaption = 'All Orders,Orders Until Today,Delayed Orders';
            OptionMembers = "All Orders","Orders Until Today","Delayed Orders";
        }
        /// <summary>
        /// Indicates whether the chart uses the work date instead of the system date as the reference point for calculations.
        /// </summary>
        field(4; "Use Work Date as Base"; Boolean)
        {
            Caption = 'Use Work Date as Base';
            ToolTip = 'Specifies if you want data in the Trailing Sales Orders chart to be based on a work date other than today''s date. This is generally relevant when you view the chart data in a demonstration database that has fictitious sales orders.';
        }
        /// <summary>
        /// Specifies the metric to display in the chart: total amount excluding VAT or the number of orders.
        /// </summary>
        field(5; "Value to Calculate"; Option)
        {
            Caption = 'Value to Calculate';
            OptionCaption = 'Amount Excl. VAT,No. of Orders';
            OptionMembers = "Amount Excl. VAT","No. of Orders";
        }
        /// <summary>
        /// Specifies the visual representation style of the chart, such as stacked area or stacked column with optional percentage display.
        /// </summary>
        field(6; "Chart Type"; Option)
        {
            Caption = 'Chart Type';
            OptionCaption = 'Stacked Area,Stacked Area (%),Stacked Column,Stacked Column (%)';
            OptionMembers = "Stacked Area","Stacked Area (%)","Stacked Column","Stacked Column (%)";
        }
        /// <summary>
        /// Contains the most recent document date from all sales orders, used to determine the chart's starting point when showing all orders.
        /// </summary>
        field(7; "Latest Order Document Date"; Date)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            CalcFormula = max("Sales Header"."Document Date" where("Document Type" = const(Order)));
            Caption = 'Latest Order Document Date';
            FieldClass = FlowField;
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

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'Updated at %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    /// <summary>
    /// Returns a formatted text string describing the current chart settings.
    /// </summary>
    /// <returns>A text string containing the current selection options and timestamp.</returns>
    procedure GetCurrentSelectionText(): Text[100]
    begin
        exit(Format("Show Orders") + '|' +
          Format("Period Length") + '|' +
          Format("Value to Calculate") + '|. (' +
          StrSubstNo(Text001, Time) + ')');
    end;

    /// <summary>
    /// Returns the start date for chart calculations based on the current settings.
    /// </summary>
    /// <returns>The calculated start date based on work date or today settings.</returns>
    procedure GetStartDate(): Date
    var
        StartDate: Date;
    begin
        if "Use Work Date as Base" then
            StartDate := WorkDate()
        else
            StartDate := Today;
        if "Show Orders" = "Show Orders"::"All Orders" then begin
            CalcFields("Latest Order Document Date");
            StartDate := "Latest Order Document Date";
        end;

        exit(StartDate);
    end;

    /// <summary>
    /// Returns the business chart type enum value based on the current chart type setting.
    /// </summary>
    /// <returns>The business chart type for chart rendering.</returns>
    procedure GetBusinessChartType(): Enum "Business Chart Type"
    begin
        case "Chart Type" of
            "Chart Type"::"Stacked Area":
                exit("Business Chart Type"::StackedArea);
            "Chart Type"::"Stacked Area (%)":
                exit("Business Chart Type"::StackedArea100);
            "Chart Type"::"Stacked Column":
                exit("Business Chart Type"::StackedColumn);
            "Chart Type"::"Stacked Column (%)":
                exit("Business Chart Type"::StackedColumn100);
        end;
    end;

    /// <summary>
    /// Updates the period length setting for the chart.
    /// </summary>
    /// <param name="PeriodLength">The period length to use (Day, Week, Month, Quarter, or Year).</param>
    procedure SetPeriodLength(PeriodLength: Option)
    begin
        "Period Length" := PeriodLength;
        Modify();
    end;

    /// <summary>
    /// Updates the show orders filter setting for the chart.
    /// </summary>
    /// <param name="ShowOrders">The filter option for which orders to display.</param>
    procedure SetShowOrders(ShowOrders: Integer)
    begin
        "Show Orders" := ShowOrders;
        Modify();
    end;

    /// <summary>
    /// Updates the value to calculate setting for the chart.
    /// </summary>
    /// <param name="ValueToCalc">The calculation type: amount or number of orders.</param>
    procedure SetValueToCalcuate(ValueToCalc: Integer)
    begin
        "Value to Calculate" := ValueToCalc;
        Modify();
    end;

    /// <summary>
    /// Updates the chart type setting for visual display.
    /// </summary>
    /// <param name="ChartType">The chart type option for rendering.</param>
    procedure SetChartType(ChartType: Integer)
    begin
        "Chart Type" := ChartType;
        Modify();
    end;
}

