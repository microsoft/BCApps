namespace System.Automation;

enum 460 "Workflow Approver Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Salesperson/Purchaser") { Caption = 'Salesperson/Purchaser'; }
    value(1; "Approver") { Caption = 'Approver'; }
    value(2; "Workflow User Group") { Caption = 'Workflow User Group'; }
}