#pragma warning disable AA0247
report 12469 "Item Turnover (Qty.)"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/ItemTurnoverQty.rdlc';
    Caption = 'Item Turnover (Qty.)';

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Location Filter", "Date Filter";
            column(USERID; UserId)
            {
            }
            column(PeriodText; PeriodText)
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(CurrentDate; CurrentDate)
            {
            }
            column(PrintCost; PrintCost)
            {
            }
            column(PrintQuantity; PrintQuantity)
            {
            }
            column(ShowDetails; ShowDetails)
            {
            }
            column(RequestFilter; RequestFilter)
            {
            }
            column(AmountUnit; AmountUnit)
            {
            }
            column(ItemCategory_Code; DummyItemCategory.Code)
            {
            }
            column(EndingCost; EndingCost)
            {
            }
            column(DecreaseCost; DecreaseCost)
            {
                AutoFormatType = 1;
            }
            column(IncreaseCost; IncreaseCost)
            {
                AutoFormatType = 1;
            }
            column(StartingCost; StartingCost)
            {
            }
            column(ItemDescription; ItemDescription)
            {
            }
            column(Item__No__; "No.")
            {
            }
            column(ItemDescription_Control1210120; ItemDescription)
            {
            }
            column(Unit2; Unit2)
            {
            }
            column(EndingQtyText; EndingQtyText)
            {
            }
            column(DecreaseQtyText; DecreaseQtyText)
            {
            }
            column(IncreaseQtyText; IncreaseQtyText)
            {
            }
            column(StartingQtyText; StartingQtyText)
            {
            }
            column(Item__No___Control1210132; "No.")
            {
            }
            column(EndingCost_Control1000000002; EndingCost)
            {
            }
            column(DecreaseCost_Control1000000004; DecreaseCost)
            {
                AutoFormatType = 1;
            }
            column(IncreaseCost_Control1000000005; IncreaseCost)
            {
                AutoFormatType = 1;
            }
            column(StartingCost_Control1000000008; StartingCost)
            {
            }
            column(Item__No___Control1000000012; "No.")
            {
            }
            column(Unit2_Control1000000015; Unit2)
            {
            }
            column(EndingQtyText_Control1000000017; EndingQtyText)
            {
            }
            column(DecreaseQtyText_Control1000000019; DecreaseQtyText)
            {
            }
            column(IncreaseQtyText_Control1000000021; IncreaseQtyText)
            {
            }
            column(StartingQtyText_Control1000000023; StartingQtyText)
            {
            }
            column(ItemDescription_Control1000000025; ItemDescription)
            {
            }
            column(EndingCost_Control1210106; EndingCost)
            {
            }
            column(DecreaseCost_Control1210108; DecreaseCost)
            {
                AutoFormatType = 1;
            }
            column(IncreaseCost_Control1210109; IncreaseCost)
            {
                AutoFormatType = 1;
            }
            column(StartingCost_Control1210112; StartingCost)
            {
            }
            column(STRSUBSTNO_Text12401_ItemCategory_Code_ItemCategory_Description_; StrSubstNo(Text12401, DummyItemCategory.Code, DummyItemCategory.Description))
            {
            }
            column(PrintGroupTotals; PrintGroupTotals)
            {
            }
            column(EndingCost_Control1210099; EndingCost)
            {
            }
            column(DecreaseCost_Control1210100; DecreaseCost)
            {
                AutoFormatType = 1;
            }
            column(IncreaseCost_Control1210101; IncreaseCost)
            {
                AutoFormatType = 1;
            }
            column(StartingCost_Control1210102; StartingCost)
            {
            }
            column(STRSUBSTNO_Text12401_ItemCategory_Code_ItemCategory_Description__Control1210103; StrSubstNo(Text12401, DummyItemCategory.Code, DummyItemCategory.Description))
            {
            }
            column(IncreaseQtyText_Control1210072; IncreaseQtyText)
            {
            }
            column(StartingQtyText_Control1210074; StartingQtyText)
            {
            }
            column(STRSUBSTNO_Text12402_ItemCategory_Code_ItemCategory_Description_; StrSubstNo(Text12402, DummyItemCategory.Code, DummyItemCategory.Description))
            {
            }
            column(DecreaseQtyText_Control1210078; DecreaseQtyText)
            {
            }
            column(EndingQtyText_Control1210079; EndingQtyText)
            {
            }
            column(TotalDecreaseQtyText; TotalDecreaseQtyText)
            {
            }
            column(TotalIncreaseQtyText; TotalIncreaseQtyText)
            {
            }
            column(EndingCost_Control1210032; EndingCost)
            {
            }
            column(DecreaseCost_Control1210034; DecreaseCost)
            {
                AutoFormatType = 1;
            }
            column(IncreaseCost_Control1210036; IncreaseCost)
            {
                AutoFormatType = 1;
            }
            column(StartingCost_Control1210038; StartingCost)
            {
            }
            column(Turnover_SheetCaption; Turnover_SheetCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(ItemsCaption; ItemsCaptionLbl)
            {
            }
            column(Start_of_periodCaption; Start_of_periodCaptionLbl)
            {
            }
            column(DescriptionCaption; DescriptionCaptionLbl)
            {
            }
            column(Item_No_Caption; Item_No_CaptionLbl)
            {
            }
            column(Positive_AdjustmentCaption; Positive_AdjustmentCaptionLbl)
            {
            }
            column(Negative_AdjustmentCaption; Negative_AdjustmentCaptionLbl)
            {
            }
            column(End_of_periodCaption; End_of_periodCaptionLbl)
            {
            }
            column(Period_Net_ChangeCaption; Period_Net_ChangeCaptionLbl)
            {
            }
            column(Unit_of_MeasureCaption; Unit_of_MeasureCaptionLbl)
            {
            }
            column(DetailedEntries__Red_Storno_Caption; DetailedEntries.FieldCaption("Red Storno"))
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }
            column(Item_Category_Code; "Item Category Code")
            {
            }
            dataitem(DetailedEntries; "Value Entry")
            {
                DataItemTableView = sorting("Item No.", "Posting Date", "Document No.", "Document Line No.");
                column(DetailedEntries_DetailedEntries__Posting_Date_; DetailedEntries."Posting Date")
                {
                }
                column(DetailedEntries_DetailedEntries_Description; DetailedEntries.Description)
                {
                }
                column(Debit; Debit)
                {
                }
                column(Credit; Credit)
                {
                }
                column(DetailedQtyPositive; DetailedQtyPositive)
                {
                }
                column(DetailedQtyNegative; DetailedQtyNegative)
                {
                }
                column(DetailedEntries_DetailedEntries__Entry_No__; DetailedEntries."Entry No.")
                {
                }
                column(DetailedEntries__Red_Storno_; "Red Storno")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if IsDebit() then begin
                        DetailedQtyPositive := Round("Invoiced Quantity" / QuanUnitToBaseUnit, Decimals, '=');
                        Debit := "Cost Amount (Actual)";
                        DetailedQtyNegative := 0;
                        Credit := 0;
                    end else begin
                        DetailedQtyNegative := -Round("Invoiced Quantity" / QuanUnitToBaseUnit, Decimals, '=');
                        Credit := -"Cost Amount (Actual)";
                        DetailedQtyPositive := 0;
                        Debit := 0;
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    if not ShowDetails then CurrReport.Break();
                    DetailedEntries.SetFilter("Posting Date", '%1..%2', StartDate, EndDate);
                    DetailedEntries.SetFilter("Item No.", Item."No.");
                end;
            }

            trigger OnAfterGetRecord()
            begin
                ItemDescription := Description + "Description 2";

                ValueEntry.SetRange("Item No.", "No.");

                Unit2 := Item."Base Unit of Measure";
                QuanUnitToBaseUnit := 1;

                case PrintUnitOfMeasure of
                    PrintUnitOfMeasure::Sale:
                        if ItemUnit.Get("No.", "Sales Unit of Measure") then
                            if not (ItemUnit."Qty. per Unit of Measure" = 0) then begin
                                Unit2 := ItemUnit.Code;
                                QuanUnitToBaseUnit := ItemUnit."Qty. per Unit of Measure";
                            end;
                    PrintUnitOfMeasure::Purchase:
                        if ItemUnit.Get("No.", "Purch. Unit of Measure") then
                            if not (ItemUnit."Qty. per Unit of Measure" = 0) then begin
                                Unit2 := ItemUnit.Code;
                                QuanUnitToBaseUnit := ItemUnit."Qty. per Unit of Measure";
                            end;
                end;

                if StartDate > 0D then begin
                    GetQuantityAndAmount(0D, CalcDate('<-1D>', StartDate));
                    StartingQty := Round(DebitQuantity - CreditQuantity / QuanUnitToBaseUnit, Decimals, '=');
                    StartingCost := DebitCost - CreditCost;
                end;

                GetQuantityAndAmount(0D, EndDate);
                EndingQty := Round(DebitQuantity - CreditQuantity / QuanUnitToBaseUnit, Decimals, '=');
                EndingCost := DebitCost - CreditCost;

                GetQuantityAndAmount(StartDate, EndDate);
                IncreaseQty := Round(DebitQuantity / QuanUnitToBaseUnit, Decimals, '=');
                IncreaseCost := DebitCost;
                DecreaseQty := Round(CreditQuantity / QuanUnitToBaseUnit, Decimals, '=');
                DecreaseCost := CreditCost;

                if SkipZeroBalances and (EndingQty = 0) and (EndingCost = 0) then
                    CurrReport.Skip();

                if SkipZeroNetChanges and (IncreaseQty = 0) and (DecreaseQty = 0) and
                  (IncreaseCost = 0) and (DecreaseCost = 0) then
                    CurrReport.Skip();

                if SkipZeroLines and
                  (StartingQty = 0) and (EndingQty = 0) and
                  (IncreaseQty = 0) and (DecreaseQty = 0) and
                  (StartingCost = 0) and (EndingCost = 0) and
                  (IncreaseCost = 0) and (EndingCost = 0) then
                    CurrReport.Skip();

                TextValueLine(SkipZeroValues);
            end;

            trigger OnPreDataItem()
            begin
                Clear(StartingCost);
                Clear(IncreaseCost);
                Clear(DecreaseCost);
                Clear(EndingCost);
                Clear(StartingQty);
                Clear(EndingQty);
                Clear(IncreaseQty);
                Clear(DecreaseQty);

                if not PrintGroupTotals then
                    Item.SetCurrentKey("No.");

                ValueEntry.Reset();
                ValueEntry.SetCurrentKey("Item No.", "Location Code",
                  "Global Dimension 1 Code", "Global Dimension 2 Code", "Expected Cost", Positive, "Posting Date");
                ValueEntry.SetFilter("Location Code", GetFilter("Location Filter"));
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
                    group(Printout)
                    {
                        Caption = 'Printout';
                        field("Rounding Precision"; RoundingPrecision)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Rounding Precision';
                            ToolTip = 'Specifies the size of the interval to be used when rounding amounts in the specified currency. You can specify invoice rounding for each currency in the Currency table.';
                        }
                        field("Replace zero values"; SkipZeroValues)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Replace zero values by blanks';
                            ToolTip = 'Specifies if you want all zero values on the report to be displayed as blank entries.';
                        }
                        field("Skip accounts without net changes"; SkipZeroNetChanges)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Skip accounts without net changes';
                            ToolTip = 'Specifies that you want the report to exclude accounts with zero turnovers for the given period.';
                        }
                        field("Skip accounts with zero ending balance"; SkipZeroBalances)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Skip accounts with zero ending balance';
                            ToolTip = 'Specifies that you want the report to exclude accounts with zero ending balance at the end of the period.';
                        }
                        field("Skip zero lines"; SkipZeroLines)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Skip zero lines';
                            ToolTip = 'Specifies if lines with zero amount are not be included.';
                        }
                        field("Show details"; ShowDetails)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Show details';
                            ToolTip = 'Specifies if the report displays all lines in detail.';
                        }
                    }
                    group(Data)
                    {
                        Caption = 'Data';
                        field("Unit of Measure"; PrintUnitOfMeasure)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Unit of Measure';
                            OptionCaption = 'Base,Sale,Purchase';
                        }
                        field("Print Quantity"; PrintQuantity)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Print Quantity';
                            ToolTip = 'Specifies that the specified quantity will be printed.';
                        }
                        field("Print Cost"; PrintCost)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Print Cost';
                        }
                        field("Print Group Totals"; PrintGroupTotals)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Print Group Totals';
                            ToolTip = 'Specifies if you want to print preliminary group totals.';
                        }
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            PrintQuantity := true;
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        ShowDetails := true;
    end;

    trigger OnPreReport()
    begin
        if not (PrintQuantity or PrintCost or PrintGroupTotals) then
            Error(Text12400);

        CurrentDate := LocManagement.Date2Text(Today) + Format(Time, 0, '  (<Hours24>:<Minutes>)');
        RequestFilter := Item.GetFilters();

        DetailedEntries.SetFilter("Posting Date", Format(StartDate));

        if Item.GetRangeMin("Date Filter") <> 0D then
            StartDate := Item.GetRangeMin("Date Filter");
        if Item.GetRangeMax("Date Filter") <> 0D then
            EndDate := Item.GetRangeMax("Date Filter")
        else
            EndDate := WorkDate();
        FillReportParameters();
    end;

    var
        ItemUnit: Record "Item Unit of Measure";
        ValueEntry: Record "Value Entry";
        DummyItemCategory: Record "Item Category";
        LocManagement: Codeunit "Localisation Management";
        StartingCost: Decimal;
        IncreaseCost: Decimal;
        DecreaseCost: Decimal;
        EndingCost: Decimal;
        StartingQty: Decimal;
        EndingQty: Decimal;
        IncreaseQty: Decimal;
        DecreaseQty: Decimal;
        StartDate: Date;
        EndDate: Date;
        SkipZeroBalances: Boolean;
        SkipZeroValues: Boolean;
        SkipZeroLines: Boolean;
        SkipZeroNetChanges: Boolean;
        PrintParameters: Boolean;
        CurrentDate: Text[30];
        ReportParameters: array[4] of Text[80];
        Counter: Integer;
        RoundingPrecision: Option "0.001","0.01","1","1000";
        Decimals: Decimal;
        RequestFilter: Text;
        AmountUnit: Text[30];
        ValueFormat: Text[50];
        StartingQtyText: Text[30];
        EndingQtyText: Text[30];
        IncreaseQtyText: Text[30];
        DecreaseQtyText: Text[30];
        TotalIncreaseQtyText: Text[30];
        TotalDecreaseQtyText: Text[30];
        Unit2: Code[10];
        PrintUnitOfMeasure: Option Base,Sale,Purchase;
        QuanUnitToBaseUnit: Decimal;
        PrintQuantity: Boolean;
        PrintCost: Boolean;
        ItemDescription: Text[150];
        PrintGroupTotals: Boolean;
        DebitQuantity: Decimal;
        CreditQuantity: Decimal;
        DebitCost: Decimal;
        CreditCost: Decimal;
