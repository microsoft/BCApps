#pragma warning disable AA0247
report 12481 "Phys. Inventory Form INV-3"
{
    Caption = 'Phys. Inventory Form INV-3';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Item Journal Line"; "Item Journal Line")
        {
            RequestFilterFields = "Journal Template Name", "Journal Batch Name";

            trigger OnAfterGetRecord()
            begin
                ValueEntry.Reset();
                ValueEntry.SetCurrentKey(
                  "Item No.", "Location Code", "Expected Cost", Inventoriable, "Posting Date");
                ValueEntry.SetRange("Item No.", "Item No.");
                ValueEntry.SetRange("Location Code", "Location Code");
                ValueEntry.SetRange(Inventoriable, true);
                ValueEntry.SetRange("Expected Cost", false);
                ValueEntry.SetFilter("Posting Date", '<%1', "Posting Date");
                ValueEntry.CalcSums("Cost Amount (Actual)");
                TurnoverRUB := ValueEntry."Cost Amount (Actual)";

                if "Qty. (Phys. Inventory)" >= "Qty. (Calculated)" then
                    ActualTurnoverRUB := TurnoverRUB + Amount
                else
                    ActualTurnoverRUB := TurnoverRUB -
                      "Quantity (Base)" * ItemCostManagement.CalcAvgUnitActualCost("Item No.", "Location Code", "Posting Date");

                if not ExcelReportBuilderMgr.TryAddSectionWithPlaceForFooter('MAINPAGEBODY', 'MAINPAGEFOOTER') then begin
                    ExcelReportBuilderMgr.AddSection('MAINPAGEFOOTER');
                    FillSheet2Totals(
                      PageAmounts[ValueIndex::FactQty], PageAmounts[ValueIndex::FactAmt],
                      PageAmounts[ValueIndex::CalcQty], PageAmounts[ValueIndex::CalcAmt]);

                    ExcelReportBuilderMgr.AddPagebreak();
                    ExcelReportBuilderMgr.AddSection('MAINPAGEHEADER');
                    ExcelReportBuilderMgr.AddSection('MAINPAGEBODY');

                    NumberPPPage := 0;
                    Clear(PageAmounts);
                end;

                NumberPP := NumberPP + 1;
                NumberPPPage := NumberPPPage + 1;
                AddTotals(PageAmounts, "Qty. (Phys. Inventory)", ActualTurnoverRUB, "Qty. (Calculated)", TurnoverRUB);
                AddTotals(TotalAmounts, "Qty. (Phys. Inventory)", ActualTurnoverRUB, 0, 0);

                ExcelReportBuilderMgr.AddDataToSection('LineNum', Format(NumberPP));
                ExcelReportBuilderMgr.AddDataToSection('ItemName', Description);
                ExcelReportBuilderMgr.AddDataToSection('ItemId', "Item No.");
                ExcelReportBuilderMgr.AddDataToSection('CodeOKEI', "Unit of Measure Code");
                ExcelReportBuilderMgr.AddDataToSection('UnitName', StdRepMgt.GetUoMDesc("Unit of Measure Code"));
                ExcelReportBuilderMgr.AddDataToSection('CountedQty', StdRepMgt.FormatReportValue("Qty. (Phys. Inventory)", 2));
                ExcelReportBuilderMgr.AddDataToSection('CountedAmount', StdRepMgt.FormatReportValue(ActualTurnoverRUB, 2));
                ExcelReportBuilderMgr.AddDataToSection('OnHandQty', StdRepMgt.FormatReportValue("Qty. (Calculated)", 2));
                ExcelReportBuilderMgr.AddDataToSection('OnHandAmount', StdRepMgt.FormatReportValue(TurnoverRUB, 2));
            end;

            trigger OnPostDataItem()
            begin
                ExcelReportBuilderMgr.AddSection('MAINPAGEFOOTER');
                FillSheet2Totals(
                  PageAmounts[ValueIndex::FactQty], PageAmounts[ValueIndex::FactAmt],
                  PageAmounts[ValueIndex::CalcQty], PageAmounts[ValueIndex::CalcAmt]);

                FillSheet3();
            end;

            trigger OnPreDataItem()
            begin
                CompanyInfo.Get();

                CheckLocation();

                FindFirst();
                FillSheet1();

                ExcelReportBuilderMgr.SetSheet('Sheet2');
                ExcelReportBuilderMgr.AddSection('MainPageHeader0');
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
                        ToolTip = 'Specifies the date to which the report or batch job processes information.';
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
                    field(RespEmployeeNo; RespEmployeeNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Responsible Employee';
                        TableRelation = Employee;
                        ToolTip = 'Specifies the employee who is responsible for the validity of the data in the report.';
                    }
                    field(Chairman; Chairman)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Chairman';
                        TableRelation = Employee;
                    }
                    field(Member1; Member1)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Commission Member1';
                        TableRelation = Employee;
                        ToolTip = 'Specifies the name of the employee who makes up the commission.';
                    }
                    field(Member2; Member2)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Commission Member2';
                        TableRelation = Employee;
                        ToolTip = 'Specifies the name of the employee who makes up the commission.';
                    }
                    field(Member3; Member3)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Commission Member3';
                        TableRelation = Employee;
                        ToolTip = 'Specifies the name of the employee who makes up the commission.';
                    }
                    field(CheckedBy; CheckedBy)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Checked by';
                        TableRelation = Employee;
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
        InventorySetup.TestField("Phys.Inv. INV-3 Template Code");
        ExcelReportBuilderMgr.InitTemplate(InventorySetup."Phys.Inv. INV-3 Template Code");
    end;

    var
        CompanyInfo: Record "Company Information";
        Location: Record Location;
        ValueEntry: Record "Value Entry";
        ItemJnlLine: Record "Item Journal Line";
        LocMgt: Codeunit "Localisation Management";
        StdRepMgt: Codeunit "Local Report Management";
        ExcelReportBuilderMgr: Codeunit "Excel Report Builder Manager";
        ItemCostManagement: Codeunit ItemCostManagement;
        ValueIndex: Option ,FactQty,FactAmt,CalcQty,CalcAmt;
        FileName: Text;
        StartingDate: Date;
        EndingDate: Date;
        DocumentNo: Code[10];
        DocumentDate: Date;
        NumberPP: Integer;
        NumberPPPage: Integer;
        PageAmounts: array[4] of Decimal;
        TotalAmounts: array[4] of Decimal;
        CreationDate: Date;
        TurnoverRUB: Decimal;
        ActualTurnoverRUB: Decimal;
        Chairman: Code[10];
        Member1: Code[10];
        Member2: Code[10];
        Member3: Code[10];
        CheckedBy: Code[10];
        StatusOn: Date;
        RespEmployeeNo: Code[20];
        LocationCode: Code[10];
