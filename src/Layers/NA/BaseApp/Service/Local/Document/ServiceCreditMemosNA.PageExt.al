// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.EServices.EDocument;

pageextension 10021 "Service Credit Memos NA" extends "Service Credit Memos"
{
    actions
    {
        addafter("Service Document Lo&g")
        {
            action(CFDIRelationDocuments)
            {
                ApplicationArea = BasicMX;
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
#if not CLEAN26
        modify(Statistics)
        {
            trigger OnBeforeAction()
            begin
                OnBeforeCalculateSalesTaxStatistics(Rec, true);
            end;
        }
#endif
#if CLEAN27
        modify(ServiceStatistics)
        {
            Visible = not SalesTaxStatisticsVisible;
        }
#endif
        addafter(ServiceStatistics)
        {
            action(ServiceStats)
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
                RunObject = Page "Service Stats.";
                RunPageOnRec = true;
            }
        }
#if CLEAN27
        addafter(ServiceStatistics_Promoted)
        {
            actionref(ServiceStats_Promoted; ServiceStats)
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

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the ServiceStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateSalesTaxStatistics(var ServiceHeader: Record "Service Header"; ShowDialog: Boolean)
    begin
    end;
#endif
}
