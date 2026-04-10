#pragma warning disable AA0247
report 12435 "G/L Corresp Entries Analysis"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/GLCorrespEntriesAnalysis.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'G/L Corresp Entries Analysis';
    EnableHyperlinks = true;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(GLAccForReport; "G/L Account")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.";
            RequestFilterHeading = 'GL Accounts of Reports';
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(CurrentDate; CurrentDate)
            {
            }
            column(USERID; UserId)
            {
            }
            column(Double_Entries_AnalysisCaption; Double_Entries_AnalysisCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(GLAccForReport_No_; "No.")
            {
            }
            column(GLAccForReport_Global_Dimension_1_Filter; "Global Dimension 1 Filter")
            {
            }
            column(GLAccForReport_Global_Dimension_2_Filter; "Global Dimension 2 Filter")
            {
            }
            column(GLAccForReport_Business_Unit_Filter; "Business Unit Filter")
            {
            }
            dataitem("Balance Beg/Ending"; "Integer")
            {
                DataItemTableView = sorting(Number);
                MaxIteration = 1;
                column(BalanceBegining; BalanceBegining)
                {
                }
                column(SignBalanceBegining; SignBalanceBegining)
                {
                }
                column(AccountNoHeaderCaption; Text001 + GLAccForReport."No." + '   ' + GLAccForReport.Name)
                {
                }
                column(ApplicationLocalization_Date2Text_DateStartedOfPeriod_; ApplicationLocalization.Date2Text(DateStartedOfPeriod))
                {
                }
                column(PageCounter; PageCounter)
                {
                }
                column(NewPageForGlAcc; NewPageForGLAcc)
                {
                }
                column(DifferenceExist; DifferenceExist)
                {
                }
                column(GLAccURL; Format(GLAccURL.RecordId, 0, 10))
                {
                }
                column(BalanceEnding; BalanceEnding)
                {
                }
                column(SignBalanceEnding; SignBalanceEnding)
                {
                }
                column(ApplicationLocalization_Date2Text_EndingPeriodDate_; ApplicationLocalization.Date2Text(EndingPeriodDate))
                {
                }
                column(Beginning_period_balanceCaption; Beginning_period_balanceCaptionLbl)
                {
                }
                column(Ending_period_balanceCaption; Ending_period_balanceCaptionLbl)
                {
                }
                column(Balance_Beg_Ending_Number; Number)
                {
                }
                dataitem(ByGLAccounts; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    column(Text005_____GLAccForReport__No__; Text005 + ' ' + GLAccForReport."No.")
                    {
                    }
                    column(GLAcc1__No__; GLAcc1."No.")
                    {
                    }
                    column(GLAcc1_Name; GLAcc1.Name)
                    {
                    }
                    column(DebitAmountText; DebitAmountText)
                    {
                    }
                    column(CreditAmountText; CreditAmountText)
                    {
                    }
                    column(NetChangeDebit; NetChangeDebit)
                    {
                    }
                    column(NetChangeCredit; NetChangeCredit)
                    {
                    }
                    column(GLAccForReport_Name_; GLAccForReport.Name)
                    {
                    }
                    column(NetChangeDebitGLAcc; NetChangeDebitGLAcc)
                    {
                    }
                    column(NetChangeCreditGLAcc; NetChangeCreditGLAcc)
                    {
                    }
                    column(NetChangeDebit_Control4011; NetChangeDebit)
                    {
                    }
                    column(NetChangeCredit_Control4111; NetChangeCredit)
                    {
                    }
                    column(GLAccForReport_Name__Control68; GLAccForReport.Name)
                    {
                    }
                    column(No_Caption; No_CaptionLbl)
                    {
                    }
                    column(Name_AccountCaption; Name_AccountCaptionLbl)
                    {
                    }
                    column(DebitCaption; DebitCaptionLbl)
                    {
                    }
                    column(CreditCaption; CreditCaptionLbl)
                    {
                    }
                    column(EntriesCaption; EntriesCaptionLbl)
                    {
                    }
                    column(Net_Change_for_GL_AccCaption; Net_Change_for_GL_AccCaptionLbl)
                    {
                    }
                    column(ByGLAccounts_Number; Number)
                    {
                    }
                    dataitem(CorrespByGLAccDebit; "G/L Correspondence Entry")
                    {
                        DataItemLink = "Debit Global Dimension 1 Code" = field("Global Dimension 1 Filter"), "Debit Global Dimension 2 Code" = field("Global Dimension 2 Filter"), "Business Unit Code" = field("Business Unit Filter");
                        DataItemLinkReference = GLAccForReport;
                        DataItemTableView = sorting("Debit Account No.", "Credit Account No.", "Debit Global Dimension 1 Code", "Debit Global Dimension 2 Code", "Business Unit Code", "Posting Date");
                        column(CorrespByGLAccDebit__Posting_Date_; "Posting Date")
                        {
                        }
                        column(Description_; GLEntry.Description)
                        {
                        }
                        column(CorrespByGLAccDebit_Amount; Amount)
                        {
                        }
                        column(CorrespByGLAccDebit__Document_No__; "Document No.")
                        {
                        }
                        column(CorrespByGLAccDebit_Entry_No_; "Entry No.")
                        {
                        }
                        column(CorrespByGLAccDebit_Debit_Global_Dimension_1_Code; "Debit Global Dimension 1 Code")
                        {
                        }
                        column(CorrespByGLAccDebit_Debit_Global_Dimension_2_Code; "Debit Global Dimension 2 Code")
                        {
                        }
                        column(CorrespByGLAccDebit_Business_Unit_Code; "Business Unit Code")
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            GLEntry.Get("Entry No.");
                            NumberOfLinesEntries := NumberOfLinesEntries + 1;
                        end;

                        trigger OnPreDataItem()
                        begin
                            SetRange("Debit Account No.", GLAccForReport."No.");
                            SetRange("Credit Account No.", GLAcc1."No.");
                            SetRange("Posting Date", DateStartedOfPeriod, EndingPeriodDate);
                            GLAccForReport.CopyFilter("Global Dimension 1 Filter", "Debit Global Dimension 1 Code");
                            GLAccForReport.CopyFilter("Global Dimension 2 Filter", "Debit Global Dimension 2 Code");
                            GLAccForReport.CopyFilter("Business Unit Filter", "Business Unit Code");
                        end;
                    }
                    dataitem(CorrespByGLAccCredit; "G/L Correspondence Entry")
                    {
                        DataItemLink = "Debit Global Dimension 1 Code" = field("Global Dimension 1 Filter"), "Debit Global Dimension 2 Code" = field("Global Dimension 2 Filter"), "Business Unit Code" = field("Business Unit Filter");
                        DataItemLinkReference = GLAccForReport;
                        DataItemTableView = sorting("Debit Account No.", "Credit Account No.", "Debit Global Dimension 1 Code", "Debit Global Dimension 2 Code", "Business Unit Code", "Posting Date");
                        column(CorrespByGLAccCredit__Posting_Date_; "Posting Date")
                        {
                        }
                        column(Description__Control4093; GLEntry.Description)
                        {
                        }
                        column(CorrespByGLAccCredit_Amount; Amount)
                        {
                        }
                        column(CorrespByGLAccCredit__Document_No__; "Document No.")
                        {
                        }
                        column(CorrespByGLAccCredit_Entry_No_; "Entry No.")
                        {
                        }
                        column(CorrespByGLAccCredit_Debit_Global_Dimension_1_Code; "Debit Global Dimension 1 Code")
                        {
                        }
                        column(CorrespByGLAccCredit_Debit_Global_Dimension_2_Code; "Debit Global Dimension 2 Code")
                        {
                        }
                        column(CorrespByGLAccCredit_Business_Unit_Code; "Business Unit Code")
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            GLEntry.Get("Entry No.");
                            NumberOfLinesEntries := NumberOfLinesEntries + 1;
                        end;

                        trigger OnPreDataItem()
                        begin
                            SetRange("Credit Account No.", GLAccForReport."No.");
                            SetRange("Debit Account No.", GLAcc1."No.");
                            SetRange("Posting Date", DateStartedOfPeriod, EndingPeriodDate);
                            GLAccForReport.CopyFilter("Global Dimension 1 Filter", "Credit Global Dimension 1 Code");
                            GLAccForReport.CopyFilter("Global Dimension 2 Filter", "Credit Global Dimension 2 Code");
                            GLAccForReport.CopyFilter("Business Unit Filter", "Business Unit Code");
                        end;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if Number = 1 then
                            GLCorrespondenceBuffer.Find('-')
                        else
                            GLCorrespondenceBuffer.Next();
                        if GLCorrespondenceBuffer."Use Duplication List" then
                            CurrReport.Skip();
                        GLAcc1.Get(GLCorrespondenceBuffer."G/L Account");

                        DebitAmountText := '';
                        CreditAmountText := '';
                        if GLCorrespondenceBuffer.Type = GLCorrespondenceBuffer.Type::Debit then begin
                            NetChangeDebit := NetChangeDebit + GLCorrespondenceBuffer.Amount;
                            DebitAmountText := Format(GLCorrespondenceBuffer.Amount, 0, '<Sign><Integer Thousand><Decimals,3>');
                            GLCorrespondenceBuffer2.Copy(GLCorrespondenceBuffer);
                            GLCorrespondenceBuffer2.Type := GLCorrespondenceBuffer2.Type::Credit;
                            if GLCorrespondenceBuffer2.Find() then begin
                                NetChangeCredit := NetChangeCredit + GLCorrespondenceBuffer2.Amount;
                                CreditAmountText := Format(GLCorrespondenceBuffer2.Amount, 0, '<Sign><Integer Thousand><Decimals,3>');
                                GLCorrespondenceBuffer2."Use Duplication List" := true;
                                GLCorrespondenceBuffer2.Modify();
                            end;
                        end else
                            if GLCorrespondenceBuffer.Type = GLCorrespondenceBuffer.Type::Credit then begin
                                NetChangeCredit := NetChangeCredit + GLCorrespondenceBuffer.Amount;
                                CreditAmountText := Format(GLCorrespondenceBuffer.Amount, 0, '<Sign><Integer Thousand><Decimals,3>');
                                GLCorrespondenceBuffer2.Copy(GLCorrespondenceBuffer);
                                GLCorrespondenceBuffer2.Type := GLCorrespondenceBuffer.Type::Debit;
                                if GLCorrespondenceBuffer2.Find() then begin
                                    NetChangeDebit := NetChangeDebit + GLCorrespondenceBuffer2.Amount;
                                    DebitAmountText := Format(GLCorrespondenceBuffer2.Amount, 0, '<Sign><Integer Thousand><Decimals,3>');
                                    GLCorrespondenceBuffer2."Use Duplication List" := true;
                                    GLCorrespondenceBuffer2.Modify();
                                end;
                            end;

                        DifferenceExist := not ((NetChangeDebitGLAcc = NetChangeDebit)
                          and (NetChangeCreditGLAcc = NetChangeCredit));
                    end;

                    trigger OnPreDataItem()
                    begin
                        if DebitCreditSeparately
                          or (NumberOfLinesByDebit = 0)
                          or (NumberOfLinesByCredit = 0)
                        then
                            CurrReport.Break();
                        SetRange(Number, 1, NumberOfLinesByDebit + NumberOfLinesByCredit);
                        NetChangeDebit := 0;
                        NetChangeCredit := 0;
                    end;
                }
                dataitem(ByDebit; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    MaxIteration = 0;
                    column(Text002_GLAccForReport__No__; Text002 + GLAccForReport."No.")
                    {
                    }
                    column(GLAcc1__No___Control2910; GLAcc1."No.")
                    {
                    }
                    column(GLAcc1_Name_Control3010; GLAcc1.Name)
                    {
                    }
                    column(DebitAmountText_Control3110; DebitAmountText)
                    {
                    }
                    column(NetChangeDebit_Control4010; NetChangeDebit)
                    {
                    }
                    column(GLAccForReport_Name__Control73; GLAccForReport.Name)
                    {
                    }
                    column(NetChangeDebit_Control4012; NetChangeDebit)
                    {
                    }
                    column(GLAccForReport_Name__Control74; GLAccForReport.Name)
                    {
                    }
                    column(NetChangeDebitGLAcc_Control78; NetChangeDebitGLAcc)
                    {
                    }
                    column(No_Caption_Control3; No_Caption_Control3Lbl)
                    {
                    }
                    column(NameCaption; NameCaptionLbl)
                    {
                    }
                    column(EntriesCaption_Control52; EntriesCaption_Control52Lbl)
                    {
                    }
                    column(Net_Change_for_GL_AccCaption_Control35; Net_Change_for_GL_AccCaption_Control35Lbl)
                    {
                    }
                    column(ByDebit_Number; Number)
                    {
                    }
                    dataitem(CorrespByDebit; "G/L Correspondence Entry")
                    {
                        DataItemLink = "Debit Global Dimension 1 Code" = field("Global Dimension 1 Filter"), "Debit Global Dimension 2 Code" = field("Global Dimension 2 Filter"), "Business Unit Code" = field("Business Unit Filter");
                        DataItemLinkReference = GLAccForReport;
                        DataItemTableView = sorting("Debit Account No.", "Credit Account No.", "Debit Global Dimension 1 Code", "Debit Global Dimension 2 Code", "Business Unit Code", "Posting Date");
                        column(CorrespByDebit__Posting_Date_; "Posting Date")
                        {
                        }
                        column(Description__Control40; GLEntry.Description)
                        {
                        }
                        column(CorrespByDebit_Amount; Amount)
                        {
                        }
                        column(CorrespByDebit__Document_No__; "Document No.")
                        {
                        }
                        column(CorrespByDebit_Entry_No_; "Entry No.")
                        {
                        }
                        column(CorrespByDebit_Debit_Global_Dimension_1_Code; "Debit Global Dimension 1 Code")
                        {
                        }
                        column(CorrespByDebit_Debit_Global_Dimension_2_Code; "Debit Global Dimension 2 Code")
                        {
                        }
                        column(CorrespByDebit_Business_Unit_Code; "Business Unit Code")
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            GLEntry.Get("Entry No.");
                            NumberOfLinesEntries := NumberOfLinesEntries + 1;
                        end;

                        trigger OnPreDataItem()
                        begin
                            SetRange("Debit Account No.", GLAccForReport."No.");
                            SetRange("Credit Account No.", GLAcc1."No.");
                            SetRange("Posting Date", DateStartedOfPeriod, EndingPeriodDate);
                            GLAccForReport.CopyFilter("Global Dimension 1 Filter", "Debit Global Dimension 1 Code");
                            GLAccForReport.CopyFilter("Global Dimension 2 Filter", "Debit Global Dimension 2 Code");
                            GLAccForReport.CopyFilter("Business Unit Filter", "Business Unit Code");
                        end;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if Number = 1 then
                            GLCorrespondenceBuffer.Find('-')
                        else
                            GLCorrespondenceBuffer.Next();
                        GLAcc1.Get(GLCorrespondenceBuffer."G/L Account");
                        NetChangeDebit := NetChangeDebit + GLCorrespondenceBuffer.Amount;
                        DebitAmountText := Format(GLCorrespondenceBuffer.Amount, 0, '<Sign><Integer Thousand><Decimals,3>');
                        NumberOfLinesEntries := 0;

                        DifferenceExist := not (NetChangeDebitGLAcc = NetChangeDebit);
                    end;

                    trigger OnPreDataItem()
                    begin
                        if (NumberOfLinesByDebit = 0)
                          or (not DebitCreditSeparately and not (NumberOfLinesByCredit = 0))
                        then
                            CurrReport.Break();
                        SetRange(Number, 1, NumberOfLinesByDebit);
                        GLCorrespondenceBuffer.SetRange(Type, 0);

                        DifferenceExist := false;

                        NetChangeDebit := 0;
                        NetChangeCredit := 0;
                    end;
                }
                dataitem(ByCredit; "Integer")
                {
                    DataItemTableView = sorting(Number);
                    MaxIteration = 0;
                    column(Text003_GLAccForReport__No__; Text003 + GLAccForReport."No.")
                    {
                    }
                    column(GLAcc1_Name_Control3020; GLAcc1.Name)
                    {
                    }
                    column(GLAcc1__No___Control2920; GLAcc1."No.")
                    {
                    }
                    column(CreditAmountText_Control3220; CreditAmountText)
                    {
                    }
                    column(NetChangeCredit_Control4120; NetChangeCredit)
                    {
                    }
                    column(GLAccForReport_Name__Control75; GLAccForReport.Name)
                    {
                    }
                    column(NetChangeCreditGLAcc_Control38; NetChangeCreditGLAcc)
                    {
                    }
                    column(NetChangeCredit_Control4123; NetChangeCredit)
                    {
                    }
                    column(GLAccForReport_Name__Control76; GLAccForReport.Name)
                    {
                    }
                    column(No_Caption_Control18; No_Caption_Control18Lbl)
                    {
                    }
                    column(EntriesCaption_Control19; EntriesCaption_Control19Lbl)
                    {
                    }
                    column(NameCaption_Control4; NameCaption_Control4Lbl)
                    {
                    }
                    column(Net_Change_for_GL_AccCaption_Control37; Net_Change_for_GL_AccCaption_Control37Lbl)
                    {
                    }
                    column(ByCredit_Number; Number)
                    {
                    }
                    dataitem(CorrespByCredit; "G/L Correspondence Entry")
                    {
                        DataItemLink = "Debit Global Dimension 1 Code" = field("Global Dimension 1 Filter"), "Debit Global Dimension 2 Code" = field("Global Dimension 2 Filter"), "Business Unit Code" = field("Business Unit Filter");
                        DataItemLinkReference = GLAccForReport;
                        DataItemTableView = sorting("Debit Account No.", "Credit Account No.", "Debit Global Dimension 1 Code", "Debit Global Dimension 2 Code", "Business Unit Code", "Posting Date");
                        column(CorrespByCredit__Posting_Date_; "Posting Date")
                        {
                        }
                        column(Description__Control4091; GLEntry.Description)
                        {
                        }
                        column(CorrespByCredit__Document_No__; "Document No.")
                        {
                        }
                        column(CorrespByCredit_Amount; Amount)
                        {
                        }
                        column(CorrespByCredit_Entry_No_; "Entry No.")
                        {
                        }
                        column(CorrespByCredit_Debit_Global_Dimension_1_Code; "Debit Global Dimension 1 Code")
                        {
                        }
                        column(CorrespByCredit_Debit_Global_Dimension_2_Code; "Debit Global Dimension 2 Code")
                        {
                        }
                        column(CorrespByCredit_Business_Unit_Code; "Business Unit Code")
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            GLEntry.Get("Entry No.");
                            NumberOfLinesEntries := NumberOfLinesEntries + 1;
                        end;

                        trigger OnPreDataItem()
                        begin
                            SetRange("Credit Account No.", GLAccForReport."No.");
                            SetRange("Debit Account No.", GLAcc1."No.");
                            SetRange("Posting Date", DateStartedOfPeriod, EndingPeriodDate);
                            GLAccForReport.CopyFilter("Global Dimension 1 Filter", "Credit Global Dimension 1 Code");
                            GLAccForReport.CopyFilter("Global Dimension 2 Filter", "Credit Global Dimension 2 Code");
                            GLAccForReport.CopyFilter("Business Unit Filter", "Business Unit Code");
                        end;
                    }

                    trigger OnAfterGetRecord()
                    begin
                        if Number = 1 then
                            GLCorrespondenceBuffer.Find('-')
                        else
                            GLCorrespondenceBuffer.Next();
                        GLAcc1.Get(GLCorrespondenceBuffer."G/L Account");
                        NetChangeCredit := NetChangeCredit + GLCorrespondenceBuffer.Amount;
                        CreditAmountText := Format(GLCorrespondenceBuffer.Amount, 0, '<Sign><Integer Thousand><Decimals,3>');
                        NumberOfLinesEntries := 0;

                        DifferenceExist := not (NetChangeCreditGLAcc = NetChangeCredit);
                    end;

                    trigger OnPreDataItem()
                    begin
                        if (NumberOfLinesByCredit = 0)
                          or (not DebitCreditSeparately and not (NumberOfLinesByDebit = 0))
                        then
                            CurrReport.Break();
                        SetRange(Number, 1, NumberOfLinesByCredit);
                        GLCorrespondenceBuffer.SetRange(Type, 1);

                        DifferenceExist := false;

                        NetChangeDebit := 0;
                        NetChangeCredit := 0;
                    end;
                }

                trigger OnPreDataItem()
                begin
                    if NewPageForGLAcc then
                        PageCounter += 1;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                GLAccURL.SetPosition(GetPosition());

                SetRange("Date Filter", 0D, ClosingDate(CalcDate('<-1D>', DateStartedOfPeriod)));
                CalcFields("Balance at Date");
                if "Balance at Date" > 0 then
                    SignBalanceBegining := Text002
                else
                    if "Balance at Date" < 0 then
                        SignBalanceBegining := Text003
                    else
                        SignBalanceBegining := '';
                BalanceBegining := Abs("Balance at Date");
                SetRange("Date Filter", 0D, ClosingDate(EndingPeriodDate));
                CalcFields("Net Change");
                if "Net Change" > 0 then
                    SignBalanceEnding := Text002
                else
                    if "Net Change" < 0 then
                        SignBalanceEnding := Text003
                    else
                        SignBalanceEnding := '';
                BalanceEnding := Abs("Net Change");
                SetRange("Date Filter", DateStartedOfPeriod, ClosingDate(EndingPeriodDate));
                CalcFields("Debit Amount", "Credit Amount");
                NetChangeDebitGLAcc := "Debit Amount";
                NetChangeCreditGLAcc := "Credit Amount";
                if WithoutZeroNetChanges
                  and (NetChangeDebitGLAcc = 0) and (NetChangeCreditGLAcc = 0)
                then
                    CurrReport.Skip();
                if ExcludingZeroLine
                  and (BalanceBegining = 0) and (BalanceEnding = 0)
                  and (NetChangeDebitGLAcc = 0) and (NetChangeCreditGLAcc = 0)
                then
                    CurrReport.Skip();
                InternalReportManagement.CreateGLCorrespondenceMatrix(
                    GLCorrespondenceBuffer2, GLAccForReport, NumberOfLinesByDebit, NumberOfLinesByCredit,
                    DateStartedOfPeriod, EndingPeriodDate, WithoutZeroNetChanges);
                if (NumberOfLinesByDebit = 0) and (NumberOfLinesByCredit = 0) then
                    CurrReport.Skip();
            end;

            trigger OnPreDataItem()
            begin
                GLAccForReport.FilterGroup(2);
                GLAccForReport.SetFilter(GLAccForReport."Account Type", '<>%1&<>%2', "Account Type"::Heading, "Account Type"::"Begin-Total");
                GLAccForReport.FilterGroup(0);
                PageCounter := 0;

                GLAccURL.Open(DATABASE::"G/L Account");
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
                    field(PeriodBeginning; DateStartedOfPeriod)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Period Beginning';
                        ToolTip = 'Specifies the date from which the report or batch job processes information.';
                    }
                    field(EndingOfPeriod; EndingPeriodDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ending of Period';
                        ToolTip = 'Specifies the date to which the report or batch job processes information.';
                    }
                    field(WithoutZeroNetChanges; WithoutZeroNetChanges)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Without Zero Net Changes';
                    }
                    field(ExcludingZeroLine; ExcludingZeroLine)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Without Zero Lines';
                    }
                    field(DebitCreditSeparately; DebitCreditSeparately)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Debit Credit Separately';
                    }
                    field(NewPageForGLAcc; NewPageForGLAcc)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Page For GL Acc';
                        ToolTip = 'Specifies if you want to print a new page for each general ledger account.';
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
        if (DateStartedOfPeriod = 0D) and (EndingPeriodDate = 0D) then
            DateStartedOfPeriod := WorkDate();
        if DateStartedOfPeriod = 0D then
            DateStartedOfPeriod := EndingPeriodDate
        else
            if EndingPeriodDate = 0D then
                EndingPeriodDate := DateStartedOfPeriod;
        CurrentDate := ApplicationLocalization.Date2Text(Today()) + Format(Time(), 0, '(<Hours24>:<Minutes>)');
    end;

    var
