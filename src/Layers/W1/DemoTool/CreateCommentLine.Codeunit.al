codeunit 101097 "Create Comment Line"
{

    trigger OnRun()
    begin
        InsertData();
    end;

    var
        "Comment Line": Record "Comment Line";
        CA: Codeunit "Make Adjustments";
        XDebonlyemplpaidtaxestothisacc: Label 'Debit only employer-paid taxes to this account';

    procedure InsertData()
    begin
        "Comment Line".Init();
        "Comment Line".Validate("Table Name", "Comment Line"."Table Name"::"G/L Account");
        "Comment Line".Validate("No.", CA.Convert('998750'));
        "Comment Line".Validate("Line No.", 10000);
        "Comment Line".Validate(Comment, XDebonlyemplpaidtaxestothisacc);
        "Comment Line".Insert();
    end;
}

