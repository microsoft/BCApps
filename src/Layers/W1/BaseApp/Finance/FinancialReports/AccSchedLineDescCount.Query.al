// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

query 762 "Acc. Sched. Line Desc. Count"
{
    Caption = 'Acc. Sched. Line Desc. Count';

    elements
    {
        dataitem(Acc_Schedule_Line; "Acc. Schedule Line")
        {
            column(Schedule_Name; "Schedule Name")
            {
            }
            column(Description; Description)
            {
                ColumnFilter = Description = filter(<> '');
            }
            column(Count_)
            {
                ColumnFilter = Count_ = filter(> 1);
                Method = Count;
            }
        }
    }
}