#pragma warning disable AA0074
        Text12400: Label 'Select Print Quantity or Print Cost or Print Group Totals';
#pragma warning restore AA0074
        PeriodText: Text[100];
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text12401: Label 'Total Cost for %1 %2';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text12402: Label 'Total Quantity for %1 %2';
#pragma warning restore AA0470
#pragma warning restore AA0074
        ShowDetails: Boolean;
        Debit: Decimal;
        Credit: Decimal;
        DetailedQtyPositive: Decimal;
        DetailedQtyNegative: Decimal;
        Turnover_SheetCaptionLbl: Label 'Turnover Sheet';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        ItemsCaptionLbl: Label 'Items';
        Start_of_periodCaptionLbl: Label 'Start of period';
        DescriptionCaptionLbl: Label 'Description';
        Item_No_CaptionLbl: Label 'Item No.';
        Positive_AdjustmentCaptionLbl: Label 'Positive Adjustment';
        Negative_AdjustmentCaptionLbl: Label 'Negative Adjustment';
        End_of_periodCaptionLbl: Label 'End of period';
        Period_Net_ChangeCaptionLbl: Label 'Period Net Change';
        Unit_of_MeasureCaptionLbl: Label 'Unit of Measure';
        TotalCaptionLbl: Label 'Total';

    local procedure TextValueLine(ZeroToBlank: Boolean)
    begin
        if StartDate > 0D then
            StartingQtyText := TextValue(StartingQty, ZeroToBlank)
        else
            StartingQtyText := '';
        EndingQtyText := TextValue(EndingQty, ZeroToBlank);
        IncreaseQtyText := TextValue(IncreaseQty, ZeroToBlank);
        DecreaseQtyText := TextValue(DecreaseQty, ZeroToBlank);
    end;

    local procedure TextValue(Value2: Decimal; ZeroToBlank: Boolean): Text[30]
    begin
        if ZeroToBlank and (Value2 = 0) then
            exit('');
        if Decimals > 1 then
            Value2 := Round(Value2 / Decimals, Decimals)
        else
            Value2 := Round(Value2, Decimals);
        exit(Format(Value2, 0, ValueFormat));
    end;

    [Scope('OnPrem')]
    procedure GetQuantityAndAmount(StartDate: Date; EndDate: Date)
    begin
        ValueEntry.SetCurrentKey("Item No.", "Posting Date", "Document No.", "Document Line No.");
        ValueEntry.SetRange("Posting Date", StartDate, EndDate);

        DebitQuantity := 0;
        DebitCost := 0;
        CreditQuantity := 0;
        CreditCost := 0;

        if ValueEntry.FindSet() then
            repeat
                if ValueEntry.IsDebit() then begin
                    DebitQuantity := DebitQuantity + ValueEntry."Invoiced Quantity";
                    DebitCost := DebitCost + ValueEntry."Cost Amount (Actual)";
                end else begin
                    CreditQuantity := CreditQuantity - ValueEntry."Invoiced Quantity";
                    CreditCost := CreditCost - ValueEntry."Cost Amount (Actual)";
                end;
            until ValueEntry.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure FillReportParameters()
    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'for period from %1 to %2';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text003: Label 'Replace zero values by blanks';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text004: Label 'Skip accounts without net change  ';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text005: Label 'Skip accounts without ending balance';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text006: Label 'Skip lines with zero values';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text007: Label '(in currency units)';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text008: Label '(in thousands)';
