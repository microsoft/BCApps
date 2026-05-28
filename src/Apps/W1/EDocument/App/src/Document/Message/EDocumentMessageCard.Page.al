// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

/// <summary>
/// Default card for an "E-Document Message" row. Format-specific UX (Order Response Review,
/// MLR validation-rules display, etc.) is the Type's own page, opened via the "View Payload"
/// action which delegates to "IEDocumentMessageType.ViewMessage".
/// </summary>
page 6137 "E-Document Message Card"
{
    PageType = Card;
    SourceTable = "E-Document Message";
    Caption = 'E-Document Message';
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; Editable = false; }
                field("Related E-Document No."; Rec."Related E-Document No.") { ApplicationArea = All; Editable = false; }
                field("Message Type"; Rec."Message Type") { ApplicationArea = All; Editable = false; }
                field(Direction; Rec.Direction) { ApplicationArea = All; Editable = false; }
                field("Status Code"; Rec."Status Code") { ApplicationArea = All; Editable = false; }
                field(Status; Rec.Status) { ApplicationArea = All; Editable = false; }
                field("Service Code"; Rec."Service Code") { ApplicationArea = All; Editable = false; }
                field("Sent / Received At"; Rec."Sent / Received At") { ApplicationArea = All; Editable = false; }
                field("Last Error"; Rec."Last Error") { ApplicationArea = All; Editable = false; }
                field("Created At"; Rec."Created At") { ApplicationArea = All; Editable = false; }
                field("Created By"; Rec."Created By") { ApplicationArea = All; Editable = false; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ViewPayload)
            {
                ApplicationArea = All;
                Caption = 'View Payload';
                Image = View;
                ToolTip = 'Open the format-specific view of this message (delegates to Type.ViewMessage).';

                trigger OnAction()
                var
                    TypeImpl: Interface IEDocumentMessageType;
                begin
                    TypeImpl := Rec."Message Type";
                    TypeImpl.ViewMessage(Rec);
                end;
            }
        }
    }
}
