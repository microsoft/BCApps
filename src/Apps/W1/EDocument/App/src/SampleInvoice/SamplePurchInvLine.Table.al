// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.DemoData;

using Microsoft.Purchases.Document;
using Microsoft.Utilities;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Inventory.Item;
using Microsoft.Finance.AllocationAccount;
using Microsoft.Projects.Resources.Resource;

/// <summary>
/// Temporary table for sample purchase invoice line data used in PDF generation.
/// </summary>
table 6119 "Sample Purch. Inv. Line"
{
    InherentEntitlements = RMX;
    InherentPermissions = RMX;
    TableType = Temporary;
    Caption = 'Sample Purch. Inv. Line';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; Type; Enum "Purchase Line Type")
        {
            Caption = 'Type';
        }
        field(4; "No."; Code[20])
        {
            Caption = 'No.';
            ValidateTableRelation = false;
            TableRelation = if (Type = const(" ")) "Standard Text"
            else
            if (Type = const("G/L Account")) "G/L Account" where("Direct Posting" = const(true), "Account Type" = const(Posting), Blocked = const(false))
            else
            if (Type = const("Fixed Asset")) "Fixed Asset"
            else
            if (Type = const("Charge (Item)")) "Item Charge"
            else
            if (Type = const(Item)) Item
            else
            if (Type = const("Allocation Account")) "Allocation Account"
            else
            if (Type = const(Resource)) Resource;
        }
        field(5; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
        }
        field(6; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(7; Quantity; Decimal)
        {
            Caption = 'Quantity';
            AutoFormatType = 0;
        }
        field(8; "Direct Unit Cost"; Decimal)
        {
            Caption = 'Direct Unit Cost';
            AutoFormatType = 0;
        }
        field(9; "Deferral Code"; Code[10])
        {
            Caption = 'Deferral Code';
        }
        field(10; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
        }
        field(11; "Line Amount"; Decimal)
        {
            Caption = 'Line Amount';
            AutoFormatType = 2;
            AutoFormatExpression = '';
        }
    }

    keys
    {
        key(PK; "Document No.", "Line No.")
        {
            Clustered = true;
        }
    }
}
