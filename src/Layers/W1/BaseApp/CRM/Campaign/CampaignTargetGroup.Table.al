// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Campaign;

using Microsoft.CRM.Contact;
using Microsoft.Sales.Customer;

table 7030 "Campaign Target Group"
{
    Caption = 'Campaign Target Group';
    DataClassification = CustomerContent;

    fields
    {
        field(1; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Customer,Contact';
            OptionMembers = Customer,Contact;
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = if (Type = const(Customer)) Customer
            else
            if (Type = const(Contact)) Contact where(Type = filter(Company));
        }
        field(3; "Campaign No."; Code[20])
        {
            Caption = 'Campaign No.';
            TableRelation = Campaign;
        }
    }

    keys
    {
        key(Key1; Type, "No.", "Campaign No.")
        {
            Clustered = true;
        }
        key(Key2; "Campaign No.")
        {
        }
        key(Key3; "No.")
        {
        }
    }

    fieldgroups
    {
    }

    procedure CopyTo(var TempCampaignTargetGroup: Record "Campaign Target Group" temporary) Found: Boolean;
    begin
        Found := FindSet();
        if Found then
            repeat
                TempCampaignTargetGroup := Rec;
                TempCampaignTargetGroup.Insert();
            until Next() = 0;
    end;
}

