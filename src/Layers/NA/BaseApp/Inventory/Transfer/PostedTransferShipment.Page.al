// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Transfer;

using Microsoft.eServices.EDocument;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Inventory.Comment;
using Microsoft.Inventory.History;

page 5743 "Posted Transfer Shipment"
{
    Caption = 'Posted Transfer Shipment';
    InsertAllowed = false;
    PageType = Document;
    RefreshOnActivate = true;
    SourceTable = "Transfer Shipment Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Transfer-from Code"; Rec."Transfer-from Code")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the code of the location that items are transferred from.';
                }
                field("Transfer-to Code"; Rec."Transfer-to Code")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the code of the location that the items are transferred to.';
                }
                field("Direct Transfer"; Rec."Direct Transfer")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    ToolTip = 'Specifies that the transfer does not use an in-transit location.';
                }
                field("In-Transit Code"; Rec."In-Transit Code")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    ToolTip = 'Specifies the in-transit code for the transfer order, such as a shipping agent.';
                }
                field("Transfer Order No."; Rec."Transfer Order No.")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    Importance = Promoted;
                    Lookup = false;
                    ToolTip = 'Specifies the number of the related transfer order.';
                }
                field("Transfer Order Date"; Rec."Transfer Order Date")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    ToolTip = 'Specifies the date when the transfer order was created.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    ToolTip = 'Specifies the posting date for this document.';
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
            }
            part(TransferShipmentLines; "Posted Transfer Shpt. Subform")
            {
                ApplicationArea = Location;
                SubPageLink = "Document No." = field("No.");
            }
            group(Shipment)
            {
                Caption = 'Shipment';
                field("Shipment Date"; Rec."Shipment Date")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    ToolTip = 'Specifies when items on the document are shipped or were shipped. A shipment date is usually calculated from a requested delivery date plus lead time.';
                }
                field("Shipment Method Code"; Rec."Shipment Method Code")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    ToolTip = 'Specifies the delivery conditions of the related shipment, such as free on board (FOB).';
                }
                field("Shipping Agent Code"; Rec."Shipping Agent Code")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    ToolTip = 'Specifies the code for the shipping agent who is transporting the items.';
                }
                field("Shipping Agent Service Code"; Rec."Shipping Agent Service Code")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the code for the service, such as a one-day delivery, that is offered by the shipping agent.';
                }
                field("Receipt Date"; Rec."Receipt Date")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the receipt date of the transfer order.';
                }
            }
            group("Transfer-from")
            {
                Caption = 'Transfer-from';
                field("Transfer-from Name"; Rec."Transfer-from Name")
                {
                    ApplicationArea = Location;
                    Caption = 'Name';
                    Editable = false;
                    ToolTip = 'Specifies the name of the sender at the location that the items are transferred from.';
                }
                field("Transfer-from Name 2"; Rec."Transfer-from Name 2")
                {
                    ApplicationArea = Location;
                    Caption = 'Name 2';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies an additional part of the name of the sender at the location that the items are transferred from.';
                }
                field("Transfer-from Address"; Rec."Transfer-from Address")
                {
                    ApplicationArea = Location;
                    Caption = 'Address';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the address of the location that the items are transferred from.';
                }
                field("Transfer-from Address 2"; Rec."Transfer-from Address 2")
                {
                    ApplicationArea = Location;
                    Caption = 'Address 2';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies an additional part of the address of the location that items are transferred from.';
                }
                field("Transfer-from City"; Rec."Transfer-from City")
                {
                    ApplicationArea = Location;
                    Caption = 'City';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the city of the location that the items are transferred from.';
                }
                group(Control13)
                {
                    ShowCaption = false;
                    Visible = IsFromCountyVisible;
                    field("Transfer-from County"; Rec."Transfer-from County")
                    {
                        ApplicationArea = Location;
                        CaptionClass = '5,1,' + Rec."Trsf.-from Country/Region Code";
                        Editable = false;
                        Importance = Additional;
                    }
                }
                field("Transfer-from Post Code"; Rec."Transfer-from Post Code")
                {
                    ApplicationArea = Location;
                    Caption = 'Post Code';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the postal code of the location that the items are transferred from.';
                }
                field("Trsf.-from Country/Region Code"; Rec."Trsf.-from Country/Region Code")
                {
                    ApplicationArea = Location;
                    Caption = 'Country/Region';
                    Editable = false;
                    Importance = Additional;
                }
                field("Transfer-from Contact"; Rec."Transfer-from Contact")
                {
                    ApplicationArea = Location;
                    Caption = 'Contact';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the name of the contact person at the location that the items are transferred from.';
                }
            }
            group("Transfer-to")
            {
                Caption = 'Transfer-to';
                field("Transfer-to Name"; Rec."Transfer-to Name")
                {
                    ApplicationArea = Location;
                    Caption = 'Name';
                    Editable = false;
                    ToolTip = 'Specifies the name of the recipient at the location that the items are transferred to.';
                }
                field("Transfer-to Name 2"; Rec."Transfer-to Name 2")
                {
                    ApplicationArea = Location;
                    Caption = 'Name 2';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies an additional part of the name of the recipient at the location that the items are transferred to.';
                }
                field("Transfer-to Address"; Rec."Transfer-to Address")
                {
                    ApplicationArea = Location;
                    Caption = 'Address';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the address of the location that the items are transferred to.';
                }
                field("Transfer-to Address 2"; Rec."Transfer-to Address 2")
                {
                    ApplicationArea = Location;
                    Caption = 'Address 2';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies an additional part of the address of the location that items are transferred to.';
                }
                field("Transfer-to City"; Rec."Transfer-to City")
                {
                    ApplicationArea = Location;
                    Caption = 'City';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the city of the location that items are transferred to.';
                }
                group(Control21)
                {
                    ShowCaption = false;
                    Visible = IsToCountyVisible;
                    field("Transfer-to County"; Rec."Transfer-to County")
                    {
                        ApplicationArea = Location;
                        CaptionClass = '5,1,' + Rec."Trsf.-to Country/Region Code";
                        Editable = false;
                        Importance = Additional;
                    }
                }
                field("Transfer-to Post Code"; Rec."Transfer-to Post Code")
                {
                    ApplicationArea = Location;
                    Caption = 'Post Code';
                    Editable = false;
                    Importance = Additional;
                }
                field("Trsf.-to Country/Region Code"; Rec."Trsf.-to Country/Region Code")
                {
                    ApplicationArea = Location;
                    Caption = 'Country/Region';
                    Editable = false;
                    Importance = Additional;
                }
                field("Transfer-to Contact"; Rec."Transfer-to Contact")
                {
                    ApplicationArea = Location;
                    Caption = 'Contact';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the name of the contact person at the location that items are transferred to.';
                }
            }
            group("Foreign Trade")
            {
                Caption = 'Foreign Trade';
                field("Transaction Type"; Rec."Transaction Type")
                {
                    ApplicationArea = BasicEU, BasicNO;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the type of transaction that the document represents, for the purpose of reporting to INTRASTAT.';
                }
                field("Transaction Specification"; Rec."Transaction Specification")
                {
                    ApplicationArea = BasicEU, BasicNO;
                    Editable = false;
                    ToolTip = 'Specifies a specification of the document''s transaction, for the purpose of reporting to INTRASTAT.';
                }
                field("Transport Method"; Rec."Transport Method")
                {
                    ApplicationArea = BasicEU, BasicNO;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the transport method, for the purpose of reporting to INTRASTAT.';
                }
                field("Area"; Rec.Area)
                {
                    ApplicationArea = BasicEU, BasicNO;
                    Editable = false;
                    ToolTip = 'Specifies the area of the customer or vendor, for the purpose of reporting to INTRASTAT.';
                }
                field("Entry/Exit Point"; Rec."Entry/Exit Point")
                {
                    ApplicationArea = BasicEU, BasicNO;
                    Editable = false;
                    ToolTip = 'Specifies the code of either the port of entry at which the items passed into your country/region, or the port of exit.';
                }
                field("Partner VAT ID"; Rec."Partner VAT ID")
                {
                    ApplicationArea = BasicEU, BasicNO;
                    Editable = false;
                    ToolTip = 'Specifies the counter party''s VAT number.';
                }
            }
            group(ElectronicDocument)
            {
                Caption = 'Electronic Document';
                field("CFDI Export Code"; Rec."CFDI Export Code")
                {
                    ApplicationArea = Location, BasicMX;
                    ToolTip = 'Specifies a code to indicate if the document is used for exports to other countries.';
                }
                field("Transport Operators"; Rec."Transport Operators")
                {
                    ApplicationArea = Location, BasicMX;
                    ToolTip = 'Specifies the operator of the vehicle that transports the goods or merchandise.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Transit-from Date/Time"; Rec."Transit-from Date/Time")
                {
                    ApplicationArea = Location, BasicMX;
                    ToolTip = 'Specifies the estimated date and time at which the goods or merchandise leave the start address.';
                }
                field("Transit Hours"; Rec."Transit Hours")
                {
                    ApplicationArea = Location, BasicMX;
                    ToolTip = 'Specifies the estimated time in hours that it will take to transit from the start address to the temporary or final destination.';
                }
                field("Transit Distance"; Rec."Transit Distance")
                {
                    ApplicationArea = Location, BasicMX;
                    ToolTip = 'Specifies the distance travelled in kilometers from the start address to the temporary or final destination as a combination of the distances that are travelled by the different means of transport that move the goods or merchandise.';
                }
                field("Vehicle Code"; Rec."Vehicle Code")
                {
                    ApplicationArea = Location, BasicMX;
                    ToolTip = 'Specifies the vehicle that transports the goods or merchandise.';
                }
                field("Trailer 1"; Rec."Trailer 1")
                {
                    ApplicationArea = Location, BasicMX;
                    ToolTip = 'Specifies the trailer or semi-trailer that is used with the vehicle for the transfer of goods or merchandise.';
                }
                field("Trailer 2"; Rec."Trailer 2")
                {
                    ApplicationArea = Location, BasicMX;
                    ToolTip = 'Specifies the second trailer or semi-trailer that is used with the vehicle for the transfer of goods or merchandise.';
                }
                field(Control1310010; Rec."Foreign Trade")
                {
                    ApplicationArea = Location, BasicMX;
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
                    ToolTip = 'Specifies the USD to MXN exchange rate that is used to report foreign trade transfers to Mexican SAT authorities. This rate must match the rate used by the Mexican National Bank.';
                }
                field("SAT Customs Regime"; Rec."SAT Customs Regime")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the system that regulates the transfer of goods of foreign origin when it enters or exits the country. This information is required by Carte Porte in Mexico.';
                }
                field("SAT Transfer Reason"; Rec."SAT Transfer Reason")
                {
                    ApplicationArea = BasicMX;
                    ToolTip = 'Specifies the reason that is associated with the transfer of goods and merchandise in exports. This information is required by Carte Porte in Mexico.';
                }
                field("Insurer Name"; Rec."Insurer Name")
                {
                    ApplicationArea = Location, BasicMX;
                    ToolTip = 'Specifies the name of the insurer that covers the risks of the motor transport used for the transfer of goods or merchandise.';
                }
                field("Insurer Policy Number"; Rec."Insurer Policy Number")
                {
                    ApplicationArea = Location, BasicMX;
                    ToolTip = 'Specifies the policy number assigned by the insurer, which covers the risks of the motor transport used for the transfer of goods or merchandise.';
                }
                field("Medical Insurer Name"; Rec."Medical Insurer Name")
                {
                    ApplicationArea = Location, BasicMX;
                    ToolTip = 'Specifies the insurer that covers potential damage to the environment if the transport includes materials, residues or remnants, or hazardous waste.';
                }
                field("Medical Ins. Policy Number"; Rec."Medical Ins. Policy Number")
                {
                    ApplicationArea = Location, BasicMX;
                    ToolTip = 'Specifies the insurance policy number if the transport includes materials, residues or remnants, or hazardous waste.';
                }
                field("SAT Weight Unit Of Measure"; Rec."SAT Weight Unit Of Measure")
                {
                    ApplicationArea = Location, BasicMX;
                    ToolTip = 'Specifies the unit of measurement of the weight of the goods and / or merchandise that are moved in this transport.';
                }
                field("Electronic Document Status"; Rec."Electronic Document Status")
                {
                    ApplicationArea = Location, BasicMX;
                    ToolTip = 'Specifies the status of the document.';
                }
                field("Date/Time Stamped"; Rec."Date/Time Stamped")
                {
                    ApplicationArea = Location, BasicMX;
                    ToolTip = 'Specifies the date and time that the document received a digital stamp from the authorized service provider.';
                }
                field("Date/Time Canceled"; Rec."Date/Time Canceled")
                {
                    ApplicationArea = Location, BasicMX;
                    ToolTip = 'Specifies the date and time that the document was canceled.';
                }
                field("Error Code"; Rec."Error Code")
                {
                    ApplicationArea = Location, BasicMX;
                    ToolTip = 'Specifies the error code that the authorized service provider, PAC, has returned to Business Central.';
                }
                field("Error Description"; Rec."Error Description")
                {
                    ApplicationArea = Location, BasicMX;
                    ToolTip = 'Specifies the error message that the authorized service provider, PAC, has returned to Business Central.';
                }
                field("PAC Web Service Name"; Rec."PAC Web Service Name")
                {
                    ApplicationArea = Location, BasicMX;
                    Importance = Additional;
                    ToolTip = 'Specifies the name of the authorized service provider, PAC, which has processed the electronic document.';
                }
                field("Fiscal Invoice Number PAC"; Rec."Fiscal Invoice Number PAC")
                {
                    ApplicationArea = Location, BasicMX;
                    Importance = Additional;
                    ToolTip = 'Specifies the official invoice number for the electronic document.';
                }
                field("Identifier IdCCP"; Rec."Identifier IdCCP")
                {
                    ApplicationArea = BasicMX;
                    Importance = Additional;
                    ToolTip = 'Specifies the complement identifier (IdCCP) required for Carta Porte in Mexico. The IdCCP identifier is based on the guidelines defined in the RFC 4122 standard.';
                }
                field("CFDI Cancellation Reason Code"; Rec."CFDI Cancellation Reason Code")
                {
                    ApplicationArea = Location, BasicMX;
                    ToolTip = 'Specifies the reason for the cancellation as a code.';
                }
                field("Substitution Document No."; Rec."Substitution Document No.")
                {
                    ApplicationArea = Location, BasicMX;
                    ToolTip = 'Specifies the document number that replaces the canceled one. It is required when the cancellation reason is 01.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Shipment")
            {
                Caption = '&Shipment';
                Image = Shipment;
                action(Statistics)
                {
                    ApplicationArea = Location;
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunObject = Page "Transfer Shipment Statistics";
                    RunPageLink = "No." = field("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information about the transfer order, such as the quantity and total weight transferred.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Inventory Comment Sheet";
                    RunPageLink = "Document Type" = const("Posted Transfer Shipment"),
                                  "No." = field("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
                    end;
                }
            }
        }
        area(processing)
        {
            action("&Print")
            {
                ApplicationArea = Location;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                var
                    TransShptHeader: Record "Transfer Shipment Header";
                begin
                    CurrPage.SetSelectionFilter(TransShptHeader);
                    TransShptHeader.PrintRecords(true);
                end;
            }
            action("&Navigate")
            {
                ApplicationArea = Location;
                Caption = 'Find entries...';
                Image = Navigate;
                ShortCutKey = 'Ctrl+Alt+Q';
                ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';

                trigger OnAction()
                begin
                    Rec.Navigate();
                end;
            }
            action("Update Document")
            {
                ApplicationArea = BasicMX;
                Caption = 'Update Document';
                Image = Edit;
                ToolTip = 'Add new information that is relevant to the document. You can only edit a few fields because the document has already been posted.';

                trigger OnAction()
                var
                    PostedTransferShptUpdate: Page "Posted Transfer Shpt. - Update";
                begin
                    PostedTransferShptUpdate.LookupMode := true;
                    PostedTransferShptUpdate.SetRec(Rec);
                    PostedTransferShptUpdate.RunModal();
                end;
            }
            group("&Electronic Document")
            {
                Caption = '&Electronic Document';
                action("S&end")
                {
                    ApplicationArea = BasicMX;
                    Caption = 'S&end';
                    Ellipsis = true;
                    Image = SendTo;
                    ToolTip = 'Send an email to the customer with the electronic invoice attached as an XML file.';

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
                    ToolTip = 'Export the posted sales invoice as an electronic invoice, and XML file, and save it to a specified location.';

                    trigger OnAction()
                    begin
                        Rec.ExportEDocument();
                    end;
                }
                action("&Cancel")
                {
                    ApplicationArea = BasicMX;
                    Caption = '&Cancel';
                    Image = Cancel;
                    ToolTip = 'Cancel the sending of the electronic sales invoice.';

                    trigger OnAction()
                    begin
                        Rec.CancelEDocument();
                    end;
                }
                action("Print Carta Porte Document")
                {
                    ApplicationArea = BasicMX;
                    Caption = 'Print Carta Porte Document';
                    Image = PrintForm;
                    ToolTip = 'Prepare to print the Carta Porte document so that it can be shown upon request from inspectors or other authorities.';

                    trigger OnAction()
                    var
                        ElectronicCartaPorteMX: Report "Electronic Carta Porte MX";
                    begin
                        ElectronicCartaPorteMX.SetRecord(Rec);
                        ElectronicCartaPorteMX.Run();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref("Update Document_Promoted"; "Update Document")
                {
                }
                actionref("&Print_Promoted"; "&Print")
                {
                }
                actionref("&Navigate_Promoted"; "&Navigate")
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Shipment', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref(Statistics_Promoted; Statistics)
                {
                }
                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnOpenPage()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        IsFromCountyVisible := FormatAddress.UseCounty(Rec."Trsf.-from Country/Region Code");
        IsToCountyVisible := FormatAddress.UseCounty(Rec."Trsf.-to Country/Region Code");

        GLSetup.SetLoadFields("Multiple SAT Certificates");
        GLSetup.Get();
        SATCertInLocationEnabled := EInvoiceMgt.IsPACEnvironmentEnabled() and GLSetup."Multiple SAT Certificates";
    end;

    trigger OnAfterGetRecord()
    begin
        if SATCertInLocationEnabled then
            UpdateSATCertificateFields();
    end;

    var
        FormatAddress: Codeunit "Format Address";
        EInvoiceMgt: Codeunit "E-Invoice Mgt.";
        IsFromCountyVisible: Boolean;
        IsToCountyVisible: Boolean;
        SATCertInLocationEnabled: Boolean;
        SATCertificateCode: Text;
        SATCertificateName: Text;
        SATCertificateSource: Text;

    local procedure UpdateSATCertificateFields()
    var
        DocumentRecRef: RecordRef;
    begin
        DocumentRecRef.GetTable(Rec);
        EInvoiceMgt.GetSATCertificateInfoForDocument(DocumentRecRef, SATCertificateCode, SATCertificateName, SATCertificateSource);
    end;
}

