// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.TimeSheet;

query 984 "Get Time Sheet Lines"
{
    QueryType = Normal;
    ReadState = ReadUncommitted;
    DataAccessIntent = ReadOnly;
    OrderBy = descending(Starting_Date);

    elements
    {
        dataitem(Time_Sheet_Header; "Time Sheet Header")
        {
            filter(Filter_Resource_No_; "Resource No.") { }
            filter(Filter_Starting_Date; "Starting Date") { }
            filter(Filter_Approver_User; "Approver User ID") { }
            filter(Filter_Owner_User; "Owner User ID") { }

            column(Time_Sheet_No_; "No.") { }
            column(Resource_No_; "Resource No.") { }
            column(Starting_Date; "Starting Date") { }
            column(Ending_Date; "Ending Date") { }

            dataitem(Time_Sheet_Line; "Time Sheet Line")
            {
                DataItemLink = "Time Sheet No." = Time_Sheet_Header."No.";
                SqlJoinType = InnerJoin;
                column(Line_No_; "Line No.") { }
                column(Type; Type) { }
                column(Status; Status) { }
                column(Description; Description) { }
                column(Job_No_; "Job No.") { }
                column(Job_Task_No_; "Job Task No.") { }
                column(Cause_of_Absence_Code; "Cause of Absence Code") { }
                column(Chargeable; Chargeable) { }
                column(Work_Type_Code; "Work Type Code") { }
                column(Service_Order_No_; "Service Order No.") { }
                column(Assembly_Order_No_; "Assembly Order No.") { }
            }
        }
    }
}