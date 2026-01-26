// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Foundation.Address;
using Microsoft.Purchases.Vendor;
using System.Utilities;

report 7000009 "Payment Order - Test"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Purchases/Payables/PaymentOrderTest.rdlc';
    Caption = 'Payment Order - Test';

    dataset
    {
        dataitem(PmtOrd; "Payment Order")
        {
            RequestFilterFields = "No.";
            column(PmtOrd_No_; "No.")
            {
            }
            column(PmtOrd_Bank_Account_No_; "Bank Account No.")
            {
            }
            column(PmtOrd_Currency_Code; "Currency Code")
            {
            }
            dataitem(PageCounter; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(USERID; UserId)
                {
                }
                column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
                {
                }
                column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
                {
                }
                column(PmtOrd_TABLECAPTION__________PmtOrdFilter; PmtOrd.TableCaption + ':' + PmtOrdFilter)
                {
                }
                column(PmtOrd_TABLECAPTION_________PmtOrd__No__; PmtOrd.TableCaption + ' ' + PmtOrd."No.")
                {
                }
                column(BankAccAddr_1_; BankAccAddr[1])
                {
                }
                column(BankAccAddr_2_; BankAccAddr[2])
                {
                }
                column(BankAccAddr_3_; BankAccAddr[3])
                {
                }
                column(BankAccAddr_4_; BankAccAddr[4])
                {
                }
                column(BankAccAddr_5_; BankAccAddr[5])
                {
                }
                column(BankAccAddr_6_; BankAccAddr[6])
                {
                }
                column(BankAccAddr_7_; BankAccAddr[7])
                {
                }
                column(PmtOrd__Bank_Account_Name_; PmtOrd."Bank Account Name")
                {
                }
                column(Posting_Date; Format(PmtOrd."Posting Date"))
                {
                }
                column(PmtOrd__Posting_Description_; PmtOrd."Posting Description")
                {
                }
                column(PostingGroup; PostingGroup)
                {
                }
                column(PmtOrd__Currency_Code_; PmtOrd."Currency Code")
                {
                }
                column(PageCounter_Number; Number)
                {
                }
                column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
                {
                }
                column(Payment_Order___TestCaption; Payment_Order___TestCaptionLbl)
                {
                }
                column(PmtOrd__Bank_Account_Name_Caption; PmtOrd__Bank_Account_Name_CaptionLbl)
                {
                }
                column(PmtOrd__Posting_Date_Caption; PmtOrd__Posting_Date_CaptionLbl)
                {
                }
                column(PmtOrd__Posting_Description_Caption; PmtOrd__Posting_Description_CaptionLbl)
                {
                }
                column(PostingGroupCaption; PostingGroupCaptionLbl)
                {
                }
                column(PmtOrd__Currency_Code_Caption; PmtOrd__Currency_Code_CaptionLbl)
                {
                }
                dataitem(HeaderErrorCounter; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    column(ErrorText_Number_; ErrorText[Number])
                    {
                    }
                    column(HeaderErrorCounter_Number; Number)
                    {
                    }
                    column(ErrorText_Number_Caption; ErrorText_Number_CaptionLbl)
                    {
                    }

                    trigger OnPostDataItem()
                    begin
                        ErrorCounter := 0;
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange(Number, 1, ErrorCounter);
                    end;
                }
                dataitem(Doc; "Cartera Doc.")
                {
                    DataItemLink = "Bill Gr./Pmt. Order No." = field("No.");
                    DataItemLinkReference = PmtOrd;
                    DataItemTableView = sorting(Type, "Collection Agent", "Bill Gr./Pmt. Order No.") where("Collection Agent" = const(Bank), Type = const(Payable));
                    column(Doc__Remaining_Amount_; "Remaining Amount")
                    {
                        AutoFormatExpression = "Currency Code";
                        AutoFormatType = 1;
                    }
                    column(Vend_City; Vend.City)
                    {
                    }
                    column(Vend_County; Vend.County)
                    {
                    }
                    column(Vend__Post_Code_; Vend."Post Code")
                    {
                    }
                    column(Vend_Name; Vend.Name)
                    {
                    }
                    column(Doc__Account_No__; "Account No.")
                    {
                    }
                    column(Doc__Document_No__; "Document No.")
                    {
                    }
                    column(Doc__Due_Date_; Format("Due Date"))
                    {
                    }
                    column(Doc__Document_Type_; "Document Type")
                    {
                    }
                    column(DocumentTypeBill; "Document Type" = "Document Type"::Bill)
                    {
                    }
                    column(DocumentTypeInvoice; "Document Type" = "Document Type"::Invoice)
                    {
                    }
                    column(Doc__Due_Date__Control44; Format("Due Date"))
                    {
                    }
                    column(Doc__Document_No___Control46; "Document No.")
                    {
                    }
                    column(Doc__No__; "No.")
                    {
                    }
                    column(Doc__Account_No___Control50; "Account No.")
                    {
                    }
                    column(Vend_Name_Control52; Vend.Name)
                    {
                    }
                    column(Vend__Post_Code__Control53; Vend."Post Code")
                    {
                    }
                    column(Vend_City_Control54; Vend.City)
                    {
                    }
                    column(Vend_County_Control55; Vend.County)
                    {
                    }
                    column(Doc__Remaining_Amount__Control35; "Remaining Amount")
                    {
                        AutoFormatExpression = "Currency Code";
                        AutoFormatType = 1;
                    }
                    column(Doc__Document_Type__Control26; "Document Type")
                    {
                    }
                    column(Doc_Type; Type)
                    {
                    }
                    column(Doc_Entry_No_; "Entry No.")
                    {
                    }
                    column(Doc_Bill_Gr__Pmt__Order_No_; "Bill Gr./Pmt. Order No.")
                    {
                    }
                    column(Vend_Name_Control52Caption; Vend_Name_Control52CaptionLbl)
                    {
                    }
                    column(Post_CodeCaption; Post_CodeCaptionLbl)
                    {
                    }
                    column(City__Caption; City__CaptionLbl)
                    {
                    }
                    column(CountyCaption; CountyCaptionLbl)
                    {
                    }
                    column(Doc__Due_Date__Control44Caption; Doc__Due_Date__Control44CaptionLbl)
                    {
                    }
                    column(Doc__Document_No___Control46Caption; FieldCaption("Document No."))
                    {
                    }
                    column(Doc__No__Caption; Doc__No__CaptionLbl)
                    {
                    }
                    column(Vendor_No_Caption; Vendor_No_CaptionLbl)
                    {
                    }
                    column(Doc__Remaining_Amount__Control35Caption; FieldCaption("Remaining Amount"))
                    {
                    }
                    column(Doc__Document_Type__Control26Caption; FieldCaption("Document Type"))
                    {
                    }
                    dataitem(LineErrorCounter; "Integer")
                    {
                        DataItemTableView = sorting(Number);
                        column(ErrorText_Number__Control56; ErrorText[Number])
                        {
                        }
                        column(LineErrorCounter_Number; Number)
                        {
                        }
                        column(ErrorText_Number__Control56Caption; ErrorText_Number__Control56CaptionLbl)
                        {
                        }

                        trigger OnPostDataItem()
                        begin
                            ErrorCounter := 0;
                        end;

                        trigger OnPreDataItem()
                        begin
                            SetRange(Number, 1, ErrorCounter);
                        end;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        Vend.Get("Account No.");

                        DocCount := DocCount + 1;

                        if "Collection Agent" <> "Collection Agent"::Bank then
                            AddError(StrSubstNo(Text1100007, FieldCaption("Collection Agent"), "Collection Agent"::Bank));

                        if "Currency Code" <> PmtOrd."Currency Code" then
                            AddError(StrSubstNo(Text1100008, FieldCaption("Currency Code"), PmtOrd."Currency Code"));

                        if "Remaining Amt. (LCY)" = 0 then
                            AddError(StrSubstNo(Text1100009, FieldCaption("Remaining Amt. (LCY)")));

                        if Type <> Type::Payable then
                            AddError(StrSubstNo(Text1100008, FieldCaption(Type), Type::Receivable));

                        if Accepted = Accepted::No then
                            AddError(StrSubstNo(Text1100010, FieldCaption(Accepted), false));

                        VendLedgEntry.Get("Entry No.");
                        VendPostingGr.Get(VendLedgEntry."Vendor Posting Group");
                        if "Document Type" = "Document Type"::Bill then begin
                            if VendPostingGr."Bills in Payment Order Acc." = '' then
                                AddError(
                                  StrSubstNo(
                                    Text1100011,
                                    VendPostingGr.FieldCaption("Bills in Payment Order Acc."),
                                    VendPostingGr.TableCaption(),
                                    VendPostingGr.Code));
                            AccountNo := VendPostingGr."Bills in Payment Order Acc.";
                        end else begin
                            if VendPostingGr."Invoices in  Pmt. Ord. Acc." = '' then
                                AddError(
                                  StrSubstNo(
                                    Text1100011,
                                    VendPostingGr.FieldCaption("Invoices in  Pmt. Ord. Acc."),
                                    VendPostingGr.TableCaption(),
                                    VendPostingGr.Code));
                            AccountNo := VendPostingGr."Invoices in  Pmt. Ord. Acc.";
                        end;

                        NoOfDays := "Due Date" - PmtOrd."Posting Date";
                        if NoOfDays < 0 then
                            NoOfDays := 0;

                        if CalcExpenses then
                            FeeRange.CalcPmtOrdCollExpensesAmt(
                              BankAcc2."Operation Fees Code",
                              BankAcc2."Currency Code",
                              "Remaining Amount",
                              "Entry No.");

                        if CheckOtherBanks then begin
                            if DocPostBuffer.Find('+') then;
                            DocPostBuffer."Entry No." := DocPostBuffer."Entry No." + 1;
                            DocPostBuffer."No. of Days" := NoOfDays;
                            DocPostBuffer.Amount := "Remaining Amt. (LCY)";
                            DocPostBuffer.Insert();
                        end;

                        if VendPostingGr."Bills Account" = '' then
                            AddError(
                              StrSubstNo(
                                Text1100011,
                                VendPostingGr.FieldCaption("Bills Account"),
                                VendPostingGr.TableCaption(),
                                VendPostingGr.Code));

                        BalanceAccNo := VendPostingGr."Bills Account";
                        if BGPOPostBuffer.Get(AccountNo, BalanceAccNo) then begin
                            BGPOPostBuffer.Amount := BGPOPostBuffer.Amount + "Remaining Amount";
                            BGPOPostBuffer.Modify();
                        end else begin
                            BGPOPostBuffer.Account := AccountNo;
                            BGPOPostBuffer."Balance Account" := BalanceAccNo;
                            BGPOPostBuffer.Amount := "Remaining Amount";
                            BGPOPostBuffer.Insert();
                        end;
                    end;

                    trigger OnPreDataItem()
                    begin
                        Clear(DocPostBuffer);

                        if CalcExpenses then
                            FeeRange.InitPmtOrdCollExpenses(BankAcc2."Operation Fees Code", BankAcc2."Currency Code");

                        DocCount := 0;
                    end;
                }
                dataitem(Total; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    column(DocCount; DocCount)
                    {
                    }
                    column(PmtOrd_Amount; PmtOrd.Amount)
                    {
                        AutoFormatExpression = PmtOrd."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(Total_Number; Number)
                    {
                    }
                    column(No__of_DocumentsCaption; No__of_DocumentsCaptionLbl)
                    {
                    }
                    column(TotalCaption; TotalCaptionLbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        PmtOrd.CalcFields(Amount);
                    end;
                }
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(Integer_Number; Number)
                {
                }
                column(FeeRange_GetTotalPmtOrdCollExpensesAmt_Control89Caption; FeeRange_GetTotalPmtOrdCollExpensesAmt_Control89CaptionLbl)
                {
                }
                column(Payment_Order_Expenses_Amt_Caption; Payment_Order_Expenses_Amt_CaptionLbl)
                {
                }
                column(BankAcc__No__Caption; BankAcc__No__CaptionLbl)
                {
                }
                dataitem(BillGrBankAcc; "Bank Account")
                {
                    DataItemLink = "No." = field("Bank Account No.");
                    DataItemLinkReference = PmtOrd;
                    DataItemTableView = sorting("No.");
                    column(FeeRange_GetTotalPmtOrdCollExpensesAmt; FeeRange.GetTotalPmtOrdCollExpensesAmt())
                    {
                        AutoFormatExpression = PmtOrd."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(FeeRange_GetTotalPmtOrdCollExpensesAmt_Control92; FeeRange.GetTotalPmtOrdCollExpensesAmt())
                    {
                        AutoFormatExpression = PmtOrd."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(BillGrBankAcc__No__; "No.")
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        CalcFields("Posted Receiv. Bills Rmg. Amt.");
                        RiskIncGr := "Posted Receiv. Bills Rmg. Amt.";

                        if not CalcExpenses then
                            CurrReport.Break();
                    end;
                }
                dataitem(BankAcc; "Bank Account")
                {
                    DataItemLink = "Currency Code" = field("Currency Code");
                    DataItemLinkReference = PmtOrd;
                    DataItemTableView = sorting("No.");
                    RequestFilterFields = "No.";
                    column(FeeRange_GetTotalPmtOrdCollExpensesAmt_Control88; FeeRange.GetTotalPmtOrdCollExpensesAmt())
                    {
                        AutoFormatExpression = PmtOrd."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(FeeRange_GetTotalPmtOrdCollExpensesAmt_Control89; FeeRange.GetTotalPmtOrdCollExpensesAmt())
                    {
                        AutoFormatExpression = PmtOrd."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(BankAcc__No__; "No.")
                    {
                    }
                    column(BankAcc_Currency_Code; "Currency Code")
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if "No." = PmtOrd."Bank Account No." then
                            CurrReport.Skip();

                        CalcFields("Posted Receiv. Bills Rmg. Amt.");
                        RiskIncGr := "Posted Receiv. Bills Rmg. Amt.";

                        if not DocPostBuffer.Find('-') then
                            CurrReport.Skip();

                        Clear(FeeRange);
                        if not FeeRange.Find('=<>') then
                            CurrReport.Skip();
                        FeeRange.InitCollExpenses("Operation Fees Code", "Currency Code");
                        repeat
                            FeeRange.CalcCollExpensesAmt(
                              "Operation Fees Code",
                              "Currency Code",
                              DocPostBuffer.Amount,
                              DocPostBuffer."Entry No.");
                        until DocPostBuffer.Next() = 0;
                    end;
                }
            }

            trigger OnAfterGetRecord()
            begin
                Clear(BankAcc2);
                Clear(PostingGroup);
                Clear(CalcExpenses);

                if BankAcc2.Get(PmtOrd."Bank Account No.") then begin
                    if BankAcc2."Currency Code" <> PmtOrd."Currency Code" then
                        AddError(
                          StrSubstNo(
                            Text1100000,
                            BankAcc2.FieldCaption("Currency Code"),
                            PmtOrd."Currency Code",
                            BankAcc2.TableCaption,
                            BankAcc2."No."));
                    if BankAcc2."Operation Fees Code" = '' then
                        AddError(
                          StrSubstNo(
                            Text1100001,
                            BankAcc2.FieldCaption("Operation Fees Code"),
                            BankAcc2.TableCaption,
                            BankAcc2."No."));
                    if PmtOrd."Posting Date" <> 0D then
                        CalcExpenses := true;
                    FormatAddress.FormatAddr(
                      BankAccAddr, BankAcc2.Name, BankAcc2."Name 2", '', BankAcc2.Address, BankAcc2."Address 2",
                      BankAcc2.City, BankAcc2."Post Code", BankAcc2.County, BankAcc2."Country/Region Code");
                    PostingGroup := BankAcc2."Bank Acc. Posting Group";
                    CompanyIsBlocked := BankAcc2.Blocked;
                    PmtOrd."Bank Account Name" := BankAcc2.Name;
                end;

                if "Bank Account No." = '' then
                    AddError(StrSubstNo(Text1100002, FieldCaption("Bank Account No.")))
                else
                    if PostingGroup = '' then
                        AddError(
                          StrSubstNo(
                            Text1100003,
                            BankAcc2.TableCaption(),
                            "Bank Account No.",
                            BankAcc2.FieldCaption("Bank Acc. Posting Group")));

                if "Posting Date" = 0D then
                    AddError(StrSubstNo(Text1100002, FieldCaption("Posting Date")));

                if "No. Printed" = 0 then
                    AddError(Text1100004);

                if CompanyIsBlocked then
                    AddError(StrSubstNo(Text1100005, BankAcc2.TableCaption(), "Bank Account No."));

                Doc.Reset();
                Doc.SetCurrentKey(Type, "Collection Agent", "Bill Gr./Pmt. Order No.");
                Doc.SetRange(Type, Doc.Type::Payable);
                Doc.SetRange("Collection Agent", Doc."Collection Agent"::Bank);
                Doc.SetRange("Bill Gr./Pmt. Order No.", "No.");
                if not Doc.Find('-') then
                    AddError(Text1100006);
            end;

            trigger OnPreDataItem()
            begin
                if BankAccNoFilter <> '' then begin
                    SetCurrentKey("Bank Account No.");
                    SetRange("Bank Account No.", BankAccNoFilter);
                end;
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        PmtOrdFilter := PmtOrd.GetFilters();
        CheckOtherBanks := BankAcc.GetFilter("No.") <> '';
        BankAccNoFilter := BankAcc.GetFilter("No.");
    end;

    var
        Text1100000: Label '%1 must be %2 in %3 %4.';
        Text1100001: Label '%1 must be specified in %2 %3.';
        Text1100002: Label '%1 must be specified.';
        Text1100003: Label '%1 %2 has no %3.';
        Text1100004: Label 'The payment order has not been printed.';
        Text1100005: Label '%1 %2 is blocked.';
        Text1100006: Label 'The payment order is empty.';
        Text1100007: Label '%1 should be %2.';
        Text1100008: Label '%1 must be %2.';
        Text1100009: Label '%1 must not be zero.';
        Text1100010: Label '%1 cannot be %2.';
        Text1100011: Label 'Specify %1 in %2 %3.';
        BankAcc2: Record "Bank Account";
        Vend: Record Vendor;
        VendLedgEntry: Record "Vendor Ledger Entry";
        VendPostingGr: Record "Vendor Posting Group";
        DocPostBuffer: Record "Doc. Post. Buffer" temporary;
        BGPOPostBuffer: Record "BG/PO Post. Buffer" temporary;
        FeeRange: Record "Fee Range";
        FormatAddress: Codeunit "Format Address";
        PmtOrdFilter: Text[250];
        BankAccAddr: array[8] of Text[100];
        ErrorText: array[99] of Text[250];
        ErrorCounter: Integer;
        PostingGroup: Code[20];
        CompanyIsBlocked: Boolean;
        DocCount: Integer;
        AccountNo: Text[20];
        BalanceAccNo: Text[20];
        RiskIncGr: Decimal;
        CalcExpenses: Boolean;
        CheckOtherBanks: Boolean;
        NoOfDays: Integer;
        BankAccNoFilter: Text[20];
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Payment_Order___TestCaptionLbl: Label 'Payment Order - Test';
        PmtOrd__Bank_Account_Name_CaptionLbl: Label 'Bank Account Name';
        PmtOrd__Posting_Date_CaptionLbl: Label 'Posting Date';
        PmtOrd__Posting_Description_CaptionLbl: Label 'Posting Description';
        PostingGroupCaptionLbl: Label 'Posting Group';
        PmtOrd__Currency_Code_CaptionLbl: Label 'Currency Code';
        ErrorText_Number_CaptionLbl: Label 'Warning!';
        Vend_Name_Control52CaptionLbl: Label 'Name';
        Post_CodeCaptionLbl: Label 'Post Code';
        City__CaptionLbl: Label 'City /';
        CountyCaptionLbl: Label 'County';
        Doc__Due_Date__Control44CaptionLbl: Label 'Due Date';
        Doc__No__CaptionLbl: Label 'Bill No.';
        Vendor_No_CaptionLbl: Label 'Vendor No.';
        ErrorText_Number__Control56CaptionLbl: Label 'Warning!';
        No__of_DocumentsCaptionLbl: Label 'No. of Documents';
        TotalCaptionLbl: Label 'Total';
        FeeRange_GetTotalPmtOrdCollExpensesAmt_Control89CaptionLbl: Label 'Total Expenses';
        Payment_Order_Expenses_Amt_CaptionLbl: Label 'Payment Order Expenses Amt.';
        BankAcc__No__CaptionLbl: Label 'Bank Account No.';

    local procedure AddError(Text: Text[250])
    begin
        ErrorCounter := ErrorCounter + 1;
        ErrorText[ErrorCounter] := Text;
    end;
}

