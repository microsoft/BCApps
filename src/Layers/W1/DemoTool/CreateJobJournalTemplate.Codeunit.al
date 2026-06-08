codeunit 101209 "Create Job Journal Template"
{

    trigger OnRun()
    begin
        SourceCodeSetup.Get();
        InsertData(
          XJOB, XJobJournal, false, SourceCodeSetup."Job Journal",
          XJJNLGEN, XJobJournal, '1', XJ01000);
        InsertData(
          XRECURRING, XRecurringJobJournal, true, SourceCodeSetup."Job Journal",
          XJJNLREC, XRecurringJobJournal, '1001', XJ02000);
    end;

    var
        SourceCodeSetup: Record "Source Code Setup";
        "Job Journal Template": Record "Job Journal Template";
        "Create No. Series": Codeunit "Create No. Series";
        XJOB: Label 'JOB';
        XJobJournal: Label 'Job Journal';
        XJJNLGEN: Label 'JJNL-GEN';
        XJ01000: Label 'J01000';
        XRECURRING: Label 'RECURRING';
        XRecurringJobJournal: Label 'Recurring Job Journal';
        XJJNLREC: Label 'JJNL-REC';
        XJ02000: Label 'J02000';

    procedure InsertData(Name: Code[10]; Description: Text[80]; Recurring: Boolean; "Source Code": Code[10]; "No. Series": Code[10]; NoSeriesDescription: Text[30]; NoSeriesStartNo: Code[20]; NoSeriesEndNo: Code[20])
    begin
        if "No. Series" <> '' then
            "Create No. Series".InitBaseSeries(
              "No. Series", "No. Series", NoSeriesDescription, NoSeriesStartNo, NoSeriesEndNo, '', '', 1, Enum::"No. Series Implementation"::Sequence);

        "Job Journal Template".Init();
        "Job Journal Template".Validate(Name, Name);
        "Job Journal Template".Validate(Description, Description);
        "Job Journal Template".Insert(true);
        "Job Journal Template".Validate(Recurring, Recurring);
        if Recurring then
            "Job Journal Template".Validate("Posting No. Series", "No. Series")
        else
            "Job Journal Template".Validate("No. Series", "No. Series");
        "Job Journal Template".Validate("Source Code", "Source Code");
        "Job Journal Template".Modify();
    end;
}

