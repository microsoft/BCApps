// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

page 10973 "FR E-Invoice Messages"
{
    ApplicationArea = Basic, Suite;
    Caption = 'French E-Invoice Lifecycle';
    PageType = List;
    SourceTable = "FR E-Invoice Message";
    SourceTableView = sorting("Entry No.") order(descending);
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    UsageCategory = None;

    layout
    {
        area(content)
        {
            repeater(Messages)
            {
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Event Date"; Rec."Event Date")
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
                field("Source Occurrence ID"; Rec."Source Occurrence ID")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Original Entry No."; Rec."Original Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("E-Document Message Entry No."; Rec."E-Document Message Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("External Message ID"; Rec."External Message ID")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Received At"; Rec."Received At")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Sender Platform ID"; Rec."Sender Platform ID")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Sender Platform Scheme"; Rec."Sender Platform Scheme")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Sender Platform Name"; Rec."Sender Platform Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Invoice Issue Date"; Rec."Invoice Issue Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Invoice Receipt At"; Rec."Invoice Receipt At")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Invoice Issuer ID"; Rec."Invoice Issuer ID")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Invoice Issuer Scheme"; Rec."Invoice Issuer Scheme")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Invoice Issuer Name"; Rec."Invoice Issuer Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }
}