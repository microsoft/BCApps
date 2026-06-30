// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Analysis;

using Microsoft.Finance.FinancialReports;
using System.Visualization;

table 9089 "Purch. by Vend.Grp.Chart Setup"
{
    Caption = 'Purch. by Vend. Grp. Chart Setup';
    LookupPageID = "Account Schedule Chart List";
    DataClassification = CustomerContent;
    ReplicateData = false;

    InherentEntitlements = X;
    InherentPermissions = X;

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
                Rec.TestField("Start Date");
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
        key(PK; "User ID")
        {
            Clustered = true;
        }
    }

    procedure SetPeriod(Which: Option " ",Next,Previous)
    var
        BusinessChartBuffer: Record "Business Chart Buffer";
    begin
        if Which = Which::" " then
            exit;

        Rec.Get(UserId);
        BusinessChartBuffer."Period Length" := "Period Length";
        case Which of
            Which::Previous:
                "Start Date" := CalcDate('<-1D>', BusinessChartBuffer.CalcFromDate("Start Date"));
            Which::Next:
                "Start Date" := CalcDate('<1D>', BusinessChartBuffer.CalcToDate("Start Date"));
        end;
        Rec.Modify();
    end;

    procedure SetPeriodLength(PeriodLength: Option)
    begin
        Rec.Get(UserId);
        "Period Length" := PeriodLength;
        Rec.Modify(true);
    end;
}
