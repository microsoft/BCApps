// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

using Microsoft.EServices.EDocument;

pageextension 10015 "Posted Service Invoices NA" extends "Posted Service Invoices"
{
    layout
    {
        addafter("Location Code")
        {
            field("Electronic Document Status"; Rec."Electronic Document Status")
            {
                ToolTip = 'Specifies the status of the document.';
            }
            field("Date/Time Stamped"; Rec."Date/Time Stamped")
            {
                ToolTip = 'Specifies the date and time that the document received a digital stamp from the authorized service provider.';
                Visible = false;
            }
            field("Date/Time Sent"; Rec."Date/Time Sent")
            {
                ToolTip = 'Specifies the date and time that the document was sent to the customer.';
                Visible = false;
            }
            field("Date/Time Canceled"; Rec."Date/Time Canceled")
            {
                ToolTip = 'Specifies the date and time that the document was canceled.';
                Visible = false;
            }
            field("Error Code"; Rec."Error Code")
            {
                ToolTip = 'Specifies the error code that the authorized service provider, PAC, has returned to Business Central.';
                Visible = false;
            }
            field("Error Description"; Rec."Error Description")
            {
                ToolTip = 'Specifies the error message that the authorized service provider, PAC, has returned to Business Central.';
                Visible = false;
            }
        }
        modify(Amount)
        {
            Visible = false;
        }
        modify("Amount Including VAT")
        {
            Visible = false;
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
                    Caption = 'S&end';
                    Ellipsis = true;
                    Image = SendTo;
                    ToolTip = 'Send an email to the customer with the electronic service invoice attached as an XML file.';

                    trigger OnAction()
                    var
                        ServiceInvoiceHeader: Record "Service Invoice Header";
                        ProgressWindow: Dialog;
                    begin
                        CurrPage.SetSelectionFilter(ServiceInvoiceHeader);
                        ProgressWindow.Open(ProcessingInvoiceMsg);
                        if ServiceInvoiceHeader.FindSet() then
                            repeat
                                ServiceInvoiceHeader.RequestStampEDocument();
                                ProgressWindow.Update(1, ServiceInvoiceHeader."No.");
                            until ServiceInvoiceHeader.Next() = 0;
                        ProgressWindow.Close();
                    end;
                }
                action("Export E-Document as &XML")
                {
                    Caption = 'Export E-Document as &XML';
                    Image = ExportElectronicDocument;
                    ToolTip = 'Export the posted sales service invoice as an electronic service invoice, an XML file, and save it to a specified location.';

                    trigger OnAction()
                    begin
                        Rec.ExportEDocument();
                    end;
                }
                action(ExportEDocumentPDF)
                {
                    Caption = 'Export E-Document as PDF';
                    Image = ExportToBank;
                    ToolTip = 'Export the posted sales service invoice as an electronic service invoice, a PDF document, when the stamp is received.';

                    trigger OnAction()
                    begin
                        Rec.ExportEDocumentPDF();
                    end;
                }
                action("&Cancel")
                {
                    Caption = '&Cancel';
                    Image = Cancel;
                    ToolTip = 'Cancel the sending of the electronic service invoice.';

                    trigger OnAction()
                    var
                        ServiceInvoiceHeader: Record "Service Invoice Header";
                        ProgressWindow: Dialog;
                    begin
                        CurrPage.SetSelectionFilter(ServiceInvoiceHeader);
                        ProgressWindow.Open(ProcessingInvoiceMsg);
                        if ServiceInvoiceHeader.FindSet() then
                            repeat
                                ServiceInvoiceHeader.CancelEDocument();
                                ProgressWindow.Update(1, ServiceInvoiceHeader."No.");
                            until ServiceInvoiceHeader.Next() = 0;
                        ProgressWindow.Close();
                    end;
                }
                action(CFDIRelationDocuments)
                {
                    ApplicationArea = BasicMX;
                    Caption = 'CFDI Relation Documents';
                    Image = Allocations;
                    RunObject = Page "CFDI Relation Documents";
                    RunPageLink = "Document Table ID" = const(5992),
                                  "Document No." = field("No."),
                                  "Customer No." = field("Bill-to Customer No.");
                    RunPageMode = View;
                    ToolTip = 'View or add CFDI relation documents for the record.';
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
                RunObject = Page "Service Invoice Stats.";
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
    begin
        SalesTaxStatisticsVisible := Rec."Tax Area Code" <> '';
    end;

    var
        ProcessingInvoiceMsg: Label 'Processing record #1#######', Comment = '%1 = Record no';

    protected var
        SalesTaxStatisticsVisible: Boolean;

}