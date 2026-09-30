// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sustainability.EUDR;

using Microsoft.Foundation.Address;
using Microsoft.Inventory.Tracking;

tableextension 6288 "EUDR Lot No. Information" extends "Lot No. Information"
{
    fields
    {
        field(6210; "EUDR Certificate No."; Code[50])
        {
            Caption = 'EUDR Certificate No.';
            ToolTip = 'Specifies the certificate number that documents EUDR compliance for this lot.';
            DataClassification = CustomerContent;
        }
        field(6211; "Certification Scheme"; Text[100])
        {
            Caption = 'Certification Scheme';
            ToolTip = 'Specifies the certification scheme that applies to this lot, such as FSC, PEFC, RSPO, Rainforest Alliance, or Fairtrade.';
            DataClassification = CustomerContent;
        }
        field(6212; "EUDR Valid From"; Date)
        {
            Caption = 'Valid From';
            ToolTip = 'Specifies the first date that the EUDR certificate is valid for this lot.';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if (Rec."EUDR Valid From" <> 0D) and (Rec."EUDR Valid To" <> 0D) then
                    if Rec."EUDR Valid From" > Rec."EUDR Valid To" then
                        Error(EUDRValidFromAfterValidToErr, Rec.FieldCaption("EUDR Valid From"), Rec.FieldCaption("EUDR Valid To"));
            end;
        }
        field(6213; "EUDR Valid To"; Date)
        {
            Caption = 'Valid To';
            ToolTip = 'Specifies the last date that the EUDR certificate is valid for this lot.';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if (Rec."EUDR Valid From" <> 0D) and (Rec."EUDR Valid To" <> 0D) then
                    if Rec."EUDR Valid To" < Rec."EUDR Valid From" then
                        Error(EUDRValidFromAfterValidToErr, Rec.FieldCaption("EUDR Valid From"), Rec.FieldCaption("EUDR Valid To"));
            end;
        }
        field(6214; "Country/Region of Prod. Code"; Code[10])
        {
            Caption = 'Country/Region of Production Code';
            TableRelation = "Country/Region";
            ToolTip = 'Specifies the country or region where the goods in this lot were produced. You can change the value if the distributor provides different origin information.';
            DataClassification = CustomerContent;
        }
        field(6215; "DDS Reference Number"; Code[50])
        {
            Caption = 'DDS Reference Number';
            ToolTip = 'Specifies the reference number issued when the due diligence statement is registered in the EU Information System, TRACES.';
            DataClassification = CustomerContent;
        }
        field(6216; "DDS Verification No."; Code[50])
        {
            Caption = 'DDS Verification No.';
            ToolTip = 'Specifies the verification number for the EUDR due diligence statement.';
            DataClassification = CustomerContent;
        }
    }

    var
        EUDRValidFromAfterValidToErr: Label '%1 must not be after %2.', Comment = '%1 = Valid From field caption, %2 = Valid To field caption';
}