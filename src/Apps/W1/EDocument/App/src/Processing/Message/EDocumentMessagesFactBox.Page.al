// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Message;

using System.Utilities;

/// <summary>
/// Factbox listpart showing all messages related to an E-Document.
/// Surfaced on the E-Document card page via SubPageLink on "E-Document Entry No.".
/// </summary>
page 6434 "E-Document Messages FactBox"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Messages';
    PageType = ListPart;
    SourceTable = "E-Document Message";
    SourceTableView = sorting("Entry No.") order(descending);
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(content)
        {
            repeater(Messages)
            {
                field("Message Type"; Rec."Message Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the message, for example PEPPOL Order Response.';
                }
                field(Direction; Rec.Direction)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the message was sent (Outgoing) or received (Incoming).';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the current status of the message.';
                }
                field("Response Type"; Rec."Response Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the response type, for example Accepted or Rejected.';
                }
                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the message was created.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ViewXML)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'View XML';
                ToolTip = 'Download the raw XML payload of this message.';
                Image = XMLFile;
                Scope = Repeater;

                trigger OnAction()
                var
                    EDocMessageMgt: Codeunit "E-Doc. Message Mgt.";
                    TempBlob: Codeunit "Temp Blob";
                    InStr: InStream;
                    FileName: Text;
                begin
                    EDocMessageMgt.GetMessageBlob(Rec."Entry No.", TempBlob);
                    if not TempBlob.HasValue() then
                        exit;
                    TempBlob.CreateInStream(InStr);
                    FileName := BuildFileName();
                    DownloadFromStream(InStr, '', '', '', FileName);
                end;
            }
        }
    }

    var
        FileNameTok: Label 'E-Document_%1_Response_%2.xml', Comment = '%1 = E-Document number, %2 = human-readable response type', Locked = true;

    local procedure BuildFileName(): Text
    var
        ResponseTypeText: Text;
    begin
        if Rec."Response Type" = Rec."Response Type"::None then
            ResponseTypeText := Format(Rec."Message Type")
        else
            ResponseTypeText := Format(Rec."Response Type");
        exit(StrSubstNo(FileNameTok, Rec."E-Document Entry No.", ResponseTypeText));
    end;
}
