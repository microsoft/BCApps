// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.CRM.Contact;
using Microsoft.CRM.Outlook;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Attachment;
using Microsoft.Sales.Comment;
using Microsoft.Sales.Customer;
using System.Automation;

/// <summary>
/// Displays a single posted sales credit memo document with header and line details.
/// </summary>
page 134 "Posted Sales Credit Memo"
{
    Caption = 'Posted Sales Credit Memo';
    InsertAllowed = false;
    PageType = Document;
    RefreshOnActivate = true;
    SourceTable = "Sales Cr.Memo Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the posted credit memo number.';
                }
                field("Sell-to Customer No."; Rec."Sell-to Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer No.';
                    Editable = false;
                    Visible = false;
                }
                field("Sell-to Customer Name"; Rec."Sell-to Customer Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer';
                    Editable = false;
                    ShowMandatory = true;
                    TableRelation = Customer.Name;
                }
                field("Sell-to Customer Name 2"; Rec."Sell-to Customer Name 2")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Customer Name 2';
                    Editable = false;
                    Visible = false;
                }
                field("VAT Registration No."; Rec."VAT Registration No.")
                {
                    ApplicationArea = VAT;
                    Editable = false;
                    Importance = Additional;
                    Visible = false;
                }
                group("Sell-to")
                {
                    Caption = 'Sell-to';
                    field("Sell-to Address"; Rec."Sell-to Address")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Address';
                        Editable = false;
                        Importance = Additional;
                    }
                    field("Sell-to Address 2"; Rec."Sell-to Address 2")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Address 2';
                        Editable = false;
                        Importance = Additional;
                    }
                    field("Sell-to City"; Rec."Sell-to City")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'City';
                        Editable = false;
                        Importance = Additional;
                    }
                    group(Control45)
                    {
                        ShowCaption = false;
                        Visible = IsSellToCountyVisible;
                        field("Sell-to County"; Rec."Sell-to County")
                        {
                            ApplicationArea = Basic, Suite;
                            CaptionClass = '5,1,' + Rec."Sell-to Country/Region Code";
                            Editable = false;
                            Importance = Additional;
                        }
                    }
                    field("Sell-to Post Code"; Rec."Sell-to Post Code")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Post Code';
                        Editable = false;
                        Importance = Additional;
                        ToolTip = 'Specifies the postal code.';
                    }
                    field("Sell-to Country/Region Code"; Rec."Sell-to Country/Region Code")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Country/Region Code';
                        Editable = false;
                        Importance = Additional;
                    }
                    field("Sell-to Contact No."; Rec."Sell-to Contact No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Contact No.';
                        Editable = false;
                        Importance = Additional;
                    }
                    field(SellToPhoneNo; SellToContact."Phone No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Phone No.';
                        Importance = Additional;
                        Editable = false;
                        ExtendedDatatype = PhoneNo;
                        ToolTip = 'Specifies the telephone number of the contact at the customer who handles the credit memo.';
                    }
                    field(SellToMobilePhoneNo; SellToContact."Mobile Phone No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Mobile Phone No.';
                        Importance = Additional;
                        Editable = false;
                        ExtendedDatatype = PhoneNo;
                        ToolTip = 'Specifies the mobile telephone number of the contact at the customer who handles the credit memo.';
                    }
                    field(SellToEmail; SellToContact."E-Mail")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Email';
                        Importance = Additional;
                        Editable = false;
                        ExtendedDatatype = EMail;
                        ToolTip = 'Specifies the email address of the contact at the customer who handles the credit memo.';
                    }
                }
                field("Sell-to Contact"; Rec."Sell-to Contact")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Contact';
                    Editable = false;
                    ToolTip = 'Specifies the name of the person to contact when you communicate with the customer who you shipped the items on the credit memo to.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the date on which the credit memo was posted.';
                }
                field("VAT Reporting Date"; Rec."VAT Reporting Date")
                {
                    ApplicationArea = VAT;
                    Editable = false;
                    Visible = VATDateEnabled;
                    Importance = Promoted;
                }
                field("Your Reference"; Rec."Your Reference")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    Editable = false;
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                group(Control20)
                {
                    ShowCaption = false;
                    Visible = DocExchStatusVisible;
                    field("Document Exchange Status"; Rec."Document Exchange Status")
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        StyleExpr = DocExchStatusStyle;

                        trigger OnDrillDown()
                        var
                            DocExchServDocStatus: Codeunit "Doc. Exch. Serv.- Doc. Status";
                        begin
                            DocExchServDocStatus.DocExchStatusDrillDown(Rec);
                        end;
                    }
                }
                field("Pre-Assigned No."; Rec."Pre-Assigned No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Additional;
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                }
                field("Salesperson Code"; Rec."Salesperson Code")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    Importance = Additional;
                }
                field("Responsibility Center"; Rec."Responsibility Center")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    Importance = Additional;
                }
                field(Cancelled; Rec.Cancelled)
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    Style = Unfavorable;
                    StyleExpr = Rec.Cancelled;

                    trigger OnDrillDown()
                    begin
                        Rec.ShowCorrectiveInvoice();
                    end;
                }
                field(Corrective; Rec.Corrective)
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    Style = Unfavorable;
                    StyleExpr = Rec.Corrective;

                    trigger OnDrillDown()
                    begin
                        Rec.ShowCancelledInvoice();
                    end;
                }
                field("No. Printed"; Rec."No. Printed")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Additional;
                }
                group("Work Description")
                {
                    Caption = 'Work Description';
                    field(GetWorkDescription; Rec.GetWorkDescription())
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        Importance = Additional;
                        MultiLine = true;
                        ShowCaption = false;
                        ToolTip = 'Specifies the products or services being offered.';
                    }
                }
            }
            part(SalesCrMemoLines; "Posted Sales Cr. Memo Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Document No." = field("No.");
            }
            group("Invoice Details")
            {
                Caption = 'Credit Memo Details';
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                    Importance = Promoted;

                    trigger OnAssistEdit()
                    var
                        UpdateCurrencyFactor: Codeunit "Update Currency Factor";
                    begin
                        ChangeExchangeRate.SetParameter(Rec."Currency Code", Rec."Currency Factor", Rec."Posting Date");
                        ChangeExchangeRate.Editable(false);
                        if ChangeExchangeRate.RunModal() = ACTION::OK then begin
                            Rec."Currency Factor" := ChangeExchangeRate.GetParameter();
                            UpdateCurrencyFactor.ModifyPostedSalesCreditMemo(Rec);
                        end;
                        Clear(ChangeExchangeRate);
                    end;
                }
                field("Company Bank Account Code"; Rec."Company Bank Account Code")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    Importance = Promoted;
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
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    Importance = Promoted;
                }
                field("Customer Posting Group"; Rec."Customer Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Visible = false;
                }
                field("Applies-to Doc. Type"; Rec."Applies-to Doc. Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                }
                field("Applies-to Doc. No."; Rec."Applies-to Doc. No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Importance = Promoted;
                }
                field("Payment Method Code"; Rec."Payment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("EU 3-Party Trade"; Rec."EU 3-Party Trade")
                {
                    ApplicationArea = BasicEU;
                    Editable = false;
                }
                field("Tax Liable"; Rec."Tax Liable")
                {
                    ApplicationArea = SalesTax;
                    Editable = false;
                }
                field("Tax Area Code"; Rec."Tax Area Code")
                {
                    ApplicationArea = SalesTax;
                    Editable = false;
                }
                field(Correction; Rec.Correction)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
            }
            group("Shipping and Billing")
            {
                Caption = 'Shipping and Billing';
                group("Ship-to")
                {
                    Caption = 'Ship-to';
                    field("Ship-to Name"; Rec."Ship-to Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Name';
                        Editable = false;
                        ToolTip = 'Specifies the name of the customer that the items were shipped to.';
                    }
                    field("Ship-to Name 2"; Rec."Ship-to Name 2")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Name 2';
                        Editable = false;
                        Importance = Additional;
                        Visible = false;
                    }
                    field("Ship-to Address"; Rec."Ship-to Address")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Address';
                        Editable = false;
                    }
                    field("Ship-to Address 2"; Rec."Ship-to Address 2")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Address 2';
                        Editable = false;
                    }
                    field("Ship-to City"; Rec."Ship-to City")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'City';
                        Editable = false;
                    }
                    group(Control48)
                    {
                        ShowCaption = false;
                        Visible = IsShipToCountyVisible;
                        field("Ship-to County"; Rec."Ship-to County")
                        {
                            ApplicationArea = Basic, Suite;
                            CaptionClass = '5,1,' + Rec."Ship-to Country/Region Code";
                            Editable = false;
                        }
                    }
                    field("Ship-to Post Code"; Rec."Ship-to Post Code")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Post Code';
                        Editable = false;
                        ToolTip = 'Specifies the postal code.';
                    }
                    field("Ship-to Country/Region Code"; Rec."Ship-to Country/Region Code")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Country/Region';
                        Editable = false;
                    }
                    field("Ship-to Phone No."; Rec."Ship-to Phone No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Phone No.';
                        Editable = false;
                    }
                    field("Ship-to Contact"; Rec."Ship-to Contact")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Contact';
                        Editable = false;
                    }
                }
                group("Bill-to")
                {
                    Caption = 'Bill-to';
                    field("Bill-to Name"; Rec."Bill-to Name")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Name';
                        Editable = false;
                        Importance = Promoted;
                        ToolTip = 'Specifies the name of the customer that the credit memo was sent to.';
                    }
                    field("Bill-to Name 2"; Rec."Bill-to Name 2")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Name 2';
                        Editable = false;
                        Importance = Additional;
                        Visible = false;
                    }
                    field("Bill-to Address"; Rec."Bill-to Address")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Address';
                        Editable = false;
                        Importance = Additional;
                    }
                    field("Bill-to Address 2"; Rec."Bill-to Address 2")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Address 2';
                        Editable = false;
                        Importance = Additional;
                    }
                    field("Bill-to City"; Rec."Bill-to City")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'City';
                        Editable = false;
                        Importance = Additional;
                    }
                    group(Control60)
                    {
                        ShowCaption = false;
                        Visible = IsBillToCountyVisible;
                        field("Bill-to County"; Rec."Bill-to County")
                        {
                            ApplicationArea = Basic, Suite;
                            CaptionClass = '5,1,' + Rec."Bill-to Country/Region Code";
                            Editable = false;
                            Importance = Additional;
                        }
                    }
                    field("Bill-to Post Code"; Rec."Bill-to Post Code")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Post Code';
                        Editable = false;
                        Importance = Additional;
                        ToolTip = 'Specifies the postal code.';
                    }
                    field("Bill-to Country/Region Code"; Rec."Bill-to Country/Region Code")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Country/Region';
                        Editable = false;
                        Importance = Additional;
                    }
                    field("Bill-to Contact No."; Rec."Bill-to Contact No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Contact No.';
                        Editable = false;
                        Importance = Additional;
                    }
                    field(BillToContactPhoneNo; BillToContact."Phone No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Phone No.';
                        Editable = false;
                        Importance = Additional;
                        ExtendedDatatype = PhoneNo;
                        ToolTip = 'Specifies the telephone number of the contact at the customer who handles the credit memo.';
                    }
                    field(BillToContactMobilePhoneNo; BillToContact."Mobile Phone No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Mobile Phone No.';
                        Editable = false;
                        Importance = Additional;
                        ExtendedDatatype = PhoneNo;
                        ToolTip = 'Specifies the mobile telephone number of the contact at the customer who handles the credit memo.';
                    }
                    field(BillToContactEmail; BillToContact."E-Mail")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Email';
                        Editable = false;
                        Importance = Additional;
                        ExtendedDatatype = EMail;
                        ToolTip = 'Specifies the email address of the contact at the customer who handles the credit memo.';
                    }
                    field("Bill-to Contact"; Rec."Bill-to Contact")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Contact';
                        Editable = false;
                    }
                }
                group("Shipment Method")
                {
                    Caption = 'Shipment Method';
                    field("Shipment Method Code"; Rec."Shipment Method Code")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Code';
                        Editable = false;
                    }
                    field("Shipping Agent Code"; Rec."Shipping Agent Code")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Agent';
                        Editable = false;
                        Importance = Additional;
                    }
                    field("Shipping Agent Service Code"; Rec."Shipping Agent Service Code")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Agent Service';
                        Editable = false;
                        Importance = Additional;
                    }
                    field("Package Tracking No."; Rec."Package Tracking No.")
                    {
                        ApplicationArea = Suite;
                        Editable = false;
                        Importance = Additional;
                    }
                }
            }
        }
        area(factboxes)
        {
            part("Attached Documents List"; "Doc. Attachment List Factbox")
            {
                ApplicationArea = All;
                Caption = 'Documents';
                UpdatePropagation = Both;
                SubPageLink = "Table ID" = const(Database::"Sales Cr.Memo Header"),
                              "No." = field("No.");
            }
            part(IncomingDocAttachFactBox; "Incoming Doc. Attach. FactBox")
            {
                ApplicationArea = Basic, Suite;
                ShowFilter = false;
                Visible = not IsOfficeAddin;
            }
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
            group("&Cr. Memo")
            {
                Caption = '&Cr. Memo';
                Image = CreditMemo;
                action(Statistics)
                {
                    ApplicationArea = Suite;
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunObject = Page "Sales Credit Memo Statistics";
                    RunPageLink = "No." = field("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Sales Comment Sheet";
                    RunPageLink = "Document Type" = const("Posted Credit Memo"),
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
                action(DocAttach)
                {
                    ApplicationArea = All;
                    Caption = 'Attachments';
                    Image = Attach;
                    ToolTip = 'Add a file as an attachment. You can attach images as well as documents.';

                    trigger OnAction()
                    var
                        DocumentAttachmentDetails: Page "Document Attachment Details";
                        RecRef: RecordRef;
                    begin
                        RecRef.GetTable(Rec);
                        DocumentAttachmentDetails.OpenForRecRef(RecRef);
                        DocumentAttachmentDetails.RunModal();
                    end;
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("&Track Package")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Track Package';
                    Image = ItemTracking;
                    ToolTip = 'Open the shipping agent''s tracking page to track the package. ';

                    trigger OnAction()
                    begin
                        Rec.StartTrackingSite();
                    end;
                }
            }
            action(Customer)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Customer';
                Image = Customer;
                RunObject = Page "Customer Card";
                RunPageLink = "No." = field("Sell-to Customer No.");
                ShortCutKey = 'Shift+F7';
                ToolTip = 'View or edit detailed information about the customer.';
            }
            action(SendCustom)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Send';
                Ellipsis = true;
                Image = SendToMultiple;
                ToolTip = 'Prepare to send the document according to the customer''s sending profile, such as attached to an email. The Send document to window opens first so you can confirm or select a sending profile.';

                trigger OnAction()
                var
                    SalesCrMemoHeader: Record "Sales Cr.Memo Header";
                begin
                    SalesCrMemoHeader := Rec;
                    CurrPage.SetSelectionFilter(SalesCrMemoHeader);
                    SalesCrMemoHeader.SendRecords();
                end;
            }
            action(Print)
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';
                Visible = not IsOfficeAddin;

                trigger OnAction()
                begin
                    SalesCrMemoHeader := Rec;
                    CurrPage.SetSelectionFilter(SalesCrMemoHeader);
                    SalesCrMemoHeader.PrintRecords(true);
                end;
            }
            action("Send by &Email")
            {
                ApplicationArea = All;
                Caption = 'Send by &Email';
                Image = Email;
                ToolTip = 'Send the sales credit memo document as a PDF file attached to an email.';

                trigger OnAction()
                begin
                    SalesCrMemoHeader := Rec;
                    CurrPage.SetSelectionFilter(SalesCrMemoHeader);
                    SalesCrMemoHeader.EmailRecords(true);
                end;
            }
            action(AttachAsPDF)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Attach as PDF';
                Image = PrintAttachment;
                ToolTip = 'Create a PDF file and attach it to the document.';

                trigger OnAction()
                var
                    SalesCrMemoHeader: Record "Sales Cr.Memo Header";
                begin
                    SalesCrMemoHeader := Rec;
                    SalesCrMemoHeader.SetRecFilter();
                    Rec.PrintToDocumentAttachment(SalesCrMemoHeader);
                end;
            }
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Image = Navigate;
                ShortCutKey = 'Ctrl+Alt+Q';
                ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';
                Visible = not IsOfficeAddin;

                trigger OnAction()
                begin
                    Rec.Navigate();
                end;
            }
            action("Update Document")
            {
                ApplicationArea = Suite;
                Caption = 'Update Document';
                Image = Edit;
                ToolTip = 'Add new information that is relevant to the document, such as information from the shipping agent. You can only edit a few fields because the document has already been posted.';

                trigger OnAction()
                var
                    PstdSalesCrMemoUpdate: Page "Pstd. Sales Cr. Memo - Update";
                begin
                    PstdSalesCrMemoUpdate.LookupMode := true;
                    PstdSalesCrMemoUpdate.SetRec(Rec);
                    PstdSalesCrMemoUpdate.RunModal();
                end;
            }
            action(ActivityLog)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Activity Log';
                Image = Log;
                ToolTip = 'View the status and any errors if the document was sent as an electronic document or OCR file through the document exchange service.';

                trigger OnAction()
                begin
                    Rec.ShowActivityLog();
                end;
            }
            group(Cancel)
            {
                Caption = 'Cancel';
                action(CancelCrMemo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cancel';
                    Image = Cancel;
                    ToolTip = 'Create and post a sales invoice that reverses this posted sales credit memo. This posted sales credit memo will be canceled.';
                    Visible = not Rec.Cancelled and Rec.Corrective;

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"Cancel PstdSalesCrM (Yes/No)", Rec);
                    end;
                }
                action(ShowInvoice)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show Canceled/Corrective Invoice';
                    Image = Invoice;
                    Scope = Repeater;
                    ToolTip = 'Open the posted sales invoice that was created when you canceled the posted sales credit memo. If the posted sales credit memo is the result of a canceled sales invoice, then canceled invoice will open.';
                    Visible = Rec.Cancelled or Rec.Corrective;

                    trigger OnAction()
                    begin
                        Rec.ShowCanceledOrCorrInvoice();
                    end;
                }
            }
            group(IncomingDocument)
            {
                Caption = 'Incoming Document';
                Image = Documents;
                action(IncomingDocCard)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'View Incoming Document';
                    Enabled = HasIncomingDocument;
                    Image = ViewOrder;
                    ToolTip = 'View any incoming document records and file attachments that exist for the entry or document.';

                    trigger OnAction()
                    var
                        IncomingDocument: Record "Incoming Document";
                    begin
                        IncomingDocument.ShowCard(Rec."No.", Rec."Posting Date");
                    end;
                }
                action(SelectIncomingDoc)
                {
                    AccessByPermission = TableData "Incoming Document" = R;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Select Incoming Document';
                    Enabled = not HasIncomingDocument;
                    Image = SelectLineToApply;
                    ToolTip = 'Select an incoming document record and file attachment that you want to link to the entry or document.';

                    trigger OnAction()
                    var
                        IncomingDocument: Record "Incoming Document";
                    begin
                        IncomingDocument.SelectIncomingDocumentForPostedDocument(Rec."No.", Rec."Posting Date", Rec.RecordId);
                    end;
                }
                action(IncomingDocAttachFile)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Create Incoming Document from File';
                    Ellipsis = true;
                    Enabled = not HasIncomingDocument;
                    Image = Attach;
                    ToolTip = 'Create an incoming document record by selecting a file to attach, and then link the incoming document record to the entry or document.';

                    trigger OnAction()
                    var
                        IncomingDocumentAttachment: Record "Incoming Document Attachment";
                    begin
                        IncomingDocumentAttachment.NewAttachmentFromPostedDocument(Rec."No.", Rec."Posting Date");
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
                actionref("&Navigate_Promoted"; "&Navigate")
                {
                }
                group(Category_Category5)
                {
                    Caption = 'Cancel', Comment = 'Generated from the PromotedActionCategories property index 4.';
                    ShowAs = SplitButton;

                    actionref(CancelCrMemo_Promoted; CancelCrMemo)
                    {
                    }
                    actionref(ShowInvoice_Promoted; ShowInvoice)
                    {
                    }
                }
                actionref("&Track Package_Promoted"; "&Track Package")
                {
                }
            }
            group(Category_Category7)
            {
                Caption = 'Print/Send', Comment = 'Generated from the PromotedActionCategories property index 6.';

                actionref(Print_Promoted; Print)
                {
                }
                actionref("Send by &Email_Promoted"; "Send by &Email")
                {
                }
                actionref(AttachAsPDF_Promoted; AttachAsPDF)
                {
                }
                actionref(SendCustom_Promoted; SendCustom)
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Credit Memo', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref(Statistics_Promoted; Statistics)
                {
                }
                actionref(DocAttach_Promoted; DocAttach)
                {
                }
                actionref(ActivityLog_Promoted; ActivityLog)
                {
                }
                actionref(Approvals_Promoted; Approvals)
                {
                }
                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }

                separator(Navigate_Separator)
                {
                }

                actionref(Customer_Promoted; Customer)
                {
                }
            }
            group("Category_Incoming Document")
            {
                Caption = 'Incoming Document';

                actionref(IncomingDocAttachFile_Promoted; IncomingDocAttachFile)
                {
                }
                actionref(SelectIncomingDoc_Promoted; SelectIncomingDoc)
                {
                }
                actionref(IncomingDocCard_Promoted; IncomingDocCard)
                {
                }
            }
            group(Category_Category6)
            {
                Caption = 'Navigate', Comment = 'Generated from the PromotedActionCategories property index 5.';
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        IncomingDocument: Record "Incoming Document";
    begin
        HasIncomingDocument := IncomingDocument.PostedDocExists(Rec."No.", Rec."Posting Date");
        DocExchStatusStyle := Rec.GetDocExchStatusStyle();
        DocExchStatusVisible := Rec.DocExchangeStatusIsSent();
        CurrPage.IncomingDocAttachFactBox.PAGE.LoadDataFromRecord(Rec);
    end;

    trigger OnAfterGetRecord()
    begin
        DocExchStatusStyle := Rec.GetDocExchStatusStyle();
        SellToContact.GetOrClear(Rec."Sell-to Contact No.");
        BillToContact.GetOrClear(Rec."Bill-to Contact No.");
    end;

    trigger OnOpenPage()
    var
        OfficeMgt: Codeunit "Office Management";
        VATReportingDateMgt: Codeunit "VAT Reporting Date Mgt";
    begin
        Rec.SetSecurityFilterOnRespCenter();
        IsOfficeAddin := OfficeMgt.IsAvailable();

        ActivateFields();
        VATDateEnabled := VATReportingDateMgt.IsVATDateEnabled();
    end;

    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SellToContact: Record Contact;
        BillToContact: Record Contact;
        FormatAddress: Codeunit "Format Address";
        ChangeExchangeRate: Page "Change Exchange Rate";
        HasIncomingDocument: Boolean;
        DocExchStatusStyle: Text;
        DocExchStatusVisible: Boolean;
        IsOfficeAddin: Boolean;
        IsBillToCountyVisible: Boolean;
        IsSellToCountyVisible: Boolean;
        IsShipToCountyVisible: Boolean;
        VATDateEnabled: Boolean;

    local procedure ActivateFields()
    begin
        IsBillToCountyVisible := FormatAddress.UseCounty(Rec."Bill-to Country/Region Code");
        IsSellToCountyVisible := FormatAddress.UseCounty(Rec."Sell-to Country/Region Code");
        IsShipToCountyVisible := FormatAddress.UseCounty(Rec."Ship-to Country/Region Code");
    end;
}
