// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

page 331 "Reservation Wksh. Log Factbox"
{
    PageType = ListPart;
    Editable = false;
    ApplicationArea = Reservation;
    SourceTable = "Reservation Worksheet Log";
    Caption = 'Latest changes';

    layout
    {
        area(Content)
        {
            repeater(Log)
            {
                ShowCaption = false;

                field("Record ID"; Format(Rec."Record ID"))
                {
                    Caption = 'Demand Line';
                    ToolTip = 'Specifies the demand line that was changed.';
                }
                field(Quantity; Rec.Quantity)
                {
                    Caption = 'Reserved Quantity';
                    ToolTip = 'Specifies how many units were reserved for the demand line.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action("Empty Log")
            {
                Caption = 'Empty Log';
                Image = ClearLog;
                ToolTip = 'Deletes all entries in the log.';

                trigger OnAction()
                var
                    ReservationWorksheetLog: Record "Reservation Worksheet Log";
                begin
                    ReservationWorksheetLog.SetRange("Journal Batch Name", Rec."Journal Batch Name");
                    ReservationWorksheetLog.DeleteAll();
                end;
            }
            action("Show Document")
            {
                Caption = 'Show Document';
                Image = ViewDocumentLine;
                Scope = Repeater;
                ToolTip = 'Shows the document that was changed.';

                trigger OnAction()
                var
                    IsHandled: Boolean;
                begin
                    OnShowDocument(Rec, IsHandled);
                end;
            }
        }
    }

    [IntegrationEvent(false, false)]
    local procedure OnShowDocument(var ReservationWorksheetLog: Record "Reservation Worksheet Log"; var IsHandled: Boolean)
    begin
    end;
}
