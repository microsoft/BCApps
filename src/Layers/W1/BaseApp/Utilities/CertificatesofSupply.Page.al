// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

page 780 "Certificates of Supply"
{
    ApplicationArea = Basic, Suite, Service;
    Caption = 'Certificates of Supply';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Certificate of Supply";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the type of the posted document to which the certificate of supply applies.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the document number of the posted shipment document associated with the certificate of supply.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status for documents where you must receive a signed certificate of supply from the customer.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Receipt Date"; Rec."Receipt Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the receipt date of the signed certificate of supply.';
                }
                field(Printed; Rec.Printed)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies whether the certificate of supply has been printed and sent to the customer.';
                }
                field("Customer/Vendor Name"; Rec."Customer/Vendor Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the customer or vendor.';
                }
                field("Shipment Date"; Rec."Shipment/Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date that the posted shipment was shipped or posted.';
                }
                field("Shipment Country"; Rec."Ship-to Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region code of the address that the items are shipped to.';
                }
                field("Customer/Vendor No."; Rec."Customer/Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the customer or vendor.';
                }
                field("Shipment Method"; Rec."Shipment Method Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the delivery conditions of the related shipment, such as free on board (FOB).';
                }
                field("Vehicle Registration No."; Rec."Vehicle Registration No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vehicle registration number associated with the shipment.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(PrintCertificateofSupply)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Print Certificate of Supply';
                Image = PrintReport;
                ToolTip = 'Print the certificate of supply that you must send to your customer for signature as confirmation of receipt.';

                trigger OnAction()
                var
                    CertificateOfSupply: Record "Certificate of Supply";
                begin
                    if not Rec.IsEmpty() then begin
                        CertificateOfSupply.Copy(Rec);
                        CertificateOfSupply.SetRange("Document Type", Rec."Document Type");
                        CertificateOfSupply.SetRange("Document No.", Rec."Document No.");
                    end;
                    CertificateOfSupply.Print();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(PrintCertificateofSupply_Promoted; PrintCertificateofSupply)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        if Rec.GetFilters = '' then
            Rec.SetFilter(Status, '<>%1', Rec.Status::"Not Applicable")
        else
            if Rec."Document No." <> '' then
                Rec.InitRecord(Rec."Document Type".AsInteger(), Rec."Document No.")
    end;
}

