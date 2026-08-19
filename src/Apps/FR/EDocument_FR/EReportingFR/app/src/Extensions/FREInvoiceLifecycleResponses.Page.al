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
                }
                field("Invoice ID"; Rec."Invoice ID")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Response Type"; Rec."Response Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Reason Description"; Rec."Reason Description")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Received At"; Rec."Received At")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("E-Document Message Entry No."; Rec."E-Document Message Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }
}