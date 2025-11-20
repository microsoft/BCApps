// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.Reporting;
using Microsoft.Sales.Customer;
using Microsoft.Service.Comment;

page 9322 "Service Contract Quotes"
{
    ApplicationArea = Service;
    Caption = 'Service Contract Quotes';
    CardPageID = "Service Contract Quote";
    Editable = false;
    PageType = List;
    SourceTable = "Service Contract Header";
    SourceTableView = where("Contract Type" = const(Quote));
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Contract No."; Rec."Contract No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the service contract or service contract quote.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the status of the service contract or contract quote.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a description of the service contract.';
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the customer who owns the service items in the service contract/contract quote.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the name of the customer in the service contract.';
                    Visible = false;
                }
                field("Ship-to Code"; Rec."Ship-to Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a code for an alternate shipment address if you want to ship to another address than the one that has been entered automatically. This field is also used in case of drop shipment.';
                }
                field("Ship-to Name"; Rec."Ship-to Name")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the name of the customer at the address that the items are shipped to.';
                    Visible = false;
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the starting date of the service contract.';
                }
                field("Expiration Date"; Rec."Expiration Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when the service contract expires.';
                }
            }
        }
        area(factboxes)
        {
#if not CLEAN25
            part("Attached Documents"; "Document Attachment Factbox")
            {
                ObsoleteTag = '25.0';
                ObsoleteState = Pending;
                ObsoleteReason = 'The "Document Attachment FactBox" has been replaced by "Doc. Attachment List Factbox", which supports multiple files upload.';
                ApplicationArea = Service;
                Caption = 'Attachments';
                Visible = false;
                SubPageLink = "Table ID" = const(Database::"Service Contract Header"),
                              "Document Type" = const("Service Contract Quote"),
                              "No." = field("Contract No.");
            }
#endif
            part("Attached Documents List"; "Doc. Attachment List Factbox")
            {
                ApplicationArea = Service;
                Caption = 'Documents';
                UpdatePropagation = Both;
                SubPageLink = "Table ID" = const(Database::"Service Contract Header"),
                              "Document Type" = const("Service Contract Quote"),
                              "No." = field("Contract No.");
            }
            part(Control1902018507; "Customer Statistics FactBox")
            {
                ApplicationArea = Service;
                SubPageLink = "No." = field("Bill-to Customer No."),
                              "Date Filter" = field("Date Filter");
                Visible = true;
            }
            part(Control1900316107; "Customer Details FactBox")
            {
                ApplicationArea = Service;
                SubPageLink = "No." = field("Customer No."),
                              "Date Filter" = field("Date Filter");
                Visible = true;
            }
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
            group("&Quote")
            {
                Caption = '&Quote';
                Image = Quote;
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
                        Rec.ShowDocDim();
                        CurrPage.SaveRecord();
                    end;
                }
                action("Co&mments")
                {
                    ApplicationArea = Service;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Service Comment Sheet";
                    RunPageLink = "Table Name" = const("Service Contract"),
                                  "Table Subtype" = field("Contract Type"),
                                  "No." = field("Contract No."),
                                  "Table Line No." = const(0);
                    ToolTip = 'View or add comments for the record.';
                }
                action("Service Dis&counts")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Dis&counts';
                    Image = Discount;
                    RunObject = Page "Contract/Service Discounts";
                    RunPageLink = "Contract Type" = field("Contract Type"),
                                  "Contract No." = field("Contract No.");
                    ToolTip = 'View or edit the discounts that you grant for the contract on spare parts in particular service item groups, the discounts on resource hours for resources in particular resource groups, and the discounts on particular service costs.';
                }
                action("Service &Hours")
                {
                    ApplicationArea = Service;
                    Caption = 'Service &Hours';
                    Image = ServiceHours;
                    RunObject = Page "Service Hours";
                    RunPageLink = "Service Contract No." = field("Contract No."),
                                  "Service Contract Type" = filter(Quote);
                    ToolTip = 'View the service hours that are valid for the service contract. This window displays the starting and ending service hours for the contract for each weekday.';
                }
                action("&Filed Contract Quotes")
                {
                    ApplicationArea = Service;
                    Caption = '&Filed Contract Quotes';
                    Image = Quote;
                    RunObject = Page "Filed Service Contract List";
                    RunPageLink = "Contract Type Relation" = field("Contract Type"),
                                  "Contract No. Relation" = field("Contract No.");
                    RunPageView = sorting("Contract Type Relation", "Contract No. Relation", "File Date", "File Time")
                                  order(descending);
                    ToolTip = 'View filed contract quotes.';
                }
            }
        }
        area(processing)
        {
            action("&Make Contract")
            {
                ApplicationArea = Service;
                Caption = '&Make Contract';
                Image = MakeAgreement;
                ToolTip = 'Prepare to create a service contract.';

                trigger OnAction()
                var
                    SignServContractDoc: Codeunit SignServContractDoc;
                begin
                    CurrPage.Update(true);
                    SignServContractDoc.SignContractQuote(Rec);
                end;
            }
            action("&Print")
            {
                ApplicationArea = Service;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                var
                    ServDocumentPrint: Codeunit "Serv. Document Print";
                begin
                    ServDocumentPrint.PrintServiceContract(Rec);
                end;
            }
            action(AttachAsPDF)
            {
                ApplicationArea = Service;
                Caption = 'Attach as PDF';
                Ellipsis = true;
                Image = PrintAttachment;
                ToolTip = 'Create a PDF file and attach it to the document.';

                trigger OnAction()
                var
                    ServiceContractHeader: Record "Service Contract Header";
                    ServDocumentPrint: Codeunit "Serv. Document Print";
                begin
                    ServiceContractHeader := Rec;
                    ServiceContractHeader.SetRecFilter();
                    ServDocumentPrint.PrintServiceContractToDocumentAttachment(ServiceContractHeader);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                group(Category_CategoryPrint)
                {
                    ShowAs = SplitButton;

                    actionref("&Print_Promoted"; "&Print")
                    {
                    }
                    actionref(AttachAsPDF_Promoted; AttachAsPDF)
                    {
                    }
                }
                actionref("&Make Contract_Promoted"; "&Make Contract")
                {
                }
                group(Category_Quote)
                {
                    Caption = 'Quote';

                    actionref(Dimensions_Promoted; Dimensions)
                    {
                    }
                    actionref("Co&mments_Promoted"; "Co&mments")
                    {
                    }
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetSecurityFilterOnRespCenter();
    end;
}

