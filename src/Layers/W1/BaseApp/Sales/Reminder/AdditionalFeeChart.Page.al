// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using Microsoft.Finance.Currency;
using System.Integration;
using System.Visualization;

page 1051 "Additional Fee Chart"
{
    Caption = 'Additional Fee Visualization';
    PageType = CardPart;
    SourceTable = "Business Chart Buffer";

    layout
    {
        area(content)
        {
            group(Options)
            {
                Caption = 'Options';
                field(ChargePerLine; ChargePerLine)
                {
                    ApplicationArea = Suite;
                    Caption = 'Line Fee';
                    ToolTip = 'Specifies the additional fee for the line.';
                    Visible = ShowOptions;

                    trigger OnValidate()
                    begin
                        UpdateData();
                    end;
                }
                field(Currency; Currency)
                {
                    ApplicationArea = Suite;
                    Caption = 'Currency Code';
                    LookupPageID = Currencies;
                    TableRelation = Currency.Code;
                    ToolTip = 'Specifies the code for the currency that amounts are shown in.';

                    trigger OnValidate()
                    begin
                        UpdateData();
                    end;
                }
                field("Max. Remaining Amount"; MaxRemAmount)
                {
                    ApplicationArea = Suite;
                    Caption = 'Max. Remaining Amount';
                    MinValue = 0;
                    ToolTip = 'Specifies the maximum amount that is displayed as remaining in the chart.';

                    trigger OnValidate()
                    begin
                        UpdateData();
                    end;
                }
            }
            group(Graph)
            {
                Caption = 'Graph';
                usercontrol(BusinessChart; BusinessChart)
                {
                    ApplicationArea = Suite;

                    trigger AddInReady()
                    begin
                        AddInIsReady := true;
                        UpdateData();
                    end;

                    trigger Refresh()
                    begin
                        UpdateData();
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        Rec.UpdateChart(CurrPage.BusinessChart);
    end;

    var
        ReminderLevel: Record "Reminder Level";
        TempSortingTable: Record "Sorting Table" temporary;
        ChargePerLine: Boolean;
        RemAmountTxt: Label 'Remaining Amount';
        Currency: Code[10];
        MaxRemAmount: Decimal;
        ShowOptions: Boolean;
        AddInIsReady: Boolean;

    procedure SetViewMode(SetReminderLevel: Record "Reminder Level"; SetChargePerLine: Boolean; SetShowOptions: Boolean)
    begin
        ReminderLevel := SetReminderLevel;
        ChargePerLine := SetChargePerLine;
        ShowOptions := SetShowOptions;
    end;

    [Scope('OnPrem')]
    procedure UpdateData()
    begin
        if not AddInIsReady then
            exit;

        TempSortingTable.UpdateData(Rec, ReminderLevel, ChargePerLine, Currency, RemAmountTxt, MaxRemAmount);
        Rec.UpdateChart(CurrPage.BusinessChart);
    end;
}

