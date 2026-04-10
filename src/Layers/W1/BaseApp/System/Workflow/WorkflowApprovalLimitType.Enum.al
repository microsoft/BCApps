namespace System.Automation;

enum 457 "Workflow Approval Limit Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Approval Limits") { Caption = 'Approval Limits'; }
    value(1; "Credit Limits") { Caption = 'Credit Limits'; }
    value(2; "Request Limits") { Caption = 'Request Limits'; }
    value(3; "No Limits") { Caption = 'No Limits'; }
}