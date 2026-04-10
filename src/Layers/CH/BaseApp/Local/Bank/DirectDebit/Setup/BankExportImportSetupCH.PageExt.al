// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Setup;

pageextension 11553 "Bank Export/Import Setup CH" extends "Bank Export/Import Setup"
{
    layout
    {
        addafter("Check Export Codeunit Name")
        {
            field("SEPA CT Batch Booking"; Rec."SEPA CT Batch Booking")
            {
                ApplicationArea = All;
            }
        }
    }
}
