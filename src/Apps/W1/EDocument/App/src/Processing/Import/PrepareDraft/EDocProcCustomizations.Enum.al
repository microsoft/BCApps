// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

using Microsoft.eServices.EDocument.Processing.Interfaces;
using Microsoft.EServices.EDocument.Processing.Import.Sales;

enum 6110 "E-Doc. Proc. Customizations" implements
    IVendorProvider,
    IPurchaseOrderProvider,
    IPurchaseLineProvider,
    IUnitOfMeasureProvider,
    IEDocumentCreatePurchaseInvoice,
    IEDocumentCreatePurchaseCreditMemo,
    ICustomerProvider,
    ISalesLineProvider,
    IEDocumentCreateSalesOrder
{
    Extensible = true;
    DefaultImplementation = IVendorProvider = "E-Doc. Providers",
                            IPurchaseOrderProvider = "E-Doc. Providers",
                            IPurchaseLineProvider = "E-Doc. Providers",
                            IUnitOfMeasureProvider = "E-Doc. Providers",
                            IEDocumentCreatePurchaseInvoice = "E-Doc. Create Purchase Invoice",
                            IEDocumentCreatePurchaseCreditMemo = "E-Doc. Create Purch. Cr. Memo",
                            ICustomerProvider = "E-Doc. Sales Providers",
                            ISalesLineProvider = "E-Doc. Sales Providers",
                            IEDocumentCreateSalesOrder = "E-Doc. Create Sales Order";

    value(0; Default)
    {
    }
}
