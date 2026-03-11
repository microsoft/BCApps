// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using Microsoft.Sales.Archive;

/// <summary>
/// TableExtension Shpfy Sales Header Archive (ID 30203) extends Record Sales Header Archive.
/// </summary>
tableextension 30203 "Shpfy Sales Header Archive" extends "Sales Header Archive"
{
    fields
    {
        field(30100; "Shpfy Order Id"; BigInteger)
        {
            Caption = 'Shopify Order Id';
            DataClassification = CustomerContent;
            Editable = false;
        }

        field(30101; "Shpfy Order No."; Code[50])
        {
            Caption = 'Shopify Order No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}