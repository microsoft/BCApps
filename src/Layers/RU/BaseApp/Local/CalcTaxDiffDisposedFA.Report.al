#pragma warning disable AA0247
report 17307 "Calc. Tax Diff.- Disposed FA"
{
    ApplicationArea = FixedAssets;
    Caption = 'Calc. Tax Diff.- Disposed FA';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Fixed Asset"; "Fixed Asset")
        {
            DataItemTableView = sorting("No.") where("FA Type" = filter("Fixed Assets" | "Intangible Asset"), Blocked = const(false), Inactive = const(false));
            RequestFilterFields = "No.";

            trigger OnAfterGetRecord()
            var
                TaxDeprBonusAmount: Decimal;
                AccBookValueOnDisposal: Decimal;
                TaxBookValueOnDisposal: Decimal;
                DisposalDate: Date;
                FAIsSold: Boolean;
            begin
                TaxDiffFAPostingBuffer.Reset();
                TaxDiffFAPostingBuffer.DeleteAll();

                FALedgerEntry.Reset();
                FALedgerEntry.SetCurrentKey("FA No.", "Depreciation Book Code", "FA Posting Category", "FA Posting Type", "FA Posting Date");
                FALedgerEntry.SetRange("FA No.", "No.");
                FALedgerEntry.SetRange("Depreciation Book Code", TaxRegisterSetup."Tax Depreciation Book");
                FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::"Proceeds on Disposal");
                FALedgerEntry.SetRange("Canceled from FA No.", '');
                FALedgerEntry.SetRange(Reversed, false);
                if FALedgerEntry.FindLast() then
                    DisposalDate := FALedgerEntry."FA Posting Date"
                else
                    CurrReport.Skip();

                SourceType := GetTDESourceType();

                if FADepreciationBook.Get("No.", TaxRegisterSetup."Tax Depreciation Book") then begin
                    FADepreciationBook.CalcFields("Depreciation Bonus");
                    TaxDeprBonusAmount := FADepreciationBook."Depreciation Bonus";
                    FADepreciationBook.SetRange("FA Posting Date Filter", StartDate, EndDate);
                    FADepreciationBook.CalcFields("Proceeds on Disposal");
                    FAIsSold := FADepreciationBook."Proceeds on Disposal" <> 0;
                end else
                    CurrReport.Skip();

                FALedgerEntry.Reset();
                FALedgerEntry.SetCurrentKey("FA No.", "Depreciation Book Code", "FA Posting Category", "FA Posting Type", "FA Posting Date");
                FALedgerEntry.SetRange("FA No.", "No.");
                FALedgerEntry.SetRange("Depreciation Book Code", FASetup."Release Depr. Book");
                FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::"Gain/Loss");
                FALedgerEntry.SetRange("FA Posting Date", 0D, DisposalDate);
                FALedgerEntry.SetRange("Disposal Entry No.", 1);
                if FALedgerEntry.FindLast() then
                    AccBookValueOnDisposal := FALedgerEntry.Amount;

                FALedgerEntry.Reset();
                FALedgerEntry.SetCurrentKey("FA No.", "Depreciation Book Code", "FA Posting Category", "FA Posting Type", "FA Posting Date");
                FALedgerEntry.SetRange("FA No.", "No.");
                FALedgerEntry.SetRange("Depreciation Book Code", TaxRegisterSetup."Tax Depreciation Book");
                FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::"Gain/Loss");
                FALedgerEntry.SetRange("FA Posting Date", 0D, DisposalDate);
                FALedgerEntry.SetRange("Disposal Entry No.", 1);
                if FALedgerEntry.FindLast() then
                    TaxBookValueOnDisposal := FALedgerEntry.Amount;

                TaxDiffLedgerEntry.Reset();
                TaxDiffLedgerEntry.SetCurrentKey("Tax Diff. Code", "Source Type", "Source No.");
                TaxDiffLedgerEntry.SetRange("Source Type", SourceType);
                TaxDiffLedgerEntry.SetRange("Source No.", "No.");
                TaxDiffLedgerEntry.SetRange("Tax Diff. Type", TaxDiffLedgerEntry."Tax Diff. Type"::"Temporary");
                if TaxDiffLedgerEntry.FindSet() then
                    repeat
                        UpdateTaxDiffPostBuf(TaxDiffLedgerEntry."Tax Diff. Code");
                    until TaxDiffLedgerEntry.Next() = 0;

                TaxDiffFAPostingBuffer.Reset();
                if TaxDiffFAPostingBuffer.FindSet() then
                    repeat
                        TaxDiffLedgerEntry.Reset();
                        TaxDiffLedgerEntry.SetCurrentKey("Tax Diff. Code", "Source Type", "Source No.", "Posting Date");
                        TaxDiffLedgerEntry.SetRange("Tax Diff. Code", TaxDiffFAPostingBuffer."Tax Diff. Code");
                        TaxDiffLedgerEntry.SetRange("Source Type", SourceType);
                        TaxDiffLedgerEntry.SetRange("Source No.", "No.");
                        TaxDiffLedgerEntry.CalcSums(Difference);
                        if TaxDiffLedgerEntry.Difference <> 0 then
                            if not TaxDiffAlreadyPosted(TaxDiffFAPostingBuffer."Tax Diff. Code", "No.", EndDate) then
                                CreateJnlLine(
                                  StrSubstNo(Text003, "No."),
                                  EndDate,
                                  TaxDiffFAPostingBuffer."Tax Diff. Code",
                                  "No.",
                                  0,
                                  0,
                                  EndDate,
                                  TaxDiffJnlLine."Disposal Mode"::"Write Down",
                                  false,
                                  1);
                    until TaxDiffFAPostingBuffer.Next() = 0;

                if AccBookValueOnDisposal <> TaxBookValueOnDisposal then
                    if not TaxDiffAlreadyPosted(TaxRegisterSetup."Disposal TD Code", "No.", EndDate) then
                        CreateJnlLine(
                          StrSubstNo(Text004, "No."),
                          EndDate,
                          TaxRegisterSetup."Disposal TD Code",
                          "No.",
                          AccBookValueOnDisposal,
                          TaxBookValueOnDisposal,
                          0D,
                          0,
                          false,
                          0);

                if TaxDeprBonusAmount <> 0 then
                    if ("Initial Release Date" >= TaxRegisterSetup."Depr. Bonus Recovery from") and
                       (DisposalDate < CalcDate(StrSubstNo('<+%1Y>', TaxRegisterSetup."Depr. Bonus Recov. Per. (Year)"), "Initial Release Date"))
                    then
                        if FAIsSold then
                            if not TaxDiffAlreadyPosted(TaxRegisterSetup."Depr. Bonus Recovery TD Code", "No.", EndDate) then
                                CreateJnlLine(
                                  StrSubstNo(Text005, "No."),
                                  EndDate,
                                  TaxRegisterSetup."Depr. Bonus Recovery TD Code",
                                  "No.",
                                  0,
                                  -TaxDeprBonusAmount,
                                  0D,
                                  0,
                                  true,
                                  0);
            end;

            trigger OnPreDataItem()
            begin
                TaxDiffJnlLine."Journal Template Name" := TemplateName;
                TaxDiffJnlLine."Journal Batch Name" := BatchName;
                TaxDiffJnlLine.SetRange("Journal Template Name", TemplateName);
                TaxDiffJnlLine.SetRange("Journal Batch Name", BatchName);
                if TaxDiffJnlLine.FindLast() then;
                LineNo := TaxDiffJnlLine."Line No." + 10000;
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
                    field(AccountPeriod; AccountPeriod)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Accounting Period';
                        ToolTip = 'Specifies the accounting period to include data for.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            PeriodReportManagement.SelectPeriod(Text, CalendarPeriod, false);
                            DatePeriod.Copy(CalendarPeriod);
                            PeriodReportManagement.PeriodSetup(DatePeriod, false);
                            RequestOptionsPage.Update();
                            exit(true);
                        end;

                        trigger OnValidate()
                        begin
                            DatePeriod.Copy(CalendarPeriod);
                            PeriodReportManagement.PeriodSetup(DatePeriod, false);
                        end;
                    }
                    field("DatePeriod.""Period Start"""; DatePeriod."Period Start")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'From';
                        Editable = false;
                        ToolTip = 'Specifies the starting point.';
                    }
                    field("DatePeriod.""Period End"""; DatePeriod."Period End")
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'To';
                        Editable = false;
                        ToolTip = 'Specifies the ending point.';
                    }
                    field(TemplateName; TemplateName)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Jnl. Template Name';
                        TableRelation = "Tax Diff. Journal Template";
                        ToolTip = 'Specifies the name of the journal template, the basis of the journal batch, that the entries were posted from.';
                    }
                    field(BatchName; BatchName)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Jnl. Batch Name';
                        ToolTip = 'Specifies the name of the journal batch, a personalized journal layout, that the journal is based on.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            if TemplateName <> '' then begin
                                TaxDiffJnlBatch.SetRange("Journal Template Name", TemplateName);
                                TaxDiffJnlBatch.SetRange(Name, BatchName);
                                if TaxDiffJnlBatch.FindFirst() then;
                                TaxDiffJnlBatch.SetRange(Name);
                                if ACTION::LookupOK = PAGE.RunModal(0, TaxDiffJnlBatch) then begin
                                    TemplateName := TaxDiffJnlBatch."Journal Template Name";
                                    BatchName := TaxDiffJnlBatch.Name;
                                end;
                            end;
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            PeriodReportManagement.InitPeriod(CalendarPeriod, 0);
            PeriodReportManagement.SetCaptionPeriodYear(AccountPeriod, CalendarPeriod, false);
            DatePeriod.Copy(CalendarPeriod);
            PeriodReportManagement.PeriodSetup(DatePeriod, false);
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        TaxRegisterSetup.Get();
        TaxRegisterSetup.TestField("Use Group Depr. Method from", 0D);
        TaxRegisterSetup.TestField("Tax Depreciation Book");
        TaxRegisterSetup.TestField("Calculate TD for each FA", true);
        if TaxRegisterSetup."Depr. Bonus Recovery from" <> 0D then
            TaxRegisterSetup.TestField("Depr. Bonus Recov. Per. (Year)");
        FASetup.Get();
    end;

    trigger OnPreReport()
    begin
        StartDate := DatePeriod."Period Start";
        EndDate := NormalDate(DatePeriod."Period End");

        if TemplateName = '' then
            Error(Text001);

        if BatchName = '' then
            Error(Text002);

        TaxDiffJnlBatch.Get(TemplateName, BatchName);
        TaxDiffJnlBatch.TestField("No. Series");
    end;

    var
        FALedgerEntry: Record "FA Ledger Entry";
        FASetup: Record "FA Setup";
        FADepreciationBook: Record "FA Depreciation Book";
        TaxRegisterSetup: Record "Tax Register Setup";
        TaxDiffJnlBatch: Record "Tax Diff. Journal Batch";
        TaxDiffJnlLine: Record "Tax Diff. Journal Line";
        xRecTaxDiffJnlLine: Record "Tax Diff. Journal Line";
        TaxDiffFAPostingBuffer: Record "Tax Diff. FA Posting Buffer" temporary;
        TaxDiffLedgerEntry: Record "Tax Diff. Ledger Entry";
        CalendarPeriod: Record Date;
        DatePeriod: Record Date;
        PeriodReportManagement: Codeunit PeriodReportManagement;
        StartDate: Date;
        EndDate: Date;
        AccountPeriod: Text[30];
        TemplateName: Code[10];
        BatchName: Code[10];
        LineNo: Integer;
