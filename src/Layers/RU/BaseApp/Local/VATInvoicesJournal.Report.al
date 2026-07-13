#pragma warning disable AA0247
report 14927 "VAT Invoices Journal"
{
    ApplicationArea = Basic, Suite;
    Caption = 'VAT Invoices Journal';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem(Vendor; Vendor)
        {
            RequestFilterFields = "No.";
        }
        dataitem(Customer; Customer)
        {
            RequestFilterFields = "No.";
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
                    field(Year; Year)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Year';
                        MaxValue = 9999;
                        MinValue = 1;
                        ToolTip = 'Specifies the year.';

                        trigger OnValidate()
                        begin
                            CalcPeriod();
                        end;
                    }
                    field(Quarter; Quarter)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Quarter';
                        ToolTip = 'Specifies the quarter.';

                        trigger OnValidate()
                        begin
                            CalcPeriod();
                        end;
                    }
                    field(StartDate; StartDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'From';
                        Editable = false;
                        ToolTip = 'Specifies the starting point.';
                    }
                    field(EndDate; EndDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'To';
                        Editable = false;
                        ToolTip = 'Specifies the ending point.';
                    }
                    field(ShowCorrection; ShowCorrection)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Show Correction';
                        ToolTip = 'Specifies if the correction lines of an undoing of quantity posting will be shown on the report.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if (StartDate = 0D) or (EndDate = 0D) then begin
                Year := Date2DMY(WorkDate(), 3);
                Quarter := Date2DMY(WorkDate(), 2) div 4;
                CalcPeriod();
            end else begin
                Year := Date2DMY(StartDate, 3);
                Quarter := Date2DMY(StartDate, 2) div 4;
            end;
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    var
        ExcelTemplate: Record "Excel Template";
        FileName: Text[1024];
    begin
        DatePeriod."Period Start" := StartDate;
        DatePeriod."Period End" := EndDate;
        FileName := ExcelTemplate.OpenTemplate(TaxRegSetup."VAT Iss./Rcvd. Jnl. Templ Code");
        ExcelMgt.OpenBookForUpdate(FileName);
        ExcelMgt.OpenSheet('01');
        FillDocHeader();
        ExportIssuedInvoices();
        ExportReceivedInvoices();

        if FileNameSilent <> '' then begin
            ExcelMgt.SaveWrkBook(FileNameSilent);
            ExcelMgt.CloseBook();
        end else
            ExcelMgt.DownloadBook(ExcelTemplate.GetTemplateFileName(TaxRegSetup."VAT Iss./Rcvd. Jnl. Templ Code"));
    end;

    trigger OnPreReport()
    begin
        CompanyInfo.Get();
        TaxRegSetup.Get();
        TaxRegSetup.TestField("VAT Iss./Rcvd. Jnl. Templ Code");
    end;

    var
        DatePeriod: Record Date;
        TaxRegSetup: Record "Tax Register Setup";
        CompanyInfo: Record "Company Information";
        LocRepMgt: Codeunit "Local Report Management";
        ExcelMgt: Codeunit "Excel Management";
        ReportType: Option Received,Issued;
        Quarter: Option "1","2","3","4";
        RowNo: Integer;
        Year: Integer;
        ShowCorrection: Boolean;
        StartDate: Date;
        EndDate: Date;
#pragma warning disable AA0074
        Text001: Label 'Issued VAT Invoices \@1@@@@@@@@@@@@@@@';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text002: Label 'Received VAT Invoices \@1@@@@@@@@@@@@@@@';
