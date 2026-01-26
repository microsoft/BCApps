// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Purchases.Vendor;
using System.Utilities;

report 28041 "Calc. and Post WHT Settlement"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/FinancialMgt/WithholdingTax/CalcandPostWHTSettlement.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Calc. and Post WHT Settlement';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(WHTPostingSetup; "WHT Posting Setup")
        {
            DataItemTableView = sorting("WHT Business Posting Group", "WHT Product Posting Group") where("Revenue Type" = filter(<> ''));
            RequestFilterFields = "WHT Business Posting Group";
            column(USERID; UserId)
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(STRSUBSTNO_Text004_PostSettlement_; StrSubstNo(Text004, PostSettlement))
            {
            }
            column(Add_WHT_Entries__Number; "Add WHT Entries".Number)
            {
            }
            column(WHTPostingSetup_WHT_Business_Posting_Group; "WHT Business Posting Group")
            {
            }
            column(WHTPostingSetup_WHT_Product_Posting_Group; "WHT Product Posting Group")
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Calc__and_Post_WHT_SettlementCaption; Calc__and_Post_WHT_SettlementCaptionLbl)
            {
            }
            column(DisplayEntries_AmountCaption; DisplayEntries.FieldCaption(Amount))
            {
            }
            column(DisplayEntries__Amount__LCY__Caption; DisplayEntries.FieldCaption("Amount (LCY)"))
            {
            }
            column(DisplayEntries_BaseCaption; DisplayEntries.FieldCaption(Base))
            {
            }
            column(DisplayEntries__Currency_Code_Caption; DisplayEntries.FieldCaption("Currency Code"))
            {
            }
            column(DisplayEntries__WHT_Prod__Posting_Group__Control1500027Caption; DisplayEntries.FieldCaption("WHT Prod. Posting Group"))
            {
            }
            column(DisplayEntries__WHT___Caption; DisplayEntries.FieldCaption("WHT %"))
            {
            }
            column(DisplayEntries__WHT_Bus__Posting_Group__Control1500026Caption; DisplayEntries.FieldCaption("WHT Bus. Posting Group"))
            {
            }
            column(DisplayEntries__Posting_Date_Caption; DisplayEntries__Posting_Date_CaptionLbl)
            {
            }
            column(DisplayEntries__Bill_to_Pay_to_No__Caption; DisplayEntries.FieldCaption("Bill-to/Pay-to No."))
            {
            }
            column(DisplayEntries__Document_No__Caption; DisplayEntries.FieldCaption("Document No."))
            {
            }
            column(DisplayEntries__Document_Type_Caption; DisplayEntries.FieldCaption("Document Type"))
            {
            }
            column(DisplayEntries__Entry_No__Caption; DisplayEntries.FieldCaption("Entry No."))
            {
            }
            dataitem("Add WHT Entries"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                dataitem(DisplayEntries; "WHT Entry")
                {
                    column(DisplayEntries__WHT_Bus__Posting_Group_; "WHT Bus. Posting Group")
                    {
                    }
                    column(DisplayEntries__WHT_Prod__Posting_Group_; "WHT Prod. Posting Group")
                    {
                    }
                    column(DisplayEntries__Document_Type_; "Document Type")
                    {
                    }
                    column(DisplayEntries__Entry_No__; "Entry No.")
                    {
                    }
                    column(DisplayEntries__Document_No__; "Document No.")
                    {
                    }
                    column(DisplayEntries__Bill_to_Pay_to_No__; "Bill-to/Pay-to No.")
                    {
                    }
                    column(FORMAT__Posting_Date__; Format("Posting Date"))
                    {
                    }
                    column(DisplayEntries__WHT_Bus__Posting_Group__Control1500026; "WHT Bus. Posting Group")
                    {
                    }
                    column(DisplayEntries__WHT_Prod__Posting_Group__Control1500027; "WHT Prod. Posting Group")
                    {
                    }
                    column(DisplayEntries__WHT___; "WHT %")
                    {
                    }
                    column(DisplayEntries__Amount__LCY__; "Amount (LCY)")
                    {
                    }
                    column(DisplayEntries_Amount; Amount)
                    {
                    }
                    column(DisplayEntries__Currency_Code_; "Currency Code")
                    {
                    }
                    column(DisplayEntries_Base; Base)
                    {
                    }
                    column(PrintWHTEntries; PrintWHTEntries)
                    {
                    }
                    column(DisplayEntries_Base_Control1500033; Base)
                    {
                    }
                    column(DisplayEntries__Amount__LCY___Control1500034; "Amount (LCY)")
                    {
                    }

                    trigger OnPreDataItem()
                    begin
                        Reset();
                        SetCurrentKey("Document Type", "Transaction Type", Settled, "WHT Bus. Posting Group",
                          "WHT Prod. Posting Group", "Posting Date");
                        SetFilter("Posting Date", '%1..%2', StartDate, EndDate);
                        SetRange("Transaction Type", "Transaction Type"::Purchase);
                        SetRange("WHT Bus. Posting Group", WHTPostingSetup."WHT Business Posting Group");
                        SetRange("WHT Prod. Posting Group", WHTPostingSetup."WHT Product Posting Group");
                        SetFilter("Amount (LCY)", '<> 0');

                        if not PostSettlement then
                            SetRange(Settled, false);
                    end;

                    trigger OnAfterGetRecord()
                    var
                        WHTManagement: Codeunit WHTManagement;
                    begin
                        if GLSetup."Round Amount for WHT Calc" then begin
                            "Amount (LCY)" := WHTManagement.RoundWHTAMount("Amount (LCY)");
                            Amount := WHTManagement.RoundWHTAMount(Amount);
                        end;
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    SourceCodeSetup.Get();
                    WHTEntry.Reset();
                    WHTEntry.SetCurrentKey("Document Type", "Transaction Type", Settled, "WHT Bus. Posting Group",
                      "WHT Prod. Posting Group", "Posting Date");
                    WHTEntry.SetFilter("Posting Date", '%1..%2', StartDate, EndDate);
                    WHTEntry.SetRange(Settled, false);
                    WHTEntry.SetRange("Transaction Type", WHTEntry."Transaction Type"::Purchase);
                    WHTEntry.SetRange("WHT Bus. Posting Group", WHTPostingSetup."WHT Business Posting Group");
                    WHTEntry.SetRange("WHT Prod. Posting Group", WHTPostingSetup."WHT Product Posting Group");
                    WHTEntry.CalcSums("Amount (LCY)");
                    WHTAmount := WHTEntry."Amount (LCY)";
                    if (WHTAmount <> 0) and (RoundAccNo <> '') then begin
                        TotalAmount := Round(WHTAmount);
                        RoundAmount := Round(TotalAmount, 1, '<');
                        BalanceAmount := TotalAmount - RoundAmount;

                        Clear(GenJnlLine);
                        GenJnlLine."System-Created Entry" := true;
                        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
                        GenJnlLine.Description :=
                          DelChr(
                            StrSubstNo(
                              Text001,
                              WHTPostingSetup."WHT Business Posting Group",
                              WHTPostingSetup."WHT Product Posting Group"),
                            '>');
                        GenJnlLine."WHT Business Posting Group" := WHTPostingSetup."WHT Business Posting Group";
                        GenJnlLine."WHT Product Posting Group" := WHTPostingSetup."WHT Product Posting Group";
                        GenJnlLine."Posting Date" := PostingDate;
                        GenJnlLine."Document Type" := GenJnlLine."Document Type"::" ";
                        GenJnlLine."Document No." := DocNo;
                        GenJnlLine."Source Code" := SourceCodeSetup."WHT Settlement";
                        WHTPostingSetup.TestField("Payable WHT Account Code");
                        GenJnlLine."Account No." := WHTPostingSetup."Payable WHT Account Code";
                        GenJnlLine.Amount := Round(WHTAmount);
                        if PostSettlement then
                            GenJnlPostLine.Run(GenJnlLine);

                        Clear(GenJnlLine);
                        GenJnlLine.Init();
                        GenJnlLine."System-Created Entry" := true;
                        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
                        GenJnlLine.Description :=
                          DelChr(
                            StrSubstNo(
                              Text001,
                              WHTPostingSetup."WHT Business Posting Group",
                              WHTPostingSetup."WHT Product Posting Group"),
                            '>');
                        GenJnlLine."WHT Business Posting Group" := WHTPostingSetup."WHT Business Posting Group";
                        GenJnlLine."WHT Product Posting Group" := WHTPostingSetup."WHT Product Posting Group";
                        GenJnlLine."Posting Date" := PostingDate;
                        GenJnlLine."Document Type" := GenJnlLine."Document Type"::" ";
                        GenJnlLine."Document No." := DocNo;
                        GenJnlLine."Source Code" := SourceCodeSetup."WHT Settlement";
                        GenJnlLine.Amount := -RoundAmount;
                        case AccType of
                            AccType::Vendor:
                                GenJnlLine."Account Type" := GenJnlLine."Account Type"::Vendor;
                            AccType::"G/L Account":
                                GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
                        end;
                        GenJnlLine."Account No." := GLAccSettle;
                        if PostSettlement then
                            GenJnlPostLine.Run(GenJnlLine);

                        Clear(GenJnlLine);
                        GenJnlLine."System-Created Entry" := true;
                        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
                        GenJnlLine.Description := 'WHT Settlement';
                        GenJnlLine."WHT Business Posting Group" := WHTPostingSetup."WHT Business Posting Group";
                        GenJnlLine."WHT Product Posting Group" := WHTPostingSetup."WHT Product Posting Group";
                        GenJnlLine."Posting Date" := PostingDate;
                        GenJnlLine."Document Type" := GenJnlLine."Document Type"::" ";
                        GenJnlLine."Document No." := DocNo;
                        GenJnlLine."Source Code" := SourceCodeSetup."WHT Settlement";
                        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
                        GenJnlLine."Account No." := RoundAccNo;
                        GenJnlLine.Amount := -BalanceAmount;
                        if PostSettlement then begin
                            GenJnlPostLine.Run(GenJnlLine);
                            WHTEntry.ModifyAll(Settled, true);
                        end;
                    end else
                        if (WHTAmount <> 0) and (RoundAccNo = '') then begin
                            Clear(GenJnlLine);
                            GenJnlLine."System-Created Entry" := true;
                            GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
                            GenJnlLine.Description :=
                              DelChr(
                                StrSubstNo(
                                  Text001,
                                  WHTPostingSetup."WHT Business Posting Group",
                                  WHTPostingSetup."WHT Product Posting Group"),
                                '>');
                            GenJnlLine."WHT Business Posting Group" := WHTPostingSetup."WHT Business Posting Group";
                            GenJnlLine."WHT Product Posting Group" := WHTPostingSetup."WHT Product Posting Group";
                            GenJnlLine."Posting Date" := PostingDate;
                            GenJnlLine."Document Type" := GenJnlLine."Document Type"::" ";
                            GenJnlLine."Document No." := DocNo;
                            GenJnlLine."Source Code" := SourceCodeSetup."WHT Settlement";
                            WHTPostingSetup.TestField("Payable WHT Account Code");
                            GenJnlLine."Account No." := WHTPostingSetup."Payable WHT Account Code";
                            GenJnlLine.Amount := Round(WHTAmount);
                            case AccType of
                                AccType::Vendor:
                                    GenJnlLine."Bal. Account Type" := GenJnlLine."Bal. Account Type"::Vendor;
                                AccType::"G/L Account":
                                    GenJnlLine."Bal. Account Type" := GenJnlLine."Bal. Account Type"::"G/L Account";
                            end;
                            GenJnlLine."Bal. Account No." := GLAccSettle;
                            if PostSettlement then begin
                                GenJnlPostLine.Run(GenJnlLine);
                                WHTEntry.ModifyAll(Settled, true);
                            end;
                        end;
                end;
            }

            trigger OnPreDataItem()
            begin
                LastFieldNo := FieldNo("WHT Business Posting Group");
                WHTEntry.Reset();
                WHTEntry.FindLast();
                EntryNo := WHTEntry."Entry No." + 1;
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
                    field(StartingDate; StartDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the date from which the report or batch job processes information.';
                    }
                    field(EndingDate; EndDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the last date for the report.';
                    }
                    field(PostingDate; PostingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the posting date of the entry.';
                    }
                    field(DocumentNo; DocNo)
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
                    field(SettlementAccountType; AccType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Settlement Account Type';
                        ToolTip = 'Specifies if the account is a general ledger account or a vendor account.';
                    }
                    field(SettlementAccount; GLAccSettle)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Settlement Account';
                        ToolTip = 'Specifies the general ledger account number or vendor number, based on the type selected in the Settlement Account Type field.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            case AccType of
                                AccType::"G/L Account":
                                    if PAGE.RunModal(0, GLAcc, GLAcc."No.") = ACTION::LookupOK then
                                        if GLAcc.Get(GLAcc."No.") then begin
                                            GLAcc.TestField("Account Type", GLAcc."Account Type"::Posting);
                                            GLAcc.TestField(Blocked, false);
                                            GLAccSettle := GLAcc."No.";
                                        end;
                                AccType::Vendor:
                                    if PAGE.RunModal(0, Vendor, Vendor."No.") = ACTION::LookupOK then
                                        if Vendor.Get(Vendor."No.") then begin
                                            if Vendor."Privacy Blocked" then
                                                Error(PrivacyBlockedErr, Vendor."No.");
                                            if Vendor.Blocked in [Vendor.Blocked::All] then
                                                Error(Text006, Vendor."No.");
                                            GLAccSettle := Vendor."No.";
                                        end;
                            end;
                        end;

                        trigger OnValidate()
                        begin
                            if GLAccSettle <> '' then
                                case AccType of
                                    AccType::"G/L Account":
                                        if GLAcc.Get(GLAccSettle) then begin
                                            GLAcc.TestField("Account Type", GLAcc."Account Type"::Posting);
                                            GLAcc.TestField(Blocked, false);
                                        end;
                                    AccType::Vendor:
                                        begin
                                            Vendor.Get(GLAccSettle);
                                            if Vendor."Privacy Blocked" then
                                                Error(PrivacyBlockedErr, Vendor."No.");
                                            if Vendor.Blocked in [Vendor.Blocked::All] then
                                                Error(Text006, Vendor."No.");
                                        end;
                                end;
                        end;
                    }
                    field(RoundAccNo; RoundAccNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Rounding G/L Account';
                        Enabled = RoundAccNoEnable;
                        ToolTip = 'Specifies the general ledger account that you use for rounding amounts.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            if PAGE.RunModal(0, GLAcc, GLAcc."No.") = ACTION::LookupOK then
                                if GLAcc.Get(GLAcc."No.") then begin
                                    GLAcc.TestField("Account Type", GLAcc."Account Type"::Posting);
                                    GLAcc.TestField(Blocked, false);
                                    RoundAccNo := GLAcc."No.";
                                end;
                        end;

                        trigger OnValidate()
                        begin
                            if GLAcc.Get(RoundAccNo) then begin
                                GLAcc.TestField("Account Type", GLAcc."Account Type"::Posting);
                                GLAcc.TestField(Blocked, false);
                            end;
                        end;
                    }
                    field(ShowWHTEntries; PrintWHTEntries)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show WHT Entries';
                        ToolTip = 'Specifies if you want to view the withholding tax entries for the specified period.';
                    }
                    field(Post; PostSettlement)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Post';
                        ToolTip = 'Specifies that you want to post the settlement.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            RoundAccNoEnable := true;
        end;

        trigger OnOpenPage()
        begin
            if DescTxt = '' then
                DescTxt := 'WHT Settlement';
            GLSetup.Get();
            RoundAccNoEnable := GLSetup."Enable GST (Australia)";
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        if PostSettlement then
            Message(Text005);
    end;

    trigger OnPreReport()
    begin
        GLSetup.Get();
        if GLSetup."Enable GST (Australia)" and (RoundAccNo = '') then
            Error(Text007);

        if not GLSetup."Enable GST (Australia)" then
            RoundAccNo := '';
    end;

    var
        LastFieldNo: Integer;
        PrintWHTEntries: Boolean;
        PostSettlement: Boolean;
        EntryNo: Integer;
        WHTAmount: Decimal;
        WHTEntry: Record "WHT Entry";
        GLAccSettle: Code[20];
        GenJnlLine: Record "Gen. Journal Line";
        SourceCodeSetup: Record "Source Code Setup";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        DocNo: Text[30];
        PostingDate: Date;
        StartDate: Date;
        EndDate: Date;
        AccType: Option "G/L Account",Vendor;
        GLAcc: Record "G/L Account";
        Vendor: Record Vendor;
        TotalAmount: Decimal;
        RoundAmount: Decimal;
        BalanceAmount: Decimal;
        DescTxt: Text[30];
        RoundAccNo: Code[20];
        GLSetup: Record "General Ledger Setup";
        Text001: Label 'Payable WHT settlement: #1######## #2########';
        Text004: Label 'Post Settlement - %1';
        Text005: Label 'Settlement posted.';
        Text006: Label 'Blocked must be No in vendor %1';
        PrivacyBlockedErr: Label 'Privacy Blocked must be No in vendor %1.', Comment = '%1 = vendor number';
        Text007: Label 'Please enter the Rounding Account';
        RoundAccNoEnable: Boolean;
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Calc__and_Post_WHT_SettlementCaptionLbl: Label 'Calc. and Post WHT Settlement';
        DisplayEntries__Posting_Date_CaptionLbl: Label 'Posting Date';
}

