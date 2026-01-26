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

/// <summary>
/// Generates formatted check documents with proper alignment and security features.
/// Supports multiple check formats, void processing, and remittance stub generation.
/// </summary>
/// <remarks>
/// Data sources: Gen. Journal Line for check data, Bank Account for routing information.
/// Output formats: RDLC with precise positioning for check stock compatibility.
/// Integrates with CheckManagement codeunit for check numbering and void processing.
/// </remarks>
report 1401 Check
{
    DefaultLayout = RDLC;
#if not CLEAN27
    RDLCLayout = './Bank/Check/CheckGB.rdlc';
#else
    RDLCLayout = './Bank/Check/Check.rdlc';
#endif
    Caption = 'Check';
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
        dataitem(GenJnlLine; "Gen. Journal Line")
        {
            DataItemTableView = sorting("Journal Template Name", "Journal Batch Name", "Posting Date", "Document No.");
#if not CLEAN27
            column(JnlTmplName_GenJnlLine; "Journal Template Name")
            {
            }
            column(JnlBatchName_GenJnlLine; "Journal Batch Name")
            {
            }
#else
            column(JournalTempName_GenJnlLine; "Journal Template Name")
            {
            }
            column(JournalBatchName_GenJnlLine; "Journal Batch Name")
            {
            }
#endif
            column(LineNo_GenJnlLine; "Line No.")
            {
            }
            dataitem(CheckPages; "Integer")
            {
                DataItemTableView = sorting(Number);
                column(CheckToAddr1; CheckToAddr[1])
                {
                }
                column(CheckDateText; CheckDateText)
                {
                }
                column(CheckNoText; CheckNoText)
                {
                }
                column(FirstPage; FirstPage)
                {
                }
                column(PreprintedStub; PreprintedStub)
                {
                }
                column(CheckNoTextCaption; CheckNoTextCaptionLbl)
                {
                }
                dataitem(PrintSettledLoop; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    MaxIteration = 30;
#if not CLEAN27
                    column(TotalLineDiscountLineDisc; TotalLineDiscount - LineDiscount)
                    {
                        AutoFormatExpression = GenJnlLine."Currency Code";
                        AutoFormatType = 1;
                    }
#else
                    column(NetAmount; NetAmount)
                    {
                        AutoFormatExpression = GenJnlLine."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(TotalLineDiscountLineDiscount; TotalLineDiscount - LineDiscount)
                    {
                        AutoFormatExpression = GenJnlLine."Currency Code";
                        AutoFormatType = 1;
                    }
#endif
                    column(TotalLineAmountLineAmount; TotalLineAmount - LineAmount)
                    {
                        AutoFormatExpression = GenJnlLine."Currency Code";
                        AutoFormatType = 1;
                    }
#if CLEAN27
                    column(TotalLineAmountLineAmount2; TotalLineAmount - LineAmount2)
                    {
                        AutoFormatExpression = GenJnlLine."Currency Code";
                        AutoFormatType = 1;
                    }
#endif
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
                    column(LineAmountLineDiscount; LineAmount + LineDiscount)
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
#if CLEAN27
                    column(CurrencyCode2; CurrencyCode2)
                    {
                        AutoFormatExpression = GenJnlLine."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(CurrentLineAmount; CurrentLineAmount)
                    {
                        AutoFormatExpression = GenJnlLine."Currency Code";
                        AutoFormatType = 1;
                    }
#endif
                    column(ExtDocNo; ExtDocNo)
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
#if CLEAN27
                    column(CurrencyCodeCaption; CurrencyCodeCaptionLbl)
                    {
                    }
#endif
                    column(YourDocNoCaption; YourDocNoCaptionLbl)
                    {
                    }
                    column(TransportCaption; TransportCaptionLbl)
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
                                                Error(Text016);
                                            GenJnlLine2.TestField("Check Printed", false);
                                            GenJnlLine2.TestField("Bank Payment Type", GenJnlLine2."Bank Payment Type"::"Computer Check");
                                            if BankAcc2."Currency Code" <> GenJnlLine2."Currency Code" then
                                                Error(Text005);
                                            if GenJnlLine2."Applies-to Doc. No." = '' then begin
                                                DocNo := '';
                                                ExtDocNo := '';
                                                DocDate := 0D;
                                                LineAmount := CurrentLineAmount;
                                                LineDiscount := 0;
                                            end else
                                                case BalancingType of
                                                    BalancingType::"G/L Account":
                                                        begin
                                                            DocNo := GenJnlLine2."Document No.";
                                                            ExtDocNo := GenJnlLine2."External Document No.";
                                                            LineAmount := CurrentLineAmount;
                                                            LineDiscount := 0;
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
                            DocNo := Text010;
                            ExtDocNo := Text010;
                            LineAmount := 0;
                            LineDiscount := 0;
                        end;
                    end;

                    trigger OnPreDataItem()
                    begin
                        if not TestPrint then
                            if FirstPage then begin
                                FoundLast := true;
                                case ApplyMethod of
                                    ApplyMethod::OneLineOneEntry:
                                        FoundLast := false;
                                    ApplyMethod::OneLineID:
                                        case BalancingType of
                                            BalancingType::Customer:
                                                begin
                                                    CustLedgEntry.Reset();
                                                    CustLedgEntry.SetCurrentKey("Customer No.", Open, Positive);
                                                    CustLedgEntry.SetRange("Customer No.", BalancingNo);
                                                    CustLedgEntry.SetRange(Open, true);
                                                    CustLedgEntry.SetRange(Positive, true);
                                                    CustLedgEntry.SetRange("Applies-to ID", GenJnlLine."Applies-to ID");
                                                    FoundLast := not CustLedgEntry.Find('-');
                                                    if FoundLast then begin
                                                        CustLedgEntry.SetRange(Positive, false);
                                                        FoundLast := not CustLedgEntry.Find('-');
                                                        FoundNegative := true;
                                                    end else
                                                        FoundNegative := false;
                                                end;
                                            BalancingType::Vendor:
                                                begin
                                                    VendLedgEntry.Reset();
                                                    VendLedgEntry.SetCurrentKey("Vendor No.", Open, Positive);
                                                    VendLedgEntry.SetRange("Vendor No.", BalancingNo);
                                                    VendLedgEntry.SetRange(Open, true);
                                                    VendLedgEntry.SetRange(Positive, true);
                                                    VendLedgEntry.SetRange("Applies-to ID", GenJnlLine."Applies-to ID");
                                                    FoundLast := not VendLedgEntry.Find('-');
                                                    if FoundLast then begin
                                                        VendLedgEntry.SetRange(Positive, false);
                                                        FoundLast := not VendLedgEntry.Find('-');
                                                        FoundNegative := true;
                                                    end else
                                                        FoundNegative := false;
                                                end;
                                        end;
                                    ApplyMethod::MoreLinesOneEntry:
                                        FoundLast := false;
                                end;
                            end
                            else
                                FoundLast := false;

                        if DocNo = '' then
                            CurrencyCode2 := GenJnlLine."Currency Code";

                        if PreprintedStub then
                            TotalText := ''
                        else
                            TotalText := Text019;

                        if GenJnlLine."Currency Code" <> '' then
                            NetAmount := StrSubstNo(Text063, GenJnlLine."Currency Code")
                        else begin
                            GLSetup.Get();
                            NetAmount := StrSubstNo(Text063, GLSetup."LCY Code");
                        end;
                    end;
                }
                dataitem(PrintCheck; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    MaxIteration = 1;
#if not CLEAN27
                    column(CheckToAddr11; UpperCase(CheckToAddr[1]))
                    {
                    }
#else
                    column(CheckAmountText; CheckAmountText)
                    {
                    }
                    column(CheckDateTextControl2; CheckDateText)
                    {
                    }
                    column(DescriptionLine2; DescriptionLine[2])
                    {
                    }
#endif
                    column(DescriptionLine1; DescriptionLine[1])
                    {
                    }
#if not CLEAN27
                    column(CheckDateText1; CheckDateText)
                    {
                    }
                    column(DescriptionLine2; DescriptionLine[2])
                    {
                    }
                    column(CheckAmountText; CheckAmountText)
                    {
                    }
                    column(VoidText; VoidText)
                    {
                    }
#else
                    column(CheckToAddr1Control7; CheckToAddr[1])
                    {
                    }
                    column(CheckToAddr2; CheckToAddr[2])
                    {
                    }
                    column(CheckToAddr4; CheckToAddr[4])
                    {
                    }
                    column(CheckToAddr3; CheckToAddr[3])
                    {
                    }
                    column(CheckToAddr5; CheckToAddr[5])
                    {
                    }
                    column(CompanyAddr4; CompanyAddr[4])
                    {
                    }
                    column(CompanyAddr8; CompanyAddr[8])
                    {
                    }
                    column(CompanyAddr7; CompanyAddr[7])
                    {
                    }
                    column(CompanyAddr6; CompanyAddr[6])
                    {
                    }
                    column(CompanyAddr5; CompanyAddr[5])
                    {
                    }
                    column(CompanyAddr3; CompanyAddr[3])
                    {
                    }
                    column(CheckNoTextControl21; CheckNoText)
                    {
                    }
                    column(CompanyAddr2; CompanyAddr[2])
                    {
                    }
                    column(CompanyAddr1; CompanyAddr[1])
                    {
                    }
#endif
                    column(TotalLineAmount; TotalLineAmount)
                    {
                        AutoFormatExpression = GenJnlLine."Currency Code";
                        AutoFormatType = 1;
                    }
                    column(TotalText; TotalText)
                    {
                    }
#if CLEAN27
                    column(VoidText; VoidText)
                    {
                    }
#endif

                    trigger OnAfterGetRecord()
                    var
#if CLEAN27
                        Decimals: Decimal;
#endif
                        CheckLedgEntryAmount: Decimal;
                    begin
                        if not TestPrint then begin
                            CheckLedgEntry.Init();
                            CheckLedgEntry."Bank Account No." := BankAcc2."No.";
                            CheckLedgEntry."Posting Date" := GenJnlLine."Posting Date";
                            CheckLedgEntry."Document Type" := GenJnlLine."Document Type";
                            CheckLedgEntry."Document No." := UseCheckNo;
                            CheckLedgEntry.Description := GenJnlLine.Description;
                            CheckLedgEntry."Bank Payment Type" := GenJnlLine."Bank Payment Type";
                            CheckLedgEntry."Bal. Account Type" := BalancingType;
                            CheckLedgEntry."Bal. Account No." := BalancingNo;
                            if FoundLast and AddedRemainingAmount then begin
                                if TotalLineAmount <= 0 then
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
#if not CLEAN27
                                CheckLedgEntryAmount := CheckLedgEntry.Amount;
                                CheckAmountText := Format(CheckLedgEntryAmount, 0, Text1041001);
                                CheckAmountText := DelChr(CheckAmountText, '=', '.');
#else
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
#endif
                                FormatNoText(DescriptionLine, CheckLedgEntry.Amount, BankAcc2."Currency Code");
                                VoidText := '';
                            end else begin
                                Clear(CheckAmountText);
                                Clear(DescriptionLine);
                                TotalText := Text065;
                                DescriptionLine[1] := Text021;
                                DescriptionLine[2] := DescriptionLine[1];
                                VoidText := Text022;
                            end;
                        end else begin
                            CheckLedgEntry.Init();
                            CheckLedgEntry."Bank Account No." := BankAcc2."No.";
                            CheckLedgEntry."Posting Date" := GenJnlLine."Posting Date";
                            CheckLedgEntry."Document No." := UseCheckNo;
                            CheckLedgEntry.Description := Text023;
                            CheckLedgEntry."Bank Payment Type" := GenJnlLine."Bank Payment Type"::"Computer Check";
                            CheckLedgEntry."Entry Status" := CheckLedgEntry."Entry Status"::"Test Print";
                            CheckLedgEntry."Check Date" := GenJnlLine."Posting Date";
                            CheckLedgEntry."Check No." := UseCheckNo;
                            CheckManagement.InsertCheck(CheckLedgEntry, RecordId);

                            CheckAmountText := Text024;
                            DescriptionLine[1] := Text025;
                            DescriptionLine[2] := DescriptionLine[1];
                            VoidText := Text022;
                        end;

                        ChecksPrinted := ChecksPrinted + 1;
                        FirstPage := false;
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if FoundLast and AddedRemainingAmount then
                        CurrReport.Break();

                    UseCheckNo := IncStr(UseCheckNo);
                    if not TestPrint then
                        CheckNoText := UseCheckNo
                    else
                        CheckNoText := Text011;
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

                            OnAfterAssignGenJnlLineDocNoAndAccountType(GenJnlLine3, GenJnlLine."Document No.", ApplyMethod);

                            GenJnlLine3."Check Printed" := true;
                            GenJnlLine3.Modify();
                        end else begin
                            if GenJnlLine2.Find('-') then begin
                                HighestLineNo := GenJnlLine2."Line No.";
                                repeat
                                    RecordRestrictionMgt.CheckRecordHasUsageRestrictions(GenJnlLine2);
                                    if GenJnlLine2."Line No." > HighestLineNo then
                                        HighestLineNo := GenJnlLine2."Line No.";
                                    GenJnlLine3 := GenJnlLine2;
                                    GenJnlLine3.TestField("Posting No. Series", '');
                                    GenJnlLine3."Bal. Account No." := '';
                                    GenJnlLine3."Bank Payment Type" := GenJnlLine3."Bank Payment Type"::" ";
                                    GenJnlLine3."Document No." := UseCheckNo;

                                    OnAfterAssignGenJnlLineDocNoAndAccountType(GenJnlLine3, GenJnlLine."Document No.", ApplyMethod);

                                    GenJnlLine3."Check Printed" := true;
                                    GenJnlLine3.Validate(Amount);
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

                            OnAfterAssignGenJnlLineDocumentNo(GenJnlLine3, GenJnlLine."Document No.");

                            GenJnlLine3."Account Type" := GenJnlLine3."Account Type"::"Bank Account";
                            GenJnlLine3.Validate("Account No.", BankAcc2."No.");
                            if BalancingType <> BalancingType::"G/L Account" then
                                GenJnlLine3.Description := StrSubstNo(Text014, BalancingType, BalancingNo);
                            GenJnlLine3.Validate(Amount, -TotalLineAmount);
                            GenJnlLine3."Bank Payment Type" := GenJnlLine3."Bank Payment Type"::"Computer Check";
                            GenJnlLine3."Check Printed" := true;
                            GenJnlLine3."Source Code" := GenJnlLine."Source Code";
                            GenJnlLine3."Reason Code" := GenJnlLine."Reason Code";
                            GenJnlLine3."Allow Zero-Amount Posting" := true;
                            GenJnlLine3.Insert();
                            if CheckGenJournalBatchAndLineIsApproved(GenJnlLine) then
                                RecordRestrictionMgt.AllowRecordUsage(GenJnlLine3);
                        end;
                    end;

                    if not TestPrint then begin
                        BankAcc2."Last Check No." := UseCheckNo;
                        BankAcc2.Modify();
                    end;

                    Clear(CheckManagement);
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
            var
                RemitAddress: Record "Remit Address";
            begin
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
                            GenJnlLine2.SetCurrentKey("Journal Template Name", "Journal Batch Name", "Posting Date", "Document No.", "Remit-to Code");
                            GenJnlLine2.SetRange("Journal Template Name", "Journal Template Name");
                            GenJnlLine2.SetRange("Journal Batch Name", "Journal Batch Name");
                            GenJnlLine2.SetRange("Posting Date", "Posting Date");
                            GenJnlLine2.SetRange("Document No.", "Document No.");
                            GenJnlLine2.SetRange("Account Type", "Account Type");
                            GenJnlLine2.SetRange("Account No.", "Account No.");
                            GenJnlLine2.SetRange("Bal. Account Type", "Bal. Account Type");
                            GenJnlLine2.SetRange("Bal. Account No.", "Bal. Account No.");
                            GenJnlLine2.SetRange("Bank Payment Type", "Bank Payment Type");
                            GenJnlLine2.SetRange("Remit-to Code", "Remit-to Code");
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
                            CheckToAddr[1] := Description;
                        BalancingType::Customer:
                            begin
                                Cust.Get(BalancingNo);
                                if Cust."Privacy Blocked" then
                                    Error(Cust.GetPrivacyBlockedGenericErrorText(Cust));

                                if Cust.Blocked = Cust.Blocked::All then
                                    Error(Text064, Cust.FieldCaption(Blocked), Cust.Blocked, Cust.TableCaption(), Cust."No.");
                                Cust.Contact := '';
                                FormatAddr.Customer(CheckToAddr, Cust);
                                if BankAcc2."Currency Code" <> "Currency Code" then
                                    Error(Text005);
                                if Cust."Salesperson Code" <> '' then
                                    SalesPurchPerson.Get(Cust."Salesperson Code");
                            end;
                        BalancingType::Vendor:
                            begin
                                Vend.Get(BalancingNo);
                                if Vend."Privacy Blocked" then
                                    Error(Vend.GetPrivacyBlockedGenericErrorText(Vend));

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
                                OnGenJnlLineOnAfterGetRecordOnAfterBalancingTypeVendorCase(Vend, GenJnlLine);
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
                            end;
                        BalancingType::Employee:
#if not CLEAN27
                            ApplyBalancingTypeOfEmployee();
                    end;

                    if StrLen(CheckToAddr[1]) < MaxStrLen(CheckToAddr[1]) then
                        CheckToAddr[1] := CheckToAddr[1] + ' ';
                    CheckToAddr[1] := PadStr(CheckToAddr[1], MaxStrLen(CheckToAddr[1]), '*');

                    CheckDateText := Format("Posting Date", 9, Text1041000);
                    CheckDateText := UpperCase(CheckDateText);
#else
                            begin
                                Employee.Get(BalancingNo);
                                if Employee."Privacy Blocked" then
                                    Error(BlockedEmplForCheckErr, Employee."No.");
                                FormatAddr.Employee(CheckToAddr, Employee);
                                if BankAcc2."Currency Code" <> "Currency Code" then
                                    Error(Text005);
                                if Employee."Salespers./Purch. Code" <> '' then
                                    SalesPurchPerson.Get(Employee."Salespers./Purch. Code");
                            end
                    end;

                    CheckDateText := Format("Posting Date", 0, 4);
#endif
                end else begin
                    if ChecksPrinted > 0 then
                        CurrReport.Break();
                    BalancingType := BalancingType::Vendor;
                    BalancingNo := Text010;
                    Clear(CheckToAddr);
                    for i := 1 to 5 do
                        CheckToAddr[i] := Text003;
                    Clear(SalesPurchPerson);
                    CheckNoText := Text011;
                    CheckDateText := Text012;
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
                        ToolTip = 'Specifies the bank account that the printed checks will be drawn from.';

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
                    field(PreprintedStub; PreprintedStub)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Preprinted Stub';
                        ToolTip = 'Specifies if you use check forms with preprinted stubs.';
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
        InitTextVariable();
    end;

    var
        CompanyInfo: Record "Company Information";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        SalesPurchPerson: Record "Salesperson/Purchaser";
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
        GLSetup: Record "General Ledger Setup";
        Employee: Record Employee;
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        FormatAddr: Codeunit "Format Address";
        CheckManagement: Codeunit CheckManagement;
        CompanyAddr: array[8] of Text[100];
        CheckToAddr: array[8] of Text[100];
        OnesText: array[20] of Text[30];
        TensText: array[10] of Text[30];
        ExponentText: array[5] of Text[30];
        BalancingType: Enum "Gen. Journal Account Type";
        BalancingNo: Code[20];
        CheckNoText: Text[30];
        CheckDateText: Text[30];
        CheckAmountText: Text[30];
        DescriptionLine: array[2] of Text[80];
        DocNo: Text[30];
        ExtDocNo: Text[35];
        VoidText: Text[30];
        LineAmount: Decimal;
        LineDiscount: Decimal;
        TotalLineAmount: Decimal;
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
        AddedRemainingAmount: Boolean;
        ApplyMethod: Option Payment,OneLineOneEntry,OneLineID,MoreLinesOneEntry;
        ChecksPrinted: Integer;
        HighestLineNo: Integer;
        PreprintedStub: Boolean;
        TotalText: Text[10];
        DocDate: Date;
        JournalPostingDate: Date;
        i: Integer;
        CurrencyCode2: Code[10];
        NetAmount: Text[30];
        LineAmount2: Decimal;

#pragma warning disable AA0074
        Text000: Label 'Preview is not allowed.';
        Text001: Label 'Last Check No. must be filled in.';
#pragma warning disable AA0470
        Text002: Label 'Filters on %1 and %2 are not allowed.';
#pragma warning restore AA0470
        Text003: Label 'XXXXXXXXXXXXXXXX';
        Text004: Label 'must be entered.';
        Text005: Label 'The Bank Account and the General Journal Line must have the same currency.';
        Text008: Label 'Both Bank Accounts must have the same currency.';
        Text010: Label 'XXXXXXXXXX';
        Text011: Label 'XXXX';
        Text012: Label 'XX.XXXXXXXXXX.XXXX';
#pragma warning disable AA0470
        Text013: Label '%1 already exists.';
        Text014: Label 'Check for %1 %2';
#pragma warning restore AA0470
        Text016: Label 'In the Check report, One Check per Vendor and Document No.\must not be activated when Applies-to ID is specified in the journal lines.';
        Text019: Label 'Total';
#pragma warning disable AA0470
        Text020: Label 'The total amount of check %1 is %2. The amount must be positive.';
#pragma warning restore AA0470
        Text021: Label 'VOID VOID VOID VOID VOID VOID VOID VOID VOID VOID VOID VOID VOID VOID VOID VOID';
        Text022: Label 'NON-NEGOTIABLE';
        Text023: Label 'Test print';
        Text024: Label 'XXXX.XX';
        Text025: Label 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX';
        Text026: Label 'ZERO';
        Text027: Label 'HUNDRED';
#if CLEAN27
        Text028: Label 'AND';
#endif
#pragma warning disable AA0470
        Text029: Label '%1 results in a written number that is too long.';
        Text030: Label ' is already applied to %1 %2 for customer %3.';
        Text031: Label ' is already applied to %1 %2 for vendor %3.';
#pragma warning restore AA0470
        Text032: Label 'ONE';
        Text033: Label 'TWO';
        Text034: Label 'THREE';
        Text035: Label 'FOUR';
        Text036: Label 'FIVE';
        Text037: Label 'SIX';
        Text038: Label 'SEVEN';
        Text039: Label 'EIGHT';
        Text040: Label 'NINE';
        Text041: Label 'TEN';
        Text042: Label 'ELEVEN';
        Text043: Label 'TWELVE';
        Text044: Label 'THIRTEEN';
        Text045: Label 'FOURTEEN';
        Text046: Label 'FIFTEEN';
        Text047: Label 'SIXTEEN';
        Text048: Label 'SEVENTEEN';
        Text049: Label 'EIGHTEEN';
        Text050: Label 'NINETEEN';
        Text051: Label 'TWENTY';
        Text052: Label 'THIRTY';
        Text053: Label 'FORTY';
        Text054: Label 'FIFTY';
        Text055: Label 'SIXTY';
        Text056: Label 'SEVENTY';
        Text057: Label 'EIGHTY';
        Text058: Label 'NINETY';
        Text059: Label 'THOUSAND';
        Text060: Label 'MILLION';
        Text061: Label 'BILLION';
#pragma warning disable AA0470
        Text063: Label 'Net Amount %1';
        Text064: Label '%1 must not be %2 for %3 %4.';
#pragma warning restore AA0470
        Text065: Label 'Subtotal';
#if not CLEAN27
        Text1041000: Label '<Day,2><Month Text,3><Year4>', Locked = true;
        Text1041001: Label '**<Sign><Integer>-<Decimals,3>**', Locked = true;
#endif
#pragma warning restore AA0074
        CheckNoTextCaptionLbl: Label 'Check No.';
        LineAmountCaptionLbl: Label 'Net Amount';
        LineDiscountCaptionLbl: Label 'Discount';
        AmountCaptionLbl: Label 'Amount';
        DocNoCaptionLbl: Label 'Document No.';
        DocDateCaptionLbl: Label 'Document Date';
#if CLEAN27
        CurrencyCodeCaptionLbl: Label 'Currency Code';
#endif
        YourDocNoCaptionLbl: Label 'Your Doc. No.';
        TransportCaptionLbl: Label 'Transport';
        BlockedEmplForCheckErr: Label 'You cannot print check because employee %1 is blocked due to privacy.', Comment = '%1 - Employee no.';
        AlreadyAppliedToEmployeeErr: Label ' is already applied to %1 %2 for employee %3.', Comment = '%1 = Document type, %2 = Document No., %3 = Employee No.';

    /// <summary>
    /// Formats numeric amounts into written text for check printing.
    /// </summary>
    /// <param name="NoText">Array to store the formatted text output</param>
    /// <param name="No">Decimal amount to convert to text</param>
    /// <param name="CurrencyCode">Currency code for proper text formatting</param>
    procedure FormatNoText(var NoText: array[2] of Text[80]; No: Decimal; CurrencyCode: Code[10])
    var
        PrintExponent: Boolean;
        Ones: Integer;
        Tens: Integer;
        Hundreds: Integer;
        Exponent: Integer;
        NoTextIndex: Integer;
#if CLEAN27
        DecimalPosition: Decimal;
#endif
    begin
        Clear(NoText);
        NoTextIndex := 1;
        NoText[1] := '****';
#if CLEAN27
        GLSetup.Get();
#endif

        if No < 1 then
            AddToNoText(NoText, NoTextIndex, PrintExponent, Text026)
        else
#if not CLEAN27
        begin
#endif
            for Exponent := 4 downto 1 do begin
                PrintExponent := false;
                Ones := No div Power(1000, Exponent - 1);
                Hundreds := Ones div 100;
                Tens := (Ones mod 100) div 10;
                Ones := Ones mod 10;
                if Hundreds > 0 then begin
                    AddToNoText(NoText, NoTextIndex, PrintExponent, OnesText[Hundreds]);
                    AddToNoText(NoText, NoTextIndex, PrintExponent, Text027);
                end;
#if not CLEAN27
                if ((Tens > 0) or (Ones > 0)) and (Hundreds > 0) then
                    AddToNoText(NoText, NoTextIndex, PrintExponent, 'AND');
#endif
                if Tens >= 2 then begin
                    AddToNoText(NoText, NoTextIndex, PrintExponent, TensText[Tens]);
                    if Ones > 0 then
                        AddToNoText(NoText, NoTextIndex, PrintExponent, OnesText[Ones]);
                end else
                    if (Tens * 10 + Ones) > 0 then
                        AddToNoText(NoText, NoTextIndex, PrintExponent, OnesText[Tens * 10 + Ones]);
                if PrintExponent and (Exponent > 1) then
                    AddToNoText(NoText, NoTextIndex, PrintExponent, ExponentText[Exponent]);
                No := No - (Hundreds * 100 + Tens * 10 + Ones) * Power(1000, Exponent - 1);
            end;
#if not CLEAN27
            AddToNoText(NoText, NoTextIndex, PrintExponent, 'POUNDS');
        end;

        if No > 0 then
            AddToNoText(NoText, NoTextIndex, PrintExponent, Format(No * 100) + 'P**')
        else
            AddToNoText(NoText, NoTextIndex, PrintExponent, 'ONLY**');
#else
        AddToNoText(NoText, NoTextIndex, PrintExponent, Text028);
        DecimalPosition := GetAmtDecimalPosition();
        AddToNoText(NoText, NoTextIndex, PrintExponent, (Format(No * DecimalPosition) + '/' + Format(DecimalPosition)));
#endif
        if CurrencyCode <> '' then
            AddToNoText(NoText, NoTextIndex, PrintExponent, CurrencyCode);

        OnAfterFormatNoText(NoText, No, CurrencyCode);
    end;

    local procedure AddToNoText(var NoText: array[2] of Text[80]; var NoTextIndex: Integer; var PrintExponent: Boolean; AddText: Text[30])
    begin
        PrintExponent := true;

        while StrLen(NoText[NoTextIndex] + ' ' + AddText) > MaxStrLen(NoText[1]) do begin
            NoTextIndex := NoTextIndex + 1;
            if NoTextIndex > ArrayLen(NoText) then
                Error(Text029, AddText);
        end;

        NoText[NoTextIndex] := DelChr(NoText[NoTextIndex] + ' ' + AddText, '<');
    end;

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
        DocDate := CustLedgEntry2."Posting Date";
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
                LineAmount := Round(ExchangeAmt(CurrencyCode2, GenJnlLine."Currency Code", LineAmount2), Currency."Amount Rounding Precision");
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
        DocDate := VendLedgEntry2."Posting Date";
        CurrencyCode2 := VendLedgEntry2."Currency Code";
        VendLedgEntry2.CalcFields("Remaining Amount");

        LineAmount :=
          -ABSMin(
            VendLedgEntry2."Remaining Amount" -
            VendLedgEntry2."Remaining Pmt. Disc. Possible" -
            VendLedgEntry2."Accepted Payment Tolerance",
            VendLedgEntry2."Amount to Apply");

        LineAmount2 :=
          Round(ExchangeAmt(GenJnlLine."Currency Code", CurrencyCode2, LineAmount), Currency."Amount Rounding Precision");

        if ((VendLedgEntry2."Document Type" in [VendLedgEntry2."Document Type"::Invoice,
                                                VendLedgEntry2."Document Type"::"Credit Memo"]) and
            (VendLedgEntry2."Remaining Pmt. Disc. Possible" <> 0) and
            (GenJnlLine."Posting Date" <= VendLedgEntry2."Pmt. Discount Date")) or
           VendLedgEntry2."Accepted Pmt. Disc. Tolerance"
        then begin
            LineDiscount := -VendLedgEntry2."Remaining Pmt. Disc. Possible";
            if VendLedgEntry2."Accepted Payment Tolerance" <> 0 then
                LineDiscount := LineDiscount - VendLedgEntry2."Accepted Payment Tolerance";
        end else begin
            LineAmount2 :=
              Round(
                -ExchangeAmt(
                  GenJnlLine."Currency Code", CurrencyCode2, VendLedgEntry2."Amount to Apply"), Currency."Amount Rounding Precision");

            if ApplyMethod <> ApplyMethod::OneLineID then
                if Abs(RemainingAmount2) < Abs(LineAmount2) then
                    LineAmount2 := RemainingAmount2;

            LineAmount :=
              Round(ExchangeAmt(CurrencyCode2, GenJnlLine."Currency Code", LineAmount2), Currency."Amount Rounding Precision");

            LineDiscount := 0;
        end;

        OnAfterVendUpdateAmounts(VendLedgEntry2, DocDate);
    end;

    local procedure EmployeeUpdateAmounts(var EmployeeLedgerEntry2: Record "Employee Ledger Entry"; RemainingAmount2: Decimal)
    var
        AmountToApply: Decimal;
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

        CurrencyCode2 := EmployeeLedgerEntry2."Currency Code";
        EmployeeLedgerEntry2.CalcFields("Remaining Amount");

        LineAmount := -EmployeeLedgerEntry2."Remaining Amount";

        LineAmount2 :=
          Round(ExchangeAmt(GenJnlLine."Currency Code", CurrencyCode2, LineAmount), Currency."Amount Rounding Precision");
        AmountToApply :=
          Round(-ExchangeAmt(
              GenJnlLine."Currency Code", CurrencyCode2, EmployeeLedgerEntry2."Amount to Apply"), Currency."Amount Rounding Precision");
        if (RemainingAmount2 >= AmountToApply) and (RemainingAmount2 > 0) then
            LineAmount2 := AmountToApply
        else
            LineAmount2 := RemainingAmount2;
        LineAmount :=
          Round(
            ExchangeAmt(CurrencyCode2, GenJnlLine."Currency Code", LineAmount2), Currency."Amount Rounding Precision");
        LineDiscount := 0;
    end;

    /// <summary>
    /// Initializes text variables for number-to-text conversion.
    /// </summary>
    procedure InitTextVariable()
    begin
        OnesText[1] := Text032;
        OnesText[2] := Text033;
        OnesText[3] := Text034;
        OnesText[4] := Text035;
        OnesText[5] := Text036;
        OnesText[6] := Text037;
        OnesText[7] := Text038;
        OnesText[8] := Text039;
        OnesText[9] := Text040;
        OnesText[10] := Text041;
        OnesText[11] := Text042;
        OnesText[12] := Text043;
        OnesText[13] := Text044;
        OnesText[14] := Text045;
        OnesText[15] := Text046;
        OnesText[16] := Text047;
        OnesText[17] := Text048;
        OnesText[18] := Text049;
        OnesText[19] := Text050;

        TensText[1] := '';
        TensText[2] := Text051;
        TensText[3] := Text052;
        TensText[4] := Text053;
        TensText[5] := Text054;
        TensText[6] := Text055;
        TensText[7] := Text056;
        TensText[8] := Text057;
        TensText[9] := Text058;

        ExponentText[1] := '';
        ExponentText[2] := Text059;
        ExponentText[3] := Text060;
        ExponentText[4] := Text061;
    end;

    /// <summary>
    /// Initializes request parameters for check printing operation.
    /// </summary>
    /// <param name="BankAcc">Bank account code to use for check printing</param>
    /// <param name="LastCheckNo">Last check number for numbering sequence</param>
    /// <param name="NewOneCheckPrVend">Whether to print one check per vendor</param>
    /// <param name="NewReprintChecks">Whether to reprint existing checks</param>
    /// <param name="NewTestPrint">Whether this is a test print operation</param>
    /// <param name="NewPreprintedStub">Whether to use preprinted check stubs</param>
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

    /// <summary>
    /// Validates and retrieves bank account information for check processing.
    /// </summary>
    procedure InputBankAccount()
    begin
        if BankAcc2."No." <> '' then begin
            BankAcc2.Get(BankAcc2."No.");
            BankAcc2.TestField("Last Check No.");
            UseCheckNo := BankAcc2."Last Check No.";
        end;
    end;

#if CLEAN27
    local procedure GetAmtDecimalPosition(): Decimal
    var
        Currency: Record Currency;
    begin
        if GenJnlLine."Currency Code" = '' then
            Currency.InitRoundingPrecision()
        else begin
            Currency.Get(GenJnlLine."Currency Code");
            Currency.TestField("Amount Rounding Precision");
        end;
        exit(1 / Currency."Amount Rounding Precision");
    end;
#endif

    local procedure CheckGenJournalBatchAndLineIsApproved(GenJournalLine: Record "Gen. Journal Line"): Boolean
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");
        exit(
          VerifyRecordIdIsApproved(DATABASE::"Gen. Journal Batch", GenJournalBatch.RecordId) or
          VerifyRecordIdIsApproved(DATABASE::"Gen. Journal Line", GenJournalLine.RecordId));
    end;

    local procedure VerifyRecordIdIsApproved(TableNo: Integer; RecordId: RecordID): Boolean
    var
        ApprovalEntry: Record "Approval Entry";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        ApprovalEntry.SetRange("Table ID", TableNo);
        ApprovalEntry.SetRange("Record ID to Approve", RecordId);
        ApprovalEntry.SetRange(Status, ApprovalEntry.Status::Approved);
        ApprovalEntry.SetRange("Related to Change", false);
        if ApprovalEntry.IsEmpty() then
            exit(false);
        exit(not ApprovalsMgmt.HasOpenOrPendingApprovalEntries(RecordId));
    end;

    local procedure PrintOneLineOneEntryOnAfterGetRecordForCustomer(CustLedgEntry1: Record "Cust. Ledger Entry")
    begin
        CustLedgEntry1.Reset();
        CustLedgEntry1.SetCurrentKey("Document No.");
        CustLedgEntry1.SetRange("Document Type", GenJnlLine."Applies-to Doc. Type");
        CustLedgEntry1.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
        CustLedgEntry1.SetRange("Customer No.", BalancingNo);
        CustLedgEntry1.FindFirst();
        CustUpdateAmounts(CustLedgEntry1, RemainingAmount);
    end;

    local procedure PrintOneLineOneEntryOnAfterGetRecordForVendor(VendLedgEntry1: Record "Vendor Ledger Entry")
    begin
        VendLedgEntry1.Reset();
        VendLedgEntry1.SetCurrentKey("Document No.");
        VendLedgEntry1.SetRange("Document Type", GenJnlLine."Applies-to Doc. Type");
        VendLedgEntry1.SetRange("Document No.", GenJnlLine."Applies-to Doc. No.");
        VendLedgEntry1.SetRange("Vendor No.", BalancingNo);
        VendLedgEntry1.FindFirst();
        VendUpdateAmounts(VendLedgEntry1, RemainingAmount);
    end;

    local procedure PrintOneLineOneEntryOnAfterGetRecordForEmployee(EmployeeLedgerEntry1: Record "Employee Ledger Entry")
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
                    AlreadyAppliedToEmployeeErr, EmployeeLedgerEntry3."Document Type", EmployeeLedgerEntry3."Document No.",
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

#if not CLEAN27
    local procedure ApplyBalancingTypeOfEmployee()
    begin
        Employee.Get(BalancingNo);
        if Employee."Privacy Blocked" then
            Error(BlockedEmplForCheckErr, Employee."No.");
        FormatAddr.Employee(CheckToAddr, Employee);
        if BankAcc2."Currency Code" <> GenJnlLine."Currency Code" then
            Error(Text005);
        if Employee."Salespers./Purch. Code" <> '' then
            SalesPurchPerson.Get(Employee."Salespers./Purch. Code");
    end;
#endif

    /// <summary>
    /// Integration event raised after formatting numeric amount to text for check printing.
    /// Enables custom formatting or modification of the text representation of check amounts.
    /// </summary>
    /// <param name="NoText">Array containing the formatted text representation of the amount</param>
    /// <param name="No">Numeric amount that was formatted</param>
    /// <param name="CurrencyCode">Currency code for the amount</param>
    /// <remarks>
    /// Raised from FormatNoText procedure after converting numeric amount to written text format.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnAfterFormatNoText(var NoText: array[2] of Text[80]; No: Decimal; CurrencyCode: Code[10])
    begin
    end;

    /// <summary>
    /// Integration event raised after updating vendor ledger entry amounts during check processing.
    /// Enables custom processing or field updates after vendor amount calculations.
    /// </summary>
    /// <param name="VendLedgEntry2">Vendor ledger entry with updated amounts</param>
    /// <param name="DocDate">Document date used in processing</param>
    /// <remarks>
    /// Raised from VendUpdateAmounts procedure after calculating and updating vendor payment amounts.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnAfterVendUpdateAmounts(var VendLedgEntry2: Record "Vendor Ledger Entry"; var DocDate: Date)
    begin
    end;

    /// <summary>
    /// Integration event raised after processing vendor record in general journal line context.
    /// Enables custom processing or field updates after vendor data retrieval for balancing account.
    /// </summary>
    /// <param name="Vendor">Vendor record that was processed</param>
    /// <param name="GenJnlLine">General journal line in balancing context</param>
    /// <remarks>
    /// Raised from general journal line processing when balance account type is vendor.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnGenJnlLineOnAfterGetRecordOnAfterBalancingTypeVendorCase(var Vendor: Record Vendor; var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Integration event raised after assigning document number to general journal line.
    /// Enables custom processing or logging after document number assignment.
    /// </summary>
    /// <param name="GenJnlLine">General journal line with assigned document number</param>
    /// <param name="PreviousDocumentNo">Previous document number for reference</param>
    /// <remarks>
    /// Raised from document number assignment logic after setting new document number.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignGenJnlLineDocumentNo(var GenJnlLine: Record "Gen. Journal Line"; PreviousDocumentNo: Code[20])
    begin
    end;

    /// <summary>
    /// Integration event raised after assigning document number and account type to general journal line.
    /// Enables custom processing after document and account type assignment in specific apply methods.
    /// </summary>
    /// <param name="GenJnlLine">General journal line with assigned values</param>
    /// <param name="PreviousDocumentNo">Previous document number for reference</param>
    /// <param name="ApplyMethod">Apply method option used in the assignment</param>
    /// <remarks>
    /// Raised from document and account assignment logic for specific application methods.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignGenJnlLineDocNoAndAccountType(var GenJnlLine: Record "Gen. Journal Line"; PreviousDocumentNo: Code[20]; ApplyMethod: Option)
    begin
    end;
}

