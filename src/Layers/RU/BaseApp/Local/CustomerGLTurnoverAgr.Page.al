#pragma warning disable AA0247
page 14914 "Customer G/L Turnover Agr."
{
    Caption = 'Customer G/L Turnover Agr.';
    DataCaptionFields = "Customer No.", "No.", Description;
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SaveValues = true;
    SourceTable = "Customer Agreement";

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
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the agreement.';
                }
                field("Customer Posting Group"; Rec."Customer Posting Group")
                {
                    ToolTip = 'Specifies the customer''s market type to link business transactions to.';
                    Visible = false;
                }
                field("G/L Starting Balance"; Rec."G/L Starting Balance")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Caption = 'Starting Balance';
                    ToolTip = 'Specifies the balance due under the agreement on the specified date.';
                }
                field("G/L Debit Amount"; Rec."G/L Debit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    BlankNumbers = BlankZero;
                    Caption = 'Debit Amount (LCY)';
                    ToolTip = 'Specifies the amount of a debit transaction under the agreement.';
                }
                field("G/L Credit Amount"; Rec."G/L Credit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    BlankNumbers = BlankZero;
                    Caption = 'Credit Amount (LCY)';
                    ToolTip = 'Specifies the amount of a credit transaction under the agreement.';
                }
                field("G/L Balance to Date"; Rec."G/L Balance to Date")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Caption = 'Ending Balance';
                    ToolTip = 'Specifies the current balance under the agreement.';
                }
                field("G/L Net Change"; Rec."G/L Net Change")
                {
                    BlankZero = true;
                    Caption = 'Net Change (LCY)';
                    ToolTip = 'Specifies the net change in the balance over the specified period.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Agreement")
            {
                Caption = '&Agreement';
                action(Card)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Page "Customer Agreement Card";
                    RunPageLink = "Customer No." = field("Customer No."),
                                  "No." = field("No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or edit details about the selected entity.';
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
                action("Accounting Card")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Accounting Card';
                    Image = "Report";
                    ToolTip = 'View customer entries for a specific period. These entries include starting balance, net change amounts, and ending balance.';

                    trigger OnAction()
                    begin
                        Cust.Reset();
                        Cust.SetRange("No.", Rec."Customer No.");
                        Rec.CopyFilter("Date Filter", Cust."Date Filter");
                        Rec.CopyFilter("G/L Starting Date Filter", Cust."G/L Starting Date Filter");
                        REPORT.RunModal(REPORT::"Customer Accounting Card", true, false, Cust);
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
            }
            group(Category_Report)
            {
                Caption = 'Reports';

                actionref("Accounting Card_Promoted"; "Accounting Card")
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        DateFilter := Rec.GetFilter("Date Filter");
        if DateFilter = '' then
            if PeriodType = PeriodType::"Accounting Period" then
                FindPeriodUser('')
            else
                FindPeriod('');
    end;

    var
        Cust: Record Customer;
        UserPeriods: Record "User Setup";
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

