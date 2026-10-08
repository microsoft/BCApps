// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Setup;

tableextension 27037 "DIOT VAT Posting Setup" extends "VAT Posting Setup"
{
    fields
    {
#pragma warning disable AS0099 // Preserve the existing field ID for compatibility.
        field(27000; "DIOT WHT %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'DIOT WHT Percent';
            DataClassification = CustomerContent;
            MinValue = 0;
        }
#pragma warning restore AS0099
    }
}
