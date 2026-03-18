// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Interaction;

using Microsoft.Purchases.Archive;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Archive;
using Microsoft.Sales.Document;

report 5190 "Delete Interaction Log Entries"
{
    Caption = 'Delete Interaction Log Entries';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Interaction Log Entry"; "Interaction Log Entry")
        {
            DataItemTableView = sorting(Canceled, "Campaign No.", "Campaign Entry No.", Date) where(Canceled = const(true));
            RequestFilterFields = "Entry No.", "Contact No.", Date, "Campaign No.", "Interaction Group Code", "Interaction Template Code", "Salesperson Code";

            trigger OnAfterGetRecord()
            var
                SalesHeader: Record "Sales Header";
                PurchHeader: Record "Purchase Header";
            begin
                NoOfInteractions := NoOfInteractions + 1;

                if "Version No." <> 0 then
                    case "Document Type" of
                        "Document Type"::"Sales Qte.":
                            SetSalesDocInteraction("Interaction Log Entry", SalesHeader."Document Type"::Quote);
                        "Document Type"::"Sales Ord. Cnfrmn.":
                            SetSalesDocInteraction("Interaction Log Entry", SalesHeader."Document Type"::Order);
                        "Document Type"::"Sales Blnkt. Ord":
                            SetSalesDocInteraction("Interaction Log Entry", SalesHeader."Document Type"::"Blanket Order");
                        "Document Type"::"Purch.Qte.":
                            SetPurchDocInteraction("Interaction Log Entry", PurchHeader."Document Type"::Quote);
                        "Document Type"::"Purch. Ord.":
                            SetPurchDocInteraction("Interaction Log Entry", PurchHeader."Document Type"::Order);
                        "Document Type"::"Purch. Blnkt. Ord.":
                            SetPurchDocInteraction("Interaction Log Entry", PurchHeader."Document Type"::"Blanket Order");
                    end;
                Delete(true);
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
        Message(Text000, NoOfInteractions, "Interaction Log Entry".TableCaption());
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1 %2 has been deleted.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        NoOfInteractions: Integer;

    local procedure SetPurchDocInteraction(InteractionLogEntry: Record "Interaction Log Entry"; DocumentType: Enum "Purchase Document Type")
    var
        PurchHeader: Record "Purchase Header";
        PurchHeaderArchive: Record "Purchase Header Archive";
    begin
        PurchHeaderArchive.Get(DocumentType, InteractionLogEntry."Document No.", InteractionLogEntry."Doc. No. Occurrence", InteractionLogEntry."Version No.");
        PurchHeader.SetRange("Document Type", DocumentType);
        PurchHeader.SetRange("No.", InteractionLogEntry."Document No.");
        PurchHeader.SetRange("Doc. No. Occurrence", InteractionLogEntry."Doc. No. Occurrence");
        if not PurchHeader.IsEmpty() then begin
            PurchHeaderArchive."Interaction Exist" := false;
            PurchHeaderArchive.Modify();
        end else
            PurchHeaderArchive.Delete(true);
    end;

    local procedure SetSalesDocInteraction(InteractionLogEntry: Record "Interaction Log Entry"; DocumentType: Enum "Sales Document Type")
    var
        SalesHeader: Record "Sales Header";
        SalesHeaderArchive: Record "Sales Header Archive";
    begin
        SalesHeaderArchive.Get(DocumentType, InteractionLogEntry."Document No.", InteractionLogEntry."Doc. No. Occurrence", InteractionLogEntry."Version No.");
        SalesHeader.SetRange("Document Type", DocumentType);
        SalesHeader.SetRange("No.", InteractionLogEntry."Document No.");
        SalesHeader.SetRange("Doc. No. Occurrence", InteractionLogEntry."Doc. No. Occurrence");
        if not SalesHeader.IsEmpty() then begin
            SalesHeaderArchive."Interaction Exist" := false;
            SalesHeaderArchive.Modify();
        end else
            SalesHeaderArchive.Delete(true);
    end;
}

