codeunit 101909 "Adjust Inventory Value"
{

    trigger OnRun()
    begin
        InsertOtherEntry(
          0, '992180', CA.AdjustDate(19021231D), XSTART, XAdjustingInventoryvalue, -GetAmount(CA.Convert('992180')),
          0, '995310', '');
    end;

    var
        "Create Gen. Journal Line": Codeunit "Create Gen. Journal Line";
        CA: Codeunit "Make Adjustments";
        XSTART: Label 'START';
        XAdjustingInventoryvalue: Label 'Adjusting Inventory value';
        XDEFAULT: Label 'DEFAULT';

    procedure InsertOtherEntry("Account Type": Option; "Account No.": Code[20]; Date: Date; "Document No.": Code[20]; Description: Text[50]; Amount: Decimal; "Bal. Account Type": Option; "Bal. Account No.": Code[20]; "Shortcut Dimension 1 Code": Code[20])
    var
        "Gen. Journal Line": Record "Gen. Journal Line";
    begin
        "Create Gen. Journal Line".InitGenJnlLine("Gen. Journal Line", XSTART, XDEFAULT);
        "Gen. Journal Line".Validate("Account Type", "Account Type");
        if "Gen. Journal Line"."Account Type" = "Gen. Journal Line"."Account Type"::"G/L Account" then
            "Account No." := CA.Convert("Account No.");
        "Gen. Journal Line".Validate("Account No.", "Account No.");
        "Gen. Journal Line".Validate("Posting Date", Date);
        "Gen. Journal Line".Validate("Document Type", 0);
        "Gen. Journal Line".Validate("Document No.", "Document No.");
        "Gen. Journal Line".Validate(Description, Description);
        "Gen. Journal Line".Validate("Bal. Account Type", "Bal. Account Type");
        if "Gen. Journal Line"."Bal. Account Type" = "Gen. Journal Line"."Bal. Account Type"::"G/L Account" then
            "Bal. Account No." := CA.Convert("Bal. Account No.");
        "Gen. Journal Line".Validate("Bal. Account No.", "Bal. Account No.");
        "Gen. Journal Line".Validate(Amount, Amount);
        "Gen. Journal Line".Validate("Shortcut Dimension 1 Code", "Shortcut Dimension 1 Code");
        "Gen. Journal Line".Insert(true);
    end;

    procedure GetAmount(GLAccNo: Code[20]): Decimal
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Reset();
        GLAccount."No." := GLAccNo;
        GLAccount.CalcFields(Balance);
        exit(GLAccount.Balance);
    end;
}

