#pragma warning disable AA0247
report 12460 "VAT Ledger Export"
{
    Caption = 'VAT Ledger Export';
    ProcessingOnly = true;

    dataset
    {
        dataitem(VATLedger; "VAT Ledger")
        {
            DataItemTableView = sorting(Type, Code);
            dataitem(SalesVATLedgerLine; "VAT Ledger Line")
            {
                DataItemLink = Type = field(Type), Code = field(Code);
                DataItemTableView = sorting(Type, Code, "Line No.") where(Type = const(Sales), "Additional Sheet" = const(false));

                trigger OnAfterGetRecord()
                begin
                    LineNo += 1;
                    ExcelReportBuilderManager.AddSection('BODY');
                    ExportSalesVATLedgerLine(SalesVATLedgerLine);
                end;

                trigger OnPostDataItem()
                begin
                    if not AddSheet and (VATLedgerType = VATLedger.Type::Sales) then
                        ExportSalesVATLedgerLineTotals();
                end;

                trigger OnPreDataItem()
                begin
                    if AddSheet or (VATLedgerType = VATLedger.Type::Purchase) then
                        CurrReport.Break();

                    LineNo := 0;

                    case Sorting of
                        Sorting::"Document Date":
                            SetCurrentKey("Document Date");
                        Sorting::"Document No.":
                            SetCurrentKey("Document No.");
                        Sorting::"Customer No.":
                            SetCurrentKey("C/V No.");
                        else
                            SetCurrentKey("Real. VAT Entry Date");
                    end;
                end;
            }
            dataitem(PurchVATLedgerLine; "VAT Ledger Line")
            {
                DataItemLink = Type = field(Type), Code = field(Code);
                DataItemTableView = sorting(Type, Code, "Line No.") where(Type = const(Purchase), "Additional Sheet" = const(false));

                trigger OnAfterGetRecord()
                begin
                    LineNo += 1;
                    ExcelReportBuilderManager.AddSection('BODY');

                    ExportPurchVATLedgerLine(PurchVATLedgerLine, LineNo);
                end;

                trigger OnPostDataItem()
                begin
                    if AddSheet or (VATLedgerType = VATLedger.Type::Sales) then
                        CurrReport.Break();

                    ExportPurchVATLedgerLineTotals();
                end;

                trigger OnPreDataItem()
                begin
                    if AddSheet or (VATLedgerType = VATLedger.Type::Sales) then
                        CurrReport.Break();

                    LineNo := 0;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if not AddSheet then
                    ExportVATLedgerHeader();
            end;

            trigger OnPreDataItem()
            begin
                SetRange(Type, VATLedgerType);
                SetRange(Code, VATLedgerCode);
            end;
        }
        dataitem(SalesAddSheetPeriod; Date)
        {
            DataItemTableView = sorting("Period Type", "Period Start");
            dataitem(SalesVATLedgerLineAddSheet; "VAT Ledger Line")
            {
                DataItemTableView = sorting(Type, Code, "Line No.") where(Type = const(Sales), "Additional Sheet" = const(true));

                trigger OnAfterGetRecord()
                var
                    SalesInvHeader: Record "Sales Invoice Header";
                    SalesCrMemoHeader: Record "Sales Cr.Memo Header";
                    CorrDocAddSheet: Boolean;
                begin
                    if SalesInvHeader.Get("Document No.") then
                        CorrDocAddSheet := SalesInvHeader."Additional VAT Ledger Sheet";
                    if SalesCrMemoHeader.Get("Document No.") then
                        CorrDocAddSheet := SalesCrMemoHeader."Additional VAT Ledger Sheet";

                    if CorrDocAddSheet then
                        "Document Date" := "Corr. VAT Entry Posting Date";

                    LineNo += 1;
                    ExcelReportBuilderManager.AddSection('BODY');
                    ExportSalesVATLedgerLine(SalesVATLedgerLineAddSheet);
                end;

                trigger OnPostDataItem()
                begin
                    ExportSalesVATLedgerLineTotals();
                end;

                trigger OnPreDataItem()
                begin
                    SetRange("Corr. VAT Entry Posting Date", SalesAddSheetPeriod."Period Start", SalesAddSheetPeriod."Period End");

                    LineNo := 0;

                    case Sorting of
                        Sorting::"Document Date":
                            SetCurrentKey("Document Date");
                        Sorting::"Document No.":
                            SetCurrentKey("Document No.");
                        Sorting::"Customer No.":
                            SetCurrentKey("C/V No.");
                        else
                            SetCurrentKey("Real. VAT Entry Date");
                    end;
                    SetRange(Type, VATLedgerType);
                    SetRange(Code, VATLedgerCode);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                Clear(Totals);
                if SkipPeriod("Period Start", "Period End") then
                    CurrReport.Skip();

                AddSheetCounter += 1;
                StartNewAddSheetSection();
                ExportSalesAddSheetHeader("Period End");
            end;

            trigger OnPreDataItem()
            var
            begin
                AddSheetCounter := 0;

                if not AddSheet or (VATLedgerType = VATLedger.Type::Purchase) then
                    CurrReport.Break();

                if not SetPeriodFilter(SalesAddSheetPeriod) then
                    CurrReport.Break();
            end;
        }
        dataitem(PurchAddSheetPeriod; Date)
        {
            DataItemTableView = sorting("Period Type", "Period Start");
            dataitem(PurchVATLedgerLineAddSheet; "Integer")
            {
                DataItemTableView = sorting(Number);

                trigger OnAfterGetRecord()
                begin
                    if Number = 1 then
                        GroupBuffer.FindSet()
                    else
                        GroupBuffer.Next();

                    LineNo += 1;
                    ExcelReportBuilderManager.AddSection('BODY');

                    ExportPurchVATLedgerLine(GroupBuffer, LineNo);
                end;

                trigger OnPostDataItem()
                begin
                    ExportPurchVATLedgerLineTotals();
                end;

                trigger OnPreDataItem()
                begin
                    SetRange(Number, 1, GroupBuffer.Count);
                    LineNo := 0;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                Clear(Totals);
                if not FillGroupBuffer("Period Start", "Period End") then
                    CurrReport.Skip();

                AddSheetCounter += 1;
                StartNewAddSheetSection();
                ExportPurchAddSheetHeader("Period End");
            end;

            trigger OnPreDataItem()
            begin
                AddSheetCounter := 0;
                if not AddSheet or (VATLedgerType = VATLedger.Type::Sales) then
                    CurrReport.Break();

                if not SetPeriodFilter(PurchAddSheetPeriod) then
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
                    field(Sorting; Sorting)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sorting';
                        ToolTip = 'Specifies how items are sorted on the resulting report.';
                    }
                    field(PeriodType; PeriodType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Period Type';
                        ToolTip = 'Specifies if the period is Day, Month, or Quarter.';
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
        if FileNameSilent <> '' then
            ExcelReportBuilderManager.ExportDataToClientFile(FileNameSilent)
        else
            ExcelReportBuilderManager.ExportData();
    end;

    trigger OnPreReport()
    begin
        CompanyInfo.Get();
        TaxRegSetup.Get();

        case VATLedgerType of
            VATLedger.Type::Purchase:
                if AddSheet then begin
                    TaxRegSetup.TestField("Purch. Add. Sheet Templ. Code");
                    ExcelReportBuilderManager.InitTemplate(TaxRegSetup."Purch. Add. Sheet Templ. Code");
                end else begin
                    TaxRegSetup.TestField("Purch. VAT Ledg. Template Code");
                    ExcelReportBuilderManager.InitTemplate(TaxRegSetup."Purch. VAT Ledg. Template Code");
                end;
            VATLedger.Type::Sales:
                if AddSheet then begin
                    TaxRegSetup.TestField("Sales Add. Sheet Templ. Code");
                    ExcelReportBuilderManager.InitTemplate(TaxRegSetup."Sales Add. Sheet Templ. Code");
                end else begin
                    TaxRegSetup.TestField("Sales VAT Ledg. Template Code");
                    ExcelReportBuilderManager.InitTemplate(TaxRegSetup."Sales VAT Ledg. Template Code");
                end;
        end;

        ExcelReportBuilderManager.SetSheet('Sheet01');
        ExcelReportBuilderManager.AddSection('HEADER');
    end;

    var
        CompanyInfo: Record "Company Information";
        TaxRegSetup: Record "Tax Register Setup";
        GroupBuffer: Record "VAT Ledger Line" temporary;
        LocalReportMgt: Codeunit "Local Report Management";
        LocMgt: Codeunit "Localisation Management";
        VATInvJnlMgt: Codeunit "VAT Invoice Journal Management";
        ExcelReportBuilderManager: Codeunit "Excel Report Builder Manager";
        VATLedgerType: Option;
        Sorting: Option " ","Document Date","Document No.","Customer No.";
        PeriodType: Option Day,Month,Quarter;
        VATLedgerCode: Code[20];
        LineNo: Integer;
        AddSheetCounter: Integer;
        AddSheet: Boolean;
#pragma warning disable AA0074
        Text12405: Label 'Quarter';
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text12406: Label 'From %1 to %2.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        Totals: array[9, 2] of Decimal;
        FileNameSilent: Text;

    procedure InitializeReport(NewVATLedgerType: Option; NewVATLedgerCode: Code[20]; NewAddSheet: Boolean)
    begin
        VATLedgerType := NewVATLedgerType;
        VATLedgerCode := NewVATLedgerCode;
        AddSheet := NewAddSheet;
    end;

    local procedure ExportVATLedgerHeader()
    begin
        if VATLedger.Type = VATLedger.Type::Sales then
            ExportSalesVATLedgerHeader()
        else
            ExportPurchVATLedgerHeader();
    end;

    local procedure ExportSalesVATLedgerHeader()
    begin
        ExcelReportBuilderManager.AddDataToSection('CompanyName', LocalReportMgt.GetCompanyName());
        ExcelReportBuilderManager.AddDataToSection('CompanyVATRegNo',
          CompanyInfo."VAT Registration No." + ' / ' + CompanyInfo."KPP Code");
        ExcelReportBuilderManager.AddDataToSection('StartDate', LocMgt.Date2Text(VATLedger."Start Date"));
        ExcelReportBuilderManager.AddDataToSection('EndDate', LocMgt.Date2Text(VATLedger."End Date"));
    end;

    [Scope('OnPrem')]
    procedure ExportPurchVATLedgerHeader()
    begin
        ExcelReportBuilderManager.AddDataToSection('CompanyName', LocalReportMgt.GetCompanyName());
        ExcelReportBuilderManager.AddDataToSection('CompanyVATRegNo',
          CompanyInfo."VAT Registration No." + ' / ' + CompanyInfo."KPP Code");
        ExcelReportBuilderManager.AddDataToSection('StartDate', LocMgt.Date2Text(VATLedger."Start Date"));
        ExcelReportBuilderManager.AddDataToSection('EndDate', LocMgt.Date2Text(VATLedger."End Date"));
    end;

    local procedure ExportSalesVATLedgerLine(VATLedgerLine: Record "VAT Ledger Line")
    var
        PartialText: Text;
    begin
        PartialText := '';
        if VATLedgerLine.Partial then
            PartialText := LowerCase(VATLedgerLine.FieldCaption(Partial));
        ExcelReportBuilderManager.AddDataToSection('LineNumber', Format(LineNo));
        ExcelReportBuilderManager.AddDataToSection('OperationTypeCode', VATLedgerLine."VAT Entry Type");
        ExcelReportBuilderManager.AddDataToSection(
          'DocumentNoAndDate', LocalReportMgt.FormatCompoundExpr(VATLedgerLine."Document No.", Format(VATLedgerLine."Document Date")));
        ExcelReportBuilderManager.AddDataToSection('CDNo', VATLedgerLine.GetCDNoListString());
        ExcelReportBuilderManager.AddDataToSection('TariffNo', VATLedgerLine."Tariff No.");
        if VATLedgerLine."Print Revision" then begin
            ExcelReportBuilderManager.AddDataToSection(
              'RevisionNoAndDate', LocalReportMgt.FormatCompoundExpr(VATLedgerLine."Revision No.", Format(VATLedgerLine."Revision Date")));
            ExcelReportBuilderManager.AddDataToSection(
              'RevisionOfCorrectionNoAndDate',
              LocalReportMgt.FormatCompoundExpr(VATLedgerLine."Revision of Corr. No.", Format(VATLedgerLine."Revision of Corr. Date")));
        end;
        ExcelReportBuilderManager.AddDataToSection(
          'CorrectionNoAndDate', LocalReportMgt.FormatCompoundExpr(VATLedgerLine."Correction No.", Format(VATLedgerLine."Correction Date")));
        ExcelReportBuilderManager.AddDataToSection('Name', VATLedgerLine."C/V Name");
        ExcelReportBuilderManager.AddDataToSection('VATRegNoAndKPP', VATInvJnlMgt.GetCVVATRegKPP(VATLedgerLine."C/V No.", VATLedgerLine."C/V Type", VATLedgerType));
        if VATLedgerLine.Prepayment or LocalReportMgt.IsVATAgentVendor(VATLedgerLine."C/V No.", VATLedgerLine."C/V Type") then
            ExcelReportBuilderManager.AddDataToSection(
              'ExternalDocNoAndDate', LocalReportMgt.FormatCompoundExpr(VATLedgerLine."External Document No.", Format(VATLedgerLine."Payment Date")));
        if LocalReportMgt.IsForeignCurrency(VATLedgerLine."Currency Code") and
           not LocalReportMgt.IsConventionalCurrency(VATLedgerLine."Currency Code") and
           not LocalReportMgt.HasRelationalCurrCode(VATLedgerLine."Currency Code", VATLedgerLine."Document Date")
        then begin
            ExcelReportBuilderManager.AddDataToSection('CurrencyInfo', GetCurrencyInfo(VATLedgerLine."Currency Code"));
            ExcelReportBuilderManager.AddDataToSection('AmountFCY', FormatValue(Abs(VATLedgerLine.Amount)));
        end;
        ExcelReportBuilderManager.AddDataToSection(
          'AmountLCY', LocalReportMgt.FormatCompoundExpr(FormatValue(VATLedgerLine."Amount Including VAT"), PartialText));
        ExcelReportBuilderManager.AddDataToSection('Base20', FormatBaseValue(VATLedgerLine.Base20, VATLedgerLine.Prepayment));
        ExcelReportBuilderManager.AddDataToSection('Base18', FormatBaseValue(VATLedgerLine.Base18, VATLedgerLine.Prepayment));
        ExcelReportBuilderManager.AddDataToSection('Base10', FormatBaseValue(VATLedgerLine.Base10, VATLedgerLine.Prepayment));
        ExcelReportBuilderManager.AddDataToSection('Amount20', FormatValue(VATLedgerLine.Amount20));
        ExcelReportBuilderManager.AddDataToSection('Amount18', FormatValue(VATLedgerLine.Amount18));
        ExcelReportBuilderManager.AddDataToSection('Amount10', FormatValue(VATLedgerLine.Amount10));
        ExcelReportBuilderManager.AddDataToSection('Base0', FormatBaseValue(VATLedgerLine.Base0, VATLedgerLine.Prepayment));
        ExcelReportBuilderManager.AddDataToSection('BaseVATExempt', FormatValue(VATLedgerLine."Base VAT Exempt"));
        UpdateTotals(VATLedgerLine);
    end;

    local procedure ExportPurchVATLedgerLine(VATLedgerLine: Record "VAT Ledger Line"; LineNo: Integer)
    begin
        ExcelReportBuilderManager.AddDataToSection('LineNumber', Format(LineNo));
        ExcelReportBuilderManager.AddDataToSection('OperationTypeCode', VATLedgerLine."VAT Entry Type");
        ExcelReportBuilderManager.AddDataToSection(
          'DocumentNoAndDate', LocalReportMgt.FormatCompoundExpr(VATLedgerLine."Document No.", Format(VATLedgerLine."Document Date")));
        if VATLedgerLine."Print Revision" then begin
            ExcelReportBuilderManager.AddDataToSection(
              'RevisionNoAndDate', LocalReportMgt.FormatCompoundExpr(VATLedgerLine."Revision No.", Format(VATLedgerLine."Revision Date")));
            ExcelReportBuilderManager.AddDataToSection(
              'RevisionOfCorrectionNoAndDate',
              LocalReportMgt.FormatCompoundExpr(VATLedgerLine."Revision of Corr. No.", Format(VATLedgerLine."Revision of Corr. Date")));
        end;
        ExcelReportBuilderManager.AddDataToSection(
          'CorrectionNoAndDate', LocalReportMgt.FormatCompoundExpr(VATLedgerLine."Correction No.", Format(VATLedgerLine."Correction Date")));
        if VATLedgerLine.Prepayment or LocalReportMgt.IsVATAgentVendor(VATLedgerLine."C/V No.", VATLedgerLine."C/V Type") then
            ExcelReportBuilderManager.AddDataToSection(
              'ExternalDocNoAndDate', LocalReportMgt.FormatCompoundExpr(VATLedgerLine."External Document No.", Format(VATLedgerLine."Payment Date")))
        else
            if VATLedgerLine."Full VAT Amount" <> 0 then
                ExcelReportBuilderManager.AddDataToSection('ExternalDocNoAndDate', GetPurchasePaymentDocNoDate(VATLedgerLine));
        ExcelReportBuilderManager.AddDataToSection(
          'UnrealVATEntryDate', ShowDate(LocalReportMgt.GetVATLedgerItemRealizeDate(VATLedgerLine)));
        ExcelReportBuilderManager.AddDataToSection('Name', VATLedgerLine."C/V Name");
        ExcelReportBuilderManager.AddDataToSection('VATRegNoAndKPP', VATInvJnlMgt.GetCVVATRegKPP(VATLedgerLine."C/V No.", VATLedgerLine."C/V Type", VATLedgerType));
        ExcelReportBuilderManager.AddDataToSection('CDNo', VATLedgerLine.GetCDNoListString());

        case true of
            LocalReportMgt.IsForeignCurrency(VATLedgerLine."Currency Code") and
            not LocalReportMgt.IsConventionalCurrency(VATLedgerLine."Currency Code") and
            not LocalReportMgt.HasRelationalCurrCode(VATLedgerLine."Currency Code", VATLedgerLine."Document Date"):
                begin
                    ExcelReportBuilderManager.AddDataToSection('CurrencyInfo', GetCurrencyInfo(VATLedgerLine."Currency Code"));
                    ExcelReportBuilderManager.AddDataToSection('DocAmount', FormatValue(VATLedgerLine.Amount));
                end;
            LocalReportMgt.IsCustomerPrepayment(VATLedgerLine):
                ExcelReportBuilderManager.AddDataToSection('DocAmount', FormatValue(VATLedgerLine.Amount));
            else
                ExcelReportBuilderManager.AddDataToSection('DocAmount', FormatValue(VATLedgerLine."Amount Including VAT"));
        end;
        ExcelReportBuilderManager.AddDataToSection('VATAmount', FormatValue(VATLedgerLine.Amount10 + VATLedgerLine.Amount18 + VATLedgerLine.Amount20));
        UpdateTotals(VATLedgerLine);
    end;

    local procedure ExportSalesVATLedgerLineTotals()
    begin
        ExcelReportBuilderManager.AddSection('FOOTER');
        ExcelReportBuilderManager.AddDataToSection('TotalBase20', FormatTotalValue(Totals[8] [1], Totals[8] [2]));
        ExcelReportBuilderManager.AddDataToSection('TotalAmount20', FormatTotalValue(Totals[9] [1], Totals[9] [2]));
        ExcelReportBuilderManager.AddDataToSection('TotalBase18', FormatTotalValue(Totals[2] [1], Totals[2] [2]));
        ExcelReportBuilderManager.AddDataToSection('TotalAmount18', FormatTotalValue(Totals[3] [1], Totals[3] [2]));
        ExcelReportBuilderManager.AddDataToSection('TotalBase10', FormatTotalValue(Totals[4] [1], Totals[4] [2]));
        ExcelReportBuilderManager.AddDataToSection('TotalAmount10', FormatTotalValue(Totals[5] [1], Totals[5] [2]));
        ExcelReportBuilderManager.AddDataToSection('TotalBase0', FormatTotalValue(Totals[6] [1], Totals[6] [2]));
        ExcelReportBuilderManager.AddDataToSection('TotalBaseVATExempt', FormatTotalValue(Totals[7] [1], Totals[7] [2]));
    end;

    local procedure ExportPurchVATLedgerLineTotals()
    begin
        ExcelReportBuilderManager.AddSection('FOOTER');
        ExcelReportBuilderManager.AddDataToSection(
          'TotalVATAmount', FormatTotalValue(
            Totals[3] [1] + Totals[5] [1] + Totals[9] [1], Totals[3] [2] + Totals[5] [2] + Totals[9] [2]));
    end;

    local procedure ExportSalesAddSheetHeader(PeriodEnd: Date)
    begin
        ExcelReportBuilderManager.AddDataToSection('AddSheetCounter', Format(AddSheetCounter));
        ExcelReportBuilderManager.AddDataToSection('CompanyName', LocalReportMgt.GetCompanyName());
        ExcelReportBuilderManager.AddDataToSection(
          'CompanyVATRegNoAndKPP', CompanyInfo."VAT Registration No." + ' / ' + CompanyInfo."KPP Code");
        ExcelReportBuilderManager.AddDataToSection('Period', GetMainPeriodDescription(VATLedger."Start Date", VATLedger."End Date"));
        ExcelReportBuilderManager.AddDataToSection('AddSheetDate', Format(NormalDate(PeriodEnd)));
        ExcelReportBuilderManager.AddDataToSection('DirectorName', CompanyInfo."Director Name");
    end;

    local procedure ExportPurchAddSheetHeader(PeriodEnd: Date)
    begin
        ExcelReportBuilderManager.AddDataToSection('AddSheetCounter', Format(AddSheetCounter));
        ExcelReportBuilderManager.AddDataToSection('CompanyName', LocalReportMgt.GetCompanyName());
        ExcelReportBuilderManager.AddDataToSection(
          'CompanyVATRegNoAndKPP', CompanyInfo."VAT Registration No." + ' / ' + CompanyInfo."KPP Code");
        ExcelReportBuilderManager.AddDataToSection('Period', GetMainPeriodDescription(VATLedger."Start Date", VATLedger."End Date"));
        ExcelReportBuilderManager.AddDataToSection('AddSheetDate', Format(NormalDate(PeriodEnd)));
        ExcelReportBuilderManager.AddDataToSection('DirectorName', CompanyInfo."Director Name");
    end;

    local procedure FormatBaseValue(var VATBase: Decimal; Prepayment: Boolean): Text
    begin
        if VATBase <> 0 then begin
            if Prepayment then begin
                VATBase := 0;
                exit('-');
            end else
                exit(Format(VATBase, 0, '<Precision,2:2><Standard Format,0>'));
        end else
            exit('');
    end;

    local procedure FormatValue(Value: Decimal): Text
    begin
        if Value <> 0 then
            exit(LocalReportMgt.FormatReportValue(Value, 2));
        exit('');
    end;

    local procedure FormatTotalValue(FormatedValue: Decimal; Value: Decimal): Text
    begin
        if Value <> 0 then
            exit(LocalReportMgt.FormatReportValue(FormatedValue, 2));
        exit('');
    end;

    local procedure ShowDate(Date: Date): Text
    begin
        if Date = 0D then
            exit('-');
        exit(Format(Date));
    end;

    local procedure GetCurrencyInfo(CurrencyCode: Code[10]) CurrencyDescription: Text
    var
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
    begin
        CurrencyDescription := '';
        if CurrencyCode = '' then begin
            GLSetup.Get();
            CurrencyCode := GLSetup."LCY Code";
        end;

        if Currency.Get(CurrencyCode) then begin
            CurrencyDescription :=
              LowerCase(CopyStr(Currency.Description, 1, 1)) + CopyStr(Currency.Description, 2);
            if Currency."RU Bank Digital Code" <> '' then
                if CurrencyDescription <> '' then
                    CurrencyDescription := CurrencyDescription + '; ' + Currency."RU Bank Digital Code"
                else
                    CurrencyDescription := Currency."RU Bank Digital Code";
        end;
    end;

    local procedure SetPeriodFilter(var Period: Record Date): Boolean
    var
        VATLedgerLine: Record "VAT Ledger Line";
        MinDate: Date;
        MaxDate: Date;
    begin
        MinDate := 0D;
        MaxDate := 0D;

        VATLedgerLine.SetCurrentKey("Corr. VAT Entry Posting Date");
        VATLedgerLine.SetRange(Type, VATLedgerType);
        VATLedgerLine.SetRange(Code, VATLedgerCode);
        VATLedgerLine.SetRange("Additional Sheet", true);
        if VATLedgerLine.FindFirst() then
            MinDate := VATLedgerLine."Corr. VAT Entry Posting Date";
        if VATLedgerLine.FindLast() then
            MaxDate := VATLedgerLine."Corr. VAT Entry Posting Date";

        if MinDate <> 0D then
            case PeriodType of
                PeriodType::Day:
                    Period.SetRange("Period Type", Period."Period Type"::Date);
                PeriodType::Month:
                    begin
                        Period.SetRange("Period Type", Period."Period Type"::Month);
                        MinDate := CalcDate('<-CM>', MinDate);
                        MaxDate := CalcDate('<CM>', MaxDate);
                    end;
                PeriodType::Quarter:
                    begin
                        Period.SetRange("Period Type", Period."Period Type"::Quarter);
                        MinDate := CalcDate('<-CQ>', MinDate);
                        MaxDate := CalcDate('<CQ>', MaxDate);
                    end;
            end;

        Period.SetRange("Period Start", MinDate, MaxDate);
        exit(not Period.IsEmpty);
    end;

    local procedure SkipPeriod(PeriodStartDate: Date; PeriodEndDate: Date): Boolean
    var
        VATLedgerLine: Record "VAT Ledger Line";
    begin
        VATLedgerLine.SetRange(Type, VATLedger.Type);
        VATLedgerLine.SetRange(Code, VATLedger.Code);
        VATLedgerLine.SetRange("Additional Sheet", true);
        VATLedgerLine.SetRange("Corr. VAT Entry Posting Date", PeriodStartDate, PeriodEndDate);
        exit(VATLedgerLine.IsEmpty);
    end;

    local procedure FillGroupBuffer(PeriodStartDate: Date; PeriodEndDate: Date): Boolean
    var
        SourceVATEntry: Record "VAT Entry";
        AdjustingVATEntry: Record "VAT Entry";
        AdjustingVATEntryBuffer: Record "VAT Entry" temporary;
        VATLedgerConnection: Record "VAT Ledger Connection";
        VATLedgerLine: Record "VAT Ledger Line";
        VATLedgerLineBuffer: Record "VAT Ledger Line" temporary;
        AdjustingVATLedgerLine: Record "VAT Ledger Line";
    begin
        VATLedgerLine.SetRange(Type, VATLedger.Type);
        VATLedgerLine.SetRange(Code, VATLedger.Code);
        VATLedgerLine.SetRange("Additional Sheet", true);
        VATLedgerLine.SetRange("Corr. VAT Entry Posting Date", PeriodStartDate, PeriodEndDate);
        if VATLedgerLine.FindSet() then
            repeat
                VATLedgerConnection.Reset();
                VATLedgerConnection.SetRange("Connection Type", VATLedgerConnection."Connection Type"::Purchase);
                VATLedgerConnection.SetRange("Purch. Ledger Code", VATLedger.Code);
                VATLedgerConnection.SetRange("Purch. Ledger Line No.", VATLedgerLine."Line No.");
                if VATLedgerConnection.FindFirst() then begin
                    SourceVATEntry.Get(VATLedgerConnection."VAT Entry No.");
                    VATLedgerLineBuffer.TransferFields(VATLedgerLine);

                    if SourceVATEntry."Adjusted VAT Entry No." = 0 then begin
                        AdjustingVATEntry.SetRange("Adjusted VAT Entry No.", SourceVATEntry."Entry No.");
                        AdjustingVATEntry.SetRange("Posting Date", PeriodStartDate, PeriodEndDate);
                        if AdjustingVATEntry.FindFirst() then begin
                            VATLedgerConnection.SetRange("Purch. Ledger Line No.");
                            VATLedgerConnection.SetRange("VAT Entry No.", AdjustingVATEntry."Entry No.");
                            if VATLedgerConnection.FindFirst() then
                                if AdjustingVATLedgerLine.Get(
                                  VATLedger.Type, VATLedger.Code, VATLedgerConnection."Purch. Ledger Line No.")
                                then begin
                                    VATLedgerLineBuffer."Amount Including VAT" += AdjustingVATLedgerLine."Amount Including VAT";
                                    VATLedgerLineBuffer.Base10 += AdjustingVATLedgerLine.Base10;
                                    VATLedgerLineBuffer.Amount10 += AdjustingVATLedgerLine.Amount10;
                                    VATLedgerLineBuffer.Base0 += AdjustingVATLedgerLine.Base0;
                                    VATLedgerLineBuffer."Base VAT Exempt" += AdjustingVATLedgerLine."Base VAT Exempt";
                                    VATLedgerLineBuffer."Full VAT Amount" += AdjustingVATLedgerLine."Full VAT Amount";
                                    VATLedgerLineBuffer.Base18 += AdjustingVATLedgerLine.Base18;
                                    VATLedgerLineBuffer.Amount18 += AdjustingVATLedgerLine.Amount18;
                                    VATLedgerLineBuffer.Base20 += AdjustingVATLedgerLine.Base20;
                                    VATLedgerLineBuffer.Amount20 += AdjustingVATLedgerLine.Amount20;
                                    AdjustingVATEntryBuffer.TransferFields(AdjustingVATEntry);
                                    AdjustingVATEntryBuffer.Insert();
                                end;
                        end;

                    end;

                    if not AdjustingVATEntryBuffer.Get(SourceVATEntry."Entry No.") then
                        VATLedgerLineBuffer.Insert();
                end;
            until VATLedgerLine.Next() = 0;

        GroupBuffer.Reset();
        GroupBuffer.DeleteAll();

        if VATLedgerLineBuffer.FindSet() then
            repeat
                GroupBuffer.SetRange("Payment Date", VATLedgerLineBuffer."Payment Date");
                GroupBuffer.SetRange("Document No.", VATLedgerLineBuffer."Document No.");
                GroupBuffer.SetRange("C/V No.", VATLedgerLineBuffer."C/V No.");
                GroupBuffer.SetRange(Correction, VATLedgerLineBuffer.Correction);
                if not GroupBuffer.FindFirst() then begin
                    GroupBuffer.TransferFields(VATLedgerLineBuffer);
                    GroupBuffer.Insert();
                end else begin
                    GroupBuffer."Amount Including VAT" += VATLedgerLineBuffer."Amount Including VAT";
                    GroupBuffer.Base10 += VATLedgerLineBuffer.Base10;
                    GroupBuffer.Amount10 += VATLedgerLineBuffer.Amount10;
                    GroupBuffer.Base0 += VATLedgerLineBuffer.Base0;
                    GroupBuffer."Base VAT Exempt" += VATLedgerLineBuffer."Base VAT Exempt";
                    GroupBuffer."Full VAT Amount" += VATLedgerLineBuffer."Full VAT Amount";
                    GroupBuffer.Base18 += VATLedgerLineBuffer.Base18;
                    GroupBuffer.Amount18 += VATLedgerLineBuffer.Amount18;
                    GroupBuffer.Base20 += VATLedgerLineBuffer.Base20;
                    GroupBuffer.Amount20 += VATLedgerLineBuffer.Amount20;
                    GroupBuffer.Modify();
                end;
            until VATLedgerLineBuffer.Next() = 0;

        GroupBuffer.Reset();
        exit(not GroupBuffer.IsEmpty);
    end;

    local procedure GetMainPeriodDescription(StartDate: Date; EndDate: Date) MainPeriodDescription: Text
    var
        Period: Record Date;
    begin
        Period.SetRange("Period Type", Period."Period Type"::Month);
        Period.SetRange("Period Start", StartDate, EndDate);
        if Period.Count = 1 then begin
            Period.FindFirst();
            MainPeriodDescription := Period."Period Name" + ' ' + Format(Date2DMY(EndDate, 3));
        end else begin
            Period.SetRange("Period Type", Period."Period Type"::Quarter);
            if Period.Count = 1 then begin
                Period.FindFirst();
                MainPeriodDescription :=
                  Period."Period Name" + ' ' + Text12405 + ' ' + Format(Date2DMY(EndDate, 3));
            end else
                MainPeriodDescription := StrSubstNo(Text12406, StartDate, EndDate);
        end;
    end;

    local procedure UpdateTotals(VATLedgLine: Record "VAT Ledger Line")
    begin
        Totals[1] [1] += VATLedgLine."Amount Including VAT";
        Totals[1] [2] += Abs(VATLedgLine."Amount Including VAT");
        Totals[2] [1] += VATLedgLine.Base18;
        Totals[2] [2] += Abs(VATLedgLine.Base18);
        Totals[3] [1] += VATLedgLine.Amount18;
        Totals[3] [2] += Abs(VATLedgLine.Amount18);
        Totals[4] [1] += VATLedgLine.Base10;
        Totals[4] [2] += Abs(VATLedgLine.Base10);
        Totals[5] [1] += VATLedgLine.Amount10;
        Totals[5] [2] += Abs(VATLedgLine.Amount10);
        Totals[6] [1] += VATLedgLine.Base0;
        Totals[6] [2] += Abs(VATLedgLine.Base0);
        Totals[7] [1] += VATLedgLine."Base VAT Exempt";
        Totals[7] [2] += Abs(VATLedgLine."Base VAT Exempt");
        Totals[8] [1] += VATLedgLine.Base20;
        Totals[8] [2] += Abs(VATLedgLine.Base20);
        Totals[9] [1] += VATLedgLine.Amount20;
        Totals[9] [2] += Abs(VATLedgLine.Amount20);
    end;

    procedure SetFileNameSilent(NewFileNameSilent: Text)
    begin
        FileNameSilent := NewFileNameSilent;
    end;

    local procedure GetPurchasePaymentDocNoDate(VATLedgerLine: Record "VAT Ledger Line"): Text
    var
        TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary;
        PaymentDocNoDate: Text;
    begin
        VATLedgerLine.GetPmtVendorDtldLedgerLines(VATLedger."End Date", TempVendorLedgerEntry);
        if TempVendorLedgerEntry.FindSet() then
            repeat
                PaymentDocNoDate :=
                  LocalReportMgt.FormatCompoundExpr(
                    PaymentDocNoDate,
                    LocalReportMgt.FormatCompoundExpr(
                      TempVendorLedgerEntry."External Document No.", Format(TempVendorLedgerEntry."Posting Date")));
            until TempVendorLedgerEntry.Next() = 0;
        exit(PaymentDocNoDate);
    end;

    local procedure StartNewAddSheetSection()
    begin
        if AddSheetCounter > 1 then begin
            ExcelReportBuilderManager.AddPagebreak();
            ExcelReportBuilderManager.AddSection('HEADER');
        end;
    end;
}
