// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Spike.Contoso;

using Microsoft.eServices.EDocument.Service;
using Microsoft.eServices.EDocument.Integration.Receive;
using System.Utilities;

page 6943 "Contoso Mailbox"
{
    PageType = List;
    SourceTable = "Contoso Mailbox Entry";
    Caption = 'Contoso Mailbox (Spike Simulated Network)';
    UsageCategory = Lists;
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; }
                field(Direction; Rec.Direction) { ApplicationArea = All; }
                field(Kind; Rec.Kind) { ApplicationArea = All; }
                field(Reference; Rec.Reference) { ApplicationArea = All; }
                field("Service Code"; Rec."Service Code") { ApplicationArea = All; }
                field("Created At"; Rec."Created At") { ApplicationArea = All; }
                field(Processed; Rec.Processed) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action("View Content")
            {
                ApplicationArea = All;
                Caption = 'View Content';
                Image = View;
                ToolTip = 'Show the raw XML payload of this entry.';

                trigger OnAction()
                var
                    BlobBuf: Codeunit "Temp Blob";
                    InStream: InStream;
                    Content: Text;
                begin
                    Rec.GetContent(BlobBuf);
                    BlobBuf.CreateInStream(InStream, TextEncoding::UTF8);
                    InStream.Read(Content);
                    Message(Content);
                end;
            }
            action("Process Inbound Messages")
            {
                ApplicationArea = All;
                Caption = 'Process Inbound Messages';
                Image = ReceiveDocument;
                ToolTip = 'Run the framework''s inbound receive dispatcher against this service. Picks up unprocessed Message rows for the service.';

                trigger OnAction()
                var
                    EDocService: Record Microsoft.eServices.EDocument."E-Document Service";
                    Dispatcher: Codeunit "E-Doc. Receive Messages";
                    Processed: Integer;
                begin
                    if EDocService.Get(Rec."Service Code") then begin
                        Processed := Dispatcher.Run(EDocService);
                        Message('Processed %1 inbound message(s).', Processed);
                    end;
                end;
            }
        }
    }
}
