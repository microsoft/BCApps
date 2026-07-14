codeunit 101170 "Create Invoices for Jobs"
{

    trigger OnRun()
    begin
        if Job.Find('-') then
            repeat
                if JobPlanningLine.Get(Job."No.") then
                    JobCreateInvoice.CreateSalesInvoice(JobPlanningLine, false);
            until Job.Next() = 0;
    end;

    var
        JobPlanningLine: Record "Job Planning Line";
        Job: Record Job;
        JobCreateInvoice: Codeunit "Job Create-Invoice";
}

