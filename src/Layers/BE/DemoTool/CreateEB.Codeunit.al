codeunit 160100 "Create EB"
{

    trigger OnRun()
    begin
        InitializeSetup();

        // Assign/Change Bank Acc.
        PrepareVendors();

        // IBLC/BLWI initialization
        InitializeIBLCcodes('090', XTransactionsOfGoods);
        InitializeIBLCcodes('091', XReimbursement);
        InitializeIBLCcodes('092', XEU3PartyTradeTransit);

        AddExportProtocols();
    end;

    var
        Vend: Record Vendor;
        XTransactionsOfGoods: Label 'Transactions of goods crossing national borders';
        XReimbursement: Label 'Reimbursement';
        XEU3PartyTradeTransit: Label 'EU 3 Party Trade - Transit';
        XNonEuroPaymentDescTxt: Label 'Parties share fees.';
        XEuroPaymentDescTxt: Label 'Sender pays fees.';

    procedure CreateTrialData()
    begin
        InitializeSetup();

        // IBLC/BLWI initialization
        InitializeIBLCcodes('090', XTransactionsOfGoods);
        InitializeIBLCcodes('091', XReimbursement);
        InitializeIBLCcodes('092', XEU3PartyTradeTransit);
        AddExportProtocols();
    end;

    procedure CreateEvaluationData()
    begin
        // Assign/Change Bank Acc.
        PrepareVendors();
    end;

    procedure PrepareVendors()
    var
        VendBankAcc: Record "Vendor Bank Account";
        BankAccNo: Text[30];
        CheckSum: Text[30];
    begin
        Vend.Reset();
        Vend.ModifyAll("Suggest Payments", true);
        // Initialize bank account for companies with LCY
        BankAccNo := '431-0680106';
        CheckSum := '-09';
        Vend.SetRange("Country/Region Code", '');
        if Vend.Find('-') then
            repeat
                VendBankAcc.SetRange("Vendor No.", Vend."No.");
                if VendBankAcc.FindFirst() then begin
                    VendBankAcc."Bank Account No." := BankAccNo + CheckSum;
                    VendBankAcc.Modify();
                    Vend."Preferred Bank Account Code" := VendBankAcc.Code;
                    Vend.Modify();
                end;
                BankAccNo := IncStr(BankAccNo);
                CheckSum := IncStr(CheckSum);
            until Vend.Next() = 0;
    end;

    procedure InitializeIBLCcodes(Codes: Code[10]; Desc: Text[250])
    var
        IBLCcode: Record "IBLC/BLWI Transaction Code";
    begin
        IBLCcode.Init();
        IBLCcode."Transaction Code" := Codes;
        IBLCcode.Description := Desc;
        if not IBLCcode.Insert() then
            IBLCcode.Modify();
    end;

    procedure InitializeSetup()
    var
        EBSetup: Record "Electronic Banking Setup";
    begin
        EBSetup.Get();
        EBSetup."Summarize Gen. Jnl. Lines" := true;
        EBSetup."Cut off Payment Message Texts" := false;
        EBSetup.Modify();
    end;

    local procedure AddExportProtocols()
    var
        ExportProtocol: Record "Export Protocol";
    begin
        InsertExportProtocol('Domestic', 'Domestic export protocol.', 2000002, 2000001, '',
          ExportProtocol."Export Object Type"::Report, ExportProtocol."Code Expenses"::SHA);
        InsertExportProtocol('International-SHA', 'Parties share transfer fees for an intl. payment.', 2000003, 2000002, '',
          ExportProtocol."Export Object Type"::Report, ExportProtocol."Code Expenses"::SHA);
        InsertExportProtocol('International-BEN', 'Receiver pays the fees for an intl. payment.', 2000003, 2000002, '',
          ExportProtocol."Export Object Type"::Report, ExportProtocol."Code Expenses"::BEN);
        InsertExportProtocol('International-OUR', 'The sender pays the fees for an intl. payment.', 2000003, 2000002, '',
          ExportProtocol."Export Object Type"::Report, ExportProtocol."Code Expenses"::OUR);
        InsertExportProtocol('SEPA', XEuroPaymentDescTxt, Codeunit::"Check SEPA Payments", Report::"File SEPA Payments", '',
          ExportProtocol."Export Object Type"::Report, ExportProtocol."Code Expenses"::SHA);
        InsertExportProtocol('Non-Euro SEPA', XNonEuroPaymentDescTxt, Codeunit::"Check Non Euro SEPA Payments", Report::"File Non Euro SEPA Payments", '',
          ExportProtocol."Export Object Type"::Report, ExportProtocol."Code Expenses"::SHA);
        InsertExportProtocol('SEPA00100109', XEuroPaymentDescTxt, Codeunit::"Check SEPA Payments", Report::"File SEPA 001.001.09 Pmts", '',
          ExportProtocol."Export Object Type"::Report, ExportProtocol."Code Expenses"::SHA);
        InsertExportProtocol('NONEURO SEPA00100109', XNonEuroPaymentDescTxt, Codeunit::"Check Non Euro SEPA Payments", Report::"File FCY SEPA 001.001.09 Pmts", '',
          ExportProtocol."Export Object Type"::Report, ExportProtocol."Code Expenses"::SHA);
        InsertExportProtocol('Zero', 'The sending bank decides who pays the bank fees.', 0, 1000, '',
          ExportProtocol."Export Object Type"::XMLPort, ExportProtocol."Code Expenses"::" ");
    end;

    local procedure InsertExportProtocol(ExpenseCode: Code[20]; ExpenseDescription: Text[50]; CheckObjectID: Integer; ExportObjectID: Integer; ExportNoSeries: Code[20]; ExportObjectType: Option; CodeExpense: Option)
    var
        ExportProtocol: Record "Export Protocol";
    begin
        ExportProtocol.Init();
        ExportProtocol.Code := ExpenseCode;
        ExportProtocol.Description := ExpenseDescription;
        ExportProtocol.Validate("Check Object ID", CheckObjectID);
        ExportProtocol."Export Object ID" := ExportObjectID;
        ExportProtocol."Export No. Series" := ExportNoSeries;
        ExportProtocol."Export Object Type" := ExportObjectType;
        ExportProtocol."Code Expenses" := CodeExpense;
        ExportProtocol.Insert();
    end;
}

