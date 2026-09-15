codeunit 101812 "Create FA Jnl. Template"
{

    trigger OnRun()
    begin
        InsertData(XASSETS, XFixedAssetGLJournal, XFAJNLGL, false, XFixedAssetGLJournal, '1', XF01000);
        InsertData(XRECURRING, XRecurringFixedAssetGLJournal, XFAJNLGLR, true, XRecurringFixedAssetGLJournal, '1', XRF01000);
    end;

    var
        "Create No. Series": Codeunit "Create No. Series";
        XASSETS: Label 'ASSETS';
        XFixedAssetGLJournal: Label 'Fixed Asset G/L Journal';
        XFAJNLGL: Label 'FAJNL-GL';
        XF01000: Label 'F01000';
        XRECURRING: Label 'RECURRING';
        XRecurringFixedAssetGLJournal: Label 'Recurring Fixed Asset G/L Jnl';
        XFAJNLGLR: Label 'FAJNL-GLR';
        XRF01000: Label 'RF01000';

    procedure InsertData(Name: Code[10]; Description: Text[80]; "No. Series": Code[10]; Recurring: Boolean; NoSeriesDescription: Text[30]; NoSeriesStartNo: Code[20]; NoSeriesEndNo: Code[20])
    var
        "FA Journal Template": Record "FA Journal Template";
    begin
        if "No. Series" <> '' then
            "Create No. Series".InitBaseSeries(
              "No. Series", "No. Series", NoSeriesDescription, NoSeriesStartNo, NoSeriesEndNo, '', '', 1, Enum::"No. Series Implementation"::Sequence);
        "FA Journal Template".Init();
        "FA Journal Template".Validate(Name, Name);
        "FA Journal Template".Validate(Description, Description);
        "FA Journal Template".Insert(true);
        "FA Journal Template".Validate(Recurring, Recurring);
        if Recurring then
            "FA Journal Template".Validate("Posting No. Series", "No. Series")
        else
            "FA Journal Template".Validate("No. Series", "No. Series");
        "FA Journal Template".Modify();
    end;
}

