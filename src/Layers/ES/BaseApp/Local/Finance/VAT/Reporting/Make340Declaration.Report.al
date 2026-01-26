// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Check;
using Microsoft.Bank.Ledger;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Ledger;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using System.IO;
using System.Telemetry;
using System.Utilities;

report 10743 "Make 340 Declaration"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Make 340 Declaration';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = sorting(Number);
            dataitem(VATEntry; "VAT Entry")
            {
                DataItemTableView = sorting(Type, "VAT Reporting Date", "Document Type", "Document No.", "Bill-to/Pay-to No.") where(Type = filter(Sale | Purchase));
                RequestFilterFields = "Document Type", "Document No.";
                dataitem(VATEntry2; "VAT Entry")
                {
                    DataItemLink = Type = field(Type), "Document Type" = field("Document Type"), "Document No." = field("Document No."), "Bill-to/Pay-to No." = field("Bill-to/Pay-to No."), "Transaction No." = field("Transaction No.");
                    DataItemTableView = sorting(Type, "VAT Reporting Date", "Document Type", "Document No.", "Bill-to/Pay-to No.");

                    trigger OnAfterGetRecord()
                    var
                        OperationCodeRec: Record "Operation Code";
                        NewEntry: Boolean;
                    begin
                        OperationCode := GetOperationCode(VATEntry2);

                        VATBuffer."VAT %" := "VAT %";
                        VATBuffer."EC %" := "EC %";
                        VATBuffer."EC Amount" := 0;

                        if "VAT Calculation Type" = "VAT Calculation Type"::"Full VAT" then
                            Base := 0;
                        if VATBuffer.Find() then begin
                            if VATEntry.Type = VATEntry.Type::Sale then begin
                                VATBuffer.Base := VATBuffer.Base - GetTotalBase();
                                if VATBuffer."VAT %" <> 0 then
                                    VATBuffer.Amount := VATBuffer.Amount - GetTotalAmount()
                            end;
                            if VATEntry.Type = VATEntry.Type::Purchase then begin
                                VATBuffer.Base := VATBuffer.Base + GetTotalBase();
                                if VATBuffer."VAT %" <> 0 then
                                    VATBuffer.Amount := VATBuffer.Amount + GetTotalAmount()
                            end;
                            VATBuffer.Modify();
                            if not (GetOperationCode(VATEntry2) in ['C', 'D', 'I', 'Z', '2', '3']) and not OperationCodeRec.Get(OperationCode) then
                                OperationCode := ' ';
                        end else begin
                            if VATEntry.Type = VATEntry.Type::Sale then begin
                                VATBuffer.Base := -GetTotalBase();
                                if VATBuffer."VAT %" = 0 then
                                    VATBuffer.Amount := 0
                                else
                                    VATBuffer.Amount := -GetTotalAmount();
                            end;
                            if VATEntry.Type = VATEntry.Type::Purchase then begin
                                VATBuffer.Base := GetTotalBase();
                                if VATBuffer."VAT %" = 0 then
                                    VATBuffer.Amount := 0
                                else
                                    VATBuffer.Amount := GetTotalAmount();
                            end;
                            VATBuffer.Insert();
                        end;

                        if IsEmptyVATBuffer(VATBuffer) then
                            VATBuffer.Delete();
                        if Type = VATEntry.Type::Purchase then begin
                            NewEntry := false;
                            if HasBeenRealized("Entry No.") or ("Unrealized VAT Entry No." <> 0) then
                                NewEntry := CheckVLEApplication(VATEntry2);

                            VATEntryTemporary.SetRange("VAT Reporting Date", "VAT Reporting Date");
                            VATEntryTemporary.SetRange("Document No.", "Document No.");
                            VATEntryTemporary.SetRange("Document Type", "Document Type");
                            VATEntryTemporary.SetRange(Type, Type);
                            VATEntryTemporary.SetRange("VAT %", "VAT %");
                            VATEntryTemporary.SetRange("Transaction No.", "Transaction No.");
                            if VATEntryTemporary.FindFirst() and not NewEntry then begin
                                VATEntryTemporary.Base += Base;
                                VATEntryTemporary.Amount += Amount;
                                VATEntryTemporary.Modify();
                            end else begin
                                VATEntryTemporary := VATEntry2;
                                VATEntryTemporary.Insert();
                            end;

                            // Collect Unrealized VAT buffer per VATEntryTemporary
                            if "Unrealized VAT Entry No." <> 0 then begin
                                TempGLEntryVATEntryLink."G/L Entry No." := VATEntryTemporary."Entry No.";
                                TempGLEntryVATEntryLink."VAT Entry No." := "Unrealized VAT Entry No.";
                                if TempGLEntryVATEntryLink.Insert() then;
                            end;

                            VATEntryTemporary.Reset();
                        end;
                    end;

                    trigger OnPreDataItem()
                    var
                        SourceCodeSetup: Record "Source Code Setup";
                        UnrealizedVATEntry: Record "VAT Entry";
                        ShouldExit: Boolean;
                    begin
                        SalesCrMemoHeader.Reset();
                        SalesInvHeader.Reset();
                        Customer.Reset();
                        PurchCrMemoHeader.Reset();
                        PurchInvHeader.Reset();
                        Vendor.Reset();
                        GLSetup.Get();
                        VATDeductAmt := 0;
                        VendorDocumentNo := '';
                        VATEntryTemporary.Reset();
                        VATEntryTemporary.DeleteAll();
                        TempGLEntryVATEntryLink.DeleteAll(); // Used for collect Unrealized VAT buffer per VATEntryTemporary
                        SetFilter("VAT Reporting Date", '%1..%2' + VATEntryDateFilter, FromDate, ToDate);
                        case VATEntry.Type of
                            VATEntry.Type::Sale:
                                begin
                                    Customer.Get(VATEntry."Bill-to/Pay-to No.");
                                    case VATEntry."Document Type" of
                                        VATEntry."Document Type"::Invoice:
                                            begin
                                                SourceCodeSetup.Get();
                                                if VATEntry."Source Code" = SourceCodeSetup.Sales then begin
                                                    if SalesInvHeader.Get(VATEntry."Document No.") then begin
                                                        Customer.Name := SalesInvHeader."Bill-to Name";
                                                        Customer."VAT Registration No." := SalesInvHeader."VAT Registration No.";
                                                        exit;
                                                    end
                                                end else begin
                                                    ShouldExit := false;
                                                    OnGetCustomerDataFromServiceInvoice(VATEntry, Customer, ShouldExit);
                                                    if ShouldExit then
                                                        exit;
                                                end;
                                            end;
                                        VATEntry."Document Type"::"Credit Memo":
                                            begin
                                                SourceCodeSetup.Get();
                                                if VATEntry."Source Code" = SourceCodeSetup.Sales then begin
                                                    if SalesCrMemoHeader.Get(VATEntry."Document No.") then begin
                                                        Customer.Name := SalesCrMemoHeader."Bill-to Name";
                                                        Customer."VAT Registration No." := SalesCrMemoHeader."VAT Registration No.";
                                                        exit;
                                                    end
                                                end else begin;
                                                    ShouldExit := false;
                                                    OnGetCustomerDataFromServiceCrMemo(VATEntry, Customer, ShouldExit);
                                                    if ShouldExit then
                                                        exit;
                                                end;
                                            end;
                                    end;
                                end;
                            VATEntry.Type::Purchase:
                                begin
                                    Vendor.Get(VATEntry."Bill-to/Pay-to No.");
                                    VendorDocumentNo := VATEntry."External Document No.";
                                    case VATEntry."Document Type" of
                                        VATEntry."Document Type"::Invoice:
                                            if PurchInvHeader.Get(VATEntry."Document No.") then begin
                                                Vendor.Name := PurchInvHeader."Pay-to Name";
                                                Vendor."VAT Registration No." := PurchInvHeader."VAT Registration No.";
                                                exit;
                                            end;
                                        VATEntry."Document Type"::"Credit Memo":
                                            if PurchCrMemoHeader.Get(VATEntry."Document No.") then begin
                                                Vendor.Name := PurchCrMemoHeader."Pay-to Name";
                                                Vendor."VAT Registration No." := PurchCrMemoHeader."VAT Registration No.";
                                                exit;
                                            end;
                                        VATEntry."Document Type"::Payment,
                                        VATEntry."Document Type"::Refund:
                                            begin
                                                if VATEntry."Unrealized VAT Entry No." <> 0 then
                                                    if FindPmtOrderBillGrBankAcc(VATEntry.Type, VATEntry."Document No.") <> '' then
                                                        VendorDocumentNo := VATEntry."Document No."
                                                    else begin
                                                        UnrealizedVATEntry.Get(VATEntry."Unrealized VAT Entry No.");
                                                        VendorDocumentNo := FindAppliedToDocumentNo(UnrealizedVATEntry);
                                                    end;
                                                exit;
                                            end;
                                    end;
                                end;
                        end;
                    end;
                }
                dataitem("<Integer2>"; "Integer")
                {
                    DataItemTableView = sorting(Number);

                    trigger OnAfterGetRecord()
                    begin
                        if Fin then
                            CurrReport.Break();
                        if ((VATEntry.Type = VATEntry.Type::Sale) or (VATEntry.Type = VATEntry.Type::Purchase)) and
                           (VATBuffer."EC %" <> 0)
                        then
                            VATBuffer."EC Amount" := Round(VATBuffer.Base * VATBuffer."EC %" / 100);
                        VATBuffer2 := VATBuffer;
                        if VATBuffer2.Amount = 0 then
                            VATBuffer2."VAT %" := 0;
                        if VATBuffer2."EC Amount" = 0 then
                            VATBuffer2."EC %" := 0;
                        if VATEntry.Type = VATEntry.Type::Sale then
                            RecordTypeSale();
                        if VATEntry.Type = VATEntry.Type::Purchase then begin
                            VATEntryTemporary.SetCurrentKey("VAT %", "EC %");
                            VATEntryTemporary.SetRange("VAT %", VATBuffer."VAT %");
                            VATEntryTemporary.SetRange("EC %", VATBuffer."EC %");
                            VATEntryTemporary.FindSet();
                            repeat
                                VATDeductAmt := CheckDeductibleVAT(VATEntryTemporary);
                                RecordTypePurchase(VATEntryTemporary);
                            until VATEntryTemporary.Next() = 0;
                        end;
                        Fin := VATBuffer.Next() = 0;
                    end;

                    trigger OnPreDataItem()
                    begin
                        if VATBuffer.Find('-') then;
                        if VATEntryTemporary.Find('-') then;
                        Fin := false;
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if not CheckIncludeVATEntry(VATEntry) then
                        CurrReport.Skip();

                    VATBuffer.DeleteAll();

                    TempVATEntry.SetRange(Type, Type);
                    TempVATEntry.SetRange("Document No.", "Document No.");
                    TempVATEntry.SetRange("Document Type", "Document Type");
                    TempVATEntry.SetRange("Bill-to/Pay-to No.", "Bill-to/Pay-to No.");
                    TempVATEntry.SetRange("Transaction No.", "Transaction No.");
                    if not TempVATEntry.IsEmpty() then
                        CurrReport.Skip();

                    case Type of
                        Type::Sale:
                            begin
                                SkipZeroCustLedgEntry("Transaction No.");
                                if "Unrealized VAT Entry No." <> 0 then
                                    SkipUnappliedCustLedgEntry("Transaction No.");
                                BookTypeCode := 'E';
                            end;
                        Type::Purchase:
                            begin
                                SkipZeroVendLedgEntry("Transaction No.");
                                if "Unrealized VAT Entry No." <> 0 then
                                    SkipUnappliedVendLedgEntry("Transaction No.");
                                BookTypeCode := 'R';
                            end;
                    end;

                    TempVATEntry.Reset();
                    if TempVATEntry.FindLast() then;
                    TempVATEntry."Entry No." := TempVATEntry."Entry No." + 1;
                    TempVATEntry.Type := Type;
                    TempVATEntry."Document No." := "Document No.";
                    TempVATEntry."Document Type" := "Document Type";
                    TempVATEntry."Bill-to/Pay-to No." := "Bill-to/Pay-to No.";
                    TempVATEntry."Transaction No." := "Transaction No.";
                    TempVATEntry.Insert();
                end;

                trigger OnPreDataItem()
                begin
                    SetFilter("VAT Reporting Date", '%1..%2' + VATEntryDateFilter, FromDate, ToDate);
                    if Counter = 1 then begin
                        SetFilter(Type, '%1' + VATEntryTypeFilter, Type::Sale);
                        CreateTempDeclarationLineForSalesInvNoTaxVAT();
                        CreateTempDeclarationLineForSalesCrMemoNoTaxVAT();
                    end;
                    if Counter = 2 then begin
                        SetFilter(Type, '%1' + VATEntryTypeFilter, Type::Purchase);
                        CreateTempDeclarationLineForPurchInvNoTaxVAT();
                        CreateTempDeclarationLineForPurchCrMemoNoTaxVAT();
                    end;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                Counter += 1;
            end;

            trigger OnPreDataItem()
            begin
                SetRange(Number, 1, 2);
                Counter := 0;
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
                    field(FiscalYear; FiscalYear)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Fiscal Year';
                        Numeric = true;
                        ShowMandatory = true;
                        ToolTip = 'Specifies the year of the reporting period. It must be 4 digits without spaces or special characters.';

                        trigger OnValidate()
                        begin
                            FiscalYearText := FiscalYear;
                            if StrLen(FiscalYearText) <> MaxStrLen(FiscalYearText) then
                                Error(WrongFiscalYearFormatErr, MaxStrLen(FiscalYearText));

                            if not Evaluate(NumFiscalYear, FiscalYear) or (NumFiscalYear < 0) then
                                Error(WrongFiscalYearFormatErr, MaxStrLen(FiscalYearText));
                        end;
                    }
                    group(Period)
                    {
                        Caption = 'Period';
                        field(Month; Month)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Month';
                            OptionCaption = ',January,February,March,April,May,June,July,August,September,October,November,December';
                            ShowMandatory = true;
                            ToolTip = 'Specifies the month that you want to include in the operations declaration.';
                        }
                    }
                    field(MinPaymentAmount; MinPaymentAmount)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Min. Payment Amount';
                        ToolTip = 'Specifies the amount that you have received in cash. The amount that you have selected determines the sum of customer entries in the report. If the total invoiced amount for a customer for each year is less than the amount specified in the field, then the sum of the customer entries is not included in the report. If the total invoiced amount for a customer for each year is greater than the amount specified in the field, then the sum of customer entries is included in the report. When you export the data to a declaration file, the Amount Received in Cash field in the file contains the accumulated amount of customer entries in one line per year.';

                        trigger OnValidate()
                        begin
                            while StrLen(DeclarationNum) < MaxStrLen(DeclarationNum) do
                                DeclarationNum := '0' + DeclarationNum;
                        end;
                    }
                    field(ColumnGLAcc; ColumnGLAcc)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'G/L Acc. for Payments in Cash';
                        Editable = false;
                        ToolTip = 'Specifies one or more on general ledger accounts for cash payments. When you export the data to a declaration file, the Amount Received in Cash field in the file contains the accumulated value for the selected general ledger accounts. If you do not select any general ledger accounts, then type 2 lines for payments in cash will not be created.';

                        trigger OnAssistEdit()
                        var
                            GLAccSelectionBuf: Record "G/L Account Buffer";
                        begin
                            GLAccSelectionBuf.SetGLAccSelectionMultiple(ColumnGLAcc, GLAccFilterString);
                        end;
                    }
                    field(ContactName; ContactName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Contact Name';
                        ShowMandatory = true;
                        ToolTip = 'Specifies the name of the person making the declaration.';
                    }
                    field(ContactTelephone; ContactTelephone)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Telephone Number';
                        Numeric = true;
                        ShowMandatory = true;
                        ToolTip = 'Specifies the phone number as 9 digits without spaces or special characters.';

                        trigger OnValidate()
                        begin
                            if StrLen(ContactTelephone) <> MaxStrLen(ContactTelephone) then
                                Error(WrongContactTelephoneFormatErr, MaxStrLen(ContactTelephone));
                        end;
                    }
                    field(ColumnGPPG; ColumnGPPG)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Non Deduct. Gen. Prod. Post. Groups';
                        Editable = false;
                        ToolTip = 'Specifies the general product posting group for non-deductible VAT.';

                        trigger OnAssistEdit()
                        var
                            GPPGSelectionBuf: Record "Gen. Prod. Post. Group Buffer";
                        begin
                            GPPGSelectionBuf.SetNonDedGPPGSelectMultiple340(ColumnGPPG, GPPGFilterString);
                        end;
                    }
                    field(DeclarationNum; DeclarationNum)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Declaration Number';
                        Numeric = true;
                        ShowMandatory = true;
                        ToolTip = 'Specifies a number to identify the operations declaration.';

                        trigger OnValidate()
                        begin
                            while StrLen(DeclarationNum) < MaxStrLen(DeclarationNum) do
                                DeclarationNum := '0' + DeclarationNum;
                        end;
                    }
                    field(ElectronicCode; ElectronicCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Electronic Code';
                        ShowMandatory = true;
                        ToolTip = 'Specifies the electronic code as 16 digits without spaces or special characters.';

                        trigger OnValidate()
                        begin
                            if StrLen(ElectronicCode) <> MaxStrLen(ElectronicCode) then
                                Error(WrongElectronicCodeErr, MaxStrLen(ElectronicCode));
                        end;
                    }
                    field(DeclarationMediaType; DeclarationMediaType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Declaration Media Type';
                        OptionCaption = 'Telematic,CD-R';
                        ToolTip = 'Specifies the media type for the declaration. To submit the declaration electronically, select Telematic. To submit the declaration on a CD-ROM, select Physical support.';
                    }
                    field(ReplaceDeclaration; ReplaceDeclaration)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Replacement Declaration';
                        ToolTip = 'Specifies if this is a replacement of a previously sent declaration.';

                        trigger OnValidate()
                        begin
                            ReplaceDeclarationOnPush();
                        end;
                    }
                    field(PrevDeclarationNum; PrevDeclareNum)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Previous Declaration Number';
                        Enabled = PrevDeclarationNumEnable;
                        Numeric = true;
                        ToolTip = 'Specifies the number as 13 digits without spaces or special characters.';

                        trigger OnValidate()
                        begin
                            if (StrLen(PrevDeclareNum) <> MaxStrLen(PrevDeclareNum)) or (StrPos(PrevDeclareNum, ' ') <> 0) then
                                Error(WrongPreviousDeclarationNoErr, MaxStrLen(PrevDeclareNum));
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            PrevDeclarationNumEnable := true;
            if FiscalYear = '' then
                FiscalYear := Format(Date2DMY(WorkDate(), 3));
            if Month = 0 then
                Month := 1;
        end;

        trigger OnOpenPage()
        begin
            PrevDeclarationNumEnable := ReplaceDeclaration;
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        PopulateAppliedPayments();
        if TempDeclarationLines.FindFirst() then begin
            Commit();
            if PAGE.RunModal(10744, TempDeclarationLines) = ACTION::LookupOK then begin
                TempDeclarationLines.SetRange("Operation Code", 'R');
                TempDeclarationLines.SetRange("Property Location", TempDeclarationLines."Property Location"::" ");
                TempDeclarationLines.SetRange(Type, TempDeclarationLines.Type::Sale);
                if not TempDeclarationLines.IsEmpty() then
                    exit;
                TempDeclarationLines.Reset();
                CreateFileHeader();
                WriteDeclarationLinesToText(TempDeclarationLines);
            end else
                exit;
        end;

        WriteAppliedPaymentsToText();
        if FileHeaderCreated then begin
            OutFile.Close();
            DownloadFile();
        end else
            Error(NoRecordsFoundErr);
        FeatureTelemetry.LogUsage('1000HV4', ESReport340Tok, 'ES 340 Reports Created');
    end;

    trigger OnPreReport()
    var
        CustomerCashBuffer: Record "Customer Cash Buffer";
        RBMgt: Codeunit "File Management";
    begin
        IntegerCounter := 0;
        CompanyInfo.Get();
        if CompanyInfo."VAT Registration No." = '' then
            Error(MissingVATRegistrationNoErr);
        if FiscalYear = '0000' then
            Error(IncorrectFiscalYearErr);
        if StrLen(ContactTelephone) <> MaxStrLen(ContactTelephone) then
            Error(WrongContactTelephoneFormatErr, MaxStrLen(ContactTelephone));
        if ContactName = '' then
            Error(MissingContactNameErr);
        if ContactTelephone = '' then
            Error(MissingTelephoneNoErr);
        if (DeclarationNum = '') or (DeclarationNum = '0000') then
            Error(MissingDeclarationNoErr);
        if ElectronicCode = '' then
            Error(MissingElectronicCodeErr);
        if ReplaceDeclaration and (PrevDeclareNum = '') then
            Error(MissingPreviousDeclaraionNoErr);
        if GLAccFilterString = '' then
            GLAccFilterString := GetFilterStringFromColumn(ColumnGLAcc, true);

        VATEntryTypeFilter := VATEntry.GetFilter(Type);
        if VATEntryTypeFilter <> '' then
            VATEntryTypeFilter := '&' + VATEntryTypeFilter;

        VATEntryDateFilter := VATEntry.GetFilter("VAT Reporting Date");
        if VATEntryDateFilter <> '' then
            VATEntryDateFilter := '&' + VATEntryDateFilter;

        ServerTempFileName := RBMgt.ServerTempFileName('txt');

        CalcDaysinMonth();
        PeriodText := GetMonthText();
        if GPPGFilterString = '' then
            GPPGFilterString := GetFilterStringFromColumn(ColumnGPPG, false);
        CompanyVATRegNo := Format(CompanyInfo."VAT Registration No.");
        while StrLen(CompanyVATRegNo) < 9 do
            CompanyVATRegNo := '0' + CompanyVATRegNo;

        CalcTotals();
        TotalBaseAmtText := FormatTextAmt(TotalBaseAmount, true);
        TotalVATAmtText := FormatTextAmt(TotalVATAmount, true);
        TotalInvAmtText := FormatTextAmt(TotalInvoiceAmount, true);
        if (TotalBaseAmount <> 0) or
           (TotalVATAmount <> 0) or
           (TotalInvoiceAmount <> 0) or
           (NoofRecords <> 0) or
           CheckCashCollectables()
        then begin
            Clear(OutFile);
            OutFile.TextMode := true;
            OutFile.WriteMode := true;
            OutFile.Create(ServerTempFileName);
            OutFile.CreateOutStream(Outstr);
        end else
            Error(NoRecordsFoundErr);

        CustomerCashBuffer.Reset();
        CustomerCashBuffer.DeleteAll();
        FileHeaderCreated := false;
    end;

    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        Customer: Record Customer;
        CompanyInfo: Record "Company Information";
        VATBuffer: Record "Sales/Purch. Book VAT Buffer" temporary;
        VATBuffer2: Record "Sales/Purch. Book VAT Buffer";
        GLSetup: Record "General Ledger Setup";
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        PurchInvHeader: Record "Purch. Inv. Header";
        Vendor: Record Vendor;
        VATEntryTemporary: Record "VAT Entry" temporary;
        TempDeclarationLines: Record "340 Declaration Line" temporary;
        TempVATEntry: Record "VAT Entry" temporary;
        TempDetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry" temporary;
        TempGLEntryVATEntryLink: Record "G/L Entry - VAT Entry Link" temporary;
        FileManagement: Codeunit "File Management";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        Outstr: OutStream;
        OutFile: File;
        ESReport340Tok: Label 'ES Create Report 340', Locked = true;
        DeclarationNum: Text[4];
        FileName: Text;
        ContactName: Text[30];
        BookTypeCode: Text[1];
        OperationCode: Text[1];
        ColumnGPPG: Text[1024];
        TotalNoofRecords: Text[9];
        GPPGFilterString: Text[1024];
        PrevDeclareNumText: Text[13];
        CorrInvoiceText: Text[40];
        TotalBaseAmtText: Text[18];
        TotalVATAmtText: Text[18];
        TotalInvAmtText: Text[18];
        VendorDocumentNo: Text[40];
        PeriodText: Text[2];
        CompanyVATRegNo: Text[9];
        NoofRegistersText: Text[2];
        FiscalYearText: Text[4];
        OperationDateText: Text[8];
        ResidentIDText: Text[1];
        VATNoPermanentResidentCountry: Text[20];
        ColumnGLAcc: Text[1024];
        GLAccFilterString: Text[250];
        CountryCode: Code[10];
        ServerTempFileName: Text[1024];
        FiscalYear: Code[4];
        ContactTelephone: Code[9];
        PrevDeclareNum: Code[13];
        ElectronicCode: Code[16];
        IncorrectFiscalYearErr: Label 'Incorrect Fiscal Year.';
        NumFiscalYear: Integer;
        Counter: Integer;
        TotalBaseAmount: Decimal;
        TotalInvoiceAmount: Decimal;
        TotalVATAmount: Decimal;
        DeclarationMediaType: Option Telematic,"CD-R";
        Month: Option;
        VATDeductAmt: Decimal;
        ReplaceDeclaration: Boolean;
        Fin: Boolean;
        FromDate: Date;
        ToDate: Date;
        FileExportedMsg: Label '340 Declaration has been exported successfully under %1.';
        NoofRecords: Integer;
        VATEntryTypeFilter: Text;
        VATEntryDateFilter: Text;
        IntegerCounter: Integer;
        MinPaymentAmount: Decimal;
        NoOfAccounts: Integer;
        FilterArray: array[50] of Text[250];
        FileHeaderCreated: Boolean;
        PrevDeclarationNumEnable: Boolean;
        FileFilterTxt: Label 'Text files (*.txt)|*.txt|All files (*.*)|*.*';
        FileNameTxt: Label 'Declaration 340 year %1 month %2.txt', Comment = '%1=declaration year,%2=declaration month';
        MissingContactNameErr: Label 'Contact Name must be entered.';
        MissingDeclarationNoErr: Label 'Declaration Number must be entered.';
        MissingElectronicCodeErr: Label 'Electronic Code must be entered.';
        MissingPreviousDeclaraionNoErr: Label 'Please specify the Previous Declaration No. if this is a replacement declaration.';
        MissingVATRegistrationNoErr: Label 'Please specify the VAT Registration No. of your Company in the Company Information window.';
        NoRecordsFoundErr: Label 'No records were found to be included in the declaration. The process has been aborted. No file will be created.';
        WrongContactTelephoneFormatErr: Label 'Contact Telephone must be %1 digits without spaces or special characters.', Comment = '%1=number of digits';
        WrongElectronicCodeErr: Label 'Electronic Code must be %1 digits without spaces or special characters.', Comment = '%1=number of digits';
        WrongFiscalYearFormatErr: Label 'Fiscal Year must be %1 digits without spaces or special characters.', Comment = '%1=number of digits';
        WrongPreviousDeclarationNoErr: Label 'Previous Declaration Number must be %1 digits without spaces or special characters.', Comment = '%1=number of digits';
        MissingTelephoneNoErr: Label 'Contact Telephone must be entered.';

    local procedure CalcDaysinMonth()
    begin
        if not Evaluate(NumFiscalYear, FiscalYear) then
            Error(IncorrectFiscalYearErr);

        FromDate := DMY2Date(1, Month, NumFiscalYear);
        ToDate := CalcDate('<CM>', FromDate);
    end;

    local procedure CheckVATType(VATEntryRec: Record "VAT Entry"): Boolean
    var
        VATEntries: Record "VAT Entry";
        PrevVATEntry: Record "VAT Entry";
    begin
        VATEntries.Reset();
        VATEntries.SetCurrentKey("Document No.");
        VATEntries.SetRange("Document No.", VATEntryRec."Document No.");
        VATEntries.SetRange("Document Type", VATEntryRec."Document Type");
        VATEntries.SetRange(Type, VATEntryRec.Type);
        if VATEntries.Find('-') then
            repeat
                if (VATEntries.Amount <> 0) or (VATEntries."Unrealized Amount" <> 0) then begin
                    if ((VATEntries."VAT %" <> PrevVATEntry."VAT %") or (VATEntries."EC %" <> PrevVATEntry."EC %")) and
                       (PrevVATEntry."Entry No." <> 0)
                    then begin
                        if VATEntryRec."Unrealized VAT Entry No." <> 0 then
                            exit(CheckVATOnUnrealVATEntries(VATEntryRec));
                        exit(true);
                    end;
                    PrevVATEntry := VATEntries;
                end;
            until VATEntries.Next() = 0;
    end;

    local procedure CheckVATOnUnrealVATEntries(VATEntryRec: Record "VAT Entry"): Boolean
    var
        UnrealVATEntry: Record "VAT Entry";
    begin
        UnrealVATEntry.Get(VATEntryRec."Unrealized VAT Entry No.");
        UnrealVATEntry.SetCurrentKey("Transaction No.");
        UnrealVATEntry.SetRange("Transaction No.", UnrealVATEntry."Transaction No.");
        if UnrealVATEntry.FindSet() then
            repeat
                if (UnrealVATEntry."VAT %" <> VATEntryRec."VAT %") or
                   (UnrealVATEntry."EC %" <> VATEntryRec."EC %")
                then
                    exit(true);
            until UnrealVATEntry.Next() = 0;
        exit(false);
    end;

    local procedure CreateFileHeader()
    var
        DeclarationMT: Text[1];
        ReplacementText: Text[1];
        DeclareNumText: Text[13];
        Txt1: Text[500];
    begin
        FileHeaderCreated := true;
        case DeclarationMediaType of
            DeclarationMediaType::Telematic:
                DeclarationMT := 'T';
            DeclarationMediaType::"CD-R":
                DeclarationMT := 'C';
        end;

        if ReplaceDeclaration then begin
            ReplacementText := 'S';
            PrevDeclareNumText := Format(PrevDeclareNum);
        end else begin
            ReplacementText := ' ';
            PrevDeclareNumText := '0000000000000';
        end;

        TotalNoofRecords := Format(NoofRecords);
        while StrLen(TotalNoofRecords) < MaxStrLen(TotalNoofRecords) do
            TotalNoofRecords := '0' + TotalNoofRecords;
        DeclareNumText := '340' + FiscalYear + PeriodText + DeclarationNum;

        Txt1 :=
          '1' + '340' + FiscalYear + CompanyVATRegNo +
          PadStr(FormatTextName(CompanyInfo.Name), 40, ' ') +
          DeclarationMT + ConvertStr(Format(ContactTelephone, 9), ' ', '0') +
          PadStr(FormatTextName(ContactName), 40, ' ') +
          DeclareNumText + PadStr('', 1, ' ') + ReplacementText + PrevDeclareNumText + PeriodText +
          TotalNoofRecords + TotalBaseAmtText + TotalVATAmtText + TotalInvAmtText +
          PadStr('', 199, ' ') + ElectronicCode;
        Txt1 := PadStr(Txt1, 500, ' ');

        Outstr.WriteText(Txt1);
    end;

    local procedure GetMonthText(): Text[2]
    var
        MonthNo: Integer;
    begin
        MonthNo := Month;
        if MonthNo < 10 then
            exit('0' + Format(MonthNo));
        exit(Format(MonthNo));
    end;

    [Scope('OnPrem')]
    procedure FormatTextAmt(Amt: Decimal; Total: Boolean): Text[18]
    var
        Sign: Text[1];
        MaxLength: Integer;
    begin
        if Amt < 0 then
            Sign := 'N'
        else
            Sign := ' ';
        if Total then
            MaxLength := 17
        else
            MaxLength := 13;

        exit(Sign + FormatNumber(Round(Amt * 100, 1), MaxLength));
    end;

    local procedure FormatDate(PostingDate: Date): Text[8]
    begin
        if PostingDate <> 0D then
            exit(Format(PostingDate, 8, '<Year4><Month,2><Day,2>'));
        exit('00000000');
    end;

    local procedure FormatNumber(Number: Integer; Length: Integer): Text[30]
    begin
        exit(ConvertStr(Format(Number, Length, '<Integer>'), ' ', '0'));
    end;

    local procedure FormatTextName(NameString: Text[100]) Result: Text[100]
    var
        TempString: Text[100];
        TempString1: Text[1];
    begin
        Clear(Result);
        TempString := ConvertStr(UpperCase(NameString), 'ÁÀÉÈÍÌÓÒÚÙÑÜÇ()"&´ÄËÏÖ¹Ü$''ºª', 'AAEEIIOOUUÐUÃ     AEIOOU    ');
        if StrLen(TempString) > 0 then
            repeat
                TempString1 := CopyStr(TempString, 1, 1);
                if TempString1 in ['A' .. 'Z', '0' .. '9'] then
                    Result := Result + TempString1
                else
                    Result := Result + ' ';
                TempString := DelStr(TempString, 1, 1);
            until StrLen(TempString) = 0;

        exit(Result);
    end;

    local procedure FindEUCountryRegionCode(CountryCode: Code[10]): Code[10]
    var
        Country: Record "Country/Region";
    begin
        if Country.Get(CountryCode) then
            exit(Country."EU Country/Region Code");

        exit('');
    end;

    local procedure GetNoOfRegsText(): Text[2]
    var
        NoOfRegs: Integer;
    begin
        if OperationCode in ['C', '2'] then
            NoOfRegs := VATBuffer.Count
        else
            NoOfRegs := 1;
        exit(FormatNumber(NoOfRegs, 2));
    end;

    local procedure FindPmtOrderBillGrBankAcc(Type: Enum "General Posting Type"; DocumentNo: Code[40]): Code[20]
    var
        ClosedBillGroup: Record "Closed Bill Group";
        ClosedPmtOrder: Record "Closed Payment Order";
        PostedBillGroup: Record "Posted Bill Group";
        PostedPmtOrder: Record "Posted Payment Order";
    begin
        case Type of
            VATEntry.Type::Sale:
                begin
                    if StrLen(DocumentNo) <= MaxStrLen(PostedBillGroup."No.") then
                        if PostedBillGroup.Get(DocumentNo) then
                            exit(PostedBillGroup."Bank Account No.");
                    if StrLen(DocumentNo) <= MaxStrLen(ClosedBillGroup."No.") then
                        if ClosedBillGroup.Get(DocumentNo) then
                            exit(ClosedBillGroup."Bank Account No.");
                end;
            VATEntry.Type::Purchase:
                begin
                    if StrLen(DocumentNo) <= MaxStrLen(PostedPmtOrder."No.") then
                        if PostedPmtOrder.Get(DocumentNo) then
                            exit(PostedPmtOrder."Bank Account No.");
                    if StrLen(DocumentNo) <= MaxStrLen(ClosedPmtOrder."No.") then
                        if ClosedPmtOrder.Get(DocumentNo) then
                            exit(ClosedPmtOrder."Bank Account No.");
                end;
        end;
        exit('');
    end;

    local procedure RecordTypeSale()
    var
        UnrealizedVATEntry: Record "VAT Entry";
        SalesInvHeader: Record "Sales Invoice Header";
        CustVATNumber: Text[9];
        DocumentDate: Date;
        OperationDate: Date;
        AppliedToDocumentNo: Code[35];
        UnrealizedVATEntryNo: Integer;
    begin
        VATNoPermanentResidentCountry := '';
        OperationDateText := '';
        CountryCode := '';
        ResidentIDText := '';
        CorrInvoiceText := '';
        DocumentDate := VATEntry."Document Date";

        NoofRegistersText := GetNoOfRegsText();

        CountryCode := Customer."Country/Region Code";
        CustVATNumber := GetVATNumber(Customer."Country/Region Code", Customer."VAT Registration No.");
        InitCountryResidentInfo(Customer."Country/Region Code", Customer."VAT Registration No.");
        case VATEntry."Document Type" of 
            VATEntry."Document Type"::"Credit Memo":
                begin
                    OperationDateText := FormatDate(VATEntry."Posting Date");
                    if SalesCrMemoHeader.Get(VATEntry."Document No.") then begin
                        if SalesCrMemoHeader."Corrected Invoice No." <> '' then begin
                            if SalesInvHeader.Get(SalesCrMemoHeader."Corrected Invoice No.") then begin
                                OperationDateText := FormatDate(SalesInvHeader."Posting Date");
                                CorrInvoiceText := Format(SalesCrMemoHeader."Corrected Invoice No.");
                            end;
                        end else begin
                            OperationDate := GetSalesReturnReciptDate(VATEntry."Document No.");
                            if OperationDate <> 0D then
                                OperationDateText := FormatDate(OperationDate)
                            else
                                OperationDateText := FormatDate(VATEntry."Posting Date");
                            CorrInvoiceText := '';
                        end;
                    end else
                        OnRecordTypeSaleOnGetOperationDate(VATEntry, OperationDateText, CorrInvoiceText);
                end;
            VATEntry."Document Type"::Invoice:
                begin
                    OperationDate := GetSalesShipmentDate(VATEntry."Document No.");
                    if OperationDate <> 0D then
                        OperationDateText := FormatDate(OperationDate)
                    else
                        OperationDateText := FormatDate(VATEntry."Posting Date");
                end
            else
                OperationDateText := FormatDate(VATEntry."Posting Date");
        end;

        AppliedToDocumentNo := VATEntry."Document No.";
        UnrealizedVATEntryNo := 0;
        if VATEntry."Document Type" in [VATEntry."Document Type"::Payment, VATEntry."Document Type"::Refund] then begin
            UnrealizedVATEntryNo := VATEntry."Unrealized VAT Entry No.";
            DocumentDate := VATEntry."Posting Date";
            if (UnrealizedVATEntryNo <> 0) and
               (FindPmtOrderBillGrBankAcc(VATEntry.Type, VATEntry."Document No.") = '')
            then begin
                UnrealizedVATEntry.Get(UnrealizedVATEntryNo);
                AppliedToDocumentNo := FindAppliedToDocumentNo(UnrealizedVATEntry);
                OperationDateText := FormatDate(UnrealizedVATEntry."Posting Date");
                DocumentDate := UnrealizedVATEntry."Document Date";
            end;
        end;

        CreateTempDeclarationLines(PadStr(CustVATNumber, 9, ' '), Customer."No.", Customer.Name, DocumentDate,
          AppliedToDocumentNo, Format(VATEntry."Document Type"),
          '00000001', PadStr(CorrInvoiceText, 40, ' '),
          UnrealizedVATEntryNo, VATEntry."Transaction No.", VATEntry."Posting Date", VATEntry."VAT Cash Regime");
    end;

    local procedure RecordTypePurchase(VATEntryRec: Record "VAT Entry")
    var
        UnrealizedVATEntry: Record "VAT Entry";
        PurchSetup: Record "Purchases & Payables Setup";
        VendVATNumber: Text[9];
        DocumentDate: Date;
        OperationDate: Date;
        UnrealizedVATEntryNo: Integer;
    begin
        OperationDateText := '';
        CountryCode := '';
        ResidentIDText := '';
        CorrInvoiceText := '';
        VATNoPermanentResidentCountry := '';
        DocumentDate := VATEntryRec."Document Date";

        NoofRegistersText := GetNoOfRegsText();

        VendVATNumber := GetVATNumber(Vendor."Country/Region Code", Vendor."VAT Registration No.");

        CountryCode := PadStr(Vendor."Country/Region Code", 2, ' ');
        InitCountryResidentInfo(Vendor."Country/Region Code", Vendor."VAT Registration No.");
        case VATEntryRec."Document Type" of
            VATEntryRec."Document Type"::"Credit Memo":
                if PurchCrMemoHeader."Corrected Invoice No." <> '' then begin
                    if PurchInvHeader.Get(PurchCrMemoHeader."Corrected Invoice No.") then begin
                        OperationDateText := FormatDate(PurchInvHeader."Posting Date");
                        CorrInvoiceText := Format(PurchCrMemoHeader."Corrected Invoice No.");
                    end else
                        OperationDateText := FormatDate(VATEntryRec."Posting Date");
                end else begin
                    OperationDate := GetPurchReturnShipmentDate(VATEntryRec."Document No.");
                    if OperationDate <> 0D then
                        OperationDateText := FormatDate(OperationDate)
                    else
                        OperationDateText := FormatDate(VATEntryRec."Posting Date");
                    CorrInvoiceText := '';
                end;
            VATEntryRec."Document Type"::Invoice:
                if not PurchSetup."Receipt on Invoice" then begin
                    OperationDate := GetShipmentDate(VATEntryRec."Document No.");
                    if OperationDate <> 0D then
                        OperationDateText := FormatDate(OperationDate)
                    else
                        OperationDateText := FormatDate(VATEntryRec."Posting Date")
                end else
                    OperationDateText := FormatDate(VATEntryRec."Posting Date");
            else
                OperationDateText := FormatDate(VATEntryRec."Posting Date");
        end;

        VATBuffer2.Base := VATBuffer.Base;
        VATBuffer2.Amount := VATBuffer.Amount;

        if VATEntryRec."Document Type" in [VATEntryRec."Document Type"::Payment, VATEntryRec."Document Type"::Refund] then begin
            UnrealizedVATEntryNo := VATEntryTemporary."Unrealized VAT Entry No.";
            DocumentDate := VATEntryTemporary."Posting Date";
            if UnrealizedVATEntryNo <> 0 then begin
                UnrealizedVATEntry.Get(UnrealizedVATEntryNo);
                OperationDateText := FormatDate(UnrealizedVATEntry."Posting Date");
                DocumentDate := UnrealizedVATEntry."Document Date";
                if FindPmtOrderBillGrBankAcc(VATEntry.Type, VATEntry."Document No.") = '' then
                    VendorDocumentNo := UnrealizedVATEntry."External Document No.";
                if not VATEntryRec."VAT Cash Regime" then begin
                    VATBuffer2.Base := VATEntryTemporary.Base;
                    VATBuffer2.Amount := VATEntryTemporary.Amount;
                end;
            end;
        end else
            UnrealizedVATEntryNo := 0;

        if Counter = 1 then begin
            VATBuffer2."EC %" := 0;
            CreateTempDeclarationLines(PadStr(VendVATNumber, 9, ' '), Vendor."No.", Vendor.Name, DocumentDate,
              VendorDocumentNo, Format(VATEntryRec."Document Type"),
              '00000001', PadStr(CorrInvoiceText, 40, ' '),
              UnrealizedVATEntryNo, VATEntryRec."Transaction No.", VATEntryRec."Posting Date", VATEntryRec."VAT Cash Regime");
        end else
            CreateTempDeclarationLines(PadStr(VendVATNumber, 9, ' '), Vendor."No.", Vendor.Name, DocumentDate,
              VendorDocumentNo, Format(VATEntryRec."Document Type"),
              '000000000000000001', FormatTextAmt(VATDeductAmt, false) + PadStr('', 16, ' '),
              UnrealizedVATEntryNo, VATEntryRec."Transaction No.", VATEntryRec."Posting Date", VATEntryRec."VAT Cash Regime");
    end;

    local procedure CheckDeductibleVAT(VATEntryRec: Record "VAT Entry"): Decimal
    var
        VATEntries: Record "VAT Entry";
        Amt: Decimal;
        AddVATAmount: Boolean;
    begin
        if VATEntryRec.Amount <> 0 then begin
            VATEntries.SetCurrentKey("Document No.", "Document Type", "Gen. Prod. Posting Group", "VAT Prod. Posting Group", Type);
            VATEntries.SetRange("Document Type", VATEntryRec."Document Type");
            VATEntries.SetRange("Document No.", VATEntryRec."Document No.");
            VATEntries.SetRange(Type, VATEntryRec.Type);
            VATEntries.SetFilter("Gen. Prod. Posting Group", GPPGFilterString);
            if VATEntryRec."Unrealized VAT Entry No." <> 0 then
                VATEntries.SetFilter("Unrealized VAT Entry No.", '<>%1', 0);
            if VATEntries.FindSet() then
                repeat
                    AddVATAmount := (VATEntries."VAT %" = VATEntryRec."VAT %") and (VATEntries."EC %" = VATEntryRec."EC %");
                    if AddVATAmount and (VATEntryRec."Unrealized VAT Entry No." <> 0) then
                        AddVATAmount := TempGLEntryVATEntryLink.Get(VATEntryRec."Entry No.", VATEntries."Unrealized VAT Entry No.");

                    if AddVATAmount then
                        Amt += VATEntries.Amount;
                until VATEntries.Next() = 0;
        end;
        exit(Amt);
    end;

    local procedure GetFilterStringFromColumn(Columns: Text[1024]; IsGLAccount: Boolean) FilterString: Text[250]
    var
        ColumnCode: Text[1024];
        Position: Integer;
        AndOrFilterChar: Text[1];
        EmptyNotEqualFilterChar: Text[2];
    begin
        ColumnCode := Columns;
        FilterString := '';
        if IsGLAccount then begin
            EmptyNotEqualFilterChar := '';
            AndOrFilterChar := '|';
        end else begin
            EmptyNotEqualFilterChar := '<>';
            AndOrFilterChar := '&';
        end;
        repeat
            Position := StrPos(ColumnCode, ';');
            if ColumnCode <> '' then begin
                if Position <> 0 then begin
                    FilterString := FilterString + EmptyNotEqualFilterChar + CopyStr(ColumnCode, 1, Position - 1);
                    ColumnCode := CopyStr(ColumnCode, Position + 1);
                end else begin
                    FilterString := FilterString + EmptyNotEqualFilterChar + CopyStr(ColumnCode, 1);
                    ColumnCode := '';
                end;
                if ColumnCode <> '' then
                    FilterString := FilterString + AndOrFilterChar;
            end;
        until ColumnCode = '';
    end;

    local procedure GetOperationCode(VATEntryRec: Record "VAT Entry"): Text[1]
    var
        GenProdPostingGroup: Record "Gen. Product Posting Group";
    begin
        // Corrective documents
        if VATEntryRec."Document Type" in [VATEntryRec."Document Type"::"Credit Memo", VATEntryRec."Document Type"::Refund] then begin
            if VATEntryRec."VAT Cash Regime" then
                exit('3');
            exit('D');
        end;

        // Documents with more than one VAT % in the lines
        if CheckVATType(VATEntryRec) then begin
            if VATEntryRec."VAT Cash Regime" then
                exit('2');
            exit('C');
        end;

        // All other VAT Cash Regime documents
        if VATEntryRec."VAT Cash Regime" then
            exit('Z');

        if ((VATEntryRec.Type in [VATEntryRec.Type::Purchase, VATEntryRec.Type::Sale]) and
            (VATEntryRec."VAT Calculation Type" = VATEntryRec."VAT Calculation Type"::"Reverse Charge VAT") and
            VATEntryRec."EU Service")
        then
            exit('I');

        if (VATEntryRec."Unrealized Base" = 0) and (VATEntryRec."Unrealized Amount" = 0) then
            if GenProdPostingGroup.Get(VATEntryRec."Gen. Prod. Posting Group") then
                exit(GenProdPostingGroup."Operation Code");

        exit(' ');
    end;

    local procedure GetShipmentDate(DocumentNo: Code[20]) OperationDate: Date
    var
        PurchInvLine: Record "Purch. Inv. Line";
        ValueEntry: Record "Value Entry";
        ItemLedgEntry: Record "Item Ledger Entry";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        CapacityLedgEntry: Record "Capacity Ledger Entry";
    begin
        PurchInvLine.Reset();
        PurchInvLine.SetRange("Document No.", DocumentNo);
        PurchInvLine.SetFilter(Type, '<>%1', PurchInvLine.Type::" ");
        if PurchInvLine.Find('-') then
            repeat
                ValueEntry.Reset();
                ValueEntry.SetCurrentKey("Document No.");
                ValueEntry.SetRange("Document No.", PurchInvLine."Document No.");
                ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Purchase Invoice");
                ValueEntry.SetRange("Document Line No.", PurchInvLine."Line No.");
                ValueEntry.SetFilter("Invoiced Quantity", '<>0');
                if ValueEntry.Find('-') then
                    repeat
                        if ValueEntry."Item Ledger Entry No." = 0 then begin
                            CapacityLedgEntry.Get(ValueEntry."Capacity Ledger Entry No.");
                            exit(CapacityLedgEntry."Posting Date");
                        end;
                        ItemLedgEntry.Get(ValueEntry."Item Ledger Entry No.");
                        if ItemLedgEntry."Document Type" = ItemLedgEntry."Document Type"::"Purchase Receipt" then
                            if PurchRcptLine.Get(ItemLedgEntry."Document No.", ItemLedgEntry."Document Line No.") then
                                if PurchRcptHeader.Get(PurchRcptLine."Document No.") then
                                    if (OperationDate = 0D) or (ItemLedgEntry."Posting Date" < OperationDate) then
                                        OperationDate := ItemLedgEntry."Posting Date";
                    until ValueEntry.Next() = 0;
            until PurchInvLine.Next() = 0;
    end;

    local procedure CalcTotals()
    var
        VATEntry6: Record "VAT Entry";
        VATEntry7: Record "VAT Entry";
        TempSalesPurchBookVATBuffer: Record "Sales/Purch. Book VAT Buffer" temporary;
    begin
        VATEntryTemporary.DeleteAll();
        VATEntry6.Reset();
        VATEntry6.SetCurrentKey("Document Type", "Posting Date", "Document No.");
        VATEntry6.CopyFilters(VATEntry);
        VATEntryTemporary.SetCurrentKey("Document No.");
        VATEntry6.SetFilter(Type, '%1|%2', VATEntry6.Type::Sale, VATEntry6.Type::Purchase);
        if VATEntry.GetFilter("Document Type") <> '' then
            VATEntry6.SetFilter("Document Type", VATEntry.GetFilter("Document Type"))
        else
            VATEntry6.SetFilter("Document Type", '%1|%2|%3|%4', VATEntry6."Document Type"::Invoice, VATEntry6."Document Type"::"Credit Memo",
              VATEntry6."Document Type"::Payment, VATEntry6."Document Type"::Refund);
        VATEntry6.SetFilter("VAT Reporting Date", '%1..%2' + VATEntryDateFilter, FromDate, ToDate);
        if VATEntry.GetFilter("Document No.") <> '' then
            VATEntry6.SetFilter("Document No.", VATEntry.GetFilter("Document No."));
        if VATEntry6.FindSet() then
            repeat
                if CheckIncludeVATEntry(VATEntry6) then begin
                    VATEntryTemporary.SetRange("Document No.", VATEntry6."Document No.");
                    VATEntryTemporary.SetRange("Document Type", VATEntry6."Document Type");
                    VATEntryTemporary.SetRange(Type, VATEntry6.Type);
                    VATEntryTemporary.SetRange("Transaction No.", VATEntry6."Transaction No.");
                    if not VATEntryTemporary.FindFirst() then begin
                        VATEntryTemporary.Init();
                        VATEntryTemporary.Copy(VATEntry6);
                        VATEntryTemporary.Insert();
                        VATEntryTemporary.Next();
                    end;
                end;
            until VATEntry6.Next() = 0;

        VATEntryTemporary.Reset();
        if VATEntryTypeFilter <> '' then
            VATEntryTemporary.SetFilter(Type, VATEntry.GetFilter(Type));
        if VATEntryTemporary.Find('-') then
            repeat
                VATEntry7.Reset();
                VATEntry7.SetCurrentKey("Document No.");
                VATEntry7.SetRange("Document No.", VATEntryTemporary."Document No.");
                VATEntry7.SetRange("Document Type", VATEntryTemporary."Document Type");
                VATEntry7.SetRange(Type, VATEntryTemporary.Type);
                VATEntry7.SetRange("Transaction No.", VATEntryTemporary."Transaction No.");
                if VATEntry7.Find('-') then
                    VATBuffer.DeleteAll();
                TempSalesPurchBookVATBuffer.DeleteAll();
                repeat
                    VATBuffer."VAT %" := VATEntry7."VAT %";
                    VATBuffer."EC %" := VATEntry7."EC %";
                    if VATEntry7.Type = VATEntry7.Type::Sale then begin
                        VATEntry7.Base := -VATEntry7.Base;
                        VATEntry7.Amount := -VATEntry7.Amount;
                        VATEntry7."Unrealized Base" := -VATEntry7."Unrealized Base";
                        VATEntry7."Unrealized Amount" := -VATEntry7."Unrealized Amount";
                    end;
                    if VATBuffer.Find() then begin
                        UpdateVATBuffer(VATBuffer, VATEntry7);
                        VATBuffer.Modify();
                    end else begin
                        VATBuffer.Init();
                        UpdateVATBuffer(VATBuffer, VATEntry7);
                        VATBuffer.Insert();
                    end;
                    TempSalesPurchBookVATBuffer := VATBuffer;
                    if TempSalesPurchBookVATBuffer.Find() then begin
                        UpdateUnrealVATBuffer(TempSalesPurchBookVATBuffer, VATEntry7);
                        TempSalesPurchBookVATBuffer.Modify();
                    end else begin
                        TempSalesPurchBookVATBuffer.Init();
                        UpdateUnrealVATBuffer(TempSalesPurchBookVATBuffer, VATEntry7);
                        TempSalesPurchBookVATBuffer.Insert();
                    end;
                    if IsEmptyVATBuffer(VATBuffer) and IsEmptyVATBuffer(TempSalesPurchBookVATBuffer) then begin
                        VATBuffer.Delete();
                        TempSalesPurchBookVATBuffer.Delete();
                    end;
                until VATEntry7.Next() = 0;
                if not VATBuffer.IsEmpty() then
                    NoofRecords += VATBuffer.Count();
                if IsVATEntryIncludedInTotals(VATEntryTemporary) then begin
                    UpdateTotals(VATBuffer, TotalBaseAmount, TotalVATAmount, TotalInvoiceAmount);
                    UpdateTotals(TempSalesPurchBookVATBuffer, TotalBaseAmount, TotalVATAmount, TotalInvoiceAmount);
                end;
            until VATEntryTemporary.Next() = 0;
    end;

    local procedure IsEmptyVATBuffer(SalesPurchBookVATBuffer: Record "Sales/Purch. Book VAT Buffer"): Boolean
    begin
        exit((SalesPurchBookVATBuffer.Base = 0) and (SalesPurchBookVATBuffer.Amount = 0) and (SalesPurchBookVATBuffer."EC Amount" = 0));
    end;

    local procedure UpdateVATBuffer(var SalesPurchBookVATBuffer: Record "Sales/Purch. Book VAT Buffer"; AddedVATEntry: Record "VAT Entry")
    begin
        SalesPurchBookVATBuffer.Base += AddedVATEntry.Base;
        SalesPurchBookVATBuffer.Amount += AddedVATEntry.Amount;
        if ((AddedVATEntry.Type = AddedVATEntry.Type::Sale) or (AddedVATEntry.Type = AddedVATEntry.Type::Purchase)) and
           (AddedVATEntry."EC %" <> 0)
        then
            SalesPurchBookVATBuffer."EC Amount" += AddedVATEntry.Base * AddedVATEntry."EC %" / 100;
    end;

    local procedure UpdateUnrealVATBuffer(var SalesPurchBookVATBuffer: Record "Sales/Purch. Book VAT Buffer"; AddedVATEntry: Record "VAT Entry")
    begin
        SalesPurchBookVATBuffer.Base += AddedVATEntry."Unrealized Base";
        SalesPurchBookVATBuffer.Amount += AddedVATEntry."Unrealized Amount";
        if (AddedVATEntry.Type = AddedVATEntry.Type::Sale) and (AddedVATEntry."EC %" <> 0) then
            SalesPurchBookVATBuffer."EC Amount" += Round(AddedVATEntry."Unrealized Base" * AddedVATEntry."EC %" / 100);
    end;

    local procedure UpdateTotals(var SalesPurchBookVATBuffer: Record "Sales/Purch. Book VAT Buffer"; var TotalBaseAmount: Decimal; var TotalVATAmount: Decimal; var TotalInvoiceAmount: Decimal)
    begin
        if SalesPurchBookVATBuffer.FindSet() then
            repeat
                TotalBaseAmount += SalesPurchBookVATBuffer.Base;
                TotalVATAmount += SalesPurchBookVATBuffer.Amount - Round(SalesPurchBookVATBuffer."EC Amount");
                TotalInvoiceAmount += SalesPurchBookVATBuffer.Base + SalesPurchBookVATBuffer.Amount;
            until SalesPurchBookVATBuffer.Next() = 0;
    end;

    local procedure IsVATEntryIncludedInTotals(var VATEntry: Record "VAT Entry"): Boolean
    begin
        exit(
              not (VATEntry."VAT Cash Regime" and
                   (VATEntry."Document Type" in [VATEntry."Document Type"::Payment, VATEntry."Document Type"::Refund, VATEntry."Document Type"::Bill])));
    end;

    local procedure GetSalesShipmentDate(DocumentNo: Code[20]) OperationDate: Date
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesInvLine: Record "Sales Invoice Line";
        ValueEntry: Record "Value Entry";
        ItemLedgEntry: Record "Item Ledger Entry";
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        SalesInvLine.Reset();
        SalesInvLine.SetRange("Document No.", DocumentNo);
        SalesInvLine.SetFilter(Type, '<>%1', SalesInvLine.Type::" ");
        if SalesInvLine.Find('-') then
            repeat
                ValueEntry.Reset();
                ValueEntry.SetCurrentKey("Document No.");
                ValueEntry.SetRange("Document No.", SalesInvLine."Document No.");
                ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Sales Invoice");
                ValueEntry.SetRange("Document Line No.", SalesInvLine."Line No.");
                ValueEntry.SetFilter("Invoiced Quantity", '<>0');
                if ValueEntry.Find('-') then
                    repeat
                        ItemLedgEntry.Get(ValueEntry."Item Ledger Entry No.");
                        if ItemLedgEntry."Document Type" = ItemLedgEntry."Document Type"::"Sales Shipment" then
                            if SalesShipmentLine.Get(ItemLedgEntry."Document No.", ItemLedgEntry."Document Line No.") then
                                if SalesShipmentHeader.Get(SalesShipmentLine."Document No.") then
                                    if (OperationDate = 0D) or (ItemLedgEntry."Posting Date" < OperationDate) then
                                        OperationDate := ItemLedgEntry."Posting Date";
                    until ValueEntry.Next() = 0;
            until SalesInvLine.Next() = 0;
    end;

    local procedure GetSalesReturnReciptDate(DocumentNo: Code[20]) OperationDate: Date
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        ValueEntry: Record "Value Entry";
        ItemLedgEntry: Record "Item Ledger Entry";
        SalesReturnRcptLine: Record "Return Receipt Line";
        SalesReturnRcptHeader: Record "Return Receipt Header";
    begin
        SalesCrMemoLine.Reset();
        SalesCrMemoLine.SetRange("Document No.", DocumentNo);
        SalesCrMemoLine.SetFilter(Type, '<>%1', SalesCrMemoLine.Type::" ");
        if SalesCrMemoLine.Find('-') then
            repeat
                ValueEntry.Reset();
                ValueEntry.SetCurrentKey("Document No.");
                ValueEntry.SetRange("Document No.", SalesCrMemoLine."Document No.");
                ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Sales Credit Memo");
                ValueEntry.SetRange("Document Line No.", SalesCrMemoLine."Line No.");
                ValueEntry.SetFilter("Invoiced Quantity", '<>0');
                if ValueEntry.Find('-') then
                    repeat
                        ItemLedgEntry.Get(ValueEntry."Item Ledger Entry No.");
                        if ItemLedgEntry."Document Type" = ItemLedgEntry."Document Type"::"Sales Return Receipt" then
                            if SalesReturnRcptLine.Get(ItemLedgEntry."Document No.", ItemLedgEntry."Document Line No.") then
                                if SalesReturnRcptHeader.Get(SalesReturnRcptLine."Document No.") then
                                    if (OperationDate = 0D) or (ItemLedgEntry."Posting Date" < OperationDate) then
                                        OperationDate := ItemLedgEntry."Posting Date";
                    until ValueEntry.Next() = 0;
            until SalesCrMemoLine.Next() = 0;
    end;

    local procedure GetPurchReturnShipmentDate(DocumentNo: Code[20]) OperationDate: Date
    var
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        ValueEntry: Record "Value Entry";
        ItemLedgEntry: Record "Item Ledger Entry";
        PurchReturnShipmentLine: Record "Return Shipment Line";
        purchReturnShipmentHeader: Record "Return Shipment Header";
    begin
        PurchCrMemoLine.Reset();
        PurchCrMemoLine.SetRange("Document No.", DocumentNo);
        PurchCrMemoLine.SetFilter(Type, '<>%1', PurchCrMemoLine.Type::" ");
        if PurchCrMemoLine.Find('-') then
            repeat
                ValueEntry.Reset();
                ValueEntry.SetCurrentKey("Document No.");
                ValueEntry.SetRange("Document No.", PurchCrMemoLine."Document No.");
                ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Purchase Credit Memo");
                ValueEntry.SetRange("Document Line No.", PurchCrMemoLine."Line No.");
                ValueEntry.SetFilter("Invoiced Quantity", '<>0');
                if ValueEntry.Find('-') then
                    repeat
                        ItemLedgEntry.Get(ValueEntry."Item Ledger Entry No.");
                        if ItemLedgEntry."Document Type" = ItemLedgEntry."Document Type"::"Purchase Return Shipment" then
                            if PurchReturnShipmentLine.Get(ItemLedgEntry."Document No.", ItemLedgEntry."Document Line No.") then
                                if purchReturnShipmentHeader.Get(PurchReturnShipmentLine."Document No.") then
                                    if (OperationDate = 0D) or (ItemLedgEntry."Posting Date" < OperationDate) then
                                        OperationDate := ItemLedgEntry."Posting Date";
                    until ValueEntry.Next() = 0;
            until PurchCrMemoLine.Next() = 0;
    end;

    local procedure WriteDeclarationLinesToText(var DeclarationLine: Record "340 Declaration Line")
    var
        txt: Text[500];
    begin
        DeclarationLine.Reset();
        if DeclarationLine.FindSet() then
            repeat
                txt := '2340' + DeclarationLine."Fiscal Year" + DeclarationLine."VAT Registration No." + DeclarationLine."VAT Number" + PadStr('', 9, ' ') +
                  PadStr(FormatTextName(DeclarationLine."Customer/Vendor Name"), 40, ' ') + DeclarationLine."Country Code" + DeclarationLine."Resident ID" + DeclarationLine."International VAT No." +
                  DeclarationLine."Book Type Code" + PadStr(DeclarationLine."Operation Code", 1, ' ') + FormatDate(DeclarationLine."Document Date") +
                  DeclarationLine."Operation Date" + FormatNumber(DeclarationLine."VAT %" * 100, 5) + FormatTextAmt(DeclarationLine.Base, false) + FormatTextAmt(DeclarationLine."VAT Amount", false) +
                  FormatTextAmt(DeclarationLine."Amount Including VAT / EC", false) + ' 0000000000000' + PadStr(DeclarationLine."Document No.", 40, ' ') +
                  DeclarationLine."VAT Document No." + DeclarationLine."Buffer Value 18" + DeclarationLine."No. of Registers" + PadStr('', 80, ' ') + DeclarationLine."Buffer Value 40";
                if DeclarationLine.Type = DeclarationLine.Type::Sale then
                    txt += FormatNumber(DeclarationLine."EC %" * 100, 5) + FormatTextAmt(DeclarationLine."EC Amount", false) + GetPropertyLocation(DeclarationLine."Property Location") +
                      PadStr(DeclarationLine."Property Tax Account No.", 25, ' ') + PadStr('0', 15, '0') +
                      PadStr('', 4, '0') + PadStr('0', 15, '0');

                txt := PadStr(txt, 500, ' ');

                AddUnrealizedCollectionInfo(DeclarationLine, txt);

                Outstr.WriteText();
                Outstr.WriteText(txt);
            until DeclarationLine.Next() = 0;
    end;

    local procedure WriteAppliedPaymentsToText()
    var
        CustomerCashBuffer: Record "Customer Cash Buffer";
        Customer: Record Customer;
        DeclarationLine: Record "340 Declaration Line";
        txt: Text[500];
        CashAmtText: Text[15];
    begin
        CustomerCashBuffer.Reset();
        DeclarationLine."Unrealized VAT Entry No." := 0;
        DeclarationLine.Type := DeclarationLine.Type::Sale;

        if CustomerCashBuffer.FindSet() then
            repeat
                if CustomerCashBuffer."Operation Amount" >= MinPaymentAmount then begin
                    if not FileHeaderCreated then
                        CreateFileHeader();
                    CashAmtText := FormatPaymentAmount(CustomerCashBuffer."Operation Amount");
                    Customer.SetRange("VAT Registration No.", CustomerCashBuffer."VAT Registration No.");
                    Customer.FindFirst();
                    InitCountryResidentInfo(Customer."Country/Region Code", Customer."VAT Registration No.");
                    txt := '2340' + FiscalYear + CompanyVATRegNo +
                      PadStr(GetVATNumber(Customer."Country/Region Code", Customer."VAT Registration No."), 9, ' ') +
                      PadStr('', 9, ' ') + PadStr(FormatTextName(Customer.Name), 40, ' ') + PadStr(Customer."Country/Region Code", 2, ' ') +
                      ResidentIDText + VATNoPermanentResidentCountry + 'E' + PadStr('', 1, ' ') + FormatDate(ToDate) +
                      PadStr('', 13, '0') + PadStr('', 1, ' ') + PadStr('', 13, '0') + PadStr('', 1, ' ') + PadStr('', 13, '0') + PadStr('', 1, ' ') +
                      PadStr('', 13, '0') + PadStr('', 1, ' ') + PadStr('', 13, '0') + PadStr('', 58, ' ') + PadStr('', 10, '0') + PadStr('', 120, ' ') +
                      PadStr('', 5, '0') + PadStr('', 1, ' ') + PadStr('', 13, '0') + PadStr('', 1, '0') + PadStr('', 25, ' ') +
                      CashAmtText + CustomerCashBuffer."Operation Year" + PadStr('', 15, '0');
                    txt := PadStr(txt, 500, ' ');

                    AddUnrealizedCollectionInfo(DeclarationLine, txt);

                    Outstr.WriteText();
                    Outstr.WriteText(txt);
                end;
            until CustomerCashBuffer.Next() = 0;
    end;

    local procedure GetPropertyLocation(PropertyLocation: Option): Text[1]
    begin
        exit(Format(PropertyLocation));
    end;

    local procedure CreateTempDeclarationLines(VatNumber: Text[9]; No: Code[20]; Name: Text[100]; DocumentDate: Date; DocumentNo: Text[40]; DocumentType: Text[30]; BufferValue18: Text[18]; BufferValue40: Text[40]; UnrealizedVATEntryNo: Integer; TransactionNo: Integer; PostingDate: Date; VATCashRegime: Boolean)
    begin
        IntegerCounter += 1;
        TempDeclarationLines.Init();
        TempDeclarationLines.Key := IntegerCounter;
        TempDeclarationLines."Fiscal Year" := FiscalYear;
        TempDeclarationLines."VAT Registration No." := CompanyVATRegNo;
        TempDeclarationLines."VAT Number" := PadStr(VatNumber, 9, ' ');
        TempDeclarationLines."Customer/Vendor No." := No;
        TempDeclarationLines."Customer/Vendor Name" := Name;
        TempDeclarationLines."Country Code" := PadStr(CountryCode, 2, ' ');
        TempDeclarationLines."Resident ID" := ResidentIDText;
        TempDeclarationLines."International VAT No." := VATNoPermanentResidentCountry;
        TempDeclarationLines."Book Type Code" := BookTypeCode;
        TempDeclarationLines."Operation Code" := OperationCode;
        TempDeclarationLines."Document Date" := DocumentDate;
        TempDeclarationLines."Operation Date" := OperationDateText;
        TempDeclarationLines."Posting Date" := PostingDate;
        TempDeclarationLines."VAT %" := VATBuffer2."VAT %";
        TempDeclarationLines.Base := VATBuffer2.Base;
        TempDeclarationLines."Document No." := DocumentNo;
        TempDeclarationLines."Document Type" := DocumentType;
        TempDeclarationLines."VAT Document No." := PadStr(VATEntry."Document No.", 18, ' ');
        TempDeclarationLines."Buffer Value 18" := BufferValue18;
        TempDeclarationLines."No. of Registers" := NoofRegistersText;
        TempDeclarationLines."Buffer Value 40" := BufferValue40;
        TempDeclarationLines."EC %" := VATBuffer2."EC %";
        TempDeclarationLines."EC Amount" := VATBuffer2."EC Amount";
        TempDeclarationLines."VAT Amount" := VATBuffer2.Amount - VATBuffer."EC Amount";
        TempDeclarationLines."VAT Amount / EC Amount" := VATBuffer2.Amount;
        TempDeclarationLines."Amount Including VAT / EC" := VATBuffer2.Base + VATBuffer2.Amount;
        TempDeclarationLines."Collection Amount" := VATBuffer2.Base + VATBuffer2.Amount;
        TempDeclarationLines.Type := VATEntry.Type;
        TempDeclarationLines."Unrealized VAT Entry No." := UnrealizedVATEntryNo;
        TempDeclarationLines."Bank Account Ledger Entry No." := FindPaymentInformation(TransactionNo);
        TempDeclarationLines."VAT Cash Regime" := VATCashRegime;
        TempDeclarationLines.RemoveDuplicateAmounts();
        TempDeclarationLines.Insert();
    end;

    local procedure RetrieveGLAccount(StringFilter: Text[250]) NoOfAcc: Integer
    var
        CommaPos: Integer;
        j: Integer;
    begin
        CommaPos := 1;
        j := 1;
        while CommaPos <> 0 do begin
            CommaPos := StrPos(StringFilter, '|');
            if CommaPos = 0 then
                FilterArray[j] := StringFilter
            else begin
                FilterArray[j] := CopyStr(StringFilter, 1, CommaPos - 1);
                StringFilter := DelStr(StringFilter, 1, CommaPos);
            end;
            j += 1;
        end;
        NoOfAcc := j - 1;
    end;

    local procedure IsCashAccount(GLAccountNo: Text[20]): Boolean
    var
        i: Integer;
    begin
        for i := 1 to NoOfAccounts do
            if GLAccountNo = FilterArray[i] then
                exit(true);
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure InsertTextWithReplace(OriginalText: Text[1024]; TextToInsert: Text[1024]; Position: Integer) Result: Text[1024]
    var
        StrLength: Integer;
        OrigStrLength: Integer;
    begin
        OrigStrLength := StrLen(OriginalText);
        StrLength := StrLen(TextToInsert);

        if OrigStrLength < (Position + StrLength - 1) then
            OriginalText := PadStr(OriginalText, Position + StrLength - 1, ' ');

        Result := DelStr(OriginalText, Position, StrLength);
        Result := InsStr(Result, TextToInsert, Position);
    end;

    local procedure UpdateCustomerCashBuffer(CustomerNo: Code[20]; OperationYear: Integer; OperationAmount: Decimal)
    var
        CustomerCashBuffer: Record "Customer Cash Buffer";
        Customer: Record Customer;
    begin
        if OperationYear < 2012 then
            exit;
        Customer.Get(CustomerNo);

        if CustomerCashBuffer.Get(Customer."VAT Registration No.", Format(OperationYear)) then begin
            CustomerCashBuffer."Operation Amount" += OperationAmount;
            CustomerCashBuffer.Modify();
        end else begin
            CustomerCashBuffer.Init();
            CustomerCashBuffer."VAT Registration No." := Customer."VAT Registration No.";
            CustomerCashBuffer."Operation Year" := Format(OperationYear);
            CustomerCashBuffer."Operation Amount" := OperationAmount;
            CustomerCashBuffer.Insert();
        end;
    end;

    local procedure IdentifyCashPaymentsFromGL(CustLedgerEntryParam: Record "Cust. Ledger Entry"): Boolean
    var
        GLEntryLoc: Record "G/L Entry";
    begin
        GLEntryLoc.Reset();
        GLEntryLoc.SetCurrentKey("Transaction No.");
        GLEntryLoc.SetRange("Transaction No.", CustLedgerEntryParam."Transaction No.");
        GLEntryLoc.SetRange("Document No.", CustLedgerEntryParam."Document No.");
        GLEntryLoc.SetRange("Document Type", GLEntryLoc."Document Type"::Payment);
        if GLEntryLoc.FindSet() then
            repeat
                if IsCashAccount(GLEntryLoc."G/L Account No.") then
                    exit(true);
            until GLEntryLoc.Next() = 0;
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure InitializeRequest(NewFiscalYear: Code[4]; NewMonth: Integer; NewContactName: Text[30]; NewTelephoneNumber: Code[9]; NewDeclarationNumber: Text[4]; NewElectronicCode: Code[16]; NewDeclarationMediaType: Option Telematic,"CD-R"; NewReplacementDeclaration: Boolean; NewPreviousDeclarationNumber: Code[13]; NewFileName: Text[1024]; NewGLAccount: Text[20]; NewMinPaymentAmount: Decimal)
    begin
        FiscalYear := NewFiscalYear;
        Month := NewMonth;
        MinPaymentAmount := NewMinPaymentAmount;
        ColumnGLAcc := NewGLAccount;
        ContactName := NewContactName;
        ContactTelephone := NewTelephoneNumber;
        DeclarationNum := NewDeclarationNumber;
        ElectronicCode := NewElectronicCode;
        DeclarationMediaType := NewDeclarationMediaType;
        ReplaceDeclaration := NewReplacementDeclaration;
        PrevDeclareNum := NewPreviousDeclarationNumber;
        FileName := NewFileName;
    end;

    local procedure PopulateAppliedPayments()
    var
        CustomerCashBuffer: Record "Customer Cash Buffer";
        OperationYear: Integer;
    begin
        NoOfAccounts := RetrieveGLAccount(GLAccFilterString);
        if GLAccFilterString <> '' then begin
            Customer.Reset();
            Customer.SetCurrentKey("VAT Registration No.");
            Customer.SetFilter("VAT Registration No.", '<>%1', '');
            if Customer.FindSet() then
                repeat
                    if CheckCustomerPayment(Customer."No.") then
                        ExecuteCustomerPayments(Customer."No.");
                until Customer.Next() = 0;
        end;

        if CustomerCashBuffer.FindSet() then
            repeat
                Customer.SetRange("VAT Registration No.", CustomerCashBuffer."VAT Registration No.");
                Customer.FindFirst();
                Evaluate(OperationYear, CustomerCashBuffer."Operation Year");
                if OperationYear <> NumFiscalYear then
                    GetAffectedYearInvoiceAndBill(Customer."No.", OperationYear);
            until CustomerCashBuffer.Next() = 0;

        CustomerCashBuffer.Reset();
        CustomerCashBuffer.SetFilter("Operation Amount", '>=%1', MinPaymentAmount);
        NoofRecords := NoofRecords + CustomerCashBuffer.Count();
    end;

    local procedure FormatPaymentAmount(PaymentAmount: Decimal): Text[15]
    var
        AmtText: Text[15];
    begin
        PaymentAmount := PaymentAmount * 100;
        AmtText := ConvertStr(Format(PaymentAmount), ' ', '0');
        AmtText := DelChr(AmtText, '=', '.,');

        while StrLen(AmtText) < 15 do
            AmtText := '0' + AmtText;
        exit(AmtText);
    end;

    local procedure CheckCashCollectables(): Boolean
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetFilter("Document Type", '%1|%2', CustLedgerEntry."Document Type"::" ", CustLedgerEntry."Document Type"::Payment);
        CustLedgerEntry.SetRange("Document Date", FromDate, ToDate);
        CustLedgerEntry.SetRange(Reversed, false);
        exit(not CustLedgerEntry.IsEmpty);
    end;

    local procedure CombineEUCountryAndVATRegNo(EUCountryRegionCode: Code[10]; VATRegistrationNo: Code[20]): Code[20]
    begin
        if StrPos(VATRegistrationNo, EUCountryRegionCode) <> 0 then
            exit(VATRegistrationNo);

        exit(EUCountryRegionCode + VATRegistrationNo);
    end;

    local procedure GetResidentIDText(RegionCountryCode: Code[10])
    begin
        if RegionCountryCode = CompanyInfo."Country/Region Code" then
            ResidentIDText := '1'
        else
            if FindEUCountryRegionCode(RegionCountryCode) <> '' then
                ResidentIDText := '2'
            else
                ResidentIDText := '6';
    end;

    local procedure GetVATNoPermnentResidntCntry(RegionCountryCode: Code[10]; VATRegistrationNo: Code[20])
    var
        EUCountryRegionCode: Code[10];
    begin
        if RegionCountryCode <> CompanyInfo."Country/Region Code" then begin
            EUCountryRegionCode := FindEUCountryRegionCode(RegionCountryCode);
            if EUCountryRegionCode <> '' then
                VATNoPermanentResidentCountry :=
                  PadStr(CombineEUCountryAndVATRegNo(EUCountryRegionCode, VATRegistrationNo), 20, ' ')
            else
                VATNoPermanentResidentCountry := PadStr('', 20, ' ');
        end else
            VATNoPermanentResidentCountry := PadStr('', 20, ' ');
    end;

    local procedure GetVATNumber(RegionCountryCode: Code[10]; VATRegistrationNo: Code[20]): Text[9]
    begin
        if RegionCountryCode = CompanyInfo."Country/Region Code" then
            exit(PadStr(VATRegistrationNo, 9, ' '));
        exit('');
    end;

    local procedure CheckCustomerPayment(CustomerNo: Code[20]): Boolean
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetCurrentKey("Document Type", "Customer No.", "Posting Date", "Currency Code");
        CustLedgerEntry.SetFilter("Document Type", '%1|%2', CustLedgerEntry."Document Type"::" ", CustLedgerEntry."Document Type"::Payment);
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange("Document Date", FromDate, ToDate);
        if CustLedgerEntry.FindSet() then
            repeat
                if CheckCustLedgEntryExists(CustLedgerEntry) then
                    exit(true);
            until CustLedgerEntry.Next() = 0;
    end;

    local procedure ExecuteCustomerPayments(CustomerNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetCurrentKey("Document Type", "Customer No.", "Posting Date", "Currency Code");
        CustLedgerEntry.SetFilter("Document Type", '%1|%2', CustLedgerEntry."Document Type"::" ", CustLedgerEntry."Document Type"::Payment);
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange("Document Date", DMY2Date(1, 1, NumFiscalYear), ToDate);
        if CustLedgerEntry.FindSet() then
            repeat
                if CheckCustLedgEntryExists(CustLedgerEntry) then
                    FillBufferFromPaymentCustLE(CustLedgerEntry, 0);
            until CustLedgerEntry.Next() = 0;
    end;

    local procedure FillBufferFromPaymentCustLE(CustLedgerEntry: Record "Cust. Ledger Entry"; InvoiceEntryNo: Integer)
    begin
        if (CustLedgerEntry."Bal. Account Type" = CustLedgerEntry."Bal. Account Type"::"G/L Account") and
           (CustLedgerEntry."Bal. Account No." <> '')
        then begin
            if IsCashAccount(CustLedgerEntry."Bal. Account No.") then
                CalculateAppliedAmounts(CustLedgerEntry."Entry No.", CustLedgerEntry."Customer No.", InvoiceEntryNo)
        end else
            if ((CustLedgerEntry."Bal. Account No." = '') or
                (CustLedgerEntry."Bal. Account Type" <> CustLedgerEntry."Bal. Account Type"::"G/L Account"))
            then
                if IdentifyCashPaymentsFromGL(CustLedgerEntry) then
                    CalculateAppliedAmounts(CustLedgerEntry."Entry No.", CustLedgerEntry."Customer No.", InvoiceEntryNo);
    end;

    local procedure CalculateAppliedAmounts(PaymentEntryNo: Integer; CustomerNo: Code[20]; InvoiceEntryNo: Integer)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DtldCustLedgEntry.SetCurrentKey("Cust. Ledger Entry No.");
        DtldCustLedgEntry.SetRange("Applied Cust. Ledger Entry No.", PaymentEntryNo);
        DtldCustLedgEntry.SetRange(Unapplied, false);
        if InvoiceEntryNo <> 0 then
            DtldCustLedgEntry.SetRange("Cust. Ledger Entry No.", InvoiceEntryNo);
        if DtldCustLedgEntry.FindSet() then
            repeat
                if DtldCustLedgEntry."Cust. Ledger Entry No." <> DtldCustLedgEntry."Applied Cust. Ledger Entry No." then
                    if CustLedgerEntry.Get(DtldCustLedgEntry."Cust. Ledger Entry No.") then
                        UpdateCustomerCashBuffer(
                          CustomerNo, Date2DMY(CustLedgerEntry."Document Date", 3), -DtldCustLedgEntry."Amount (LCY)");
            until DtldCustLedgEntry.Next() = 0
        else begin
            DtldCustLedgEntry.SetRange("Applied Cust. Ledger Entry No.");
            DtldCustLedgEntry.SetRange("Cust. Ledger Entry No.", PaymentEntryNo);
            DtldCustLedgEntry.SetRange("Entry Type", DtldCustLedgEntry."Entry Type"::Application);
            if DtldCustLedgEntry.FindSet() then
                repeat
                    if CustLedgerEntry.Get(DtldCustLedgEntry."Applied Cust. Ledger Entry No.") then
                        UpdateCustomerCashBuffer(
                          CustomerNo, Date2DMY(CustLedgerEntry."Document Date", 3), DtldCustLedgEntry."Amount (LCY)");
                until DtldCustLedgEntry.Next() = 0;
        end;
    end;

    local procedure GetAffectedYearInvoiceAndBill(CustomerNo: Code[20]; AffectedYear: Integer)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetCurrentKey("Document Type", "Customer No.", "Posting Date", "Currency Code");
        CustLedgerEntry.SetFilter(
          "Document Type", '%1|%2', CustLedgerEntry."Document Type"::Invoice, CustLedgerEntry."Document Type"::Bill);
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange("Document Date", DMY2Date(1, 1, AffectedYear), DMY2Date(31, 12, AffectedYear));
        if CustLedgerEntry.FindSet() then
            repeat
                GetAppliedPaymentsFromInvBill(CustLedgerEntry."Entry No.");
            until CustLedgerEntry.Next() = 0;
    end;

    local procedure GetAppliedPaymentsFromInvBill(InvoiceEntryNo: Integer)
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        DtldCustLedgEntry.SetRange("Applied Cust. Ledger Entry No.", InvoiceEntryNo);
        DtldCustLedgEntry.SetRange("Entry Type", DtldCustLedgEntry."Entry Type"::Application);
        DtldCustLedgEntry.SetFilter("Posting Date", '<%1', DMY2Date(1, 1, NumFiscalYear));
        DtldCustLedgEntry.SetRange(Unapplied, false);
        if DtldCustLedgEntry.FindSet() then
            repeat
                if DtldCustLedgEntry."Cust. Ledger Entry No." <> DtldCustLedgEntry."Applied Cust. Ledger Entry No." then
                    if CustLedgerEntry.Get(DtldCustLedgEntry."Cust. Ledger Entry No.") then
                        FillBufferFromPaymentCustLE(CustLedgerEntry, InvoiceEntryNo);
            until DtldCustLedgEntry.Next() = 0
        else begin
            DtldCustLedgEntry.SetRange("Applied Cust. Ledger Entry No.");
            DtldCustLedgEntry.SetRange("Cust. Ledger Entry No.", InvoiceEntryNo);
            if DtldCustLedgEntry.FindSet() then
                repeat
                    if DtldCustLedgEntry."Cust. Ledger Entry No." <> DtldCustLedgEntry."Applied Cust. Ledger Entry No." then
                        if CustLedgerEntry.Get(DtldCustLedgEntry."Applied Cust. Ledger Entry No.") then
                            FillBufferFromPaymentCustLE(CustLedgerEntry, InvoiceEntryNo);
                until DtldCustLedgEntry.Next() = 0;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetServerFileName(var ServerFileName: Text[1024])
    begin
        ServerFileName := ServerTempFileName;
    end;

    local procedure CheckCustLedgEntryExists(CustLedgerEntry: Record "Cust. Ledger Entry"): Boolean
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        ApplDtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        if CustLedgerEntry."Document Type" = CustLedgerEntry."Document Type"::Payment then
            exit(true);
        DtldCustLedgEntry.SetCurrentKey("Cust. Ledger Entry No.");
        DtldCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgerEntry."Entry No.");
        if DtldCustLedgEntry.FindFirst() then begin
            ApplDtldCustLedgEntry.SetRange("Transaction No.", DtldCustLedgEntry."Transaction No.");
            ApplDtldCustLedgEntry.SetFilter("Cust. Ledger Entry No.", '<>%1', DtldCustLedgEntry."Cust. Ledger Entry No.");
            ApplDtldCustLedgEntry.SetRange("Document Type", ApplDtldCustLedgEntry."Document Type"::Bill);
            exit(ApplDtldCustLedgEntry.IsEmpty);
        end;
    end;

    local procedure AddUnrealizedCollectionInfo(var DeclarationLine: Record "340 Declaration Line"; var txt: Text[500])
    begin
        AddCollectionDate(DeclarationLine, txt);
        AddCollectionAmount(DeclarationLine, txt);
        AddCollectionBankAcc(DeclarationLine, txt);
    end;

    local procedure AddCollectionDate(var DeclarationLine: Record "340 Declaration Line"; var txt: Text[1024])
    var
        PmntDate: Text[8];
        InsertPosition: Integer;
    begin
        if DeclarationLine."VAT Cash Regime" and (DeclarationLine."Unrealized VAT Entry No." <> 0) then
            PmntDate := FormatDate(DeclarationLine."Posting Date")
        else
            PmntDate := PadStr('', 8, '0');

        if DeclarationLine.Type = DeclarationLine.Type::Sale then
            InsertPosition := 445
        else
            InsertPosition := 350;

        txt := InsertTextWithReplace(txt, PmntDate, InsertPosition);
    end;

    local procedure AddCollectionAmount(var DeclarationLine: Record "340 Declaration Line"; var txt: Text[1024])
    var
        CollectionAmountValue: Decimal;
        CollectionAmount: Text[13];
        InsertPosition: Integer;
    begin
        if DeclarationLine."VAT Cash Regime" and (DeclarationLine."Unrealized VAT Entry No." <> 0) then
            CollectionAmountValue := DeclarationLine."Collection Amount" * 100;

        CollectionAmount := Format(CollectionAmountValue, 13, '<Integer>');
        CollectionAmount := ConvertStr(CollectionAmount, ' ', '0');

        if DeclarationLine.Type = DeclarationLine.Type::Sale then
            InsertPosition := 453
        else
            InsertPosition := 358;

        txt := InsertTextWithReplace(txt, CollectionAmount, InsertPosition);
    end;

    local procedure AddPaymentMethod(var DeclarationLine: Record "340 Declaration Line"; var txt: Text[1024]; CollectionPaymentMethodUsed: Text[1])
    var
        InsertPosition: Integer;
    begin
        if DeclarationLine.Type = DeclarationLine.Type::Sale then
            InsertPosition := 466
        else
            InsertPosition := 371;

        CollectionPaymentMethodUsed := PadStr(CollectionPaymentMethodUsed, 1, ' ');
        txt := InsertTextWithReplace(txt, CollectionPaymentMethodUsed, InsertPosition);
    end;

    local procedure AddCollectionBankAcc(var DeclarationLine: Record "340 Declaration Line"; var txt: Text[1024])
    var
        VATEntryForPmnt: Record "VAT Entry";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        CheckLedgerEntry: Record "Check Ledger Entry";
        BankAccNo: Code[20];
        CollectionPaymentMethodUsed: Text[1];
        BankAccountOrPaymentMethodUsed: Text[34];
        InsertPosition: Integer;
    begin
        if DeclarationLine."VAT Cash Regime" and VATEntryForPmnt.Get(DeclarationLine."Unrealized VAT Entry No.") then begin
            CheckLedgerEntry.SetRange("Bank Account Ledger Entry No.", DeclarationLine."Bank Account Ledger Entry No.");
            if CheckLedgerEntry.FindFirst() then begin
                BankAccountOrPaymentMethodUsed := CheckLedgerEntry."Check No.";
                CollectionPaymentMethodUsed := 'T';
            end else begin
                if BankAccountLedgerEntry.Get(DeclarationLine."Bank Account Ledger Entry No.") then
                    BankAccNo := BankAccountLedgerEntry."Bank Account No."
                else
                    BankAccNo := FindPmtOrderBillGrBankAcc(DeclarationLine.Type, DeclarationLine."Document No.");
                BankAccountOrPaymentMethodUsed := GetBankAccountUsed(BankAccNo);
                if BankAccountOrPaymentMethodUsed <> '' then
                    CollectionPaymentMethodUsed := 'C';
            end;
            if BankAccountOrPaymentMethodUsed = '' then begin
                CollectionPaymentMethodUsed := 'O';
                if DeclarationLine.Type = DeclarationLine.Type::Sale then
                    BankAccountOrPaymentMethodUsed := FindCustPaymentMethod(VATEntryForPmnt)
                else
                    BankAccountOrPaymentMethodUsed := FindVendPaymentMethod(VATEntryForPmnt);
            end;
        end;

        AddPaymentMethod(DeclarationLine, txt, CollectionPaymentMethodUsed);

        if DeclarationLine.Type = DeclarationLine.Type::Sale then
            InsertPosition := 467
        else
            InsertPosition := 372;

        BankAccountOrPaymentMethodUsed := PadStr(BankAccountOrPaymentMethodUsed, 34, ' ');
        txt := InsertTextWithReplace(txt, BankAccountOrPaymentMethodUsed, InsertPosition);
    end;

    local procedure GetBankAccountUsed(BankAccNo: Code[20]) BankAccountUsed: Text[34]
    var
        BankAccount: Record "Bank Account";
    begin
        if BankAccount.Get(BankAccNo) then begin
            BankAccountUsed := BankAccount."CCC No.";
            if BankAccountUsed = '' then
                BankAccountUsed := BankAccount."Bank Account No.";
            if BankAccountUsed = '' then
                BankAccountUsed := CopyStr(BankAccount.IBAN, 1, MaxStrLen(BankAccountUsed));
        end;
    end;

    local procedure AreDatesInSamePeriod(Date1: Date; Date2: Date): Boolean
    begin
        exit(CalcDate('<CM>', Date1) = CalcDate('<CM>', Date2));
    end;

    local procedure FindCustPaymentMethod(DocVATEntry: Record "VAT Entry"): Text[30]
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesInvHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        CustLedgerEntry.SetRange("Transaction No.", DocVATEntry."Transaction No.");
        if CustLedgerEntry.FindFirst() then begin
            case CustLedgerEntry."Document Type" of
                CustLedgerEntry."Document Type"::Invoice:
                    if SalesInvHeader.Get(CustLedgerEntry."Document No.") then
                        exit(SalesInvHeader."Payment Method Code");
                CustLedgerEntry."Document Type"::"Credit Memo":
                    if SalesCrMemoHeader.Get(CustLedgerEntry."Document No.") then
                        exit(SalesCrMemoHeader."Payment Method Code");
            end;
            if Customer.Get(CustLedgerEntry."Customer No.") then
                exit(Customer."Payment Method Code");
        end;
    end;

    local procedure FindVendPaymentMethod(DocVATEntry: Record "VAT Entry"): Text[30]
    var
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        VendorLedgerEntry.SetRange("Transaction No.", DocVATEntry."Transaction No.");
        if VendorLedgerEntry.FindFirst() then begin
            case VendorLedgerEntry."Document Type" of
                VendorLedgerEntry."Document Type"::Invoice:
                    if PurchInvHeader.Get(VendorLedgerEntry."Document No.") then
                        exit(PurchInvHeader."Payment Method Code");
                VendorLedgerEntry."Document Type"::"Credit Memo":
                    if PurchCrMemoHdr.Get(VendorLedgerEntry."Document No.") then
                        exit(PurchCrMemoHdr."Payment Method Code");
            end;
            if Vendor.Get(VendorLedgerEntry."Vendor No.") then
                exit(Vendor."Payment Method Code");
        end;
    end;

    local procedure FindPaymentInformation(TransactionNo: Integer): Integer
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        BankAccountLedgerEntry.SetRange("Transaction No.", TransactionNo);
        if BankAccountLedgerEntry.FindFirst() then
            exit(BankAccountLedgerEntry."Entry No.");

        exit(0);
    end;

    local procedure FindAppliedToDocumentNo(UnrealizedVATEntry: Record "VAT Entry"): Code[35]
    begin
        if UnrealizedVATEntry.Type = UnrealizedVATEntry.Type::Sale then
            exit(UnrealizedVATEntry."Document No.");

        if UnrealizedVATEntry.Type = UnrealizedVATEntry.Type::Purchase then
            exit(UnrealizedVATEntry."External Document No.");
    end;

    local procedure SkipUnappliedCustLedgEntry(TransactionNo: Integer)
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        UnappliedDtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DtldCustLedgEntry.SetCurrentKey("Transaction No.");
        DtldCustLedgEntry.SetRange("Transaction No.", TransactionNo);
        DtldCustLedgEntry.SetRange("Entry Type", DtldCustLedgEntry."Entry Type"::Application);
        if DtldCustLedgEntry.FindFirst() then
            if DtldCustLedgEntry.Unapplied then begin
                UnappliedDtldCustLedgEntry.Get(DtldCustLedgEntry."Unapplied by Entry No.");
                if AreDatesInSamePeriod(UnappliedDtldCustLedgEntry."Posting Date", DtldCustLedgEntry."Posting Date") then
                    CurrReport.Skip();
            end;
    end;

    local procedure SkipUnappliedVendLedgEntry(TransactionNo: Integer)
    var
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        UnappliedDtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        DtldVendLedgEntry.SetCurrentKey("Transaction No.");
        DtldVendLedgEntry.SetRange("Transaction No.", TransactionNo);
        DtldVendLedgEntry.SetRange("Entry Type", DtldVendLedgEntry."Entry Type"::Application);
        if DtldVendLedgEntry.FindFirst() then
            if DtldVendLedgEntry.Unapplied then begin
                UnappliedDtldVendLedgEntry.Get(DtldVendLedgEntry."Unapplied by Entry No.");
                if AreDatesInSamePeriod(UnappliedDtldVendLedgEntry."Posting Date", DtldVendLedgEntry."Posting Date") then
                    CurrReport.Skip();
            end;
    end;

    local procedure SkipZeroCustLedgEntry(TransactionNo: Integer)
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgEntry.SetRange("Transaction No.", TransactionNo);
        if CustLedgEntry.FindFirst() then begin
            CustLedgEntry.CalcFields("Original Amount");
            if CustLedgEntry."Original Amount" = 0 then
                CurrReport.Skip();
        end;
    end;

    local procedure SkipZeroVendLedgEntry(TransactionNo: Integer)
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        VendLedgEntry.SetRange("Transaction No.", TransactionNo);
        if VendLedgEntry.FindFirst() then begin
            VendLedgEntry.CalcFields("Original Amount");
            if VendLedgEntry."Original Amount" = 0 then
                CurrReport.Skip();
        end;
    end;

    local procedure ReplaceDeclarationOnPush()
    begin
        PrevDeclarationNumEnable := ReplaceDeclaration;
    end;

    local procedure CheckVLEApplication(VATEntry: Record "VAT Entry"): Boolean
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        CheckVendLedgEntry: Record "Vendor Ledger Entry";
        RecordFound: Boolean;
        UnrealizedVendLedgEntry: Integer;
    begin
        FilterVendLedgerEntryByVATEntry(VendorLedgerEntry, VATEntry);
        RecordFound := VendorLedgerEntry.FindSet();
        if (not RecordFound) and (VATEntry."Unrealized VAT Entry No." <> 0) then begin
            VendorLedgerEntry.SetFilter("Transaction No.", '%1..', VATEntry."Transaction No.");
            RecordFound := VendorLedgerEntry.FindSet();
        end;
        if RecordFound then
            repeat
                UnrealizedVendLedgEntry :=
                  GetUnrealizedInvoiceVLENo(VATEntry."Unrealized VAT Entry No.", VendorLedgerEntry."Applies-to Bill No.");
                DtldVendLedgEntry.Reset();
                DtldVendLedgEntry.SetRange(Unapplied, false);
                DtldVendLedgEntry.SetRange("Entry Type", DtldVendLedgEntry."Entry Type"::Application);
                DtldVendLedgEntry.SetRange("Applied Vend. Ledger Entry No.", VendorLedgerEntry."Entry No.");
                if UnrealizedVendLedgEntry <> 0 then
                    DtldVendLedgEntry.SetRange("Vendor Ledger Entry No.", UnrealizedVendLedgEntry);

                if DtldVendLedgEntry.FindSet() then
                    repeat
                        if (DtldVendLedgEntry."Vendor Ledger Entry No." <> DtldVendLedgEntry."Applied Vend. Ledger Entry No.") and
                           CheckVendLedgEntry.Get(DtldVendLedgEntry."Vendor Ledger Entry No.")
                        then begin
                            if ExistDtldVLE(DtldVendLedgEntry."Vendor Ledger Entry No.", DtldVendLedgEntry."Applied Vend. Ledger Entry No.") then
                                exit(false);
                            InsertTempDtldVLE(DtldVendLedgEntry."Vendor Ledger Entry No.", DtldVendLedgEntry."Applied Vend. Ledger Entry No.");
                            exit(true);
                        end;
                    until DtldVendLedgEntry.Next() = 0
                else begin
                    DtldVendLedgEntry.SetRange("Applied Vend. Ledger Entry No.");
                    DtldVendLedgEntry.SetRange("Vendor Ledger Entry No.", VendorLedgerEntry."Entry No.");
                    if UnrealizedVendLedgEntry <> 0 then
                        DtldVendLedgEntry.SetRange("Applied Vend. Ledger Entry No.", UnrealizedVendLedgEntry);

                    if DtldVendLedgEntry.FindSet() then
                        repeat
                            if CheckVendLedgEntry.Get(DtldVendLedgEntry."Applied Vend. Ledger Entry No.") then begin
                                if ExistDtldVLE(DtldVendLedgEntry."Applied Vend. Ledger Entry No.", DtldVendLedgEntry."Vendor Ledger Entry No.") then
                                    exit(false);
                                InsertTempDtldVLE(DtldVendLedgEntry."Applied Vend. Ledger Entry No.", DtldVendLedgEntry."Vendor Ledger Entry No.");
                                exit(true);
                            end;
                        until DtldVendLedgEntry.Next() = 0;
                end;
            until VendorLedgerEntry.Next() = 0;

        exit(true);
    end;

    local procedure GetUnrealizedInvoiceVLENo(VATEntryNo: Integer; AppliesToBillNo: Code[20]): Integer
    var
        VATEntry: Record "VAT Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        if not VATEntry.Get(VATEntryNo) then
            exit(0);

        VendLedgEntry.SetRange("Vendor No.", VATEntry."Bill-to/Pay-to No.");
        VendLedgEntry.SetRange("Posting Date", VATEntry."Posting Date");
        VendLedgEntry.SetRange("Document No.", VATEntry."Document No.");
        if AppliesToBillNo = '' then
            VendLedgEntry.SetRange("Document Type", VATEntry."Document Type")
        else begin
            VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::Bill);
            VendLedgEntry.SetRange("Bill No.", AppliesToBillNo);
        end;
        if VendLedgEntry.FindFirst() then
            exit(VendLedgEntry."Entry No.");
        exit(0);
    end;

    local procedure FilterVendLedgerEntryByVATEntry(var VendLedgEntry: Record "Vendor Ledger Entry"; VATEntry: Record "VAT Entry")
    begin
        VendLedgEntry.SetRange("Vendor No.", VATEntry."Bill-to/Pay-to No.");
        VendLedgEntry.SetRange("Posting Date", VATEntry."Posting Date");
        VendLedgEntry.SetRange("Document Type", VATEntry."Document Type");
        VendLedgEntry.SetRange("Document No.", VATEntry."Document No.");
        VendLedgEntry.SetRange("Transaction No.", VATEntry."Transaction No.");
    end;

    local procedure HasBeenRealized(VATEntryNo: Integer): Boolean
    var
        UnrealizedVATEntry: Record "VAT Entry";
    begin
        UnrealizedVATEntry.SetRange("Unrealized VAT Entry No.", VATEntryNo);
        exit(not UnrealizedVATEntry.IsEmpty);
    end;

    local procedure ExistDtldVLE(VLENo: Integer; AppliedVLENo: Integer): Boolean
    begin
        TempDetailedVendorLedgEntry.SetRange("Vendor Ledger Entry No.", VLENo);
        TempDetailedVendorLedgEntry.SetRange("Applied Vend. Ledger Entry No.", AppliedVLENo);
        exit(not TempDetailedVendorLedgEntry.IsEmpty);
    end;

    local procedure InsertTempDtldVLE(VLENo: Integer; AppliedVLENo: Integer)
    begin
        TempDetailedVendorLedgEntry.Init();
        if TempDetailedVendorLedgEntry.FindLast() then;
        TempDetailedVendorLedgEntry."Entry No." += 1;
        TempDetailedVendorLedgEntry."Vendor Ledger Entry No." := VLENo;
        TempDetailedVendorLedgEntry."Applied Vend. Ledger Entry No." := AppliedVLENo;
        TempDetailedVendorLedgEntry.Insert();
    end;

    local procedure DownloadFile()
    begin
        // Testability: FileName is initialized if this report is invoked from tests
        if FileName = '' then begin
            FileName := StrSubstNo(FileNameTxt, FiscalYear, Month);
            if Download(ServerTempFileName, '', '', FileFilterTxt, FileName) then;
        end else begin
            FileManagement.CopyServerFile(ServerTempFileName, FileName, true);
            Message(FileExportedMsg, FileName);
        end;
    end;

    local procedure CheckIncludeVATEntry(VATEntry: Record "VAT Entry"): Boolean
    begin
        exit(
              not ((VATEntry."Document Type" in [VATEntry."Document Type"::Invoice, VATEntry."Document Type"::"Credit Memo",
                                        VATEntry."Document Type"::"Finance Charge Memo", VATEntry."Document Type"::Reminder]) and
                   (VATEntry."Unrealized Base" <> 0) and not VATEntry."VAT Cash Regime") and
              not (VATEntry."Document Type" = VATEntry."Document Type"::" "))
        // Invoices, Credit Memos, Finance Charge Memos and Reminders with unrealized base and are not in the VAT Cash Regime should not be shown, only their payment
    end;

    local procedure CreateTempDeclarationLineForPurchInvNoTaxVAT()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        VATEntry: Record "VAT Entry";
        GLEntry: Record "G/L Entry";
        VendVATNumber: Text[9];
    begin
        PurchInvLine.SetRange("Posting Date", FromDate, ToDate);
        PurchInvLine.SetRange("VAT Calculation Type", PurchInvLine."VAT Calculation Type"::"No Taxable VAT");
        if PurchInvLine.FindSet() then
            repeat
                PurchInvHeader.Get(PurchInvLine."Document No.");
                InitNoTaxDeclarationInfo(
                  VATEntry.Type::Purchase, PurchInvHeader."Posting Date", PurchInvLine."Document No.", 'R', PurchInvLine.Amount);
                Vendor.Get(PurchInvLine."Pay-to Vendor No.");
                VendVATNumber := GetVATNumber(Vendor."Country/Region Code", Vendor."VAT Registration No.");
                InitCountryResidentInfo(Vendor."Country/Region Code", Vendor."VAT Registration No.");
                CreateTempDeclarationLines(
                  PadStr(VendVATNumber, 9, ' '), Vendor."No.", Vendor.Name, PurchInvHeader."Document Date",
                  PurchInvHeader."Vendor Invoice No.", Format(VATEntry."Document Type"::Invoice),
                  '000000000000000001', FormatTextAmt(0, false) + PadStr('', 16, ' '), 0,
                  GetDocumentTransactionNo(GLEntry."Document Type"::Invoice, PurchInvHeader."No.", PurchInvHeader."Posting Date"),
                  PurchInvHeader."Posting Date", false);
            until PurchInvLine.Next() = 0;
    end;

    local procedure CreateTempDeclarationLineForPurchCrMemoNoTaxVAT()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        VATEntry: Record "VAT Entry";
        GLEntry: Record "G/L Entry";
        VendVATNumber: Text[9];
    begin
        PurchCrMemoLine.SetRange("Posting Date", FromDate, ToDate);
        PurchCrMemoLine.SetRange("VAT Calculation Type", PurchCrMemoLine."VAT Calculation Type"::"No Taxable VAT");
        if PurchCrMemoLine.FindSet() then
            repeat
                PurchCrMemoHdr.Get(PurchCrMemoLine."Document No.");
                InitNoTaxDeclarationInfo(
                  VATEntry.Type::Purchase, PurchCrMemoHdr."Posting Date", PurchCrMemoLine."Document No.", 'R', -PurchCrMemoLine.Amount);
                OperationCode := 'D';
                Vendor.Get(PurchCrMemoLine."Pay-to Vendor No.");
                VendVATNumber := GetVATNumber(Vendor."Country/Region Code", Vendor."VAT Registration No.");
                InitCountryResidentInfo(Vendor."Country/Region Code", Vendor."VAT Registration No.");
                CreateTempDeclarationLines(
                  PadStr(VendVATNumber, 9, ' '), Vendor."No.", Vendor.Name, PurchCrMemoHdr."Document Date",
                  PurchCrMemoHdr."Vendor Cr. Memo No.", Format(VATEntry."Document Type"::"Credit Memo"),
                  '000000000000000001', FormatTextAmt(0, false) + PadStr('', 16, ' '), 0,
                  GetDocumentTransactionNo(GLEntry."Document Type"::"Credit Memo", PurchCrMemoHdr."No.", PurchCrMemoHdr."Posting Date"),
                  PurchCrMemoHdr."Posting Date", false);
            until PurchCrMemoLine.Next() = 0;
    end;

    local procedure CreateTempDeclarationLineForSalesInvNoTaxVAT()
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesInvLine: Record "Sales Invoice Line";
        VATEntry: Record "VAT Entry";
        GLEntry: Record "G/L Entry";
        CustVATNumber: Text[9];
    begin
        SalesInvLine.SetRange("Posting Date", FromDate, ToDate);
        SalesInvLine.SetRange("VAT Calculation Type", SalesInvLine."VAT Calculation Type"::"No Taxable VAT");
        if SalesInvLine.FindSet() then
            repeat
                SalesInvHeader.Get(SalesInvLine."Document No.");
                InitNoTaxDeclarationInfo(
                  VATEntry.Type::Sale, SalesInvHeader."Posting Date", SalesInvLine."Document No.", 'E', SalesInvLine.Amount);
                Customer.Get(SalesInvLine."Bill-to Customer No.");
                InitCountryResidentInfo(Customer."Country/Region Code", Customer."VAT Registration No.");
                CustVATNumber := GetVATNumber(Customer."Country/Region Code", Customer."VAT Registration No.");
                CreateTempDeclarationLines(
                  PadStr(CustVATNumber, 9, ' '), Customer."No.", Customer.Name, SalesInvHeader."Document Date",
                  SalesInvHeader."No.", Format(VATEntry."Document Type"::Invoice),
                  '00000001', '', 0,
                  GetDocumentTransactionNo(GLEntry."Document Type"::Invoice, SalesInvHeader."No.", SalesInvHeader."Posting Date"),
                  SalesInvHeader."Posting Date", false);
            until SalesInvLine.Next() = 0;
    end;

    local procedure CreateTempDeclarationLineForSalesCrMemoNoTaxVAT()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        VATEntry: Record "VAT Entry";
        GLEntry: Record "G/L Entry";
        CustVATNumber: Text[9];
    begin
        SalesCrMemoLine.SetRange("Posting Date", FromDate, ToDate);
        SalesCrMemoLine.SetRange("VAT Calculation Type", SalesCrMemoLine."VAT Calculation Type"::"No Taxable VAT");
        if SalesCrMemoLine.FindSet() then
            repeat
                SalesCrMemoHeader.Get(SalesCrMemoLine."Document No.");
                InitNoTaxDeclarationInfo(
                  VATEntry.Type::Sale, SalesCrMemoHeader."Posting Date", SalesCrMemoLine."Document No.", 'E', -SalesCrMemoLine.Amount);
                OperationCode := 'D';
                Customer.Get(SalesCrMemoLine."Bill-to Customer No.");
                InitCountryResidentInfo(Customer."Country/Region Code", Customer."VAT Registration No.");
                CustVATNumber := GetVATNumber(Customer."Country/Region Code", Customer."VAT Registration No.");
                CreateTempDeclarationLines(
                  PadStr(CustVATNumber, 9, ' '), Customer."No.", Customer.Name, SalesCrMemoHeader."Document Date",
                  SalesCrMemoHeader."No.", Format(VATEntry."Document Type"::"Credit Memo"),
                  '00000001', '', 0,
                  GetDocumentTransactionNo(GLEntry."Document Type"::"Credit Memo", SalesCrMemoHeader."No.", SalesCrMemoHeader."Posting Date"),
                  SalesCrMemoHeader."Posting Date", false);
            until SalesCrMemoLine.Next() = 0;
    end;

    local procedure InitNoTaxDeclarationInfo(Type: Enum "General Posting Type"; PostingDate: Date; DocNo: Code[20]; NewBookTypeCode: Code[1]; Amount: Decimal)
    begin
        Clear(VATBuffer2);
        VATBuffer2.Base := Amount;
        BookTypeCode := NewBookTypeCode;
        VATEntry.Type := Type;
        VATEntry."Document No." := DocNo;
        NoofRegistersText := GetNoOfRegsText();
        OperationDateText := FormatDate(PostingDate);
    end;

    local procedure GetDocumentTransactionNo(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; PostingDate: Date): Integer
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document Type", DocType);
        GLEntry.SetRange("Document No.", DocNo);
        GLEntry.SetRange("Posting Date", PostingDate);
        GLEntry.FindFirst();
        exit(GLEntry."Transaction No.");
    end;

    local procedure InitCountryResidentInfo(CountryRegionCode: Code[10]; VATRegistrationNo: Text[20])
    begin
        GetResidentIDText(CountryRegionCode);
        GetVATNoPermnentResidntCntry(CountryRegionCode, VATRegistrationNo);
        CountryCode := PadStr(CountryRegionCode, 2, ' ')
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetCustomerDataFromServiceInvoice(VATEntry: Record "VAT Entry"; var Customer: Record Customer; var ShouldExit: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetCustomerDataFromServiceCrMemo(VATEntry: Record "VAT Entry"; var Customer: Record Customer; var ShouldExit: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecordTypeSaleOnGetOperationDate(VATEntry: Record "VAT Entry"; var OperationDateText: Text; var CorrInvoiceText: Text)
    begin
    end;
}