#pragma warning disable AA0470
        RespEmployeeDoesNotMatchErr: Label 'Journal Line exists for Location %1 Responsible Employee %2. Must be one Responsible Employee only.';
#pragma warning restore AA0470

    [Scope('OnPrem')]
    procedure CheckLocation()
    begin
        ItemJnlLine.SetRange("Journal Template Name", "Item Journal Line"."Journal Template Name");
        ItemJnlLine.SetRange("Journal Batch Name", "Item Journal Line"."Journal Batch Name");
        if ItemJnlLine.FindSet() then begin
            LocationCode := ItemJnlLine."Location Code";
            Location.Get(LocationCode);
            RespEmployeeNo := Location."Responsible Employee No.";
            repeat
                if ItemJnlLine."Location Code" <> LocationCode then begin
                    Location.Get(ItemJnlLine."Location Code");
                    if Location."Responsible Employee No." <> RespEmployeeNo then
                        Error(RespEmployeeDoesNotMatchErr, Location.Code, Location."Responsible Employee No.");
                end;
            until ItemJnlLine.Next() = 0;
        end;
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

    local procedure AddTotals(var TotalArr: array[4] of Decimal; FactQty: Decimal; FactAmt: Decimal; CalcQty: Decimal; CalcAmt: Decimal)
    begin
        TotalArr[ValueIndex::FactQty] += FactQty;
        TotalArr[ValueIndex::FactAmt] += FactAmt;
        TotalArr[ValueIndex::CalcQty] += CalcQty;
        TotalArr[ValueIndex::CalcAmt] += CalcAmt;
    end;

    local procedure FillSheet1()
    begin
        ExcelReportBuilderMgr.SetSheet('Sheet1');
        ExcelReportBuilderMgr.AddSection('FIRSTPAGE');

        ExcelReportBuilderMgr.AddDataToSection('Company', StdRepMgt.GetCompanyName());
        ExcelReportBuilderMgr.AddDataToSection('Warehouse', StdRepMgt.GetEmpDepartment(RespEmployeeNo));

        ExcelReportBuilderMgr.AddDataToSection('ClassificationbyOKPO', CompanyInfo."OKPO Code");
        ExcelReportBuilderMgr.AddDataToSection('OrderNum', DocumentNo);
        ExcelReportBuilderMgr.AddDataToSection('OrderDate', Format(DocumentDate));
        ExcelReportBuilderMgr.AddDataToSection('InventStartDate', Format(StartingDate));
        ExcelReportBuilderMgr.AddDataToSection('InventEndDate', Format(EndingDate));
        ExcelReportBuilderMgr.AddDataToSection('InventJournalNum', "Item Journal Line"."Document No.");
        ExcelReportBuilderMgr.AddDataToSection('CountingListCreateDate', Format(CreationDate));

        ExcelReportBuilderMgr.AddDataToSection('InChargeTitleFirstPageLine1', StdRepMgt.GetEmpPosition(RespEmployeeNo));
        ExcelReportBuilderMgr.AddDataToSection('InChargeNameFirstPageLine1', StdRepMgt.GetEmpName(RespEmployeeNo));

        ExcelReportBuilderMgr.AddDataToSection('InventOnHandDateDay', Format(WorkDate(), 0, '<Day,2>'));
        ExcelReportBuilderMgr.AddDataToSection('InventOnHandDateMth', Format(LocMgt.Month2Text(WorkDate())));
        ExcelReportBuilderMgr.AddDataToSection('InventOnHandDateYr', Format(WorkDate(), 0, '<Year>'));
    end;

    local procedure FillSheet2Totals(FactQty: Decimal; FactAmt: Decimal; CalcQty: Decimal; CalcAmt: Decimal)
    begin
        ExcelReportBuilderMgr.AddDataToSection('CountedQtyPageTotal', StdRepMgt.FormatReportValue(FactQty, 2));
        ExcelReportBuilderMgr.AddDataToSection('CountedAmountPageTotal', StdRepMgt.FormatReportValue(FactAmt, 2));
        ExcelReportBuilderMgr.AddDataToSection('OnHandQtyPageTotal', StdRepMgt.FormatReportValue(CalcQty, 2));
        ExcelReportBuilderMgr.AddDataToSection('OnHandAmountPageTotal', StdRepMgt.FormatReportValue(CalcAmt, 2));

        ExcelReportBuilderMgr.AddDataToSection('LineNumPageTotalStr', LocMgt.Integer2Text(NumberPPPage, 2, '', '', ''));
        ExcelReportBuilderMgr.AddDataToSection('CountedQtyPageTotalStr',
          LocMgt.Integer2Text(FactQty, 2, '', '', '') + ' / ' +
          LocMgt.Integer2Text(GetDecimals(FactQty), 0, '', '', ''));

        ExcelReportBuilderMgr.AddDataToSection('CountedAmountPageTotalStr', LocMgt.Integer2Text(FactAmt, 2, '', '', ''));
        ExcelReportBuilderMgr.AddDataToSection('CountedAmountPageTotalCent', StdRepMgt.FormatReportValue(GetDecimals(FactAmt), 0));
    end;

    local procedure FillSheet3()
    begin
        ExcelReportBuilderMgr.SetSheet('Sheet3');
        ExcelReportBuilderMgr.AddSection('LASTPAGE');

        ExcelReportBuilderMgr.AddDataToSection('LineNumTotalStr', LocMgt.Integer2Text(NumberPP, 2, '', '', ''));
        ExcelReportBuilderMgr.AddDataToSection('CountedQtyTotalStr',
          LocMgt.Integer2Text(TotalAmounts[ValueIndex::FactQty], 2, '', '', '') + ' / ' +
          LocMgt.Integer2Text(GetDecimals(TotalAmounts[ValueIndex::FactQty]), 0, '', '', ''));

        ExcelReportBuilderMgr.AddDataToSection('CountedAmountTotalStr',
          LocMgt.Integer2Text(TotalAmounts[ValueIndex::FactAmt], 2, '', '', ''));
        ExcelReportBuilderMgr.AddDataToSection('CountedAmountTotalCent',
          StdRepMgt.FormatReportValue(GetDecimals(TotalAmounts[ValueIndex::FactAmt]), 0));

        ExcelReportBuilderMgr.AddDataToSection('ChairmanTitle', StdRepMgt.GetEmpPosition(Chairman));
        ExcelReportBuilderMgr.AddDataToSection('ChairmanName', StdRepMgt.GetEmpName(Chairman));
        ExcelReportBuilderMgr.AddDataToSection('MemberTitleLine1', StdRepMgt.GetEmpPosition(Member1));
        ExcelReportBuilderMgr.AddDataToSection('MemberNameLine1', StdRepMgt.GetEmpName(Member1));
        ExcelReportBuilderMgr.AddDataToSection('MemberTitleLine2', StdRepMgt.GetEmpPosition(Member2));
        ExcelReportBuilderMgr.AddDataToSection('MemberNameLine2', StdRepMgt.GetEmpName(Member2));
        ExcelReportBuilderMgr.AddDataToSection('MemberTitleLine3', StdRepMgt.GetEmpPosition(Member3));
        ExcelReportBuilderMgr.AddDataToSection('MemberNameLine3', StdRepMgt.GetEmpName(Member3));

        ExcelReportBuilderMgr.AddDataToSection('InChargeTitleLastPageLine1', StdRepMgt.GetEmpPosition(RespEmployeeNo));
        ExcelReportBuilderMgr.AddDataToSection('InChargeNameLastPageLine1', StdRepMgt.GetEmpName(RespEmployeeNo));
        ExcelReportBuilderMgr.AddDataToSection('CheckedByTitleLastPage', StdRepMgt.GetEmpPosition(CheckedBy));
        ExcelReportBuilderMgr.AddDataToSection('CheckedByNameLastPage', StdRepMgt.GetEmpName(CheckedBy));
        ExcelReportBuilderMgr.AddDataToSection('TotalNumStr', Format(NumberPP));
    end;
}

