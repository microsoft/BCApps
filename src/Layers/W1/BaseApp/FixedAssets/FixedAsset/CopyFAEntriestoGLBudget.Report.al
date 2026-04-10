// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.FixedAsset;

using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.Setup;

report 5684 "Copy FA Entries to G/L Budget"
{
    Caption = 'Copy FA Entries to G/L Budget';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Fixed Asset"; "Fixed Asset")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "FA Class Code", "FA Subclass Code", "Budgeted Asset";

            trigger OnAfterGetRecord()
            begin
                Window.Update(1, "No.");
                if not FADeprBook.Get("No.", DeprBookCode) then
                    CurrReport.Skip();
                if Inactive or (FADeprBook."Disposal Date" > 0D) then
                    CurrReport.Skip();

                FALedgEntry.SetRange("FA No.", "No.");
                if FALedgEntry.Find('-') then
                    repeat
                        if GetTransferType(FALedgEntry) then begin
                            FADeprBook.TestField("FA Posting Group");
                            FALedgEntry."FA Posting Group" := FADeprBook."FA Posting Group";
                            FALedgEntry.Description := PostingDescription;
                            BudgetDepreciation.CopyFAToBudget(FALedgEntry, BudgetNameCode, BalAccount, '');
                        end;
                    until FALedgEntry.Next() = 0;
            end;

            trigger OnPreDataItem()
            begin
                FALedgEntry.SetCurrentKey("FA No.", "Depreciation Book Code", "FA Posting Category", "FA Posting Type", "Posting Date");
                FALedgEntry.SetRange("Depreciation Book Code", DeprBookCode);
                FALedgEntry.SetRange("FA Posting Category", FALedgEntry."FA Posting Category"::" ");
                FALedgEntry.SetRange(
                  "FA Posting Type",
                  FALedgEntry."FA Posting Type"::"Acquisition Cost", FALedgEntry."FA Posting Type"::"Custom 2");
                FALedgEntry.SetRange("Posting Date", StartingDate, EndingDate2);
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
                    field(CopyDeprBook; DeprBookCode)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Copy Depr. Book';
                        TableRelation = "Depreciation Book";
                        ToolTip = 'Specifies that the specified entries will be copied from one depreciation book to another. The entries are not posted to the new depreciation book - they are either inserted as lines in a general ledger fixed asset journal or in a fixed asset journal, depending on whether the new depreciation book has activated general ledger integration.';
                    }
                    field(CopyToGLBudgetName; BudgetNameCode)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Copy to G/L Budget Name';
                        TableRelation = "G/L Budget Name";
                        ToolTip = 'Specifies the name of the budget you want to copy projected values to.';
                    }
                    field(StartingDate; StartingDate)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the date when you want the report to start.';
                    }
                    field(EndingDate; EndingDate)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the date when you want the report to end.';
                    }
                    field(PostingDescription; PostingDescription)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Posting Description';
                        ToolTip = 'Specifies the posting date to be used by the batch job as a filter.';
                    }
                    field(BalAccount; BalAccount)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Insert Bal. Account';
                        ToolTip = 'Specifies if you want the batch job to automatically insert fixed asset entries with balancing accounts.';
                    }
                    group(Copy)
                    {
                        Caption = 'Copy';
                        field("TransferType[1]"; TransferType[1])
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Acquisition Cost';
                            ToolTip = 'Specifies whether acquisition cost entries posted to this depreciation book are posted both to the general ledger and the FA ledger.';
                        }
                        field("TransferType[2]"; TransferType[2])
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Depreciation';
                            ToolTip = 'Specifies whether depreciation entries posted to this depreciation book are posted both to the general ledger and the FA ledger.';
                        }
                        field("TransferType[3]"; TransferType[3])
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Write-Down';
                            ToolTip = 'Specifies whether write-down entries posted to this depreciation book should be posted to the general ledger and the FA ledger.';
                        }
                        field("TransferType[4]"; TransferType[4])
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Appreciation';
                            ToolTip = 'Specifies if appreciations are included by the batch job.';
                        }
                        field("TransferType[5]"; TransferType[5])
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Custom 1';
                            ToolTip = 'Specifies whether custom 1 entries posted to this depreciation book are posted to the general ledger and the FA ledger.';
                        }
                        field("TransferType[6]"; TransferType[6])
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Custom 2';
                            ToolTip = 'Specifies whether custom 2 entries posted to this depreciation book are posted to the general ledger and the FA ledger.';
                        }
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
        if (EndingDate > 0D) and (StartingDate > EndingDate) then
            Error(Text000);
        if EndingDate = 0D then
            EndingDate2 := DMY2Date(31, 12, 9999)
        else
            EndingDate2 := EndingDate;
        DeprBook.Get(DeprBookCode);

        if "Fixed Asset".GetFilter("FA Posting Group") <> '' then
            Error(Text002, "Fixed Asset".FieldCaption("FA Posting Group"));

        Window.Open(Text001);
    end;

    var
        FASetup: Record "FA Setup";
        DeprBook: Record "Depreciation Book";
        FADeprBook: Record "FA Depreciation Book";
        FALedgEntry: Record "FA Ledger Entry";
        BudgetDepreciation: Codeunit "Budget Depreciation";
        Window: Dialog;
        TransferType: array[6] of Boolean;
        BalAccount: Boolean;
        PostingDescription: Text[100];
        DeprBookCode: Code[10];
        BudgetNameCode: Code[10];
        StartingDate: Date;
        EndingDate: Date;
        EndingDate2: Date;

#pragma warning disable AA0074
        Text000: Label 'You must specify an Ending Date that is later than the Starting Date.';
#pragma warning disable AA0470
        Text001: Label 'Copying fixed asset    #1##########';
        Text002: Label 'You should not set a filter on %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure GetTransferType(var FALedgEntry: Record "FA Ledger Entry"): Boolean
    begin
        case FALedgEntry."FA Posting Type" of
            FALedgEntry."FA Posting Type"::"Acquisition Cost":
                exit(TransferType[1]);
            FALedgEntry."FA Posting Type"::Depreciation:
                exit(TransferType[2]);
            FALedgEntry."FA Posting Type"::"Write-Down":
                exit(TransferType[3]);
            FALedgEntry."FA Posting Type"::Appreciation:
                exit(TransferType[4]);
            FALedgEntry."FA Posting Type"::"Custom 1":
                exit(TransferType[5]);
            FALedgEntry."FA Posting Type"::"Custom 2":
                exit(TransferType[6]);
        end;
        exit(false);
    end;

    procedure SetTransferType(NewAcquisitionCost: Boolean; NewDepreciation: Boolean; NewWriteDown: Boolean; NewAppreciation: Boolean; NewCustom1: Boolean; NewCustom2: Boolean)
    begin
        TransferType[1] := NewAcquisitionCost;
        TransferType[2] := NewDepreciation;
        TransferType[3] := NewWriteDown;
        TransferType[4] := NewAppreciation;
        TransferType[5] := NewCustom1;
        TransferType[6] := NewCustom2;
    end;

    procedure InitializeRequest(NewDeprBookCode: Code[10]; NewBudgetNameCode: Code[10]; NewStartingDate: Date; NewEndingDate: Date; NewPostingDescription: Text[100]; NewBalAccount: Boolean)
    begin
        DeprBookCode := NewDeprBookCode;
        BudgetNameCode := NewBudgetNameCode;
        StartingDate := NewStartingDate;
        EndingDate := NewEndingDate;
        PostingDescription := NewPostingDescription;
        BalAccount := NewBalAccount;
    end;
}

