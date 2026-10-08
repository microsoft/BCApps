#pragma warning disable AA0247
report 17207 "Create Norm Details"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Create Norm Details';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Tax Register Norm Jurisdiction"; "Tax Register Norm Jurisdiction")
        {
            DataItemTableView = sorting(Code);
            RequestFilterFields = "Code";
            dataitem(Date; Date)
            {
                DataItemTableView = sorting("Period Type", "Period Start") where("Period Type" = const(Month));

                trigger OnAfterGetRecord()
                begin
                    DateBegin := NormalDate("Period Start");
                    DateEnd := NormalDate("Period End");
                    CreateNormDetails("Tax Register Norm Jurisdiction".Code, DateBegin, DateEnd);
                end;

                trigger OnPreDataItem()
                begin
                    SetRange("Period Type", "Period Type"::Month);
                    SetRange("Period Start", NormalDate(DatePeriod."Period Start"), NormalDate(DatePeriod."Period End"));
                end;
            }

            trigger OnAfterGetRecord()
            begin
                NormTemplateLine.GenerateProfile();
                NormTermName.GenerateProfile();
                Commit();

                TaxRegTermMgt.CheckTaxRegTerm(true, Code,
                  DATABASE::"Tax Reg. Norm Term", DATABASE::"Tax Reg. Norm Term Formula");

                TaxRegTermMgt.CheckTaxRegLink(true, Code,
                  DATABASE::"Tax Reg. Norm Template Line");
            end;

            trigger OnPreDataItem()
            begin
                NormJurisdiction.Copy("Tax Register Norm Jurisdiction");
                if NormJurisdiction.Find('-') then
                    if NormJurisdiction.Next() <> 0 then
                        CurrReport.Quit();
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
        end;
    }

    labels
    {
    }

    var
        NormJurisdiction: Record "Tax Register Norm Jurisdiction";
        NormTermName: Record "Tax Reg. Norm Term";
        NormTemplateLine: Record "Tax Reg. Norm Template Line";
        CalendarPeriod: Record Date;
        DatePeriod: Record Date;
        PeriodReportManagement: Codeunit PeriodReportManagement;
        TaxRegTermMgt: Codeunit "Tax Register Term Mgt.";
        DateBegin: Date;
        DateEnd: Date;
        Periodicity: Option Month,Quarter,Year;
        AccountPeriod: Text[30];
#pragma warning disable AA0074
        Text1001: Label 'Existing details will be delete.\Continue?';
