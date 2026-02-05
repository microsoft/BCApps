// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExciseTaxes;

using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Foundation.UOM;

tableextension 7418 "Excise Fixed Asset Ext" extends "Fixed Asset"
{
    fields
    {
        field(7412; "Excise Tax Type"; Code[20])
        {
            Caption = 'Excise Tax Type';
            TableRelation = "Excise Tax Type".Code where(Enabled = const(true));
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                ExciseTaxType: Record "Excise Tax Type";
            begin
                if "Excise Tax Type" <> '' then begin
                    ExciseTaxType.Get("Excise Tax Type");
                    if not ExciseTaxType.Enabled then
                        Error(ExciseTaxTypeNotEnabledErr, "Excise Tax Type");
                end else begin
                    "Qty for Excise Tax" := 0;
                    "Excise Tax UOM" := '';
                end;
            end;
        }

        field(7413; "Qty for Excise Tax"; Decimal)
        {
            Caption = 'Qty for Excise Tax';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if ("Qty for Excise Tax" <> 0) and ("Excise Tax Type" = '') then
                    Error(MustSpecifyExciseTaxTypeForQuantityErr);
            end;
        }

        field(7414; "Excise Tax UOM"; Code[10])
        {
            Caption = 'Excise Tax UOM';
            TableRelation = "Unit of Measure".Code;
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if ("Excise Tax UOM" <> '') and ("Excise Tax Type" = '') then
                    Error(MustSpecifyExciseTaxTypeForUOMErr);
            end;
        }
    }

    var
        ExciseTaxTypeNotEnabledErr: Label 'Excise tax type %1 is not enabled.', Comment = '%1 = Excise Tax Type Code';
        MustSpecifyExciseTaxTypeForQuantityErr: Label 'You must specify an Excise Tax Type before entering a quantity.';
        MustSpecifyExciseTaxTypeForUOMErr: Label 'You must specify an Excise Tax Type before entering a UOM.';

}