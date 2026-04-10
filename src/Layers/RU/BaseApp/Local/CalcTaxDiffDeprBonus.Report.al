#pragma warning disable AA0247
report 17308 "Calc. Tax Diff.- Depr. Bonus"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Calc. Tax Diff.- Depr. Bonus';
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
            begin
                if FADepreciationBook.Get("No.", TaxRegisterSetup."Tax Depreciation Book") then begin
                    FADepreciationBook.SetRange("FA Posting Date Filter", StartDate, EndDate);
                    FADepreciationBook.CalcFields("Depreciation Bonus");
                    TaxDeprBonusAmount := FADepreciationBook."Depreciation Bonus";
                end;

                if TaxDeprBonusAmount <> 0 then begin
                    SourceType := GetTDESourceType();
                    if not TaxDiffAlreadyPosted(
                         TaxRegisterSetup."Depr. Bonus TD Code",
                         SourceType,
                         "No.",
                         EndDate)
                    then
                        CreateJnlLine(
                          StrSubstNo(Text003, "No."),
                          EndDate,
                          TaxRegisterSetup."Depr. Bonus TD Code",
                          0,
                          -TaxDeprBonusAmount,
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
                        ApplicationArea = Basic, Suite;
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
                        ApplicationArea = Basic, Suite;
                        Caption = 'From';
                        Editable = false;
                        ToolTip = 'Specifies the starting point.';
                    }
                    field("DatePeriod.""Period End"""; DatePeriod."Period End")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'To';
                        Editable = false;
                        ToolTip = 'Specifies the ending point.';
                    }
                    field(TemplateName; TemplateName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Jnl. Template Name';
                        TableRelation = "Tax Diff. Journal Template";
                        ToolTip = 'Specifies the name of the journal template, the basis of the journal batch, that the entries were posted from.';
                    }
                    field(BatchName; BatchName)
                    {
                        ApplicationArea = Basic, Suite;
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
        FASetup: Record "FA Setup";
        FADepreciationBook: Record "FA Depreciation Book";
        TaxRegisterSetup: Record "Tax Register Setup";
        TaxDiffJnlBatch: Record "Tax Diff. Journal Batch";
        TaxDiffJnlLine: Record "Tax Diff. Journal Line";
        xRecTaxDiffJnlLine: Record "Tax Diff. Journal Line";
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
        Text003: Label 'Depreciation Bonus for %1';
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
        TaxDiffJnlLine."Posting Date" := PostingDate;
        TaxDiffJnlLine."Source Type" := SourceType;
        TaxDiffJnlLine.Validate("Source No.", SourceNo);
        TaxDiffJnlLine.Validate("Tax Diff. Code", TaxDiffCode);
        TaxDiffJnlLine.Validate("Amount (Base)", AmountBase);
        TaxDiffJnlLine.Validate("Amount (Tax)", AmountTax);
        TaxDiffJnlLine."Source Entry Type" := TaxDiffJnlLine."Source Entry Type"::"Depr. Bonus";
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
        TaxDiffLedgerEntry.SetRange("Source Entry Type", TaxDiffLedgerEntry."Source Entry Type"::"Depr. Bonus");
        exit(not TaxDiffLedgerEntry.IsEmpty);
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

