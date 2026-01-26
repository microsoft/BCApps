// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Statement;

using Microsoft.Bank.Payment;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.HumanResources.Payables;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.Receivables;
using System.Utilities;

report 11400 "CBG Posting - Test"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Bank/Statement/CBGPostingTest.rdlc';
    Caption = 'CBG Posting - Test';

    dataset
    {
        dataitem("Gen. Journal Batch"; "Gen. Journal Batch")
        {
        }
        dataitem("CBG Statement"; "CBG Statement")
        {
            DataItemTableView = sorting("Journal Template Name", "No.");
            RequestFilterFields = "Journal Template Name", "No.";
            column(No_CBGStmt; "No.")
            {
            }
            column(AccType_CBGStmt; "Account Type")
            {
            }
            column(AccNo_CBGStmt; "Account No.")
            {
            }
            column(Value1; Value[1])
            {
            }
            column(OpeningBal_CBGStmt; "Opening Balance")
            {
            }
            column(ClosingBal_CBGStmt; "Closing Balance")
            {
            }
            column(Today; Today)
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(Type_CBGStmt; Type)
            {
            }
            column(GetName; GetName())
            {
            }
            column(Label1; Label[1])
            {
            }
            column(Label2; Label[2])
            {
            }
            column(Value2; Value[2])
            {
            }
            column(Label3; Label[3])
            {
            }
            column(Value3; Value[3])
            {
            }
            column(Label4; Label[4])
            {
            }
            column(Value4; Format(Value[4]))
            {
            }
            column(ApplyInformation; ApplyInformation)
            {
            }
            column(ForLayoutDate; Date)
            {
            }
            column(JnlTmpltName_CBGStmt; "Journal Template Name")
            {
            }
            column(NoCaption_CBGStmt; FieldCaption("No."))
            {
            }
            column(OBCaption_CBGStmt; FieldCaption("Opening Balance"))
            {
            }
            column(CBCaption_CBGStmt; FieldCaption("Closing Balance"))
            {
            }
            dataitem("CBG Statement Line"; "CBG Statement Line")
            {
                DataItemLink = "Journal Template Name" = field("Journal Template Name"), "No." = field("No.");
                DataItemTableView = sorting("Journal Template Name", "No.");
                column(DateFormatted_CBGStmtLine; Format(Date))
                {
                }
                column(AccType_CBGStmtLine; "Account Type")
                {
                }
                column(AccNo_CBGStmtLine; "Account No.")
                {
                }
                column(Desc_CBGStmtLine; Description)
                {
                }
                column(ShowVAT; ShowVAT())
                {
                    AutoFormatExpression = "CBG Statement".Currency;
                    AutoFormatType = 1;
                }
                column(DebitVATCreditVAT; "Debit VAT" - "Credit VAT")
                {
                    AutoFormatExpression = "CBG Statement".Currency;
                    AutoFormatType = 1;
                }
                column(UseDocumentNo; UseDocumentNo)
                {
                }
                column(Identification_CBGStmtLine; Identification)
                {
                }
                column(Debit_CBGStmtLine; Debit)
                {
                    AutoFormatExpression = "CBG Statement".Currency;
                    AutoFormatType = 1;
                }
                column(Credit_CBGStmtLine; Credit)
                {
                    AutoFormatExpression = "CBG Statement".Currency;
                    AutoFormatType = 1;
                }
                column(Currency_CBGStatement; "CBG Statement".Currency)
                {
                }
                column(TotalNetChangeDI_CBGStmtLine; "CBG Statement Line".TotalNetChange(Text1000004))
                {
                    AutoFormatExpression = "CBG Statement".Currency;
                    AutoFormatType = 1;
                }
                column(TotalNetChangeCI_CBGStmtLine; "CBG Statement Line".TotalNetChange(Text1000005))
                {
                    AutoFormatExpression = "CBG Statement".Currency;
                    AutoFormatType = 1;
                }
                column(OBTotalNetChangeNCI_CBGStmtLine; "CBG Statement"."Opening Balance" - "CBG Statement Line".TotalNetChange(Text1000006))
                {
                    AutoFormatExpression = "CBG Statement".Currency;
                    AutoFormatType = 1;
                }
                column(ABSCBGSttmtOBTotalNetChangeNCICB; Abs("CBG Statement"."Opening Balance" - "CBG Statement Line".TotalNetChange(Text1000006) - "CBG Statement"."Closing Balance"))
                {
                    AutoFormatExpression = "CBG Statement".Currency;
                    AutoFormatType = 1;
                }
                column(JnlTmpltName_CBGStmtLine; "Journal Template Name")
                {
                }
                column(No_CBGStmtLine; "No.")
                {
                }
                column(LineNo_CBGStmtLine; "Line No.")
                {
                }
                column(AppliesToDocNo_CBGStmtLine; "Applies-to Doc. No.")
                {
                }
                column(AppliesToDocType_CBGStmtLine; "Applies-to Doc. Type")
                {
                }
                column(StmtNo_CBGStmtLine; "Statement No.")
                {
                }
                column(DebitVATCreditVATCaption; DebitVATCreditVATCaptionLbl)
                {
                }
                column(ShowVATCaption; ShowVATCaptionLbl)
                {
                }
                column(DescCaption_CBGStmtLine; FieldCaption(Description))
                {
                }
                column(NoCaption; NoCaptionLbl)
                {
                }
                column(DocumentNoCaption; DocumentNoCaptionLbl)
                {
                }
                column(PostingDateCaption; PostingDateCaptionLbl)
                {
                }
                column(IdCaption_CBGStmtLine; FieldCaption(Identification))
                {
                }
                column(DebitCaption_CBGStmtLine; FieldCaption(Debit))
                {
                }
                column(CreditCaption_CBGStmtLine; FieldCaption(Credit))
                {
                }
                column(DescriptionCaption; DescriptionCaptionLbl)
                {
                }
                column(OutstandingAmountCaption; OutstandingAmountCaptionLbl)
                {
                }
                column(OriginalAmountCaption; OriginalAmountCaptionLbl)
                {
                }
                column(CurrCaption; CurrencyCaptionLbl)
                {
                }
                column(DateCaption; DateCaptionLbl)
                {
                }
                column(OurDocNoCaption; OurDocumentNoCaptionLbl)
                {
                }
                column(YourDocNoCaption; YourDocumentNoCaptionLbl)
                {
                }
                column(AppliedEntriesCaption; AppliedEntriesCaptionLbl)
                {
                }
                column(AppliedAmountCaption; AppliedAmountCaptionLbl)
                {
                }
                column(OpeningBalanceCaption; OpeningBalanceCaptionLbl)
                {
                }
                column(ClosingBalanceCaption; ClosingBalanceCaptionLbl)
                {
                }
                column(TotalNetChangeCaption; TotalNetChangeCaptionLbl)
                {
                }
                column(DecreaseCaption; DecreaseCaptionLbl)
                {
                }
                column(IncreaseCaption; IncreaseCaptionLbl)
                {
                }
                column(CalcClosingBalCaption; CalcClosingBalCaptionLbl)
                {
                }
                column(DifferenceCaption; DifferenceCaptionLbl)
                {
                }
                dataitem(CustEntryApplyID; "Cust. Ledger Entry")
                {
                    DataItemLink = "Customer No." = field("Account No.");
                    DataItemTableView = sorting("Customer No.", Open, Positive, "Due Date", "Currency Code") where(Open = const(true));
                    column(Desc_CustEntryApplyID; Description)
                    {
                    }
                    column(RemAmt_CustEntryApplyID; "Remaining Amount")
                    {
                        AutoFormatExpression = "Currency Code";
                        AutoFormatType = 1;
                    }
                    column(Amt_CustEntryApplyID; Amount)
                    {
                        AutoFormatExpression = "Currency Code";
                        AutoFormatType = 1;
                    }
                    column(CurrCode_CustEntryApplyID; "Currency Code")
                    {
                    }
                    column(DocDateFormat_CustEntryApplyID; Format("Document Date"))
                    {
                    }
                    column(DocNo_CustEntryApplyID; "Document No.")
                    {
                    }
                    column(ExtDocNo_CustEntryApplyID; "External Document No.")
                    {
                    }
                    column(DocType_CustEntryApplyID; "Document Type")
                    {
                    }
                    column(EntryNo_CustEntryApplyID; "Entry No.")
                    {
                    }
                    column(CustNo_CustEntryApplyID; "Customer No.")
                    {
                    }

                    trigger OnPreDataItem()
                    var
                        AppliesToID: Code[50];
                    begin
                        if not ApplyInformation then
                            CurrReport.Break();
                        if "CBG Statement Line"."Account Type" <> "CBG Statement Line"."Account Type"::Customer then
                            CurrReport.Break();

                        if ("CBG Statement Line"."Applies-to ID" = '') and
                           ("CBG Statement Line"."Account No." <> '') and
                           ("CBG Statement Line"."Applies-to Doc. No." <> '') and
                           ("CBG Statement Line"."Applies-to Doc. Type" <> "CBG Statement Line"."Applies-to Doc. Type"::" ")
                        then
                            CurrReport.Break();

                        case "CBG Statement".Type of
                            "CBG Statement".Type::Cash:
                                AppliesToID := "CBG Statement Line"."Document No.";
                            "CBG Statement".Type::"Bank/Giro":
                                AppliesToID := "CBG Statement Line"."Applies-to ID";
                        end;
                        if AppliesToID = '' then
                            CurrReport.Break();
                        SetRange("Applies-to ID", AppliesToID);
                    end;
                }
                dataitem(CustEntryApplyNo; "Cust. Ledger Entry")
                {
                    DataItemLink = "Customer No." = field("Account No."), "Document No." = field("Applies-to Doc. No."), "Document Type" = field("Applies-to Doc. Type");
                    DataItemTableView = sorting("Document No.");
                    column(DocType_CustEntryApplyNo; "Document Type")
                    {
                    }
                    column(Desc_CustEntryApplyNo; Description)
                    {
                    }
                    column(RemAmt_CustEntryApplyNo; "Remaining Amount")
                    {
                        AutoFormatExpression = "Currency Code";
                        AutoFormatType = 1;
                    }
                    column(Amt_CustEntryApplyNo; Amount)
                    {
                        AutoFormatExpression = "Currency Code";
                        AutoFormatType = 1;
                    }
                    column(CurrCode_CustEntryApplyNo; "Currency Code")
                    {
                    }
                    column(DocDate_CustEntryApplyNo; Format("Document Date"))
                    {
                    }
                    column(DocNo_CustEntryApplyNo; "Document No.")
                    {
                    }
                    column(ExtDocNo_CustEntryApplyNo; "External Document No.")
                    {
                    }
                    column(EntryNo_CustEntryApplyNo; "Entry No.")
                    {
                    }
                    column(CustNo_CustEntryApplyNo; "Customer No.")
                    {
                    }

                    trigger OnPreDataItem()
                    begin
                        if not ApplyInformation then
                            CurrReport.Break();
                        if "CBG Statement Line"."Account Type" <> "CBG Statement Line"."Account Type"::Customer then
                            CurrReport.Break();
                    end;
                }
                dataitem(VendEntryApplyID; "Vendor Ledger Entry")
                {
                    DataItemLink = "Vendor No." = field("Account No.");
                    DataItemTableView = sorting("Vendor No.", Open, Positive, "Due Date", "Currency Code") where(Open = const(true));
                    column(Desc_VendEntryApplyID; Description)
                    {
                    }
                    column(RemAmt_VendEntryApplyID; "Remaining Amount")
                    {
                        AutoFormatExpression = "Currency Code";
                        AutoFormatType = 1;
                    }
                    column(Amt_VendEntryApplyID; Amount)
                    {
                        AutoFormatExpression = "Currency Code";
                        AutoFormatType = 1;
                    }
                    column(CurrCode_VendEntryApplyID; "Currency Code")
                    {
                    }
                    column(DocDate_VendEntryApplyID; Format("Document Date"))
                    {
                    }
                    column(DocNo_VendEntryApplyID; "Document No.")
                    {
                    }
                    column(ExtDocNo_VendEntryApplyID; "External Document No.")
                    {
                    }
                    column(DocType_VendEntryApplyID; "Document Type")
                    {
                    }
                    column(EntryNo_VendEntryApplyID; "Entry No.")
                    {
                    }
                    column(VendorNo_VendEntryApplyID; "Vendor No.")
                    {
                    }

                    trigger OnPreDataItem()
                    var
                        AppliesToID: Code[50];
                    begin
                        if not ApplyInformation then
                            CurrReport.Break();
                        if "CBG Statement Line"."Account Type" <> "CBG Statement Line"."Account Type"::Vendor then
                            CurrReport.Break();

                        if ("CBG Statement Line"."Applies-to ID" = '') and
                           ("CBG Statement Line"."Account No." <> '') and
                           ("CBG Statement Line"."Applies-to Doc. No." <> '') and
                           ("CBG Statement Line"."Applies-to Doc. Type" <> "CBG Statement Line"."Applies-to Doc. Type"::" ")
                        then
                            CurrReport.Break();

                        case "CBG Statement".Type of
                            "CBG Statement".Type::Cash:
                                AppliesToID := "CBG Statement Line"."Document No.";
                            "CBG Statement".Type::"Bank/Giro":
                                AppliesToID := "CBG Statement Line"."Applies-to ID";
                        end;
                        if AppliesToID = '' then
                            CurrReport.Break();
                        SetRange("Applies-to ID", AppliesToID);
                    end;
                }
                dataitem(VendEntryApplyNo; "Vendor Ledger Entry")
                {
                    DataItemLink = "Vendor No." = field("Account No."), "Document No." = field("Applies-to Doc. No."), "Document Type" = field("Applies-to Doc. Type");
                    DataItemTableView = sorting("Document No.");
                    column(Desc_VendEntryApplyNo; Description)
                    {
                    }
                    column(RemAmt_VendEntryApplyNo; "Remaining Amount")
                    {
                        AutoFormatExpression = "Currency Code";
                        AutoFormatType = 1;
                    }
                    column(Amt_VendEntryApplyNo; Amount)
                    {
                        AutoFormatExpression = "Currency Code";
                        AutoFormatType = 1;
                    }
                    column(CurrCode_VendEntryApplyNo; "Currency Code")
                    {
                    }
                    column(DocDate_VendEntryApplyNo; Format("Document Date"))
                    {
                    }
                    column(DocNo_VendEntryApplyNo; "Document No.")
                    {
                    }
                    column(ExtDocNo_VendEntryApplyNo; "External Document No.")
                    {
                    }
                    column(DocType_VendEntryApplyNo; "Document Type")
                    {
                    }
                    column(EntryNo_VendEntryApplyNo; "Entry No.")
                    {
                    }
                    column(VendorNo_VendEntryApplyNo; "Vendor No.")
                    {
                    }

                    trigger OnPreDataItem()
                    begin
                        if not ApplyInformation then
                            CurrReport.Break();
                        if "CBG Statement Line"."Account Type" <> "CBG Statement Line"."Account Type"::Vendor then
                            CurrReport.Break();
                    end;
                }
                dataitem(EmplEntryApplyID; "Employee Ledger Entry")
                {
                    DataItemLink = "Employee No." = field("Account No.");
                    DataItemTableView = sorting("Employee No.", Open, Positive, "Currency Code") where(Open = const(true));
                    column(Desc_EmplEntryApplyID; Description)
                    {
                    }
                    column(RemAmt_EmplEntryApplyID; "Remaining Amount")
                    {
                        AutoFormatExpression = "Currency Code";
                        AutoFormatType = 1;
                    }
                    column(Amt_EmplEntryApplyID; Amount)
                    {
                        AutoFormatExpression = "Currency Code";
                        AutoFormatType = 1;
                    }
                    column(CurrCode_EmplEntryApplyID; "Currency Code")
                    {
                    }
                    column(DocDate_EmplEntryApplyID; Format("Posting Date"))
                    {
                    }
                    column(DocNo_EmplEntryApplyID; "Document No.")
                    {
                    }
                    column(DocType_EmplEntryApplyID; "Document Type")
                    {
                    }
                    column(EntryNo_EmplEntryApplyID; "Entry No.")
                    {
                    }
                    column(EmployeeNo_EmplEntryApplyID; "Employee No.")
                    {
                    }

                    trigger OnPreDataItem()
                    var
                        AppliesToID: Code[50];
                    begin
                        if not ApplyInformation then
                            CurrReport.Break();
                        if "CBG Statement Line"."Account Type" <> "CBG Statement Line"."Account Type"::Employee then
                            CurrReport.Break();

                        if ("CBG Statement Line"."Applies-to ID" = '') and
                           ("CBG Statement Line"."Account No." <> '') and
                           ("CBG Statement Line"."Applies-to Doc. No." <> '')
                        then
                            CurrReport.Break();

                        case "CBG Statement".Type of
                            "CBG Statement".Type::Cash:
                                AppliesToID := "CBG Statement Line"."Document No.";
                            "CBG Statement".Type::"Bank/Giro":
                                AppliesToID := "CBG Statement Line"."Applies-to ID";
                        end;
                        if AppliesToID = '' then
                            CurrReport.Break();
                        SetRange("Applies-to ID", AppliesToID);
                    end;
                }
                dataitem(EmplEntryApplyNo; "Employee Ledger Entry")
                {
                    DataItemLink = "Employee No." = field("Account No."), "Document No." = field("Applies-to Doc. No."), "Document Type" = field("Applies-to Doc. Type");
                    DataItemTableView = sorting("Document No.");
                    column(Desc_EmplEntryApplyNo; Description)
                    {
                    }
                    column(RemAmt_EmplEntryApplyNo; "Remaining Amount")
                    {
                        AutoFormatExpression = "Currency Code";
                        AutoFormatType = 1;
                    }
                    column(Amt_EmplEntryApplyNo; Amount)
                    {
                        AutoFormatExpression = "Currency Code";
                        AutoFormatType = 1;
                    }
                    column(CurrCode_EmplEntryApplyNo; "Currency Code")
                    {
                    }
                    column(DocDate_EmplEntryApplyNo; Format("Posting Date"))
                    {
                    }
                    column(DocNo_EmplEntryApplyNo; "Document No.")
                    {
                    }
                    column(DocType_EmplEntryApplyNo; "Document Type")
                    {
                    }
                    column(EntryNo_EmplEntryApplyNo; "Entry No.")
                    {
                    }
                    column(EmployeeNo_EmplEntryApplyNo; "Employee No.")
                    {
                    }

                    trigger OnPreDataItem()
                    begin
                        if not ApplyInformation then
                            CurrReport.Break();
                        if "CBG Statement Line"."Account Type" <> "CBG Statement Line"."Account Type"::Employee then
                            CurrReport.Break();
                    end;
                }
                dataitem("Payment History Line"; "Payment History Line")
                {
                    DataItemLink = Identification = field(Identification), "Our Bank" = field("Statement No.");
                    DataItemTableView = sorting("Our Bank", Identification, Status) where(Identification = filter(<> ''), Status = filter(Transmitted | "Request for Cancellation"));
                    column(OurBank_PymtHistoryLine; "Our Bank")
                    {
                    }
                    column(RunNo_PymtHistoryLine; "Run No.")
                    {
                    }
                    column(LineNo_PymtHistoryLine; "Line No.")
                    {
                    }
                    column(Identification_PymtHistoryLine; Identification)
                    {
                    }
                    dataitem("Detail Line"; "Detail Line")
                    {
                        DataItemLink = "Connect Batches" = field("Run No."), "Connect Lines" = field("Line No."), "Our Bank" = field("Our Bank");
                        DataItemTableView = sorting("Our Bank", Status, "Connect Batches", "Connect Lines", Date) where(Status = const("In process"));
                        column(TransNo_DetailLine; "Transaction No.")
                        {
                        }
                        column(ConnectBatches_DetailLine; "Connect Batches")
                        {
                        }
                        column(ConnectLines_DetailLine; "Connect Lines")
                        {
                        }
                        column(OurBannk_DetailLine; "Our Bank")
                        {
                        }
                        column(SerialNoEntry_DetailLine; "Serial No. (Entry)")
                        {
                        }
                        dataitem(CustEntryDetail; "Cust. Ledger Entry")
                        {
                            DataItemLink = "Entry No." = field("Serial No. (Entry)");
                            DataItemTableView = sorting("Entry No.");
                            column(Desc_CustEntryDetail; Description)
                            {
                            }
                            column(RemAmt_CustEntryDetail; "Remaining Amount")
                            {
                                AutoFormatExpression = "Currency Code";
                                AutoFormatType = 1;
                            }
                            column(Amt_CustEntryDetail; Amount)
                            {
                                AutoFormatExpression = "Currency Code";
                                AutoFormatType = 1;
                            }
                            column(CurrCode_CustEntryDetail; "Currency Code")
                            {
                            }
                            column(DocDate_CustEntryDetail; Format("Document Date"))
                            {
                            }
                            column(DocNo_CustEntryDetail; "Document No.")
                            {
                            }
                            column(ExtDocNo_CustEntryDetail; "External Document No.")
                            {
                            }
                            column(DocType_CustEntryDetail; "Document Type")
                            {
                            }
                            column(Amt_DetailLine; "Detail Line".Amount)
                            {
                                AutoFormatExpression = "Detail Line"."Currency Code";
                                AutoFormatType = 1;
                            }
                            column(EntryNo_CustEntryDetail; "Entry No.")
                            {
                            }

                            trigger OnPreDataItem()
                            begin
                                if "Detail Line"."Account Type" <> "Detail Line"."Account Type"::Customer then
                                    CurrReport.Break();
                            end;
                        }
                        dataitem(VendEntryDetail; "Vendor Ledger Entry")
                        {
                            DataItemLink = "Entry No." = field("Serial No. (Entry)");
                            DataItemTableView = sorting("Entry No.");
                            column(Desc_VendEntryDetail; Description)
                            {
                            }
                            column(RemAmt_VendEntryDetail; "Remaining Amount")
                            {
                                AutoFormatExpression = "Currency Code";
                                AutoFormatType = 1;
                            }
                            column(Amt_VendEntryDetail; Amount)
                            {
                                AutoFormatExpression = "Currency Code";
                                AutoFormatType = 1;
                            }
                            column(CurrCode_VendEntryDetail; "Currency Code")
                            {
                            }
                            column(DocDate_VendEntryDetail; Format("Document Date"))
                            {
                            }
                            column(DocNo_VendEntryDetail; "Document No.")
                            {
                            }
                            column(ExtDocNo_VendEntryDetail; "External Document No.")
                            {
                            }
                            column(DocType_VendEntryDetail; "Document Type")
                            {
                            }
                            column(Amount_DetailLine; "Detail Line".Amount)
                            {
                                AutoFormatExpression = "Detail Line"."Currency Code";
                                AutoFormatType = 1;
                            }
                            column(EntryNo_VendEntryDetail; "Entry No.")
                            {
                            }

                            trigger OnPreDataItem()
                            begin
                                if "Detail Line"."Account Type" <> "Detail Line"."Account Type"::Vendor then
                                    CurrReport.Break();
                            end;
                        }
                        dataitem(EmplEntryDetail; "Employee Ledger Entry")
                        {
                            DataItemLink = "Entry No." = field("Serial No. (Entry)");
                            DataItemTableView = sorting("Entry No.");
                            column(Desc_EmplEntryDetail; Description)
                            {
                            }
                            column(RemAmt_EmplEntryDetail; "Remaining Amount")
                            {
                                AutoFormatExpression = "Currency Code";
                                AutoFormatType = 1;
                            }
                            column(Amt_EmplEntryDetail; Amount)
                            {
                                AutoFormatExpression = "Currency Code";
                                AutoFormatType = 1;
                            }
                            column(CurrCode_EmplEntryDetail; "Currency Code")
                            {
                            }
                            column(DocDate_EmplEntryDetail; Format("Posting Date"))
                            {
                            }
                            column(DocNo_EmplEntryDetail; "Document No.")
                            {
                            }
                            column(DocType_EmplEntryDetail; "Document Type")
                            {
                            }
                            column(Amount_EmplDetailLine; "Detail Line".Amount)
                            {
                                AutoFormatExpression = "Detail Line"."Currency Code";
                                AutoFormatType = 1;
                            }
                            column(EntryNo_EmplEntryDetail; "Entry No.")
                            {
                            }

                            trigger OnPreDataItem()
                            begin
                                if "Detail Line"."Account Type" <> "Detail Line"."Account Type"::Employee then
                                    CurrReport.Break();
                            end;
                        }
                    }

                    trigger OnPreDataItem()
                    begin
                        if not ApplyInformation then
                            CurrReport.Break();
                        if "CBG Statement".Type <> "CBG Statement".Type::"Bank/Giro" then
                            CurrReport.Break();
                    end;
                }
                dataitem("Integer"; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));

                    trigger OnPreDataItem()
                    begin
                        if not ApplyInformation then
                            CurrReport.Break();
                        if not HeaderPrinted then
                            CurrReport.Break();
                        HeaderPrinted := false;
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if "CBG Statement".Type = "CBG Statement".Type::Cash then
                        UseDocumentNo := "Document No.";
                    if ApplyInformation then begin
                        Print := ("CBG Statement Line".Identification <> '') or ("CBG Statement Line"."Applies-to Doc. No." <> '');
                        if not Print then
                            case "CBG Statement Line"."Account Type" of
                                "CBG Statement Line"."Account Type"::Customer:
                                    begin
                                        CustEntries.SetCurrentKey("Customer No.", Open);
                                        CustEntries.SetRange("Customer No.", "Account No.");
                                        CustEntries.SetRange(Open, true);
                                        case "CBG Statement".Type of
                                            "CBG Statement".Type::Cash:
                                                CustEntries.SetRange("Applies-to ID", "CBG Statement Line"."Document No.");
                                            "CBG Statement".Type::"Bank/Giro":
                                                CustEntries.SetRange("Applies-to ID", "CBG Statement Line"."Applies-to ID");
                                        end;
                                        Print := CustEntries.Find('-');
                                    end;
                                "CBG Statement Line"."Account Type"::Vendor:
                                    begin
                                        VendEntries.SetCurrentKey("Vendor No.", Open);
                                        VendEntries.SetRange("Vendor No.", "Account No.");
                                        VendEntries.SetRange(Open, true);
                                        case "CBG Statement".Type of
                                            "CBG Statement".Type::Cash:
                                                VendEntries.SetRange("Applies-to ID", "CBG Statement Line"."Document No.");
                                            "CBG Statement".Type::"Bank/Giro":
                                                VendEntries.SetRange("Applies-to ID", "CBG Statement Line"."Applies-to ID");
                                        end;
                                        Print := VendEntries.Find('-');
                                    end;
                                "Account Type"::Employee:
                                    begin
                                        EmployeeLedgerEntry.SetCurrentKey("Employee No.", Open);
                                        EmployeeLedgerEntry.SetRange("Employee No.", "Account No.");
                                        EmployeeLedgerEntry.SetRange(Open, true);
                                        case "CBG Statement".Type of
                                            "CBG Statement".Type::Cash:
                                                EmployeeLedgerEntry.SetRange("Applies-to ID", "Document No.");
                                            "CBG Statement".Type::"Bank/Giro":
                                                EmployeeLedgerEntry.SetRange("Applies-to ID", "Applies-to ID");
                                        end;
                                        Print := EmployeeLedgerEntry.FindFirst();
                                    end;
                            end;
                    end else
                        Print := false;
                    HeaderPrinted := Print;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if Type = Type::"Bank/Giro" then
                    UseDocumentNo := "Document No."
                else
                    "Document No." := '';

                Clear(Label);
                Clear(Value);

                if "Account Type" = "Account Type"::"Bank Account" then begin
                    if Currency <> '' then begin
                        Label[1] := CurrencyCaptionLbl;
                        Value[1] := Currency;
                    end;

                    Label[2] := Text1000001;
                    Value[2] := CLAccountNo();
                end;

                if Type = Type::"Bank/Giro" then begin
                    Label[3] := DocumentNoCaptionLbl;
                    Value[3] := "Document No.";
                    Label[4] := Text1000003;
                    Value[4] := Format(Date);
                end
            end;

            trigger OnPreDataItem()
            var
                GenJournalTemplateFilter: Text;
            begin
                GenJournalTemplateFilter := "Gen. Journal Batch".GetFilter("Journal Template Name");
                if GenJournalTemplateFilter <> '' then
                    SetFilter("Journal Template Name", GenJournalTemplateFilter);
            end;
        }
    }

    requestpage
    {
        Caption = 'Checklist rep. Cash Bank Giro';
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field("Show Applied Entries"; ApplyInformation)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Applied Entries';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        Text1000001: Label 'G/L Account';
        Text1000003: Label 'Document Date';
        Text1000004: Label 'DI';
        Text1000005: Label 'CI';
        Text1000006: Label 'NCI';
        Text1000007: Label 'Incl. %1';
        Text1000008: Label 'Excl. %1';
        HeaderPrinted: Boolean;
        UseDocumentNo: Code[20];
        Label: array[4] of Text[30];
        Value: array[4] of Text[80];
        ApplyInformation: Boolean;
        Print: Boolean;
        CustEntries: Record "Cust. Ledger Entry";
        VendEntries: Record "Vendor Ledger Entry";
        DebitVATCreditVATCaptionLbl: Label 'VAT Amount';
        ShowVATCaptionLbl: Label 'VAT';
        NoCaptionLbl: Label 'No.';
        DocumentNoCaptionLbl: Label 'Document No.';
        PostingDateCaptionLbl: Label 'Posting Date';
        DescriptionCaptionLbl: Label 'Description';
        OutstandingAmountCaptionLbl: Label 'Outstanding Amount';
        OriginalAmountCaptionLbl: Label 'Original Amount';
        CurrencyCaptionLbl: Label 'Currency';
        DateCaptionLbl: Label 'Date';
        OurDocumentNoCaptionLbl: Label 'Our Document No.';
        YourDocumentNoCaptionLbl: Label 'Your Document No.';
        AppliedEntriesCaptionLbl: Label 'Applied Entries';
        AppliedAmountCaptionLbl: Label 'Applied amount';
        OpeningBalanceCaptionLbl: Label 'Opening Balance';
        ClosingBalanceCaptionLbl: Label 'Closing Balance';
        TotalNetChangeCaptionLbl: Label 'Total Net Change';
        DecreaseCaptionLbl: Label 'Decrease';
        IncreaseCaptionLbl: Label 'Increase';
        CalcClosingBalCaptionLbl: Label 'Calculated Closing Balance';
        DifferenceCaptionLbl: Label 'Difference';
        EmployeeLedgerEntry: Record "Employee Ledger Entry";

    [Scope('OnPrem')]
    procedure ShowVAT() res: Text[30]
    begin
        if "CBG Statement Line"."VAT %" <> 0 then begin
            if "CBG Statement Line"."Amount incl. VAT" then
                res := StrSubstNo(Text1000007, "CBG Statement Line"."VAT %") + '%'
            else
                res := StrSubstNo(Text1000008, "CBG Statement Line"."VAT %") + '%'
        end else
            res := '';
    end;
}

