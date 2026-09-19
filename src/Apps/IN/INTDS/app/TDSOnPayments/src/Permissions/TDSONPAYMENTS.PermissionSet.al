// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.TDS.TDSOnPayments;

permissionset 18766 "TDS ON PAYMENTS"
{
    Access = Public;
    Assignable = true;
    Caption = 'TDS on Payments';

    Permissions = tabledata "Provisional Entry" = RIMD;
}
