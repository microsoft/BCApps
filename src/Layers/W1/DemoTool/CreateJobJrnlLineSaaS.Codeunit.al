codeunit 101218 "Create Job Jrnl Line SaaS"
{

    trigger OnRun()
    var
        CreateJobResources: Codeunit "Create Job Resources";
    begin
        InsertData(XJOB00010, '1010', 19010316D, XJJ1234, 0, CreateJobResources.KatherineCode(), XSpecifications, 8, true);
        InsertData(XJOB00010, '1010', 19010317D, XJJ1234, 0, CreateJobResources.KatherineCode(), XSpecifications, 8, true);
        InsertData(XJOB00010, '1110', 19010318D, XJJ1234, 0, CreateJobResources.TerryCode(), XRemoveOldFurnishings, 8, true);
        InsertData(XJOB00030, '200', 19010318D, XJJ1234, 0, CreateJobResources.KatherineCode(), XKATHERINEHULL, 8, true);
        InsertData(XJOB00030, '300', 19010318D, XJJ1234, 1, X1908S, XLONDONSWIVELCHAIR, 2, true);
    end;

    var
        "Job Journal Batch": Record "Job Journal Batch";
        "Job Journal Line": Record "Job Journal Line";
        DummyBlankJobJnlLine: Record "Job Journal Line";
        DemoDataSetup: Record "Demo Data Setup";
        CA: Codeunit "Make Adjustments";
        "Line No.": Integer;
        XJOB00010: Label 'JOB00010', Locked = true;
        XRemoveOldFurnishings: Label 'Removing Old Furnishings';
        XSpecifications: Label 'Specifications';
        XJJ1234: Label 'JJ1234', Locked = true;
        XDEFAULT: Label 'DEFAULT';
        XJOB: Label 'JOB';
        XJOB00030: Label 'JOB00030', Locked = true;
        X1908S: Label '1908-S', Locked = true;
        xKATHERINEHULL: Label 'KATHERINE HULL';
        XLONDONSWIVELCHAIR: Label 'LONDON Swivel Chair, blue';

    procedure InsertData("Job No.": Code[20]; "Job Task": Code[20]; Date: Date; "Document No.": Code[20]; Type: Integer; "No.": Code[20]; Description: Text[50]; Quantity: Decimal; Chargeable: Boolean)
    begin
        Date := CA.AdjustDate(Date);
        InitJobJnlLine("Job Journal Line", XJOB, XDEFAULT);
        "Job Journal Line".Validate("Job No.", "Job No.");
        "Job Journal Line".Validate("Job Task No.", "Job Task");

        "Job Journal Line".Validate("Posting Date", Date);
        "Job Journal Line".Validate("Document No.", "Document No.");
        "Job Journal Line".Validate(Type, Type);
        "Job Journal Line"."Gen. Bus. Posting Group" := DemoDataSetup.DomesticCode();
        "Job Journal Line"."Gen. Prod. Posting Group" := DemoDataSetup.ServicesCode();
        "Job Journal Line".Validate("No.", "No.");
        if Description <> '' then
            "Job Journal Line".Validate(Description, Description);
        "Job Journal Line".Validate(Quantity, Quantity);
        "Job Journal Line".Validate(Chargeable, Chargeable);
        "Job Journal Line".Insert(true);
    end;

    procedure InitJobJnlLine(var "Job Journal Line": Record "Job Journal Line"; "Journal Template Name": Code[10]; "Journal Batch Name": Code[10])
    begin
        "Job Journal Line".Init();
        "Job Journal Line".Validate("Journal Template Name", "Journal Template Name");
        "Job Journal Line".Validate("Journal Batch Name", "Journal Batch Name");
        if ("Journal Template Name" <> "Job Journal Batch"."Journal Template Name") or
           ("Journal Batch Name" <> "Job Journal Batch".Name)
        then begin
            "Job Journal Batch".Get("Journal Template Name", "Journal Batch Name");
            if ("Job Journal Batch"."No. Series" <> '') or
               ("Job Journal Batch"."Posting No. Series" <> '')
            then begin
                "Job Journal Batch"."No. Series" := '';
                "Job Journal Batch"."Posting No. Series" := '';
                "Job Journal Batch".Modify();
            end;
        end;
        "Line No." := "Line No." + 10000;
        "Job Journal Line".Validate("Line No.", "Line No.");
        "Job Journal Line".SetUpNewLine(DummyBlankJobJnlLine);
    end;
}

