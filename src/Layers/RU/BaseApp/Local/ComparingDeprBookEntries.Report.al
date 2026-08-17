#pragma warning disable AA0247
report 14970 "Comparing Depr. Book Entries"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/ComparingDeprBookEntries.rdlc';
    ApplicationArea = FixedAssets;
    Caption = 'Comparing Depr. Book Entries';
    EnableHyperlinks = true;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(FA; "Fixed Asset")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "FA Class Code", "FA Subclass Code", "FA Type", "Depreciation Group", "Belonging to Manufacturing";
            column(Heading; Heading)
            {
            }
            column(FIlters; FIlters)
            {
            }
            column(USERID; UserId)
            {
            }
            column(CurrentDate; CurrentDate)
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(FA__No__; "No.")
            {
            }
            column(FA_FA_Description; Description)
            {
            }
            column(FADeprBook2__Book_Value_; FADeprBook2."Book Value")
            {
            }
            column(TotalDepr2; TotalDepr2)
            {
            }
            column(FADeprBook2_Depreciation; FADeprBook2.Depreciation)
            {
            }
            column(FADeprBook2__Write_Down____FADeprBook2_Appreciation; FADeprBook2."Write-Down" + FADeprBook2.Appreciation)
            {
            }
            column(FADeprBook2__Acquisition_Cost_; FADeprBook2."Acquisition Cost")
            {
            }
            column(FADeprBook2__Depreciation_Book_Code_; FADeprBook2."Depreciation Book Code")
            {
            }
            column(FADeprBook1__Acquisition_Cost_; FADeprBook1."Acquisition Cost")
            {
            }
            column(FADeprBook1_Depreciation; FADeprBook1.Depreciation)
            {
            }
            column(FADeprBook1__Book_Value_; FADeprBook1."Book Value")
            {
            }
            column(FADeprBook1__Depreciation_Book_Code_; FADeprBook1."Depreciation Book Code")
            {
            }
            column(FADeprBook1__Write_Down____FADeprBook1_Appreciation; FADeprBook1."Write-Down" + FADeprBook1.Appreciation)
            {
            }
            column(TotalDepr; TotalDepr)
            {
            }
            column(GroupByDeprGroup; GroupByDeprGroup)
            {
            }
            column(RollUpByDeprGroup; RollUpByDeprGroup)
            {
            }
            column(FADeprGroup; FADeprGroup)
            {
            }
            column(FALink; Format(FALink.RecordId, 0, 10))
            {
            }
            column(FADeprBook1Link; Format(FADeprBook1Link.RecordId, 0, 10))
            {
            }
            column(FADeprBook2Link; Format(FADeprBook2Link.RecordId, 0, 10))
            {
            }
            column(GroupTotals_2_Index___Book_Value__; GroupTotals[2, Index::"Book Value"])
            {
            }
            column(GroupTotals_2_Index___Total_Depr__; GroupTotals[2, Index::"Total Depr"])
            {
            }
            column(GroupTotals_1_Index___Book_Value__; GroupTotals[1, Index::"Book Value"])
            {
            }
            column(GroupTotals_1_Index___Total_Depr__; GroupTotals[1, Index::"Total Depr"])
            {
            }
            column(GroupTotals_2_Index__Depreciation_; GroupTotals[2, Index::Depreciation])
            {
            }
            column(GroupTotals_1_Index__Depreciation_; GroupTotals[1, Index::Depreciation])
            {
            }
            column(GroupTotals_1_Index__Changes_; GroupTotals[1, Index::Changes])
            {
            }
            column(GroupTotals_2_Index__Changes_; GroupTotals[2, Index::Changes])
            {
            }
            column(GroupTotals_1_Index__Acquisition_; GroupTotals[1, Index::Acquisition])
            {
            }
            column(GroupTotals_2_Index__Acquisition_; GroupTotals[2, Index::Acquisition])
            {
            }
            column(DeprBookCode1; DeprBookCode1)
            {
            }
            column(DeprBookCode2; DeprBookCode2)
            {
            }
            column(STRSUBSTNO_Text003_DepreciationGroup_Code_DepreciationGroup_Description_; StrSubstNo(Text003, DepreciationGroup.Code, DepreciationGroup.Description))
            {
            }
            column(Totals_2_Index___Book_Value__; Totals[2, Index::"Book Value"])
            {
            }
            column(Totals_2_Index__Depreciation_; Totals[2, Index::Depreciation])
            {
            }
            column(Totals_1_Index__Depreciation_; Totals[1, Index::Depreciation])
            {
            }
            column(Totals_1_Index___Book_Value__; Totals[1, Index::"Book Value"])
            {
            }
            column(Totals_1_Index__Changes_; Totals[1, Index::Changes])
            {
            }
            column(Totals_2_Index__Changes_; Totals[2, Index::Changes])
            {
            }
            column(Totals_1_Index__Acquisition_; Totals[1, Index::Acquisition])
            {
            }
            column(Totals_2_Index__Acquisition_; Totals[2, Index::Acquisition])
            {
            }
            column(DeprBookCode1_Control1210071; DeprBookCode1)
            {
            }
            column(DeprBookCode2_Control1210072; DeprBookCode2)
            {
            }
            column(Totals_1_Index___Total_Depr__; Totals[1, Index::"Total Depr"])
            {
            }
            column(Totals_2_Index___Total_Depr__; Totals[2, Index::"Total Depr"])
            {
            }
            column(Book_ValueCaption; Book_ValueCaptionLbl)
            {
            }
            column(Total_DepreciationCaption; Total_DepreciationCaptionLbl)
            {
            }
            column(Depreciation_for_PeriodCaption; Depreciation_for_PeriodCaptionLbl)
            {
            }
            column(Appreciation__Write_DownCaption; Appreciation__Write_DownCaptionLbl)
            {
            }
            column(Acquisition_CostCaption; Acquisition_CostCaptionLbl)
            {
            }
            column(Depreciation_Book_CodeCaption; Depreciation_Book_CodeCaptionLbl)
            {
            }
            column(DescriptionCaption; DescriptionCaptionLbl)
            {
            }
            column(FA_No_Caption; FA_No_CaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(Fixed_AssetsCaption; Fixed_AssetsCaptionLbl)
            {
            }
            column(Book_ValueCaption_Control1210000; Book_ValueCaption_Control1210000Lbl)
            {
            }
            column(Total_DepreciationCaption_Control1210001; Total_DepreciationCaption_Control1210001Lbl)
            {
            }
            column(Depreciation_for_PeriodCaption_Control1210003; Depreciation_for_PeriodCaption_Control1210003Lbl)
            {
            }
            column(Appreciation__Write_DownCaption_Control1210005; Appreciation__Write_DownCaption_Control1210005Lbl)
            {
            }
            column(Acquisition_CostCaption_Control1210007; Acquisition_CostCaption_Control1210007Lbl)
            {
            }
            column(Depreciation_Book_CodeCaption_Control1210008; Depreciation_Book_CodeCaption_Control1210008Lbl)
            {
            }
            column(DescriptionCaption_Control1210010; DescriptionCaption_Control1210010Lbl)
            {
            }
            column(FA_No_Caption_Control1210011; FA_No_Caption_Control1210011Lbl)
            {
            }
            column(Totals_Caption; Totals_CaptionLbl)
            {
            }
            column(FA_Depreciation_Group; "Depreciation Group")
            {
            }

            trigger OnAfterGetRecord()
            begin
                Clear(FADeprBook1);
                Clear(FADeprBook2);
                if not FADeprBook1.Get("No.", DeprBookCode1) and not FADeprBook2.Get("No.", DeprBookCode2) then
                    CurrReport.Skip();

                if GroupByDeprGroup then begin
                    if DepreciationGroup.Get("Depreciation Group") then;

                    if PrevGroup <> "Depreciation Group" then
                        ClearGroupTotal := true
                    else
                        ClearGroupTotal := false;

                    if ClearGroupTotal then
                        Clear(GroupTotals);

                    PrevGroup := "Depreciation Group";

                    FADeprGroup := "Depreciation Group";
                end;

                FADeprBook1Link.SetPosition(FADeprBook1.GetPosition());
                FADeprBook2Link.SetPosition(FADeprBook2.GetPosition());


                if ReportDate <> 0D then
                    FADeprBook1.SetFilter("FA Posting Date Filter", '..%1', ReportDate);
                FADeprBook1.CalcFields("Acquisition Cost", Depreciation, "Book Value", "Write-Down", Appreciation);
                TotalDepr := FADeprBook1.Depreciation;
                if (StartDate <> 0D) or (ReportDate <> 0D) then
                    FADeprBook1.SetFilter("FA Posting Date Filter", '%1..%2', StartDate, ReportDate);
                FADeprBook1.CalcFields(Depreciation);
                IncTotals(1, FADeprBook1."Acquisition Cost", FADeprBook1.Depreciation, TotalDepr,
                  FADeprBook1."Book Value", FADeprBook1."Write-Down" + FADeprBook1.Appreciation);

                if ReportDate <> 0D then
                    FADeprBook2.SetFilter("FA Posting Date Filter", '..%1', ReportDate);
                FADeprBook2.CalcFields("Acquisition Cost", Depreciation, "Book Value", "Write-Down", Appreciation);
                TotalDepr2 := FADeprBook2.Depreciation;
                if (StartDate <> 0D) or (ReportDate <> 0D) then
                    FADeprBook2.SetFilter("FA Posting Date Filter", '%1..%2', StartDate, ReportDate);
                FADeprBook2.CalcFields(Depreciation);

                IncTotals(2, FADeprBook2."Acquisition Cost", FADeprBook2.Depreciation, TotalDepr2,
                  FADeprBook2."Book Value", FADeprBook2."Write-Down" + FADeprBook2.Appreciation);

                FALink.SetPosition(GetPosition());
            end;

            trigger OnPreDataItem()
            var
                FixedAsset: Record "Fixed Asset";
            begin
                Heading := Text000 + Format(StartDate) + ' . . ' + Format(ReportDate);
                FIlters := CopyStr(GetFilters, 1, 250);
                Clear(Totals);

                Clear(GroupTotals);

                if GroupByDeprGroup then begin
                    SetCurrentKey("Depreciation Group");

                    FixedAsset.SetCurrentKey("Depreciation Group");
                    FixedAsset.CopyFilters(FA);
                    if FixedAsset.FindFirst() then
                        PrevGroup := FixedAsset."Depreciation Group"
                end;

                if RollUpByDeprGroup then
                    if GetFilters <> '' then
                        if not Confirm(Text004) then
                            Error('');

                FADeprGroup := '';
                FALink.Open(DATABASE::"Fixed Asset");

                FADeprBook1Link.Open(DATABASE::"FA Depreciation Book");
                FADeprBook2Link.Open(DATABASE::"FA Depreciation Book");
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
                    field(DeprBookCode1; DeprBookCode1)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Depr. Book 1';
                        TableRelation = "Depreciation Book";
                    }
                    field(DeprBookCode2; DeprBookCode2)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Depr. Book 2';
                        TableRelation = "Depreciation Book";
                    }
                    field(StartDate; StartDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Date of the Period Beginning';

                        trigger OnValidate()
                        begin
                            if StartDate <> 0D then
                                ReportDate := CalcDate('<CM>', StartDate);
                        end;
                    }
                    field(ReportDate; ReportDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Date of the Period Ending';

                        trigger OnValidate()
                        begin
                            if ReportDate < StartDate then
                                Error(Text002);
                        end;
                    }
                    field(ShowNull; ShowNull)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show empty lines';
                    }
                    field(GroupByDeprGroup; GroupByDeprGroup)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Group By Depr. Group';

                        trigger OnValidate()
                        begin
                            GroupByDeprGroupOnAfterValidat();
                        end;
                    }
                    field(RollUpGrCheckBox; RollUpByDeprGroup)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Roll Up By Depr. Group';
                        Enabled = RollUpGrCheckBoxEnable;
                        ToolTip = 'Specifies if you want to summarize entries by depreciation groups.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            RollUpGrCheckBoxEnable := true;
        end;

        trigger OnOpenPage()
        begin
            FASetup.Get();
            if DeprBook.Get(FASetup."Release Depr. Book") then
                DeprBookCode1 := DeprBook.Code;

            TaxRegisterSetup.Get();
            if DeprBook.Get(TaxRegisterSetup."Tax Depreciation Book") then
                DeprBookCode2 := DeprBook.Code;

            UpdateControls();
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        CurrentDate := LocMgt.Date2Text(Today()) + Format(Time(), 0, '(<Hours24>:<Minutes>)');

        if (DeprBookCode1 = '') or (DeprBookCode2 = '') then
            Error(Text001);
    end;

    var
        FASetup: Record "FA Setup";
        DeprBook: Record "Depreciation Book";
        FADeprBook1: Record "FA Depreciation Book";
        FADeprBook2: Record "FA Depreciation Book";
        TaxRegisterSetup: Record "Tax Register Setup";
        DepreciationGroup: Record "Depreciation Group";
        LocMgt: Codeunit "Localisation Management";
        FALink: RecordRef;
        FADeprBook1Link: RecordRef;
        FADeprBook2Link: RecordRef;
        DeprBookCode1: Code[10];
        DeprBookCode2: Code[10];
        ReportDate: Date;
