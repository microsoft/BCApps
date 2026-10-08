codeunit 101761 "Create Std. Gen. Journal Line"
{

    trigger OnRun()
    begin
        LineNo := 0;
        InsertData(XGENERAL, XPAYROLL, 0, '998710', 100000, XPayrollJournal, XADM);
        InsertData(XGENERAL, XPAYROLL, 0, '998720', 30000, XPayrollJournal, XADM);
        InsertData(XGENERAL, XPAYROLL, 0, '998730', 1000, XPayrollJournal, XADM);
        InsertData(XGENERAL, XPAYROLL, 0, '998750', 8000, XPayrollJournal, XADM);
        InsertData(XGENERAL, XPAYROLL, 0, '995830', -8000, XPayrollJournal, XADM);
        InsertData(XGENERAL, XPAYROLL, 0, '998740', 25000, XPayrollJournal, XADM);
        InsertData(XGENERAL, XPAYROLL, 3, XWWBOPERATING, -156000, XPayrollJournal, XADM);
    end;

    var
        StdGenJnlLine: Record "Standard General Journal Line";
        CA: Codeunit "Make Adjustments";
        LineNo: Integer;
        XGENERAL: Label 'GENERAL';
        XPAYROLL: Label 'PAYROLL';
        XPayrollJournal: Label 'Payroll Journal';
        XADM: Label 'ADM';
        XWWBOPERATING: Label 'WWB-OPERATING';

    procedure InsertData(JournalTemplateName: Code[10]; StdGenJnlCode: Code[10]; AccountType: Integer; No: Code[20]; Amount: Decimal; Description: Text[50]; Department: Code[20])
    var
        GenJnlTemplate: Record "Gen. Journal Template";
    begin
        StdGenJnlLine.Init();
        StdGenJnlLine."Line No." := 0;
        StdGenJnlLine.Validate("Journal Template Name", JournalTemplateName);
        GenJnlTemplate.Get(JournalTemplateName);
        StdGenJnlLine.Validate("Source Code", GenJnlTemplate."Source Code");
        StdGenJnlLine.Validate("Standard Journal Code", StdGenJnlCode);
        StdGenJnlLine.Validate("Account Type", AccountType);
        if AccountType <> 0 then
            StdGenJnlLine.Validate("Account No.", No)
        else
            StdGenJnlLine.Validate("Account No.", CA.Convert(No));
        if Amount <> 0 then
            StdGenJnlLine.Validate(Amount, Amount);
        if Department <> '' then
            StdGenJnlLine.Validate("Shortcut Dimension 1 Code", Department);
        StdGenJnlLine.Validate(Description, Description);
        LineNo := LineNo + 10000;
        StdGenJnlLine."Line No." := LineNo;
        StdGenJnlLine.Insert(true);
    end;
}

