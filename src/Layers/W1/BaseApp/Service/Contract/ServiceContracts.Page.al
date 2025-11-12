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
using Microsoft.Service.Document;
using Microsoft.Service.Ledger;
using Microsoft.Service.Reports;

page 9321 "Service Contracts"
{
    ApplicationArea = Service;
    Caption = 'Service Contracts';
    CardPageID = "Service Contract";
    Editable = false;
    PageType = List;
    AboutTitle = 'About Service Contracts';
    AboutText = 'Manage service contracts with customers, including creating, updating, and evaluating agreements, adjusting service pricing and discounts, tracking service hours, and handling contract status, billing, and automatic credit memos for removed contract lines.';
    SourceTable = "Service Contract Header";
    SourceTableView = where("Contract Type" = const(Contract));
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
                field("Bill-to Customer No."; Rec."Bill-to Customer No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the customer that you send or sent the invoice or credit memo to.';
                    Visible = false;
                }
                field("Bill-to Name"; Rec."Bill-to Name")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the name of the customer that you send or sent the invoice or credit memo to.';
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
                field("Change Status"; Rec."Change Status")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies if a service contract or contract quote is locked or open for changes.';
                    Visible = false;
                }
                field("Payment Terms Code"; Rec."Payment Terms Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a formula that calculates the payment due date, payment discount date, and payment discount amount.';
                    Visible = false;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the currency used to calculate the amounts in the documents related to this contract.';
                    Visible = false;
                }
                field("First Service Date"; Rec."First Service Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date of the first expected service for the service items in the contract.';
                    Visible = false;
                }
                field("Service Order Type"; Rec."Service Order Type")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the service order type assigned to service orders linked to this contract.';
                    Visible = false;
                }
                field("Invoice Period"; Rec."Invoice Period")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the invoice period for the service contract.';
                    Visible = false;
                }
                field("Next Price Update Date"; Rec."Next Price Update Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the next date you want contract prices to be updated.';
                    Visible = false;
                }
                field("Last Price Update Date"; Rec."Last Price Update Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date you last updated the contract prices.';
                    Visible = false;
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
                              "Document Type" = const("Service Contract"),
                              "No." = field("Contract No.");
            }
