// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CashFlow.Forecast;

using Microsoft.CashFlow.Setup;
using System.Visualization;

table 869 "Cash Flow Chart Setup"
{
    Caption = 'Cash Flow Chart Setup';
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
        field(3; Show; Option)
        {
            Caption = 'Show';
            OptionCaption = 'Accumulated Cash,Change in Cash,Combined';
            OptionMembers = "Accumulated Cash","Change in Cash",Combined;
        }
        field(4; "Start Date"; Option)
        {
            Caption = 'Start Date';
            OptionCaption = 'First Entry Date,Working Date';
            OptionMembers = "First Entry Date","Working Date";
        }
        field(5; "Group By"; Option)
        {
            Caption = 'Group By';
            OptionCaption = 'Positive/Negative,Account No.,Source Type';
            OptionMembers = "Positive/Negative","Account No.","Source Type";
        }
        field(6; "Chart Type"; Option)
        {
            Caption = 'Chart Type';
            OptionCaption = 'Step Line,Stacked Area (%),Stacked Column,Stacked Column (%)';
            OptionMembers = "Step Line","Stacked Area (%)","Stacked Column","Stacked Column (%)";
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
        CFSetup: Record "Cash Flow Setup";

#pragma warning disable AA0470
        StatusTxt: Label '%1 | %2 | %3 | %4 | %5 (Updated: %6)', Comment = '<"Cash Flow Forecast No."> | <Show> | <"Start Date"> | <"Period Length"> | <"Group By">.  (Updated: <Time>)';
#pragma warning restore AA0470

    procedure GetCurrentSelectionText(): Text
    begin
        if not CFSetup.Get() then
            exit;
        exit(StrSubstNo(StatusTxt, CFSetup."CF No. on Chart in Role Center", Show, "Start Date", "Period Length", "Group By", Time));
    end;

    procedure GetStartDate(): Date
    var
        CashFlowForecast: Record "Cash Flow Forecast";
        Which: Option First,Last;
        StartDate: Date;
    begin
        case "Start Date" of
            "Start Date"::"Working Date":
                StartDate := WorkDate();
            "Start Date"::"First Entry Date":
                begin
                    CFSetup.Get();
                    CashFlowForecast.Get(CFSetup."CF No. on Chart in Role Center");
                    StartDate := CashFlowForecast.GetEntryDate(Which::First);
                end;
        end;
        exit(StartDate);
    end;

    procedure GetChartType(): Integer
    var
        BusinessChartBuf: Record "Business Chart Buffer";
    begin
        case "Chart Type" of
            "Chart Type"::"Step Line":
                exit(BusinessChartBuf."Chart Type"::StepLine.AsInteger());
            "Chart Type"::"Stacked Column":
                exit(BusinessChartBuf."Chart Type"::StackedColumn.AsInteger());
        end;
    end;

    procedure SetGroupBy(GroupBy: Option)
    begin
        "Group By" := GroupBy;
        Modify();
    end;

    procedure SetShow(NewShow: Option)
    begin
        Show := NewShow;
        Modify();
    end;

    procedure SetStartDate(StartDate: Option)
    begin
        "Start Date" := StartDate;
        Modify();
    end;

    procedure SetPeriodLength(PeriodLength: Option)
    begin
        "Period Length" := PeriodLength;
        Modify();
    end;

    procedure SetChartType(ChartType: Integer)
    begin
        "Chart Type" := ChartType;
        Modify();
    end;
}

