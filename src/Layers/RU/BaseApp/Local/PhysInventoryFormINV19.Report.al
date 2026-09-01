#pragma warning disable AA0247
report 12482 "Phys. Inventory Form INV-19"
{
    Caption = 'Phys. Inventory Form INV-19';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Item Journal Line"; "Item Journal Line")
        {

            trigger OnAfterGetRecord()
            begin
                if Quantity <> 0 then begin
                    Surplus := 0;
                    Lack := 0;
                    QntDifference := "Qty. (Phys. Inventory)" - "Qty. (Calculated)";
                    CalcAmnt := "Qty. (Calculated)" * "Unit Cost";
                    ActualAmnt := "Qty. (Phys. Inventory)" * "Unit Cost";
                    AmntDifference := ActualAmnt - CalcAmnt;
                    if QntDifference > 0 then begin
                        SurplusTurnoverRUB := Abs(AmntDifference);
                        Surplus := Abs(QntDifference);
                    end else begin
                        LackTurnoverRUB := Abs(AmntDifference);
                        Lack := Abs(QntDifference);
                    end
                end else begin
                    SurplusTurnoverRUB := 0;
                    Surplus := 0;
                    LackTurnoverRUB := 0;
                    Lack := 0;
                end;

                NumberPP += 1;
                TotalSurplus += Surplus;
                TotalLack += Lack;
                TotalSurplusTurnoverRUB += SurplusTurnoverRUB;
                TotalLackTurnoverRUB += LackTurnoverRUB;

                if not ExcelReportBuilderMgr.TryAddSectionWithPlaceForFooter('BODY', 'REPORTFOOTER') then begin
                    ExcelReportBuilderMgr.AddPagebreak();
                    ExcelReportBuilderMgr.AddSection('PAGEHEADER');
                    ExcelReportBuilderMgr.AddSection('BODY');
                end;

                ExcelReportBuilderMgr.AddDataToSection('LineNum', Format(NumberPP));
                ExcelReportBuilderMgr.AddDataToSection('ItemName', Description);
                ExcelReportBuilderMgr.AddDataToSection('ItemId', "Item No.");
                ExcelReportBuilderMgr.AddDataToSection('CodeOkei', "Unit of Measure Code");
                ExcelReportBuilderMgr.AddDataToSection('BOMUnitId', StdRepMgt.GetUoMDesc("Unit of Measure Code"));
                ExcelReportBuilderMgr.AddDataToSection('QtyIssue', StdRepMgt.FormatReportValue(Surplus, 2));
                ExcelReportBuilderMgr.AddDataToSection('CostIssue', StdRepMgt.FormatReportValue(SurplusTurnoverRUB, 2));
                ExcelReportBuilderMgr.AddDataToSection('QtyLoss', StdRepMgt.FormatReportValue(Lack, 2));
                ExcelReportBuilderMgr.AddDataToSection('CostLoss', StdRepMgt.FormatReportValue(LackTurnoverRUB, 2));
            end;

            trigger OnPostDataItem()
            begin
                ExcelReportBuilderMgr.AddSection('REPORTFOOTER');

                ExcelReportBuilderMgr.AddDataToSection('QtyIssueTotal', StdRepMgt.FormatReportValue(TotalSurplus, 2));
                ExcelReportBuilderMgr.AddDataToSection('CostIssueTotal', StdRepMgt.FormatReportValue(TotalSurplusTurnoverRUB, 2));
                ExcelReportBuilderMgr.AddDataToSection('QtyLossTotal', StdRepMgt.FormatReportValue(TotalLack, 2));
                ExcelReportBuilderMgr.AddDataToSection('CostLossTotal', StdRepMgt.FormatReportValue(TotalLackTurnoverRUB, 2));
                ExcelReportBuilderMgr.AddDataToSection('InChargeTitle_21', StdRepMgt.GetEmpPosition(SignedBy));
                ExcelReportBuilderMgr.AddDataToSection('InChargeName_21', StdRepMgt.GetEmpName(SignedBy));
            end;

            trigger OnPreDataItem()
            begin
                CompanyInfo.Get();

                FindFirst();
                FillSheet1();

                ExcelReportBuilderMgr.SetSheet('Sheet2');
                ExcelReportBuilderMgr.AddSection('PAGEHEADER');
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(DocumentNo; DocumentNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document No.';
                        ToolTip = 'Specifies the number of the related document.';
                    }
                    field(DocumentDate; DocumentDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document Date';
                        ToolTip = 'Specifies the creation date of the related document.';
                    }
                    field(StartingDate; StartingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventorization Start Date';
                        ToolTip = 'Specifies the date from which the report or batch job processes information.';
                    }
                    field(EndingDate; EndingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventorization End Date';
                    }
                    field(CreationDate; CreationDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document Creation Date';
                        ToolTip = 'Specifies the creation date of the related document.';
                    }
                    field(StatusOn; StatusOn)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'As of Date';
                        ToolTip = 'Specifies a search method. If you select As of Date, and there is no currency exchange rate on a certain date, a message requesting that you enter a currency exchange rate for the date is displayed.';
                    }
                    field(SignedBy; SignedBy)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Signed by';
                        TableRelation = Employee;
                        ToolTip = 'Specifies the name of the employee who is responsible for the report.';
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
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.TestField("Phys.Inv. INV-19 Template Code");
        ExcelReportBuilderMgr.InitTemplate(InventorySetup."Phys.Inv. INV-19 Template Code");
    end;

    var
        CompanyInfo: Record "Company Information";
        LocMgt: Codeunit "Localisation Management";
        StdRepMgt: Codeunit "Local Report Management";
        ExcelReportBuilderMgr: Codeunit "Excel Report Builder Manager";
        FileName: Text;
        StartingDate: Date;
        EndingDate: Date;
        DocumentNo: Code[10];
        DocumentDate: Date;
        NumberPP: Integer;
        CreationDate: Date;
        Surplus: Decimal;
        Lack: Decimal;
        SurplusTurnoverRUB: Decimal;
        LackTurnoverRUB: Decimal;
        StatusOn: Date;
        SignedBy: Code[20];
        QntDifference: Decimal;
        CalcAmnt: Decimal;
        ActualAmnt: Decimal;
        AmntDifference: Decimal;
        TotalSurplus: Decimal;
        TotalLack: Decimal;
        TotalSurplusTurnoverRUB: Decimal;
        TotalLackTurnoverRUB: Decimal;

    [Scope('OnPrem')]
    procedure SetFileNameSilent(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;

    local procedure FillSheet1()
    begin
        ExcelReportBuilderMgr.SetSheet('Sheet1');
        ExcelReportBuilderMgr.AddSection('FIRSTPAGE');

        ExcelReportBuilderMgr.AddDataToSection('CompanyName', StdRepMgt.GetCompanyName());
        ExcelReportBuilderMgr.AddDataToSection('Department', StdRepMgt.GetEmpDepartment(SignedBy));
        ExcelReportBuilderMgr.AddDataToSection('OKPO', CompanyInfo."OKPO Code");
        ExcelReportBuilderMgr.AddDataToSection('DocNo', DocumentNo);
        ExcelReportBuilderMgr.AddDataToSection('DocDate', Format(DocumentDate));
        ExcelReportBuilderMgr.AddDataToSection('MinInventoryDate', Format(StartingDate));
        ExcelReportBuilderMgr.AddDataToSection('MaxInventoryDate', Format(EndingDate));
        ExcelReportBuilderMgr.AddDataToSection('DocumentNum', "Item Journal Line"."Document No.");
        ExcelReportBuilderMgr.AddDataToSection('DocumentDate', Format(CreationDate));
        ExcelReportBuilderMgr.AddDataToSection('TransDate', LocMgt.Date2Text(StatusOn));
    end;
}