#endif
            part("Attached Documents List"; "Doc. Attachment List Factbox")
            {
                ApplicationArea = Service;
                Caption = 'Documents';
                UpdatePropagation = Both;
                SubPageLink = "Table ID" = const(Database::"Service Contract Header"),
                              "Document Type" = const("Service Contract"),
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
            group("&Contract")
            {
                Caption = '&Contract';
                Image = Agreement;
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
                action("Service Ledger E&ntries")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Ledger E&ntries';
                    Image = ServiceLedger;
                    RunObject = Page "Service Ledger Entries";
                    RunPageLink = "Service Contract No." = field("Contract No.");
                    RunPageView = sorting("Service Contract No.");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View all the ledger entries for the service item or service order that result from posting transactions in service documents.';
                }
                action("&Warranty Ledger Entries")
                {
                    ApplicationArea = Service;
                    Caption = '&Warranty Ledger Entries';
                    Image = WarrantyLedger;
                    RunObject = Page "Warranty Ledger Entries";
                    RunPageLink = "Service Contract No." = field("Contract No.");
                    RunPageView = sorting("Service Contract No.", "Posting Date", "Document No.");
                    ToolTip = 'View all the ledger entries for the service item or service order that result from posting transactions in service documents that contain warranty agreements.';
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
                                  "Service Contract Type" = filter(Contract);
                    ToolTip = 'View the service hours that are valid for the service contract. This window displays the starting and ending service hours for the contract for each weekday.';
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
                group(Statistics)
                {
                    Caption = 'Statistics';
                    Image = Statistics;
                    action(Action1102601013)
                    {
                        ApplicationArea = Service;
                        Caption = 'Statistics';
                        Image = Statistics;
                        RunObject = Page "Contract Statistics";
                        RunPageLink = "Contract Type" = const(Contract),
                                      "Contract No." = field("Contract No.");
                        ShortCutKey = 'F7';
                        ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                    }
                    action("Tr&endscape")
                    {
                        ApplicationArea = Service;
                        Caption = 'Tr&endscape';
                        Image = Trendscape;
                        RunObject = Page "Contract Trendscape";
                        RunPageLink = "Contract Type" = const(Contract),
                                      "Contract No." = field("Contract No.");
                        ToolTip = 'View a detailed account of service item transactions by time intervals.';
                    }
                }
                action("Filed Contracts")
                {
                    ApplicationArea = Service;
                    Caption = 'Filed Contracts';
                    Image = Agreement;
                    RunObject = Page "Filed Service Contract List";
                    RunPageLink = "Contract Type Relation" = field("Contract Type"),
                                  "Contract No. Relation" = field("Contract No.");
                    RunPageView = sorting("Contract Type Relation", "Contract No. Relation", "File Date", "File Time")
                                  order(descending);
                    ToolTip = 'View service contracts that are filed.';
                }
                group("Ser&vice Overview")
                {
                    Caption = 'Ser&vice Overview';
                    Image = Tools;
                    action("Service Orders")
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Orders';
                        Image = Document;
                        RunObject = Page "Service List";
                        RunPageLink = "Document Type" = const(Order),
                                      "Contract No." = field("Contract No.");
                        RunPageView = sorting("Contract No.");
                        ToolTip = 'Open the list of ongoing service orders.';
                    }
                    action("Posted Service Invoices")
                    {
                        ApplicationArea = Service;
                        Caption = 'Posted Service Invoices';
                        Image = PostedServiceOrder;
                        RunObject = Page "Service Document Registers";
                        RunPageLink = "Source Document No." = field("Contract No.");
                        RunPageView = sorting("Source Document Type", "Source Document No.", "Destination Document Type", "Destination Document No.")
                                      where("Source Document Type" = const(Contract),
                                            "Destination Document Type" = const("Posted Invoice"));
                        ToolTip = 'Open the list of posted service invoices.';
                    }
                }
                action("C&hange Log")
                {
                    ApplicationArea = Service;
                    Caption = 'C&hange Log';
                    Image = ChangeLog;
                    RunObject = Page "Contract Change Log";
                    RunPageLink = "Contract No." = field("Contract No.");
                    RunPageView = sorting("Contract No.")
                                  order(descending);
                    ToolTip = 'View all changes that have been made to the service contract.';
                }
                action("&Gain/Loss Entries")
                {
                    ApplicationArea = Service;
                    Caption = '&Gain/Loss Entries';
                    Image = GainLossEntries;
                    RunObject = Page "Contract Gain/Loss Entries";
                    RunPageLink = "Contract No." = field("Contract No.");
                    RunPageView = sorting("Contract No.", "Change Date")
                                  order(descending);
                    ToolTip = 'View the contract number, reason code, contract group code, responsibility center, customer number, ship-to code, customer name, and type of change, as well as the contract gain and loss. You can print all your service contract gain/loss entries.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Si&gn Contract")
                {
                    ApplicationArea = Service;
                    Caption = 'Si&gn Contract';
                    Image = Signature;
                    ToolTip = 'Confirm the contract.';

                    trigger OnAction()
                    var
                        SignServContractDoc: Codeunit SignServContractDoc;
                    begin
                        CurrPage.Update();
                        SignServContractDoc.SignContract(Rec);
                        CurrPage.Update();
                    end;
                }
                action("&Lock Contract")
                {
                    ApplicationArea = Service;
                    Caption = '&Lock Contract';
                    Image = Lock;
                    ToolTip = 'Make sure that the changes will be part of the contract.';

                    trigger OnAction()
                    var
                        LockOpenServContract: Codeunit "Lock-OpenServContract";
                    begin
                        CurrPage.Update();
                        LockOpenServContract.LockServContract(Rec);
                        CurrPage.Update();
                    end;
                }
                action("&Open Contract")
                {
                    ApplicationArea = Service;
                    Caption = '&Open Contract';
                    Image = ReOpen;
                    ToolTip = 'Open the service contract.';

                    trigger OnAction()
                    var
                        LockOpenServContract: Codeunit "Lock-OpenServContract";
                    begin
                        CurrPage.Update();
                        LockOpenServContract.OpenServContract(Rec);
                        CurrPage.Update();
                    end;
                }
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
        area(reporting)
        {
            action("Contract, Service Order Test")
            {
                ApplicationArea = Service;
                Caption = 'Contract, Service Order Test';
                Image = "Report";
                RunObject = Report "Contr. Serv. Orders - Test";
                ToolTip = 'View the numbers of contracts, the numbers and the names of customers, as well as some other information relating to the service orders that are created for the period that you have specified. You can test which service contracts include service items that are due for service within the specified period.';
            }
            action("Maintenance Visit - Planning")
            {
                ApplicationArea = Service;
                Caption = 'Maintenance Visit - Planning';
                Image = "Report";
                RunObject = Report "Maintenance Visit - Planning";
                ToolTip = 'View the service zone code, group code, contract number, customer number, service period, as well as the service date. You can select the schedule for one or more responsibility centers. The report shows the service dates of all the maintenance visits for the chosen responsibility centers. You can print all your schedules for maintenance visits.';
            }
            action("Service Contract Details")
            {
                ApplicationArea = Service;
                Caption = 'Service Contract Details';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Service Contract-Detail";
                ToolTip = 'View detailed information for the service contract.';
            }
            action("Service Contract Profit")
            {
                ApplicationArea = Service;
                Caption = 'Service Contract Profit';
                Image = "Report";
                RunObject = Report "Service Profit (Contracts)";
                ToolTip = 'View profit information for the service contract.';
            }
            action("Contract Invoice Test")
            {
                ApplicationArea = Service;
                Caption = 'Contract Invoice Test';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Contract Invoicing";
                ToolTip = 'Specifies billable profits for the project task that are related to items.';
            }
            action("Service Contract-Customer")
            {
                ApplicationArea = Service;
                Caption = 'Service Contract-Customer';
                Image = "Report";
                RunObject = Report "Service Contract - Customer";
                ToolTip = 'View information about status, next invoice date, invoice period, amount per period, and annual amount. You can print a list of service contracts for each customer in a selected time period.';
            }
            action("Service Contract-Salesperson")
            {
                ApplicationArea = Service;
                Caption = 'Service Contract-Salesperson';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Serv. Contract - Salesperson";
                ToolTip = 'View customer number, name, description, starting date and the annual amount for each service contract. You can use the report to calculate and document sales commission. You can print a list of service contracts for each salesperson for a selected period.';
            }
            action("Contract Price Update - Test")
            {
                ApplicationArea = Service;
                Caption = 'Contract Price Update - Test';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Contract Price Update - Test";
                ToolTip = 'View the contracts numbers, customer numbers, contract amounts, price update percentages, and any errors that occur. You can test which service contracts need price updates up to the date that you have specified.';
            }
            action("Service Items Out of Warranty")
            {
                ApplicationArea = Service;
                Caption = 'Service Items Out of Warranty';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Service Items Out of Warranty";
                ToolTip = 'View information about warranty end dates, serial numbers, number of active contracts, items description, and names of customers. You can print a list of service items that are out of warranty.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Lock Contract_Promoted"; "&Lock Contract")
                {
                }
                actionref("&Open Contract_Promoted"; "&Open Contract")
                {
                }
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
                actionref("Si&gn Contract_Promoted"; "Si&gn Contract")
                {
                }
            }
            group(Category_Contract)
            {
                Caption = 'Contract';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref(Action1102601013_Promoted; Action1102601013)
                {
                }
                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Reports';

                actionref("Contract, Service Order Test_Promoted"; "Contract, Service Order Test")
                {
                }
                actionref("Maintenance Visit - Planning_Promoted"; "Maintenance Visit - Planning")
                {
                }
                actionref("Service Contract Profit_Promoted"; "Service Contract Profit")
                {
                }
                actionref("Service Contract-Customer_Promoted"; "Service Contract-Customer")
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetSecurityFilterOnRespCenter();
    end;
}

