// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

tableextension 6130 "E-Doc. Purch. Inv. Line" extends "Purch. Inv. Line"
{
    fields
    {
        field(6101; "Search Similarity Score"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Search Similarity Score';
            Editable = false;
            DataClassification = SystemMetadata;
        }

    }

    keys
    {
        key(KeySearch; "Search Similarity Score")
        {
        }
    }

    internal procedure GetStyle() Result: Text
    begin
        if Rec."Search Similarity Score" < 0.5 then
            exit('Unfavorable');

        exit('None');
    end;

}
