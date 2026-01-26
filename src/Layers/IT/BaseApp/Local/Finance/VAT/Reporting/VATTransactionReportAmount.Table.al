// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.VAT.Setup;

table 12195 "VAT Transaction Report Amount"
{
    Caption = 'VAT Transaction Report Amount';
    DrillDownPageID = "VAT Transaction Report Amounts";
    LookupPageID = "VAT Transaction Report Amounts";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            NotBlank = true;
        }
        field(2; "Threshold Amount Excl. VAT"; Decimal)
        {
            Caption = 'Threshold Amount Excl. VAT';
            MinValue = 0;

            trigger OnValidate()
            begin
                ValidateVATTransactionAmount();
            end;
        }
        field(3; "Threshold Amount Incl. VAT"; Decimal)
        {
            Caption = 'Threshold Amount Incl. VAT';
            MinValue = 0;

            trigger OnValidate()
            begin
                ValidateVATTransactionAmount();
            end;
        }
    }

    keys
    {
        key(Key1; "Starting Date")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        DataTransThreshold: Record "VAT Transaction Report Amount";
    begin
        VATPostingSetup.SetRange("Include in VAT Transac. Rep.", true);
        if VATPostingSetup.FindFirst() then
            if (DataTransThreshold.Count - 1) = 0 then
                Error(NotAllowedToDeleteErr);
    end;

    var
        NotAllowedToDeleteErr: Label 'You cannot delete VAT Transaction Report Amounts since VAT Posting Setup records with Include in VAT Transaction Report exist.';
        NoThresholdIsSetErr: Label 'You cannot export transactions for the calendar date %1, because there is no threshold set for this date on the %2 table.';
        ThresholdSetupErr: Label '%1 cannot be more than %2.';

    [Scope('OnPrem')]
    procedure ValidateVATTransactionAmount()
    begin
        if "Threshold Amount Excl. VAT" > "Threshold Amount Incl. VAT" then
            Error(ThresholdSetupErr, FieldCaption("Threshold Amount Excl. VAT"), FieldCaption("Threshold Amount Incl. VAT"));
    end;

    [Scope('OnPrem')]
    procedure IncludeInVATTransacRep(OperationOccurredDate: Date; PricesIncludingVAT: Boolean; Amount: Decimal): Boolean
    var
        VatTransRepAmountPage: Page "VAT Transaction Report Amounts";
    begin
        SetFilter("Starting Date", '<=%1', OperationOccurredDate);
        if FindLast() then begin
            if PricesIncludingVAT then
                exit(Amount >= "Threshold Amount Incl. VAT");
            exit(Amount >= "Threshold Amount Excl. VAT");
        end;
        Error(NoThresholdIsSetErr, OperationOccurredDate, VatTransRepAmountPage.Caption);
    end;
}

