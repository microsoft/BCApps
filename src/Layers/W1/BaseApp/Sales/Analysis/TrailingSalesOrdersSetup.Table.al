// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Analysis;

using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using System.Visualization;

table 760 "Trailing Sales Orders Setup"
{
    Caption = 'Trailing Sales Orders Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "User ID"; Text[132])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(2; "Period Length"; Option)
        {
            Caption = 'Period Length';
            OptionCaption = 'Day,Week,Month,Quarter,Year';
            OptionMembers = Day,Week,Month,Quarter,Year;
        }
        field(3; "Show Orders"; Option)
        {
            Caption = 'Show Orders';
            OptionCaption = 'All Orders,Orders Until Today,Delayed Orders';
            OptionMembers = "All Orders","Orders Until Today","Delayed Orders";
        }
        field(4; "Use Work Date as Base"; Boolean)
        {
            Caption = 'Use Work Date as Base';
        }
        field(5; "Value to Calculate"; Option)
        {
            Caption = 'Value to Calculate';
            OptionCaption = 'Amount Excl. VAT,No. of Orders';
            OptionMembers = "Amount Excl. VAT","No. of Orders";
        }
        field(6; "Chart Type"; Option)
        {
            Caption = 'Chart Type';
            OptionCaption = 'Stacked Area,Stacked Area (%),Stacked Column,Stacked Column (%)';
            OptionMembers = "Stacked Area","Stacked Area (%)","Stacked Column","Stacked Column (%)";
        }
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

    procedure GetCurrentSelectionText(): Text[100]
    begin
        exit(Format("Show Orders") + '|' +
          Format("Period Length") + '|' +
          Format("Value to Calculate") + '|. (' +
          StrSubstNo(Text001, Time) + ')');
    end;

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

    procedure SetPeriodLength(PeriodLength: Option)
    begin
        "Period Length" := PeriodLength;
        Modify();
    end;

    procedure SetShowOrders(ShowOrders: Integer)
    begin
        "Show Orders" := ShowOrders;
        Modify();
    end;

    procedure SetValueToCalcuate(ValueToCalc: Integer)
    begin
        "Value to Calculate" := ValueToCalc;
        Modify();
    end;

    procedure SetChartType(ChartType: Integer)
    begin
        "Chart Type" := ChartType;
        Modify();
    end;
}

