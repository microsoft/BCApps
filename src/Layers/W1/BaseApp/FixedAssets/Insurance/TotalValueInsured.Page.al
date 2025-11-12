// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Insurance;

using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Setup;

page 5649 "Total Value Insured"
{
    Caption = 'Total Value Insured';
    Editable = false;
    PageType = Document;
    SourceTable = "Fixed Asset";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = FixedAssets;
                    ToolTip = 'Specifies a description of the fixed asset.';
                }
#pragma warning disable AA0100
                field("FASetup.""Insurance Depr. Book"""; FASetup."Insurance Depr. Book")
#pragma warning restore AA0100
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Insurance Depr. Book';
                    ToolTip = 'Specifies the depreciation book code that is specified in the Fixed Asset Setup window.';
                }
#pragma warning disable AA0100
                field("FADeprBook.""Acquisition Cost"""; FADeprBook."Acquisition Cost")
#pragma warning restore AA0100
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Acquisition Cost';
                    ToolTip = 'Specifies the total percentage of acquisition cost that can be allocated when acquisition cost is posted.';
                }
            }
            part(TotalValue; "Total Value Insured Subform")
            {
                ApplicationArea = FixedAssets;
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        CurrPage.TotalValue.PAGE.CreateTotalValue(Rec."No.");
        FASetup.Get();
        FADeprBook.Init();
        if FASetup."Insurance Depr. Book" <> '' then
            if FADeprBook.Get(Rec."No.", FASetup."Insurance Depr. Book") then
                FADeprBook.CalcFields("Acquisition Cost");
    end;

    var
        FASetup: Record "FA Setup";
        FADeprBook: Record "FA Depreciation Book";
}

