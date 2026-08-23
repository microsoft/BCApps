// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.Sales.Comment;

tableextension 10975 "FR Sales Comment Line" extends "Sales Comment Line"
{
    fields
    {
        field(10970; "FR Regulatory Comment Type"; Enum "FR Regulatory Comment Type")
        {
            Caption = 'French Regulatory Type';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the French regulatory purpose of the comment. The selected type is automatically added as a prefix when the comment is exported to an electronic invoice.';
        }
    }
}