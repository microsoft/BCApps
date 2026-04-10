// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Depreciation;

using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Setup;

report 5689 "Create FA Depreciation Books"
{
    Caption = 'Create FA Depreciation Books';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Fixed Asset"; "Fixed Asset")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "FA Class Code", "FA Subclass Code";

            trigger OnAfterGetRecord()
            begin
                if Inactive then
                    CurrReport.Skip();
                if FADeprBook.Get("No.", DeprBookCode) then begin
                    Window.Update(2, "No.");
                    CurrReport.Skip();
                end;
                Window.Update(1, "No.");
                if FANo <> '' then
                    FADeprBook := FADeprBook2
                else
                    FADeprBook.Init();
                FADeprBook."FA No." := "No.";
                FADeprBook."Depreciation Book Code" := DeprBookCode;
                FADeprBook.Insert(true);
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(DepreciationBook; DeprBookCode)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Depreciation Book';
                        TableRelation = "Depreciation Book";
                        ToolTip = 'Specifies the code for the depreciation book to be included in the report or batch job.';

                        trigger OnValidate()
                        begin
                            CheckFADeprBook();
                        end;
                    }
                    field(CopyFromFANo; FANo)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Copy from FA No.';
                        TableRelation = "Fixed Asset";
                        ToolTip = 'Specifies the number of the fixed asset that you want to copy from.';

                        trigger OnValidate()
                        begin
                            CheckFADeprBook();
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if DeprBookCode = '' then begin
                FASetup.Get();
                DeprBookCode := FASetup."Default Depr. Book";
            end;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        DeprBook.Get(DeprBookCode);
        Window.Open(
          Text000 +
          Text001);
        if FANo <> '' then
            FADeprBook2.Get(FANo, DeprBookCode);
    end;

    var
        FASetup: Record "FA Setup";
        DeprBook: Record "Depreciation Book";
        FADeprBook: Record "FA Depreciation Book";
        FADeprBook2: Record "FA Depreciation Book";
        Window: Dialog;
        DeprBookCode: Code[10];
        FANo: Code[20];

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Creating fixed asset book     #1##########\';
        Text001: Label 'Not creating fixed asset book #2##########';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure CheckFADeprBook()
    var
        FADeprBook: Record "FA Depreciation Book";
    begin
        if (DeprBookCode <> '') and (FANo <> '') then
            FADeprBook.Get(FANo, DeprBookCode);
    end;
}

