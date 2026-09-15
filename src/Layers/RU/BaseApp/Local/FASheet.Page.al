#pragma warning disable AA0247
page 12497 "FA Sheet"
{
    ApplicationArea = FixedAssets;
    Caption = 'Fixed Asset Sheet';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "FA Depreciation Book";
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
                    end;
                }
                field(AmountType; AmountType)
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'View as';
                    Description = '000627';
                    OptionCaption = 'Net Change,Balance at Date';
                    ToolTip = 'Specifies how amounts are displayed. Net Change: The net change in the balance for the selected period. Balance at Date: The balance as of the last day in the selected period.';

                    trigger OnValidate()
                    begin
                        FindPeriod('');
                    end;
                }
            }
            repeater(Matrix)
            {
                Editable = false;
                field("FA No."; Rec."FA No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the number of the related fixed asset. ';
                }
                field("FA.Description"; FA.Description)
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'FA Description';
                    ToolTip = 'Specifies a description of the fixed asset.';
                }
                field("FA.""Undepreciable FA"""; FA."Undepreciable FA")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Undepr. FA';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = FixedAssets;
                    BlankZero = true;
                    ToolTip = 'Specifies the quantity of the fixed asset.';
                }
                field("FA Posting Group"; Rec."FA Posting Group")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies which posting group is used for the depreciation book when posting fixed asset transactions.';
                    Visible = false;
                }
                field("Acquisition Date"; Rec."Acquisition Date")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the FA posting date of the first posted acquisition cost.';
                }
                field("Depreciation Method"; Rec."Depreciation Method")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies how depreciation is calculated for the depreciation book.';
                    Visible = false;
                }
                field("Depreciation Starting Date"; Rec."Depreciation Starting Date")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the date on which depreciation of the fixed asset starts.';
                }
                field("Depreciation Ending Date"; Rec."Depreciation Ending Date")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the date on which depreciation of the fixed asset ends.';
                }
                field("No. of Depreciation Years"; Rec."No. of Depreciation Years")
                {
                    ApplicationArea = FixedAssets;
                    BlankZero = true;
                    ToolTip = 'Specifies the length of the depreciation period, expressed in years.';
                }
                field("Disposal Date"; Rec."Disposal Date")
                {
                    ApplicationArea = FixedAssets;
                }
                field(Depreciation; Rec.Depreciation)
                {
                    ApplicationArea = FixedAssets;
                    BlankZero = true;
                }
                field("Acquisition Cost"; Rec."Acquisition Cost")
                {
                    ApplicationArea = FixedAssets;
                    BlankZero = true;
                    ToolTip = 'Specifies the total percentage of acquisition cost that can be allocated when acquisition cost is posted.';
                }
                field("Book Value"; Rec."Book Value")
                {
                    ApplicationArea = FixedAssets;
                    BlankZero = true;
                    ToolTip = 'Specifies the book value for the fixed asset.';
                }
                field("Proceeds on Disposal"; Rec."Proceeds on Disposal")
                {
                    ApplicationArea = FixedAssets;
                    BlankZero = true;
                    ToolTip = 'Specifies the total proceeds on disposal for the fixed asset.';
                }
                field("Gain/Loss"; Rec."Gain/Loss")
                {
                    ApplicationArea = FixedAssets;
                    BlankZero = true;
                    ToolTip = 'Specifies the total gain (credit) or loss (debit) for the fixed asset.';
                }
                field("Write-Down"; Rec."Write-Down")
                {
                    ApplicationArea = FixedAssets;
                    BlankZero = true;
                }
                field(Appreciation; Rec.Appreciation)
                {
                    ApplicationArea = FixedAssets;
                    BlankZero = true;
                }
                field("Custom 1"; Rec."Custom 1")
                {
                    ApplicationArea = FixedAssets;
                    BlankZero = true;
                    ToolTip = 'Specifies the total LCY amount for custom 1 entries for the fixed asset.';
                }
                field("Custom 2"; Rec."Custom 2")
                {
                    ApplicationArea = FixedAssets;
                    BlankZero = true;
                    ToolTip = 'Specifies the total LCY amount for custom 2 entries for the fixed asset.';
                }
                field("Salvage Value"; Rec."Salvage Value")
                {
                    ApplicationArea = FixedAssets;
                    BlankZero = true;
                    ToolTip = 'Specifies the estimated residual value of a fixed asset when it can no longer be used.';
                }
                field("Book Value on Disposal"; Rec."Book Value on Disposal")
                {
                    ApplicationArea = FixedAssets;
                    BlankZero = true;
                    ToolTip = 'Specifies the total amount of entries posted with the Book Value on Disposal posting type. Entries of this kind are created when you post disposal of a fixed asset to a depreciation book where the Gross method has been selected in the Disposal Calculation Method field.';
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
                    RunObject = Page "Fixed Asset Card";
                    RunPageLink = "No." = field("FA No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or edit details about the selected entity.';
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
                action("FA Sheet")
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'FA Sheet';
                    Image = FixedAssets;
                    ToolTip = 'View or edit fixed asset turnover information based on the fixed asset depreciation books. This window shows information similar to the FA Turnover report.';

                    trigger OnAction()
                    begin
                        Clear(FATurnover);
                        FATurnover.SetParameters(Rec);
                        FATurnover.Run();
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

                actionref("FA Sheet_Promoted"; "FA Sheet")
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if FA.Get(Rec."FA No.") then;
    end;

    trigger OnOpenPage()
    begin
        DateFilter := Rec.GetFilter("FA Posting Date Filter");
        if DateFilter = '' then
            if PeriodType = PeriodType::"Accounting Period" then
                FindPeriodUser('')
            else
                FindPeriod('');

        if DeprBookFilter = '' then begin
            FASetup.Get();
            DeprBookFilter := FASetup."Default Depr. Book";
        end;
        Rec.SetRange("Depreciation Book Code", DeprBookFilter);
    end;

    var
        FA: Record "Fixed Asset";
        UserPeriods: Record "User Setup";
        FASetup: Record "FA Setup";
        FATurnover: Report "FA Turnover";
        PeriodType: Enum "Analysis Period Type";
        DateFilter: Text;
        DeprBookFilter: Text[30];
        AmountType: Option "Net Change","Balance at Date";

    local procedure FindPeriod(SearchText: Code[10])
    var
        Calendar: Record Date;
        PeriodPageManagement: Codeunit PeriodPageManagement;
    begin
        if Rec.GetFilter("FA Posting Date Filter") <> '' then begin
            Calendar.SetFilter("Period Start", Rec.GetFilter("FA Posting Date Filter"));
            if not PeriodPageManagement.FindDate('+', Calendar, PeriodType) then
                PeriodPageManagement.FindDate('+', Calendar, PeriodType::Day);
            Calendar.SetRange("Period Start");
        end;
        PeriodPageManagement.FindDate(SearchText, Calendar, PeriodType);
        if AmountType = AmountType::"Net Change" then begin
            Rec.SetRange("FA Posting Date Filter", Calendar."Period Start", Calendar."Period End");
            if Rec.GetRangeMin("FA Posting Date Filter") = Rec.GetRangeMax("FA Posting Date Filter") then
                Rec.SetRange("FA Posting Date Filter", Rec.GetRangeMin("FA Posting Date Filter"));
        end else
            Rec.SetRange("FA Posting Date Filter", 0D, Calendar."Period End");
    end;

    local procedure FindPeriodUser(SearchText: Code[10])
    var
        Calendar: Record Date;
        PeriodPageManagement: Codeunit PeriodPageManagement;
    begin
        if UserPeriods.Get(UserId) then begin
            Rec.SetRange("FA Posting Date Filter", UserPeriods."Allow Posting From", UserPeriods."Allow Posting To");
            if Rec.GetRangeMin("FA Posting Date Filter") = Rec.GetRangeMax("FA Posting Date Filter") then
                Rec.SetRange("FA Posting Date Filter", Rec.GetRangeMin("FA Posting Date Filter"));
        end else begin
            if Rec.GetFilter("FA Posting Date Filter") <> '' then begin
                Calendar.SetFilter("Period Start", Rec.GetFilter("FA Posting Date Filter"));
                if not PeriodPageManagement.FindDate('+', Calendar, PeriodType) then
                    PeriodPageManagement.FindDate('+', Calendar, PeriodType::Day);
                Calendar.SetRange("Period Start");
            end;
            PeriodPageManagement.FindDate(SearchText, Calendar, PeriodType);
            if AmountType = AmountType::"Net Change" then begin
                Rec.SetRange("FA Posting Date Filter", Calendar."Period Start", Calendar."Period End");
                if Rec.GetRangeMin("FA Posting Date Filter") = Rec.GetRangeMax("FA Posting Date Filter") then
                    Rec.SetRange("FA Posting Date Filter", Rec.GetRangeMin("FA Posting Date Filter"));
            end else
                Rec.SetRange("FA Posting Date Filter", 0D, Calendar."Period End");
        end;
    end;
}

