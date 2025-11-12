// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Ledger;

using Microsoft.FixedAssets.FixedAsset;

query 267 "FA Ledger Entries"
{
    Caption = 'FA Ledger Entries';

    elements
    {
        dataitem(FA_Ledger_Entry; "FA Ledger Entry")
        {
            column(Entry_No; "Entry No.")
            {
            }
            column(G_L_Entry_No; "G/L Entry No.")
            {
            }
            column(FA_No; "FA No.")
            {
            }
            column(FA_Class_Code; "FA Class Code")
            {
            }
            column(FA_Subclass_Code; "FA Subclass Code")
            {
            }
            column(FA_Posting_Date; "FA Posting Date")
            {
            }
            column(FA_Posting_Category; "FA Posting Category")
            {
            }
            column(FA_Posting_Type; "FA Posting Type")
            {
            }
            column(FA_Location_Code; "FA Location Code")
            {
            }
            column(Depreciation_Book_Code; "Depreciation Book Code")
            {
            }
            column(Posting_Date; "Posting Date")
            {
            }
            column(Document_Date; "Document Date")
            {
            }
            column(Document_Type; "Document Type")
            {
            }
            column(Document_No; "Document No.")
            {
            }
            column(Gen_Bus_Posting_Group; "Gen. Bus. Posting Group")
            {
            }
            column(Gen_Prod_Posting_Group; "Gen. Prod. Posting Group")
            {
            }
            column(Location_Code; "Location Code")
            {
            }
            column(Source_Code; "Source Code")
            {
            }
            column(Reason_Code; "Reason Code")
            {
            }
            column(Amount_LCY; "Amount (LCY)")
            {
            }
            column(Dimension_Set_ID; "Dimension Set ID")
            {
            }
            dataitem(Fixed_Asset; "Fixed Asset")
            {
                DataItemLink = "No." = FA_Ledger_Entry."FA No.";
                column(FA_Description; Description)
                {
                }
            }
        }
    }
}

