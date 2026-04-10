#pragma warning disable AA0247
page 12407 "Vendor G/L Turnover"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Vendor G/L Turnover';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SaveValues = true;
    SourceTable = Vendor;
    SourceTableView = sorting("Vendor Type");
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            group(Options)
            {
                Caption = 'Options';
                field(PeriodType; PeriodType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'View by';
                    ToolTip = 'Specifies by which period amounts are displayed.';

                    trigger OnValidate()
                    begin
                        FindPeriod('');
                        CurrPage.Update();
                    end;
                }
            }
            repeater(Control5)
            {
                Editable = false;
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the related record.';
                }
                field("Vendor Posting Group"; Rec."Vendor Posting Group")
                {
                    ToolTip = 'Specifies the vendor''s market type to link business transactions made for the vendor with the appropriate account in the general ledger.';
                    Visible = false;
                }
                field("G/L Starting Balance"; Rec."G/L Starting Balance")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Caption = 'Starting Balance';
                    ToolTip = 'Specifies the general ledger starting balance associated with the vendor.';
                }
                field("G/L Debit Amount"; Rec."G/L Debit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    BlankNumbers = BlankZero;
                    Caption = 'Debit Amount (LCY)';
                    ToolTip = 'Specifies the general ledger debit amount associated with the vendor.';
                }
                field("G/L Credit Amount"; Rec."G/L Credit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    BlankNumbers = BlankZero;
                    Caption = 'Credit Amount (LCY)';
                    ToolTip = 'Specifies the general ledger credit amount associated with the vendor.';
                }
                field("G/L Balance to Date"; Rec."G/L Balance to Date")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Caption = 'Ending Balance';
                    ToolTip = 'Specifies the general ledger balance to date associated with the vendor.';
                }
                field("G/L Net Change"; Rec."G/L Net Change")
                {
                    BlankZero = true;
                    Caption = 'Net Change (LCY)';
                    ToolTip = 'Specifies the general ledger net change associated with the vendor.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Vendor")
            {
                Caption = '&Vendor';
                Image = Vendor;
                action(Card)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    ShortCutKey = 'Shift+F7';

                    trigger OnAction()
                    begin
                        Vendor.Copy(Rec);
                        case Rec."Vendor Type" of
                            Rec."Vendor Type"::Vendor:
                                PAGE.Run(PAGE::"Vendor Card", Vendor);
                            Rec."Vendor Type"::"Resp. Employee":
                                PAGE.Run(PAGE::"Resp. Employee Card", Vendor);
                            Rec."Vendor Type"::"Tax Authority":
                                PAGE.Run(PAGE::"Tax Authority/Fund Card", Vendor);
                        end;
                    end;
                }
                action("A&greements")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'A&greements';
                    Image = Agreement;
                    RunObject = Page "Vendor G/L Turnover Agr.";
                    RunPageLink = "Vendor No." = field("No."),
                                  "Global Dimension 1 Filter" = field(filter("Global Dimension 1 Filter")),
                                  "Global Dimension 2 Filter" = field(filter("Global Dimension 2 Filter")),
                                  "Date Filter" = field(filter("Date Filter")),
                                  "G/L Account Filter" = field(filter("G/L Account Filter")),
                                  "G/L Starting Date Filter" = field(filter("G/L Starting Date Filter"));
                    ShortCutKey = 'Shift+F11';
                }
            }
        }
        area(processing)
        {
            action("Previous Period")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Previous Period';
                Image = PreviousRecord;
                ToolTip = 'Previous Period';

                trigger OnAction()
                begin
                    FindPeriod('<=');
                end;
            }
            action("Next Period")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Next Period';
                Image = NextRecord;
                ToolTip = 'Next Period';

                trigger OnAction()
                begin
                    FindPeriod('>=');
                end;
            }
            group("&Print")
            {
                Caption = '&Print';
                Image = Print;
                action("G/L Turnover")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'G/L Turnover';
                    Image = Turnover;
                    ToolTip = 'Analyze the turnover compared with vendor or customer account balances.';

                    trigger OnAction()
                    begin
                        Vend.Copy(Rec);
                        REPORT.RunModal(REPORT::"Vendor G/L Turnover", true, false, Vend);
                    end;
                }
                action("Accounting Card")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Accounting Card';
                    Image = Account;

                    trigger OnAction()
                    begin
                        Vend.Reset();
                        Vend.CopyFilters(Rec);
                        REPORT.RunModal(REPORT::"Vendor Accounting Card", true, false, Vend);
                    end;
                }
            }
        }
        area(reporting)
        {
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Previous Period_Promoted"; "Previous Period")
                {
                }
                actionref("Next Period_Promoted"; "Next Period")
                {
                }
                actionref("A&greements_Promoted"; "A&greements")
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Reports';

                actionref("G/L Turnover_Promoted"; "G/L Turnover")
                {
                }
                actionref("Accounting Card_Promoted"; "Accounting Card")
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        DateFilter := Rec.GetFilter("Date Filter");
        if DateFilter = '' then begin
            if PeriodType = PeriodType::"Accounting Period" then
                FindPeriodUser('')
            else
                FindPeriod('');
        end else
            Rec.SetRange("G/L Starting Date Filter", Rec.GetRangeMin("Date Filter") - 1);
    end;

    var
        Vend: Record Vendor;
        UserPeriods: Record "User Setup";
        Vendor: Record Vendor;
        PeriodType: Enum "Analysis Period Type";
        DateFilter: Text;

    local procedure FindPeriod(SearchText: Code[10])
    var
        Calendar: Record Date;
        PeriodPageManagement: Codeunit PeriodPageManagement;
    begin
        if Rec.GetFilter("Date Filter") <> '' then begin
            Calendar.SetFilter("Period Start", Rec.GetFilter("Date Filter"));
            if not PeriodPageManagement.FindDate('+', Calendar, PeriodType) then
                PeriodPageManagement.FindDate('+', Calendar, PeriodType::Day);
            Calendar.SetRange("Period Start");
        end;
        PeriodPageManagement.FindDate(SearchText, Calendar, PeriodType);
        Rec.SetRange("Date Filter", Calendar."Period Start", Calendar."Period End");
        if Rec.GetRangeMin("Date Filter") = Rec.GetRangeMax("Date Filter") then
            Rec.SetRange("Date Filter", Rec.GetRangeMin("Date Filter"));
        Rec.SetRange("G/L Starting Date Filter", Rec.GetRangeMin("Date Filter") - 1);
    end;

    local procedure FindPeriodUser(SearchText: Code[10])
    var
        Calendar: Record Date;
        PeriodPageManagement: Codeunit PeriodPageManagement;
    begin
        if UserPeriods.Get(UserId) then begin
            Rec.SetRange("Date Filter", UserPeriods."Allow Posting From", UserPeriods."Allow Posting To");
            if Rec.GetRangeMin("Date Filter") = Rec.GetRangeMax("Date Filter") then
                Rec.SetRange("Date Filter", Rec.GetRangeMin("Date Filter"));
        end else begin
            if Rec.GetFilter("Date Filter") <> '' then begin
                Calendar.SetFilter("Period Start", Rec.GetFilter("Date Filter"));
                if not PeriodPageManagement.FindDate('+', Calendar, PeriodType) then
                    PeriodPageManagement.FindDate('+', Calendar, PeriodType::Day);
                Calendar.SetRange("Period Start");
            end;
            PeriodPageManagement.FindDate(SearchText, Calendar, PeriodType);
            Rec.SetRange("Date Filter", Calendar."Period Start", Calendar."Period End");
            if Rec.GetRangeMin("Date Filter") = Rec.GetRangeMax("Date Filter") then
                Rec.SetRange("Date Filter", Rec.GetRangeMin("Date Filter"));
        end;
    end;
}

