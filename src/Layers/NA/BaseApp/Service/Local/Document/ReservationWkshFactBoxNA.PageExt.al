// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Inventory.Tracking;

pageextension 10029 ReservationWkshFactBoxNA extends "Reservation Wksh. Factbox"
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        // Add changes to page actions here
        modify(Statistics)
        {
            Visible = false;
        }
        addafter(Statistics)
        {
            action(ServiceStatistics)
            {
                ApplicationArea = Reservation;
                Caption = 'Statistics';
                Image = Statistics;
                ToolTip = 'Show statistics for the source document.';

                trigger OnAction()
                var
                    ServiceHeader: Record "Service Header";
                    ReservationWorksheetMgt: Codeunit "Reservation Worksheet Mgt.";
                begin
                    if Rec."Source Type" = Database::"Service Line" then begin
                        ServiceHeader.SetLoadFields("Document Type", "No.", "Tax Area Code");
                        ServiceHeader.Get(Rec."Source Subtype", Rec."Source ID");
                        if ServiceHeader."Tax Area Code" <> '' then
                            Page.Run(Page::"Service Order Stats.", ServiceHeader)
                        else
                            ReservationWorksheetMgt.ShowStatistics(Rec)
                    end else
                        ReservationWorksheetMgt.ShowStatistics(Rec);
                end;
            }
        }
    }
}