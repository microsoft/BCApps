codeunit 163510 "Create Cash Desk CZP"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData(XCashDesk1, XCD01, 10000.0, 5000.0, 5000.0, CreateRoundingMethod.GetRoundingMethod('XWHOLE'));
    end;

    var
        CashDeskCZP: Record "Cash Desk CZP";
        DemoDataSetup: Record "Demo Data Setup";
        CreateNoSeries: Codeunit "Create No. Series";
        CreateRoundingMethod: Codeunit "Create Rounding Method";
        CreateBankAccPostingGroup: Codeunit "Create Bank Acc. Posting Group";
        XCashDesk1: Label 'Cash Desk 1';
        XCD01: Label 'CD01';
        XCDR: Label 'CD-P';
        XCDW: Label 'CD-W';
        XCashDocumentReceipts: Label 'Cash Document Receipts';
        XCashDocumentWithdrawals: Label 'Cash Document Withdrawals';

    procedure InsertData(Name: Text[100]; BankAccPostingGroup: Code[20]; MaxBalance: Decimal; CashReceiptLimit: Decimal; CashWithdrawalLimit: Decimal; RoundingMethodCode: Code[10])
    begin
        CashDeskCZP.Init();
        CashDeskCZP."No." := '';
        CashDeskCZP.Insert(true);

        CashDeskCZP.Name := Name;
        CashDeskCZP."Bank Acc. Posting Group" := BankAccPostingGroup;
        CashDeskCZP."Rounding Method Code" := RoundingMethodCode;
        CashDeskCZP."Debit Rounding Account" := '568100';
        CashDeskCZP."Credit Rounding Account" := '668100';
        CashDeskCZP."Max. Balance" := MaxBalance;
        CashDeskCZP."Cash Receipt Limit" := CashReceiptLimit;
        CashDeskCZP."Cash Withdrawal Limit" := CashWithdrawalLimit;

        CreateNoSeries.InitBaseSeries2(
          CashDeskCZP."Cash Document Receipt Nos.", XCDR, XCashDocumentReceipts, 'PPD0001', '', '', '', 1);
        CreateNoSeries.InitBaseSeries2(
          CashDeskCZP."Cash Document Withdrawal Nos.", XCDW, XCashDocumentWithdrawals, 'VPD0001', '', '', '', 1);

        CashDeskCZP.Modify(true);
    end;

    procedure CreateEvaluationData()
    begin
        DemoDataSetup.Get();
        InsertData(XCashDesk1, CreateBankAccPostingGroup.GetBankAccPostingGroup('XCASHDESK'), 10000.0, 270000.0, 270000.0, CreateRoundingMethod.GetRoundingMethod('XCROWNS'));
    end;

    procedure GetCashDeskCode(CashDeskCode: Text): Code[20]
    begin
        case UpperCase(CashDeskCode) of
            'XCD01':
                exit(XCD01)
        end
    end;
}
