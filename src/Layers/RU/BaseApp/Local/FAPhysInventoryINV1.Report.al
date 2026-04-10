#pragma warning disable AA0247
report 12486 "FA Phys. Inventory INV-1"
{
    Caption = 'FA Phys. Inventory INV-1';
    ProcessingOnly = true;

    dataset
    {
        dataitem("FA Journal Line"; "FA Journal Line")
        {
            DataItemTableView = sorting("Journal Template Name", "Journal Batch Name", "Line No.");
            RequestFilterFields = "Journal Template Name", "Journal Batch Name", "Document No.", "Location Code", "Employee No.";

            trigger OnAfterGetRecord()
            begin
                FixetAsset.Get("FA No.");

                if not ExcelReportBuilderMgr.TryAddSectionWithPlaceForFooter('MAINPAGEBODY', 'MAINPAGEFOOTER') then begin
                    ExcelReportBuilderMgr.AddSection('MAINPAGEFOOTER');
                    FillMainPageTotals();

                    ExcelReportBuilderMgr.AddPagebreak();
                    ExcelReportBuilderMgr.AddSection('MAINPAGEHEADER');
                    ExcelReportBuilderMgr.AddSection('MAINPAGEBODY');

                    NumberPPPage := 0;
                    Clear(PageAmounts);
                end;

                NumberPP += 1;
                NumberPPPage += 1;
                AddTotals(PageAmounts, "Actual Quantity", "Actual Amount", "Calc. Quantity", "Calc. Amount");
                AddTotals(TotalAmounts, "Actual Quantity", "Actual Amount", "Calc. Quantity", "Calc. Amount");

                ExcelReportBuilderMgr.AddDataToSection('LineNum', Format(NumberPP));
                ExcelReportBuilderMgr.AddDataToSection('AssetName', Description);
                ExcelReportBuilderMgr.AddDataToSection('ManufacturingYear', Format(FixetAsset."Manufacturing Year"));
                ExcelReportBuilderMgr.AddDataToSection('InventoryNumber', FixetAsset."Inventory Number");
                ExcelReportBuilderMgr.AddDataToSection('FactoryNumber', FixetAsset."Factory No.");
                ExcelReportBuilderMgr.AddDataToSection('PassportNo', FixetAsset."Passport No.");
                ExcelReportBuilderMgr.AddDataToSection('FactQty', StdRepMgt.FormatReportValue("Actual Quantity", 2));
                ExcelReportBuilderMgr.AddDataToSection('FactAmount', StdRepMgt.FormatReportValue("Actual Amount", 2));
                ExcelReportBuilderMgr.AddDataToSection('CalcQty', StdRepMgt.FormatReportValue("Calc. Quantity", 2));
                ExcelReportBuilderMgr.AddDataToSection('CalcAmount', StdRepMgt.FormatReportValue("Calc. Amount", 2));
            end;

            trigger OnPostDataItem()
            begin
                ExcelReportBuilderMgr.AddSection('MAINPAGEFOOTER');
                FillMainPageTotals();
                ExcelReportBuilderMgr.AddPagebreak();

                FillLastPage();
            end;

            trigger OnPreDataItem()
            begin
                CompanyInf.Get();
                if FindFirst() then
                    InvSheetNo := "Document No.";

                if FALocation.Get(GetFilter("Location Code")) then;

                if not Employee.Get(GetFilter("Employee No.")) then
                    if Employee.Get(FALocation."Employee No.") then;

                ExcelReportBuilderMgr.SetSheet('Sheet1');
                FillFirstPage();
                ExcelReportBuilderMgr.AddSection('MAINPAGEHEADER');
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
                    field(InventoryDate; CreatDate)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Inventory Date';
                        ToolTip = 'Specifies the creation date of the document.';
                    }
                    field(DocumentNo; DocumentNo)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Document No.';
                        ToolTip = 'Specifies the number of the related document.';
                    }
                    field(DocumentDate; DocumentDate)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Document Date';
                        ToolTip = 'Specifies the creation date of the related document.';
                    }
                    field(StartDate; StartDate)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the beginning of the period for which entries are adjusted. This field is usually left blank, but you can enter a date.';
                    }
                    field(EndDate; EndDate)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the date to which the report or batch job processes information.';
                    }
                    field(Chairman; Chairman)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Chairman';
                        TableRelation = Employee;
                        ToolTip = 'Specifies the name of the employee who leads the commission.';
                    }
                    field(Commission1; Commission1)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Commission Member1';
                        TableRelation = Employee;
                        ToolTip = 'Specifies the name of the employee who makes up the commission.';
                    }
                    field(Commission2; Commission2)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Commission Member2';
                        TableRelation = Employee;
                        ToolTip = 'Specifies the name of the employee who makes up the commission.';
                    }
                    field(Commission3; Commission3)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Commission Member3';
                        TableRelation = Employee;
                        ToolTip = 'Specifies the name of the employee who makes up the commission.';
                    }
                    field(WhoCheck; WhoCheck)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Checked by';
                        TableRelation = Employee;
                        ToolTip = 'Specifies the name of the employee who checks the document.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            CreatDate := WorkDate();
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        if FileName <> '' then
            ExcelReportBuilderMgr.ExportDataToClientFile(FileName)
        else
            ExcelReportBuilderMgr.ExportData();
    end;

    trigger OnPreReport()
    var
        FASetup: Record "FA Setup";
    begin
        FASetup.Get();
        FASetup.TestField("INV-1 Template Code");
        ExcelReportBuilderMgr.InitTemplate(FASetup."INV-1 Template Code");
    end;

    var
        CompanyInf: Record "Company Information";
        FALocation: Record "FA Location";
        FixetAsset: Record "Fixed Asset";
        Employee: Record Employee;
        LocMgt: Codeunit "Localisation Management";
        StdRepMgt: Codeunit "Local Report Management";
        ExcelReportBuilderMgr: Codeunit "Excel Report Builder Manager";
        StartDate: Date;
        EndDate: Date;
        DocumentNo: Code[10];
        DocumentDate: Date;
        CreatDate: Date;
        Chairman: Text[250];
        Commission1: Text[250];
        Commission2: Text[250];
        Commission3: Text[250];
        WhoCheck: Text[250];
        FileName: Text;
        InvSheetNo: Code[10];
        ValueIndex: Option ,FactQty,FactAmt,CalcQty,CalcAmt;
        PageAmounts: array[4] of Decimal;
        TotalAmounts: array[4] of Decimal;
        NumberPP: Integer;
        NumberPPPage: Integer;

    [Scope('OnPrem')]
    procedure SetFileNameSilent(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;

    local procedure AddTotals(var TotalArr: array[4] of Decimal; FactQty: Decimal; FactAmt: Decimal; CalcQty: Decimal; CalcAmt: Decimal)
    begin
        TotalArr[ValueIndex::FactQty] += FactQty;
        TotalArr[ValueIndex::FactAmt] += FactAmt;
        TotalArr[ValueIndex::CalcQty] += CalcQty;
        TotalArr[ValueIndex::CalcAmt] += CalcAmt;
    end;

    local procedure FillFirstPage()
    begin
        ExcelReportBuilderMgr.AddSection('FIRSTPAGE');

        ExcelReportBuilderMgr.AddDataToSection('InventJournalNum', InvSheetNo);
        ExcelReportBuilderMgr.AddDataToSection('InventJournalDate', Format(CreatDate));
        ExcelReportBuilderMgr.AddDataToSection('CompanyName', StdRepMgt.GetCompanyName());
        ExcelReportBuilderMgr.AddDataToSection('DepartmentName', StdRepMgt.GetEmpDepartment(Employee."No."));
        ExcelReportBuilderMgr.AddDataToSection('OKPO', CompanyInf."OKPO Code");
        ExcelReportBuilderMgr.AddDataToSection('DocumentNo', DocumentNo);
        ExcelReportBuilderMgr.AddDataToSection('DocumentDate', Format(DocumentDate));
        ExcelReportBuilderMgr.AddDataToSection('InventStartDate', Format(StartDate));
        ExcelReportBuilderMgr.AddDataToSection('InventEndDate', Format(EndDate));
        ExcelReportBuilderMgr.AddDataToSection('LocationName', FALocation.Name);
        ExcelReportBuilderMgr.AddDataToSection('RespFirstPageTitle1', StdRepMgt.GetEmpPosition(Employee."No."));
        ExcelReportBuilderMgr.AddDataToSection('RespFirstPageName1', StdRepMgt.GetEmpName(Employee."No."));
        ExcelReportBuilderMgr.AddPagebreak();
    end;

    local procedure FillMainPageTotals()
    begin
        ExcelReportBuilderMgr.AddDataToSection('FactQtyTotal', StdRepMgt.FormatReportValue(PageAmounts[ValueIndex::FactQty], 2));
        ExcelReportBuilderMgr.AddDataToSection('FactCostTotal', StdRepMgt.FormatReportValue(PageAmounts[ValueIndex::FactAmt], 2));
        ExcelReportBuilderMgr.AddDataToSection('AccountingQtyTotal',
          StdRepMgt.FormatReportValue(PageAmounts[ValueIndex::CalcQty], 2));
        ExcelReportBuilderMgr.AddDataToSection('AccountingCostTotal',
          StdRepMgt.FormatReportValue(PageAmounts[ValueIndex::CalcAmt], 2));

        ExcelReportBuilderMgr.AddDataToSection('LineNumPageTotalStr', LocMgt.Integer2Text(NumberPPPage, 2, '', '', ''));
        ExcelReportBuilderMgr.AddDataToSection('FactQtyPageTxt', LocMgt.Integer2Text(PageAmounts[ValueIndex::FactQty], 2, '', '', ''));

        ExcelReportBuilderMgr.AddDataToSection('FactCostPageTxt', LocMgt.Amount2Text('', PageAmounts[ValueIndex::FactAmt]));
    end;

    local procedure FillLastPage()
    begin
        ExcelReportBuilderMgr.AddSection('LASTPAGE');

        ExcelReportBuilderMgr.AddDataToSection('LineNumTotalStr', LocMgt.Integer2Text(NumberPP, 2, '', '', ''));
        ExcelReportBuilderMgr.AddDataToSection('FactQtyTxt', LocMgt.Integer2Text(TotalAmounts[ValueIndex::FactQty], 2, '', '', ''));
        ExcelReportBuilderMgr.AddDataToSection('FactCostTxt', LocMgt.Amount2Text('', TotalAmounts[ValueIndex::FactAmt]));
        ExcelReportBuilderMgr.AddDataToSection('TotalNumStr', Format(NumberPP));

        ExcelReportBuilderMgr.AddDataToSection('Chairman', StdRepMgt.GetEmpPosition(Chairman));
        ExcelReportBuilderMgr.AddDataToSection('ChairmanName', StdRepMgt.GetEmpName(Chairman));
        ExcelReportBuilderMgr.AddDataToSection('Member1', StdRepMgt.GetEmpPosition(Commission1));
        ExcelReportBuilderMgr.AddDataToSection('MemberName1', StdRepMgt.GetEmpName(Commission1));
        ExcelReportBuilderMgr.AddDataToSection('Member2', StdRepMgt.GetEmpPosition(Commission2));
        ExcelReportBuilderMgr.AddDataToSection('MemberName2', StdRepMgt.GetEmpName(Commission2));
        ExcelReportBuilderMgr.AddDataToSection('Member3', StdRepMgt.GetEmpPosition(Commission3));
        ExcelReportBuilderMgr.AddDataToSection('MemberName3', StdRepMgt.GetEmpName(Commission3));
        ExcelReportBuilderMgr.AddDataToSection('RespLastPageTitle1', StdRepMgt.GetEmpPosition(FALocation."Employee No."));
        ExcelReportBuilderMgr.AddDataToSection('RespLastPageName1', StdRepMgt.GetEmpName(FALocation."Employee No."));
        ExcelReportBuilderMgr.AddDataToSection('CheckedByTitleLastPage', StdRepMgt.GetEmpPosition(WhoCheck));
        ExcelReportBuilderMgr.AddDataToSection('CheckedByNameLastPage', StdRepMgt.GetEmpName(WhoCheck));
    end;
}

