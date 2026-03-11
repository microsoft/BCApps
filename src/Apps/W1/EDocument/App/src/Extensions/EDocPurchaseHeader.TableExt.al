// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.eServices.EDocument;

tableextension 6169 "E-Doc. Purchase Header" extends "Purchase Header"
{
    fields
    {
        field(6100; "E-Document Link"; Guid)
        {
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(6101; "Amount Incl. VAT To Inv."; Decimal)
        {
            CalcFormula = sum("Purchase Line"."Amount Incl. VAT To Inv." where("Document Type" = field("Document Type"),
                                                                            "Document No." = field("No.")));
            Caption = 'Amount Incl. VAT To Inv.';
            Editable = false;
            FieldClass = FlowField;
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
        }
    }
    keys
    {
        key(EDocKey1; "E-Document Link")
        {
        }
    }

    internal procedure IsLinkedToEDoc(EDocumentToExclude: Record "E-Document"): Boolean
    begin
        exit(not IsNullGuid("E-Document Link") and ("E-Document Link" <> EDocumentToExclude.SystemId));
    end;

}
