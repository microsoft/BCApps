// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Finance.GeneralLedger.Ledger;

tableextension 28030 WHTGLRegister extends "G/L Register"
{
    fields
    {
        field(28040; "From WHT Entry No."; Integer)
        {
            Caption = 'From WHT Entry No.';
            DataClassification = CustomerContent;
            TableRelation = "WHT Entry";
        }
        field(28041; "To WHT Entry No."; Integer)
        {
            Caption = 'To WHT Entry No.';
            DataClassification = CustomerContent;
            TableRelation = "WHT Entry";
        }
    }
}
