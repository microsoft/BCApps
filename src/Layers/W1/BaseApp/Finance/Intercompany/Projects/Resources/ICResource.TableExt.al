// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Resource;

using Microsoft.Intercompany.GLAccount;

/// <summary>
/// Extends Resource with Intercompany-specific fields.
/// Adds the IC Partner Purchase G/L Account No. field for intercompany purchase posting.
/// </summary>
tableextension 8496 ICResource extends Resource
{
    fields
    {
        field(60; "IC Partner Purch. G/L Acc. No."; Code[20])
        {
            Caption = 'IC Partner Purch. G/L Acc. No.';
            DataClassification = CustomerContent;
            TableRelation = "IC G/L Account";
            ToolTip = 'Specifies the intercompany g/l account number in your partner''s company that the amount for this resource is posted to.';
        }
    }
}
