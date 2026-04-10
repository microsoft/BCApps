// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Archive;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Address;
using Microsoft.Sales.Customer;
using System.Security.User;

page 6268 "Service Quote Archive"
{
    Caption = 'Service Quote Archive';
    PageType = Document;
    DeleteAllowed = false;
    Editable = false;
    SourceTable = "Service Header Archive";
    SourceTableView = where("Document Type" = filter(Quote));

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                }
                field("Contact No."; Rec."Contact No.")
                {
                    ApplicationArea = Service;
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = Service;
                }
                group("Sell-to")
                {
                    Caption = 'Sell-to';
                    field(Name; Rec.Name)
                    {
                        ApplicationArea = Service;
                    }
                    field("Name 2"; Rec."Name 2")
                    {
                        ApplicationArea = Service;
                        Importance = Additional;
                        Visible = false;
                    }
                    field(Address; Rec.Address)
                    {
                        ApplicationArea = Service;
                        QuickEntry = false;
                    }
                    field("Address 2"; Rec."Address 2")
                    {
                        ApplicationArea = Service;
                        QuickEntry = false;
                    }
                    field(City; Rec.City)
                    {
                        ApplicationArea = Service;
                        QuickEntry = false;
                    }
                    group(CountyGroup)
                    {
                        ShowCaption = false;
                        Visible = IsSellToCountyVisible;
                        field(County; Rec.County)
                        {
                            ApplicationArea = Service;
                            QuickEntry = false;
                        }
                    }
                    field("Post Code"; Rec."Post Code")
                    {
                        ApplicationArea = Service;
                        QuickEntry = false;
                    }
                    field("Country/Region Code"; Rec."Country/Region Code")
                    {
                        ApplicationArea = Service;
                        QuickEntry = false;

                    }
                    field("Contact Name"; Rec."Contact Name")
                    {
                        ApplicationArea = Service;
                    }
                }
                field("Phone No."; Rec."Phone No.")
                {
                    ApplicationArea = Service;
                }
                field("E-Mail"; Rec."E-Mail")
                {
                    ApplicationArea = Service;
                    ExtendedDatatype = EMail;
                }
                field("Phone No. 2"; Rec."Phone No. 2")
                {
                    ApplicationArea = Service;
                }
                field("Notify Customer"; Rec."Notify Customer")
                {
                    ApplicationArea = Service;
                }
                field("Service Order Type"; Rec."Service Order Type")
                {
                    ApplicationArea = Service;
                }
                field("Contract No."; Rec."Contract No.")
                {
                    ApplicationArea = Service;
                }
                field("Response Date"; Rec."Response Date")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                }
                field("Response Time"; Rec."Response Time")
                {
                    ApplicationArea = Service;
                }
                field(Priority; Rec.Priority)
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Service;
                }
                field("Responsibility Center"; Rec."Responsibility Center")
                {
                    ApplicationArea = Service;
                }
                field("Assigned User ID"; Rec."Assigned User ID")
                {
                    ApplicationArea = Service;
                }
                group("Work Description")
                {
                    Caption = 'Work Description';
                    field(WorkDescription; WorkDescription)
                    {
                        ApplicationArea = Service;
                        Importance = Additional;
                        MultiLine = true;
                        ShowCaption = false;
                        ToolTip = 'Specifies the products or service being offered.';
                    }
                }
            }
            part(ServItemLine; "Service Quote Archive Subform")
            {
                ApplicationArea = Service;
                Editable = false;
                SubPageLink = "Document No." = field("No."),
                "Doc. No. Occurrence" = field("Doc. No. Occurrence"),
                "Version No." = field("Version No.");
            }
            group(Invoicing)
            {
                Caption = 'Invoicing';
                field("Bill-to Customer No."; Rec."Bill-to Customer No.")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;

                }
                field("Bill-to Contact No."; Rec."Bill-to Contact No.")
                {
                    ApplicationArea = Service;
                }
                group("Bill-to")
                {
                    Caption = 'Bill-to';
                    field("Bill-to Name"; Rec."Bill-to Name")
                    {
                        ApplicationArea = Service;
                        Caption = 'Name';
                    }
                    field("Bill-to Name 2"; Rec."Bill-to Name 2")
                    {
                        ApplicationArea = Service;
                        Caption = 'Name 2';
                        Importance = Additional;
                        Visible = false;
                    }
                    field("Bill-to Address"; Rec."Bill-to Address")
                    {
                        ApplicationArea = Service;
                        Caption = 'Address';
                        QuickEntry = false;
                    }
                    field("Bill-to Address 2"; Rec."Bill-to Address 2")
                    {
                        ApplicationArea = Service;
                        Caption = 'Address 2';
                        QuickEntry = false;
                    }
                    field("Bill-to City"; Rec."Bill-to City")
                    {
                        ApplicationArea = Service;
                        Caption = 'City';
                        QuickEntry = false;
                    }
                    group(BillCounty)
                    {
                        ShowCaption = false;
                        Visible = IsBillToCountyVisible;
                        field("Bill-to County"; Rec."Bill-to County")
                        {
                            ApplicationArea = Service;
                            CaptionClass = '5,1,' + Rec."Bill-to Country/Region Code";
                            QuickEntry = false;
                        }
                    }
                    field("Bill-to Post Code"; Rec."Bill-to Post Code")
                    {
                        ApplicationArea = Service;
                        Caption = 'Post Code';
                        QuickEntry = false;
                    }
                    field("Bill-to Country/Region Code"; Rec."Bill-to Country/Region Code")
                    {
                        ApplicationArea = Service;
                        Caption = 'Country/Region';
                        QuickEntry = false;
                        ToolTip = 'Specifies the country or region of the customer on the service document.';

                    }
                    field("Bill-to Contact"; Rec."Bill-to Contact")
                    {
                        ApplicationArea = Service;
                        Caption = 'Contact';
                    }
                }
                field("Your Reference"; Rec."Your Reference")
                {
                    ApplicationArea = Service;
                }
                field("Salesperson Code"; Rec."Salesperson Code")
                {
                    ApplicationArea = Service;
                }
                field("Max. Labor Unit Price"; Rec."Max. Labor Unit Price")
                {
                    ApplicationArea = Service;
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Service;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                }
                field("Payment Terms Code"; Rec."Payment Terms Code")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies when the related invoice must be paid.';
                }
                field("Payment Discount %"; Rec."Payment Discount %")
                {
                    ApplicationArea = Service;
                }
                field("Pmt. Discount Date"; Rec."Pmt. Discount Date")
                {
                    ApplicationArea = Service;
                }
                field("Payment Method Code"; Rec."Payment Method Code")
                {
                    ApplicationArea = Service;
                }
                field("Prices Including VAT"; Rec."Prices Including VAT")
                {
                    ApplicationArea = VAT;

                }
                field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group")
                {
                    ApplicationArea = Service;
                }
            }
            group(Shipping)
            {
                Caption = 'Shipping';
                field("Ship-to Code"; Rec."Ship-to Code")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;

                }
                group("Ship-to")
                {
                    Caption = 'Ship-to';
                    field("Ship-to Name"; Rec."Ship-to Name")
                    {
                        ApplicationArea = Service;
                        Caption = 'Name';
                    }
                    field("Ship-to Address"; Rec."Ship-to Address")
                    {
                        ApplicationArea = Service;
                        Caption = 'Address';
                        QuickEntry = false;
                    }
                    field("Ship-to Address 2"; Rec."Ship-to Address 2")
                    {
                        ApplicationArea = Service;
                        Caption = 'Address 2';
                        QuickEntry = false;
                    }
                    field("Ship-to City"; Rec."Ship-to City")
                    {
                        ApplicationArea = Service;
                        Caption = 'City';
                        QuickEntry = false;
                    }
                    group(ShipCounty)
                    {
                        ShowCaption = false;
                        Visible = IsShipToCountyVisible;
                        field("Ship-to County"; Rec."Ship-to County")
                        {
                            ApplicationArea = Service;
                            CaptionClass = '5,1,' + Rec."Ship-to Country/Region Code";
                            QuickEntry = false;
                        }
                    }
                    field("Ship-to Post Code"; Rec."Ship-to Post Code")
                    {
                        ApplicationArea = Service;
                        Caption = 'Post Code';
                        Importance = Promoted;
                        QuickEntry = false;
                    }
                    field("Ship-to Country/Region Code"; Rec."Ship-to Country/Region Code")
                    {
                        ApplicationArea = Service;
                        Caption = 'Country/Region';
                        QuickEntry = false;
                    }
                    field("Ship-to Contact"; Rec."Ship-to Contact")
                    {
                        ApplicationArea = Service;
                        Caption = 'Contact';
                        Importance = Promoted;
                    }
                }
                field("Ship-to Phone"; Rec."Ship-to Phone")
                {
                    ApplicationArea = Service;
                    Caption = 'Ship-to Phone/Phone 2';
                }
                field("Ship-to Phone 2"; Rec."Ship-to Phone 2")
                {
                    ApplicationArea = Service;
                }
                field("Ship-to E-Mail"; Rec."Ship-to E-Mail")
                {
                    ApplicationArea = Service;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the location of the service item, such as a warehouse or distribution center.';
                }
                field("Shipment Method Code"; Rec."Shipment Method Code")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Shipping Agent Code"; Rec."Shipping Agent Code")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
                field("Shipping Agent Service Code"; Rec."Shipping Agent Service Code")
                {
                    ApplicationArea = Service;
                    Visible = false;
                }
            }
            group(Details)
            {
                Caption = 'Details';
                field("Warning Status"; Rec."Warning Status")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                }
                field("Link Service to Service Item"; Rec."Link Service to Service Item")
                {
                    ApplicationArea = Service;
                }
                field("Allocated Hours"; Rec."Allocated Hours")
                {
                    ApplicationArea = Service;
                }
                field("No. of Allocations"; Rec."No. of Allocations")
                {
                    ApplicationArea = Service;
                }
                field("No. of Unallocated Items"; Rec."No. of Unallocated Items")
                {
                    ApplicationArea = Service;
                }
                field("Service Zone Code"; Rec."Service Zone Code")
                {
                    ApplicationArea = Service;
                }
                field("Order Date"; Rec."Order Date")
                {
                    ApplicationArea = Service;

                }
                field("Order Time"; Rec."Order Time")
                {
                    ApplicationArea = Service;
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                }
                field("Starting Time"; Rec."Starting Time")
                {
                    ApplicationArea = Service;
                }
                field("Actual Response Time (Hours)"; Rec."Actual Response Time (Hours)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of hours from order creation, to when the service order status changes from Pending, to In Process.';
                }
                field("Finishing Date"; Rec."Finishing Date")
                {
                    ApplicationArea = Service;
                }
                field("Finishing Time"; Rec."Finishing Time")
                {
                    ApplicationArea = Service;
                }
            }
            group(" Foreign Trade")
            {
                Caption = ' Foreign Trade';
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;

                    trigger OnAssistEdit()
                    begin
                        Clear(ChangeExchangeRate);
                        ChangeExchangeRate.SetParameter(Rec."Currency Code", Rec."Currency Factor", Rec."Posting Date");
                        if ChangeExchangeRate.RunModal() = ACTION::OK then begin
                            Rec.Validate("Currency Factor", ChangeExchangeRate.GetParameter());
                            CurrPage.Update();
                        end;
                        Clear(ChangeExchangeRate);
                    end;
                }
                field("Company Bank Account Code"; Rec."Company Bank Account Code")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                }
                field("EU 3-Party Trade"; Rec."EU 3-Party Trade")
                {
                    ApplicationArea = BasicEU, BasicNO;
                }
                field("Transaction Type"; Rec."Transaction Type")
                {
                    ApplicationArea = BasicEU, BasicNO;
                }
                field("Transaction Specification"; Rec."Transaction Specification")
                {
                    ApplicationArea = BasicEU, BasicNO;
                }
                field("Transport Method"; Rec."Transport Method")
                {
                    ApplicationArea = BasicEU, BasicNO;
                }
                field("Exit Point"; Rec."Exit Point")
                {
                    ApplicationArea = BasicEU, BasicNO;
                }
                field("Area"; Rec.Area)
                {
                    ApplicationArea = BasicEU, BasicNO;
                }
            }
            group(Version)
            {
                Caption = 'Version';
                field("Version No."; Rec."Version No.")
                {
                    ApplicationArea = Service;
                }
                field("Archived By"; Rec."Archived By")
                {
                    ApplicationArea = Service;

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation(Rec."Archived By");
                    end;
                }
                field("Date Archived"; Rec."Date Archived")
                {
                    ApplicationArea = Service;
                }
                field("Time Archived"; Rec."Time Archived")
                {
                    ApplicationArea = Service;
                }
                field("Interaction Exist"; Rec."Interaction Exist")
                {
                    ApplicationArea = RelationshipMgmt;
                }
            }
        }

        area(factboxes)
        {
            part(CustomerStatisticsFactBoxPart; "Customer Statistics FactBox")
            {
                ApplicationArea = Service;
                SubPageLink = "No." = field("Bill-to Customer No."),
                              "Date Filter" = field("Date Filter");
                Visible = false;
            }
            part(CustomerDetailsFactBoxPart; "Customer Details FactBox")
            {
                ApplicationArea = Service;
                SubPageLink = "No." = field("Customer No."),
                              "Date Filter" = field("Date Filter");
                Visible = false;
            }
            systempart(LinksPart; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Ver&sion")
            {
                Caption = 'Ver&sion';
                Image = Versions;

                action(Card)
                {
                    ApplicationArea = Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Page "Customer Card";
                    RunPageLink = "No." = field("Customer No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View detailed information about the record on the document or journal line.';
                }
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
                        CurrPage.SaveRecord();
                    end;
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Service Archive Comment Sheet";
                    RunPageLink = "Table Name" = const("Service Header"),
                                  "Table Subtype" = field("Document Type"),
                                  "No." = field("No."),
                                  Type = const(General),
                                  "Doc. No. Occurrence" = field("Doc. No. Occurrence"),
                                  "Version No." = field("Version No.");
                    ToolTip = 'View comments for the record.';
                }
            }
        }
        area(processing)
        {
            action(Restore)
            {
                ApplicationArea = Suite;
                Caption = '&Restore';
                Ellipsis = true;
                Image = Restore;
                ToolTip = 'Transfer the contents of this archived version to the original document. This is only possible if the original is not posted or deleted. ';

                trigger OnAction()
                var
                    ServiceDocumentArchiveMgmt: Codeunit "Service Document Archive Mgmt.";
                begin
                    ServiceDocumentArchiveMgmt.RestoreServiceDocument(Rec);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Restore_Promoted; Restore)
                {
                }
            }
            group(Category_Quote)
            {
                Caption = 'Quote';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        ActivateFields();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        WorkDescription := Rec.GetWorkDescription();
    end;

    var
        FormatAddress: Codeunit "Format Address";
        ChangeExchangeRate: Page "Change Exchange Rate";
        WorkDescription: Text;
        IsBillToCountyVisible: Boolean;
        IsSellToCountyVisible: Boolean;
        IsShipToCountyVisible: Boolean;

    local procedure ActivateFields()
    begin
        IsSellToCountyVisible := FormatAddress.UseCounty(Rec."Country/Region Code");
        IsBillToCountyVisible := FormatAddress.UseCounty(Rec."Bill-to Country/Region Code");
        IsShipToCountyVisible := FormatAddress.UseCounty(Rec."Ship-to Country/Region Code");
    end;
}