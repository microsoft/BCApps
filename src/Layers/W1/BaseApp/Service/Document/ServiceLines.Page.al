// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.ExtendedText;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Item.Substitution;
using Microsoft.Inventory.Location;
using Microsoft.Pricing.Calculation;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.TimeSheet;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Pricing;
using Microsoft.Service.Comment;
using Microsoft.Service.History;
using Microsoft.Service.Ledger;
using Microsoft.Service.Maintenance;
using Microsoft.Service.Posting;
using Microsoft.Service.Pricing;
using Microsoft.Service.Setup;
using Microsoft.Warehouse.Document;
using System.Utilities;

page 5905 "Service Lines"
{
    AutoSplitKey = true;
    Caption = 'Service Lines';
    DataCaptionFields = "Document Type", "Document No.";
    DelayedInsert = true;
    PageType = Worksheet;
    PopulateAllFields = true;
    SourceTable = "Service Line";

    layout
    {
        area(content)
        {
            field(SelectionFilter; SelectionFilter)
            {
                ApplicationArea = Service;
                Caption = 'Service Lines Filter';
                OptionCaption = 'All,Per Selected Service Item Line,Service Item Line Non-Related';
                ToolTip = 'Specifies a service line filter.';

                trigger OnValidate()
                begin
                    SelectionFilterOnAfterValidate();
                end;
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("Service Item Line No."; Rec."Service Item Line No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the service item line number linked to this service line.';
                    Visible = false;
                }
                field("Service Item No."; Rec."Service Item No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the service item number linked to this service line.';
                }
                field("Service Item Serial No."; Rec."Service Item Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the service item serial number linked to this line.';
                    Visible = false;
                }
                field("Service Item Line Description"; Rec."Service Item Line Description")
                {
                    ApplicationArea = Service;
                    DrillDown = false;
                    ToolTip = 'Specifies the description of the service item line in the service order.';
                    Visible = false;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the type of the service line.';

                    trigger OnValidate()
                    begin
                        NoOnAfterValidate();
                    end;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

                    trigger OnValidate()
                    var
                        Item: Record "Item";
                    begin
                        if Rec."Variant Code" = '' then
                            VariantCodeMandatory := Item.IsVariantMandatory(Rec.Type = Rec.Type::Item, Rec."No.");
                        NoOnAfterValidate();
                    end;
                }
                field("Item Reference No."; Rec."Item Reference No.")
                {
                    AccessByPermission = tabledata "Item Reference" = R;
                    ApplicationArea = Service, ItemReferences;
                    QuickEntry = false;
                    ToolTip = 'Specifies the referenced item number. If you enter a cross reference between yours and your vendor''s or customer''s item number, then this number will override the standard item number when you enter the reference number on a service document.';
                    Visible = ItemReferenceVisible;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        ServItemReferenceMgt: Codeunit "Serv. Item Reference Mgt.";
                    begin
                        ServItemReferenceMgt.ServiceReferenceNoLookup(Rec);
                        NoOnAfterValidate();
                        CurrPage.Update();
                    end;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                    ShowMandatory = VariantCodeMandatory;

                    trigger OnValidate()
                    var
                        Item: Record "Item";
                    begin
                        if Rec."Variant Code" = '' then
                            VariantCodeMandatory := Item.IsVariantMandatory(Rec.Type = Rec.Type::Item, Rec."No.");
                    end;
                }
                field(Nonstock; Rec.Nonstock)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that the item is a catalog item.';
                    Visible = false;
                }
                field("Substitution Available"; Rec."Substitution Available")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies whether a substitute is available for the item.';
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the description of an item, resource, cost, or a standard text on the line.';
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies an additional description of the item, resource, or cost.';
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the inventory location from where the items on the line should be taken and where they should be registered.';

                    trigger OnValidate()
                    begin
                        LocationCodeOnAfterValidate();
                    end;
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the bin where the items are picked or put away.';
                    Visible = false;
                }
                field(Control134; Rec.Reserve)
                {
                    ApplicationArea = Reservation;
                    ToolTip = 'Specifies whether a reservation can be made for items on this line.';
                    Visible = false;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the number of item units, resource hours, cost on the service line.';

                    trigger OnValidate()
                    begin
                        QuantityOnAfterValidate();
                    end;
                }
                field("Reserved Quantity"; Rec."Reserved Quantity")
                {
                    ApplicationArea = Reservation;
                    BlankZero = true;
                    ToolTip = 'Specifies how many item units on this line have been reserved.';
                    Visible = false;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Unit Cost (LCY)"; Rec."Unit Cost (LCY)")
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                    ToolTip = 'Specifies the cost, in LCY, of one unit of the item or resource on the line.';
                    Visible = false;
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                    ToolTip = 'Specifies the price of one unit of the item or resource. You can enter a price manually or have it entered according to the Price/Profit Calculation field on the related card.';
                }
                field("Line Amount"; Rec."Line Amount")
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                    ToolTip = 'Specifies the net amount, excluding any invoice discount amount, that must be paid for products on the line.';
                }
                field("Tax Liable"; Rec."Tax Liable")
                {
                    ApplicationArea = SalesTax;
                    Editable = true;
                    ToolTip = 'Specifies that items, resources, or costs on the current service line are liable for sales tax.';
                    Visible = true;
                }
                field("Tax Area Code"; Rec."Tax Area Code")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies the tax area that is used to calculate and post sales tax.';
                    Visible = true;
                }
                field("Tax Group Code"; Rec."Tax Group Code")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies the tax group that is used to calculate and post sales tax.';
                }
                field("Line Discount %"; Rec."Line Discount %")
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                    ToolTip = 'Specifies the discount percentage that is granted for the item on the line.';
                }
                field("Line Discount Amount"; Rec."Line Discount Amount")
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                    ToolTip = 'Specifies the discount amount that is granted for the item on the line.';
                }
                field("Line Discount Type"; Rec."Line Discount Type")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the type of the line discount assigned to this line.';
                }
                field("Qty. to Ship"; Rec."Qty. to Ship")
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                    ToolTip = 'Specifies the quantity of items that remain to be shipped.';
                }
                field("Quantity Shipped"; Rec."Quantity Shipped")
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                    ToolTip = 'Specifies how many units of the item on the line have been posted as shipped.';

                    trigger OnDrillDown()
                    var
                        ServiceShipmentLine: Record "Service Shipment Line";
                    begin
                        ServiceShipmentLine.SetCurrentKey("Document No.", "No.", "Posting Date");
                        ServiceShipmentLine.SetRange("Order No.", Rec."Document No.");
                        ServiceShipmentLine.SetRange("Order Line No.", Rec."Line No.");
                        ServiceShipmentLine.SetFilter(Quantity, '<>%1', 0);
                        Page.RunModal(0, ServiceShipmentLine);
                    end;
                }
                field("Qty. to Invoice"; Rec."Qty. to Invoice")
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                    ToolTip = 'Specifies the quantity of the items, resources, costs, or general ledger account payments, which should be invoiced.';
                }
                field("Quantity Invoiced"; Rec."Quantity Invoiced")
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                    ToolTip = 'Specifies how many units of the item on the line have been posted as invoiced.';

                    trigger OnDrillDown()
                    var
                        ServiceInvoiceLine: Record "Service Invoice Line";
                    begin
                        ServiceInvoiceLine.SetCurrentKey("Document No.", "No.", "Posting Date");
                        ServiceInvoiceLine.SetRange("Order No.", Rec."Document No.");
                        ServiceInvoiceLine.SetRange("Line No.", Rec."Line No.");
                        ServiceInvoiceLine.SetFilter(Quantity, '<>%1', 0);
                        Page.RunModal(0, ServiceInvoiceLine);
                    end;
                }
                field("Qty. to Consume"; Rec."Qty. to Consume")
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                    ToolTip = 'Specifies the quantity of items, resource hours, costs, or G/L account payments that should be consumed.';
                }
                field("Quantity Consumed"; Rec."Quantity Consumed")
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                    ToolTip = 'Specifies the quantity of items, resource hours, costs, or general ledger account payments on this line, which have been posted as consumed.';
                }
                field("Job Remaining Qty."; Rec."Job Remaining Qty.")
                {
                    ApplicationArea = Jobs;
                    BlankZero = true;
                    ToolTip = 'Specifies the quantity that remains to complete a project.';
                    Visible = false;
                }
                field("Job Remaining Total Cost"; Rec."Job Remaining Total Cost")
                {
                    ApplicationArea = Jobs;
                    BlankZero = true;
                    ToolTip = 'Specifies the remaining total cost, as the sum of costs from project planning lines associated with the order.';
                    Visible = false;
                }
                field("Job Remaining Total Cost (LCY)"; Rec."Job Remaining Total Cost (LCY)")
                {
                    ApplicationArea = Jobs;
                    BlankZero = true;
                    ToolTip = 'Specifies the remaining total cost for the project planning line associated with the service order.';
                    Visible = false;
                }
                field("Job Remaining Line Amount"; Rec."Job Remaining Line Amount")
                {
                    ApplicationArea = Jobs;
                    BlankZero = true;
                    ToolTip = 'Specifies the net amount of the project planning line.';
                    Visible = false;
                }
                field("Work Type Code"; Rec."Work Type Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a code for the type of work performed by the resource registered on this line.';
                    Visible = false;
                }
                field("Fault Reason Code"; Rec."Fault Reason Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the fault reason for this service line.';
                    Visible = false;
                }
                field("Fault Area Code"; Rec."Fault Area Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the fault area associated with this line.';
                    Visible = FaultAreaCodeVisible;
                }
                field("Symptom Code"; Rec."Symptom Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the symptom associated with this line.';
                    Visible = SymptomCodeVisible;
                }
                field("Fault Code"; Rec."Fault Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the fault associated with this line.';
                    Visible = FaultCodeVisible;
                }
                field("Resolution Code"; Rec."Resolution Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the resolution associated with this line.';
                    Visible = ResolutionCodeVisible;
                }
                field("Serv. Price Adjmt. Gr. Code"; Rec."Serv. Price Adjmt. Gr. Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the service price adjustment group code that applies to this line.';
                    Visible = false;
                }
                field("Allow Invoice Disc."; Rec."Allow Invoice Disc.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies if the invoice line is included when the invoice discount is calculated.';
                    Visible = false;
                }
                field("Inv. Discount Amount"; Rec."Inv. Discount Amount")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the total calculated invoice discount amount for the line.';
                    Visible = false;
                }
                field("Exclude Warranty"; Rec."Exclude Warranty")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that the warranty discount is excluded on this line.';
                }
                field("Exclude Contract Discount"; Rec."Exclude Contract Discount")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that the contract discount is excluded for the item, resource, or cost on this line.';
                }
                field(Warranty; Rec.Warranty)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that a warranty discount is available on this line of type Item or Resource.';
                }
                field("Warranty Disc. %"; Rec."Warranty Disc. %")
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                    ToolTip = 'Specifies the percentage of the warranty discount that is valid for the items or resources on this line.';
                    Visible = false;
                }
                field("Contract No."; Rec."Contract No.")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the number of the contract, if the service order originated from a service contract.';
                }
                field("Contract Disc. %"; Rec."Contract Disc. %")
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                    ToolTip = 'Specifies the contract discount percentage that is valid for the items, resources, and costs on this line.';
                    Visible = false;
                }
                field("VAT %"; Rec."VAT %")
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                    ToolTip = 'Specifies the VAT percentage used to calculate Amount Including VAT on this line.';
                    Visible = false;
                }
                field("VAT Base Amount"; Rec."VAT Base Amount")
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                    ToolTip = 'Specifies the amount that serves as a base for calculating the Amount Including VAT field.';
                    Visible = false;
                }
                field("Amount Including VAT"; Rec."Amount Including VAT")
                {
                    ApplicationArea = Service;
                    BlankZero = true;
                    ToolTip = 'Specifies the net amount, including VAT, for this line.';
                    Visible = false;
                }
                field("Gen. Bus. Posting Group"; Rec."Gen. Bus. Posting Group")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the vendor''s or customer''s trade type to link transactions made for this business partner with the appropriate general ledger account according to the general posting setup.';
                    Visible = false;
                }
                field("Gen. Prod. Posting Group"; Rec."Gen. Prod. Posting Group")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the item''s product type to link transactions made for this item with the appropriate general ledger account according to the general posting setup.';
                    Visible = false;
                }
                field("Posting Group"; Rec."Posting Group")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the inventory posting group assigned to the item.';
                    Visible = false;
                }
                field("Planned Delivery Date"; Rec."Planned Delivery Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the planned date that the shipment will be delivered at the customer''s address. If the customer requests a delivery date, the program calculates whether the items will be available for delivery on this date. If the items are available, the planned delivery date will be the same as the requested delivery date. If not, the program calculates the date that the items are available for delivery and enters this date in the Planned Delivery Date field.';
                }
                field("Needed by Date"; Rec."Needed by Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when you require the item to be available for a service order.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when the service line should be posted.';

                    trigger OnValidate()
                    begin
                        PostingDateOnAfterValidate();
                    end;
                }
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the related project.';
                    Visible = false;
                }
                field("Job Task No."; Rec."Job Task No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the related project task.';
                    Visible = false;
                }
                field("Job Planning Line No."; Rec."Job Planning Line No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the project planning line number associated with this line. This establishes a link that can be used to calculate actual usage.';
                    Visible = false;
                }
                field("Job Line Type"; Rec."Job Line Type")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the type of journal line that is created in the Project Planning Line table from this line.';
                    Visible = false;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("ShortcutDimCode[3]"; ShortcutDimCode[3])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,3';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(3),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(3, ShortcutDimCode[3]);
                    end;
                }
                field("ShortcutDimCode[4]"; ShortcutDimCode[4])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,4';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(4),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(4, ShortcutDimCode[4]);
                    end;
                }
                field("ShortcutDimCode[5]"; ShortcutDimCode[5])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,5';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(5),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(5, ShortcutDimCode[5]);
                    end;
                }
                field("ShortcutDimCode[6]"; ShortcutDimCode[6])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,6';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(6),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(6, ShortcutDimCode[6]);
                    end;
                }
                field("ShortcutDimCode[7]"; ShortcutDimCode[7])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,7';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(7),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(7, ShortcutDimCode[7]);
                    end;
                }
                field("ShortcutDimCode[8]"; ShortcutDimCode[8])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,8';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(8),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(8, ShortcutDimCode[8]);
                    end;
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
                SubPageLink = "Table ID" = const(Database::"Service Line"),
                              "No." = field("Document No."),
                              "Document Type" = field("Document Type"),
                              "Line No." = field("Line No.");
            }
