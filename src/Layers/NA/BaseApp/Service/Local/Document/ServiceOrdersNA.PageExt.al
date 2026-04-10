// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.EServices.EDocument;

pageextension 10025 "Service Orders NA" extends "Service Orders"
{
    actions
    {
        addafter("Co&mments")
        {
            action(CFDIRelationDocuments)
            {
                ApplicationArea = Service, BasicMX;
                Caption = 'CFDI Relation Documents';
                Image = Allocations;
                RunObject = Page "CFDI Relation Documents";
                RunPageLink = "Document Table ID" = const(5900),
#pragma warning disable AL0603
                                "Document Type" = field("Document Type"),
#pragma warning restore AL0603
                                "Document No." = field("No."),
                                "Customer No." = field("Bill-to Customer No.");
                ToolTip = 'View or add CFDI relation documents for the record.';
            }
        }
#if CLEAN27
        modify(ServiceOrderStatistics)
        {
            Visible = not SalesTaxStatisticsVisible;
        }
#endif
        addafter(ServiceOrderStatistics)
        {
            action(ServiceOrderStats)
            {
                ApplicationArea = Service;
                Caption = 'Statistics';
                Image = Statistics;
                ShortCutKey = 'F7';
                ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
#if CLEAN27
                    Visible = SalesTaxStatisticsVisible;
#else
                Visible = false;
#endif
                RunObject = Page "Service Order Stats.";
                RunPageOnRec = true;
            }
        }
#if CLEAN27
        addafter(ServiceOrderStatistics_Promoted)
        {
            actionref(ServiceOrderStats_Promoted; ServiceOrderStatistics)
            {
            }
        }
#endif
    }

    trigger OnOpenPage()
    begin
        SalesTaxStatisticsVisible := Rec."Tax Area Code" <> '';
    end;

    protected var
        SalesTaxStatisticsVisible: Boolean;
}
