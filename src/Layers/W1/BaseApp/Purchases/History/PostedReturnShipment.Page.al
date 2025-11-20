// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

using Microsoft.CRM.Contact;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Address;
using Microsoft.Purchases.Comment;
using Microsoft.Utilities;
using System.Automation;

page 6650 "Posted Return Shipment"
{
    Caption = 'Posted Return Shipment';
    InsertAllowed = false;
    PageType = Document;
    RefreshOnActivate = true;
    SourceTable = "Return Shipment Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = PurchReturnOrder;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Buy-from Vendor No."; Rec."Buy-from Vendor No.")
                {
                    ApplicationArea = PurchReturnOrder;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the name of the vendor who delivered the items.';
                }
                field("Buy-from Contact No."; Rec."Buy-from Contact No.")
                {
                    ApplicationArea = PurchReturnOrder;
                    Editable = false;
                    ToolTip = 'Specifies the number of the contact person at the vendor who delivered the items.';
                }
                group("Buy-from")
                {
                    Caption = 'Buy-from';
                    field("Buy-from Vendor Name"; Rec."Buy-from Vendor Name")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Name';
                        Editable = false;
                        ToolTip = 'Specifies the name of the vendor who delivered the items.';
                    }
                    field("Buy-from Vendor Name 2"; Rec."Buy-from Vendor Name 2")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Name 2';
                        Editable = false;
                        Importance = Additional;
                        Visible = false;
                    }
                    field("Buy-from Address"; Rec."Buy-from Address")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Address';
                        Editable = false;
                        ToolTip = 'Specifies the address of the vendor who delivered the items.';
                    }
                    field("Buy-from Address 2"; Rec."Buy-from Address 2")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Address 2';
                        Editable = false;
                        ToolTip = 'Specifies an additional part of the address of the vendor who delivered the items.';
                    }
                    field("Buy-from City"; Rec."Buy-from City")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'City';
                        Editable = false;
                        ToolTip = 'Specifies the city of the vendor who delivered the items.';
                    }
                    group(Control13)
                    {
                        ShowCaption = false;
                        Visible = IsBuyFromCountyVisible;
                        field("Buy-from County"; Rec."Buy-from County")
                        {
                            ApplicationArea = PurchReturnOrder;
                            CaptionClass = '5,1,' + Rec."Buy-from Country/Region Code";
                            Editable = false;
                        }
                    }
                    field("Buy-from Post Code"; Rec."Buy-from Post Code")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Post Code';
                        Editable = false;
                        ToolTip = 'Specifies the post code of the vendor who delivered the items.';
                    }
                    field("Buy-from Country/Region Code"; Rec."Buy-from Country/Region Code")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Country/Region';
                        Editable = false;
                    }
                    field("Buy-from Contact"; Rec."Buy-from Contact")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Contact';
                        Editable = false;
                        ToolTip = 'Specifies the name of the contact person at the vendor who delivered the items.';
                    }
                    field(BuyFromContactPhoneNo; BuyFromContact."Phone No.")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Phone No.';
                        Importance = Additional;
                        Editable = false;
                        ExtendedDatatype = PhoneNo;
                        ToolTip = 'Specifies the telephone number of the vendor contact person.';
                    }
                    field(BuyFromContactMobilePhoneNo; BuyFromContact."Mobile Phone No.")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Mobile Phone No.';
                        Importance = Additional;
                        Editable = false;
                        ExtendedDatatype = PhoneNo;
                        ToolTip = 'Specifies the mobile telephone number of the vendor contact person.';
                    }
                    field(BuyFromContactEmail; BuyFromContact."E-Mail")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Email';
                        Importance = Additional;
                        Editable = false;
                        ExtendedDatatype = EMail;
                        ToolTip = 'Specifies the email address of the vendor contact person.';
                    }
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = PurchReturnOrder;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = PurchReturnOrder;
                    Editable = false;
                    ToolTip = 'Specifies the date when the related document was created.';
                }
                field("Return Order No."; Rec."Return Order No.")
                {
                    ApplicationArea = PurchReturnOrder;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the return order that will post a return shipment.';
                }
                field("Vendor Authorization No."; Rec."Vendor Authorization No.")
                {
                    ApplicationArea = PurchReturnOrder;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the identification number of a compensation agreement.';
                }
                field("Order Address Code"; Rec."Order Address Code")
                {
                    ApplicationArea = PurchReturnOrder;
                    Editable = false;
                    ToolTip = 'Specifies the order address of the related customer.';
                }
                field("Purchaser Code"; Rec."Purchaser Code")
                {
                    ApplicationArea = PurchReturnOrder;
                    Editable = false;
                    ToolTip = 'Specifies which purchaser is assigned to the vendor.';
                }
                field("Responsibility Center"; Rec."Responsibility Center")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies the code of the responsibility center, such as a distribution hub, that is associated with the involved user, company, customer, or vendor.';
                }
                field("No. Printed"; Rec."No. Printed")
                {
                    ApplicationArea = PurchReturnOrder;
                    Editable = false;
                    ToolTip = 'Specifies how many times the document has been printed.';
                }
            }
            part(ReturnShptLines; "Posted Return Shipment Subform")
            {
                ApplicationArea = PurchReturnOrder;
                SubPageLink = "Document No." = field("No.");
            }
            group(Invoicing)
            {
                Caption = 'Invoicing';
                field("Pay-to Vendor No."; Rec."Pay-to Vendor No.")
                {
                    ApplicationArea = PurchReturnOrder;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the vendor that you received the invoice from.';
                }
                field("Pay-to Contact No."; Rec."Pay-to Contact No.")
                {
                    ApplicationArea = PurchReturnOrder;
                    Editable = false;
                    ToolTip = 'Specifies the number of the person to contact about an invoice from this customer.';
                }
                group(Control15)
                {
                    ShowCaption = false;
                    field("Pay-to Name"; Rec."Pay-to Name")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Name';
                        Editable = false;
                        ToolTip = 'Specifies the name of the customer who you received the invoice from.';
                    }
                    field("Pay-to Name 2"; Rec."Pay-to Name 2")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Name 2';
                        Editable = false;
                        Importance = Additional;
                        Visible = false;
                    }
                    field("Pay-to Address"; Rec."Pay-to Address")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Address';
                        Editable = false;
                        ToolTip = 'Specifies the address of the vendor that you received the invoice from.';
                    }
                    field("Pay-to Address 2"; Rec."Pay-to Address 2")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Address 2';
                        Editable = false;
                        ToolTip = 'Specifies an additional part of the address of the customer that the invoice was shipped to.';
                    }
                    field("Pay-to City"; Rec."Pay-to City")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'City';
                        Editable = false;
                        ToolTip = 'Specifies the city of the customer that you shipped the invoice to.';
                    }
                    group(Control23)
                    {
                        ShowCaption = false;
                        Visible = IsPayFromCountyVisible;
                        field("Pay-to County"; Rec."Pay-to County")
                        {
                            ApplicationArea = PurchReturnOrder;
                            CaptionClass = '5,1,' + Rec."Pay-to Country/Region Code";
                            Editable = false;
                        }
                    }
                    field("Pay-to Post Code"; Rec."Pay-to Post Code")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Post Code';
                        Editable = false;
                        ToolTip = 'Specifies the post code of the customer that you received the invoice from.';
                    }
                    field("Pay-to Country/Region Code"; Rec."Pay-to Country/Region Code")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Country/Region';
                        Editable = false;
                    }
                    field("Pay-to Contact"; Rec."Pay-to Contact")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Contact';
                        Editable = false;
                        ToolTip = 'Specifies the name of the person to contact about an invoice from this customer.';
                    }
                    field(PayToContactPhoneNo; PayToContact."Phone No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Phone No.';
                        Editable = false;
                        Importance = Additional;
                        ExtendedDatatype = PhoneNo;
                        ToolTip = 'Specifies the telephone number of the vendor contact person.';
                    }
                    field(PayToContactMobilePhoneNo; PayToContact."Mobile Phone No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Mobile Phone No.';
                        Editable = false;
                        Importance = Additional;
                        ExtendedDatatype = PhoneNo;
                        ToolTip = 'Specifies the mobile telephone number of the vendor contact person.';
                    }
                    field(PayToContactEmail; PayToContact."E-Mail")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Email';
                        Editable = false;
                        Importance = Additional;
                        ExtendedDatatype = Email;
                        ToolTip = 'Specifies the email address of the vendor contact person.';
                    }
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
                field("Applies-to Doc. Type"; Rec."Applies-to Doc. Type")
                {
                    ApplicationArea = PurchReturnOrder;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the type of the posted document that this document or journal line will be applied to when you post, for example to register payment.';
                }
                field("Applies-to Doc. No."; Rec."Applies-to Doc. No.")
                {
                    ApplicationArea = PurchReturnOrder;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the posted document that this document or journal line will be applied to when you post, for example to register payment.';
                }
            }
            group(Shipping)
            {
                Caption = 'Shipping';
                group("Ship-to")
                {
                    Caption = 'Ship-to';
                    field("Ship-to Name"; Rec."Ship-to Name")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Name';
                        Editable = false;
                        ToolTip = 'Specifies the name of the customer at the address that the items are shipped to.';
                    }
                    field("Ship-to Name 2"; Rec."Ship-to Name 2")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Name 2';
                        Editable = false;
                        Importance = Additional;
                        ToolTip = 'Specifies an additional part of the name of the customer at the address that the items are shipped to.';
                        Visible = false;
                    }
                    field("Ship-to Address"; Rec."Ship-to Address")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Address';
                        Editable = false;
                        ToolTip = 'Specifies the address that the items are shipped to.';
                    }
                    field("Ship-to Address 2"; Rec."Ship-to Address 2")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Address 2';
                        Editable = false;
                        ToolTip = 'Specifies an additional part of the ship-to address, in case it is a long address.';
                    }
                    field("Ship-to City"; Rec."Ship-to City")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'City';
                        Editable = false;
                        ToolTip = 'Specifies the city of the address that the items are shipped to.';
                    }
                    group(Control35)
                    {
                        ShowCaption = false;
                        Visible = IsShipToCountyVisible;
                        field("Ship-to County"; Rec."Ship-to County")
                        {
                            ApplicationArea = PurchReturnOrder;
                            CaptionClass = '5,1,' + Rec."Ship-to Country/Region Code";
                            Editable = false;
                        }
                    }
                    field("Ship-to Post Code"; Rec."Ship-to Post Code")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Post Code';
                        Editable = false;
                        ToolTip = 'Specifies the postal code of the address that the items are shipped to.';
                    }
                    field("Ship-to Country/Region Code"; Rec."Ship-to Country/Region Code")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Country/Region';
                        Editable = false;
                        ToolTip = 'Specifies the country or region of the ship-to address.';
                    }
                    field("Ship-to Phone No."; Rec."Ship-to Phone No.")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Phone No.';
                        Editable = false;
                        ToolTip = 'Specifies the telephone number of the company''s shipping address.';
                    }
                    field("Ship-to Contact"; Rec."Ship-to Contact")
                    {
                        ApplicationArea = PurchReturnOrder;
                        Caption = 'Contact';
                        Editable = false;
                        ToolTip = 'Specifies the name of the contact person at the address that the items are shipped to.';
                    }
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = PurchReturnOrder;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the location from where inventory items to the customer on the sales document are to be shipped by default.';
                }
            }
            group("Foreign Trade")
            {
                Caption = 'Foreign Trade';
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = PurchReturnOrder;
                    Importance = Promoted;
                    ToolTip = 'Specifies the currency that is used on the entry.';

                    trigger OnAssistEdit()
                    begin
                        ChangeExchangeRate.SetParameter(Rec."Currency Code", Rec."Currency Factor", Rec."Posting Date");
                        ChangeExchangeRate.Editable(false);
                        if ChangeExchangeRate.RunModal() = ACTION::OK then begin
                            Rec."Currency Factor" := ChangeExchangeRate.GetParameter();
                            Rec.Modify();
                        end;
                        Clear(ChangeExchangeRate);
                    end;
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
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Return Shpt.")
            {
                Caption = '&Return Shpt.';
                Image = Shipment;
                action(Statistics)
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunObject = Page "Return Shipment Statistics";
                    RunPageLink = "No." = field("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
                action("Co&mments")
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Purch. Comment Sheet";
                    RunPageLink = "Document Type" = const("Posted Return Shipment"),
                                  "No." = field("No."),
                                  "Document Line No." = const(0);
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
                action(Approvals)
                {
                    AccessByPermission = TableData "Posted Approval Entry" = R;
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Approvals';
                    Image = Approvals;
                    ToolTip = 'View a list of the records that are waiting to be approved. For example, you can see who requested the record to be approved, when it was sent, and when it is due to be approved.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.ShowPostedApprovalEntries(Rec.RecordId);
                    end;
                }
            }
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action(DocumentLineTracking)
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Document &Line Tracking';
                    Image = Navigate;
                    ToolTip = 'View related open, posted, or archived documents or document lines.';

                    trigger OnAction()
                    begin
                        CurrPage.ReturnShptLines.PAGE.ShowDocumentLineTracking();
                    end;
                }
                action(CertificateOfSupplyDetails)
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Certificate of Supply Details';
                    Image = Certificate;
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = Process;
                    RunObject = Page "Certificates of Supply";
                    RunPageLink = "Document Type" = filter("Return Shipment"),
                                  "Document No." = field("No.");
                    ToolTip = 'View the certificate of supply that you must send to your customer for signature as confirmation of receipt. You must print a certificate of supply if the shipment uses a combination of VAT business posting group and VAT product posting group that have been marked to require a certificate of supply in the VAT Posting Setup window.';
                }
                action(PrintCertificateofSupply)
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Print Certificate of Supply';
                    Image = PrintReport;
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = Process;
                    ToolTip = 'Print the certificate of supply that you must send to your customer for signature as confirmation of receipt.';

                    trigger OnAction()
                    var
                        CertificateOfSupply: Record "Certificate of Supply";
                    begin
                        CertificateOfSupply.SetRange("Document Type", CertificateOfSupply."Document Type"::"Return Shipment");
                        CertificateOfSupply.SetRange("Document No.", Rec."No.");
                        CertificateOfSupply.Print();
                    end;
                }
            }
        }
        area(processing)
        {
            action("&Print")
            {
                ApplicationArea = PurchReturnOrder;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                begin
                    ReturnShptHeader := Rec;
                    OnBeforePrintRecords(Rec, ReturnShptHeader);
                    CurrPage.SetSelectionFilter(ReturnShptHeader);
                    ReturnShptHeader.PrintRecords(true);
                end;
            }
            action("&Navigate")
            {
                ApplicationArea = PurchReturnOrder;
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
                ApplicationArea = PurchReturnOrder;
                Caption = 'Update Document';
                Image = Edit;
                ToolTip = 'Add new information that is relevant to the document, such as the country or region. You can only edit a few fields because the document has already been posted.';

                trigger OnAction()
                var
                    PostedReturnShptUpdate: Page "Posted Return Shpt. - Update";
                begin
                    PostedReturnShptUpdate.LookupMode := true;
                    PostedReturnShptUpdate.SetRec(Rec);
                    PostedReturnShptUpdate.RunModal();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Print_Promoted"; "&Print")
                {
                }
                actionref("&Navigate_Promoted"; "&Navigate")
                {
                }
                actionref("Update Document_Promoted"; "Update Document")
                {
                }
            }
            group(Category_Shipment)
            {
                Caption = 'Shipment';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref(Statistics_Promoted; Statistics)
                {
                }
                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }
                actionref(Approvals_Promoted; Approvals)
                {
                }
            }
            group("Category_Certificate of Supply")
            {
                Caption = 'Certificate of Supply';

                actionref(PrintCertificateofSupply_Promoted; PrintCertificateofSupply)
                {
                }
                actionref(CertificateOfSupplyDetails_Promoted; CertificateOfSupplyDetails)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnOpenPage(Rec, IsHandled);
        if IsHandled then
            exit;

        Rec.SetSecurityFilterOnRespCenter();

        ActivateFields();
    end;

    trigger OnAfterGetRecord()
    begin
        BuyFromContact.GetOrClear(Rec."Buy-from Contact No.");
        PayToContact.GetOrClear(Rec."Pay-to Contact No.");
    end;

    var
        ReturnShptHeader: Record "Return Shipment Header";
        BuyFromContact: Record Contact;
        PayToContact: Record Contact;
        FormatAddress: Codeunit "Format Address";
        ChangeExchangeRate: Page "Change Exchange Rate";
        IsShipToCountyVisible: Boolean;
        IsPayFromCountyVisible: Boolean;
        IsBuyFromCountyVisible: Boolean;

    local procedure ActivateFields()
    begin
        IsBuyFromCountyVisible := FormatAddress.UseCounty(Rec."Buy-from Country/Region Code");
        IsPayFromCountyVisible := FormatAddress.UseCounty(Rec."Pay-to Country/Region Code");
        IsShipToCountyVisible := FormatAddress.UseCounty(Rec."Ship-to Country/Region Code");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintRecords(var ReturnShipmentHeaderRec: Record "Return Shipment Header"; var ReturnShipmentHeaderToPrint: Record "Return Shipment Header")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeOnOpenPage(var ReturnShipmentHeader: Record "Return Shipment Header"; var IsHandled: Boolean)
    begin
    end;
}

