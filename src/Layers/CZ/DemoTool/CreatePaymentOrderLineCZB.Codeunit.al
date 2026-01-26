codeunit 163507 "Create Payment Order Line CZB"
{

    trigger OnRun()
    begin
        InsertData('BPRI0001', PaymentOrderLineCZB.Type::Vendor, '10000', CreateCVBAnkAccount.GetCVBankAccountCode('XTHO'), '23587', 308488.75);
        InsertData('BPRI0001', PaymentOrderLineCZB.Type::Vendor, '30000', CreateCVBAnkAccount.GetCVBankAccountCode('XTHO'), '108021', 732000.0);
        InsertData('BPRI0002', PaymentOrderLineCZB.Type::Vendor, '10000', CreateCVBAnkAccount.GetCVBankAccountCode('XTHO'), '108023', 595186.88);
        InsertData('BPRI0002', PaymentOrderLineCZB.Type::Vendor, '30000', CreateCVBAnkAccount.GetCVBankAccountCode('XTHO'), '108026', 136637.5);
    end;

    var
        PaymentOrderLineCZB: Record "Payment Order Line CZB";
        CreateCVBAnkAccount: Codeunit "Create C/V Bank Account";
        LineNo: Integer;
        PreviousDocumentNo: Code[20];

    procedure InsertData(PaymentOrderNo: Code[20]; Type: Enum "Banking Line Type CZB"; No: Code[20]; BankAccountCode: Code[10]; VariableSymbol: Code[10]; AmountLCY: Decimal)
    begin
        PaymentOrderLineCZB.Init();
        PaymentOrderLineCZB."Payment Order No." := PaymentOrderNo;

        if PreviousDocumentNo <> PaymentOrderNo then begin
            LineNo := 0;
            PreviousDocumentNo := PaymentOrderNo;
        end;

        LineNo := LineNo + 10000;

        PaymentOrderLineCZB.Validate("Line No.", LineNo);
        PaymentOrderLineCZB.Type := Type;
        PaymentOrderLineCZB."Due Date" := WorkDate();
        PaymentOrderLineCZB.Validate("No.", No);
        PaymentOrderLineCZB.Validate("Cust./Vendor Bank Account Code", BankAccountCode);
        PaymentOrderLineCZB.Validate("Variable Symbol", VariableSymbol);
        PaymentOrderLineCZB.Validate("Amount (LCY)", AmountLCY);
        PaymentOrderLineCZB.Insert();
    end;

    procedure CreateEvaluationData()
    begin
        InsertData('BPRI0001', PaymentOrderLineCZB.Type::Vendor, '20000', CreateCVBAnkAccount.GetCVBankAccountCode('XECA'), '13456', 13310.0);
        InsertData('BPRI0001', PaymentOrderLineCZB.Type::Vendor, '20000', CreateCVBAnkAccount.GetCVBankAccountCode('XECA'), '1895', 50000.0);
        InsertData('BPRI0002', PaymentOrderLineCZB.Type::Vendor, '20000', CreateCVBAnkAccount.GetCVBankAccountCode('XECA'), '1114589', 6050.0);
        InsertData('BPRI0002', PaymentOrderLineCZB.Type::Vendor, '20000', CreateCVBAnkAccount.GetCVBankAccountCode('XECA'), '1229685', 42797.70);
    end;
}
