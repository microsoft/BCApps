// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

page 10973 "FR E-Inv. Lifecycle Responses"
{
    ApplicationArea = Basic, Suite;
    Caption = 'E-Invoice Lifecycle Responses';
    Editable = false;
    InherentPermissions = X;
    PageType = List;
    SourceTable = "FR E-Invoice Lifecycle Resp.";
    SourceTableView = sorting("E-Document Entry No.", "Received At") order(descending);
    UsageCategory = History;

    layout
    {
        area(Content)
        {
            repeater(Responses)
            {
                field("Response ID"; Rec."Response ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the identifier of the lifecycle response.';
                }
                field("Invoice ID"; Rec."Invoice ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the identifier of the electronic invoice.';
                }
                field("Response Type"; Rec."Response Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of lifecycle response received for the electronic invoice.';
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code that indicates the reason for the lifecycle response.';
                }
                field("Reason Description"; Rec."Reason Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the reason for the lifecycle response.';
                }
                field("Received At"; Rec."Received At")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date and time when the lifecycle response was received.';
                }
                field("E-Document Message Entry No."; Rec."E-Document Message Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry number of the related electronic document message.';
                }
            }
        }
    }
}