#pragma warning disable AA0074
        Text002: Label 'Debit';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text003: Label 'Credit';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text005: Label 'Net Changes ';
#pragma warning restore AA0074
        GLAcc1: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        GLCorrespondenceBuffer: Record "G/L Correspondence Buffer";
        GLCorrespondenceBuffer2: Record "G/L Correspondence Buffer";
        ApplicationLocalization: Codeunit "Localisation Management";
        InternalReportManagement: Codeunit "Internal Report Management";
        CurrentDate: Text[30];
        DebitAmountText: Text[30];
        CreditAmountText: Text[30];
        SignBalanceBegining: Text[10];
        SignBalanceEnding: Text[10];
        BalanceBegining: Decimal;
        BalanceEnding: Decimal;
        NetChangeDebit: Decimal;
        NetChangeCredit: Decimal;
        NetChangeDebitGLAcc: Decimal;
        NetChangeCreditGLAcc: Decimal;
        DateStartedOfPeriod: Date;
        EndingPeriodDate: Date;
        WithoutZeroNetChanges: Boolean;
        ExcludingZeroLine: Boolean;
        NewPageForGLAcc: Boolean;
        DebitCreditSeparately: Boolean;
        NumberOfLinesByDebit: Integer;
        NumberOfLinesByCredit: Integer;
        NumberOfLinesEntries: Integer;
