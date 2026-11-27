// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Foundation.Company;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Manufacturing.Setup;

permissionset 149929 "Subc WIP Nav Test"
{
    Assignable = false;
    Permissions = tabledata "Manufacturing Setup" = R,
                  tabledata "General Ledger Setup" = R,
                  tabledata "Company Information" = R;
}
