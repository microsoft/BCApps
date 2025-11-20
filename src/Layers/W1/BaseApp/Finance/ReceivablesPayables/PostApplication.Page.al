// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;

page 579 "Post Application"
{
    Caption = 'Post Application';
    PageType = StandardDialog;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(JnlTemplateName; ApplyUnapplyParameters."Journal Template Name")
                {
                    ApplicationArea = BasicBE;
                    Caption = 'Journal Template Name';
                    ToolTip = 'Specifies the name of the journal template that is used for the posting.';
                    Visible = IsBatchVisible;
                }
                field(JnlBatchName; ApplyUnapplyParameters."Journal Batch Name")
                {
                    ApplicationArea = BasicBE;
                    Caption = 'Journal Batch Name';
                    ToolTip = 'Specifies the name of the journal batch that is used for the posting.';
                    Visible = IsBatchVisible;

                    trigger OnValidate()
                    begin
                        if ApplyUnapplyParameters."Journal Batch Name" <> '' then begin
                            ApplyUnapplyParameters.TestField("Journal Template Name");
                            GenJnlBatch.Get(ApplyUnapplyParameters."Journal Template Name", ApplyUnapplyParameters."Journal Batch Name");
                        end;
                    end;
                }
                field(DocNo; ApplyUnapplyParameters."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Document No.';
                    ToolTip = 'Specifies the document number of the entry to be applied.';
                }
                field(ExtDocNo; ApplyUnapplyParameters."External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'External Document No.';
                    ToolTip = 'Specifies the external document number of the entry to be applied.';
                }
                field(PostingDate; ApplyUnapplyParameters."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posting Date';
                    ToolTip = 'Specifies the posting date of the entry to be applied.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        GLSetup.GetRecordOnce();
        IsBatchVisible := GLSetup."Journal Templ. Name Mandatory";
    end;

    protected var
        GenJnlBatch: Record "Gen. Journal Batch";
        GLSetup: Record "General Ledger Setup";
        ApplyUnapplyParameters: Record "Apply Unapply Parameters";
        IsBatchVisible: Boolean;

    procedure SetParameters(NewApplyUnapplyParameters: Record "Apply Unapply Parameters")
    begin
        ApplyUnapplyParameters := NewApplyUnapplyParameters;
    end;

    procedure GetParameters(var NewApplyUnapplyParameters: Record "Apply Unapply Parameters")
    begin
        NewApplyUnapplyParameters := ApplyUnapplyParameters;
    end;
}

