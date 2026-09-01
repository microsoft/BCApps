#pragma warning disable AA0247
report 17204 "Create Tax Registers"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Create Tax Registers';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Tax Register Section"; "Tax Register Section")
        {
            DataItemTableView = sorting(Code);
            RequestFilterFields = "Code";
            dataitem(Date; Date)
            {
                DataItemTableView = sorting("Period Type", "Period Start") where("Period Type" = const(Month));

                trigger OnAfterGetRecord()
                begin
                    StartDate := NormalDate("Period Start");
                    EndDate := NormalDate("Period End");

                    case true of
                        UseGLEntries:
                            CreateTaxRegGLEntry.CreateRegister("Tax Register Section".Code, StartDate, EndDate);
                        UseItemEntries:
                            CreateTaxRegItemEntry.CreateRegister("Tax Register Section".Code, StartDate, EndDate);
                        UseCVEntries:
                            CreateTaxRegCVEntry.CreateRegister("Tax Register Section".Code, StartDate, EndDate);
                        UseFAEntries:
                            CreateTaxRegFAEntry.CreateRegister("Tax Register Section".Code, StartDate, EndDate);
                        UseFEEntries:
                            CreateTaxRegFEEntry.CreateRegister("Tax Register Section".Code, StartDate, EndDate);
                        UseTemplates:
                            begin
                                LinkAccumulateRecordRef.Open(DATABASE::"Tax Register Accumulation");
                                TaxRegAccumulation.Reset();
                                TaxRegAccumulation.SetCurrentKey("Section Code", "Tax Register No.", "Template Line No.");
                                TaxRegAccumulation.SetRange("Section Code", "Tax Register Section".Code);
                                TaxRegAccumulation.SetRange("Ending Date", EndDate);
                                LinkAccumulateRecordRef.SetView(GetView(false));
                                CycleLevel := 1;
                                while CycleLevel <> 0 do begin
                                    TaxReg.SetRange(Level, CycleLevel);
                                    TaxReg.SetRange("Section Code", "Tax Register Section".Code);
                                    if not TaxReg.FindSet() then
                                        CycleLevel := 0
                                    else begin
                                        repeat
                                            if TaxReg."Storing Method" = TaxReg."Storing Method"::Calculation then begin
                                                TaxRegAccumulation.SetRange("Tax Register No.", TaxReg."No.");
                                                TaxRegAccumulation.DeleteAll();
                                                TaxRegTemplate.SetRange(Code, TaxReg."No.");
                                                if TaxRegTemplate.FindFirst() then begin
                                                    TaxRegTemplate.SetRange("Section Code", "Tax Register Section".Code);
                                                    TaxRegTemplate.SetRange("Date Filter", StartDate, EndDate);
                                                    TemplateRecordRef.GetTable(TaxRegTemplate);
                                                    TemplateRecordRef.SetView(TaxRegTemplate.GetView(false));
                                                    TaxRegTermMgt.AccumulateTaxRegTemplate(
                                                      TemplateRecordRef, EntryNoAmountBuffer, LinkAccumulateRecordRef);
                                                    EntryNoAmountBuffer.DeleteAll();
                                                end;
                                            end;
                                        until TaxReg.Next() = 0;
                                        CycleLevel += 1;
                                    end;
                                end;
                            end;
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    SetRange("Period Type", "Period Type"::Month);
                    SetRange("Period Start", NormalDate(DatePeriod."Period Start"), NormalDate(DatePeriod."Period End"));
                end;
            }

            trigger OnAfterGetRecord()
            begin
                TaxRegTermMgt.CheckTaxRegTerm(true, Code,
                  DATABASE::"Tax Register Term", DATABASE::"Tax Register Term Formula");

                TaxRegTermMgt.CheckTaxRegLink(true, Code,
                  DATABASE::"Tax Register Template");

                CreateTaxRegGLEntry.BuildTaxRegGLCorresp(
                  Code, CalcDate('<-CM>', NormalDate(DatePeriod."Period Start")), CalcDate('<CM>', NormalDate(DatePeriod."Period End")));
            end;

            trigger OnPreDataItem()
            begin
                if GetRangeMin(Code) <> GetRangeMax(Code) then
                    Error(Text1000);

                TestField(Status, Status::Open);
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
                    field(Periodicity; Periodicity)
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
                    field(UseTemplates; UseTemplates)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Templates';
                    }
                    field(UseGLEntries; UseGLEntries)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'G/L Entries';
                        ToolTip = 'Specifies the related general ledger entries.';
                    }
                    field(UseItemEntries; UseItemEntries)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Items';
                    }
                    field(UseCVEntries; UseCVEntries)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Vendors/Customers';
                    }
                    field(UseFAEntries; UseFAEntries)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Fixed Assets';
                        ToolTip = 'Specifies entries that relate to fixed assets.';
                    }
                    field(UseFEEntries; UseFEEntries)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Future Expences';
                    }
                    field(UsePREntries; UsePREntries)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payroll Entries';
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

            UseItemEntries := true;
            UseCVEntries := true;
            UseGLEntries := true;
            UseFAEntries := true;
            UseFEEntries := true;
            UseTemplates := true;
            UsePREntries := true;
        end;
    }

    labels
    {
    }

    var
        TaxReg: Record "Tax Register";
        TaxRegTemplate: Record "Tax Register Template";
        TaxRegAccumulation: Record "Tax Register Accumulation";
        EntryNoAmountBuffer: Record "Entry No. Amount Buffer";
        CalendarPeriod: Record Date;
        DatePeriod: Record Date;
        CreateTaxRegItemEntry: Codeunit "Create Tax Register Item Entry";
        CreateTaxRegFEEntry: Codeunit "Create Tax Register FE Entry";
        CreateTaxRegCVEntry: Codeunit "Create Tax Register CV Entry";
        CreateTaxRegGLEntry: Codeunit "Create Tax Register GL Entry";
        CreateTaxRegFAEntry: Codeunit "Create Tax Register FA Entry";
        TaxRegTermMgt: Codeunit "Tax Register Term Mgt.";
        PeriodReportManagement: Codeunit PeriodReportManagement;
        TemplateRecordRef: RecordRef;
        LinkAccumulateRecordRef: RecordRef;
        StartDate: Date;
        EndDate: Date;
        UseTemplates: Boolean;
        UseGLEntries: Boolean;
        UseFEEntries: Boolean;
        UseCVEntries: Boolean;
        UseFAEntries: Boolean;
        UseItemEntries: Boolean;
        UsePREntries: Boolean;
        Periodicity: Option Month,Quarter,Year;
        AccountPeriod: Text[30];
        CycleLevel: Integer;
#pragma warning disable AA0074
        Text1000: Label 'There is no filter for Section Code. Continue?';
#pragma warning restore AA0074
}

