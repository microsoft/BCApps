// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#pragma warning disable AA0247
tableextension 12145 NoSeriesIT extends "No. Series"
{
    fields
    {
#pragma warning disable AS0125
        field(12100; "No. Series Type"; Enum "No. Series Type")
        {
            Caption = 'No. Series Type';
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif

            trigger OnValidate()
            var
                NoSeriesIT: Codeunit "No. Series IT";
            begin
                NoSeriesIT.ValidateNoSeriesType(Rec, xRec);
            end;
        }
        field(12101; "VAT Register"; Code[10])
        {
            Caption = 'VAT Register';
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif

            TableRelation = if ("No. Series Type" = const(Sales)) "VAT Register" where(Type = const(Sale))
            else
            if ("No. Series Type" = const(Purchase)) "VAT Register" where(Type = const(Purchase));

            trigger OnValidate()
            begin
                if "No. Series Type" = "No. Series Type"::Normal then
                    Error(NoSeriesTypeMustNotBeNormalErr, FieldCaption("No. Series Type"));
            end;

        }
        field(12102; "VAT Reg. Print Priority"; Integer)
        {
            Caption = 'VAT Reg. Print Priority';
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif
        }
        field(12103; "Reverse Sales VAT No. Series"; Code[20])
        {
            Caption = 'Reverse Sales VAT No. Series';
            DataClassification = CustomerContent;
#if not CLEANSCHEMA27
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
#endif

            TableRelation = if ("No. Series Type" = const(Sales)) "No. Series" where("No. Series Type" = const(Purchase))
            else
            if ("No. Series Type" = const(Purchase)) "No. Series" where("No. Series Type" = const(Sales));

            trigger OnValidate()
            begin
                if "No. Series Type" = "No. Series Type"::Normal then
                    Error(NoSeriesTypeMustNotBeNormalErr, FieldCaption("No. Series Type"));
            end;
        }
    }
#pragma warning restore AS0125
    keys
    {
        key(Key12145; "VAT Reg. Print Priority")
        {
        }
    }

    var
        NoSeriesTypeMustNotBeNormalErr: Label '%1 must not be Normal', Comment = '%1 = No. Series Type';
}
