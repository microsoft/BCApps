// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Bank.BankAccount;
using Microsoft.CRM.Campaign;
using Microsoft.CRM.Team;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Journal;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.FixedAssets.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.Period;
using Microsoft.HumanResources.Employee;
using Microsoft.Intercompany.BankAccount;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Intercompany.Partner;
using Microsoft.Projects.Project.Job;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Purchases.Setup;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Setup;
using System.Integration;
using System.Security.User;
using System.Utilities;

report 6250 "Auto Posting Errors"
{
    Caption = 'Auto Posting Errors';
    ProcessingOnly = true;
    MaximumDatasetSize = 1000000;
    ExecutionTimeout = '12:00:00';
    MaximumDocumentCount = 500;

    dataset
    {
        dataitem("Gen. Journal Batch"; "Gen. Journal Batch")
        {
            DataItemTableView = sorting("Journal Template Name", Name);
            column(JnlTmplName_GenJnlBatch; "Journal Template Name")
            {
            }
            column(Name_GenJnlBatch; Name)
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(GeneralJnlTestCaption; GeneralJnlTestLbl)
            {
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                PrintOnlyIfDetail = true;
                column(JnlTemplateName_GenJnlBatch; "Gen. Journal Batch"."Journal Template Name")
                {
                }
                column(JnlName_GenJnlBatch; "Gen. Journal Batch".Name)
                {
                }
                column(GenJnlLineFilter; GenJnlLineFilter)
                {
                }
                column(GenJnlLineFilterTableCaption; "Gen. Journal Line".TableCaption + ': ' + GenJnlLineFilter)
                {
                }
                column(Number_Integer; Number)
                {
                }
                column(PageNoCaption; PageNoLbl)
                {
                }
                column(JnlTmplNameCaption_GenJnlBatch; "Gen. Journal Batch".FieldCaption("Journal Template Name"))
                {
                }
                column(JournalBatchCaption; JnlBatchNameLbl)
                {
                }
                column(PostingDateCaption; PostingDateLbl)
                {
                }
                column(DocumentTypeCaption; DocumentTypeLbl)
                {
                }
                column(DocNoCaption_GenJnlLine; "Gen. Journal Line".FieldCaption("Document No."))
                {
                }
                column(AccountTypeCaption; AccountTypeLbl)
                {
                }
                column(AccNoCaption_GenJnlLine; "Gen. Journal Line".FieldCaption("Account No."))
                {
                }
                column(AccNameCaption; AccNameLbl)
                {
                }
                column(DescCaption_GenJnlLine; "Gen. Journal Line".FieldCaption(Description))
                {
                }
                column(PostingTypeCaption; GenPostingTypeLbl)
                {
                }
                column(GenBusPostGroupCaption; GenBusPostingGroupLbl)
                {
                }
                column(GenProdPostGroupCaption; GenProdPostingGroupLbl)
                {
                }
                column(AmountCaption_GenJnlLine; "Gen. Journal Line".FieldCaption(Amount))
                {
                }
                column(BalAccNoCaption_GenJnlLine; "Gen. Journal Line".FieldCaption("Bal. Account No."))
                {
                }
                column(BalLCYCaption_GenJnlLine; "Gen. Journal Line".FieldCaption("Balance (LCY)"))
                {
                }
                dataitem("Gen. Journal Line"; "Gen. Journal Line")
                {
                    DataItemLink = "Journal Template Name" = field("Journal Template Name"), "Journal Batch Name" = field(Name);
                    DataItemLinkReference = "Gen. Journal Batch";
                    DataItemTableView = sorting("Journal Template Name", "Journal Batch Name", "Line No.");
                    RequestFilterFields = "Posting Date";
                    column(PostingDate_GenJnlLine; Format("Posting Date"))
                    {
                    }
                    column(DocType_GenJnlLine; "Document Type")
                    {
                    }
                    column(DocNo_GenJnlLine; "Document No.")
                    {
                    }
                    column(ExtDocNo_GenJnlLine; "External Document No.")
                    {
                    }
                    column(AccountType_GenJnlLine; "Account Type")
                    {
                    }
                    column(AccountNo_GenJnlLine; "Account No.")
                    {
                    }
                    column(AccName; AccName)
                    {
                    }
                    column(Description_GenJnlLine; Description)
                    {
                    }
                    column(GenPostType_GenJnlLine; "Gen. Posting Type")
                    {
                    }
                    column(GenBusPosGroup_GenJnlLine; "Gen. Bus. Posting Group")
                    {
                    }
                    column(GenProdPostGroup_GenJnlLine; "Gen. Prod. Posting Group")
                    {
                    }
                    column(Amount_GenJnlLine; Amount)
                    {
                    }
                    column(CurrencyCode_GenJnlLine; "Currency Code")
                    {
                    }
                    column(BalAccNo_GenJnlLine; "Bal. Account No.")
                    {
                    }
                    column(BalanceLCY_GenJnlLine; "Balance (LCY)")
                    {
                    }
                    column(AmountLCY; AmountLCY)
                    {
                    }
                    column(BalanceLCY; BalanceLCY)
                    {
                    }
                    column(AmountLCY_GenJnlLine; "Amount (LCY)")
                    {
                    }
                    column(JnlTmplName_GenJnlLine; "Journal Template Name")
                    {
                    }
                    column(JnlBatchName_GenJnlLine; "Journal Batch Name")
                    {
                    }
                    column(LineNo_GenJnlLine; "Line No.")
                    {
                    }
                    column(TotalLCYCaption; AmountLCYLbl)
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
                        column(DimensionsCaption; DimensionsLbl)
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

                            DimText := GetDimensionText(DimSetEntry);
                        end;

                        trigger OnPreDataItem()
                        begin
                            if not ShowDim then
                                CurrReport.Break();
                            DimSetEntry.Reset();
                            DimSetEntry.SetRange("Dimension Set ID", "Gen. Journal Line"."Dimension Set ID")
                        end;
                    }
                    dataitem("Gen. Jnl. Allocation"; "Gen. Jnl. Allocation")
                    {
                        DataItemLink = "Journal Template Name" = field("Journal Template Name"), "Journal Batch Name" = field("Journal Batch Name"), "Journal Line No." = field("Line No.");
                        DataItemTableView = sorting("Journal Template Name", "Journal Batch Name", "Journal Line No.", "Line No.");
                        column(AccountNo_GenJnlAllocation; "Account No.")
                        {
                        }
                        column(AccountName_GenJnlAllocation; "Account Name")
                        {
                        }
                        column(AllocationQuantity_GenJnlAllocation; "Allocation Quantity")
                        {
                        }
                        column(AllocationPct_GenJnlAllocation; "Allocation %")
                        {
                        }
                        column(Amount_GenJnlAllocation; Amount)
                        {
                        }
                        column(JournalLineNo_GenJnlAllocation; "Journal Line No.")
                        {
                        }
                        column(LineNo_GenJnlAllocation; "Line No.")
                        {
                        }
                        column(JournalBatchName_GenJnlAllocation; "Journal Batch Name")
                        {
                        }
                        column(AccountNoCaption_GenJnlAllocation; FieldCaption("Account No."))
                        {
                        }
                        column(AccountNameCaption_GenJnlAllocation; FieldCaption("Account Name"))
                        {
                        }
                        column(AllocationQuantityCaption_GenJnlAllocation; FieldCaption("Allocation Quantity"))
                        {
                        }
                        column(AllocationPctCaption_GenJnlAllocation; FieldCaption("Allocation %"))
                        {
                        }
                        column(AmountCaption_GenJnlAllocation; FieldCaption(Amount))
                        {
                        }
                        column(Recurring_GenJnlTemplate; GenJnlTemplate.Recurring)
                        {
                        }
                        dataitem(DimensionLoopAllocations; "Integer")
                        {
                            DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                            column(AllocationDimText; AllocationDimText)
                            {
                            }
                            column(Number_DimensionLoopAllocations; Number)
                            {
                            }
                            column(DimensionAllocationsCaption; DimensionAllocationsLbl)
                            {
                            }

                            trigger OnAfterGetRecord()
                            begin
                                if Number = 1 then begin
                                    if not DimSetEntry.FindFirst() then
                                        CurrReport.Break();
                                end else
                                    if not Continue then
                                        CurrReport.Break();

                                AllocationDimText := GetDimensionText(DimSetEntry);
                            end;

                            trigger OnPreDataItem()
                            begin
                                if not ShowDim then
                                    CurrReport.Break();
                                DimSetEntry.Reset();
                                DimSetEntry.SetRange("Dimension Set ID", "Gen. Jnl. Allocation"."Dimension Set ID")
                            end;
                        }
                    }
                    dataitem(ErrorLoop; "Integer")
                    {
                        DataItemTableView = sorting(Number);
                        column(ErrorTextNumber; ErrorText[Number])
                        {
                        }
                        column(WarningCaption; WarningLbl)
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
                        if "Currency Code" = '' then
                            "Amount (LCY)" := Amount;

                        UpdateLineBalance();

                        AccName := '';
                        BalAccName := '';

                        if not EmptyLine() then begin
                            MakeRecurringTexts("Gen. Journal Line");

                            AmountError := false;

                            if ("Account No." = '') and ("Bal. Account No." = '') then
                                AddError(StrSubstNo(Text001Txt, FieldCaption("Account No."), FieldCaption("Bal. Account No.")))
                            else
                                if ("Account Type" <> "Account Type"::"Fixed Asset") and
                                   ("Bal. Account Type" <> "Bal. Account Type"::"Fixed Asset")
                                then
                                    TestFixedAssetFields("Gen. Journal Line");
                            CheckICDocument();
                            OnAfterGetGenJnlLineAccount("Gen. Journal Line");
                            OnAfterGetGenJnlLineBalanceAccount("Gen. Journal Line");

                            if ("Account No." <> '') and
                               not "System-Created Entry" and
                               (Amount = 0) and
                               not GenJnlTemplate.Recurring and
                               not "Allow Zero-Amount Posting" and
                               ("Account Type" <> "Account Type"::"Fixed Asset")
                            then
                                WarningIfZeroAmt("Gen. Journal Line");

                            CheckRecurringLine("Gen. Journal Line");
                            CheckAllocations("Gen. Journal Line");
                            OnAfterGetGenJnlLinePostingDate("Gen. Journal Line");

                            if "Document Date" <> 0D then
                                if ("Document Date" <> NormalDate("Document Date")) and
                                   (("Account Type" <> "Account Type"::"G/L Account") or
                                    ("Bal. Account Type" <> "Bal. Account Type"::"G/L Account"))
                                then
                                    AddError(
                                      StrSubstNo(
                                        Text013Txt, FieldCaption("Document Date")));

                            if "Document No." = '' then
                                AddError(StrSubstNo(Text002Txt, FieldCaption("Document No.")))
                            else
                                if "Gen. Journal Batch"."No. Series" <> '' then begin
                                    if (LastEntrdDocNo <> '') and
                                       ("Document No." <> LastEntrdDocNo) and
                                       ("Document No." <> IncStr(LastEntrdDocNo))
                                    then
                                        AddError(Text016Txt);
                                    LastEntrdDocNo := "Document No.";
                                end;

                            if ("Account Type" in ["Account Type"::Customer, "Account Type"::Vendor, "Account Type"::"Fixed Asset"]) and
                               ("Bal. Account Type" in ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor, "Bal. Account Type"::"Fixed Asset"])
                            then
                                AddError(
                                  StrSubstNo(
                                    Text017Txt,
                                    FieldCaption("Account Type"), FieldCaption("Bal. Account Type")));

                            if Amount * "Amount (LCY)" < 0 then
                                AddError(
                                  StrSubstNo(
                                    Text008Txt, FieldCaption("Amount (LCY)"), FieldCaption(Amount)));

                            OnAfterGetGenJnlLineAccountType("Gen. Journal Line");

                            if ("Account No." <> '') and ("Bal. Account No." <> '') then begin
                                PurchPostingType := false;
                                SalesPostingType := false;
                            end;
                            if "Account No." <> '' then
                                CheckAccountTypes("Account Type", AccName);
                            if "Bal. Account No." <> '' then begin
                                CODEUNIT.Run(CODEUNIT::"Exchange Acc. G/L Journal Line", "Gen. Journal Line");
                                CheckAccountTypes("Account Type", BalAccName);
                                CODEUNIT.Run(CODEUNIT::"Exchange Acc. G/L Journal Line", "Gen. Journal Line");
                            end;

                            if not DimMgt.CheckDimIDComb("Dimension Set ID") then
                                AddError(DimMgt.GetDimCombErr());

                            TableID[1] := DimMgt.TypeToTableID1("Account Type".AsInteger());
                            No[1] := "Account No.";
                            TableID[2] := DimMgt.TypeToTableID1("Bal. Account Type".AsInteger());
                            No[2] := "Bal. Account No.";
                            TableID[3] := DATABASE::Job;
                            No[3] := "Job No.";
                            TableID[4] := DATABASE::"Salesperson/Purchaser";
                            No[4] := "Salespers./Purch. Code";
                            TableID[5] := DATABASE::Campaign;
                            No[5] := "Campaign No.";
                            if not DimMgt.CheckDimValuePosting(TableID, No, "Dimension Set ID") then
                                AddError(DimMgt.GetDimValuePostingErr());
                        end;

                        CheckBalance();
                        AmountLCY += "Amount (LCY)";
                        BalanceLCY += "Balance (LCY)";
                    end;

                    trigger OnPreDataItem()
                    begin
                        CopyFilter("Journal Batch Name", "Gen. Journal Batch".Name);
                        GenJnlLineFilter := GetFilters();

                        GenJnlTemplate.Get("Gen. Journal Batch"."Journal Template Name");
                        if GenJnlTemplate.Recurring then begin
                            if GetFilter("Posting Date") <> '' then
                                AddError(
                                  StrSubstNo(
                                    Text000Txt,
                                    FieldCaption("Posting Date")));
                            SetRange("Posting Date", 0D, WorkDate());
                            if GetFilter("Expiration Date") <> '' then
                                AddError(
                                  StrSubstNo(
                                    Text000Txt,
                                    FieldCaption("Expiration Date")));
                            SetFilter("Expiration Date", '%1 | %2..', 0D, WorkDate());
                        end;

                        if "Gen. Journal Batch"."No. Series" <> '' then begin
                            NoSeries.Get("Gen. Journal Batch"."No. Series");
                            LastEntrdDocNo := '';
                            LastEntrdDate := 0D;
                        end;

                        TempGenJournalLineCustVendIC.Reset();
                        TempGenJournalLineCustVendIC.DeleteAll();
                        VATEntryCreated := false;

                        GenJnlLine2.Reset();
                        GenJnlLine2.CopyFilters("Gen. Journal Line");

                        TempGLAccNetChange.DeleteAll();
                    end;
                }
                dataitem(ReconcileLoop; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    column(GLAccNetChangeNo; TempGLAccNetChange."No.")
                    {
                    }
                    column(GLAccNetChangeName; TempGLAccNetChange.Name)
                    {
                    }
                    column(GLAccNetChangeNetChangeJnl; TempGLAccNetChange."Net Change in Jnl.")
                    {
                    }
                    column(GLAccNetChangeBalafterPost; TempGLAccNetChange."Balance after Posting")
                    {
                    }
                    column(ReconciliationCaption; ReconciliationLbl)
                    {
                    }
                    column(NoCaption; NoLbl)
                    {
                    }
                    column(NameCaption; NameLbl)
                    {
                    }
                    column(NetChangeinJnlCaption; NetChangeinJnlLbl)
                    {
                    }
                    column(BalafterPostingCaption; BalafterPostingLbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if Number = 1 then
                            TempGLAccNetChange.Find('-')
                        else
                            TempGLAccNetChange.Next();
                    end;

                    trigger OnPostDataItem()
                    begin
                        TempGLAccNetChange.DeleteAll();
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange(Number, 1, TempGLAccNetChange.Count);
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
                    field(ShowDim; ShowDim)
                    {
                        ApplicationArea = Dimensions;
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

    var
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
        TempGenJournalLineCustVendIC: Record "Gen. Journal Line" temporary;
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
        TempGLAccNetChange: Record "G/L Account Net Change" temporary;
        DimSetEntry: Record "Dimension Set Entry";
        Employee: Record Employee;
        DataMigrationError: Record "Data Migration Error";
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
        BalanceLCY: Decimal;
        AmountLCY: Decimal;
        DocBalance: Decimal;
        DocBalanceReverse: Decimal;
        DateBalance: Decimal;
        DateBalanceReverse: Decimal;
        TotalBalance: Decimal;
        TotalBalanceReverse: Decimal;
        AccName: Text[100];
        LastLineNo: Integer;
        AmountError: Boolean;
        ErrorCounter: Integer;
        ErrorText: array[50] of Text[250];
        TempErrorText: Text[250];
        BalAccName: Text[100];
        VATEntryCreated: Boolean;
        CustPosting: Boolean;
        VendPosting: Boolean;
        SalesPostingType: Boolean;
        PurchPostingType: Boolean;
        DimText: Text[75];
        AllocationDimText: Text[75];
        ShowDim: Boolean;
        Continue: Boolean;
        CurrentICPartner: Code[20];

        Text000Txt: Label '%1 cannot be filtered when you post recurring journals.', Comment = '%1=Posting or Expiration Date';
        Text001Txt: Label '%1 or %2 must be specified.', Comment = '%1=Account Number, %2=Balance Account Number';
        Text002Txt: Label '%1 must be specified.', Comment = '%1=Gen. Posting Type';
        Text003Txt: Label '%1 + %2 must be %3.', Comment = '%1=VAT Amount, %2=VAT Base Amount, %3=Amont';
        Text004Txt: Label '%1 must be " " when %2 is %3.', Comment = '%1=Gen. Posting Type field caption, %2=Account Type field caption, %3=Account Type';
        Text005Txt: Label '%1, %2, %3 or %4 must not be completed when %5 is %6.', Comment = '%1=Gen. Bus. Posting Group field caption, %2=Gen. Bus. Posting Group field caption, %3=VAT Bus. Posting Group field caption, %4=VAT Bus. Posting Group field caption, %5=Account Type field caption, %6=Account Type';
        Text006Txt: Label '%1 must be negative.', Comment = '%1=GenJnlLine Amount field caption';
        Text007Txt: Label '%1 must be positive.', Comment = '%1=GenJnlLine Amount field caption';
        Text008Txt: Label '%1 must have the same sign as %2.', Comment = '%1=Amount LCY, %2=Amount';
        Text009Txt: Label '%1 cannot be specified.', Comment = '%1=Project No.';
        Text010Txt: Label '%1 must be Yes.', Comment = '%1=Check Printed';
        Text011Txt: Label '%1 + %2 must be -%3.', Comment = '%1=Bal. VAT Amount, %2=Bal. VAT Base Amount, %3=Amont';
        Text012Txt: Label '%1 must have a different sign than %2.', Comment = '%1=Sales/Purch. LCY, %2=Amount';
        Text013Txt: Label '%1 must only be a closing date for G/L entries.', Comment = '%1=Posting or Document Date';
        Text014Txt: Label '%1 is not within your allowed range of posting dates.', Comment = '%1=Posting Date';
        Text015Txt: Label 'The lines are not listed according to Posting Date because they were not entered in that order.';
        Text016Txt: Label 'There is a gap in the number series.';
        Text017Txt: Label '%1 or %2 must be G/L Account or Bank Account.', Comment = '%1=Account Type, %2=Bal. Account Type';
        Text018Txt: Label '%1 must be 0.', Comment = '%1=Payment Discount Percent';
        Text019Txt: Label '%1 cannot be specified when using recurring journals.', Comment = '%1=Bal. Account No.';
        Text020Txt: Label '%1 must not be %2 when %3 = %4.', Comment = '%1=Recurring Method field caption, %2=Recurring Method, %3=Bal. Account Type field caption, %4=Bal. Account Type';
        Text021Txt: Label 'Allocations can only be used with recurring journals.';
        Text022Txt: Label 'Specify %1 in the %2 allocation lines.', Comment = '%1=GenJnlAlloc. Account No. field caption, %2=GenJnlAlloc. Count';
        Text024Txt: Label '%1 %2 posted on %3, must be separated by an empty line.', Comment = '%1 - document type, %2 - document number, %3 - posting date';
        Text025Txt: Label '%1 %2 is out of balance by %3.', Comment = '%1=LastDocType, %2=LastDocNo, %3=DocBalance';
        Text026Txt: Label 'The reversing entries for %1 %2 are out of balance by %3.', Comment = '%1=LastDocType, %2=LastDocNo, %3=DocBalanceReverse';
        Text027Txt: Label 'As of %1, the lines are out of balance by %2.', Comment = '%1=LastDate, %2=DateBalance';
        Text028Txt: Label 'As of %1, the reversing entries are out of balance by %2.', Comment = '%1=LastDate, %2=DateBalanceReverse';
        Text029Txt: Label 'The total of the lines is out of balance by %1.', Comment = '%1=TotalBalance';
        Text030Txt: Label 'The total of the reversing entries is out of balance by %1.', Comment = '%1=TotalBalance';
        Text031Txt: Label '%1 %2 does not exist.', Comment = '%1=GLAcc.TableCaption(), %2=Account No.';
        Text032Txt: Label '%1 must be %2 for %3 %4.', Comment = '%1=GLAcc. Account Type field caption, %2=GLAcc.Account Type, %3=GLAcc. table caption, %4=Account No.';
        Text036Txt: Label '%1 %2 %3 does not exist.', Comment = '%1=VATPostingSetup table caption, %2=VAT Bus. Posting Group, %3=VAT Prod. Posting Group';
        Text037Txt: Label '%1 must be %2.', Comment = '%1=VAT Calculation Type field caption, %2=VATPostingSetup.VAT Calculation Type';
        Text038Txt: Label 'The currency %1 cannot be found. Check the currency table.', Comment = '%1=Currency Code';
        Text039Txt: Label 'Sales %1 %2 already exists.', Comment = '%1=Document Type, %2=Document No.';
        Text040Txt: Label 'Purchase %1 %2 already exists.', Comment = '%1=Document Type, %2=Document No.';
        Text041Txt: Label '%1 must be entered.', Comment = '%1=External Document No. field caption';
        Text042Txt: Label '%1 must not be filled when %2 is different in %3 and %4.', Comment = '%1=Bank Payment Type, %2=Currency Code, %3=TABLECAPTION, %4= BankAcc. Table caption';
        Text043Txt: Label '%1 %2 must not have %3 = %4.', Comment = '%1=FA.TableCaption(), %2=Account No., %3=FA.Budgeted Asset field caption, %4=TRUE';
        Text044Txt: Label '%1 must not be specified in fixed asset journal lines.', Comment = '%1=Project No. field caption';
        Text045Txt: Label '%1 must be specified in fixed asset journal lines.', Comment = '%1=FA Posting Type field caption';
        Text046Txt: Label '%1 must be different than %2.', Comment = '%1=Depreciation Book Code field caption, %2=Duplicate in Depreciation Book field caption';
        Text047Txt: Label '%1 and %2 must not both be %3.', Comment = '%1=Account Type field caption, %2=Bal. Account Type field caption, %3=Account Type';
#pragma warning disable AA0470
        Text049Txt: Label '%1 must not be specified when %2 = %3.', Comment = '%1=Gen. Posting Type field caption, 2%=FA Posting Type field caption, %3=FA Posting Type';
#pragma warning restore AA0470
        Text050Txt: Label 'must not be specified together with %1 = %2.', Comment = '%1=FA Posting Type field caption, %2=FA Posting Type';
        Text051Txt: Label '%1 must be identical to %2.', Comment = '%1=Posting Date field caption,%2=FA Posting Date';
        Text052Txt: Label '%1 cannot be a closing date.', Comment = '%1=FA Posting Date field caption';
        Text053Txt: Label '%1 is not within your range of allowed posting dates.', Comment = '%1=FA Posting Date field caption';
        Text054Txt: Label 'Insurance integration is not activated for %1 %2.', Comment = '%1=Depreciation Book Code field caption,%2=Depreciation Book Code';
        Text055Txt: Label 'must not be specified when %1 is specified.', Comment = '%1=FA Error Entry No. field caption';
        Text056Txt: Label 'When G/L integration is not activated, %1 must not be posted in the general journal.', Comment = '%1=FA Posting Type';
        Text057Txt: Label 'When G/L integration is not activated, %1 must not be specified in the general journal.', Comment = '%1=Depr. until FA Posting Date field caption';
        Text058Txt: Label '%1 must not be specified.', Comment = '%1=FA Posting Type field caption';
        Text059Txt: Label 'The combination of Customer and Gen. Posting Type Purchase is not allowed.';
        Text060Txt: Label 'The combination of Vendor and Gen. Posting Type Sales is not allowed.';
        Text061Txt: Label 'The Balance and Reversing Balance recurring methods can be used only with Allocations.';
        Text062Txt: Label '%1 must not be 0.', Comment = '%1=GenJnlLine  Amount';
        Text064Txt: Label '%1 %2 is already used in line %3 (%4 %5).', Comment = '%1=GenJnlLine External Document No. field caption, %2=GenJnlLine External Document No., %3=TempGenJnlLine Line No., %4=GenJnlLine Document No.field caption, %5=TempGenJnlLine Document No.';
        Text065Txt: Label '%1 must not be blocked with type %2 when %3 is %4.', Comment = '%1=Account Type, %2=Cust.Blocked, %3=Document Type field caption, %4=Document Type';
        Text066Txt: Label 'You cannot enter G/L Account or Bank Account in both %1 and %2.', Comment = '%1=Account No. field caption, %2=Bal. Account No. field caption';
        Text067Txt: Label '%1 %2 is linked to %3 %4.', Comment = '%1=Customer table caption, %2=Account No., %3=ICPartner table caption, %4=IC Partner Code';
        Text069Txt: Label '%1 must not be specified when %2 is %3.', Comment = '%1=IC Partner G/L Acc. No. field caption, %2=IC Direction field caption, %3=IC Direction';
        Text070Txt: Label '%1 must not be specified when the document is not an intercompany transaction.', Comment = '%1=IC Partner G/L Acc. No. field caption';
        Text071Txt: Label '%1 %2 does not exist.', Comment = '%1=Project table caption, %2=Project No.';
        Text072Txt: Label '%1 must not be %2 for %3 %4.', Comment = '%1=Project Blocked field caption, %2=Project Blocked, %3=Project table caption, %4=Project No.';
        Text073Txt: Label '%1 %2 already exists.', Comment = '%1=Document No. field caption, %2=Document No.';
        PostingErrorTxt: Label 'Posting error on batch %1- Document Number %2 %3', Comment = '%1=Gen. Journal Line Journal Batch Name, %2=Gen. Journal Line Document No., %3=Text';
        GPMigrationTypeTxt: Label 'Great Plains', Locked = true;
        GeneralJnlTestLbl: Label 'General Journal - Test';
        PageNoLbl: Label 'Page';
        JnlBatchNameLbl: Label 'Journal Batch';
        PostingDateLbl: Label 'Posting Date';
        DocumentTypeLbl: Label 'Document Type';
        AccountTypeLbl: Label 'Account Type';
        AccNameLbl: Label 'Name';
        GenPostingTypeLbl: Label 'Gen. Posting Type';
        GenBusPostingGroupLbl: Label 'Gen. Bus. Posting Group';
        GenProdPostingGroupLbl: Label 'Gen. Prod. Posting Group';
        AmountLCYLbl: Label 'Total (LCY)';
        DimensionsLbl: Label 'Dimensions';
        WarningLbl: Label 'Warning!';
        ReconciliationLbl: Label 'Reconciliation';
        NoLbl: Label 'No.';
        NameLbl: Label 'Name';
        NetChangeinJnlLbl: Label 'Net Change in Jnl.';
        BalafterPostingLbl: Label 'Balance after Posting';
        DimensionAllocationsLbl: Label 'Allocation Dimensions';

    local procedure CheckRecurringLine(GenJnlLine2: Record "Gen. Journal Line")
    begin
        if GenJnlTemplate.Recurring then begin
            if GenJnlLine2."Recurring Method" = "Gen. Journal Recurring Method"::" " then
                AddError(StrSubstNo(Text002Txt, GenJnlLine2.FieldCaption("Recurring Method")));
            if Format(GenJnlLine2."Recurring Frequency") = '' then
                AddError(StrSubstNo(Text002Txt, GenJnlLine2.FieldCaption("Recurring Frequency")));
            if GenJnlLine2."Bal. Account No." <> '' then
                AddError(
                  StrSubstNo(
                    Text019Txt,
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
                        Text020Txt,
                        GenJnlLine2.FieldCaption("Recurring Method"), GenJnlLine2."Recurring Method",
                        GenJnlLine2.FieldCaption("Account Type"), GenJnlLine2."Account Type"));
                if GenJnlLine2."Bal. Account Type" = GenJnlLine2."Bal. Account Type"::"Fixed Asset" then
                    AddError(
                      StrSubstNo(
                        Text020Txt,
                        GenJnlLine2.FieldCaption("Recurring Method"), GenJnlLine2."Recurring Method",
                        GenJnlLine2.FieldCaption("Bal. Account Type"), GenJnlLine2."Bal. Account Type"));
            end;
        end else begin
            if GenJnlLine2."Recurring Method" <> "Gen. Journal Recurring Method"::" " then
                AddError(StrSubstNo(Text009Txt, GenJnlLine2.FieldCaption("Recurring Method")));
            if Format(GenJnlLine2."Recurring Frequency") <> '' then
                AddError(StrSubstNo(Text009Txt, GenJnlLine2.FieldCaption("Recurring Frequency")));
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
                AddError(Text061Txt);
        end;

        GenJnlAlloc.Reset();
        GenJnlAlloc.SetRange("Journal Template Name", GenJnlLine2."Journal Template Name");
        GenJnlAlloc.SetRange("Journal Batch Name", GenJnlLine2."Journal Batch Name");
        GenJnlAlloc.SetRange("Journal Line No.", GenJnlLine2."Line No.");
        GenJnlAlloc.SetFilter(Amount, '<>0');
        if GenJnlAlloc.FindFirst() then
            if not GenJnlTemplate.Recurring then
                AddError(Text021Txt)
            else begin
                GenJnlAlloc.SetRange("Account No.", '');
                if GenJnlAlloc.FindFirst() then
                    AddError(
                      StrSubstNo(
                        Text022Txt,
                        GenJnlAlloc.FieldCaption("Account No."), GenJnlAlloc.Count));
            end;
    end;

    local procedure MakeRecurringTexts(var GenJnlLine2: Record "Gen. Journal Line")
    begin
        if (GenJnlLine2."Posting Date" <> 0D) and (GenJnlLine2."Account No." <> '') and (GenJnlLine2."Recurring Method" <> "Gen. Journal Recurring Method"::" ") then
            AccountingPeriod.MakeRecurringTexts(GenJnlLine2."Posting Date", GenJnlLine2."Document No.", GenJnlLine2.Description);
    end;

    local procedure CheckBalance()
    var
        GenJnlLine: Record "Gen. Journal Line";
        NextGenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine := "Gen. Journal Line";
        LastLineNo := "Gen. Journal Line"."Line No.";
        NextGenJnlLine := "Gen. Journal Line";
        if NextGenJnlLine.Next() = 0 then;
        MakeRecurringTexts(NextGenJnlLine);
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
            if TotalBalance = 0 then
                VATEntryCreated := false;
            if GenJnlTemplate."Force Doc. Balance" then begin
                VATEntryCreated :=
                  VATEntryCreated or
                  ((GenJnlLine."Account Type" = GenJnlLine."Account Type"::"G/L Account") and (GenJnlLine."Account No." <> '') and
                   (GenJnlLine."Gen. Posting Type" in [GenJnlLine."Gen. Posting Type"::Purchase, GenJnlLine."Gen. Posting Type"::Sale])) or
                  ((GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::"G/L Account") and (GenJnlLine."Bal. Account No." <> '') and
                   (GenJnlLine."Bal. Gen. Posting Type" in [GenJnlLine."Bal. Gen. Posting Type"::Purchase, GenJnlLine."Bal. Gen. Posting Type"::Sale]));
                TempGenJournalLineCustVendIC.IsCustVendICAdded(GenJnlLine);
                if (TempGenJournalLineCustVendIC.Count > 1) and VATEntryCreated then
                    AddError(
                      StrSubstNo(
                        Text024Txt,
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
                        AddError(StrSubstNo(Text025Txt, LastDocType, LastDocNo, DocBalance));
                    DocBalanceReverse <> 0:
                        AddError(StrSubstNo(Text026Txt, LastDocType, LastDocNo, DocBalanceReverse));
                end;
                DocBalance := 0;
                DocBalanceReverse := 0;
            end;
            if (NextGenJnlLine."Posting Date" <> LastDate) or
               (NextGenJnlLine."Document Type" <> LastDocType) or (NextGenJnlLine."Document No." <> LastDocNo)
            then begin
                TempGenJournalLineCustVendIC.Reset();
                TempGenJournalLineCustVendIC.DeleteAll();
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
                        Text027Txt,
                        LastDate, DateBalance));
                DateBalanceReverse <> 0:
                    AddError(
                      StrSubstNo(
                        Text028Txt,
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
                        Text029Txt,
                        TotalBalance));
                TotalBalanceReverse <> 0:
                    AddError(
                      StrSubstNo(
                        Text030Txt,
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

        if DataMigrationError.FindLast() then
            DataMigrationError.Id := DataMigrationError.Id + 1
        else
            DataMigrationError.Id := 1;
        DataMigrationError.Init();
        DataMigrationError."Migration Type" := GPMigrationTypeTxt;
        DataMigrationError."Error Message" :=
          StrSubstNo(PostingErrorTxt, "Gen. Journal Line"."Journal Batch Name", "Gen. Journal Line"."Document No.", Text);
        DataMigrationError.Insert();
    end;

    local procedure ReconcileGLAccNo(GLAccNo: Code[20]; ReconcileAmount: Decimal)
    begin
        if not TempGLAccNetChange.Get(GLAccNo) then begin
            GLAcc.Get(GLAccNo);
            GLAcc.CalcFields("Balance at Date");
            TempGLAccNetChange.Init();
            TempGLAccNetChange."No." := GLAcc."No.";
            TempGLAccNetChange.Name := GLAcc.Name;
            TempGLAccNetChange."Balance after Posting" := GLAcc."Balance at Date";
            TempGLAccNetChange.Insert();
        end;
        TempGLAccNetChange."Net Change in Jnl." := TempGLAccNetChange."Net Change in Jnl." + ReconcileAmount;
        TempGLAccNetChange."Balance after Posting" := TempGLAccNetChange."Balance after Posting" + ReconcileAmount;
        TempGLAccNetChange.Modify();
    end;

    local procedure CheckGLAcc(var GenJnlLine: Record "Gen. Journal Line"; var AccName: Text[100])
    begin
        if not GLAcc.Get(GenJnlLine."Account No.") then
            AddError(
              StrSubstNo(
                Text031Txt,
                GLAcc.TableCaption(), GenJnlLine."Account No."))
        else begin
            AccName := GLAcc.Name;

            if GLAcc.Blocked then
                AddError(
                  StrSubstNo(
                    Text032Txt,
                    GLAcc.FieldCaption(Blocked), false, GLAcc.TableCaption(), GenJnlLine."Account No."));
            if GLAcc."Account Type" <> GLAcc."Account Type"::Posting then begin
                GLAcc."Account Type" := GLAcc."Account Type"::Posting;
                AddError(
                  StrSubstNo(
                    Text032Txt,
                    GLAcc.FieldCaption("Account Type"), GLAcc."Account Type", GLAcc.TableCaption(), GenJnlLine."Account No."));
            end;
            if not GenJnlLine."System-Created Entry" then
                if GenJnlLine."Posting Date" = NormalDate(GenJnlLine."Posting Date") then
                    if not GLAcc."Direct Posting" then
                        AddError(
                          StrSubstNo(
                            Text032Txt,
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
                        Text036Txt,
                        VATPostingSetup.TableCaption(), GenJnlLine."VAT Bus. Posting Group", GenJnlLine."VAT Prod. Posting Group"))
                else
                    if GenJnlLine."VAT Calculation Type" <> VATPostingSetup."VAT Calculation Type" then
                        AddError(
                          StrSubstNo(
                            Text037Txt,
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
                Text031Txt,
                Cust.TableCaption(), GenJnlLine."Account No."))
        else begin
            AccName := Cust.Name;
            if Cust."Privacy Blocked" then
                AddError(Cust.GetPrivacyBlockedGenericErrorText(Cust));
            if ((Cust.Blocked = Cust.Blocked::All) or
                ((Cust.Blocked = Cust.Blocked::Invoice) and
                 (GenJnlLine."Document Type" in [GenJnlLine."Document Type"::Invoice, GenJnlLine."Document Type"::" "]))
                )
            then
                AddError(
                  StrSubstNo(
                    Text065Txt,
                    GenJnlLine."Account Type", Cust.Blocked, GenJnlLine.FieldCaption("Document Type"), GenJnlLine."Document Type"));
            if GenJnlLine."Currency Code" <> '' then
                if not Currency.Get(GenJnlLine."Currency Code") then
                    AddError(
                      StrSubstNo(
                        Text038Txt,
                        GenJnlLine."Currency Code"));
            if (Cust."IC Partner Code" <> '') and (GenJnlTemplate.Type = GenJnlTemplate.Type::Intercompany) then
                if ICPartner.Get(Cust."IC Partner Code") then begin
                    if ICPartner.Blocked then
                        AddError(
                          StrSubstNo(
                            '%1 %2',
                            StrSubstNo(
                              Text067Txt,
                              Cust.TableCaption(), GenJnlLine."Account No.", ICPartner.TableCaption(), GenJnlLine."IC Partner Code"),
                            StrSubstNo(
                              Text032Txt,
                              ICPartner.FieldCaption(Blocked), false, ICPartner.TableCaption(), Cust."IC Partner Code")));
                end else
                    AddError(
                      StrSubstNo(
                        '%1 %2',
                        StrSubstNo(
                          Text067Txt,
                          Cust.TableCaption(), GenJnlLine."Account No.", ICPartner.TableCaption(), Cust."IC Partner Code"),
                        StrSubstNo(
                          Text031Txt,
                          ICPartner.TableCaption(), Cust."IC Partner Code")));
            CustPosting := true;
            TestPostingType();

            if GenJnlLine."Recurring Method" = "Gen. Journal Recurring Method"::" " then
                if GenJnlLine."Document Type" in
                   [GenJnlLine."Document Type"::Invoice, GenJnlLine."Document Type"::"Credit Memo",
                    GenJnlLine."Document Type"::"Finance Charge Memo", GenJnlLine."Document Type"::Reminder]
                then begin
                    OldCustLedgEntry.Reset();
                    OldCustLedgEntry.SetCurrentKey("Document No.");
                    OldCustLedgEntry.SetRange("Document Type", GenJnlLine."Document Type");
                    OldCustLedgEntry.SetRange("Document No.", GenJnlLine."Document No.");
                    if OldCustLedgEntry.FindFirst() then
                        AddError(
                          StrSubstNo(
                            Text039Txt, GenJnlLine."Document Type", GenJnlLine."Document No."));

                    if SalesSetup."Ext. Doc. No. Mandatory" or
                       (GenJnlLine."External Document No." <> '')
                    then begin
                        if GenJnlLine."External Document No." = '' then
                            AddError(
                              StrSubstNo(
                                Text041Txt, GenJnlLine.FieldCaption("External Document No.")));

                        OldCustLedgEntry.Reset();
                        OldCustLedgEntry.SetCurrentKey("External Document No.");
                        OldCustLedgEntry.SetRange("Document Type", GenJnlLine."Document Type");
                        OldCustLedgEntry.SetRange("Customer No.", GenJnlLine."Account No.");
                        OldCustLedgEntry.SetRange("External Document No.", GenJnlLine."External Document No.");
                        if OldCustLedgEntry.FindFirst() then
                            AddError(
                              StrSubstNo(
                                Text039Txt,
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
                Text031Txt,
                Vend.TableCaption(), GenJnlLine."Account No."))
        else begin
            AccName := Vend.Name;
            if Vend."Privacy Blocked" then
                AddError(Vend.GetPrivacyBlockedGenericErrorText(Vend));
            if ((Vend.Blocked = Vend.Blocked::All) or
                ((Vend.Blocked = Vend.Blocked::Payment) and (GenJnlLine."Document Type" = GenJnlLine."Document Type"::Payment))
                )
            then
                AddError(
                  StrSubstNo(
                    Text065Txt,
                    GenJnlLine."Account Type", Vend.Blocked, GenJnlLine.FieldCaption("Document Type"), GenJnlLine."Document Type"));
            if GenJnlLine."Currency Code" <> '' then
                if not Currency.Get(GenJnlLine."Currency Code") then
                    AddError(
                      StrSubstNo(
                        Text038Txt,
                        GenJnlLine."Currency Code"));

            if (Vend."IC Partner Code" <> '') and (GenJnlTemplate.Type = GenJnlTemplate.Type::Intercompany) then
                if ICPartner.Get(Vend."IC Partner Code") then begin
                    if ICPartner.Blocked then
                        AddError(
                          StrSubstNo(
                            '%1 %2',
                            StrSubstNo(
                              Text067Txt,
                              Vend.TableCaption(), GenJnlLine."Account No.", ICPartner.TableCaption(), Vend."IC Partner Code"),
                            StrSubstNo(
                              Text032Txt,
                              ICPartner.FieldCaption(Blocked), false, ICPartner.TableCaption(), Vend."IC Partner Code")));
                end else
                    AddError(
                      StrSubstNo(
                        '%1 %2',
                        StrSubstNo(
                          Text067Txt,
                          Vend.TableCaption(), GenJnlLine."Account No.", ICPartner.TableCaption(), GenJnlLine."IC Partner Code"),
                        StrSubstNo(
                          Text031Txt,
                          ICPartner.TableCaption(), Vend."IC Partner Code")));
            VendPosting := true;
            TestPostingType();

            if GenJnlLine."Recurring Method" = "Gen. Journal Recurring Method"::" " then
                if GenJnlLine."Document Type" in
                   [GenJnlLine."Document Type"::Invoice, GenJnlLine."Document Type"::"Credit Memo",
                    GenJnlLine."Document Type"::"Finance Charge Memo", GenJnlLine."Document Type"::Reminder]
                then begin
                    OldVendLedgEntry.Reset();
                    OldVendLedgEntry.SetCurrentKey("Document No.");
                    OldVendLedgEntry.SetRange("Document Type", GenJnlLine."Document Type");
                    OldVendLedgEntry.SetRange("Document No.", GenJnlLine."Document No.");
                    if OldVendLedgEntry.FindFirst() then
                        AddError(
                          StrSubstNo(
                            Text040Txt,
                            GenJnlLine."Document Type", GenJnlLine."Document No."));

                    if PurchSetup."Ext. Doc. No. Mandatory" or
                       (GenJnlLine."External Document No." <> '')
                    then begin
                        if GenJnlLine."External Document No." = '' then
                            AddError(
                              StrSubstNo(
                                Text041Txt, GenJnlLine.FieldCaption("External Document No.")));

                        OldVendLedgEntry.Reset();
                        OldVendLedgEntry.SetCurrentKey("External Document No.");
                        OldVendLedgEntry.SetRange("Document Type", GenJnlLine."Document Type");
                        OldVendLedgEntry.SetRange("Vendor No.", GenJnlLine."Account No.");
                        OldVendLedgEntry.SetRange("External Document No.", GenJnlLine."External Document No.");
                        if OldVendLedgEntry.FindFirst() then
                            AddError(
                              StrSubstNo(
                                Text040Txt,
                                GenJnlLine."Document Type", GenJnlLine."External Document No."));
                        CheckAgainstPrevLines("Gen. Journal Line");
                    end;
                end;
        end;
    end;

    local procedure CheckEmployee(var GenJnlLine: Record "Gen. Journal Line"; var AccName: Text[100])
    begin
        if not Employee.Get(GenJnlLine."Account No.") then
            AddError(StrSubstNo(Text031Txt, Employee.TableCaption(), GenJnlLine."Account No."))
        else begin
            AccName := Employee."No.";
            if Employee."Privacy Blocked" then
                AddError(StrSubstNo(Text032Txt, Employee.FieldCaption("Privacy Blocked"), false, Employee.TableCaption(), AccName))
        end;
    end;

    local procedure CheckBankAcc(var GenJnlLine: Record "Gen. Journal Line"; var AccName: Text[100])
    begin
        if not BankAcc.Get(GenJnlLine."Account No.") then
            AddError(
              StrSubstNo(
                Text031Txt,
                BankAcc.TableCaption(), GenJnlLine."Account No."))
        else begin
            AccName := BankAcc.Name;

            if BankAcc.Blocked then
                AddError(
                  StrSubstNo(
                    Text032Txt,
                    BankAcc.FieldCaption(Blocked), false, BankAcc.TableCaption(), GenJnlLine."Account No."));
            if (GenJnlLine."Currency Code" <> BankAcc."Currency Code") and (BankAcc."Currency Code" <> '') then
                AddError(
                  StrSubstNo(
                    Text037Txt,
                    GenJnlLine.FieldCaption("Currency Code"), BankAcc."Currency Code"));

            if GenJnlLine."Currency Code" <> '' then
                if not Currency.Get(GenJnlLine."Currency Code") then
                    AddError(
                      StrSubstNo(
                        Text038Txt,
                        GenJnlLine."Currency Code"));

            if GenJnlLine."Bank Payment Type" <> GenJnlLine."Bank Payment Type"::" " then
                if (GenJnlLine."Bank Payment Type" = GenJnlLine."Bank Payment Type"::"Computer Check") and (GenJnlLine.Amount < 0) then
                    if BankAcc."Currency Code" <> GenJnlLine."Currency Code" then
                        AddError(
                          StrSubstNo(
                            Text042Txt,
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
                Text031Txt,
                FA.TableCaption(), GenJnlLine."Account No."))
        else begin
            AccName := FA.Description;
            if FA.Blocked then
                AddError(
                  StrSubstNo(
                    Text032Txt,
                    FA.FieldCaption(Blocked), false, FA.TableCaption(), GenJnlLine."Account No."));
            if FA.Inactive then
                AddError(
                  StrSubstNo(
                    Text032Txt,
                    FA.FieldCaption(Inactive), false, FA.TableCaption(), GenJnlLine."Account No."));
            if FA."Budgeted Asset" then
                AddError(
                  StrSubstNo(
                    Text043Txt,
                    FA.TableCaption(), GenJnlLine."Account No.", FA.FieldCaption("Budgeted Asset"), true));
            if DeprBook.Get(GenJnlLine."Depreciation Book Code") then
                CheckFAIntegration(GenJnlLine)
            else
                AddError(
                  StrSubstNo(
                    Text031Txt,
                    DeprBook.TableCaption(), GenJnlLine."Depreciation Book Code"));
            if not FADeprBook.Get(FA."No.", GenJnlLine."Depreciation Book Code") then
                AddError(
                  StrSubstNo(
                    Text036Txt,
                    FADeprBook.TableCaption(), FA."No.", GenJnlLine."Depreciation Book Code"));
        end;
    end;

    local procedure CheckICPartner(var GenJnlLine: Record "Gen. Journal Line"; var AccName: Text[100])
    begin
        if not ICPartner.Get(GenJnlLine."Account No.") then
            AddError(
              StrSubstNo(
                Text031Txt,
                ICPartner.TableCaption(), GenJnlLine."Account No."))
        else begin
            AccName := ICPartner.Name;
            if ICPartner.Blocked then
                AddError(
                  StrSubstNo(
                    Text032Txt,
                    ICPartner.FieldCaption(Blocked), false, ICPartner.TableCaption(), GenJnlLine."Account No."));
        end;
    end;

    local procedure TestFixedAsset(var GenJnlLine: Record "Gen. Journal Line")
    begin
        CheckInitialFAFields(GenJnlLine);
        CheckFADocNo(GenJnlLine);
        CheckAccountTypeFAFields(GenJnlLine);
        CheckBalAccountTypeFAFields(GenJnlLine);
        TempErrorText :=
          '%1 ' +
          StrSubstNo(
            Text050Txt,
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
                    Text051Txt,
                    GenJnlLine.FieldCaption("Posting Date"), GenJnlLine.FieldCaption("FA Posting Date")));
        CheckPostingDateFAFields(GenJnlLine);
        FASetup.Get();
        if (GenJnlLine."FA Posting Type" = GenJnlLine."FA Posting Type"::"Acquisition Cost") and
           (GenJnlLine."Insurance No." <> '') and (GenJnlLine."Depreciation Book Code" <> FASetup."Insurance Depr. Book")
        then
            AddError(
              StrSubstNo(
                Text054Txt,
                GenJnlLine.FieldCaption("Depreciation Book Code"), GenJnlLine."Depreciation Book Code"));

        if GenJnlLine."FA Error Entry No." > 0 then begin
            TempErrorText :=
              '%1 ' +
              StrSubstNo(
                Text055Txt,
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
            if GenJnlLine."Recurring Method" <> "Gen. Journal Recurring Method"::" " then
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
                Text056Txt,
                GenJnlLine."FA Posting Type"));

        if not DeprBook."G/L Integration - Depreciation" then begin
            if GenJnlLine."Depr. until FA Posting Date" then
                AddError(
                  StrSubstNo(
                    Text057Txt,
                    GenJnlLine.FieldCaption("Depr. until FA Posting Date")));
            if GenJnlLine."Depr. Acquisition Cost" then
                AddError(
                  StrSubstNo(
                    Text057Txt,
                    GenJnlLine.FieldCaption("Depr. Acquisition Cost")));
        end;
    end;

    local procedure TestFixedAssetFields(var GenJnlLine: Record "Gen. Journal Line")
    begin
        if GenJnlLine."FA Posting Type" <> GenJnlLine."FA Posting Type"::" " then
            AddError(StrSubstNo(Text058Txt, GenJnlLine.FieldCaption("FA Posting Type")));
        if GenJnlLine."Depreciation Book Code" <> '' then
            AddError(StrSubstNo(Text058Txt, GenJnlLine.FieldCaption("Depreciation Book Code")));
    end;

    procedure TestPostingType()
    begin
        case true of
            CustPosting and PurchPostingType:
                AddError(Text059Txt);
            VendPosting and SalesPostingType:
                AddError(Text060Txt);
        end;
    end;

    local procedure WarningIfNegativeAmt(GenJnlLine: Record "Gen. Journal Line")
    begin
        if (GenJnlLine.Amount < 0) and not AmountError then begin
            AmountError := true;
            AddError(StrSubstNo(Text007Txt, GenJnlLine.FieldCaption(Amount)));
        end;
    end;

    local procedure WarningIfPositiveAmt(GenJnlLine: Record "Gen. Journal Line")
    begin
        if (GenJnlLine.Amount > 0) and not AmountError then begin
            AmountError := true;
            AddError(StrSubstNo(Text006Txt, GenJnlLine.FieldCaption(Amount)));
        end;
    end;

    local procedure WarningIfZeroAmt(GenJnlLine: Record "Gen. Journal Line")
    begin
        if (GenJnlLine.Amount = 0) and not AmountError then begin
            AmountError := true;
            AddError(StrSubstNo(Text002Txt, GenJnlLine.FieldCaption(Amount)));
        end;
    end;

    local procedure WarningIfNonZeroAmt(GenJnlLine: Record "Gen. Journal Line")
    begin
        if (GenJnlLine.Amount <> 0) and not AmountError then begin
            AmountError := true;
            AddError(StrSubstNo(Text062Txt, GenJnlLine.FieldCaption(Amount)));
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

        i := 0;
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
                    Text064Txt, GenJnlLine.FieldCaption("External Document No."), GenJnlLine."External Document No.",
                    TempGenJnlLine."Line No.", GenJnlLine.FieldCaption("Document No."), TempGenJnlLine."Document No."));
            end;
        end;

        TempGenJnlLine.Reset();
        TempGenJnlLine := GenJnlLine;
        TempGenJnlLine.Insert();
    end;

    local procedure CheckICDocument()
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

    local procedure TestJobFields(var GenJnlLine: Record "Gen. Journal Line")
    var
        Job: Record Job;
        JobTask: Record "Job Task";
    begin
        if (GenJnlLine."Job No." = '') or (GenJnlLine."Account Type" <> GenJnlLine."Account Type"::"G/L Account") then
            exit;
        if not Job.Get(GenJnlLine."Job No.") then
            AddError(StrSubstNo(Text071Txt, Job.TableCaption(), GenJnlLine."Job No."))
        else
            if Job.Blocked <> Job.Blocked::" " then
                AddError(
                  StrSubstNo(
                    Text072Txt, Job.FieldCaption(Blocked), Job.Blocked, Job.TableCaption(), GenJnlLine."Job No."));

        if GenJnlLine."Job Task No." = '' then
            AddError(StrSubstNo(Text002Txt, GenJnlLine.FieldCaption("Job Task No.")))
        else
            if not JobTask.Get(GenJnlLine."Job No.", GenJnlLine."Job Task No.") then
                AddError(StrSubstNo(Text071Txt, JobTask.TableCaption(), GenJnlLine."Job Task No."))
    end;

    local procedure CheckFADocNo(GenJnlLine: Record "Gen. Journal Line")
    var
        DepreciationBook2: Record "Depreciation Book";
        FAJnlLine: Record "FA Journal Line";
        OldFALedgEntry: Record "FA Ledger Entry";
        OldMaintenanceLedgEntry: Record "Maintenance Ledger Entry";
        FANo: Code[20];
    begin
        if GenJnlLine."Account Type" = GenJnlLine."Account Type"::"Fixed Asset" then
            FANo := GenJnlLine."Account No.";
        if GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::"Fixed Asset" then
            FANo := GenJnlLine."Bal. Account No.";
        if (FANo = '') or
           (GenJnlLine."FA Posting Type" = GenJnlLine."FA Posting Type"::" ") or
           (GenJnlLine."Depreciation Book Code" = '') or
           (GenJnlLine."Document No." = '')
        then
            exit;
        if not DepreciationBook2.Get(GenJnlLine."Depreciation Book Code") then
            exit;
        if DepreciationBook2."Allow Identical Document No." then
            exit;

        FAJnlLine."FA Posting Type" := "FA Journal Line FA Posting Type".FromInteger(GenJnlLine."FA Posting Type".AsInteger() - 1);
        if GenJnlLine."FA Posting Type" <> GenJnlLine."FA Posting Type"::Maintenance then begin
            OldFALedgEntry.SetCurrentKey(
              "FA No.", "Depreciation Book Code", "FA Posting Category", "FA Posting Type", "Document No.");
            OldFALedgEntry.SetRange("FA No.", FANo);
            OldFALedgEntry.SetRange("Depreciation Book Code", GenJnlLine."Depreciation Book Code");
            OldFALedgEntry.SetRange("FA Posting Category", OldFALedgEntry."FA Posting Category"::" ");
            OldFALedgEntry.SetRange("FA Posting Type", FAJnlLine.ConvertToLedgEntry(FAJnlLine));
            OldFALedgEntry.SetRange("Document No.", GenJnlLine."Document No.");
            if not OldFALedgEntry.IsEmpty() then
                AddError(StrSubstNo(Text073Txt, GenJnlLine.FieldCaption("Document No."), GenJnlLine."Document No."));
        end else begin
            OldMaintenanceLedgEntry.SetCurrentKey(
              "FA No.", "Depreciation Book Code", "Document No.");
            OldMaintenanceLedgEntry.SetRange("FA No.", FANo);
            OldMaintenanceLedgEntry.SetRange("Depreciation Book Code", GenJnlLine."Depreciation Book Code");
            OldMaintenanceLedgEntry.SetRange("Document No.", GenJnlLine."Document No.");
            if not OldMaintenanceLedgEntry.IsEmpty() then
                AddError(StrSubstNo(Text073Txt, GenJnlLine.FieldCaption("Document No."), GenJnlLine."Document No."));
        end;
    end;

    procedure InitializeRequest(NewShowDim: Boolean)
    begin
        ShowDim := NewShowDim;
    end;

    local procedure GetDimensionText(var DimensionSetEntry: Record "Dimension Set Entry"): Text[75]
    var
        DimensionText: Text[75];
        Separator: Code[10];
        DimValue: Text[45];
    begin
        Separator := '';
        DimValue := '';
        Continue := false;

        repeat
            DimValue := StrSubstNo('%1 - %2', DimensionSetEntry."Dimension Code", DimensionSetEntry."Dimension Value Code");
            if MaxStrLen(DimensionText) < StrLen(DimensionText + Separator + DimValue) then begin
                Continue := true;
                exit(DimensionText);
            end;
            DimensionText := DimensionText + Separator + DimValue;
            Separator := '; ';
        until DimSetEntry.Next() = 0;
        exit(DimensionText);
    end;

    local procedure CheckAccountTypes(AccountType: Enum "Gen. Journal Account Type"; var Name: Text[100])
    begin
        case AccountType of
            AccountType::"G/L Account":
                CheckGLAcc("Gen. Journal Line", Name);
            AccountType::Customer:
                CheckCust("Gen. Journal Line", Name);
            AccountType::Vendor:
                CheckVend("Gen. Journal Line", Name);
            AccountType::"Bank Account":
                CheckBankAcc("Gen. Journal Line", Name);
            AccountType::"Fixed Asset":
                CheckFixedAsset("Gen. Journal Line", Name);
            AccountType::"IC Partner":
                CheckICPartner("Gen. Journal Line", Name);
            AccountType::Employee:
                CheckEmployee("Gen. Journal Line", Name);
        end;
    end;

    local procedure CheckInitialFAFields(var GenJnlLine: Record "Gen. Journal Line")
    begin
        if GenJnlLine."Job No." <> '' then
            AddError(
              StrSubstNo(
                Text044Txt, GenJnlLine.FieldCaption("Job No.")));
        if GenJnlLine."FA Posting Type" = GenJnlLine."FA Posting Type"::" " then
            AddError(
              StrSubstNo(
                Text045Txt, GenJnlLine.FieldCaption("FA Posting Type")));
        if GenJnlLine."Depreciation Book Code" = '' then
            AddError(
              StrSubstNo(
                Text045Txt, GenJnlLine.FieldCaption("Depreciation Book Code")));
        if GenJnlLine."Depreciation Book Code" = GenJnlLine."Duplicate in Depreciation Book" then
            AddError(
              StrSubstNo(
                Text046Txt,
                GenJnlLine.FieldCaption("Depreciation Book Code"), GenJnlLine.FieldCaption("Duplicate in Depreciation Book")));
    end;

    local procedure CheckPostingDateFAFields(var GenJnlLine: Record "Gen. Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPostingDateFAFields(GenJnlLine, ErrorText, ErrorCounter, IsHandled);
        if IsHandled then
            exit;

        if GenJnlLine."FA Posting Date" <> 0D then begin
            if GenJnlLine."FA Posting Date" <> NormalDate(GenJnlLine."FA Posting Date") then
                AddError(
                  StrSubstNo(
                    Text052Txt,
                    GenJnlLine.FieldCaption("FA Posting Date")));
            if not (GenJnlLine."FA Posting Date" in [DMY2Date(1, 1, 2) .. DMY2Date(31, 12, 9998)]) then
                AddError(
                  StrSubstNo(
                    Text053Txt,
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
                    AllowFAPostingTo := DMY2Date(31, 12, 9998);
            end;
            if (GenJnlLine."FA Posting Date" < AllowFAPostingFrom) or
               (GenJnlLine."FA Posting Date" > AllowFAPostingTo)
            then
                AddError(
                  StrSubstNo(
                    Text053Txt,
                    GenJnlLine.FieldCaption("FA Posting Date")));
        end;
    end;

    local procedure CheckAccountTypeFAFields(var GenJnlLine: Record "Gen. Journal Line")
    begin
        if GenJnlLine."Account Type" = GenJnlLine."Bal. Account Type" then
            AddError(
              StrSubstNo(
                Text047Txt,
                GenJnlLine.FieldCaption("Account Type"), GenJnlLine.FieldCaption("Bal. Account Type"), GenJnlLine."Account Type"));
        if GenJnlLine."Account Type" = GenJnlLine."Account Type"::"Fixed Asset" then
            if GenJnlLine."FA Posting Type" in
               [GenJnlLine."FA Posting Type"::"Acquisition Cost", GenJnlLine."FA Posting Type"::Disposal, GenJnlLine."FA Posting Type"::Maintenance]
            then begin
                if (GenJnlLine."Gen. Bus. Posting Group" <> '') or (GenJnlLine."Gen. Prod. Posting Group" <> '') then
                    if GenJnlLine."Gen. Posting Type" = GenJnlLine."Gen. Posting Type"::" " then
                        AddError(StrSubstNo(Text002Txt, GenJnlLine.FieldCaption("Gen. Posting Type")));
            end else begin
                if GenJnlLine."Gen. Posting Type" <> GenJnlLine."Gen. Posting Type"::" " then
                    AddError(
                      StrSubstNo(
                        Text049Txt,
                        GenJnlLine.FieldCaption("Gen. Posting Type"), GenJnlLine.FieldCaption("FA Posting Type"), GenJnlLine."FA Posting Type"));
                if GenJnlLine."Gen. Bus. Posting Group" <> '' then
                    AddError(
                      StrSubstNo(
                        Text049Txt,
                        GenJnlLine.FieldCaption("Gen. Bus. Posting Group"), GenJnlLine.FieldCaption("FA Posting Type"), GenJnlLine."FA Posting Type"));
                if GenJnlLine."Gen. Prod. Posting Group" <> '' then
                    AddError(
                      StrSubstNo(
                        Text049Txt,
                        GenJnlLine.FieldCaption("Gen. Prod. Posting Group"), GenJnlLine.FieldCaption("FA Posting Type"), GenJnlLine."FA Posting Type"));
            end;
    end;

    local procedure CheckBalAccountTypeFAFields(var GenJnlLine: Record "Gen. Journal Line")
    begin
        if GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::"Fixed Asset" then
            if GenJnlLine."FA Posting Type" in
               [GenJnlLine."FA Posting Type"::"Acquisition Cost", GenJnlLine."FA Posting Type"::Disposal, GenJnlLine."FA Posting Type"::Maintenance]
            then begin
                if (GenJnlLine."Bal. Gen. Bus. Posting Group" <> '') or (GenJnlLine."Bal. Gen. Prod. Posting Group" <> '') then
                    if GenJnlLine."Bal. Gen. Posting Type" = GenJnlLine."Bal. Gen. Posting Type"::" " then
                        AddError(StrSubstNo(Text002Txt, GenJnlLine.FieldCaption("Bal. Gen. Posting Type")));
            end else begin
                if GenJnlLine."Bal. Gen. Posting Type" <> GenJnlLine."Bal. Gen. Posting Type"::" " then
                    AddError(
                      StrSubstNo(
                        Text049Txt,
                        GenJnlLine.FieldCaption("Bal. Gen. Posting Type"), GenJnlLine.FieldCaption("FA Posting Type"), GenJnlLine."FA Posting Type"));
                if GenJnlLine."Bal. Gen. Bus. Posting Group" <> '' then
                    AddError(
                      StrSubstNo(
                        Text049Txt,
                        GenJnlLine.FieldCaption("Bal. Gen. Bus. Posting Group"), GenJnlLine.FieldCaption("FA Posting Type"), GenJnlLine."FA Posting Type"));
                if GenJnlLine."Bal. Gen. Prod. Posting Group" <> '' then
                    AddError(
                      StrSubstNo(
                        Text049Txt,
                        GenJnlLine.FieldCaption("Bal. Gen. Prod. Posting Group"), GenJnlLine.FieldCaption("FA Posting Type"), GenJnlLine."FA Posting Type"));
            end;
    end;

    local procedure OnAfterGetGenJnlLineAccount(var GenJnlLine: Record "Gen. Journal Line")
    begin
        if GenJnlLine."Account No." <> '' then
            case GenJnlLine."Account Type" of
                GenJnlLine."Account Type"::"G/L Account":
                    begin
                        if (GenJnlLine."Gen. Bus. Posting Group" <> '') or (GenJnlLine."Gen. Prod. Posting Group" <> '') or
                           (GenJnlLine."VAT Bus. Posting Group" <> '') or (GenJnlLine."VAT Prod. Posting Group" <> '')
                        then
                            if GenJnlLine."Gen. Posting Type" = GenJnlLine."Gen. Posting Type"::" " then
                                AddError(StrSubstNo(Text002Txt, GenJnlLine.FieldCaption("Gen. Posting Type")));
                        if (GenJnlLine."Gen. Posting Type" <> GenJnlLine."Gen. Posting Type"::" ") and
                           (GenJnlLine."VAT Posting" = GenJnlLine."VAT Posting"::"Automatic VAT Entry")
                        then begin
                            if GenJnlLine."VAT Amount" + GenJnlLine."VAT Base Amount" <> GenJnlLine.Amount then
                                AddError(
                                  StrSubstNo(
                                    Text003Txt, GenJnlLine.FieldCaption("VAT Amount"), GenJnlLine.FieldCaption("VAT Base Amount"),
                                    GenJnlLine.FieldCaption(Amount)));
                            if GenJnlLine."Currency Code" <> '' then
                                if GenJnlLine."VAT Amount (LCY)" + GenJnlLine."VAT Base Amount (LCY)" <> GenJnlLine."Amount (LCY)" then
                                    AddError(
                                      StrSubstNo(
                                        Text003Txt, GenJnlLine.FieldCaption("VAT Amount (LCY)"),
                                        GenJnlLine.FieldCaption("VAT Base Amount (LCY)"), GenJnlLine.FieldCaption("Amount (LCY)")));
                        end;
                        TestJobFields("Gen. Journal Line");
                    end;
                GenJnlLine."Account Type"::Customer, GenJnlLine."Account Type"::Vendor:
                    begin
                        if GenJnlLine."Gen. Posting Type" <> GenJnlLine."Gen. Posting Type"::" " then
                            AddError(
                              StrSubstNo(
                                Text004Txt,
                                GenJnlLine.FieldCaption("Gen. Posting Type"), GenJnlLine.FieldCaption("Account Type"), GenJnlLine."Account Type"));
                        if (GenJnlLine."Gen. Bus. Posting Group" <> '') or (GenJnlLine."Gen. Prod. Posting Group" <> '') or
                           (GenJnlLine."VAT Bus. Posting Group" <> '') or (GenJnlLine."VAT Prod. Posting Group" <> '')
                        then
                            AddError(
                              StrSubstNo(
                                Text005Txt,
                                GenJnlLine.FieldCaption("Gen. Bus. Posting Group"), GenJnlLine.FieldCaption("Gen. Prod. Posting Group"),
                                GenJnlLine.FieldCaption("VAT Bus. Posting Group"), GenJnlLine.FieldCaption("VAT Prod. Posting Group"),
                                GenJnlLine.FieldCaption("Account Type"), GenJnlLine."Account Type"));

                        if GenJnlLine."Document Type" <> GenJnlLine."Document Type"::" " then
                            if GenJnlLine."Account Type" = GenJnlLine."Account Type"::Customer then
                                case GenJnlLine."Document Type" of
                                    GenJnlLine."Document Type"::"Credit Memo":
                                        WarningIfPositiveAmt("Gen. Journal Line");
                                    GenJnlLine."Document Type"::Payment:
                                        if (GenJnlLine."Applies-to Doc. Type" = GenJnlLine."Applies-to Doc. Type"::"Credit Memo") and
                                           (GenJnlLine."Applies-to Doc. No." <> '')
                                        then
                                            WarningIfNegativeAmt("Gen. Journal Line")
                                        else
                                            WarningIfPositiveAmt("Gen. Journal Line");
                                    GenJnlLine."Document Type"::Refund:
                                        WarningIfNegativeAmt("Gen. Journal Line");
                                    else
                                        WarningIfNegativeAmt("Gen. Journal Line");
                                end
                            else
                                case GenJnlLine."Document Type" of
                                    GenJnlLine."Document Type"::"Credit Memo":
                                        WarningIfNegativeAmt("Gen. Journal Line");
                                    GenJnlLine."Document Type"::Payment:
                                        if (GenJnlLine."Applies-to Doc. Type" = GenJnlLine."Applies-to Doc. Type"::"Credit Memo") and
                                           (GenJnlLine."Applies-to Doc. No." <> '')
                                        then
                                            WarningIfPositiveAmt("Gen. Journal Line")
                                        else
                                            WarningIfNegativeAmt("Gen. Journal Line");
                                    GenJnlLine."Document Type"::Refund:
                                        WarningIfPositiveAmt("Gen. Journal Line");
                                    else
                                        WarningIfPositiveAmt("Gen. Journal Line");
                                end;

                        if GenJnlLine.Amount * GenJnlLine."Sales/Purch. (LCY)" < 0 then
                            AddError(
                              StrSubstNo(
                                Text008Txt,
                                GenJnlLine.FieldCaption("Sales/Purch. (LCY)"), GenJnlLine.FieldCaption(Amount)));
                        if GenJnlLine."Job No." <> '' then
                            AddError(StrSubstNo(Text009Txt, GenJnlLine.FieldCaption("Job No.")));
                    end;
                GenJnlLine."Account Type"::"Bank Account":
                    begin
                        if GenJnlLine."Gen. Posting Type" <> GenJnlLine."Gen. Posting Type"::" " then
                            AddError(
                              StrSubstNo(
                                Text004Txt,
                                GenJnlLine.FieldCaption("Gen. Posting Type"), GenJnlLine.FieldCaption("Account Type"), GenJnlLine."Account Type"));
                        if (GenJnlLine."Gen. Bus. Posting Group" <> '') or (GenJnlLine."Gen. Prod. Posting Group" <> '') or
                           (GenJnlLine."VAT Bus. Posting Group" <> '') or (GenJnlLine."VAT Prod. Posting Group" <> '')
                        then
                            AddError(
                              StrSubstNo(
                                Text005Txt,
                                GenJnlLine.FieldCaption("Gen. Bus. Posting Group"), GenJnlLine.FieldCaption("Gen. Prod. Posting Group"),
                                GenJnlLine.FieldCaption("VAT Bus. Posting Group"), GenJnlLine.FieldCaption("VAT Prod. Posting Group"),
                                GenJnlLine.FieldCaption("Account Type"), GenJnlLine."Account Type"));

                        if GenJnlLine."Job No." <> '' then
                            AddError(StrSubstNo(Text009Txt, GenJnlLine.FieldCaption("Job No.")));
                        if (GenJnlLine.Amount < 0) and (GenJnlLine."Bank Payment Type" = GenJnlLine."Bank Payment Type"::"Computer Check") then
                            if not GenJnlLine."Check Printed" then
                                AddError(StrSubstNo(Text010Txt, GenJnlLine.FieldCaption("Check Printed")));
                    end;
                GenJnlLine."Account Type"::"Fixed Asset":
                    TestFixedAsset("Gen. Journal Line");
            end;
    end;

    local procedure OnAfterGetGenJnlLineBalanceAccount(var GenJnlLine: Record "Gen. Journal Line")
    begin
        if GenJnlLine."Bal. Account No." <> '' then
            case GenJnlLine."Bal. Account Type" of
                GenJnlLine."Bal. Account Type"::"G/L Account":
                    begin
                        if (GenJnlLine."Bal. Gen. Bus. Posting Group" <> '') or (GenJnlLine."Bal. Gen. Prod. Posting Group" <> '') or
                           (GenJnlLine."Bal. VAT Bus. Posting Group" <> '') or (GenJnlLine."Bal. VAT Prod. Posting Group" <> '')
                        then
                            if GenJnlLine."Bal. Gen. Posting Type" = GenJnlLine."Bal. Gen. Posting Type"::" " then
                                AddError(StrSubstNo(Text002Txt, GenJnlLine.FieldCaption("Bal. Gen. Posting Type")));
                        if (GenJnlLine."Bal. Gen. Posting Type" <> GenJnlLine."Bal. Gen. Posting Type"::" ") and
                           (GenJnlLine."VAT Posting" = GenJnlLine."VAT Posting"::"Automatic VAT Entry")
                        then begin
                            if GenJnlLine."Bal. VAT Amount" + GenJnlLine."Bal. VAT Base Amount" <> -GenJnlLine.Amount then
                                AddError(
                                  StrSubstNo(
                                    Text011Txt, GenJnlLine.FieldCaption("Bal. VAT Amount"), GenJnlLine.FieldCaption("Bal. VAT Base Amount"),
                                    GenJnlLine.FieldCaption(Amount)));
                            if GenJnlLine."Currency Code" <> '' then
                                if GenJnlLine."Bal. VAT Amount (LCY)" + GenJnlLine."Bal. VAT Base Amount (LCY)" <> -GenJnlLine."Amount (LCY)" then
                                    AddError(
                                      StrSubstNo(
                                        Text011Txt, GenJnlLine.FieldCaption("Bal. VAT Amount (LCY)"),
                                        GenJnlLine.FieldCaption("Bal. VAT Base Amount (LCY)"), GenJnlLine.FieldCaption("Amount (LCY)")));
                        end;
                    end;
                GenJnlLine."Bal. Account Type"::Customer, GenJnlLine."Bal. Account Type"::Vendor:
                    begin
                        if GenJnlLine."Bal. Gen. Posting Type" <> GenJnlLine."Bal. Gen. Posting Type"::" " then
                            AddError(
                              StrSubstNo(
                                Text004Txt,
                                GenJnlLine.FieldCaption("Bal. Gen. Posting Type"), GenJnlLine.FieldCaption("Bal. Account Type"), GenJnlLine."Bal. Account Type"));
                        if (GenJnlLine."Bal. Gen. Bus. Posting Group" <> '') or (GenJnlLine."Bal. Gen. Prod. Posting Group" <> '') or
                           (GenJnlLine."Bal. VAT Bus. Posting Group" <> '') or (GenJnlLine."Bal. VAT Prod. Posting Group" <> '')
                        then
                            AddError(
                              StrSubstNo(
                                Text005Txt,
                                GenJnlLine.FieldCaption("Bal. Gen. Bus. Posting Group"), GenJnlLine.FieldCaption("Bal. Gen. Prod. Posting Group"),
                                GenJnlLine.FieldCaption("Bal. VAT Bus. Posting Group"), GenJnlLine.FieldCaption("Bal. VAT Prod. Posting Group"),
                                GenJnlLine.FieldCaption("Bal. Account Type"), GenJnlLine."Bal. Account Type"));

                        if GenJnlLine."Document Type" <> GenJnlLine."Document Type"::" " then
                            if (GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::Customer) =
                               (GenJnlLine."Document Type" in [GenJnlLine."Document Type"::Payment, GenJnlLine."Document Type"::"Credit Memo"])
                            then
                                WarningIfNegativeAmt("Gen. Journal Line")
                            else
                                WarningIfPositiveAmt("Gen. Journal Line");

                        if GenJnlLine.Amount * GenJnlLine."Sales/Purch. (LCY)" > 0 then
                            AddError(
                              StrSubstNo(
                                Text012Txt,
                                GenJnlLine.FieldCaption("Sales/Purch. (LCY)"), GenJnlLine.FieldCaption(Amount)));
                        if GenJnlLine."Job No." <> '' then
                            AddError(StrSubstNo(Text009Txt, GenJnlLine.FieldCaption("Job No.")));
                    end;
                GenJnlLine."Bal. Account Type"::"Bank Account":
                    begin
                        if GenJnlLine."Bal. Gen. Posting Type" <> GenJnlLine."Bal. Gen. Posting Type"::" " then
                            AddError(
                              StrSubstNo(
                                Text004Txt,
                                GenJnlLine.FieldCaption("Bal. Gen. Posting Type"), GenJnlLine.FieldCaption("Bal. Account Type"), GenJnlLine."Bal. Account Type"));
                        if (GenJnlLine."Bal. Gen. Bus. Posting Group" <> '') or (GenJnlLine."Bal. Gen. Prod. Posting Group" <> '') or
                           (GenJnlLine."Bal. VAT Bus. Posting Group" <> '') or (GenJnlLine."Bal. VAT Prod. Posting Group" <> '')
                        then
                            AddError(
                              StrSubstNo(
                                Text005Txt,
                                GenJnlLine.FieldCaption("Bal. Gen. Bus. Posting Group"), GenJnlLine.FieldCaption("Bal. Gen. Prod. Posting Group"),
                                GenJnlLine.FieldCaption("Bal. VAT Bus. Posting Group"), GenJnlLine.FieldCaption("Bal. VAT Prod. Posting Group"),
                                GenJnlLine.FieldCaption("Bal. Account Type"), GenJnlLine."Bal. Account Type"));

                        if GenJnlLine."Job No." <> '' then
                            AddError(StrSubstNo(Text009Txt, GenJnlLine.FieldCaption("Job No.")));
                        if (GenJnlLine.Amount > 0) and (GenJnlLine."Bank Payment Type" = GenJnlLine."Bank Payment Type"::"Computer Check") then
                            if not GenJnlLine."Check Printed" then
                                AddError(StrSubstNo(Text010Txt, GenJnlLine.FieldCaption("Check Printed")));
                    end;
                GenJnlLine."Bal. Account Type"::"Fixed Asset":
                    TestFixedAsset("Gen. Journal Line");
            end;
    end;

    local procedure OnAfterGetGenJnlLinePostingDate(var GenJnlLine: Record "Gen. Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnAfterGetGenJnlLinePostingDate(GenJnlLine, ErrorText, ErrorCounter, IsHandled);
        if IsHandled then
            exit;

        if GenJnlLine."Posting Date" = 0D then
            AddError(StrSubstNo(Text002Txt, GenJnlLine.FieldCaption("Posting Date")))
        else begin
            if GenJnlLine."Posting Date" <> NormalDate(GenJnlLine."Posting Date") then
                if (GenJnlLine."Account Type" <> GenJnlLine."Account Type"::"G/L Account") or
                   (GenJnlLine."Bal. Account Type" <> GenJnlLine."Bal. Account Type"::"G/L Account")
                then
                    AddError(
                      StrSubstNo(
                        Text013Txt, GenJnlLine.FieldCaption("Posting Date")));

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
                    AllowPostingTo := DMY2Date(31, 12, 9999);
            end;
            if (GenJnlLine."Posting Date" < AllowPostingFrom) or (GenJnlLine."Posting Date" > AllowPostingTo) then
                AddError(
                  StrSubstNo(
                    Text014Txt, Format(GenJnlLine."Posting Date")));

            if "Gen. Journal Batch"."No. Series" <> '' then begin
                if NoSeries."Date Order" and (GenJnlLine."Posting Date" < LastEntrdDate) then
                    AddError(Text015Txt);
                LastEntrdDate := GenJnlLine."Posting Date";
            end;
        end;
    end;

    local procedure OnAfterGetGenJnlLineAccountType(var GenJnlLine: Record "Gen. Journal Line")
    var
        PaymentTerms: Record "Payment Terms";
    begin
        if (GenJnlLine."Account Type" = GenJnlLine."Account Type"::"G/L Account") and
           (GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::"G/L Account")
        then
            if GenJnlLine."Applies-to Doc. No." <> '' then
                AddError(StrSubstNo(Text009Txt, GenJnlLine.FieldCaption("Applies-to Doc. No.")));

        if ((GenJnlLine."Account Type" = GenJnlLine."Account Type"::"G/L Account") and
            (GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::"G/L Account")) or
           (GenJnlLine."Document Type" <> GenJnlLine."Document Type"::Invoice)
        then begin
            if not PaymentTerms.Get(GenJnlLine."Payment Terms Code") then begin
                if GenJnlLine."Pmt. Discount Date" <> 0D then
                    AddError(StrSubstNo(Text009Txt, GenJnlLine.FieldCaption("Pmt. Discount Date")));
                if GenJnlLine."Payment Discount %" <> 0 then
                    AddError(StrSubstNo(Text018Txt, GenJnlLine.FieldCaption("Payment Discount %")));
            end;

            if PaymentTerms.Get(GenJnlLine."Payment Terms Code") then
                if (GenJnlLine."Document Type" = GenJnlLine."Document Type"::"Credit Memo") and (not PaymentTerms."Calc. Pmt. Disc. on Cr. Memos") then begin
                    if GenJnlLine."Pmt. Discount Date" <> 0D then
                        AddError(StrSubstNo(Text009Txt, GenJnlLine.FieldCaption("Pmt. Discount Date")));
                    if GenJnlLine."Payment Discount %" <> 0 then
                        AddError(StrSubstNo(Text018Txt, GenJnlLine.FieldCaption("Payment Discount %")));
                end;
        end;

        if ((GenJnlLine."Account Type" = GenJnlLine."Account Type"::"G/L Account") and
            (GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::"G/L Account")) or
           (GenJnlLine."Applies-to Doc. No." <> '')
        then
            if GenJnlLine."Applies-to ID" <> '' then
                AddError(StrSubstNo(Text009Txt, GenJnlLine.FieldCaption("Applies-to ID")));

        if (GenJnlLine."Account Type" <> GenJnlLine."Account Type"::"Bank Account") and
           (GenJnlLine."Bal. Account Type" <> GenJnlLine."Bal. Account Type"::"Bank Account")
        then
            if GenJnlLine2."Bank Payment Type" <> GenJnlLine2."Bank Payment Type"::" " then
                AddError(StrSubstNo(Text009Txt, GenJnlLine.FieldCaption("Bank Payment Type")));
    end;

    local procedure CheckICAccountNo()
    var
        ICGLAccount: Record "IC G/L Account";
        ICBankAccount: Record "IC Bank Account";
    begin
        if (CurrentICPartner <> '') and ("Gen. Journal Line"."IC Direction" = "Gen. Journal Line"."IC Direction"::Outgoing) then
            if ("Gen. Journal Line"."Account Type" in ["Gen. Journal Line"."Account Type"::"G/L Account", "Gen. Journal Line"."Account Type"::"Bank Account"]) and
               ("Gen. Journal Line"."Bal. Account Type" in ["Gen. Journal Line"."Bal. Account Type"::"G/L Account", "Gen. Journal Line"."Account Type"::"Bank Account"]) and
               ("Gen. Journal Line"."Account No." <> '') and
               ("Gen. Journal Line"."Bal. Account No." <> '')
            then
                AddError(StrSubstNo(Text066Txt, "Gen. Journal Line".FieldCaption("Account No."), "Gen. Journal Line".FieldCaption("Bal. Account No.")))
            else begin
                if (("Gen. Journal Line"."Account Type" in ["Gen. Journal Line"."Account Type"::"G/L Account", "Gen. Journal Line"."Account Type"::"Bank Account"]) and ("Gen. Journal Line"."Account No." <> '')) xor
                   (("Gen. Journal Line"."Bal. Account Type" in ["Gen. Journal Line"."Bal. Account Type"::"G/L Account", "Gen. Journal Line"."Account Type"::"Bank Account"]) and
                    ("Gen. Journal Line"."Bal. Account No." <> ''))
                then
                    if "Gen. Journal Line"."IC Account No." = '' then
                        AddError(StrSubstNo(Text002Txt, "Gen. Journal Line".FieldCaption("IC Account No.")))
                    else begin
                        if "Gen. Journal Line"."IC Account Type" = "Gen. Journal Line"."IC Account Type"::"G/L Account" then
                            if ICGLAccount.Get("Gen. Journal Line"."IC Account No.") then
                                if ICGLAccount.Blocked then
                                    AddError(StrSubstNo(Text032Txt, ICGLAccount.FieldCaption(Blocked), false, "Gen. Journal Line".FieldCaption("IC Account No."),
                                        "Gen. Journal Line"."IC Account No."));

                        if "Gen. Journal Line"."IC Account Type" = "Gen. Journal Line"."IC Account Type"::"Bank Account" then
                            if ICBankAccount.Get("Gen. Journal Line"."IC Account No.", CurrentICPartner) then
                                if ICBankAccount.Blocked then
                                    AddError(StrSubstNo(Text032Txt, ICBankAccount.FieldCaption(Blocked), false, "Gen. Journal Line".FieldCaption("IC Account No."),
                                        "Gen. Journal Line"."IC Account No."));
                    end;
                if not ((("Gen. Journal Line"."Account Type" in ["Gen. Journal Line"."Account Type"::"G/L Account", "Gen. Journal Line"."Account Type"::"Bank Account"]) and
                         ("Gen. Journal Line"."Account No." <> '')) xor
                        (("Gen. Journal Line"."Bal. Account Type" in ["Gen. Journal Line"."Bal. Account Type"::"G/L Account", "Gen. Journal Line"."Account Type"::"Bank Account"]) and
                         ("Gen. Journal Line"."Bal. Account No." <> '')))
                then
                    if "Gen. Journal Line"."IC Account No." <> '' then
                        AddError(StrSubstNo(Text009Txt, "Gen. Journal Line".FieldCaption("IC Account No.")));
            end
        else
            if "Gen. Journal Line"."IC Account No." <> '' then begin
                if "Gen. Journal Line"."IC Direction" = "Gen. Journal Line"."IC Direction"::Incoming then
                    AddError(StrSubstNo(Text069Txt, "Gen. Journal Line".FieldCaption("IC Account No."),
                        "Gen. Journal Line".FieldCaption("IC Direction"), Format("Gen. Journal Line"."IC Direction")));
                if CurrentICPartner = '' then
                    AddError(StrSubstNo(Text070Txt, "Gen. Journal Line".FieldCaption("IC Account No.")));
            end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnAfterGetGenJnlLinePostingDate(var GenJournalLine: Record "Gen. Journal Line"; var ErrorText: array[50] of Text[250]; var ErrorCounter: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPostingDateFAFields(var GenJnlLine: Record "Gen. Journal Line"; var ErrorText: array[50] of Text[250]; var ErrorCounter: Integer; var IsHandled: Boolean)
    begin
    end;
}

