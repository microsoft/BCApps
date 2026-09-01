// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.RoleCenters;

using Microsoft.Purchases.RoleCenters;
using Microsoft.Service.Document;

pageextension 6463 "Serv. Purchasing Manager RC" extends "Purchasing Manager Role Center"
{
    actions
    {
        addafter("Blanket Orders1")
        {
            action("Orders3")
            {
                ApplicationArea = Service;
                Caption = 'Service Orders';
                RunObject = page "Service Orders";
            }
        }
    }
}
