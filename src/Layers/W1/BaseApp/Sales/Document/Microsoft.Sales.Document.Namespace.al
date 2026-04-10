// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project oder for license information.
// ------------------------------------------------------------------------------------------------

/// <summary>
/// Provides functionality for managing sales documents throughout the sales process lifecycle.
/// </summary>
/// <remarks>
/// The Microsoft.Sales.Document namespace contains tables, pages, codeunits, reports, queries, and enumerations
/// that handle all aspects of sales document management in Business Central.
///
/// ## Core Document Types
///
/// This namespace supports six primary sales document types:
///
/// - **Sales Quote**: Initial customer proposals that can be converted to orders or invoices
/// - **Sales Order**: Confirmed customer orders for goods or services with shipping and invoicing
/// - **Sales Invoice**: Direct billing documents for immediate posting
/// - **Sales Credit Memo**: Documents for processing customer refunds and returns
/// - **Blanket Sales Order**: Long-term agreements with customers for recurring deliveries
/// - **Sales Return Order**: Documents for managing customer returns and return receipts
///
/// ## Key Tables
///
/// The namespace centers around two primary tables:
///
/// - **Sales Header (Table 36)**: Stores document-level information including customer details,
///   dates, amounts, shipping information, and document status
/// - **Sales Line (Table 37)**: Contains line-level details for items, resources, charges,
///   quantities, prices, and discounts
///
/// Supporting tables include:
/// - Sales Planning Line: Planning information for sales order fulfillment
/// - Sales Prepayment: Prepayment percentage configurations by item and customer
/// - Item Charge Assignment (Sales): Allocation of item charges across shipments and receipts
/// - Standard Sales Code/Line: Reusable standard sales transactions
/// - Drop Shipment Post Buffer: Temporary storage for drop shipment posting
///
/// ## Document Lifecycle
///
/// Sales documents follow a standard lifecycle:
///
/// 1. **Creation**: Documents are created manually or converted from other document types
/// 2. **Entry**: Lines are added with items, resources, or other line types
/// 3. **Release**: Documents are released for further processing (shipping/invoicing)
/// 4. **Posting**: Documents are posted to create ledger entries and posted documents
///
/// ## Key Processes
///
/// ### Document Conversion
/// - Quotes can be converted to orders or invoices
/// - Blanket orders generate regular sales orders
/// - Orders can be partially or fully shipped and invoiced
///
/// ### Discount Calculation
/// - Line discounts based on customer/item combinations
/// - Invoice discounts based on document totals
/// - Automatic or manual discount calculation modes
///
/// ### Availability and Planning
/// - Real-time inventory availability checking
/// - Integration with planning worksheets
/// - Drop shipment and special order handling
///
/// ### Document Release and Approval
/// - Manual and automatic release workflows
/// - Integration with approval processes
/// - Warehouse integration for picking and shipping
///
/// ## Integration Points
///
/// This namespace integrates with:
/// - **Microsoft.Sales.Customer**: Customer master data and credit management
/// - **Microsoft.Sales.Posting**: Document posting and ledger entry creation
/// - **Microsoft.Sales.History**: Posted document archives
/// - **Microsoft.Inventory**: Item availability and reservation
/// - **Microsoft.Warehouse**: Pick, ship, and receive operations
/// - **Microsoft.Finance**: VAT, dimensions, and payment terms
/// - **Microsoft.Pricing**: Price and discount calculations
///
/// ## Batch Processing
///
/// The namespace includes reports for batch operations:
/// - Batch posting of invoices, credit memos, orders, and return orders
/// - Combining shipments into consolidated invoices
/// - Combining return receipts into consolidated credit memos
/// - Cleanup of invoiced documents (orders, blanket orders, return orders)
///
/// ## Extensibility
///
/// Key extension points include:
/// - Document type enumerations for custom document types
/// - Events on document validation and posting
/// - Customizable standard sales codes
/// - Flexible prepayment configurations
/// </remarks>
namespace Microsoft.Sales.Document;
