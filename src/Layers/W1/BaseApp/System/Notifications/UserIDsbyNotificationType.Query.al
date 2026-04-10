namespace System.Environment.Configuration;

query 1511 "User IDs by Notification Type"
{
    Caption = 'User IDs by Notification Type';

    elements
    {
        dataitem(Notification_Entry; "Notification Entry")
        {
            column(Recipient_User_ID; "Recipient User ID")
            {
            }
            column(Type; Type)
            {
            }
            column(Count_)
            {
                Method = Count;
            }
        }
    }
}

