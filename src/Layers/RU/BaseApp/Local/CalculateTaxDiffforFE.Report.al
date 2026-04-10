#pragma warning disable AA0247
report 17300 "Calculate Tax Diff. for FE"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Calculate Tax Diff. for FE';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Future Expense"; "Fixed Asset")
        {
            DataItemTableView = sorting("No.") where("FA Type" = const("Future Expense"), Blocked = const(false), Inactive = const(false));

            trigger OnAfterGetRecord()
            begin
                Processing += 1;
                Wnd.Update(1, "No.");
                Wnd.Update(2, Round((Processing / Total) * 10000, 1));
                if not TaxDiff.Get("Tax Difference Code") then
                    CurrReport.Skip();

                if not Choice[Choices::Fixed] and (TaxDiff.Type = TaxDiff.Type::Constant) or
                   not Choice[Choices::"Temporary"] and (TaxDiff.Type = TaxDiff.Type::"Temporary")
                then
                    CurrReport.Skip();

                AccAcquisCost := 0;
                TaxAcquisCost := 0;
                AccountDepreciation := 0;
                TaxAccountDepreciation := 0;

                if FADepreciationBook.Get("No.", FASetup."Future Depr. Book") then begin
                    FADepreciationBook.SetRange("FA Posting Date Filter", DatePeriod."Period Start", NormalDate(DatePeriod."Period End"));
                    FADepreciationBook.CalcFields(Depreciation, "Acquisition Cost");
                    AccountDepreciation := FADepreciationBook.Depreciation;
                    AccAcquisCost := FADepreciationBook."Acquisition Cost";
                end;

                if FADepreciationBook.Get("No.", TaxRegisterSetup."Future Exp. Depreciation Book") then begin
                    FADepreciationBook.SetRange("FA Posting Date Filter", DatePeriod."Period Start", DatePeriod."Period End");
                    FADepreciationBook.CalcFields(Depreciation, "Acquisition Cost");
                    TaxAccountDepreciation := FADepreciationBook.Depreciation;
                    TaxAcquisCost := FADepreciationBook."Acquisition Cost";
                end;
                if not CalcTDAcquisCost then begin
                    if not (((DisposalDate = 0D) or (TaxDiff."Tax Period Limited" = TaxDiff."Tax Period Limited"::" ")) and
                            ((AccountDepreciation = 0) and (TaxAccountDepreciation = 0)))
                    then begin
                        xRecTaxDiffJnlLine := TaxDiffJnlLine;
                        TaxDiffJnlLine."Line No." += 10000;
                        TaxDiffJnlLine.Init();
                        TaxDiffJnlLine.SetUpNewLine(xRecTaxDiffJnlLine);
                        TaxDiffJnlLine."Posting Date" := PostingDate;
                        if TaxDiffJnlLine."Document No." = '' then
                            TaxDiffJnlLine."Document No." := DocumentNo;
                        TaxDiffJnlLine.Description := PostingDescription;
                        TaxDiffJnlLine."Source Type" := TaxDiffJnlLine."Source Type"::"Future Expense";
                        TaxDiffJnlLine.Validate("Source No.", "No.");
                        TaxDiffJnlLine."Amount (Base)" := Abs(AccountDepreciation);
                        TaxDiffJnlLine.Validate("Amount (Tax)", Abs(TaxAccountDepreciation));
                        if (TaxDiff."Tax Period Limited" <> TaxDiff."Tax Period Limited"::" ") and (DisposalDate <> 0D) then begin
                            TaxDiffJnlLine."Disposal Mode" := TaxDiffJnlLine."Disposal Mode"::Transform;
                            TaxDiffJnlLine."Disposal Date" := DisposalDate;
                        end;
                        TaxDiffJnlLine.Insert();
                    end;
                end else
                    if ((AccountDepreciation = 0) and (TaxAccountDepreciation = 0)) and
                       (((AccAcquisCost <> 0) and (TaxAcquisCost = 0)) or ((AccAcquisCost = 0) and (TaxAcquisCost <> 0)))
                    then begin
                        xRecTaxDiffJnlLine := TaxDiffJnlLine;
                        TaxDiffJnlLine."Line No." += 10000;
                        TaxDiffJnlLine.Init();
                        TaxDiffJnlLine.SetUpNewLine(xRecTaxDiffJnlLine);
                        TaxDiffJnlLine."Posting Date" := PostingDate;
                        if TaxDiffJnlLine."Document No." = '' then
                            TaxDiffJnlLine."Document No." := DocumentNo;
                        TaxDiffJnlLine.Description := StrSubstNo(Text1005, "No.");
                        TaxDiffJnlLine."Source Type" := TaxDiffJnlLine."Source Type"::"Future Expense";
                        TaxDiffJnlLine.Validate("Source No.", "No.");
                        TaxDiffJnlLine.Validate("Tax Diff. Code", "Tax Difference Code");
                        TaxDiffJnlLine."Amount (Base)" := Abs(TaxAcquisCost);
                        TaxDiffJnlLine.Validate("Amount (Tax)", Abs(AccAcquisCost));
                        TaxDiffJnlLine.Insert();
                    end;
            end;

            trigger OnPostDataItem()
            begin
                Wnd.Close();
            end;

            trigger OnPreDataItem()
            begin
                Total := Count;
                Wnd.Open(Text1001);
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
                            AccountPeriodOnAfterValidate();
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
                    field("Choice[Choices::Fixed]"; Choice[Choices::Fixed])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Fixed Tax Differences';
                        ToolTip = 'Specifies if the tax difference amount is fixed.';
                    }
                    field("Choice[Choices::""Temporary""]"; Choice[Choices::"Temporary"])
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Temporary Tax Differences';
                        ToolTip = 'Specifies if the tax difference is temporary.';
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
                    field(PostingDate; PostingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the posting date of the entries that you want to include in the report or batch job.';
                    }
                    field(DocumentNo; DocumentNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document No.';
                        ToolTip = 'Specifies the number of the related document.';
                    }
                    field(PostingDescription; PostingDescription)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Description';
                        ToolTip = 'Specifies a description of the tax difference.';
                    }
                    field(CalcTDAcquisCost; CalcTDAcquisCost)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Calc. TD for Acquis. Cost';
                        ToolTip = 'Specifies if you want to calculate tax differences for acquisitioned costs.';
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

            Choice[Choices::Fixed] := true;
            Choice[Choices::"Temporary"] := true;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        if (TemplateName = '') or (BatchName = '') then
            Error(Text1000);

        TaxDiffJnlLine."Journal Template Name" := TemplateName;
        TaxDiffJnlLine."Journal Batch Name" := BatchName;
        TaxDiffJnlLine.SetRange("Journal Template Name", TaxDiffJnlLine."Journal Template Name");
        TaxDiffJnlLine.SetRange("Journal Batch Name", TaxDiffJnlLine."Journal Batch Name");
        if not TaxDiffJnlLine.FindLast() then
            TaxDiffJnlLine."Line No." := 0;

        SetProperties();

        DisposalDate := 0D;
        if CalcDate('<CM>', PostingDate) = CalcDate('<CY>', PostingDate) then
            DisposalDate := CalcDate('<CM>', PostingDate);

        if DisposalDate <> 0D then
            if not Confirm(Text1002, true, TaxDiffJnlLine.FieldCaption("Posting Date")) then
                DisposalDate := 0D;

        FASetup.Get();
        FASetup.TestField("Future Depr. Book");
        TaxRegisterSetup.Get();
        TaxRegisterSetup.TestField("Future Exp. Depreciation Book");
    end;

    var
        FASetup: Record "FA Setup";
        FADepreciationBook: Record "FA Depreciation Book";
        TaxRegisterSetup: Record "Tax Register Setup";
        TaxDiffJnlBatch: Record "Tax Diff. Journal Batch";
        TaxDiffJnlLine: Record "Tax Diff. Journal Line";
        xRecTaxDiffJnlLine: Record "Tax Diff. Journal Line";
        TaxDiff: Record "Tax Difference";
        CalendarPeriod: Record Date;
        DatePeriod: Record Date;
        PeriodReportManagement: Codeunit PeriodReportManagement;
        Wnd: Dialog;
        PostingDate: Date;
        DisposalDate: Date;
        Choices: Option ,"Fixed","Temporary";
        Choice: array[4] of Boolean;
        AccountPeriod: Text[30];
