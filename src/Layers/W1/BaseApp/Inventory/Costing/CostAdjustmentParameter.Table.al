// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

table 5808 "Cost Adjustment Parameter"
{
    Caption = 'Cost Adjustment Parameter';
    TableType = Temporary;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(10; "Online Adjustment"; Boolean)
        {
            Caption = 'Online Adjustment';
        }
        field(20; "Post to G/L"; Boolean)
        {
            Caption = 'Post to G/L';
        }
        field(30; "Skip Job Item Cost Update"; Boolean)
        {
            Caption = 'Skip Job Item Cost Update';
        }
        field(40; "Item-By-Item Commit"; Boolean)
        {
            Caption = 'Item-By-Item Commit';
        }
        field(50; "Max Duration"; Duration)
        {
            Caption = 'Max Duration';
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

}