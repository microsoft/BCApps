// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

#pragma warning disable AL0520 // Accepted: the base table is obsolete but this extension must remain for upgrade compatibility.
tableextension 18244 "GST Invoice Pos Buffer" extends "Invoice Post. Buffer"
#pragma warning restore AL0520
{
    fields
    {
        field(18244; "FA Non-Availment"; Boolean)
        {
            Caption = 'FA Non-Availment';
            DataClassification = CustomerContent;
        }
        field(18245; "FA Non-Availment Amount"; Decimal)
        {
            Caption = 'FA Non-Availment Amount';
            DataClassification = CustomerContent;
        }
        field(18246; "FA Availment"; Boolean)
        {
            Caption = 'FA Availment';
            DataClassification = CustomerContent;
        }
        field(18247; "FA Custom Duty Amount"; Decimal)
        {
            Caption = 'FA Custom Duty Amount';
            DataClassification = CustomerContent;
        }
    }

}
