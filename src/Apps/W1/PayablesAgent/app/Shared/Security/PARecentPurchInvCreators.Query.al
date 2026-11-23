// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Agent.PayablesAgent;

using Microsoft.Purchases.History;

query 3304 "PA Recent Purch. Inv. Creators"
{
    Access = Internal;
    QueryType = Normal;
    InherentEntitlements = X;
    InherentPermissions = X;
    OrderBy = descending(PostingDate);
    TopNumberOfRows = 500;

    elements
    {
        dataitem(PurchInvHeader; "Purch. Inv. Header")
        {
            column(PostingDate; "Posting Date")
            {
            }
            column(SystemCreatedBy; SystemCreatedBy)
            {
            }
        }
    }
}
