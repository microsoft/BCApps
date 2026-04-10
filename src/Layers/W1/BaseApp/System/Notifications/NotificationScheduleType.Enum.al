namespace System.Environment.Configuration;

enum 1512 "Notification Schedule Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Instantly") { Caption = 'Instantly'; }
    value(1; "Daily") { Caption = 'Daily'; }
    value(2; "Weekly") { Caption = 'Weekly'; }
    value(3; "Monthly") { Caption = 'Monthly'; }
}