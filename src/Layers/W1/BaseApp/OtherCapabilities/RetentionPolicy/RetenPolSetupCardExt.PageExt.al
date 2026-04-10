namespace System.DataAdministration;

using System.Threading;

pageextension 3998 "Reten. Pol. Setup Card Ext." extends "Retention Policy Setup Card"
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

    trigger OnAfterGetCurrRecord()
    begin
        CurrPage."Retention Policy Setup Lines".Page.SetIsDocumentArchiveTable(Rec."Table Id");
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        CurrPage."Retention Policy Setup Lines".Page.SetIsDocumentArchiveTable(Rec."Table Id");
    end;
}