#pragma warning disable AA0247
report 17301 "Calculate Tax Diff. for Calc."
{
    ApplicationArea = Basic, Suite;
    Caption = 'Calculate Tax Diff. for Calc.';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Tax Calc. Section"; "Tax Calc. Section")
        {
            DataItemTableView = sorting(Code);
            MaxIteration = 1;
            RequestFilterFields = "Code";
            dataitem("Tax Calc. Header"; "Tax Calc. Header")
            {
                DataItemLink = "Section Code" = field(Code);
                DataItemTableView = sorting("Section Code", "Tax Diff. Code") where("Tax Diff. Code" = filter(<> ''), "Storing Method" = const("Build Entry"));

                trigger OnAfterGetRecord()
                begin
                    Processing += 1;
                    Wnd.Update(1, "No.");
                    Wnd.Update(2, Round((Processing / Total) * 10000, 1));
                    if not TaxDiff.Get("Tax Diff. Code") then
                        CurrReport.Skip();

                    AmountBase := 0;
                    AmountTax := 0;
                    DisposedFixedAsset := false;
                    TaxDiffEntry.SetCurrentKey("Tax Diff. Code", "Source Type", "Source No.", "Posting Date");
                    TaxDiffEntry.SetRange("Tax Diff. Code", "Tax Diff. Code");
                    TaxDiffEntry.SetRange("Posting Date", NormalDate(DatePeriod."Period Start"), NormalDate(DatePeriod."Period End"));
                    TaxDiffEntry.CalcSums("Amount (Base)", "Amount (Tax)");
                    TaxCalcAccum.SetRange("Register No.", "No.");
                    TaxCalcAccum.SetRange("Tax Diff. Amount (Base)", true);
                    if TaxCalcAccum.FindFirst() then begin
                        AmountBase := TaxCalcAccum.Amount - TaxDiffEntry."Amount (Base)";
                        DisposedFixedAsset := TaxCalcAccum.Disposed;
                    end;
                    TaxCalcAccum.SetRange("Tax Diff. Amount (Base)");
                    TaxCalcAccum.SetRange("Tax Diff. Amount (Tax)", true);
                    if TaxCalcAccum.FindFirst() then begin
                        AmountTax := TaxCalcAccum.Amount - TaxDiffEntry."Amount (Tax)";
                        DisposedFixedAsset := DisposedFixedAsset or TaxCalcAccum.Disposed;
                    end;
                    TaxCalcAccum.SetRange("Tax Diff. Amount (Tax)");

                    if (DisposalDate = 0D) or (TaxDiff."Tax Period Limited" = TaxDiff."Tax Period Limited"::" ") then
                        if (AmountBase = 0) and (AmountTax = 0) then
                            CurrReport.Skip();

                    if (AmountBase = 0) and (AmountTax = 0) then
                        if DisposedFixedAsset or (TaxDiff."Calculation Mode" <> TaxDiff."Calculation Mode"::Balance) then
                            CurrReport.Skip();

                    TaxDiffJnlLine."Line No." += 10000;
                    TaxDiffJnlLine.Init();
                    TaxDiffJnlLine.SetUpNewLine(TaxDiffJnlLine);
                    TaxDiffJnlLine."Posting Date" := PostingDate;
                    if TaxDiffJnlLine."Document No." = '' then
                        TaxDiffJnlLine."Document No." := DocumentNo;
                    TaxDiffJnlLine.Description := CopyStr(Description, 1, MaxStrLen(TaxDiffJnlLine.Description));
                    TaxDiffJnlLine.Validate("Tax Diff. Code", TaxDiff.Code);
                    TaxDiffJnlLine.Validate("Tax Diff. Calc. Mode", TaxDiff."Calculation Mode");
                    if DisposedFixedAsset then begin
                        TaxDiffJnlLine."Partial Disposal" := true;
                        TaxDiffJnlLine."Disposal Mode" := TaxDiffJnlLine."Disposal Mode"::"Write Down";
                        TaxDiffJnlLine."Amount (Base)" := Abs(AmountBase);
                        TaxDiffJnlLine.Validate("Amount (Tax)", Abs(AmountTax));
                    end else
                        if TaxDiff."Calculation Mode" = TaxDiff."Calculation Mode"::Balance then begin
                            if (AmountBase = 0) and (AmountTax = 0) then
                                TaxDiffJnlLine."Tax Diff. Calc. Mode" := TaxDiffJnlLine."Tax Diff. Calc. Mode"::Balance;
                            TaxDiffJnlLine."YTD Amount (Base)" := Abs(AmountBase);
                            TaxDiffJnlLine.Validate("YTD Amount (Tax)", Abs(AmountTax));
                            if (TaxDiff."Tax Period Limited" <> TaxDiff."Tax Period Limited"::" ") and (DisposalDate <> 0D) then begin
                                TaxDiffJnlLine."Disposal Mode" := TaxDiffJnlLine."Disposal Mode"::Transform;
                                TaxDiffJnlLine."Disposal Date" := DisposalDate;
                                TaxDiffJnlLine.Validate("Tax Diff. Calc. Mode", TaxDiffJnlLine."Tax Diff. Calc. Mode"::" ");
                            end;
                        end else begin
                            TaxDiffJnlLine."Amount (Base)" := Abs(AmountBase);
                            TaxDiffJnlLine.Validate("Amount (Tax)", Abs(AmountTax));
                        end;
                    TaxDiffJnlLine.Insert();
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

            trigger OnAfterGetRecord()
            begin
                TaxCalcAccum.SetRange("Section Code", Code);
            end;

            trigger OnPreDataItem()
            begin
                TaxCalcAccum.SetCurrentKey("Section Code", "Register No.");
                TaxCalcAccum.SetRange("Ending Date", NormalDate(DatePeriod."Period End"));
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
                    field("ÅÑÓ¿«ñ¿þ¡«ßÔý"; Periodicity)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Periodicity';
                        OptionCaption = 'Month,Quarter,Year';
                        ToolTip = 'Specifies if the accounting period is Month, Quarter, or Year.';

                        trigger OnValidate()
                        begin
                            PeriodReportManagement.InitPeriod(CalendarPeriod, Periodicity);
                            AccountPeriod := '';
                            PeriodReportManagement.SetCaptionPeriodYear(AccountPeriod, CalendarPeriod, false);
                            DatePeriod.Copy(CalendarPeriod);
                            PeriodReportManagement.PeriodSetup(DatePeriod, false);
                            PeriodicityOnAfterValidate();
                        end;
                    }
                    field("ÄÔþÑÔ¡Ù® »ÑÓ¿«ñ"; AccountPeriod)
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
                    field("ß"; DatePeriod."Period Start")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'From';
                        Editable = false;
                        ToolTip = 'Specifies the starting point.';
                    }
                    field("»«"; DatePeriod."Period End")
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
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            PeriodReportManagement.InitPeriod(CalendarPeriod, Periodicity);
            PeriodReportManagement.SetCaptionPeriodYear(AccountPeriod, CalendarPeriod, false);
            DatePeriod.Copy(CalendarPeriod);
            PeriodReportManagement.PeriodSetup(DatePeriod, false);

            SetProperties();
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        if (TemplateName = '') or
           (BatchName = '')
        then
            Error(Text1000);

        TaxDiffJnlLine."Journal Template Name" := TemplateName;
        TaxDiffJnlLine."Journal Batch Name" := BatchName;
        TaxDiffJnlLine.SetRange("Journal Template Name", TaxDiffJnlLine."Journal Template Name");
        TaxDiffJnlLine.SetRange("Journal Batch Name", TaxDiffJnlLine."Journal Batch Name");
        if not TaxDiffJnlLine.FindLast() then
            TaxDiffJnlLine."Line No." := 0;

        DisposalDate := 0D;
        if CalcDate('<CM>', PostingDate) = CalcDate('<CY>', PostingDate) then
            DisposalDate := CalcDate('<CM>', PostingDate);

        if DisposalDate <> 0D then
            if not Confirm(Text1002 + Text1003 + Text1004, true, TaxDiffJnlLine.FieldCaption("Posting Date")) then
                DisposalDate := 0D;

        SetProperties();
    end;

    var
        TaxDiffJnlBatch: Record "Tax Diff. Journal Batch";
        TaxDiffJnlLine: Record "Tax Diff. Journal Line";
        TaxDiff: Record "Tax Difference";
        TaxCalcAccum: Record "Tax Calc. Accumulation";
        CalendarPeriod: Record Date;
        DatePeriod: Record Date;
        TaxDiffEntry: Record "Tax Diff. Ledger Entry";
        PeriodReportManagement: Codeunit PeriodReportManagement;
        Wnd: Dialog;
        PostingDate: Date;
        DisposalDate: Date;
        Periodicity: Option Month,Quarter,Year;
        AccountPeriod: Text[30];
#pragma warning disable AA0074
        Text1000: Label 'You must specify Journal Template and Journal Batch.';
#pragma warning restore AA0074
        DocumentNo: Code[20];
        Total: Integer;
        Processing: Integer;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text1001: Label 'Processing  #1########\@2@@@@@@@@@@@@@';
#pragma warning restore AA0470
#pragma warning restore AA0074
        TemplateName: Code[10];
        BatchName: Code[10];
        AmountBase: Decimal;
        AmountTax: Decimal;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text1002: Label '%1 is in last month of the year then transformation should be made';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text1003: Label 'to constant temporary differencies posted within accounting period.\';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text1004: Label 'Perform required preparations for transformations?';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text12411: Label 'DT-';
#pragma warning restore AA0074
        DisposedFixedAsset: Boolean;

    [Scope('OnPrem')]
    procedure SetProperties()
    begin
        PostingDate := DatePeriod."Period End";
        if Date2DMY(DatePeriod."Period Start", 2) > 9 then
            DocumentNo := Text12411 + Format(DatePeriod."Period Start", 0, '<Year>-<Month>')
        else
            DocumentNo := Text12411 + Format(DatePeriod."Period Start", 2, '<Year>') + '-0' + Format(DatePeriod."Period Start", 0, '<Month>');
    end;

    local procedure AccountPeriodOnAfterValidate()
    begin
        SetProperties();
    end;

    local procedure PeriodicityOnAfterValidate()
    begin
        SetProperties();
    end;
}

