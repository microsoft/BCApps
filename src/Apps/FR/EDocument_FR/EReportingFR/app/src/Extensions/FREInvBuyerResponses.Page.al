// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.eServices.EDocument;

page 10974 "FR E-Inv. Buyer Responses"
{
    ApplicationArea = Basic, Suite;
    Caption = 'E-Invoice Buyer Responses';
    Editable = false;
    InherentPermissions = X;
    PageType = List;
    SourceTable = "FR E-Invoice Buyer Response";
    UsageCategory = History;

    layout
    {
        area(Content)
        {
            repeater(Responses)
            {
                field("Response Type"; Rec."Response Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of response sent for the electronic invoice.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the processing status of the buyer response.';
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code that indicates the reason for the response.';
                }
                field("Reason Description"; Rec."Reason Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the reason for the response.';
                }
                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date and time when the buyer response was created.';
                }
                field("E-Document Message Entry No."; Rec."E-Document Message Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry number of the related electronic document message.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(GetResponse)
            {
                AccessByPermission = tabledata "FR E-Invoice Buyer Response" = M;
                ApplicationArea = Basic, Suite;
                Caption = 'Get Response';
                Enabled = Rec.Status = Rec.Status::"Pending Response";
                Image = Refresh;
                ToolTip = 'Get the latest processing response for the buyer response message.';

                trigger OnAction()
                var
                    EDocument: Record "E-Document";
                    FREInvoiceBuyerResponseMgt: Codeunit "FR E-Inv. Buyer Resp. Mgt.";
                begin
                    EDocument.Get(Rec."E-Document Entry No.");
                    FREInvoiceBuyerResponseMgt.GetResponse(EDocument);
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            actionref(GetResponsePromoted; GetResponse)
            {
            }
        }
    }
}