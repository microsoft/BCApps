// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

pageextension 10028 "Service Invoice Subform NA" extends "Service Invoice Subform"
{
    layout
    {
        addafter("Line Amount")
        {
            field("Amount Including VAT"; Rec."Amount Including VAT")
            {
                ToolTip = 'Specifies the sum of the amounts in the Amount Including VAT fields on the associated sales lines.';
            }
        }
    }
}
