// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Receivables;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Foundation.Address;
using Microsoft.Sales.Customer;
using System.Utilities;

report 7000008 "Bill Group - Test"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Sales/Receivables/BillGroupTest.rdlc';
    Caption = 'Bill Group - Test';

    dataset
    {
        dataitem(BillGr; "Bill Group")
        {
            RequestFilterFields = "No.";
            column(BillGr_No_; "No.")
            {
            }
            column(BillGr_Bank_Account_No_; "Bank Account No.")
            {
            }
            column(BillGr_Currency_Code; "Currency Code")
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
                column(BillGr_TABLECAPTION__________BillGrFilter; BillGr.TableCaption + ':' + BillGrFilter)
                {
                }
                column(BillGr_TABLECAPTION_________BillGr__No__; BillGr.TableCaption + ' ' + BillGr."No.")
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
                column(BillGr__Bank_Account_Name_; BillGr."Bank Account Name")
                {
                }
                column(OperationText; OperationText)
                {
                }
                column(BillGr__Posting_Date_; Format(BillGr."Posting Date"))
                {
                }
                column(BillGr__Posting_Description_; BillGr."Posting Description")
                {
                }
                column(PostingGroup; PostingGroup)
                {
                }
                column(BillGr__Currency_Code_; BillGr."Currency Code")
                {
                }
                column(FactoringType; FactoringType)
                {
                }
                column(PageCounter_Number; Number)
                {
                }
                column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
                {
                }
                column(Bill_Group___TestCaption; Bill_Group___TestCaptionLbl)
                {
                }
                column(BillGr__Bank_Account_Name_Caption; BillGr__Bank_Account_Name_CaptionLbl)
                {
                }
                column(OperationTextCaption; OperationTextCaptionLbl)
                {
                }
                column(BillGr__Posting_Date_Caption; BillGr__Posting_Date_CaptionLbl)
                {
                }
                column(BillGr__Posting_Description_Caption; BillGr__Posting_Description_CaptionLbl)
                {
                }
                column(PostingGroupCaption; PostingGroupCaptionLbl)
                {
                }
                column(BillGr__Currency_Code_Caption; BillGr__Currency_Code_CaptionLbl)
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
                    DataItemLinkReference = BillGr;
                    DataItemTableView = sorting(Type, "Collection Agent", "Bill Gr./Pmt. Order No.") where("Collection Agent" = const(Bank), Type = const(Receivable));
                    column(Doc__Entry_No__; "Entry No.")
                    {
                    }
                    column(Doc__Due_Date_; Format("Due Date"))
                    {
                    }
                    column(Doc__Document_No__; "Document No.")
                    {
                    }
                    column(Doc__No__; "No.")
                    {
                    }
                    column(Doc__Account_No__; "Account No.")
                    {
                    }
                    column(Cust_Name; Cust.Name)
                    {
                    }
                    column(Cust__Post_Code_; Cust."Post Code")
                    {
                    }
                    column(Cust_City; Cust.City)
                    {
                    }
                    column(Cust_County; Cust.County)
                    {
                    }
                    column(Doc__Remaining_Amount_; "Remaining Amount")
                    {
                        AutoFormatExpression = "Currency Code";
                        AutoFormatType = 1;
                    }
                    column(Doc__Document_Type_; "Document Type")
                    {
                    }
                    column(Doc__Document_Type____Doc__Document_Type___Bill; "Document Type" = "Document Type"::Bill)
                    {
                    }
                    column(Cust_County_Control97; Cust.County)
                    {
                    }
                    column(Cust_Name_Control98; Cust.Name)
                    {
                    }
                    column(Cust__Post_Code__Control99; Cust."Post Code")
                    {
                    }
                    column(Cust_City_Control100; Cust.City)
                    {
                    }
                    column(Doc__Remaining_Amount__Control101; "Remaining Amount")
                    {
                        AutoFormatExpression = "Currency Code";
                        AutoFormatType = 1;
                    }
                    column(Doc__Account_No___Control102; "Account No.")
                    {
                    }
                    column(Doc__Document_No___Control104; "Document No.")
                    {
                    }
                    column(Doc__Due_Date__Control105; Format("Due Date"))
                    {
                    }
                    column(Doc__Document_Type__Control128; "Document Type")
                    {
                    }
                    column(Doc__Document_Type____Doc__Document_Type___Invoice; "Document Type" = "Document Type"::Invoice)
                    {
                    }
                    column(Doc_Type; Type)
                    {
                    }
                    column(Doc_Bill_Gr__Pmt__Order_No_; "Bill Gr./Pmt. Order No.")
                    {
                    }
                    column(Cust_NameCaption; Cust_NameCaptionLbl)
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
                    column(Doc__Due_Date_Caption; Doc__Due_Date_CaptionLbl)
                    {
                    }
                    column(Doc__Document_No__Caption; FieldCaption("Document No."))
                    {
                    }
                    column(Doc__No__Caption; Doc__No__CaptionLbl)
                    {
                    }
                    column(Doc__Account_No__Caption; Doc__Account_No__CaptionLbl)
                    {
                    }
                    column(Doc__Remaining_Amount_Caption; FieldCaption("Remaining Amount"))
                    {
                    }
                    column(Doc__Document_Type__Control128Caption; FieldCaption("Document Type"))
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
                        Cust.Get("Account No.");

                        DocCount := DocCount + 1;

                        if "Collection Agent" <> "Collection Agent"::Bank then
                            AddError(StrSubstNo(Text1100010, FieldCaption("Collection Agent"), "Collection Agent"::Bank));

                        if "Currency Code" <> BillGr."Currency Code" then
                            AddError(StrSubstNo(Text1100010, FieldCaption("Currency Code"), BillGr."Currency Code"));

                        if "Remaining Amt. (LCY)" = 0 then
                            AddError(StrSubstNo(Text1100011, FieldCaption("Remaining Amt. (LCY)")));

                        if Type <> Type::Receivable then
                            AddError(StrSubstNo(Text1100010, FieldCaption(Type), Type::Receivable));

                        if Accepted = Accepted::No then
                            AddError(StrSubstNo(Text1100012, FieldCaption(Accepted), false));

                        if (BillGr.Factoring <> BillGr.Factoring::" ") and ("Document Type" = "Document Type"::Bill) then
                            AddError(StrSubstNo(Text1100012, FieldCaption("Document Type"), "Document Type"::Bill));

                        if (BillGr.Factoring = BillGr.Factoring::" ") and ("Document Type" <> "Document Type"::Bill) then
                            AddError(StrSubstNo(Text1100010, FieldCaption("Document Type"), "Document Type"::Bill));

                        CustLedgEntry.Get("Entry No.");
                        CustPostingGr.Get(CustLedgEntry."Customer Posting Group");
                        if BillGr."Dealing Type" = BillGr."Dealing Type"::Discount then begin
                            if CustPostingGr."Discted. Bills Acc." = '' then
                                AddError(
                                  StrSubstNo(
                                    Text1100013,
                                    CustPostingGr.FieldCaption("Discted. Bills Acc."),
                                    CustPostingGr.TableCaption(),
                                    CustPostingGr.Code));
                            AccountNo := CustPostingGr."Discted. Bills Acc.";
                        end else begin
                            if CustPostingGr."Bills on Collection Acc." = '' then
                                AddError(
                                  StrSubstNo(
                                    Text1100013,
                                    CustPostingGr.FieldCaption("Bills on Collection Acc."),
                                    CustPostingGr.TableCaption(),
                                    CustPostingGr.Code));
                            AccountNo := CustPostingGr."Bills on Collection Acc.";
                        end;

                        NoOfDays := "Due Date" - BillGr."Posting Date";
                        if NoOfDays < 0 then begin
                            NoOfDays := 0;
                            if BillGr."Dealing Type" = BillGr."Dealing Type"::Discount then
                                AddError(
                                  Text1100014);
                        end;

                        if CalcExpenses then begin
                            if (BillGr."Dealing Type" = BillGr."Dealing Type"::Discount) and (BillGr.Factoring = BillGr.Factoring::" ") then begin
                                FeeRange.CalcDiscExpensesAmt(
                                  BankAcc2."Operation Fees Code",
                                  BankAcc2."Currency Code",
                                  "Remaining Amount",
                                  "Entry No.");
                                FeeRange.CalcDiscInterestsAmt(
                                  BankAcc2."Operation Fees Code",
                                  BankAcc2."Currency Code",
                                  NoOfDays,
                                  "Remaining Amount",
                                  "Entry No.");
                            end else
                                if BillGr.Factoring = BillGr.Factoring::" " then
                                    FeeRange.CalcCollExpensesAmt(
                                      BankAcc2."Operation Fees Code",
                                      BankAcc2."Currency Code",
                                      "Remaining Amount",
                                      "Entry No.");
                            if BillGr.Factoring <> BillGr.Factoring::" " then begin
                                if BillGr.Factoring = BillGr.Factoring::Risked then
                                    FeeRange.CalcRiskFactExpensesAmt(
                                      BankAcc2."Operation Fees Code",
                                      BankAcc2."Currency Code",
                                      "Remaining Amount",
                                      "Entry No.")
                                else
                                    FeeRange.CalcUnriskFactExpensesAmt(
                                      BankAcc2."Operation Fees Code",
                                      BankAcc2."Currency Code",
                                      "Remaining Amount",
                                      "Entry No.");

                                if (CustRating.Get(BankAcc2."Customer Ratings Code", BankAcc2."Currency Code", "Account No.") and
                                    (CustRating."Risk Percentage" <> 0))
                                then begin
                                    if BillGr."Dealing Type" = BillGr."Dealing Type"::Discount then
                                        FeeRange.CalcDiscInterestsAmt(
                                          BankAcc2."Operation Fees Code",
                                          BankAcc2."Currency Code",
                                          NoOfDays,
                                          DocPost.FindDisctdAmt("Remaining Amount", "Account No.", BillGr."Bank Account No."),
                                          "Entry No.");
                                end else
                                    if BillGr."Dealing Type" = BillGr."Dealing Type"::Discount then
                                        AddError(
                                          StrSubstNo(
                                            Text1100015,
                                            CustRating.TableCaption(),
                                            BankAcc2.TableCaption(),
                                            BankAcc2."No.",
                                            BankAcc2.FieldCaption("Currency Code"),
                                            BankAcc2."Currency Code",
                                            Cust.TableCaption(),
                                            Cust.FieldCaption("No."),
                                            "Account No."));
                            end;
                        end;

                        if CheckOtherBanks then begin
                            if DocPostBuffer.Find('+') then;
                            DocPostBuffer."Entry No." := DocPostBuffer."Entry No." + 1;
                            DocPostBuffer."No. of Days" := NoOfDays;
                            DocPostBuffer.Amount := "Remaining Amt. (LCY)";
                            DocPostBuffer.Insert();
                        end;

                        if CustPostingGr."Bills Account" = '' then
                            AddError(
                              StrSubstNo(
                                Text1100013,
                                CustPostingGr.FieldCaption("Bills Account"),
                                CustPostingGr.TableCaption(),
                                CustPostingGr.Code));

                        BalanceAccNo := CustPostingGr."Bills Account";
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

                    trigger OnPostDataItem()
                    begin
                        if (BillGr."Dealing Type" = BillGr."Dealing Type"::Discount) and BankAcc2.Find() then begin
                            if BankAcc2."Bank Acc. Posting Group" = '' then
                                AddError(
                                  StrSubstNo(
                                    Text1100016,
                                    BankAcc2.FieldCaption("Bank Acc. Posting Group"),
                                    BillGr.TableCaption(),
                                    BillGr."Bank Account No."));
                            if BankAccPostingGr.Get(BankAcc2."Bank Acc. Posting Group") then
                                if BankAccPostingGr."Liabs. for Disc. Bills Acc." = '' then
                                    AddError(
                                      StrSubstNo(
                                        Text1100013,
                                        BankAccPostingGr.FieldCaption("Liabs. for Disc. Bills Acc."),
                                        BankAccPostingGr.TableCaption(),
                                        BankAccPostingGr.Code));
                        end;
                    end;

                    trigger OnPreDataItem()
                    begin
                        Clear(DocPostBuffer);

                        if CalcExpenses then begin
                            if (BillGr."Dealing Type" = BillGr."Dealing Type"::Discount) and
                               (BillGr.Factoring = BillGr.Factoring::" ")
                            then begin
                                FeeRange.InitDiscExpenses(BankAcc2."Operation Fees Code", BankAcc2."Currency Code");
                                FeeRange.InitDiscInterests(BankAcc2."Operation Fees Code", BankAcc2."Currency Code");
                            end else
                                if BillGr.Factoring = BillGr.Factoring::" " then
                                    FeeRange.InitCollExpenses(BankAcc2."Operation Fees Code", BankAcc2."Currency Code");
                            if BillGr.Factoring <> BillGr.Factoring::" " then begin
                                if BillGr.Factoring = BillGr.Factoring::Risked then
                                    FeeRange.InitRiskFactExpenses(BankAcc2."Operation Fees Code", BankAcc2."Currency Code")
                                else
                                    FeeRange.InitUnriskFactExpenses(BankAcc2."Operation Fees Code", BankAcc2."Currency Code");
                                if BillGr."Dealing Type" = BillGr."Dealing Type"::Discount then begin
                                    FeeRange.InitDiscExpenses(BankAcc2."Operation Fees Code", BankAcc2."Currency Code");
                                    FeeRange.InitDiscInterests(BankAcc2."Operation Fees Code", BankAcc2."Currency Code");
                                end else
                                    FeeRange.InitCollExpenses(BankAcc2."Operation Fees Code", BankAcc2."Currency Code");
                            end;
                        end;

                        DocCount := 0;
                    end;
                }
                dataitem(Total; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    column(DocCount; DocCount)
                    {
                    }
                    column(BillGr_Amount; BillGr.Amount)
                    {
                        AutoFormatExpression = BillGr."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(SetLabel; SetLabel())
                    {
                    }
                    column(Total_Number; Number)
                    {
                    }
                    column(TotalCaption; TotalCaptionLbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        BillGr.CalcFields(Amount);
                    end;
                }
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(BillGrFactoringInt; BillGrFactoringInt)
                {
                }
                column(BillGrDealingTypeInt; BillGrDealingTypeInt)
                {
                }
                column(SetLabel2; SetLabel2())
                {
                }
                column(Integer_Number; Number)
                {
                }
                column(FORMAT_CreditLimitExceeded__Control76Caption; FORMAT_CreditLimitExceeded__Control76CaptionLbl)
                {
                }
                column(BankAcc__Credit_Limit_for_Discount_Caption; BankAcc.FieldCaption("Credit Limit for Discount"))
                {
                }
                column(RiskIncGr_Control77Caption; RiskIncGr_Control77CaptionLbl)
                {
                }
                column(BankAcc__Posted_Receiv__Bills_Rmg__Amt__Caption; BankAcc.FieldCaption("Posted Receiv. Bills Rmg. Amt."))
                {
                }
                column(FeeRange_GetTotalCollExpensesAmt_FeeRange_GetTotalDiscExpensesAmt_FeeRange_GetTotalDiscInterestsAmt_Control70Caption; FeeRange_GetTotalCollExpensesAmt_FeeRange_GetTotalDiscExpensesAmt_FeeRange_GetTotalDiscInterestsAmt_Control70CaptionLbl)
                {
                }
                column(FeeRange_GetTotalCollExpensesAmt_Control63Caption; FeeRange_GetTotalCollExpensesAmt_Control63CaptionLbl)
                {
                }
                column(FeeRange_GetTotalDiscExpensesAmt_Control61Caption; FeeRange_GetTotalDiscExpensesAmt_Control61CaptionLbl)
                {
                }
                column(FeeRange_GetTotalDiscInterestsAmt_Control60Caption; FeeRange_GetTotalDiscInterestsAmt_Control60CaptionLbl)
                {
                }
                column(BankAcc__No__Caption; BankAcc__No__CaptionLbl)
                {
                }
                column(FeeRange_GetTotalCollExpensesAmt_FeeRange_GetTotalDiscExpensesAmt_FeeRange_GetTotalDiscInterestsAmt_Control89Caption; FeeRange_GetTotalCollExpensesAmt_FeeRange_GetTotalDiscExpensesAmt_FeeRange_GetTotalDiscInterestsAmt_Control89CaptionLbl)
                {
                }
                column(FeeRange_GetTotalCollExpensesAmt_Control88Caption; FeeRange_GetTotalCollExpensesAmt_Control88CaptionLbl)
                {
                }
                column(FeeRange_GetTotalDiscExpensesAmt_Control87Caption; FeeRange_GetTotalDiscExpensesAmt_Control87CaptionLbl)
                {
                }
                column(FeeRange_GetTotalDiscInterestsAmt_Control86Caption; FeeRange_GetTotalDiscInterestsAmt_Control86CaptionLbl)
                {
                }
                column(BankAcc__No___Control90Caption; BankAcc__No___Control90CaptionLbl)
                {
                }
                column(BankAcc__No___Control90Caption_Control59; BankAcc__No___Control90Caption_Control59Lbl)
                {
                }
                column(FeeRange_GetTotalDiscInterestsAmt_Control86Caption_Control106; FeeRange_GetTotalDiscInterestsAmt_Control86Caption_Control106Lbl)
                {
                }
                column(FeeRange_GetTotalCollExpensesAmt_FeeRange_GetTotalDiscExpensesAmt_FeeRange_GetTotalDiscInterestsAmt_114; FeeRange_GetTotalCollExpensesAmt_FeeRange_GetTotalDiscExpensesAmt_FeeRange_GetTotalDiscInterestsAmt_Lbl)
                {
                }
                dataitem(BillGrBankAcc; "Bank Account")
                {
                    DataItemLink = "No." = field("Bank Account No.");
                    DataItemLinkReference = BillGr;
                    DataItemTableView = sorting("No.");
                    column(FORMAT_CreditLimitExceeded_; Format(CreditLimitExceeded))
                    {
                    }
                    column(BillGrBankAcc__Credit_Limit_for_Discount_; "Credit Limit for Discount")
                    {
                        AutoFormatExpression = BillGr."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(RiskIncGr; RiskIncGr)
                    {
                        AutoFormatExpression = BillGr."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(BillGrBankAcc__Posted_Receiv__Bills_Rmg__Amt__; "Posted Receiv. Bills Rmg. Amt.")
                    {
                        AutoFormatExpression = BillGr."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(FeeRange_GetTotalCollExpensesAmt_FeeRange_GetTotalDiscExpensesAmt_FeeRange_GetTotalDiscInterestsAmt; FeeRange.GetTotalCollExpensesAmt() + FeeRange.GetTotalDiscExpensesAmt() + FeeRange.GetTotalDiscInterestsAmt())
                    {
                        AutoFormatExpression = BillGr."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(FeeRange_GetTotalCollExpensesAmt; FeeRange.GetTotalCollExpensesAmt())
                    {
                        AutoFormatExpression = BillGr."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(FeeRange_GetTotalDiscExpensesAmt; FeeRange.GetTotalDiscExpensesAmt())
                    {
                        AutoFormatExpression = BillGr."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(FeeRange_GetTotalDiscInterestsAmt; FeeRange.GetTotalDiscInterestsAmt())
                    {
                        AutoFormatExpression = BillGr."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(BillGrBankAcc__No__; "No.")
                    {
                    }
                    column(FeeRange_GetTotalCollExpensesAmt_FeeRange_GetTotalDiscExpensesAmt_FeeRange_GetTotalDiscInterestsAmt_Control91; FeeRange.GetTotalCollExpensesAmt() + FeeRange.GetTotalDiscExpensesAmt() + FeeRange.GetTotalDiscInterestsAmt())
                    {
                        AutoFormatExpression = BillGr."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(FeeRange_GetTotalCollExpensesAmt_Control92; FeeRange.GetTotalCollExpensesAmt())
                    {
                        AutoFormatExpression = BillGr."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(FeeRange_GetTotalDiscExpensesAmt_Control93; FeeRange.GetTotalDiscExpensesAmt())
                    {
                        AutoFormatExpression = BillGr."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(FeeRange_GetTotalDiscInterestsAmt_Control94; FeeRange.GetTotalDiscInterestsAmt())
                    {
                        AutoFormatExpression = BillGr."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(BillGrBankAcc__No___Control95; "No.")
                    {
                    }
                    column(BillGrBankAcc__No___Control108; "No.")
                    {
                    }
                    column(FeeRange_GetTotalDiscInterestsAmt_Control109; FeeRange.GetTotalDiscInterestsAmt())
                    {
                        AutoFormatExpression = BillGr."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(FeeRange_GetTotalRiskFactExpensesAmt; FeeRange.GetTotalRiskFactExpensesAmt())
                    {
                        AutoFormatExpression = BillGr."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(FeeRange_GetTotalDiscInterestsAmt___FeeRange_GetTotalRiskFactExpensesAmt; FeeRange.GetTotalDiscInterestsAmt() + FeeRange.GetTotalRiskFactExpensesAmt())
                    {
                        AutoFormatExpression = BillGr."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(FeeRange_GetTotalUnriskFactExpensesAmt; FeeRange.GetTotalUnriskFactExpensesAmt())
                    {
                        AutoFormatExpression = BillGr."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(FeeRange_GetTotalDiscInterestsAmt_Control112; FeeRange.GetTotalDiscInterestsAmt())
                    {
                        AutoFormatExpression = BillGr."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(BillGrBankAcc__No___Control113; "No.")
                    {
                    }
                    column(FeeRange_GetTotalDiscInterestsAmt___FeeRange_GetTotalUnriskFactExpensesAmt; FeeRange.GetTotalDiscInterestsAmt() + FeeRange.GetTotalUnriskFactExpensesAmt())
                    {
                        AutoFormatExpression = BillGr."Currency Code";
                        AutoFormatType = 1;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        SetRange("Dealing Type Filter", 1); // Discount
                        CalcFields("Posted Receiv. Bills Rmg. Amt.");
                        if BillGr."Dealing Type" = BillGr."Dealing Type"::Discount then
                            RiskIncGr := "Posted Receiv. Bills Rmg. Amt." + BillGr.Amount
                        else
                            RiskIncGr := "Posted Receiv. Bills Rmg. Amt.";
                        CreditLimitExceeded := RiskIncGr > "Credit Limit for Discount";

                        if not CalcExpenses then
                            CurrReport.Break();
                    end;
                }
                dataitem(BankAcc; "Bank Account")
                {
                    DataItemLink = "Currency Code" = field("Currency Code");
                    DataItemLinkReference = BillGr;
                    DataItemTableView = sorting("No.");
                    RequestFilterFields = "No.";
                    column(FeeRange_GetTotalDiscInterestsAmt_Control60; FeeRange.GetTotalDiscInterestsAmt())
                    {
                        AutoFormatExpression = BillGr."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(FeeRange_GetTotalDiscExpensesAmt_Control61; FeeRange.GetTotalDiscExpensesAmt())
                    {
                        AutoFormatExpression = BillGr."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(FeeRange_GetTotalCollExpensesAmt_Control63; FeeRange.GetTotalCollExpensesAmt())
                    {
                        AutoFormatExpression = BillGr."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(BankAcc__No__; "No.")
                    {
                    }
                    column(FeeRange_GetTotalCollExpensesAmt_FeeRange_GetTotalDiscExpensesAmt_FeeRange_GetTotalDiscInterestsAmt_Control70; FeeRange.GetTotalCollExpensesAmt() + FeeRange.GetTotalDiscExpensesAmt() + FeeRange.GetTotalDiscInterestsAmt())
                    {
                        AutoFormatExpression = BillGr."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(FORMAT_CreditLimitExceeded__Control76; Format(CreditLimitExceeded))
                    {
                    }
                    column(RiskIncGr_Control77; RiskIncGr)
                    {
                        AutoFormatExpression = BillGr."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(BankAcc__Posted_Receiv__Bills_Rmg__Amt__; "Posted Receiv. Bills Rmg. Amt.")
                    {
                        AutoFormatExpression = BillGr."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(BankAcc__Credit_Limit_for_Discount_; "Credit Limit for Discount")
                    {
                        AutoFormatExpression = BillGr."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(FeeRange_GetTotalDiscInterestsAmt_Control86; FeeRange.GetTotalDiscInterestsAmt())
                    {
                        AutoFormatExpression = BillGr."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(FeeRange_GetTotalDiscExpensesAmt_Control87; FeeRange.GetTotalDiscExpensesAmt())
                    {
                        AutoFormatExpression = BillGr."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(FeeRange_GetTotalCollExpensesAmt_Control88; FeeRange.GetTotalCollExpensesAmt())
                    {
                        AutoFormatExpression = BillGr."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(FeeRange_GetTotalCollExpensesAmt_FeeRange_GetTotalDiscExpensesAmt_FeeRange_GetTotalDiscInterestsAmt_Control89; FeeRange.GetTotalCollExpensesAmt() + FeeRange.GetTotalDiscExpensesAmt() + FeeRange.GetTotalDiscInterestsAmt())
                    {
                        AutoFormatExpression = BillGr."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(BankAcc__No___Control90; "No.")
                    {
                    }
                    column(FeeRange_GetTotalDiscInterestsAmt___FeeRange_GetTotalRiskFactExpensesAmt_Control117; FeeRange.GetTotalDiscInterestsAmt() + FeeRange.GetTotalRiskFactExpensesAmt())
                    {
                        AutoFormatExpression = BillGr."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(FeeRange_GetTotalRiskFactExpensesAmt_Control118; FeeRange.GetTotalRiskFactExpensesAmt())
                    {
                        AutoFormatExpression = BillGr."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(FeeRange_GetTotalDiscInterestsAmt_Control119; FeeRange.GetTotalDiscInterestsAmt())
                    {
                        AutoFormatExpression = BillGr."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(BankAcc__No___Control120; "No.")
                    {
                    }
                    column(FeeRange_GetTotalDiscInterestsAmt___FeeRange_GetTotalUnriskFactExpensesAmt_Control121; FeeRange.GetTotalDiscInterestsAmt() + FeeRange.GetTotalUnriskFactExpensesAmt())
                    {
                        AutoFormatExpression = BillGr."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(FeeRange_GetTotalUnriskFactExpensesAmt_Control122; FeeRange.GetTotalUnriskFactExpensesAmt())
                    {
                        AutoFormatExpression = BillGr."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(FeeRange_GetTotalDiscInterestsAmt_Control123; FeeRange.GetTotalDiscInterestsAmt())
                    {
                        AutoFormatExpression = BillGr."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(BankAcc__No___Control124; "No.")
                    {
                    }
                    column(BankAcc_Currency_Code; "Currency Code")
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if "No." = BillGr."Bank Account No." then
                            CurrReport.Skip();

                        SetRange("Dealing Type Filter", 1); // Discount
                        CalcFields("Posted Receiv. Bills Rmg. Amt.");
                        if BillGr."Dealing Type" = BillGr."Dealing Type"::Discount then
                            RiskIncGr := "Posted Receiv. Bills Rmg. Amt." + BillGr.Amount
                        else
                            RiskIncGr := "Posted Receiv. Bills Rmg. Amt.";
                        CreditLimitExceeded := RiskIncGr > "Credit Limit for Discount";

                        if not DocPostBuffer.Find('-') then
                            CurrReport.Skip();

                        Clear(FeeRange);
                        if not FeeRange.Find('=<>') then
                            CurrReport.Skip();
                        if BillGr."Dealing Type" = BillGr."Dealing Type"::Discount then begin
                            FeeRange.InitDiscExpenses("Operation Fees Code", "Currency Code");
                            FeeRange.InitDiscInterests("Operation Fees Code", "Currency Code");
                            repeat
                                FeeRange.CalcDiscExpensesAmt(
                                  "Operation Fees Code",
                                  "Currency Code",
                                  DocPostBuffer.Amount,
                                  DocPostBuffer."Entry No.");
                                FeeRange.CalcDiscInterestsAmt(
                                  "Operation Fees Code",
                                  "Currency Code",
                                  NoOfDays,
                                  DocPostBuffer.Amount,
                                  DocPostBuffer."Entry No.");
                            until DocPostBuffer.Next() = 0;
                        end else begin
                            FeeRange.InitCollExpenses("Operation Fees Code", "Currency Code");
                            repeat
                                FeeRange.CalcCollExpensesAmt(
                                  "Operation Fees Code",
                                  "Currency Code",
                                  DocPostBuffer.Amount,
                                  DocPostBuffer."Entry No.");
                            until DocPostBuffer.Next() = 0;
                        end;
                    end;
                }
            }

            trigger OnAfterGetRecord()
            begin
                if "Dealing Type" = "Dealing Type"::Discount then
                    OperationText := Text1100000
                else
                    OperationText := Text1100001;
                FactoringType := GetFactoringType();

                Clear(BankAcc2);
                Clear(PostingGroup);
                Clear(CalcExpenses);

                if BankAcc2.Get(BillGr."Bank Account No.") then begin
                    if BankAcc2."Currency Code" <> BillGr."Currency Code" then
                        AddError(
                          StrSubstNo(
                            Text1100002,
                            BankAcc2.FieldCaption("Currency Code"),
                            BillGr."Currency Code",
                            BankAcc2.TableCaption,
                            BankAcc2."No."));
                    if BankAcc2."Operation Fees Code" = '' then
                        AddError(
                          StrSubstNo(
                            Text1100003,
                            BankAcc2.FieldCaption("Operation Fees Code"),
                            BankAcc2.TableCaption,
                            BankAcc2."No."));
                    if BankAcc2."Customer Ratings Code" = '' then
                        AddError(
                          StrSubstNo(
                            Text1100003,
                            BankAcc2.FieldCaption("Customer Ratings Code"),
                            BankAcc2.TableCaption,
                            BankAcc2."No."));
                    if BillGr."Posting Date" <> 0D then
                        CalcExpenses := true;
                    FormatAddress.FormatAddr(
                      BankAccAddr, BankAcc2.Name, BankAcc2."Name 2", '', BankAcc2.Address, BankAcc2."Address 2",
                      BankAcc2.City, BankAcc2."Post Code", BankAcc2.County, BankAcc2."Country/Region Code");
                    PostingGroup := BankAcc2."Bank Acc. Posting Group";
                    CompanyIsBlocked := BankAcc2.Blocked;
                    BillGr."Bank Account Name" := BankAcc2.Name;
                    if (BillGr."Dealing Type" = BillGr."Dealing Type"::Discount) and (BillGr.Factoring = BillGr.Factoring::" ") then begin
                        BankAcc2.SetRange("Dealing Type Filter", 1);
                        // Discount
                        BankAcc2.CalcFields("Posted Receiv. Bills Rmg. Amt.");
                        BillGr.CalcFields(Amount);
                        if BankAcc2."Posted Receiv. Bills Rmg. Amt." + BillGr.Amount > BankAcc2."Credit Limit for Discount" then
                            AddError(Text1100004);
                    end;
                end;

                if "Bank Account No." = '' then
                    AddError(StrSubstNo(Text1100005, FieldCaption("Bank Account No.")))
                else
                    if PostingGroup = '' then
                        AddError(
                          StrSubstNo(
                            Text1100006,
                            BankAcc2.TableCaption(),
                            "Bank Account No.",
                            BankAcc2.FieldCaption("Bank Acc. Posting Group")));

                if "Posting Date" = 0D then
                    AddError(StrSubstNo(Text1100005, FieldCaption("Posting Date")));

                if "No. Printed" = 0 then
                    AddError(Text1100007);

                if CompanyIsBlocked then
                    AddError(StrSubstNo(Text1100008, BankAcc2.TableCaption(), "Bank Account No."));

                Doc.Reset();
                Doc.SetCurrentKey(Type, "Collection Agent", "Bill Gr./Pmt. Order No.");
                Doc.SetRange(Type, Doc.Type::Receivable);
                Doc.SetRange("Collection Agent", Doc."Collection Agent"::Bank);
                Doc.SetRange("Bill Gr./Pmt. Order No.", "No.");
                if not Doc.Find('-') then
                    AddError(Text1100009);

                BillGrDealingTypeInt := "Dealing Type".AsInteger();
                BillGrFactoringInt := Factoring
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
        BillGrFilter := BillGr.GetFilters();
        CheckOtherBanks := BankAcc.GetFilter("No.") <> '';
        BankAccNoFilter := BankAcc.GetFilter("No.");
    end;

    var
        Text1100000: Label 'For Discount';
        Text1100001: Label 'For Collection';
        Text1100002: Label '%1 must be %2 in %3 %4.';
        Text1100003: Label '%1 must be specified in %2 %3.';
        Text1100004: Label 'The credit limit will be exceeded.';
        Text1100005: Label '%1 must be specified.';
        Text1100006: Label '%1 %2 has no %3.';
        Text1100007: Label 'The bill group has not been printed.';
        Text1100008: Label '%1 %2 is blocked.';
        Text1100009: Label 'The bill group is empty.';
        Text1100010: Label '%1 must be %2.';
        Text1100011: Label '%1 must not be zero.';
        Text1100012: Label '%1 cannot be %2.';
        Text1100013: Label 'Specify %1 in %2 %3.';
        Text1100014: Label 'This Bill is due before the posting date of the bill group. It should not be included in a group for discount.';
        Text1100015: Label 'The %1 for %2 %3 %4 %5 %6 %7 %8 doesn''t exist.';
        Text1100016: Label 'Specify %1 for %2 %3.';
        Text1100017: Label 'Risked Factoring';
        Text1100018: Label 'Unrisked Factoring';
        Text1100019: Label 'No. of invoices';
        Text1100020: Label 'No. of bills';
        Text1100021: Label 'Risked Factoring Expenses';
        Text1100022: Label 'Unrisked Factoring Expenses';
        BankAcc2: Record "Bank Account";
        Cust: Record Customer;
        CustLedgEntry: Record "Cust. Ledger Entry";
        CustPostingGr: Record "Customer Posting Group";
        DocPostBuffer: Record "Doc. Post. Buffer" temporary;
        BGPOPostBuffer: Record "BG/PO Post. Buffer" temporary;
        BankAccPostingGr: Record "Bank Account Posting Group";
        FeeRange: Record "Fee Range";
        CustRating: Record "Customer Rating";
        DocPost: Codeunit "Document-Post";
        FormatAddress: Codeunit "Format Address";
        BillGrFilter: Text[250];
        BankAccAddr: array[8] of Text[100];
        OperationText: Text[80];
        ErrorText: array[99] of Text[250];
        ErrorCounter: Integer;
        PostingGroup: Code[20];
        CompanyIsBlocked: Boolean;
        DocCount: Integer;
        AccountNo: Text[20];
        BalanceAccNo: Text[20];
        CreditLimitExceeded: Boolean;
        RiskIncGr: Decimal;
        CalcExpenses: Boolean;
        CheckOtherBanks: Boolean;
        NoOfDays: Integer;
        FactoringType: Text[30];
        BankAccNoFilter: Text[20];
        BillGrFactoringInt: Integer;
        BillGrDealingTypeInt: Integer;
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Bill_Group___TestCaptionLbl: Label 'Bill Group - Test';
        BillGr__Bank_Account_Name_CaptionLbl: Label 'Bank Account Name';
        OperationTextCaptionLbl: Label 'Operation';
        BillGr__Posting_Date_CaptionLbl: Label 'Posting Date';
        BillGr__Posting_Description_CaptionLbl: Label 'Posting Description';
        PostingGroupCaptionLbl: Label 'Posting Group';
        BillGr__Currency_Code_CaptionLbl: Label 'Currency Code';
        ErrorText_Number_CaptionLbl: Label 'Warning!';
        Cust_NameCaptionLbl: Label 'Name';
        Post_CodeCaptionLbl: Label 'Post Code';
        City__CaptionLbl: Label 'City /';
        CountyCaptionLbl: Label 'County';
        Doc__Due_Date_CaptionLbl: Label 'Due Date';
        Doc__No__CaptionLbl: Label 'Bill No.';
        Doc__Account_No__CaptionLbl: Label 'Customer No.';
        ErrorText_Number__Control56CaptionLbl: Label 'Warning!';
        TotalCaptionLbl: Label 'Total';
        FORMAT_CreditLimitExceeded__Control76CaptionLbl: Label 'Exceeded';
        RiskIncGr_Control77CaptionLbl: Label 'Risk Including this Bill Group';
        FeeRange_GetTotalCollExpensesAmt_FeeRange_GetTotalDiscExpensesAmt_FeeRange_GetTotalDiscInterestsAmt_Control70CaptionLbl: Label 'Total Expenses';
        FeeRange_GetTotalCollExpensesAmt_Control63CaptionLbl: Label 'Collection Expenses';
        FeeRange_GetTotalDiscExpensesAmt_Control61CaptionLbl: Label 'Discount Expenses';
        FeeRange_GetTotalDiscInterestsAmt_Control60CaptionLbl: Label 'Discount Interests';
        BankAcc__No__CaptionLbl: Label 'Bank Account No.';
        FeeRange_GetTotalCollExpensesAmt_FeeRange_GetTotalDiscExpensesAmt_FeeRange_GetTotalDiscInterestsAmt_Control89CaptionLbl: Label 'Total Expenses';
        FeeRange_GetTotalCollExpensesAmt_Control88CaptionLbl: Label 'Collection Expenses';
        FeeRange_GetTotalDiscExpensesAmt_Control87CaptionLbl: Label 'Discount Expenses';
        FeeRange_GetTotalDiscInterestsAmt_Control86CaptionLbl: Label 'Discount Interests';
        BankAcc__No___Control90CaptionLbl: Label 'Bank Account No.';
        BankAcc__No___Control90Caption_Control59Lbl: Label 'Bank Account No.';
        FeeRange_GetTotalDiscInterestsAmt_Control86Caption_Control106Lbl: Label 'Discount Interests';
        FeeRange_GetTotalCollExpensesAmt_FeeRange_GetTotalDiscExpensesAmt_FeeRange_GetTotalDiscInterestsAmt_Lbl: Label 'Total Expenses';

    local procedure AddError(Text: Text[250])
    begin
        ErrorCounter := ErrorCounter + 1;
        ErrorText[ErrorCounter] := Text;
    end;

    [Scope('OnPrem')]
    procedure GetFactoringType(): Text[30]
    begin
        if BillGr.Factoring <> BillGr.Factoring::" " then begin
            if BillGr.Factoring = BillGr.Factoring::Risked then
                exit(Text1100017);

            exit(Text1100018);
        end;
    end;

    [Scope('OnPrem')]
    procedure SetLabel(): Text[30]
    begin
        if BillGr.Factoring <> BillGr.Factoring::" " then
            exit(Text1100019);

        exit(Text1100020);
    end;

    [Scope('OnPrem')]
    procedure SetLabel2(): Text[30]
    begin
        if BillGr.Factoring <> BillGr.Factoring::" " then begin
            if BillGr.Factoring = BillGr.Factoring::Risked then
                exit(Text1100021);

            exit(Text1100022);
        end;
    end;
}

