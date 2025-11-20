// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Requisition;

using Microsoft.Assembly.Document;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.History;
using System.Security.AccessControl;
using System.Security.User;

table 5525 "Manufacturing User Template"
{
    Caption = 'Manufacturing User Template';
    ReplicateData = true;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                UserSelection: Codeunit "User Selection";
            begin
                UserSelection.ValidateUserName("User ID");
            end;
        }
        field(2; "Create Purchase Order"; Enum "Planning Create Purchase Order")
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Create Purchase Order';
        }
        field(3; "Create Production Order"; Enum Microsoft.Manufacturing.Document."Planning Create Prod. Order")
        {
            Caption = 'Create Production Order';
        }
        field(4; "Create Transfer Order"; Enum "Planning Create Transfer Order")
        {
            AccessByPermission = TableData "Transfer Header" = R;
            Caption = 'Create Transfer Order';
        }
        field(5; "Create Assembly Order"; Enum "Planning Create Assembly Order")
        {
            AccessByPermission = TableData "Assembly Header" = R;
            Caption = 'Create Assembly Order';
        }
        field(11; "Purchase Req. Wksh. Template"; Code[10])
        {
            Caption = 'Purchase Req. Wksh. Template';
            TableRelation = "Req. Wksh. Template";
        }
        field(12; "Purchase Wksh. Name"; Code[10])
        {
            Caption = 'Purchase Wksh. Name';
            TableRelation = "Requisition Wksh. Name".Name where("Worksheet Template Name" = field("Purchase Req. Wksh. Template"));
        }
        field(15; "Prod. Req. Wksh. Template"; Code[10])
        {
            Caption = 'Prod. Req. Wksh. Template';
            TableRelation = "Req. Wksh. Template";
        }
        field(16; "Prod. Wksh. Name"; Code[10])
        {
            Caption = 'Prod. Wksh. Name';
            TableRelation = "Requisition Wksh. Name".Name where("Worksheet Template Name" = field("Prod. Req. Wksh. Template"));
        }
        field(19; "Transfer Req. Wksh. Template"; Code[10])
        {
            Caption = 'Transfer Req. Wksh. Template';
            TableRelation = "Req. Wksh. Template";
        }
        field(20; "Transfer Wksh. Name"; Code[10])
        {
            Caption = 'Transfer Wksh. Name';
            TableRelation = "Requisition Wksh. Name".Name where("Worksheet Template Name" = field("Transfer Req. Wksh. Template"));
        }
        field(21; "Make Orders"; Option)
        {
            Caption = 'Make Orders';
            OptionCaption = 'The Active Line,The Active Order,All Lines';
            OptionMembers = "The Active Line","The Active Order","All Lines";
        }
    }

    keys
    {
        key(Key1; "User ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