#pragma warning disable AA0074
        Text001: Label 'Please define two depreciation books to compare.';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text002: Label 'Date of the end of the period should not be more dates of its beginning.';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text000: Label 'Comparing of depreciation books operations for the period: ';
#pragma warning restore AA0074
        Heading: Text[150];
        StartDate: Date;
        Totals: array[2, 5] of Decimal;
        GroupTotals: array[2, 5] of Decimal;
        Index: Option ,Acquisition,Depreciation,"Total Depr",Changes,"Book Value";
        TotalDepr: Decimal;
        TotalDepr2: Decimal;
        NotNull: Boolean;
        ShowNull: Boolean;
        FIlters: Text[250];
        GroupByDeprGroup: Boolean;
        RollUpByDeprGroup: Boolean;
        ClearGroupTotal: Boolean;
        PrevGroup: Code[10];
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text003: Label 'Depr. Group %1 %2 Total';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text004: Label 'There are some FA which do not included to the report. Continue?';
#pragma warning restore AA0074
        CurrentDate: Text[30];
        FADeprGroup: Code[10];
        RollUpGrCheckBoxEnable: Boolean;
        Book_ValueCaptionLbl: Label 'Book Value';
        Total_DepreciationCaptionLbl: Label 'Total Depreciation';
        Depreciation_for_PeriodCaptionLbl: Label 'Depreciation for Period';
        Appreciation__Write_DownCaptionLbl: Label 'Appreciation, Write-Down';
        Acquisition_CostCaptionLbl: Label 'Acquisition Cost';
        Depreciation_Book_CodeCaptionLbl: Label 'Depreciation Book Code';
        DescriptionCaptionLbl: Label 'Description';
        FA_No_CaptionLbl: Label 'FA No.';
        PageCaptionLbl: Label 'Page';
        Fixed_AssetsCaptionLbl: Label 'Depr. Book';
        Book_ValueCaption_Control1210000Lbl: Label 'Book Value';
        Total_DepreciationCaption_Control1210001Lbl: Label 'Total Depreciation';
        Depreciation_for_PeriodCaption_Control1210003Lbl: Label 'Depreciation for Period';
        Appreciation__Write_DownCaption_Control1210005Lbl: Label 'Appreciation, Write-Down';
        Acquisition_CostCaption_Control1210007Lbl: Label 'Acquisition Cost';
        Depreciation_Book_CodeCaption_Control1210008Lbl: Label 'Depreciation Book Code';
        DescriptionCaption_Control1210010Lbl: Label 'Description';
        FA_No_Caption_Control1210011Lbl: Label 'FA No.';
        Totals_CaptionLbl: Label 'Totals:';

    [Scope('OnPrem')]
    procedure IncTotals(Level: Integer; Acquisition: Decimal; Depreciation: Decimal; TotalDepr: Decimal; BookValue: Decimal; Change: Decimal)
    begin
        Totals[Level, Index::Acquisition] += Acquisition;
        Totals[Level, Index::Depreciation] += Depreciation;
        Totals[Level, Index::"Total Depr"] += TotalDepr;
        Totals[Level, Index::"Book Value"] += BookValue;
        Totals[Level, Index::Changes] += Change;
        NotNull :=
          NotNull or
          (Acquisition <> 0) or
          (Depreciation <> 0) or
          (TotalDepr <> 0) or
          (BookValue <> 0) or
          (Change <> 0);

        if GroupByDeprGroup then begin
            GroupTotals[Level, Index::Acquisition] += Acquisition;
            GroupTotals[Level, Index::Depreciation] += Depreciation;
            GroupTotals[Level, Index::"Total Depr"] += TotalDepr;
            GroupTotals[Level, Index::"Book Value"] += BookValue;
            GroupTotals[Level, Index::Changes] += Change;
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateControls()
    begin
        PageUpdateControls();
    end;

    local procedure GroupByDeprGroupOnAfterValidat()
    begin
        UpdateControls();
    end;

    local procedure PageUpdateControls()
    begin
        RollUpGrCheckBoxEnable := GroupByDeprGroup;
        if not GroupByDeprGroup then
            RollUpByDeprGroup := false;
    end;
}

