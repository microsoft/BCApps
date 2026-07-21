// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.Sales.Comment;

pageextension 10975 "FR Sales Comment Sheet" extends "Sales Comment Sheet"
{
    layout
    {
        addafter(Comment)
        {
            field("FR Regulatory Comment Type"; Rec."FR Regulatory Comment Type")
            {
                ApplicationArea = Comments;
                ToolTip = 'Specifies the French regulatory purpose when this comment must be included in the electronic invoice.';
            }
        }
    }
}