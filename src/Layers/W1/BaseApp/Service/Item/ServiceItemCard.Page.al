// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Item;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Attachment;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Sales.Customer;
using Microsoft.Service.Comment;
using Microsoft.Service.Contract;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Ledger;
using Microsoft.Service.Maintenance;
using Microsoft.Service.Reports;
using Microsoft.Service.Resources;
using Microsoft.Utilities;
#if not CLEAN25
using Microsoft.Integration.Dataverse;
#endif

page 5980 "Service Item Card"
{
    Caption = 'Service Item Card';
    PageType = Card;
    SourceTable = "Service Item";

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
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                    Visible = NoFieldVisible;

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies a description of this item.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies the item number linked to the service item.';

                    trigger OnValidate()
                    var
                        Item: Record "Item";
                    begin
                        Rec.CalcFields("Item Description");
                        if Rec."Variant Code" = '' then
                            VariantCodeMandatory := Item.IsVariantMandatory(true, Rec."Item No.");
                    end;
                }
                field("Item Description"; Rec."Item Description")
                {
                    ApplicationArea = Service;
                    DrillDown = false;
                    ToolTip = 'Specifies the description of the item that the service item is linked to.';
                }
                field("Service Item Group Code"; Rec."Service Item Group Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the service item group associated with this item.';
                }
                field("Service Price Group Code"; Rec."Service Price Group Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the Service Price Group associated with this item.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    ShowMandatory = VariantCodeMandatory;

                    trigger OnValidate()
                    var
                        Item: Record "Item";
                    begin
                        if Rec."Variant Code" = '' then
                            VariantCodeMandatory := Item.IsVariantMandatory(true, Rec."Item No.");
                    end;
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    AssistEdit = true;
                    ToolTip = 'Specifies the serial number of this item.';

                    trigger OnAssistEdit()
                    var
                        ItemLedgerEntry: Record "Item Ledger Entry";
                    begin
                        Clear(ItemLedgerEntry);
                        ItemLedgerEntry.FilterGroup(2);
                        ItemLedgerEntry.SetRange("Item No.", Rec."Item No.");
                        if Rec."Variant Code" <> '' then
                            ItemLedgerEntry.SetRange("Variant Code", Rec."Variant Code");
                        ItemLedgerEntry.SetFilter("Serial No.", '<>%1', '');
                        ItemLedgerEntry.FilterGroup(0);

                        if PAGE.RunModal(0, ItemLedgerEntry) = ACTION::LookupOK then
                            Rec.Validate("Serial No.", ItemLedgerEntry."Serial No.");
                    end;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies the status of the service item.';
                }
                field("Service Item Components"; Rec."Service Item Components")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that there is a component for this service item.';
                }
                field("Search Description"; Rec."Search Description")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies an alternate description to search for the service item.';
                }
                field("Response Time (Hours)"; Rec."Response Time (Hours)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the estimated number of hours this item requires before service on it should be started.';
                }
                field(Priority; Rec.Priority)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the service priority for this item.';
                }
                field("Last Service Date"; Rec."Last Service Date")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the date of the last service on this item.';
                }
                field("Warranty Starting Date (Parts)"; Rec."Warranty Starting Date (Parts)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the starting date of the spare parts warranty for this item.';
                }
                field("Warranty Ending Date (Parts)"; Rec."Warranty Ending Date (Parts)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the ending date of the spare parts warranty for this item.';
                }
                field("Warranty % (Parts)"; Rec."Warranty % (Parts)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the percentage of spare parts costs covered by the warranty for the item.';
                }
                field("Warranty Starting Date (Labor)"; Rec."Warranty Starting Date (Labor)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the starting date of the labor warranty for this item.';
                }
                field("Warranty Ending Date (Labor)"; Rec."Warranty Ending Date (Labor)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the ending date of the labor warranty for this item.';
                }
                field("Warranty % (Labor)"; Rec."Warranty % (Labor)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the percentage of labor costs covered by the warranty for this item.';
                }
                field("Preferred Resource"; Rec."Preferred Resource")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the resource that the customer prefers for servicing of the item.';
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that the service item is blocked from being used in service contracts or used and posted in transactions via service documents, except credit memos.';
                }
            }
            group(Customer)
            {
                Caption = 'Customer';
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the customer who owns this item.';

                    trigger OnValidate()
                    begin
                        Rec.CalcFields(Name, "Name 2", Address, "Address 2", "Post Code",
                          City, Contact, "Phone No.", County, "Country/Region Code");
                        CustomerNoOnAfterValidate();
                        IsSellToCountyVisible := FormatAddress.UseCounty(Rec."Country/Region Code");
                    end;
                }
                group("Sell-to")
                {
                    Caption = 'Sell-to';
                    field(Name; Rec.Name)
                    {
                        ApplicationArea = Service;
                        DrillDown = false;
                        Importance = Promoted;
                        ToolTip = 'Specifies the name of the customer who owns this item.';
                    }
                    field(Address; Rec.Address)
                    {
                        ApplicationArea = Service;
                        DrillDown = false;
                        QuickEntry = false;
                        ToolTip = 'Specifies the address of the customer who owns this item.';
                    }
                    field("Address 2"; Rec."Address 2")
                    {
                        ApplicationArea = Service;
                        DrillDown = false;
                        QuickEntry = false;
                        ToolTip = 'Specifies additional address information.';
                    }
                    field(City; Rec.City)
                    {
                        ApplicationArea = Service;
                        DrillDown = false;
                        QuickEntry = false;
                        ToolTip = 'Specifies the city of the customer address.';
                    }
                    group(Control23)
                    {
                        ShowCaption = false;
                        Visible = IsSellToCountyVisible;
                        field(County; Rec.County)
                        {
                            ApplicationArea = Service;
                            QuickEntry = false;
                            ToolTip = 'Specifies the state, province or county as a part of the address.';
                        }
                    }
                    field("Post Code"; Rec."Post Code")
                    {
                        ApplicationArea = Service;
                        DrillDown = false;
                        QuickEntry = false;
                        ToolTip = 'Specifies the postal code.';
                    }
                    field("Country/Region Code"; Rec."Country/Region Code")
                    {
                        ApplicationArea = Service;
                        QuickEntry = false;
                        ToolTip = 'Specifies the country/region of the address.';
                    }
                    field(Contact; Rec.Contact)
                    {
                        ApplicationArea = Service;
                        DrillDown = false;
                        Importance = Promoted;
                        ToolTip = 'Specifies the name of the person you regularly contact when you do business with the customer who owns this item.';
                    }
                }
                field("Phone No."; Rec."Phone No.")
                {
                    ApplicationArea = Service;
                    DrillDown = false;
                    ToolTip = 'Specifies the customer phone number.';
                }
                field("Location of Service Item"; Rec."Location of Service Item")
                {
                    ApplicationArea = Location;
                    Importance = Promoted;
                    ToolTip = 'Specifies the code of the location of this item.';
                }
            }
            group(Shipping)
            {
                Caption = 'Shipping';
                field("Ship-to Code"; Rec."Ship-to Code")
                {
                    ApplicationArea = Service;
                    Importance = Promoted;
                    ToolTip = 'Specifies a code for an alternate shipment address if you want to ship to another address than the one that has been entered automatically. This field is also used in case of drop shipment.';

                    trigger OnValidate()
                    begin
                        UpdateShipToCode();
                        IsShipToCountyVisible := FormatAddress.UseCounty(Rec."Ship-to Country/Region Code");
                    end;
                }
                group("Ship-to")
                {
                    Caption = 'Ship-to';
                    field("Ship-to Name"; Rec."Ship-to Name")
                    {
                        ApplicationArea = Service;
                        Caption = 'Name';
                        DrillDown = false;
                        ToolTip = 'Specifies the name of the customer at the address that the items are shipped to.';
                    }
                    field("Ship-to Name 2"; Rec."Ship-to Name 2")
                    {
                        ApplicationArea = Service;
                        Caption = 'Name 2';
                        Importance = Additional;
                        ToolTip = 'Specifies an additional part of the name of the customer at the address that the items are shipped to.';
                        QuickEntry = false;
                        Visible = false;
                    }
                    field("Ship-to Address"; Rec."Ship-to Address")
                    {
                        ApplicationArea = Service;
                        Caption = 'Address';
                        DrillDown = false;
                        QuickEntry = false;
                        ToolTip = 'Specifies the address that the items are shipped to.';
                    }
                    field("Ship-to Address 2"; Rec."Ship-to Address 2")
                    {
                        ApplicationArea = Service;
                        Caption = 'Address 2';
                        DrillDown = false;
                        QuickEntry = false;
                        ToolTip = 'Specifies an additional part of the ship-to address, in case it is a long address.';
                    }
                    field("Ship-to City"; Rec."Ship-to City")
                    {
                        ApplicationArea = Service;
                        Caption = 'City';
                        DrillDown = false;
                        QuickEntry = false;
                        ToolTip = 'Specifies the city of the address that the items are shipped to.';
                    }
                    group(Control35)
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
                        DrillDown = false;
                        Importance = Promoted;
                        QuickEntry = false;
                        ToolTip = 'Specifies the postal code of the address that the items are shipped to.';
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
                        DrillDown = false;
                        Importance = Promoted;
                        ToolTip = 'Specifies the name of the contact person at the address that the items are shipped to.';
                    }
                }
                field("Ship-to Phone No."; Rec."Ship-to Phone No.")
                {
                    ApplicationArea = Service;
                    DrillDown = false;
                    ToolTip = 'Specifies the phone number at address that the items are shipped to.';
                }
            }
            group(Contract)
            {
                Caption = 'Contract';
                field("Default Contract Cost"; Rec."Default Contract Cost")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the default contract cost of a service item that later will be included in a service contract or contract quote.';
                }
                field("Default Contract Value"; Rec."Default Contract Value")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the default contract value of an item that later will be included in a service contract or contract quote.';
                }
                field("Default Contract Discount %"; Rec."Default Contract Discount %")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a default contract discount percentage for an item, if this item will be part of a service contract.';
                }
                field("Service Contracts"; Rec."Service Contracts")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that this service item is associated with one or more service contracts/quotes.';
                }
            }
            group(Vendor)
            {
                Caption = 'Vendor';
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the vendor for this item.';

                    trigger OnValidate()
                    begin
                        Rec.CalcFields("Vendor Name");
                    end;
                }
                field("Vendor Name"; Rec."Vendor Name")
                {
                    ApplicationArea = Service;
                    DrillDown = false;
                    ToolTip = 'Specifies the vendor name for this item.';
                }
                field("Vendor Item No."; Rec."Vendor Item No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number that the vendor uses for this item.';
                }
                field("Vendor Item Name"; Rec."Vendor Item Name")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the name assigned to this item by the vendor.';
                }
            }
            group(Detail)
            {
                Caption = 'Detail';
                field("Sales Unit Cost"; Rec."Sales Unit Cost")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the unit cost of this item when it was sold.';
                }
                field("Sales Unit Price"; Rec."Sales Unit Price")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the unit price of this item when it was sold.';
                }
                field("Sales Date"; Rec."Sales Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when this item was sold.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Installation Date"; Rec."Installation Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when this item was installed at the customer''s site.';
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
                SubPageLink = "Table ID" = const(Database::"Service Item"),
                              "No." = field("No.");
            }
