// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets;

using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Setup;
using Microsoft.Foundation.NoSeries;
using System.Utilities;

tableextension 31249 "FA Setup CZF" extends "FA Setup"
{
    fields
    {
        field(31240; "Tax Depreciation Book CZF"; Code[10])
        {
            Caption = 'Tax Depreciation Book';
            TableRelation = "Depreciation Book";
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                FixedAsset: Record "Fixed Asset";
                FADepreciationBook: Record "FA Depreciation Book";
            begin
                if "Tax Depreciation Book CZF" = xRec."Tax Depreciation Book CZF" then
                    exit;
                if FixedAsset.FindSet(true) then
                    repeat
                        if FADepreciationBook.Get(FixedAsset."No.", Rec."Tax Depreciation Book CZF") then
                            FixedAsset."Tax Deprec. Group Code CZF" := FADepreciationBook."Tax Deprec. Group Code CZF"
                        else
                            FixedAsset."Tax Deprec. Group Code CZF" := '';
                        FixedAsset.Modify();
                    until FixedAsset.Next() = 0;
            end;
        }
        field(31241; "Fixed Asset History Nos. CZF"; Code[20])
        {
            Caption = 'Fixed Asset History Nos.';
            DataClassification = CustomerContent;
            TableRelation = "No. Series";
        }
        field(31242; "Fixed Asset History CZF"; Boolean)
        {
            Caption = 'Fixed Asset History';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if GuiAllowed and (CurrFieldNo <> 0) then
                    if "Fixed Asset History CZF" then begin
                        TestField("Fixed Asset History Nos. CZF");
                        Report.Run(Report::"Initialize FA History CZF");
                    end;
            end;
        }
        field(31244; "FA Acquisition As Custom 2 CZF"; Boolean)
        {
            Caption = 'FA Acquisition As Custom 2';
            DataClassification = CustomerContent;
        }
        field(31245; "Incl. Ending Book Value CZF"; Boolean)
        {
            Caption = 'Include Ending Book Value in Depreciation Base';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether the ending book value (residual value) is included in the calculation of the depreciation base. If disabled, depreciation is calculated from the full acquisition cost and stops at the ending book value. If enabled, the ending book value is subtracted from the base before depreciation is calculated. For assets with a tax depreciation group, the ending book value is ignored.';

            trigger OnValidate()
            var
                ConfirmManagement: Codeunit "Confirm Management";
                ChangeCalculationQst: Label 'Changing this setting changes the way new depreciation is calculated. Do you really want to make the change?';
            begin
                if Rec."Incl. Ending Book Value CZF" = xRec."Incl. Ending Book Value CZF" then
                    exit;
                if GuiAllowed and (CurrFieldNo <> 0) then
                    if not ConfirmManagement.GetResponseOrDefault(ChangeCalculationQst, false) then
                        Rec."Incl. Ending Book Value CZF" := xRec."Incl. Ending Book Value CZF";
            end;
        }
    }

    internal procedure BonusDepreciationCorrectlySetupCZF(): Boolean
    begin
        exit((Rec."Bonus Depreciation %" > 0) and (Rec."Bonus Depr. Effective Date" <> 0D));
    end;
}
