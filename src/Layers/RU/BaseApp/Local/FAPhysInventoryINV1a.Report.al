#pragma warning disable AA0247
report 14921 "FA Phys. Inventory INV-1a"
{
    Caption = 'FA Phys. Inventory INV-1a';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Document Print Buffer"; "Document Print Buffer")
        {
            DataItemTableView = sorting("User ID");
            dataitem("FA Journal Line"; "FA Journal Line")
            {
                DataItemLink = "Journal Template Name" = field("Journal Template Name"), "Journal Batch Name" = field("Journal Batch Name");
                DataItemTableView = sorting("Journal Template Name", "Journal Batch Name", "Line No.");

                trigger OnAfterGetRecord()
                begin
                    if not FA.Get("FA No.") then
                        CurrReport.Skip();

                    if FA."FA Type" <> FA."FA Type"::"Intangible Asset" then
                        CurrReport.Skip();

                    if not ExcelReportBuilderMgr.TryAddSectionWithPlaceForFooter('MAINPAGEBODY', 'MAINPAGEFOOTER') then begin
                        FillMainPageTotals();
                        ExcelReportBuilderMgr.AddPagebreak();
                        ExcelReportBuilderMgr.AddSection('MAINPAGEHEADER');
                        ExcelReportBuilderMgr.AddSection('MAINPAGEBODY');

                        QtyNumberPPPage := 0;
                        Clear(PageAmount);
                    end;

                    QtyNumberPP += 1;
                    QtyNumberPPPage += 1;

                    AddTotals(PageAmount, "Actual Amount", "Calc. Amount");
                    AddTotals(TotalAmount, "Actual Amount", "Calc. Amount");

                    ExcelReportBuilderMgr.AddDataToSection('LineNum', Format(QtyNumberPP));
                    ExcelReportBuilderMgr.AddDataToSection('ItemName', Description);
                    ExcelReportBuilderMgr.AddDataToSection('ReleaseDate', Format(FA."Initial Release Date"));
                    ExcelReportBuilderMgr.AddDataToSection('ActualAmount', Format("Actual Amount"));
                    ExcelReportBuilderMgr.AddDataToSection('CalcAmount', Format("Calc. Amount"));
                end;

                trigger OnPostDataItem()
                begin
                    FillMainPageTotals();
                    FillLastPage();
                end;

                trigger OnPreDataItem()
                begin
                    if "Document Print Buffer"."Table ID" <> DATABASE::"FA Journal Line" then
                        CurrReport.Break();

                    FillGeneralInfo();

                    ExcelReportBuilderMgr.SetSheet('Sheet2');
                    ExcelReportBuilderMgr.AddSection('MAINPAGEHEADER');
                end;
            }
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
                    group(Commission)
                    {
                        Caption = 'Commission';
                        field(Commission1; Commission1)
                        {
                            ApplicationArea = FixedAssets;
                            TableRelation = Employee;
                            ToolTip = 'Specifies the employees who serves on the commission.';
                        }
                        field(Commission2; Commission2)
                        {
                            ApplicationArea = FixedAssets;
                            TableRelation = Employee;
                            ToolTip = 'Specifies the employees who serves on the commission.';
                        }
                        field(Commission3; Commission3)
                        {
                            ApplicationArea = FixedAssets;
                            TableRelation = Employee;
                            ToolTip = 'Specifies the employees who serves on the commission.';
                        }
                    }
                    group("Responsible Person")
                    {
                        Caption = 'Responsible Person';
                        field(ResponsiblePerson1; ResponsiblePerson1)
                        {
                            ApplicationArea = FixedAssets;
                            TableRelation = Employee;
                        }
                        field(ResponsiblePerson2; ResponsiblePerson2)
                        {
                            ApplicationArea = FixedAssets;
                            TableRelation = Employee;
                        }
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
                        ToolTip = 'Specifies the chairman from the employee list as a signatory.';
                    }
                    field(CheckedBy; CheckedBy)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Supervisor';
                        TableRelation = Employee;
                        ToolTip = 'Specifies the supervisor as a signatory.';
                    }
                    field(FALocationCode; FALocationCode)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Location';
                        TableRelation = "FA Location";
                        ToolTip = 'Specifies the fixed asset location code.';
                    }
                }
            }
        }

        actions
        {
        }
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
    begin
        FASetup.Get();
        FASetup.TestField("INV-1a Template Code");
        ExcelReportBuilderMgr.InitTemplate(FASetup."INV-1a Template Code");
        ExcelReportBuilderMgr.SetSheet('Sheet1');
    end;

    var
        CompanyInfo: Record "Company Information";
        FALocation: Record "FA Location";
        FA: Record "Fixed Asset";
        FASetup: Record "FA Setup";
        LocMgt: Codeunit "Localisation Management";
        StdRepMgt: Codeunit "Local Report Management";
        ExcelReportBuilderMgr: Codeunit "Excel Report Builder Manager";
        FileName: Text;
        StartDate: Date;
        EndDate: Date;
        DocumentNo: Code[20];
        DocumentDate: Date;
        QtyNumberPP: Integer;
        QtyNumberPPPage: Integer;
        TotalAmount: array[2] of Decimal;
        PageAmount: array[2] of Decimal;
        Chairman: Code[20];
        Commission1: Code[20];
        Commission2: Code[20];
        Commission3: Code[20];
        CheckedBy: Code[20];
        ResponsiblePerson1: Code[20];
        ResponsiblePerson2: Code[20];
        FALocationCode: Code[10];
        ValueIndex: Option ,FactAmt,CalcAmt;

    [Scope('OnPrem')]
    procedure FillGeneralInfo()
    begin
        CompanyInfo.Get();
        ExcelReportBuilderMgr.AddSection('FIRSTPAGE');

        ExcelReportBuilderMgr.AddDataToSection('CompanyName', StdRepMgt.GetCompanyName());
        if FALocation.Get(FALocationCode) then begin
            ExcelReportBuilderMgr.AddDataToSection('LocationName', FALocation.Name);
            ExcelReportBuilderMgr.AddDataToSection('DepartmentName', StdRepMgt.GetEmpDepartment(FALocation."Employee No."));
        end;
        ExcelReportBuilderMgr.AddDataToSection('OKPO', CompanyInfo."OKPO Code");
        ExcelReportBuilderMgr.AddDataToSection('StartDate', Format(StartDate));
        ExcelReportBuilderMgr.AddDataToSection('EndDate', Format(EndDate));
        ExcelReportBuilderMgr.AddDataToSection('DocNumber', DocumentNo);
        ExcelReportBuilderMgr.AddDataToSection('DocDate', Format(DocumentDate));
        ExcelReportBuilderMgr.AddDataToSection('RespFirstPageTitle1', StdRepMgt.GetEmpPosition(ResponsiblePerson1));
        ExcelReportBuilderMgr.AddDataToSection('RespFirstPageName1', StdRepMgt.GetEmpName(ResponsiblePerson1));
        ExcelReportBuilderMgr.AddDataToSection('RespFirstPageTitle2', StdRepMgt.GetEmpPosition(ResponsiblePerson2));
        ExcelReportBuilderMgr.AddDataToSection('RespFirstPageName2', StdRepMgt.GetEmpName(ResponsiblePerson2));
    end;

    [Scope('OnPrem')]
    procedure SetFileNameSilent(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;

    local procedure GetDecimals(FullAmount: Decimal): Decimal
    begin
        exit(Abs((FullAmount - Round(FullAmount, 1, '<')) * 100));
    end;

    local procedure AddTotals(var TotalArr: array[2] of Decimal; ActualAmt: Decimal; CalcAmt: Decimal)
    begin
        TotalArr[ValueIndex::FactAmt] += ActualAmt;
        TotalArr[ValueIndex::CalcAmt] += CalcAmt;
    end;

    local procedure FillMainPageTotals()
    begin
        ExcelReportBuilderMgr.AddSection('MAINPAGEFOOTER');
        ExcelReportBuilderMgr.AddDataToSection('TotalFactAmount', Format(PageAmount[ValueIndex::FactAmt]));
        ExcelReportBuilderMgr.AddDataToSection('TotalAccountingAmount', Format(PageAmount[ValueIndex::CalcAmt]));
        ExcelReportBuilderMgr.AddDataToSection('AssetCnt', LocMgt.Integer2Text(QtyNumberPPPage, 1, '', '', ''));
        ExcelReportBuilderMgr.AddDataToSection('AmountFact', LocMgt.Integer2Text(PageAmount[ValueIndex::FactAmt], 1, '', '', ''));
        ExcelReportBuilderMgr.AddDataToSection('Cent', Format(GetDecimals(PageAmount[ValueIndex::FactAmt])));
    end;

    local procedure FillLastPage()
    begin
        ExcelReportBuilderMgr.SetSheet('Sheet3');
        ExcelReportBuilderMgr.AddSection('LASTPAGE');

        ExcelReportBuilderMgr.AddDataToSection('LineNumTotalStr', LocMgt.Integer2Text(QtyNumberPP, 2, '', '', ''));
        ExcelReportBuilderMgr.AddDataToSection('CountedAmountTotalStr',
          LocMgt.Integer2Text(TotalAmount[ValueIndex::FactAmt], 2, '', '', ''));
        ExcelReportBuilderMgr.AddDataToSection('CountedAmountTotalCent',
          StdRepMgt.FormatReportValue(GetDecimals(TotalAmount[ValueIndex::FactAmt]), 0));
        ExcelReportBuilderMgr.AddDataToSection('CountTo', Format(QtyNumberPP));

        ExcelReportBuilderMgr.AddDataToSection('Chairman', StdRepMgt.GetEmpPosition(Chairman));
        ExcelReportBuilderMgr.AddDataToSection('ChairmanName', StdRepMgt.GetEmpName(Chairman));
        ExcelReportBuilderMgr.AddDataToSection('Member1', StdRepMgt.GetEmpPosition(Commission1));
        ExcelReportBuilderMgr.AddDataToSection('MemberName1', StdRepMgt.GetEmpName(Commission1));
        ExcelReportBuilderMgr.AddDataToSection('Member2', StdRepMgt.GetEmpPosition(Commission2));
        ExcelReportBuilderMgr.AddDataToSection('MemberName2', StdRepMgt.GetEmpName(Commission2));
        ExcelReportBuilderMgr.AddDataToSection('Member3', StdRepMgt.GetEmpPosition(Commission3));
        ExcelReportBuilderMgr.AddDataToSection('MemberName3', StdRepMgt.GetEmpName(Commission3));

        ExcelReportBuilderMgr.AddDataToSection('RespLastPageTitle1', StdRepMgt.GetEmpPosition(ResponsiblePerson1));
        ExcelReportBuilderMgr.AddDataToSection('RespLastPageName1', StdRepMgt.GetEmpName(ResponsiblePerson1));
        ExcelReportBuilderMgr.AddDataToSection('RespLastPageTitle2', StdRepMgt.GetEmpPosition(ResponsiblePerson2));
        ExcelReportBuilderMgr.AddDataToSection('RespLastPageName2', StdRepMgt.GetEmpName(ResponsiblePerson2));
        ExcelReportBuilderMgr.AddDataToSection('CheckedByTitleLastPage', StdRepMgt.GetEmpPosition(CheckedBy));
        ExcelReportBuilderMgr.AddDataToSection('CheckedByNameLastPage', StdRepMgt.GetEmpName(CheckedBy));
    end;
}

