namespace System.Automation;

enum 458 "Workflow Approval Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Workflow User Group") { Caption = 'Workflow User Group'; }
    value(1; "Sales Pers./Purchaser") { Caption = 'Sales Pers./Purchaser'; }
    value(2; "Approver") { Caption = 'Approver'; }
}