// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.RoleCenters;

profile "AP COORDINATOR"
{
    Caption = 'Accounts Payable Coordinator';
    ProfileDescription = 'Functionality for finance staff coordinating AP work, such as verifying paperwork, applying criteria from the accounting manager to determine which invoices to pay, processing supplier payments, and reconciling bank statements.';
    RoleCenter = 9002;
    Enabled = false;
}
