// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.MarketingText;
using System.Text;

table 5835 "Marketing Text Suggestion"
{
    TableType = Temporary;
    Extensible = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; No; Integer)
        {
        }
        field(2; GeneratedText; Blob)
        {
        }
        field(3; Voice; Enum "Entity Text Tone")
        {
        }
        field(4; TextFormat; Enum "Entity Text Format")
        {
        }
        field(5; Emphasis; Enum "Entity Text Emphasis")
        {
        }
        field(6; PageCaption; Text[2048])
        {
        }
        field(7; SelectedAttributes; Blob)
        {
        }
    }

    keys
    {
        key(PK; No)
        {
        }
    }
}