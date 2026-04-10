// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Setup;

tableextension 11553 "Bank Export/Import Setup CH" extends "Bank Export/Import Setup"
{
    fields
    {
        field(11500; "SEPA CT Batch Booking"; Enum "SEPA CT Batch Booking")
        {
            Caption = 'SEPA CT Batch Booking';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies how the Batch Booking (BtchBookg) value is set in SEPA Credit Transfer exports.Auto uses the default behavior (returns true when the number of payments for batch booking is ≥ 50).Always sets the value to true, and Never sets it to false.';
        }
    }
}
