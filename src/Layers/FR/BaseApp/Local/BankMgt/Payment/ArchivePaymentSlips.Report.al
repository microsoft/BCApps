// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

report 10873 "Archive Payment Slips"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Archive Payment Slips';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Payment Header"; "Payment Header")
        {
            CalcFields = "Archiving Authorized";
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Payment Class";

            trigger OnAfterGetRecord()
            begin
                if "Archiving Authorized" then begin
                    PaymentManagement.ArchiveDocument("Payment Header");
                    ArchivedDocs += 1;
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

    trigger OnPostReport()
    begin
        if ArchivedDocs = 0 then
            Message(Text002)
        else
            if ArchivedDocs = 1 then
                Message(Text003)
            else
                Message(Text001, ArchivedDocs);
    end;

    trigger OnPreReport()
    begin
        ArchivedDocs := 0;
    end;

    var
        PaymentManagement: Codeunit "Payment Management";
        ArchivedDocs: Integer;
        Text001: Label '%1 Payment Headers have been archived.';
        Text002: Label 'There is no Payment Header to archive.';
        Text003: Label 'One Payment Header has been archived.';
}

