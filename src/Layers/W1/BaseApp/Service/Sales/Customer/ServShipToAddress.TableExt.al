// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

using Microsoft.Service.Setup;

tableextension 6466 "Serv. Ship-To Address" extends "Ship-to Address"
{
    fields
    {
        field(5900; "Service Zone Code"; Code[10])
        {
            Caption = 'Service Zone Code';
            DataClassification = CustomerContent;
            TableRelation = "Service Zone";
        }
    }
}
