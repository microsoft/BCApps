// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.TimeSheet;

query 986 "Time Sheet Line Status Count"
{
    QueryType = Normal;
    ReadState = ReadUncommitted;
    DataAccessIntent = ReadOnly;

    elements
    {
        dataitem(Time_Sheet_Header; "Time Sheet Header")
        {
            filter(Filter_Owner_User; "Owner User ID") { }
            filter(Filter_Approver_User; "Approver User ID") { }
            column(Time_Sheet_No_; "No.") { }
            dataitem(Time_Sheet_Line; "Time Sheet Line")
            {
                DataItemLink = "Time Sheet No." = Time_Sheet_Header."No.";
                SqlJoinType = LeftOuterJoin;
                filter(Filter_Status; Status) { }
                column(Time_Sheet_Status; Status) { }
                column(Time_Sheet_LineInStatus_Count)
                {
                    Method = Count;
                    ColumnFilter = Time_Sheet_LineInStatus_Count = filter(> 0);

                }
            }
        }
    }
}