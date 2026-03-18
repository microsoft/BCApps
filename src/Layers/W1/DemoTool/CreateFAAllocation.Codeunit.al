codeunit 101810 "Create FA Allocation"
{

    trigger OnRun()
    begin
        InsertData(XTELEPHONE, "FA Allocation Type"::Depreciation, '998820', XADM, 30);
        InsertData(XTELEPHONE, "FA Allocation Type"::Depreciation, '998820', XPROD, 20);
        InsertData(XTELEPHONE, "FA Allocation Type"::Depreciation, '998820', XSALES, 50);
        InsertData(XTELEPHONE, "FA Allocation Type"::Gain, '998840', XADM, 30);
        InsertData(XTELEPHONE, "FA Allocation Type"::Gain, '998840', XPROD, 20);
        InsertData(XTELEPHONE, "FA Allocation Type"::Gain, '998840', XSALES, 50);
        InsertData(XTELEPHONE, "FA Allocation Type"::Loss, '998840', XADM, 30);
        InsertData(XTELEPHONE, "FA Allocation Type"::Loss, '998840', XPROD, 20);
        InsertData(XTELEPHONE, "FA Allocation Type"::Loss, '998840', XSALES, 50);
    end;

    var
        CA: Codeunit "Make Adjustments";
        "Line No.": Integer;
        XTELEPHONE: Label 'TELEPHONE';
        XADM: Label 'ADM';
        XPROD: Label 'PROD';
        XSALES: Label 'SALES';

    procedure InsertData("Code": Code[10]; "Allocation Type": Enum "FA Allocation Type"; "Account No.": Code[20]; "Global Dimension 1 Code": Code[20]; "Allocation %": Decimal)
    var
        "FA Allocation": Record "FA Allocation";
    begin
        "FA Allocation".Code := Code;
        "FA Allocation"."Allocation Type" := "Allocation Type";
        "Line No." := "Line No." + 10000;
        "FA Allocation"."Line No." := "Line No.";
        "FA Allocation".Validate("Account No.", CA.Convert("Account No."));
        "FA Allocation".Validate("Global Dimension 1 Code", "Global Dimension 1 Code");
        "FA Allocation".Validate("Allocation %", "Allocation %");
        "FA Allocation".Insert();
    end;
}

