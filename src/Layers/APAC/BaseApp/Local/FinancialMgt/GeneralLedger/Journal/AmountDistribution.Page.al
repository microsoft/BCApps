// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

page 17101 "Amount Distribution"
{
    Caption = 'Amount Distribution';
    PageType = Card;

    layout
    {
        area(content)
        {
            group(Control10)
            {
                ShowCaption = false;
                field(FromDate; FromDate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'From Date';
                    ToolTip = 'Specifies the first date of the distribution.';
                }
                field(ToDate; ToDate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'To Date';
                    ToolTip = 'Specifies the last date of the period.';
                }
                field(WhatToCalculate; WhatToCalculate)
                {
                    ApplicationArea = Basic, Suite;
                    OptionCaption = 'Net Change,Balance';
                    ToolTip = 'Specifies what to calculate.';
                    ShowCaption = false;
                }
            }
        }
    }

    actions
    {
    }

    var
        FromDate: Date;
        ToDate: Date;
        WhatToCalculate: Option "Net Change",Balance;

    [Scope('OnPrem')]
    procedure ReturnDates(var StartDate: Date; var EndDate: Date; var CalcWhat: Option "Net Change",Balance)
    begin
        StartDate := FromDate;
        EndDate := ToDate;
        CalcWhat := WhatToCalculate;
    end;
}

