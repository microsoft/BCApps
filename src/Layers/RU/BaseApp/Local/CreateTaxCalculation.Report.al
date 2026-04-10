#pragma warning disable AA0247
report 17309 "Create Tax Calculation"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Create Tax Calculation';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Tax Calc. Section"; "Tax Calc. Section")
        {
            RequestFilterFields = "Code";

            trigger OnAfterGetRecord()
            begin
                TaxCalcMgt.CreateTaxCalcForPeriod(Code, UseGLEntry, UseFAEntry, UseItemEntry, UseTemplate, CalendarPeriod);
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    group(Period)
                    {
                        Caption = 'Period';
                        field(Periodicity; Periodicity)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Periodicity';
                            OptionCaption = 'Month,Quarter,Year';
                            ToolTip = 'Specifies if the accounting period is Month, Quarter, or Year.';

                            trigger OnValidate()
                            begin
                                TaxCalcMgt.InitTaxPeriod(CalendarPeriod, Periodicity, WorkDate());
                                AccountPeriod := '';
                                TaxCalcMgt.SetCaptionPeriodAndYear(AccountPeriod, CalendarPeriod);
                                DatePeriod.Copy(CalendarPeriod);
                                TaxCalcMgt.PeriodSetup(DatePeriod);
                            end;
                        }
                        field(AccountPeriod; AccountPeriod)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Accounting Period';
                            ToolTip = 'Specifies the accounting period to include data for.';

                            trigger OnLookup(var Text: Text): Boolean
                            begin
                                TaxCalcMgt.SelectPeriod(Text, CalendarPeriod);
                                DatePeriod.Copy(CalendarPeriod);
                                TaxCalcMgt.PeriodSetup(DatePeriod);
                                RequestOptionsPage.Update();
                                exit(true);
                            end;

                            trigger OnValidate()
                            begin
                                DatePeriod.Copy(CalendarPeriod);
                                TaxCalcMgt.PeriodSetup(DatePeriod);
                            end;
                        }
                        field("DatePeriod.""Period Start"""; DatePeriod."Period Start")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'From';
                            ToolTip = 'Specifies the starting point.';
                        }
                        field("DatePeriod.""Period End"""; DatePeriod."Period End")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'To';
                            ToolTip = 'Specifies the ending point.';
                        }
                    }
                    field(UseGLEntry; UseGLEntry)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'G/L Entries';
                        ToolTip = 'Specifies the related general ledger entries.';
                    }
                    field(UseItemEntry; UseItemEntry)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Item Entries';
                    }
                    field(UseFAEntry; UseFAEntry)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'FA Entries';
                        ToolTip = 'Specifies entries that relate to fixed assets.';
                    }
                    field(UseTemplate; UseTemplate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Templates';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if HiddenStartDate <> 0D then
                TaxCalcMgt.InitTaxPeriod(CalendarPeriod, Periodicity, HiddenStartDate)
            else
                TaxCalcMgt.InitTaxPeriod(CalendarPeriod, Periodicity, WorkDate());
            TaxCalcMgt.SetCaptionPeriodAndYear(AccountPeriod, CalendarPeriod);
            DatePeriod.Copy(CalendarPeriod);
            TaxCalcMgt.PeriodSetup(DatePeriod);
        end;
    }

    labels
    {
    }

    var
        CalendarPeriod: Record Date;
        DatePeriod: Record Date;
        TaxCalcMgt: Codeunit "Tax Calc. Mgt.";
        HiddenStartDate: Date;
        Periodicity: Option Month,Quarter,Year;
        AccountPeriod: Text[30];
        UseGLEntry: Boolean;
        UseFAEntry: Boolean;
        UseItemEntry: Boolean;
        UseTemplate: Boolean;

    [Scope('OnPrem')]
    procedure SetPeriodStart(NewStartDate: Date)
    begin
        HiddenStartDate := NewStartDate;
    end;
}

