#pragma warning disable AA0247
codeunit 14945 "Advance Statement Helper"
{

    trigger OnRun()
    begin
    end;

    var
        CompInfo: Record "Company Information";
        Employee: Record Employee;
        ExcelReportBuilderManager: Codeunit "Excel Report Builder Manager";
        LocMgt: Codeunit "Localisation Management";
        GeneralManagerTxt: Label 'General Manager';
        AdvReceivedTxt: Label 'Advance received 1.';
        FCYReferenceTxt: Label '  1a. in currency (reference)';
        TotalReceivedTxt: Label 'Received total';
        SpentTxt: Label 'Spent';
        RemainderTxt: Label '  Remainder';
        OverdraftTxt: Label '  Overdraft';
        DocumentsOnTxt: Label 'documents on';
        PagesTxt: Label 'pages';
        LocalReportMgt: Codeunit "Local Report Management";
        RespEmployee: Text;
        RubleTxt: Label 'rub.';
        CopecTxt: Label 'kop.)';

    [Scope('OnPrem')]
    procedure InitReportTemplate()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.TestField("Adv. Statement Template Code");
        ExcelReportBuilderManager.InitTemplate(PurchasesPayablesSetup."Adv. Statement Template Code");
        ExcelReportBuilderManager.SetSheet('Sheet1');

        CompInfo.Get();
    end;

    [Scope('OnPrem')]
    procedure FillHeader(ReportAmount: Decimal; DocumentNo: Code[20]; DocumentDate: Date; ContactNo: Code[20]; ContactName: Text; Purpose: Text)
    begin
        ExcelReportBuilderManager.AddSection('REPORTHEADER');

        ExcelReportBuilderManager.AddDataToSection('CompanyName', CompInfo.Name);
        ExcelReportBuilderManager.AddDataToSection('OKPO', CompInfo."OKPO Code");
        ExcelReportBuilderManager.AddDataToSection('AmountInWordsHeader1',
          CopyStr(LocMgt.Amount2Text('', ReportAmount), 1, 30));
        ExcelReportBuilderManager.AddDataToSection('AmountInWordsHeader2',
          CopyStr(LocMgt.Amount2Text('', ReportAmount), 31, 100));

        ExcelReportBuilderManager.AddDataToSection('ChiefTitle', GeneralManagerTxt);
        ExcelReportBuilderManager.AddDataToSection('AdvanceId', DocumentNo);
        ExcelReportBuilderManager.AddDataToSection('Date', Format(DocumentDate));
        ExcelReportBuilderManager.AddDataToSection('ChiefName', CompInfo."Director Name");

        if Employee.ReadPermission then
            if Employee.Get(ContactNo) then;

        RespEmployee := ContactName;
        ExcelReportBuilderManager.AddDataToSection('EmplName', RespEmployee);
        ExcelReportBuilderManager.AddDataToSection('EmplId', Employee."No.");
        ExcelReportBuilderManager.AddDataToSection('EmplPosition', Employee.GetJobTitleName());
        ExcelReportBuilderManager.AddDataToSection('Target', Purpose);

        ExcelReportBuilderManager.AddDataToSection('ReportDay', Format(Date2DMY(DocumentDate, 1)));
        ExcelReportBuilderManager.AddDataToSection('ReportMonth', LocMgt.GetMonthName(DocumentDate, true));
        ExcelReportBuilderManager.AddDataToSection('ReportYear', Format(Date2DMY(DocumentDate, 3) mod 100));
    end;

    [Scope('OnPrem')]
    procedure FillAdvance(Remainder: Decimal; Overdraft: Decimal)
    begin
        ExcelReportBuilderManager.AddSection('PREVADVANCE');

        ExcelReportBuilderManager.AddDataToSection('Remainder', BlankZeroValue(Remainder));
        ExcelReportBuilderManager.AddDataToSection('Overdraft', BlankZeroValue(Overdraft));
    end;

    [Scope('OnPrem')]
    procedure FillAdvanceDetails(DocReceived: array[4] of Text; DocAmount: array[4] of Decimal; OutstandingAmount: Decimal; Remainder: Decimal; Overdraft: Decimal; DebitAccount: array[8] of Code[20]; DebitAmount: array[8] of Decimal; CreditAccount: Code[20]; CreditAmount: Decimal)
    begin
        FillAdvanceDetailsLine(
          AdvReceivedTxt, DocReceived[1], Abs(DocAmount[1]), DebitAccount[1], DebitAmount[1], CreditAccount, CreditAmount);
        FillAdvanceDetailsLine(
          FCYReferenceTxt, DocReceived[4], Abs(DocAmount[4]), DebitAccount[2], DebitAmount[2], '', 0);
        FillAdvanceDetailsLine(
          '  2.', DocReceived[2], Abs(DocAmount[2]), DebitAccount[3], DebitAmount[3], '', 0);
        FillAdvanceDetailsLine(
          '  3.', DocReceived[3], Abs(DocAmount[3]), DebitAccount[4], DebitAmount[4], '', 0);
        FillAdvanceDetailsLine(
          TotalReceivedTxt, '', Abs(DocAmount[1] + DocAmount[2] + DocAmount[3]),
          DebitAccount[5], DebitAmount[5], '', 0);
        FillAdvanceDetailsLine(
          SpentTxt, '', OutstandingAmount, DebitAccount[6], DebitAmount[6], '', 0);
        FillAdvanceDetailsLine(
          RemainderTxt, '', Abs(Remainder), DebitAccount[7], DebitAmount[7], '', 0);
        FillAdvanceDetailsLine(
          OverdraftTxt, '', Abs(Overdraft), DebitAccount[8], DebitAmount[8], '', 0);
    end;

    local procedure FillAdvanceDetailsLine(LineTxt: Text; Received: Text; Amount: Decimal; DebitAccount: Code[20]; DebitAmount: Decimal; CreditAccount: Code[20]; CreditAmount: Decimal)
    begin
        ExcelReportBuilderManager.AddSection('ADVANCEGRID');

        ExcelReportBuilderManager.AddDataToSection('DocTxt', LineTxt);
        if Received <> '' then
            ExcelReportBuilderManager.AddDataToSection('DocReceived', Format(Received));
        ExcelReportBuilderManager.AddDataToSection('DocAmount', BlankZeroValue(Amount));

        ExcelReportBuilderManager.AddDataToSection('DebetAccount', Format(DebitAccount));
        ExcelReportBuilderManager.AddDataToSection('DebetAmount', BlankZeroValue(DebitAmount));
        if CreditAccount <> '' then
            ExcelReportBuilderManager.AddDataToSection('CreditAccount', Format(CreditAccount));
        ExcelReportBuilderManager.AddDataToSection('CreditAmount', BlankZeroValue(CreditAmount));
    end;

    [Scope('OnPrem')]
    procedure FillSummary(NoOfDocuments: Integer; NoOfPages: Integer; Amount: Decimal; AccountantCode: Code[10]; Remainder: Decimal; Overdraft: Decimal; DocNo: Code[20]; DocDate: Date; CashierCode: Code[10]; HeaderDate: Date)
    var
        Zero: Text;
    begin
        ExcelReportBuilderManager.AddSection('SUMMARY');

        ExcelReportBuilderManager.AddDataToSection('CountReasonDoc', Format(NoOfDocuments));
        ExcelReportBuilderManager.AddDataToSection('DocDeclension', DocumentsOnTxt);
        ExcelReportBuilderManager.AddDataToSection('CountReasonDocPrep', Format(NoOfPages));
        ExcelReportBuilderManager.AddDataToSection('PageDeclension', PagesTxt);

        ExcelReportBuilderManager.AddDataToSection('AmountApprovedTotalInWords', LocMgt.Amount2Text('', Amount));
        ExcelReportBuilderManager.AddDataToSection('ConfirmSum',
          ' ( ' + Format(Amount div 1) + ' ' + RubleTxt + ' ' +
          Zero + Format(Amount mod 1 * 100) + ' ' + CopecTxt);

        ExcelReportBuilderManager.AddDataToSection('ChiefAccountantName', CompInfo."Accountant Name");
        ExcelReportBuilderManager.AddDataToSection('AccountantName', LocalReportMgt.GetEmpName(AccountantCode));

        ExcelReportBuilderManager.AddSection('OVERUNDER');
        ExcelReportBuilderManager.AddDataToSection('AmountRUR',
          BlankZeroValue(Abs(Remainder div 1)) + ' ' + BlankZeroValue(Abs(Overdraft div 1)));
        ExcelReportBuilderManager.AddDataToSection('AmountCOP',
          BlankZeroValue(Abs((Remainder mod 1) * 100)) + ' ' + BlankZeroValue(Abs((Overdraft mod 1) * 100)));
        ExcelReportBuilderManager.AddDataToSection('CashOrder', DocNo);
        ExcelReportBuilderManager.AddDataToSection('CashOrderDate', Format(DocDate));

        ExcelReportBuilderManager.AddSection('ACCOUNTANT');
        ExcelReportBuilderManager.AddDataToSection('CashierName', LocalReportMgt.GetEmpName(CashierCode));
        ExcelReportBuilderManager.AddDataToSection('CashierDate', Format(HeaderDate));
    end;

    [Scope('OnPrem')]
    procedure FillReceipt(DocNo: Code[20]; DocDate: Date; Amount: Decimal; NoOfDocuments: Integer; NoOfPages: Integer; CashierCode: Code[10])
    begin
        ExcelReportBuilderManager.AddSection('RECEIPT');

        ExcelReportBuilderManager.AddDataToSection('ReceiptEmplName', RespEmployee);
        ExcelReportBuilderManager.AddDataToSection('ReceiptAdvNo', DocNo);
        ExcelReportBuilderManager.AddDataToSection('ReceiptAdvDate', Format(DocDate));
        ExcelReportBuilderManager.AddDataToSection('ReceiptAmountTxt', LocMgt.Amount2Text('', Amount));
        ExcelReportBuilderManager.AddDataToSection('ReceiptDocCount', Format(NoOfDocuments));
        ExcelReportBuilderManager.AddDataToSection('ReceiptDocCountPrep', Format(NoOfPages));
        ExcelReportBuilderManager.AddDataToSection('ReceiptDocCountDecl', PagesTxt);
        ExcelReportBuilderManager.AddDataToSection('ReceiptAccountant', LocalReportMgt.GetEmpName(CashierCode));
        ExcelReportBuilderManager.AddDataToSection('ReceiptDate', Format(DocDate));

        ExcelReportBuilderManager.AddPagebreak();
    end;

    [Scope('OnPrem')]
    procedure FillPageHeader()
    begin
        ExcelReportBuilderManager.AddSection('PAGEHEADER');
    end;

    [Scope('OnPrem')]
    procedure FillBody(LineNo: Integer; DocDate: Date; DocNo: Code[20]; Description: Text; AmountLCY: Decimal; AmountFCY: Decimal; SubAcc: Text)
    begin
        ExcelReportBuilderManager.AddSection('EXPENSEGRID');

        ExcelReportBuilderManager.AddDataToSection('LineNum', Format(LineNo));
        ExcelReportBuilderManager.AddDataToSection('DocDate', Format(DocDate));
        ExcelReportBuilderManager.AddDataToSection('DocNum', Format(DocNo));
        ExcelReportBuilderManager.AddDataToSection('DocName', Format(Description));
        ExcelReportBuilderManager.AddDataToSection('AmountMST', BlankZeroValue(AmountLCY));
        ExcelReportBuilderManager.AddDataToSection('AmountCur', BlankZeroValue(AmountFCY));
        ExcelReportBuilderManager.AddDataToSection('AmountMSTApprove', BlankZeroValue(AmountLCY));
        ExcelReportBuilderManager.AddDataToSection('AmountCurApprove', BlankZeroValue(AmountFCY));
        ExcelReportBuilderManager.AddDataToSection('LedAcc', SubAcc);
    end;

    [Scope('OnPrem')]
    procedure FillFooter(AmountLCY: Decimal; AmountFCY: Decimal)
    begin
        ExcelReportBuilderManager.AddSection('FOOTER');

        ExcelReportBuilderManager.AddDataToSection('TotalAmountMST', BlankZeroValue(AmountLCY));
        ExcelReportBuilderManager.AddDataToSection('TotalAmountCur', BlankZeroValue(AmountFCY));
        ExcelReportBuilderManager.AddDataToSection('TotalAmountMSTAppr', BlankZeroValue(AmountLCY));
        ExcelReportBuilderManager.AddDataToSection('TotalAmountCurAppr', BlankZeroValue(AmountFCY));

        ExcelReportBuilderManager.AddDataToSection('FooterEmplName', RespEmployee);
    end;

    [Scope('OnPrem')]
    procedure ExportData()
    begin
        ExcelReportBuilderManager.ExportData();
    end;

    [Scope('OnPrem')]
    procedure ExportDataToClientFile(FileName: Text)
    begin
        ExcelReportBuilderManager.ExportDataToClientFile(FileName);
    end;

    local procedure BlankZeroValue(Value: Decimal): Text
    begin
        if Value = 0 then
            exit('');

        exit(LocalReportMgt.FormatReportValue(Value, 2));
    end;
}

