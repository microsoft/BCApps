// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.VAT.Ledger;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.Utilities;

/// <summary>
/// Provides printing functionality for VAT reports with formatted output layout.
/// Serves as base report structure for VAT report printing and customization.
/// </summary>
report 740 "VAT Report Print"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Finance/VAT/Reporting/VATReportPrint.rdlc';
    Caption = 'VAT Report Print';
    UseRequestPage = true;

    dataset
    {
        dataitem("VAT Report Header"; "VAT Report Header")
        {
            RequestFilterFields = "No.";
            column(USERID; UserId)
            {
            }
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(Hdr_ReportCaptionTxt; ReportCaptionTxt)
            {
            }
            column(Hdr_Page_Txt; PageTxt)
            {
            }
            column(Hdr_Page_of_Txt; PageOfTxt)
            {
            }
            column(Hdr_Date_Interval; Format("Start Date", 0, 4) + ' - ' + Format("End Date", 0, 4))
            {
            }
            column(Hdr_VAT_Report_No; "No.")
            {
            }
            column(Hdr_VAT_Report_Type; "VAT Report Type")
            {
            }
            column(Hdr_VAT_Report_Type_Label; TypeTxt)
            {
            }
            column(Hdr_VAT_Report_ReceiptNo; ReceiptNoText)
            {
            }
            column(Hdr_VAT_Report_ReceiptNo_Label; FieldCaption("Tax Auth. Receipt No."))
            {
            }
            column(Hdr_Original_Report_No; "Original Report No.")
            {
            }
            dataitem(FEInvoicesIssued; "VAT Report Line")
            {
                DataItemLink = "VAT Report No." = field("No.");
                DataItemTableView = sorting("VAT Report No.", "Line No.") where("Record Identifier" = const('FE'), "Incl. in Report" = const(true));
                column(FE_Section_Header; FESectionHdrTxt)
                {
                }
                column(FE_Document_No_Caption; FieldCaption("Document No."))
                {
                }
                column(FE_Document_Type_Caption; FieldCaption("Document Type"))
                {
                }
                column(FE_Record_identifier_Caption; VATIdentifierTxt)
                {
                }
                column(FE_Posting_Date_Caption; FieldCaption("Posting Date"))
                {
                }
                column(FE_Base_Caption; FieldCaption(Base))
                {
                }
                column(FE_Amount_Caption; FieldCaption(Amount))
                {
                }
                column(FE_Document_No; "Document No.")
                {
                }
                column(FE_Document_Type; "Document Type")
                {
                }
                column(FE_VAT_Group_Identifier; "VAT Group Identifier")
                {
                }
                column(FE_Posting_Date; Format("Posting Date", 0, 3))
                {
                }
                column(FE_Base; Format(Base, 0, DecimalFormatTxt))
                {
                }
                column(FE_Amount; Format(Amount, 0, DecimalFormatTxt))
                {
                }
                column(FE_SubTotal_Label; SubTotalTxt)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    TotalBase[ConstGroup::FE] += Base;
                    TotalAmount[ConstGroup::FE] += Amount;
                end;
            }
            dataitem(FRInvoicesReceived; "VAT Report Line")
            {
                DataItemLink = "VAT Report No." = field("No.");
                DataItemTableView = sorting("VAT Report No.", "Line No.") where("Record Identifier" = const('FR'), "Incl. in Report" = const(true));
                column(FR_Section_Header; FRSectionHdrTxt)
                {
                }
                column(FR_Document_No_Caption; FieldCaption("Document No."))
                {
                }
                column(FR_Document_Type_Caption; FieldCaption("Document Type"))
                {
                }
                column(FR_Record_identifier_Caption; VATIdentifierTxt)
                {
                }
                column(FR_Posting_Date_Caption; FieldCaption("Posting Date"))
                {
                }
                column(FR_Base_Caption; FieldCaption(Base))
                {
                }
                column(FR_Amount_Caption; FieldCaption(Amount))
                {
                }
                column(FR_Document_No; "Document No.")
                {
                }
                column(FR_Document_Type; "Document Type")
                {
                }
                column(FR_VAT_Group_Identifier; "VAT Group Identifier")
                {
                }
                column(FR_Posting_Date; Format("Posting Date", 0, 3))
                {
                }
                column(FR_Base; Format(Base, 0, DecimalFormatTxt))
                {
                }
                column(FR_Amount; Format(Amount, 0, DecimalFormatTxt))
                {
                }
                column(FR_SubTotal_Label; SubTotalTxt)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    TotalBase[ConstGroup::FR] += Base;
                    TotalAmount[ConstGroup::FR] += Amount;
                end;
            }
            dataitem(NECreditMemoIssued; "VAT Report Line")
            {
                DataItemLink = "VAT Report No." = field("No.");
                DataItemTableView = sorting("VAT Report No.", "Line No.") where("Record Identifier" = const('NE'), "Incl. in Report" = const(true));
                column(NE_Section_Header; NESectionHdrTxt)
                {
                }
                column(NE_Document_No_Caption; FieldCaption("Document No."))
                {
                }
                column(NE_Document_Type_Caption; FieldCaption("Document Type"))
                {
                }
                column(NE_Record_identifier_Caption; VATIdentifierTxt)
                {
                }
                column(NE_Posting_Date_Caption; FieldCaption("Posting Date"))
                {
                }
                column(NE_Base_Caption; FieldCaption(Base))
                {
                }
                column(NE_Amount_Caption; FieldCaption(Amount))
                {
                }
                column(NE_Document_No; "Document No.")
                {
                }
                column(NE_Document_Type; "Document Type")
                {
                }
                column(NE_VAT_Group_Identifier; "VAT Group Identifier")
                {
                }
                column(NE_Posting_Date; Format("Posting Date", 0, 3))
                {
                }
                column(NE_Base; Format(Base, 0, DecimalFormatTxt))
                {
                }
                column(NE_Amount; Format(Amount, 0, DecimalFormatTxt))
                {
                }
                column(NE_SubTotal_Label; SubTotalTxt)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    TotalBase[ConstGroup::NE] += Base;
                    TotalAmount[ConstGroup::NE] += Amount;
                end;
            }
            dataitem(NRCreditMemoReceived; "VAT Report Line")
            {
                DataItemLink = "VAT Report No." = field("No.");
                DataItemTableView = sorting("VAT Report No.", "Line No.") where("Record Identifier" = const('NR'), "Incl. in Report" = const(true));
                column(NR_Section_Header; NRSectionHdrTxt)
                {
                }
                column(NR_Document_No_Caption; FieldCaption("Document No."))
                {
                }
                column(NR_Document_Type_Caption; FieldCaption("Document Type"))
                {
                }
                column(NR_Record_identifier_Caption; VATIdentifierTxt)
                {
                }
                column(NR_Posting_Date_Caption; FieldCaption("Posting Date"))
                {
                }
                column(NR_Base_Caption; FieldCaption(Base))
                {
                }
                column(NR_Amount_Caption; FieldCaption(Amount))
                {
                }
                column(NR_Document_No; "Document No.")
                {
                }
                column(NR_Document_Type; "Document Type")
                {
                }
                column(NR_VAT_Group_Identifier; "VAT Group Identifier")
                {
                }
                column(NR_Posting_Date; Format("Posting Date", 0, 3))
                {
                }
                column(NR_Base; Format(Base, 0, DecimalFormatTxt))
                {
                }
                column(NR_Amount; Format(Amount, 0, DecimalFormatTxt))
                {
                }
                column(NR_SubTotal_Label; SubTotalTxt)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    TotalBase[ConstGroup::NR] += Base;
                    TotalAmount[ConstGroup::NR] += Amount;
                end;
            }
            dataitem(FNNonResidentSales; "VAT Report Line")
            {
                DataItemLink = "VAT Report No." = field("No.");
                DataItemTableView = sorting("VAT Report No.", "Line No.") where("Record Identifier" = const('FN'), "Incl. in Report" = const(true));
                column(FN_Section_Header; FNSectionHdrTxt)
                {
                }
                column(FN_Document_No_Caption; FieldCaption("Document No."))
                {
                }
                column(FN_Document_Type_Caption; FieldCaption("Document Type"))
                {
                }
                column(FN_Record_identifier_Caption; VATIdentifierTxt)
                {
                }
                column(FN_Posting_Date_Caption; FieldCaption("Posting Date"))
                {
                }
                column(FN_Base_Caption; FieldCaption(Base))
                {
                }
                column(FN_Amount_Caption; FieldCaption(Amount))
                {
                }
                column(FN_Document_No; "Document No.")
                {
                }
                column(FN_Document_Type; "Document Type")
                {
                }
                column(FN_VAT_Group_Identifier; "VAT Group Identifier")
                {
                }
                column(FN_Posting_Date; Format("Posting Date", 0, 3))
                {
                }
                column(FN_Base; Format(Base, 0, DecimalFormatTxt))
                {
                }
                column(FN_Amount; Format(Amount, 0, DecimalFormatTxt))
                {
                }
                column(FN_SubTotal_Label; SubTotalTxt)
                {
                }
                dataitem(FNVATEntry; "VAT Entry")
                {
                    DataItemLink = "Entry No." = field("VAT Entry No.");
                    DataItemTableView = sorting("Entry No.");
                    column(FN_First_Name; "First Name")
                    {
                    }
                    column(FN_Last_Name; "Last Name")
                    {
                    }
                    column(FN_Company_Name; VATEntryCompanyName)
                    {
                    }

                    trigger OnAfterGetRecord()
                    var
                        Customer: Record Customer;
                        Vendor: Record Vendor;
                    begin
                        VATEntryCompanyName := '';
                        case Type of
                            Type::Purchase:
                                if Vendor.Get("Bill-to/Pay-to No.") then
                                    VATEntryCompanyName := Vendor.Name;
                            Type::Sale:
                                if Customer.Get("Bill-to/Pay-to No.") then
                                    VATEntryCompanyName := Customer.Name;
                        end;
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    TotalBase[ConstGroup::FN] += Base;
                    TotalAmount[ConstGroup::FN] += Amount;
                end;
            }
            dataitem(SENonResidentPurchase; "VAT Report Line")
            {
                DataItemLink = "VAT Report No." = field("No.");
                DataItemTableView = sorting("VAT Report No.", "Line No.") where("Record Identifier" = const('SE'), "Incl. in Report" = const(true));
                column(SE_Section_Header; SESectionHdrTxt)
                {
                }
                column(SE_Document_No_Caption; FieldCaption("Document No."))
                {
                }
                column(SE_Document_Type_Caption; FieldCaption("Document Type"))
                {
                }
                column(SE_Record_identifier_Caption; VATIdentifierTxt)
                {
                }
                column(SE_Posting_Date_Caption; FieldCaption("Posting Date"))
                {
                }
                column(SE_Base_Caption; FieldCaption(Base))
                {
                }
                column(SE_Amount_Caption; FieldCaption(Amount))
                {
                }
                column(SE_Document_No; "Document No.")
                {
                }
                column(SE_Document_Type; "Document Type")
                {
                }
                column(SE_VAT_Group_Identifier; "VAT Group Identifier")
                {
                }
                column(SE_Posting_Date; Format("Posting Date", 0, 3))
                {
                }
                column(SE_Base; Format(Base, 0, DecimalFormatTxt))
                {
                }
                column(SE_Amount; Format(Amount, 0, DecimalFormatTxt))
                {
                }
                column(SE_SubTotal_Label; SubTotalTxt)
                {
                }
                dataitem(SEVATEntry; "VAT Entry")
                {
                    DataItemLink = "Entry No." = field("VAT Entry No.");
                    DataItemTableView = sorting("Entry No.");
                    column(SE_First_Name; "First Name")
                    {
                    }
                    column(SE_Last_Name; "Last Name")
                    {
                    }
                    column(SE_Company_Name; VATEntryCompanyName)
                    {
                    }

                    trigger OnAfterGetRecord()
                    var
                        Customer: Record Customer;
                        Vendor: Record Vendor;
                    begin
                        VATEntryCompanyName := '';
                        case Type of
                            Type::Purchase:
                                if Vendor.Get("Bill-to/Pay-to No.") then
                                    VATEntryCompanyName := Vendor.Name;
                            Type::Sale:
                                if "Reverse Sales VAT" then
                                    if Vendor.Get("Bill-to/Pay-to No.") then
                                        VATEntryCompanyName := Vendor.Name
                                    else
                                        if Customer.Get("Bill-to/Pay-to No.") then
                                            VATEntryCompanyName := Customer.Name;
                        end;
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    TotalBase[ConstGroup::SE] += Base;
                    TotalAmount[ConstGroup::SE] += Amount;
                end;
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(FE_Total_Base; Format(TotalBase[ConstGroup::FE], 0, DecimalFormatTxt))
                {
                }
                column(FE_Total_Amount; Format(TotalAmount[ConstGroup::FE], 0, DecimalFormatTxt))
                {
                }
                column(FR_Total_Base; Format(TotalBase[ConstGroup::FR], 0, DecimalFormatTxt))
                {
                }
                column(FR_Total_Amount; Format(TotalAmount[ConstGroup::FR], 0, DecimalFormatTxt))
                {
                }
                column(NR_Total_Base; Format(TotalBase[ConstGroup::NR], 0, DecimalFormatTxt))
                {
                }
                column(NR_Total_Amount; Format(TotalAmount[ConstGroup::NR], 0, DecimalFormatTxt))
                {
                }
                column(NE_Total_Base; Format(TotalBase[ConstGroup::NE], 0, DecimalFormatTxt))
                {
                }
                column(NE_Total_Amount; Format(TotalAmount[ConstGroup::NE], 0, DecimalFormatTxt))
                {
                }
                column(FN_Total_Base; Format(TotalBase[ConstGroup::FN], 0, DecimalFormatTxt))
                {
                }
                column(FN_Total_Amount; Format(TotalAmount[ConstGroup::FN], 0, DecimalFormatTxt))
                {
                }
                column(SE_Total_Base; Format(TotalBase[ConstGroup::SE], 0, DecimalFormatTxt))
                {
                }
                column(SE_Total_Amount; Format(TotalAmount[ConstGroup::SE], 0, DecimalFormatTxt))
                {
                }

                trigger OnAfterGetRecord()
                var
                    I: Integer;
                begin
                    for I := 1 to 6 do begin
                        TotalBase[ConstGroup::Total] += TotalBase[I];
                        TotalAmount[ConstGroup::Total] += TotalAmount[I];
                    end;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if "VAT Report Header"."Tax Auth. Receipt No." = '' then
                    ReceiptNoText := NotApplicableTxt
                else
                    ReceiptNoText := Format("VAT Report Header"."Tax Auth. Receipt No.");
            end;

            trigger OnPreDataItem()
            var
            begin
                if Count > 1 then
                    Error(MultipleReportsErr);
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        ReportCaptionTxt: Label 'VAT Entry Transmission Report';
        VATIdentifierTxt: Label 'VAT Identifier';
        TotalBase: array[7] of Decimal;
        TotalAmount: array[7] of Decimal;
        SubTotalTxt: Label 'Subtotal';
        FESectionHdrTxt: Label 'Issued Invoices (Residents)';
        FRSectionHdrTxt: Label 'Received Invoices (Residents)';
        NESectionHdrTxt: Label 'Issued Credit Memos (Residents)';
        NRSectionHdrTxt: Label 'Received Credit Memos (Residents)';
        FNSectionHdrTxt: Label 'Sales (Nonresidents)';
        SESectionHdrTxt: Label 'Purchase (Nonresidents)';
        PageTxt: Label 'Page';
        PageOfTxt: Label 'of';
        TypeTxt: Label 'Report type';
        NotApplicableTxt: Label 'Not assigned';
        ReceiptNoText: Text;
        DecimalFormatTxt: Label '<sign><Integer Thousand><Decimals,3><Precision,2:2>', Locked = true;
        ConstGroup: Option ,FE,FR,NE,NR,FN,SE,Total;
        VATEntryCompanyName: Text;
        MultipleReportsErr: Label 'You can print one report at a time.';
}