#pragma warning restore AA0074
        DeleteWasConfirmed: Boolean;

    [Scope('OnPrem')]
    procedure CreateNormDetails(NormJurisdictionCode: Code[10]; DateBegin: Date; DateEnd: Date)
    var
        NormGroup: Record "Tax Register Norm Group";
        NormDetail: Record "Tax Register Norm Detail";
        NormTemplateLine: Record "Tax Reg. Norm Template Line";
        NormAccumulat: Record "Tax Reg. Norm Accumulation";
        EntryNoAmountBuffer: Record "Entry No. Amount Buffer" temporary;
        GeneralTermMgt: Codeunit "Tax Register Term Mgt.";
        NormTemplateRecordRef: RecordRef;
        LinkAccumulateRecordRef: RecordRef;
        CycleLevel: Integer;
    begin
        NormGroup.SetRange("Norm Jurisdiction Code", NormJurisdictionCode);
        NormGroup.SetRange("Storing Method", NormGroup."Storing Method"::Calculation);
        LinkAccumulateRecordRef.Open(DATABASE::"Tax Reg. Norm Accumulation");
        NormAccumulat.Init();
        NormAccumulat.SetCurrentKey("Norm Jurisdiction Code", "Norm Group Code", "Template Line No.");
        NormAccumulat.SetRange("Norm Jurisdiction Code", NormJurisdictionCode);
        NormAccumulat.SetRange("Ending Date", DateEnd);
        LinkAccumulateRecordRef.SetView(NormAccumulat.GetView(false));
        NormDetail.SetRange("Norm Jurisdiction Code", NormJurisdictionCode);
        NormDetail.SetRange("Norm Type", NormDetail."Norm Type"::Amount);
        NormDetail.SetFilter("Effective Date", '%1..', DateEnd);
        if NormGroup.FindSet() then
            repeat
                NormDetail.SetRange("Norm Group Code", NormGroup.Code);
                NormAccumulat.SetRange("Norm Group Code", NormGroup.Code);
                NormAccumulat.DeleteAll();
                if NormDetail.FindFirst() then
                    if not DeleteWasConfirmed then begin
                        if not Confirm(Text1001, false) then
                            Error('');
                        DeleteWasConfirmed := true;
                    end;
                NormDetail.DeleteAll(true);
            until NormGroup.Next() = 0;
        NormGroup.SetRange("Storing Method");
        NormTemplateLine.SetRange("Norm Jurisdiction Code", NormJurisdictionCode);
        CycleLevel := 1;
        while CycleLevel <> 0 do begin
            NormGroup.SetRange(Level, CycleLevel);
            if not NormGroup.FindSet() then
                CycleLevel := 0
            else begin
                repeat
                    if NormGroup."Storing Method" = NormGroup."Storing Method"::Calculation then begin
                        NormTemplateLine.SetRange("Norm Group Code", NormGroup.Code);
                        if NormTemplateLine.FindFirst() then begin
                            NormTemplateLine.SetRange("Date Filter", DateBegin, DateEnd);
                            NormTemplateRecordRef.GetTable(NormTemplateLine);
                            NormTemplateRecordRef.SetView(NormTemplateLine.GetView(false));
                            GeneralTermMgt.AccumulateTaxRegTemplate(
                              NormTemplateRecordRef, EntryNoAmountBuffer, LinkAccumulateRecordRef);

                            NormDetail.Init();
                            NormDetail."Norm Jurisdiction Code" := NormGroup."Norm Jurisdiction Code";
                            NormDetail."Norm Group Code" := NormGroup.Code;
                            NormDetail."Norm Type" := NormDetail."Norm Type"::Amount;
                            NormDetail."Effective Date" := DateEnd;

                            if CreateAccumulate(NormTemplateLine, EntryNoAmountBuffer, NormDetail.Norm) then
                                NormDetail.Insert();

                            EntryNoAmountBuffer.DeleteAll();
                        end;
                    end;
                until NormGroup.Next() = 0;
                CycleLevel += 1;
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateAccumulate(var NormTemplateLine: Record "Tax Reg. Norm Template Line"; var EntryNoAmountBuffer: Record "Entry No. Amount Buffer"; var NormValue: Decimal) RetCode: Boolean
    var
        NormTemplateLine0: Record "Tax Reg. Norm Template Line";
        NormAccumulat: Record "Tax Reg. Norm Accumulation";
        NormAccumulat0: Record "Tax Reg. Norm Accumulation";
        NormAccumulat1: Record "Tax Reg. Norm Accumulation";
        GeneralTermMgt: Codeunit "Tax Register Term Mgt.";
    begin
        RetCode := EntryNoAmountBuffer.Find('-');
        if RetCode then begin
            NormAccumulat."Starting Date" := NormTemplateLine.GetRangeMin("Date Filter");
            NormAccumulat."Ending Date" := NormTemplateLine.GetRangeMax("Date Filter");
            NormAccumulat."Norm Jurisdiction Code" := NormTemplateLine."Norm Jurisdiction Code";
            NormAccumulat."Norm Group Code" := NormTemplateLine."Norm Group Code";
            repeat
                NormTemplateLine0.Get(
                  NormAccumulat."Norm Jurisdiction Code", NormAccumulat."Norm Group Code", EntryNoAmountBuffer."Entry No.");
                NormAccumulat."Template Line Code" := NormTemplateLine0."Line Code";
                NormAccumulat.Indentation := NormTemplateLine0.Indentation;
                NormAccumulat.Bold := NormTemplateLine0.Bold;
                NormAccumulat.Description := NormTemplateLine0.Description;
                NormAccumulat."Template Line No." := NormTemplateLine0."Line No.";
                NormAccumulat."Amount Date Filter" :=
                  GeneralTermMgt.CalcIntervalDate(
                    NormAccumulat."Starting Date",
                    NormAccumulat."Ending Date",
                    NormTemplateLine0.Period);

                NormAccumulat.Amount := EntryNoAmountBuffer.Amount;
                NormAccumulat."Amount Period" := NormAccumulat.Amount;

                if not NormAccumulat0.FindLast() then
                    NormAccumulat0."Entry No." := 0;
                NormAccumulat."Entry No." := NormAccumulat0."Entry No." + 1;
                NormAccumulat.Insert();

                if NormTemplateLine0.Period <> '' then begin
                    NormAccumulat1 := NormAccumulat;
                    NormAccumulat1.Reset();
                    NormAccumulat1.SetCurrentKey(
                      "Norm Jurisdiction Code", "Norm Group Code", "Template Line No.", "Starting Date", "Ending Date");
                    NormAccumulat1.SetRange("Norm Jurisdiction Code", NormAccumulat."Norm Jurisdiction Code");
                    NormAccumulat1.SetRange("Norm Group Code", NormAccumulat."Norm Group Code");
                    NormAccumulat1.SetRange("Template Line No.", NormAccumulat."Template Line No.");
                    NormAccumulat1.SetFilter("Starting Date", NormAccumulat."Amount Date Filter");
                    NormAccumulat1.SetFilter("Ending Date", NormAccumulat."Amount Date Filter");
                    NormAccumulat1.CalcSums("Amount Period");
                    NormAccumulat.Amount := NormAccumulat1."Amount Period";
                    NormAccumulat.Modify();
                end;

                if NormTemplateLine0."Line Type" = NormTemplateLine0."Line Type"::"Norm Value" then
                    NormValue := NormAccumulat.Amount;
                RetCode := RetCode and (NormTemplateLine0."Line Type" <> NormTemplateLine0."Line Type"::"Amount for Norm");

            until EntryNoAmountBuffer.Next(1) = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure SetPeriod(NewDate: Date)
    begin
        if NewDate <> 0D then begin
            Periodicity := Periodicity::Month;
            CalendarPeriod.Get(CalendarPeriod."Period Type"::Month, CalcDate('<-CM>', NewDate));
            DatePeriod.Copy(CalendarPeriod);
            PeriodReportManagement.PeriodSetup(DatePeriod, false);
        end;
    end;
}

