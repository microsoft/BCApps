// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Document;

using Microsoft.Foundation.Attachment;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Item;
using Microsoft.QualityManagement.AccessControl;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Dispositions.InventoryAdjustment;
using Microsoft.QualityManagement.Dispositions.ItemTracking;
using Microsoft.QualityManagement.Dispositions.Move;
using Microsoft.QualityManagement.Dispositions.Purchase;
using Microsoft.QualityManagement.Dispositions.PutAway;
using Microsoft.QualityManagement.Dispositions.Transfer;
using Microsoft.QualityManagement.Utilities;
using Microsoft.Warehouse.Structure;

/// <summary>
/// List of Quality Inspections
/// </summary>
page 20408 "Qlty. Inspection List"
{
    Caption = 'Quality Inspections';
    CardPageId = "Qlty. Inspection";
    DeleteAllowed = false;
    Editable = false;
    PageType = List;
    SourceTable = "Qlty. Inspection Header";
    SourceTableView = sorting("No.", "Re-inspection No.") order(descending);
    UsageCategory = Lists;
    ApplicationArea = QualityManagement;

    layout
    {
        area(Content)
        {
            repeater(GroupInspections)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                }
                field("Re-inspection No."; Rec."Re-inspection No.")
                {
                }
                field("Most Recent Re-inspection"; Rec."Most Recent Re-inspection")
                {
                    Visible = false;
                }
                field("Template Code"; Rec."Template Code")
                {
                }
                field(Description; Rec.Description)
                {
                }
                field(Status; Rec.Status)
                {
                }
                field("Result Code"; Rec."Result Code")
                {
                    Visible = false;
                }
                field("Result Description"; Rec."Result Description")
                {
                }
                field("Finished Date"; Rec."Finished Date")
                {
                }
                field("Finished By User ID"; Rec."Finished By User ID")
                {
                    Visible = false;
                    Editable = false;
                }
                field("Evaluation Sequence"; Rec."Evaluation Sequence")
                {
                    Visible = false;
                }
                field("Source Table No."; Rec."Source Table No.")
                {
                    Visible = false;
                }
                field("Source Document No."; Rec."Source Document No.")
                {
                }
                field("Source Line No."; Rec."Source Document Line No.")
                {
                    Visible = false;
                }
                field("Lot No."; Rec."Source Lot No.")
                {
                }
                field("Serial No."; Rec."Source Serial No.")
                {
                }
                field("Package No."; Rec."Source Package No.")
                {
                }
                field("Item No."; Rec."Source Item No.")
                {
                }
                field("Source Variant Code"; Rec."Source Variant Code")
                {
                }
                field("Location Code"; Rec."Location Code")
                {
                    Visible = false;
                }
                field("Source Quantity (Base)"; Rec."Source Quantity (Base)")
                {
                    Visible = false;
                    AutoFormatType = 0;
                    DecimalPlaces = 0 : 5;
                }
                field("Sample Size"; Rec."Sample Size")
                {
                    Visible = false;
                }
                field("Assigned User ID"; Rec."Assigned User ID")
                {
                }
                field(SystemCreatedAt; Rec.SystemCreatedAt)
                {
                    Caption = 'Created at';
                    ToolTip = 'Specifies the date and time when the inspection was created.';
                }
                field(SystemCreatedByUserID; QltyMiscHelpers.GetUserNameByUserSecurityID(Rec.SystemCreatedBy))
                {
                    Caption = 'Created by User ID';
                    ToolTip = 'Specifies the ID of the user who created the inspection.';
                }
                field(SystemModifiedAt; Rec.SystemModifiedAt)
                {
                    Caption = 'Last modified at';
                    ToolTip = 'Specifies the date and time when the inspection was last modified.';
                }
                field(SystemModifiedByUserID; QltyMiscHelpers.GetUserNameByUserSecurityID(Rec.SystemModifiedBy))
                {
                    Caption = 'Last modified by User ID';
                    ToolTip = 'Specifies the ID of the user who last modified the inspection.';
                }
            }
        }
        area(FactBoxes)
        {
            part("Most Recent Picture"; "Qlty. Most Recent Picture")
            {
                Caption = 'Picture';
                SubPageLink = "No." = field("No."), "Re-inspection No." = field("Re-inspection No.");
            }
            part("Attached Documents"; "Doc. Attachment List Factbox")
            {
                Caption = 'Attachments';
                SubPageLink = "Table ID" = const(Database::"Qlty. Inspection Header"),
                              "No." = field("No."),
                              "Line No." = field("Re-inspection No.");
            }
            part("Template Attached Documents"; "Doc. Attachment List Factbox")
            {
                Caption = 'Template Documents';
                SubPageLink = "Table ID" = const(Database::"Qlty. Inspection Template Hdr."),
                              "No." = field("Template Code");
            }
            systempart(RecordLinks; Links)
            {
                ApplicationArea = RecordLinks;
            }
            systempart(RecordNotes; Notes)
            {
                ApplicationArea = Notes;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CreateInspection)
            {
                Scope = Repeater;
                AccessByPermission = tabledata "Qlty. Inspection Header" = I;
                Caption = 'Create Inspection';
                ToolTip = 'Specifies to create a new Quality Inspection.';
                Image = CreateForm;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;

                trigger OnAction()
                var
                    QltyCreateInspection: Report "Qlty. Create Inspection";
                begin
                    QltyCreateInspection.InitializeReportParameters(Rec."Template Code");
                    QltyCreateInspection.RunModal();
                    CurrPage.Update(false); // after creating an inspection from a blank list this helps make sure the actions stay updated.
                end;
            }
            action("Create Re-inspection")
            {
                AccessByPermission = tabledata "Qlty. Inspection Header" = I;
                Caption = 'Create Re-inspection';
                Image = Reuse;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Create Re-inspection';
                Enabled = CanCreateReinspection;

                trigger OnAction()
                begin
                    Rec.CreateReinspection();
                    CurrPage.Update(false);
                end;
            }
            action(TakePicture)
            {
                Caption = 'Take Picture';
                Enabled = RowActionsAreEnabled;
                Image = Camera;
                ToolTip = 'Activate the camera on the device.';

                trigger OnAction()
                begin
                    Rec.TakeNewMostRecentPicture();
                end;
            }
            action(ChangeStatusFinish)
            {
                AccessByPermission = tabledata "Qlty. Inspection Header" = M;
                Caption = 'Finish';
                Image = ReleaseDoc;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Finish';
                Enabled = CanFinish;

                trigger OnAction()
                var
                    QltyInspectionHeaderToFinish: Record "Qlty. Inspection Header";
                begin
                    CurrPage.SetSelectionFilter(QltyInspectionHeaderToFinish);
                    if QltyInspectionHeaderToFinish.FindSet(true) then
                        repeat
                            QltyInspectionHeaderToFinish.FinishInspection();
                        until QltyInspectionHeaderToFinish.Next() = 0;
                    CurrPage.Update(false);
                end;
            }
            action(ChangeStatusReopen)
            {
                AccessByPermission = tabledata "Qlty. Inspection Header" = M;
                Caption = 'Reopen';
                Image = ReOpen;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Reopen';
                Enabled = CanReopen;

                trigger OnAction()
                var
                    QltyInspectionHeaderToReopen: Record "Qlty. Inspection Header";
                begin
                    CurrPage.SetSelectionFilter(QltyInspectionHeaderToReopen);
                    if QltyInspectionHeaderToReopen.FindSet(true) then
                        repeat
                            QltyInspectionHeaderToReopen.ReopenInspection();
                        until QltyInspectionHeaderToReopen.Next() = 0;
                    CurrPage.Update(false);
                end;
            }
            action(AssignToSelf)
            {
                Scope = Repeater;
                Image = AddContacts;
                Caption = 'Take ownership';
                ToolTip = 'Specifies whether to assign the inspection to yourself.';
                AboutTitle = 'Take ownership';
                AboutText = 'Use this to assign the inspection to yourself.';
                Visible = CanAssignToSelf;
                Enabled = CanAssignToSelf;

                trigger OnAction()
                var
                    QltyInspectionHeaderToAssignToSelf: Record "Qlty. Inspection Header";
                begin
                    CurrPage.SetSelectionFilter(QltyInspectionHeaderToAssignToSelf);
                    if QltyInspectionHeaderToAssignToSelf.FindSet(true) then
                        repeat
                            QltyInspectionHeaderToAssignToSelf.AssignToSelf();
                            QltyInspectionHeaderToAssignToSelf.Modify();
                        until QltyInspectionHeaderToAssignToSelf.Next() = 0;
                    CurrPage.Update(false);
                end;
            }
            action(Unassign)
            {
                Scope = Repeater;
                Image = ExportContact;
                Caption = 'Unassign';
                ToolTip = 'Specifies whether to unassign this inspection.';
                AboutTitle = 'Unassign';
                AboutText = 'Use this to unassign this inspection.';
                Visible = CanUnassign;
                Enabled = CanUnassign;

                trigger OnAction()
                var
                    QltyInspectionHeaderToUnassign: Record "Qlty. Inspection Header";
                begin
                    CurrPage.SetSelectionFilter(QltyInspectionHeaderToUnassign);
                    if QltyInspectionHeaderToUnassign.FindSet(true) then
                        repeat
                            QltyInspectionHeaderToUnassign.Validate("Assigned User ID", '');
                            QltyInspectionHeaderToUnassign.Modify(false);
                        until QltyInspectionHeaderToUnassign.Next() = 0;
                    CurrPage.Update(false);
                end;
            }
            action(MoveToBin)
            {
                Caption = 'Move Inventory';
                Enabled = RowActionsAreEnabled;
                Image = CreateMovement;
                ToolTip = 'Move related inventory to a different Bin. Use this to quarantine into a specific bin.';

                trigger OnAction()
                var
                    QltyInspectionHeader: Record "Qlty. Inspection Header";
                begin
                    QltyInspectionHeader := Rec;
                    QltyInspectionHeader.SetRecFilter();
                    Report.Run(Report::"Qlty. Move Inventory", true, true, QltyInspectionHeader);
                end;
            }
            action(CreateInternalPutAway)
            {
                Caption = 'Create Internal Put-away';
                Enabled = RowActionsAreEnabled;
                Image = CreatePutAway;
                ToolTip = 'Creates an Internal Put-away document.';

                trigger OnAction()
                var
                    QltyInspectionHeader: Record "Qlty. Inspection Header";
                begin
                    QltyInspectionHeader := Rec;
                    QltyInspectionHeader.SetRecFilter();
                    Report.Run(Report::"Qlty. Create Internal Put-away", true, true, QltyInspectionHeader);
                end;
            }
            action(Transfer)
            {
                Caption = 'Create Transfer Order';
                Enabled = RowActionsAreEnabled;
                Image = NewTransferOrder;
                ToolTip = 'Transfer related inventory to a different location.';

                trigger OnAction()
                var
                    QltyInspectionHeader: Record "Qlty. Inspection Header";
                begin
                    QltyInspectionHeader := Rec;
                    QltyInspectionHeader.SetRecFilter();
                    Report.Run(Report::"Qlty. Create Transfer Order", true, true, QltyInspectionHeader);
                end;
            }
            action(CreateNegativeAdjustment)
            {
                Caption = 'Create Negative Adjustment';
                Enabled = RowActionsAreEnabled;
                Image = MoveNegativeLines;
                ToolTip = 'Reduce inventory quantity, for disposal after performing destructive testing or doing a stock write-off for damage or spoilage.';

                trigger OnAction()
                var
                    QltyInspectionHeader: Record "Qlty. Inspection Header";
                begin
                    QltyInspectionHeader := Rec;
                    QltyInspectionHeader.SetRecFilter();
                    Report.Run(Report::"Qlty. Create Negative Adjmt.", true, true, QltyInspectionHeader);
                end;
            }
            action(ChangeItemTracking)
            {
                Caption = 'Change Item Tracking';
                Enabled = RowActionsAreEnabled;
                Image = ItemTrackingLedger;
                ToolTip = 'Change Item Tracking Information.';

                trigger OnAction()
                var
                    QltyInspectionHeader: Record "Qlty. Inspection Header";
                begin
                    QltyInspectionHeader := Rec;
                    QltyInspectionHeader.SetRecFilter();
                    Report.Run(Report::"Qlty. Change Item Tracking", true, true, QltyInspectionHeader);
                end;
            }
            action(CreatePurchaseReturnOrder)
            {
                Caption = 'Create Purchase Return Order';
                Enabled = RowActionsAreEnabled;
                Image = ReturnOrder;
                ToolTip = 'Create a purchase Return Order.';

                trigger OnAction()
                var
                    QltyInspectionHeader: Record "Qlty. Inspection Header";
                begin
                    QltyInspectionHeader := Rec;
                    QltyInspectionHeader.SetRecFilter();
                    Report.Run(Report::"Qlty. Create Purchase Return", true, true, QltyInspectionHeader);
                end;
            }
        }
        area(Reporting)
        {
            action(CertificateOfAnalysis)
            {
                Caption = 'Certificate of Analysis';
                Enabled = RowActionsAreEnabled;
                ToolTip = 'Certificate of Analysis (CoA) for this inspection.';
                Image = Certificate;
                Scope = Repeater;
                Promoted = true;
                PromotedOnly = true;
                PromotedIsBig = true;
                PromotedCategory = Report;

                trigger OnAction()
                var
                    QltyInspectionHeader: Record "Qlty. Inspection Header";
                begin
                    QltyInspectionHeader := Rec;
                    QltyInspectionHeader.SetRecFilter();
                    QltyInspectionHeader.FindFirst();
                    QltyInspectionHeader.PrintCertificateOfAnalysis();
                end;
            }
            action(NonConformanceReport)
            {
                PromotedCategory = Report;
                Caption = 'Non Conformance Report';
                Enabled = RowActionsAreEnabled;
                ToolTip = 'Specifies the Non Conformance Report has a layout suitable for quality inspection templates that typically contain Non Conformance Report questions.';
                Image = PrintReport;
                Promoted = true;
                PromotedIsBig = true;
                PromotedOnly = true;

                trigger OnAction()
                var
                    QltyInspectionHeader: Record "Qlty. Inspection Header";
                begin
                    QltyInspectionHeader := Rec;
                    QltyInspectionHeader.SetRecFilter();
                    QltyInspectionHeader.FindFirst();
                    QltyInspectionHeader.PrintNonConformance();
                end;
            }
            action(GeneralInspectionReport)
            {
                PromotedCategory = Report;
                Caption = 'Inspection Report';
                Enabled = RowActionsAreEnabled;
                ToolTip = 'General purpose inspection report.';
                Image = PrintReport;
                Promoted = true;
                PromotedIsBig = true;
                PromotedOnly = true;

                trigger OnAction()
                var
                    QltyInspectionHeader: Record "Qlty. Inspection Header";
                begin
                    QltyInspectionHeader := Rec;
                    QltyInspectionHeader.SetRecFilter();
                    QltyInspectionHeader.FindFirst();
                    QltyInspectionHeader.PrintGeneralPurposeInspection();
                end;
            }
        }
        area(Navigation)
        {
            action(Attachments)
            {
                Caption = 'Attachments';
                Enabled = RowActionsAreEnabled;
                Image = Attach;
                ToolTip = 'Add a file as an attachment. You can attach images as well as documents.';

                trigger OnAction()
                var
                    DocumentAttachmentDetails: Page "Document Attachment Details";
                    RecRef: RecordRef;
                begin
                    RecRef.GetTable(Rec);
                    DocumentAttachmentDetails.OpenForRecRef(RecRef);
                    DocumentAttachmentDetails.RunModal();
                end;
            }
            action(OpenSourceDocument)
            {
                Caption = 'Open Source Document';
                Enabled = RowActionsAreEnabled;
                Image = ViewSourceDocumentLine;
                ToolTip = 'Opens the related source document.';

                trigger OnAction()
                var
                    QltyDocumentNavigation: Codeunit "Qlty. Document Navigation";
                begin
                    QltyDocumentNavigation.NavigateToSourceDocument(Rec);
                end;
            }
            action(FindEntries)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Enabled = RowActionsAreEnabled;
                Image = Navigate;
                ShortCutKey = 'Ctrl+Alt+Q';
                ToolTip = 'Find entries and documents that exist for the document number.';

                trigger OnAction()
                var
                    QltyDocumentNavigation: Codeunit "Qlty. Document Navigation";
                begin
                    QltyDocumentNavigation.NavigateToFindEntries(Rec);
                end;
            }
            group(ItemAvailabilityBy)
            {
                Caption = 'Item Availability by';
                Enabled = RowActionsAreEnabled;
                Image = ItemAvailability;
                action(tItemAvailabilityByEvent)
                {
                    ApplicationArea = Suite;
                    Caption = 'Event';
                    Enabled = RowActionsAreEnabled;
                    Image = "Event";
                    ToolTip = 'View how the actual and the projected available balance of an item will develop over time according to supply and demand events.';

                    trigger OnAction()
                    var
                        Item: Record Item;
                        AvailItemAvailabilityFormsMgt: Codeunit "Item Availability Forms Mgt";
                    begin
                        Item.Get(Rec."Source Item No.");
                        AvailItemAvailabilityFormsMgt.ShowItemAvailabilityFromItem(Item, "Item Availability Type"::"Event");
                    end;
                }
                action(Period)
                {
                    ApplicationArea = Suite;
                    Caption = 'Period';
                    Enabled = RowActionsAreEnabled;
                    Image = Period;
                    RunObject = Page "Item Availability by Periods";
                    RunPageLink = "No." = field("Source Item No."),
                                      "Location Filter" = field("Location Code"),
                                      "Variant Filter" = field("Source Variant Code");
                    ToolTip = 'Show the projected quantity of the item over time according to time periods, such as day, week, or month.';
                }
                action(Variant)
                {
                    ApplicationArea = Planning;
                    Caption = 'Variant';
                    Enabled = RowActionsAreEnabled;
                    Image = ItemVariant;
                    RunObject = Page "Item Availability by Variant";
                    RunPageLink = "No." = field("Source Item No."),
                                      "Location Filter" = field("Location Code"),
                                      "Variant Filter" = field("Source Variant Code");
                    ToolTip = 'View the current and projected quantity of the item for each variant.';
                }
                action(Location)
                {
                    ApplicationArea = Suite;
                    Caption = 'Location';
                    Enabled = RowActionsAreEnabled;
                    Image = Warehouse;
                    RunObject = Page "Item Availability by Location";
                    RunPageLink = "No." = field("Source Item No."),
                                      "Location Filter" = field("Location Code"),
                                      "Variant Filter" = field("Source Variant Code");
                    ToolTip = 'View the actual and projected quantity of the item per location.';
                }
                action(Lot)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Lot';
                    Enabled = RowActionsAreEnabled;
                    Image = LotInfo;
                    RunObject = Page "Item Availability by Lot No.";
                    RunPageLink = "No." = field("Source Item No.");
                    ToolTip = 'View the current and projected quantity of the item for each lot.';
                }
                action(BinContents)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Bin Contents';
                    Enabled = RowActionsAreEnabled;
                    Image = BinContent;
                    RunObject = Page "Bin Content";
                    RunPageLink = "Item No." = field("Source Item No.");
                    RunPageView = sorting("Item No.");
                    ToolTip = 'View the quantities of the item in each bin where it exists. You can see all the important parameters relating to bin content, and you can modify certain bin content parameters in this window.';
                }
            }
        }
    }

    views
    {
        view(viewOpen)
        {
            Caption = 'Open (all)';
            Filters = where(Status = const(Open));
            OrderBy = descending("No.", "Re-inspection No.");
        }
        view(viewOpenAndDue)
        {
            Caption = 'Open and Due (all)';
            Filters = where(Status = const(Open),
                            "Planned Start Date" = filter('<=%NOW'));
            OrderBy = descending("No.", "Re-inspection No.");
        }
        view(viewFinished)
        {
            Caption = 'Finished';
            Filters = where(Status = const(Finished));
            OrderBy = descending("No.", "Re-inspection No.");
        }
        view(viewMyOpen)
        {
            Caption = 'Open (mine)';
            Filters = where(Status = const(Open),
                            "Assigned User ID" = filter('%me'));
            OrderBy = descending("No.", "Re-inspection No.");
        }
        view(viewMyOpenAndDue)
        {
            Caption = 'Open and Due (mine)';
            Filters = where(Status = const(Open),
                            "Assigned User ID" = filter('%me'),
                            "Planned Start Date" = filter('<=%NOW'));
            OrderBy = descending("No.", "Re-inspection No.");
        }
        view(viewMyFinished)
        {
            Caption = 'Finished (mine)';
            Filters = where(Status = const(Finished),
                            "Assigned User ID" = filter('%me'));
            OrderBy = descending("No.", "Re-inspection No.");
        }
        view(viewAssignedtoMe)
        {
            Caption = 'Assigned To Me';
            Filters = where("Assigned User ID" = filter('%me'));
            OrderBy = descending("No.", "Re-inspection No.");
        }
        view(viewUnassigned)
        {
            Caption = 'Unassigned';
            Filters = where("Assigned User ID" = filter(''''''));
            OrderBy = descending("No.", "Re-inspection No.");
        }
    }

    var
        QltyPermissionMgmt: Codeunit "Qlty. Permission Mgmt.";
        QltyMiscHelpers: Codeunit "Qlty. Misc Helpers";
        CanAssignToSelf: Boolean;
        CanCreateReinspection: Boolean;
        CanUnassign: Boolean;
        CanFinish: Boolean;
        CanReopen: Boolean;
        RowActionsAreEnabled: Boolean;

    trigger OnOpenPage()
    begin
        RowActionsAreEnabled := not IsNullGuid(Rec.SystemId);
        CanReopen := RowActionsAreEnabled and not Rec.HasMoreRecentReinspection();
        CanFinish := RowActionsAreEnabled and (Rec.Status <> Rec.Status::Finished);
        CanCreateReinspection := RowActionsAreEnabled;
    end;

    trigger OnAfterGetCurrRecord()
    begin
        CanAssignToSelf := false;
        CanUnassign := false;
        RowActionsAreEnabled := not IsNullGuid(Rec.SystemId);
        CanReopen := RowActionsAreEnabled and not Rec.HasMoreRecentReinspection();
        CanFinish := RowActionsAreEnabled and (Rec.Status <> Rec.Status::Finished);

        if (Rec."Assigned User ID" = '') or ((Rec."Assigned User ID" <> UserId()) and QltyPermissionMgmt.CanChangeOtherInspections()) then
            CanAssignToSelf := RowActionsAreEnabled;

        if (Rec."Assigned User ID" = UserId()) or (((Rec."Assigned User ID" <> '') and QltyPermissionMgmt.CanChangeOtherInspections()))
         then
            CanUnassign := RowActionsAreEnabled;
    end;

    procedure RunModalSourceDocumentFilterWithRecord(RecordVariant: Variant) ResultAction: Action
    begin
        ResultAction := RunModalFilterWith(RecordVariant, false, false, true);
    end;

    procedure RunModalSourceItemFilterWithRecord(RecordVariant: Variant) ResultAction: Action
    begin
        ResultAction := RunModalFilterWith(RecordVariant, true, false, false);
    end;

    procedure RunModalSourceItemAndSourceDocumentFilterWithRecord(RecordVariant: Variant) ResultAction: Action
    begin
        ResultAction := RunModalFilterWith(RecordVariant, true, false, true);
    end;

    procedure RunModalSourceItemTrackingFilterWithRecord(RecordVariant: Variant) ResultAction: Action
    begin
        ResultAction := RunModalFilterWith(RecordVariant, true, true, false);
    end;

    local procedure RunModalFilterWith(RecordVariant: Variant; UseItem: Boolean; UseTracking: Boolean; UseDocument: Boolean) ResultAction: Action
    begin
        Rec.SetRecordFiltersToFindInspectionFor(true, RecordVariant, UseItem, UseTracking, UseDocument);
        ResultAction := CurrPage.RunModal();
    end;
}
