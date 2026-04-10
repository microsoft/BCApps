// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CostAccounting.Ledger;

using Microsoft.Foundation.Navigate;
using System.Security.User;

page 1103 "Cost Entries"
{
    AdditionalSearchTerms = 'entries';
    ApplicationArea = CostAccounting;
    Caption = 'Cost Entries';
    DataCaptionFields = "Cost Type No.";
    Editable = false;
    PageType = List;
    SourceTable = "Cost Entry";
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control4)
            {
                ShowCaption = false;
                field("Cost Type No."; Rec."Cost Type No.")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the subtype of the cost center. This is an information field and is not used for any other purposes. Choose the field to select the cost subtype.';
                }
                field("Cost Center Code"; Rec."Cost Center Code")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the cost center code. The code serves as a default value for cost posting that is captured later in the cost journal.';
                }
                field("Cost Object Code"; Rec."Cost Object Code")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the cost object code. The code serves as a default value for cost posting that is captured later in the cost journal.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the number of the related document.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the description of the cost entry.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the amount of the cost entry.';
                }
                field("G/L Account"; Rec."G/L Account")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the G/L account that the cost entry applies to.';
                }
                field("G/L Entry No."; Rec."G/L Entry No.")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the entry number of the corresponding general ledger entry that is associated with this cost entry. For combined entries, the entry number of the last general ledger entry is saved in the field. This is the entry with the highest entry number.';
                }
                field("Allocation ID"; Rec."Allocation ID")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the ID of the allocation key that the cost budget entry comes from.';
                }
                field("Allocation Description"; Rec."Allocation Description")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the description that explains the allocation level and shares.';
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                }
                field(Allocated; Rec.Allocated)
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies whether the cost entry has been allocated.';
                }
                field("Additional-Currency Amount"; Rec."Additional-Currency Amount")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the amount of this entry, in the additional reporting currency.';
                    Visible = false;
                }
                field("Allocated with Journal No."; Rec."Allocated with Journal No.")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies which cost journal was used to allocate the cost.';
                }
                field("System-Created Entry"; Rec."System-Created Entry")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the entry created by the system for the cost entry.';
                }
                field("Source Code"; Rec."Source Code")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the source code that specifies where the entry was created.';
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
                }
                field("Batch Name"; Rec."Batch Name")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the journal batch name used in the posting. The name is copied from the Journal Template Name field on the cost journal line.';
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation(Rec."User ID");
                    end;
                }
                field("Debit Amount"; Rec."Debit Amount")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the total of the ledger entries that represent debits.';
                    Visible = false;
                }
                field("Credit Amount"; Rec."Credit Amount")
                {
                    ApplicationArea = CostAccounting;
                    ToolTip = 'Specifies the total of the ledger entries that represent credits.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("&Navigate")
            {
                ApplicationArea = CostAccounting;
                Caption = 'Find entries...';
                Image = Navigate;
                ShortCutKey = 'Ctrl+Alt+Q';
                ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';

                trigger OnAction()
                var
                    Navigate: Page Navigate;
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

                actionref("&Navigate_Promoted"; "&Navigate")
                {
                }
            }
        }
    }
}

