// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.FixedAsset;

using Microsoft.Finance.Dimension;
using Microsoft.FixedAssets.Depreciation;

report 5685 "Copy Fixed Asset"
{
    Caption = 'Copy Fixed Asset';
    Permissions = TableData "FA Depreciation Book" = ri;
    ProcessingOnly = true;

    dataset
    {
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
                    field(FANo; FANo)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Copy from FA No.';
                        TableRelation = "Fixed Asset";
                        ToolTip = 'Specifies the number of the fixed asset that you want to copy from.';
                    }
                    field(NumberofCopies; NumberofCopies)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'No. of Copies';
                        MinValue = 1;
                        ToolTip = 'Specifies the number of new fixed asset that you want to create.';
                    }
                    field(FirstFANo; FirstFANo)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'First FA No.';
                        ToolTip = 'Specifies the number of the first fixed asset. If No. of Copies is greater than 1, the First FA No. field must include a number, for example FA045.';

                        trigger OnValidate()
                        begin
                            if FirstFANo <> '' then
                                UseFANoSeries := false;
                        end;
                    }
                    field(UseFANoSeries; UseFANoSeries)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Use FA No. Series';
                        ToolTip = 'Specifies if you want the new fixed asset to have a number from the number series specified in Fixed Asset Nos. field in the Fixed Asset Setup window.';

                        trigger OnValidate()
                        begin
                            if UseFANoSeries then
                                FirstFANo := '';
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
            if NumberofCopies < 1 then
                NumberofCopies := 1;
            FANo := FANo2;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        OnBeforePreReport(FANo, NumberofCopies, FirstFANo, UseFANoSeries);
        DefaultDim.LockTable();
        FADeprBook.LockTable();
        FA.LockTable();
        if FANo = '' then
            Error(Text000, FA.TableCaption(), FA.FieldCaption("No."));
        if (FirstFANo = '') and not UseFANoSeries then
            Error(Text001);
        FA.Get(FANo);
        FADeprBook."FA No." := FANo;
        FADeprBook.SetRange("FA No.", FANo);
        DefaultDim."Table ID" := DATABASE::"Fixed Asset";
        DefaultDim."No." := FANo;
        DefaultDim.SetRange("Table ID", DATABASE::"Fixed Asset");
        DefaultDim.SetRange("No.", FANo);
        DefaultDim2 := DefaultDim;
        for I := 1 to NumberofCopies do begin
            FA2 := FA;
            FA2."No." := '';
            FA2."Last Date Modified" := 0D;
            FA2."Main Asset/Component" := FA2."Main Asset/Component"::" ";
            FA2."Component of Main Asset" := '';
            OnOnPreReportOnBeforeFA2Insert(FA2, FA);
            if UseFANoSeries then
                FA2.Insert(true)
            else begin
                FA2."No." := FirstFANo;
                if NumberofCopies > 1 then
                    FirstFANo := IncStr(FirstFANo);
                if FA2."No." = '' then
                    Error(Text002, FA.TableCaption(), FA.FieldCaption("No."));
                FA2.Insert(true);
            end;
            if DefaultDim.Find('-') then
                repeat
                    DefaultDim2 := DefaultDim;
                    DefaultDim2."No." := FA2."No.";
                    DefaultDim2.Insert(true);
                until DefaultDim.Next() = 0;
            if FADeprBook.Find('-') then
                repeat
                    FADeprBook2 := FADeprBook;
                    FADeprBook2."FA No." := FA2."No.";
                    FADeprBook2.Insert(true);
                until FADeprBook.Next() = 0;
            if FA2.Find() then begin
                FA2."Last Date Modified" := 0D;
                FA2.Modify();
            end;
            OnAfterFixedAssetCopied(FA2, FA);
        end;
    end;

    var
        DefaultDim: Record "Default Dimension";
        DefaultDim2: Record "Default Dimension";
        FA: Record "Fixed Asset";
        FA2: Record "Fixed Asset";
        FADeprBook: Record "FA Depreciation Book";
        FADeprBook2: Record "FA Depreciation Book";
        FANo: Code[20];
        FANo2: Code[20];
        FirstFANo: Code[20];
        UseFANoSeries: Boolean;
        NumberofCopies: Integer;
        I: Integer;
#pragma warning disable AA0074
        Text000: Label 'You must specify a number in the Copy from %1 %2 field.', Comment = '%1: TABLECAPTION(Fixed Asset); %2: Field(No.)';
        Text001: Label 'You must specify a number in First FA No. field or use the FA No. Series.';
        Text002: Label 'You must include a number in the First FA %1 %2 field.', Comment = '%1: TABLECAPTION(Fixed Asset); %2: Field(No.)';
#pragma warning restore AA0074

    procedure SetFANo(NewFANo: Code[20])
    begin
        FANo2 := NewFANo;
    end;

    procedure InitializeRequest(NewFANo: Code[20]; NewNumberofCopies: Integer; NewFirstFANo: Code[20]; NewUseFANoSeries: Boolean)
    begin
        NumberofCopies := NewNumberofCopies;
        FirstFANo := NewFirstFANo;
        UseFANoSeries := NewUseFANoSeries;
        FANo := NewFANo;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFixedAssetCopied(var FixedAsset2: Record "Fixed Asset"; var FixedAsset: Record "Fixed Asset")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOnPreReportOnBeforeFA2Insert(var FixedAsset2: Record "Fixed Asset"; var FixedAsset: Record "Fixed Asset")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePreReport(FANo: Code[20]; NumberofCopies: Integer; FirstFANo: Code[20]; UseFANoSeries: Boolean)
    begin
    end;
}