#pragma warning restore AA0074
        FileNameSilent: Text;

    [Scope('OnPrem')]
    procedure CalcPeriod()
    begin
        EndDate := CalcDate(StrSubstNo('<+%1Q-1D>', Quarter + 1), DMY2Date(1, 1, Year));
        StartDate := CalcDate('<-CQ>', EndDate);
    end;

    [Scope('OnPrem')]
    procedure CopyRow(var FirstRow: Boolean; var LineNo: Integer)
    begin
        if not FirstRow then begin
            ExcelMgt.CopyRow(RowNo);
            RowNo += 1;
            ExcelMgt.ClearRow(RowNo);
            LineNo += 1;
        end else
            FirstRow := false;
    end;

    [Scope('OnPrem')]
    procedure FillReceivedExcelForm(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var LineNo: Integer; var FirstRow: Boolean)
    var
        VATLedgerLine: Record "VAT Ledger Line" temporary;
        VATInvJnlMgt: Codeunit "VAT Invoice Journal Management";
        Window: Dialog;
        AmtInclVATText: Text[30];
        VATAmtText: Text[30];
        Column: Option " ",Decrease,Increase;
        I: Integer;
        VendLedgEntryCount: Integer;
        VATInvRcvdDate: Date;
        VATEntryType: Code[15];
        CurrDescr: Text[40];
        VATRegNoKPP: Text[30];
    begin
        VendorLedgerEntry.Reset();
        VendorLedgerEntry.SetCurrentKey("Vendor VAT Invoice Rcvd Date", "Entry No.");
        if VendorLedgerEntry.FindSet() then begin
            I := 0;
            VendLedgEntryCount := VendorLedgerEntry.Count;
            Window.Open(Text002);
            repeat
                I += 1;
                Window.Update(1, Round(I / VendLedgEntryCount * 10000, 1));

                CopyRow(FirstRow, LineNo);

                VATInvJnlMgt.GetVATInvJnlLineValues(
                  VendorLedgerEntry, VATLedgerLine, LineNo, ReportType,
                  AmtInclVATText, VATAmtText, Column, VATInvRcvdDate, VATEntryType, CurrDescr, VATRegNoKPP);

                FillVATInvJnlLine(
                  VATLedgerLine, AmtInclVATText, VATAmtText, Column,
                  VATInvRcvdDate, VATEntryType, CurrDescr, VATRegNoKPP);
            until VendorLedgerEntry.Next() = 0;
            Window.Close();
        end;
    end;

    [Scope('OnPrem')]
    procedure FillIssuedExcelForm(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var LineNo: Integer; var FirstRow: Boolean)
    var
        VATLedgerLine: Record "VAT Ledger Line" temporary;
        VATInvJnlMgt: Codeunit "VAT Invoice Journal Management";
        Window: Dialog;
        AmtInclVATText: Text[30];
        VATAmtText: Text[30];
        Column: Option " ",Decrease,Increase;
        I: Integer;
        VendLedgEntryCount: Integer;
        VATInvRcvdDate: Date;
        VATEntryType: Code[15];
        CurrDescr: Text[40];
        VATRegNoKPP: Text[30];
    begin
        VendorLedgerEntry.Reset();
        VendorLedgerEntry.SetCurrentKey("Vendor VAT Invoice Rcvd Date", "Entry No.");
        if VendorLedgerEntry.FindSet() then begin
            I := 0;
            VendLedgEntryCount := VendorLedgerEntry.Count;
            Window.Open(Text001);
            repeat
                I += 1;
                Window.Update(1, Round(I / VendLedgEntryCount * 10000, 1));

                CopyRow(FirstRow, LineNo);

                VATInvJnlMgt.GetVATInvJnlLineValues(
                  VendorLedgerEntry, VATLedgerLine, LineNo, ReportType,
                  AmtInclVATText, VATAmtText, Column, VATInvRcvdDate, VATEntryType, CurrDescr, VATRegNoKPP);

                FillVATInvJnlLine(
                  VATLedgerLine, AmtInclVATText, VATAmtText, Column,
                  VATInvRcvdDate, VATEntryType, CurrDescr, VATRegNoKPP);
            until VendorLedgerEntry.Next() = 0;
            Window.Close();
        end;
    end;

    [Scope('OnPrem')]
    procedure FillDocHeader()
    begin
        ExcelMgt.FillCell('CM12', LocRepMgt.GetCompanyName());
        ExcelMgt.FillCell('CI13', CompanyInfo."VAT Registration No." + ' / ' + CompanyInfo."KPP Code");
        ExcelMgt.FillCell('BU14', Format(Quarter));
        ExcelMgt.FillCell('CO14', CopyStr(Format(Year), 3));
        ExcelMgt.FillCell('CO37', CompanyInfo."Accountant Name");
    end;

    [Scope('OnPrem')]
    procedure FillVATInvJnlLine(VATLedgerLine: Record "VAT Ledger Line"; AmtInclVATText: Text[30]; VATAmtText: Text[30]; Column: Option " ",Decrease,Increase; VATInvRcvdDate: Date; VATEntryType: Code[15]; CurrDescr: Text[40]; VATRegNoKPP: Text[30])
    begin
        ExcelMgt.FillCell('A' + Format(RowNo), Format(VATLedgerLine."Line No."));
        ExcelMgt.FillCell('E' + Format(RowNo), Format(VATInvRcvdDate));
        ExcelMgt.FillCell('L' + Format(RowNo), VATEntryType);
        ExcelMgt.FillCell('R' + Format(RowNo), LocRepMgt.FormatCompoundExpr(VATLedgerLine."Document No.", Format(VATLedgerLine."Document Date")));
        ExcelMgt.FillCell('AH' + Format(RowNo), LocRepMgt.FormatCompoundExpr(VATLedgerLine."Correction No.", Format(VATLedgerLine."Correction Date")));
        if VATLedgerLine."Print Revision" then begin
            if VATLedgerLine."Revision No." <> '' then
                ExcelMgt.FillCell('Z' + Format(RowNo), LocRepMgt.FormatCompoundExpr(VATLedgerLine."Revision No.", Format(VATLedgerLine."Revision Date")));
            if VATLedgerLine."Revision of Corr. No." <> '' then
                ExcelMgt.FillCell(
                  'AP' + Format(RowNo), LocRepMgt.FormatCompoundExpr(VATLedgerLine."Revision of Corr. No.", Format(VATLedgerLine."Revision of Corr. Date")));
        end;
        ExcelMgt.FillCell('AX' + Format(RowNo), VATLedgerLine."C/V Name");
        ExcelMgt.FillCell('BG' + Format(RowNo), VATRegNoKPP);
        if ReportType = ReportType::Issued then
            ExcelMgt.FillCell('DC' + Format(RowNo), CurrDescr)
        else
            ExcelMgt.FillCell('DB' + Format(RowNo), CurrDescr);
        case Column of
            Column::" ":
                begin
                    if ReportType = ReportType::Issued then
                        ExcelMgt.FillCell('DM' + Format(RowNo), AmtInclVATText)
                    else
                        ExcelMgt.FillCell('DL' + Format(RowNo), AmtInclVATText);
                    ExcelMgt.FillCell('EA' + Format(RowNo), VATAmtText);
                end;
            Column::Decrease:
                begin
                    ExcelMgt.FillCell('EJ' + Format(RowNo), AmtInclVATText);
                    ExcelMgt.FillCell('EX' + Format(RowNo), VATAmtText);
                end;
            Column::Increase:
                begin
                    ExcelMgt.FillCell('EQ' + Format(RowNo), AmtInclVATText);
                    ExcelMgt.FillCell('FE' + Format(RowNo), VATAmtText);
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure ExportIssuedInvoices()
    var
        TempVendLedgEntryVend: Record "Vendor Ledger Entry" temporary;
        TempVendLedgEntryCust: Record "Vendor Ledger Entry" temporary;
        VATInvJnlMgt: Codeunit "VAT Invoice Journal Management";
        LineNo: Integer;
        FirstRow: Boolean;
    begin
        ReportType := ReportType::Issued;
        VATInvJnlMgt.GetVendVATList(
          TempVendLedgEntryVend, Vendor, ReportType, DatePeriod, ShowCorrection);
        VATInvJnlMgt.GetCustVATList(
          TempVendLedgEntryCust, Customer, ReportType, DatePeriod, ShowCorrection);

        FirstRow := true;
        RowNo := 21;
        LineNo := 1;
        FillIssuedExcelForm(TempVendLedgEntryVend, LineNo, FirstRow);
        FillIssuedExcelForm(TempVendLedgEntryCust, LineNo, FirstRow);
    end;

    [Scope('OnPrem')]
    procedure ExportReceivedInvoices()
    var
        TempVendLedgEntryVend: Record "Vendor Ledger Entry" temporary;
        TempVendLedgEntryCust: Record "Vendor Ledger Entry" temporary;
        VATInvJnlMgt: Codeunit "VAT Invoice Journal Management";
        FirstRow: Boolean;
        LineNo: Integer;
    begin
        ReportType := ReportType::Received;
        VATInvJnlMgt.GetVendVATList(
          TempVendLedgEntryVend, Vendor, ReportType, DatePeriod, ShowCorrection);
        VATInvJnlMgt.GetCustVATList(
          TempVendLedgEntryCust, Customer, ReportType, DatePeriod, ShowCorrection);

        FirstRow := true;
        RowNo := RowNo + 10;
        LineNo := 1;
        FillReceivedExcelForm(TempVendLedgEntryVend, LineNo, FirstRow);
        FillReceivedExcelForm(TempVendLedgEntryCust, LineNo, FirstRow);
    end;

    [Scope('OnPrem')]
    procedure SetFileNameSilent(NewFileNameSilent: Text)
    begin
        FileNameSilent := NewFileNameSilent;
    end;

    [Scope('OnPrem')]
    procedure InitializeRequest(NewYear: Integer; NewQuarter: Option; NewStartDate: Date; NewEndDate: Date; NewShowCorrection: Boolean)
    begin
        Year := NewYear;
        Quarter := NewQuarter;
        StartDate := NewStartDate;
        EndDate := NewEndDate;
        ShowCorrection := NewShowCorrection;
    end;
}

