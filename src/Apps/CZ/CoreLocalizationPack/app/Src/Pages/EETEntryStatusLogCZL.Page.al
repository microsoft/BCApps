// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance;

using System.Utilities;

#pragma implicitwith disable
page 31148 "EET Entry Status Log CZL"
{
    Caption = 'EET Entry Status Log';
    DataCaptionFields = "EET Entry No.";
    Editable = false;
    PageType = List;
    SourceTable = "EET Entry Status Log CZL";
    SourceTableView = order(descending);
    ApplicationArea = Basic, Suite;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Changed At"; Rec."Changed At")
                {
                }
                field(Status; Rec.Status)
                {
                }
                field(Description; Rec.Description)
                {
                }
                field("Global Transaction Id"; Rec."Global Transaction Id")
                {
                }
                field(RequestMessage; Rec.GetRequestFileName())
                {
                    Caption = 'Request Message';
                    ToolTip = 'Specifies the name of the file with the request message that was sent to the EET service for this status change. The file name is shown only if the message was saved according to the Request Log Level in the EET service setup. Select the field to download the message.';

                    trigger OnDrillDown()
                    begin
                        Rec.DownloadRequestMessage();
                    end;
                }
                field(ResponseMessage; Rec.GetResponseFileName())
                {
                    Caption = 'Response Message';
                    ToolTip = 'Specifies the name of the file with the response message that was received from the EET service for this status change. The file name is shown only if the message was saved according to the Response Log Level in the EET service setup. Select the field to download the message.';

                    trigger OnDrillDown()
                    begin
                        Rec.DownloadResponseMessage();
                    end;
                }
                field("EET Entry No."; Rec."EET Entry No.")
                {
                    Visible = false;
                }
                field("Entry No."; Rec."Entry No.")
                {
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            part(ErrorMessagesPart; "Error Messages Part")
            {
                Caption = 'Errors and Warnings';
                ShowFilter = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(DownloadRequestMessage)
            {
                Caption = 'Download Request';
                Enabled = HasRequestMessage;
                Image = Export;
                ToolTip = 'Downloads the data message that was sent to the EET service when the status was changed. The message is available only if it was saved according to the Request Log Level in the EET service setup.';

                trigger OnAction()
                begin
                    Rec.DownloadRequestMessage();
                end;
            }
            action(DownloadResponseMessage)
            {
                Caption = 'Download Response';
                Enabled = HasResponseMessage;
                Image = Export;
                ToolTip = 'Downloads the response that was received from the EET service when the status was changed. The response is available only if it was saved according to the Response Log Level in the EET service setup.';

                trigger OnAction()
                begin
                    Rec.DownloadResponseMessage();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(DownloadRequestMessage_Promoted; DownloadRequestMessage)
                {
                }
                actionref(DownloadResponseMessage_Promoted; DownloadResponseMessage)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        HasRequestMessage := Rec.HasRequestMessage();
        HasResponseMessage := Rec.HasResponseMessage();
        UpdateErrorMessages();
    end;

    var
        HasRequestMessage: Boolean;
        HasResponseMessage: Boolean;

    local procedure UpdateErrorMessages()
    var
        ErrorMessage: Record "Error Message";
        TempErrorMessage: Record "Error Message" temporary;
    begin
        ErrorMessage.SetRange("Context Record ID", Rec.RecordId);
        ErrorMessage.CopyToTemp(TempErrorMessage);
        CurrPage.ErrorMessagesPart.PAGE.SetRecords(TempErrorMessage);
        CurrPage.ErrorMessagesPart.PAGE.Update();
    end;
}
