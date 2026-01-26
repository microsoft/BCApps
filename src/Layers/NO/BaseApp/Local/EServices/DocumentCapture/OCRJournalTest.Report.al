// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Bank.BankAccount;
using Microsoft.CRM.Campaign;
using Microsoft.CRM.Team;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.Period;
using Microsoft.Projects.Project.Job;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Setup;
using System.Security.User;
using System.Utilities;

report 15000100 "OCR Journal - Test"
{
    // MBS Navision NO - OCR Payment
    // - Based on Report 2, version NAVW13.01.01,NAVNO3.01.01
    // - Code changes marked with OCR01.
    // - New Section "Gen. Journal Line, Body (2)" showing OCR errors.
    DefaultLayout = RDLC;
    RDLCLayout = './Local/EServices/DocumentCapture/OCRJournalTest.rdlc';

    Caption = 'General Journal - Test';

    dataset
    {
        dataitem("Gen. Journal Batch"; "Gen. Journal Batch")
        {
            DataItemTableView = sorting("Journal Template Name", Name);
            RequestFilterFields = "Journal Template Name", Name;
            column(JournalTemplateName_GenJournalBatch; "Journal Template Name")
            {
            }
            column(Name_GenJournalBatch; Name)
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(GenJournalBatchJournalTemplateName; "Gen. Journal Batch"."Journal Template Name")
            {
            }
            column(GenJournalBatchName; "Gen. Journal Batch".Name)
            {
            }
            column(OCRJournalTestCaption; OCRJournalTestCaptionLbl)
            {
            }
            column(ShowOnlyOCRErrors; ShowOnlyOCRErrors)
            {
            }
            column(GenJournalBatchJournalTemplateNameCaption; "Gen. Journal Batch".FieldCaption("Journal Template Name"))
            {
            }
            column(JournalBatchCaption; JournalBatchCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(GenJournalLinePostingDateCaption; "Gen. Journal Line".FieldCaption("Posting Date"))
            {
            }
            column(GenJournalLineDocumentTypeCaption; DocumentTypeCaptionLbl)
            {
            }
            column(GenJournalLineDocumentNoCaption; "Gen. Journal Line".FieldCaption("Document No."))
            {
            }
            column(GenJournalLineAccountTypeCaption; AccountTypeCaptionLbl)
            {
            }
            column(GenJournalLineAccountNoCaption; "Gen. Journal Line".FieldCaption("Account No."))
            {
            }
            column(NameCaption; NameCaptionLbl)
            {
            }
            column(GenJournalLineDescriptionCaption; "Gen. Journal Line".FieldCaption(Description))
            {
            }
            column(GenPostingTypeCaption; GenPostingTypeCaptionLbl)
            {
            }
            column(GenJournalLineAmountCaption; "Gen. Journal Line".FieldCaption(Amount))
            {
            }
            column(GenJournalLineBalAccountNoCaption; "Gen. Journal Line".FieldCaption("Bal. Account No."))
            {
            }
            column(GenJournalLineBalanceLCYCaption; "Gen. Journal Line".FieldCaption("Balance (LCY)"))
            {
            }
            column(GenJournalLineVATNumberCaption; "Gen. Journal Line".FieldCaption("VAT Number"))
            {
            }
            column(GenJournalLineBalGenPostingTypeCaption; "Gen. Journal Line".FieldCaption("Bal. Gen. Posting Type"))
            {
            }
            column(GenJournalLineBalVATNumberCaption; "Gen. Journal Line".FieldCaption("Bal. VAT Number"))
            {
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                PrintOnlyIfDetail = true;
                dataitem("Gen. Journal Line"; "Gen. Journal Line")
                {
                    DataItemLink = "Journal Template Name" = field("Journal Template Name"), "Journal Batch Name" = field(Name);
                    DataItemLinkReference = "Gen. Journal Batch";
                    DataItemTableView = sorting("Journal Template Name", "Journal Batch Name", "Line No.");
                    RequestFilterFields = "Posting Date";
                    column(PostingDate_GenJournalLine; "Posting Date")
                    {
                    }
                    column(DocumentType_GenJournalLine; "Document Type")
                    {
                    }
                    column(DocumentNo_GenJournalLine; "Document No.")
                    {
                    }
                    column(AccountType_GenJournalLine; "Account Type")
                    {
                    }
                    column(AccountNo_GenJournalLine; "Account No.")
                    {
                    }
                    column(AccName; AccName)
                    {
                    }
                    column(Description_GenJournalLine; Description)
                    {
                    }
                    column(GenPostingType_GenJournalLine; "Gen. Posting Type")
                    {
                    }
                    column(Amount_GenJournalLine; Amount)
                    {
                    }
                    column(CurrencyCode_GenJournalLine; "Currency Code")
                    {
                    }
                    column(BalAccountNo_GenJournalLine; "Bal. Account No.")
                    {
                    }
                    column(BalanceLCY_GenJournalLine; "Balance (LCY)")
                    {
                    }
                    column(VATNumber_GenJournalLine; "VAT Number")
                    {
                    }
                    column(BalGenPostingType_GenJournalLine; "Bal. Gen. Posting Type")
                    {
                    }
                    column(BalVATNumber_GenJournalLine; "Bal. VAT Number")
                    {
                    }
                    column(AmountLCY_GenJournalLine; "Amount (LCY)")
                    {
                    }
                    column(AmountLCY; AmountLCY)
                    {
                    }
                    column(BalanceLCY; BalanceLCY)
                    {
                    }
                    column(TotalLCYCaption; TotalLCYCaptionLbl)
                    {
                    }
                    column(JnlTmplName_GenJnlLine; "Journal Template Name")
                    {
                    }
                    column(JournalBatchName_GenJournalLine; "Journal Batch Name")
                    {
                    }
                    column(Warning_GenJournalLine; Warning)
                    {
                    }
                    column(LineNo_GenJnlLine; "Line No.")
                    {
                    }
                    dataitem(DimensionLoop; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                        column(DimText; DimText)
                        {
                        }
                        column(Number_DimensionLoop; Number)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if Number = 1 then begin
                                if not DimSetEntry.FindSet() then
                                    CurrReport.Break();
                            end else
                                if not Continue then
                                    CurrReport.Break();

                            DimText := GetDimText();
                        end;

                        trigger OnPreDataItem()
                        begin
                            if not ShowDim then
                                CurrReport.Break();

                            DimSetEntry.SetRange("Dimension Set ID", "Gen. Journal Line"."Dimension Set ID");
                        end;
                    }
                    dataitem(ErrorLoop; "Integer")
                    {
                        DataItemTableView = sorting(Number);
                        column(OCRWarningText; OCRWarningText)
                        {
                        }
                        column(OCRCaptionLbl; OCRCaptionLbl)
                        {
                        }
                        column(ErrorTextNumber; ErrorText[Number])
                        {
                        }
                        column(ErrorTextNumberCaption; WarningCaptionLbl)
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
                    var
                        DimMgt: Codeunit DimensionManagement;
                        TableID: array[10] of Integer;
                        No: array[10] of Code[20];
                    begin
                        if ShowOnlyOCRErrors and not "Gen. Journal Line".Warning then
                            CurrReport.Skip();
                        // Delete backslash (=newline) in the error text
                        OCRWarningText := ConvertStr("Warning text", '\', ' ');

                        if "Currency Code" = '' then
                            "Amount (LCY)" := Amount;

                        UpdateLineBalance();

                        AccName := '';
                        BalAccName := '';

                        if not EmptyLine() then begin
                            MakeRecurringTexts("Gen. Journal Line");

                            AmountError := false;

                            if ("Account No." = '') and ("Bal. Account No." = '') then
                                AddError(StrSubstNo(Text001, FieldCaption("Account No."), FieldCaption("Bal. Account No.")))
                            else
                                if ("Account Type" <> "Account Type"::"Fixed Asset") and
                                   ("Bal. Account Type" <> "Bal. Account Type"::"Fixed Asset")
                                then
                                    TestFixedAssetFields("Gen. Journal Line");

                            if "Account No." <> '' then
                                case "Account Type" of
                                    "Account Type"::"G/L Account":
                                        begin
                                            if ("Gen. Bus. Posting Group" <> '') or ("Gen. Prod. Posting Group" <> '') or
                                               ("VAT Bus. Posting Group" <> '') or ("VAT Prod. Posting Group" <> '')
                                            then
                                                if "Gen. Posting Type" = "Gen. Posting Type"::" " then
                                                    AddError(StrSubstNo(Text002, FieldCaption("Gen. Posting Type")));
                                            if ("Gen. Posting Type" <> "Gen. Posting Type"::" ") and
                                               ("VAT Posting" = "VAT Posting"::"Automatic VAT Entry")
                                            then begin
                                                if "VAT Amount" + "VAT Base Amount" <> Amount then
                                                    AddError(AmountNotEqualMsg);
                                                if "Currency Code" <> '' then
                                                    if "VAT Amount (LCY)" + "VAT Base Amount (LCY)" <> "Amount (LCY)" then
                                                        AddError(AmountLCYNotEqualMsg);
                                            end;
                                        end;
                                    "Account Type"::Customer, "Account Type"::Vendor:
                                        begin
                                            if "Gen. Posting Type" <> "Gen. Posting Type"::" " then
                                                AddError(
                                                  StrSubstNo(
                                                    Text004,
                                                    FieldCaption("Gen. Posting Type"), FieldCaption("Account Type"), "Account Type"));
                                            if ("Gen. Bus. Posting Group" <> '') or ("Gen. Prod. Posting Group" <> '') or
                                               ("VAT Bus. Posting Group" <> '') or ("VAT Prod. Posting Group" <> '')
                                            then
                                                AddError(StrSubstNo(AccountsNotCompletedMsg, "Account Type"));

                                            if "Document Type" <> "Document Type"::" " then
                                                if "Account Type" = "Account Type"::Customer then
                                                    case "Document Type" of
                                                        "Document Type"::"Credit Memo":
                                                            WarningIfPositiveAmt("Gen. Journal Line");
                                                        "Document Type"::Payment:
                                                            if ("Applies-to Doc. Type" = "Applies-to Doc. Type"::"Credit Memo") and
                                                               ("Applies-to Doc. No." <> '')
                                                            then
                                                                WarningIfNegativeAmt("Gen. Journal Line")
                                                            else
                                                                WarningIfPositiveAmt("Gen. Journal Line");
                                                        else
                                                            WarningIfNegativeAmt("Gen. Journal Line");
                                                    end
                                                else
                                                    case "Document Type" of
                                                        "Document Type"::"Credit Memo":
                                                            WarningIfNegativeAmt("Gen. Journal Line");
                                                        "Document Type"::Payment:
                                                            if ("Applies-to Doc. Type" = "Applies-to Doc. Type"::"Credit Memo") and
                                                               ("Applies-to Doc. No." <> '')
                                                            then
                                                                WarningIfPositiveAmt("Gen. Journal Line")
                                                            else
                                                                WarningIfNegativeAmt("Gen. Journal Line");
                                                        else
                                                            WarningIfPositiveAmt("Gen. Journal Line");
                                                    end;

                                            if Amount * "Sales/Purch. (LCY)" < 0 then
                                                AddError(
                                                  StrSubstNo(
                                                    Text008,
                                                    FieldCaption("Sales/Purch. (LCY)"), FieldCaption(Amount)));
                                            if "Job No." <> '' then
                                                AddError(StrSubstNo(Text009, FieldCaption("Job No.")));
                                        end;
                                    "Account Type"::"Bank Account":
                                        begin
                                            if "Gen. Posting Type" <> "Gen. Posting Type"::" " then
                                                AddError(
                                                  StrSubstNo(
                                                    Text004,
                                                    FieldCaption("Gen. Posting Type"), FieldCaption("Account Type"), "Account Type"));
                                            if ("Gen. Bus. Posting Group" <> '') or ("Gen. Prod. Posting Group" <> '') or
                                               ("VAT Bus. Posting Group" <> '') or ("VAT Prod. Posting Group" <> '')
                                            then
                                                AddError(StrSubstNo(AccountsNotCompletedMsg, "Account Type"));

                                            if "Job No." <> '' then
                                                AddError(StrSubstNo(Text009, FieldCaption("Job No.")));
                                            if (Amount < 0) and ("Bank Payment Type" = "Bank Payment Type"::"Computer Check") then
                                                if not "Check Printed" then
                                                    AddError(StrSubstNo(Text010, FieldCaption("Check Printed")));
                                        end;
                                    "Account Type"::"Fixed Asset":
                                        TestFixedAsset("Gen. Journal Line");
                                end;

                            if "Bal. Account No." <> '' then
                                case "Bal. Account Type" of
                                    "Bal. Account Type"::"G/L Account":
                                        begin
                                            if ("Bal. Gen. Bus. Posting Group" <> '') or ("Bal. Gen. Prod. Posting Group" <> '') or
                                               ("Bal. VAT Bus. Posting Group" <> '') or ("Bal. VAT Prod. Posting Group" <> '')
                                            then
                                                if "Bal. Gen. Posting Type" = "Bal. Gen. Posting Type"::" " then
                                                    AddError(StrSubstNo(Text002, FieldCaption("Bal. Gen. Posting Type")));
                                            if ("Bal. Gen. Posting Type" <> "Bal. Gen. Posting Type"::" ") and
                                               ("VAT Posting" = "VAT Posting"::"Automatic VAT Entry")
                                            then begin
                                                if "Bal. VAT Amount" + "Bal. VAT Base Amount" <> -Amount then
                                                    AddError(BalAmountNotEqualMsg);
                                                if "Currency Code" <> '' then
                                                    if "Bal. VAT Amount (LCY)" + "Bal. VAT Base Amount (LCY)" <> -"Amount (LCY)" then
                                                        AddError(BalAmountLCYNotEqualMsg);
                                            end;
                                        end;
                                    "Bal. Account Type"::Customer, "Bal. Account Type"::Vendor:
                                        begin
                                            if "Bal. Gen. Posting Type" <> "Bal. Gen. Posting Type"::" " then
                                                AddError(
                                                  StrSubstNo(
                                                    Text004,
                                                    FieldCaption("Bal. Gen. Posting Type"), FieldCaption("Bal. Account Type"), "Bal. Account Type"));
                                            if ("Bal. Gen. Bus. Posting Group" <> '') or ("Bal. Gen. Prod. Posting Group" <> '') or
                                               ("Bal. VAT Bus. Posting Group" <> '') or ("Bal. VAT Prod. Posting Group" <> '')
                                            then
                                                AddError(StrSubstNo(BalAccountsNotCompletedMsg, "Bal. Account Type"));

                                            if "Document Type" <> "Document Type"::" " then
                                                if ("Bal. Account Type" = "Bal. Account Type"::Customer) =
                                                   ("Document Type" in ["Document Type"::Payment, "Document Type"::"Credit Memo"])
                                                then
                                                    WarningIfNegativeAmt("Gen. Journal Line")
                                                else
                                                    WarningIfPositiveAmt("Gen. Journal Line");

                                            if Amount * "Sales/Purch. (LCY)" > 0 then
                                                AddError(
                                                  StrSubstNo(
                                                    Text012,
                                                    FieldCaption("Sales/Purch. (LCY)"), FieldCaption(Amount)));
                                            if "Job No." <> '' then
                                                AddError(StrSubstNo(Text009, FieldCaption("Job No.")));
                                        end;
                                    "Bal. Account Type"::"Bank Account":
                                        begin
                                            if "Bal. Gen. Posting Type" <> "Bal. Gen. Posting Type"::" " then
                                                AddError(
                                                  StrSubstNo(
                                                    Text004,
                                                    FieldCaption("Bal. Gen. Posting Type"), FieldCaption("Bal. Account Type"), "Bal. Account Type"));
                                            if ("Bal. Gen. Bus. Posting Group" <> '') or ("Bal. Gen. Prod. Posting Group" <> '') or
                                               ("Bal. VAT Bus. Posting Group" <> '') or ("Bal. VAT Prod. Posting Group" <> '')
                                            then
                                                AddError(StrSubstNo(BalAccountsNotCompletedMsg, "Bal. Account Type"));

                                            if "Job No." <> '' then
                                                AddError(StrSubstNo(Text009, FieldCaption("Job No.")));
                                            if (Amount > 0) and ("Bank Payment Type" = "Bank Payment Type"::"Computer Check") then
                                                if not "Check Printed" then
                                                    AddError(StrSubstNo(Text010, FieldCaption("Check Printed")));
                                        end;
                                    "Bal. Account Type"::"Fixed Asset":
                                        TestFixedAsset("Gen. Journal Line");
                                end;

                            if ("Account No." <> '') and
                               not "System-Created Entry" and
                               ("Gen. Posting Type" = "Gen. Posting Type"::" ") and
                               (Amount = 0) and
                               not GenJnlTemplate.Recurring and
                               not "Allow Zero-Amount Posting" and
                               ("Account Type" <> "Account Type"::"Fixed Asset")
                            then
                                WarningIfZeroAmt("Gen. Journal Line");

                            CheckRecurringLine("Gen. Journal Line");
                            CheckAllocations("Gen. Journal Line");

                            if "Posting Date" = 0D then
                                AddError(StrSubstNo(Text002, FieldCaption("Posting Date")))
                            else begin
                                if "Posting Date" <> NormalDate("Posting Date") then
                                    if ("Account Type" <> "Account Type"::"G/L Account") or
                                       ("Bal. Account Type" <> "Bal. Account Type"::"G/L Account")
                                    then
                                        AddError(
                                          StrSubstNo(
                                            Text013, FieldCaption("Posting Date")));

                                if (AllowPostingFrom = 0D) and (AllowPostingTo = 0D) then begin
                                    if UserId <> '' then
                                        if UserSetup.Get(UserId) then begin
                                            AllowPostingFrom := UserSetup."Allow Posting From";
                                            AllowPostingTo := UserSetup."Allow Posting To";
                                        end;
                                    if (AllowPostingFrom = 0D) and (AllowPostingTo = 0D) then begin
                                        AllowPostingFrom := GLSetup."Allow Posting From";
                                        AllowPostingTo := GLSetup."Allow Posting To";
                                    end;
                                    if AllowPostingTo = 0D then
                                        AllowPostingTo := 99991231D;
                                end;
                                if ("Posting Date" < AllowPostingFrom) or ("Posting Date" > AllowPostingTo) then
                                    AddError(
                                      StrSubstNo(
                                        Text014, Format("Posting Date")));

                                if "Gen. Journal Batch"."No. Series" <> '' then begin
                                    if NoSeries."Date Order" and ("Posting Date" < LastEntrdDate) then
                                        AddError(Text015);
                                    LastEntrdDate := "Posting Date";
                                end;
                            end;

                            if "Document Date" <> 0D then
                                if ("Document Date" <> NormalDate("Document Date")) and
                                   (("Account Type" <> "Account Type"::"G/L Account") or
                                    ("Bal. Account Type" <> "Bal. Account Type"::"G/L Account"))
                                then
                                    AddError(
                                      StrSubstNo(
                                        Text013, FieldCaption("Document Date")));

                            if "Document No." = '' then
                                AddError(StrSubstNo(Text002, FieldCaption("Document No.")))
                            else
                                if "Gen. Journal Batch"."No. Series" <> '' then begin
                                    if (LastEntrdDocNo <> '') and
                                       ("Document No." <> LastEntrdDocNo) and
                                       ("Document No." <> IncStr(LastEntrdDocNo))
                                    then
                                        AddError(Text016);
                                    LastEntrdDocNo := "Document No.";
                                end;

                            if ("Account Type" in ["Account Type"::Customer, "Account Type"::Vendor, "Account Type"::"Fixed Asset"]) and
                               ("Bal. Account Type" in ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor, "Bal. Account Type"::"Fixed Asset"])
                            then
                                AddError(
                                  StrSubstNo(
                                    Text017,
                                    FieldCaption("Account Type"), FieldCaption("Bal. Account Type")));

                            if Amount * "Amount (LCY)" < 0 then
                                AddError(
                                  StrSubstNo(
                                    Text008, FieldCaption("Amount (LCY)"), FieldCaption(Amount)));

                            if ("Account Type" = "Account Type"::"G/L Account") and
                               ("Bal. Account Type" = "Bal. Account Type"::"G/L Account")
                            then
                                if "Applies-to Doc. No." <> '' then
                                    AddError(StrSubstNo(Text009, FieldCaption("Applies-to Doc. No.")));

                            if (("Account Type" = "Account Type"::"G/L Account") and
                                ("Bal. Account Type" = "Bal. Account Type"::"G/L Account")) or
                               ("Document Type" <> "Document Type"::Invoice)
                            then begin
                                if "Pmt. Discount Date" <> 0D then
                                    AddError(StrSubstNo(Text009, FieldCaption("Pmt. Discount Date")));
                                if "Payment Discount %" <> 0 then
                                    AddError(StrSubstNo(Text018, FieldCaption("Payment Discount %")));
                            end;

                            if (("Account Type" = "Account Type"::"G/L Account") and
                                ("Bal. Account Type" = "Bal. Account Type"::"G/L Account")) or
                               ("Applies-to Doc. No." <> '')
                            then
                                if "Applies-to ID" <> '' then
                                    AddError(StrSubstNo(Text009, FieldCaption("Applies-to ID")));

                            if ("Account Type" <> "Account Type"::"Bank Account") and
                               ("Bal. Account Type" <> "Bal. Account Type"::"Bank Account")
                            then
                                if GenJnlLine2."Bank Payment Type" <> "Bank Payment Type"::" " then
                                    AddError(StrSubstNo(Text009, FieldCaption("Bank Payment Type")));

                            if "Account No." <> '' then
                                case "Account Type" of
                                    "Account Type"::"G/L Account":
                                        CheckGLAcc("Gen. Journal Line", AccName);
                                    "Account Type"::Customer:
                                        CheckCust("Gen. Journal Line", AccName);
                                    "Account Type"::Vendor:
                                        CheckVend("Gen. Journal Line", AccName);
                                    "Account Type"::"Bank Account":
                                        CheckBankAcc("Gen. Journal Line", AccName);
                                    "Account Type"::"Fixed Asset":
                                        CheckFixedAsset("Gen. Journal Line", AccName);
                                end;
                            if "Bal. Account No." <> '' then begin
                                CODEUNIT.Run(CODEUNIT::"Exchange Acc. G/L Journal Line", "Gen. Journal Line");
                                case "Account Type" of
                                    "Account Type"::"G/L Account":
                                        CheckGLAcc("Gen. Journal Line", BalAccName);
                                    "Account Type"::Customer:
                                        CheckCust("Gen. Journal Line", BalAccName);
                                    "Account Type"::Vendor:
                                        CheckVend("Gen. Journal Line", BalAccName);
                                    "Account Type"::"Bank Account":
                                        CheckBankAcc("Gen. Journal Line", BalAccName);
                                    "Account Type"::"Fixed Asset":
                                        CheckFixedAsset("Gen. Journal Line", BalAccName);
                                end;
                                CODEUNIT.Run(CODEUNIT::"Exchange Acc. G/L Journal Line", "Gen. Journal Line");
                            end;

                            if not DimMgt.CheckDimIDComb("Dimension Set ID") then
                                AddError(DimMgt.GetDimCombErr());

                            TableID[1] := DimMgt.TypeToTableID1("Account Type".AsInteger());
                            No[1] := "Account No.";
                            TableID[2] := DimMgt.TypeToTableID1("Bal. Account Type".AsInteger());
                            No[2] := "Bal. Account No.";
                            TableID[3] := Database::Job;
                            No[3] := "Job No.";
                            TableID[4] := Database::"Salesperson/Purchaser";
                            No[4] := "Salespers./Purch. Code";
                            TableID[5] := Database::Campaign;
                            No[5] := "Campaign No.";

                            if not DimMgt.CheckDimValuePosting(TableID, No, "Dimension Set ID") then
                                AddError(DimMgt.GetDimValuePostingErr());
                        end;

                        CheckBalance();
                    end;

                    trigger OnPreDataItem()
                    begin
                        GenJnlTemplate.Get("Gen. Journal Batch"."Journal Template Name");
                        if GenJnlTemplate.Recurring then begin
                            if GetFilter("Posting Date") <> '' then
                                AddError(
                                  StrSubstNo(
                                    Text000,
                                    FieldCaption("Posting Date")));
                            SetRange("Posting Date", 0D, WorkDate());
                            if GetFilter("Expiration Date") <> '' then
                                AddError(
                                  StrSubstNo(
                                    Text000,
                                    FieldCaption("Expiration Date")));
                            SetFilter("Expiration Date", '%1 | %2..', 0D, WorkDate());
                        end;

                        if "Gen. Journal Batch"."No. Series" <> '' then begin
                            NoSeries.Get("Gen. Journal Batch"."No. Series");
                            LastEntrdDocNo := '';
                            LastEntrdDate := 0D;
                        end;

                        CurrentCustomerVendors := 0;
                        VATEntryCreated := false;

                        GenJnlLine2.Reset();
                        GenJnlLine2.CopyFilters("Gen. Journal Line");

                        GLAccNetChange.DeleteAll();
                    end;
                }
                dataitem(ReconcileLoop; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    column(GLAccNetChangeName; GLAccNetChange.Name)
                    {
                    }
                    column(GLAccNetChangeBalanceafterPosting; GLAccNetChange."Balance after Posting")
                    {
                    }
                    column(NoCaption; NoCaptionLbl)
                    {
                    }
                    column(NetChangeInJnlCaption; NetChangeInJnlCaptionLbl)
                    {
                    }
                    column(Number_ReconcileLoop; Number)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if Number = 1 then
                            GLAccNetChange.Find('-')
                        else
                            GLAccNetChange.Next();
                    end;

                    trigger OnPostDataItem()
                    begin
                        GLAccNetChange.DeleteAll();
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange(Number, 1, GLAccNetChange.Count);
                    end;
                }
            }

            trigger OnPreDataItem()
            begin
                GLSetup.Get();
                SalesSetup.Get();
                PurchSetup.Get();
                AmountLCY := 0;
                BalanceLCY := 0;
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
                    field(ShowOnlyOCRErrors; ShowOnlyOCRErrors)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show only Lines with OCR Errors';
                        ToolTip = 'Specifies if you want to print only the journal lines that contain a warning in the test report.';
                    }
                    field(ShowDim; ShowDim)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Dimensions';
                        ToolTip = 'Specifies if you want dimensions information for the journal lines to be included in the report.';
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

    trigger OnPreReport()
    begin
        GenJnlLineFilter := "Gen. Journal Line".GetFilters();
    end;

    var
        Text000: Label '%1 cannot be filtered when you post recurring journals.';
        Text001: Label '%1 or %2 must be specified.';
        Text002: Label '%1 must be specified.';
        AmountNotEqualMsg: Label 'VAT Amount + VAT Base Amount must be Amount.';
        AmountLCYNotEqualMsg: Label 'VAT Amount (LCY) + VAT Base Amount (LCY) must be Amount (LCY).';
        Text004: Label '%1 must be " " when %2 is %3.';
        AccountsNotCompletedMsg: Label 'Gen. Bus. Posting Group, Gen. Prod. Posting Group, VAT Bus. Posting Group or VAT Prod. Posting Group must not be completed when Account Type is %1.';
        BalAccountsNotCompletedMsg: Label 'Bal. Gen. Bus. Posting Group, Bal. Gen. Prod. Posting Group, Bal. VAT Bus. Posting Group or Bal. VAT Prod. Posting Group must not be completed when Bal. Account Type is %1.';
        Text006: Label '%1 must be negative.';
        Text007: Label '%1 must be positive.';
        Text008: Label '%1 must have the same sign as %2.';
        Text009: Label '%1 cannot be specified.';
        Text010: Label '%1 must be Yes.';
        BalAmountNotEqualMsg: Label 'Bal. VAT Amount + Bal. VAT Base Amount must be -Amount.';
        BalAmountLCYNotEqualMsg: Label 'Bal. VAT Amount (LCY) + Bal. VAT Base Amount (LCY) must be -Amount (LCY).';
        Text012: Label '%1 must have a different sign than %2.';
        Text013: Label '%1 must only be a closing date for G/L entries.';
        Text014: Label '%1 is not within your allowed range of posting dates.';
        Text015: Label 'The lines are not listed according to Posting Date because they were not entered in that order.';
        Text016: Label 'There is a gap in the number series.';
        Text017: Label '%1 or %2 must be G/L Account or Bank Account.';
        Text018: Label '%1 must be 0.';
        Text019: Label '%1 cannot be specified when using recurring journals.';
        WrongRecurringMethodForAccountTypeMsg: Label 'Recurring Method must not be %1 when Account Type = %2.';
        WrongRecurringMethodForBalAccountTypeMsg: Label 'Recurring Method must not be %1 when Bal. Account Type = %2.';
        Text021: Label 'Allocations can only be used with recurring journals.';
        Text022: Label 'Please specify %1 in the %2 allocation lines.';
        Text023: Label '<Month Text>', Locked = true;
        Text024: Label '%1 %2 posted on %3, must be separated by an empty line', Comment = 'Parameter 1 - Document Type( ,Payment,Invoice,Credit Memo,Finance Charge Memo,Reminder,Refund), 2 - Document No, 3 - Posting Date';
        Text025: Label '%1 %2 is out of balance by %3.', Comment = 'Parameter 1 - Document Type( ,Payment,Invoice,Credit Memo,Finance Charge Memo,Reminder,Refund), 2 - Document No, 3 - Document Balance';
        Text026: Label 'The reversing entries for %1 %2 are out of balance by %3.', Comment = 'Parameter 1 - Document Type( ,Payment,Invoice,Credit Memo,Finance Charge Memo,Reminder,Refund), 2 - Document No, 3 - Document Balance';
        Text027: Label 'As of %1, the lines are out of balance by %2.';
        Text028: Label 'As of %1, the reversing entries are out of balance by %2.';
        Text029: Label 'The total of the lines is out of balance by %1.';
        Text030: Label 'The total of the reversing entries is out of balance by %1.';
        Text031: Label '%1 %2 does not exist.', Comment = 'Parameter 1 - Table caption, 2 - Account No.';
        Text032: Label '%1 must be %2 for %3 %4.', Comment = 'Parameter 1 - field caption, 2 - type or boolean value, 3 - table caption, 4 - account no.';
        Text036: Label '%1 %2 %3 does not exist.', Comment = 'Parameter 1 - Table Caption, 2 - value A, 3 - value B';
        Text037: Label '%1 must be %2.';
        Text038: Label 'The currency %1 cannot be found. Please check the currency table.';
        Text039: Label 'Sales %1 %2 already exists.', Comment = 'Parameter 1 - Document Type, 2 - Document No.';
        Text040: Label 'Purchase %1 %2 already exists for this vendor.', Comment = 'Parameter 1 - Document Type, 2 - Document No.';
        Text041: Label '%1 must be entered.';
        Text042: Label '%1 must not be filled when %2 is different in %3 and %4.';
        WrongBudgetAssetMsg: Label 'Fixed Asset %1 must not have Budget Asset = %2.';
        Text044: Label '%1 must not be specified in fixed asset journal lines.';
        Text045: Label '%1 must be specified in fixed asset journal lines.';
        Text046: Label '%1 must be different than %2.';
        Text047: Label '%1 and %2 must not both be %3.';
        NonEmptyGenPostingTypeMsg: Label 'Gen. Posting Type must not be specified when FA Posting Type = %1.';
        Text049: Label '%1 must not be specified when FA Posting Type = %2.';
        Text050: Label 'must not be specified together with FA Posting Type = %1.';
        Text051: Label '%1 must be identical to %2.';
        Text052: Label '%1 cannot be a closing date.';
        Text053: Label '%1 is not within your range of allowed posting dates.';
        Text054: Label 'Insurance integration is not activated for Depreciation Book Code %1.';
        Text055: Label 'must not be specified when %1 is specified.';
        Text056: Label 'When G/L integration is not activated, %1 must not be posted in the general journal.';
        Text057: Label 'When G/L integration is not activated, %1 must not be specified in the general journal.';
        Text058: Label '%1 must not be specified.';
        Text059: Label 'Customer and Gen. Posting Type Purchase are not allowed.';
        Text060: Label 'Vendor and Gen. Posting Type Sales are not allowed.';
        Text061: Label 'The Balance and Reversing Balance recurring methods can be used only with Allocations.';
        Text062: Label '%1 must not be 0.';
        GLSetup: Record "General Ledger Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        PurchSetup: Record "Purchases & Payables Setup";
        UserSetup: Record "User Setup";
        AccountingPeriod: Record "Accounting Period";
        GLAcc: Record "G/L Account";
        Currency: Record Currency;
        Cust: Record Customer;
        Vend: Record Vendor;
        BankAccPostingGr: Record "Bank Account Posting Group";
        BankAcc: Record "Bank Account";
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlLine2: Record "Gen. Journal Line";
        GenJnlAlloc: Record "Gen. Jnl. Allocation";
        OldCustLedgEntry: Record "Cust. Ledger Entry";
        OldVendLedgEntry: Record "Vendor Ledger Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        NoSeries: Record "No. Series";
        FA: Record "Fixed Asset";
        DeprBook: Record "Depreciation Book";
        FADeprBook: Record "FA Depreciation Book";
        FASetup: Record "FA Setup";
        GLAccNetChange: Record "G/L Account Net Change" temporary;
        DimSetEntry: Record "Dimension Set Entry";
        GenJnlLineFilter: Text[250];
        AllowPostingFrom: Date;
        AllowPostingTo: Date;
        AllowFAPostingFrom: Date;
        AllowFAPostingTo: Date;
        LastDate: Date;
        LastDocType: Enum "Gen. Journal Document Type";
        LastDocNo: Code[20];
        LastEntrdDocNo: Code[20];
        LastEntrdDate: Date;
        DocBalance: Decimal;
        DocBalanceReverse: Decimal;
        DateBalance: Decimal;
        DateBalanceReverse: Decimal;
        BalanceLCY: Decimal;
        AmountLCY: Decimal;
        TotalBalance: Decimal;
        TotalBalanceReverse: Decimal;
        AccName: Text[100];
        LastLineNo: Integer;
        Day: Integer;
        Week: Integer;
        Month: Integer;
        MonthText: Text[30];
        AmountError: Boolean;
        ErrorCounter: Integer;
        ErrorText: array[50] of Text[250];
        TempErrorText: Text[250];
        BalAccName: Text[100];
        CurrentCustomerVendors: Integer;
        VATEntryCreated: Boolean;
        CustPosting: Boolean;
        VendPosting: Boolean;
        SalesPostingType: Boolean;
        PurchPostingType: Boolean;
        DimText: Text[120];
        OldDimText: Text[75];
        ShowDim: Boolean;
        Continue: Boolean;
        Text063: Label 'Document,Payment,Invoice,Credit Memo,Finance Charge Memo,Reminder';
        OCRWarningText: Text[100];
        ShowOnlyOCRErrors: Boolean;
        OCRJournalTestCaptionLbl: Label 'OCR Journal - Test';
        PageCaptionLbl: Label 'Page';
        JournalBatchCaptionLbl: Label 'Journal Batch';
        DocumentTypeCaptionLbl: Label 'Document Type';
        AccountTypeCaptionLbl: Label 'Account Type';
        NameCaptionLbl: Label 'Name';
        GenPostingTypeCaptionLbl: Label 'Gen. Posting Type';
        TotalLCYCaptionLbl: Label 'Total (LCY)';
        OCRCaptionLbl: Label 'OCR';
        WarningCaptionLbl: Label 'Warning!';
        NoCaptionLbl: Label 'No.';
        NetChangeInJnlCaptionLbl: Label 'Net Change in Jnl.';

    local procedure CheckRecurringLine(GenJnlLine2: Record "Gen. Journal Line")
    begin
        if GenJnlTemplate.Recurring then begin
            if GenJnlLine2."Recurring Method" = GenJnlLine2."Recurring Method"::" " then
                AddError(StrSubstNo(Text002, GenJnlLine2.FieldCaption("Recurring Method")));
            if Format(GenJnlLine2."Recurring Frequency") = '' then
                AddError(StrSubstNo(Text002, GenJnlLine2.FieldCaption("Recurring Frequency")));
            if GenJnlLine2."Bal. Account No." <> '' then
                AddError(
                  StrSubstNo(
                    Text019,
                    GenJnlLine2.FieldCaption("Bal. Account No.")));
            case GenJnlLine2."Recurring Method" of
                GenJnlLine2."Recurring Method"::"V  Variable", GenJnlLine2."Recurring Method"::"RV Reversing Variable",
              GenJnlLine2."Recurring Method"::"F  Fixed", GenJnlLine2."Recurring Method"::"RF Reversing Fixed":
                    WarningIfZeroAmt("Gen. Journal Line");
                GenJnlLine2."Recurring Method"::"B  Balance", GenJnlLine2."Recurring Method"::"RB Reversing Balance":
                    WarningIfNonZeroAmt("Gen. Journal Line");
            end;
            if GenJnlLine2."Recurring Method".AsInteger() > GenJnlLine2."Recurring Method"::"V  Variable".AsInteger() then begin
                if GenJnlLine2."Account Type" = GenJnlLine2."Account Type"::"Fixed Asset" then
                    AddError(
                      StrSubstNo(WrongRecurringMethodForAccountTypeMsg, GenJnlLine2."Recurring Method", GenJnlLine2."Account Type"));
                if GenJnlLine2."Bal. Account Type" = GenJnlLine2."Bal. Account Type"::"Fixed Asset" then
                    AddError(
                      StrSubstNo(WrongRecurringMethodForBalAccountTypeMsg, GenJnlLine2."Recurring Method", GenJnlLine2."Bal. Account Type"));
            end;
        end else begin
            if GenJnlLine2."Recurring Method" <> GenJnlLine2."Recurring Method"::" " then
                AddError(StrSubstNo(Text009, GenJnlLine2.FieldCaption("Recurring Method")));
            if Format(GenJnlLine2."Recurring Frequency") <> '' then
                AddError(StrSubstNo(Text009, GenJnlLine2.FieldCaption("Recurring Frequency")));
        end;
    end;

    local procedure CheckAllocations(GenJnlLine2: Record "Gen. Journal Line")
    begin
        if GenJnlLine2."Recurring Method" in
            [GenJnlLine2."Recurring Method"::"B  Balance",
             GenJnlLine2."Recurring Method"::"RB Reversing Balance"]
        then begin
            GenJnlAlloc.Reset();
            GenJnlAlloc.SetRange("Journal Template Name", GenJnlLine2."Journal Template Name");
            GenJnlAlloc.SetRange("Journal Batch Name", GenJnlLine2."Journal Batch Name");
            GenJnlAlloc.SetRange("Journal Line No.", GenJnlLine2."Line No.");
            if not GenJnlAlloc.FindFirst() then
                AddError(Text061);
        end;

        GenJnlAlloc.Reset();
        GenJnlAlloc.SetRange("Journal Template Name", GenJnlLine2."Journal Template Name");
        GenJnlAlloc.SetRange("Journal Batch Name", GenJnlLine2."Journal Batch Name");
        GenJnlAlloc.SetRange("Journal Line No.", GenJnlLine2."Line No.");
        GenJnlAlloc.SetFilter(Amount, '<>0');
        if GenJnlAlloc.FindFirst() then
            if not GenJnlTemplate.Recurring then
                AddError(Text021)
            else begin
                GenJnlAlloc.SetRange("Account No.", '');
                if GenJnlAlloc.FindFirst() then
                    AddError(
                      StrSubstNo(
                        Text022,
                        GenJnlAlloc.FieldCaption("Account No."), GenJnlAlloc.Count));
            end;
    end;

    local procedure MakeRecurringTexts(var GenJnlLine2: Record "Gen. Journal Line")
    begin
        if (GenJnlLine2."Posting Date" <> 0D) and (GenJnlLine2."Account No." <> '') and (GenJnlLine2."Recurring Method" <> GenJnlLine2."Recurring Method"::" ") then begin
            Day := Date2DMY(GenJnlLine2."Posting Date", 1);
            Week := Date2DWY(GenJnlLine2."Posting Date", 2);
            Month := Date2DMY(GenJnlLine2."Posting Date", 2);
            MonthText := Format(GenJnlLine2."Posting Date", 0, Text023);
            AccountingPeriod.SetRange("Starting Date", 0D, GenJnlLine2."Posting Date");
            if not AccountingPeriod.FindLast() then
                AccountingPeriod.Name := '';
            GenJnlLine2."Document No." :=
              DelChr(
                PadStr(
                  StrSubstNo(GenJnlLine2."Document No.", Day, Week, Month, MonthText, AccountingPeriod.Name),
                  MaxStrLen(GenJnlLine2."Document No.")),
                '>');
            GenJnlLine2.Description :=
              DelChr(
                PadStr(
                  StrSubstNo(GenJnlLine2.Description, Day, Week, Month, MonthText, AccountingPeriod.Name),
                  MaxStrLen(GenJnlLine2.Description)),
                '>');
        end;
    end;

    local procedure CheckBalance()
    var
        GenJnlLine: Record "Gen. Journal Line";
        NextGenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine := "Gen. Journal Line";
        LastLineNo := "Gen. Journal Line"."Line No.";
        if "Gen. Journal Line".Next() = 0 then;
        NextGenJnlLine := "Gen. Journal Line";
        MakeRecurringTexts(NextGenJnlLine);
        "Gen. Journal Line" := GenJnlLine;
        if not GenJnlLine.EmptyLine() then begin
            DocBalance := DocBalance + GenJnlLine."Balance (LCY)";
            DateBalance := DateBalance + GenJnlLine."Balance (LCY)";
            TotalBalance := TotalBalance + GenJnlLine."Balance (LCY)";
            if GenJnlLine."Recurring Method".AsInteger() >= GenJnlLine."Recurring Method"::"RF Reversing Fixed".AsInteger() then begin
                DocBalanceReverse := DocBalanceReverse + GenJnlLine."Balance (LCY)";
                DateBalanceReverse := DateBalanceReverse + GenJnlLine."Balance (LCY)";
                TotalBalanceReverse := TotalBalanceReverse + GenJnlLine."Balance (LCY)";
            end;
            LastDocType := GenJnlLine."Document Type";
            LastDocNo := GenJnlLine."Document No.";
            LastDate := GenJnlLine."Posting Date";
            if TotalBalance = 0 then begin
                CurrentCustomerVendors := 0;
                VATEntryCreated := false;
            end;
            if GenJnlTemplate."Force Doc. Balance" then begin
                VATEntryCreated :=
                  VATEntryCreated or
                  ((GenJnlLine."Account Type" = GenJnlLine."Account Type"::"G/L Account") and (GenJnlLine."Account No." <> '') and
                   (GenJnlLine."Gen. Posting Type" in [GenJnlLine."Gen. Posting Type"::Purchase, GenJnlLine."Gen. Posting Type"::Sale])) or
                  ((GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::"G/L Account") and (GenJnlLine."Bal. Account No." <> '') and
                   (GenJnlLine."Bal. Gen. Posting Type" in [GenJnlLine."Bal. Gen. Posting Type"::Purchase, GenJnlLine."Bal. Gen. Posting Type"::Sale]));
                if ((GenJnlLine."Account Type" in [GenJnlLine."Account Type"::Customer, GenJnlLine."Account Type"::Vendor]) and
                    (GenJnlLine."Account No." <> '')) or
                   ((GenJnlLine."Bal. Account Type" in [GenJnlLine."Bal. Account Type"::Customer, GenJnlLine."Bal. Account Type"::Vendor]) and
                    (GenJnlLine."Bal. Account No." <> ''))
                then
                    CurrentCustomerVendors := CurrentCustomerVendors + 1;
                if (CurrentCustomerVendors > 1) and VATEntryCreated then
                    AddError(
                      StrSubstNo(
                        Text024,
                        GenJnlLine."Document Type", GenJnlLine."Document No.", GenJnlLine."Posting Date"));
            end;
        end;

        if GenJnlTemplate."Force Doc. Balance" and
            (LastDate <> 0D) and (LastDocNo <> '') and
            ((NextGenJnlLine."Posting Date" <> LastDate) or
            (NextGenJnlLine."Document Type" <> LastDocType) or
            (NextGenJnlLine."Document No." <> LastDocNo) or
            (NextGenJnlLine."Line No." = LastLineNo))
        then begin
            case true of
                DocBalance <> 0:
                    AddError(
                      StrSubstNo(
                        Text025,
                        SelectStr(LastDocType.AsInteger() + 1, Text063), LastDocNo, DocBalance));
                DocBalanceReverse <> 0:
                    AddError(
                      StrSubstNo(
                        Text026,
                        SelectStr(LastDocType.AsInteger() + 1, Text063), LastDocNo, DocBalanceReverse));
            end;
            DocBalance := 0;
            DocBalanceReverse := 0;
            if (NextGenJnlLine."Posting Date" <> LastDate) or
               (NextGenJnlLine."Document Type" <> LastDocType) or (NextGenJnlLine."Document No." <> LastDocNo)
            then begin
                CurrentCustomerVendors := 0;
                VATEntryCreated := false;
                CustPosting := false;
                VendPosting := false;
                SalesPostingType := false;
                PurchPostingType := false;
            end;
        end;

        if (LastDate <> 0D) and ((NextGenJnlLine."Posting Date" <> LastDate) or (NextGenJnlLine."Line No." = LastLineNo)) then begin
            case true of
                DateBalance <> 0:
                    AddError(
                      StrSubstNo(
                        Text027,
                        LastDate, DateBalance));
                DateBalanceReverse <> 0:
                    AddError(
                      StrSubstNo(
                        Text028,
                        LastDate, DateBalanceReverse));
            end;
            DocBalance := 0;
            DocBalanceReverse := 0;
            DateBalance := 0;
            DateBalanceReverse := 0;
        end;

        if NextGenJnlLine."Line No." = LastLineNo then begin
            case true of
                TotalBalance <> 0:
                    AddError(
                      StrSubstNo(
                        Text029,
                        TotalBalance));
                TotalBalanceReverse <> 0:
                    AddError(
                      StrSubstNo(
                        Text030,
                        TotalBalanceReverse));
            end;
            DocBalance := 0;
            DocBalanceReverse := 0;
            DateBalance := 0;
            DateBalanceReverse := 0;
            TotalBalance := 0;
            TotalBalanceReverse := 0;
            LastDate := 0D;
            LastDocType := LastDocType::" ";
            LastDocNo := '';
        end;

        AmountLCY += "Gen. Journal Line"."Amount (LCY)";
        BalanceLCY += "Gen. Journal Line"."Balance (LCY)";
    end;

    local procedure AddError(Text: Text[250])
    begin
        ErrorCounter := ErrorCounter + 1;
        ErrorText[ErrorCounter] := Text;
    end;

    local procedure ReconcileGLAccNo(GLAccNo: Code[20]; ReconcileAmount: Decimal)
    begin
        if not GLAccNetChange.Get(GLAccNo) then begin
            GLAcc.Get(GLAccNo);
            GLAcc.CalcFields("Balance at Date");
            GLAccNetChange.Init();
            GLAccNetChange."No." := GLAcc."No.";
            GLAccNetChange.Name := GLAcc.Name;
            GLAccNetChange."Balance after Posting" := GLAcc."Balance at Date";
            GLAccNetChange.Insert();
        end;
        GLAccNetChange."Net Change in Jnl." := GLAccNetChange."Net Change in Jnl." + ReconcileAmount;
        GLAccNetChange."Balance after Posting" := GLAccNetChange."Balance after Posting" + ReconcileAmount;
        GLAccNetChange.Modify();
    end;

    local procedure CheckGLAcc(var GenJnlLine: Record "Gen. Journal Line"; var AccName: Text[100])
    begin
        if not GLAcc.Get(GenJnlLine."Account No.") then
            AddError(
              StrSubstNo(
                Text031,
                GLAcc.TableCaption(), GenJnlLine."Account No."))
        else begin
            AccName := GLAcc.Name;

            if GLAcc.Blocked then
                AddError(
                  StrSubstNo(
                    Text032,
                    GLAcc.FieldCaption(Blocked), false, GLAcc.TableCaption(), GenJnlLine."Account No."));
            if GLAcc."Account Type" <> GLAcc."Account Type"::Posting then begin
                GLAcc."Account Type" := GLAcc."Account Type"::Posting;
                AddError(
                  StrSubstNo(
                    Text032,
                    GLAcc.FieldCaption("Account Type"), GLAcc."Account Type", GLAcc.TableCaption(), GenJnlLine."Account No."));
            end;
            if not GenJnlLine."System-Created Entry" then
                if GenJnlLine."Posting Date" = NormalDate(GenJnlLine."Posting Date") then
                    if not GLAcc."Direct Posting" then
                        AddError(
                          StrSubstNo(
                            Text032,
                            GLAcc.FieldCaption("Direct Posting"), true, GLAcc.TableCaption(), GenJnlLine."Account No."));

            if GenJnlLine."Gen. Posting Type" <> GenJnlLine."Gen. Posting Type"::" " then begin
                case GenJnlLine."Gen. Posting Type" of
                    GenJnlLine."Gen. Posting Type"::Sale:
                        SalesPostingType := true;
                    GenJnlLine."Gen. Posting Type"::Purchase:
                        PurchPostingType := true;
                end;
                TestPostingType();

                if not VATPostingSetup.Get(GenJnlLine."VAT Bus. Posting Group", GenJnlLine."VAT Prod. Posting Group") then
                    AddError(
                      StrSubstNo(
                        Text036,
                        VATPostingSetup.TableCaption(), GenJnlLine."VAT Bus. Posting Group", GenJnlLine."VAT Prod. Posting Group"))
                else
                    if GenJnlLine."VAT Calculation Type" <> VATPostingSetup."VAT Calculation Type" then
                        AddError(
                          StrSubstNo(
                            Text037,
                            GenJnlLine.FieldCaption("VAT Calculation Type"), VATPostingSetup."VAT Calculation Type"))
            end;

            if GLAcc."Reconciliation Account" then
                ReconcileGLAccNo(GenJnlLine."Account No.", Round(GenJnlLine."Amount (LCY)" / (1 + GenJnlLine."VAT %" / 100)));
        end;
    end;

    local procedure CheckCust(var GenJnlLine: Record "Gen. Journal Line"; var AccName: Text[100])
    begin
        if not Cust.Get(GenJnlLine."Account No.") then
            AddError(
              StrSubstNo(
                Text031,
                Cust.TableCaption(), GenJnlLine."Account No."))
        else begin
            AccName := Cust.Name;

            if Cust."Privacy Blocked" then
                AddError(
                  StrSubstNo(
                    Text032,
                    Cust.FieldCaption("Privacy Blocked"), false, Cust.TableCaption(), GenJnlLine."Account No."));
            if Cust.Blocked <> Cust.Blocked::" " then
                AddError(
                  StrSubstNo(
                    Text032,
                    Cust.FieldCaption(Blocked), false, Cust.TableCaption(), GenJnlLine."Account No."));
            if GenJnlLine."Currency Code" <> '' then
                if not Currency.Get(GenJnlLine."Currency Code") then
                    AddError(
                      StrSubstNo(
                        Text038,
                        GenJnlLine."Currency Code"));

            CustPosting := true;
            TestPostingType();

            if GenJnlLine."Recurring Method" = GenJnlLine."Recurring Method"::" " then
                if GenJnlLine."Document Type" in
                   [GenJnlLine."Document Type"::Invoice, GenJnlLine."Document Type"::"Credit Memo",
                    GenJnlLine."Document Type"::"Finance Charge Memo"]
                then begin
                    OldCustLedgEntry.Reset();
                    OldCustLedgEntry.SetCurrentKey("Document Type", "Document No.", "Customer No.");
                    OldCustLedgEntry.SetRange("Document Type", GenJnlLine."Document Type");
                    OldCustLedgEntry.SetRange("Document No.", GenJnlLine."Document No.");
                    if OldCustLedgEntry.FindFirst() then
                        AddError(StrSubstNo(Text039, GenJnlLine."Document Type", GenJnlLine."Document No."));
                end;

            if SalesSetup."Ext. Doc. No. Mandatory" then
                GenJnlLine.TestField("External Document No.");
        end;
    end;

    local procedure CheckVend(var GenJnlLine: Record "Gen. Journal Line"; var AccName: Text[100])
    begin
        if not Vend.Get(GenJnlLine."Account No.") then
            AddError(
              StrSubstNo(
                Text031,
                Vend.TableCaption(), GenJnlLine."Account No."))
        else begin
            AccName := Vend.Name;

            if Vend."Privacy Blocked" then
                AddError(
                  StrSubstNo(
                    Text032,
                    Vend.FieldCaption("Privacy Blocked"), false, Vend.TableCaption(), GenJnlLine."Account No."));
            if Vend.Blocked <> Vend.Blocked::" " then
                AddError(
                  StrSubstNo(
                    Text032,
                    Vend.FieldCaption(Blocked), false, Vend.TableCaption(), GenJnlLine."Account No."));
            if GenJnlLine."Currency Code" <> '' then
                if not Currency.Get(GenJnlLine."Currency Code") then
                    AddError(
                      StrSubstNo(
                        Text038,
                        GenJnlLine."Currency Code"));

            VendPosting := true;
            TestPostingType();

            if GenJnlLine."Recurring Method" = GenJnlLine."Recurring Method"::" " then
                if GenJnlLine."Document Type" in
                   [GenJnlLine."Document Type"::Invoice, GenJnlLine."Document Type"::"Credit Memo",
                    GenJnlLine."Document Type"::"Finance Charge Memo"]
                then begin
                    OldVendLedgEntry.Reset();
                    OldVendLedgEntry.SetCurrentKey("Document No.");
                    OldVendLedgEntry.SetRange("Document Type", GenJnlLine."Document Type");
                    OldVendLedgEntry.SetRange("Document No.", GenJnlLine."Document No.");
                    OldVendLedgEntry.SetRange("Vendor No.", GenJnlLine."Account No.");
                    if OldVendLedgEntry.FindFirst() then
                        AddError(
                          StrSubstNo(
                            Text040,
                            GenJnlLine."Document Type", GenJnlLine."Document No."));

                    if PurchSetup."Ext. Doc. No. Mandatory" or
                       (GenJnlLine."External Document No." <> '')
                    then begin
                        if GenJnlLine."External Document No." = '' then
                            AddError(
                              StrSubstNo(
                                Text041, GenJnlLine.FieldCaption("External Document No.")));
                        OldVendLedgEntry.Reset();
                        OldVendLedgEntry.SetCurrentKey("External Document No.");
                        OldVendLedgEntry.SetRange("Document Type", GenJnlLine."Document Type");
                        OldVendLedgEntry.SetRange("External Document No.", GenJnlLine."External Document No.");
                        OldVendLedgEntry.SetRange("Vendor No.", GenJnlLine."Account No.");
                        if OldVendLedgEntry.FindFirst() then
                            AddError(
                              StrSubstNo(
                                Text040,
                                GenJnlLine."Document Type", GenJnlLine."External Document No."));
                    end;
                end;
        end;
    end;

    local procedure CheckBankAcc(var GenJnlLine: Record "Gen. Journal Line"; var AccName: Text[100])
    begin
        if not BankAcc.Get(GenJnlLine."Account No.") then
            AddError(
              StrSubstNo(
                Text031,
                BankAcc.TableCaption(), GenJnlLine."Account No."))
        else begin
            AccName := BankAcc.Name;

            if BankAcc.Blocked then
                AddError(
                  StrSubstNo(
                    Text032,
                    BankAcc.FieldCaption(Blocked), false, BankAcc.TableCaption(), GenJnlLine."Account No."));
            if (GenJnlLine."Currency Code" <> BankAcc."Currency Code") and (BankAcc."Currency Code" <> '') then
                AddError(
                  StrSubstNo(
                    Text037,
                    GenJnlLine.FieldCaption("Currency Code"), BankAcc."Currency Code"));

            if GenJnlLine."Currency Code" <> '' then
                if not Currency.Get(GenJnlLine."Currency Code") then
                    AddError(
                      StrSubstNo(
                        Text038,
                        GenJnlLine."Currency Code"));

            if GenJnlLine."Bank Payment Type" <> GenJnlLine."Bank Payment Type"::" " then
                if (GenJnlLine."Bank Payment Type" = GenJnlLine."Bank Payment Type"::"Computer Check") and (GenJnlLine.Amount < 0) then
                    if BankAcc."Currency Code" <> GenJnlLine."Currency Code" then
                        AddError(
                          StrSubstNo(
                            Text042,
                            GenJnlLine.FieldCaption("Bank Payment Type"), GenJnlLine.FieldCaption("Currency Code"),
                            GenJnlLine.TableCaption, BankAcc.TableCaption()));

            if BankAccPostingGr.Get(BankAcc."Bank Acc. Posting Group") then
                if BankAccPostingGr."G/L Account No." <> '' then
                    ReconcileGLAccNo(
                      BankAccPostingGr."G/L Account No.",
                      Round(GenJnlLine."Amount (LCY)" / (1 + GenJnlLine."VAT %" / 100)));
        end;
    end;

    local procedure CheckFixedAsset(var GenJnlLine: Record "Gen. Journal Line"; var AccName: Text[100])
    begin
        if not FA.Get(GenJnlLine."Account No.") then
            AddError(
              StrSubstNo(
                Text031,
                FA.TableCaption(), GenJnlLine."Account No."))
        else begin
            AccName := FA.Description;
            if FA.Blocked then
                AddError(
                  StrSubstNo(
                    Text032,
                    FA.FieldCaption(Blocked), false, FA.TableCaption(), GenJnlLine."Account No."));
            if FA.Inactive then
                AddError(
                  StrSubstNo(
                    Text032,
                    FA.FieldCaption(Inactive), false, FA.TableCaption(), GenJnlLine."Account No."));
            if FA."Budgeted Asset" then
                AddError(
                  StrSubstNo(WrongBudgetAssetMsg, GenJnlLine."Account No.", true));
            if DeprBook.Get(GenJnlLine."Depreciation Book Code") then
                CheckFAIntegration(GenJnlLine)
            else
                AddError(
                  StrSubstNo(
                    Text031,
                    DeprBook.TableCaption(), GenJnlLine."Depreciation Book Code"));
            if not FADeprBook.Get(FA."No.", GenJnlLine."Depreciation Book Code") then
                AddError(
                  StrSubstNo(
                    Text036,
                    FADeprBook.TableCaption(), FA."No.", GenJnlLine."Depreciation Book Code"));
        end;
    end;

    local procedure TestFixedAsset(var GenJnlLine: Record "Gen. Journal Line")
    begin
        if GenJnlLine."Job No." <> '' then
            AddError(
              StrSubstNo(
                Text044, GenJnlLine.FieldCaption("Job No.")));
        if GenJnlLine."FA Posting Type" = GenJnlLine."FA Posting Type"::" " then
            AddError(
              StrSubstNo(
                Text045, GenJnlLine.FieldCaption("FA Posting Type")));
        if GenJnlLine."Depreciation Book Code" = '' then
            AddError(
              StrSubstNo(
                Text045, GenJnlLine.FieldCaption("Depreciation Book Code")));
        if GenJnlLine."Depreciation Book Code" = GenJnlLine."Duplicate in Depreciation Book" then
            AddError(
              StrSubstNo(
                Text046,
                GenJnlLine.FieldCaption("Depreciation Book Code"), GenJnlLine.FieldCaption("Duplicate in Depreciation Book")));
        if GenJnlLine."Account Type" = GenJnlLine."Bal. Account Type" then
            AddError(
              StrSubstNo(
                Text047,
                GenJnlLine.FieldCaption("Account Type"), GenJnlLine.FieldCaption("Bal. Account Type"), GenJnlLine."Account Type"));
        if GenJnlLine."Account Type" = GenJnlLine."Account Type"::"Fixed Asset" then
            if GenJnlLine."FA Posting Type" in
               [GenJnlLine."FA Posting Type"::"Acquisition Cost", GenJnlLine."FA Posting Type"::Disposal, GenJnlLine."FA Posting Type"::Maintenance]
            then begin
                if (GenJnlLine."Gen. Bus. Posting Group" <> '') or (GenJnlLine."Gen. Prod. Posting Group" <> '') then
                    if GenJnlLine."Gen. Posting Type" = GenJnlLine."Gen. Posting Type"::" " then
                        AddError(StrSubstNo(Text002, GenJnlLine.FieldCaption("Gen. Posting Type")));
            end else begin
                if GenJnlLine."Gen. Posting Type" <> GenJnlLine."Gen. Posting Type"::" " then
                    AddError(StrSubstNo(NonEmptyGenPostingTypeMsg, GenJnlLine."FA Posting Type"));
                if GenJnlLine."Gen. Bus. Posting Group" <> '' then
                    AddError(
                      StrSubstNo(Text049, GenJnlLine.FieldCaption("Gen. Bus. Posting Group"), GenJnlLine."FA Posting Type"));
                if GenJnlLine."Gen. Prod. Posting Group" <> '' then
                    AddError(
                      StrSubstNo(Text049, GenJnlLine.FieldCaption("Gen. Prod. Posting Group"), GenJnlLine."FA Posting Type"));
            end;
        if GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::"Fixed Asset" then
            if GenJnlLine."FA Posting Type" in
               [GenJnlLine."FA Posting Type"::"Acquisition Cost", GenJnlLine."FA Posting Type"::Disposal, GenJnlLine."FA Posting Type"::Maintenance]
            then begin
                if (GenJnlLine."Bal. Gen. Bus. Posting Group" <> '') or (GenJnlLine."Bal. Gen. Prod. Posting Group" <> '') then
                    if GenJnlLine."Bal. Gen. Posting Type" = GenJnlLine."Bal. Gen. Posting Type"::" " then
                        AddError(StrSubstNo(Text002, GenJnlLine.FieldCaption("Bal. Gen. Posting Type")));
            end else begin
                if GenJnlLine."Bal. Gen. Posting Type" <> GenJnlLine."Bal. Gen. Posting Type"::" " then
                    AddError(
                      StrSubstNo(Text049, GenJnlLine.FieldCaption("Bal. Gen. Posting Type"), GenJnlLine."FA Posting Type"));
                if GenJnlLine."Bal. Gen. Bus. Posting Group" <> '' then
                    AddError(
                      StrSubstNo(Text049, GenJnlLine.FieldCaption("Bal. Gen. Bus. Posting Group"), GenJnlLine."FA Posting Type"));
                if GenJnlLine."Bal. Gen. Prod. Posting Group" <> '' then
                    AddError(
                      StrSubstNo(Text049, GenJnlLine.FieldCaption("Bal. Gen. Prod. Posting Group"), GenJnlLine."FA Posting Type"));
            end;
        TempErrorText :=
          '%1 ' + StrSubstNo(Text050, GenJnlLine."FA Posting Type");
        if GenJnlLine."FA Posting Type" <> GenJnlLine."FA Posting Type"::"Acquisition Cost" then begin
            if GenJnlLine."Depr. Acquisition Cost" then
                AddError(StrSubstNo(TempErrorText, GenJnlLine.FieldCaption("Depr. Acquisition Cost")));
            if GenJnlLine."Salvage Value" <> 0 then
                AddError(StrSubstNo(TempErrorText, GenJnlLine.FieldCaption("Salvage Value")));
            if GenJnlLine."FA Posting Type" <> GenJnlLine."FA Posting Type"::Maintenance then
                if GenJnlLine.Quantity <> 0 then
                    AddError(StrSubstNo(TempErrorText, GenJnlLine.FieldCaption(Quantity)));
            if GenJnlLine."Insurance No." <> '' then
                AddError(StrSubstNo(TempErrorText, GenJnlLine.FieldCaption("Insurance No.")));
        end;
        if (GenJnlLine."FA Posting Type" = GenJnlLine."FA Posting Type"::Maintenance) and GenJnlLine."Depr. until FA Posting Date" then
            AddError(StrSubstNo(TempErrorText, GenJnlLine.FieldCaption("Depr. until FA Posting Date")));
        if (GenJnlLine."FA Posting Type" <> GenJnlLine."FA Posting Type"::Maintenance) and (GenJnlLine."Maintenance Code" <> '') then
            AddError(StrSubstNo(TempErrorText, GenJnlLine.FieldCaption("Maintenance Code")));

        if (GenJnlLine."FA Posting Type" <> GenJnlLine."FA Posting Type"::Depreciation) and
           (GenJnlLine."FA Posting Type" <> GenJnlLine."FA Posting Type"::"Custom 1") and
           (GenJnlLine."No. of Depreciation Days" <> 0)
        then
            AddError(StrSubstNo(TempErrorText, GenJnlLine.FieldCaption("No. of Depreciation Days")));

        if (GenJnlLine."FA Posting Type" = GenJnlLine."FA Posting Type"::Disposal) and GenJnlLine."FA Reclassification Entry" then
            AddError(StrSubstNo(TempErrorText, GenJnlLine.FieldCaption("FA Reclassification Entry")));

        if (GenJnlLine."FA Posting Type" = GenJnlLine."FA Posting Type"::Disposal) and (GenJnlLine."Budgeted FA No." <> '') then
            AddError(StrSubstNo(TempErrorText, GenJnlLine.FieldCaption("Budgeted FA No.")));

        if GenJnlLine."FA Posting Date" = 0D then
            GenJnlLine."FA Posting Date" := GenJnlLine."Posting Date";
        if DeprBook.Get(GenJnlLine."Depreciation Book Code") then
            if DeprBook."Use Same FA+G/L Posting Dates" and (GenJnlLine."Posting Date" <> GenJnlLine."FA Posting Date") then
                AddError(
                  StrSubstNo(
                    Text051,
                    GenJnlLine.FieldCaption("Posting Date"), GenJnlLine.FieldCaption("FA Posting Date")));
        if GenJnlLine."FA Posting Date" <> 0D then begin
            if GenJnlLine."FA Posting Date" <> NormalDate(GenJnlLine."FA Posting Date") then
                AddError(
                  StrSubstNo(
                    Text052,
                    GenJnlLine.FieldCaption("FA Posting Date")));
            if not (GenJnlLine."FA Posting Date" in [00020101D .. 99981231D]) then
                AddError(
                  StrSubstNo(
                    Text053,
                    GenJnlLine.FieldCaption("FA Posting Date")));
            if (AllowFAPostingFrom = 0D) and (AllowFAPostingTo = 0D) then begin
                if UserId <> '' then
                    if UserSetup.Get(UserId) then begin
                        AllowFAPostingFrom := UserSetup."Allow FA Posting From";
                        AllowFAPostingTo := UserSetup."Allow FA Posting To";
                    end;
                if (AllowFAPostingFrom = 0D) and (AllowFAPostingTo = 0D) then begin
                    FASetup.Get();
                    AllowFAPostingFrom := FASetup."Allow FA Posting From";
                    AllowFAPostingTo := FASetup."Allow FA Posting To";
                end;
                if AllowFAPostingTo = 0D then
                    AllowFAPostingTo := 99981231D;
            end;
            if (GenJnlLine."FA Posting Date" < AllowFAPostingFrom) or
               (GenJnlLine."FA Posting Date" > AllowFAPostingTo)
            then
                AddError(
                  StrSubstNo(
                    Text053,
                    GenJnlLine.FieldCaption("FA Posting Date")));
        end;
        FASetup.Get();
        if (GenJnlLine."FA Posting Type" = GenJnlLine."FA Posting Type"::"Acquisition Cost") and
           (GenJnlLine."Insurance No." <> '') and (GenJnlLine."Depreciation Book Code" <> FASetup."Insurance Depr. Book")
        then
            AddError(StrSubstNo(Text054, GenJnlLine."Depreciation Book Code"));

        if GenJnlLine."FA Error Entry No." > 0 then begin
            TempErrorText :=
              '%1 ' +
              StrSubstNo(
                Text055,
                GenJnlLine.FieldCaption("FA Error Entry No."));
            if GenJnlLine."Depr. until FA Posting Date" then
                AddError(StrSubstNo(TempErrorText, GenJnlLine.FieldCaption("Depr. until FA Posting Date")));
            if GenJnlLine."Depr. Acquisition Cost" then
                AddError(StrSubstNo(TempErrorText, GenJnlLine.FieldCaption("Depr. Acquisition Cost")));
            if GenJnlLine."Duplicate in Depreciation Book" <> '' then
                AddError(StrSubstNo(TempErrorText, GenJnlLine.FieldCaption("Duplicate in Depreciation Book")));
            if GenJnlLine."Use Duplication List" then
                AddError(StrSubstNo(TempErrorText, GenJnlLine.FieldCaption("Use Duplication List")));
            if GenJnlLine."Salvage Value" <> 0 then
                AddError(StrSubstNo(TempErrorText, GenJnlLine.FieldCaption("Salvage Value")));
            if GenJnlLine."Insurance No." <> '' then
                AddError(StrSubstNo(TempErrorText, GenJnlLine.FieldCaption("Insurance No.")));
            if GenJnlLine."Budgeted FA No." <> '' then
                AddError(StrSubstNo(TempErrorText, GenJnlLine.FieldCaption("Budgeted FA No.")));
            if GenJnlLine."Recurring Method" <> GenJnlLine."Recurring Method"::" " then
                AddError(StrSubstNo(TempErrorText, GenJnlLine.FieldCaption("Recurring Method")));
            if GenJnlLine."FA Posting Type" = GenJnlLine."FA Posting Type"::Maintenance then
                AddError(StrSubstNo(TempErrorText, GenJnlLine."FA Posting Type"));
        end;
    end;

    local procedure CheckFAIntegration(var GenJnlLine: Record "Gen. Journal Line")
    var
        GLIntegration: Boolean;
    begin
        if GenJnlLine."FA Posting Type" = GenJnlLine."FA Posting Type"::" " then
            exit;
        case GenJnlLine."FA Posting Type" of
            GenJnlLine."FA Posting Type"::"Acquisition Cost":
                GLIntegration := DeprBook."G/L Integration - Acq. Cost";
            GenJnlLine."FA Posting Type"::Depreciation:
                GLIntegration := DeprBook."G/L Integration - Depreciation";
            GenJnlLine."FA Posting Type"::"Write-Down":
                GLIntegration := DeprBook."G/L Integration - Write-Down";
            GenJnlLine."FA Posting Type"::Appreciation:
                GLIntegration := DeprBook."G/L Integration - Appreciation";
            GenJnlLine."FA Posting Type"::"Custom 1":
                GLIntegration := DeprBook."G/L Integration - Custom 1";
            GenJnlLine."FA Posting Type"::"Custom 2":
                GLIntegration := DeprBook."G/L Integration - Custom 2";
            GenJnlLine."FA Posting Type"::Disposal:
                GLIntegration := DeprBook."G/L Integration - Disposal";
            GenJnlLine."FA Posting Type"::Maintenance:
                GLIntegration := DeprBook."G/L Integration - Maintenance";
        end;
        if not GLIntegration then
            AddError(
              StrSubstNo(
                Text056,
                GenJnlLine."FA Posting Type"));

        if not DeprBook."G/L Integration - Depreciation" then begin
            if GenJnlLine."Depr. until FA Posting Date" then
                AddError(
                  StrSubstNo(
                    Text057,
                    GenJnlLine.FieldCaption("Depr. until FA Posting Date")));
            if GenJnlLine."Depr. Acquisition Cost" then
                AddError(
                  StrSubstNo(
                    Text057,
                    GenJnlLine.FieldCaption("Depr. Acquisition Cost")));
        end;
    end;

    local procedure TestFixedAssetFields(var GenJnlLine: Record "Gen. Journal Line")
    begin
        if GenJnlLine."FA Posting Type" <> GenJnlLine."FA Posting Type"::" " then
            AddError(StrSubstNo(Text058, GenJnlLine.FieldCaption("FA Posting Type")));
        if GenJnlLine."Depreciation Book Code" <> '' then
            AddError(StrSubstNo(Text058, GenJnlLine.FieldCaption("Depreciation Book Code")));
    end;

    [Scope('OnPrem')]
    procedure TestPostingType()
    begin
        case true of
            CustPosting and PurchPostingType:
                AddError(Text059);
            VendPosting and SalesPostingType:
                AddError(Text060);
        end;
    end;

    local procedure WarningIfNegativeAmt(GenJnlLine: Record "Gen. Journal Line")
    begin
        if (GenJnlLine.Amount < 0) and not AmountError then begin
            AmountError := true;
            AddError(StrSubstNo(Text007, GenJnlLine.FieldCaption(Amount)));
        end;
    end;

    local procedure WarningIfPositiveAmt(GenJnlLine: Record "Gen. Journal Line")
    begin
        if (GenJnlLine.Amount > 0) and not AmountError then begin
            AmountError := true;
            AddError(StrSubstNo(Text006, GenJnlLine.FieldCaption(Amount)));
        end;
    end;

    local procedure WarningIfZeroAmt(GenJnlLine: Record "Gen. Journal Line")
    begin
        if (GenJnlLine.Amount = 0) and not AmountError then begin
            AmountError := true;
            AddError(StrSubstNo(Text002, GenJnlLine.FieldCaption(Amount)));
        end;
    end;

    local procedure WarningIfNonZeroAmt(GenJnlLine: Record "Gen. Journal Line")
    begin
        if (GenJnlLine.Amount <> 0) and not AmountError then begin
            AmountError := true;
            AddError(StrSubstNo(Text062, GenJnlLine.FieldCaption(Amount)));
        end;
    end;

    local procedure GetDimText() DimText: Text[120]
    begin
        Clear(DimText);
        Continue := false;
        repeat
            OldDimText := CopyStr(DimText, 1, MaxStrLen(OldDimText));
            if DimText = '' then
                DimText := StrSubstNo('%1 - %2', DimSetEntry."Dimension Code", DimSetEntry."Dimension Value Code")
            else
                DimText :=
                  StrSubstNo(
                    '%1; %2 - %3', DimText, DimSetEntry."Dimension Code", DimSetEntry."Dimension Value Code");
            if StrLen(DimText) > MaxStrLen(OldDimText) then begin
                DimText := OldDimText;
                Continue := true;
                exit;
            end;
        until DimSetEntry.Next() = 0;
        exit(DimText);
    end;
}

