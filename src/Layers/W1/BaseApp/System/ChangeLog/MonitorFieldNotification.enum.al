namespace System.Diagnostics;

enum 1366 "Monitor Field Notification"
{
    Extensible = false;

    value(0; "Turned Off")
    {
        Caption = 'Turned Off';
    }

    value(1; "Email Sent")
    {
        Caption = 'Email Sent';
    }

    value(2; "Sending Email Failed")
    {
        Caption = 'Sending Email Failed';
    }
    value(3; "Email Enqueued")
    {
        Caption = 'Email Enqueued';
    }
}