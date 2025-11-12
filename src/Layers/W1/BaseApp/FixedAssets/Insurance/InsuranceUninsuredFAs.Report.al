// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Insurance;

using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Setup;

report 5626 "Insurance - Uninsured FAs"
{
    DefaultLayout = RDLC;
    RDLCLayout = './FixedAssets/Insurance/InsuranceUninsuredFAs.rdlc';
    ApplicationArea = FixedAssets;
    Caption = 'Uninsured Fixed Assets';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Fixed Asset"; "Fixed Asset")
        {
            RequestFilterFields = "No.", "FA Class Code", "FA Subclass Code";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(FixedAssetCaptionFilter; TableCaption + ': ' + FAFilter)
            {
            }
            column(FAFilter; FAFilter)
            {
            }
            column(HeadLineText1; HeadLineText[1])
            {
            }
            column(HeadLineText2; HeadLineText[2])
            {
            }
            column(HeadLineText3; HeadLineText[3])
            {
            }
            column(Amounts1; Amounts[1])
            {
                AutoFormatType = 1;
            }
            column(Amounts2; Amounts[2])
            {
                AutoFormatType = 1;
            }
            column(Amounts3; Amounts[3])
            {
                AutoFormatType = 1;
            }
            column(No_FixedAsset; "No.")
            {
                IncludeCaption = true;
            }
            column(Description_FixedAsset; Description)
            {
                IncludeCaption = true;
            }
            column(TotalAmounts1; TotalAmounts[1])
            {
                AutoFormatType = 1;
            }
            column(TotalAmounts2; TotalAmounts[2])
            {
                AutoFormatType = 1;
            }
            column(TotalAmounts3; TotalAmounts[3])
            {
                AutoFormatType = 1;
            }
            column(CurrReportPageNoCaption; CurrReportPageNoCaptionLbl)
            {
            }
            column(InsUninsuredFxdAssetsCptn; InsUninsuredFxdAssetsCptnLbl)
            {
            }
            column(TotalCaption; TotalCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                if not FADeprBook.Get("No.", DeprBook.Code) then
                    CurrReport.Skip();
                CalcFields(Insured);
                if (FADeprBook."Disposal Date" > 0D) or Insured or Inactive then
                    CurrReport.Skip();
                FADeprBook.CalcFields("Acquisition Cost", Depreciation, "Book Value");

                SetAmountsFromBook();

                for i := 1 to 3 do
                    TotalAmounts[i] := TotalAmounts[i] + Amounts[i];
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        FAFilter := "Fixed Asset".GetFilters();
        MakeAmountHeadLine();
        FASetup.Get();
        FASetup.TestField("Insurance Depr. Book");
        DeprBook.Get(FASetup."Insurance Depr. Book");
    end;

    var
        FASetup: Record "FA Setup";
        DeprBook: Record "Depreciation Book";
        FADeprBook: Record "FA Depreciation Book";
        FAFilter: Text;
        TotalAmounts: array[3] of Decimal;
        HeadLineText: array[3] of Text[80];
        Amounts: array[3] of Decimal;
        i: Integer;
        CurrReportPageNoCaptionLbl: Label 'Page';
        InsUninsuredFxdAssetsCptnLbl: Label 'Insurance - Uninsured Fixed Assets';
        TotalCaptionLbl: Label 'Total';

    local procedure MakeAmountHeadLine()
    begin
        HeadLineText[1] := FADeprBook.FieldCaption("Acquisition Cost");
        HeadLineText[2] := FADeprBook.FieldCaption(Depreciation);
        HeadLineText[3] := FADeprBook.FieldCaption("Book Value");
    end;

    local procedure SetAmountsFromBook()
    begin
        Amounts[1] := FADeprBook."Acquisition Cost";
        Amounts[2] := FADeprBook.Depreciation;
        Amounts[3] := FADeprBook."Book Value";

        OnAfterSetAmountsFromBook(Amounts, FADeprBook);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetAmountsFromBook(var Amounts: array[3] of Decimal; FADepreciationBook: Record "FA Depreciation Book")
    begin
    end;
}

