#pragma warning disable AA0247
report 12437 "G/L Account Card"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/GLAccountCard.rdlc';
    Caption = 'G/L Account Card';
    EnableHyperlinks = true;

    dataset
    {
        dataitem(GLAcc; "G/L Account")
        {
            DataItemTableView = where("Account Type" = const(Posting));
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Global Dimension 1 Filter", "Global Dimension 2 Filter", "Business Unit Filter", "Date Filter";
            column(USERID; UserId)
            {
            }
            column(CurrentFilter; CurrentFilter)
            {
            }
            column(HeaderPeriodTitle; StrSubstNo(Text005, LocMgt.Date2Text(StartDate), LocMgt.Date2Text(EndDate)))
            {
            }
            column(CurrentDate; CurrentDate)
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(COMPANYNAME_Control1210020; COMPANYPROPERTY.DisplayName())
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(GL_Account_CardCaption; GL_Account_CardCaptionLbl)
            {
            }
            column(GLAcc_No_; "No.")
            {
            }
            column(GLAcc_Global_Dimension_1_Filter; "Global Dimension 1 Filter")
            {
            }
            column(GLAcc_Global_Dimension_2_Filter; "Global Dimension 2 Filter")
            {
            }
            column(GLAcc_Date_Filter; "Date Filter")
            {
            }
            dataitem(Balance; "Integer")
            {
                DataItemTableView = sorting(Number);
                MaxIteration = 1;
                column(GLAcc__No__; GLAcc."No.")
                {
                }
                column(GLAcc_Name; GLAcc.Name)
                {
                }
                column(GLAccURL; Format(GLAccURL.RecordId, 0, 10))
                {
                }
                column(BalanceBegining; BalanceBegining)
                {
                }
                column(SignBalanceBegining; SignBalanceBegining)
                {
                }
                column(Text004_____LocMgt_Date2Text_StartDate_; Text004 + ' ' + LocMgt.Date2Text(StartDate))
                {
                }
                column(BalanceBegining_Control1210026; BalanceBegining)
                {
                }
                column(SignBalanceBegining_Control1210027; SignBalanceBegining)
                {
                }
                column(Text004_____LocMgt_Date2Text_StartDate__Control1210028; Text004 + ' ' + LocMgt.Date2Text(StartDate))
                {
                }
                column(CreditAmount; CreditAmount)
                {
                }
                column(DebetAmount; DebetAmount)
                {
                }
                column(GLAcc_Name_Control1210073; GLAcc.Name)
                {
                }
                column(BalanceEnding; BalanceEnding)
                {
                }
                column(SignBalanceEnding; SignBalanceEnding)
                {
                }
                column(Text004_____LocMgt_Date2Text_EndDate_; Text004 + ' ' + LocMgt.Date2Text(EndDate))
                {
                }
                column(BalanceEnding_Control1210079; BalanceEnding)
                {
                }
                column(SignBalanceEnding_Control1210080; SignBalanceEnding)
                {
                }
                column(Text004_____LocMgt_Date2Text_EndDate__Control1210081; Text004 + ' ' + LocMgt.Date2Text(EndDate))
                {
                }
                column(Balance_Number; Number)
                {
                }
                column(TotalDebetAmount; TotalDebetAmount)
                {
                }
                column(TotalCreditAmount; TotalCreditAmount)
                {
                }
                dataitem(GLEntry; "G/L Entry")
                {
                    DataItemLink = "G/L Account No." = field("No."), "Global Dimension 1 Code" = field("Global Dimension 1 Filter"), "Global Dimension 2 Code" = field("Global Dimension 2 Filter"), "Posting Date" = field("Date Filter"), "Source Type" = field("Source Type Filter"), "Source No." = field("Source No. Filter");
                    DataItemLinkReference = GLAcc;
                    DataItemTableView = sorting("Transaction No.");
                    column(GLEntry_Description; Description)
                    {
                    }
                    column(DebetAmount_Control1210047; DebetAmount)
                    {
                    }
                    column(CreditAmount_Control1210050; CreditAmount)
                    {
                    }
                    column(GLEntry__Document_No__; "Document No.")
                    {
                    }
                    column(GLEntry__Posting_Date_; "Posting Date")
                    {
                    }
                    column(DescriptionCaption; DescriptionCaptionLbl)
                    {
                    }
                    column(DebitCaption; DebitCaptionLbl)
                    {
                    }
                    column(CreditCaption; CreditCaptionLbl)
                    {
                    }
                    column(References_between_accountsCaption; References_between_accountsCaptionLbl)
                    {
                    }
                    column(Document_No_Caption; Document_No_CaptionLbl)
                    {
                    }
                    column(Posting_DateCaption; Posting_DateCaptionLbl)
                    {
                    }
                    column(Net_ChangeCaption; Net_ChangeCaptionLbl)
                    {
                    }
                    column(GLEntry_Entry_No_; "Entry No.")
                    {
                    }
                    column(GLEntry_G_L_Account_No_; "G/L Account No.")
                    {
                    }
                    column(GLEntry_Global_Dimension_1_Code; "Global Dimension 1 Code")
                    {
                    }
                    column(GLEntry_Global_Dimension_2_Code; "Global Dimension 2 Code")
                    {
                    }
                    column(GLEntry_Transaction_No_; "Transaction No.")
                    {
                    }
                    dataitem(GLCorrEntry; "G/L Correspondence Entry")
                    {
                        DataItemLink = "Document No." = field("Document No."), "Transaction No." = field("Transaction No.");
                        DataItemTableView = sorting("Transaction No.", "Debit Account No.", "Credit Account No.");
                        column(CorrAccount; CorrAccount)
                        {
                        }
                        column(CorrAmount; CorrAmount)
                        {
                        }
                        column(ShowCorr; ShowCorr)
                        {
                        }
                        column(PageNo; PageNo)
                        {
                        }
                        column(GLCorrEntry_Entry_No_; "Entry No.")
                        {
                        }
                        column(GLCorrEntry_Document_No_; "Document No.")
                        {
                        }
                        column(GLCorrEntry_Transaction_No_; "Transaction No.")
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if (GLCorrEntry."Debit Account No." <> GLEntry."G/L Account No.") and
                               (GLCorrEntry."Credit Account No." <> GLEntry."G/L Account No.") or not ShowCorr then
                                CurrReport.Skip();

                            if GLCorrEntry."Debit Account No." = GLEntry."G/L Account No." then begin
                                CorrAccount := GLCorrEntry."Credit Account No.";
                                CorrAmount := -GLCorrEntry.Amount
                            end else begin
                                CorrAccount := GLCorrEntry."Debit Account No.";
                                CorrAmount := GLCorrEntry.Amount;
                            end;
                        end;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        DebetAmount := 0;
                        CreditAmount := 0;

                        if (GLEntry."Document No." = CurrDocNo) and
                           (GLEntry."Transaction No." = CurrTransNo) then
                            CurrReport.Skip();

                        GLEntry1.Reset();
                        GLEntry1.SetRange("Transaction No.", "Transaction No.");
                        GLEntry1.SetRange("Document No.", "Document No.");
                        GLEntry1.SetRange("G/L Account No.", "G/L Account No.");
                        if GLEntry1.Find('-') then
                            repeat
                                DebetAmount := DebetAmount + GLEntry1."Debit Amount";
                                CreditAmount := CreditAmount + GLEntry1."Credit Amount";
                            until GLEntry1.Next() = 0;

                        if ("Posting Date" = ClosingDate("Posting Date")) and
                           not PrintClosingEntries
                        then begin
                            DebetAmount := 0;
                            CreditAmount := 0;
                            CurrReport.Skip();
                        end;

                        CurrDocNo := GLEntry."Document No.";
                        CurrTransNo := GLEntry."Transaction No.";
                    end;

                    trigger OnPreDataItem()
                    begin
                        Clear(DebetAmount);
                        Clear(CreditAmount);
                    end;
                }
            }

            trigger OnAfterGetRecord()
            begin
                GLAccURL.SetPosition(GetPosition());

                Clear(LineAmount);
                if PrintClosingEntries then
                    SetRange("Date Filter", StartDate, ClosingDate(EndDate))
                else
                    SetRange("Date Filter", StartDate, EndDate);
                CalcFields("Debit Amount", "Credit Amount");
                LineAmount[3] := "Debit Amount";
                LineAmount[4] := "Credit Amount";
                if (LineAmount[3] = 0) and (LineAmount[4] = 0) then
                    CurrReport.Skip();

                TotalDebetAmount := LineAmount[3];
                TotalCreditAmount := LineAmount[4];

                SignBalanceBegining := '';
                SignBalanceEnding := '';

                BalanceBegining := 0;
                if PrintClosingEntries then
                    SetRange("Date Filter", 0D, ClosingDate(CalcDate('<-1D>', StartDate)))
                else
                    SetRange("Date Filter", 0D, CalcDate('<-1D>', StartDate));
                CalcFields("Debit Amount", "Credit Amount");
                LineAmount[1] := "Debit Amount";
                LineAmount[2] := "Credit Amount";
                if (LineAmount[1] - LineAmount[2]) > 0 then begin
                    SignBalanceBegining := Text002;
                    BalanceBegining := LineAmount[1] - LineAmount[2];
                end;
                if (LineAmount[1] - LineAmount[2]) < 0 then begin
                    SignBalanceBegining := Text003;
                    BalanceBegining := LineAmount[2] - LineAmount[1];
                end;

                BalanceEnding := 0;
                LineAmount[5] := LineAmount[1] + LineAmount[3];
                LineAmount[6] := LineAmount[2] + LineAmount[4];
                if (LineAmount[5] - LineAmount[6]) > 0 then begin
                    SignBalanceEnding := Text002;
                    BalanceEnding := LineAmount[5] - LineAmount[6];
                end;
                if (LineAmount[5] - LineAmount[6]) < 0 then begin
                    SignBalanceEnding := Text003;
                    BalanceEnding := LineAmount[6] - LineAmount[5];
                end;

                if PrintClosingEntries then
                    SetRange("Date Filter", StartDate, ClosingDate(EndDate))
                else
                    SetRange("Date Filter", StartDate, EndDate);

                if NewPageForGLAcc then
                    PageNo += 1;
            end;

            trigger OnPreDataItem()
            begin
                PageNo := 0;
                FilterGroup(2);
                SetFilter("Account Type", '%1', "Account Type"::Posting);
                FilterGroup(0);

                GLAccURL.Open(DATABASE::"G/L Account")
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
                    field(ShowCorr; ShowCorr)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Correspondence';
                        MultiLine = true;
                    }
                    field(NewPageForGLAcc; NewPageForGLAcc)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Page for GL Acc';
                        ToolTip = 'Specifies if you want to print a new page for each general ledger account.';
                    }
                    field(PrintClosingEntries; PrintClosingEntries)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Including Closing Period Entries';
                        MultiLine = true;
                        ToolTip = 'Specifies if you want to include the closing period entries on the report.';
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
        CurrentFilter := GLAcc.GetFilters();
        CurrentDate := LocMgt.Date2Text(Today()) + Format(Time(), 0, '(<Hours24>:<Minutes>)');
        if GLAcc.GetRangeMin("Date Filter") > 0D then
            StartDate := GLAcc.GetRangeMin("Date Filter");
        EndDate := GLAcc.GetRangeMax("Date Filter");
    end;

    var
#pragma warning disable AA0074
        Text002: Label 'Debit';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text003: Label 'Credit';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text004: Label 'Balance at';
#pragma warning restore AA0074
        GLEntry1: Record "G/L Entry";
        LocMgt: Codeunit "Localisation Management";
        CurrentDate: Text[30];
        CurrentFilter: Text;
        SignBalanceBegining: Text[10];
        SignBalanceEnding: Text[10];
        BalanceBegining: Decimal;
        BalanceEnding: Decimal;
        StartDate: Date;
        EndDate: Date;
        NewPageForGLAcc: Boolean;
        PrintClosingEntries: Boolean;
        CorrAccount: Code[20];
        CorrAmount: Decimal;
        ShowCorr: Boolean;
        DebetAmount: Decimal;
        CreditAmount: Decimal;
        CurrDocNo: Code[20];
        CurrTransNo: Integer;
        LineAmount: array[10] of Decimal;
        PageNo: Integer;
        GLAccURL: RecordRef;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text005: Label 'For Period from %1 to %2';
#pragma warning restore AA0470
#pragma warning restore AA0074
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        GL_Account_CardCaptionLbl: Label 'GL Account Card';
        DescriptionCaptionLbl: Label 'Description';
        DebitCaptionLbl: Label 'Debit';
        CreditCaptionLbl: Label 'Credit';
        References_between_accountsCaptionLbl: Label 'References between accounts';
        Document_No_CaptionLbl: Label 'Document No.';
        Posting_DateCaptionLbl: Label 'Posting Date';
        Net_ChangeCaptionLbl: Label 'Net Change';
        TotalDebetAmount: Decimal;
        TotalCreditAmount: Decimal;
}