#pragma warning restore AA0074
    begin
        case RoundingPrecision of
            RoundingPrecision::"0.001":
                begin
                    ValueFormat := '<Sign><Integer Thousand><Decimals,4>';
                    Decimals := 0.001;
                    AmountUnit := '';
                end;
            RoundingPrecision::"0.01":
                begin
                    ValueFormat := '<Sign><Integer Thousand><Decimals,3>';
                    Decimals := 0.01;
                    AmountUnit := '';
                end;
            RoundingPrecision::"1":
                begin
                    ValueFormat := '<Sign><Integer Thousand>';
                    Decimals := 1;
                    AmountUnit := Text007;
                end;
            RoundingPrecision::"1000":
                begin
                    ValueFormat := '<Sign><Integer Thousand>';
                    Decimals := 1000;
                    AmountUnit := Text008;
                end;
        end;
        Counter := 0;
        if SkipZeroValues then begin
            Counter := Counter + 1;
            ReportParameters[Counter] := Text003;
        end;
        if SkipZeroNetChanges then begin
            Counter := Counter + 1;
            ReportParameters[Counter] := Text004;
        end;
        if SkipZeroBalances then begin
            Counter := Counter + 1;
            ReportParameters[Counter] := Text005;
        end;
        if SkipZeroLines then begin
            Counter := Counter + 1;
            ReportParameters[Counter] := Text006;
        end;

        PeriodText := StrSubstNo(Text001, StartDate, EndDate);
        PrintParameters := Counter > 0;
    end;
}
