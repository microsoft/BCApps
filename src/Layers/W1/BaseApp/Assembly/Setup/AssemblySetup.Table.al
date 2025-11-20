// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Setup;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Location;
using Microsoft.Sales.History;

table 905 "Assembly Setup"
{
    Caption = 'Assembly Setup';
    DataClassification = CustomerContent;
    DrillDownPageID = "Assembly Setup";
    LookupPageID = "Assembly Setup";

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(5; "Stockout Warning"; Boolean)
        {
            Caption = 'Stockout Warning';
            InitValue = true;
        }
        field(10; "Assembly Order Nos."; Code[20])
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Assembly Order Nos.';
            TableRelation = "No. Series";
        }
        field(20; "Assembly Quote Nos."; Code[20])
        {
            Caption = 'Assembly Quote Nos.';
            TableRelation = "No. Series";
        }
        field(30; "Blanket Assembly Order Nos."; Code[20])
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Blanket Assembly Order Nos.';
            TableRelation = "No. Series";
        }
        field(50; "Posted Assembly Order Nos."; Code[20])
        {
            Caption = 'Posted Assembly Order Nos.';
            TableRelation = "No. Series";
        }
        field(100; "Copy Component Dimensions from"; Option)
        {
            AccessByPermission = TableData Dimension = R;
            Caption = 'Copy Component Dimensions from';
            OptionCaption = 'Item/Resource Card,Order Header';
            OptionMembers = "Item/Resource Card","Order Header";
        }
        field(110; "Default Location for Orders"; Code[10])
        {
            Caption = 'Default Location for Orders';
            TableRelation = Location;
        }
        field(120; "Copy Comments when Posting"; Boolean)
        {
            Caption = 'Copy Comments when Posting';
            InitValue = true;
        }
        field(130; "Create Movements Automatically"; Boolean)
        {
            Caption = 'Create Movements Automatically';
        }
        field(140; "Default Gen. Bus. Post. Group"; Code[20])
        {
            Caption = 'Default General Business Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

