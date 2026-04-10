namespace System.Automation;

enum 465 "Workflow Approver Limit Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Approver Chain") { Caption = 'Approver Chain'; }
    value(1; "Direct Approver") { Caption = 'Direct Approver'; }
    value(2; "First Qualified Approver") { Caption = 'First Qualified Approver'; }
    value(3; "Specific Approver") { Caption = 'Specific Approver'; }
}