// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

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
using Microsoft.Foundation.Company;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.Period;
using Microsoft.Intercompany.BankAccount;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Intercompany.Journal;
using Microsoft.Intercompany.Partner;
using Microsoft.Projects.Project.Job;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Setup;
using System.Security.User;
using System.Utilities;

report 10089 "Payment Journal - Test"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Finance/GeneralLedger/Reports/PaymentJournalTest.rdlc';
    Caption = 'Payment Journal - Test';

    dataset
    {
        dataitem("Gen. Journal Batch"; "Gen. Journal Batch")
        {
            DataItemTableView = sorting("Journal Template Name", Name);
            column(Gen__Journal_Batch_Journal_Template_Name; "Journal Template Name")
            {
            }
            column(Gen__Journal_Batch_Name; Name)
            {
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                PrintOnlyIfDetail = true;
                column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
                {
                }
                column(CompanyInformation_Name; CompanyInformation.Name)
                {
                }
                column(USERID; UserId)
                {
                }
                column(Gen__Journal_Batch___Journal_Template_Name_; "Gen. Journal Batch"."Journal Template Name")
                {
                }
                column(Gen__Journal_Batch__Name; "Gen. Journal Batch".Name)
                {
                }
                column(TIME; Time)
                {
                }
                column(Gen__Journal_Line__TABLECAPTION__________GenJnlLineFilter; "Gen. Journal Line".TableCaption + ': ' + GenJnlLineFilter)
                {
                }
                column(USText001; USText001)
                {
                }
                column(GenJnlLineFilter; GenJnlLineFilter)
                {
                }
                column(GenJnlTemplate_Force_Doc_Balance; GenJnlTemplate."Force Doc. Balance")
                {
                }
                column(Integer_Number; Number)
                {
                }
                column(Payment_Journal___TestCaption; Payment_Journal___TestCaptionLbl)
                {
                }
                column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
                {
                }
                column(Gen__Journal_Batch___Journal_Template_Name_Caption; "Gen. Journal Batch".FieldCaption("Journal Template Name"))
                {
                }
                column(Gen__Journal_Batch__NameCaption; Gen__Journal_Batch__NameCaptionLbl)
                {
                }
                column(Gen__Journal_Line__Posting_Date_Caption; Gen__Journal_Line__Posting_Date_CaptionLbl)
                {
                }
                column(Gen__Journal_Line__Document_Type_Caption; Gen__Journal_Line__Document_Type_CaptionLbl)
                {
                }
                column(Gen__Journal_Line__Document_No__Caption; Gen__Journal_Line__Document_No__CaptionLbl)
                {
                }
                column(Gen__Journal_Line__Account_Type_Caption; Gen__Journal_Line__Account_Type_CaptionLbl)
                {
                }
                column(Gen__Journal_Line__Account_No__Caption; Gen__Journal_Line__Account_No__CaptionLbl)
                {
                }
                column(Gen__Journal_Line_DescriptionCaption; "Gen. Journal Line".FieldCaption(Description))
                {
                }
                column(Gen__Journal_Line_AmountCaption; "Gen. Journal Line".FieldCaption(Amount))
                {
                }
                column(Gen__Journal_Line__Bal__Account_No__Caption; Gen__Journal_Line__Bal__Account_No__CaptionLbl)
                {
                }
                column(Gen__Journal_Line__Bal__Account_Type_Caption; Gen__Journal_Line__Bal__Account_Type_CaptionLbl)
                {
                }
                column(Gen__Journal_Line__Bank_Payment_Type_Caption; "Gen. Journal Line".FieldCaption("Bank Payment Type"))
                {
                }
                column(Gen__Journal_Line__Applies_to_Doc__Type_Caption; Gen__Journal_Line__Applies_to_Doc__Type_CaptionLbl)
                {
                }
                column(Gen__Journal_Line__Applies_to_Doc__No__Caption; Gen__Journal_Line__Applies_to_Doc__No__CaptionLbl)
                {
                }
                column(DocumentCaption; DocumentCaptionLbl)
                {
                }
                column(AccountCaption; AccountCaptionLbl)
                {
                }
                column(Applies_to_Doc_Caption; Applies_to_Doc_CaptionLbl)
                {
                }
                column(Bal__AccountCaption; Bal__AccountCaptionLbl)
                {
                }
                dataitem("Gen. Journal Line"; "Gen. Journal Line")
                {
                    DataItemLink = "Journal Template Name" = field("Journal Template Name"), "Journal Batch Name" = field(Name);
                    DataItemLinkReference = "Gen. Journal Batch";
                    DataItemTableView = sorting("Journal Template Name", "Journal Batch Name", "Line No.");
                    RequestFilterFields = "Posting Date";
                    column(Gen__Journal_Line__Posting_Date_; "Posting Date")
                    {
                    }
                    column(Gen__Journal_Line__Document_Type_; "Document Type")
                    {
                    }
                    column(Gen__Journal_Line__Document_No__; "Document No.")
                    {
                    }
                    column(Gen__Journal_Line__Account_Type_; "Account Type")
                    {
                    }
                    column(Gen__Journal_Line__Account_No__; "Account No.")
                    {
                    }
                    column(Gen__Journal_Line_Description; Description)
                    {
                    }
                    column(Gen__Journal_Line_Amount; Amount)
                    {
                    }
                    column(Gen__Journal_Line__Currency_Code_; "Currency Code")
                    {
                    }
                    column(Gen__Journal_Line__Bal__Account_No__; "Bal. Account No.")
                    {
                    }
                    column(Gen__Journal_Line__Bal__Account_Type_; "Bal. Account Type")
                    {
                    }
                    column(Gen__Journal_Line__Bank_Payment_Type_; "Bank Payment Type")
                    {
                    }
                    column(Gen__Journal_Line__External_Document_No__; "External Document No.")
                    {
                    }
                    column(Gen__Journal_Line__Applies_to_Doc__Type_; "Applies-to Doc. Type")
                    {
                    }
                    column(Gen__Journal_Line__Applies_to_Doc__No__; "Applies-to Doc. No.")
                    {
                    }
                    column(Gen__Journal_Line__Amount__LCY__; "Amount (LCY)")
                    {
                    }
                    column(Gen__Journal_Line__Balance__LCY__; "Balance (LCY)")
                    {
                    }
                    column(ShowDim; ShowDim)
                    {
                    }
                    column(Gen__Journal_Line_Journal_Template_Name; "Journal Template Name")
                    {
                    }
                    column(Gen__Journal_Line_Journal_Batch_Name; "Journal Batch Name")
                    {
                    }
                    column(Gen__Journal_Line_Line_No_; "Line No.")
                    {
                    }
                    column(Gen__Journal_Line__Amount__LCY__Caption; CaptionClassTranslate('101,0,Total (%1)'))
                    {
                    }
                    dataitem(TempLoop; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = const(1));
                        column(Gen__Journal_Line___Amount__LCY__; "Gen. Journal Line"."Amount (LCY)")
                        {
                        }
                        column(Gen__Journal_Line___Balance__LCY__; "Gen. Journal Line"."Balance (LCY)")
                        {
                        }
                        column(TempLoop_Number; Number)
                        {
                        }
                    }
                    dataitem(DimensionLoop; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                        column(DimText; DimText)
                        {
                        }
                        column(DimText_Control55; DimText)
                        {
                        }
                        column(DimensionLoop_DimensionLoop_Number; Number)
                        {
                        }
                        column(DimensionsCaption; DimensionsCaptionLbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if Number = 1 then begin
                                if not DimSetEntry.Find('-') then
                                    CurrReport.Break();
                            end else
                                if not Continue then
                                    CurrReport.Break();

                            Clear(DimText);
                            Continue := false;
                            repeat
                                OldDimText := DimText;
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
                            until (DimSetEntry.Next() = 0);
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
                        column(ErrorText_Number_; ErrorText[Number])
                        {
                        }
                        column(ErrorCounter; ErrorCounter)
                        {
                        }
                        column(ErrorLoop_Number; Number)
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

                    trigger OnAfterGetRecord()
                    var
                        PaymentTerms: Record "Payment Terms";
                        DimMgt: Codeunit DimensionManagement;
                        TableID: array[10] of Integer;
                        No: array[10] of Code[20];
                    begin
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
                            CheckICDocument();
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
                                                    AddError(
                                                      StrSubstNo(
                                                        Text003, FieldCaption("VAT Amount"), FieldCaption("VAT Base Amount"),
                                                        FieldCaption(Amount)));
                                                if "Currency Code" <> '' then
                                                    if "VAT Amount (LCY)" + "VAT Base Amount (LCY)" <> "Amount (LCY)" then
                                                        AddError(
                                                          StrSubstNo(
                                                            Text003, FieldCaption("VAT Amount (LCY)"),
                                                            FieldCaption("VAT Base Amount (LCY)"), FieldCaption("Amount (LCY)")));
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
                                                AddError(
                                                  StrSubstNo(
                                                    Text005,
                                                    FieldCaption("Gen. Bus. Posting Group"), FieldCaption("Gen. Prod. Posting Group"),
                                                    FieldCaption("VAT Bus. Posting Group"), FieldCaption("VAT Prod. Posting Group"),
                                                    FieldCaption("Account Type"), "Account Type"));

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
                                                        "Document Type"::Refund:
                                                            WarningIfNegativeAmt("Gen. Journal Line");
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
                                                        "Document Type"::Refund:
                                                            WarningIfPositiveAmt("Gen. Journal Line");
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
                                                AddError(
                                                  StrSubstNo(
                                                    Text005,
                                                    FieldCaption("Gen. Bus. Posting Group"), FieldCaption("Gen. Prod. Posting Group"),
                                                    FieldCaption("VAT Bus. Posting Group"), FieldCaption("VAT Prod. Posting Group"),
                                                    FieldCaption("Account Type"), "Account Type"));

                                            if "Job No." <> '' then
                                                AddError(StrSubstNo(Text009, FieldCaption("Job No.")));
                                            if (Amount < 0) and ("Bank Payment Type" = "Bank Payment Type"::"Computer Check") then
                                                if not "Check Printed" then
                                                    AddError(StrSubstNo(Text010,
                                                        FieldCaption("Check Printed"), "Bank Payment Type"::"Electronic Payment"));
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
                                                    AddError(
                                                      StrSubstNo(
                                                        Text011, FieldCaption("Bal. VAT Amount"), FieldCaption("Bal. VAT Base Amount"),
                                                        FieldCaption(Amount)));
                                                if "Currency Code" <> '' then
                                                    if "Bal. VAT Amount (LCY)" + "Bal. VAT Base Amount (LCY)" <> -"Amount (LCY)" then
                                                        AddError(
                                                          StrSubstNo(
                                                            Text011, FieldCaption("Bal. VAT Amount (LCY)"),
                                                            FieldCaption("Bal. VAT Base Amount (LCY)"), FieldCaption("Amount (LCY)")));
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
                                                AddError(
                                                  StrSubstNo(
                                                    Text005,
                                                    FieldCaption("Bal. Gen. Bus. Posting Group"), FieldCaption("Bal. Gen. Prod. Posting Group"),
                                                    FieldCaption("Bal. VAT Bus. Posting Group"), FieldCaption("Bal. VAT Prod. Posting Group"),
                                                    FieldCaption("Bal. Account Type"), "Bal. Account Type"));

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
                                                AddError(
                                                  StrSubstNo(
                                                    Text005,
                                                    FieldCaption("Bal. Gen. Bus. Posting Group"), FieldCaption("Bal. Gen. Prod. Posting Group"),
                                                    FieldCaption("Bal. VAT Bus. Posting Group"), FieldCaption("Bal. VAT Prod. Posting Group"),
                                                    FieldCaption("Bal. Account Type"), "Bal. Account Type"));

                                            if "Job No." <> '' then
                                                AddError(StrSubstNo(Text009, FieldCaption("Job No.")));
                                            if (Amount > 0) and ("Bank Payment Type" = "Bank Payment Type"::"Computer Check") then
                                                if not "Check Printed" then
                                                    AddError(StrSubstNo(Text010,
                                                        FieldCaption("Check Printed"), "Bank Payment Type"::"Electronic Payment"));
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
                            then
                                if PaymentTerms.Get("Payment Terms Code") then begin
                                    if ("Document Type" = "Document Type"::"Credit Memo") and
                                       (not PaymentTerms."Calc. Pmt. Disc. on Cr. Memos")
                                    then begin
                                        if "Pmt. Discount Date" <> 0D then
                                            AddError(StrSubstNo(Text009, FieldCaption("Pmt. Discount Date")));
                                        if "Payment Discount %" <> 0 then
                                            AddError(StrSubstNo(Text018, FieldCaption("Payment Discount %")));
                                    end;
                                end else begin
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
                                if GenJnlLine2."Bank Payment Type" <> GenJnlLine2."Bank Payment Type"::" " then
                                    AddError(StrSubstNo(Text009, FieldCaption("Bank Payment Type")));

                            if ("Account No." <> '') and ("Bal. Account No." <> '') then begin
                                PurchPostingType := false;
                                SalesPostingType := false;
                            end;
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
                                    "Account Type"::"IC Partner":
                                        CheckICPartner("Gen. Journal Line", AccName);
                                end;
                            if "Bal. Account No." <> '' then begin
                                ExchAccGLJnlLine.Run("Gen. Journal Line");
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
                                    "Account Type"::"IC Partner":
                                        CheckICPartner("Gen. Journal Line", AccName);
                                end;
                                ExchAccGLJnlLine.Run("Gen. Journal Line");
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
                            if "Bank Payment Type" = "Bank Payment Type"::"Electronic Payment" then begin
                                if not "Check Transmitted" then
                                    AddError(StrSubstNo(Text010,
                                        FieldCaption("Check Transmitted"), "Bank Payment Type"::"Electronic Payment"));
                                if not "Check Exported" then
                                    AddError(StrSubstNo(Text010,
                                        FieldCaption("Check Exported"), "Bank Payment Type"::"Electronic Payment"));
                            end;
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
                    column(GLAccNetChange__No__; GLAccNetChange."No.")
                    {
                    }
                    column(GLAccNetChange_Name; GLAccNetChange.Name)
                    {
                    }
                    column(GLAccNetChange__Net_Change_in_Jnl__; GLAccNetChange."Net Change in Jnl.")
                    {
                    }
                    column(GLAccNetChange__Balance_after_Posting_; GLAccNetChange."Balance after Posting")
                    {
                    }
                    column(ReconcileLoop_Number; Number)
                    {
                    }
                    column(ReconciliationCaption; ReconciliationCaptionLbl)
                    {
                    }
                    column(GLAccNetChange__No__Caption; GLAccNetChange__No__CaptionLbl)
                    {
                    }
                    column(GLAccNetChange_NameCaption; GLAccNetChange_NameCaptionLbl)
                    {
                    }
                    column(GLAccNetChange__Net_Change_in_Jnl__Caption; GLAccNetChange__Net_Change_in_Jnl__CaptionLbl)
                    {
                    }
                    column(GLAccNetChange__Balance_after_Posting_Caption; GLAccNetChange__Balance_after_Posting_CaptionLbl)
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

            trigger OnAfterGetRecord()
            begin
                GenJnlTemplate.Get("Gen. Journal Batch"."Journal Template Name");
            end;

            trigger OnPreDataItem()
            begin
                GLSetup.Get();
                SalesSetup.Get();
                PurchSetup.Get();
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
                    field(ShowDimensions; ShowDim)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Show Dimensions';
                        ToolTip = 'Specifies if you want if you want the report to show dimensions.';
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
        CompanyInformation.Get();
    end;

    var
        Text000: Label '%1 cannot be filtered when you post recurring journals.';
        Text001: Label '%1 or %2 must be specified.';
        Text002: Label '%1 must be specified.';
        Text003: Label '%1 + %2 must be %3.';
        Text004: Label '%1 must be " " when %2 is %3.';
        Text005: Label '%1, %2, %3 or %4 must not be completed when %5 is %6.';
        Text006: Label '%1 must be negative.';
        Text007: Label '%1 must be positive.';
        Text008: Label '%1 must have the same sign as %2.';
        Text009: Label '%1 cannot be specified.';
        Text010: Label '%1 must be Yes for a(n) %2.';
        Text011: Label '%1 + %2 must be -%3.';
        Text012: Label '%1 must have a different sign than %2.';
        Text013: Label '%1 must only be a closing date for G/L entries.';
        Text014: Label '%1 is not within your allowed range of posting dates.';
        Text015: Label 'The lines are not listed according to Posting Date because they were not entered in that order.';
        Text016: Label 'There is a gap in the number series.';
        Text017: Label '%1 or %2 must be G/L Account or Bank Account.';
        Text018: Label '%1 must be 0.';
        Text019: Label '%1 cannot be specified when using recurring journals.';
        Text020: Label '%1 must not be %2 when %3 = %4.';
        Text021: Label 'Allocations can only be used with recurring journals.';
        Text022: Label 'Please specify %1 in the %2 allocation lines.';
        Text023: Label '<Month Text>', Locked = true;
        Text024: Label '%1 %2 posted on %3, must be separated by an empty line';
        Text025: Label '%1 %2 is out of balance by %3.';
        Text026: Label 'The reversing entries for %1 %2 are out of balance by %3.';
        Text027: Label 'As of %1, the lines are out of balance by %2.';
        Text028: Label 'As of %1, the reversing entries are out of balance by %2.';
        Text029: Label 'The total of the lines is out of balance by %1.';
        Text030: Label 'The total of the reversing entries is out of balance by %1.';
        Text031: Label '%1 %2 does not exist.';
        Text032: Label '%1 must be %2 for %3 %4.';
        Text036: Label '%1 %2 %3 does not exist.';
        Text037: Label '%1 must be %2.';
        Text038: Label 'The currency %1 cannot be found. Please check the currency table.';
        Text039: Label 'Sales %1 %2 already exists.';
        Text040: Label 'Purchase %1 %2 already exists.';
        Text041: Label '%1 must be entered.';
        Text042: Label '%1 must not be filled when %2 is different in %3 and %4.';
        Text043: Label '%1 %2 must not have %3 = %4.';
        Text044: Label '%1 must not be specified in fixed asset journal lines.';
        Text045: Label '%1 must be specified in fixed asset journal lines.';
        Text046: Label '%1 must be different than %2.';
        Text047: Label '%1 and %2 must not both be %3.';
        Text048: Label '%1  must not be specified when %2 = %3.';
        Text049: Label '%1 must not be specified when %2 = %3.';
        Text050: Label 'must not be specified together with %1 = %2.';
        Text051: Label '%1 must be identical to %2.';
        Text052: Label '%1 cannot be a closing date.';
        Text053: Label '%1 is not within your range of allowed posting dates.';
        Text054: Label 'Insurance integration is not activated for %1 %2.';
        Text055: Label 'must not be specified when %1 is specified.';
        Text056: Label 'When G/L integration is not activated, %1 must not be posted in the general journal.';
        Text057: Label 'When G/L integration is not activated, %1 must not be specified in the general journal.';
        Text058: Label '%1 must not be specified.';
        Text059: Label 'The combination of Customer and Gen. Posting Type Purchase is not allowed.';
        Text060: Label 'The combination of Vendor and Gen. Posting Type Sales is not allowed.';
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
        TempGenJnlLine: Record "Gen. Journal Line" temporary;
        GenJnlAlloc: Record "Gen. Jnl. Allocation";
        OldCustLedgEntry: Record "Cust. Ledger Entry";
        OldVendLedgEntry: Record "Vendor Ledger Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        NoSeries: Record "No. Series";
        FA: Record "Fixed Asset";
        ICPartner: Record "IC Partner";
        DeprBook: Record "Depreciation Book";
        FADeprBook: Record "FA Depreciation Book";
        FASetup: Record "FA Setup";
        GLAccNetChange: Record "G/L Account Net Change" temporary;
        CompanyInformation: Record "Company Information";
        DimSetEntry: Record "Dimension Set Entry";
        ExchAccGLJnlLine: Codeunit "Exchange Acc. G/L Journal Line";
        GenJnlLineFilter: Text;
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
        TotalBalance: Decimal;
        TotalBalanceReverse: Decimal;
        AccName: Text[100];
        LastLineNo: Integer;
        Day: Integer;
        Week: Integer;
        Month: Integer;
        Year: Integer;
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
        OldDimText: Text[120];
        ShowDim: Boolean;
        Continue: Boolean;
        Text063: Label 'Document,Payment,Invoice,Credit Memo,Finance Charge Memo,Reminder,Refund';
        Text064: Label '%1 %2 is already used in line %3 (%4 %5).';
        Text065: Label '%1 must not be blocked with type %2 when %3 is %4';
        PrivacyBlockedErr: Label '%1 must not be blocked for privacy.', Comment = '%1 = account type';
        CurrentICPartner: Code[20];
        Text066: Label 'You cannot enter G/L Account or Bank Account in both %1 and %2.';
        Text067: Label '%1 %2 is linked to %3 %4.';
        Text069: Label '%1 must not be specified when %2 is %3.';
        Text070: Label '%1 must not be specified when the document is not an intercompany transaction.';
        USText001: Label 'Warning:  Checks cannot be financially voided when Force Doc. Balance is set to No in the Journal Template.';
        Payment_Journal___TestCaptionLbl: Label 'Payment Journal - Test';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Gen__Journal_Batch__NameCaptionLbl: Label 'Journal Batch';
        Gen__Journal_Line__Posting_Date_CaptionLbl: Label 'Posting Date';
        Gen__Journal_Line__Document_Type_CaptionLbl: Label 'Type';
        Gen__Journal_Line__Document_No__CaptionLbl: Label 'Number';
        Gen__Journal_Line__Account_Type_CaptionLbl: Label 'Type';
        Gen__Journal_Line__Account_No__CaptionLbl: Label 'Number';
        Gen__Journal_Line__Bal__Account_No__CaptionLbl: Label 'Number';
        Gen__Journal_Line__Bal__Account_Type_CaptionLbl: Label 'Type';
        Gen__Journal_Line__Applies_to_Doc__Type_CaptionLbl: Label 'Type';
        Gen__Journal_Line__Applies_to_Doc__No__CaptionLbl: Label 'Number';
        DocumentCaptionLbl: Label 'Document';
        AccountCaptionLbl: Label 'Account';
        Applies_to_Doc_CaptionLbl: Label 'Applies-to Doc.';
        Bal__AccountCaptionLbl: Label 'Bal. Account';
        DimensionsCaptionLbl: Label 'Dimensions';
        ErrorText_Number_CaptionLbl: Label 'Warning!';
        ReconciliationCaptionLbl: Label 'Reconciliation';
        GLAccNetChange__No__CaptionLbl: Label 'No.';
        GLAccNetChange_NameCaptionLbl: Label 'Name';
        GLAccNetChange__Net_Change_in_Jnl__CaptionLbl: Label 'Net Change in Jnl.';
        GLAccNetChange__Balance_after_Posting_CaptionLbl: Label 'Balance after Posting';

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
                      StrSubstNo(
                        Text020,
                        GenJnlLine2.FieldCaption("Recurring Method"), GenJnlLine2."Recurring Method",
                        GenJnlLine2.FieldCaption("Account Type"), GenJnlLine2."Account Type"));
                if GenJnlLine2."Bal. Account Type" = GenJnlLine2."Bal. Account Type"::"Fixed Asset" then
                    AddError(
                      StrSubstNo(
                        Text020,
                        GenJnlLine2.FieldCaption("Recurring Method"), GenJnlLine2."Recurring Method",
                        GenJnlLine2.FieldCaption("Bal. Account Type"), GenJnlLine2."Bal. Account Type"));
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
            Year := Date2DMY(GenJnlLine2."Posting Date", 3);
            AccountingPeriod.SetRange("Starting Date", 0D, GenJnlLine2."Posting Date");
            if not AccountingPeriod.FindLast() then
                AccountingPeriod.Name := '';
            GenJnlLine2."Document No." :=
              DelChr(
                PadStr(
                  StrSubstNo(GenJnlLine2."Document No.", Day, Week, Month, MonthText, AccountingPeriod.Name, Year),
                  MaxStrLen(GenJnlLine2."Document No.")),
                '>');
            GenJnlLine2.Description :=
              DelChr(
                PadStr(
                  StrSubstNo(GenJnlLine2.Description, Day, Week, Month, MonthText, AccountingPeriod.Name, Year),
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

        if (LastDate <> 0D) and (LastDocNo <> '') and
           ((NextGenJnlLine."Posting Date" <> LastDate) or
            (NextGenJnlLine."Document Type" <> LastDocType) or
            (NextGenJnlLine."Document No." <> LastDocNo) or
            (NextGenJnlLine."Line No." = LastLineNo))
        then begin
            if GenJnlTemplate."Force Doc. Balance" then begin
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
            end;
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
                    PrivacyBlockedErr,
                    GenJnlLine."Account Type"));
            if ((Cust.Blocked in [Cust.Blocked::All]) or
                ((Cust.Blocked in [Cust.Blocked::Invoice, Cust.Blocked::Ship]) and
                 (GenJnlLine."Document Type" in [GenJnlLine."Document Type"::Invoice, GenJnlLine."Document Type"::" "]))
                )
            then
                AddError(
                  StrSubstNo(
                    Text065,
                    GenJnlLine."Account Type", Cust.Blocked, GenJnlLine.FieldCaption("Document Type"), GenJnlLine."Document Type"));
            if GenJnlLine."Currency Code" <> '' then
                if not Currency.Get(GenJnlLine."Currency Code") then
                    AddError(
                      StrSubstNo(
                        Text038,
                        GenJnlLine."Currency Code"));
            if (Cust."IC Partner Code" <> '') and (GenJnlTemplate.Type = GenJnlTemplate.Type::Intercompany) then
                if ICPartner.Get(Cust."IC Partner Code") then begin
                    if ICPartner.Blocked then
                        AddError(
                          StrSubstNo(
                            '%1 %2',
                            StrSubstNo(
                              Text067,
                              Cust.TableCaption(), GenJnlLine."Account No.", ICPartner.TableCaption(), GenJnlLine."IC Partner Code"),
                            StrSubstNo(
                              Text032,
                              ICPartner.FieldCaption(Blocked), false, ICPartner.TableCaption(), Cust."IC Partner Code")));
                end else
                    AddError(
                      StrSubstNo(
                        '%1 %2',
                        StrSubstNo(
                          Text067,
                          Cust.TableCaption(), GenJnlLine."Account No.", ICPartner.TableCaption(), Cust."IC Partner Code"),
                        StrSubstNo(
                          Text031,
                          ICPartner.TableCaption(), Cust."IC Partner Code")));
            CustPosting := true;
            TestPostingType();

            if GenJnlLine."Recurring Method" = GenJnlLine."Recurring Method"::" " then
                if GenJnlLine."Document Type" in
                   [GenJnlLine."Document Type"::Invoice, GenJnlLine."Document Type"::"Credit Memo",
                    GenJnlLine."Document Type"::"Finance Charge Memo", GenJnlLine."Document Type"::Reminder]
                then begin
                    OldCustLedgEntry.Reset();
                    OldCustLedgEntry.SetCurrentKey("Document No.", "Document Type", "Customer No.");
                    OldCustLedgEntry.SetRange("Document Type", GenJnlLine."Document Type");
                    OldCustLedgEntry.SetRange("Document No.", GenJnlLine."Document No.");
                    if OldCustLedgEntry.FindFirst() then
                        AddError(
                          StrSubstNo(
                            Text039, GenJnlLine."Document Type", GenJnlLine."Document No."));

                    if SalesSetup."Ext. Doc. No. Mandatory" or
                       (GenJnlLine."External Document No." <> '')
                    then begin
                        if GenJnlLine."External Document No." = '' then
                            AddError(
                              StrSubstNo(
                                Text041, GenJnlLine.FieldCaption("External Document No.")));

                        OldCustLedgEntry.Reset();
                        OldCustLedgEntry.SetCurrentKey("Document Type", "External Document No.", "Customer No.");
                        OldCustLedgEntry.SetRange("Document Type", GenJnlLine."Document Type");
                        OldCustLedgEntry.SetRange("Customer No.", GenJnlLine."Account No.");
                        OldCustLedgEntry.SetRange("External Document No.", GenJnlLine."External Document No.");
                        if OldCustLedgEntry.FindFirst() then
                            AddError(
                              StrSubstNo(
                                Text039,
                                GenJnlLine."Document Type", GenJnlLine."External Document No."));
                        CheckAgainstPrevLines("Gen. Journal Line");
                    end;
                end;
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
                    PrivacyBlockedErr,
                    GenJnlLine."Account Type"));

            if ((Vend.Blocked in [Vend.Blocked::All]) or
                ((Vend.Blocked = Vend.Blocked::Payment) and (GenJnlLine."Document Type" = GenJnlLine."Document Type"::Payment))
                )
            then
                AddError(
                  StrSubstNo(
                    Text065,
                    GenJnlLine."Account Type", Vend.Blocked, GenJnlLine.FieldCaption("Document Type"), GenJnlLine."Document Type"));

            if GenJnlLine."Currency Code" <> '' then
                if not Currency.Get(GenJnlLine."Currency Code") then
                    AddError(
                      StrSubstNo(
                        Text038,
                        GenJnlLine."Currency Code"));

            if (Vend."IC Partner Code" <> '') and (GenJnlTemplate.Type = GenJnlTemplate.Type::Intercompany) then
                if ICPartner.Get(Cust."IC Partner Code") then begin
                    if ICPartner.Blocked then
                        AddError(
                          StrSubstNo(
                            '%1 %2',
                            StrSubstNo(
                              Text067,
                              Vend.TableCaption(), GenJnlLine."Account No.", ICPartner.TableCaption(), Vend."IC Partner Code"),
                            StrSubstNo(
                              Text032,
                              ICPartner.FieldCaption(Blocked), false, ICPartner.TableCaption(), Vend."IC Partner Code")));
                end else
                    AddError(
                      StrSubstNo(
                        '%1 %2',
                        StrSubstNo(
                          Text067,
                          Vend.TableCaption(), GenJnlLine."Account No.", ICPartner.TableCaption(), GenJnlLine."IC Partner Code"),
                        StrSubstNo(
                          Text031,
                          ICPartner.TableCaption(), Vend."IC Partner Code")));
            VendPosting := true;
            TestPostingType();

            if GenJnlLine."Recurring Method" = GenJnlLine."Recurring Method"::" " then
                if GenJnlLine."Document Type" in
                   [GenJnlLine."Document Type"::Invoice, GenJnlLine."Document Type"::"Credit Memo",
                    GenJnlLine."Document Type"::"Finance Charge Memo", GenJnlLine."Document Type"::Reminder]
                then begin
                    OldVendLedgEntry.Reset();
                    OldVendLedgEntry.SetCurrentKey("Document No.", "Document Type", "Vendor No.");
                    OldVendLedgEntry.SetRange("Document Type", GenJnlLine."Document Type");
                    OldVendLedgEntry.SetRange("Document No.", GenJnlLine."Document No.");
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
                        OldVendLedgEntry.SetCurrentKey("External Document No.", "Document Type", "Vendor No.");
                        OldVendLedgEntry.SetRange("Document Type", GenJnlLine."Document Type");
                        OldVendLedgEntry.SetRange("Vendor No.", GenJnlLine."Account No.");
                        OldVendLedgEntry.SetRange("External Document No.", GenJnlLine."External Document No.");
                        if OldVendLedgEntry.FindFirst() then
                            AddError(
                              StrSubstNo(
                                Text040,
                                GenJnlLine."Document Type", GenJnlLine."External Document No."));
                        CheckAgainstPrevLines("Gen. Journal Line");
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
                  StrSubstNo(
                    Text043,
                    FA.TableCaption(), GenJnlLine."Account No.", FA.FieldCaption("Budgeted Asset"), true));
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

    procedure CheckICPartner(var GenJnlLine: Record "Gen. Journal Line"; var AccName: Text[100])
    begin
        if not ICPartner.Get(GenJnlLine."Account No.") then
            AddError(
              StrSubstNo(
                Text031,
                ICPartner.TableCaption(), GenJnlLine."Account No."))
        else begin
            AccName := ICPartner.Name;
            if ICPartner.Blocked then
                AddError(
                  StrSubstNo(
                    Text032,
                    ICPartner.FieldCaption(Blocked), false, ICPartner.TableCaption(), GenJnlLine."Account No."));
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
                    AddError(
                      StrSubstNo(
                        Text048,
                        GenJnlLine.FieldCaption("Gen. Posting Type"), GenJnlLine.FieldCaption("FA Posting Type"), GenJnlLine."FA Posting Type"));
                if GenJnlLine."Gen. Bus. Posting Group" <> '' then
                    AddError(
                      StrSubstNo(
                        Text049,
                        GenJnlLine.FieldCaption("Gen. Bus. Posting Group"), GenJnlLine.FieldCaption("FA Posting Type"), GenJnlLine."FA Posting Type"));
                if GenJnlLine."Gen. Prod. Posting Group" <> '' then
                    AddError(
                      StrSubstNo(
                        Text049,
                        GenJnlLine.FieldCaption("Gen. Prod. Posting Group"), GenJnlLine.FieldCaption("FA Posting Type"), GenJnlLine."FA Posting Type"));
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
                      StrSubstNo(
                        Text049,
                        GenJnlLine.FieldCaption("Bal. Gen. Posting Type"), GenJnlLine.FieldCaption("FA Posting Type"), GenJnlLine."FA Posting Type"));
                if GenJnlLine."Bal. Gen. Bus. Posting Group" <> '' then
                    AddError(
                      StrSubstNo(
                        Text049,
                        GenJnlLine.FieldCaption("Bal. Gen. Bus. Posting Group"), GenJnlLine.FieldCaption("FA Posting Type"), GenJnlLine."FA Posting Type"));
                if GenJnlLine."Bal. Gen. Prod. Posting Group" <> '' then
                    AddError(
                      StrSubstNo(
                        Text049,
                        GenJnlLine.FieldCaption("Bal. Gen. Prod. Posting Group"), GenJnlLine.FieldCaption("FA Posting Type"), GenJnlLine."FA Posting Type"));
            end;
        TempErrorText :=
          '%1 ' +
          StrSubstNo(
            Text050,
            GenJnlLine.FieldCaption("FA Posting Type"), GenJnlLine."FA Posting Type");
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
            if not (GenJnlLine."FA Posting Date" in [00010101D .. 99981231D]) then
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
            AddError(
              StrSubstNo(
                Text054,
                GenJnlLine.FieldCaption("Depreciation Book Code"), GenJnlLine."Depreciation Book Code"));

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

    local procedure CheckAgainstPrevLines(GenJnlLine: Record "Gen. Journal Line")
    var
        i: Integer;
        AccType: Enum "Gen. Journal Account Type";
        AccNo: Code[20];
        ErrorFound: Boolean;
    begin
        if (GenJnlLine."External Document No." = '') or
           not (GenJnlLine."Account Type" in
                [GenJnlLine."Account Type"::Customer, GenJnlLine."Account Type"::Vendor]) and
           not (GenJnlLine."Bal. Account Type" in
                [GenJnlLine."Bal. Account Type"::Customer, GenJnlLine."Bal. Account Type"::Vendor])
        then
            exit;

        if GenJnlLine."Account Type" in [GenJnlLine."Account Type"::Customer, GenJnlLine."Account Type"::Vendor] then begin
            AccType := GenJnlLine."Account Type";
            AccNo := GenJnlLine."Account No.";
        end else begin
            AccType := GenJnlLine."Bal. Account Type";
            AccNo := GenJnlLine."Bal. Account No.";
        end;

        TempGenJnlLine.Reset();
        TempGenJnlLine.SetRange("External Document No.", GenJnlLine."External Document No.");

        while (i < 2) and not ErrorFound do begin
            i := i + 1;
            if i = 1 then begin
                TempGenJnlLine.SetRange("Account Type", AccType);
                TempGenJnlLine.SetRange("Account No.", AccNo);
                TempGenJnlLine.SetRange("Bal. Account Type");
                TempGenJnlLine.SetRange("Bal. Account No.");
            end else begin
                TempGenJnlLine.SetRange("Account Type");
                TempGenJnlLine.SetRange("Account No.");
                TempGenJnlLine.SetRange("Bal. Account Type", AccType);
                TempGenJnlLine.SetRange("Bal. Account No.", AccNo);
            end;
            if TempGenJnlLine.FindFirst() then begin
                ErrorFound := true;
                AddError(
                  StrSubstNo(
                    Text064, GenJnlLine.FieldCaption("External Document No."), GenJnlLine."External Document No.",
                    TempGenJnlLine."Line No.", GenJnlLine.FieldCaption("Document No."), TempGenJnlLine."Document No."));
            end;
        end;

        TempGenJnlLine.Reset();
        TempGenJnlLine := GenJnlLine;
        TempGenJnlLine.Insert();
    end;

    procedure CheckICDocument()
    var
        GenJnlLine4: Record "Gen. Journal Line";
    begin
        if GenJnlTemplate.Type = GenJnlTemplate.Type::Intercompany then begin
            if ("Gen. Journal Line"."Posting Date" <> LastDate) or ("Gen. Journal Line"."Document Type" <> LastDocType) or ("Gen. Journal Line"."Document No." <> LastDocNo) then begin
                GenJnlLine4.SetCurrentKey("Journal Template Name", "Journal Batch Name", "Posting Date", "Document No.");
                GenJnlLine4.SetRange("Journal Template Name", "Gen. Journal Line"."Journal Template Name");
                GenJnlLine4.SetRange("Journal Batch Name", "Gen. Journal Line"."Journal Batch Name");
                GenJnlLine4.SetRange("Posting Date", "Gen. Journal Line"."Posting Date");
                GenJnlLine4.SetRange("Document No.", "Gen. Journal Line"."Document No.");
                GenJnlLine4.SetFilter("IC Partner Code", '<>%1', '');
                if GenJnlLine4.FindFirst() then
                    CurrentICPartner := GenJnlLine4."IC Partner Code"
                else
                    CurrentICPartner := '';
            end;
            CheckICAccountNo();
        end;
    end;

    local procedure CheckICAccountNo()
    var
        ICGLAccount: Record "IC G/L Account";
        ICBankAccount: Record "IC Bank Account";
    begin
        if (CurrentICPartner <> '') and ("Gen. Journal Line"."IC Direction" = "Gen. Journal Line"."IC Direction"::Outgoing) then begin
            if ("Gen. Journal Line"."Account Type" in ["Gen. Journal Line"."Account Type"::"G/L Account", "Gen. Journal Line"."Account Type"::"Bank Account"]) and
               ("Gen. Journal Line"."Bal. Account Type" in ["Gen. Journal Line"."Bal. Account Type"::"G/L Account", "Gen. Journal Line"."Account Type"::"Bank Account"]) and
               ("Gen. Journal Line"."Account No." <> '') and
               ("Gen. Journal Line"."Bal. Account No." <> '')
            then
                AddError(StrSubstNo(Text066, "Gen. Journal Line".FieldCaption("Account No."), "Gen. Journal Line".FieldCaption("Bal. Account No.")))
            else
                if (("Gen. Journal Line"."Account Type" in ["Gen. Journal Line"."Account Type"::"G/L Account", "Gen. Journal Line"."Account Type"::"Bank Account"]) and ("Gen. Journal Line"."Account No." <> '')) xor
                   (("Gen. Journal Line"."Bal. Account Type" in ["Gen. Journal Line"."Bal. Account Type"::"G/L Account", "Gen. Journal Line"."Account Type"::"Bank Account"]) and
                    ("Gen. Journal Line"."Bal. Account No." <> ''))
                then
                    if "Gen. Journal Line"."IC Account No." = '' then
                        AddError(StrSubstNo(Text002, "Gen. Journal Line".FieldCaption("IC Account No.")))
                    else begin
                        if "Gen. Journal Line"."IC Account Type" = "IC Journal Account Type"::"G/L Account" then
                            if ICGLAccount.Get("Gen. Journal Line"."IC Account No.") then
                                if ICGLAccount.Blocked then
                                    AddError(StrSubstNo(Text032, ICGLAccount.FieldCaption(Blocked), false,
                                        "Gen. Journal Line".FieldCaption("IC Account No."), "Gen. Journal Line"."IC Account No."));

                        if "Gen. Journal Line"."IC Account Type" = "IC Journal Account Type"::"Bank Account" then
                            if ICBankAccount.Get("Gen. Journal Line"."IC Account No.", CurrentICPartner) then
                                if ICBankAccount.Blocked then
                                    AddError(StrSubstNo(Text032, ICGLAccount.FieldCaption(Blocked), false,
                                        "Gen. Journal Line".FieldCaption("IC Account No."), "Gen. Journal Line"."IC Account No."));
                    end
                else
                    if "Gen. Journal Line"."IC Account No." <> '' then
                        AddError(StrSubstNo(Text009, "Gen. Journal Line".FieldCaption("IC Account No.")));
        end else
            if "Gen. Journal Line"."IC Account No." <> '' then begin
                if "Gen. Journal Line"."IC Direction" = "Gen. Journal Line"."IC Direction"::Incoming then
                    AddError(StrSubstNo(Text069, "Gen. Journal Line".FieldCaption("IC Account No."), "Gen. Journal Line".FieldCaption("IC Direction"), Format("Gen. Journal Line"."IC Direction")));
                if CurrentICPartner = '' then
                    AddError(StrSubstNo(Text070, "Gen. Journal Line".FieldCaption("IC Account No.")));
            end;
    end;
}

