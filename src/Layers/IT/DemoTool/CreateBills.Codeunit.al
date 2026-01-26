codeunit 161380 "Create Bills"
{

    trigger OnRun()
    var
        CreateNoSeries: Codeunit "Create No. Series";
        NoSeries: Record "No. Series";
        TempSeriesCode: Code[10];
    begin
        InsertData(XxBB, XBankTransfer, false, false, '', '', '', '', '', 0, '', XxVNBILLIST, XxBANKTRANSF, '', XxVNBILLS);
        InsertData(XxRB, XCustomerBill, true, true, '2490', XxTMCUSTBILL, XxCUSTBILLS, XxCUSBILLIST, XxRIBA, 0, '', '', '', '', '');

        CreateNoSeries.InsertSeries(TempSeriesCode, XxCUSBILLIST, XCustomerBillList, XxDEC000001, '', '', '', 1, true,
                                         NoSeries."No. Series Type"::Normal, '', 0, '', false);
        CreateNoSeries.InsertSeries(TempSeriesCode, XxVNBILLIST, XVendorBillsBRList, XxDEF00001, '', '', '', 1, true,
                                         NoSeries."No. Series Type"::Normal, '', 0, '', false);
        CreateNoSeries.InsertSeries(TempSeriesCode, XxCUSTBILLS, XFinalCustomerBillNo, XxBILLC00001, '', '', '', 1, true,
                                         NoSeries."No. Series Type"::Normal, '', 0, '', false);
        CreateNoSeries.InsertSeries(TempSeriesCode, XxVNBILLS, XVendorBillsBRNo, XxBILL000001, '', '', '', 1, true,
                                         NoSeries."No. Series Type"::Normal, '', 0, '', false);
        CreateNoSeries.InsertSeries(TempSeriesCode, XxTMDCUS, XTemporaryCustBillListNo, XxTEC000001, '', '',
                                         '', 1, true, NoSeries."No. Series Type"::Normal, '', 0, '', false);
        CreateNoSeries.InsertSeries(TempSeriesCode, XxTMDVEN, XVendorBillsBRListNo, XxTDF00001, '', '', '', 1, true,
                                         NoSeries."No. Series Type"::Normal, '', 0, '', false);
        CreateNoSeries.InsertSeries(TempSeriesCode, XxTMCUSTBILL, XTemporaryCustomerBillNo, XxTEC00001, '', '', '', 1, true,
                                         NoSeries."No. Series Type"::Normal, '', 0, '', false);
    end;

    var
        XxBB: Label 'BB';
        XBankTransfer: Label 'Bank Transfer';
        XxVNBILLIST: Label 'VNBILLIST';
        XxBANKTRANSF: Label 'BANKTRANSF';
        XxVNBILLS: Label 'VNBILLS';
        XxRB: Label 'RB';
        XCustomerBill: Label 'Customer Bill';
        XxTMCUSTBILL: Label 'TMCUSTBILL';
        XxCUSTBILLS: Label 'CUSTBILLS';
        XxCUSBILLIST: Label 'CUSBILLIST';
        XxRIBA: Label 'RIBA';
        XCustomerBillList: Label 'Customer Bill List';
        XxDEC000001: Label 'DEC000001';
        XVendorBillsBRList: Label 'Vendor Bills/BR List';
        XxDEF00001: Label 'DEF00001';
        XFinalCustomerBillNo: Label 'Final Customer Bill No.';
        XxBILLC00001: Label 'BILLC00001';
        XVendorBillsBRNo: Label 'Vendor Bills/BR No.';
        XxBILL000001: Label 'BILL000001';
        XxTMDCUS: Label 'TMDCUS';
        XTemporaryCustBillListNo: Label 'Temporary Cust. Bill List No.';
        XxTEC000001: Label 'TEC000001';
        XxTMDVEN: Label 'TMDVEN';
        XVendorBillsBRListNo: Label 'Vendor Bills/BR List No.';
        XxTDF00001: Label 'TDF00001';
        XTemporaryCustomerBillNo: Label 'Temporary Customer Bill No.';
        XxTEC00001: Label 'TEC00001';

    procedure InsertData("Code": Code[20]; Description: Text[30]; AllowIssue: Boolean; BankReceipt: Boolean; BillsForCollTempAccNo: Code[20]; TemporaryBillNo: Code[10]; FinalBillNo: Code[10]; ListNo: Code[10]; BillSourceCode: Code[10]; BillIDReport: Integer; ReasonCodeCustBill: Code[10]; VendorBillList: Code[10]; VendBillSourceCode: Code[10]; ReasonCodeVendBill: Code[10]; VendorBillNo: Code[10])
    var
        Bill: Record Bill;
    begin
        Bill.Init();
        Bill.Validate(Code, Code);
        Bill.Validate(Description, Description);
        Bill.Validate("Allow Issue", AllowIssue);
        Bill.Validate("Bank Receipt", BankReceipt);
        Bill."Bills for Coll. Temp. Acc. No." := BillsForCollTempAccNo;
        Bill."Temporary Bill No." := TemporaryBillNo;
        Bill."Final Bill No." := FinalBillNo;
        Bill."List No." := ListNo;
        Bill."Bill Source Code" := BillSourceCode;
        Bill.Validate("Bill ID Report", BillIDReport);
        Bill.Validate("Reason Code Cust. Bill", ReasonCodeCustBill);
        Bill."Vendor Bill List" := VendorBillList;
        Bill."Vend. Bill Source Code" := VendBillSourceCode;
        Bill.Validate("Reason Code Vend. Bill", ReasonCodeVendBill);
        Bill."Vendor Bill No." := VendorBillNo;
        Bill.Insert();
    end;
}