#pragma warning disable AA0074
        Text001: Label 'Please enter a journal template name.';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text002: Label 'Please enter a journal batch name.';
#pragma warning restore AA0074
        SourceType: Option " ","Future Expense","Fixed Asset","Intangible Asset";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text003: Label 'TD charges due disposal of the %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text004: Label 'TD charges due diff. book value %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text005: Label 'Depr. Bonus Recovery %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    [Scope('OnPrem')]
    procedure CreateJnlLine(Description: Text[80]; PostingDate: Date; TaxDiffCode: Code[10]; SourceNo: Code[20]; AmountBase: Decimal; AmountTax: Decimal; DisposalDate: Date; DisposalMode: Integer; DeprBonusRecover: Boolean; CalcMode: Integer)
    var
        NoSeries: Codeunit "No. Series";
    begin
        xRecTaxDiffJnlLine := TaxDiffJnlLine;
        TaxDiffJnlLine.Init();
        TaxDiffJnlLine.SetUpNewLine(xRecTaxDiffJnlLine);
        TaxDiffJnlLine."Journal Template Name" := TemplateName;
        TaxDiffJnlLine."Journal Batch Name" := BatchName;
        TaxDiffJnlLine."Line No." := LineNo;
        TaxDiffJnlLine.Description := CopyStr(Description, 1, MaxStrLen(TaxDiffJnlLine.Description));
        TaxDiffJnlLine."Document No." := NoSeries.GetNextNo(TaxDiffJnlBatch."No. Series", EndDate);
        TaxDiffJnlLine."Posting Date" := PostingDate;
        TaxDiffJnlLine."Source Type" := SourceType;
        TaxDiffJnlLine.Validate("Source No.", SourceNo);
        TaxDiffJnlLine.Validate("Tax Diff. Code", TaxDiffCode);
        TaxDiffJnlLine.Validate("Amount (Base)", AmountBase);
        TaxDiffJnlLine.Validate("Amount (Tax)", AmountTax);
        TaxDiffJnlLine."Disposal Date" := DisposalDate;
        TaxDiffJnlLine."Disposal Mode" := DisposalMode;
        TaxDiffJnlLine."Depr. Bonus Recovery" := DeprBonusRecover;
        TaxDiffJnlLine."Source Entry Type" := TaxDiffJnlLine."Source Entry Type"::"Disposed FA";
        TaxDiffJnlLine.Validate("Tax Diff. Calc. Mode", CalcMode);
        TaxDiffJnlLine.Insert();
        LineNo += 10000;
    end;

    [Scope('OnPrem')]
    procedure TaxDiffAlreadyPosted(TaxDiffCode: Code[10]; SourceNo: Code[20]; PostingDate: Date): Boolean
    begin
        TaxDiffLedgerEntry.SetCurrentKey("Tax Diff. Code", "Source Type", "Source No.", "Posting Date");
        TaxDiffLedgerEntry.SetRange("Posting Date", PostingDate);
        TaxDiffLedgerEntry.SetRange("Source Type", SourceType);
        TaxDiffLedgerEntry.SetRange("Source No.", SourceNo);
        TaxDiffLedgerEntry.SetRange("Tax Diff. Code", TaxDiffCode);
        TaxDiffLedgerEntry.SetRange(Reversed, false);
        TaxDiffLedgerEntry.SetRange("Source Entry Type", TaxDiffLedgerEntry."Source Entry Type"::"Disposed FA");
        exit(not TaxDiffLedgerEntry.IsEmpty);
    end;

    [Scope('OnPrem')]
    procedure UpdateTaxDiffPostBuf(TaxDiffCode: Code[10])
    begin
        if not TaxDiffFAPostingBuffer.Get(0, TaxDiffCode) then begin
            TaxDiffFAPostingBuffer."Tax Diff. Code" := TaxDiffCode;
            TaxDiffFAPostingBuffer.Insert();
            LineNo += 10000;
        end;
    end;

    [Scope('OnPrem')]
    procedure InitializeRequest(StartDate: Date; EndDate: Date; TaxDiffJnlTemplateName: Code[10]; TaxDiffJnlBatchName: Code[10])
    begin
        DatePeriod."Period Start" := StartDate;
        DatePeriod."Period End" := EndDate;
        TemplateName := TaxDiffJnlTemplateName;
        BatchName := TaxDiffJnlBatchName;
    end;
}

