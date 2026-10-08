#pragma warning disable AA0247
page 12499 "FA G/L Turnover"
{
    Caption = 'FA G/L Turnover';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SaveValues = true;
    SourceTable = "Fixed Asset";
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
                    ApplicationArea = FixedAssets;
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
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the description associated with this line.';
                }
                field("Begining Balance"; Rec."G/L Starting Balance")
                {
                    ApplicationArea = FixedAssets;
                    BlankZero = true;
                    Caption = 'Starting Balance (LCY)';
                    ToolTip = 'Specifies the general ledger starting balance associated with the fixed asset.';
                }
                field("G/L Debit Amount"; Rec."G/L Debit Amount")
                {
                    ApplicationArea = FixedAssets;
                    BlankNumbers = BlankZero;
                    Caption = 'Debit Amount (LCY)';
                    ToolTip = 'Specifies the general ledger debit amount associated with the fixed asset.';
                }
                field("G/L Credit Amount"; Rec."G/L Credit Amount")
                {
                    ApplicationArea = FixedAssets;
                    BlankNumbers = BlankZero;
                    Caption = 'Credit Amount (LCY)';
                    ToolTip = 'Specifies the general ledger credit amount associated with the fixed asset.';
                }
                field("Balance Ending"; Rec."G/L Balance to Date")
                {
                    ApplicationArea = FixedAssets;
                    BlankZero = true;
                    Caption = 'Ending Balance (LCY)';
                    ToolTip = 'Specifies the general ledger balance to date associated with the fixed asset.';
                }
                field("G/L Net Change"; Rec."G/L Net Change")
                {
                    ApplicationArea = FixedAssets;
                    BlankZero = true;
                    Caption = 'Net Change (LCY)';
                    ToolTip = 'Specifies the general ledger net change of the fixed asset.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Fixed Asset")
            {
                Caption = '&Fixed Asset';
                Image = FixedAssets;
                action(Card)
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Card';
                    Image = EditLines;
                    ShortCutKey = 'Shift+F7';

                    trigger OnAction()
                    begin
                        FA.Copy(Rec);
                        PAGE.Run(PAGE::"Fixed Asset Card", FA);
                    end;
                }
            }
        }
        area(processing)
        {
            action("Previous Period")
            {
                ApplicationArea = FixedAssets;
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
                ApplicationArea = FixedAssets;
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
                action("Turnover Sheet")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Turnover Sheet';
                    Image = "Report";
                    ToolTip = 'View the fixed asset turnover information. You can view information such as the fixed asset name, quantity, status, depreciation dates, and amounts. The report can be used as documentation for the correction of quantities and for auditing purposes.';

                    trigger OnAction()
                    begin
                        FA.Copy(Rec);
                        REPORT.RunModal(REPORT::"Fixed Asset G/L Turnover", true, false, FA);
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

                actionref("Turnover Sheet_Promoted"; "Turnover Sheet")
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
        FA: Record "Fixed Asset";
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

