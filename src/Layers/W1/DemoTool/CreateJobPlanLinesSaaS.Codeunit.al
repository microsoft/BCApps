codeunit 101216 "Create Job PlanLines SaaS"
{

    trigger OnRun()
    var
        CreateJobResources: Codeunit "Create Job Resources";
    begin
        InsertData(XJOB00010, '1010', 10000, 2, 19030125D, '', 0, CreateJobResources.KatherineCode(), XKATHERINEHULL, XHOUR, 20, 0, 50, 100);
        InsertData(XJOB00010, '1020', 10000, 2, 19030125D, '', 3, '', XREVIEWDESIGNS, XHOUR, 0, 0, 0, 0);
        InsertData(XJOB00010, '1110', 10000, 2, 19030125D, '', 0, CreateJobResources.TerryCode(), XTerryDodds, XHOUR, 30, 0, 50, 100);
        InsertData(XJOB00010, '1120', 10000, 2, 19030125D, '', 0, CreateJobResources.TerryCode(), XTerryDodds, XHOUR, 2, 0, 50, 100);
        InsertData(XJOB00010, '1210', 12500, 2, 19030125D, '', 0, CreateJobResources.LinaCode(), XLINATOWNSEND, XHOUR, 50, 0, 60, 120);
        InsertData(XJOB00010, '1220', 15000, 2, 19030125D, '', 0, CreateJobResources.KatherineCode(), XKATHERINEHULL, XHOUR, 1, 0, 50, 100);
        InsertData(XJOB00010, '1230', 20000, 2, 19030125D, '', 0, CreateJobResources.MartyCode(), XMartyHorst, XHOUR, 10, 0, 45, 90);
        InsertData(XJOB00010, '1240', 25000, 2, 19030125D, '', 1, X1936S, XBERLINEGUESTCHAIRYELLOW, XPCS, 8, 0, 97.5, 143.9);
        InsertData(XJOB00010, '1310', 30000, 2, 19030125D, '', 0, CreateJobResources.LinaCode(), XLINATOWNSEND, XHOUR, 4, 0, 60, 120);
        InsertData(XJOB00010, '1320', 35000, 2, 19030125D, '', 0, CreateJobResources.LinaCode(), XLINATOWNSEND, XHOUR, 10, 0, 60, 120);

        InsertData(XJOB00020, '100', 10000, 0, 19030125D, '5678', 0, CreateJobResources.LinaCode(), XLINATOWNSEND, XHOUR, 2, 0, 60, 120);
        InsertData(XJOB00020, '200', 10000, 1, 19030125D, '5678', 0, CreateJobResources.LinaCode(), XLINATOWNSEND, XHOUR, 8, 0, 60, 120);
        InsertData(XJOB00020, '300', 10000, 2, 19030125D, '5678', 0, CreateJobResources.LinaCode(), XLINATOWNSEND, XHOUR, 4, 0, 60, 120);
        InsertData(XJOB00020, '300', 20000, 2, 19030125D, '5678', 1, X1920S, XANTWERPCONFERNECETABLE, XPCS, 1, 0, 328, 420.4);

        InsertData(XJOB00030, '100', 10000, 0, 19030125D, '5678', 0, CreateJobResources.KatherineCode(), XKATHERINEHULL, XHOUR, 8, 0, 84.7, 154);
        InsertData(XJOB00030, '200', 10000, 1, 19030125D, '5678', 0, CreateJobResources.KatherineCode(), XKATHERINEHULL, XHOUR, 16, 0, 84.7, 154);
        InsertData(XJOB00030, '300', 10000, 2, 19030125D, '5678', 0, CreateJobResources.KatherineCode(), XKATHERINEHULL, XHOUR, 10, 0, 84.7, 154);
        InsertData(XJOB00030, '300', 20000, 2, 19030125D, '5678', 1, X1908S, XLONDONSWIVELCHAIR, XPCS, 2, 0, 148.1, 190.1);
    end;

    var
        JobPlanningLine: Record "Job Planning Line";
        CA: Codeunit "Make Adjustments";
        XJOB00010: Label 'JOB00010', Locked = true;
        XJOB00020: Label 'JOB00020', Locked = true;
        XREVIEWDESIGNS: Label 'Review Designs';
        xKATHERINEHULL: Label 'KATHERINE HULL';
        XTerryDodds: Label 'Terry Dodds';
        XLINATOWNSEND: Label 'Lina Townsend';
        XBERLINEGUESTCHAIRYELLOW: Label 'BERLIN Guest Chair, yellow';
        XANTWERPCONFERNECETABLE: Label 'ANTWERP Conference Table';
        XMartyHorst: Label 'Marty Horst';
        X1936S: Label '1936-S', Locked = true;
        X1920S: Label '1920-S', Locked = true;
        XHOUR: Label 'HOUR';
        XPCS: Label 'PCS';
        XJOB00030: Label 'JOB00030', Locked = true;
        XLONDONSWIVELCHAIR: Label 'LONDON Swivel Chair, blue';
        X1908S: Label '1908-S', Locked = true;

    procedure InsertData("Job No.": Code[20]; "Job Task No.": Code[20]; "Line No.": Integer; "Line Type": Option Budget,Billable,"Both Budget and Billable"; "Planning Date": Date; "Document No.": Code[20]; Type: Option Resource,Item,"G/L Account",Text; "No.": Code[20]; Description: Text[50]; "Unit of Measure Code": Code[10]; Quantity: Decimal; "Line Discount %": Decimal; "Unit Cost": Decimal; "Unit Price": Decimal)
    begin
        JobPlanningLine.Init();
        JobPlanningLine.Validate("Job No.", "Job No.");
        JobPlanningLine.Validate("Job Task No.", "Job Task No.");
        JobPlanningLine.Validate("Line No.", "Line No.");
        JobPlanningLine.Insert(true);
        JobPlanningLine.Validate("Line Type", "Line Type");
        JobPlanningLine.Validate("Planning Date", CA.AdjustDate("Planning Date"));
        JobPlanningLine.Validate("Document No.", "Document No.");
        JobPlanningLine.Type := "Job Planning Line Type".FromInteger(Type);
        if "No." <> '' then begin
            JobPlanningLine.Validate("No.", "No.");
            JobPlanningLine.Validate("Unit of Measure Code", "Unit of Measure Code");
            JobPlanningLine.Validate(Quantity, Quantity);
            JobPlanningLine.Validate("Line Discount %", "Line Discount %");
            if "Unit Cost" <> 0 then
                JobPlanningLine.Validate("Unit Cost (LCY)", "Unit Cost");
            if "Unit Price" <> 0 then
                JobPlanningLine.Validate("Unit Price", "Unit Price");
        end;
        JobPlanningLine.Validate(Description, Description);
        JobPlanningLine.Modify();
    end;
}

