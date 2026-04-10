#pragma warning disable AA0247
page 17328 "Tax Calc. Create"
{
    Caption = 'Tax Calc. Create';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Card;
    SourceTable = "Tax Calc. Section";
    SourceTableView = where(Status = filter(Open | Statement));

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(Period; Periodicity)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Periodicity';
                    OptionCaption = 'Month,Quarter,Year';
                    ToolTip = 'Specifies if the accounting period is Month, Quarter, or Year.';

                    trigger OnValidate()
                    begin
                        TaxCalcMgt.InitTaxPeriod(CalendarPeriod, Periodicity, Rec."Starting Date");
                        AccountPeriod := '';
                        TaxCalcMgt.SetCaptionPeriodAndYear(AccountPeriod, CalendarPeriod);
                        DatePeriod.Copy(CalendarPeriod);
                        TaxCalcMgt.PeriodSetup(DatePeriod);
                    end;
                }
                field(AccountingPeriod; AccountPeriod)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Accounting Period';
                    ToolTip = 'Specifies the accounting period to include data for.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        TaxCalcMgt.SelectPeriod(Text, CalendarPeriod);
                        DatePeriod.Copy(CalendarPeriod);
                        TaxCalcMgt.PeriodSetup(DatePeriod);
                        CurrPage.Update();
                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        DatePeriod.Copy(CalendarPeriod);
                        TaxCalcMgt.PeriodSetup(DatePeriod);
                    end;
                }
                field(From; DatePeriod."Period Start")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'From';
                    ToolTip = 'Specifies the starting point.';
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
                field("To"; DatePeriod."Period End")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'To';
                    ToolTip = 'Specifies the ending point.';
                }
                field("Last G/L Entries Date"; Rec."Last G/L Entries Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date of the last general ledger entry associated with the tax calculation section.';
                }
                field("Last Item Entries Date"; Rec."Last Item Entries Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date of the last item entry associated with the tax calculation section.';
                }
                field("Last FA Entries Date"; Rec."Last FA Entries Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date of the last fixed asset entry associated with the tax calculation section.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the status of the tax calculation section.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the start date associated with the tax calculation section.';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the end date associated with the tax calculation section.';
                }
                field("No G/L Entries Date"; Rec."No G/L Entries Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger entry date associated with the tax calculation section.';
                }
                field("No Item Entries Date"; Rec."No Item Entries Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the item entry date associated with the tax calculation section.';
                }
                field("No FA Entries Date"; Rec."No FA Entries Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the fixed asset entry date associated with the tax calculation section.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        TaxCalcMgt.InitTaxPeriod(CalendarPeriod, Periodicity,
          TaxCalcMgt.GetNextAvailableBeginDate(Rec.Code, DATABASE::"Tax Calc. Accumulation", true));
        TaxCalcMgt.SetCaptionPeriodAndYear(AccountPeriod, CalendarPeriod);
        DatePeriod.Copy(CalendarPeriod);
        TaxCalcMgt.PeriodSetup(DatePeriod);

        Rec.SetRecFilter();
    end;

    var
        CalendarPeriod: Record Date;
        DatePeriod: Record Date;
        TaxCalcMgt: Codeunit "Tax Calc. Mgt.";
        Periodicity: Option Month,Quarter,Year;
        AccountPeriod: Text[30];
        UseGLEntry: Boolean;
        UseFAEntry: Boolean;
        UseItemEntry: Boolean;
        UseTemplate: Boolean;

    [Scope('OnPrem')]
    procedure ReturnChoices(var UseGLEntry2: Boolean; var UseFAEntry2: Boolean; var UseItemEntry2: Boolean; var UseTemplate2: Boolean; var UserDatePeriod: Record Date)
    begin
        UseGLEntry2 := UseGLEntry;
        UseFAEntry2 := UseFAEntry;
        UseItemEntry2 := UseItemEntry;
        UseTemplate2 := UseTemplate;
        UserDatePeriod := DatePeriod;
    end;
}

