codeunit 119089 "Create Cost Acct. Jnl Template"
{

    trigger OnRun()
    var
        CostJournalTemplate: Record "Cost Journal Template";
    begin
        CostJournalTemplate.Name := XCOSTACCT;
        CostJournalTemplate.Description := XStandardJournal;
        CostJournalTemplate."Posting Report ID" := REPORT::"Cost Register";
        if not CostJournalTemplate.Insert() then
            CostJournalTemplate.Modify();
    end;

    var
        XCOSTACCT: Label 'COSTACCT', Comment = 'COSTACCT stands for Cost Accounting.';
        XStandardJournal: Label 'Standard Journal';
}

