namespace System.Threading;

enum 485 "Document Job Queue Status"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Scheduled for Posting") { Caption = 'Scheduled for Posting'; }
    value(2; "Error") { Caption = 'Error'; }
    value(3; "Posting") { Caption = 'Posting'; }
}