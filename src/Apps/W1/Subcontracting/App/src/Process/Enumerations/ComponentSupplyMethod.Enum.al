// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

enum 99001500 "Component Supply Method"
{
    Extensible = true;
    // No supply method is selected.
    value(0; Empty)
    {
        Caption = ' ', Locked = true;
    }
    // The subcontractor provides the required component materials.
    value(1; VendorSupplied)
    {
        Caption = 'Vendor-Supplied';
    }
    // Your company owns the components and stores them at the subcontractor location (consignment stock).
    value(2; ConsignmentAtVendor)
    {
        Caption = 'Consignment at Vendor';
    }
    // Components are sent to the subcontractor through a transfer order.
    value(3; TransferToVendor)
    {
        Caption = 'Transfer to Vendor';
    }
}