#endif
            part("Attached Documents List"; "Doc. Attachment List Factbox")
            {
                ApplicationArea = Service;
                Caption = 'Documents';
                UpdatePropagation = Both;
                SubPageLink = "Table ID" = const(Database::"Service Line"),
                              "No." = field("Document No."),
                              "Document Type" = field("Document Type"),
                              "Line No." = field("Line No.");
                Visible = false;
            }
            part(Control1904739907; "Service Line FactBox")
            {
                ApplicationArea = Service;
                SubPageLink = "Document Type" = field("Document Type"),
                              "Document No." = field("Document No."),
                              "Line No." = field("Line No.");
                Visible = false;
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("O&rder")
            {
                Caption = 'O&rder';
                Image = "Order";
                action("Service Ledger E&ntries")
                {
                    ApplicationArea = Service;
                    Caption = 'Service Ledger E&ntries';
                    Image = ServiceLedger;
                    RunObject = Page "Service Ledger Entries";
                    RunPageLink = "Service Order No." = field("Document No.");
                    RunPageView = sorting("Service Order No.", "Service Item No. (Serviced)", "Entry Type", "Moved from Prepaid Acc.", "Posting Date", Open, Type);
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View all the ledger entries for the service item or service order that result from posting transactions in service documents.';
                }
                action("&Warranty Ledger Entries")
                {
                    ApplicationArea = Service;
                    Caption = '&Warranty Ledger Entries';
                    Image = WarrantyLedger;
                    RunObject = Page "Warranty Ledger Entries";
                    RunPageLink = "Service Order No." = field("Document No.");
                    RunPageView = sorting("Service Order No.", "Posting Date", "Document No.");
                    ToolTip = 'View all the ledger entries for the service item or service order that result from posting transactions in service documents that contain warranty agreements.';
                }
                action("&Job Ledger Entries")
                {
                    ApplicationArea = Jobs;
                    Caption = '&Project Ledger Entries';
                    Image = JobLedger;
                    RunObject = Page "Job Ledger Entries";
                    RunPageLink = "Service Order No." = field("Document No.");
                    RunPageView = sorting("Service Order No.", "Posting Date")
                                  where("Entry Type" = const(Usage));
                    ToolTip = 'View all the project ledger entries that result from posting transactions in the service document that involve a project.';
                }
                action("&Customer Card")
                {
                    ApplicationArea = Service;
                    Caption = '&Customer Card';
                    Image = Customer;
                    RunObject = Page "Customer Card";
                    RunPageLink = "No." = field("Customer No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View detailed information about the customer.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Service Comment Sheet";
                    RunPageLink = "Table Name" = const("Service Header"),
                                  "Table Subtype" = field("Document Type"),
                                  "No." = field("Document No."),
                                  Type = const(General);
                    ToolTip = 'View or add comments for the record.';
                }
                action("S&hipments")
                {
                    ApplicationArea = Service;
                    Caption = 'S&hipments';
                    Image = Shipment;
                    ToolTip = 'View related posted service shipments.';

                    trigger OnAction()
                    var
                        ServShptHeader: Record "Service Shipment Header";
                    begin
                        ServShptHeader.Reset();
                        ServShptHeader.FilterGroup(2);
                        ServShptHeader.SetRange("Order No.", Rec."Document No.");
                        ServShptHeader.FilterGroup(0);
                        PAGE.RunModal(0, ServShptHeader)
                    end;
                }
                action(Invoices)
                {
                    ApplicationArea = Service;
                    Caption = 'Invoices';
                    Image = Invoice;
                    ToolTip = 'View a list of ongoing sales invoices for the order.';

                    trigger OnAction()
                    var
                        ServInvHeader: Record "Service Invoice Header";
                    begin
                        ServInvHeader.Reset();
                        ServInvHeader.FilterGroup(2);
                        ServInvHeader.SetRange("Order No.", Rec."Document No.");
                        ServInvHeader.FilterGroup(0);
                        PAGE.RunModal(0, ServInvHeader)
                    end;
                }
                action("Warehouse Shipment Lines")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Warehouse Shipment Lines';
                    Image = ShipmentLines;
                    RunObject = Page "Whse. Shipment Lines";
                    RunPageLink = "Source Type" = const(5902),
#pragma warning disable AL0603
                                  "Source Subtype" = field("Document Type"),
#pragma warning restore AL0603
                                  "Source No." = field("Document No.");
                    RunPageView = sorting("Source Type", "Source Subtype", "Source No.", "Source Line No.");
                    ToolTip = 'View ongoing warehouse shipments for the document, in advanced warehouse configurations.';
                }
            }
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
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
                group("Item Availability by")
                {
                    Caption = 'Item Availability by';
                    Image = ItemAvailability;
                    action("Event")
                    {
                        ApplicationArea = Planning;
                        Caption = 'Event';
                        Image = "Event";
                        ToolTip = 'View how the actual and the projected available balance of an item will develop over time according to supply and demand events.';

                        trigger OnAction()
                        begin
                            ServAvailabilityMgt.ShowItemAvailabilityFromServLine(Rec, "Item Availability Type"::"Event");
                            CurrPage.Update(true);
                        end;
                    }
                    action(Period)
                    {
                        ApplicationArea = Planning;
                        Caption = 'Period';
                        Image = Period;
                        ToolTip = 'View the projected quantity of the item over time according to time periods, such as day, week, or month.';

                        trigger OnAction()
                        begin
                            ServAvailabilityMgt.ShowItemAvailabilityFromServLine(Rec, "Item Availability Type"::Period);
                            CurrPage.Update(true);
                        end;
                    }
                    action(Variant)
                    {
                        ApplicationArea = Planning;
                        Caption = 'Variant';
                        Image = ItemVariant;
                        ToolTip = 'View or edit the item''s variants. Instead of setting up each color of an item as a separate item, you can set up the various colors as variants of the item.';

                        trigger OnAction()
                        begin
                            ServAvailabilityMgt.ShowItemAvailabilityFromServLine(Rec, "Item Availability Type"::Variant);
                            CurrPage.Update(true);
                        end;
                    }
                    action(Location)
                    {
                        AccessByPermission = TableData Location = R;
                        ApplicationArea = Location;
                        Caption = 'Location';
                        Image = Warehouse;
                        ToolTip = 'View the actual and projected quantity of the item per location.';

                        trigger OnAction()
                        begin
                            ServAvailabilityMgt.ShowItemAvailabilityFromServLine(Rec, "Item Availability Type"::Location);
                            CurrPage.Update(true);
                        end;
                    }
                    action(Lot)
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Lot';
                        Image = LotInfo;
                        RunObject = Page "Item Availability by Lot No.";
                        RunPageLink = "No." = field("No."),
                            "Location Filter" = field("Location Code"),
                            "Variant Filter" = field("Variant Code");
                        ToolTip = 'View the current and projected quantity of the item in each lot.';
                    }
                    action("BOM Level")
                    {
                        ApplicationArea = Planning;
                        Caption = 'BOM Level';
                        Image = BOMLevel;
                        ToolTip = 'View availability figures for items on bills of materials that show how many units of a parent item you can make based on the availability of child items.';

                        trigger OnAction()
                        begin
                            ServAvailabilityMgt.ShowItemAvailabilityFromServLine(Rec, "Item Availability Type"::BOM);
                            CurrPage.Update(true);
                        end;
                    }
                }
                action(ReservationEntries)
                {
                    AccessByPermission = TableData Item = R;
                    ApplicationArea = Reservation;
                    Caption = 'Reservation Entries';
                    Image = ReservationLedger;
                    ToolTip = 'View the entries for every reservation that is made, either manually or automatically.';

                    trigger OnAction()
                    begin
                        Rec.ShowReservationEntries(true);
                    end;
                }
                action(ItemTrackingLines)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Item &Tracking Lines';
                    Image = ItemTrackingLines;
                    ShortCutKey = 'Ctrl+Alt+I';
                    ToolTip = 'View or edit serial, lot and package numbers that are assigned to the item on the document or journal line.';

                    trigger OnAction()
                    begin
                        Rec.OpenItemTrackingLines();
                    end;
                }
                action(SelectItemSubstitution)
                {
                    AccessByPermission = TableData "Item Substitution" = R;
                    ApplicationArea = Service;
                    Caption = 'Select Item Substitution';
                    Image = SelectItemSubstitution;
                    ToolTip = 'Select another item that has been set up to be traded instead of the original item if it is unavailable.';

                    trigger OnAction()
                    begin
                        CurrPage.SaveRecord();
                        Rec.ShowItemSub();
                        CurrPage.Update(true);
                        if (Rec.Reserve = Rec.Reserve::Always) and (Rec."No." <> xRec."No.") then begin
                            Rec.AutoReserve();
                            CurrPage.Update(false);
                        end;
                    end;
                }
                action("&Fault/Resol. Codes Relationships")
                {
                    ApplicationArea = Service;
                    Caption = '&Fault/Resol. Codes Relationships';
                    Image = FaultDefault;
                    ToolTip = 'View or edit the relationships between fault codes, including the fault, fault area, and symptom codes, as well as resolution codes and service item groups. It displays the existing combinations of these codes for the service item group of the service item from which you accessed the window and the number of occurrences for each one.';

                    trigger OnAction()
                    begin
                        SelectFaultResolutionCode();
                    end;
                }
                action("Order &Promising")
                {
                    AccessByPermission = TableData "Order Promising Line" = R;
                    ApplicationArea = OrderPromising;
                    Caption = 'Order &Promising';
                    Image = OrderPromising;
                    ToolTip = 'Calculate the shipment and delivery dates based on the item''s known and expected availability dates, and then promise the dates to the customer.';

                    trigger OnAction()
                    begin
                        Rec.ShowOrderPromisingLine();
                    end;
                }
                action(DocAttach)
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
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Insert &Ext. Texts")
                {
                    AccessByPermission = TableData "Extended Text Header" = R;
                    ApplicationArea = Service;
                    Caption = 'Insert &Ext. Texts';
                    Image = Text;
                    ToolTip = 'Insert the extended item description that is set up for the item that is being processed on the line.';

                    trigger OnAction()
                    begin
                        InsertExtendedText(true);
                    end;
                }
                action("Insert &Starting Fee")
                {
                    ApplicationArea = Service;
                    Caption = 'Insert &Starting Fee';
                    Image = InsertStartingFee;
                    ToolTip = 'Add a general starting fee for the service order.';

                    trigger OnAction()
                    begin
                        InsertStartFee();
                    end;
                }
                action("Insert &Travel Fee")
                {
                    ApplicationArea = Service;
                    Caption = 'Insert &Travel Fee';
                    Image = InsertTravelFee;
                    ToolTip = 'Add a general travel fee for the service order.';

                    trigger OnAction()
                    begin
                        InsertTravelFee();
                    end;
                }
                action(SelectMultiItems)
                {
                    AccessByPermission = TableData Item = R;
                    ApplicationArea = Service;
                    Caption = 'Select items';
                    Ellipsis = true;
                    Image = NewItem;
                    ToolTip = 'Add two or more items from the full list of available items.';

                    trigger OnAction()
                    begin
                        Rec.SelectMultipleItems();
                    end;
                }
                action("S&plit Resource Line")
                {
                    ApplicationArea = Service;
                    Caption = 'S&plit Resource Line';
                    Image = Split;
                    ToolTip = 'Distribute a resource''s work on multiple service item lines. If the same resource works on all the service items in the service order, you can register the total resource hours for one service item only and then split the resource line to divide the resource hours onto the resource lines for the other service items.';

                    trigger OnAction()
                    begin
                        Rec.SplitResourceLine();
                    end;
                }
                action(Reserve)
                {
                    ApplicationArea = Reservation;
                    Caption = '&Reserve';
                    Image = Reserve;
                    ToolTip = 'Reserve the quantity that is required on the document line that you opened this window for.';

                    trigger OnAction()
                    begin
                        Rec.ShowReservation();
                    end;
                }
                action("Order &Tracking")
                {
                    ApplicationArea = Service;
                    Caption = 'Order &Tracking';
                    Image = OrderTracking;
                    ToolTip = 'Tracks the connection of a supply to its corresponding demand. This can help you find the original demand that created a specific production order or purchase order.';

                    trigger OnAction()
                    begin
                        Rec.ShowTracking();
                    end;
                }
                action("Ca&talog Items")
                {
                    AccessByPermission = TableData "Nonstock Item" = R;
                    ApplicationArea = Service;
                    Caption = 'Ca&talog Items';
                    Image = NonStockItem;
                    ToolTip = 'View the list of items that you do not carry in inventory. ';

                    trigger OnAction()
                    begin
                        Rec.ShowNonstock();
                        CurrPage.Update();
                    end;
                }
                action("&Create Lines from Time Sheets")
                {
                    ApplicationArea = Service;
                    Caption = '&Create Lines from Time Sheets';
                    Image = CreateLinesFromTimesheet;
                    ToolTip = 'Insert service lines according to an existing time sheet.';

                    trigger OnAction()
                    var
                        ServTimeSheetMgt: Codeunit "Serv. Time Sheet Mgt.";
                        ConfirmManagement: Codeunit "Confirm Management";
                    begin
                        if ConfirmManagement.GetResponseOrDefault(Text012, true) then begin
                            ServHeader.Get(Rec."Document Type", Rec."Document No.");
                            ServTimeSheetMgt.CreateServDocLinesFromTS(ServHeader);
                        end;
                    end;
                }
            }
            group("Price/Discount")
            {
                Caption = 'Price/Discount';
                Image = Price;
                action("Get Price")
                {
                    ApplicationArea = Service;
                    Caption = 'Get Price';
                    Image = Price;
                    ToolTip = 'Insert the lowest possible price in the Unit Price field according to any special price that you have set up.';

                    trigger OnAction()
                    begin
                        Rec.PickPrice();
                        CurrPage.Update();
                    end;
                }
                action("Adjust Service Price")
                {
                    ApplicationArea = Service;
                    Caption = 'Adjust Service Price';
                    Image = PriceAdjustment;
                    ToolTip = 'Adjust existing service prices according to changed costs, spare parts, and resource hours. Note that prices are not adjusted for service items that belong to service contracts, service items with a warranty, items service on lines that are partially or fully invoiced. When you run the service price adjustment, all discounts in the order are replaced by the values of the service price adjustment.';

                    trigger OnAction()
                    var
                        ServPriceMgmt: Codeunit "Service Price Management";
                    begin
                        ServItemLine.Get(Rec."Document Type", Rec."Document No.", ServItemLineNo);
                        ServPriceMgmt.ShowPriceAdjustment(ServItemLine);
                    end;
                }
                action("Undo Price Adjustment")
                {
                    ApplicationArea = Service;
                    Caption = 'Undo Price Adjustment';
                    Image = Undo;
                    ToolTip = 'Cancel the latest price change and reset the previous price.';

                    trigger OnAction()
                    var
                        ServPriceMgmt: Codeunit "Service Price Management";
                        ConfirmManagement: Codeunit "Confirm Management";
                    begin
                        if ConfirmManagement.GetResponseOrDefault(Text011, true) then begin
                            ServPriceMgmt.CheckServItemGrCode(Rec);
                            ServPriceMgmt.ResetAdjustedLines(Rec);
                        end;
                    end;
                }
                action("Get Li&ne Discount")
                {
                    AccessByPermission = TableData "Sales Line Discount" = R;
                    ApplicationArea = Service;
                    Caption = 'Get Li&ne Discount';
                    Image = LineDiscount;
                    ToolTip = 'Insert the best possible discount in the Line Discount field according to any special discounts that you have set up.';
                    Visible = not ExtendedPriceEnabled;

                    trigger OnAction()
                    begin
                        Rec.PickDiscount();
                        CurrPage.Update();
                    end;
                }
                action(GetLineDiscount)
                {
                    AccessByPermission = TableData "Sales Discount Access" = R;
                    ApplicationArea = Service;
                    Caption = 'Get Li&ne Discount';
                    Image = LineDiscount;
                    Visible = ExtendedPriceEnabled;
                    ToolTip = 'Insert the best possible discount in the Line Discount field according to any special discounts that you have set up.';

                    trigger OnAction()
                    begin
                        Rec.PickDiscount();
                        CurrPage.Update();
                    end;
                }
                action("Calculate Invoice Discount")
                {
                    ApplicationArea = Service;
                    Caption = 'Calculate &Invoice Discount';
                    Image = CalculateInvoiceDiscount;
                    ToolTip = 'Calculate the invoice discount that applies to the service order.';

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"Service-Disc. (Yes/No)", Rec);
                    end;
                }
            }
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action(Post)
                {
                    ApplicationArea = Service;
                    Caption = 'P&ost';
                    Image = PostOrder;
                    ShortCutKey = 'F9';
                    ToolTip = 'Finalize the document or journal by posting the amounts and quantities to the related accounts in your company books.';

                    trigger OnAction()
                    var
                        ServiceLine: Record "Service Line";
                        TempServiceLine: Record "Service Line" temporary;
                    begin
                        Rec.Modify(true);
                        CurrPage.SaveRecord();
                        CurrPage.SetSelectionFilter(ServiceLine);

                        if ServiceLine.FindSet() then
                            repeat
                                TempServiceLine.Init();
                                TempServiceLine := ServiceLine;
                                OnPostOnBeforeInsertTempServiceLine(ServiceLine, TempServiceLine);
                                TempServiceLine.Insert();
                            until ServiceLine.Next() = 0
                        else
                            exit;

                        ServHeader.Get(Rec."Document Type", Rec."Document No.");
                        ServHeader.SendToPostWithLines(Codeunit::"Service-Post (Yes/No)", TempServiceLine);

                        ServiceLine.SetRange("Document Type", ServHeader."Document Type");
                        ServiceLine.SetRange("Document No.", ServHeader."No.");
                        if ServiceLine.IsEmpty() then begin
                            Rec.Reset();
                            CurrPage.Close();
                        end else
                            CurrPage.Update();
                    end;
                }
                action(Preview)
                {
                    ApplicationArea = Service;
                    Caption = 'Preview Posting';
                    Image = ViewPostedOrder;
                    ShortCutKey = 'Ctrl+Alt+F9';
                    ToolTip = 'Review the different types of entries that will be created when you post the document or journal.';

                    trigger OnAction()
                    var
                        ServiceLine: Record "Service Line";
                        TempServiceLine: Record "Service Line" temporary;
                        ServicePostYesNo: Codeunit "Service-Post (Yes/No)";
                    begin
                        CurrPage.SaveRecord();
                        CurrPage.SetSelectionFilter(ServiceLine);

                        if ServiceLine.Findset() then
                            repeat
                                TempServiceLine.Init();
                                TempServiceLine := ServiceLine;
                                if TempServiceLine.Insert() then;
                            until ServiceLine.Next() = 0
                        else
                            exit;

                        ServHeader.Get(Rec."Document Type", Rec."Document No.");
                        ServicePostYesNo.PreviewDocumentWithLines(ServHeader, TempServiceLine);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                group(Category_Posting)
                {
                    Caption = 'Posting';
                    ShowAs = SplitButton;

                    actionref(Post_Promoted; Post)
                    {
                    }
                    actionref(Preview_Promoted; Preview)
                    {
                    }
                }
                actionref(Reserve_Promoted; Reserve)
                {
                }
                actionref(SelectMultiItems_Promoted; SelectMultiItems)
                {
                }
            }
            group(Category_Order)
            {
                Caption = 'Order';

                actionref("S&hipments_Promoted"; "S&hipments")
                {
                }
                actionref(Invoices_Promoted; Invoices)
                {
                }
                actionref("&Customer Card_Promoted"; "&Customer Card")
                {
                }
                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }
            }
            group(Category_Line)
            {
                Caption = 'Line';

                actionref(ItemTrackingLines_Promoted; ItemTrackingLines)
                {
                }
                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref(ReservationEntries_Promoted; ReservationEntries)
                {
                }
                actionref(SelectItemSubstitution_Promoted; SelectItemSubstitution)
                {
                }
                actionref("&Fault/Resol. Codes Relationships_Promoted"; "&Fault/Resol. Codes Relationships")
                {
                }
                actionref("Order &Promising_Promoted"; "Order &Promising")
                {
                }
                actionref(DocAttach_Promoted; DocAttach)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Item: Record Item;
    begin
        Rec.ShowShortcutDimCode(ShortcutDimCode);
        if Rec."Variant Code" = '' then
            VariantCodeMandatory := Item.IsVariantMandatory(Rec.Type = Rec.Type::Item, Rec."No.");
    end;

    trigger OnDeleteRecord(): Boolean
    var
        ServiceLineReserve: Codeunit "Service Line-Reserve";
    begin
        if (Rec.Quantity <> 0) and Rec.ItemExists(Rec."No.") then begin
            Commit();
            if not ServiceLineReserve.DeleteLineConfirm(Rec) then
                exit(false);
            ServiceLineReserve.DeleteLine(Rec);
        end;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        if not AddExtendedText then
            Rec."Line No." := Rec.GetLineNo();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Clear(ShortcutDimCode);

        if ServHeader.Get(Rec."Document Type", Rec."Document No.") then
            if ServHeader."Link Service to Service Item" then
                if SelectionFilter <> SelectionFilter::"Lines Not Item Related" then
                    Rec.Validate("Service Item Line No.", ServItemLineNo)
                else
                    Rec.Validate("Service Item Line No.", 0)
            else
                Rec.Validate("Service Item Line No.", 0);
    end;

    trigger OnOpenPage()
    var
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
    begin
        ExtendedPriceEnabled := PriceCalculationMgt.IsExtendedPriceCalculationEnabled();
        Clear(SelectionFilter);
        SelectionFilter := SelectionFilter::"Lines per Selected Service Item";
        OnOpenPageOnBeforeSetSelectionFilter(SelectionFilter);
        SetSelectionFilter();
        SetItemReferenceVisibility();

        ServMgtSetup.Get();
        case ServMgtSetup."Fault Reporting Level" of
            ServMgtSetup."Fault Reporting Level"::None:
                begin
                    FaultAreaCodeVisible := false;
                    SymptomCodeVisible := false;
                    FaultCodeVisible := false;
                    ResolutionCodeVisible := false;
                end;
            ServMgtSetup."Fault Reporting Level"::Fault:
                begin
                    FaultAreaCodeVisible := false;
                    SymptomCodeVisible := false;
                    FaultCodeVisible := true;
                    ResolutionCodeVisible := true;
                end;
            ServMgtSetup."Fault Reporting Level"::"Fault+Symptom":
                begin
                    FaultAreaCodeVisible := false;
                    SymptomCodeVisible := true;
                    FaultCodeVisible := true;
                    ResolutionCodeVisible := true;
                end;
            ServMgtSetup."Fault Reporting Level"::"Fault+Symptom+Area (IRIS)":
                begin
                    FaultAreaCodeVisible := true;
                    SymptomCodeVisible := true;
                    FaultCodeVisible := true;
                    ResolutionCodeVisible := true;
                end;
        end;
    end;

    var
        ServMgtSetup: Record "Service Mgt. Setup";
        ServHeader: Record "Service Header";
        ServItemLine: Record "Service Item Line";
        ServAvailabilityMgt: Codeunit "Serv. Availability Mgt.";
        ServItemLineNo: Integer;
        AddExtendedText: Boolean;
        ExtendedPriceEnabled: Boolean;
        ItemReferenceVisible: Boolean;
        VariantCodeMandatory: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text008: Label 'You cannot open the window because %1 is %2 in the %3 table.';
#pragma warning restore AA0470
        Text011: Label 'This will reset all price adjusted lines to default values. Do you want to continue?';
        Text012: Label 'Do you want to create service lines from time sheets?';
#pragma warning restore AA0074

    protected var
        ShortcutDimCode: array[8] of Code[20];
        FaultAreaCodeVisible: Boolean;
        SymptomCodeVisible: Boolean;
        FaultCodeVisible: Boolean;
        ResolutionCodeVisible: Boolean;
        SelectionFilter: Option "All Service Lines","Lines per Selected Service Item","Lines Not Item Related";

    procedure CalcInvDisc(var ServLine: Record "Service Line")
    begin
        CODEUNIT.Run(CODEUNIT::"Service-Calc. Discount", ServLine);
    end;

    procedure Initialize(NewServItemLine: Integer)
    begin
        ServItemLineNo := NewServItemLine;
    end;

    procedure SetSelectionFilter()
    begin
        OnBeforeSetSelectionFilter(SelectionFilter, Rec);
        case SelectionFilter of
            SelectionFilter::"All Service Lines":
                Rec.SetRange("Service Item Line No.");
            SelectionFilter::"Lines per Selected Service Item":
                Rec.SetRange("Service Item Line No.", ServItemLineNo);
            SelectionFilter::"Lines Not Item Related":
                Rec.SetRange("Service Item Line No.", 0);
        end;
        CurrPage.Update(false);
    end;

    procedure InsertExtendedText(Unconditionally: Boolean)
    var
        ServiceTransferExtText: Codeunit "Service Transfer Ext. Text";
    begin
        OnBeforeInsertExtendedText(Rec);

        if ServiceTransferExtText.ServCheckIfAnyExtText(Rec, Unconditionally) then begin
            AddExtendedText := true;
            CurrPage.SaveRecord();
            AddExtendedText := false;
            ServiceTransferExtText.InsertServExtText(Rec);
        end;
        if ServiceTransferExtText.MakeUpdate() then
            CurrPage.Update();
    end;

    local procedure InsertStartFee()
    var
        ServOrderMgt: Codeunit ServOrderManagement;
    begin
        Clear(ServOrderMgt);
        if ServOrderMgt.InsertServCost(Rec, 1, false) then
            CurrPage.Update();
    end;

    local procedure InsertTravelFee()
    var
        ServOrderMgt: Codeunit ServOrderManagement;
    begin
        Clear(ServOrderMgt);
        if ServOrderMgt.InsertServCost(Rec, 0, false) then
            CurrPage.Update();
    end;

    local procedure SelectFaultResolutionCode()
    var
        ServSetup: Record "Service Mgt. Setup";
        FaultResolutionRelation: Page "Fault/Resol. Cod. Relationship";
    begin
        ServSetup.Get();
        case ServSetup."Fault Reporting Level" of
            ServSetup."Fault Reporting Level"::None:
                Error(
                  Text008,
                  ServSetup.FieldCaption("Fault Reporting Level"),
                  ServSetup."Fault Reporting Level", ServSetup.TableCaption());
        end;
        ServItemLine.Get(Rec."Document Type", Rec."Document No.", Rec."Service Item Line No.");
        Clear(FaultResolutionRelation);
        FaultResolutionRelation.SetDocument(DATABASE::"Service Line", Rec."Document Type".AsInteger(), Rec."Document No.", Rec."Line No.");
        FaultResolutionRelation.SetFilters(Rec."Symptom Code", Rec."Fault Code", Rec."Fault Area Code", ServItemLine."Service Item Group Code");
        FaultResolutionRelation.RunModal();
        CurrPage.Update(false);
    end;

    local procedure NoOnAfterValidate()
    begin
        InsertExtendedText(false);

        if (Rec.Reserve = Rec.Reserve::Always) and
           (Rec."Outstanding Qty. (Base)" <> 0) and
           (Rec."No." <> xRec."No.")
        then begin
            CurrPage.SaveRecord();
            Rec.AutoReserve();
            CurrPage.Update(false);
        end;
    end;

    procedure LocationCodeOnAfterValidate()
    begin
        if (Rec.Reserve = Rec.Reserve::Always) and
           (Rec."Outstanding Qty. (Base)" <> 0) and
           (Rec."Location Code" <> xRec."Location Code")
        then begin
            CurrPage.SaveRecord();
            Rec.AutoReserve();
        end;
        CurrPage.Update(true);
    end;

    procedure QuantityOnAfterValidate()
    var
        UpdateIsDone: Boolean;
    begin
        if Rec.Type = Rec.Type::Item then
            case Rec.Reserve of
                Rec.Reserve::Always:
                    begin
                        CurrPage.SaveRecord();
                        Rec.AutoReserve();
                        CurrPage.Update(false);
                        UpdateIsDone := true;
                    end;
                Rec.Reserve::Optional:
                    if (Rec.Quantity < xRec.Quantity) and (xRec.Quantity > 0) then begin
                        CurrPage.SaveRecord();
                        CurrPage.Update(false);
                        UpdateIsDone := true;
                    end;
            end;

        if (Rec.Type = Rec.Type::Item) and
           ((Rec.Quantity <> xRec.Quantity) or (Rec."Line No." = 0)) and
           not UpdateIsDone
        then
            CurrPage.Update(true);
    end;

    procedure PostingDateOnAfterValidate()
    begin
        if (Rec.Reserve = Rec.Reserve::Always) and
           (Rec."Outstanding Qty. (Base)" <> 0) and
           (Rec."Posting Date" <> xRec."Posting Date")
        then begin
            CurrPage.SaveRecord();
            Rec.AutoReserve();
            CurrPage.Update(false);
        end;
    end;

    local procedure SelectionFilterOnAfterValidate()
    begin
        CurrPage.Update();
        SetSelectionFilter();
    end;

    local procedure SetItemReferenceVisibility()
    var
        ItemReference: Record "Item Reference";
    begin
        ItemReferenceVisible := not ItemReference.IsEmpty();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertExtendedText(var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetSelectionFilter(var SelectionFilter: Option "All Service Lines","Lines per Selected Service Item","Lines Not Item Related"; var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenPageOnBeforeSetSelectionFilter(var SelectionFilter: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostOnBeforeInsertTempServiceLine(var ServiceLine: Record "Service Line"; var TempServiceLine: Record "Service Line" temporary)
    begin
    end;
}

