codeunit 163419 "Create FA Charge"
{

    trigger OnRun()
    begin
        InsertData(XEXCLUDETA, XExcludeCostinTA, XFA, XFA + '20', true, XEXFA + '4');
        InsertData(XINCLUDETA, XIncludeCostinTA, XFA, XFA + '20', false, XEXFA + '1');
    end;

    var
        "FA Charge": Record "FA Charge";
        XEXCLUDETA: Label 'EXCLUDETA';
        XINCLUDETA: Label 'INCLUDETA';
        XExcludeCostinTA: Label 'Exclude Cost in TA';
        XIncludeCostinTA: Label 'Include Cost in TA';
        XFA: Label 'FA';
        XEXFA: Label 'EX-FA';

    procedure InsertData("No.": Code[10]; Description: Text[50]; "Gen. Prod. Posting Group": Code[20]; "VAT Prod. Posting Group": Code[20]; "Exclude Cost for TA": Boolean; "Tax Difference Code": Code[10])
    begin
        "FA Charge".Init();
        "FA Charge"."No." := "No.";
        "FA Charge".Description := Description;
        "FA Charge".Validate("Gen. Prod. Posting Group", "Gen. Prod. Posting Group");
        "FA Charge".Validate("VAT Prod. Posting Group", "VAT Prod. Posting Group");
        "FA Charge"."Exclude Cost for TA" := "Exclude Cost for TA";
        "FA Charge"."Tax Difference Code" := "Tax Difference Code";
        "FA Charge".Insert();
    end;
}

