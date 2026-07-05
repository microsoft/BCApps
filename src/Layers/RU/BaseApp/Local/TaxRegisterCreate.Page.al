#pragma warning disable AA0247
page 17236 "Tax Register Create"
{
    Caption = 'Tax Register Create';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Card;
    SourceTable = "Tax Register Section";
    SourceTableView = where(Status = filter(Open | Reporting));

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(Periodicity; Periodicity)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Periodicity';
                    OptionCaption = 'Month,Quarter,Year';
                    ToolTip = 'Specifies if the accounting period is Month, Quarter, or Year.';

                    trigger OnValidate()
                    begin
                        TaxRegMgt.InitTaxPeriod(CalendarPeriod, Periodicity, Rec."Starting Date");
                        AccountPeriod := '';
                        TaxRegMgt.SetCaptionPeriodAndYear(AccountPeriod, CalendarPeriod);
                        DatePeriod.Copy(CalendarPeriod);
                        TaxRegMgt.PeriodSetup(DatePeriod);
                    end;
                }
                field(AccountPeriod; AccountPeriod)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Accounting Period';
                    ToolTip = 'Specifies the accounting period to include data for.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        TaxRegMgt.SelectPeriod(Text, CalendarPeriod);
                        DatePeriod.Copy(CalendarPeriod);
                        TaxRegMgt.PeriodSetup(DatePeriod);
                        CurrPage.Update();
                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        DatePeriod.Copy(CalendarPeriod);
                        TaxRegMgt.PeriodSetup(DatePeriod);
                    end;
                }
                field("DatePeriod.""Period Start"""; DatePeriod."Period Start")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'From';
                    ToolTip = 'Specifies the starting point.';
                }
                field("Choice[Choices::""G/L Entry""]"; Choice[Choices::"G/L Entry"])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'G/L Entries';
                    ToolTip = 'Specifies the related general ledger entries.';
                }
                field("Choice[Choices::""Vend./Cust.""]"; Choice[Choices::"Vend./Cust."])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendor/Customer Entries';
                }
                field("Choice[Choices::Item]"; Choice[Choices::Item])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item Entries';
                }
                field("Choice[Choices::FA]"; Choice[Choices::FA])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Fixed Asset Entries';
                    ToolTip = 'Specifies entries that relate to fixed assets.';
                }
                field("Choice[Choices::""Fut. Exp.""]"; Choice[Choices::"Fut. Exp."])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Future Expense Entries';
                }
                field("Choice[Choices::Employee]"; Choice[Choices::Employee])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payroll Entries';
                }
                field("Choice[Choices::Template]"; Choice[Choices::Template])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Templates';
                }
                field("DatePeriod.""Period End"""; DatePeriod."Period End")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'To';
                    ToolTip = 'Specifies the ending point.';
                }
                field("Last GL Entries Date"; Rec."Last GL Entries Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last general ledger entry date for the tax register section.';
                }
                field("Last CV Entries Date"; Rec."Last CV Entries Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last creditor or debtor entry date for the tax register section.';
                }
                field("Last Item Entries Date"; Rec."Last Item Entries Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last item entry date for the tax register section.';
                }
                field("Last FA Entries Date"; Rec."Last FA Entries Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last fixed asset entry date for the tax register section.';
                }
                field("Last FE Entries Date"; Rec."Last FE Entries Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last future expenses entry date for the tax register section.';
                }
                field("Last PR Entries Date"; Rec."Last PR Entries Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last payroll entry date for the tax register section.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the status associated with the tax register section.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the start date associated with the tax register section.';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the end date associated with the tax register section.';
                }
                field("Absence GL Entries Date"; Rec."Absence GL Entries Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when general ledger entries were not available for the tax register section.';
                }
                field("Absence CV Entries Date"; Rec."Absence CV Entries Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when credit or debtor entries were not available for the tax register section.';
                }
                field("Absence Item Entries Date"; Rec."Absence Item Entries Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when item entries were not available for the tax register section.';
                }
                field("Absence FA Entries Date"; Rec."Absence FA Entries Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when fixed asset entries were not available for the tax register section.';
                }
                field("Absence FE Entries Date"; Rec."Absence FE Entries Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when future expense entries were not available for the tax register section.';
                }
                field("Absence PR Entries Date"; Rec."Absence PR Entries Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when payroll entries were not available for the tax register section.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        TaxRegMgt.InitTaxPeriod(CalendarPeriod, Periodicity,
          TaxRegMgt.GetNextAvailableBeginDate(Rec.Code, DATABASE::"Tax Register Accumulation", true));
        TaxRegMgt.SetCaptionPeriodAndYear(AccountPeriod, CalendarPeriod);
        DatePeriod.Copy(CalendarPeriod);
        TaxRegMgt.PeriodSetup(DatePeriod);

        Rec.SetRecFilter();
    end;

    trigger OnOpenPage()
    begin
        Choice[Choices::Employee] := false;

        Choice[Choices::Item] := true;
        Choice[Choices::Employee] := true;
        Choice[Choices::"Vend./Cust."] := true;
        Choice[Choices::"G/L Entry"] := true;
        Choice[Choices::FA] := true;
        Choice[Choices::"Fut. Exp."] := true;
        Choice[Choices::Template] := true;
    end;

    var
        CalendarPeriod: Record Date;
        DatePeriod: Record Date;
        TaxRegMgt: Codeunit "Tax Register Mgt.";
        Choices: Option ,Item,Employee,"Vend./Cust.","G/L Entry",FA,"Fut. Exp.",Template;
        Choice: array[10] of Boolean;
        Periodicity: Option Month,Quarter,Year;
        AccountPeriod: Text[30];

    [Scope('OnPrem')]
    procedure ReturnChoices(var UserChoice: array[10] of Boolean; var UserDatePeriod: Record Date)
    begin
        CopyArray(UserChoice, Choice, 1);
        UserDatePeriod := DatePeriod;
    end;
}

