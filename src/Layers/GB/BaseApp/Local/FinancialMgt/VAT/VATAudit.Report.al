#if not CLEAN27
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.VAT.Ledger;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using System.IO;
using System.Telemetry;

report 10512 "VAT Audit"
{
    Caption = 'VAT Audit';
    ProcessingOnly = true;
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to VAT Audit Reports GB app';
    ObsoleteTag = '27.0';

    dataset
    {
        dataitem(Customer; Customer)
        {
            DataItemTableView = sorting("No.");

            trigger OnAfterGetRecord()
            begin
                CustomerFile.Write(
                  StrSubstNo(
                    SevenDelimitedValuesTxt,
                    "No.",
                    Name,
                    Address,
                    "Address 2",
                    City,
                    County,
                    "Post Code"));

                Window.Update(1, "No.");
            end;

            trigger OnPostDataItem()
            begin
                if CustomerExport then begin
                    CustomerFile.Close();
                    Download(CustomerFileName, '', 'C:', '', ToFile);
                end;
            end;

            trigger OnPreDataItem()
            begin
                if not CustomerExport then
                    CurrReport.Break();
                CustomerFile.TextMode := true;
                CustomerFile.WriteMode := true;
                ToFile := CustomerFileName;
                CustomerFileName := RBMgt.ServerTempFileName('');
                CustomerFile.Create(CustomerFileName);
                CustomerFile.Write(
                  StrSubstNo(
                    SevenDelimitedValuesTxt,
                    FieldCaption("No."),
                    FieldCaption(Name),
                    FieldCaption(Address),
                    FieldCaption("Address 2"),
                    FieldCaption(City),
                    FieldCaption(County),
                    FieldCaption("Post Code")));

                Window.Open(Text1041000);
            end;
        }
        dataitem(OpenPayments; "Cust. Ledger Entry")
        {
            CalcFields = "Original Amt. (LCY)";
            DataItemTableView = sorting("Customer No.", Open, Positive) where(Open = const(true), Positive = const(false));

            trigger OnAfterGetRecord()
            begin
                OpenPaymentFile.Write(
                  StrSubstNo(
                    SevenDelimitedValuesTxt,
                    "Entry No.",
                    "Customer No.",
                    Description,
                    Format("Document Type"),
                    "Document No.",
                    "Posting Date",
                    "Original Amt. (LCY)"));

                Window.Update(1, "Entry No.");
            end;

            trigger OnPostDataItem()
            begin
                if OpenPaymentExport then begin
                    OpenPaymentFile.Close();
                    Download(OpenPaymentFileName, '', 'C:', '', ToFile);
                end;
            end;

            trigger OnPreDataItem()
            begin
                if not OpenPaymentExport then
                    CurrReport.Break();
                OpenPaymentFile.TextMode := true;
                OpenPaymentFile.WriteMode := true;
                ToFile := OpenPaymentFileName;
                OpenPaymentFileName := RBMgt.ServerTempFileName('');

                OpenPaymentFile.Create(OpenPaymentFileName);
                OpenPaymentFile.Write(
                  StrSubstNo(
                    SevenDelimitedValuesTxt,
                    FieldCaption("Entry No."),
                    FieldCaption("Customer No."),
                    FieldCaption(Description),
                    FieldCaption("Document Type"),
                    FieldCaption("Document No."),
                    FieldCaption("Posting Date"),
                    FieldCaption("Original Amt. (LCY)")));

                Window.Open(Text1041001);
            end;
        }
        dataitem(LateInvoicing; "Cust. Ledger Entry")
        {
            CalcFields = "Original Amt. (LCY)";
            DataItemTableView = sorting("Customer No.", Open, Positive) where(Open = const(false), Positive = const(false));

            trigger OnAfterGetRecord()
            var
                CustLedgEntry: Record "Cust. Ledger Entry";
                InvPostingDates: Text[250];
                LateInvoice: Boolean;
            begin
                LateInvoice := false;
                InvPostingDates := '';
                CustLedgEntry.Reset();
                CustLedgEntry.SetCurrentKey("Entry No.");
                CustLedgEntry.SetRange("Entry No.", "Closed by Entry No.");
                if CustLedgEntry.Find('-') then
                    repeat
                        if (CustLedgEntry."Posting Date" - "Posting Date") > LateInvoiceDelay then begin
                            LateInvoice := true;
                            if StrLen(InvPostingDates) > 1 then
                                InvPostingDates := InvPostingDates + ';';
                            if StrLen(InvPostingDates) < 240 then
                                InvPostingDates := InvPostingDates + Format(CustLedgEntry."Posting Date");
                        end;
                    until CustLedgEntry.Next() = 0;
                CustLedgEntry.Reset();
                CustLedgEntry.SetCurrentKey("Closed by Entry No.");
                CustLedgEntry.SetRange("Closed by Entry No.", "Entry No.");
                if CustLedgEntry.Find('-') then
                    repeat
                        if (CustLedgEntry."Posting Date" - "Posting Date") > LateInvoiceDelay then begin
                            LateInvoice := true;
                            if StrLen(InvPostingDates) > 1 then
                                InvPostingDates := InvPostingDates + ';';
                            if StrLen(InvPostingDates) < 240 then
                                InvPostingDates := InvPostingDates + Format(CustLedgEntry."Posting Date");
                        end;
                    until CustLedgEntry.Next() = 0;

                if not LateInvoice then
                    CurrReport.Skip();

                LateInvoicingFile.Write(
                  StrSubstNo(
                    EightDelimitedValuesTxt,
                    "Entry No.",
                    "Customer No.",
                    Description,
                    Format("Document Type"),
                    "Document No.",
                    "Posting Date",
                    InvPostingDates,
                    "Original Amt. (LCY)"));

                Window.Update(1, "Entry No.");
            end;

            trigger OnPostDataItem()
            begin
                if LateInvoicingExport then begin
                    LateInvoicingFile.Close();
                    Download(LateInvoicingFileName, '', 'C:', '', ToFile);
                end;
            end;

            trigger OnPreDataItem()
            begin
                if not LateInvoicingExport then
                    CurrReport.Break();
                LateInvoicingFile.TextMode := true;
                LateInvoicingFile.WriteMode := true;
                ToFile := LateInvoicingFileName;
                LateInvoicingFileName := RBMgt.ServerTempFileName('');

                LateInvoicingFile.Create(LateInvoicingFileName);
                LateInvoicingFile.Write(
                  StrSubstNo(
                    EightDelimitedValuesTxt,
                    FieldCaption("Entry No."),
                    FieldCaption("Customer No."),
                    FieldCaption(Description),
                    FieldCaption("Document Type"),
                    FieldCaption("Document No."),
                    Text1041002 + FieldCaption("Posting Date"),
                    Text1041003 + FieldCaption("Posting Date"),
                    FieldCaption("Original Amt. (LCY)")));

                Window.Open(Text1041004);
            end;
        }
        dataitem(Vendor; Vendor)
        {
            DataItemTableView = sorting("No.");

            trigger OnAfterGetRecord()
            begin
                VendorFile.Write(
                  StrSubstNo(
                    EightDelimitedValuesTxt,
                    "No.",
                    Name,
                    Address,
                    "Address 2",
                    City,
                    County,
                    "Post Code"));

                Window.Update(1, "No.");
            end;

            trigger OnPostDataItem()
            begin
                if VendorExport then begin
                    VendorFile.Close();
                    Download(VendorFileName, '', 'C:', '', ToFile);
                end;
            end;

            trigger OnPreDataItem()
            begin
                if not VendorExport then
                    CurrReport.Break();
                VendorFile.TextMode := true;
                VendorFile.WriteMode := true;
                ToFile := VendorFileName;
                VendorFileName := RBMgt.ServerTempFileName('');

                VendorFile.Create(VendorFileName);
                VendorFile.Write(
                  StrSubstNo(
                    SevenDelimitedValuesTxt,
                    FieldCaption("No."),
                    FieldCaption(Name),
                    FieldCaption(Address),
                    FieldCaption("Address 2"),
                    FieldCaption(City),
                    FieldCaption(County),
                    FieldCaption("Post Code")));

                Window.Open(Text1041005);
            end;
        }
        dataitem("VAT Entry"; "VAT Entry")
        {
            DataItemTableView = sorting("Document No.", "VAT Reporting Date");
            RequestFilterFields = "VAT Reporting Date", "Posting Date";

            trigger OnAfterGetRecord()
            begin
                VATEntryFile.Write(
                  StrSubstNo(
                    ElevenDelimitedValuesTxt,
                    "Posting Date",
                    "VAT Reporting Date",
                    "Document No.",
                    Format("Document Type"),
                    Base,
                    Amount,
                    Format("VAT Calculation Type"),
                    Format(Type),
                    "Bill-to/Pay-to No.",
                    "External Document No.",
                    "Entry No."));

                Window.Update(1, "Entry No.");
            end;

            trigger OnPostDataItem()
            begin
                if VATEntryExport then begin
                    VATEntryFile.Close();
                    Download(VATEntryFileName, '', 'C:', '', ToFile);
                end;
            end;

            trigger OnPreDataItem()
            begin
                if not VATEntryExport then
                    CurrReport.Break();
                VATEntryFile.TextMode := true;
                VATEntryFile.WriteMode := true;

                ToFile := VATEntryFileName;
                VATEntryFileName := RBMgt.ServerTempFileName('');

                VATEntryFile.Create(VATEntryFileName);
                VATEntryFile.Write(
                  StrSubstNo(
                    ElevenDelimitedValuesTxt,
                    FieldCaption("Posting Date"),
                    FieldCaption("VAT Reporting Date"),
                    FieldCaption("Document No."),
                    FieldCaption("Document Type"),
                    FieldCaption(Base),
                    FieldCaption(Amount),
                    FieldCaption("VAT Calculation Type"),
                    FieldCaption(Type),
                    FieldCaption("Bill-to/Pay-to No."),
                    FieldCaption("External Document No."),
                    FieldCaption("Entry No.")));

                Window.Open(Text1041006);
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
                    field(CustomerExport; CustomerExport)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Export Customers';
                        ToolTip = 'Specifies that you want to export the Customer table.';
                    }
                    field(CustomerFileNameCtrl; CustomerFileName)
                    {
                        ApplicationArea = All;
                        Caption = 'Customer File';
                        ToolTip = 'Specifies the relevant customer data for VAT auditors.';
                        Visible = CustomerFileNameCtrlVisible;
                    }
                    field(OpenPaymentExport; OpenPaymentExport)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Export Open Payments';
                        ToolTip = 'Specifies that you want to export all customers'' opened credit entries.';
                    }
                    field(OpenPaymentFileNameCtrl; OpenPaymentFileName)
                    {
                        ApplicationArea = All;
                        Caption = 'Open Payments File';
                        ToolTip = 'Specifies that you want to export the open credit entries.';
                        Visible = OpenPaymentFileNameCtrlVisible;
                    }
                    field(LateInvoicingExport; LateInvoicingExport)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Export Late Invoicing';
                        ToolTip = 'Specifies that you want to export all customer entries that were invoiced later than Late Invoice Delay (Days) limit.';
                    }
                    field(LateInvoiceDelay; LateInvoiceDelay)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Late Invoice Delay (Days)';
                        DecimalPlaces = 0 : 0;
                        MinValue = 0;
                        ToolTip = 'Specifies the number of days between the invoice issue date and the payment received date. ';
                    }
                    field(LateInvoicingFileNameCtrl; LateInvoicingFileName)
                    {
                        ApplicationArea = All;
                        Caption = 'Late Invoicing File';
                        ToolTip = 'Specifies customer entries that took longer to invoice than the number of days specified in the Late Invoice Delay (Days) field.';
                        Visible = LateInvoicingFileNameCtrlVisib;
                    }
                    field(VendorExport; VendorExport)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Export Vendors';
                        ToolTip = 'Specifies that you want to export the Vendor table.';
                    }
                    field(VendorFileNameCtrl; VendorFileName)
                    {
                        ApplicationArea = All;
                        Caption = 'Vendor File';
                        ToolTip = 'Specifies the relevant vendor data for VAT auditors.';
                        Visible = VendorFileNameCtrlVisible;
                    }
                    field(VATEntryExport; VATEntryExport)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Export VAT Entries';
                        ToolTip = 'Specifies that you want to export the VAT Entry table.';
                    }
                    field(VATEntryFileNameCtrl; VATEntryFileName)
                    {
                        ApplicationArea = All;
                        Caption = 'VAT Entry File';
                        ToolTip = 'Specifies the relevant VAT entry data for VAT auditors.';
                        Visible = VATEntryFileNameCtrlVisible;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            VATEntryFileNameCtrlVisible := true;
            VendorFileNameCtrlVisible := true;
            LateInvoicingFileNameCtrlVisib := true;
            OpenPaymentFileNameCtrlVisible := true;
            CustomerFileNameCtrlVisible := true;
        end;

        trigger OnOpenPage()
        begin
            FeatureTelemetry.LogUptake('0001Q1D', VatTok, Enum::"Feature Uptake Status"::Discovered);
            if CustomerFileName = '' then
                CustomerFileName := Text1041013;
            if OpenPaymentFileName = '' then
                OpenPaymentFileName := Text1041014;
            if LateInvoicingFileName = '' then
                LateInvoicingFileName := Text1041015;
            if VendorFileName = '' then
                VendorFileName := Text1041016;
            if VATEntryFileName = '' then
                VATEntryFileName := Text1041017;
            if LateInvoiceDelay = 0 then
                LateInvoiceDelay := 14;
            CustomerFileNameCtrlVisible := false;
            OpenPaymentFileNameCtrlVisible := false;
            LateInvoicingFileNameCtrlVisib := false;
            VendorFileNameCtrlVisible := false;
            VATEntryFileNameCtrlVisible := false
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        FeatureTelemetry.LogUptake('0001Q1C', VatTok, Enum::"Feature Uptake Status"::"Set up");
        if CustomerExport and (CustomerFileName = '') then
            Error(Text1041007);

        if OpenPaymentExport and (OpenPaymentFileName = '') then
            Error(Text1041008);

        if LateInvoicingExport then begin
            if LateInvoicingFileName = '' then
                Error(Text1041009);
            if LateInvoiceDelay = 0 then
                Error(Text1041010);
        end;

        if VendorExport and (VendorFileName = '') then
            Error(Text1041011);

        if VATEntryExport and (VATEntryFileName = '') then
            Error(Text1041012);
    end;

    trigger OnPostReport()
    begin
        FeatureTelemetry.LogUptake('0001Q1A', VatTok, Enum::"Feature Uptake Status"::"Used");
        FeatureTelemetry.LogUsage('0001Q1B', VatTok, 'UK VAT Audit Report Printed');
    end;

    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        VatTok: Label 'UK Print VAT Audit Reports', Locked = true;
        Text1041000: Label 'Exporting Customers...#1##################';
        Text1041001: Label 'Exporting Open Payments...#1##################';
        Text1041002: Label 'Payment ';
        Text1041003: Label 'Invoice ';
        Text1041004: Label 'Exporting Late Invoicing Entries...#1##################';
        Text1041005: Label 'Exporting Vendors...#1##################';
        Text1041006: Label 'Exporting VAT Entries...#1##################';
        Text1041007: Label 'Please enter the Customer File name.';
        Text1041008: Label 'Please enter the Open Payments File name.';
        Text1041009: Label 'Please enter the Late Invoicing File name.';
        Text1041010: Label 'Please enter the Late Invoicing No. of Days.';
        Text1041011: Label 'Please enter the Vendor File name.';
        Text1041012: Label 'Please enter the VAT Entry File name.';
        Text1041013: Label 'C:\Customer.CSV';
        Text1041014: Label 'C:\OpenPay.CSV';
        Text1041015: Label 'C:\LateInv.CSV';
        Text1041016: Label 'C:\Vendor.CSV';
        Text1041017: Label 'C:\VATentry.CSV';
        RBMgt: Codeunit "File Management";
        Window: Dialog;
        CustomerFile: File;
        OpenPaymentFile: File;
        LateInvoicingFile: File;
        VendorFile: File;
        VATEntryFile: File;
        CustomerFileName: Text[1024];
        OpenPaymentFileName: Text[1024];
        LateInvoicingFileName: Text[1024];
        VendorFileName: Text[1024];
        VATEntryFileName: Text[1024];
        CustomerExport: Boolean;
        OpenPaymentExport: Boolean;
        LateInvoicingExport: Boolean;
        VendorExport: Boolean;
        VATEntryExport: Boolean;
        LateInvoiceDelay: Decimal;
        ToFile: Text[1024];
        CustomerFileNameCtrlVisible: Boolean;
        OpenPaymentFileNameCtrlVisible: Boolean;
        LateInvoicingFileNameCtrlVisib: Boolean;
        VendorFileNameCtrlVisible: Boolean;
        VATEntryFileNameCtrlVisible: Boolean;
        SevenDelimitedValuesTxt: Label '"%1","%2","%3","%4","%5","%6","%7"', Locked = true;
        EightDelimitedValuesTxt: Label '"%1","%2","%3","%4","%5","%6","%7","%8"', Locked = true;
        ElevenDelimitedValuesTxt: Label '"%1","%2","%3","%4","%5","%6","%7","%8","%9","%10","%11"', Locked = true;
}
#endif