#endif
            part("Attached Documents List"; "Doc. Attachment List Factbox")
            {
                ApplicationArea = Service;
                Caption = 'Documents';
                UpdatePropagation = Both;
                SubPageLink = "Table ID" = const(Database::"Service Item"),
                              "No." = field("No.");
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
            group("&Service Item")
            {
                Caption = '&Service Item';
                Image = ServiceItem;
                action("&Components")
                {
                    ApplicationArea = Service;
                    Caption = '&Components';
                    Image = Components;
                    RunObject = Page "Service Item Component List";
                    RunPageLink = Active = const(true),
                                  "Parent Service Item No." = field("No.");
                    RunPageView = sorting(Active, "Parent Service Item No.", "Line No.");
                    ToolTip = 'View components that are used in the service item.';
                }
                action("&Dimensions")
                {
                    ApplicationArea = Dimensions;
                    Caption = '&Dimensions';
                    Image = Dimensions;
                    RunObject = Page "Default Dimensions";
                    RunPageLink = "Table ID" = const(5940),
                                  "No." = field("No.");
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to journal lines to distribute costs and analyze transaction history.';
                }
                group(Statistics)
                {
                    Caption = 'Statistics';
                    Image = Statistics;
                    action(Action39)
                    {
                        ApplicationArea = Service;
                        Caption = 'Statistics';
                        Image = Statistics;
                        RunObject = Page "Service Item Statistics";
                        RunPageLink = "No." = field("No.");
                        ShortCutKey = 'F7';
                        ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                    }
                    action("Tr&endscape")
                    {
                        ApplicationArea = Service;
                        Caption = 'Tr&endscape';
                        Image = Trendscape;
                        RunObject = Page "Service Item Trendscape";
                        RunPageLink = "No." = field("No.");
                        ToolTip = 'View a detailed account of service item transactions by time intervals.';
                    }
                }
                group(Troubleshooting)
                {
                    Caption = 'Troubleshooting';
                    Image = Troubleshoot;
                    action("Troubleshooting Setup")
                    {
                        ApplicationArea = Service;
                        Caption = 'Troubleshooting Setup';
                        Image = Troubleshoot;
                        RunObject = Page "Troubleshooting Setup";
                        RunPageLink = Type = const("Service Item"),
                                      "No." = field("No.");
                        ToolTip = 'View or edit your settings for troubleshooting service items.';
                    }
                    action("<Page Troubleshooting>")
                    {
                        ApplicationArea = Service;
                        Caption = 'Troubleshooting';
                        Image = Troubleshoot;
                        ToolTip = 'View or edit information about technical problems with a service item.';

                        trigger OnAction()
                        var
                            TroubleshootingHeader: Record "Troubleshooting Header";
                        begin
                            TroubleshootingHeader.ShowForServItem(Rec);
                        end;
                    }
                }
                action("Resource Skills")
                {
                    ApplicationArea = Service;
                    Caption = 'Resource Skills';
                    Image = ResourceSkills;
                    RunObject = Page "Resource Skills";
                    RunPageLink = Type = const("Service Item"),
                                  "No." = field("No.");
                    ToolTip = 'View the assignment of skills to resources, items, service item groups, and service items. You can use skill codes to allocate skilled resources to service items or items that need special skills for servicing.';
                }
                action("S&killed Resources")
                {
                    ApplicationArea = Service;
                    Caption = 'S&killed Resources';
                    Image = ResourceSkills;
                    ToolTip = 'View the list of resources that have the skills required to handle service items.';

                    trigger OnAction()
                    begin
                        Clear(SkilledResourceList);
                        SkilledResourceList.Initialize(ResourceSkill.Type::"Service Item", Rec."No.", Rec.Description);
                        SkilledResourceList.RunModal();
                    end;
                }
                action("Co&mments")
                {
                    ApplicationArea = Service;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Service Comment Sheet";
                    RunPageLink = "Table Name" = const("Service Item"),
                                  "Table Subtype" = const("0"),
                                  "No." = field("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action(Attachments)
                {
                    ApplicationArea = Service;
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
            group(Documents)
            {
                Caption = 'Documents';
                Image = Documents;
                group("S&ervice Orders")
                {
                    Caption = 'S&ervice Orders';
                    Image = "Order";
                    action("&Item Lines")
                    {
                        ApplicationArea = Service;
                        Caption = '&Item Lines';
                        Image = ItemLines;
                        RunObject = Page "Service Item Lines";
                        RunPageLink = "Service Item No." = field("No.");
                        RunPageView = sorting("Service Item No.");
                        ToolTip = 'View ongoing service item lines for the item. ';
                    }
                    action("&Service Lines")
                    {
                        ApplicationArea = Service;
                        Caption = '&Service Lines';
                        Image = ServiceLines;
                        RunObject = Page "Service Line List";
                        RunPageLink = "Service Item No." = field("No.");
                        RunPageView = sorting("Service Item No.");
                        ToolTip = 'View ongoing service lines for the item.';
                    }
                }
                group("Service Shi&pments")
                {
                    Caption = 'Service Shi&pments';
                    Image = Shipment;
                    action(Action117)
                    {
                        ApplicationArea = Service;
                        Caption = 'Shipped &Item Lines';
                        Image = ItemLines;
                        RunObject = Page "Posted Shpt. Item Line List";
                        RunPageLink = "Service Item No." = field("No.");
                        RunPageView = sorting("Service Item No.");
                        ToolTip = 'View shipped service item lines for the item. ';
                    }
                    action(Action113)
                    {
                        ApplicationArea = Service;
                        Caption = 'Shipped &Service Lines';
                        Image = ServiceLines;
                        RunObject = Page "Posted Serv. Shpt. Line List";
                        RunPageLink = "Service Item No." = field("No.");
                        RunPageView = sorting("Service Item No.");
                        ToolTip = 'View shipped service lines for the item.';
                    }
                }
                action("Ser&vice Contracts")
                {
                    ApplicationArea = Service;
                    Caption = 'Ser&vice Contracts';
                    Image = ServiceAgreement;
                    RunObject = Page "Serv. Contr. List (Serv. Item)";
                    RunPageLink = "Service Item No." = field("No.");
                    RunPageView = sorting("Service Item No.", "Contract Status");
                    ToolTip = 'Open the list of ongoing service contracts.';
                }
            }
            group(History)
            {
                Caption = 'History';
                Image = History;
                action("Service Item Lo&g")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Item Lo&g';
                    Image = Log;
                    RunObject = Page "Service Item Log";
                    RunPageLink = "Service Item No." = field("No.");
                    ToolTip = 'View a list of the service document changes that have been logged. The program creates entries in the window when, for example, the response time or service order status changed, a resource was allocated, a service order was shipped or invoiced, and so on. Each line in this window identifies the event that occurred to the service document. The line contains the information about the field that was changed, its old and new value, the date and time when the change took place, and the ID of the user who actually made the changes.';
                }
                action("Service Ledger E&ntries")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Ledger E&ntries';
                    Image = ServiceLedger;
                    RunObject = Page "Service Ledger Entries";
                    RunPageLink = "Service Item No. (Serviced)" = field("No."),
                                  "Service Order No." = field("Service Order Filter"),
                                  "Service Contract No." = field("Contract Filter"),
                                  "Posting Date" = field("Date Filter");
                    RunPageView = sorting("Service Item No. (Serviced)", "Entry Type", "Moved from Prepaid Acc.", Type, "Posting Date");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View all the ledger entries for the service item or service order that result from posting transactions in service documents.';
                }
                action("&Warranty Ledger Entries")
                {
                    ApplicationArea = Service;
                    Caption = '&Warranty Ledger Entries';
                    Image = WarrantyLedger;
                    RunObject = Page "Warranty Ledger Entries";
                    RunPageLink = "Service Item No. (Serviced)" = field("No.");
                    RunPageView = sorting("Service Item No. (Serviced)", "Posting Date", "Document No.");
                    ToolTip = 'View all the ledger entries for the service item or service order that result from posting transactions in service documents that contain warranty agreements.';
                }
            }
#if not CLEAN25
            group(ActionGroupFS)
            {
                Caption = 'Dynamics 365 Field Service';
                Visible = false;
                ObsoleteReason = 'Field Service is moved to Field Service Integration app.';
                ObsoleteState = Pending;
                ObsoleteTag = '25.0';

                action(CRMGoToProduct)
                {
                    ApplicationArea = Suite;
                    Caption = 'Customer Asset';
                    Image = CoupledItem;
                    ToolTip = 'Open the coupled Dynamics 365 Field Service customer asset.';
                    ObsoleteReason = 'Field Service is moved to Field Service Integration app.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '25.0';

                    trigger OnAction()
                    var
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        CRMIntegrationManagement.ShowCRMEntityFromRecordID(Rec.RecordId);
                    end;
                }
                action(CRMSynchronizeNow)
                {
                    AccessByPermission = TableData "CRM Integration Record" = IM;
                    ApplicationArea = Suite;
                    Caption = 'Synchronize';
                    Image = Refresh;
                    ToolTip = 'Send updated data to Dynamics 365 Field Service.';
                    ObsoleteReason = 'Field Service is moved to Field Service Integration app.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '25.0';

                    trigger OnAction()
                    var
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        CRMIntegrationManagement.UpdateOneNow(Rec.RecordId);
                    end;
                }
                group(Coupling)
                {
                    Caption = 'Coupling', Comment = 'Coupling is a noun';
                    Image = LinkAccount;
                    ToolTip = 'Create, change, or delete a coupling between the Business Central record and a Dynamics 365 Field Service record.';
                    ObsoleteReason = 'Field Service is moved to Field Service Integration app.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '25.0';

                    action(ManageCRMCoupling)
                    {
                        AccessByPermission = TableData "CRM Integration Record" = IM;
                        ApplicationArea = Suite;
                        Caption = 'Set Up Coupling';
                        Image = LinkAccount;
                        ToolTip = 'Create or modify the coupling to a Dynamics 365 Field Service product.';
                        ObsoleteReason = 'Field Service is moved to Field Service Integration app.';
                        ObsoleteState = Pending;
                        ObsoleteTag = '25.0';

                        trigger OnAction()
                        var
                            CRMIntegrationManagement: Codeunit "CRM Integration Management";
                        begin
                            CRMIntegrationManagement.DefineCoupling(Rec.RecordId);
                        end;
                    }
                    action(MatchBasedCouplingFS)
                    {
                        AccessByPermission = TableData "CRM Integration Record" = IM;
                        ApplicationArea = Suite;
                        Caption = 'Match-Based Coupling';
                        Image = CoupledItem;
                        ToolTip = 'Couple resources to products in Dynamics 365 Sales based on matching criteria.';
                        ObsoleteReason = 'Field Service is moved to Field Service Integration app.';
                        ObsoleteState = Pending;
                        ObsoleteTag = '25.0';

                        trigger OnAction()
                        var
                            ServiceItem: Record "Service Item";
                            CRMIntegrationManagement: Codeunit "CRM Integration Management";
                            RecRef: RecordRef;
                        begin
                            CurrPage.SetSelectionFilter(ServiceItem);
                            RecRef.GetTable(ServiceItem);
                            CRMIntegrationManagement.MatchBasedCoupling(RecRef);
                        end;
                    }
                    action(DeleteCRMCoupling)
                    {
                        AccessByPermission = TableData "CRM Integration Record" = D;
                        ApplicationArea = Suite;
                        Caption = 'Delete Coupling';
                        Enabled = false;
                        Image = UnLinkAccount;
                        ToolTip = 'Delete the coupling to a Dynamics 365 Field Service product.';
                        ObsoleteReason = 'Field Service is moved to Field Service Integration app.';
                        ObsoleteState = Pending;
                        ObsoleteTag = '25.0';

                        trigger OnAction()
                        var
                            CRMCouplingManagement: Codeunit "CRM Coupling Management";
                        begin
                            CRMCouplingManagement.RemoveCoupling(Rec.RecordId);
                        end;
                    }
                }
                action(ShowLog)
                {
                    ApplicationArea = Suite;
                    Caption = 'Synchronization Log';
                    Image = Log;
                    ToolTip = 'View integration synchronization jobs for the resource table.';
                    ObsoleteReason = 'Field Service is moved to Field Service Integration app.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '25.0';

                    trigger OnAction()
                    var
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        CRMIntegrationManagement.ShowLog(Rec.RecordId);
                    end;
                }
            }
#endif
        }
        area(processing)
        {
            group(New)
            {
                Caption = 'New';
                Image = NewItem;
                action("New Item")
                {
                    ApplicationArea = Service;
                    Caption = 'New Item';
                    Image = NewItem;
                    RunObject = Page "Item Card";
                    RunPageMode = Create;
                    ToolTip = 'Create an item card based on the stockkeeping unit.';
                }
            }
        }
        area(reporting)
        {
            action("Service Line Item Label")
            {
                ApplicationArea = Service;
                Caption = 'Service Line Item Label';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Service Item Line Labels";
                ToolTip = 'View the list of service items on service orders. The report shows the order number, service item number, serial number, and the name of the item.';
            }
        }
        area(Promoted)
        {
            group(Category_Category5)
            {
                Caption = 'Item', Comment = 'Generated from the PromotedActionCategories property index 4.';

                actionref(Attachments_Promoted; Attachments)
                {
                }
                actionref("&Dimensions_Promoted"; "&Dimensions")
                {
                }
                actionref(Action39_Promoted; Action39)
                {
                }
                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }
                actionref("S&killed Resources_Promoted"; "S&killed Resources")
                {
                }
                actionref("&Components_Promoted"; "&Components")
                {
                }
                actionref("Resource Skills_Promoted"; "Resource Skills")
                {
                }
                actionref("Ser&vice Contracts_Promoted"; "Ser&vice Contracts")
                {
                }
                actionref("Service Item Lo&g_Promoted"; "Service Item Lo&g")
                {
                }
            }
            group(Category_Troubleshooting)
            {
                Caption = 'Troubleshooting';

                actionref("<Page Troubleshooting>_Promoted"; "<Page Troubleshooting>")
                {
                }
                actionref("Troubleshooting Setup_Promoted"; "Troubleshooting Setup")
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Navigate', Comment = 'Generated from the PromotedActionCategories property index 3.';

            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Item: Record Item;
    begin
        UpdateShipToCode();
        if Rec."Variant Code" = '' then
            VariantCodeMandatory := Item.IsVariantMandatory(true, Rec."Item No.");
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Item: Record Item;
    begin
        if Rec."Item No." = '' then
            if Rec.GetFilter("Item No.") <> '' then
                if Rec.GetRangeMin("Item No.") = Rec.GetRangeMax("Item No.") then begin
                    Item.SetLoadFields(Blocked, "Service Blocked");
                    if Item.Get(Rec.GetRangeMin("Item No.")) then
                        if (not Item.Blocked) and (not Item."Service Blocked") then
                            Rec."Item No." := Item."No.";
                end;

        if Rec."Customer No." = '' then
            if Rec.GetFilter("Customer No.") <> '' then
                if Rec.GetRangeMin("Customer No.") = Rec.GetRangeMax("Customer No.") then
                    Rec."Customer No." := Rec.GetRangeMin("Customer No.");
    end;

    trigger OnOpenPage()
    begin
        IsSellToCountyVisible := FormatAddress.UseCounty(Rec."Country/Region Code");
        IsShipToCountyVisible := FormatAddress.UseCounty(Rec."Ship-to Country/Region Code");
        SetNoFieldVisible();
    end;

    var
        ResourceSkill: Record "Resource Skill";
        FormatAddress: Codeunit "Format Address";
        SkilledResourceList: Page "Skilled Resource List";
        NoFieldVisible: Boolean;
        IsSellToCountyVisible: Boolean;
        IsShipToCountyVisible: Boolean;
        VariantCodeMandatory: Boolean;

    local procedure UpdateShipToCode()
    begin
        if Rec."Ship-to Code" = '' then begin
            Rec."Ship-to Name" := Rec.Name;
            Rec."Ship-to Address" := Rec.Address;
            Rec."Ship-to Address 2" := Rec."Address 2";
            Rec."Ship-to Post Code" := Rec."Post Code";
            Rec."Ship-to City" := Rec.City;
            Rec."Ship-to County" := Rec.County;
            Rec."Ship-to Phone No." := Rec."Phone No.";
            Rec."Ship-to Contact" := Rec.Contact;
        end else
            Rec.CalcFields(
              "Ship-to Name", "Ship-to Name 2", "Ship-to Address", "Ship-to Address 2", "Ship-to Post Code", "Ship-to City",
              "Ship-to County", "Ship-to Country/Region Code", "Ship-to Contact", "Ship-to Phone No.");
    end;

    local procedure CustomerNoOnAfterValidate()
    begin
        if Rec."Customer No." <> xRec."Customer No." then
            UpdateShipToCode();
    end;

    local procedure SetNoFieldVisible()
    var
        ServDocumentNoVisibility: Codeunit "Serv. Document No. Visibility";
    begin
        NoFieldVisible := ServDocumentNoVisibility.ServiceItemNoIsVisible();
    end;
}

