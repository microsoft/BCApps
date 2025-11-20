// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AllocationAccount;

page 2672 "Fixed Account Distribution"
{
    PageType = ListPart;
    SourceTable = "Alloc. Account Distribution";
    AutoSplitKey = true;
    DelayedInsert = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Destination Account Type"; Rec."Destination Account Type")
                {
                    ApplicationArea = All;
                    Caption = 'Destination Account Type';
                    ToolTip = 'Specifies the account type that the amount will be posted to.';
                }
                field("Destination Account Number"; Rec."Destination Account Number")
                {
                    ApplicationArea = All;
                    Caption = 'Destination Account Number';
                    ToolTip = 'Specifies the account number that the amount will be posted to. You can select Destination Account Number if Destination Account Type field is G/L Account or Bank Account. If Destination Account Type field is Inherit from Parent, Destination Account Number and Destination Account Type will be taken from the line when the Allocation Account No. field is set.';
                }
                field("Destination Account Name"; Rec.LookupDistributionAccountName())
                {
                    ApplicationArea = All;
                    Caption = 'Destination Account Name';
                    ToolTip = 'Specifies the name of the account that the amount will be posted to.';
                    Editable = false;
                }
                field(Share; Rec.Share)
                {
                    Caption = 'Share';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Share that is used for the variable account distributions.';
                }
                field(Percent; Rec.Percent)
                {
                    Caption = 'Percent';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Percent that is used for the variable account distributions.';
                    BlankZero = true;
                }
            }
        }
    }
    actions
    {
        area(processing)
        {
            action(PreviewDistributions)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Test Allocation';
                Image = Translation;
#pragma warning disable AA0219
                ToolTip = 'Test the allocation account''s setup by distributing an amount on different dates.';
#pragma warning restore AA0219
                Scope = Page;

                trigger OnAction()
                var
                    AllocationAccount: Record "Allocation Account";
                    AllocationAccountPreview: Page "Allocation Account Preview";
                begin
                    AllocationAccount.Get(Rec."Allocation Account No.");
                    AllocationAccountPreview.SetFixedAllocation(true);
                    AllocationAccountPreview.UpdateAllocationAccount(AllocationAccount);
                    AllocationAccountPreview.Run();
                end;
            }
            action(Dimensions)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Dimensions';
                Image = Dimensions;
                ShortCutKey = 'Shift+Ctrl+D';
#pragma warning disable AA0219
                ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to journal lines to distribute costs and analyze transaction history.';
#pragma warning restore AA0219
                trigger OnAction()
                begin
                    Rec.ShowDimensions();
                    if Rec."Dimension Set ID" <> xRec."Dimension Set ID" then
                        Rec.Modify();
                end;
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Account Type" := Rec."Account Type"::Fixed;
        Rec."Destination Account Type" := xRec."Destination Account Type";
    end;
}
