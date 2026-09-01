#pragma warning disable AA0247
report 17306 "Calculate Tax Diff. for FA"
{
    ApplicationArea = FixedAssets;
    Caption = 'Calculate Tax Diff. for FA';
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
                AccAcquisitionCost: Decimal;
                TaxAcquisitionCost: Decimal;
                AccCurrPeriodAcquisitionCost: Decimal;
                TaxCurrPeriodAcquisitionCost: Decimal;
                AccDeprAmount: Decimal;
                TaxDeprAmount: Decimal;
                TaxDeprBonusAmount: Decimal;
                BufferedAccDeprAmount: Decimal;
                DiffAccDeprAmountToPost: Decimal;
                DiffAccDeprBonusAmountToPost: Decimal;
                TaxDiffPeriodDeprAmount: Decimal;
            begin
                TaxDiffFAPostingBuffer.Reset();
                TaxDiffFAPostingBuffer.DeleteAll();

                SourceType := GetTDESourceType();

                if FADepreciationBook.Get("No.", FASetup."Release Depr. Book") then begin
                    FADepreciationBook.SetRange("FA Posting Date Filter", 0D, StartDate - 1);
                    FADepreciationBook.CalcFields("Acquisition Cost", "Salvage Value", Appreciation);
                    AccAcquisitionCost :=
                      FADepreciationBook."Acquisition Cost" +
                      FADepreciationBook.Appreciation +
                      FADepreciationBook."Salvage Value";

                    FADepreciationBook.SetRange("FA Posting Date Filter", StartDate, EndDate);
                    FADepreciationBook.CalcFields("Acquisition Cost", "Salvage Value", Appreciation, Depreciation);
                    AccCurrPeriodAcquisitionCost :=
                      FADepreciationBook."Acquisition Cost" +
                      FADepreciationBook.Appreciation +
                      FADepreciationBook."Salvage Value";
                    AccDeprAmount := -FADepreciationBook.Depreciation;
                end;

                if FADepreciationBook.Get("No.", TaxRegisterSetup."Tax Depreciation Book") then begin
                    FADepreciationBook.SetRange("FA Posting Date Filter", 0D, StartDate - 1);
                    FADepreciationBook.CalcFields("Acquisition Cost", "Salvage Value", Appreciation);
                    TaxAcquisitionCost :=
                      FADepreciationBook."Acquisition Cost" +
                      FADepreciationBook.Appreciation +
                      FADepreciationBook."Salvage Value";

                    FADepreciationBook.SetRange("FA Posting Date Filter", StartDate, EndDate);
                    FADepreciationBook.CalcFields("Acquisition Cost", "Salvage Value", Appreciation, Depreciation, "Depreciation Bonus");
                    TaxCurrPeriodAcquisitionCost :=
                      FADepreciationBook."Acquisition Cost" +
                      FADepreciationBook.Appreciation +
                      FADepreciationBook."Salvage Value";
                    TaxDeprAmount := -FADepreciationBook.Depreciation;
                    TaxDeprBonusAmount := -FADepreciationBook."Depreciation Bonus";
                end;

                if AccAcquisitionCost < TaxAcquisitionCost then begin
                    Message(Text003, "Fixed Asset".TableCaption(), "No.");
                    CurrReport.Skip();
                end;

                if (AccAcquisitionCost <> TaxAcquisitionCost) or
                   (AccCurrPeriodAcquisitionCost <> TaxCurrPeriodAcquisitionCost) or
                   (AccDeprAmount <> TaxDeprAmount) or
                   (TaxDeprBonusAmount <> 0)
                then begin
                    DepreciationBook.SetRange("Control FA Acquis. Cost", true);
                    if DepreciationBook.FindSet() then
                        repeat
                            if FADepreciationBook.Get("No.", DepreciationBook.Code) then begin
                                FALedgerEntry.Reset();
                                FALedgerEntry.SetCurrentKey("FA No.", "Depreciation Book Code", "FA Posting Date", Reversed, "Tax Difference Code");
                                FALedgerEntry.SetRange("FA No.", "No.");
                                FALedgerEntry.SetRange("FA Posting Date", 0D, EndDate);
                                FALedgerEntry.SetRange("Depreciation Book Code", DepreciationBook.Code);
                                FALedgerEntry.SetFilter(
                                  "FA Posting Type",
                                  '%1|%2|%3',
                                  FALedgerEntry."FA Posting Type"::"Acquisition Cost",
                                  FALedgerEntry."FA Posting Type"::Appreciation,
                                  FALedgerEntry."FA Posting Type"::"Salvage Value");
                                FALedgerEntry.SetRange("Reclassification Entry", false);
                                FALedgerEntry.SetFilter("Tax Difference Code", '<>%1&<>%2', '', TaxRegisterSetup."Default FA TD Code");
                                if FALedgerEntry.FindSet() then
                                    repeat
                                        TaxDiff.Get(FALedgerEntry."Tax Difference Code");

                                        if FALedgerEntry."FA Posting Date" < StartDate then begin
                                            if AccDeprAmount <> TaxDeprAmount then
                                                UpdateTaxDiffPostBuf(
                                                  TaxDiffFAPostingBuffer.Type::Depreciation,
                                                  FALedgerEntry."Tax Difference Code",
                                                  FALedgerEntry.Amount);
                                        end else
                                            if (AccCurrPeriodAcquisitionCost <> TaxCurrPeriodAcquisitionCost) and
                                               (TaxDiff.Type = TaxDiff.Type::"Temporary")
                                            then
                                                UpdateTaxDiffPostBuf(
                                                  TaxDiffFAPostingBuffer.Type::"Acquisition Cost",
                                                  FALedgerEntry."Tax Difference Code",
                                                  FALedgerEntry.Amount);
                                    until FALedgerEntry.Next() = 0;
                            end;
                        until DepreciationBook.Next() = 0;

                    FALedgerEntry.SetRange("Tax Difference Code");
                    FALedgerEntry.SetRange("Depreciation Book Code", TaxRegisterSetup."Tax Depreciation Book");
                    FALedgerEntry.SetRange("FA Posting Date", 0D, EndDate);
                    FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::Depreciation);
                    FALedgerEntry.SetRange("Depr. Bonus", true);
                    if FALedgerEntry.FindSet() then
                        repeat
                            UpdateTaxDiffPostBuf(
                              TaxDiffFAPostingBuffer.Type::"Depreciation Bonus",
                              TaxRegisterSetup."Depr. Bonus TD Code",
                              FALedgerEntry.Amount);
                        until FALedgerEntry.Next() = 0;
                end;

                TaxDiffFAPostingBuffer.Reset();
                if TaxDiffFAPostingBuffer.FindSet() then
                    repeat
                        TaxDiff.Get(TaxDiffFAPostingBuffer."Tax Diff. Code");

                        case TaxDiffFAPostingBuffer.Type of
                            TaxDiffFAPostingBuffer.Type::"Acquisition Cost":
                                if not TaxDiffAlreadyPosted(
                                        TaxDiffFAPostingBuffer."Tax Diff. Code",
                                        SourceType,
                                        "No.",
                                        "Initial Release Date")
                                then
                                    CreateJnlLine(
                                        StrSubstNo('%1 %2', TaxDiff.Description, "No."),
                                        "Initial Release Date",
                                        TaxDiffFAPostingBuffer."Tax Diff. Code",
                                        0,
                                        TaxDiffFAPostingBuffer."Initial Amount",
                                        TaxDiffJnlLine."Source Type"::"Fixed Asset",
                                        "No.");
                            TaxDiffFAPostingBuffer.Type::Depreciation:
                                if not TaxDiffAlreadyPosted(
                                     TaxDiffFAPostingBuffer."Tax Diff. Code",
                                     SourceType,
                                     "No.",
                                     EndDate)
                                then begin
                                    DiffAccDeprAmountToPost := Round(AccDeprAmount * TaxDiffFAPostingBuffer."Initial Amount" / AccAcquisitionCost);
                                    if DiffAccDeprAmountToPost <> 0 then begin
                                        CreateJnlLine(
                                          StrSubstNo('%1 %2', TaxDiff.Description, "No."),
                                          EndDate,
                                          TaxDiffFAPostingBuffer."Tax Diff. Code",
                                          DiffAccDeprAmountToPost,
                                          0,
                                          TaxDiffJnlLine."Source Type"::"Fixed Asset",
                                          "No.");
                                        BufferedAccDeprAmount := BufferedAccDeprAmount + DiffAccDeprAmountToPost;
                                    end;
                                end;
                            TaxDiffFAPostingBuffer.Type::"Depreciation Bonus":
                                if not TaxDiffAlreadyPosted(
                                     TaxDiffFAPostingBuffer."Tax Diff. Code",
                                     SourceType,
                                     "No.",
                                     EndDate)
                                then begin
                                    DiffAccDeprBonusAmountToPost :=
                                      -Round(AccDeprAmount * TaxDiffFAPostingBuffer."Initial Amount" / AccAcquisitionCost);
                                    if DiffAccDeprBonusAmountToPost <> 0 then
                                        CreateJnlLine(
                                          StrSubstNo('%1 %2', TaxDiff.Description, "No."),
                                          EndDate,
                                          TaxDiffFAPostingBuffer."Tax Diff. Code",
                                          DiffAccDeprBonusAmountToPost,
                                          0,
                                          TaxDiffJnlLine."Source Type"::"Fixed Asset",
                                          "No.");
                                end;
                        end;
                    until TaxDiffFAPostingBuffer.Next() = 0;

                TaxDiffPeriodDeprAmount := AccDeprAmount - BufferedAccDeprAmount - DiffAccDeprBonusAmountToPost;
                if ((TaxDiffPeriodDeprAmount <> 0) or (TaxDeprAmount - TaxDeprBonusAmount <> 0)) and
                   (TaxDiffPeriodDeprAmount <> TaxDeprAmount - TaxDeprBonusAmount)
                then begin
                    TaxDiff.Get("Tax Difference Code");
                    if not TaxDiffAlreadyPosted(
                         "Tax Difference Code",
                         SourceType,
                         "No.",
                         EndDate)
                    then
                        CreateJnlLine(
                          StrSubstNo('%1 %2', TaxDiff.Description, "No."),
                          EndDate,
                          "Tax Difference Code",
                          TaxDiffPeriodDeprAmount,
                          TaxDeprAmount - TaxDeprBonusAmount,
                          TaxDiffJnlLine."Source Type"::"Fixed Asset",
                          "No.");
                end;
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
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        TaxRegisterSetup: Record "Tax Register Setup";
        TaxDiffJnlBatch: Record "Tax Diff. Journal Batch";
        TaxDiffJnlLine: Record "Tax Diff. Journal Line";
        xRecTaxDiffJnlLine: Record "Tax Diff. Journal Line";
        TaxDiffFAPostingBuffer: Record "Tax Diff. FA Posting Buffer" temporary;
        TaxDiff: Record "Tax Difference";
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
        Text003: Label '%1 %2 is skipped. Please calculate tax difference manually if it is necessary.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    [Scope('OnPrem')]
    procedure CreateJnlLine(Description: Text[80]; PostingDate: Date; TaxDiffCode: Code[10]; AmountBase: Decimal; AmountTax: Decimal; SourceType: Option; SourceNo: Code[20])
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
        if PostingDate = 0D then
            TaxDiffJnlLine."Posting Date" := EndDate
        else
            TaxDiffJnlLine."Posting Date" := PostingDate;
        TaxDiffJnlLine."Source Type" := SourceType;
        TaxDiffJnlLine.Validate("Source No.", SourceNo);
        TaxDiffJnlLine.Validate("Tax Diff. Code", TaxDiffCode);
        TaxDiffJnlLine.Validate("Amount (Base)", AmountBase);
        TaxDiffJnlLine.Validate("Amount (Tax)", AmountTax);
        TaxDiffJnlLine."Source Entry Type" := TaxDiffJnlLine."Source Entry Type"::FA;
        TaxDiffJnlLine.Insert();
        LineNo += 10000;
    end;

    [Scope('OnPrem')]
    procedure TaxDiffAlreadyPosted(TaxDiffCode: Code[10]; SourceType: Option; SourceNo: Code[20]; PostingDate: Date): Boolean
    begin
        TaxDiffLedgerEntry.SetCurrentKey("Tax Diff. Code", "Source Type", "Source No.", "Posting Date");
        TaxDiffLedgerEntry.SetRange("Posting Date", PostingDate);
        TaxDiffLedgerEntry.SetRange("Source Type", SourceType);
        TaxDiffLedgerEntry.SetRange("Source No.", SourceNo);
        TaxDiffLedgerEntry.SetRange("Tax Diff. Code", TaxDiffCode);
        TaxDiffLedgerEntry.SetRange(Reversed, false);
        TaxDiffLedgerEntry.SetRange("Source Entry Type", TaxDiffLedgerEntry."Source Entry Type"::FA);
        exit(not TaxDiffLedgerEntry.IsEmpty);
    end;

    [Scope('OnPrem')]
    procedure UpdateTaxDiffPostBuf(Type: Option "Acquisition Cost","Depreciation Bonus",Depreciation; TaxDiffCode: Code[10]; InitialAmount: Decimal)
    begin
        if not TaxDiffFAPostingBuffer.Get(Type, TaxDiffCode) then begin
            TaxDiffFAPostingBuffer.Type := Type;
            TaxDiffFAPostingBuffer."Tax Diff. Code" := TaxDiffCode;
            TaxDiffFAPostingBuffer."Initial Amount" := InitialAmount;
            TaxDiffFAPostingBuffer.Insert();
            LineNo += 10000;
        end else begin
            TaxDiffFAPostingBuffer."Initial Amount" += InitialAmount;
            TaxDiffFAPostingBuffer.Modify();
        end;
    end;

    [Scope('OnPrem')]
    procedure InitializeRequest(NewEndDate: Date; NewTemplateName: Code[10]; NewBatchName: Code[10])
    begin
        TemplateName := NewTemplateName;
        BatchName := NewBatchName;
        DatePeriod.SetRange("Period Type", DatePeriod."Period Type"::Month);
        DatePeriod.SetRange("Period End", ClosingDate(CalcDate('<CM>', NewEndDate)));
        DatePeriod.FindFirst();
    end;
}

