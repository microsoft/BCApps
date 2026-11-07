// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Comment;

using Microsoft.Intercompany.Partner;

tableextension 8510 "IC Comment Line Relations" extends "Comment Line"
{
    fields
    {
        modify("No.")
        {
            TableRelation = if ("Table Name" = const("IC Partner")) "IC Partner";
        }
    }
}
