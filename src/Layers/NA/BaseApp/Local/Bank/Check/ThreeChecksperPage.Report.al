// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Check;

using Microsoft.Bank.BankAccount;
using Microsoft.CRM.Team;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.HumanResources.Employee;
using Microsoft.HumanResources.Payables;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using System.Utilities;

report 10413 "Three Checks per Page"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Bank/Check/ThreeChecksperPage.rdlc';
    Caption = 'Three Checks per Page';
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
                    Error(Text000Err);

                if UseCheckNo = '' then
                    Error(Text001Err);

                if IncStr(UseCheckNo) = '' then
                    Error(USText004Err);

                if TestPrint then
                    CurrReport.Break();

                if not ReprintChecks then
                    CurrReport.Break();

                if (GetFilter("Line No.") <> '') or (GetFilter("Document No.") <> '') then
                    Error(
                      Text002Err, FieldCaption("Line No."), FieldCaption("Document No."));
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
                                Error(USText006Err, BankAcc2.FieldCaption("Check Date Format"), BankAcc2.TableCaption(), BankAcc2."No.");
                            if BankAcc2."Bank Communication" = BankAcc2."Bank Communication"::"S Spanish" then
                                Error(USText007Err, BankAcc2.FieldCaption("Bank Communication"), BankAcc2.TableCaption(), BankAcc2."No.");
                        end;
                    "Account Type"::Customer:
                        begin
                            Cust.Get("Account No.");
                            if Cust."Check Date Format" = Cust."Check Date Format"::" " then
                                Error(USText006Err, Cust.FieldCaption("Check Date Format"), Cust.TableCaption(), "Account No.");
                            if Cust."Bank Communication" = Cust."Bank Communication"::"S Spanish" then
                                Error(USText007Err, Cust.FieldCaption("Bank Communication"), Cust.TableCaption(), "Account No.");
                        end;
                    "Account Type"::Vendor:
                        begin
                            Vend.Get("Account No.");
                            if Vend."Check Date Format" = Vend."Check Date Format"::" " then
                                Error(USText006Err, Vend.FieldCaption("Check Date Format"), Vend.TableCaption(), "Account No.");
                            if Vend."Bank Communication" = Vend."Bank Communication"::"S Spanish" then
                                Error(USText007Err, Vend.FieldCaption("Bank Communication"), Vend.TableCaption(), "Account No.");
                        end;
                    "Account Type"::"Bank Account":
                        begin
                            BankAcc.Get("Account No.");
                            if BankAcc."Check Date Format" = BankAcc."Check Date Format"::" " then
                                Error(USText006Err, BankAcc.FieldCaption("Check Date Format"), BankAcc.TableCaption(), "Account No.");
                            if BankAcc."Bank Communication" = BankAcc."Bank Communication"::"S Spanish" then
                                Error(USText007Err, BankAcc.FieldCaption("Bank Communication"), BankAcc.TableCaption(), "Account No.");
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
            column(JnlTemplateName_GenJnlLine; "Journal Template Name")
            {
            }
            column(JnlBatchName_GenJnlLine; "Journal Batch Name")
            {
            }
            column(LineNo_GenJnlLine; "Line No.")
            {
            }
            dataitem(CheckPages; "Integer")
            {
                DataItemTableView = sorting(Number);
                column(CheckToAddr1; CheckToAddr[1])
                {
                }
                column(CheckDateTxt; Format(CheckDateText))
                {
                }
                column(CheckNoTxt; CheckNoText[1])
                {
                }
                column(CheckNoTextCaption; CheckNoTextCaptionLbl)
                {
                }
                dataitem(PrintSettledLoop; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    MaxIteration = 30;
                    column(LineAmt; LineAmount)
                    {
                        AutoFormatExpression = GenJnlLine."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(LineDisc; LineDiscount)
                    {
                        AutoFormatExpression = GenJnlLine."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(LineAmtLineDisc; LineAmount + LineDiscount)
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
                    column(PageNo; PageNo[1])
                    {
                    }
                    column(NetAmount; NetAmountLbl)
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
                    column(PostingDescriptionCaption; PostingDescriptionCaptionLbl)
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
                                    DocDate := 0D;
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
                                        ApplyOneLineOneEntry(BalancingType);
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
                                                Error(Text016Err);
                                            GenJnlLine2.TestField("Check Printed", false);
                                            GenJnlLine2.TestField("Bank Payment Type", GenJnlLine2."Bank Payment Type"::"Computer Check");
                                            if BankAcc2."Currency Code" <> GenJnlLine2."Currency Code" then
                                                Error(Text005Err);
                                            if GenJnlLine2."Applies-to Doc. No." = '' then begin
                                                DocNo := '';
                                                ExtDocNo := '';
                                                DocDate := 0D;
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
                                                            if GenJnlLine2."Source Line No." <> 0 then
                                                                VendLedgEntry.SetRange("Entry No.", GenJnlLine2."Source Line No.")
                                                            else begin
                                                                VendLedgEntry.SetCurrentKey("Document No.");
                                                                VendLedgEntry.SetRange("Document Type", GenJnlLine2."Applies-to Doc. Type");
                                                                VendLedgEntry.SetRange("Document No.", GenJnlLine2."Applies-to Doc. No.");
                                                                VendLedgEntry.SetRange("Vendor No.", BalancingNo);
                                                            end;
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

                            TotalLineAmount := TotalLineAmount + LineAmount2;
                            TotalLineDiscount := TotalLineDiscount + LineDiscount;
                        end else begin
                            if FoundLast then
                                CurrReport.Break();
                            FoundLast := true;
                            DocNo := Text010Lbl;
                            ExtDocNo := Text010Lbl;
                            LineAmount := 0;
                            LineDiscount := 0;
                            PostingDesc := '';
                        end;

                        if DocNo = '' then
                            CurrencyCode2 := GenJnlLine."Currency Code";
                    end;

                    trigger OnPreDataItem()
                    begin
                        PrintCheckHelper.PrintSettledLoopHelper(CustLedgEntry, VendLedgEntry, GenJnlLine, BalancingType.AsInteger(), BalancingNo,
                          FoundLast, TestPrint, FirstPage, FoundNegative, ApplyMethod);

                        if DocNo = '' then
                            CurrencyCode2 := GenJnlLine."Currency Code";

                        TotalText := Text019Lbl;

                        PageNo[CheckIteration] := PageNo[CheckIteration] + 1;
                    end;
                }
                dataitem(PrintCheck; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    MaxIteration = 1;
                    column(PrnChkCheckDateTextCheckStyleUS; PrnChkCheckDateText[CheckStyle::US])
                    {
                    }
                    column(CommentLine1; PrnChkDescriptionLine[CheckStyle::US, 1])
                    {
                    }
                    column(PrnChkCheckToAddrCheckStyleUS2; PrnChkCheckToAddr[CheckStyle::US, 2])
                    {
                    }
                    column(PrnChkCheckToAddrCheckStyleUS3; PrnChkCheckToAddr[CheckStyle::US, 3])
                    {
                    }
                    column(PrnChkCompanyAddrCheckStyleUS4; PrnChkCompanyAddr[CheckStyle::US, 4])
                    {
                    }
                    column(PrnChkCompanyAddrCheckStyleUS5; PrnChkCompanyAddr[CheckStyle::US, 5])
                    {
                    }
                    column(PrnChkCheckNoTextCheckStyleUS; PrnChkCheckNoText[1] [CheckStyle::US])
                    {
                    }
                    column(PrnChkCompanyAddrCheckStyleUS1; PrnChkCompanyAddr[CheckStyle::US, 1])
                    {
                    }
                    column(TotalLineAmount; TotalLineAmount)
                    {
                        AutoFormatExpression = GenJnlLine."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(TotalTxt; TotalText)
                    {
                    }
                    column(PrnChkCompanyAddrCheckStyleCA1; PrnChkCompanyAddr[CheckStyle::CA, 1])
                    {
                    }
                    column(PrnChkCompanyAddrCheckStyleCA3; PrnChkCompanyAddr[CheckStyle::CA, 3])
                    {
                    }
                    column(PrnChkCompanyAddrCheckStyleCA5; PrnChkCompanyAddr[CheckStyle::CA, 5])
                    {
                    }
                    column(PrnChkCommentLineCheckStyleCA1; PrnChkDescriptionLine[CheckStyle::CA, 1])
                    {
                    }
                    column(PrnChkCheckToAddrCheckStyleCA1; PrnChkCheckToAddr[CheckStyle::CA, 1])
                    {
                    }
                    column(PrnChkCheckToAddrCheckStyleCA3; PrnChkCheckToAddr[CheckStyle::CA, 3])
                    {
                    }
                    column(PrnChkCheckToAddrCheckStyleCA5; PrnChkCheckToAddr[CheckStyle::CA, 5])
                    {
                    }
                    column(PrnChkDateIndicatorCheckStyleCA; PrnChkDateIndicator[CheckStyle::CA])
                    {
                    }
                    column(PrnChkVoidTxtCheckStyleCA; PrnChkVoidText[CheckStyle::CA])
                    {
                    }
                    column(PrnChkCurrencyCodeCheckStyleUS; PrnChkCurrencyCode[CheckStyle::US])
                    {
                    }
                    column(CompanyAddr1; CompanyAddr[1])
                    {
                    }
                    column(CompanyAddr2; CompanyAddr[2])
                    {
                    }
                    column(CompanyAddr3; CompanyAddr[3])
                    {
                    }
                    column(CompanyAddr4; CompanyAddr[4])
                    {
                    }
                    column(CompanyAddr5; CompanyAddr[5])
                    {
                    }
                    column(CompanyAddr6; CompanyAddr[6])
                    {
                    }
                    column(CheckNoText_PrintCheck; CheckNoText[1])
                    {
                    }
                    column(CheckDateTxt2; CheckDateText)
                    {
                    }
                    column(DateIndicator; DateIndicator)
                    {
                    }
                    column(CommentLine11; DescriptionLine[1])
                    {
                    }
                    column(CommentLine21; DescriptionLine[2])
                    {
                    }
                    column(CheckAmtTxt; DollarSignBefore + CheckAmountText + DollarSignAfter)
                    {
                    }
                    column(CurrencyCode; BankAcc."Currency Code")
                    {
                    }
                    column(CheckToAddr01; CheckToAddr[1])
                    {
                    }
                    column(CheckToAddr2; CheckToAddr[2])
                    {
                    }
                    column(CheckToAddr3; CheckToAddr[3])
                    {
                    }
                    column(CheckToAddr4; CheckToAddr[4])
                    {
                    }
                    column(CheckToAddr5; CheckToAddr[5])
                    {
                    }
                    column(VoidTxt; VoidText)
                    {
                    }
                    column(CheckStyleIndex; CheckStyleIndex)
                    {
                    }
                    column(BankCurrencyCode; BankCurrencyCode)
                    {
                    }
                    column(PageNo_PrintCheck; PageNo[1])
                    {
                    }
                    column(BPrnChkCheckNoTextCheckStyleUS; PrnChkCheckNoText[2] [CheckStyle::US])
                    {
                    }
                    column(BCheckNoText_PrintCheck; CheckNoText[2])
                    {
                    }
                    column(BPageNo_PrintCheck; PageNo[2])
                    {
                    }
                    column(CPrnChkCheckNoTextCheckStyleUS; PrnChkCheckNoText[3] [CheckStyle::US])
                    {
                    }
                    column(CCheckNoText_PrintCheck; CheckNoText[3])
                    {
                    }
                    column(CPageNo_PrintCheck; PageNo[3])
                    {
                    }
                    column(CheckIteration; CheckIteration)
                    {
                    }

                    trigger OnAfterGetRecord()
                    var
                        Decimals: Decimal;
                        CheckLedgEntryAmount: Decimal;
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
                                if TotalLineAmount <= 0 then
                                    Error(
                                      Text020Err,
                                      UseCheckNo, TotalLineAmount);
                                CheckLedgEntry."Entry Status" := CheckLedgEntry."Entry Status"::Printed;
                                CheckLedgEntry.Amount := TotalLineAmount;
                            end else begin
                                CheckLedgEntry."Entry Status" := CheckLedgEntry."Entry Status"::Voided;
                                CheckLedgEntry.Amount := 0;
                            end;
                            CheckLedgEntry."Check Date" := GenJnlLine."Posting Date";
                            CheckLedgEntry."Check No." := UseCheckNo;
                            CheckManagement.InsertCheck(CheckLedgEntry, RecordId);

                            if FoundLast and AddedRemainingAmount then begin
                                if BankAcc2."Currency Code" <> '' then
                                    Currency.Get(BankAcc2."Currency Code")
                                else
                                    Currency.InitRoundingPrecision();
                                CheckLedgEntryAmount := CheckLedgEntry.Amount;
                                Decimals := CheckLedgEntry.Amount - Round(CheckLedgEntry.Amount, 1, '<');
                                if StrLen(Format(Decimals)) < StrLen(Format(Currency."Amount Rounding Precision")) then
                                    if Decimals = 0 then
                                        CheckAmountText := Format(CheckLedgEntryAmount, 0, 0) +
                                          CopyStr(Format(0.01), 2, 1) +
                                          PadStr('', StrLen(Format(Currency."Amount Rounding Precision")) - 2, '0')
                                    else
                                        CheckAmountText := Format(CheckLedgEntryAmount, 0, 0) +
                                          PadStr('', StrLen(Format(Currency."Amount Rounding Precision")) - StrLen(Format(Decimals)), '0')
                                else
                                    CheckAmountText := Format(CheckLedgEntryAmount, 0, 0);
                                if CheckLanguage = 3084 then begin   // French
                                    DollarSignBefore := '';
                                    DollarSignAfter := CopyStr(Currency.Symbol, 1, 5);
                                end else begin
                                    DollarSignBefore := CopyStr(Currency.Symbol, 1, 5);
                                    DollarSignAfter := ' ';
                                end;
                                if not CheckTranslationManagement.FormatNoText(DescriptionLine, CheckLedgEntry.Amount, CheckLanguage, BankAcc2."Currency Code") then
                                    Error(DescriptionLine[1]);
                                VoidText := '';
                            end else begin
                                Clear(CheckAmountText);
                                Clear(DescriptionLine);
                                TotalText := Text065Lbl;
                                DescriptionLine[1] := Text021Lbl;
                                DescriptionLine[2] := DescriptionLine[1];
                                VoidText := Text022Lbl;
                            end;
                        end else begin
                            CheckLedgEntry.Init();
                            CheckLedgEntry."Bank Account No." := BankAcc2."No.";
                            CheckLedgEntry."Posting Date" := GenJnlLine."Posting Date";
                            CheckLedgEntry."Document No." := UseCheckNo;
                            CheckLedgEntry.Description := Text023Lbl;
                            CheckLedgEntry."Bank Payment Type" := GenJnlLine."Bank Payment Type"::"Computer Check";
                            CheckLedgEntry."Entry Status" := CheckLedgEntry."Entry Status"::"Test Print";
                            CheckLedgEntry."Check Date" := GenJnlLine."Posting Date";
                            CheckLedgEntry."Check No." := UseCheckNo;
                            CheckManagement.InsertCheck(CheckLedgEntry, RecordId);

                            CheckAmountText := Text024Lbl;
                            DescriptionLine[1] := Text025Lbl;
                            DescriptionLine[2] := DescriptionLine[1];
                            VoidText := Text022Lbl;
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
                        PrnChkCheckNoText[CheckIteration] [CheckStyle] := CheckNoText[CheckIteration];
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
                        CheckAmountText := CopyStr(CheckAmountText, 1, 20) + DollarSignBefore + DollarSignAfter;
                        Index := 0;
                        if CheckAmountText = Text024Lbl then
                            if StrLen(CheckAmountText) < (ControlLen - 12) then
                                repeat
                                    Index := Index + 1;
                                    CheckAmountText := InsStr(CheckAmountText, '*', StrLen(CheckAmountText) + 1);
                                until (Index = ControlLen) or (StrLen(CheckAmountText) >= (ControlLen - 12));
                        if CheckAmountText <> Text024Lbl then
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
                          DollarSignBefore + CopyStr(CheckAmountText, 1, 20) + DollarSignAfter;

                        CheckStyleIndex := CheckStyle;
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if FoundLast and AddedRemainingAmount then
                        CurrReport.Break();

                    UseCheckNo := IncStr(UseCheckNo);
                    if not TestPrint then
                        CheckNoText[CheckIteration] := UseCheckNo
                    else
                        CheckNoText[CheckIteration] := Text011Lbl;
                end;

                trigger OnPostDataItem()
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
                                GenJnlLine3.FieldError("Document No.", StrSubstNo(Text013Err, UseCheckNo));
                        end;

                        if ApplyMethod <> ApplyMethod::MoreLinesOneEntry then begin
                            GenJnlLine3 := GenJnlLine;
                            GenJnlLine3.TestField("Posting No. Series", '');
                            GenJnlLine3."Document No." := UseCheckNo;
                            GenJnlLine3."Check Printed" := true;
                            GenJnlLine3.Modify();
                        end else begin
                            TotalLineAmountDollar := 0;
                            if GenJnlLine2.Find('-') then begin
                                HighestLineNo := GenJnlLine2."Line No.";
                                repeat
                                    if BankAcc2."Currency Code" <> GenJnlLine2."Currency Code" then
                                        Error(Text005Err);
                                    if GenJnlLine2."Line No." > HighestLineNo then
                                        HighestLineNo := GenJnlLine2."Line No.";
                                    GenJnlLine3 := GenJnlLine2;
                                    GenJnlLine3.TestField("Posting No. Series", '');
                                    GenJnlLine3."Bal. Account No." := '';
                                    GenJnlLine3."Bank Payment Type" := GenJnlLine3."Bank Payment Type"::" ";
                                    GenJnlLine3."Document No." := UseCheckNo;
                                    GenJnlLine3."Check Printed" := true;
                                    GenJnlLine3.Validate(Amount);
                                    TotalLineAmountDollar := TotalLineAmountDollar + GenJnlLine3."Amount (LCY)";
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
                                GenJnlLine3.Description := StrSubstNo(Text014Lbl, SelectStr(BalancingType.AsInteger() + 1, Text062Lbl), BalancingNo);
                            GenJnlLine3.Validate(Amount, -TotalLineAmount);
                            if TotalLineAmount <> TotalLineAmountDollar then
                                GenJnlLine3.Validate("Amount (LCY)", -TotalLineAmountDollar);
                            GenJnlLine3."Bank Payment Type" := GenJnlLine3."Bank Payment Type"::"Computer Check";
                            GenJnlLine3."Check Printed" := true;
                            GenJnlLine3."Source Code" := GenJnlLine."Source Code";
                            GenJnlLine3."Reason Code" := GenJnlLine."Reason Code";
                            GenJnlLine3."Allow Zero-Amount Posting" := true;
                            GenJnlLine3.Insert();
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
                end;
            }

            trigger OnAfterGetRecord()
            begin
                CheckIteration := CheckIteration + 1;
                if CheckIteration > 3 then
                    CheckIteration := CheckIteration - 3;

                if OneCheckPrVendor and ("Currency Code" <> '') and
                   ("Currency Code" <> Currency.Code)
                then begin
                    Currency.Get("Currency Code");
                    Currency.TestField("Conv. LCY Rndg. Debit Acc.");
                    Currency.TestField("Conv. LCY Rndg. Credit Acc.");
                end;

                JournalPostingDate := "Posting Date";

                if "Bank Payment Type" = "Bank Payment Type"::"Computer Check" then
                    TestField("Exported to Payment File", false);

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
                    end else begin
                        if "Account No." = '' then
                            FieldError("Account No.", Text004Err);
                        if "Account No." <> '' then
                            FieldError("Bal. Account No.", Text004Err);
                    end;

                    Clear(CheckToAddr);
                    Clear(SalespersonPurchaser);
                    case BalancingType of
                        BalancingType::"G/L Account":
                            begin
                                CheckToAddr[1] := Description;
                                CheckTranslationManagement.SetCheckPrintParams(
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
                                    Error(Text064Err, Cust.FieldCaption(Blocked), Cust.Blocked, Cust.TableCaption(), Cust."No.");
                                Cust.Contact := '';
                                FormatAddr.Customer(CheckToAddr, Cust);
                                if BankAcc2."Currency Code" <> "Currency Code" then
                                    Error(Text005Err);
                                if Cust."Salesperson Code" <> '' then
                                    SalespersonPurchaser.Get(Cust."Salesperson Code");
                                CheckTranslationManagement.SetCheckPrintParams(
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
                                    Error(Text064Err, Vend.FieldCaption(Blocked), Vend.Blocked, Vend.TableCaption(), Vend."No.");
                                Vend.Contact := '';
                                FormatAddr.Vendor(CheckToAddr, Vend);
                                if BankAcc2."Currency Code" <> "Currency Code" then
                                    Error(Text005Err);
                                if Vend."Purchaser Code" <> '' then
                                    SalespersonPurchaser.Get(Vend."Purchaser Code");
                                CheckTranslationManagement.SetCheckPrintParams(
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
                                    Error(Text008Err);
                                if BankAcc."Our Contact Code" <> '' then
                                    SalespersonPurchaser.Get(BankAcc."Our Contact Code");
                                CheckTranslationManagement.SetCheckPrintParams(
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
                            ApplyBalancingTypeOfEmployee();
                    end;

                    CheckDateText :=
                      CheckTranslationManagement.FormatDate("Posting Date", CheckDateFormat, DateSeparator, CheckLanguage, DateIndicator);
                end else begin
                    if ChecksPrinted > 2 then
                        CurrReport.Break();
                    CheckTranslationManagement.SetCheckPrintParams(
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
                    BalancingNo := Text010Lbl;
                    Clear(CheckToAddr);
                    for i := 1 to 5 do
                        CheckToAddr[i] := Text003Lbl;
                    Clear(SalespersonPurchaser);
                    CheckNoText[CheckIteration] := Text011Lbl;
                    if CheckStyle = CheckStyle::CA then
                        CheckDateText := DateIndicator
                    else
                        CheckDateText := Text010Lbl;
                end;
            end;

            trigger OnPreDataItem()
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
                        CompanyAddr[i] := Text003Lbl;
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
                            InputBankAccount();
                        end;
                    }
                    field(LastCheckNo; UseCheckNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Last Check No.';
                        ToolTip = 'Specifies the value of the Last Check No. field on the bank account card.';
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
                    field(TestPrinting; TestPrint)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Test Print';
                        ToolTip = 'Specifies if you want to print the checks on blank paper before you print them on check forms.';
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
            if not Confirm(USText001Qst, true) then
                Error(USText002Err);

        PageNo[1] := 0;
        PageNo[2] := 0;
        PageNo[3] := 0;
        CheckIteration := 0;
    end;

    var
        Text000Err: Label 'Preview is not allowed.';
        Text001Err: Label 'Last Check No. must be filled in.';
        Text002Err: Label 'Filters on %1 and %2 are not allowed.', Comment = '%1=Field caption for Line No. field.; %2=Field caption for Document No. field.';
        Text003Lbl: Label 'XXXXXXXXXXXXXXXX', Comment = 'Do not translate.';
        Text004Err: Label 'must be entered';
        Text005Err: Label 'The Bank Account and the General Journal Line must have the same currency.';
        Text008Err: Label 'Both Bank Accounts must have the same currency.';
        Text010Lbl: Label 'XXXXXXXXXX', Comment = 'Do not translate.';
        Text011Lbl: Label 'XXXX', Comment = 'Do not translate.';
        Text013Err: Label '%1 already exists.', Comment = '%1=Check number.';
        Text014Lbl: Label 'Check for %1 %2', Comment = '%1=Balancing account type. %2=Balancing account code.';
        Text016Err: Label 'In the Check report, One Check per Vendor and Document No.\must not be activated when Applies-to ID is specified in the journal lines.';
        Text019Lbl: Label 'Total';
        Text020Err: Label 'The total amount of check %1 is %2. The amount must be positive.', Comment = '%1=The check number.; %2=The total amount of the check.';
        Text021Lbl: Label 'VOID VOID VOID VOID VOID VOID VOID VOID VOID VOID VOID VOID VOID VOID VOID VOID', Comment = 'Translation is acceptable, but keep the capitalization.';
        Text022Lbl: Label 'NON-NEGOTIABLE', Comment = 'Translation is acceptable, but keep the capitalization.';
        Text023Lbl: Label 'Test print';
        Text024Lbl: Label 'XXXX.XX', Comment = 'Do not translate.';
        Text025Lbl: Label 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX', Comment = 'Do not translate.';
        Text030Err: Label ' is already applied to %1 %2 for customer %3.', Comment = '%1=Document Type;%2=Document Number;%3=Customer Number.';
        Text031Err: Label ' is already applied to %1 %2 for vendor %3.', Comment = '%1=Document Type;%2=Document Number;%3=Vendor Number.';
        CompanyInfo: Record "Company Information";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        GenJnlLine2: Record "Gen. Journal Line";
        GenJnlLine3: Record "Gen. Journal Line";
        Cust: Record Customer;
        CustLedgEntry: Record "Cust. Ledger Entry";
        Vend: Record Vendor;
        VendLedgEntry: Record "Vendor Ledger Entry";
        BankAcc: Record "Bank Account";
        BankAcc2: Record "Bank Account";
        CheckLedgEntry: Record "Check Ledger Entry";
        Currency: Record Currency;
        GenJnlTemplate: Record "Gen. Journal Template";
        Employee: Record Employee;
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        CheckTranslationManagement: Report "Check Translation Management";
        PrintCheckHelper: Codeunit "Print Check Helper";
        FormatAddr: Codeunit "Format Address";
        CheckManagement: Codeunit CheckManagement;
        CompanyAddr: array[8] of Text[100];
        CheckToAddr: array[8] of Text[100];
        BalancingType: Enum "Gen. Journal Account Type";
        BalancingNo: Code[20];
        CheckNoText: array[3] of Text[30];
        CheckDateText: Text[30];
        CheckAmountText: Text[30];
        DescriptionLine: array[2] of Text[80];
        DocNo: Text[30];
        ExtDocNo: Text[35];
        VoidText: Text[30];
        LineAmount: Decimal;
        LineDiscount: Decimal;
        TotalLineAmount: Decimal;
        TotalLineAmountDollar: Decimal;
        TotalLineDiscount: Decimal;
        RemainingAmount: Decimal;
        CurrentLineAmount: Decimal;
        UseCheckNo: Code[20];
        FoundLast: Boolean;
        ReprintChecks: Boolean;
        TestPrint: Boolean;
        FirstPage: Boolean;
        OneCheckPrVendor: Boolean;
        FoundNegative: Boolean;
        CommitEachCheck: Boolean;
        AddedRemainingAmount: Boolean;
        ApplyMethod: Option Payment,OneLineOneEntry,OneLineID,MoreLinesOneEntry;
        ChecksPrinted: Integer;
        HighestLineNo: Integer;
        TotalText: Text[10];
        DocDate: Date;
        JournalPostingDate: Date;
        i: Integer;
        CurrencyCode2: Code[10];
        LineAmount2: Decimal;
        Text064Err: Label '%1 must not be %2 for %3 %4.', Comment = '%1=Blocked field caption;%2=Blocked value from Customer table;%3=Caption for Customer table;%4=Customer Number';
        PrivacyBlockedErr: Label '%1 %2 must not be blocked for privacy.', Comment = '%1 = customer or vendor, %2 = customer or vendor code.';
        Text065Lbl: Label 'Subtotal';
        Text062Lbl: Label 'G/L Account,Customer,Vendor,Bank Account,,,Employee';
        USText001Qst: Label 'Warning:  Checks cannot be financially voided when Force Doc. Balance is set to No in the Journal Template.  Do you want to continue anyway?';
        USText002Err: Label 'Process cancelled at user request.';
        USText004Err: Label 'Last Check No. must include at least one digit, so that it can be incremented.';
        DateIndicator: Text[10];
        CheckDateFormat: Option " ","MM DD YYYY","DD MM YYYY","YYYY MM DD";
        CheckStyle: Option ,US,CA;
        CheckLanguage: Integer;
        DateSeparator: Option " ","-",".","/";
        DollarSignBefore: Code[5];
        DollarSignAfter: Code[5];
        PrnChkCompanyAddr: array[2, 8] of Text[50];
        PrnChkCheckToAddr: array[2, 8] of Text[50];
        PrnChkCheckNoText: array[3, 2] of Text[30];
        PrnChkCheckDateText: array[2] of Text[30];
        PrnChkCheckAmountText: array[2] of Text[30];
        PrnChkDescriptionLine: array[2, 2] of Text[80];
        PrnChkVoidText: array[2] of Text[30];
        PrnChkDateIndicator: array[2] of Text[10];
        PrnChkCurrencyCode: array[2] of Code[10];
        USText006Err: Label 'You cannot use the <blank> %1 option with a Canadian style check. Please check %2 %3.', Comment = '%1=Check Date Format field caption;%2=Caption for Bank Account table;%3=Bank Account number.';
        USText007Err: Label 'You cannot use the Spanish %1 option with a Canadian style check. Please check %2 %3.', Comment = '%1=Bank Communication field caption;%2=Caption for Bank Account table;%3=Bank Account number.';
        PostingDesc: Text[100];
        CheckStyleIndex: Integer;
        BankCurrencyCode: Text[30];
        StartingLen: Integer;
        ControlLen: Integer;
        Index: Integer;
        NewLen: Integer;
        PageNo: array[3] of Integer;
        CheckNoTextCaptionLbl: Label 'Check No.';
        NetAmountLbl: Label 'Net Amount';
        LineDiscountCaptionLbl: Label 'Discount';
        AmountCaptionLbl: Label 'Amount';
        DocNoCaptionLbl: Label 'Document No.';
        DocDateCaptionLbl: Label 'Document Date';
        PostingDescriptionCaptionLbl: Label 'Posting Description';
        CheckIteration: Integer;
        AlreadyAppliedToEmployeeErr: Label ' is already applied to %1 %2 for employee %3.', Comment = '%1 = Document type, %2 = Document No., %3 = Employee No.';
        BlockedEmplForCheckErr: Label 'You cannot print check because employee %1 is blocked due to privacy.', Comment = '%1 - Employee no.';

    local procedure CustUpdateAmounts(var CustLedgEntry2: Record "Cust. Ledger Entry"; RemainingAmount2: Decimal)
    var
        AmountToApply: Decimal;
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
        PostingDesc := CustLedgEntry2.Description;
        CurrencyCode2 := CustLedgEntry2."Currency Code";
        CustLedgEntry2.CalcFields("Remaining Amount");

        LineAmount :=
          -ABSMin(
            CustLedgEntry2."Remaining Amount" -
            CustLedgEntry2."Remaining Pmt. Disc. Possible" -
            CustLedgEntry2."Accepted Payment Tolerance",
            CustLedgEntry2."Amount to Apply");
        LineAmount2 :=
          Round(ExchangeAmt(GenJnlLine."Currency Code", CurrencyCode2, LineAmount), Currency."Amount Rounding Precision");

        if ((CustLedgEntry2."Document Type" in [CustLedgEntry2."Document Type"::Invoice,
                                                CustLedgEntry2."Document Type"::"Credit Memo"]) and
            (CustLedgEntry2."Remaining Pmt. Disc. Possible" <> 0) and
            (CustLedgEntry2."Posting Date" <= CustLedgEntry2."Pmt. Discount Date")) or
           CustLedgEntry2."Accepted Pmt. Disc. Tolerance"
        then begin
            LineDiscount := -CustLedgEntry2."Remaining Pmt. Disc. Possible";
            if CustLedgEntry2."Accepted Payment Tolerance" <> 0 then
                LineDiscount := LineDiscount - CustLedgEntry2."Accepted Payment Tolerance";
        end else begin
            AmountToApply :=
              Round(-ExchangeAmt(
                  GenJnlLine."Currency Code", CurrencyCode2, CustLedgEntry2."Amount to Apply"), Currency."Amount Rounding Precision");
            if RemainingAmount2 >= AmountToApply then
                LineAmount2 := AmountToApply
            else begin
                LineAmount2 := RemainingAmount2;
                LineAmount :=
                  Round(
                    ExchangeAmt(CurrencyCode2, GenJnlLine."Currency Code", LineAmount2), Currency."Amount Rounding Precision");
            end;
            LineDiscount := 0;
        end;
    end;

    local procedure VendUpdateAmounts(var VendLedgEntry2: Record "Vendor Ledger Entry"; RemainingAmount2: Decimal)
    var
        AmountToApply: Decimal;
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
        DocNo := CopyStr(ExtDocNo, 1, 30);
        DocDate := VendLedgEntry2."Document Date";

        PostingDesc := VendLedgEntry2.Description;

        CurrencyCode2 := VendLedgEntry2."Currency Code";
        VendLedgEntry2.CalcFields("Remaining Amount");

        LineAmount := -(VendLedgEntry2."Remaining Amount" - VendLedgEntry2."Remaining Pmt. Disc. Possible" -
                        VendLedgEntry2."Accepted Payment Tolerance");

        LineAmount2 :=
          Round(ExchangeAmt(GenJnlLine."Currency Code", CurrencyCode2, LineAmount), Currency."Amount Rounding Precision");

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
            AmountToApply :=
              Round(-ExchangeAmt(
                  GenJnlLine."Currency Code", CurrencyCode2, VendLedgEntry2."Amount to Apply"), Currency."Amount Rounding Precision");
            if (RemainingAmount2 >= AmountToApply) and (RemainingAmount2 > 0) then
                LineAmount2 := AmountToApply
            else
                LineAmount2 := RemainingAmount2;
            LineAmount :=
              Round(
                ExchangeAmt(CurrencyCode2, GenJnlLine."Currency Code", LineAmount2), Currency."Amount Rounding Precision");
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
            ExchangeAmt(GenJnlLine."Currency Code", CurrencyCode2, LineAmount),
            Currency."Amount Rounding Precision");

        if RemainingAmount2 >= Round(-ExchangeAmt(GenJnlLine."Currency Code", CurrencyCode2,
               EmployeeLedgerEntry2."Amount to Apply"), Currency."Amount Rounding Precision")
        then begin
            LineAmount2 := Round(-ExchangeAmt(GenJnlLine."Currency Code", CurrencyCode2,
                  EmployeeLedgerEntry2."Amount to Apply"), Currency."Amount Rounding Precision");
            LineAmount :=
              Round(
                ExchangeAmt(CurrencyCode2, GenJnlLine."Currency Code",
                  LineAmount2), Currency."Amount Rounding Precision");
        end else begin
            LineAmount2 := RemainingAmount2;
            LineAmount :=
              Round(
                ExchangeAmt(CurrencyCode2, GenJnlLine."Currency Code",
                  LineAmount2), Currency."Amount Rounding Precision");
        end;
        LineDiscount := 0;
    end;

    procedure InitializeRequest(BankAcc: Code[20]; LastCheckNo: Code[20]; NewOneCheckPrVend: Boolean; NewReprintChecks: Boolean; NewTestPrint: Boolean)
    begin
        if BankAcc <> '' then
            if BankAcc2.Get(BankAcc) then begin
                UseCheckNo := LastCheckNo;
                OneCheckPrVendor := NewOneCheckPrVend;
                ReprintChecks := NewReprintChecks;
                TestPrint := NewTestPrint;
            end;
    end;

    local procedure ExchangeAmt(CurrencyCode: Code[10]; CurrencyCode2: Code[10]; Amount: Decimal) Amount2: Decimal
    begin
        if (CurrencyCode <> '') and (CurrencyCode2 = '') then
            Amount2 :=
              CurrencyExchangeRate.ExchangeAmtLCYToFCY(
                JournalPostingDate, CurrencyCode, Amount, CurrencyExchangeRate.ExchangeRate(JournalPostingDate, CurrencyCode))
        else
            if (CurrencyCode = '') and (CurrencyCode2 <> '') then
                Amount2 :=
                  CurrencyExchangeRate.ExchangeAmtFCYToLCY(
                    JournalPostingDate, CurrencyCode2, Amount, CurrencyExchangeRate.ExchangeRate(JournalPostingDate, CurrencyCode2))
            else
                if (CurrencyCode <> '') and (CurrencyCode2 <> '') and (CurrencyCode <> CurrencyCode2) then
                    Amount2 := CurrencyExchangeRate.ExchangeAmtFCYToFCY(JournalPostingDate, CurrencyCode2, CurrencyCode, Amount)
                else
                    Amount2 := Amount;
    end;

    local procedure ABSMin(Decimal1: Decimal; Decimal2: Decimal): Decimal
    begin
        if Abs(Decimal1) < Abs(Decimal2) then
            exit(Decimal1);
        exit(Decimal2);
    end;

    procedure InputBankAccount()
    begin
        if BankAcc2."No." <> '' then begin
            BankAcc2.Get(BankAcc2."No.");
            BankAcc2.TestField("Last Check No.");
            UseCheckNo := BankAcc2."Last Check No.";
        end;
    end;

    local procedure UpdateEmployeeLedgEntry(var EmployeeLedgerEntry1: Record "Employee Ledger Entry"; RemainingAmount1: Decimal)
    begin
        EmployeeLedgerEntry1.Reset();
        EmployeeLedgerEntry1.SetCurrentKey("Document No.");
        EmployeeLedgerEntry1.SetRange("Document Type", GenJnlLine."Applies-to Doc. Type");
        EmployeeLedgerEntry1.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
        EmployeeLedgerEntry1.SetRange("Employee No.", BalancingNo);
        EmployeeLedgerEntry1.FindFirst();
        EmployeeUpdateAmounts(EmployeeLedgerEntry1, RemainingAmount1);
    end;

    local procedure ApplyOneLineOneEntry(BalancingType: Enum "Gen. Journal Account Type")
    begin
        case BalancingType of
            BalancingType::Customer:
                UpdateCustLedgEntry(CustLedgEntry, RemainingAmount);
            BalancingType::Vendor:
                UpdateVendLedgEntry(VendLedgEntry, RemainingAmount);
            BalancingType::Employee:
                UpdateEmployeeLedgEntry(EmployeeLedgerEntry, RemainingAmount);
        end;
        RemainingAmount := RemainingAmount - LineAmount2;
        CurrentLineAmount := LineAmount2;
        FoundLast := true;
    end;

    local procedure UpdateCustLedgEntry(var CustLedgEntry: Record "Cust. Ledger Entry"; RemainingAmount: Decimal)
    begin
        CustLedgEntry.Reset();
        CustLedgEntry.SetCurrentKey("Document No.");
        CustLedgEntry.SetRange("Document Type", GenJnlLine."Applies-to Doc. Type");
        CustLedgEntry.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
        CustLedgEntry.SetRange("Customer No.", BalancingNo);
        CustLedgEntry.Find('-');
        CustUpdateAmounts(CustLedgEntry, RemainingAmount);
    end;

    local procedure UpdateVendLedgEntry(var VendLedgEntry: Record "Vendor Ledger Entry"; RemainingAmount: Decimal)
    begin
        VendLedgEntry.Reset();
        VendLedgEntry.SetCurrentKey("Document No.");
        VendLedgEntry.SetRange("Document Type", GenJnlLine."Applies-to Doc. Type");
        VendLedgEntry.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
        VendLedgEntry.SetRange("Vendor No.", BalancingNo);
        VendLedgEntry.Find('-');
        VendUpdateAmounts(VendLedgEntry, RemainingAmount);
    end;

    local procedure ApplyBalancingTypeOfEmployee()
    begin
        Employee.Get(BalancingNo);
        if Employee."Privacy Blocked" then
            Error(BlockedEmplForCheckErr, Employee."No.");
        FormatAddr.Employee(CheckToAddr, Employee);
        if BankAcc2."Currency Code" <> GenJnlLine."Currency Code" then
            Error(Text005Err);
        if Employee."Salespers./Purch. Code" <> '' then
            SalespersonPurchaser.Get(Employee."Salespers./Purch. Code");
        CheckTranslationManagement.SetCheckPrintParams(
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
                    Text030Err,
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
                    Text031Err,
                    VendLedgEntry3."Document Type", VendLedgEntry3."Document No.",
                    VendLedgEntry3."Vendor No."));
    end;
}

