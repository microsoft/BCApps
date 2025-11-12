// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Foundation.Navigate;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Reports;
using System.Security.User;

page 6520 "Item Tracing"
{
    AdditionalSearchTerms = 'serial number,lot number,expiration,fefo,item tracking,fda,defect';
    ApplicationArea = ItemTracking;
    Caption = 'Item Tracing';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Worksheet;
    AboutTitle = 'About Item Tracing';
    AboutText = 'Trace the complete history and movement of item-tracked inventory by serial, lot, or package number, viewing all related posted transactions from origin to usage or vice versa to support quality control, compliance, and recall management.';
    SourceTable = "Item Tracing Buffer";
    SourceTableTemporary = true;
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(SerialNoFilter; SerialNoFilter)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Serial No. Filter';
                    ToolTip = 'Specifies the serial number or a filter on the serial numbers that you would like to trace.';
                    ExtendedDatatype = Barcode;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        SerialNoInfo: Record "Serial No. Information";
                        SerialNoList: Page "Serial No. Information List";
                    begin
                        SerialNoInfo.Reset();

                        Clear(SerialNoList);
                        SerialNoList.SetTableView(SerialNoInfo);
                        if SerialNoList.RunModal() = ACTION::LookupOK then
                            SerialNoFilter := SerialNoList.GetSelectionFilter();
                    end;
                }
                field(LotNoFilter; LotNoFilter)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Lot No. Filter';
                    ToolTip = 'Specifies the lot number or a filter on the lot numbers that you would like to trace.';
                    ExtendedDatatype = Barcode;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        LotNoInfo: Record "Lot No. Information";
                        LotNoList: Page "Lot No. Information List";
                    begin
                        LotNoInfo.Reset();

                        Clear(LotNoList);
                        LotNoList.SetTableView(LotNoInfo);
                        if LotNoList.RunModal() = ACTION::LookupOK then
                            LotNoFilter := LotNoList.GetSelectionFilter();
                    end;
                }
                field(PackageNoFilter; PackageNoFilter)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Package No. Filter';
                    CaptionClass = '6,3';
                    ToolTip = 'Specifies the package number or a filter on the package numbers that you would like to trace.';
                    ExtendedDatatype = Barcode;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        PackageNoInfo: Record "Package No. Information";
                        PackageNoInfoList: Page "Package No. Information List";
                    begin
                        PackageNoInfo.Reset();

                        Clear(PackageNoInfoList);
                        PackageNoInfoList.SetTableView(PackageNoInfo);
                        if PackageNoInfoList.RunModal() = ACTION::LookupOK then
                            PackageNoFilter := PackageNoInfoList.GetSelectionFilter();
                    end;
                }
                field(ItemNoFilter; ItemNoFilter)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Item Filter';
                    ToolTip = 'Specifies the item number or a filter on the item numbers that you would like to trace.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Item: Record Item;
                        ItemList: Page "Item List";
                    begin
                        Item.Reset();

                        Clear(ItemList);
                        ItemList.SetTableView(Item);
                        ItemList.LookupMode(true);
                        if ItemList.RunModal() = ACTION::LookupOK then
                            ItemNoFilter := ItemList.GetSelectionFilter();
                    end;

                    trigger OnValidate()
                    begin
                        if ItemNoFilter = '' then
                            VariantFilter := '';
                    end;
                }
                field(VariantFilter; VariantFilter)
                {
                    ApplicationArea = Planning;
                    Caption = 'Variant Filter';
                    ToolTip = 'Specifies the variant code or a filter on the variant codes that you would like to trace.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        ItemVariant: Record "Item Variant";
                        ItemVariants: Page "Item Variants";
                    begin
                        if ItemNoFilter = '' then
                            Error(Text001);

                        ItemVariant.Reset();

                        Clear(ItemVariants);
                        ItemVariant.SetFilter("Item No.", ItemNoFilter);
                        ItemVariants.SetTableView(ItemVariant);
                        ItemVariants.LookupMode(true);
                        if ItemVariants.RunModal() = ACTION::LookupOK then begin
                            ItemVariants.GetRecord(ItemVariant);
                            VariantFilter := ItemVariant.Code;
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        if ItemNoFilter = '' then
                            Error(Text001);
                    end;
                }
                field(ShowComponents; ShowComponents)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Show Components';
                    OptionCaption = 'No,Item-tracked Only,All';
                    ToolTip = 'Specifies if you would like to see the components of the item that you are tracing.';
                }
                field(TraceMethod; TraceMethod)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Trace Method';
                    OptionCaption = 'Origin -> Usage,Usage -> Origin';
                    ToolTip = 'Specifies posted serial, lot or package numbers that can be traced either forward or backward in a supply chain.';
                }
            }
            label(Control35)
            {
                ApplicationArea = ItemTracking;
                CaptionClass = Format(TraceText);
                Editable = false;
                ShowCaption = false;
                ToolTip = 'Specifies the text that is used to trace the item.';
            }
            repeater(Control1)
            {
                IndentationColumn = DescriptionIndent;
                IndentationControls = Description;
                ShowAsTree = true;
                ShowCaption = false;
                field(Description; Rec.Description)
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies a description of the traced item.';
                }
                field("Entry Type"; Rec."Entry Type")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the type of the traced entry.';
                    Visible = false;
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    Editable = false;
                    Style = Strong;
                    ToolTip = 'Specifies the serial number to be traced.';
                }
                field("Lot No."; Rec."Lot No.")
                {
                    ApplicationArea = ItemTracking;
                    Editable = false;
                    Style = Strong;
                    ToolTip = 'Specifies the traced lot number.';
                }
                field("Package No."; Rec."Package No.")
                {
                    ApplicationArea = ItemTracking;
                    Editable = false;
                    Style = Strong;
                    ToolTip = 'Specifies the traced package number.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = ItemTracking;
                    Editable = false;
                    Style = Strong;
                    ToolTip = 'Specifies the number of the traced item.';
                }
                field("Item Description"; Rec."Item Description")
                {
                    ApplicationArea = ItemTracking;
                    Editable = false;
                    ToolTip = 'Specifies a description of the item.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the number of the traced document.';
                    Visible = false;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the date when the traced item was posted.';
                    Visible = false;
                }
                field("Source Type"; Rec."Source Type")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the type of record, such as Sales Header, that the item is traced from.';
                    Visible = false;
                }
                field("Source No."; Rec."Source No.")
                {
                    ApplicationArea = ItemTracking;
                    Editable = false;
                    ToolTip = 'Specifies the number of the source document that the entry originates from.';
                    Visible = false;
                }
                field("Source Name"; Rec."Source Name")
                {
                    ApplicationArea = ItemTracking;
                    Editable = false;
                    ToolTip = 'Specifies the name of the record that the item is traced from.';
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = ItemTracking;
                    Editable = false;
                    ToolTip = 'Specifies the location of the traced item.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the quantity of the traced item in the line.';

                    trigger OnDrillDown()
                    var
                        ItemLedgerEntry: Record "Item Ledger Entry";
                    begin
                        ItemLedgerEntry.Reset();
                        ItemLedgerEntry.SetRange("Entry No.", Rec."Item Ledger Entry No.");
                        PAGE.RunModal(0, ItemLedgerEntry);
                    end;
                }
                field("Remaining Quantity"; Rec."Remaining Quantity")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the quantity in the Quantity field that remains to be processed.';
                }
                field("Created by"; Rec."Created by")
                {
                    ApplicationArea = ItemTracking;
                    Lookup = true;
                    ToolTip = 'Specifies the user who created the traced record.';
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation(Rec."Created by");
                    end;
                }
                field("Created on"; Rec."Created on")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the date when the traced record was created.';
                    Visible = false;
                }
                field("Already Traced"; Rec."Already Traced")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies if additional transaction history under this line has already been traced by other lines above it.';
                }
                field("Item Ledger Entry No."; Rec."Item Ledger Entry No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the number of the traced item ledger entry.';
                    Visible = false;
                }
                field("Parent Item Ledger Entry No."; Rec."Parent Item Ledger Entry No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the parent of the traced item ledger entry.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group(Line)
            {
                Caption = '&Line';
                Image = Line;
                action(ShowDocument)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Show Document';
                    Image = View;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Open the document that the selected line exists on.';

                    trigger OnAction()
                    begin
                        ItemTracingMgt.ShowDocument(Rec."Record Identifier");
                    end;
                }
            }
            group(Item)
            {
                Caption = '&Item';
                Image = Item;
                action(Card)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Page "Item Card";
                    RunPageLink = "No." = field("Item No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the record on the document or journal line.';
                }
                action(LedgerEntries)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Ledger E&ntries';
                    Image = CustomerLedger;
                    RunObject = Page "Item Ledger Entries";
                    RunPageLink = "Item No." = field("Item No.");
                    RunPageView = sorting("Item No.");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of transactions that have been posted for the selected record.';
                }
            }
        }
        area(processing)
        {
            group(Functions)
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(TraceOppositeFromLine)
                {
                    ApplicationArea = ItemTracking;
                    Caption = '&Trace Opposite - from Line';
                    Enabled = FunctionsEnable;
                    Image = TraceOppositeLine;
                    ToolTip = 'Repeat the previous trace, but going the opposite direction.';

                    trigger OnAction()
                    begin
                        if TraceMethod = TraceMethod::"Origin->Usage" then
                            TraceMethod := TraceMethod::"Usage->Origin"
                        else
                            TraceMethod := TraceMethod::"Origin->Usage";
                        OppositeTraceFromLine();
                    end;
                }
                action(SetFiltersWithLineValues)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Set &Filters with Line Values';
                    Enabled = FunctionsEnable;
                    Image = FilterLines;
                    ToolTip = 'Insert the values of the selected line in the respective filter fields on the header and executes a new trace. This function is useful, for example, when the origin of the defective item is found and that particular trace line must form the basis of additional tracking with the same trace method.';

                    trigger OnAction()
                    begin
                        ItemTracingMgt.InitSearchParm(Rec, SerialNoFilter, LotNoFilter, PackageNoFilter, ItemNoFilter, VariantFilter);
                    end;
                }
                action("Go to Already-Traced History")
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Go to Already-Traced History';
                    Enabled = FunctionsEnable;
                    Image = MoveUp;
                    ToolTip = 'View the item tracing history.';

                    trigger OnAction()
                    begin
                        SetFocus(Rec."Item Ledger Entry No.");
                    end;
                }
                action(NextTraceResult)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Next Trace Result';
                    Image = NextRecord;
                    ToolTip = 'View the next item transaction in the tracing direction. ';

                    trigger OnAction()
                    begin
                        RecallHistory(1);
                    end;
                }
                action(PreviousTraceResult)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Previous Trace Result';
                    Image = PreviousRecord;
                    ToolTip = 'View the previous item transaction in the tracing direction.';

                    trigger OnAction()
                    begin
                        RecallHistory(-1);
                    end;
                }
            }
            action(Print)
            {
                ApplicationArea = ItemTracking;
                Caption = '&Print';
                Ellipsis = true;
                Enabled = PrintEnable;
                Image = Print;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                var
                    xItemTracingBuffer: Record "Item Tracing Buffer";
                    PrintTracking: Report "Item Tracing Specification";
                begin
                    Clear(PrintTracking);
                    xItemTracingBuffer.Copy(Rec);
                    PrintTracking.TransferEntries(Rec);
                    Rec.Copy(xItemTracingBuffer);
                    PrintTracking.Run();
                end;
            }
            action(Navigate)
            {
                ApplicationArea = ItemTracking;
                Caption = 'Find entries...';
                Enabled = NavigateEnable;
                Image = Navigate;
                ShortCutKey = 'Ctrl+Alt+Q';
                ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';

                trigger OnAction()
                var
                    ItemTrackingSetup: Record "Item Tracking Setup";
                    Navigate: Page Navigate;
                begin
                    ItemTrackingSetup.CopyTrackingFromItemTracingBuffer(Rec);
                    Navigate.SetTracking(ItemTrackingSetup);
                    Navigate.Run();
                end;
            }
            action(Trace)
            {
                ApplicationArea = ItemTracking;
                Caption = '&Trace';
                Image = Trace;
                ToolTip = 'Trace where a serial, lot or package number assigned to the item was used, for example, to find which lot a defective component came from or to find all the customers that have received items containing the defective component.';

                trigger OnAction()
                begin
                    FindRecords();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(Trace_Promoted; Trace)
                {
                }
                actionref(ShowDocument_Promoted; ShowDocument)
                {
                }
                actionref(Navigate_Promoted; Navigate)
                {
                }
                actionref(TraceOppositeFromLine_Promoted; TraceOppositeFromLine)
                {
                }
                actionref(Print_Promoted; Print)
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Line', Comment = 'Generated from the PromotedActionCategories property index 3.';

            }
            group(Category_Category5)
            {
                Caption = 'Item', Comment = 'Generated from the PromotedActionCategories property index 4.';

            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        DescriptionIndent := 0;
        ItemTracingMgt.SetExpansionStatus(Rec, TempTrackEntry, Rec, ActualExpansionStatus);
        DescriptionOnFormat();
    end;

    trigger OnInit()
    begin
        NavigateEnable := true;
        PrintEnable := true;
        FunctionsEnable := true;
    end;

    trigger OnOpenPage()
    begin
        InitButtons();
        if not FiltersInitialized then begin
            TraceMethod := TraceMethod::"Usage->Origin";
            ShowComponents := ShowComponents::"Item-tracked Only";
        end;
    end;

    var
        TempTrackEntry: Record "Item Tracing Buffer" temporary;
        ItemTracingMgt: Codeunit "Item Tracing Mgt.";
        ActualExpansionStatus: Option "Has Children",Expanded,"No Children";
#pragma warning disable AA0074
        Text001: Label 'Item No. Filter is required.';
#pragma warning restore AA0074
        TraceText: Text;
#pragma warning disable AA0470
        TraceTextTxt: Label 'Serial No.: %1, Lot No.: %2, Package No. %3, Item: %4, Variant: %5, Trace Method: %6, Show Components: %7', Comment = '%1 - Serial No.';
#pragma warning restore AA0470
        PreviousExists: Boolean;
        NextExists: Boolean;
#pragma warning disable AA0074
        Text003: Label 'Filters are too large to show.';
        Text004: Label 'Origin->Usage,Usage->Origin';
        Text005: Label 'No,Item-tracked Only,All';
#pragma warning restore AA0074
        DescriptionIndent: Integer;
        FunctionsEnable: Boolean;
        PrintEnable: Boolean;
        NavigateEnable: Boolean;

    protected var
        SerialNoFilter: Text;
        LotNoFilter: Text;
        PackageNoFilter: Text;
        ItemNoFilter: Text;
        VariantFilter: Text;
        TraceMethod: Option "Origin->Usage","Usage->Origin";
        ShowComponents: Option No,"Item-tracked Only",All;
        FiltersInitialized: Boolean;

    procedure FindRecords()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnFindRecordsOnBeforeItemTracingMgtFindRecords(TempTrackEntry, Rec, SerialNoFilter, LotNoFilter, PackageNoFilter, ItemNoFilter, VariantFilter, TraceMethod, ShowComponents, IsHandled);
        if not IsHandled then
            ItemTracingMgt.FindRecords(TempTrackEntry, Rec,
              SerialNoFilter, LotNoFilter, PackageNoFilter, ItemNoFilter, VariantFilter,
              TraceMethod, ShowComponents);
        InitButtons();

        ItemTracingMgt.GetHistoryStatus(PreviousExists, NextExists);

        UpdateTraceText();

        ItemTracingMgt.ExpandAll(TempTrackEntry, Rec);
        OnFindRecordsOnBeforeCurrPageUpdate(Rec);
        CurrPage.Update(false)
    end;

    local procedure OppositeTraceFromLine()
    begin
        ItemTracingMgt.InitSearchParm(Rec, SerialNoFilter, LotNoFilter, PackageNoFilter, ItemNoFilter, VariantFilter);
        FindRecords();
    end;

    procedure InitButtons()
    begin
        if not TempTrackEntry.FindFirst() then begin
            FunctionsEnable := false;
            PrintEnable := false;
            NavigateEnable := false;
        end else begin
            FunctionsEnable := true;
            PrintEnable := true;
            NavigateEnable := true;
        end;

        OnInitButtons(FunctionsEnable, PrintEnable, NavigateEnable);
    end;

    procedure InitFilters(var ItemTrackingEntry: Record "Item Tracing Buffer")
    begin
        SerialNoFilter := ItemTrackingEntry.GetFilter("Serial No.");
        LotNoFilter := ItemTrackingEntry.GetFilter("Lot No.");
        PackageNoFilter := ItemTrackingEntry.GetFilter("Package No.");
        ItemNoFilter := ItemTrackingEntry.GetFilter("Item No.");
        VariantFilter := ItemTrackingEntry.GetFilter("Variant Code");
        TraceMethod := TraceMethod::"Usage->Origin";
        ShowComponents := ShowComponents::"Item-tracked Only";
        FiltersInitialized := true;

        OnAfterInitFilters(ItemTrackingEntry, TraceMethod, ShowComponents);
    end;

    procedure GetItemFilters(var TraceMethod2: Option "Origin->Usage","Usage->Origin"; var ShowComponents2: Option No,"Item-tracked Only",All; var SerialNoFilter2: Text; var LotNoFilter2: Text; var ItemNoFilter2: Text; var VariantFilter2: Text)
    begin
        TraceMethod2 := TraceMethod;
        ShowComponents2 := ShowComponents;
        SerialNoFilter2 := SerialNoFilter;
        LotNoFilter2 := LotNoFilter;
        ItemNoFilter2 := ItemNoFilter;
        VariantFilter2 := VariantFilter;
    end;

    procedure SetItemFilters(TraceMethod2: Option "Origin->Usage","Usage->Origin"; ShowComponents2: Option No,"Item-tracked Only",All; SerialNoFilter2: Text; LotNoFilter2: Text; ItemNoFilter2: Text; VariantFilter2: Text)
    begin
        TraceMethod := TraceMethod2;
        ShowComponents := ShowComponents2;
        SerialNoFilter := SerialNoFilter2;
        LotNoFilter := LotNoFilter2;
        ItemNoFilter := ItemNoFilter2;
        VariantFilter := VariantFilter2;
    end;

    local procedure RecallHistory(Steps: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnRecallHistoryOnBeforeItemTracingMgtRecallHistory(Steps, TempTrackEntry, Rec, SerialNoFilter, LotNoFilter, PackageNoFilter, ItemNoFilter, VariantFilter, TraceMethod, ShowComponents, IsHandled);
        if not IsHandled then
            ItemTracingMgt.RecallHistory(Steps, TempTrackEntry, Rec, SerialNoFilter,
              LotNoFilter, PackageNoFilter, ItemNoFilter, VariantFilter, TraceMethod, ShowComponents);
        UpdateTraceText();
        InitButtons();
        ItemTracingMgt.GetHistoryStatus(PreviousExists, NextExists);

        ItemTracingMgt.ExpandAll(TempTrackEntry, Rec);
        CurrPage.Update(false);
    end;

    local procedure UpdateTraceText()
    var
        LengthOfText: Integer;
        Overflow: Boolean;
    begin
        LengthOfText := (StrLen(TraceTextTxt + SerialNoFilter + LotNoFilter + PackageNoFilter + ItemNoFilter + VariantFilter) +
                         StrLen(Format(TraceMethod)) + StrLen(Format(ShowComponents)) - 6); // 6 = number of positions in TraceTextTxt

        Overflow := LengthOfText > 512;

        if Overflow then
            TraceText := Text003
        else
            TraceText := StrSubstNo(TraceTextTxt, SerialNoFilter, LotNoFilter, PackageNoFilter, ItemNoFilter, VariantFilter,
                SelectStr(TraceMethod + 1, Text004), SelectStr(ShowComponents + 1, Text005));

        OnAfterUpdateTraceText(TraceText, SerialNoFilter, LotNoFilter, ItemNoFilter, VariantFilter, TraceMethod, ShowComponents);
    end;

    local procedure DescriptionOnFormat()
    begin
        DescriptionIndent := Rec.Level;
    end;

    local procedure SetFocus(ItemLedgerEntryNo: Integer)
    begin
        if Rec."Already Traced" then begin
            TempTrackEntry.SetCurrentKey("Item Ledger Entry No.");
            TempTrackEntry.SetRange("Item Ledger Entry No.", ItemLedgerEntryNo);
            TempTrackEntry.FindFirst();
            CurrPage.SetRecord(TempTrackEntry);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFilters(var ItemTracingBuffer: Record "Item Tracing Buffer"; var TraceMethod: Option Forward,Backward; var ShowComponents: Option No,"Item-tracked only",All)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateTraceText(var TraceText: Text; SerialNoFilter: Text; LotNoFilter: Text; ItemNoFilter: Text; VariantFilter: Text; TraceMethod: Option Forward,Backward; ShowComponents: Option No,"Item-tracked only",All)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitButtons(var FunctionsEnable: Boolean; var PrintEnable: Boolean; var NavigateEnable: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnFindRecordsOnBeforeItemTracingMgtFindRecords(var ItemTracingBuffer: Record "Item Tracing Buffer"; var ItemTracingBufferRec: Record "Item Tracing Buffer"; SerialNoFilter: Text; LotNoFilter: Text; PackageNoFilter: Text; ItemNoFilter: Text; VariantFilter: Text; Direction: Option; ShowComponents: Option; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindRecordsOnBeforeCurrPageUpdate(var ItemTracingBuffer: Record "Item Tracing Buffer" temporary)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnRecallHistoryOnBeforeItemTracingMgtRecallHistory(Steps: Integer; var ItemTracingBuffer: Record "Item Tracing Buffer"; var ItemTracingBufferRec: Record "Item Tracing Buffer"; var SerialNoFilter: Text; var LotNoFilter: Text; var PackageNoFilter: Text; var ItemNoFilter: Text; var VariantFilter: Text; var TraceMethod: Option; var ShowComponents: Option; var IsHandled: Boolean)
    begin
    end;
}

