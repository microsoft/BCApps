namespace System.Environment.Configuration;

enum 1511 "Notification Entry Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "New Record") { Caption = 'New Record'; }
    value(1; "Approval") { Caption = 'Approval'; }
    value(2; "Overdue") { Caption = 'Overdue'; }
}