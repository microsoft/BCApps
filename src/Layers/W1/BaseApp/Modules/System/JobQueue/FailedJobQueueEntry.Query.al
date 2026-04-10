namespace System.Threading;

query 472 "Failed Job Queue Entry"
{
    Caption = 'Failed Job Queue Entry';

    elements
    {
        dataitem(Job_Queue_Entry; "Job Queue Entry")
        {
            DataItemTableFilter = Status = filter(Error), "Recurring Job" = const(false);
            column(ID; ID)
            {
            }
            column(Status; Status)
            {
            }
            column(Recurring_Job; "Recurring Job")
            {
            }
            column(Earliest_Start_Date_Time; "Earliest Start Date/Time")
            {
            }
            filter(UserID; "User ID")
            {
            }
            dataitem(Job_Queue_Log_Entry; "Job Queue Log Entry")
            {
                DataItemLink = ID = Job_Queue_Entry.ID;
                column(End_Date_Time; "End Date/Time")
                {
                }
            }
        }
    }
}

