#pragma warning disable AA0247
report 14926 "Inventory for Deferrals INV-11"
{
    Caption = 'Inventory for Deferrals INV-11';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Document Print Buffer"; "Document Print Buffer")
        {
            DataItemTableView = sorting("User ID");
            dataitem(FAJournalLine; "FA Journal Line")
            {
                DataItemLink = "Journal Template Name" = field("Journal Template Name"), "Journal Batch Name" = field("Journal Batch Name");
                DataItemTableView = sorting("Journal Template Name", "Journal Batch Name", "Line No.");

                trigger OnAfterGetRecord()
                begin
                    FADepreciationBook.Reset();
                    FADepreciationBook.SetRange("FA No.", "FA No.");
                    FADepreciationBook.SetRange("Depreciation Book Code", "Depreciation Book Code");
                    FADepreciationBook.SetRange("FA Posting Date Filter", 0D, InvStartDate - 1);
                    if (not FADepreciationBook.FindFirst()) or (FADepreciationBook."Acquisition Date" >= InvStartDate) then
                        CurrReport.Skip();

                    if (LocationCode = '') and ("Location Code" <> '') and (StrPos(DepartmentsLocation, "Location Code") = 0) then
                        DepartmentsLocation := DepartmentsLocation + "Location Code" + ', ';

                    if not IsBackSide then
                        if not ExcelReportBuilderMgr.TryAddSectionWithPlaceForFooter('BODY', 'PAGEFOOTER') then begin
                            PopulateTotals(true);
                            ExcelReportBuilderMgr.SetSheet('Sheet2');
                            IsBackSide := true;
                            ExcelReportBuilderMgr.AddSection('LASTPAGEHEADER');
                            ExcelReportBuilderMgr.AddSection('LASTPAGEBODY');
                            PopulateReportTable(false);
                        end else
                            PopulateReportTable(true)
                    else
                        if not ExcelReportBuilderMgr.TryAddSectionWithPlaceForFooter('LASTPAGEBODY', 'LASTPAGEFOOTER,REPORTACTTOTAL') then begin
                            PopulateTotals(false);
                            ExcelReportBuilderMgr.AddPagebreak();
                            ExcelReportBuilderMgr.AddSection('LASTPAGEHEADER');
                            ExcelReportBuilderMgr.AddSection('LASTPAGEBODY');
                            PopulateReportTable(false);
                        end else
                            PopulateReportTable(false);
                end;

                trigger OnPostDataItem()
                begin
                    if not IsBackSide then begin
                        PopulateTotals(true);
                        ExcelReportBuilderMgr.SetSheet('Sheet2');
                        ExcelReportBuilderMgr.AddSection('LASTPAGEHEADER');
                        PopulateTotals(false);
                    end else
                        PopulateTotals(false);
                    PopulateReportFooter();
                end;

                trigger OnPreDataItem()
                begin
                    DepartmentsLocation := '';
                    TableLineCounter := 1;
                    Clear(TotalAmounts);
                    ExcelReportBuilderMgr.AddSection('PAGEHEADER');
                end;
            }

            trigger OnPostDataItem()
            begin
                if (LocationCode = '') and (DepartmentsLocation <> '') then begin
                    ExcelReportBuilderMgr.SetSheet('Sheet1');
                    ExcelReportBuilderMgr.AddDataToPreviousSection(
                      FirstPageID, 'Department', CopyStr(DepartmentsLocation, 1, StrLen(DepartmentsLocation) - 2));
                end;
            end;

            trigger OnPreDataItem()
            begin
                if "Document Print Buffer".Get(UserId) then
                    if "Document Print Buffer"."Table ID" <> DATABASE::"FA Journal Line" then
                        CurrReport.Break();
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
                    field(DocNo; DocNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document No.';
                        ToolTip = 'Specifies the number of the related document.';
                    }
                    field(DocDate; DocDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document Date';
                        ToolTip = 'Specifies the creation date of the related document.';
                    }
                    field(LocationCode; LocationCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Location Code';
                        TableRelation = "FA Location";
                        ToolTip = 'Specifies the code for the location where the items are located.';
                    }
                    field(InvStartDate; InvStartDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory Starting Date';

                        trigger OnValidate()
                        begin
                            if (InvEndDate <> 0D) and (InvEndDate < InvStartDate) then
                                Error(InvtEndDateErr);
                        end;
                    }
                    field(InvEndDate; InvEndDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Inventory Ending Date';
                        ToolTip = 'Specifies the date to which the report or batch job processes information.';

                        trigger OnValidate()
                        begin
                            if (InvStartDate <> 0D) and (InvEndDate < InvStartDate) then
                                Error(InvtEndDateErr);
                        end;
                    }
                    field(Chairman; Chairman)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Chairman';
                        TableRelation = Employee;
                    }
                    group(Commission)
                    {
                        Caption = 'Commission';
                        field("Commission[1]"; Commission[1])
                        {
                            ApplicationArea = Basic, Suite;
                            TableRelation = Employee;
                        }
                        field("Commission[2]"; Commission[2])
                        {
                            ApplicationArea = Basic, Suite;
                            TableRelation = Employee;
                        }
                        field("Commission[3]"; Commission[3])
                        {
                            ApplicationArea = Basic, Suite;
                            TableRelation = Employee;
                        }
                    }
                    group("Materially Responsible Person")
                    {
                        Caption = 'Materially Responsible Person';
                        field("MatRespPerson[1]"; MatRespPerson[1])
                        {
                            ApplicationArea = Basic, Suite;
                            TableRelation = Employee;
                        }
                        field("MatRespPerson[2]"; MatRespPerson[2])
                        {
                            ApplicationArea = Basic, Suite;
                            TableRelation = Employee;
                        }
                        field("MatRespPerson[3]"; MatRespPerson[3])
                        {
                            ApplicationArea = Basic, Suite;
                            TableRelation = Employee;
                        }
                    }
                    field(CheckedBy; CheckedBy)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Checked By';
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
    begin
        if (InvStartDate = 0D) or (InvEndDate = 0D) then
            Error(InvtPeriodNotSpecifiedErr);

        InitReportTemplate();
        PopulateReportHeader();
    end;

    var
        FADepreciationBook: Record "FA Depreciation Book";
        StdRepMgt: Codeunit "Local Report Management";
        ExcelReportBuilderMgr: Codeunit "Excel Report Builder Manager";
        DocDate: Date;
        InvStartDate: Date;
        InvEndDate: Date;
        DocNo: Code[20];
        Chairman: Code[20];
        CheckedBy: Code[20];
        MatRespPerson: array[3] of Code[20];
        LocationCode: Code[10];
        InvtEndDateErr: Label 'Inventory Ending Date should be later than Inventory Starting Date.';
        Commission: array[3] of Text[250];
        DepartmentsLocation: Text[250];
        InventoryTxt: Label 'Inventory ';
        FileName: Text;
        TableLineCounter: Integer;
        InvtPeriodNotSpecifiedErr: Label 'Inventory period should be specified.';
        FirstPageID: Integer;
        TotalAmounts: array[9] of Decimal;
        TotalReportAmounts: array[9] of Decimal;
        IsBackSide: Boolean;

    local procedure PopulateReportHeader()
    var
        CompanyAddress: Record "Company Address";
        CompanyInfo: Record "Company Information";
        FALocation: Record "FA Location";
        LocManagement: Codeunit "Localisation Management";
    begin
        CompanyInfo.Get();

        ExcelReportBuilderMgr.AddSection('REPORTHEADER');
        ExcelReportBuilderMgr.AddDataToSection('OKPO', CompanyInfo."OKPO Code");

        CompanyAddress.SetRange("Address Type", CompanyAddress."Address Type"::Legal);
        if CompanyAddress.FindFirst() then
            ExcelReportBuilderMgr.AddDataToSection('CompanyName', CompanyAddress.Name + ' ' + CompanyAddress."Name 2")
        else
            ExcelReportBuilderMgr.AddDataToSection('CompanyName', StdRepMgt.GetCompanyName());

        if LocationCode <> '' then begin
            FALocation.Get(LocationCode);
            ExcelReportBuilderMgr.AddDataToSection('Department', FALocation.Name);
        end;

        ExcelReportBuilderMgr.AddDataToSection('ActivityType', CompanyInfo."Principal Activity");
        ExcelReportBuilderMgr.AddDataToSection('StartDate', Format(InvStartDate));
        ExcelReportBuilderMgr.AddDataToSection('EndDate', Format(InvEndDate));
        ExcelReportBuilderMgr.AddDataToSection('OperationType', InventoryTxt);
        ExcelReportBuilderMgr.AddDataToSection('InventoryOrder', DocNo);
        ExcelReportBuilderMgr.AddDataToSection('DocumentNum', DocNo);
        if DocDate <> 0D then begin
            ExcelReportBuilderMgr.AddDataToSection('InventoryDate', Format(DocDate));
            ExcelReportBuilderMgr.AddDataToSection('DocumentDate', Format(DocDate));
            ExcelReportBuilderMgr.AddDataToSection('DayDateEnd', Format(Date2DMY(DocDate, 1)));
            ExcelReportBuilderMgr.AddDataToSection('MonthDateEnd', LocManagement.Month2Text(DocDate));
            ExcelReportBuilderMgr.AddDataToSection('YearDateEnd', Format(Date2DMY(DocDate, 3)));
        end;
        FirstPageID := ExcelReportBuilderMgr.GetCurrentSectionId();
    end;

    local procedure PopulateReportTable(FirstTable: Boolean)
    var
        FixedAsset: Record "Fixed Asset";
        AmortizeMonths: Integer;
        NumberOfMonths: Integer;
        NumberOfDepreciationMonths: Integer;
        DepreciationAmountPerMonth: Decimal;
        InventoryAmount: Decimal;
        CalcDepreciationAmount: Decimal;
    begin
        FixedAsset.Get(FAJournalLine."FA No.");

        FADepreciationBook.CalcFields("Acquisition Cost", Depreciation);
        FADepreciationBook.TestField("No. of Depreciation Months");
        NumberOfDepreciationMonths := FADepreciationBook."No. of Depreciation Months";

        TotalAmounts[1] := TotalAmounts[1] + FADepreciationBook."Acquisition Cost";
        CalcDepreciationAmount :=
          Round(FADepreciationBook."Acquisition Cost" / NumberOfDepreciationMonths, 0.01);

        TotalAmounts[2] := TotalAmounts[2] + CalcDepreciationAmount;
        TotalAmounts[3] := TotalAmounts[3] + Abs(FADepreciationBook.Depreciation);
        TotalAmounts[4] := TotalAmounts[4] + FADepreciationBook."Acquisition Cost" - Abs(FADepreciationBook.Depreciation);

        NumberOfMonths := Date2DMY(InvStartDate, 2) - Date2DMY(FADepreciationBook."Acquisition Date", 2);
        AmortizeMonths :=
          NumberOfMonths + (Date2DMY(InvStartDate, 3) - Date2DMY(FADepreciationBook."Acquisition Date", 3)) * 12;

        if AmortizeMonths = 0 then begin
            AmortizeMonths := 1;
            NumberOfMonths := 1;
        end;

        if Date2DMY(InvStartDate, 3) - Date2DMY(FADepreciationBook."Acquisition Date", 3) <> 0 then
            NumberOfMonths := Date2DMY(InvStartDate, 2) - 1;

        DepreciationAmountPerMonth := Round(FAJournalLine."Actual Amount" / NumberOfDepreciationMonths, 0.01);
        TotalAmounts[5] := TotalAmounts[5] + DepreciationAmountPerMonth;
        if NumberOfMonths * DepreciationAmountPerMonth >
           FADepreciationBook."Acquisition Cost" - Abs(FADepreciationBook.Depreciation)
        then
            TotalAmounts[6] := TotalAmounts[6] + FADepreciationBook."Acquisition Cost" - Abs(FADepreciationBook.Depreciation)
        else
            TotalAmounts[6] := TotalAmounts[6] + NumberOfMonths * DepreciationAmountPerMonth;
        TotalAmounts[7] := TotalAmounts[7] + FAJournalLine."Actual  Remaining Amount";

        InventoryAmount := FAJournalLine."Actual  Remaining Amount" - FADepreciationBook."Acquisition Cost" +
          Abs(FADepreciationBook.Depreciation);
        if InventoryAmount < 0 then
            TotalAmounts[8] := TotalAmounts[8] - InventoryAmount
        else
            TotalAmounts[9] := TotalAmounts[9] + InventoryAmount;

        if FirstTable then begin
            ExcelReportBuilderMgr.AddDataToSection('LineNo', Format(TableLineCounter));
            ExcelReportBuilderMgr.AddDataToSection('Name', FixedAsset.Description);
            ExcelReportBuilderMgr.AddDataToSection('Code', FAJournalLine."FA No.");
            ExcelReportBuilderMgr.AddDataToSection('DeferralsAmount',
              FormatDecimal(FADepreciationBook."Acquisition Cost"));
            ExcelReportBuilderMgr.AddDataToSection('AcquisitionDate', Format(FADepreciationBook."Acquisition Date"));
            ExcelReportBuilderMgr.AddDataToSection('LifeTime', Format(NumberOfDepreciationMonths));

            ExcelReportBuilderMgr.AddDataToSection('CalcWritingOffAmount',
              FormatDecimal(CalcDepreciationAmount));
            ExcelReportBuilderMgr.AddDataToSection('WritingOffAmount',
              FormatDecimal(Abs(FADepreciationBook.Depreciation)));
            ExcelReportBuilderMgr.AddDataToSection(
              'RemainAmount',
              FormatDecimal(FADepreciationBook."Acquisition Cost" - Abs(FADepreciationBook.Depreciation)));

            ExcelReportBuilderMgr.AddDataToSection('Months', Format(AmortizeMonths));
            ExcelReportBuilderMgr.AddDataToSection('WritingOffReportMonth',
              FormatDecimal(DepreciationAmountPerMonth));
            if NumberOfMonths * DepreciationAmountPerMonth >
               FADepreciationBook."Acquisition Cost" - Abs(FADepreciationBook.Depreciation)
            then
                ExcelReportBuilderMgr.AddDataToSection(
                  'WritingOffReportYear',
                  FormatDecimal(FADepreciationBook."Acquisition Cost" - Abs(FADepreciationBook.Depreciation)))
            else
                ExcelReportBuilderMgr.AddDataToSection('WritingOffReportYear',
                  FormatDecimal(NumberOfMonths * DepreciationAmountPerMonth));
            ExcelReportBuilderMgr.AddDataToSection('CalcRemainAmount',
              FormatDecimal(FAJournalLine."Actual  Remaining Amount"));
            if InventoryAmount < 0 then
                ExcelReportBuilderMgr.AddDataToSection('SubjectToWriteOff',
                  FormatDecimal(Abs(InventoryAmount)));
            if InventoryAmount > 0 then
                ExcelReportBuilderMgr.AddDataToSection('ExcessivelyWrittenOff',
                  FormatDecimal(InventoryAmount));
        end else begin
            ExcelReportBuilderMgr.AddDataToSection('LineNoLast', Format(TableLineCounter));
            ExcelReportBuilderMgr.AddDataToSection('NameLast', FixedAsset.Description);
            ExcelReportBuilderMgr.AddDataToSection('CodeLast', FAJournalLine."FA No.");
            ExcelReportBuilderMgr.AddDataToSection('DeferralsAmountLast',
              FormatDecimal(FADepreciationBook."Acquisition Cost"));
            ExcelReportBuilderMgr.AddDataToSection('AcquisitionDateLast', Format(FADepreciationBook."Acquisition Date"));
            ExcelReportBuilderMgr.AddDataToSection('LifeTimeLast', Format(NumberOfDepreciationMonths));
            ExcelReportBuilderMgr.AddDataToSection('CalcWritingOffAmountLast',
              FormatDecimal(CalcDepreciationAmount));
            ExcelReportBuilderMgr.AddDataToSection('WritingOffAmountTotalLast',
              FormatDecimal(Abs(FADepreciationBook.Depreciation)));
            ExcelReportBuilderMgr.AddDataToSection(
              'RemainAmountLast',
              FormatDecimal(FADepreciationBook."Acquisition Cost" - Abs(FADepreciationBook.Depreciation)));

            ExcelReportBuilderMgr.AddDataToSection('MonthsLast', Format(AmortizeMonths));
            ExcelReportBuilderMgr.AddDataToSection('WritingOffReportMonthLast',
              FormatDecimal(DepreciationAmountPerMonth));

            if NumberOfMonths * DepreciationAmountPerMonth >
               FADepreciationBook."Acquisition Cost" - Abs(FADepreciationBook.Depreciation)
            then
                ExcelReportBuilderMgr.AddDataToSection(
                  'WritingOffReportYearLast',
                  FormatDecimal(FADepreciationBook."Acquisition Cost" - Abs(FADepreciationBook.Depreciation)))
            else
                ExcelReportBuilderMgr.AddDataToSection('WritingOffReportYearLast',
                  FormatDecimal(NumberOfMonths * DepreciationAmountPerMonth));
            ExcelReportBuilderMgr.AddDataToSection('CalcRemainAmountLast',
              FormatDecimal(FAJournalLine."Actual  Remaining Amount"));
            if InventoryAmount < 0 then
                ExcelReportBuilderMgr.AddDataToSection('SubjectToWriteOffLast',
                  FormatDecimal(Abs(InventoryAmount)));
            if InventoryAmount > 0 then
                ExcelReportBuilderMgr.AddDataToSection('ExcessivelyWrittenOffLast',
                  FormatDecimal(InventoryAmount));
        end;
        TableLineCounter += 1;
    end;

    local procedure PopulateTotals(FirstTable: Boolean)
    var
        "Count": Integer;
    begin
        if FirstTable then begin
            ExcelReportBuilderMgr.AddSection('PAGEFOOTER');
            ExcelReportBuilderMgr.AddDataToSection('PGDefSum', FormatDecimal(TotalAmounts[1]));
            ExcelReportBuilderMgr.AddDataToSection('PgWritingOffAmount', FormatDecimal(TotalAmounts[2]));
            ExcelReportBuilderMgr.AddDataToSection('PgWrittenOffAmount', FormatDecimal(TotalAmounts[3]));
            ExcelReportBuilderMgr.AddDataToSection('PgRemainAmount', FormatDecimal(TotalAmounts[4]));
            ExcelReportBuilderMgr.AddDataToSection('PgWritingOffReportMonth', FormatDecimal(TotalAmounts[5]));
            ExcelReportBuilderMgr.AddDataToSection('PgWritingOffReportYear', FormatDecimal(TotalAmounts[6]));
            ExcelReportBuilderMgr.AddDataToSection('PgCalcRemainAmount', FormatDecimal(TotalAmounts[7]));
            ExcelReportBuilderMgr.AddDataToSection('SubjectToWOffTotal', FormatDecimal(TotalAmounts[8]));
            ExcelReportBuilderMgr.AddDataToSection('ExcessivelyWOffTotal', FormatDecimal(TotalAmounts[9]));
        end else begin
            ExcelReportBuilderMgr.AddSection('LASTPAGEFOOTER');
            ExcelReportBuilderMgr.AddDataToSection('PGDefSumLast', FormatDecimal(TotalAmounts[1]));
            ExcelReportBuilderMgr.AddDataToSection('PgWritingOffAmountLast', FormatDecimal(TotalAmounts[2]));
            ExcelReportBuilderMgr.AddDataToSection('PgWrittenOffAmountLast', FormatDecimal(TotalAmounts[3]));
            ExcelReportBuilderMgr.AddDataToSection('PgRemainAmountLast', FormatDecimal(TotalAmounts[4]));
            ExcelReportBuilderMgr.AddDataToSection('PgWritingOffReportMonthLast', FormatDecimal(TotalAmounts[5]));
            ExcelReportBuilderMgr.AddDataToSection('PgWritingOffReportYearLast', FormatDecimal(TotalAmounts[6]));
            ExcelReportBuilderMgr.AddDataToSection('PgCalcRemainAmountLast', FormatDecimal(TotalAmounts[7]));
            ExcelReportBuilderMgr.AddDataToSection('SubjectToWOffLastTotal', FormatDecimal(TotalAmounts[8]));
            ExcelReportBuilderMgr.AddDataToSection('ExcessivelyWOffLastTotal', FormatDecimal(TotalAmounts[9]));
        end;

        for Count := 1 to ArrayLen(TotalAmounts) do
            TotalReportAmounts[Count] += TotalAmounts[Count];

        Clear(TotalAmounts);
    end;

    local procedure PopulateReportFooter()
    begin
        ExcelReportBuilderMgr.AddSection('REPORTACTTOTAL');
        ExcelReportBuilderMgr.AddDataToSection('TotDefSumLast', FormatDecimal(TotalReportAmounts[1]));
        ExcelReportBuilderMgr.AddDataToSection('TotWritingOffAmountLast', FormatDecimal(TotalReportAmounts[2]));
        ExcelReportBuilderMgr.AddDataToSection('TotWrittenOffAmountLast', FormatDecimal(TotalReportAmounts[3]));
        ExcelReportBuilderMgr.AddDataToSection('TotRemainAmountLast', FormatDecimal(TotalReportAmounts[4]));
        ExcelReportBuilderMgr.AddDataToSection('TotWritingOffReportMonthLast', FormatDecimal(TotalReportAmounts[5]));
        ExcelReportBuilderMgr.AddDataToSection('TotWritingOffReportYearLast', FormatDecimal(TotalReportAmounts[6]));
        ExcelReportBuilderMgr.AddDataToSection('TotCalcRemainAmountLast', FormatDecimal(TotalReportAmounts[7]));
        ExcelReportBuilderMgr.AddDataToSection('TotSubjectToWOffLastTotal', FormatDecimal(TotalReportAmounts[8]));
        ExcelReportBuilderMgr.AddDataToSection('TotExcessivelyWOffLastTotal', FormatDecimal(TotalReportAmounts[9]));

        ExcelReportBuilderMgr.AddSection('REPORTFOOTER');
        ExcelReportBuilderMgr.AddDataToSection('ChairmanTitle', StdRepMgt.GetEmpPosition(Chairman));
        ExcelReportBuilderMgr.AddDataToSection('Chairman', StdRepMgt.GetEmpName(Chairman));
        ExcelReportBuilderMgr.AddDataToSection('Member1Title', StdRepMgt.GetEmpPosition(Commission[1]));
        ExcelReportBuilderMgr.AddDataToSection('Member1', StdRepMgt.GetEmpName(Commission[1]));
        ExcelReportBuilderMgr.AddDataToSection('Member2Title', StdRepMgt.GetEmpPosition(Commission[2]));
        ExcelReportBuilderMgr.AddDataToSection('Member2', StdRepMgt.GetEmpName(Commission[2]));
        ExcelReportBuilderMgr.AddDataToSection('Member3Title', StdRepMgt.GetEmpPosition(Commission[3]));
        ExcelReportBuilderMgr.AddDataToSection('Member3', StdRepMgt.GetEmpName(Commission[3]));

        ExcelReportBuilderMgr.AddDataToSection('ItemsCount', Format(TableLineCounter - 1));

        ExcelReportBuilderMgr.AddDataToSection('InChargeTitle', StdRepMgt.GetEmpPosition(MatRespPerson[1]));
        ExcelReportBuilderMgr.AddDataToSection('InCharge1', StdRepMgt.GetEmpName(MatRespPerson[1]));
        ExcelReportBuilderMgr.AddDataToSection('InChargeTitle2', StdRepMgt.GetEmpPosition(MatRespPerson[2]));
        ExcelReportBuilderMgr.AddDataToSection('InCharge2', StdRepMgt.GetEmpName(MatRespPerson[2]));
        ExcelReportBuilderMgr.AddDataToSection('InChargeTitle3', StdRepMgt.GetEmpPosition(MatRespPerson[3]));
        ExcelReportBuilderMgr.AddDataToSection('InCharge3', StdRepMgt.GetEmpName(MatRespPerson[3]));

        ExcelReportBuilderMgr.AddDataToSection('AccountantTitle', StdRepMgt.GetEmpPosition(CheckedBy));
        ExcelReportBuilderMgr.AddDataToSection('Accountant', StdRepMgt.GetEmpName(CheckedBy));
    end;

    local procedure InitReportTemplate()
    var
        FASetup: Record "FA Setup";
    begin
        FASetup.Get();
        FASetup.TestField("INV-11 Template Code");

        ExcelReportBuilderMgr.InitTemplate(FASetup."INV-11 Template Code");
        ExcelReportBuilderMgr.SetSheet('Sheet1');
    end;

    [Scope('OnPrem')]
    procedure InitializeRequest(NewInvStartDate: Date; NewInvEndDate: Date)
    begin
        InvStartDate := NewInvStartDate;
        InvEndDate := NewInvEndDate;
    end;

    [Scope('OnPrem')]
    procedure SetFileNameSilent(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;

    local procedure FormatDecimal(Value: Decimal): Text
    begin
        exit(StdRepMgt.FormatReportValue(Value, 2));
    end;
}

