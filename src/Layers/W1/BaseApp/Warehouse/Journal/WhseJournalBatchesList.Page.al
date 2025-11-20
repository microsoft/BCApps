// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Journal;

using Microsoft.Foundation.Reporting;

page 7329 "Whse. Journal Batches List"
{
    Caption = 'Whse. Journal Batches List';
    DataCaptionExpression = DataCaption();
    DelayedInsert = true;
    Editable = false;
    PageType = List;
    SourceTable = "Warehouse Journal Batch";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Rec.Name)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the name of the warehouse journal batch.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies a description of the warehouse journal batch.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code of the location where the journal batch applies.';
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
                }
                field("No. Series"; Rec."No. Series")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number series from which entry or record numbers are assigned to new entries or records.';
                }
                field("Registering No. Series"; Rec."Registering No. Series")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number series code used to assign document numbers to the warehouse entries that are registered from this journal batch.';
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
        area(processing)
        {
            action("Edit Journal")
            {
                ApplicationArea = Warehouse;
                Caption = 'Edit Journal';
                Image = OpenJournal;
                ShortCutKey = 'Return';
                ToolTip = 'Open a journal based on the journal batch.';

                trigger OnAction()
                begin
                    WhseJnlLine.TemplateSelectionFromBatch(Rec);
                end;
            }
            group("&Registering")
            {
                Caption = '&Registering';
                Image = PostOrder;
                action("Test Report")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Test Report';
                    Ellipsis = true;
                    Image = TestReport;
                    ToolTip = 'View a test report so that you can find and correct any errors before you perform the actual posting of the journal or document.';

                    trigger OnAction()
                    var
                        ReportPrint: Codeunit "Test Report-Print";
                    begin
                        ReportPrint.PrintWhseJnlBatch(Rec);
                    end;
                }
                action("&Register")
                {
                    ApplicationArea = Warehouse;
                    Caption = '&Register';
                    Image = Confirm;
                    RunObject = Codeunit "Whse. Jnl.-B.Register";
                    ShortCutKey = 'F9';
                    ToolTip = 'Register the warehouse entry in question, such as a positive adjustment. ';
                }
                action("Register and &Print")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Register and &Print';
                    Image = ConfirmAndPrint;
                    RunObject = Codeunit "Whse. Jnl.-B.Register+Print";
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Register the warehouse entry adjustments and print an overview of the changes. ';
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Edit Journal_Promoted"; "Edit Journal")
                {
                }
                actionref("&Register_Promoted"; "&Register")
                {
                }
                actionref("Register and &Print_Promoted"; "Register and &Print")
                {
                }
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    begin
        if Rec.Find(Which) then begin
            WhseJnlBatch := Rec;
            while true do begin
                if WMSManagement.LocationIsAllowed(Rec."Location Code") then
                    exit(true);
                if Rec.Next(1) = 0 then begin
                    Rec := WhseJnlBatch;
                    if Rec.Find(Which) then
                        while true do begin
                            if WMSManagement.LocationIsAllowed(Rec."Location Code") then
                                exit(true);
                            if Rec.Next(-1) = 0 then
                                exit(false);
                        end;
                end;
            end;
        end;
        exit(false);
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        RealSteps: Integer;
        NextSteps: Integer;
    begin
        if Steps = 0 then
            exit;

        WhseJnlBatch := Rec;
        repeat
            NextSteps := Rec.Next(Steps / Abs(Steps));
            if WMSManagement.LocationIsAllowed(Rec."Location Code") then begin
                RealSteps := RealSteps + NextSteps;
                WhseJnlBatch := Rec;
            end;
        until (NextSteps = 0) or (RealSteps = Steps);
        Rec := WhseJnlBatch;
        Rec.Find();
        exit(RealSteps);
    end;

    var
        WhseJnlLine: Record "Warehouse Journal Line";
        WhseJnlBatch: Record "Warehouse Journal Batch";
        WMSManagement: Codeunit "WMS Management";

    local procedure DataCaption(): Text[250]
    var
        WhseJnlTemplate: Record "Warehouse Journal Template";
    begin
        if not CurrPage.LookupMode then
            if Rec.GetFilter("Journal Template Name") <> '' then
                if Rec.GetRangeMin("Journal Template Name") = Rec.GetRangeMax("Journal Template Name") then
                    if WhseJnlTemplate.Get(Rec.GetRangeMin("Journal Template Name")) then
                        exit(WhseJnlTemplate.Name + ' ' + WhseJnlTemplate.Description);
    end;
}

