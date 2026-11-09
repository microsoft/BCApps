// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Comment;

using Microsoft.Bank.BankAccount;
using Microsoft.CRM.Campaign;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Insurance;
using Microsoft.Intercompany.Partner;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

tableextension 97 "Comment Line Relations" extends "Comment Line"
{
    fields
    {
        modify("No.")
        {
            TableRelation = if ("Table Name" = const("G/L Account")) "G/L Account"
            else
            if ("Table Name" = const(Customer)) Customer
            else
            if ("Table Name" = const(Vendor)) Vendor
            else
            if ("Table Name" = const(Item)) Item
            else
            if ("Table Name" = const(Resource)) Resource
            else
            if ("Table Name" = const(Job)) Job
            else
            if ("Table Name" = const("Resource Group")) "Resource Group"
            else
            if ("Table Name" = const("Bank Account")) "Bank Account"
            else
            if ("Table Name" = const(Campaign)) Campaign
            else
            if ("Table Name" = const("Fixed Asset")) "Fixed Asset"
            else
            if ("Table Name" = const(Insurance)) Insurance
            else
            if ("Table Name" = const("IC Partner")) "IC Partner";
        }
    }
}
