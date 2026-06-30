codeunit 101206 "Create Res. Journal Template"
{

    trigger OnRun()
    begin
        SourceCodeSetup.Get();
        InsertData(
          XRESOURCES, XResourceJournal, false, SourceCodeSetup."Resource Journal",
          XRJNLGEN, XResourceJournal, '1', XR01000);
        InsertData(
          XRECURRING, XRecurringResourceJournal, true, SourceCodeSetup."Resource Journal",
          XRJNLREC, XRecurringResourceJournal, '1001', XR02000);
    end;

    var
        SourceCodeSetup: Record "Source Code Setup";
        "Res. Journal Template": Record "Res. Journal Template";
        "Create No. Series": Codeunit "Create No. Series";
        XRESOURCES: Label 'RESOURCES';
        XResourceJournal: Label 'Resource Journal';
        XRJNLGEN: Label 'RJNL-GEN';
        XR01000: Label 'R01000';
        XRECURRING: Label 'RECURRING';
        XRecurringResourceJournal: Label 'Recurring Resource Journal';
        XRJNLREC: Label 'RJNL-REC';
        XR02000: Label 'R02000';

    procedure InsertData(Name: Code[10]; Description: Text[80]; Recurring: Boolean; "Source Code": Code[10]; "No. Series": Code[10]; NoSeriesDescription: Text[30]; NoSeriesStartNo: Code[20]; NoSeriesEndNo: Code[20])
    begin
        if "No. Series" <> '' then
            "Create No. Series".InitBaseSeries(
              "No. Series", "No. Series", NoSeriesDescription, NoSeriesStartNo, NoSeriesEndNo, '', '', 1, Enum::"No. Series Implementation"::Sequence);

        "Res. Journal Template".Init();
        "Res. Journal Template".Validate(Name, Name);
        "Res. Journal Template".Validate(Description, Description);
        "Res. Journal Template".Insert(true);
        "Res. Journal Template".Validate(Recurring, Recurring);
        if Recurring then
            "Res. Journal Template".Validate("Posting No. Series", "No. Series")
        else
            "Res. Journal Template".Validate("No. Series", "No. Series");
        "Res. Journal Template".Validate("Source Code", "Source Code");
        "Res. Journal Template".Modify();
    end;
}

