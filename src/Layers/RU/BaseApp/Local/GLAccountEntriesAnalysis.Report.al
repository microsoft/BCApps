#pragma warning disable AA0247
report 12438 "G/L Account Entries Analysis"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/GLAccountEntriesAnalysis.rdlc';
    Caption = 'G/L Account Entries Analysis';
    EnableHyperlinks = true;

    dataset
    {
        dataitem("G/L Account"; "G/L Account")
        {
            DataItemTableView = sorting("No.") where("Account Type" = const(Posting));
            RequestFilterFields = "No.", "Date Filter";
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(CurrentDate; CurrentDate)
            {
            }
            column(USERID; UserId)
            {
            }
            column(BalanceBegining; BalanceBegining)
            {
            }
            column(SignBalanceBegining; SignBalanceBegining)
            {
            }
            column(Text010____No_____________Name_; Text010 + "No." + '   ' + Name)
            {
            }
            column(LocMgt_Date2Text_StartDate_; LocMgt.Date2Text(StartDate))
            {
            }
            column(GLAccURL; Format(GLAccURL.RecordId, 0, 10))
            {
            }
            column(PageNo; PageNo)
            {
            }
            column(DifferenceExist; DifferenceExist)
            {
            }
            column(GL_Acc__For_EntryCaption; GL_Acc__For_EntryCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Begining_period_balanceCaption; Begining_period_balanceCaptionLbl)
            {
            }
            column(G_L_Account_No_; "No.")
            {
            }
            dataitem(BYGLAccounts; "Integer")
            {
                DataItemTableView = sorting(Number);
                column(Text005___________G_L_Account___No__; Text005 + '  ' + "G/L Account"."No.")
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
                column(G_L_Account__Name_; "G/L Account".Name)
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
                column(G_L_Account__Name__Control47; "G/L Account".Name)
                {
                }
                column(No_Caption; No_CaptionLbl)
                {
                }
                column(NameCaption; NameCaptionLbl)
                {
                }
                column(DebitCaption; DebitCaptionLbl)
                {
                }
                column(CreditCaption; CreditCaptionLbl)
                {
                }
                column(Net_Change_for_GL_AccCaption; Net_Change_for_GL_AccCaptionLbl)
                {
                }
                column(BYGLAccounts_Number; Number)
                {
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
                        NetChangeDebit += GLCorrespondenceBuffer.Amount;
                        DebitAmountText := Format(GLCorrespondenceBuffer.Amount, 0, '<Sign><Integer Thousand><Decimals,3>');
                        GLCorrespondenceBuffer2.Copy(GLCorrespondenceBuffer);
                        GLCorrespondenceBuffer2.Type := GLCorrespondenceBuffer2.Type::Credit;
                        if GLCorrespondenceBuffer2.Find() then begin
                            NetChangeCredit += GLCorrespondenceBuffer2.Amount;
                            CreditAmountText := Format(GLCorrespondenceBuffer2.Amount, 0, '<Sign><Integer Thousand><Decimals,3>');
                            GLCorrespondenceBuffer2."Use Duplication List" := true;
                            GLCorrespondenceBuffer2.Modify();
                        end;
                    end else
                        if GLCorrespondenceBuffer.Type = GLCorrespondenceBuffer.Type::Credit then begin
                            NetChangeCredit += GLCorrespondenceBuffer.Amount;
                            CreditAmountText := Format(GLCorrespondenceBuffer.Amount, 0, '<Sign><Integer Thousand><Decimals,3>');
                            GLCorrespondenceBuffer2.Copy(GLCorrespondenceBuffer);
                            GLCorrespondenceBuffer2.Type := GLCorrespondenceBuffer2.Type::Debit;
                            if GLCorrespondenceBuffer2.Find() then begin
                                NetChangeDebit += GLCorrespondenceBuffer2.Amount;
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
                column(Text002____G_L_Account___No__; Text002 + "G/L Account"."No.")
                {
                }
                column(DebitAmountText_Control1210010; DebitAmountText)
                {
                }
                column(GLAcc1_Name_Control1210013; GLAcc1.Name)
                {
                }
                column(GLAcc1__No___Control1210015; GLAcc1."No.")
                {
                }
                column(NetChangeDebit_Control4010; NetChangeDebit)
                {
                }
                column(G_L_Account__Name__Control48; "G/L Account".Name)
                {
                }
                column(NetChangeDebit_Control4012; NetChangeDebit)
                {
                }
                column(NetChangeDebitGLAcc_Control45; NetChangeDebitGLAcc)
                {
                }
                column(G_L_Account__Name__Control49; "G/L Account".Name)
                {
                }
                column(No_Caption_Control3; No_Caption_Control3Lbl)
                {
                }
                column(NameCaption_Control4; NameCaption_Control4Lbl)
                {
                }
                column(Net_Change_for_GL_AccCaption_Control35; Net_Change_for_GL_AccCaption_Control35Lbl)
                {
                }
                column(ByDebit_Number; Number)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if Number = 1 then
                        GLCorrespondenceBuffer.Find('-')
                    else
                        GLCorrespondenceBuffer.Next();
                    GLAcc1.Get(GLCorrespondenceBuffer."G/L Account");
                    NetChangeDebit += GLCorrespondenceBuffer.Amount;
                    DebitAmountText := Format(GLCorrespondenceBuffer.Amount, 0, '<Sign><Integer Thousand><Decimals,3>');
                end;

                trigger OnPreDataItem()
                begin
                    if (NumberOfLinesByDebit = 0)
                      or (not DebitCreditSeparately and not (NumberOfLinesByCredit = 0))
                    then
                        CurrReport.Break();
                    SetRange(Number, 1, NumberOfLinesByDebit);
                    GLCorrespondenceBuffer.SetRange(Type, 0);
                    NetChangeDebit := 0;
                end;
            }
            dataitem(ByCredit; "Integer")
            {
                DataItemTableView = sorting(Number);
                MaxIteration = 0;
                column(Text003____G_L_Account___No__; Text003 + "G/L Account"."No.")
                {
                }
                column(CreditAmountText_Control1210018; CreditAmountText)
                {
                }
                column(GLAcc1_Name_Control1210021; GLAcc1.Name)
                {
                }
                column(GLAcc1__No___Control1210024; GLAcc1."No.")
                {
                }
                column(NetChangeCredit_Control4120; NetChangeCredit)
                {
                }
                column(G_L_Account__Name__Control50; "G/L Account".Name)
                {
                }
                column(NetChangeCredit_Control4123; NetChangeCredit)
                {
                }
                column(NetChangeCreditGLAcc_Control46; NetChangeCreditGLAcc)
                {
                }
                column(G_L_Account__Name__Control51; "G/L Account".Name)
                {
                }
                column(NameCaption_Control19; NameCaption_Control19Lbl)
                {
                }
                column(No_Caption_Control18; No_Caption_Control18Lbl)
                {
                }
                column(Net_Change_for_GL_AccCaption_Control37; Net_Change_for_GL_AccCaption_Control37Lbl)
                {
                }
                column(ByCredit_Number; Number)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if Number = 1 then
                        GLCorrespondenceBuffer.Find('-')
                    else
                        GLCorrespondenceBuffer.Next();
                    GLAcc1.Get(GLCorrespondenceBuffer."G/L Account");
                    NetChangeCredit += GLCorrespondenceBuffer.Amount;
                    CreditAmountText := Format(GLCorrespondenceBuffer.Amount, 0, '<Sign><Integer Thousand><Decimals,3>');

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
                    NetChangeCredit := 0;
                end;
            }
            dataitem(Balance; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(BalanceEnding; BalanceEnding)
                {
                }
                column(SignBalanceEnding; SignBalanceEnding)
                {
                }
                column(LocMgt_Date2Text_EndDate_; LocMgt.Date2Text(EndDate))
                {
                }
                column(Ending_period_balanceCaption; Ending_period_balanceCaptionLbl)
                {
                }
                column(Balance_Number; Number)
                {
                }

                trigger OnPostDataItem()
                begin
                    if NewPageForGLAcc then
                        PageNo += 1;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                GLAccURL.SetPosition(GetPosition());

                SetRange("Date Filter", 0D, CalcDate('<-1D>', StartDate));
                CalcFields("Balance at Date");
                if "Balance at Date" > 0 then
                    SignBalanceBegining := Text002
                else
                    if "Balance at Date" < 0 then
                        SignBalanceBegining := Text003
                    else
                        SignBalanceBegining := '';
                BalanceBegining := Abs("Balance at Date");
                SetRange("Date Filter", 0D, EndDate);
                CalcFields("Net Change");
                if "Net Change" > 0 then
                    SignBalanceEnding := Text002
                else
                    if "Balance at Date" < 0 then
                        SignBalanceEnding := Text003
                    else
                        SignBalanceEnding := '';
                BalanceEnding := Abs("Net Change");
                SetRange("Date Filter", StartDate, EndDate);
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
                  GLCorrespondenceBuffer, "G/L Account", NumberOfLinesByDebit, NumberOfLinesByCredit,
                  StartDate, EndDate, WithoutZeroNetChanges);
                if (NumberOfLinesByDebit = 0) and (NumberOfLinesByCredit = 0) then
                    CurrReport.Skip();
            end;

            trigger OnPreDataItem()
            begin
                PageNo := 0;
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
                    group(Printout)
                    {
                        Caption = 'Printout';
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
        CurrentDate := LocMgt.Date2Text(Today()) + Format(Time(), 0, '(<Hours24>:<Minutes>)');
        if "G/L Account".GetRangeMin("Date Filter") > 0D then
            StartDate := "G/L Account".GetRangeMin("Date Filter");
        EndDate := "G/L Account".GetRangeMax("Date Filter");
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
        GLCorrespondenceBuffer: Record "G/L Correspondence Buffer";
        GLCorrespondenceBuffer2: Record "G/L Correspondence Buffer";
        LocMgt: Codeunit "Localisation Management";
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
        StartDate: Date;
        EndDate: Date;
        WithoutZeroNetChanges: Boolean;
        ExcludingZeroLine: Boolean;
        NewPageForGLAcc: Boolean;
        DebitCreditSeparately: Boolean;
        NumberOfLinesByDebit: Integer;
        NumberOfLinesByCredit: Integer;
#pragma warning disable AA0074
        Text010: Label 'Invoice ³', Comment = 'Must be translated: æþÑÔ ³';
#pragma warning restore AA0074
        PageNo: Integer;
        GLAccURL: RecordRef;
        DifferenceExist: Boolean;
        GL_Acc__For_EntryCaptionLbl: Label 'GL Acc. For Entry';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Begining_period_balanceCaptionLbl: Label 'Begining period balance';
        No_CaptionLbl: Label 'No.';
        NameCaptionLbl: Label 'Name';
        DebitCaptionLbl: Label 'Debit';
        CreditCaptionLbl: Label 'Credit';
        Net_Change_for_GL_AccCaptionLbl: Label 'Net Change for GL Acc';
        No_Caption_Control3Lbl: Label 'No.';
        NameCaption_Control4Lbl: Label 'Name';
        Net_Change_for_GL_AccCaption_Control35Lbl: Label 'Net Change for GL Acc';
        NameCaption_Control19Lbl: Label 'Name';
        No_Caption_Control18Lbl: Label 'No.';
        Net_Change_for_GL_AccCaption_Control37Lbl: Label 'Net Change for GL Acc';
        Ending_period_balanceCaptionLbl: Label 'Ending period balance';
}

