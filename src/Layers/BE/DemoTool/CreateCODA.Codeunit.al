codeunit 160102 "Create CODA"
{

    trigger OnRun()
    begin
        ModifyBank(XNBL);
        InsertJnlTemplate(XNBL);
        CreateGLAccounts();

        CodedTransactions();
        CodedBankAccStatement();
    end;

    var
        CodedTrans: Record "Transaction Coding";
        GLAccountCategory: Record "G/L Account Category";
        CodBankAccStatement: Record "CODA Statement";
        CodBankAccStatLine: Record "CODA Statement Line";
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
        MessType: Option "Non standard format","Standard format";
        CodId: Option ,,Movement,Information,"Free Message";
        CodType: Option Global,Detail;
        StatementLineNo: Integer;
        XNBL: Label 'NBL';
        XCODATemporaryAccount: Label 'CODA Temporary Account';
        XBankCharges: Label 'Bank Charges';
        XBrokerage: Label 'Brokerage';
        XRedemptionOfLoan: Label 'Redemption of Loan';
        XStockBuyIn: Label 'Stock Buy In';
        XStockExchangeTurnoverTax: Label 'Stock Exchange Turnover Tax';
        XDefaultPosting: Label 'Default Posting';
        XYourSingleTransferOrders: Label 'Your single Transfer Orders';
        XWages: Label 'Wages';
        XYourCollectiveTransferOrders: Label 'Your collective Transfer Orders';
        XGlobalBankCharges: Label 'Global Bank Charges';
        XNetBankCharges: Label 'Net Bank Charges';
        XBankChargesVAT: Label 'Bank Charges VAT';
        XTransferToYourAccount: Label 'Transfer to your Account';
        XPaymentInYourFavour: Label 'Payment in your Favour';
        XYourCheckPayment: Label 'Your Check Payment';
        XCheckRemittance: Label 'Check Remittance';
        XPaymentOfDomiciledInvoice: Label 'Payment of Domiciled Invoice';
        XUnpaidDebtDue: Label 'Unpaid Debt Due';
        XReimbursement: Label 'Reimbursement';
        XStockBuyInGrossAmount: Label 'Stock Buy In Gross Amount';
        XBrokerageOnStocks: Label 'Brokerage on Stocks';
        XTermedLoan: Label 'Termed Loan';
        XFinanceChargesOnLoans: Label 'Finance Charges on Loans';
        XCapitalFinChargesInvestments: Label 'Capital/Finance Charges Investments';
        XFinanceChargesReceived: Label 'Finance Charges Received';
        XWithholdingTaxOnIncome: Label 'Withholding Tax on Income';
        XForeignTransferCosts: Label 'Foreign Transfer Costs';
        XForeignTransferVAT: Label 'Foreign Transfer VAT';
        XForeignTransfPaymCommision: Label 'Foreign Transfer Payment Commision';
        XForeignTransferPhoneCosts: Label 'Foreign Transfer Phone Costs';
        XForeignTransferGrossAmount: Label 'Foreign Transfer Gross Amount';
        XByOrderOf: Label 'BY ORDER OF :';
        XPrepaymentShipment: Label 'PREPAYMENT SHIPMENT OF 10/12/99';
        XRabobank: Label 'RABOBANK NETHERLANDS';
        XTransferOrderCharges: Label 'TRANSFER ORDER CHARGES :';
        XCorrespondent: Label 'CORRESPONDENT';
        XChargesToYourDebitInEUR: Label 'CHARGES TO YOUR DEBIT IN EUR :';
        XPaymentCommission: Label 'PAYMENT COMMISSION';
        XVATTaxable: Label 'VAT TAXABLE';
        XTotalToYourDebit: Label 'TOTAL TO YOUR DEBIT :';
        XMillersAndCo: Label 'MILLERS & CO';
        XAsOfDateYouAreInvitedTo: Label 'AS OF 03/03 YOU ARE INVITED TO SUBSCRIBE TO THE';
        XNewGovernmentLoanUsingRef: Label 'NEW GOVERNMENT LOAN USING REF. 45/66392';
        XPleaseContactYourBankManager: Label 'PLEASE CONTACT YOUR BANK MANAGER FOR MORE INFORMATION.';

    procedure CreateTrialData()
    begin
        CreateGLAccounts();

        CodedTransactions();
    end;

    procedure CreateEvaluationData()
    begin
        ModifyBank(XNBL);
        InsertJnlTemplate(XNBL);
        CodedBankAccStatement();
    end;

    local procedure CreateGLAccounts()
    begin
        InsertGLAccount('499999', XCODATemporaryAccount);
        UpdateAccountCategory('499999', GLAccountCategory."Account Category"::Assets, 2); // Asset
        InsertGLAccount('656000', XBankCharges);
        UpdateAccountCategory('656000', GLAccountCategory."Account Category"::Expense, 34); // Bank Charges
        InsertGLAccount('614200', XBrokerage);
        UpdateAccountCategory('614200', GLAccountCategory."Account Category"::Expense, 33); // Brokerage
        InsertGLAccount('420000', XRedemptionOfLoan);
        UpdateAccountCategory('420000', GLAccountCategory."Account Category"::Assets, 4); // Redemption of Loan
        InsertGLAccount('520000', XStockBuyIn);
        UpdateAccountCategory('520000', GLAccountCategory."Account Category"::Assets, 2); // Stock Buy In
        InsertGLAccount('656100', XStockExchangeTurnoverTax);
        UpdateAccountCategory('656100', GLAccountCategory."Account Category"::Expense, 34); // Stock Exchange Turnover Tax
    end;

    procedure ModifyBank(BankAccount: Code[10])
    var
        BankAcc: Record "Bank Account";
    begin
        if BankAcc.Get(BankAccount) then begin
            BankAcc."Protocol No." := '290';
            BankAcc."Version Code" := '1';
            BankAcc.Modify();
        end;
    end;

    procedure InsertJnlTemplate(TemplateName: Code[10])
    var
        GenJnlTemplate: Record "Gen. Journal Template";
    begin
        GenJnlTemplate.Name := TemplateName;
        GenJnlTemplate.Description := TemplateName;
        GenJnlTemplate.Validate(Type, GenJnlTemplate.Type::Financial);
        GenJnlTemplate."Force Doc. Balance" := true;
        GenJnlTemplate."Bal. Account Type" := GenJnlTemplate."Bal. Account Type"::"Bank Account";
        GenJnlTemplate."Bal. Account No." := TemplateName;
        GenJnlTemplate.Insert();
    end;

    procedure InsertGLAccount(GlAccount: Code[20]; VarName: Text[30])
    var
        GLAcc: Record "G/L Account";
    begin
        GLAcc.Init();
        GLAcc."No." := GlAccount;
        GLAcc.Name := VarName;
        if GLAcc."No." < '600000' then
            GLAcc."Income/Balance" := GLAcc."Income/Balance"::"Balance Sheet";

        if not GLAcc.Insert() then
            GLAcc.Modify();
    end;

    procedure CodedTransactions()
    begin
        InsertCodedTransaction(
          0, 0, 0, CodedTrans."Globalisation Code"::Global, CodedTrans."Account Type"::"G/L Account", '499999', XDefaultPosting);
        InsertCodedTransaction(
          1, 1, 0, CodedTrans."Globalisation Code"::Global, CodedTrans."Account Type"::Vendor, '', XYourSingleTransferOrders);
        InsertCodedTransaction(
          1, 5, 0, CodedTrans."Globalisation Code"::Global, CodedTrans."Account Type"::"G/L Account", '620300', XWages);
        InsertCodedTransaction(
          1, 7, 0, CodedTrans."Globalisation Code"::Global, CodedTrans."Account Type"::"G/L Account", '550005', XYourCollectiveTransferOrders);
        InsertCodedTransaction(
          1, 37, 0, CodedTrans."Globalisation Code"::Global, CodedTrans."Account Type"::"G/L Account", '656000', XGlobalBankCharges);
        InsertCodedTransaction(
          1, 37, 6, CodedTrans."Globalisation Code"::Global, CodedTrans."Account Type"::"G/L Account", '656000', XNetBankCharges);
        InsertCodedTransaction(
          1, 37, 11, CodedTrans."Globalisation Code"::Global, CodedTrans."Account Type"::"G/L Account", '411000', XBankChargesVAT);
        InsertCodedTransaction(
          1, 50, 0, CodedTrans."Globalisation Code"::Global, CodedTrans."Account Type"::Customer, '', XTransferToYourAccount);
        InsertCodedTransaction(
          1, 52, 0, CodedTrans."Globalisation Code"::Global, CodedTrans."Account Type"::Customer, '', XPaymentInYourFavour);
        InsertCodedTransaction(
          3, 1, 0, CodedTrans."Globalisation Code"::Global, CodedTrans."Account Type"::"G/L Account", '499999', XYourCheckPayment);
        InsertCodedTransaction(
          3, 52, 0, CodedTrans."Globalisation Code"::Global, CodedTrans."Account Type"::"G/L Account", '499999', XCheckRemittance);
        InsertCodedTransaction(
          5, 1, 0, CodedTrans."Globalisation Code"::Global, CodedTrans."Account Type"::Vendor, '', XPaymentOfDomiciledInvoice);
        InsertCodedTransaction(
          5, 3, 0, CodedTrans."Globalisation Code"::Global, CodedTrans."Account Type"::Customer, '', XUnpaidDebtDue);
        InsertCodedTransaction(
          5, 5, 0, CodedTrans."Globalisation Code"::Global, CodedTrans."Account Type"::Customer, '', XReimbursement);
        InsertCodedTransaction(
          11, 1, 0, CodedTrans."Globalisation Code"::Global, CodedTrans."Account Type"::"G/L Account", '520000', XStockBuyIn);
        InsertCodedTransaction(
          11, 1, 100, CodedTrans."Globalisation Code"::Global, CodedTrans."Account Type"::"G/L Account", '520000', XStockBuyInGrossAmount);
        InsertCodedTransaction(
          11, 1, 426, CodedTrans."Globalisation Code"::Global, CodedTrans."Account Type"::"G/L Account", '614200', XBrokerageOnStocks);
        InsertCodedTransaction(
          11, 1, 427, CodedTrans."Globalisation Code"::Global, CodedTrans."Account Type"::"G/L Account", '656100', XStockExchangeTurnoverTax);
        InsertCodedTransaction(
          13, 11, 0, CodedTrans."Globalisation Code"::Global, CodedTrans."Account Type"::"G/L Account", '420000', XTermedLoan);
        InsertCodedTransaction(
          13, 11, 2, CodedTrans."Globalisation Code"::Global, CodedTrans."Account Type"::"G/L Account", '650000', XFinanceChargesOnLoans);
        InsertCodedTransaction(
          13, 11, 55, CodedTrans."Globalisation Code"::Global, CodedTrans."Account Type"::"G/L Account", '420000', XRedemptionOfLoan);
        InsertCodedTransaction(
          30, 54, 0, CodedTrans."Globalisation Code"::Detail, CodedTrans."Account Type"::"G/L Account", '580000', XCapitalFinChargesInvestments)
        ;
        InsertCodedTransaction(
          30, 54, 1, CodedTrans."Globalisation Code"::Global, CodedTrans."Account Type"::"G/L Account", '750000', XFinanceChargesReceived);
        InsertCodedTransaction(
          30, 54, 51, CodedTrans."Globalisation Code"::Global, CodedTrans."Account Type"::"G/L Account", '650000', XWithholdingTaxOnIncome);
        InsertCodedTransaction(
          41, 37, 0, CodedTrans."Globalisation Code"::Detail, CodedTrans."Account Type"::"G/L Account", '656000', XForeignTransferCosts);
        InsertCodedTransaction(
          41, 37, 11, CodedTrans."Globalisation Code"::Detail, CodedTrans."Account Type"::"G/L Account", '411000', XForeignTransferVAT);
        InsertCodedTransaction(
          41, 37, 13, CodedTrans."Globalisation Code"::Detail, CodedTrans."Account Type"::"G/L Account", '656000', XForeignTransfPaymCommision);
        InsertCodedTransaction(
          41, 37, 39, CodedTrans."Globalisation Code"::Detail, CodedTrans."Account Type"::"G/L Account", '612200', XForeignTransferPhoneCosts);
        InsertCodedTransaction(
          41, 37, 100, CodedTrans."Globalisation Code"::Detail, CodedTrans."Account Type"::"G/L Account", '656000', XForeignTransferGrossAmount)
        ;
    end;

    procedure InsertCodedTransaction(Family: Integer; Transact: Integer; RowTitle: Integer; Glob: Option; AccType: Option; AccNo: Code[20]; Desc: Text[250])
    begin
        CodedTrans."Transaction Family" := Family;
        CodedTrans.Transaction := Transact;
        CodedTrans."Transaction Category" := RowTitle;
        CodedTrans."Globalisation Code" := Glob;
        CodedTrans."Account Type" := AccType;
        CodedTrans."Account No." := AccNo;
        CodedTrans.Description := Desc;
        CodedTrans.Insert();
    end;

    procedure CodedBankAccStatement()
    var
        Cust: Record Customer;
        Vend: Record Vendor;
        CustName: Text[26];
        CustAddress: Text[26];
        CustCity: Text[26];
        VendName: Text[26];
        VendAddress: Text[26];
        VendCity: Text[26];
    begin
        InsertCodedBankAccStatement(XNBL, '216', 1853323, 20010216D, 983935);

        Cust.Get('10000');
        CustName := CopyStr(Cust.Name, 1, 26);
        CustAddress := CopyStr(Cust.Address, 1, 26);
        CustCity := CopyStr(Cust.City, 1, 26);
        InsertCodedBankAccStatLine(
          CodId::Movement, CodType::Global, '230058315713', 498297, 20080217D, 0, 1, 50, 0, MessType::"Non standard format", 0,
          '*** 00/9906/86864***', 20080217D, '230058315713', CustName, CustAddress, CustCity, 0, '216/1');
        InsertCodedBankAccStatLine(
          CodId::"Free Message", CodType::Global, '', 0, 0D, 0, 0, 0, 0, MessType::"Non standard format", 0,
          'REF. 850719730107                             + 498.297 EUR', 0D, '', '', '', '', 10000, '216/1');
        InsertCodedBankAccStatLine(
          CodId::"Free Message", CodType::Global, '', 0, 0D, 0, 0, 0, 0, MessType::"Non standard format", 0,
          XByOrderOf + '               ' + '230-0583157-13', 0D, '', '', '', '', 10000, '216/1');
        InsertCodedBankAccStatLine(
          CodId::"Free Message", CodType::Global, '', 0, 0D, 0, 0, 0, 0, MessType::"Non standard format", 0,
          CustName + '    ' + CustAddress, 0D, '', '', '', '', 10000, '216/1');
        InsertCodedBankAccStatLine(
          CodId::"Free Message", CodType::Global, '', 0, 0D, 0, 0, 0, 0, MessType::"Non standard format", 0,
          CustCity, 0D, '', '', '', '', 10000, '216/1');
        InsertCodedBankAccStatLine(
          CodId::"Free Message", CodType::Global, '', 0, 0D, 0, 0, 0, 0, MessType::"Non standard format", 0,
          '*** 00/9906/103001***', 0D, '', '', '', '', 10000, '216/1');
        InsertCodedBankAccStatLine(
          CodId::Movement, CodType::Global, '4850743000074', 6967, 20080217D, 2, 1, 50, 0, MessType::"Non standard format", 0,
          'REF. **/36.9288', 20080217D, '', '', '', '', 0, '216/2');
        Cust.Get('40000');
        CustName := CopyStr(Cust.Name, 1, 26);
        CustAddress := CopyStr(Cust.Address, 1, 26);
        CustCity := CopyStr(Cust.City, 1, 26);
        InsertCodedBankAccStatLine(
          CodId::Movement, CodType::Global, '230058315713', 100200, 20080217D, 0, 1, 50, 0, MessType::"Non standard format", 0,
          '*** 00/9906/84037***', 20080217D, '310054005646', CustName, CustAddress, CustCity, 0, '216/3');
        InsertCodedBankAccStatLine(
          CodId::"Free Message", CodType::Global, '', 0, 0D, 0, 0, 0, 0, MessType::"Non standard format", 0,
          'REF. 850719730107                             + 100.200 EUR', 0D, '', '', '', '', 80000, '216/3');
        InsertCodedBankAccStatLine(
          CodId::"Free Message", CodType::Global, '', 0, 0D, 0, 0, 0, 0, MessType::"Non standard format", 0,
          XByOrderOf + '               ' + '310-0540056-46', 0D, '', '', '', '', 80000, '216/3');
        InsertCodedBankAccStatLine(
          CodId::"Free Message", CodType::Global, '', 0, 0D, 0, 0, 0, 0, MessType::"Non standard format", 0,
          CustName + '     ' + CustAddress, 0D, '', '', '', '', 80000, '216/3');
        InsertCodedBankAccStatLine(
          CodId::"Free Message", CodType::Global, '', 0, 0D, 0, 0, 0, 0, MessType::"Non standard format", 0,
          CustCity, 0D, '', '', '', '', 80000, '216/3');
        InsertCodedBankAccStatLine(
          CodId::"Free Message", CodType::Global, '', 0, 0D, 0, 0, 0, 0, MessType::"Non standard format", 0,
          XPrepaymentShipment, 0D, '', '', '', '', 80000, '216/3');
        InsertCodedBankAccStatLine(
          CodId::Movement, CodType::Global, '4850750705981', -1208, 20010216D, 0, 3, 3, 0, MessType::"Standard format", 107,
          '4001969689460002 00001602010000 ARAL MECHELEN    MECHELEN', 20080217D, '', '', '', '', 0, '216/4');
        Cust.Get('20000');
        CustName := CopyStr(Cust.Name, 1, 26);
        CustAddress := CopyStr(Cust.Address, 1, 26);
        CustCity := CopyStr(Cust.City, 1, 26);
        InsertCodedBankAccStatLine(
          CodId::Movement, CodType::Global, '788535710831', 426053, 20080217D, 0, 1, 50, 0, MessType::"Standard format", 101,
          '000010300285', 20080217D, '788535710831', CustName, CustAddress, CustCity, 0, '216/5');
        InsertCodedBankAccStatLine(
          CodId::Movement, CodType::Global, '4866447710582', -182, 20080217D, 3, 41, 37, 0, MessType::"Non standard format", 0,
          '', 20080217D, '', '', '', '', 0, '216/6');
        InsertCodedBankAccStatLine(
          CodId::Information, CodType::Global, '4866447710582', 0, 0D, 3, 41, 37, 0, MessType::"Non standard format", 0,
          XRabobank, 0D, '', '', '', '', 160000, '216/6');
        InsertCodedBankAccStatLine(
          CodId::Information, CodType::Global, '4866447710582', 0, 0D, 3, 41, 37, 0, MessType::"Non standard format", 0,
          XTransferOrderCharges + '                        EUR         5550,00', 0D, '', '', '', '', 160000, '216/6');
        InsertCodedBankAccStatLine(
          CodId::"Free Message", CodType::Global, '', 0, 0D, 0, 0, 0, 0, MessType::"Non standard format", 0,
          'REF. 866447710582                                 FOLIO 01', 0D, '', '', '', '', 160000, '216/6');
        InsertCodedBankAccStatLine(
          CodId::"Free Message", CodType::Global, '', 0, 0D, 0, 0, 0, 0, MessType::"Non standard format", 0,
          XTransferOrderCharges, 0D, '', '', '', '', 160000, '216/6');
        InsertCodedBankAccStatLine(
          CodId::"Free Message", CodType::Global, '', 0, 0D, 0, 0, 0, 0, MessType::"Non standard format", 0,
          'EUR               5550,00 O.REF. :  0298077832710582 2311', 0D, '', '', '', '', 160000, '216/6');
        InsertCodedBankAccStatLine(
          CodId::"Free Message", CodType::Global, '', 0, 0D, 0, 0, 0, 0, MessType::"Non standard format", 0,
          XCorrespondent + '   ' + XRabobank, 0D, '', '', '', '', 160000, '216/6');
        InsertCodedBankAccStatLine(
          CodId::"Free Message", CodType::Global, '', 0, 0D, 0, 0, 0, 0,
          MessType::"Non standard format", 0, XChargesToYourDebitInEUR, 0D, '', '', '', '', 160000, '216/6');
        InsertCodedBankAccStatLine(
          CodId::"Free Message", CodType::Global, '', 0, 0D, 0, 0, 0, 0,
          MessType::"Non standard format", 0, XPaymentCommission + '                 150,00', 0D, '', '', '', '', 160000, '216/6');
        InsertCodedBankAccStatLine(
          CodId::"Free Message", CodType::Global, '', 0, 0D, 0, 0, 0, 0,
          MessType::"Non standard format", 0, XVATTaxable + '       150,00 VAT   21,00%            32,00', 0D, '', '', '', '', 160000, '216/6');
        InsertCodedBankAccStatLine(
          CodId::"Free Message", CodType::Global, '', 0, 0D, 0, 0, 0, 0,
          MessType::"Non standard format", 0, XTotalToYourDebit + '     VAL. 15.02 EUR              182,00', 0D, '', '', '', '', 160000, '216/6');
        InsertCodedBankAccStatLine(
          CodId::Movement, CodType::Detail, '4866447710582', -32, 20080217D, 8, 41, 37, 11, MessType::"Standard format", 106,
          '0000000000320000000150000002100000000 000000000032000', 20080217D, '', '', '', '', 160000, '216/6-1');
        InsertCodedBankAccStatLine(
          CodId::Movement, CodType::Detail, '4866447710582', -150, 20080217D, 8, 41, 37, 13,
          MessType::"Non standard format", 0, '', 20080217D, '', '', '', '', 160000, '216/6-2');
        Vend.Get('30000');
        VendName := CopyStr(Vend.Name, 1, 26);
        VendAddress := CopyStr(Vend.Address, 1, 26);
        VendCity := CopyStr(Vend.City, 1, 26);
        InsertCodedBankAccStatLine(
          CodId::Movement, CodType::Global, '4850659338955', -220099, 20080217D, 0, 1, 1, 0,
          MessType::"Non standard format", 0, '101000010802665', 20080217D, '431068010811', VendName, VendAddress, VendCity, 0, '216/7');
        InsertCodedBankAccStatLine(
          CodId::Movement, CodType::Global, '4850836332760', -1700, 20080217D, 0, 1, 1, 0, MessType::"Standard format",
          101, '198411561414', 20080217D, '431068011114', XMillersAndCo, '', '', 0, '216/8');
        InsertCodedBankAccStatLine(
          CodId::"Free Message", CodType::Global, '', 0, 0D, 0, 0, 0, 0, MessType::"Non standard format", 0,
          XAsOfDateYouAreInvitedTo, 0D, '', '', '', '', 0, '216/0');
        InsertCodedBankAccStatLine(
          CodId::"Free Message", CodType::Global, '', 0, 0D, 0, 0, 0, 0, MessType::"Non standard format", 0,
          XNewGovernmentLoanUsingRef, 0D, '', '', '', '', 0, '216/0');
        InsertCodedBankAccStatLine(
          CodId::"Free Message", CodType::Global, '', 0, 0D, 0, 0, 0, 0, MessType::"Non standard format", 0,
          XPleaseContactYourBankManager, 0D, '', '', '', '', 0, '216/0');
    end;

    procedure InsertCodedBankAccStatement(BankAccountNo: Code[10]; StatementNo: Code[10]; EndingBalance: Decimal; StatementDate: Date; BalanceLastStat: Decimal)
    begin
        CodBankAccStatement."Bank Account No." := BankAccountNo;
        CodBankAccStatement."Statement No." := StatementNo;
        CodBankAccStatement."Statement Ending Balance" := EndingBalance;
        CodBankAccStatement."Statement Date" := StatementDate;
        CodBankAccStatement."Balance Last Statement" := BalanceLastStat;
        CodBankAccStatement.Insert();
    end;

    procedure InsertCodedBankAccStatLine(StatId: Option; StatType: Option; BankReferenceNo: Text[13]; StatAmount: Decimal; TransactionDate: Date; TransactionType: Integer; TransactionFamily: Integer; StatTransaction: Integer; TransactionCat: Integer; MessageType: Option; TypeStandardMessage: Integer; StatMessage: Text[250]; PostingDate: Date; BankAccNoOtherParty: Text[12]; NameOtherParty: Text[26]; AddressOtherParty: Text[26]; CityOtherParty: Text[26]; AttachedToLineNo: Integer; DocumentNo: Code[20])
    begin
        StatementLineNo := StatementLineNo + 10000;

        CodBankAccStatLine."Bank Account No." := XNBL;
        CodBankAccStatLine."Statement No." := '216';
        CodBankAccStatLine."Statement Line No." := StatementLineNo;
        CodBankAccStatLine.ID := StatId;
        CodBankAccStatLine.Type := StatType;
        CodBankAccStatLine."Bank Reference No." := BankReferenceNo;
        CodBankAccStatLine."Statement Amount" := StatAmount;
        CodBankAccStatLine."Transaction Date" := TransactionDate;
        CodBankAccStatLine."Transaction Type" := TransactionType;
        CodBankAccStatLine."Transaction Family" := TransactionFamily;
        CodBankAccStatLine.Transaction := StatTransaction;
        CodBankAccStatLine."Transaction Category" := TransactionCat;
        CodBankAccStatLine."Message Type" := MessageType;
        CodBankAccStatLine."Type Standard Format Message" := TypeStandardMessage;
        CodBankAccStatLine."Statement Message" := StatMessage;
        CodBankAccStatLine."Posting Date" := PostingDate;
        CodBankAccStatLine."Bank Account No. Other Party" := BankAccNoOtherParty;
        CodBankAccStatLine."Name Other Party" := NameOtherParty;
        CodBankAccStatLine."Address Other Party" := AddressOtherParty;
        CodBankAccStatLine."City Other Party" := CityOtherParty;
        CodBankAccStatLine."Attached to Line No." := AttachedToLineNo;
        CodBankAccStatLine."Document No." := DocumentNo;
        CodBankAccStatLine."Unapplied Amount" := StatAmount;
        CodBankAccStatLine.Insert();
    end;

    local procedure UpdateAccountCategory(GLAccountNo: Code[20]; AccountCategoryValue: Option; AccountSubcategoryEntryNo: Integer)
    var
        GLAccount: Record "G/L Account";
        GLAccountCategory: Record "G/L Account Category";
    begin
        GLAccount.Get(GLAccountNo);
        GLAccountCategoryMgt.GetAccountCategory(GLAccountCategory, AccountCategoryValue);
        GLAccount."Account Category" := "G/L Account Category".FromInteger(GLAccountCategory."Account Category");
        GLAccount."Account Subcategory Entry No." := AccountSubcategoryEntryNo;
        GLAccount.Modify(true);
    end;
}

