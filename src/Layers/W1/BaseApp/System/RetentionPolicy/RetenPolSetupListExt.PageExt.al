namespace System.DataAdministration;

using System.Threading;

pageextension 3999 "Reten. Pol. Setup List Ext." extends "Retention Policy Setup List"
{
    actions
    {
        // Add changes to page actions here
        addafter(RetentionPeriods)
        {
            action(JobQueueEntries)
            {
                ApplicationArea = All;
                Caption = 'Job Queue Entries';
                ToolTip = 'Open the Job Queue Entries page to view a list of all jobs.';
                RunObject = Page "Job Queue Entries";
                AccessByPermission = TableData "Job Queue Entry" = R;
            }
        }
        addfirst(Category_Category4)
        {
            actionref(JobQueueEntries_Promoted; JobQueueEntries)
            {
            }
        }
    }
}