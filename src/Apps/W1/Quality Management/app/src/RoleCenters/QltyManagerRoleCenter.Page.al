// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.RoleCenters;

using Microsoft.Assembly.History;
using Microsoft.Foundation.Navigate;
using Microsoft.Inventory.Counting.History;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Configuration.Template.Test;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Reports;
using Microsoft.QualityManagement.Setup;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Warehouse.Activity.History;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.InternalDocument;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Worksheet;

page 20426 "Qlty. Manager Role Center"
{
    Caption = 'Quality Manager';
    PageType = RoleCenter;
    ApplicationArea = QualityManagement;

    layout
    {
        area(RoleCenter)
        {
            group(SettingsForRoleCenterMain)
            {
                ShowCaption = false;

                part("Qlty. Inspection Activities"; "Qlty. Inspection Activities")
                {
                    Caption = 'Quality Inspections';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Qlty_Processing_ItemTracing)
            {
                ApplicationArea = Warehouse;
                Caption = 'Item Tracing';
                Image = ItemTracing;
                RunObject = Page "Item Tracing";
                ToolTip = 'Trace where a lot/serial/package number assigned to the item was used, for example, to find which lot a defective component came from or to find all the customers that have received items containing the defective component.';
            }
            group(Qlty_Processing_Reports)
            {
                Caption = 'Reports';

                action(Qlty_Processing_CertificateOfAnalysis)
                {
                    Caption = 'Certificate of Analysis';
                    Image = Certificate;
                    ToolTip = 'Printable Certificate of Analysis (COA) report.';
                    RunObject = Report "Qlty. Certificate of Analysis";
                }
                action(Qlty_Processing_GeneralInspectionReport)
                {
                    Caption = 'Inspection Report';
                    Image = PrintReport;
                    ToolTip = 'Specifies a printable general purpose inspection report.';
                    RunObject = Report "Qlty. General Purpose Inspect.";
                }
                action(Qlty_Processing_NonConformanceReport)
                {
                    Image = PrintReport;
                    Caption = 'Non Conformance Report';
                    ToolTip = 'Specifies the Non Conformance Report has a layout suitable for quality inspection templates that typically contain Non Conformance Report questions.';
                    RunObject = Report "Qlty. Non-Conformance";
                }
            }
            group(Qlty_Processing_Analysis)
            {
                Caption = 'Analysis';

                action(Qlty_Processing_InspectionLines)
                {
                    Caption = 'Quality Inspection Lines';
                    Image = AnalysisView;
                    ToolTip = 'Historical Quality Inspection lines. Use this with analysis mode.';
                    RunObject = Page "Qlty. Inspection Lines";
                }
            }
            group(Qlty_Processing_SemiRegularSetup)
            {
                Caption = 'Templates and Rules';

                action(Qlty_Processing_ConfigureInspectionTemplates)
                {
                    Caption = 'Inspection Templates';
                    Image = Database;
                    RunObject = Page "Qlty. Inspection Template List";
                    RunPageMode = Edit;
                    ToolTip = 'Specifies a Quality Inspection Template is an inspection plan containing a set of questions and data points that you want to collect.';
                }
                action(Qlty_Processing_ConfigureInspectionGenerationRules)
                {
                    Caption = 'Inspection Generation Rules';
                    Image = MapDimensions;
                    RunObject = Page "Qlty. Inspection Gen. Rules";
                    RunPageMode = Edit;
                    ToolTip = 'Specifies a Quality Inspection generation rule defines when you want to ask a set of questions or other data that you want to collect that is defined in a template. You connect a template to a source table, and set the criteria to use that template with the table filter. When these filter criteria is met, then it will choose that template. When there are multiple matches, it will use the first template that it finds, based on the sort order.';
                }
                action(Qlty_Processing_ConfigureTests)
                {
                    Caption = 'Tests';
                    Image = MapDimensions;
                    RunObject = Page "Qlty. Tests";
                    RunPageMode = Edit;
                    ToolTip = 'Specifies a quality inspection test is a data points to capture, or questions, or measurements.';
                }
            }
            group(Qlty_Processing_Configure)
            {
                Caption = 'Setup';
                Tooltip = 'Configure the Quality Management';
                Image = Setup;

                action(Qlty_Processing_Setup)
                {
                    Caption = 'Quality Management Setup';
                    Tooltip = 'Change the behavior of the Quality Management.';
                    RunObject = Page "Qlty. Management Setup";
                    Image = Setup;
                    RunPageMode = Edit;
                }
            }
        }
        area(Embedding)
        {
            action(Qlty_Embedding_ShowInspections)
            {
                Caption = 'Quality Inspections';
                Image = TaskQualityMeasure;
                ToolTip = 'See existing Quality Inspections and create a new inspection.';
                RunObject = Page "Qlty. Inspection List";
            }
            action(Qlty_Embedding_Items)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Items';
                RunObject = Page "Item List";
                ToolTip = 'View or edit detailed information for the products that you trade in. The item card can be of type Inventory or Service to specify if the item is a physical unit or a labor time unit. Here you also define if items in inventory or on incoming orders are automatically reserved for outbound documents and whether order tracking links are created between demand and supply to reflect planning actions.';
            }
            action(Qlty_Embedding_PurchaseOrders)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Purchase Orders';
                RunObject = Page "Purchase Order List";
                ToolTip = 'Create purchase orders to mirror sales documents that vendors send to you. This enables you to record the cost of purchases and to track accounts payable. Posting purchase orders dynamically updates inventory levels so that you can minimize inventory costs and provide better customer service. Purchase orders allow partial receipts, unlike with purchase invoices, and enable drop shipment directly from your vendor to your customer. Purchase orders can be created automatically from PDF or image files from your vendors by using the Incoming Documents feature.';
            }
            action(Qlty_Embedding_ReleasedProductionOrders)
            {
                ApplicationArea = Manufacturing;
                Caption = 'Released Production Orders';
                RunObject = Page "Released Production Orders";
                ToolTip = 'View the list of released production order that are ready for warehouse activities.';
            }
            action(Qlty_Embedding_LotNoInformation)
            {
                ApplicationArea = ItemTracking;
                Caption = 'Lot No. Information';
                RunObject = Page "Lot No. Information List";
                Image = ListPage;
                ToolTip = 'View the list of Lot No. Information records.';
            }
        }
        area(Sections)
        {
            group(Qlty_Sections_SalesAndPurchases)
            {
                Caption = 'Sales & Purchases';

                action(Qlty_Sections_SalesOrders)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Sales Orders';
                    Image = "Order";
                    RunObject = Page "Sales Order List";
                    ToolTip = 'Record your agreements with customers to sell certain products on certain delivery and payment terms. Sales orders, unlike sales invoices, allow you to ship partially, deliver directly from your vendor to your customer, initiate warehouse handling, and print various customer-facing documents. Sales invoicing is integrated in the sales order process.';
                }
                action(Qlty_Sections_SalesOrdersReleased)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Released';
                    RunObject = Page "Sales Order List";
                    RunPageView = where(Status = filter(Released));
                    ToolTip = 'View the list of released source documents that are ready for warehouse activities.';
                }
                action(Qlty_Sections_SalesOrdersPartShipped)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Partially Shipped';
                    RunObject = Page "Sales Order List";
                    RunPageView = where(Status = filter(Released),
                                        "Completely Shipped" = filter(false));
                    ToolTip = 'View the list of ongoing warehouse shipments that are partially completed.';
                }
                action(Qlty_Sections_SalesReturnOrders)
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Sales Return Orders';
                    Image = ReturnOrder;
                    RunObject = Page "Sales Return Order List";
                    ToolTip = 'Compensate your customers for incorrect or damaged items that you sent to them and received payment for. Sales return orders enable you to receive items from multiple sales documents with one sales return, automatically create related sales credit memos or other return-related documents, such as a replacement sales order, and support warehouse documents for the item handling. Note: If an erroneous sale has not been paid yet, you can simply cancel the posted sales invoice to automatically revert the financial transaction.';
                }
                action(Qlty_Sections_PurchaseOrders)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Purchase Orders';
                    RunObject = Page "Purchase Order List";
                    ToolTip = 'Create purchase orders to mirror sales documents that vendors send to you. This enables you to record the cost of purchases and to track accounts payable. Posting purchase orders dynamically updates inventory levels so that you can minimize inventory costs and provide better customer service. Purchase orders allow partial receipts, unlike with purchase invoices, and enable drop shipment directly from your vendor to your customer. Purchase orders can be created automatically from PDF or image files from your vendors by using the Incoming Documents feature.';
                }
                action(Qlty_Sections_PurchaseOrdersReleased)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Released';
                    RunObject = Page "Purchase Order List";
                    RunPageView = where(Status = filter(Released));
                    ToolTip = 'View the list of released source documents that are ready for warehouse activities.';
                }
                action(Qlty_Sections_PurchaseOrdersPartReceived)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Partially Received';
                    RunObject = Page "Purchase Order List";
                    RunPageView = where(Status = filter(Released),
                                        "Completely Received" = filter(false));
                    ToolTip = 'View the list of ongoing warehouse receipts that are partially completed.';
                }
                action(Qlty_Sections_PurchaseReturnOrders)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Purchase Return Orders';
                    RunObject = Page "Purchase Return Order List";
                    ToolTip = 'Create purchase return orders to mirror sales return documents that vendors send to you for incorrect or damaged items that you have paid for and then returned to the vendor. Purchase return orders enable you to ship back items from multiple purchase documents with one purchase return and support warehouse documents for the item handling. Purchase return orders can be created automatically from PDF or image files from your vendors by using the Incoming Documents feature. Note: If you have not yet paid for an erroneous purchase, you can simply cancel the posted purchase invoice to automatically revert the financial transaction.';
                }
            }
            group(Qlty_Sections_ReferenceData)
            {
                Caption = 'Reference Data';
                Image = ReferenceData;

                action(Qlty_Sections_Items)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Items';
                    Image = Item;
                    RunObject = Page "Item List";
                    ToolTip = 'View or edit detailed information for the products that you trade in. The item card can be of type Inventory or Service to specify if the item is a physical unit or a labor time unit. Here you also define if items in inventory or on incoming orders are automatically reserved for outbound documents and whether order tracking links are created between demand and supply to reflect planning actions.';
                }
                action(Qlty_Sections_LotNoInformation)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Lot No. Information';
                    RunObject = Page "Lot No. Information List";
                    Image = ListPage;
                    ToolTip = 'View the list of Lot No. Information records.';
                }
                action(Qlty_Sections_Locations)
                {
                    ApplicationArea = Location;
                    Caption = 'Locations';
                    Image = Warehouse;
                    RunObject = Page "Location List";
                    ToolTip = 'View the list of warehouse locations.';
                }
            }
            group(Qlty_Sections_Journals)
            {
                Caption = 'Journals';
                Image = Journals;

                action(Qlty_Sections_WarehouseItemJournals)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Warehouse Item Journals';
                    RunObject = Page "Whse. Journal Batches List";
                    RunPageView = where("Template Type" = const(Item));
                    ToolTip = 'Adjust the quantity of an item in a particular bin or bins. For instance, you might find some items in a bin that are not registered in the system, or you might not be able to pick the quantity needed because there are fewer items in a bin than was calculated by the program. The bin is then updated to correspond to the actual quantity in the bin. In addition, it creates a balancing quantity in the adjustment bin, for synchronization with item ledger entries, which you can then post with an item journal.';
                }
                action(Qlty_Sections_WarehouseReclassificationJournals)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Warehouse Reclassification Journals';
                    RunObject = Page "Whse. Journal Batches List";
                    RunPageView = where("Template Type" = const(Reclassification));
                    ToolTip = 'Change information on warehouse entries, such as zone codes and bin codes.';
                }
                action(Qlty_Sections_ItemJournals)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Item Journals';
                    RunObject = Page "Item Journal Batches";
                    RunPageView = where("Template Type" = const(Item),
                                        Recurring = const(false));
                    ToolTip = 'Post item transactions directly to the item ledger to adjust inventory in connection with purchases, sales, and positive or negative adjustments without using documents. You can save sets of item journal lines as standard journals so that you can perform recurring postings quickly. A condensed version of the item journal function exists on item cards for quick adjustment of an items inventory quantity.';
                }
                action(Qlty_Sections_ItemReclassificationJournals)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Item Reclassification Journals';
                    RunObject = Page "Item Journal Batches";
                    RunPageView = where("Template Type" = const(Transfer),
                                        Recurring = const(false));
                    ToolTip = 'Change information recorded on item ledger entries. Typical inventory information to reclassify includes dimensions and sales campaign codes, but you can also perform basic inventory transfers by reclassifying location and bin codes. Lot/serial/package numbers and their expiration dates must be reclassified with the Item Tracking Reclassification journal.';
                }
            }
            group(Qlty_Sections_Worksheet_Group)
            {
                Caption = 'Worksheet';
                Image = Worksheets;

                action(Qlty_Sections_PutAwayWorksheets)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Put-away Worksheets';
                    RunObject = Page "Worksheet Names List";
                    RunPageView = where("Template Type" = const("Put-away"));
                    ToolTip = 'Plan and initialize item put-aways.';
                }
                action(Qlty_Sections_MovementWorksheets)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Movement Worksheets';
                    RunObject = Page "Worksheet Names List";
                    RunPageView = where("Template Type" = const(Movement));
                    ToolTip = 'Plan and initiate movements of items between bins according to an advanced warehouse configuration.';
                }
                action(Qlty_Sections_InternalPutAways)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Internal Put-aways';
                    RunObject = Page "Whse. Internal Put-away List";
                    ToolTip = 'View the list of ongoing put-aways for internal activities, such as production.';
                }
            }
            group(Qlty_Sections_PostedDocuments)
            {
                Caption = 'Posted Documents';
                Image = FiledPosted;

                action(Qlty_Sections_PostedWarehouseShipments)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Posted Warehouse Shipments';
                    RunObject = Page "Posted Whse. Shipment List";
                    ToolTip = 'Open the list of posted warehouse shipments.';
                }
                action(Qlty_Sections_PostedSalesShipments)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Posted Sales Shipments';
                    RunObject = Page "Posted Sales Shipments";
                    ToolTip = 'Open the list of posted sales shipments.';
                }
                action(Qlty_Sections_PostedTransferShipments)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Posted Transfer Shipments';
                    RunObject = Page "Posted Transfer Shipments";
                    ToolTip = 'Open the list of posted transfer shipments.';
                }
                action(Qlty_Sections_PostedReturnShipments)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Posted Return Shipments';
                    RunObject = Page "Posted Return Shipments";
                    ToolTip = 'Open the list of posted return shipments.';
                }
                action(Qlty_Sections_PostedWarehouseReceipts)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Posted Warehouse Receipts';
                    RunObject = Page "Posted Whse. Receipt List";
                    ToolTip = 'Open the list of posted warehouse receipts.';
                }
                action(Qlty_Sections_PostedPurchaseReceipts)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Posted Purchase Receipts';
                    RunObject = Page "Posted Purchase Receipts";
                    ToolTip = 'Open the list of posted purchase receipts.';
                }
                action(Qlty_Sections_PostedTransferReceipts)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Posted Transfer Receipts';
                    RunObject = Page "Posted Transfer Receipts";
                    ToolTip = 'Open the list of posted transfer receipts.';
                }
                action(Qlty_Sections_PostedReturnReceipts)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Posted Return Receipts';
                    Image = PostedReturnReceipt;
                    RunObject = Page "Posted Return Receipts";
                    ToolTip = 'Open the list of posted return receipts.';
                }
                action(Qlty_Sections_PostedPhysicalInventoryOrders)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Posted Physical Inventory Orders';
                    RunObject = Page "Posted Phys. Invt. Order List";
                    ToolTip = 'View the list of posted inventory counts.';
                }
                action(Qlty_Sections_PostedPhysicalInventoryRecordings)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Posted Physical Inventory Recordings';
                    RunObject = Page "Posted Phys. Invt. Rec. List";
                    ToolTip = 'View the list of finished inventory counts, ready for posting.';
                }
                action(Qlty_Sections_PostedAssemblyOrders)
                {
                    ApplicationArea = Assembly;
                    Caption = 'Posted Assembly Orders';
                    RunObject = Page "Posted Assembly Orders";
                    ToolTip = 'View completed assembly orders.';
                }
                action(Qlty_Sections_Navigate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Find entries...';
                    Image = Navigate;
                    RunObject = Page Navigate;
                    ShortCutKey = 'Ctrl+Alt+Q';
                    ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';
                }
            }
            group(Qlty_Sections_RegisteredDocuments)
            {
                Caption = 'Registered Documents';
                Image = RegisteredDocs;

                action(Qlty_Sections_RegisteredWarehousePicks)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Registered Warehouse Picks';
                    Image = RegisteredDocs;
                    RunObject = Page "Registered Whse. Picks";
                    ToolTip = 'View warehouse picks that have been performed.';
                }
                action(Qlty_Sections_RegisteredWarehousePutAways)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Registered Warehouse Put-aways';
                    Image = RegisteredDocs;
                    RunObject = Page "Registered Whse. Put-aways";
                    ToolTip = 'View the list of completed put-away activities.';
                }
                action(Qlty_Sections_RegisteredWarehouseMovements)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Registered WarehouseMovements';
                    Image = RegisteredDocs;
                    RunObject = Page "Registered Whse. Movements";
                    ToolTip = 'View the list of completed warehouse movements.';
                }
            }
        }
    }
}
