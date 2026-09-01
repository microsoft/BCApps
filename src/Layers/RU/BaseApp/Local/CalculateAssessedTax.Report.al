#pragma warning disable AA0247
report 14920 "Calculate Assessed Tax"
{
    ApplicationArea = FixedAssets;
    Caption = 'Calculate Assessed Tax';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            DataItemTableView = sorting("No.") where("Vendor Type" = const("Tax Authority"));
            dataitem(OKATO; OKATO)
            {
                DataItemLink = "Tax Authority No." = field("No.");
                DataItemTableView = sorting(Code);
                dataitem(Chapter2; "Integer")
                {
                    DataItemTableView = sorting(Number);

                    trigger OnAfterGetRecord()
                    begin
                        Window.Update(2, 2);
                        FillSpecialInfo(2);

                        AssessedTaxCode.Reset();
                        AssessedTaxCode.SetRange("Region Code", OKATO."Region Code");
                        AssessedTaxCode.SetRange("Exemption Tax Allowance Code", '');
                        if AssessedTaxCode.Find('-') then
                            repeat
                                TempFixedAsset.Reset();
                                SetATCodeExemptFilters();

                                // Property Type = 1
                                TempFixedAsset.SetRange("Assessed Tax Code", AssessedTaxCode.Code);
                                TempFixedAsset.SetRange("Property Type", TempFixedAsset."Property Type"::"Immovable UGSS Property");
                                if TempFixedAsset.FindSet() then begin
                                    FillTitle[1] := true;
                                    repeat
                                        Clear(DeprCost);
                                        PageCounter[2] := PageCounter[2] + 1;
                                        DeleteSheet[2] := true;
                                        CalcPeriodDeprCost(TempFixedAsset."No.", AssessedTaxCode.Code);
                                        FillChapter2(TempFixedAsset."Property Type", TempFixedAsset."Property Type", AssessedTaxCode.Code);
                                    until TempFixedAsset.Next() = 0;
                                end;

                                if ReportingPeriod = 3 then begin
                                    TempFixedAsset.SetFilter("Tax Amount Paid Abroad", '<>0');
                                    if TempFixedAsset.FindSet() then begin
                                        FillTitle[1] := true;
                                        repeat
                                            Clear(DeprCost);
                                            PageCounter[2] := PageCounter[2] + 1;
                                            DeleteSheet[2] := true;
                                            TaxAmountAbroad := 0;
                                            CalcPeriodDeprCost(TempFixedAsset."No.", AssessedTaxCode.Code);
                                            TaxAmountAbroad := TaxAmountAbroad + TempFixedAsset."Tax Amount Paid Abroad";
                                            FillChapter2(TempFixedAsset."Property Type", 4, AssessedTaxCode.Code);
                                        until TempFixedAsset.Next() = 0;
                                    end;
                                    TempFixedAsset.SetRange("Tax Amount Paid Abroad");
                                end;

                                if AssessedTaxCodeExempt.FindSet() then
                                    repeat
                                        TempFixedAsset.SetRange("Assessed Tax Code", AssessedTaxCodeExempt.Code);
                                        if TempFixedAsset.FindSet() then begin
                                            FillTitle[1] := true;
                                            repeat
                                                Clear(DeprCost);
                                                PageCounter[2] := PageCounter[2] + 1;
                                                DeleteSheet[2] := true;
                                                CalcPeriodDeprCost(TempFixedAsset."No.", AssessedTaxCodeExempt.Code);
                                                FillChapter2(TempFixedAsset."Property Type", TempFixedAsset."Property Type", AssessedTaxCodeExempt.Code);
                                            until TempFixedAsset.Next() = 0;
                                        end;
                                    until AssessedTaxCodeExempt.Next() = 0;

                                // Property Type = 2
                                TempFixedAsset.SetRange("Assessed Tax Code", AssessedTaxCode.Code);
                                TempFixedAsset.SetRange("Property Type", TempFixedAsset."Property Type"::"Immovable Distributed Property");
                                if TempFixedAsset.FindSet() then begin
                                    FillTitle[2] := true;
                                    repeat
                                        Clear(DeprCost);
                                        PageCounter[2] := PageCounter[2] + 1;
                                        DeleteSheet[2] := true;
                                        CalcPeriodDeprCost(TempFixedAsset."No.", AssessedTaxCode.Code);
                                        FillChapter2(TempFixedAsset."Property Type", TempFixedAsset."Property Type", AssessedTaxCode.Code);
                                    until TempFixedAsset.Next() = 0;
                                end;

                                if ReportingPeriod = 3 then begin
                                    TempFixedAsset.SetFilter("Tax Amount Paid Abroad", '<>0');
                                    if TempFixedAsset.FindSet() then begin
                                        FillTitle[2] := true;
                                        repeat
                                            Clear(DeprCost);
                                            PageCounter[2] := PageCounter[2] + 1;
                                            DeleteSheet[2] := true;
                                            TaxAmountAbroad := 0;
                                            CalcPeriodDeprCost(TempFixedAsset."No.", AssessedTaxCode.Code);
                                            TaxAmountAbroad := TaxAmountAbroad + TempFixedAsset."Tax Amount Paid Abroad";
                                            FillChapter2(TempFixedAsset."Property Type", 4, AssessedTaxCode.Code);
                                        until TempFixedAsset.Next() = 0;
                                    end;
                                    TempFixedAsset.SetRange("Tax Amount Paid Abroad");
                                end;

                                if AssessedTaxCodeExempt.FindSet() then
                                    repeat
                                        TempFixedAsset.SetRange("Assessed Tax Code", AssessedTaxCodeExempt.Code);
                                        if TempFixedAsset.FindSet() then begin
                                            FillTitle[2] := true;
                                            repeat
                                                Clear(DeprCost);
                                                PageCounter[2] := PageCounter[2] + 1;
                                                DeleteSheet[2] := true;
                                                CalcPeriodDeprCost(TempFixedAsset."No.", AssessedTaxCodeExempt.Code);
                                                FillChapter2(TempFixedAsset."Property Type", TempFixedAsset."Property Type", AssessedTaxCodeExempt.Code);
                                            until TempFixedAsset.Next() = 0;
                                        end;
                                    until AssessedTaxCodeExempt.Next() = 0;

                                // Property Type = 3
                                TempFixedAsset.SetRange("Assessed Tax Code", AssessedTaxCode.Code);
                                TempFixedAsset.SetRange("Property Type", TempFixedAsset."Property Type"::"Other Property");
                                if TempFixedAsset.FindSet() then begin
                                    Clear(DeprCost);
                                    FillTitle[2] := true;
                                    PageCounter[2] := PageCounter[2] + 1;
                                    DeleteSheet[2] := true;
                                    repeat
                                        CalcPeriodDeprCost(TempFixedAsset."No.", AssessedTaxCode.Code);
                                    until TempFixedAsset.Next() = 0;
                                    FillChapter2(TempFixedAsset."Property Type", TempFixedAsset."Property Type", AssessedTaxCode.Code);
                                    MainSheetName := ExcelMgt.GetSheetName();
                                end;

                                if ReportingPeriod = 3 then begin
                                    TempFixedAsset.SetFilter("Tax Amount Paid Abroad", '<>0');
                                    if TempFixedAsset.FindSet() then begin
                                        Clear(DeprCost);
                                        FillTitle[2] := true;
                                        PageCounter[2] := PageCounter[2] + 1;
                                        DeleteSheet[2] := true;
                                        TaxAmountAbroad := 0;
                                        repeat
                                            CalcPeriodDeprCost(TempFixedAsset."No.", AssessedTaxCode.Code);
                                            TaxAmountAbroad := TaxAmountAbroad + TempFixedAsset."Tax Amount Paid Abroad";
                                        until TempFixedAsset.Next() = 0;
                                        FillChapter2(TempFixedAsset."Property Type", 4, AssessedTaxCode.Code);
                                    end;
                                    TempFixedAsset.SetRange("Tax Amount Paid Abroad");
                                end;

                                if AssessedTaxCodeExempt.FindSet() then
                                    repeat
                                        TempFixedAsset.SetRange("Assessed Tax Code", AssessedTaxCodeExempt.Code);
                                        if TempFixedAsset.FindSet() then begin
                                            FillTitle[2] := true;
                                            PageCounter[2] := PageCounter[2] + 1;
                                            DeleteSheet[2] := true;
                                            repeat
                                                CalcPeriodDeprCost(TempFixedAsset."No.", AssessedTaxCodeExempt.Code);
                                            until TempFixedAsset.Next() = 0;
                                            Exemption := true;
                                            FillChapter2(TempFixedAsset."Property Type", TempFixedAsset."Property Type", AssessedTaxCodeExempt.Code);
                                        end;
                                    until AssessedTaxCodeExempt.Next() = 0;

                                // Property Type = 5
                                TempFixedAsset.SetRange("Assessed Tax Code", AssessedTaxCode.Code);
                                TempFixedAsset.SetRange("Property Type", TempFixedAsset."Property Type"::"Special Economic Zone Property");
                                if TempFixedAsset.FindSet() then begin
                                    Clear(DeprCost);
                                    FillTitle[2] := true;
                                    PageCounter[2] := PageCounter[2] + 1;
                                    DeleteSheet[2] := true;
                                    repeat
                                        CalcPeriodDeprCost(TempFixedAsset."No.", AssessedTaxCode.Code);
                                    until TempFixedAsset.Next() = 0;
                                    FillChapter2(TempFixedAsset."Property Type", TempFixedAsset."Property Type", AssessedTaxCode.Code);
                                end;

                                if ReportingPeriod = 3 then begin
                                    TempFixedAsset.SetFilter("Tax Amount Paid Abroad", '<>0');
                                    if TempFixedAsset.FindSet() then begin
                                        Clear(DeprCost);
                                        FillTitle[2] := true;
                                        PageCounter[2] := PageCounter[2] + 1;
                                        DeleteSheet[2] := true;
                                        TaxAmountAbroad := 0;
                                        repeat
                                            CalcPeriodDeprCost(TempFixedAsset."No.", AssessedTaxCode.Code);
                                            TaxAmountAbroad := TaxAmountAbroad + TempFixedAsset."Tax Amount Paid Abroad";
                                        until TempFixedAsset.Next() = 0;
                                        FillChapter2(TempFixedAsset."Property Type", 4, AssessedTaxCode.Code);
                                    end;
                                    TempFixedAsset.SetRange("Tax Amount Paid Abroad");
                                end;

                                if AssessedTaxCodeExempt.FindSet() then
                                    repeat
                                        TempFixedAsset.SetRange("Assessed Tax Code", AssessedTaxCodeExempt.Code);
                                        if TempFixedAsset.FindSet() then begin
                                            Clear(DeprCost);
                                            FillTitle[2] := true;
                                            PageCounter[2] := PageCounter[2] + 1;
                                            DeleteSheet[2] := true;
                                            repeat
                                                CalcPeriodDeprCost(TempFixedAsset."No.", AssessedTaxCodeExempt.Code);
                                            until TempFixedAsset.Next() = 0;
                                            FillChapter2(TempFixedAsset."Property Type", TempFixedAsset."Property Type", AssessedTaxCodeExempt.Code);
                                        end;
                                    until AssessedTaxCodeExempt.Next() = 0;

                            until AssessedTaxCode.Next() = 0;
                        CurrReport.Break();
                    end;
                }
                dataitem(Chapter1; "Integer")
                {
                    DataItemTableView = sorting(Number);

                    trigger OnAfterGetRecord()
                    begin
                        Window.Update(2, 1);
                        Window.Update(3, '');
                        FillSpecialInfo(1);

                        if (not FillTitle[1]) and (not FillTitle[2]) then
                            OKATOCounter := OKATOCounter - 1;

                        CreateSheet := (OKATOCounter = 1) and (FillTitle[1] or FillTitle[2]);

                        if OKATOCounter > Ch1BlockCounter then begin
                            PageCounter[1] := PageCounter[1] + 1;
                            OKATOCounter := 1;
                            CreateSheet := true;
                        end;

                        SheetName := '00001' + '#' + Format(PageCounter[1]);

                        if CreateSheet then begin
                            ExcelMgt.CopySheet('00001', '00002', SheetName);
                            CreateSheet := false;
                        end;

                        if FillTitle[1] or FillTitle[2] then
                            ExcelMgt.OpenSheet(SheetName);

                        if OKATOCounter = 1 then begin
                            Shift := 1;
                            StartCell := OKATOCounter * 10 + 1;
                            if ReportingPeriod <> 3 then
                                StartCell := StartCell + 1;
                        end else begin
                            Shift := OKATOCounter * PeriodFactor - PeriodShift;
                            StartCell := OKATOCounter * 10 - Shift;
                        end;

                        if FillTitle[1] then begin
                            ExcelMgt.FillCellsGroup2('BI' + Format(StartCell), 11, 1, OKATO.Code, '0', 1);
                            ExcelMgt.FillCellsGroup2('BI' + Format(StartCell + 2), 20, 1, FASetup."KBK (UGSS)", '0', 1);
                            if TotalAmount[1] < 0 then
                                ExcelMgt.FillCellsGroup2('BI' + Format(StartCell + 4), 15, 1, '', '-', 1)
                            else
                                ExcelMgt.FillCellsGroup2(
                                  'BI' + Format(StartCell + 4), 15, 1, Format(TotalAmount[1] - TotalAmount[3], 0, 1), '-', 1);
                            if OKATOCounter > Ch1BlockCounter then begin
                                PageCounter[1] := PageCounter[1] + 1;
                                OKATOCounter := 0;
                                CreateSheet := true;
                            end;
                            if FillTitle[2] then begin
                                OKATOCounter := OKATOCounter + 1;
                                Shift := OKATOCounter * PeriodFactor - PeriodShift;
                                StartCell := OKATOCounter * 10 - Shift;
                            end;
                        end;

                        SheetName := '00001' + '#' + Format(PageCounter[1]);
                        ExcelMgt.WriteAllToCurrentSheet();

                        if CreateSheet then begin
                            ExcelMgt.CopySheet('00001', '00002', SheetName);
                            CreateSheet := false;
                        end;

                        if FillTitle[1] or FillTitle[2] then
                            ExcelMgt.OpenSheet(SheetName);

                        if FillTitle[2] then begin
                            ExcelMgt.FillCellsGroup2('BI' + Format(StartCell), 11, 1, OKATO.Code, '0', 1);
                            ExcelMgt.FillCellsGroup2('BI' + Format(StartCell + 2), 20, 1, FASetup.KBK, '0', 1);
                            if TotalAmount[2] < 0 then
                                ExcelMgt.FillCellsGroup2('BI' + Format(StartCell + 4), 15, 1, '', '-', 1)
                            else
                                ExcelMgt.FillCellsGroup2(
                                  'BI' + Format(StartCell + 4), 15, 1, Format(TotalAmount[2] - TotalAmount[4], 0, 1), '-', 1);
                        end;

                        DeleteSheet[1] := true;
                        ExcelMgt.WriteAllToCurrentSheet();

                        CurrReport.Break();
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    TempFixedAsset.Reset();
                    TempFixedAsset.DeleteAll();
                    FixedAsset.Reset();
                    if FixedAsset.Find('-') then begin
                        FixedAsset.SetRange(Blocked, false);
                        FixedAsset.SetRange("FA Type", FixedAsset."FA Type"::"Fixed Assets");
                        FixedAsset.SetFilter("Property Type", '<>%1', FixedAsset."Property Type"::" ");
                        FixedAsset.SetFilter("Assessed Tax Code", '<>%1', '');
                        FixedAsset.SetFilter("Main Asset/Component", '<>%1', FixedAsset."Main Asset/Component"::"Main Asset");
                        if FixedAsset.FindFirst() then
                            repeat
                                InsertTempFA := false;
                                ReportingDate := StartingDate;
                                for I := 1 to (3 * (ReportingPeriod + 1) + 1) do begin
                                    CalcTempDeprCost(FixedAsset."No.", ReportingDate);
                                    if TempDeprCost > 0 then
                                        InsertTempFA := true;
                                    ReportingDate := CalcDate('<+1M>', ReportingDate);
                                    if I = 13 then
                                        ReportingDate := CalcDate('<-1D>', ReportingDate);
                                end;
                                if InsertTempFA and (not TempFixedAsset.Get(FixedAsset."No.")) then begin
                                    TempFixedAsset.Init();
                                    TempFixedAsset.TransferFields(FixedAsset);
                                    TempFixedAsset.Insert();
                                end;
                            until FixedAsset.Next() = 0;
                    end;

                    if TempFixedAsset.Count = 0 then
                        CurrReport.Skip();

                    OKATOCounter := OKATOCounter + 1;

                    Clear(TotalAmount);
                    Clear(FillTitle);

                    Window.Update(1, Code);
                end;

                trigger OnPreDataItem()
                begin
                    Clear(PageCounter);
                    Clear(DeleteSheet);
                    LineNo := 1;
                    PageCounter[1] := 1;
                    OKATOCounter := 0;
                    if ReportingPeriod = 3 then begin
                        Ch1BlockCounter := 6;
                        PeriodShift := 3;
                        PeriodFactor := 2;
                    end else begin
                        Ch1BlockCounter := 7;
                        PeriodShift := 5;
                        PeriodFactor := 3;
                    end;
                end;
            }
            dataitem(Title; "Integer")
            {
                DataItemTableView = sorting(Number);

                trigger OnAfterGetRecord()
                begin
                    FillSpecialInfo(3);

                    for I := 1 to 3 do
                        if DeleteSheet[I] = true then
                            ExcelMgt.DeleteSheet('0000' + Format(I));

                    SheetName := 'Title';
                    ExcelMgt.OpenSheet(SheetName);
                    ExcelMgt.FillCellsGroup2('AK1', 12, 1, CompanyInfo."VAT Registration No.", '-', 1);
                    ExcelMgt.FillCellsGroup2('AK4', 9, 1, CompanyInfo."KPP Code", '-', 1);

                    case ReportingPeriod of
                        0:
                            if Reorganization then
                                ExcelMgt.FillCellsGroup2('BV10', 2, 1, '51', '-', 1)
                            else
                                ExcelMgt.FillCellsGroup2('BV10', 2, 1, '21', '-', 1);
                        1:
                            if Reorganization then
                                ExcelMgt.FillCellsGroup2('BV10', 2, 1, '52', '-', 1)
                            else
                                ExcelMgt.FillCellsGroup2('BV10', 2, 1, '31', '-', 1);
                        2:
                            if Reorganization then
                                ExcelMgt.FillCellsGroup2('BV10', 2, 1, '53', '-', 1)
                            else
                                ExcelMgt.FillCellsGroup2('BV10', 2, 1, '33', '-', 1);
                        3:
                            if Reorganization then
                                ExcelMgt.FillCellsGroup2('BV10', 2, 1, '50', '-', 1)
                            else
                                ExcelMgt.FillCellsGroup2('BV10', 2, 1, '34', '-', 1);
                    end;

                    ExcelMgt.FillCellsGroup2('DE10', 4, 1, Format(Year), '-', 1);
                    TaxAuthCode := CopyStr(Vendor."VAT Registration No.", 1, 4);
                    ExcelMgt.FillCellsGroup2('AY12', 4, 1, TaxAuthCode, '-', 1);
                    ExcelMgt.FillCellsGroup2('DH12', 3, 1, Format(Submitted), '-', 1);
                    ExcelMgt.FillCellsGroup2('CG23', 8, 1, CompanyInfo."OKVED Code", '-', 1);
                    ExcelMgt.FillCellsGroup2('A14', 40, 4, CompanyInfo.Name + CompanyInfo."Name 2", '-', 1);
                    ExcelMgt.FillCellsGroup2('AK27', 20, 1, CompanyInfo."Phone No.", '-', 1);
                    if Reorganization then begin
                        if ReportingPeriod = 3 then
                            ExcelMgt.FillCell('AB25', Format(ReorganizationType))
                        else
                            ExcelMgt.FillCell('X25', Format(ReorganizationType));
                        ExcelMgt.FillCellsGroup2('BJ25', 10, 1, VATRegNo, '-', 1);
                        ExcelMgt.FillCellsGroup2('CP25', 9, 1, KPPCode, '-', 1);
                    end;

                    if not Representative then begin
                        ExcelMgt.FillCell('M35', '1');
                        ExcelMgt.FillCellsGroup2('A37', 20, 1, Employee."Last Name", '-', 1);
                        ExcelMgt.FillCellsGroup2('A40', 20, 1, Employee."First Name", '-', 1);
                        ExcelMgt.FillCellsGroup2('A44', 20, 1, Employee."Middle Name", '-', 1);
                    end else begin
                        ExcelMgt.FillCell('M35', '2');
                        ExcelMgt.FillCellsGroup2('A37', 20, 1, CompanyInfo."Representative Last Name", '-', 1);
                        ExcelMgt.FillCellsGroup2('A40', 20, 1, CompanyInfo."Representative First Name", '-', 1);
                        ExcelMgt.FillCellsGroup2('A44', 20, 1, CompanyInfo."Representative Middle Name", '-', 1);
                        ExcelMgt.FillCellsGroup2('A48', 20, 8, CompanyInfo."Representative Organization", '-', 1);
                        ExcelMgt.FillCellsGroup2('A74', 20, 2, CompanyInfo."Representative Document", '-', 1);
                    end;

                    if not DetailedInfo then
                        ExcelMgt.DeleteSheet('Info');

                    if DetailedInfo then
                        PageCounter[6] := ExcelMgt.GetSheetsCount() - 1
                    else
                        PageCounter[6] := ExcelMgt.GetSheetsCount();
                    ExcelMgt.WriteAllToCurrentSheet();

                    ExcelMgt.OpenSheet('Title');
                    ExcelMgt.FillCellsGroup2('E29', 3, 1, Format(PageCounter[6]), '-', 1);
                    ExcelMgt.WriteAllToCurrentSheet();

                    PageText := '001';
                    for I := 2 to PageCounter[6] do begin
                        PageText := IncStr(PageText);
                        ExcelMgt.OpenSheetByNumber(I);
                        ExcelMgt.FillCellsGroup2('BR4', 3, 1, PageText, '0', 0);
                        ExcelMgt.WriteAllToCurrentSheet();

                        if CopyStr(ExcelMgt.GetSheetName(), 6) = '#1' then
                            ExcelMgt.SetSheetName(CopyStr(ExcelMgt.GetSheetName(), 1, 5));
                    end;
                    CurrReport.Break();
                end;
            }

            trigger OnAfterGetRecord()
            var
            begin
            end;

            trigger OnPostDataItem()
            begin
                Window.Close();
                if FileNameSilent <> '' then begin
                    ExcelMgt.SaveWrkBook(FileNameSilent);
                    ExcelMgt.CloseBook();
                end else begin
                    ExcelMgt.OpenSheet('Title');
                    ExcelMgt.DownloadBook(TemplateFileName);
                end;
            end;

            trigger OnPreDataItem()
            var
                ExcelTemplate: Record "Excel Template";
                FileName: Text[250];
            begin
                CompanyInfo.Get();
                FASetup.Get();
                Employee.Get(CompanyInfo."Director No.");
                CheckATCodeDuplicate();
                if ReportingPeriod = 3 then begin
                    FASetup.TestField("AT Declaration Template Code");
                    FileName := ExcelTemplate.OpenTemplate(FASetup."AT Declaration Template Code");
                    TemplateFileName := ExcelTemplate.GetTemplateFileName(FASetup."AT Declaration Template Code");
                end else begin
                    FASetup.TestField("AT Advance Template Code");
                    FileName := ExcelTemplate.OpenTemplate(FASetup."AT Advance Template Code");
                    TemplateFileName := ExcelTemplate.GetTemplateFileName(FASetup."AT Advance Template Code");
                end;

                ExcelMgt.OpenBookForUpdate(FileName);
                ExcelMgt.OpenSheet('Title');
                Window.Open(Text007);
                TaxAuthority.Get(TaxAuthNo);
                SetRange("No.", TaxAuthority."No.");
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
                    field(TaxAuthNo; TaxAuthNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Tax Authority No.';
                        TableRelation = Vendor where("Vendor Type" = const("Tax Authority"));
                    }
                    field(Year; Year)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Year';
                        ToolTip = 'Specifies the year.';

                        trigger OnValidate()
                        begin
                            CalculatePeriod();
                        end;
                    }
                    field(ReportingPeriod; ReportingPeriod)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Reporting Period';
                        OptionCaption = '1 quarter,1 half-year,9 months,year';
                        ToolTip = 'Specifies the reporting period.';

                        trigger OnValidate()
                        begin
                            CalculatePeriod();
                        end;
                    }
                    field(StartingDate; StartingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'From';
                        Editable = false;
                        ToolTip = 'Specifies the starting point.';
                    }
                    field(EndingDate; EndingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'To';
                        Editable = false;
                        ToolTip = 'Specifies the ending point.';
                    }
                    field(Representative; Representative)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Approved by Representative';
                    }
                    group(Submitted)
                    {
                        Caption = 'Submitted';
                        field(Control1210003; Submitted)
                        {
                            ApplicationArea = Basic, Suite;
                            ShowCaption = false;
                            OptionCaption = '213 - At the place of the largest taxpayer,214 - At the place of Russian organization,215 - At the place of location of assignee which is not the largest taxpayer,216 - At the place of accounting of assignee which is the largest taxpayer,221 - At the place of separated unit with separate balance,245 - At the place of foreign company registration,281 - At the place of real-estate object';
                        }
                    }
                    group(Reorganization)
                    {
                        Caption = 'Reorganization';
                        field("Reorganization (Liquidation)"; Reorganization)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Reorganization (Liquidation)';
                            ToolTip = 'Specifies information about liquidation.';
                        }
                        field(ReorganizationType; ReorganizationType)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Reorganization Type';
                            OptionCaption = ' ,1 - Reorganization,2 - Merging,3 - Disjoining,5 - Joining,6 - Disjoining with simultaneous joining,0 - Liquidation';
                            ToolTip = 'Specifies the type of the reorganization.';
                        }
                        field(VATRegNo; VATRegNo)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'VAT Registration No.';
                        }
                        field(KPPCode; KPPCode)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'KPP Code';
                            ToolTip = 'Specifies the company registration code.';
                        }
                    }
                    field(DetailedInfo; DetailedInfo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Detailed Info Sheet';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            Year := Date2DMY(WorkDate(), 3);
            CalculatePeriod();
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        if TaxAuthNo = '' then
            Error(Text008);
    end;

    var
        CompanyInfo: Record "Company Information";
        FASetup: Record "FA Setup";
        FADeprBook: Record "FA Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        TempFixedAsset: Record "Fixed Asset" temporary;
        FALocation: Record "FA Location";
        AssessedTaxCode: Record "Assessed Tax Code";
        AssessedTaxCodeExempt: Record "Assessed Tax Code";
        TaxAuthority: Record Vendor;
        Employee: Record Employee;
        ExcelMgt: Codeunit "Excel Management";
        Window: Dialog;
        TaxAuthNo: Code[20];
        DeprCost: array[13, 4] of Decimal;
        TempDeprCost: Decimal;
        TotalAmount: array[4] of Decimal;
        LineNo: Integer;
        Year: Integer;
        I: Integer;
        J: Integer;
        StartCell: Integer;
        Shift: Integer;
        PageCounter: array[6] of Integer;
        Ch1BlockCounter: Integer;
        PeriodShift: Integer;
        PeriodFactor: Integer;
        ReportingPeriod: Option;
        StartingDate: Date;
        EndingDate: Date;
        ReportingDate: Date;
        SheetName: Text[30];
        MainSheetName: Text[30];
        TaxAuthCode: Text[4];
        PageText: Text[3];
        TemplateFileName: Text;
        CreateSheet: Boolean;
        DeleteSheet: array[3] of Boolean;
        DetailedInfo: Boolean;
        FillTitle: array[2] of Boolean;
        InsertTempFA: Boolean;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text007: Label 'OKATO Code #1####\Chapter #2####\FA No. #3####';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text008: Label 'Select Tax Authority No.';
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text010: Label 'There are duplicate Assessed Tax Codes: Assessed Tax Code=%1 and Assessed Tax Code=%2. Remove one of them.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text011: Label 'Base Assessed Tax Code should exist for Assessed Tax Code=%1.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        Representative: Boolean;
        Exemption: Boolean;
        TaxAmountAbroad: Decimal;
        OKATOCounter: Integer;
        Submitted: Option "213","214","215","216","221","245","281";
        ReorganizationType: Option " ","1","2","3","5","6","0";
        Reorganization: Boolean;
        VATRegNo: Code[20];
        KPPCode: Code[10];
        FileNameSilent: Text;

    [Scope('OnPrem')]
    procedure FillChapter2(PropertyType: Integer; PropertyType2: Integer; ATCode: Code[20])
    begin
        if ReportingPeriod = 3 then
            FillYear(PropertyType, PropertyType2, ATCode)
        else
            FillNotYear(PropertyType, PropertyType2, ATCode);
    end;

    [Scope('OnPrem')]
    procedure FillYear(PropertyType: Integer; PropertyType2: Integer; ATCode: Code[20])
    var
        AssessedTaxCode2: Record "Assessed Tax Code";
        AssessedTaxAllowance: Record "Assessed Tax Allowance";
        LineAmount: array[8] of Decimal;
    begin
        RoundDeprCost();
        Clear(LineAmount);
        AssessedTaxCode2.Get(ATCode);

        if not Exemption then begin
            SheetName := '00002' + '#' + Format(PageCounter[2]);
            ExcelMgt.CopySheet('00002', '00003', SheetName);
            ExcelMgt.OpenSheet(SheetName);
        end else
            SheetName := MainSheetName;
        ExcelMgt.OpenSheet(SheetName);
        ExcelMgt.FillCell('Y11', Format(PropertyType2));
        ExcelMgt.FillCellsGroup2('CH11', 11, 1, OKATO.Code, '0', 1);

        J := 17;

        // Line #020 - #140
        for I := 1 to 13 do begin
            LineAmount[1] := LineAmount[1] + DeprCost[I] [1];
            LineAmount[2] := LineAmount[2] + DeprCost[I] [2];
            ExcelMgt.FillCellsGroup2('X' + Format(I + J), 15, 1, Format(DeprCost[I] [1], 0, 1), '-', 1);
            if AssessedTaxCode2."Exemption Tax Allowance Code" <> '' then
                ExcelMgt.FillCellsGroup2('BU' + Format(I + J), 15, 1, Format(DeprCost[I] [2], 0, 1), '-', 1);
            J := J + 1;
            if DeprCost[I] [3] <> 0 then
                LineAmount[7] := DeprCost[I] [3];
            if DeprCost[I] [4] <> 0 then
                LineAmount[8] := DeprCost[I] [4];
        end;
        if LineAmount[7] <> 0 then
            ExcelMgt.FillCellsGroup2('X44', 15, 1, Format(LineAmount[7], 0, 1), '-', 1);
        if LineAmount[8] <> 0 then
            ExcelMgt.FillCellsGroup2('BU44', 15, 1, Format(LineAmount[8], 0, 1), '-', 1);

        // Line #150
        LineAmount[1] := Round(LineAmount[1] / 13, 1, '=');
        ExcelMgt.FillCellsGroup2('BF49', 15, 1, Format(LineAmount[1], 0, 1), '-', 1);

        // Line #160 - #170
        LineAmount[2] := Round(LineAmount[2] / 13, 1, '=');
        if AssessedTaxCode2."Exemption Tax Allowance Code" <> '' then begin
            ExcelMgt.FillCellsGroup2('BF51', 7, 1, AssessedTaxCode2."Exemption Tax Allowance Code", '-', 1);
            AssessedTaxAllowance.Get(AssessedTaxCode2."Exemption Tax Allowance Code");
            ExcelMgt.FillCellsGroup2(
              'CD51', 12, 1,
              AssessedTaxAllowance."Article Number" + AssessedTaxAllowance."Clause Number" +
              AssessedTaxAllowance."Subclause Number", '-', 1);
            ExcelMgt.FillCellsGroup2('BF54', 15, 1, Format(LineAmount[2], 0, 1), '-', 1);
        end;

        // Line #180
        if PropertyType = 2 then
            if TempFixedAsset."Book Value per Share" <> 0 then
                if (TempFixedAsset."Book Value per Share" * 100 - ((TempFixedAsset."Book Value per Share" * 100) div 10)) <> 0
                then begin
                    ExcelMgt.FillCellsGroup2('BF57', 10, 1, Format(TempFixedAsset."Book Value per Share" * 100), '-', 1);
                    ExcelMgt.FillCellsGroup2('CM57', 10, 1, Format(100), '-', 1);
                end else begin
                    ExcelMgt.FillCellsGroup2('BF57', 10, 1, Format(TempFixedAsset."Book Value per Share" * 10), '-', 1);
                    ExcelMgt.FillCellsGroup2('CM57', 10, 1, Format(10), '-', 1);
                end;

        // Line #190
        if PropertyType = 2 then
            LineAmount[3] := Round((LineAmount[1] - LineAmount[2]) * TempFixedAsset."Book Value per Share", 1, '=')
        else
            LineAmount[3] := LineAmount[1] - LineAmount[2];
        ExcelMgt.FillCellsGroup2('BF59', 15, 1, Format(LineAmount[3], 0, 1), '-', 1);

        // Line #200
        if AssessedTaxCode2."Dec. Rate Tax Allowance Code" <> '' then begin
            ExcelMgt.FillCellsGroup2('BF61', 7, 1, AssessedTaxCode2."Dec. Rate Tax Allowance Code", '-', 1);
            AssessedTaxAllowance.Get(AssessedTaxCode2."Dec. Rate Tax Allowance Code");
            ExcelMgt.FillCellsGroup2(
              'CD61', 12, 1,
              AssessedTaxAllowance."Article Number" + AssessedTaxAllowance."Clause Number" +
              AssessedTaxAllowance."Subclause Number", '-', 1);
        end;
        FillYearRest(LineAmount, PropertyType, PropertyType2, ATCode);
        ExcelMgt.WriteAllToCurrentSheet();
    end;

    [Scope('OnPrem')]
    procedure FillYearRest(var LineAmount: array[8] of Decimal; PropertyType: Integer; PropertyType2: Integer; ATCode: Code[20])
    var
        AssessedTaxCode2: Record "Assessed Tax Code";
        AssessedTaxAllowance: Record "Assessed Tax Allowance";
        Decimals: Decimal;
    begin
        AssessedTaxCode2.Get(ATCode);
        // Line #210
        ExcelMgt.FillCellsGroup2('BF63', 1, 1, Format(AssessedTaxCode2."Rate %" div 1), '-', 1);
        Decimals := (AssessedTaxCode2."Rate %" - AssessedTaxCode2."Rate %" div 1);
        ExcelMgt.FillCellsGroup2('BL63', 2, 1, Format(Decimals * 100), '-', 1);

        // Line #220
        LineAmount[4] := LineAmount[3] * AssessedTaxCode2."Rate %" / 100;
        if PropertyType = 1 then
            if TempFixedAsset."Book Value per Share" <> 0 then
                LineAmount[4] := LineAmount[4] * TempFixedAsset."Book Value per Share";
        LineAmount[4] := Round(LineAmount[4], 1, '=');
        ExcelMgt.FillCellsGroup2('BF65', 15, 1, Format(LineAmount[4], 0, 1), '-', 1);

        // Line #240 - #250
        if AssessedTaxCode2."Dec. Amount Tax Allowance Code" <> '' then begin
            ExcelMgt.FillCellsGroup2('BF71', 7, 1, AssessedTaxCode2."Dec. Amount Tax Allowance Code", '-', 1);
            AssessedTaxAllowance.Get(AssessedTaxCode2."Dec. Amount Tax Allowance Code");
            ExcelMgt.FillCellsGroup2(
              'CD71', 12, 1,
              AssessedTaxAllowance."Article Number" + AssessedTaxAllowance."Clause Number" +
              AssessedTaxAllowance."Subclause Number", '-', 1);
            if AssessedTaxCode2."Decreasing Amount Type" = AssessedTaxCode2."Decreasing Amount Type"::Percent then
                LineAmount[5] := Round(LineAmount[4] * AssessedTaxCode2."Decreasing Amount" / 100, 1, '=')
            else
                LineAmount[5] := Round(AssessedTaxCode2."Decreasing Amount", 1, '=');
            ExcelMgt.FillCellsGroup2('BF74', 15, 1, Format(LineAmount[5], 0, 1), '-', 1);
        end;

        // Line #260
        if PropertyType2 = 4 then begin
            TaxAmountAbroad := Round(TaxAmountAbroad, 1, '=');
            ExcelMgt.FillCellsGroup2('BF77', 15, 1, Format(TaxAmountAbroad, 0, 1), '-', 1);
        end;
        if not Exemption then
            case PropertyType of
                1:
                    if PropertyType2 <> 4 then
                        TotalAmount[1] := TotalAmount[1] + LineAmount[4] - LineAmount[5]
                    else
                        if (LineAmount[4] - LineAmount[5]) <= TaxAmountAbroad then
                            TotalAmount[3] := TotalAmount[3] + (LineAmount[4] - LineAmount[5])
                        else
                            TotalAmount[3] := TotalAmount[3] + TaxAmountAbroad;
                2, 3, 5:
                    if PropertyType2 <> 4 then
                        TotalAmount[2] := TotalAmount[2] + LineAmount[4] - LineAmount[5]
                    else
                        if (LineAmount[4] - LineAmount[5]) <= TaxAmountAbroad then
                            TotalAmount[4] := TotalAmount[4] + (LineAmount[4] - LineAmount[5])
                        else
                            TotalAmount[4] := TotalAmount[4] + TaxAmountAbroad;
            end;

        Exemption := false;
    end;

    [Scope('OnPrem')]
    procedure FillNotYear(PropertyType: Integer; PropertyType2: Integer; ATCode: Code[20])
    var
        AssessedTaxCode2: Record "Assessed Tax Code";
        AssessedTaxAllowance: Record "Assessed Tax Allowance";
        LineAmount: array[8] of Decimal;
        Decimals: Decimal;
    begin
        RoundDeprCost();
        Clear(LineAmount);
        AssessedTaxCode2.Get(ATCode);

        if not Exemption then begin
            SheetName := '00002' + '#' + Format(PageCounter[2]);
            ExcelMgt.CopySheet('00002', '00003', SheetName);
        end else
            SheetName := MainSheetName;

        ExcelMgt.OpenSheet(SheetName);
        ExcelMgt.FillCell('Y12', Format(PropertyType2));
        ExcelMgt.FillCellsGroup2('CH12', 11, 1, OKATO.Code, '0', 1);

        J := 20;
        // Line #020 - #110
        for I := 1 to ((ReportingPeriod + 1) * 3 + 1) do begin
            LineAmount[1] := LineAmount[1] + DeprCost[I] [1];
            LineAmount[2] := LineAmount[2] + DeprCost[I] [2];
            ExcelMgt.FillCellsGroup2('X' + Format(I + J), 15, 1, Format(DeprCost[I] [1], 0, 1), '-', 1);
            if AssessedTaxCode2."Exemption Tax Allowance Code" <> '' then
                ExcelMgt.FillCellsGroup2('BU' + Format(I + J), 15, 1, Format(DeprCost[I] [2], 0, 1), '-', 1);
            J := J + 1;
        end;

        // Line #120
        LineAmount[1] := Round(LineAmount[1] / ((ReportingPeriod + 1) * 3 + 1), 1, '=');
        ExcelMgt.FillCellsGroup2('BF47', 15, 1, Format(LineAmount[1], 0, 1), '-', 1);

        // Line #130 - #140
        LineAmount[2] := Round(LineAmount[2] / ((ReportingPeriod + 1) * 3 + 1), 1, '=');
        if AssessedTaxCode2."Exemption Tax Allowance Code" <> '' then begin
            ExcelMgt.FillCellsGroup2('BF49', 7, 1, AssessedTaxCode2."Exemption Tax Allowance Code", '-', 1);
            AssessedTaxAllowance.Get(AssessedTaxCode2."Exemption Tax Allowance Code");
            ExcelMgt.FillCellsGroup2(
              'CD49', 12, 1,
              AssessedTaxAllowance."Article Number" + AssessedTaxAllowance."Clause Number" +
              AssessedTaxAllowance."Subclause Number", '-', 1);
            ExcelMgt.FillCellsGroup2('BF52', 15, 1, Format(LineAmount[2], 0, 1), '-', 1);
        end;

        // Line #150
        if PropertyType = 2 then
            if TempFixedAsset."Book Value per Share" <> 0 then
                if (TempFixedAsset."Book Value per Share" * 100 - ((TempFixedAsset."Book Value per Share" * 100) div 10)) <> 0
                then begin
                    ExcelMgt.FillCellsGroup2('BF55', 10, 1, Format(TempFixedAsset."Book Value per Share" * 100), '-', 1);
                    ExcelMgt.FillCellsGroup2('CM55', 10, 1, Format(100), '-', 1);
                end else begin
                    ExcelMgt.FillCellsGroup2('BF55', 10, 1, Format(TempFixedAsset."Book Value per Share" * 10), '-', 1);
                    ExcelMgt.FillCellsGroup2('CM55', 10, 1, Format(10), '-', 1);
                end;

        // Line #160
        if AssessedTaxCode2."Dec. Rate Tax Allowance Code" <> '' then begin
            ExcelMgt.FillCellsGroup2('BF58', 7, 1, AssessedTaxCode2."Dec. Rate Tax Allowance Code", '-', 1);
            AssessedTaxAllowance.Get(AssessedTaxCode2."Dec. Rate Tax Allowance Code");
            ExcelMgt.FillCellsGroup2(
              'CD58', 12, 1,
              AssessedTaxAllowance."Article Number" + AssessedTaxAllowance."Clause Number" +
              AssessedTaxAllowance."Subclause Number", '-', 1);
        end;

        // Line #170
        ExcelMgt.FillCellsGroup2('BF60', 1, 1, Format(AssessedTaxCode2."Rate %" div 1), '-', 1);
        Decimals := (AssessedTaxCode2."Rate %" - AssessedTaxCode2."Rate %" div 1);
        ExcelMgt.FillCellsGroup2('BL60', 2, 1, Format(Decimals * 100), '-', 1);

        // Line #180
        LineAmount[3] := LineAmount[1] - LineAmount[2];
        LineAmount[4] := LineAmount[3] * AssessedTaxCode2."Rate %" / 100 / 4;
        if PropertyType in [1, 2] then
            if TempFixedAsset."Book Value per Share" <> 0 then
                LineAmount[4] := LineAmount[4] * TempFixedAsset."Book Value per Share";
        LineAmount[4] := Round(LineAmount[4], 1, '=');
        ExcelMgt.FillCellsGroup2('BF62', 15, 1, Format(LineAmount[4], 0, 1), '-', 1);

        // Line #190 - #200
        if AssessedTaxCode2."Dec. Amount Tax Allowance Code" <> '' then begin
            ExcelMgt.FillCellsGroup2('BF65', 7, 1, AssessedTaxCode2."Dec. Amount Tax Allowance Code", '-', 1);
            AssessedTaxAllowance.Get(AssessedTaxCode2."Dec. Amount Tax Allowance Code");
            ExcelMgt.FillCellsGroup2(
              'CD65', 12, 1,
              AssessedTaxAllowance."Article Number" + AssessedTaxAllowance."Clause Number" +
              AssessedTaxAllowance."Subclause Number", '-', 1);
            if AssessedTaxCode2."Decreasing Amount Type" = AssessedTaxCode2."Decreasing Amount Type"::Percent then
                LineAmount[5] := Round(LineAmount[4] * AssessedTaxCode2."Decreasing Amount" / 100 / 4, 1, '=')
            else
                LineAmount[5] := Round(AssessedTaxCode2."Decreasing Amount" / 4, 1, '=');
            ExcelMgt.FillCellsGroup2('BF68', 15, 1, Format(LineAmount[5], 0, 1), '-', 1);
        end;
        if not Exemption then
            if PropertyType = 1 then
                TotalAmount[1] := TotalAmount[1] + LineAmount[4] - LineAmount[5]
            else
                TotalAmount[2] := TotalAmount[2] + LineAmount[4] - LineAmount[5];

        Exemption := false;
        ExcelMgt.WriteAllToCurrentSheet();
    end;

    [Scope('OnPrem')]
    procedure FillInfoSheet(TitleString: Boolean)
    begin
        if DetailedInfo then begin
            LineNo := LineNo + 1;
            ExcelMgt.OpenSheet('Info');
            if TitleString then begin
                ExcelMgt.FillCell('A' + Format(LineNo), TempFixedAsset."No.");
                ExcelMgt.FillCell('B' + Format(LineNo), TempFixedAsset.Description);
                ExcelMgt.FillCell('C' + Format(LineNo), Format(TempFixedAsset."Property Type"));
                ExcelMgt.FillCell('D' + Format(LineNo), Format(TempFixedAsset."OKATO Code"));
                ExcelMgt.FillCell('E' + Format(LineNo), Format(TempFixedAsset."Assessed Tax Code"));
                ExcelMgt.FillCell('F' + Format(LineNo), Format(AssessedTaxCode."Dec. Rate Tax Allowance Code"));
                ExcelMgt.FillCell('G' + Format(LineNo), Format(AssessedTaxCode."Dec. Amount Tax Allowance Code"));
                ExcelMgt.FillCell('H' + Format(LineNo), Format(AssessedTaxCode."Decreasing Amount Type"));
                ExcelMgt.FillCell('I' + Format(LineNo), Format(AssessedTaxCode."Decreasing Amount"));
            end else begin
                ExcelMgt.FillCell('J' + Format(LineNo), Format(ReportingDate));
                ExcelMgt.FillCell('K' + Format(LineNo), Format(TempDeprCost, 0, 1));
            end;
        end;
        ExcelMgt.WriteAllToCurrentSheet();
    end;

    [Scope('OnPrem')]
    procedure FillSpecialInfo(ChapterNo: Integer)
    begin
        SheetName := '0000' + Format(ChapterNo);
        ExcelMgt.OpenSheet(SheetName);
        ExcelMgt.FillCellsGroup2('AK1', 12, 1, CompanyInfo."VAT Registration No.", '-', 1);
        ExcelMgt.FillCellsGroup2('AK4', 9, 1, CompanyInfo."KPP Code", '-', 1);
        ExcelMgt.WriteAllToCurrentSheet();
    end;

    [Scope('OnPrem')]
    procedure CalculatePeriod()
    begin
        StartingDate := DMY2Date(1, 1, Year);
        EndingDate := CalcDate('<' + Format(3 * (ReportingPeriod + 1) - 1) + 'M>' + '<+CM>', StartingDate);
    end;

    [Scope('OnPrem')]
    procedure CalcTempDeprCost(FANo: Code[20]; CalculationDate: Date)
    var
        FALocationCode: Code[20];
        EmployeeNo: Code[20];
    begin
        TempDeprCost := 0;
        FADeprBook.Reset();
        FADeprBook.SetRange("FA No.", FANo);
        FADeprBook.SetRange("Depreciation Book Code", FASetup."Release Depr. Book");
        FADeprBook.SetRange("FA Posting Date Filter", 0D, CalcDate('<-1D>', CalculationDate));
        if FADeprBook.Find('-') then begin
            FADeprBook.CalcFields("Book Value");
            FADeprBook.GetLocationAtDate(FALocationCode, EmployeeNo, CalculationDate);
            if FALocation.Get(FALocationCode) then
                if FALocation."OKATO Code" = OKATO.Code then
                    TempDeprCost := TempDeprCost + FADeprBook."Book Value";
        end;
    end;

    [Scope('OnPrem')]
    procedure CalcPeriodDeprCost(FANo: Code[20]; ATCode: Code[20])
    var
        AssessedTaxCode2: Record "Assessed Tax Code";
        ImmovableFA: Boolean;
    begin
        AssessedTaxCode2.Get(ATCode);
        ReportingDate := StartingDate;
        FillInfoSheet(true);
        ImmovableFA := IsImmovableFA(FANo);
        for I := 1 to (3 * (ReportingPeriod + 1) + 1) do begin
            CalcTempDeprCost(FANo, ReportingDate);
            DeprCost[I] [1] := DeprCost[I] [1] + TempDeprCost;
            if ImmovableFA then
                DeprCost[I] [3] := DeprCost[I] [3] + TempDeprCost;
            if AssessedTaxCode2."Exemption Tax Allowance Code" <> '' then begin
                DeprCost[I] [2] := DeprCost[I] [2] + TempDeprCost;
                if ImmovableFA then
                    DeprCost[I] [4] := DeprCost[I] [4] + TempDeprCost;
            end;
            FillInfoSheet(false);
            ReportingDate := CalcDate('<+1M>', ReportingDate);
            if I = 13 then
                ReportingDate := CalcDate('<-1D>', ReportingDate);
        end;
    end;

    local procedure RoundDeprCost()
    var
        J: Integer;
    begin
        for I := 1 to ArrayLen(DeprCost, 1) do
            for J := 1 to ArrayLen(DeprCost, 2) do
                DeprCost[I] [J] := Round(DeprCost[I] [J], 1);
    end;

    [Scope('OnPrem')]
    procedure SetATCodeExemptFilters()
    begin
        AssessedTaxCodeExempt.Reset();
        AssessedTaxCodeExempt.SetRange("Region Code", OKATO."Region Code");
        AssessedTaxCodeExempt.SetRange("Rate %", AssessedTaxCode."Rate %");
        AssessedTaxCodeExempt.SetRange("Dec. Rate Tax Allowance Code", AssessedTaxCode."Dec. Rate Tax Allowance Code");
        AssessedTaxCodeExempt.SetRange("Dec. Amount Tax Allowance Code", AssessedTaxCode."Dec. Amount Tax Allowance Code");
        AssessedTaxCodeExempt.SetFilter("Exemption Tax Allowance Code", '<>%1', '');
    end;

    [Scope('OnPrem')]
    procedure CheckATCodeDuplicate()
    var
        AssessedTaxCodeDublicate: Record "Assessed Tax Code";
        OKATO1: Record OKATO;
    begin
        OKATO1.Reset();
        OKATO1.SetRange("Tax Authority No.", TaxAuthNo);
        if OKATO1.Find('-') then
            repeat
                AssessedTaxCode.Reset();
                AssessedTaxCode.SetRange("Region Code", OKATO1."Region Code");
                if AssessedTaxCode.Find('-') then
                    repeat
                        AssessedTaxCodeDublicate.Reset();
                        AssessedTaxCodeDublicate.SetFilter(Code, '<>%1', AssessedTaxCode.Code);
                        AssessedTaxCodeDublicate.SetRange("Region Code", AssessedTaxCode."Region Code");
                        AssessedTaxCodeDublicate.SetRange("Rate %", AssessedTaxCode."Rate %");
                        AssessedTaxCodeDublicate.SetRange("Dec. Rate Tax Allowance Code", AssessedTaxCode."Dec. Rate Tax Allowance Code");
                        if AssessedTaxCode."Exemption Tax Allowance Code" = '' then
                            AssessedTaxCodeDublicate.SetRange("Exemption Tax Allowance Code", '')
                        else begin
                            AssessedTaxCodeDublicate.SetRange("Dec. Amount Tax Allowance Code", AssessedTaxCode."Dec. Amount Tax Allowance Code");
                            AssessedTaxCodeDublicate.SetRange("Exemption Tax Allowance Code", AssessedTaxCode."Exemption Tax Allowance Code");
                        end;
                        if AssessedTaxCodeDublicate.Find('-') then
                            Error(Text010, AssessedTaxCode.Code, AssessedTaxCodeDublicate.Code);
                        if AssessedTaxCode."Exemption Tax Allowance Code" <> '' then
                            CheckBaseCode();
                    until AssessedTaxCode.Next() = 0;
            until OKATO1.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure CheckBaseCode()
    var
        AssessedTaxCodeBase: Record "Assessed Tax Code";
    begin
        AssessedTaxCodeBase.Reset();
        AssessedTaxCodeBase.SetRange("Region Code", AssessedTaxCode."Region Code");
        AssessedTaxCodeBase.SetRange("Rate %", AssessedTaxCode."Rate %");
        AssessedTaxCodeBase.SetRange("Dec. Rate Tax Allowance Code", AssessedTaxCode."Dec. Rate Tax Allowance Code");
        AssessedTaxCodeBase.SetRange("Dec. Amount Tax Allowance Code", AssessedTaxCode."Dec. Amount Tax Allowance Code");
        AssessedTaxCodeBase.SetRange("Exemption Tax Allowance Code", '');
        if not AssessedTaxCodeBase.Find('-') then
            Error(Text011, AssessedTaxCode.Code);
    end;

    [Scope('OnPrem')]
    procedure IsImmovableFA(FANo: Code[20]): Boolean
    var
        TempFA: Record "Fixed Asset";
    begin
        TempFA.Get(FANo);
        exit(TempFA."FA Type for Taxation" = TempFA."FA Type for Taxation"::Immovable);
    end;

    [Scope('OnPrem')]
    procedure InitializeRequest(NewTaxAuthNo: Code[20]; NewYear: Integer; NewReportingPeriod: Integer; NewStartingDate: Date; NewEndingDate: Date; NewSubmitted: Integer; NewReorganization: Boolean; NewDetailedInfo: Boolean)
    begin
        TaxAuthNo := NewTaxAuthNo;
        Year := NewYear;
        ReportingPeriod := NewReportingPeriod;
        StartingDate := NewStartingDate;
        EndingDate := NewEndingDate;
        Submitted := NewSubmitted;
        Reorganization := NewReorganization;
        DetailedInfo := NewDetailedInfo;
    end;

    [Scope('OnPrem')]
    procedure SetFileNameSilent(NewFileNameSilent: Text)
    begin
        FileNameSilent := NewFileNameSilent;
    end;
}

