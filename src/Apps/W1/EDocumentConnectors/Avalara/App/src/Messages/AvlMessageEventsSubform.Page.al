// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.Avalara;

/// <summary>
/// Subform page displaying message events from Avalara document processing in chronological order.
/// </summary>
page 6803 "Avl Message Events Subform"
{
    ApplicationArea = All;
    Caption = 'Message Events';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = ListPart;
    SourceTable = "Avl Message Event";

    layout
    {
        area(Content)
        {
            repeater(Events)
            {
                field(EDocEntryNo; Rec.EDocEntryNo)
                {
                    ApplicationArea = All;
                    Caption = 'E-Document Entry No.';
                    ToolTip = 'Specifies the entry number of the related E-Document.';
                }
                field(MessageRow; Rec.MessageRow)
                {
                    ApplicationArea = All;
                    Caption = 'No.';
                    ToolTip = 'Specifies the sequence number of the event.';
                }
                field(eventDateTime; Rec.eventDateTime)
                {
                    ApplicationArea = All;
                    Caption = 'Event Date/Time';
                    ToolTip = 'Specifies the date and time when the event occurred.';
                }
                field(message; Rec.message)
                {
                    ApplicationArea = All;
                    Caption = 'Message';
                    ToolTip = 'Specifies the event description from Avalara.';
                }
                field(responseKey; Rec.responseKey)
                {
                    ApplicationArea = All;
                    Caption = 'Response Key';
                    ToolTip = 'Specifies the technical response key from the API.';
                }
                field(responseValue; Rec.responseValue)
                {
                    ApplicationArea = All;
                    Caption = 'Response Value';
                    ToolTip = 'Specifies the technical response value from the API.';
                }
                field(id; Rec.id)
                {
                    ApplicationArea = All;
                    Caption = 'Message ID';
                    ToolTip = 'Specifies the unique identifier for the parent message.';
                    Visible = false;
                }
                field(PostedDocument; Rec.PostedDocument)
                {
                    ApplicationArea = All;
                    Caption = 'Posted Document';
                    ToolTip = 'Specifies the posted document number associated with this event.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ViewFullMessage)
            {
                ApplicationArea = All;
                Caption = 'View Full Message';
                Image = ShowList;
                ToolTip = 'View the complete message text for this event.';

                trigger OnAction()
                var
                    FullMessageDialog: Page "Avl Full Message Dialog";
                begin
                    FullMessageDialog.SetMessage(Rec.GetFullMessage());
                    FullMessageDialog.RunModal();
                end;
            }
        }
    }
}
