// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension.Correction;

using Microsoft.Finance.GeneralLedger.Ledger;
using System.Security.User;

/// <summary>
/// List part page displaying G/L entries after dimension correction posting. Shows the completed correction results with updated dimension values.
/// </summary>
page 2584 "Dim Correct Posted Ledg Entr"
{
    PageType = ListPart;
    SourceTable = "G/L Entry";
    SourceTableTemporary = true;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                ShowCaption = false;

                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the identifier for the entry. The number series for entries assigned the identifier.';

                    trigger OnDrillDown()
                    var
                        GLEntry: Record "G/L Entry";
                    begin
                        if GLEntry.Get(Rec."Entry No.") then
                            Page.Run(0, Rec);
                    end;
                }

                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("G/L Account No."; Rec."G/L Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("G/L Account Name"; Rec."G/L Account Name")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    Editable = false;
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = Jobs;
                    Editable = false;
                    Visible = false;
                }
                field("Global Dimension 1 Code"; Rec."Global Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    Visible = false;
                }
                field("Global Dimension 2 Code"; Rec."Global Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    Visible = false;
                }
                field("IC Partner Code"; Rec."IC Partner Code")
                {
                    ApplicationArea = Intercompany;
                    Editable = false;
                    Visible = false;
                }
                field("Gen. Posting Type"; Rec."Gen. Posting Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Gen. Bus. Posting Group"; Rec."Gen. Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the vendor''s or customer''s trade type to link transactions made for this business partner with the appropriate ledger account according to the general posting setup.';
                }
                field("Gen. Prod. Posting Group"; Rec."Gen. Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the item''s product type to link transactions made for this item with the appropriate ledger account according to the general posting setup.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Visible = false;
                }
                field("Additional-Currency Amount"; Rec."Additional-Currency Amount")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies the ledger entry that is posted if you post in an additional reporting currency.';
                    Visible = false;
                }
                field("VAT Amount"; Rec."VAT Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Visible = false;
                }
                field("Bal. Account Type"; Rec."Bal. Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Bal. Account No."; Rec."Bal. Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the ledger, customer, vendor, or bank account that the balancing entry is posted to, such as a cash account for cash purchases.';
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation(Rec."User ID");
                    end;
                }
                field("Source Code"; Rec."Source Code")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    Visible = false;
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    Visible = false;
                }
                field(Reversed; Rec.Reversed)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Visible = false;
                }
                field("Reversed by Entry No."; Rec."Reversed by Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Visible = false;
                }
                field("Reversed Entry No."; Rec."Reversed Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Visible = false;
                }
                field("FA Entry Type"; Rec."FA Entry Type")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    Visible = false;
                }
                field("FA Entry No."; Rec."FA Entry No.")
                {
                    ApplicationArea = FixedAssets;
                    Editable = false;
                    Visible = false;
                }

                field("Dimension Set ID"; Rec."Dimension Set ID")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    Visible = false;
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(ShowSelectionCriteria)
            {
                ApplicationArea = All;
                Caption = 'Show Selection Criteria';
                Image = History;
                ToolTip = 'View the filter criteria that was used to select the entries to correct.';

                trigger OnAction()
                var
                    DimCorrectSelectionCriteria: Record "Dim Correct Selection Criteria";
                    DimCorrectSelectionCriteriaPage: Page "Dim Correct Selection Criteria";
                begin
                    DimCorrectSelectionCriteria.SetRange("Dimension Correction Entry No.", DimensionCorrectionEntryNo);
                    DimCorrectSelectionCriteriaPage.SetReadOnly();
                    DimCorrectSelectionCriteriaPage.SetTableView(DimCorrectSelectionCriteria);
                    DimCorrectSelectionCriteriaPage.RunModal();
                end;
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    begin
        if PreviewDisabled then begin
            if Which = '+' then
                LoadRecords(true);

            // If filters have chaned load everythig again
            if PreviousView <> Rec.GetView() then
                RecordsLoaded := false;
        end;

        if not RecordsLoaded then begin
            LoadRecords(false);
            RecordsLoaded := true;
            if Rec.FindFirst() then;
        end;

        if PreviewDisabled then
            PreviousView := Rec.GetView();

        exit(Rec.Find(Which));
    end;

    local procedure LoadRecords(Reversed: Boolean): Boolean
    var
        DimCorrectionEntryLog: Record "Dim Correction Entry Log";
        LastDimCorrectionEntryLog: Record "Dim Correction Entry Log";
        GLEntry: Record "G/L Entry";
        DimensionCorrectionMgt: Codeunit "Dimension Correction Mgt";
        Dimensions: Dictionary of [Text, Text];
        FilterText: Text;
        EntryIncluded: Boolean;
    begin
        if DimensionCorrectionEntryNo = 0 then
            exit;
        Rec.DeleteAll();
        RecordCount := 0;
        GLEntry.FilterGroup(4);
        GLEntry.SetView(Rec.GetView());
        GLEntry.SetCurrentKey("Entry No.");
        GLEntry.Ascending(not Reversed);

        DimCorrectionEntryLog.SetRange("Dimension Correction Entry No.", DimensionCorrectionEntryNo);
        if DimCorrectionEntryLog.Count() < DimensionCorrectionMgt.GetFilterConditionsLimit() then begin
            DimCorrectionEntryLog.FindSet();
            repeat
                if FilterText = '' then
                    FilterText := StrSubstNo(FilterRangeTxt, DimCorrectionEntryLog."Start Entry No.", DimCorrectionEntryLog."End Entry No.")
                else
                    FilterText += '|' + StrSubstNo(FilterRangeTxt, DimCorrectionEntryLog."Start Entry No.", DimCorrectionEntryLog."End Entry No.");
            until DimCorrectionEntryLog.Next() = 0;
        end else begin
            DimCorrectionEntryLog.FindFirst();
            FilterText := Format(DimCorrectionEntryLog."Start Entry No.");
            DimCorrectionEntryLog.FindLast();
            FilterText := StrSubstNo(FilterRangeTxt, FilterText, DimCorrectionEntryLog."End Entry No.");
        end;

        GLEntry.SetFilter("Entry No.", FilterText);
        if not GLEntry.FindSet() then
            exit;

        LastDimCorrectionEntryLog.SetRange("Dimension Correction Entry No.", DimensionCorrectionEntryNo);
        LastDimCorrectionEntryLog.FindFirst();
        DimCorrectionEntryLog.SetRange("Dimension Correction Entry No.", DimensionCorrectionEntryNo);

        repeat
            if DimCorrectionEntryLog.Count() > DimensionCorrectionMgt.GetFilterConditionsLimit() then begin
                EntryIncluded := (GLEntry."Entry No." >= LastDimCorrectionEntryLog."Start Entry No.") and (GLEntry."Entry No." <= LastDimCorrectionEntryLog."End Entry No.");
                if not EntryIncluded then begin
                    DimCorrectionEntryLog.SetFilter("Start Entry No.", '<=%1', GLEntry."Entry No.");
                    DimCorrectionEntryLog.SetFilter("End Entry No.", '>=%1', GLEntry."Entry No.");
                    EntryIncluded := DimCorrectionEntryLog.FindFirst();
                    if EntryIncluded then
                        LastDimCorrectionEntryLog.Copy(DimCorrectionEntryLog);
                end;
            end else
                EntryIncluded := true;

            if EntryIncluded then begin
                Rec.TransferFields(GLEntry, true);
                if not Rec.Insert() then begin
                    Dimensions.Add('Category', DimensionCorrectionTok);
                    Dimensions.Add('DimCorrectionEntryNo', Format(DimensionCorrectionEntryNo));
                    Dimensions.Add('GLEntryNo', Format(GLEntry."Entry No."));
                    Session.LogMessage('0000EHB', DuplicateLedgerEntryFoundLbl, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, Dimensions);
                end;

                RecordCount += 1;
                if RecordCount > DimensionCorrectManagement.GetPreviewGLEntriesLimit() then begin
                    PreviewDisabled := true;
                    exit;
                end;
            end;
        until GLEntry.Next() = 0;
    end;

    /// <summary>
    /// Sets the dimension correction entry number for displaying posted G/L entries with corrected dimensions.
    /// </summary>
    /// <param name="NewDimensionCorrectionEntryNo">The dimension correction entry number to filter posted entries</param>
    procedure SetDimensionCorrectionEntryNo(NewDimensionCorrectionEntryNo: Integer)
    begin
        if NewDimensionCorrectionEntryNo <> DimensionCorrectionEntryNo then begin
            DimensionCorrectionEntryNo := NewDimensionCorrectionEntryNo;
            DeselectAll();
        end;
    end;

    local procedure DeselectAll()
    begin
        Rec.Reset();
        Rec.DeleteALl();
        PreviewDisabled := false;
        Clear(Rec);
        Clear(RecordsLoaded);
        Clear(RecordCount);
        Clear(PreviousView);
    end;

    var
        DimensionCorrectManagement: Codeunit "Dimension Correction Mgt";
        DimensionCorrectionEntryNo: Integer;
        RecordsLoaded: Boolean;
        RecordCount: Integer;
        PreviewDisabled: Boolean;
        PreviousView: Text;
        DuplicateLedgerEntryFoundLbl: Label 'A duplicate ledger entry was found for the dimension correction.', Locked = true;
        DimensionCorrectionTok: Label 'DimensionCorrection';
        FilterRangeTxt: Label '%1..%2', Locked = true;
}