#pragma warning disable AA0074
        Text001: Label 'Invoice ³', Comment = 'Must be translated: æþÑÔ ³';
#pragma warning restore AA0074
        DifferenceExist: Boolean;
        PageCounter: Integer;
        GLAccURL: RecordRef;
        Double_Entries_AnalysisCaptionLbl: Label 'Double Entries Analysis';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Beginning_period_balanceCaptionLbl: Label 'Beginning period balance';
        Ending_period_balanceCaptionLbl: Label 'Ending period balance';
        No_CaptionLbl: Label 'No.';
        Name_AccountCaptionLbl: Label 'Name Account';
        DebitCaptionLbl: Label 'Debit';
        CreditCaptionLbl: Label 'Credit';
        EntriesCaptionLbl: Label 'Entries';
        Net_Change_for_GL_AccCaptionLbl: Label 'Net Change for GL Acc';
        No_Caption_Control3Lbl: Label 'No.';
        NameCaptionLbl: Label 'Name';
        EntriesCaption_Control52Lbl: Label 'Entries';
        Net_Change_for_GL_AccCaption_Control35Lbl: Label 'Net Change for GL Acc';
        No_Caption_Control18Lbl: Label 'No.';
        EntriesCaption_Control19Lbl: Label 'Entries';
        NameCaption_Control4Lbl: Label 'Name';
        Net_Change_for_GL_AccCaption_Control37Lbl: Label 'Net Change for GL Acc';
}

