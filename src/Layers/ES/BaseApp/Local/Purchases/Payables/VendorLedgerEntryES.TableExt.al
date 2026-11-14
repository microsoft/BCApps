// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

#pragma warning disable AS0088
tableextension 10715 "Vendor Ledger Entry ES" extends "Vendor Ledger Entry"
{
    fields
    {
        field(10707; "Correction Type"; Option)
        {
            Caption = 'Correction Type';
            DataClassification = CustomerContent;
            OptionCaption = ' ,Replacement,Difference,Removal';
            OptionMembers = " ",Replacement,Difference,Removal;
        }
        field(10708; "Corrected Invoice No."; Code[20])
        {
            Caption = 'Corrected Invoice No.';
            DataClassification = CustomerContent;
        }
    }
}
