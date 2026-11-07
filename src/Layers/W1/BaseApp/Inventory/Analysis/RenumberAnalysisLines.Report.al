// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

report 7110 "Renumber Analysis Lines"
{
    Caption = 'Renumber Analysis Lines';
    ProcessingOnly = true;

    dataset
    {
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(StartRowRefNo; RowRefNo)
                    {
                        ApplicationArea = SalesAnalysis, PurchaseAnalysis, InventoryAnalysis;
                        Caption = 'Start Row Ref. No.';
                        ToolTip = 'Specifies that the row reference numbers are filled.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        Message(Text000);
    end;

    trigger OnPreReport()
    begin
        if AnalysisLine.Find('-') then
            repeat
                AnalysisLine.Validate("Row Ref. No.", RowRefNo);
                AnalysisLine.Modify();
                RowRefNo := IncStr(RowRefNo);
            until AnalysisLine.Next() = 0;
    end;

    var
        AnalysisLine: Record "Analysis Line";
        RowRefNo: Code[20];
#pragma warning disable AA0074
        Text000: Label 'The reference numbers were successfully changed.';
#pragma warning restore AA0074

    procedure Init(var AnalysisLine2: Record "Analysis Line")
    begin
        AnalysisLine.Copy(AnalysisLine2);
    end;
}

