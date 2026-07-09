#pragma warning disable AA0247
page 17337 "FA Tax Differences"
{
    ApplicationArea = FixedAssets;
    Caption = 'FA Tax Differences';
    PageType = Worksheet;
    ShowFilter = true;
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
                    end;
                }
            }
            repeater(Control1210000)
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
                field(AmountBase; AmountBase)
                {
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    ApplicationArea = FixedAssets;
                    Caption = 'Amount (Base)';

                    trigger OnDrillDown()
                    begin
                        FALedgerEntry.Reset();
                        FALedgerEntry.FilterGroup(2);
                        FALedgerEntry.SetRange("FA No.", Rec."No.");
                        FALedgerEntry.SetRange("Depreciation Book Code", FASetup."Release Depr. Book");
                        Rec.CopyFilter("Date Filter", FALedgerEntry."FA Posting Date");
                        FALedgerEntry.SetFilter(
                          "FA Posting Type",
                          '%1|%2|%3',
                          FALedgerEntry."FA Posting Type"::"Acquisition Cost",
                          FALedgerEntry."FA Posting Type"::Appreciation,
                          FALedgerEntry."FA Posting Type"::"Salvage Value");
                        FALedgerEntry.FilterGroup(0);
                        PAGE.RunModal(0, FALedgerEntry);
                    end;
                }
                field(AmountTax; AmountTax)
                {
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    ApplicationArea = FixedAssets;
                    Caption = 'Amount (Tax)';

                    trigger OnDrillDown()
                    begin
                        FALedgerEntry.Reset();
                        FALedgerEntry.FilterGroup(2);
                        FALedgerEntry.SetRange("FA No.", Rec."No.");
                        FALedgerEntry.SetRange("Depreciation Book Code", TaxRegisterSetup."Tax Depreciation Book");
                        Rec.CopyFilter("Date Filter", FALedgerEntry."FA Posting Date");
                        FALedgerEntry.SetFilter(
                          "FA Posting Type",
                          '%1|%2|%3',
                          FALedgerEntry."FA Posting Type"::"Acquisition Cost",
                          FALedgerEntry."FA Posting Type"::Appreciation,
                          FALedgerEntry."FA Posting Type"::"Salvage Value");
                        FALedgerEntry.FilterGroup(0);
                        PAGE.RunModal(0, FALedgerEntry);
                    end;
                }
                field(DifferenceAmount; DifferenceAmount)
                {
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    ApplicationArea = FixedAssets;
                    Caption = 'Difference Amount';
                }
                field(DifferenceAmountCalc; DifferenceAmountCalc)
                {
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    ApplicationArea = FixedAssets;
                    Caption = 'Difference Amount (Calc.)';

                    trigger OnDrillDown()
                    begin
                        FALedgerEntry.Reset();
                        FALedgerEntry.SetCurrentKey("FA No.", "Depreciation Book Code", "FA Posting Date", Reversed, "Tax Difference Code");
                        FALedgerEntry.FilterGroup(2);
                        FALedgerEntry.SetRange("FA No.", Rec."No.");
                        Rec.CopyFilter("Date Filter", FALedgerEntry."FA Posting Date");
                        FALedgerEntry.SetFilter("Depreciation Book Code", DeprBookFilter);
                        FALedgerEntry.SetRange(Reversed, false);
                        FALedgerEntry.SetFilter("Tax Difference Code", '<>%1', TaxRegisterSetup."Default FA TD Code");
                        FALedgerEntry.FilterGroup(0);
                        PAGE.RunModal(0, FALedgerEntry);
                    end;
                }
                field(IsDifference; IsDifference)
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Is Difference';
                }
            }
        }
    }

    actions
    {
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
        }
    }

    trigger OnAfterGetRecord()
    begin
        CalcAmounts();
    end;

    trigger OnOpenPage()
    begin
        FASetup.Get();
        FASetup.TestField("Release Depr. Book");
        TaxRegisterSetup.Get();
        TaxRegisterSetup.TestField("Tax Depreciation Book");
        DeprBookFilter := GetDeprBookFilter();
        FindPeriod('');
    end;

    var
        FASetup: Record "FA Setup";
        FALedgerEntry: Record "FA Ledger Entry";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        TaxRegisterSetup: Record "Tax Register Setup";
        PeriodType: Enum "Analysis Period Type";
        AmountBase: Decimal;
        AmountTax: Decimal;
        DifferenceAmount: Decimal;
        DifferenceAmountCalc: Decimal;
        IsDifference: Boolean;
        DeprBookFilter: Code[250];

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
    end;

    [Scope('OnPrem')]
    procedure CalcAmounts()
    begin
        AmountBase := 0;
        AmountTax := 0;
        DifferenceAmount := 0;
        DifferenceAmountCalc := 0;
        IsDifference := false;

        if FADepreciationBook.Get(Rec."No.", FASetup."Release Depr. Book") then begin
            Rec.CopyFilter("Date Filter", FADepreciationBook."FA Posting Date Filter");
            FADepreciationBook.CalcFields("Acquisition Cost", Appreciation, "Salvage Value");
            AmountBase :=
              FADepreciationBook."Acquisition Cost" +
              FADepreciationBook.Appreciation +
              FADepreciationBook."Salvage Value";
        end;

        if FADepreciationBook.Get(Rec."No.", TaxRegisterSetup."Tax Depreciation Book") then begin
            Rec.CopyFilter("Date Filter", FADepreciationBook."FA Posting Date Filter");
            FADepreciationBook.CalcFields("Acquisition Cost");
            AmountTax :=
              FADepreciationBook."Acquisition Cost" +
              FADepreciationBook.Appreciation +
              FADepreciationBook."Salvage Value";
        end;

        DifferenceAmount := AmountBase - AmountTax;

        FALedgerEntry.Reset();
        FALedgerEntry.SetCurrentKey("FA No.", "Depreciation Book Code", "FA Posting Date", Reversed, "Tax Difference Code");
        FALedgerEntry.SetRange("FA No.", Rec."No.");
        Rec.CopyFilter("Date Filter", FALedgerEntry."FA Posting Date");
        FALedgerEntry.SetFilter("Depreciation Book Code", DeprBookFilter);
        FALedgerEntry.SetRange(Reversed, false);
        FALedgerEntry.SetFilter("Tax Difference Code", '<>%1', TaxRegisterSetup."Default FA TD Code");
        FALedgerEntry.CalcSums(Amount);
        DifferenceAmountCalc := FALedgerEntry.Amount;

        IsDifference := DifferenceAmount <> DifferenceAmountCalc;
    end;

    [Scope('OnPrem')]
    procedure GetDeprBookFilter() "Filter": Code[250]
    begin
        DepreciationBook.SetRange("Control FA Acquis. Cost", true);
        if DepreciationBook.Find('-') then
            repeat
                if Filter = '' then
                    Filter := DepreciationBook.Code
                else
                    Filter := Filter + '|' + DepreciationBook.Code;
            until DepreciationBook.Next() = 0;
    end;
}
