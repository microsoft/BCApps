// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Purchases.History;

tableextension 7000114 "SII Purch. Inv. Header" extends "Purch. Inv. Header"
{
    fields
    {
        field(10706; "SII Status"; Enum "SII Document Status")
        {
            CalcFormula = lookup("SII Doc. Upload State".Status where("Document Source" = const("Vendor Ledger"),
                                                                       "Document Type" = const(Invoice),
                                                                       "Document No." = field("No.")));
            Caption = 'SII Status';
            FieldClass = FlowField;

            trigger OnLookup()
            var
                SIIDocUploadState: Record "SII Doc. Upload State";
                SIIHistory: Record "SII History";
            begin
                SIIDocUploadState.SetRange("Document Source", SIIDocUploadState."Document Source"::"Vendor Ledger");
                SIIDocUploadState.SetRange("Document Type", SIIDocUploadState."Document Type"::Invoice);
                SIIDocUploadState.SetRange("Document No.", "No.");
                if SIIDocUploadState.FindFirst() then begin
                    SIIHistory.SetRange("Document State Id", SIIDocUploadState.Id);
                    PAGE.Run(PAGE::"SII History", SIIHistory);
                end;
            end;
        }
        field(10707; "Invoice Type"; Enum "SII Purch. Invoice Type")
        {
            Caption = 'Invoice Type';
            DataClassification = CustomerContent;
        }
        field(10708; "Cr. Memo Type"; Enum "SII Purch. Credit Memo Type")
        {
            Caption = 'Cr. Memo Type';
            DataClassification = CustomerContent;
        }
        field(10709; "Special Scheme Code"; Enum "SII Purch. Special Scheme Code")
        {
            Caption = 'Special Scheme Code';
            DataClassification = CustomerContent;
        }
        field(10710; "Operation Description"; Text[250])
        {
            Caption = 'Operation Description';
            DataClassification = CustomerContent;
        }
        field(10712; "Operation Description 2"; Text[250])
        {
            Caption = 'Operation Description 2';
            DataClassification = CustomerContent;
        }
        field(10720; "Succeeded Company Name"; Text[250])
        {
            Caption = 'Succeeded Company Name';
            DataClassification = CustomerContent;
        }
        field(10721; "Succeeded VAT Registration No."; Text[20])
        {
            Caption = 'Succeeded VAT Registration No.';
            DataClassification = CustomerContent;
        }
        field(10722; "ID Type"; Enum "SII ID Type")
        {
            Caption = 'ID Type';
            DataClassification = CustomerContent;
        }
        field(10723; "Sent to SII"; Boolean)
        {
            CalcFormula = exist("SII Doc. Upload State" where("Document Source" = const("Vendor Ledger"),
                                                               "Document Type" = const(Invoice),
                                                               "Document No." = field("No.")));
            Editable = false;
            FieldClass = FlowField;
        }
        field(10724; "Do Not Send To SII"; Boolean)
        {
            Caption = 'Do Not Send To SII';
            DataClassification = CustomerContent;
        }
    }
}
