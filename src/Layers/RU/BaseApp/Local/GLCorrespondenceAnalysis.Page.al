#pragma warning disable AA0247
page 12402 "G/L Correspondence Analysis"
{
    ApplicationArea = Basic, Suite;
    Caption = 'G/L Correspondence';
    PageType = List;
    SaveValues = true;
    SourceTable = "G/L Correspondence";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            group(Options)
            {
                Caption = 'Options';
                field(ClosingEntryFilter; ClosingEntryFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Closing Entries';
                    OptionCaption = 'Include,Exclude';
                    ToolTip = 'Specifies whether the balance shown will include closing entries. If you want to see the amounts on income statement accounts in closed years, you must exclude closing entries.';

                    trigger OnValidate()
                    begin
                        FindPeriod('');
                        ClosingEntryFilterOnAfterValid();
                    end;
                }
                field(PeriodType; PeriodType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'View by';
                    ToolTip = 'Specifies by which period amounts are displayed.';

                    trigger OnValidate()
                    begin
                        if PeriodType = PeriodType::"Accounting Period" then
                            AccountingPerioPeriodTypeOnVal();
                        if PeriodType = PeriodType::Year then
                            YearPeriodTypeOnValidate();
                        if PeriodType = PeriodType::Quarter then
                            QuarterPeriodTypeOnValidate();
                        if PeriodType = PeriodType::Month then
                            MonthPeriodTypeOnValidate();
                        if PeriodType = PeriodType::Week then
                            WeekPeriodTypeOnValidate();
                        if PeriodType = PeriodType::Day then
                            DayPeriodTypeOnValidate();
                    end;
                }
                field(AmountType; AmountType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'View as';
                    ToolTip = 'Specifies how amounts are displayed. Net Change: The net change in the balance for the selected period. Balance at Date: The balance as of the last day in the selected period.';

                    trigger OnValidate()
                    begin
                        if AmountType = AmountType::"Balance at Date" then
                            BalanceatDateAmountTypeOnValid();
                        if AmountType = AmountType::"Net Change" then
                            NetChangeAmountTypeOnValidate();
                    end;
                }
            }
            repeater(Control1210000)
            {
                Editable = false;
                ShowCaption = false;
                field("Debit Account No."; Rec."Debit Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the debit account number associated with this correspondence.';
                }
                field("Debit Account Name"; Rec."Debit Account Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the debit account associated with this correspondence.';
                }
                field("Credit Account No."; Rec."Credit Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the credit account number associated with this correspondence.';
                }
                field("Credit Account Name"; Rec."Credit Account Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the credit account associated with this correspondence.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    BlankNumbers = BlankZero;
                    ToolTip = 'Specifies the amount associated with this correspondence.';
                }
                field("Amount (ACY)"; Rec."Amount (ACY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the additional reporting currency (ACY) amount associated with this correspondence.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Debit Account")
            {
                Caption = '&Debit Account';
                action(Card)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Page "G/L Account Card";
                    RunPageLink = "No." = field("Debit Account No."),
                                  "Date Filter" = field("Date Filter"),
                                  "Global Dimension 1 Filter" = field("Debit Global Dim. 1 Filter"),
                                  "Global Dimension 2 Filter" = field("Debit Global Dim. 2 Filter"),
                                  "Business Unit Filter" = field("Business Unit Filter");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or edit details about the selected entity.';
                }
                action("Debit Account Ledger Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Debit Account Ledger Entries';
                    Image = GL;
                    RunObject = Page "General Ledger Entries";
                    RunPageLink = "G/L Account No." = field("Debit Account No.");
                    RunPageView = sorting("G/L Account No.");
                    ShortCutKey = 'Ctrl+F7';
                }
                action("Co&mments")
                {
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Comment Sheet";
                    RunPageLink = "Table Name" = const("G/L Account"),
                                  "No." = field("Debit Account No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action(Dimensions)
                {
                    ApplicationArea = Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    RunObject = Page "Default Dimensions";
                    RunPageLink = "Table ID" = const(15),
                                  "No." = field("Debit Account No.");
                    ShortCutKey = 'Shift+Ctrl+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to journal lines to distribute costs and analyze transaction history.';
                }
                action("E&xtended Texts")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'E&xtended Texts';
                    Image = Text;
                    RunObject = Page "Extended Text List";
                    RunPageLink = "Table Name" = const("G/L Account"),
                                  "No." = field("Debit Account No.");
                    RunPageView = sorting("Table Name", "No.", "Language Code", "All Language Codes", "Starting Date", "Ending Date");
                    ToolTip = 'View or edit additional text for the descriptions of items. Extended text can be inserted under the Description field on document lines for the item.';
                }
            }
            group("&Credit Account")
            {
                Caption = '&Credit Account';
                action(Action1210044)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Page "Chart of Accounts";
                    RunPageLink = "No." = field("Credit Account No."),
                                  "Date Filter" = field("Date Filter"),
                                  "Global Dimension 1 Filter" = field("Credit Global Dim. 1 Filter"),
                                  "Global Dimension 2 Filter" = field("Credit Global Dim. 2 Filter"),
                                  "Business Unit Filter" = field("Business Unit Filter");
                    ToolTip = 'View or edit details about the selected entity.';
                }
                action("Credit Account Ledger Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Credit Account Ledger Entries';
                    Image = GL;
                    RunObject = Page "General Ledger Entries";
                    RunPageLink = "G/L Account No." = field("Credit Account No.");
                    RunPageView = sorting("G/L Account No.");
                }
                action(Action1210046)
                {
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Comment Sheet";
                    RunPageLink = "Table Name" = const("G/L Account"),
                                  "No." = field("Credit Account No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action(Action1210047)
                {
                    ApplicationArea = Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    RunObject = Page "Default Dimensions";
                    RunPageLink = "Table ID" = const(15),
                                  "No." = field("Credit Account No.");
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to journal lines to distribute costs and analyze transaction history.';
                }
                action(Action1210048)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'E&xtended Texts';
                    Image = Text;
                    RunObject = Page "Extended Text List";
                    RunPageLink = "Table Name" = const("G/L Account"),
                                  "No." = field("Credit Account No.");
                    RunPageView = sorting("Table Name", "No.", "Language Code", "All Language Codes", "Starting Date", "Ending Date");
                    ToolTip = 'View or edit additional text for the descriptions of items. Extended text can be inserted under the Description field on document lines for the item.';
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
                actionref("Debit Account Ledger Entries_Promoted"; "Debit Account Ledger Entries")
                {
                }
                actionref("Credit Account Ledger Entries_Promoted"; "Credit Account Ledger Entries")
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Rec.CalcFields(Amount, "Amount (ACY)");
    end;

    trigger OnOpenPage()
    begin
        FindPeriod('');
    end;

    var
        PeriodType: Enum "Analysis Period Type";
        AmountType: Enum "Analysis Amount Type";
        ClosingEntryFilter: Option Include,Exclude;

    local procedure FindPeriod(SearchText: Code[10])
    var
        Calendar: Record Date;
        AccountingPeriod: Record "Accounting Period";
        PeriodPageManagement: Codeunit PeriodPageManagement;
    begin
        if Rec.GetFilter("Date Filter") <> '' then begin
            Calendar.SetFilter("Period Start", Rec.GetFilter("Date Filter"));
            if not PeriodPageManagement.FindDate('+', Calendar, PeriodType) then
                PeriodPageManagement.FindDate('+', Calendar, PeriodType::Day);
            Calendar.SetRange("Period Start");
        end;
        PeriodPageManagement.FindDate(SearchText, Calendar, PeriodType);
        if AmountType = AmountType::"Net Change" then
            if Calendar."Period Start" = Calendar."Period End" then
                Rec.SetRange("Date Filter", Calendar."Period Start")
            else
                Rec.SetRange("Date Filter", Calendar."Period Start", Calendar."Period End")
        else
            Rec.SetRange("Date Filter", 0D, Calendar."Period End");
        if ClosingEntryFilter = ClosingEntryFilter::Exclude then begin
            AccountingPeriod.SetCurrentKey("New Fiscal Year");
            AccountingPeriod.SetRange("New Fiscal Year", true);
            if Rec.GetRangeMin("Date Filter") = 0D then
                AccountingPeriod.SetRange("Starting Date", 0D, Rec.GetRangeMax("Date Filter"))
            else
                AccountingPeriod.SetRange(
                  "Starting Date",
                  Rec.GetRangeMin("Date Filter") + 1,
                  Rec.GetRangeMax("Date Filter"));
            if AccountingPeriod.Find('-') then
                repeat
                    Rec.SetFilter(
                      "Date Filter", Rec.GetFilter("Date Filter") + '&<>%1',
                      ClosingDate(AccountingPeriod."Starting Date" - 1));
                until AccountingPeriod.Next() = 0;
        end else
            Rec.SetRange(
              "Date Filter",
              Rec.GetRangeMin("Date Filter"),
              ClosingDate(Rec.GetRangeMax("Date Filter")));
    end;

    local procedure ClosingEntryFilterOnAfterValid()
    begin
        CurrPage.Update();
    end;

    local procedure DayPeriodTypeOnPush()
    begin
        FindPeriod('');
    end;

    local procedure WeekPeriodTypeOnPush()
    begin
        FindPeriod('');
    end;

    local procedure MonthPeriodTypeOnPush()
    begin
        FindPeriod('');
    end;

    local procedure QuarterPeriodTypeOnPush()
    begin
        FindPeriod('');
    end;

    local procedure YearPeriodTypeOnPush()
    begin
        FindPeriod('');
    end;

    local procedure AccountingPerioPeriodTypOnPush()
    begin
        FindPeriod('');
    end;

    local procedure NetChangeAmountTypeOnPush()
    begin
        FindPeriod('');
    end;

    local procedure BalanceatDateAmountTypeOnPush()
    begin
        FindPeriod('');
    end;

    local procedure DayPeriodTypeOnValidate()
    begin
        DayPeriodTypeOnPush();
    end;

    local procedure WeekPeriodTypeOnValidate()
    begin
        WeekPeriodTypeOnPush();
    end;

    local procedure MonthPeriodTypeOnValidate()
    begin
        MonthPeriodTypeOnPush();
    end;

    local procedure QuarterPeriodTypeOnValidate()
    begin
        QuarterPeriodTypeOnPush();
    end;

    local procedure YearPeriodTypeOnValidate()
    begin
        YearPeriodTypeOnPush();
    end;

    local procedure AccountingPerioPeriodTypeOnVal()
    begin
        AccountingPerioPeriodTypOnPush();
    end;

    local procedure NetChangeAmountTypeOnValidate()
    begin
        NetChangeAmountTypeOnPush();
    end;

    local procedure BalanceatDateAmountTypeOnValid()
    begin
        BalanceatDateAmountTypeOnPush();
    end;
}