#pragma warning disable AA0074
        Text1000: Label 'You must specify Journal Template and Journal Batch.';
#pragma warning restore AA0074
        DocumentNo: Code[20];
        PostingDescription: Text[50];
        Total: Integer;
        Processing: Integer;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text1001: Label 'Processing  #1########\@2@@@@@@@@@@@@@';
#pragma warning restore AA0470
#pragma warning restore AA0074
        TemplateName: Code[10];
        BatchName: Code[10];
        AccountDepreciation: Decimal;
        TaxAccountDepreciation: Decimal;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text1002: Label '%1  is in the last month of the year. Temporary differences posted within accounting period should be transformed to constant differences. Perform required preparations for transformations?';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text1005: Label 'DTD arising %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text12411: Label 'DT-';
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text12410: Label '%1 %2 FE Tax Differences';
#pragma warning restore AA0470
#pragma warning restore AA0074
        AccAcquisCost: Decimal;
        TaxAcquisCost: Decimal;
        CalcTDAcquisCost: Boolean;

    [Scope('OnPrem')]
    procedure SetProperties()
    begin
        PostingDate := DatePeriod."Period End";
        PostingDescription :=
          StrSubstNo(Text12410,
            Format(DatePeriod."Period Start", 0, '<Month Text> '),
            Date2DMY(DatePeriod."Period Start", 3));

        if Date2DMY(DatePeriod."Period Start", 2) > 9 then
            DocumentNo := Text12411 + Format(DatePeriod."Period Start", 0, '<Year>-<Month>')
        else
            DocumentNo := Text12411 + Format(DatePeriod."Period Start", 2, '<Year>') + '-0' + Format(DatePeriod."Period Start", 0, '<Month>');
    end;

    local procedure AccountPeriodOnAfterValidate()
    begin
        SetProperties();
    end;

    [Scope('OnPrem')]
    procedure InitializeRequest(StartDate: Date; EndDate: Date; TaxDiffJnlTemplateName: Code[10]; TaxDiffJnlBatchName: Code[10]; FixedTaxDiff: Boolean; TempTaxDiff: Boolean)
    begin
        DatePeriod."Period Start" := StartDate;
        DatePeriod."Period End" := EndDate;
        TemplateName := TaxDiffJnlTemplateName;
        BatchName := TaxDiffJnlBatchName;
        Choice[Choices::Fixed] := FixedTaxDiff;
        Choice[Choices::"Temporary"] := TempTaxDiff;
    end;
}

