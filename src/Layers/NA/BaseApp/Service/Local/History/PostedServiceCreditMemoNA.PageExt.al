// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

using Microsoft.EServices.EDocument;
using Microsoft.Finance.GeneralLedger.Setup;

pageextension 10012 "Posted Service Credit Memo NA" extends "Posted Service Credit Memo"
{
    layout
    {
        addafter("Foreign Trade")
        {
            group("Electronic Invoice")
            {
                Caption = 'Electronic Invoice';
                field("CFDI Purpose"; Rec."CFDI Purpose")
                {
                    ApplicationArea = BasicMX;
                    Importance = Additional;
                    ToolTip = 'Specifies the CFDI purpose required for reporting to the Mexican tax authorities (SAT).';
                }
                field("CFDI Relation"; Rec."CFDI Relation")
                {
                    ApplicationArea = BasicMX;
                    Importance = Additional;
                    ToolTip = 'Specifies the relation of the CFDI document. ';
                }
                field("CFDI Period"; Rec."CFDI Period")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the period to use when reporting for general public customers';
                }
                field("SAT Address ID"; Rec."SAT Address ID")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the SAT address that the goods or merchandise are moved to.';
                    BlankZero = true;
                }
                field("CFDI Export Code"; Rec."CFDI Export Code")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies a code to indicate if the document is used for exports to other countries.';
                }
                field("CFDI Certificate of Origin No."; Rec."CFDI Certificate of Origin No.")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the identifier which was used to pay for the issuance of the certificate of origin.';
                }
                field(Control1310005; Rec."Foreign Trade")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies whether the goods or merchandise that are transported enter or leave the national territory.';
                }
                field("SAT International Trade Term"; Rec."SAT International Trade Term")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies an international commercial terms code that are used in international sale contracts according to the SAT internatoinal trade terms definition.';
                }
                field("SAT Certificate Name"; SATCertificateName)
                {
                    ApplicationArea = BasicMX;
                    Caption = 'SAT Certificate Name';
                    ToolTip = 'Specifies the name of the certificate that is used to sign the e-document.';
                    Visible = SATCertInLocationEnabled;
                    Editable = false;

                    trigger OnDrillDown()
                    begin
                        EInvoiceMgt.DrillDownSATCertificate(SATCertificateCode);
                    end;
                }
                field("SAT Certificate Source"; SATCertificateSource)
                {
                    ApplicationArea = BasicMX;
                    Caption = 'SAT Certificate Source';
                    ToolTip = 'Specifies the record with which the certificate is associated, such as General Ledger Setup or a specific Location (e.g., Location BLUE).';
                    Visible = SATCertInLocationEnabled;
                    Editable = false;
                }
                field("Exchange Rate USD"; Rec."Exchange Rate USD")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the USD to MXN exchange rate that is used to report foreign trade documents to Mexican SAT authorities. This rate must match the rate used by the Mexican National Bank.';
                }
                field("Electronic Document Status"; Rec."Electronic Document Status")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the status of the document.';
                }
                field("Date/Time Stamped"; Rec."Date/Time Stamped")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the date and time that the document received a digital stamp from the authorized service provider.';
                }
                field("Date/Time Sent"; Rec."Date/Time Sent")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the date and time that the document was sent to the customer.';
                }
                field("Date/Time Canceled"; Rec."Date/Time Canceled")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the date and time that the document was canceled.';
                }
                field("Error Code"; Rec."Error Code")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the error code that the authorized service provider, PAC, has returned to Business Central.';
                }
                field("Error Description"; Rec."Error Description")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the error message that the authorized service provider, PAC, has returned to Business Central.';
                }
                field("PAC Web Service Name"; Rec."PAC Web Service Name")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the name of the authorized service provider, PAC, which has processed the electronic document.';
                }
                field("Fiscal Invoice Number PAC"; Rec."Fiscal Invoice Number PAC")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the official invoice number for the electronic document.';
                }
                field("No. of E-Documents Sent"; Rec."No. of E-Documents Sent")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the number of times that this document has been sent electronically.';
                }
                field("CFDI Cancellation Reason Code"; Rec."CFDI Cancellation Reason Code")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the reason for the cancellation as a code.';
                }
                field("Substitution Document No."; Rec."Substitution Document No.")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the document number that replaces the canceled one. It is required when the cancellation reason is 01.';
                }
            }
        }
    }
    actions
    {
        addbefore(SendCustom)
        {
            group("&Electronic Document")
            {
                Caption = '&Electronic Document';
                action("S&end")
                {
                    ApplicationArea = BasicMX;
                    Caption = 'S&end';
                    Ellipsis = true;
                    Image = SendTo;
                    ToolTip = 'Send an email to the customer with the electronic service credit memo attached as an XML file.';

                    trigger OnAction()
                    begin
                        Rec.RequestStampEDocument();
                    end;
                }
                action("Export E-Document as &XML")
                {
                    ApplicationArea = BasicMX;
                    Caption = 'Export E-Document as &XML';
                    Image = ExportElectronicDocument;
                    ToolTip = 'Export the posted service credit memo as an electronic credit memo, an XML file, and save it to a specified location.';

                    trigger OnAction()
                    begin
                        Rec.ExportEDocument();
                    end;
                }
                action(ExportEDocumentPDF)
                {
                    ApplicationArea = BasicMX;
                    Caption = 'Export E-Document as PDF';
                    Image = ExportToBank;
                    ToolTip = 'Export the posted service credit memo as an electronic credit memo, a PDF document, when the stamp is received.';

                    trigger OnAction()
                    begin
                        Rec.ExportEDocumentPDF();
                    end;
                }
                action(CFDIRelationDocuments)
                {
                    ApplicationArea = BasicMX;
                    Caption = 'CFDI Relation Documents';
                    Image = Allocations;
                    RunObject = Page "CFDI Relation Documents";
                    RunPageLink = "Document Table ID" = const(5994),
                                  "Document No." = field("No."),
                                  "Customer No." = field("Bill-to Customer No.");
                    RunPageMode = View;
                    ToolTip = 'View or add CFDI relation documents for the record.';
                }
                action("&Cancel")
                {
                    ApplicationArea = BasicMX;
                    Caption = '&Cancel';
                    Image = Cancel;
                    ToolTip = 'Cancel the sending of the electronic service credit memo.';

                    trigger OnAction()
                    begin
                        Rec.CancelEDocument();
                    end;
                }
            }
        }
        addafter(ServiceStatistics)
        {
            action(ServiceStats)
            {
                ApplicationArea = Service;
                Caption = 'Statistics';
                Image = Statistics;
                ShortCutKey = 'F7';
                ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
#if CLEAN27
                    Visible = SalesTaxStatisticsVisible;
#else
                Visible = false;
#endif
                RunObject = Page "Service Credit Memo Stats.";
                RunPageOnRec = true;
            }
        }
#if CLEAN27
        addafter(ServiceStatistics_Promoted)
        {
            actionref(ServiceStats_Promoted; ServiceStats)
            {
            }
        }
#endif
    }

    trigger OnOpenPage()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.SetLoadFields("Multiple SAT Certificates");
        GLSetup.Get();
        SATCertInLocationEnabled := EInvoiceMgt.IsPACEnvironmentEnabled() and GLSetup."Multiple SAT Certificates";
        SalesTaxStatisticsVisible := Rec."Tax Area Code" <> '';
    end;

    trigger OnAfterGetRecord()
    begin
        if SATCertInLocationEnabled then
            UpdateSATCertificateFields();
    end;

    var
        EInvoiceMgt: Codeunit "E-Invoice Mgt.";
        SATCertInLocationEnabled: Boolean;
        SATCertificateCode: Text;
        SATCertificateName: Text;
        SATCertificateSource: Text;

    protected var
        SalesTaxStatisticsVisible: Boolean;

    local procedure UpdateSATCertificateFields()
    var
        DocumentRecRef: RecordRef;
    begin
        DocumentRecRef.GetTable(Rec);
        EInvoiceMgt.GetSATCertificateInfoForDocument(DocumentRecRef, SATCertificateCode, SATCertificateName, SATCertificateSource);
    end;
}