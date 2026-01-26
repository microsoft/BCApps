// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Inventory.Intrastat;

tableextension 12153 "Service Line IT" extends "Service Line"
{
    fields
    {
        field(12101; "Deductible %"; Decimal)
        {
            Caption = 'Deductible %';
            DataClassification = CustomerContent;
            DecimalPlaces = 2 : 2;
            Editable = false;
            InitValue = 100;
            MaxValue = 100;
        }
        field(12125; "Service Tariff No."; Code[10])
        {
            Caption = 'Service Tariff No.';
            DataClassification = CustomerContent;
            TableRelation = "Service Tariff Number";

            trigger OnValidate()
            var
                VATPostingSetup: Record "VAT Posting Setup";
            begin
                if "Service Tariff No." <> '' then
                    VATPostingSetup.CheckEUService("VAT Bus. Posting Group", "VAT Prod. Posting Group");
            end;
        }
        field(12130; "Include in VAT Transac. Rep."; Boolean)
        {
            Caption = 'Include in VAT Transac. Rep.';
            DataClassification = CustomerContent;
        }
        field(12131; "Refers to Period"; Option)
        {
            Caption = 'Refers to Period';
            DataClassification = CustomerContent;
            OptionCaption = ' ,Current,Current Calendar Year,Previous Calendar Year';
            OptionMembers = " ",Current,"Current Calendar Year","Previous Calendar Year";
        }
        field(12145; "Automatically Generated"; Boolean)
        {
            Caption = 'Automatically Generated';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key12100; "Document Type", "Document No.", "VAT Prod. Posting Group")
        {
        }
    }

    [Scope('OnPrem')]
    procedure ValidateIncludeInDT(): Boolean
    var
        Country: Record "Country/Region";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        GetServHeader();
        "Include in VAT Transac. Rep." := false;
        if Country.CheckNotEUCountry(ServHeader."Country/Region Code") and
           VATPostingSetup.IncludeInVATTransReport("VAT Bus. Posting Group", "VAT Prod. Posting Group")
        then
            "Include in VAT Transac. Rep." := true;
        exit("Include in VAT Transac. Rep.");
    end;

    procedure UpdateSplitVATLines(ChangedFieldName: Text)
    begin
        if RemoveSplitVATLinesWithCheck(ChangedFieldName) then
            ServHeader.AddSplitVATLines();
    end;

    procedure RemoveSplitVATLinesWithCheck(ChangedFieldName: Text): Boolean
    var
        SplitVATServiceLine: Record "Service Line";
    begin
        if "Automatically Generated" then
            exit(false);

        ServHeader.Get(Rec."Document Type", Rec."Document No.");

        if not ServHeader.GetSplitVATLines(SplitVATServiceLine) then
            exit(false); // No impact on split VAT lines

        if not Confirm(ReGenerateSplitVATLinesQst, true, ChangedFieldName) then
            Error(MustDeleteGeneratedSplitVATLinesErr, ChangedFieldName);

        ServHeader.RemoveSplitVATLines(SplitVATServiceLine);
        exit(true);
    end;

    var
        ReGenerateSplitVATLinesQst: Label 'If you change %1, the existing automatically generated split VAT service lines will be deleted and new service lines based on the new information will be created.\\Do you want to change %1?', Comment = '%1=A field name whose value is just being changed.';
        MustDeleteGeneratedSplitVATLinesErr: Label 'You must delete the existing automatically generated split VAT lines before you can change %1.', Comment = '%1=A field name whose value is just being changed.';
}
