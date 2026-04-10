// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;

using Microsoft.Finance.Currency;
using Microsoft.Service.Document;
using Microsoft.Service.Ledger;

report 6033 "Get Prepaid Contract Entries"
{
    Caption = 'Get Prepaid Contract Entries';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Service Ledger Entry"; "Service Ledger Entry")
        {
            DataItemTableView = sorting("Service Contract No.", "Entry No.", "Entry Type", Type, "Moved from Prepaid Acc.", "Posting Date", Open, Prepaid) where(Type = const("Service Contract"), "Entry Type" = const(Sale), "Moved from Prepaid Acc." = const(false), Open = const(false));
            RequestFilterFields = "Service Contract No.", "Posting Date";

            trigger OnAfterGetRecord()
            begin
                if "Customer No." = ServHeader."Customer No." then begin
                    if (ContractNo = '') or ((ContractNo <> '') and (ContractNo <> "Service Contract No.")) then begin
                        ServLine.Init();
                        ServLine."Document Type" := ServHeader."Document Type";
                        ServLine."Document No." := ServHeader."No.";
                        ServLine."Line No." := NextLine;
                        ServLine.Description := StrSubstNo('%1: %2', ServContract.TableCaption(), "Service Contract No.");
                        ServLine."Customer No." := ServHeader."Customer No.";
                        ServLine."Contract No." := "Service Contract No.";
                        ServLine.Insert();
                        NextLine := NextLine + 10000;
                        ContractNo := "Service Contract No."
                    end;
                    Clear(ServLine);
                    ServLine.Init();
                    ServLine."Document Type" := ServHeader."Document Type";
                    ServLine."Document No." := ServHeader."No.";
                    ServLine."Line No." := NextLine;
                    ServLine.Insert(true);
                    ServLine.Type := ServLine.Type::"G/L Account";
                    ServContractAccGr.Get("Serv. Contract Acc. Gr. Code");
                    ServContractAccGr.TestField("Prepaid Contract Acc.");
                    ServLine.Validate("No.", ServContractAccGr."Prepaid Contract Acc.");
                    ServLine.Validate(Quantity, 1);
                    ServLine."Shortcut Dimension 1 Code" := "Global Dimension 1 Code";
                    ServLine."Shortcut Dimension 2 Code" := "Global Dimension 2 Code";
                    ServLine."Dimension Set ID" := "Dimension Set ID";
                    if ServHeader."Currency Code" <> '' then
                        ServLine.Validate("Unit Price", UnitAmountToFCY(-"Amount (LCY)"))
                    else
                        ServLine.Validate("Unit Price", -"Amount (LCY)");
                    ServLine.Validate("Unit Cost (LCY)", "Unit Cost");
                    ServLine.Validate("Contract No.", "Service Contract No.");
                    ServLine.Validate("Service Item No.", "Service Item No. (Serviced)");
                    ServLine.Validate("Appl.-to Service Entry", "Entry No.");
                    ServLine.Modify();
                    NextLine := NextLine + 10000;
                end;
            end;
        }
    }

    requestpage
    {

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

    trigger OnInitReport()
    begin
        ContractNo := '';
    end;

    trigger OnPreReport()
    begin
        if ServHeader."No." = '' then
            Error(Text000);
        ServLine.Reset();
        ServLine.SetRange("Document Type", ServHeader."Document Type");
        ServLine.SetRange("Document No.", ServHeader."No.");
        if ServLine.FindLast() then
            NextLine := ServLine."Line No." + 10000
        else
            NextLine := 10000;
    end;

    var
        ServHeader: Record "Service Header";
        ServContractAccGr: Record "Service Contract Account Group";
        ServLine: Record "Service Line";
        Currency: Record Currency;
        ServContract: Record "Service Contract Header";
        NextLine: Integer;
#pragma warning disable AA0074
        Text000: Label 'The batch job has not been initialized.';
#pragma warning restore AA0074
        ContractNo: Code[20];

    procedure Initialize(ServHeader2: Record "Service Header")
    begin
        ServHeader := ServHeader2;

        ServHeader.TestField("Document Type", ServHeader."Document Type"::"Credit Memo");
        ServHeader.TestField("No.");
        ServHeader.TestField("Customer No.");
        ServHeader.TestField("Bill-to Customer No.");
        GetCurrency();
    end;

    local procedure UnitAmountToFCY(FCAmount: Decimal): Decimal
    var
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        Currency.TestField("Unit-Amount Rounding Precision");
        exit(
          Round(
            CurrExchRate.ExchangeAmtLCYToFCY(
              ServHeader."Posting Date", ServHeader."Currency Code",
              FCAmount, ServHeader."Currency Factor"),
            Currency."Unit-Amount Rounding Precision"));
    end;

    local procedure GetCurrency()
    begin
        if ServHeader."Currency Code" = '' then
            Currency.InitRoundingPrecision()
        else begin
            Currency.Get(ServHeader."Currency Code");
            Currency.TestField("Amount Rounding Precision");
        end;
    end;
}

