// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Foundation.Navigate;

page 12136 "Computed Contribution"
{
    Caption = 'Computed Contribution';
    Editable = false;
    PageType = List;
    SourceTable = "Computed Contribution";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the transaction date of the source document that generated the contribution tax entry.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an identification number that refers to the source document that generated the contribution tax entry.';
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an identification number, which links the vendor''s source document to the contribution tax entry.';
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the identification number of the vendor that is related to the contribution tax entry.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the contribution tax entry is posted.';
                }
                field("Social Security Code"; Rec."Social Security Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Social Security code that is applied to the contribution tax entry.';
                }
                field("Gross Amount"; Rec."Gross Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the original purchase that is subject to Social Security tax.';
                }
                field("Soc.Sec.Non Taxable Amount"; Rec."Soc.Sec.Non Taxable Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the original purchase that is excluded from Social Security tax liability, based on provisions in the law.';
                }
                field("INAIL Code"; Rec."INAIL Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the INAIL contribution tax code that is applied to the purchase for workers'' compensation insurance.';
                }
                field("INAIL Gross Amount"; Rec."INAIL Gross Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount of the original purchase that is subject to INAIL contribution tax.';
                }
                field("INAIL Non Taxable Amount"; Rec."INAIL Non Taxable Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the original purchase that is excluded from the INAIL contribution tax, based on provisions in the law.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Navigate)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Image = Navigate;
                ToolTip = 'View the number and type of entries that have the same document number or posting date.';

                trigger OnAction()
                begin
                    Navigate.SetDoc(Rec."Posting Date", Rec."Document No.");
                    Navigate.Run();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Navigate_Promoted; Navigate)
                {
                }
            }
        }
    }

    var
        Navigate: Page Navigate;
}

