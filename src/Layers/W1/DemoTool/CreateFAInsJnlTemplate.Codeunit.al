codeunit 101819 "Create FA Ins. Jnl. Template"
{

    trigger OnRun()
    begin
        InsertData(XINSURANCE, XInsuranceJournal, XFAINSJNLG, XInsuranceJournal, '1', XN01000);
    end;

    var
        "Create No. Series": Codeunit "Create No. Series";
        XINSURANCE: Label 'INSURANCE';
        XInsuranceJournal: Label 'Insurance Journal';
        XFAINSJNLG: Label 'FA-INSJNLG';
        XN01000: Label 'N01000';

    procedure InsertData(Name: Code[10]; Description: Text[80]; "No. Series": Code[10]; NoSeriesDescription: Text[30]; NoSeriesStartNo: Code[20]; NoSeriesEndNo: Code[20])
    var
        "Insurance Journal Template": Record "Insurance Journal Template";
    begin
        if "No. Series" <> '' then
            "Create No. Series".InitBaseSeries(
              "No. Series", "No. Series", NoSeriesDescription, NoSeriesStartNo, NoSeriesEndNo, '', '', 1);
        "Insurance Journal Template".Init();
        "Insurance Journal Template".Validate(Name, Name);
        "Insurance Journal Template".Validate(Description, Description);
        "Insurance Journal Template".Insert(true);
        "Insurance Journal Template".Validate("No. Series", "No. Series");
        "Insurance Journal Template".Modify();
    end;
}

