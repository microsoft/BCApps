// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Payables;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Navigate;
using System.Security.User;

page 63 "Applied Employee Entries"
{
    Caption = 'Applied Employee Entries';
    DataCaptionExpression = Heading;
    Editable = false;
    PageType = List;
    SourceTable = "Employee Ledger Entry";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = BasicHR;
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the employee entry''s document type.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = BasicHR;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = BasicHR;
                }
                field("Global Dimension 1 Code"; Rec."Global Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = DimVisible1;
                }
                field("Global Dimension 2 Code"; Rec."Global Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = DimVisible2;
                }
                field("Salespers./Purch. Code"; Rec."Salespers./Purch. Code")
                {
                    ApplicationArea = BasicHR;
                    Visible = false;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = BasicHR;
                }
                field("Original Amount"; Rec."Original Amount")
                {
                    ApplicationArea = BasicHR;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = BasicHR;
                    Visible = AmountVisible;
                }
                field("Debit Amount"; Rec."Debit Amount")
                {
                    ApplicationArea = BasicHR;
                    Visible = DebitCreditVisible;
                }
                field("Credit Amount"; Rec."Credit Amount")
                {
                    ApplicationArea = BasicHR;
                    Visible = DebitCreditVisible;
                }
                field("Closed by Amount"; Rec."Closed by Amount")
                {
                    ApplicationArea = BasicHR;
                }
                field("Closed by Currency Code"; Rec."Closed by Currency Code")
                {
                    ApplicationArea = BasicHR;
                }
                field("Closed by Currency Amount"; Rec."Closed by Currency Amount")
                {
                    ApplicationArea = BasicHR;
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = BasicHR;
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation(Rec."User ID");
                    end;
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = BasicHR;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Ent&ry")
            {
                Caption = 'Ent&ry';
                Image = Entry;
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
                    end;
                }
                action("Detailed &Ledger Entries")
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Detailed &Ledger Entries';
                    Image = View;
                    RunObject = Page "Detailed Empl. Ledger Entries";
                    RunPageLink = "Employee Ledger Entry No." = field("Entry No."),
                                  "Employee No." = field("Employee No.");
                    RunPageView = sorting("Employee Ledger Entry No.", "Posting Date");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View a summary of all the posted entries and adjustments related to a specific employee ledger entry.';
                }
            }
        }
        area(processing)
        {
            action("&Navigate")
            {
                ApplicationArea = BasicHR;
                Caption = 'Find entries...';
                Image = Navigate;
                ShortCutKey = 'Ctrl+Alt+Q';
                ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';

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

                actionref("&Navigate_Promoted"; "&Navigate")
                {
                }
                group(Category_Entry)
                {
                    Caption = 'Entry';

                    actionref(Dimensions_Promoted; Dimensions)
                    {
                    }
                    actionref("Detailed &Ledger Entries_Promoted"; "Detailed &Ledger Entries")
                    {
                    }
                }
            }
        }
    }

    trigger OnInit()
    begin
        AmountVisible := true;
    end;

    trigger OnOpenPage()
    begin
        Rec.Reset();
        SetControlVisibility();

        if Rec."Entry No." <> 0 then begin
            CreateEmplLedgEntry := Rec;
            if CreateEmplLedgEntry."Document Type" = CreateEmplLedgEntry."Document Type"::" " then
                Heading := DocumentTxt
            else
                Heading := Format(CreateEmplLedgEntry."Document Type");
            Heading := Heading + ' ' + CreateEmplLedgEntry."Document No.";

            FindApplnEntriesDtldtLedgEntry();
            Rec.SetCurrentKey("Entry No.");
            Rec.SetRange("Entry No.");

            if CreateEmplLedgEntry."Closed by Entry No." <> 0 then begin
                Rec."Entry No." := CreateEmplLedgEntry."Closed by Entry No.";
                Rec.Mark(true);
            end;

            Rec.SetCurrentKey("Closed by Entry No.");
            Rec.SetRange("Closed by Entry No.", CreateEmplLedgEntry."Entry No.");
            if Rec.Find('-') then
                repeat
                    Rec.Mark(true);
                until Rec.Next() = 0;

            Rec.SetCurrentKey("Entry No.");
            Rec.SetRange("Closed by Entry No.");
        end;

        Rec.MarkedOnly(true);
    end;

    var
        CreateEmplLedgEntry: Record "Employee Ledger Entry";
        Navigate: Page Navigate;
        Heading: Text;
        AmountVisible: Boolean;
        DebitCreditVisible: Boolean;
        DimVisible1: Boolean;
        DimVisible2: Boolean;

        DocumentTxt: Label 'Document';

    local procedure FindApplnEntriesDtldtLedgEntry()
    var
        DtldEmplLedgEntry1: Record "Detailed Employee Ledger Entry";
        DtldEmplLedgEntry2: Record "Detailed Employee Ledger Entry";
    begin
        DtldEmplLedgEntry1.SetCurrentKey("Employee Ledger Entry No.");
        DtldEmplLedgEntry1.SetRange("Employee Ledger Entry No.", CreateEmplLedgEntry."Entry No.");
        DtldEmplLedgEntry1.SetRange(Unapplied, false);
        if DtldEmplLedgEntry1.Find('-') then
            repeat
                if DtldEmplLedgEntry1."Employee Ledger Entry No." =
                   DtldEmplLedgEntry1."Applied Empl. Ledger Entry No."
                then begin
                    DtldEmplLedgEntry2.Init();
                    DtldEmplLedgEntry2.SetCurrentKey("Applied Empl. Ledger Entry No.", "Entry Type");
                    DtldEmplLedgEntry2.SetRange(
                      "Applied Empl. Ledger Entry No.", DtldEmplLedgEntry1."Applied Empl. Ledger Entry No.");
                    DtldEmplLedgEntry2.SetRange("Entry Type", DtldEmplLedgEntry2."Entry Type"::Application);
                    DtldEmplLedgEntry2.SetRange(Unapplied, false);
                    if DtldEmplLedgEntry2.Find('-') then
                        repeat
                            if DtldEmplLedgEntry2."Employee Ledger Entry No." <>
                               DtldEmplLedgEntry2."Applied Empl. Ledger Entry No."
                            then begin
                                Rec.SetCurrentKey("Entry No.");
                                Rec.SetRange("Entry No.", DtldEmplLedgEntry2."Employee Ledger Entry No.");
                                if Rec.Find('-') then
                                    Rec.Mark(true);
                            end;
                        until DtldEmplLedgEntry2.Next() = 0;
                end else begin
                    Rec.SetCurrentKey("Entry No.");
                    Rec.SetRange("Entry No.", DtldEmplLedgEntry1."Applied Empl. Ledger Entry No.");
                    if Rec.Find('-') then
                        Rec.Mark(true);
                end;
            until DtldEmplLedgEntry1.Next() = 0;
    end;

    local procedure SetControlVisibility()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        AmountVisible := not (GLSetup."Show Amounts" = GLSetup."Show Amounts"::"Debit/Credit Only");
        DebitCreditVisible := not (GLSetup."Show Amounts" = GLSetup."Show Amounts"::"Amount Only");
        DimVisible1 := GLSetup."Global Dimension 1 Code" <> '';
        DimVisible2 := GLSetup."Global Dimension 2 Code" <> '';
    end;
}

