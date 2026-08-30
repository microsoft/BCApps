// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SpendRequest;

page 6840 "Spend Request List"
{
    Caption = 'Spend Requests';
    PageType = List;
    ApplicationArea = Basic, Suite;
    UsageCategory = Lists;
    SourceTable = "Spend Request";
    SourceTableView = where("Document Type" = const(" "));
    CardPageId = "Spend Request Card";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field("No."; Rec."No.")
                {
                }
                field("Requested By"; Rec."Requested By")
                {
                }
                field(Purpose; Rec.Purpose)
                {
                }
                field(Status; Rec.Status)
                {
                }
                field("Total Expected Amount (LCY)"; Rec."Total Expected Amount (LCY)")
                {
                }
                field("Total Spent Amount (LCY)"; Rec."Total Spent Amount (LCY)")
                {
                }
                field(RemainingAmountLCY; Rec.GetRemainingAmountLCY())
                {
                    Caption = 'Remaining Amount (LCY)';
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    ToolTip = 'Specifies the difference between estimated amount and actually spent amount.';
                    Importance = Additional;
                }
                field("Expected Start Date"; Rec."Expected Start Date")
                {
                }
                field("Expected End Date"; Rec."Expected End Date")
                {
                }
                field("Approved by User Name"; Rec."Approved/Rejected by User Name")
                {
                }
                field(ClosedAt; Rec."Closed At")
                {
                }
                field(ClosedByDoc; Rec."Closed By Document No.")
                {
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            group(Action21)
            {
                Caption = 'Submit';
                Image = ReleaseDoc;

                action(Submit)
                {
                    Caption = 'Submit';
                    ToolTip = 'Set the status field to Submitted so that it can be processed for approval.';
                    ApplicationArea = Basic, Suite;
                    Enabled = Rec.Status <> Rec.Status::Released;
                    Image = ReleaseDoc;

                    trigger OnAction()
                    var
                        ReleaseSpendRequest: Codeunit "Release Spend Request";
                    begin
                        ReleaseSpendRequest.PerformManualRelease(Rec);
                    end;
                }
                action(ReOpen)
                {
                    Caption = 'Reopen';
                    ToolTip = 'Set the status field to Open so that it can be edited.';
                    ApplicationArea = Basic, Suite;
                    Enabled = Rec.Status <> Rec.Status::Open;
                    Image = ReOpen;

                    trigger OnAction()
                    var
                        ReleaseSpendRequest: Codeunit "Release Spend Request";
                    begin
                        ReleaseSpendRequest.PerformManualReopen(Rec);
                    end;
                }
                action(Close)
                {
                    Caption = 'Close';
                    ToolTip = 'Set the status field to Closed so it cannot be used anymore.';
                    ApplicationArea = Basic, Suite;
                    Enabled = Rec.Status <> Rec.Status::Closed;
                    Image = CloseDocument;

                    trigger OnAction()
                    var
                        ReleaseSpendRequest: Codeunit "Release Spend Request";
                    begin
                        ReleaseSpendRequest.PerformManualClose(Rec);
                    end;
                }
            }
            group(SpendRequestApproval)
            {
                Caption = 'Approval';
                action(Approve)
                {
                    Caption = 'Approve';
                    ToolTip = 'Manually set the status field to Approved';
                    ApplicationArea = Basic, Suite;
                    Enabled = Rec.Status <> Rec.Status::Approved;
                    Image = Approve;

                    trigger OnAction()
                    begin
                        Rec.Approve();
                    end;
                }
                action(Reject)
                {
                    Caption = 'Reject';
                    ToolTip = 'Manually set the status field to Rejected';
                    ApplicationArea = Basic, Suite;
                    Enabled = Rec.Status <> Rec.Status::Closed;
                    Image = Reject;

                    trigger OnAction()
                    begin
                        Rec.Reject();
                    end;
                }
            }
            action(RefreshCurrency)
            {
                Caption = 'Refresh Currency Exchange rate';
                ToolTip = 'Updates the currency exchange rate and Total Expected Amount (LCY).';
                Enabled = (Rec."Currency Code" <> '') and (Rec.Status <> Rec.Status::Closed);
                ApplicationArea = Basic, Suite;
                Image = Recalculate;

                trigger OnAction()
                begin
                    if Rec.Status = Rec.Status::Closed then
                        Error(SpendRequestClosedErr, Rec.GetDocumentTypeDescription());
                    Rec.UpdateCurrencyExchangeRate();
                    Rec.Modify();
                end;
            }
        }
        area(Navigation)
        {
            action(Dimensions)
            {
                AccessByPermission = TableData Microsoft.Finance.Dimension.Dimension = R;
                ApplicationArea = Dimensions;
                Caption = 'Dimensions';
                Enabled = Rec."No." <> '';
                Image = Dimensions;
                ShortCutKey = 'Alt+D';
                ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to expenses to distribute costs and analyze transaction history.';

                trigger OnAction()
                begin
                    Rec.ShowDocDim();
                    CurrPage.SaveRecord();
                end;
            }
        }
        area(Reporting)
        {
            group(Report)
            {
                Caption = 'Report';
                Image = Print;

                action(Print)
                {
                    Caption = 'Print';
                    ToolTip = 'Prints the selected spend requests.';
                    ApplicationArea = Basic, Suite;
                    Image = Print;

                    trigger OnAction()
                    var
                        SpendRequest: Record "Spend Request";
                        SpendRequestDocument: Report "Spend Request Document";
                    begin
                        CurrPage.SetSelectionFilter(SpendRequest);
                        SpendRequestDocument.SetTableView(SpendRequest);
                        SpendRequestDocument.Run();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';
                group(Category_Submit)
                {
                    Caption = 'Submit';
                    ShowAs = SplitButton;

                    actionref(Submit_Promoted; Submit)
                    {
                    }
                    actionref(Reopen_Promoted; Reopen)
                    {
                    }
                    actionref(Close_Promoted; Close)
                    {
                    }
                }
                actionref(RefreshCurrency_Promoted; RefreshCurrency)
                {
                }
            }
            group(Category_Approval)
            {
                Caption = 'Approval';

                actionref(Approve_Promoted; Approve)
                {
                }
                actionref(Reject_Promoted; Reject)
                {
                }
            }
            group(Category_SpendRequest)
            {
                Caption = 'Spend Request';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
            }
        }
    }

    var
        SpendRequestClosedErr: Label 'A closed %1 cannot be updated.', Comment = '%1 = document type description, e.g. spend request or Travel Request';
}
