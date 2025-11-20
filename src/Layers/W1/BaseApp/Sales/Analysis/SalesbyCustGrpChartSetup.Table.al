// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Analysis;

using Microsoft.Finance.FinancialReports;
using System.Visualization;

table 1319 "Sales by Cust. Grp.Chart Setup"
{
    Caption = 'Sales by Cust. Grp.Chart Setup';
    LookupPageID = "Account Schedule Chart List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "User ID"; Text[132])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(31; "Start Date"; Date)
        {
            Caption = 'Start Date';

            trigger OnValidate()
            begin
                TestField("Start Date");
            end;
        }
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

    procedure SetPeriodLength(PeriodLength: Option)
    begin
        Get(UserId);
        "Period Length" := PeriodLength;
        Modify(true);
    end;
}

