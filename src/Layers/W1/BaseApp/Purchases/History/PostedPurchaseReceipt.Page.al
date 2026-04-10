// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

using Microsoft.CRM.Contact;
using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Address;
using Microsoft.Purchases.Comment;
using System.Automation;

page 136 "Posted Purchase Receipt"
{
    Caption = 'Posted Purchase Receipt';
    InsertAllowed = false;
    PageType = Document;
    SourceTable = "Purch. Rcpt. Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    Importance = Promoted;
                }
                field("Buy-from Vendor No."; Rec."Buy-from Vendor No.")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    Importance = Promoted;
                }
                field("Buy-from Contact No."; Rec."Buy-from Contact No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
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
                group("Buy-from")
                {
                    Caption = 'Buy-from';
                    field("Buy-from Vendor Name"; Rec."Buy-from Vendor Name")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Name';
                        Editable = false;
                    }
                    field("Buy-from Vendor Name 2"; Rec."Buy-from Vendor Name 2")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Name 2';
                        Editable = false;
                        Importance = Additional;
                        Visible = false;
                    }
                    field("Buy-from Address"; Rec."Buy-from Address")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Address';
                        Editable = false;
                    }
                    field("Buy-from Address 2"; Rec."Buy-from Address 2")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Address 2';
                        Editable = false;
                    }
                    field("Buy-from City"; Rec."Buy-from City")
                    {
                        ApplicationArea = Suite;
                        Caption = 'City';
                        Editable = false;
                    }
                    group(Control11)
                    {
                        ShowCaption = false;
                        Visible = IsBuyFromCountyVisible;
                        field("Buy-from County"; Rec."Buy-from County")
                        {
                            ApplicationArea = Suite;
                            CaptionClass = '5,1,' + Rec."Buy-from Country/Region Code";
                            Editable = false;
                        }
                    }
                    field("Buy-from Post Code"; Rec."Buy-from Post Code")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Post Code';
                        Editable = false;
                    }
                    field("Buy-from Country/Region Code"; Rec."Buy-from Country/Region Code")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Country/Region';
                        Editable = false;
                    }
                    field("Buy-from Contact"; Rec."Buy-from Contact")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Contact';
                        Editable = false;
                    }
                }
                field("No. Printed"; Rec."No. Printed")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the posting date of the record.';
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date when the purchase document was created.';
                }
                field("Requested Receipt Date"; Rec."Requested Receipt Date")
                {
                    ApplicationArea = Suite;
                }
                field("Promised Receipt Date"; Rec."Promised Receipt Date")
                {
                    ApplicationArea = OrderPromising;
                }
                field("Quote No."; Rec."Quote No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Order No."; Rec."Order No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Vendor Order No."; Rec."Vendor Order No.")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    Importance = Promoted;
                }
                field("Vendor Shipment No."; Rec."Vendor Shipment No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Order Address Code"; Rec."Order Address Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Purchaser Code"; Rec."Purchaser Code")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                }
                field("Responsibility Center"; Rec."Responsibility Center")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                }
            }
            part(PurchReceiptLines; "Posted Purchase Rcpt. Subform")
            {
                ApplicationArea = Suite;
                SubPageLink = "Document No." = field("No.");
            }
            group(Invoicing)
            {
                Caption = 'Invoicing';
                field("Pay-to Vendor No."; Rec."Pay-to Vendor No.")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    Importance = Promoted;
                }
                field("Pay-to Contact no."; Rec."Pay-to Contact no.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
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
                group("Pay-to")
                {
                    Caption = 'Pay-to';
                    field("Pay-to Name"; Rec."Pay-to Name")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Name';
                        Editable = false;
                    }
                    field("Pay-to Name 2"; Rec."Pay-to Name 2")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Name 2';
                        Editable = false;
                        Importance = Additional;
                        Visible = false;
                    }
                    field("Pay-to Address"; Rec."Pay-to Address")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Address';
                        Editable = false;
                    }
                    field("Pay-to Address 2"; Rec."Pay-to Address 2")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Address 2';
                        Editable = false;
                    }
                    field("Pay-to City"; Rec."Pay-to City")
                    {
                        ApplicationArea = Suite;
                        Caption = 'City';
                        Editable = false;
                    }
                    group(Control19)
                    {
                        ShowCaption = false;
                        Visible = IsPayToCountyVisible;
                        field("Pay-to County"; Rec."Pay-to County")
                        {
                            ApplicationArea = Suite;
                            CaptionClass = '5,1,' + Rec."Pay-to Country/Region Code";
                            Editable = false;
                        }
                    }
                    field("Pay-to Post Code"; Rec."Pay-to Post Code")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Post Code';
                        Editable = false;
                    }
                    field("Pay-to Country/Region Code"; Rec."Pay-to Country/Region Code")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Country/Region';
                        Editable = false;
                    }
                    field("Pay-to Contact"; Rec."Pay-to Contact")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Contact';
                        Editable = false;
                        ToolTip = 'Specifies the contact person at the vendor that you received the invoice from.';
                    }
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
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
                        ApplicationArea = Suite;
                        Caption = 'Name';
                        Editable = false;
                    }
                    field("Ship-to Name 2"; Rec."Ship-to Name 2")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Name 2';
                        Editable = false;
                        Importance = Additional;
                        Visible = false;
                    }
                    field("Ship-to Address"; Rec."Ship-to Address")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Address';
                        Editable = false;
                    }
                    field("Ship-to Address 2"; Rec."Ship-to Address 2")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Address 2';
                        Editable = false;
                    }
                    field("Ship-to City"; Rec."Ship-to City")
                    {
                        ApplicationArea = Suite;
                        Caption = 'City';
                        Editable = false;
                    }
                    group(Control29)
                    {
                        ShowCaption = false;
                        Visible = IsShipToCountyVisible;
                        field("Ship-to County"; Rec."Ship-to County")
                        {
                            ApplicationArea = Suite;
                            CaptionClass = '5,1,' + Rec."Ship-to Country/Region Code";
                            Editable = false;
                        }
                    }
                    field("Ship-to Post Code"; Rec."Ship-to Post Code")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Post Code';
                        Editable = false;
                    }
                    field("Ship-to Country/Region Code"; Rec."Ship-to Country/Region Code")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Country/Region';
                        Editable = false;
                    }
                    field("Ship-to Phone No."; Rec."Ship-to Phone No.")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Phone No.';
                        Editable = false;
                    }
                    field("Ship-to Contact"; Rec."Ship-to Contact")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Contact';
                        Editable = false;
                    }
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    Importance = Promoted;
                }
                field("Inbound Whse. Handling Time"; Rec."Inbound Whse. Handling Time")
                {
                    ApplicationArea = Warehouse;
                }
                field("Shipment Method Code"; Rec."Shipment Method Code")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                }
                field("Lead Time Calculation"; Rec."Lead Time Calculation")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Expected Receipt Date"; Rec."Expected Receipt Date")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    Importance = Promoted;
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
            group("&Receipt")
            {
                Caption = '&Receipt';
                Image = Receipt;
                action(Statistics)
                {
                    ApplicationArea = Suite;
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunObject = Page "Purchase Receipt Statistics";
                    RunPageLink = "No." = field("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Suite;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Purch. Comment Sheet";
                    RunPageLink = "Document Type" = const(Receipt),
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
                    ApplicationArea = Suite;
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
        }
        area(processing)
        {
            action("&Print")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                begin
                    PurchRcptHeader := Rec;
                    OnBeforePrintRecords(Rec, PurchRcptHeader);
                    CurrPage.SetSelectionFilter(PurchRcptHeader);
                    PurchRcptHeader.PrintRecords(true);
                end;
            }
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Image = Navigate;
                ShortCutKey = 'Ctrl+Alt+Q';
                ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';

                trigger OnAction()
                begin
                    Rec.Navigate();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref("&Print_Promoted"; "&Print")
                {
                }
                actionref("&Navigate_Promoted"; "&Navigate")
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Print/Send', Comment = 'Generated from the PromotedActionCategories property index 4.';

            }
            group(Category_Category4)
            {
                Caption = 'Receipt', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref(Statistics_Promoted; Statistics)
                {
                }
                actionref(Approvals_Promoted; Approvals)
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
    begin
        Rec.SetSecurityFilterOnRespCenter();

        ActivateFields();
    end;

    trigger OnAfterGetRecord()
    begin
        BuyFromContact.GetOrClear(Rec."Buy-from Contact No.");
        PayToContact.GetOrClear(Rec."Pay-to Contact No.");
    end;

    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        BuyFromContact: Record Contact;
        PayToContact: Record Contact;
        FormatAddress: Codeunit "Format Address";
        IsBuyFromCountyVisible: Boolean;
        IsPayToCountyVisible: Boolean;
        IsShipToCountyVisible: Boolean;

    local procedure ActivateFields()
    begin
        IsBuyFromCountyVisible := FormatAddress.UseCounty(Rec."Buy-from Country/Region Code");
        IsPayToCountyVisible := FormatAddress.UseCounty(Rec."Pay-to Country/Region Code");
        IsShipToCountyVisible := FormatAddress.UseCounty(Rec."Ship-to Country/Region Code");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintRecords(PurchRcptHeaderRec: Record "Purch. Rcpt. Header"; var ToPrint: Record "Purch. Rcpt. Header")
    begin
    end;
}

