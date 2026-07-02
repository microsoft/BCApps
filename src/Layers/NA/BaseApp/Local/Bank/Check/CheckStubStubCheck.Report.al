// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Check;

using Microsoft.Bank.BankAccount;
using Microsoft.CRM.Team;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.HumanResources.Employee;
using Microsoft.HumanResources.Payables;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Remittance;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using System.Automation;
using System.Utilities;

report 10401 "Check (Stub/Stub/Check)"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Bank/Check/CheckStubStubCheck.rdlc';
    Caption = 'Check (Stub/Stub/Check)';
    Permissions = TableData "Bank Account" = m;

    dataset
    {
        dataitem(VoidGenJnlLine; "Gen. Journal Line")
        {
            DataItemTableView = sorting("Journal Template Name", "Journal Batch Name", "Posting Date", "Document No.");
            RequestFilterFields = "Journal Template Name", "Journal Batch Name", "Posting Date";

            trigger OnAfterGetRecord()
            begin
                CheckManagement.VoidCheck(VoidGenJnlLine);
            end;

            trigger OnPreDataItem()
            begin
                if CurrReport.Preview then
                    Error(Text000);

                if UseCheckNo = '' then
                    Error(Text001);

                if IncStr(UseCheckNo) = '' then
                    Error(USText004);

                if TestPrint then
                    CurrReport.Break();

                if not ReprintChecks then
                    CurrReport.Break();

                if (GetFilter("Line No.") <> '') or (GetFilter("Document No.") <> '') then
                    Error(
                      Text002, FieldCaption("Line No."), FieldCaption("Document No."));
                SetRange("Bank Payment Type", "Bank Payment Type"::"Computer Check");
                SetRange("Check Printed", true);
            end;
        }
        dataitem(TestGenJnlLine; "Gen. Journal Line")
        {
            DataItemTableView = sorting("Journal Template Name", "Journal Batch Name", "Line No.");

            trigger OnAfterGetRecord()
            begin
                if Amount = 0 then
                    CurrReport.Skip();

                TestField("Bal. Account Type", "Bal. Account Type"::"Bank Account");
                if "Bal. Account No." <> BankAcc2."No." then
                    CurrReport.Skip();
                case "Account Type" of
                    "Account Type"::"G/L Account":
                        begin
                            if BankAcc2."Check Date Format" = BankAcc2."Check Date Format"::" " then
                                Error(USText006, BankAcc2.FieldCaption("Check Date Format"), BankAcc2.TableCaption(), BankAcc2."No.");
                            if BankAcc2."Bank Communication" = BankAcc2."Bank Communication"::"S Spanish" then
                                Error(USText007, BankAcc2.FieldCaption("Bank Communication"), BankAcc2.TableCaption(), BankAcc2."No.");
                        end;
                    "Account Type"::Customer:
                        begin
                            Cust.Get("Account No.");
                            if Cust."Check Date Format" = Cust."Check Date Format"::" " then
                                Error(USText006, Cust.FieldCaption("Check Date Format"), Cust.TableCaption(), "Account No.");
                            if Cust."Bank Communication" = Cust."Bank Communication"::"S Spanish" then
                                Error(USText007, Cust.FieldCaption("Bank Communication"), Cust.TableCaption(), "Account No.");
                        end;
                    "Account Type"::Vendor:
                        begin
                            Vend.Get("Account No.");
                            if Vend."Check Date Format" = Vend."Check Date Format"::" " then
                                Error(USText006, Vend.FieldCaption("Check Date Format"), Vend.TableCaption(), "Account No.");
                            if Vend."Bank Communication" = Vend."Bank Communication"::"S Spanish" then
                                Error(USText007, Vend.FieldCaption("Bank Communication"), Vend.TableCaption(), "Account No.");
                        end;
                    "Account Type"::"Bank Account":
                        begin
                            BankAcc.Get("Account No.");
                            if BankAcc."Check Date Format" = BankAcc."Check Date Format"::" " then
                                Error(USText006, BankAcc.FieldCaption("Check Date Format"), BankAcc.TableCaption(), "Account No.");
                            if BankAcc."Bank Communication" = BankAcc."Bank Communication"::"S Spanish" then
                                Error(USText007, BankAcc.FieldCaption("Bank Communication"), BankAcc.TableCaption(), "Account No.");
                        end;
                end;
            end;

            trigger OnPreDataItem()
            begin
                if TestPrint then begin
                    BankAcc2.Get(BankAcc2."No.");
                    BankCurrencyCode := BankAcc2."Currency Code";
                end;

                if TestPrint then
                    CurrReport.Break();
                BankAcc2.Get(BankAcc2."No.");
                BankCurrencyCode := BankAcc2."Currency Code";

                if BankAcc2."Country/Region Code" <> 'CA' then
                    CurrReport.Break();
                BankAcc2.TestField(Blocked, false);
                Copy(VoidGenJnlLine);
                BankAcc2.Get(BankAcc2."No.");
                BankAcc2.TestField(Blocked, false);
                SetRange("Bank Payment Type", "Bank Payment Type"::"Computer Check");
                SetRange("Check Printed", false);
            end;
        }
        dataitem(GenJnlLine; "Gen. Journal Line")
        {
            DataItemTableView = sorting("Journal Template Name", "Journal Batch Name", "Posting Date", "Document No.");
            column(GenJnlLine_Journal_Template_Name; "Journal Template Name")
            {
            }
            column(GenJnlLine_Journal_Batch_Name; "Journal Batch Name")
            {
            }
            column(GenJnlLine_Line_No_; "Line No.")
            {
            }
            dataitem(CheckPages; "Integer")
            {
                DataItemTableView = sorting(Number);
                column(CheckToAddr_1_; CheckToAddr[1])
                {
                }
                column(CheckDateText; CheckDateText)
                {
                }
                column(CheckNoText; CheckNoText)
                {
                }
                column(PageNo; PageNo)
                {
                }
                column(CheckPages_Number; Number)
                {
                }
                column(CheckNoTextCaption; CheckNoTextCaptionLbl)
                {
                }
                dataitem(PrintSettledLoop; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    MaxIteration = 10;
                    column(PreprintedStub; PreprintedStub)
                    {
                    }
                    column(LineAmount; LineAmount)
                    {
                        AutoFormatExpression = GenJnlLine."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(LineDiscount; LineDiscount)
                    {
                        AutoFormatExpression = GenJnlLine."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(LineAmount___LineDiscount; LineAmount + LineDiscount)
                    {
                        AutoFormatExpression = GenJnlLine."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(DocNo; DocNo)
                    {
                    }
                    column(DocDate; DocDate)
                    {
                    }
                    column(PostingDesc; PostingDesc)
                    {
                    }
                    column(PrintSettledLoop_Number; Number)
                    {
                    }
                    column(LineAmountCaption; LineAmountCaptionLbl)
                    {
                    }
                    column(LineDiscountCaption; LineDiscountCaptionLbl)
                    {
                    }
                    column(AmountCaption; AmountCaptionLbl)
                    {
                    }
                    column(DocNoCaption; DocNoCaptionLbl)
                    {
                    }
                    column(DocDateCaption; DocDateCaptionLbl)
                    {
                    }
                    column(Posting_DescriptionCaption; Posting_DescriptionCaptionLbl)
                    {
                    }
                    column(BankTransitNo; BankTransitNo)
                    {
                    }
                    column(BankAccountNo; BankAccountNo)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if not TestPrint then begin
                            if FoundLast or not AddedRemainingAmount then begin
                                if RemainingAmount <> 0 then begin
                                    AddedRemainingAmount := true;
                                    FoundLast := true;
                                    DocNo := '';
                                    ExtDocNo := '';
                                    LineAmount := RemainingAmount;
                                    LineAmount2 := RemainingAmount;
                                    CurrentLineAmount := LineAmount2;
                                    LineDiscount := 0;
                                    RemainingAmount := 0;

                                    PostingDesc := CheckToAddr[1];
                                end else
                                    CurrReport.Break();
                            end else
                                case ApplyMethod of
                                    ApplyMethod::OneLineOneEntry:
                                        begin
                                            case BalancingType of
                                                BalancingType::Customer:
                                                    PrintOneLineOneEntryOnAfterGetRecordForCustomer(CustLedgEntry);
                                                BalancingType::Vendor:
                                                    PrintOneLineOneEntryOnAfterGetRecordForVendor(VendLedgEntry);
                                                BalancingType::Employee:
                                                    PrintOneLineOneEntryOnAfterGetRecordForEmployee(EmployeeLedgerEntry);
                                            end;
                                            RemainingAmount := RemainingAmount - LineAmount2;
                                            CurrentLineAmount := LineAmount2;
                                            FoundLast := true;
                                        end;
                                    ApplyMethod::OneLineID:
                                        begin
                                            case BalancingType of
                                                BalancingType::Customer:
                                                    begin
                                                        CustUpdateAmounts(CustLedgEntry, RemainingAmount);
                                                        FoundLast := (CustLedgEntry.Next() = 0) or (RemainingAmount <= 0);
                                                        if FoundLast and not FoundNegative then begin
                                                            CustLedgEntry.SetRange(Positive, false);
                                                            FoundLast := not CustLedgEntry.Find('-');
                                                            FoundNegative := true;
                                                        end;
                                                    end;
                                                BalancingType::Vendor:
                                                    begin
                                                        VendUpdateAmounts(VendLedgEntry, RemainingAmount);
                                                        FoundLast := (VendLedgEntry.Next() = 0) or (RemainingAmount <= 0);
                                                        if FoundLast and not FoundNegative then begin
                                                            VendLedgEntry.SetRange(Positive, false);
                                                            FoundLast := not VendLedgEntry.Find('-');
                                                            FoundNegative := true;
                                                        end;
                                                    end;
                                            end;
                                            RemainingAmount := RemainingAmount - LineAmount2;
                                            CurrentLineAmount := LineAmount2;
                                            AddedRemainingAmount := not (FoundLast and (RemainingAmount > 0));
                                        end;
                                    ApplyMethod::MoreLinesOneEntry:
                                        begin
                                            CurrentLineAmount := GenJnlLine2.Amount;
                                            LineAmount2 := CurrentLineAmount;
                                            if GenJnlLine2."Applies-to ID" <> '' then
                                                Error(
                                                  Text016 +
                                                  Text017);
                                            GenJnlLine2.TestField("Check Printed", false);
                                            GenJnlLine2.TestField("Bank Payment Type", GenJnlLine2."Bank Payment Type"::"Computer Check");

                                            if GenJnlLine2."Applies-to Doc. No." = '' then begin
                                                DocNo := '';
                                                ExtDocNo := '';
                                                LineAmount := CurrentLineAmount;
                                                LineDiscount := 0;
                                                PostingDesc := GenJnlLine2.Description;
                                            end else
                                                case BalancingType of
                                                    BalancingType::"G/L Account":
                                                        begin
                                                            DocNo := GenJnlLine2."Document No.";
                                                            ExtDocNo := GenJnlLine2."External Document No.";
                                                            LineAmount := CurrentLineAmount;
                                                            LineDiscount := 0;
                                                            PostingDesc := GenJnlLine2.Description;
                                                        end;
                                                    BalancingType::Customer:
                                                        begin
                                                            CustLedgEntry.Reset();
                                                            CustLedgEntry.SetCurrentKey("Document No.");
                                                            CustLedgEntry.SetRange("Document Type", GenJnlLine2."Applies-to Doc. Type");
                                                            CustLedgEntry.SetRange("Document No.", GenJnlLine2."Applies-to Doc. No.");
                                                            CustLedgEntry.SetRange("Customer No.", BalancingNo);
                                                            CustLedgEntry.Find('-');
                                                            CustUpdateAmounts(CustLedgEntry, CurrentLineAmount);
                                                            LineAmount := CurrentLineAmount;
                                                        end;
                                                    BalancingType::Vendor:
                                                        begin
                                                            VendLedgEntry.Reset();
                                                            VendLedgEntry.SetCurrentKey("Document No.");
                                                            VendLedgEntry.SetRange("Document Type", GenJnlLine2."Applies-to Doc. Type");
                                                            VendLedgEntry.SetRange("Document No.", GenJnlLine2."Applies-to Doc. No.");
                                                            VendLedgEntry.SetRange("Vendor No.", BalancingNo);
                                                            VendLedgEntry.Find('-');
                                                            VendUpdateAmounts(VendLedgEntry, CurrentLineAmount);
                                                            LineAmount := CurrentLineAmount;
                                                        end;
                                                    BalancingType::"Bank Account":
                                                        begin
                                                            DocNo := GenJnlLine2."Document No.";
                                                            ExtDocNo := GenJnlLine2."External Document No.";
                                                            LineAmount := CurrentLineAmount;
                                                            LineDiscount := 0;
                                                            PostingDesc := GenJnlLine2.Description;
                                                        end;
                                                    BalancingType::Employee:
                                                        begin
                                                            EmployeeLedgerEntry.Reset();
                                                            if GenJnlLine2."Source Line No." <> 0 then
                                                                EmployeeLedgerEntry.SetRange("Entry No.", GenJnlLine2."Source Line No.")
                                                            else begin
                                                                EmployeeLedgerEntry.SetCurrentKey("Document No.");
                                                                EmployeeLedgerEntry.SetRange("Document Type", GenJnlLine2."Applies-to Doc. Type");
                                                                EmployeeLedgerEntry.SetRange("Document No.", GenJnlLine2."Applies-to Doc. No.");
                                                                EmployeeLedgerEntry.SetRange("Employee No.", BalancingNo);
                                                            end;
                                                            EmployeeLedgerEntry.FindFirst();
                                                            EmployeeUpdateAmounts(EmployeeLedgerEntry, CurrentLineAmount);
                                                            LineAmount := CurrentLineAmount;
                                                        end;
                                                end;

                                            FoundLast := GenJnlLine2.Next() = 0;
                                        end;
                                end;

                            TotalLineAmount := TotalLineAmount + CurrentLineAmount;
                            TotalLineDiscount := TotalLineDiscount + LineDiscount;
                        end else begin
                            if FoundLast then
                                CurrReport.Break();
                            FoundLast := true;
                            DocNo := Text010;
                            ExtDocNo := Text010;
                            LineAmount := 0;
                            LineDiscount := 0;
                            PostingDesc := '';
                        end;

                        if DocNo = '' then
                            CurrencyCode2 := GenJnlLine."Currency Code";

                        Stub2LineNo := Stub2LineNo + 1;
                        Stub2DocNo[Stub2LineNo] := DocNo;
                        Stub2DocDate[Stub2LineNo] := DocDate;
                        Stub2LineAmount[Stub2LineNo] := LineAmount;
                        Stub2LineDiscount[Stub2LineNo] := LineDiscount;
                        Stub2PostingDescription[Stub2LineNo] := PostingDesc;

                        OnAfterOnAfterGetRecordOfPrintSettledLoop(GenJnlLine2, TotalLineAmount, CurrentLineAmount, TotalLineDiscount, LineDiscount, BalancingType, ApplyMethod);
                    end;

                    trigger OnPreDataItem()
                    begin
                        PrintCheckHelper.PrintSettledLoopHelper(CustLedgEntry, VendLedgEntry, GenJnlLine, BalancingType.AsInteger(), BalancingNo,
                          FoundLast, TestPrint, FirstPage, FoundNegative, ApplyMethod);

                        if PreprintedStub then
                            TotalText := ''
                        else begin
                            TotalText := Text019;
                            Stub2DocNoHeader := USText011;
                            Stub2DocDateHeader := USText012;
                            Stub2AmountHeader := USText013;
                            Stub2DiscountHeader := USText014;
                            Stub2NetAmountHeader := USText015;
                            Stub2PostingDescHeader := USText017;
                        end;
                        GLSetup.Get();
                        PageNo := PageNo + 1;

                        if TestPrint then begin
                            BankTransitNo := Text003;
                            BankAccountNo := Text003;
                        end;
                        BankTransitNo := BankAcc2."Transit No.";
                        BankAccountNo := BankAcc2."Bank Account No.";

                        OnAfterOnPreDataItemOfPrintSettledLoop(GenJnlLine, BalancingType, ApplyMethod);
                    end;
                }
                dataitem(PrintCheck; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    MaxIteration = 1;
                    column(PrnChkCheckToAddr_CheckStyle__CA_5_; PrnChkCheckToAddr[CheckStyle::CA, 5])
                    {
                    }
                    column(PrnChkCheckToAddr_CheckStyle__CA_4_; PrnChkCheckToAddr[CheckStyle::CA, 4])
                    {
                    }
                    column(PrnChkCheckToAddr_CheckStyle__CA_3_; PrnChkCheckToAddr[CheckStyle::CA, 3])
                    {
                    }
                    column(PrnChkCheckToAddr_CheckStyle__CA_2_; PrnChkCheckToAddr[CheckStyle::CA, 2])
                    {
                    }
                    column(PrnChkCheckToAddr_CheckStyle__CA_1_; PrnChkCheckToAddr[CheckStyle::CA, 1])
                    {
                    }
                    column(PrnChkCheckAmountText_CheckStyle__US_; PrnChkCheckAmountText[CheckStyle::US])
                    {
                    }
                    column(PrnChkCheckDateText_CheckStyle__US_; PrnChkCheckDateText[CheckStyle::US])
                    {
                    }
                    column(PrnChkDescriptionLine_CheckStyle__US_2_; PrnChkDescriptionLine[CheckStyle::US, 2])
                    {
                    }
                    column(PrnChkDescriptionLine_CheckStyle__US_1_; PrnChkDescriptionLine[CheckStyle::US, 1])
                    {
                    }
                    column(PrnChkCheckToAddr_CheckStyle__US_1_; PrnChkCheckToAddr[CheckStyle::US, 1])
                    {
                    }
                    column(PrnChkCheckToAddr_CheckStyle__US_2_; PrnChkCheckToAddr[CheckStyle::US, 2])
                    {
                    }
                    column(PrnChkCheckToAddr_CheckStyle__US_4_; PrnChkCheckToAddr[CheckStyle::US, 4])
                    {
                    }
                    column(PrnChkCheckToAddr_CheckStyle__US_3_; PrnChkCheckToAddr[CheckStyle::US, 3])
                    {
                    }
                    column(PrnChkCheckToAddr_CheckStyle__US_5_; PrnChkCheckToAddr[CheckStyle::US, 5])
                    {
                    }
                    column(PrnChkCompanyAddr_CheckStyle__US_4_; PrnChkCompanyAddr[CheckStyle::US, 4])
                    {
                    }
                    column(PrnChkCompanyAddr_CheckStyle__US_6_; PrnChkCompanyAddr[CheckStyle::US, 6])
                    {
                    }
                    column(PrnChkCompanyAddr_CheckStyle__US_5_; PrnChkCompanyAddr[CheckStyle::US, 5])
                    {
                    }
                    column(PrnChkCompanyAddr_CheckStyle__US_3_; PrnChkCompanyAddr[CheckStyle::US, 3])
                    {
                    }
                    column(PrnChkCheckNoText_CheckStyle__US_; PrnChkCheckNoText[CheckStyle::US])
                    {
                    }
                    column(PrnChkCompanyAddr_CheckStyle__US_2_; PrnChkCompanyAddr[CheckStyle::US, 2])
                    {
                    }
                    column(PrnChkCompanyAddr_CheckStyle__US_1_; PrnChkCompanyAddr[CheckStyle::US, 1])
                    {
                    }
                    column(TotalLineAmount; TotalLineAmount)
                    {
                        AutoFormatExpression = GenJnlLine."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(TotalText; TotalText)
                    {
                    }
                    column(PrnChkVoidText_CheckStyle__US_; PrnChkVoidText[CheckStyle::US])
                    {
                    }
                    column(PrnChkCompanyAddr_CheckStyle__CA_1_; PrnChkCompanyAddr[CheckStyle::CA, 1])
                    {
                    }
                    column(PrnChkCompanyAddr_CheckStyle__CA_2_; PrnChkCompanyAddr[CheckStyle::CA, 2])
                    {
                    }
                    column(PrnChkCompanyAddr_CheckStyle__CA_3_; PrnChkCompanyAddr[CheckStyle::CA, 3])
                    {
                    }
                    column(PrnChkCompanyAddr_CheckStyle__CA_4_; PrnChkCompanyAddr[CheckStyle::CA, 4])
                    {
                    }
                    column(PrnChkCompanyAddr_CheckStyle__CA_5_; PrnChkCompanyAddr[CheckStyle::CA, 5])
                    {
                    }
                    column(PrnChkCompanyAddr_CheckStyle__CA_6_; PrnChkCompanyAddr[CheckStyle::CA, 6])
                    {
                    }
                    column(PrnChkDescriptionLine_CheckStyle__CA_1_; PrnChkDescriptionLine[CheckStyle::CA, 1])
                    {
                    }
                    column(PrnChkDescriptionLine_CheckStyle__CA_2_; PrnChkDescriptionLine[CheckStyle::CA, 2])
                    {
                    }
                    column(PrnChkCheckDateText_CheckStyle__CA_; PrnChkCheckDateText[CheckStyle::CA])
                    {
                    }
                    column(PrnChkDateIndicator_CheckStyle__CA_; PrnChkDateIndicator[CheckStyle::CA])
                    {
                    }
                    column(PrnChkCheckAmountText_CheckStyle__CA_; PrnChkCheckAmountText[CheckStyle::CA])
                    {
                    }
                    column(PrnChkVoidText_CheckStyle__CA_; PrnChkVoidText[CheckStyle::CA])
                    {
                    }
                    column(PrnChkCurrencyCode_CheckStyle__CA_; PrnChkCurrencyCode[CheckStyle::CA])
                    {
                    }
                    column(PrnChkCurrencyCode_CheckStyle__US_; PrnChkCurrencyCode[CheckStyle::US])
                    {
                    }
                    column(CheckNoText_Control1480000; CheckNoText)
                    {
                    }
                    column(CheckDateText_Control1480021; CheckDateText)
                    {
                    }
                    column(CheckToAddr_1__Control1480022; CheckToAddr[1])
                    {
                    }
                    column(Stub2DocNoHeader; Stub2DocNoHeader)
                    {
                    }
                    column(Stub2DocDateHeader; Stub2DocDateHeader)
                    {
                    }
                    column(Stub2AmountHeader; Stub2AmountHeader)
                    {
                    }
                    column(Stub2DiscountHeader; Stub2DiscountHeader)
                    {
                    }
                    column(Stub2NetAmountHeader; Stub2NetAmountHeader)
                    {
                    }
                    column(Stub2LineAmount_1_; Stub2LineAmount[1])
                    {
                        AutoFormatExpression = GenJnlLine."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(Stub2LineDiscount_1_; Stub2LineDiscount[1])
                    {
                        AutoFormatExpression = GenJnlLine."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(Stub2LineAmount_1____Stub2LineDiscount_1_; Stub2LineAmount[1] + Stub2LineDiscount[1])
                    {
                        AutoFormatExpression = GenJnlLine."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(Stub2DocDate_1_; Stub2DocDate[1])
                    {
                    }
                    column(Stub2DocNo_1_; Stub2DocNo[1])
                    {
                    }
                    column(Stub2LineAmount_2_; Stub2LineAmount[2])
                    {
                        AutoFormatExpression = GenJnlLine."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(Stub2LineDiscount_2_; Stub2LineDiscount[2])
                    {
                        AutoFormatExpression = GenJnlLine."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(Stub2LineAmount_2____Stub2LineDiscount_2_; Stub2LineAmount[2] + Stub2LineDiscount[2])
                    {
                        AutoFormatExpression = GenJnlLine."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(Stub2DocDate_2_; Stub2DocDate[2])
                    {
                    }
                    column(Stub2DocNo_2_; Stub2DocNo[2])
                    {
                    }
                    column(Stub2LineAmount_3_; Stub2LineAmount[3])
                    {
                        AutoFormatExpression = GenJnlLine."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(Stub2LineDiscount_3_; Stub2LineDiscount[3])
                    {
                        AutoFormatExpression = GenJnlLine."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(Stub2LineAmount_3____Stub2LineDiscount_3_; Stub2LineAmount[3] + Stub2LineDiscount[3])
                    {
                        AutoFormatExpression = GenJnlLine."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(Stub2DocDate_3_; Stub2DocDate[3])
                    {
                    }
                    column(Stub2DocNo_3_; Stub2DocNo[3])
                    {
                    }
                    column(Stub2LineAmount_4_; Stub2LineAmount[4])
                    {
                        AutoFormatExpression = GenJnlLine."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(Stub2LineDiscount_4_; Stub2LineDiscount[4])
                    {
                        AutoFormatExpression = GenJnlLine."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(Stub2LineAmount_4____Stub2LineDiscount_4_; Stub2LineAmount[4] + Stub2LineDiscount[4])
                    {
                        AutoFormatExpression = GenJnlLine."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(Stub2DocDate_4_; Stub2DocDate[4])
                    {
                    }
                    column(Stub2DocNo_4_; Stub2DocNo[4])
                    {
                    }
                    column(Stub2LineAmount_5_; Stub2LineAmount[5])
                    {
                        AutoFormatExpression = GenJnlLine."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(Stub2LineDiscount_5_; Stub2LineDiscount[5])
                    {
                        AutoFormatExpression = GenJnlLine."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(Stub2LineAmount_5____Stub2LineDiscount_5_; Stub2LineAmount[5] + Stub2LineDiscount[5])
                    {
                        AutoFormatExpression = GenJnlLine."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(Stub2DocDate_5_; Stub2DocDate[5])
                    {
                    }
                    column(Stub2DocNo_5_; Stub2DocNo[5])
                    {
                    }
                    column(Stub2LineAmount_6_; Stub2LineAmount[6])
                    {
                        AutoFormatExpression = GenJnlLine."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(Stub2LineDiscount_6_; Stub2LineDiscount[6])
                    {
                        AutoFormatExpression = GenJnlLine."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(Stub2LineAmount_6____Stub2LineDiscount_6_; Stub2LineAmount[6] + Stub2LineDiscount[6])
                    {
                        AutoFormatExpression = GenJnlLine."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(Stub2DocDate_6_; Stub2DocDate[6])
                    {
                    }
                    column(Stub2DocNo_6_; Stub2DocNo[6])
                    {
                    }
                    column(Stub2LineAmount_7_; Stub2LineAmount[7])
                    {
                        AutoFormatExpression = GenJnlLine."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(Stub2LineDiscount_7_; Stub2LineDiscount[7])
                    {
                        AutoFormatExpression = GenJnlLine."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(Stub2LineAmount_7____Stub2LineDiscount_7_; Stub2LineAmount[7] + Stub2LineDiscount[7])
                    {
                        AutoFormatExpression = GenJnlLine."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(Stub2DocDate_7_; Stub2DocDate[7])
                    {
                    }
                    column(Stub2DocNo_7_; Stub2DocNo[7])
                    {
                    }
                    column(Stub2LineAmount_8_; Stub2LineAmount[8])
                    {
                        AutoFormatExpression = GenJnlLine."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(Stub2LineDiscount_8_; Stub2LineDiscount[8])
                    {
                        AutoFormatExpression = GenJnlLine."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(Stub2LineAmount_8____Stub2LineDiscount_8_; Stub2LineAmount[8] + Stub2LineDiscount[8])
                    {
                        AutoFormatExpression = GenJnlLine."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(Stub2DocDate_8_; Stub2DocDate[8])
                    {
                    }
                    column(Stub2DocNo_8_; Stub2DocNo[8])
                    {
                    }
                    column(Stub2LineAmount_9_; Stub2LineAmount[9])
                    {
                        AutoFormatExpression = GenJnlLine."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(Stub2LineDiscount_9_; Stub2LineDiscount[9])
                    {
                        AutoFormatExpression = GenJnlLine."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(Stub2LineAmount_9____Stub2LineDiscount_9_; Stub2LineAmount[9] + Stub2LineDiscount[9])
                    {
                        AutoFormatExpression = GenJnlLine."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(Stub2DocDate_9_; Stub2DocDate[9])
                    {
                    }
                    column(Stub2DocNo_9_; Stub2DocNo[9])
                    {
                    }
                    column(Stub2LineAmount_10_; Stub2LineAmount[10])
                    {
                        AutoFormatExpression = GenJnlLine."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(Stub2LineDiscount_10_; Stub2LineDiscount[10])
                    {
                        AutoFormatExpression = GenJnlLine."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(Stub2LineAmount_10____Stub2LineDiscount_10_; Stub2LineAmount[10] + Stub2LineDiscount[10])
                    {
                        AutoFormatExpression = GenJnlLine."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(Stub2DocDate_10_; Stub2DocDate[10])
                    {
                    }
                    column(Stub2DocNo_10_; Stub2DocNo[10])
                    {
                    }
                    column(TotalLineAmount_Control1480082; TotalLineAmount)
                    {
                        AutoFormatExpression = GenJnlLine."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(TotalText_Control1480083; TotalText)
                    {
                    }
                    column(Stub2PostingDescHeader; Stub2PostingDescHeader)
                    {
                    }
                    column(Stub2PostingDescription_1_; Stub2PostingDescription[1])
                    {
                    }
                    column(Stub2PostingDescription_2_; Stub2PostingDescription[2])
                    {
                    }
                    column(Stub2PostingDescription_4_; Stub2PostingDescription[4])
                    {
                    }
                    column(Stub2PostingDescription_3_; Stub2PostingDescription[3])
                    {
                    }
                    column(Stub2PostingDescription_8_; Stub2PostingDescription[8])
                    {
                    }
                    column(Stub2PostingDescription_7_; Stub2PostingDescription[7])
                    {
                    }
                    column(Stub2PostingDescription_6_; Stub2PostingDescription[6])
                    {
                    }
                    column(Stub2PostingDescription_5_; Stub2PostingDescription[5])
                    {
                    }
                    column(Stub2PostingDescription_10_; Stub2PostingDescription[10])
                    {
                    }
                    column(Stub2PostingDescription_9_; Stub2PostingDescription[9])
                    {
                    }
                    column(CheckToAddr_5_; CheckToAddr[5])
                    {
                    }
                    column(CheckToAddr_4_; CheckToAddr[4])
                    {
                    }
                    column(CheckToAddr_3_; CheckToAddr[3])
                    {
                    }
                    column(CheckToAddr_2_; CheckToAddr[2])
                    {
                    }
                    column(CheckToAddr_01_; CheckToAddr[1])
                    {
                    }
                    column(VoidText; VoidText)
                    {
                    }
                    column(BankCurrencyCode; BankCurrencyCode)
                    {
                    }
                    column(DollarSignBefore_CheckAmountText_DollarSignAfter; DollarSignBefore + CheckAmountText + DollarSignAfter)
                    {
                    }
                    column(DescriptionLine_1__; DescriptionLine[1])
                    {
                    }
                    column(DescriptionLine_2__; DescriptionLine[2])
                    {
                    }
                    column(DateIndicator; DateIndicator)
                    {
                    }
                    column(CheckDateText_Control1020014; CheckDateText)
                    {
                    }
                    column(CheckNoText_Control1020015; CheckNoText)
                    {
                    }
                    column(CompanyAddr_6_; CompanyAddr[6])
                    {
                    }
                    column(CompanyAddr_5_; CompanyAddr[5])
                    {
                    }
                    column(CompanyAddr_4_; CompanyAddr[4])
                    {
                    }
                    column(CompanyAddr_3_; CompanyAddr[3])
                    {
                    }
                    column(CompanyAddr_2_; CompanyAddr[2])
                    {
                    }
                    column(CompanyAddr_1_; CompanyAddr[1])
                    {
                    }
                    column(CheckStyleIndex; CheckStyleIndex)
                    {
                    }
                    column(PageNo_Control1020024; PageNo)
                    {
                    }
                    column(PrintCheck_Number; Number)
                    {
                    }
                    column(CheckNoText_Control1480000Caption; CheckNoText_Control1480000CaptionLbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    var
                        CurrencySymbol: Code[5];
                    begin
                        if not TestPrint then begin
                            CheckLedgEntry.Init();
                            CheckLedgEntry."Bank Account No." := BankAcc2."No.";
                            CheckLedgEntry."Posting Date" := GenJnlLine."Posting Date";
                            CheckLedgEntry."Document Type" := GenJnlLine."Document Type";
                            CheckLedgEntry."Document No." := UseCheckNo;
                            CheckLedgEntry.Description := CheckToAddr[1];
                            CheckLedgEntry."Bank Payment Type" := GenJnlLine."Bank Payment Type";
                            CheckLedgEntry."Bal. Account Type" := BalancingType;
                            CheckLedgEntry."Bal. Account No." := BalancingNo;
                            if FoundLast and AddedRemainingAmount then begin
                                if TotalLineAmount < 0 then
                                    Error(
                                      Text020,
                                      UseCheckNo, TotalLineAmount);
                                CheckLedgEntry."Entry Status" := CheckLedgEntry."Entry Status"::Printed;
                                CheckLedgEntry.Amount := TotalLineAmount;
                            end else begin
                                CheckLedgEntry."Entry Status" := CheckLedgEntry."Entry Status"::Voided;
                                CheckLedgEntry.Amount := 0;
                            end;
                            CheckLedgEntry."Check Date" := GenJnlLine."Posting Date";
                            CheckLedgEntry."Check No." := UseCheckNo;
                            CheckManagement.InsertCheck(CheckLedgEntry, GenJnlLine.RecordId);

                            if FoundLast and AddedRemainingAmount then begin
                                CheckAmountText := CheckLedgEntry.GetCheckAmountText(BankAcc2."Currency Code", CurrencySymbol);

                                if CheckLanguage = 3084 then begin
                                    // French
                                    DollarSignBefore := '';
                                    DollarSignAfter := CurrencySymbol;
                                end else begin
                                    DollarSignBefore := CurrencySymbol;
                                    DollarSignAfter := ' ';
                                end;
                                if not ChkTransMgt.FormatNoText(DescriptionLine, CheckLedgEntry.Amount, CheckLanguage, BankAcc2."Currency Code") then
                                    Error(DescriptionLine[1]);
                                VoidText := '';
                            end else begin
                                Clear(CheckAmountText);
                                Clear(DescriptionLine);
                                DescriptionLine[1] := CopyStr(Text021, 1, MaxStrLen(descriptionline[1]));
                                DescriptionLine[2] := DescriptionLine[1];
                                VoidText := Text022;
                            end;
                        end
                        else begin
                            CheckLedgEntry.Init();
                            CheckLedgEntry."Bank Account No." := BankAcc2."No.";
                            CheckLedgEntry."Posting Date" := GenJnlLine."Posting Date";
                            CheckLedgEntry."Document No." := UseCheckNo;
                            CheckLedgEntry.Description := Text023;
                            CheckLedgEntry."Bank Payment Type" := GenJnlLine."Bank Payment Type"::"Computer Check";
                            CheckLedgEntry."Entry Status" := CheckLedgEntry."Entry Status"::"Test Print";
                            CheckLedgEntry."Check Date" := GenJnlLine."Posting Date";
                            CheckLedgEntry."Check No." := UseCheckNo;
                            CheckManagement.InsertCheck(CheckLedgEntry, GenJnlLine.RecordId);

                            CheckAmountText := Text024;
                            DescriptionLine[1] := Text025;
                            DescriptionLine[2] := DescriptionLine[1];
                            VoidText := Text022;
                        end;

                        ChecksPrinted := ChecksPrinted + 1;
                        FirstPage := false;

                        Clear(PrnChkCompanyAddr);
                        Clear(PrnChkCheckToAddr);
                        Clear(PrnChkCheckNoText);
                        Clear(PrnChkCheckDateText);
                        Clear(PrnChkDescriptionLine);
                        Clear(PrnChkVoidText);
                        Clear(PrnChkDateIndicator);
                        Clear(PrnChkCurrencyCode);
                        Clear(PrnChkCheckAmountText);
                        CopyArray(PrnChkCompanyAddr[CheckStyle], CompanyAddr, 1);
                        CopyArray(PrnChkCheckToAddr[CheckStyle], CheckToAddr, 1);
                        PrnChkCheckNoText[CheckStyle] := CheckNoText;
                        PrnChkCheckDateText[CheckStyle] := CheckDateText;
                        CopyArray(PrnChkDescriptionLine[CheckStyle], DescriptionLine, 1);
                        PrnChkVoidText[CheckStyle] := VoidText;
                        PrnChkDateIndicator[CheckStyle] := DateIndicator;
                        PrnChkCurrencyCode[CheckStyle] := BankAcc2."Currency Code";
                        StartingLen := StrLen(CheckAmountText);
                        if CheckStyle = CheckStyle::US then
                            ControlLen := 27
                        else
                            ControlLen := 29;
                        CheckAmountText := CheckAmountText + DollarSignBefore + DollarSignAfter;
                        Index := 0;
                        if CheckAmountText = Text024 then begin
                            if StrLen(CheckAmountText) < (ControlLen - 12) then
                                repeat
                                    Index := Index + 1;
                                    CheckAmountText := InsStr(CheckAmountText, '*', StrLen(CheckAmountText) + 1);
                                until (Index = ControlLen) or (StrLen(CheckAmountText) >= (ControlLen - 12));
                        end else
                            if StrLen(CheckAmountText) < (ControlLen - 11) then
                                repeat
                                    Index := Index + 1;
                                    CheckAmountText := InsStr(CheckAmountText, '*', StrLen(CheckAmountText) + 1);
                                until (Index = ControlLen) or (StrLen(CheckAmountText) >= (ControlLen - 11));
                        CheckAmountText :=
                          DelStr(CheckAmountText, StartingLen + 1, StrLen(DollarSignBefore + DollarSignAfter));
                        NewLen := StrLen(CheckAmountText);
                        if NewLen <> StartingLen then
                            CheckAmountText :=
                              CopyStr(CheckAmountText, StartingLen + 1) +
                              CopyStr(CheckAmountText, 1, StartingLen);
                        PrnChkCheckAmountText[CheckStyle] :=
                          DollarSignBefore + CheckAmountText + DollarSignAfter;

                        if CheckStyle = CheckStyle::CA then
                            CheckStyleIndex := 0
                        else
                            CheckStyleIndex := 1;

                        OnAfterOnAfterGetRecordOfPrintCheck(GenJnlLine);
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if FoundLast and AddedRemainingAmount then
                        CurrReport.Break();

                    UseCheckNo := IncStr(UseCheckNo);
                    OnAfterIncStrCheckNo(UseCheckNo, GenJnlLine, CheckPages, PageNo);
                    if not TestPrint then
                        CheckNoText := UseCheckNo
                    else
                        CheckNoText := Text011;

                    Stub2LineNo := 0;
                    Clear(Stub2DocNo);
                    Clear(Stub2DocDate);
                    Clear(Stub2LineAmount);
                    Clear(Stub2LineDiscount);
                    Clear(Stub2PostingDescription);
                    Stub2DocNoHeader := '';
                    Stub2DocDateHeader := '';
                    Stub2AmountHeader := '';
                    Stub2DiscountHeader := '';
                    Stub2NetAmountHeader := '';
                    Stub2PostingDescHeader := '';
                end;

                trigger OnPostDataItem()
                var
                    RecordRestrictionMgt: Codeunit "Record Restriction Mgt.";
                begin
                    if not TestPrint then begin
                        if UseCheckNo <> GenJnlLine."Document No." then begin
                            GenJnlLine3.Reset();
                            GenJnlLine3.SetCurrentKey("Journal Template Name", "Journal Batch Name", "Posting Date", "Document No.");
                            GenJnlLine3.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
                            GenJnlLine3.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
                            GenJnlLine3.SetRange("Posting Date", GenJnlLine."Posting Date");
                            GenJnlLine3.SetRange("Document No.", UseCheckNo);
                            if GenJnlLine3.Find('-') then
                                GenJnlLine3.FieldError("Document No.", StrSubstNo(Text013, UseCheckNo));
                        end;

                        if ApplyMethod <> ApplyMethod::MoreLinesOneEntry then begin
                            GenJnlLine3 := GenJnlLine;
                            GenJnlLine3.TestField("Posting No. Series", '');
                            GenJnlLine3."Document No." := UseCheckNo;
                            GenJnlLine3."Check Printed" := true;
                            GenJnlLine3.Modify();
                        end else begin
                            "TotalLineAmount$" := 0;
                            if GenJnlLine2.Find('-') then begin
                                HighestLineNo := GenJnlLine2."Line No.";
                                repeat
                                    RecordRestrictionMgt.CheckRecordHasUsageRestrictions(GenJnlLine2);
                                    if BankAcc2."Currency Code" <> GenJnlLine2."Currency Code" then
                                        Error(Text005);
                                    if GenJnlLine2."Line No." > HighestLineNo then
                                        HighestLineNo := GenJnlLine2."Line No.";
                                    GenJnlLine3 := GenJnlLine2;
                                    GenJnlLine3.TestField("Posting No. Series", '');
                                    GenJnlLine3."Bal. Account No." := '';
                                    GenJnlLine3."Bank Payment Type" := GenJnlLine3."Bank Payment Type"::" ";
                                    GenJnlLine3."Document No." := UseCheckNo;
                                    GenJnlLine3."Check Printed" := true;
                                    GenJnlLine3.Validate(Amount);
                                    "TotalLineAmount$" := "TotalLineAmount$" + GenJnlLine3."Amount (LCY)";
                                    GenJnlLine3.Modify();
                                until GenJnlLine2.Next() = 0;
                            end;

                            GenJnlLine3.Reset();
                            GenJnlLine3 := GenJnlLine;
                            GenJnlLine3.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
                            GenJnlLine3.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
                            GenJnlLine3."Line No." := HighestLineNo;
                            if GenJnlLine3.Next() = 0 then
                                GenJnlLine3."Line No." := HighestLineNo + 10000
                            else begin
                                while GenJnlLine3."Line No." = HighestLineNo + 1 do begin
                                    HighestLineNo := GenJnlLine3."Line No.";
                                    if GenJnlLine3.Next() = 0 then
                                        GenJnlLine3."Line No." := HighestLineNo + 20000;
                                end;
                                GenJnlLine3."Line No." := (GenJnlLine3."Line No." + HighestLineNo) div 2;
                            end;
                            GenJnlLine3.Init();
                            GenJnlLine3.Validate("Posting Date", GenJnlLine."Posting Date");
                            GenJnlLine3."Document Type" := GenJnlLine."Document Type";
                            GenJnlLine3."Document No." := UseCheckNo;
                            GenJnlLine3."Account Type" := GenJnlLine3."Account Type"::"Bank Account";
                            GenJnlLine3.Validate("Account No.", BankAcc2."No.");
                            if BalancingType <> BalancingType::"G/L Account" then
                                GenJnlLine3.Description := StrSubstNo(Text014, SelectStr(BalancingType.AsInteger() + 1, Text062), BalancingNo);
                            GenJnlLine3.Validate(Amount, -TotalLineAmount);
                            if TotalLineAmount <> "TotalLineAmount$" then
                                GenJnlLine3.Validate("Amount (LCY)", -"TotalLineAmount$");
                            GenJnlLine3."Bank Payment Type" := GenJnlLine3."Bank Payment Type"::"Computer Check";
                            GenJnlLine3."Check Printed" := true;
                            GenJnlLine3."Source Code" := GenJnlLine."Source Code";
                            GenJnlLine3."Reason Code" := GenJnlLine."Reason Code";
                            GenJnlLine3."Allow Zero-Amount Posting" := true;
                            GenJnlLine3."Shortcut Dimension 1 Code" := GenJnlLine."Shortcut Dimension 1 Code";
                            GenJnlLine3."Shortcut Dimension 2 Code" := GenJnlLine."Shortcut Dimension 2 Code";
                            GenJnlLine3."Dimension Set ID" := GenJnlLine."Dimension Set ID";
                            GenJnlLine3.Insert();
                            if CheckGenJournalBatchAndLineIsApproved(GenJnlLine) then
                                RecordRestrictionMgt.AllowRecordUsage(GenJnlLine3);
                        end;
                    end;

                    if not TestPrint then begin
                        BankAcc2."Last Check No." := UseCheckNo;
                        BankAcc2.Modify();
                    end;

                    if CommitEachCheck then begin
                        Commit();
                        Clear(CheckManagement);
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    FirstPage := true;
                    FoundLast := false;
                    TotalLineAmount := 0;
                    TotalLineDiscount := 0;
                    AddedRemainingAmount := true;

                    OnAfterOnPreDataItemOfCheckPages(GenJnlLine);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if OneCheckPrVendor and ("Currency Code" <> '') and
                   ("Currency Code" <> Currency.Code)
                then begin
                    Currency.Get("Currency Code");
                    Currency.TestField("Conv. LCY Rndg. Debit Acc.");
                    Currency.TestField("Conv. LCY Rndg. Credit Acc.");
                end;

                if not TestPrint then begin
                    if Amount = 0 then
                        CurrReport.Skip();

                    TestField("Bal. Account Type", "Bal. Account Type"::"Bank Account");
                    if "Bal. Account No." <> BankAcc2."No." then
                        CurrReport.Skip();

                    if ("Account No." <> '') and ("Bal. Account No." <> '') then begin
                        BalancingType := "Account Type";
                        BalancingNo := "Account No.";
                        RemainingAmount := Amount;
                        if OneCheckPrVendor then begin
                            ApplyMethod := ApplyMethod::MoreLinesOneEntry;
                            GenJnlLine2.Reset();
                            GenJnlLine2.SetCurrentKey("Journal Template Name", "Journal Batch Name", "Posting Date", "Document No.");
                            GenJnlLine2.SetRange("Journal Template Name", "Journal Template Name");
                            GenJnlLine2.SetRange("Journal Batch Name", "Journal Batch Name");
                            GenJnlLine2.SetRange("Posting Date", "Posting Date");
                            GenJnlLine2.SetRange("Document No.", "Document No.");
                            GenJnlLine2.SetRange("Account Type", "Account Type");
                            GenJnlLine2.SetRange("Account No.", "Account No.");
                            GenJnlLine2.SetRange("Bal. Account Type", "Bal. Account Type");
                            GenJnlLine2.SetRange("Bal. Account No.", "Bal. Account No.");
                            GenJnlLine2.SetRange("Bank Payment Type", "Bank Payment Type");
                            GenJnlLine2.Find('-');
                            RemainingAmount := 0;
                        end else
                            if "Applies-to Doc. No." <> '' then
                                ApplyMethod := ApplyMethod::OneLineOneEntry
                            else
                                if "Applies-to ID" <> '' then
                                    ApplyMethod := ApplyMethod::OneLineID
                                else
                                    ApplyMethod := ApplyMethod::Payment;
                    end else
                        if "Account No." = '' then
                            FieldError("Account No.", Text004)
                        else
                            FieldError("Bal. Account No.", Text004);

                    Clear(CheckToAddr);
                    Clear(SalesPurchPerson);
                    case BalancingType of
                        BalancingType::"G/L Account":
                            begin
                                CheckToAddr[1] := Description;
                                ChkTransMgt.SetCheckPrintParams(
                                  BankAcc2."Check Date Format",
                                  BankAcc2."Check Date Separator",
                                  BankAcc2."Country/Region Code",
                                  BankAcc2."Bank Communication",
                                  CheckToAddr[1],
                                  CheckDateFormat,
                                  DateSeparator,
                                  CheckLanguage,
                                  CheckStyle);
                            end;
                        BalancingType::Customer:
                            begin
                                Cust.Get(BalancingNo);
                                if Cust."Privacy Blocked" then
                                    Error(PrivacyBlockedErr, Cust.TableCaption(), Cust."No.");
                                if Cust.Blocked in [Cust.Blocked::All] then
                                    Error(Text064, Cust.FieldCaption(Blocked), Cust.Blocked, Cust.TableCaption(), Cust."No.");
                                Cust.Contact := '';
                                FormatAddr.Customer(CheckToAddr, Cust);
                                if BankAcc2."Currency Code" <> "Currency Code" then
                                    Error(Text005);
                                if Cust."Salesperson Code" <> '' then
                                    SalesPurchPerson.Get(Cust."Salesperson Code");
                                ChkTransMgt.SetCheckPrintParams(
                                  Cust."Check Date Format",
                                  Cust."Check Date Separator",
                                  BankAcc2."Country/Region Code",
                                  Cust."Bank Communication",
                                  CheckToAddr[1],
                                  CheckDateFormat,
                                  DateSeparator,
                                  CheckLanguage,
                                  CheckStyle);
                            end;
                        BalancingType::Vendor:
                            begin
                                Vend.Get(BalancingNo);
                                if Vend."Privacy Blocked" then
                                    Error(PrivacyBlockedErr, Vend.TableCaption(), Vend."No.");
                                if Vend.Blocked in [Vend.Blocked::All, Vend.Blocked::Payment] then
                                    Error(Text064, Vend.FieldCaption(Blocked), Vend.Blocked, Vend.TableCaption(), Vend."No.");
                                Vend.Contact := '';
                                if GenJnlLine."Remit-to Code" = '' then
                                    FormatAddr.Vendor(CheckToAddr, Vend)
                                else begin
                                    RemitAddress.Get(GenJnlLine."Remit-to Code", GenJnlLine."Account No.");
                                    FormatAddr.VendorRemitToAddress(RemitAddress, CheckToAddr);
                                end;
                                if BankAcc2."Currency Code" <> "Currency Code" then
                                    Error(Text005);
                                if Vend."Purchaser Code" <> '' then
                                    SalesPurchPerson.Get(Vend."Purchaser Code");
                                ChkTransMgt.SetCheckPrintParams(
                                  Vend."Check Date Format",
                                  Vend."Check Date Separator",
                                  BankAcc2."Country/Region Code",
                                  Vend."Bank Communication",
                                  CheckToAddr[1],
                                  CheckDateFormat,
                                  DateSeparator,
                                  CheckLanguage,
                                  CheckStyle);
                            end;
                        BalancingType::"Bank Account":
                            begin
                                BankAcc.Get(BalancingNo);
                                BankAcc.TestField(Blocked, false);
                                BankAcc.Contact := '';
                                FormatAddr.BankAcc(CheckToAddr, BankAcc);
                                if BankAcc2."Currency Code" <> BankAcc."Currency Code" then
                                    Error(Text008);
                                if BankAcc."Our Contact Code" <> '' then
                                    SalesPurchPerson.Get(BankAcc."Our Contact Code");
                                ChkTransMgt.SetCheckPrintParams(
                                  BankAcc."Check Date Format",
                                  BankAcc."Check Date Separator",
                                  BankAcc2."Country/Region Code",
                                  BankAcc."Bank Communication",
                                  CheckToAddr[1],
                                  CheckDateFormat,
                                  DateSeparator,
                                  CheckLanguage,
                                  CheckStyle);
                            end;
                        BalancingType::Employee:
                            begin
                                Employee.Get(BalancingNo);
                                if Employee."Privacy Blocked" then
                                    Error(BlockedEmplForCheckErr, Employee."No.");
                                FormatAddr.Employee(CheckToAddr, Employee);
                                if BankAcc2."Currency Code" <> "Currency Code" then
                                    Error(Text005);
                                if Employee."Salespers./Purch. Code" <> '' then
                                    SalesPurchPerson.Get(Employee."Salespers./Purch. Code");
                                ChkTransMgt.SetCheckPrintParams(
                                  BankAcc."Check Date Format",
                                  BankAcc."Check Date Separator",
                                  BankAcc."Country/Region Code",
                                  BankAcc."Bank Communication",
                                  CheckToAddr[1],
                                  CheckDateFormat,
                                  DateSeparator,
                                  CheckLanguage,
                                  CheckStyle);
                            end;
                    end;

                    CheckDateText :=
                      ChkTransMgt.FormatDate("Posting Date", CheckDateFormat, DateSeparator, CheckLanguage, DateIndicator);
                end else begin
                    if ChecksPrinted > 0 then
                        CurrReport.Break();
                    ChkTransMgt.SetCheckPrintParams(
                      BankAcc2."Check Date Format",
                      BankAcc2."Check Date Separator",
                      BankAcc2."Country/Region Code",
                      BankAcc2."Bank Communication",
                      CheckToAddr[1],
                      CheckDateFormat,
                      DateSeparator,
                      CheckLanguage,
                      CheckStyle);
                    BalancingType := BalancingType::Vendor;
                    BalancingNo := Text010;
                    Clear(CheckToAddr);
                    for i := 1 to 5 do
                        CheckToAddr[i] := Text003;
                    Clear(SalesPurchPerson);
                    CheckNoText := Text011;
                    if CheckStyle = CheckStyle::CA then
                        CheckDateText := DateIndicator
                    else
                        CheckDateText := Text010;
                end;

                OnAfterOnAfterGetRecordOfGenJnlLine(GenJnlLine, RemitAddress, CheckToAddr, BalancingType, ApplyMethod, OneCheckPrVendor);
            end;

            trigger OnPreDataItem()
            var
                CompanyInfo: Record "Company Information";
            begin
                Copy(VoidGenJnlLine);
                CompanyInfo.Get();
                if not TestPrint then begin
                    FormatAddr.Company(CompanyAddr, CompanyInfo);
                    BankAcc2.Get(BankAcc2."No.");
                    BankAcc2.TestField(Blocked, false);
                    Copy(VoidGenJnlLine);
                    SetRange("Bank Payment Type", "Bank Payment Type"::"Computer Check");
                    SetRange("Check Printed", false);
                end else begin
                    Clear(CompanyAddr);
                    for i := 1 to 5 do
                        CompanyAddr[i] := Text003;
                end;
                ChecksPrinted := 0;

                SetRange("Account Type", "Account Type"::"Fixed Asset");
                if Find('-') then
                    FieldError("Account Type");
                SetRange("Account Type");
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(BankAccount; BankAcc2."No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Bank Account';
                        TableRelation = "Bank Account";
                        ToolTip = 'Specifies the bank account that the check will be drawn from.';

                        trigger OnValidate()
                        begin
                            if BankAcc2."No." <> '' then begin
                                BankAcc2.Get(BankAcc2."No.");
                                BankAcc2.TestField("Last Check No.");
                                UseCheckNo := BankAcc2."Last Check No.";
                            end;
                        end;
                    }
                    field(UseCheckNo; UseCheckNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Last Check No.';
                        ToolTip = 'Specifies the number of the last check that was issued. If you have entered a number in the Last Check No. field in the Bank Account Card window, the number will appear here when you fill in the Bank Account field.';
                    }
                    field(OneCheckPerVendorPerDocumentNo; OneCheckPrVendor)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'One Check per Vendor per Document No.';
                        MultiLine = true;
                        ToolTip = 'Specifies if only one check is printed per vendor for each document number.';
                    }
                    field(ReprintChecks; ReprintChecks)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Reprint Checks';
                        ToolTip = 'Specifies if checks are printed again if you canceled the printing due to a problem.';
                    }
                    field(TestPrint; TestPrint)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Test Print';
                        ToolTip = 'Specifies if you want to print the checks on blank paper before you print them on check forms.';
                    }
                    field(PreprintedStub; PreprintedStub)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Preprinted Stub';
                        ToolTip = 'Specifies if you use check forms with preprinted stubs.';
                    }
                    field(CommitEachCheck; CommitEachCheck)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Commit Each Check';
                        ToolTip = 'Specifies if you want each check to commit to the database after printing instead of at the end of the print job. This allows you to avoid differences between the data and check stock on networks where the print job is cached.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if BankAcc2."No." <> '' then
                if BankAcc2.Get(BankAcc2."No.") then
                    UseCheckNo := BankAcc2."Last Check No."
                else begin
                    BankAcc2."No." := '';
                    UseCheckNo := '';
                end;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        GenJnlTemplate.Get(VoidGenJnlLine.GetFilter("Journal Template Name"));
        if not GenJnlTemplate."Force Doc. Balance" then
            if not Confirm(USText001, true) then
                Error(USText002);

        PageNo := 0;
    end;

    var
        Text000: Label 'Preview is not allowed.';
        Text001: Label 'Last Check No. must be filled in.';
        Text002: Label 'Filters on %1 and %2 are not allowed.';
        Text003: Label 'XXXXXXXXXXXXXXXX';
        Text004: Label 'must be entered.';
        Text005: Label 'The Bank Account and the General Journal Line must have the same currency.';
        Text008: Label 'Both Bank Accounts must have the same currency.';
        Text010: Label 'XXXXXXXXXX';
        Text011: Label 'XXXX';
        Text013: Label '%1 already exists.';
        Text014: Label 'Check for %1 %2';
        Text016: Label 'In the Check report, One Check per Vendor and Document No.\';
        Text017: Label 'must not be activated when Applies-to ID is specified in the journal lines.';
        Text019: Label 'Total';
        Text020: Label 'The total amount of check %1 is %2. The amount must be positive.';
        Text021: Label 'VOID VOID VOID VOID VOID VOID VOID VOID VOID VOID VOID VOID VOID VOID VOID VOID';
        Text022: Label 'NON-NEGOTIABLE';
        Text023: Label 'Test print';
        Text024: Label 'XXXX.XX';
        Text025: Label 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX';
        Text030: Label ' is already applied to %1 %2 for customer %3.';
        Text031: Label ' is already applied to %1 %2 for vendor %3.';
        SalesPurchPerson: Record "Salesperson/Purchaser";
        GenJnlLine2: Record "Gen. Journal Line";
        GenJnlLine3: Record "Gen. Journal Line";
        Cust: Record Customer;
        Vend: Record Vendor;
        BankAcc: Record "Bank Account";
        BankAcc2: Record "Bank Account";
        CheckLedgEntry: Record "Check Ledger Entry";
        Currency: Record Currency;
        GenJnlTemplate: Record "Gen. Journal Template";
        Employee: Record Employee;
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        RemitAddress: Record "Remit Address";
        FormatAddr: Codeunit "Format Address";
        CheckManagement: Codeunit CheckManagement;
        PrintCheckHelper: Codeunit "Print Check Helper";
        ChkTransMgt: Report "Check Translation Management";
        DocNo: Text[35];
        ExtDocNo: Text[35];
        VoidText: Text[30];
        "TotalLineAmount$": Decimal;
        TotalLineDiscount: Decimal;
        FoundLast: Boolean;
        ReprintChecks: Boolean;
        TestPrint: Boolean;
        FirstPage: Boolean;
        FoundNegative: Boolean;
        CommitEachCheck: Boolean;
        AddedRemainingAmount: Boolean;
        ChecksPrinted: Integer;
        HighestLineNo: Integer;
        TotalText: Text[10];
        DocDate: Date;
        i: Integer;
        CurrencyCode2: Code[10];
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        LineAmount2: Decimal;
        GLSetup: Record "General Ledger Setup";
        Text064: Label '%1 must not be %2 for %3 %4.';
        PrivacyBlockedErr: Label '%1 %2 must not be blocked for privacy.', Comment = '%1 = customer or vendor, %2 = customer or vendor code.';
        Text062: Label 'G/L Account,Customer,Vendor,Bank Account,,,Employee';
        USText001: Label 'Warning:  Checks cannot be financially voided when Force Doc. Balance is set to No in the Journal Template.  Do you want to continue anyway?';
        USText002: Label 'Process cancelled at user request.';
        USText004: Label 'Last Check No. must include at least one digit, so that it can be incremented.';
        DateIndicator: Text[10];
        CheckDateFormat: Option " ","MM DD YYYY","DD MM YYYY","YYYY MM DD";
        CheckStyle: Option ,US,CA;
        CheckLanguage: Integer;
        DateSeparator: Option " ","-",".","/";
        DollarSignBefore: Code[5];
        DollarSignAfter: Code[5];
        PrnChkCompanyAddr: array[2, 8] of Text[50];
        PrnChkCheckToAddr: array[2, 8] of Text[50];
        PrnChkCheckNoText: array[2] of Text[30];
        PrnChkCheckDateText: array[2] of Text[30];
        PrnChkCheckAmountText: array[2] of Text[30];
        PrnChkDescriptionLine: array[2, 2] of Text[80];
        PrnChkVoidText: array[2] of Text[30];
        PrnChkDateIndicator: array[2] of Text[10];
        PrnChkCurrencyCode: array[2] of Code[10];
        USText006: Label 'You cannot use the <blank> %1 option with a Canadian style check. Please check %2 %3.';
        USText007: Label 'You cannot use the Spanish %1 option with a Canadian style check. Please check %2 %3.';
        USText011: Label 'Document No.';
        USText012: Label 'Document Date';
        USText013: Label 'Amount';
        USText014: Label 'Discount';
        USText015: Label 'Net Amount';
        PostingDesc: Text[100];
        USText017: Label 'Posting Description';
        StartingLen: Integer;
        ControlLen: Integer;
        NewLen: Integer;
        CheckStyleIndex: Integer;
        Index: Integer;
        BankCurrencyCode: Text[30];
        BankTransitNo: Text[20];
        BankAccountNo: Text[30];
        PageNo: Integer;
        CheckNoTextCaptionLbl: Label 'Check No.';
        LineAmountCaptionLbl: Label 'Net Amount';
        LineDiscountCaptionLbl: Label 'Discount';
        AmountCaptionLbl: Label 'Amount';
        DocNoCaptionLbl: Label 'Document No.';
        DocDateCaptionLbl: Label 'Document Date';
        Posting_DescriptionCaptionLbl: Label 'Posting Description';
        CheckNoText_Control1480000CaptionLbl: Label 'Check No.';
        AlreadyAppliedToEmployeeErr: Label ' is already applied to %1 %2 for employee %3.', Comment = '%1 = Document type, %2 = Document No., %3 = Employee No.';
        BlockedEmplForCheckErr: Label 'You cannot print check because employee %1 is blocked due to privacy.', Comment = '%1 - Employee no.';

    protected var

        PreprintedStub: Boolean;
        OneCheckPrVendor: Boolean;
        ApplyMethod: Option Payment,OneLineOneEntry,OneLineID,MoreLinesOneEntry;
        BalancingType: Enum "Gen. Journal Account Type";
        CompanyAddr: array[8] of Text[100];
        CheckToAddr: array[8] of Text[100];
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        RemainingAmount: Decimal;
        CurrentLineAmount: Decimal;
        LineAmount: Decimal;
        LineDiscount: Decimal;
        TotalLineAmount: Decimal;
        UseCheckNo: Code[20];
        BalancingNo: Code[20];
        CheckNoText: Text[30];
        CheckDateText: Text[30];
        CheckAmountText: Text[30];
        Stub2LineNo: Integer;
        Stub2DocNo: array[50] of Text[35];
        Stub2DocDate: array[50] of Date;
        Stub2LineAmount: array[50] of Decimal;
        Stub2LineDiscount: array[50] of Decimal;
        Stub2PostingDescription: array[50] of Text[100];
        Stub2DocNoHeader: Text[30];
        Stub2DocDateHeader: Text[30];
        Stub2AmountHeader: Text[30];
        Stub2DiscountHeader: Text[30];
        Stub2NetAmountHeader: Text[30];
        Stub2PostingDescHeader: Text[30];
        DescriptionLine: array[2] of Text[80];

    local procedure CustUpdateAmounts(var CustLedgEntry2: Record "Cust. Ledger Entry"; RemainingAmount2: Decimal)
    begin
        if (ApplyMethod = ApplyMethod::OneLineOneEntry) or
           (ApplyMethod = ApplyMethod::MoreLinesOneEntry)
        then begin
            GenJnlLine3.Reset();
            GenJnlLine3.SetCurrentKey("Account Type", "Account No.", "Applies-to Doc. Type", "Applies-to Doc. No.");
            CheckGLEntriesForCustomers(CustLedgEntry2);
        end;

        DocNo := CustLedgEntry2."Document No.";
        ExtDocNo := CustLedgEntry2."External Document No.";
        DocDate := CustLedgEntry2."Document Date";
        CurrencyCode2 := CustLedgEntry2."Currency Code";
        CustLedgEntry2.CalcFields("Remaining Amount");
        PostingDesc := CustLedgEntry2.Description;

        LineAmount := -(CustLedgEntry2."Remaining Amount" - CustLedgEntry2."Remaining Pmt. Disc. Possible" -
                        CustLedgEntry2."Accepted Payment Tolerance");
        LineAmount2 :=
          Round(
            ExchangeAmt(CustLedgEntry2."Posting Date", GenJnlLine."Currency Code", CurrencyCode2, LineAmount),
            Currency."Amount Rounding Precision");
        if ((((CustLedgEntry2."Document Type" = CustLedgEntry2."Document Type"::Invoice) and
              (LineAmount2 >= RemainingAmount2)) or
             ((CustLedgEntry2."Document Type" = CustLedgEntry2."Document Type"::"Credit Memo") and
              (LineAmount2 <= RemainingAmount2))) and
            (GenJnlLine."Posting Date" <= CustLedgEntry2."Pmt. Discount Date")) or
           CustLedgEntry2."Accepted Pmt. Disc. Tolerance"
        then begin
            LineDiscount := -CustLedgEntry2."Remaining Pmt. Disc. Possible";
            if CustLedgEntry2."Accepted Payment Tolerance" <> 0 then
                LineDiscount := LineDiscount - CustLedgEntry2."Accepted Payment Tolerance";
        end else begin
            if RemainingAmount2 >=
               Round(
                 -(ExchangeAmt(CustLedgEntry2."Posting Date", GenJnlLine."Currency Code", CurrencyCode2,
                     CustLedgEntry2."Remaining Amount")), Currency."Amount Rounding Precision")
            then
                LineAmount2 :=
                  Round(
                    -(ExchangeAmt(CustLedgEntry2."Posting Date", GenJnlLine."Currency Code", CurrencyCode2,
                        CustLedgEntry2."Remaining Amount")), Currency."Amount Rounding Precision")
            else begin
                LineAmount2 := RemainingAmount2;
                LineAmount :=
                  Round(
                    ExchangeAmt(CustLedgEntry2."Posting Date", CurrencyCode2, GenJnlLine."Currency Code",
                      LineAmount2), Currency."Amount Rounding Precision");
            end;
            LineDiscount := 0;
        end;
    end;

    local procedure VendUpdateAmounts(var VendLedgEntry2: Record "Vendor Ledger Entry"; RemainingAmount2: Decimal)
    begin
        if (ApplyMethod = ApplyMethod::OneLineOneEntry) or
           (ApplyMethod = ApplyMethod::MoreLinesOneEntry)
        then begin
            GenJnlLine3.Reset();
            GenJnlLine3.SetCurrentKey("Account Type", "Account No.", "Applies-to Doc. Type", "Applies-to Doc. No.");
            CheckGLEntiresForVendors(VendLedgEntry2);
        end;

        DocNo := VendLedgEntry2."Document No.";
        ExtDocNo := VendLedgEntry2."External Document No.";
        DocNo := ExtDocNo;
        DocDate := VendLedgEntry2."Document Date";
        CurrencyCode2 := VendLedgEntry2."Currency Code";
        PostingDesc := VendLedgEntry2.Description;
        VendLedgEntry2.CalcFields("Remaining Amount");
        LineAmount := -(VendLedgEntry2."Remaining Amount" - VendLedgEntry2."Remaining Pmt. Disc. Possible" -
                        VendLedgEntry2."Accepted Payment Tolerance");

        LineAmount2 :=
          Round(
            ExchangeAmt(VendLedgEntry2."Posting Date", GenJnlLine."Currency Code", CurrencyCode2, LineAmount),
            Currency."Amount Rounding Precision");

        if ((((VendLedgEntry2."Document Type" = VendLedgEntry2."Document Type"::Invoice) and
              (LineAmount2 <= RemainingAmount2)) or
             ((VendLedgEntry2."Document Type" = VendLedgEntry2."Document Type"::"Credit Memo") and
              (LineAmount2 <= RemainingAmount2))) and
            (GenJnlLine."Posting Date" <= VendLedgEntry2."Pmt. Discount Date")) or
           VendLedgEntry2."Accepted Pmt. Disc. Tolerance"
        then begin
            LineDiscount := -VendLedgEntry2."Remaining Pmt. Disc. Possible";
            if VendLedgEntry2."Accepted Payment Tolerance" <> 0 then
                LineDiscount := LineDiscount - VendLedgEntry2."Accepted Payment Tolerance";
        end else begin
            if RemainingAmount2 >=
               Round(
                 -(ExchangeAmt(VendLedgEntry2."Posting Date", GenJnlLine."Currency Code", CurrencyCode2,
                     VendLedgEntry2."Amount to Apply")), Currency."Amount Rounding Precision")
            then begin
                LineAmount2 :=
                  Round(
                    -(ExchangeAmt(VendLedgEntry2."Posting Date", GenJnlLine."Currency Code", CurrencyCode2,
                        VendLedgEntry2."Amount to Apply")), Currency."Amount Rounding Precision");
                LineAmount :=
                  Round(
                    ExchangeAmt(VendLedgEntry2."Posting Date", CurrencyCode2, GenJnlLine."Currency Code",
                      LineAmount2), Currency."Amount Rounding Precision");
            end else begin
                LineAmount2 := RemainingAmount2;
                LineAmount :=
                  Round(
                    ExchangeAmt(VendLedgEntry2."Posting Date", CurrencyCode2, GenJnlLine."Currency Code",
                      LineAmount2), Currency."Amount Rounding Precision");
            end;
            LineDiscount := 0;
        end;
    end;

    local procedure EmployeeUpdateAmounts(var EmployeeLedgerEntry2: Record "Employee Ledger Entry"; RemainingAmount2: Decimal)
    begin
        if (ApplyMethod = ApplyMethod::OneLineOneEntry) or
           (ApplyMethod = ApplyMethod::MoreLinesOneEntry)
        then begin
            GenJnlLine3.Reset();
            GenJnlLine3.SetCurrentKey("Account Type", "Account No.", "Applies-to Doc. Type", "Applies-to Doc. No.");
            CheckGLEntriesForEmployee(EmployeeLedgerEntry2);
        end;

        DocNo := EmployeeLedgerEntry2."Document No.";
        DocDate := EmployeeLedgerEntry2."Posting Date";
        PostingDesc := EmployeeLedgerEntry2.Description;

        CurrencyCode2 := EmployeeLedgerEntry2."Currency Code";
        EmployeeLedgerEntry2.CalcFields("Remaining Amount");

        LineAmount := -EmployeeLedgerEntry2."Remaining Amount";

        LineAmount2 :=
          Round(
            ExchangeAmt(EmployeeLedgerEntry2."Posting Date", GenJnlLine."Currency Code", CurrencyCode2, LineAmount),
            Currency."Amount Rounding Precision");

        if RemainingAmount2 >= Round(-ExchangeAmt(EmployeeLedgerEntry2."Posting Date", GenJnlLine."Currency Code", CurrencyCode2,
               EmployeeLedgerEntry2."Amount to Apply"), Currency."Amount Rounding Precision")
        then begin
            LineAmount2 := Round(-ExchangeAmt(EmployeeLedgerEntry2."Posting Date", GenJnlLine."Currency Code", CurrencyCode2,
                  EmployeeLedgerEntry2."Amount to Apply"), Currency."Amount Rounding Precision");
            LineAmount :=
              Round(
                ExchangeAmt(EmployeeLedgerEntry2."Posting Date", CurrencyCode2, GenJnlLine."Currency Code",
                  LineAmount2), Currency."Amount Rounding Precision");
        end else begin
            LineAmount2 := RemainingAmount2;
            LineAmount :=
              Round(
                ExchangeAmt(EmployeeLedgerEntry2."Posting Date", CurrencyCode2, GenJnlLine."Currency Code",
                  LineAmount2), Currency."Amount Rounding Precision");
        end;
        LineDiscount := 0;
    end;

    procedure InitializeRequest(BankAcc: Code[20]; LastCheckNo: Code[20]; NewOneCheckPrVend: Boolean; NewReprintChecks: Boolean; NewTestPrint: Boolean; NewPreprintedStub: Boolean)
    begin
        if BankAcc <> '' then
            if BankAcc2.Get(BankAcc) then begin
                UseCheckNo := LastCheckNo;
                OneCheckPrVendor := NewOneCheckPrVend;
                ReprintChecks := NewReprintChecks;
                TestPrint := NewTestPrint;
                PreprintedStub := NewPreprintedStub;
            end;
    end;

    procedure ExchangeAmt(PostingDate: Date; CurrencyCode: Code[10]; CurrencyCode2: Code[10]; Amount: Decimal) Amount2: Decimal
    begin
        if (CurrencyCode <> '') and (CurrencyCode2 = '') then
            Amount2 :=
              CurrencyExchangeRate.ExchangeAmtLCYToFCY(
                PostingDate, CurrencyCode, Amount, CurrencyExchangeRate.ExchangeRate(PostingDate, CurrencyCode))
        else
            if (CurrencyCode = '') and (CurrencyCode2 <> '') then
                Amount2 :=
                  CurrencyExchangeRate.ExchangeAmtFCYToLCY(
                    PostingDate, CurrencyCode2, Amount, CurrencyExchangeRate.ExchangeRate(PostingDate, CurrencyCode2))
            else
                if (CurrencyCode <> '') and (CurrencyCode2 <> '') and (CurrencyCode <> CurrencyCode2) then
                    Amount2 := CurrencyExchangeRate.ExchangeAmtFCYToFCY(PostingDate, CurrencyCode2, CurrencyCode, Amount)
                else
                    Amount2 := Amount;
    end;

    local procedure CheckGenJournalBatchAndLineIsApproved(GenJournalLine: Record "Gen. Journal Line"): Boolean
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");
        exit(
          VerifyRecordIdIsApproved(GenJournalBatch.RecordId) or
          VerifyRecordIdIsApproved(GenJournalLine.RecordId));
    end;

    local procedure VerifyRecordIdIsApproved(RecordID: RecordID): Boolean
    var
        ApprovalEntry: Record "Approval Entry";
    begin
        ApprovalEntry.SetRange("Table ID", RecordID.TableNo);
        ApprovalEntry.SetRange("Record ID to Approve", RecordID);
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Approved);
        ApprovalEntry.SetRange("Related to Change", false);
        if ApprovalEntry.IsEmpty() then
            exit(false);

        ApprovalEntry.SetFilter(Status, '%1|%2', ApprovalEntry.Status::Open, ApprovalEntry.Status::Created);
        exit(ApprovalEntry.IsEmpty);
    end;

    local procedure PrintOneLineOneEntryOnAfterGetRecordForCustomer(var CustLedgEntry1: Record "Cust. Ledger Entry")
    begin
        CustLedgEntry1.Reset();
        CustLedgEntry1.SetCurrentKey("Document No.");
        CustLedgEntry1.SetRange("Document Type", GenJnlLine."Applies-to Doc. Type");
        CustLedgEntry1.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
        CustLedgEntry1.SetRange("Customer No.", BalancingNo);
        CustLedgEntry1.Find('-');
        CustUpdateAmounts(CustLedgEntry1, RemainingAmount);
    end;

    local procedure PrintOneLineOneEntryOnAfterGetRecordForVendor(var VendLedgEntry1: Record "Vendor Ledger Entry")
    begin
        VendLedgEntry1.Reset();
        VendLedgEntry1.SetCurrentKey("Document No.");
        VendLedgEntry1.SetRange("Document Type", GenJnlLine."Applies-to Doc. Type");
        VendLedgEntry1.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
        VendLedgEntry1.SetRange("Vendor No.", BalancingNo);
        VendLedgEntry1.Find('-');
        VendUpdateAmounts(VendLedgEntry1, RemainingAmount);
    end;

    local procedure PrintOneLineOneEntryOnAfterGetRecordForEmployee(var EmployeeLedgerEntry1: Record "Employee Ledger Entry")
    begin
        EmployeeLedgerEntry1.Reset();
        EmployeeLedgerEntry1.SetCurrentKey("Document No.");
        EmployeeLedgerEntry1.SetRange("Document Type", GenJnlLine."Applies-to Doc. Type");
        EmployeeLedgerEntry1.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
        EmployeeLedgerEntry1.SetRange("Employee No.", BalancingNo);
        EmployeeLedgerEntry1.FindFirst();
        EmployeeUpdateAmounts(EmployeeLedgerEntry1, RemainingAmount);
    end;

    local procedure CheckGLEntriesForEmployee(var EmployeeLedgerEntry3: Record "Employee Ledger Entry")
    begin
        GenJnlLine3.SetRange("Account Type", GenJnlLine3."Account Type"::Employee);
        GenJnlLine3.SetRange("Account No.", EmployeeLedgerEntry3."Employee No.");
        GenJnlLine3.SetRange("Applies-to Doc. Type", EmployeeLedgerEntry3."Document Type");
        GenJnlLine3.SetRange("Applies-to Doc. No.", EmployeeLedgerEntry3."Document No.");
        if ApplyMethod = ApplyMethod::OneLineOneEntry then
            GenJnlLine3.SetFilter("Line No.", '<>%1', GenJnlLine."Line No.")
        else
            GenJnlLine3.SetFilter("Line No.", '<>%1', GenJnlLine2."Line No.");
        if EmployeeLedgerEntry3."Document Type" <> EmployeeLedgerEntry3."Document Type"::" " then
            if GenJnlLine3.Find('-') then
                GenJnlLine3.FieldError(
                  "Applies-to Doc. No.",
                  StrSubstNo(
                    AlreadyAppliedToEmployeeErr,
                    EmployeeLedgerEntry3."Document Type", EmployeeLedgerEntry3."Document No.",
                    EmployeeLedgerEntry3."Employee No."));
    end;

    local procedure CheckGLEntriesForCustomers(var CustLedgEntry3: Record "Cust. Ledger Entry")
    begin
        GenJnlLine3.SetRange("Account Type", GenJnlLine3."Account Type"::Customer);
        GenJnlLine3.SetRange("Account No.", CustLedgEntry3."Customer No.");
        GenJnlLine3.SetRange("Applies-to Doc. Type", CustLedgEntry3."Document Type");
        GenJnlLine3.SetRange("Applies-to Doc. No.", CustLedgEntry3."Document No.");
        if ApplyMethod = ApplyMethod::OneLineOneEntry then
            GenJnlLine3.SetFilter("Line No.", '<>%1', GenJnlLine."Line No.")
        else
            GenJnlLine3.SetFilter("Line No.", '<>%1', GenJnlLine2."Line No.");
        if CustLedgEntry3."Document Type" <> CustLedgEntry3."Document Type"::" " then
            if GenJnlLine3.Find('-') then
                GenJnlLine3.FieldError(
                  "Applies-to Doc. No.",
                  StrSubstNo(
                    Text030,
                    CustLedgEntry3."Document Type", CustLedgEntry3."Document No.",
                    CustLedgEntry3."Customer No."));
    end;

    local procedure CheckGLEntiresForVendors(var VendLedgEntry3: Record "Vendor Ledger Entry")
    begin
        GenJnlLine3.SetRange("Account Type", GenJnlLine3."Account Type"::Vendor);
        GenJnlLine3.SetRange("Account No.", VendLedgEntry3."Vendor No.");
        GenJnlLine3.SetRange("Applies-to Doc. Type", VendLedgEntry3."Document Type");
        GenJnlLine3.SetRange("Applies-to Doc. No.", VendLedgEntry3."Document No.");
        if ApplyMethod = ApplyMethod::OneLineOneEntry then
            GenJnlLine3.SetFilter("Line No.", '<>%1', GenJnlLine."Line No.")
        else
            GenJnlLine3.SetFilter("Line No.", '<>%1', GenJnlLine2."Line No.");
        if VendLedgEntry3."Document Type" <> VendLedgEntry3."Document Type"::" " then
            if GenJnlLine3.Find('-') then
                GenJnlLine3.FieldError(
                  "Applies-to Doc. No.",
                  StrSubstNo(
                    Text031,
                    VendLedgEntry3."Document Type", VendLedgEntry3."Document No.",
                    VendLedgEntry3."Vendor No."));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIncStrCheckNo(var UseCheckNo: Code[20]; var GenJnlLine: Record "Gen. Journal Line"; var CheckPages: Record Integer; PageNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnPreDataItemOfPrintSettledLoop(var GenJournalLine: Record "Gen. Journal Line"; BalancingType: Enum "Gen. Journal Account Type"; ApplyMethod: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnAfterGetRecordOfPrintCheck(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnAfterGetRecordOfPrintSettledLoop(var GenJournalLine2: Record "Gen. Journal Line"; var TotalLineAmount: Decimal; var CurrentLineAmount: Decimal; var TotalLineDiscount: Decimal; var LineDiscount: Decimal; BalancingType: Enum "Gen. Journal Account Type"; ApplyMethod: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnPreDataItemOfCheckPages(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnAfterGetRecordOfGenJnlLine(GenJournalLine: Record "Gen. Journal Line"; var RemitAddress: Record "Remit Address"; var CheckToAddr: array[8] of Text[100]; BalancingType: Enum "Gen. Journal Account Type"; ApplyMethod: Option; var OneCheckPrVendor: Boolean)
    begin
    end;
}

