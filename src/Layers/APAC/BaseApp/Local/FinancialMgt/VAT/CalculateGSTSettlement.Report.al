// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.Consolidation;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Intercompany.Journal;
using Microsoft.Intercompany.Partner;
using Microsoft.Purchases.Vendor;
using System.Utilities;

report 11603 "Calculate GST Settlement"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/FinancialMgt/VAT/CalculateGSTSettlement.rdlc';
    Caption = 'Calculate GST Settlement';
    Permissions = TableData "G/L Account Net Change" = rimd,
                  TableData "VAT Entry" = m,
                  TableData "BAS Calculation Sheet" = rm;

    dataset
    {
        dataitem("BAS Calculation Sheet"; "BAS Calculation Sheet")
        {
            RequestFilterFields = A1, "BAS Version";
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(USERID; UserId)
            {
            }
            column(BAS_Calculation_Sheet_A1; A1)
            {
            }
            column(BAS_Calculation_Sheet_BAS_Version; "BAS Version")
            {
            }
            column(Calculate_GST_SettlementCaption; Calculate_GST_SettlementCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            dataitem(RepeatLoop; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                column(FORMAT__BAS_Calculation_Sheet__A4_; Format("BAS Calculation Sheet".A4))
                {
                }
                column(FORMAT__BAS_Calculation_Sheet__A3_; Format("BAS Calculation Sheet".A3))
                {
                }
                column(BAS_Calculation_Sheet___BAS_Version_; "BAS Calculation Sheet"."BAS Version")
                {
                }
                column(BAS_Calculation_Sheet__A1; "BAS Calculation Sheet".A1)
                {
                }
                column(RepeatLoop_RepeatLoop_Number; Number)
                {
                }
                column(BAS_Calculation_Sheet__A4Caption; BAS_Calculation_Sheet__A4CaptionLbl)
                {
                }
                column(BAS_Calculation_Sheet__A3Caption; BAS_Calculation_Sheet__A3CaptionLbl)
                {
                }
                column(BAS_Calculation_Sheet___BAS_Version_Caption; BAS_Calculation_Sheet___BAS_Version_CaptionLbl)
                {
                }
                column(BAS_Calculation_Sheet__A1Caption; BAS_Calculation_Sheet__A1CaptionLbl)
                {
                }
                dataitem("BAS Calc. Sheet Entry"; "BAS Calc. Sheet Entry")
                {
                    DataItemLink = "BAS Document No." = field(A1), "BAS Version" = field("BAS Version");
                    DataItemLinkReference = "BAS Calculation Sheet";
                    DataItemTableView = sorting("Company Name", "BAS Document No.", "BAS Version", "Field Label No.", Type, "Entry No.");
                    column(STRSUBSTNO__Field__1__CurrFieldID_; StrSubstNo('Field %1', CurrFieldID))
                    {
                    }
                    column(CurrAmt; CurrAmt)
                    {
                    }
                    column(FORMAT_ClearingPostingDate_; Format(ClearingPostingDate))
                    {
                    }
                    column(ClearingAccNo; ClearingAccNo)
                    {
                    }
                    column(ClearingDescription; ClearingDescription)
                    {
                    }
                    column(ClearingAmount; ClearingAmount)
                    {
                    }
                    column(ClearingVATAmount; ClearingVATAmount)
                    {
                    }
                    column(ClearingAmount_ClearingVATAmount; ClearingAmount + ClearingVATAmount)
                    {
                    }
                    column(TotalClearingVATAmount; TotalClearingVATAmount)
                    {
                    }
                    column(TotalClearingAmount; TotalClearingAmount)
                    {
                    }
                    column(TotalClearingAmount_TotalClearingVATAmount; TotalClearingAmount + TotalClearingVATAmount)
                    {
                    }
                    column(BAS_Calc__Sheet_Entry_Company_Name; "Company Name")
                    {
                    }
                    column(BAS_Calc__Sheet_Entry_BAS_Document_No_; "BAS Document No.")
                    {
                    }
                    column(BAS_Calc__Sheet_Entry_BAS_Version; "BAS Version")
                    {
                    }
                    column(BAS_Calc__Sheet_Entry_Field_Label_No_; "Field Label No.")
                    {
                    }
                    column(BAS_Calc__Sheet_Entry_Type; Type)
                    {
                    }
                    column(BAS_Calc__Sheet_Entry_Entry_No_; "Entry No.")
                    {
                    }
                    column(BAS_Calc__Sheet_Entry_Amount_Type; "Amount Type")
                    {
                    }
                    column(ClearingAmount_ClearingVATAmountCaption; ClearingAmount_ClearingVATAmountCaptionLbl)
                    {
                    }
                    column(ClearingVATAmountCaption; ClearingVATAmountCaptionLbl)
                    {
                    }
                    column(ClearingAmountCaption; ClearingAmountCaptionLbl)
                    {
                    }
                    column(ClearingDescriptionCaption; ClearingDescriptionCaptionLbl)
                    {
                    }
                    column(ClearingAccNoCaption; ClearingAccNoCaptionLbl)
                    {
                    }
                    column(ClearingPostingDateCaption; ClearingPostingDateCaptionLbl)
                    {
                    }
                    column(TotalsCaption; TotalsCaptionLbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    var
                        VATPostingSetup: Record "VAT Posting Setup";
                    begin
                        ClearingAccNo := '';
                        ClearingAmount := 0;
                        ClearingVATAmount := 0;
                        ClearingPostingDate := 0D;
                        ClearingDescription := '';

                        case Type of
                            Type::"G/L Entry":
                                begin
                                    GLEntry.Get("Entry No.");
                                    ClearingAccNo := GLEntry."G/L Account No.";
                                    ClearingAmount := GLEntry.Amount;
                                    ClearingVATAmount := GLEntry."VAT Amount";
                                    ClearingPostingDate := GLEntry."Posting Date";
                                    ClearingDescription := GLEntry.Description;
                                end;
                            Type::"GST Entry":
                                begin
                                    VATEntry.Get("Entry No.");
                                    if VATPostingSetup.Get(
                                         VATEntry."VAT Bus. Posting Group", VATEntry."VAT Prod. Posting Group")
                                    then
                                        case VATEntry.Type of
                                            VATEntry.Type::Sale:
                                                if VATPostingSetup."Sales VAT Account" <> '' then
                                                    ClearingAccNo := VATPostingSetup."Sales VAT Account";
                                            VATEntry.Type::Purchase:
                                                if VATPostingSetup."Purchase VAT Account" <> '' then
                                                    ClearingAccNo := VATPostingSetup."Purchase VAT Account";
                                        end;

                                    case "Amount Type" of
                                        "Amount Type"::Base, "Amount Type"::Amount:
                                            begin
                                                ClearingAmount := VATEntry.Base;
                                                ClearingVATAmount := VATEntry.Amount;
                                            end;
                                        "Amount Type"::"Unrealized Base", "Amount Type"::"Unrealized Amount":
                                            begin
                                                ClearingAmount := VATEntry."Unrealized Base";
                                                ClearingVATAmount := VATEntry."Unrealized Amount";
                                            end;
                                    end;
                                    ClearingPostingDate := VATEntry."Posting Date";
                                    ClearingDescription := StrSubstNo(Text1450015, VATEntry.TableCaption(), VATEntry."Entry No.");
                                end;
                        end;

                        if (ClearingAccNo = '') and (ClearingVATAmount <> 0) then
                            Error(Text1450009, VATEntry.TableCaption(), VATEntry."Entry No.");
                        if (AccType = AccType::"G/L Account") and (ClearingAccNo = AccNo) then
                            Error(Text1450006);
                        // IF ClearingAccNo = RoundAccNo THEN
                        // ERROR(Text1450007);

                        TotalClearingAmount := TotalClearingAmount + ClearingAmount;
                        TotalClearingVATAmount := TotalClearingVATAmount + ClearingVATAmount;

                        if Post then
                            if not TempGLAccountNetChange.Get(ClearingAccNo) then begin
                                TempGLAccountNetChange.Init();
                                TempGLAccountNetChange."No." := ClearingAccNo;
                                if Type = Type::"G/L Entry" then
                                    TempGLAccountNetChange."Net Change in Jnl." := ClearingAmount
                                else
                                    TempGLAccountNetChange."Net Change in Jnl." := ClearingVATAmount;
                                TempGLAccountNetChange.Insert();
                            end else begin
                                if Type = Type::"G/L Entry" then
                                    TempGLAccountNetChange."Net Change in Jnl." += ClearingAmount
                                else
                                    TempGLAccountNetChange."Net Change in Jnl." += ClearingVATAmount;
                                TempGLAccountNetChange.Modify();
                            end;
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange("Company Name", CompanyName);
                        SetRange("Field Label No.", CurrFieldID);
                        TotalClearingAmount := 0;
                        TotalClearingVATAmount := 0;
                        TempGLAccountNetChange.DeleteAll();
                    end;
                }
                dataitem(PostSettlementLoop; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = filter(1));
                    column(InterCompany; InterCompany)
                    {
                    }
                    column(GenJnlLine_2__Amount; -TempGenJnlLine[2].Amount)
                    {
                    }
                    column(GenJnlLine_2__Description; TempGenJnlLine[2].Description)
                    {
                    }
                    column(GenJnlLine_2___Account_No__; TempGenJnlLine[2]."Account No.")
                    {
                    }
                    column(GenJnlLine_2___Account_Type_; TempGenJnlLine[2]."Account Type")
                    {
                    }
                    column(FORMAT_GenJnlLine_2___Posting_Date__; Format(TempGenJnlLine[2]."Posting Date"))
                    {
                    }
                    column(TotalAmt; -TotalAmt)
                    {
                    }
                    column(GenJnlLine1_Description; GenJnlLine1.Description)
                    {
                    }
                    column(GenJnlLine1__Account_No__; GenJnlLine1."Account No.")
                    {
                    }
                    column(GenJnlLine1__Account_Type_; GenJnlLine1."Account Type")
                    {
                    }
                    column(FORMAT_GenJnlLine1__Posting_Date__; Format(GenJnlLine1."Posting Date"))
                    {
                    }
                    column(GenJnlLine_3__Amount; -TempGenJnlLine[3].Amount)
                    {
                    }
                    column(GenJnlLine_3__Description; TempGenJnlLine[3].Description)
                    {
                    }
                    column(GenJnlLine_3___Account_No__; TempGenJnlLine[3]."Account No.")
                    {
                    }
                    column(GenJnlLine_3___Account_Type_; TempGenJnlLine[3]."Account Type")
                    {
                    }
                    column(FORMAT_GenJnlLine_3___Posting_Date__; Format(TempGenJnlLine[3]."Posting Date"))
                    {
                    }
                    column(ShowRoundSection; ShowRoundSection)
                    {
                    }
                    column(PostSettlementLoop_Number; Number)
                    {
                    }
                    column(GenJnlLine_2___Posting_Date_Caption; GenJnlLine_2___Posting_Date_CaptionLbl)
                    {
                    }
                    column(GenJnlLine_2___Account_Type_Caption; GenJnlLine_2___Account_Type_CaptionLbl)
                    {
                    }
                    column(GenJnlLine_2___Account_No__Caption; GenJnlLine_2___Account_No__CaptionLbl)
                    {
                    }
                    column(GenJnlLine_2__DescriptionCaption; GenJnlLine_2__DescriptionCaptionLbl)
                    {
                    }
                    column(GenJnlLine_2__AmountCaption; GenJnlLine_2__AmountCaptionLbl)
                    {
                    }
                    column(TotalAmtCaption; TotalAmtCaptionLbl)
                    {
                    }
                    column(GenJnlLine1_DescriptionCaption; GenJnlLine1_DescriptionCaptionLbl)
                    {
                    }
                    column(GenJnlLine1__Account_No__Caption; GenJnlLine1__Account_No__CaptionLbl)
                    {
                    }
                    column(GenJnlLine1__Account_Type_Caption; GenJnlLine1__Account_Type_CaptionLbl)
                    {
                    }
                    column(GenJnlLine1__Posting_Date_Caption; GenJnlLine1__Posting_Date_CaptionLbl)
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if not Post then
                            CurrReport.Break();

                        if TempGLAccountNetChange.Find('-') then begin
                            // Post clearing accounts
                            repeat
                                if TempGLAccountNetChange."Net Change in Jnl." <> 0 then
                                    if InterCompany then begin
                                        InitGenJnlLine(GenJnlLine1, false);
                                        SetBASDataForGenJnlLine(GenJnlLine1);
                                        GenJnlLine1."Account Type" := GenJnlLine1."Account Type"::"G/L Account";
                                        GenJnlLine1.Validate("Account No.", TempGLAccountNetChange."No.");
                                        InitializeGenJournalLineForInterCompany(GenJnlLine1, TempGLAccountNetChange."No.");
                                        GenJnlLine1.Description := DescTxt;
                                        GenJnlLine1.Validate(Amount, -TempGLAccountNetChange."Net Change in Jnl.");
                                        if GenJnlLine1."VAT Calculation Type" <>
                                           GenJnlLine1."VAT Calculation Type"::"Full VAT"
                                        then
                                            GenJnlLine1."Gen. Posting Type" := GenJnlLine1."Gen. Posting Type"::Settlement;
                                        GenJnlLine1."Source Code" := SourceCodeSetup."VAT Settlement";
                                        TotalAmt := TotalAmt + TempGLAccountNetChange."Net Change in Jnl.";
                                        GenJnlLine1.Insert(true);
                                    end else begin
                                        InitGenJnlLine(TempGenJnlLine[1], false);
                                        SetBASDataForGenJnlLine(TempGenJnlLine[1]);
                                        TempGenJnlLine[1]."Account Type" := "Gen. Journal Account Type"::"G/L Account";
                                        TempGenJnlLine[1].Validate("Account No.", TempGLAccountNetChange."No.");
                                        TempGenJnlLine[1].Description := DescTxt;
                                        TempGenJnlLine[1].Validate(Amount, -TempGLAccountNetChange."Net Change in Jnl.");
                                        if TempGenJnlLine[1]."VAT Calculation Type" <>
                                           TempGenJnlLine[1]."VAT Calculation Type"::"Full VAT"
                                        then
                                            TempGenJnlLine[1]."Gen. Posting Type" := TempGenJnlLine[1]."Gen. Posting Type"::Settlement;
                                        TempGenJnlLine[1]."Source Code" := SourceCodeSetup."VAT Settlement";
                                        TotalAmt := TotalAmt + TempGLAccountNetChange."Net Change in Jnl.";
                                        GenJnlPostLine.Run(TempGenJnlLine[1]);
                                    end;
                            until TempGLAccountNetChange.Next() = 0;

                            // Post settlement account
                            if ((RoundAccNo = '') and (TotalAmt <> 0)) or
                               ((RoundAccNo <> '') and (CurrAmt <> 0))
                            then
                                if InterCompany then begin
                                    InitGenJnlLine(GenJnlLine1, true);
                                    SetBASDataForGenJnlLine(GenJnlLine1);
                                    case AccType of
                                        AccType::"G/L Account":
                                            GenJnlLine1."Account Type" := GenJnlLine1."Account Type"::"G/L Account";
                                        AccType::Vendor:
                                            GenJnlLine1."Account Type" := GenJnlLine1."Account Type"::Vendor;
                                    end;
                                    GenJnlLine1.Validate("Account No.", AccNo);
                                    InitializeGenJournalLineForInterCompany(GenJnlLine1, AccNo);
                                    GenJnlLine1.Description := DescTxt;
                                    SetSettlementAmount(GenJnlLine1);
                                    if GenJnlLine1."VAT Calculation Type" <>
                                       GenJnlLine1."VAT Calculation Type"::"Full VAT"
                                    then
                                        GenJnlLine1."Gen. Posting Type" := GenJnlLine1."Gen. Posting Type"::Settlement;
                                    GenJnlLine1."Source Code" := SourceCodeSetup."VAT Settlement";
                                    // GenJnlLine1.GetDefaultDim(JournalLineDimension[2]);
                                    GenJnlLine1.Insert(true);
                                end else begin
                                    InitGenJnlLine(TempGenJnlLine[2], false);
                                    SetBASDataForGenJnlLine(TempGenJnlLine[2]);
                                    case AccType of
                                        AccType::"G/L Account":
                                            TempGenJnlLine[2]."Account Type" := TempGenJnlLine[2]."Account Type"::"G/L Account";
                                        AccType::Vendor:
                                            TempGenJnlLine[2]."Account Type" := TempGenJnlLine[2]."Account Type"::Vendor;
                                    end;
                                    TempGenJnlLine[2].Validate("Account No.", AccNo);
                                    TempGenJnlLine[2].Description := DescTxt;
                                    SetSettlementAmount(TempGenJnlLine[2]);
                                    if TempGenJnlLine[2]."VAT Calculation Type" <>
                                       TempGenJnlLine[2]."VAT Calculation Type"::"Full VAT"
                                    then
                                        TempGenJnlLine[2]."Gen. Posting Type" := TempGenJnlLine[2]."Gen. Posting Type"::Settlement;
                                    TempGenJnlLine[2]."Source Code" := SourceCodeSetup."VAT Settlement";
                                    // GenJnlLine[2].GetDefaultDim(JournalLineDimension[2]);
                                    GenJnlPostLine.Run(TempGenJnlLine[2]);
                                    VATEntry2.Reset();
                                    VATEntry2.SetRange("Posting Date", PostDate);
                                    VATEntry2.SetRange("Document No.", DocNo);
                                    VATEntry2.SetFilter(Amount, '<%1', 0);
                                    if VATEntry2.FindLast() then
                                        VATApplyEntryNo := VATEntry2."Entry No.";
                                end;

                            // Post rounding account
                            if (RoundAccNo <> '') and (TotalAmt - CurrAmt <> 0) then begin
                                if InterCompany then begin
                                    InitGenJnlLine(GenJnlLine1, true);
                                    SetBASDataForGenJnlLine(GenJnlLine1);
                                    case AccType of
                                        AccType::"G/L Account":
                                            GenJnlLine1."Account Type" := GenJnlLine1."Account Type"::"G/L Account";
                                        AccType::Vendor:
                                            GenJnlLine1."Account Type" := GenJnlLine1."Account Type"::Vendor;
                                    end;
                                    GenJnlLine1.Validate("Account No.", RoundAccNo);
                                    InitializeGenJournalLineForInterCompany(GenJnlLine1, RoundAccNo);
                                    GenJnlLine1.Description := DescTxt;
                                    GenJnlLine1.Validate(Amount, TotalAmt - CurrAmt);
                                    if GenJnlLine1."VAT Calculation Type" <>
                                       GenJnlLine1."VAT Calculation Type"::"Full VAT"
                                    then
                                        GenJnlLine1."Gen. Posting Type" := GenJnlLine1."Gen. Posting Type"::Settlement;
                                    GenJnlLine1."Source Code" := SourceCodeSetup."VAT Settlement";
                                    // GenJnlLine1.GetDefaultDim(JournalLineDimension[2]);
                                    GenJnlLine1.Insert(true);
                                end else begin
                                    InitGenJnlLine(TempGenJnlLine[3], false);
                                    SetBASDataForGenJnlLine(TempGenJnlLine[3]);
                                    TempGenJnlLine[3]."Account Type" := "Gen. Journal Account Type"::"G/L Account";
                                    TempGenJnlLine[3].Validate("Account No.", RoundAccNo);
                                    TempGenJnlLine[3].Description := 'GST Settlement (Rounding)';
                                    TempGenJnlLine[3].Validate(Amount, TotalAmt - CurrAmt);
                                    if TempGenJnlLine[3]."VAT Calculation Type" <>
                                       TempGenJnlLine[3]."VAT Calculation Type"::"Full VAT"
                                    then
                                        TempGenJnlLine[3]."Gen. Posting Type" := TempGenJnlLine[3]."Gen. Posting Type"::Settlement;
                                    TempGenJnlLine[3]."Source Code" := SourceCodeSetup."VAT Settlement";
                                    // GenJnlLine[3].GetDefaultDim(JournalLineDimension[3]);
                                    GenJnlPostLine.Run(TempGenJnlLine[3]);
                                    ShowRoundSection := true;
                                end;
                            end else
                                ShowRoundSection := false;
                            if GenJnlLine1.Find('-') then
                                if InterCompany then
                                    CODEUNIT.Run(Codeunit::"Gen. Jnl.-Post", GenJnlLine1);
                        end;

                        VATEntry1.ModifyAll("Closed by Entry No.", VATApplyEntryNo);
                        VATEntry1.ModifyAll(Closed, true);
                    end;

                    trigger OnPreDataItem()
                    begin
                        if Post and GenJnlPostLine.IsGLEntryInconsistent() then begin
                            GenJnlPostLine.ShowInconsistentEntries();
                            error('');
                        end;
                        Clear(GenJnlPostLine);
                        Clear(TotalAmt);
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    case Number of
                        1:
                            SetFieldID("BAS Calculation Sheet".FieldName("1A"), "BAS Calculation Sheet"."1A");
                        2:
                            SetFieldID("BAS Calculation Sheet".FieldName("1B"), "BAS Calculation Sheet"."1B");
                        3:
                            SetFieldID("BAS Calculation Sheet".FieldName("1C"), "BAS Calculation Sheet"."1C");
                        4:
                            SetFieldID("BAS Calculation Sheet".FieldName("1D"), "BAS Calculation Sheet"."1D");
                        5:
                            SetFieldID("BAS Calculation Sheet".FieldName("1E"), "BAS Calculation Sheet"."1E");
                        6:
                            SetFieldID("BAS Calculation Sheet".FieldName("1F"), "BAS Calculation Sheet"."1F");
                        7:
                            SetFieldID("BAS Calculation Sheet".FieldName("1G"), "BAS Calculation Sheet"."1G");
                        8:
                            SetFieldID("BAS Calculation Sheet".FieldName("4"), "BAS Calculation Sheet"."4");
                        9:
                            SetFieldID("BAS Calculation Sheet".FieldName("5A"), "BAS Calculation Sheet"."5A");
                        10:
                            SetFieldID("BAS Calculation Sheet".FieldName("5B"), "BAS Calculation Sheet"."5B");
                        11:
                            SetFieldID("BAS Calculation Sheet".FieldName("6A"), "BAS Calculation Sheet"."6A");
                        12:
                            SetFieldID("BAS Calculation Sheet".FieldName("6B"), "BAS Calculation Sheet"."6B");
                        13:
                            SetFieldID("BAS Calculation Sheet".FieldName("7"), "BAS Calculation Sheet"."7");
                        14:
                            SetFieldID("BAS Calculation Sheet".FieldName("7C"), "BAS Calculation Sheet"."7C");
                        15:
                            SetFieldID("BAS Calculation Sheet".FieldName("7D"), "BAS Calculation Sheet"."7D");
                        else
                            CurrReport.Break();
                    end;

                    if Post then
                        Window.Update(3, StrSubstNo('Field %1', CurrFieldID));

                    if CurrAmt = 0 then
                        CurrReport.Skip();

                    VATEntry1.Reset();
                    VATEntry1.SetRange("BAS Doc. No.", "BAS Calculation Sheet".A1);
                    VATEntry1.SetRange("BAS Version", "BAS Calculation Sheet"."BAS Version");
                    VATEntry1.SetRange(Closed, false);
                end;

                trigger OnPostDataItem()
                begin
                    if Post then begin
                        if GenJnlPostLine.IsGLEntryInconsistent() then begin
                            GenJnlPostLine.ShowInconsistentEntries();
                            error('');
                        end;
                        "BAS Calculation Sheet".Settled := true;
                        "BAS Calculation Sheet".Modify();
                    end;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                TestField(Updated);
                TestField(Exported);
                if "Group Consolidated" then
                    Error(Text1450000);
                if Post then begin
                    TestField(Settled, false);
                    Window.Update(1, A1);
                    Window.Update(2, "BAS Version");
                end;
            end;

            trigger OnPostDataItem()
            begin
                if Post then begin
                    Window.Close();
                    Message(Text1450005);
                end;
            end;

            trigger OnPreDataItem()
            begin
                if Post and (AccNo = '') then
                    Error(Text1450001);

                if Post then
                    Window.Open(
                      Text1450002 +
                      Text1450003 +
                      Text1450004);
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
                    field(AccType; AccType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Settlement Account Type';
                        ToolTip = 'Specifies if the account is a general ledger account or a vendor account.';
                    }
                    field(AccNo; AccNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Settlement Account No.';
                        ToolTip = 'Specifies the general ledger account number or vendor number, based on the type selected in the Settlement Account Type field.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            case AccType of
                                AccType::"G/L Account":
                                    if PAGE.RunModal(0, GLAcc, GLAcc."No.") = ACTION::LookupOK then
                                        AccNo := GLAcc."No.";
                                AccType::Vendor:
                                    if PAGE.RunModal(0, Vendor, Vendor."No.") = ACTION::LookupOK then
                                        AccNo := Vendor."No.";
                            end;
                        end;
                    }
                    field(RoundAccNo; RoundAccNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Rounding G/L Account No.';
                        ToolTip = 'Specifies the general ledger account that you use for rounding amounts.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            if PAGE.RunModal(0, GLAcc, GLAcc."No.") = ACTION::LookupOK then
                                RoundAccNo := GLAcc."No.";
                        end;
                    }
                    field(PostDate; PostDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the posting date of the entry.';
                    }
                    field(DocNo; DocNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document No.';
                        ToolTip = 'Specifies the original document that is associated with this entry.';
                    }
                    field(DescTxt; DescTxt)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Description';
                        ToolTip = 'Specifies a description of the settlement.';
                    }
                    field(Post; Post)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Post';
                        ToolTip = 'Specifies that you want to post the settlement.';
                    }
                    field(InterCompany; InterCompany)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inter Company';
                        ToolTip = 'Specifies that the settlement includes intercompany transactions.';
                    }
                    field(ICPartnerCode; ICPartnerCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'IC Partner Code';
                        TableRelation = "IC Partner";
                        ToolTip = 'Specifies the intercompany partner.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if DescTxt = '' then
                DescTxt := Text1450000;
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup.TestField("Enable GST (Australia)", true);
    end;

    trigger OnPreReport()
    begin
        if not SourceCodeSetup.Get() then
            SourceCodeSetup."VAT Settlement" := '';
    end;

    var
        SourceCodeSetup: Record "Source Code Setup";
        GLAcc: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        Vendor: Record Vendor;
        TempGenJnlLine: array[3] of Record "Gen. Journal Line" temporary;
        TempGLAccountNetChange: Record "G/L Account Net Change" temporary;
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine1: Record "Gen. Journal Line";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        PostDate: Date;
        AccType: Option "G/L Account",Vendor;
        DescTxt: Text[30];
        CurrFieldID: Text[30];
        DocNo: Code[20];
        AccNo: Code[20];
        RoundAccNo: Code[20];
        CurrAmt: Decimal;
        TotalAmt: Decimal;
        Post: Boolean;
        ShowRoundSection: Boolean;
        Window: Dialog;
        Text1450000: Label 'GST Settlement';
        Text1450001: Label 'Please enter Settlement Account No.';
        Text1450002: Label 'BAS Document No.           #1###############\';
        Text1450003: Label 'BAS Version                #2##########\';
        Text1450004: Label 'Posting GST Settlement     #3##########\';
        Text1450005: Label 'GST Settlement has been successfully posted.';
        Text1450006: Label 'Clearing Account and Settlement Account must not be the same.';
        Text1450009: Label 'Clearing Account does not exist for %1 %2.';
        ClearingAccNo: Code[20];
        ClearingAmount: Decimal;
        ClearingVATAmount: Decimal;
        ClearingPostingDate: Date;
        ClearingDescription: Text[100];
        Text1450015: Label '%1 %2';
        TotalClearingAmount: Decimal;
        TotalClearingVATAmount: Decimal;
        LineNo: Integer;
        InterCompany: Boolean;
        JnlBatch: Code[20];
        NoSeriesBatch: Codeunit "No. Series - Batch";
        VATEntry1: Record "VAT Entry";
        VATEntry2: Record "VAT Entry";
        VATApplyEntryNo: Integer;
        Calculate_GST_SettlementCaptionLbl: Label 'Calculate GST Settlement';
        PageCaptionLbl: Label 'Page';
        BAS_Calculation_Sheet__A4CaptionLbl: Label 'Period Covered To';
        BAS_Calculation_Sheet__A3CaptionLbl: Label 'Period Covered From';
        BAS_Calculation_Sheet___BAS_Version_CaptionLbl: Label 'BAS Version';
        BAS_Calculation_Sheet__A1CaptionLbl: Label 'Document No.';
        ClearingAmount_ClearingVATAmountCaptionLbl: Label 'Amount + GST Amount';
        ClearingVATAmountCaptionLbl: Label 'GST Amount';
        ClearingAmountCaptionLbl: Label 'Amount';
        ClearingDescriptionCaptionLbl: Label 'Description';
        ClearingAccNoCaptionLbl: Label 'G/L Account No.';
        ClearingPostingDateCaptionLbl: Label 'Posting Date';
        TotalsCaptionLbl: Label 'Totals';
        GenJnlLine_2___Posting_Date_CaptionLbl: Label 'Posting Date';
        GenJnlLine_2___Account_Type_CaptionLbl: Label 'Account Type';
        GenJnlLine_2___Account_No__CaptionLbl: Label 'Account No.';
        GenJnlLine_2__DescriptionCaptionLbl: Label 'Description';
        GenJnlLine_2__AmountCaptionLbl: Label 'Amount';
        TotalAmtCaptionLbl: Label 'Amount';
        GenJnlLine1_DescriptionCaptionLbl: Label 'Description';
        GenJnlLine1__Account_No__CaptionLbl: Label 'Account No.';
        GenJnlLine1__Account_Type_CaptionLbl: Label 'Account Type';
        GenJnlLine1__Posting_Date_CaptionLbl: Label 'Posting Date';
        ICPartnerCode: Code[20];

    local procedure SetBASDataForGenJnlLine(var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine."BAS Doc. No." := "BAS Calculation Sheet".A1;
        GenJournalLine."BAS Version" := "BAS Calculation Sheet"."BAS Version";
    end;

    [Scope('OnPrem')]
    procedure InitGenJnlLine(var NewGenJnlLine: Record "Gen. Journal Line"; ICPartner: Boolean)
    begin
        if InterCompany then begin
            GenJnlTemplate.SetRange(Type, GenJnlTemplate.Type::Intercompany);
            if GenJnlTemplate.FindFirst() then begin
                NewGenJnlLine.SetRange("Journal Template Name", GenJnlTemplate.Name);
                GenJnlBatch.SetRange("Journal Template Name", GenJnlTemplate.Name);
                if GenJnlBatch.FindFirst() then begin
                    JnlBatch := GenJnlBatch.Name;
                    if not ICPartner then
                        if GenJnlBatch."No. Series" <> '' then
                            DocNo := NoSeriesBatch.GetNextNo(GenJnlBatch."No. Series", PostDate);
                    NewGenJnlLine.SetRange("Journal Batch Name", JnlBatch);
                end;
                NewGenJnlLine."Journal Template Name" := GenJnlTemplate.Name;
                NewGenJnlLine."Journal Batch Name" := JnlBatch;
                if LineNo = 0 then
                    if NewGenJnlLine.Find('+') then
                        LineNo := NewGenJnlLine."Line No."
                    else
                        LineNo := 0;
                NewGenJnlLine."Line No." := LineNo + 10000;
                LineNo := LineNo + 10000;
            end;
        end;
        NewGenJnlLine.Init();
        if ICPartner then
            NewGenJnlLine.Validate("IC Account No.", '');
        NewGenJnlLine.Validate("Posting Date", PostDate);
        NewGenJnlLine.Validate("Document Date", PostDate);
        NewGenJnlLine.Validate("Document No.", DocNo);
        NewGenJnlLine."System-Created Entry" := true;
        NewGenJnlLine."VAT Posting" := NewGenJnlLine."VAT Posting"::"Manual VAT Entry";
    end;

    [Scope('OnPrem')]
    procedure SetFieldID(NewFieldID: Text[30]; NewAmt: Decimal)
    begin
        CurrFieldID := NewFieldID;
        CurrAmt := NewAmt;
    end;

    local procedure InitializeGenJournalLineForInterCompany(var GenJournalLine: Record "Gen. Journal Line"; ICPartnerGLAccount: Code[20])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Intercompany);
        if GenJournalTemplate.FindFirst() then begin
            GenJournalLine."Journal Template Name" := GenJournalTemplate.Name;
            if GenJournalLine."Journal Batch Name" = '' then begin
                GenJournalBatch.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
                GenJournalBatch.FindFirst();
                GenJournalLine."Journal Batch Name" := GenJournalBatch.Name;
            end;
        end;

        if (GenJournalLine."IC Account Type" = "IC Journal Account Type"::"G/L Account") then
            GenJournalLine.Validate("IC Account No.", ICPartnerGLAccount);
        GenJournalLine."IC Partner Code" := ICPartnerCode;
    end;

    local procedure SetSettlementAmount(var GenJournalLine: Record "Gen. Journal Line")
    begin
        if RoundAccNo = '' then
            GenJournalLine.Validate(Amount, TotalAmt)
        else
            GenJournalLine.Validate(Amount, CurrAmt);
    end;
}

