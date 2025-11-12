// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.RateChange;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using Microsoft.Utilities;

page 553 "VAT Rate Change Log Entries"
{
    Caption = 'VAT Rate Change Log Entries';
    Editable = false;
    PageType = List;
    SourceTable = "VAT Rate Change Log Entry";
    SourceTableView = sorting("Entry No.");

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                }
                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the table. This field is intended only for internal use.';
                    Visible = false;
                }
                field("Table Caption"; Rec."Table Caption")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the table. This field is intended only for internal use.';
                    Visible = false;
                }
                field("Record Identifier"; Format(Rec."Record ID"))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Record Identifier';
                    ToolTip = 'Specifies the location of this line in the printed or exported VAT report.';
                }
                field("Old Gen. Prod. Posting Group"; Rec."Old Gen. Prod. Posting Group")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the general product posting group before the VAT rate change conversion.';
                }
                field("New Gen. Prod. Posting Group"; Rec."New Gen. Prod. Posting Group")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the new general product posting group after the VAT rate change conversion.';
                }
                field("Old VAT Prod. Posting Group"; Rec."Old VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT product posting group before the VAT rate change conversion.';
                }
                field("New VAT Prod. Posting Group"; Rec."New VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the new VAT product posting group after the VAT rate change conversion.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description for the VAT rate change conversion.';
                }
                field(Converted; Rec.Converted)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the VAT rate change conversion.';
                }
                field("Converted Date"; Rec."Converted Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the VAT rate change log entry was created.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(Show)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Show';
                    Ellipsis = true;
                    Image = View;
                    ToolTip = 'View the log details.';

                    trigger OnAction()
                    var
                        SalesHeader: Record "Sales Header";
                        SalesLine: Record "Sales Line";
                        PurchaseHeader: Record "Purchase Header";
                        PurchaseLine: Record "Purchase Line";
                        PageManagement: Codeunit "Page Management";
                        RecRef: RecordRef;
                        IsHandled: Boolean;
                    begin
                        if Format(Rec."Record ID") = '' then
                            exit;
                        if not RecRef.Get(Rec."Record ID") then
                            Error(Text0002);

                        case Rec."Table ID" of
                            Database::"Sales Header",
                          Database::"Purchase Header",
                          Database::"Gen. Journal Line",
                          Database::Item,
                          Database::"G/L Account",
                          Database::"Item Category",
                          Database::"Item Charge",
                          Database::Resource:
                                PageManagement.PageRunModal(RecRef);
                            Database::"Sales Line":
                                begin
                                    RecRef.SetTable(SalesLine);
                                    SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
                                    PageManagement.PageRunModal(SalesHeader);
                                end;
                            Database::"Purchase Line":
                                begin
                                    RecRef.SetTable(PurchaseLine);
                                    PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
                                    PageManagement.PageRunModal(PurchaseHeader);
                                end;
                            else begin
                                IsHandled := false;
                                OnAfterShow(Rec, IsHandled, RecRef);
                                if not IsHandled then
                                    Message(Text0001);
                            end;
                        end;
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Show_Promoted; Show)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Rec.CalcFields("Table Caption");
    end;

    var
#pragma warning disable AA0074
        Text0001: Label 'Search for the pages to see this entry.';
        Text0002: Label 'The related entry has been posted or deleted.';
#pragma warning restore AA0074

    [IntegrationEvent(false, false)]
    local procedure OnAfterShow(VATRateChangeLogEntry: Record "VAT Rate Change Log Entry"; var IsHandled: Boolean; RecRef: RecordRef)
    begin
    end;
}

