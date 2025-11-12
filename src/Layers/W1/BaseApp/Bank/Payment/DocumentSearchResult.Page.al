// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

/// <summary>
/// Page 986 "Document Search Result" displays the results of document searches performed during payment registration.
/// This page shows a list of documents found based on search criteria, allowing users to select and drill down into document details.
/// </summary>
/// <remarks>
/// Source table: Document Search Result (temporary). Used to display search results
/// from document search operations during payment processing workflows.
/// </remarks>
page 986 "Document Search Result"
{
    Caption = 'Document Search Result';
    Editable = false;
    PageType = List;
    SourceTable = "Document Search Result";
    SourceTableTemporary = true;
    SourceTableView = sorting("Doc. No.")
                      order(ascending);

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Doc. No."; Rec."Doc. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies information about a non-posted document that is found using the Document Search window during manual payment processing.';

                    trigger OnDrillDown()
                    begin
                        PaymentRegistrationMgt.ShowRecords(Rec);
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies information about a non-posted document that is found using the Document Search window during manual payment processing.';

                    trigger OnDrillDown()
                    begin
                        PaymentRegistrationMgt.ShowRecords(Rec);
                    end;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies information about a non-posted document that is found using the Document Search window during manual payment processing.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ShowRecord)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Show';
                Image = ShowSelected;
                ToolTip = 'Open the document on the selected line.';

                trigger OnAction()
                begin
                    PaymentRegistrationMgt.ShowRecords(Rec);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(ShowRecord_Promoted; ShowRecord)
                {
                }
            }
        }
    }

    var
        PaymentRegistrationMgt: Codeunit "Payment Registration Mgt.";
}

