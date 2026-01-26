// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Ledger;

using Microsoft.FixedAssets.Depreciation;

report 5686 "Cancel FA Entries"
{
    Caption = 'Cancel FA Entries';
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
                    field(UseNewPosting; UseNewPosting)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Use New Posting Date';
                        ToolTip = 'Specifies that a new posting date is applied to the journal entries created by the batch job. If the field is cleared, the posting date of the fixed asset ledger entries to be canceled is copied to the journal entries that the batch job creates.';
                    }
                    field(NewPostingDate; NewPostingDate)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'New Posting Date';
                        ToolTip = 'Specifies the posting date to be applied to the journal entries created by the batch job when the Use New Posting Date field is selected.';
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

    trigger OnPreReport()
    begin
        DerogDeprBook.SetRange(Code, FALedgEntry."Depreciation Book Code");
        if DerogDeprBook.Find('-') then
            if DerogDeprBook."Derogatory Calculation" <> '' then begin
                DerogFALedgEntry.Copy(FALedgEntry);
                DerogFALedgEntry.SetFilter("FA Posting Type", '<>%1', DerogFALedgEntry."FA Posting Type"::"Salvage Value");
                if DerogFALedgEntry.Find('-') then
                    Error(Text10800);
            end;
        if UseNewPosting then
            if NewPostingDate = 0D then
                Error(Text000);
        if not UseNewPosting then
            if NewPostingDate > 0D then
                Error(Text001);
        if NewPostingDate > 0D then
            if NormalDate(NewPostingDate) <> NewPostingDate then
                Error(Text002);

        CancelFALedgEntries.TransferLine(FALedgEntry, false, NewPostingDate);
    end;

    var
        FALedgEntry: Record "FA Ledger Entry";
        CancelFALedgEntries: Codeunit "Cancel FA Ledger Entries";
        UseNewPosting: Boolean;
        NewPostingDate: Date;
        DerogDeprBook: Record "Depreciation Book";
        Text10800: Label 'You cannot cancel FA entries that were posted to a derogatory depreciation book. Instead you must\cancel the FA entries posted to the depreciation book integrated with G/L.';
        DerogFALedgEntry: Record "FA Ledger Entry";

#pragma warning disable AA0074
        Text000: Label 'You must specify New Posting Date.';
        Text001: Label 'You must not specify New Posting Date.';
        Text002: Label 'You must not specify a closing date.';
#pragma warning restore AA0074

    procedure GetFALedgEntry(var FALedgEntry2: Record "FA Ledger Entry")
    begin
        FALedgEntry.Copy(FALedgEntry2);
    end;
}

