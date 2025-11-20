// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Setup;

using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Routing;

table 99000785 "Quality Measure"
{
    Caption = 'Quality Measure';
    DrillDownPageID = "Quality Measures";
    LookupPageID = "Quality Measures";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        RoutingQualityMeasure: Record "Routing Quality Measure";
        ProdOrderRtngQltyMeas: Record "Prod. Order Rtng Qlty Meas.";
    begin
        ProdOrderRtngQltyMeas.SetRange("Qlty Measure Code", Code);
        if not ProdOrderRtngQltyMeas.IsEmpty() then
            Error(CannotDeleteRecProdOrderErr);

        RoutingQualityMeasure.SetRange("Qlty Measure Code", Code);
        if not RoutingQualityMeasure.IsEmpty() then
            Error(CannotDeleteRecActRoutingErr);
    end;

    var
        CannotDeleteRecProdOrderErr: Label 'You cannot delete the Quality Measure because it is being used on one or more active Production Orders.';
        CannotDeleteRecActRoutingErr: Label 'You cannot delete the Quality Measure because it is being used on one or more active Routings.';
}

