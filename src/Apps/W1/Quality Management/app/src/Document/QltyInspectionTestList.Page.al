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
/// List of Quality Inspection Tests
/// </summary>
page 20408 "Qlty. Inspection Test List"
{
    Caption = 'Quality Inspection Tests';
    CardPageID = "Qlty. Inspection Test";
    DeleteAllowed = false;
    Editable = false;
    PageType = List;
    SourceTable = "Qlty. Inspection Test Header";
    SourceTableView = sorting("No.", "Retest No.") order(descending);
    AdditionalSearchTerms = 'Test Results,Certificates,Quality Tests,Inspection tests,inspection results';
    UsageCategory = Lists;
    ApplicationArea = QualityManagement;

    layout
    {
        area(Content)
        {
            repeater(GroupTests)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                }
                field("Retest No."; Rec."Retest No.")
                {
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
                field("Grade Code"; Rec."Grade Code")
                {
                    Visible = false;
                }
                field("Grade Description"; Rec."Grade Description")
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
                field("Grade Priority"; Rec."Grade Priority")
                {
                    Visible = false;
                }
                field("Source Table No."; Rec."Source Table No.")
                {
                    Visible = false;
                }
                field("Source Document No."; Rec."Source Document No.")
                {
                    Visible = false;
                }
                field("Source Line No."; Rec."Source Document Line No.")
                {
                    Visible = false;
                }
                field("Serial No."; Rec."Source Serial No.")
                {
                }
                field("Lot No."; Rec."Source Lot No.")
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
                    ToolTip = 'Specifies the date and time when the test was created.';
                }
                field(SystemCreatedByUserID; QltyMiscHelpers.GetUserNameByUserSecurityID(Rec.SystemCreatedBy))
                {
                    Caption = 'Created by User ID';
                    ToolTip = 'Specifies the ID of the user who created the test.';
                }
                field(SystemModifiedAt; Rec.SystemModifiedAt)
                {
                    Caption = 'Last modified at';
                    ToolTip = 'Specifies the date and time when the test was last modified.';
                }
                field(SystemModifiedByUserID; QltyMiscHelpers.GetUserNameByUserSecurityID(Rec.SystemModifiedBy))
                {
                    Caption = 'Last modified by User ID';
                    ToolTip = 'Specifies the ID of the user who last modified the test.';
                }
            }
        }
        area(FactBoxes)
        {
            part("Most Recent Picture"; "Qlty. Most Recent Picture")
            {
                Caption = 'Picture';
                SubPageLink = "No." = field("No."), "Retest No." = field("Retest No.");
            }
            part("Attached Documents"; "Doc. Attachment List Factbox")
            {
                Caption = 'Attachments';
                SubPageLink = "Table ID" = const(Database::"Qlty. Inspection Test Header"),
                              "No." = field("No."),
                              "Line No." = field("Retest No.");
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
            action(CreateTest)
            {
                Scope = Repeater;
                Caption = 'Create Test';
                ToolTip = 'Specifies to create a new Quality Inspection Test.';
                Image = CreateForm;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Enabled = CanCreateTest;

                trigger OnAction()
                var
                    QltyCreateInspectionTest: Report "Qlty. Create Inspection Test";
                begin
                    QltyCreateInspectionTest.InitializeReportParameters(Rec."Template Code");
                    QltyCreateInspectionTest.RunModal();
                end;
            }
            action(CreateRetest)
            {
                Caption = 'Create Retest';
                Image = Reuse;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Create Retest';
                Enabled = CanCreateRetest;

                trigger OnAction()
                begin
                    Rec.CreateReTest();
                    CurrPage.Update(false);
                end;
            }
            action(TakePicture)
            {
                Caption = 'Take Picture';
                Image = Camera;
                ToolTip = 'Activate the camera on the device.';

                trigger OnAction()
                begin
                    Rec.TakeNewPicture();
                end;
            }
            action(ChangeStatusFinish)
            {
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
                    TestsToFinishQualityOrder: Record "Qlty. Inspection Test Header";
                begin
                    CurrPage.SetSelectionFilter(TestsToFinishQualityOrder);
                    if TestsToFinishQualityOrder.FindSet(true) then
                        repeat
                            TestsToFinishQualityOrder.FinishTest();
                        until TestsToFinishQualityOrder.Next() = 0;
                    CurrPage.Update(false);
                end;
            }
            action(ChangeStatusReopen)
            {
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
                    TestsToReopenQualityOrder: Record "Qlty. Inspection Test Header";
                begin
                    CurrPage.SetSelectionFilter(TestsToReopenQualityOrder);
                    if TestsToReopenQualityOrder.FindSet(true) then
                        repeat
                            TestsToReopenQualityOrder.ReopenTest();
                        until TestsToReopenQualityOrder.Next() = 0;
                    CurrPage.Update(false);
                end;
            }
            action(AssignToSelf)
            {
                Scope = Repeater;
                Image = CreateInventoryPick;
                Caption = 'Pick Up';
                ToolTip = 'Specifies whether to assign the test to yourself.';
                AboutTitle = 'Pick Up';
                AboutText = 'Use this to assign the test to yourself.';
                Visible = CanAssignToSelf;
                Enabled = CanAssignToSelf;

                trigger OnAction()
                var
                    TestsToPickUpQualityOrder: Record "Qlty. Inspection Test Header";
                begin
                    CurrPage.SetSelectionFilter(TestsToPickUpQualityOrder);
                    if TestsToPickUpQualityOrder.FindSet(true) then
                        repeat
                            TestsToPickUpQualityOrder.AssignToSelf();
                            TestsToPickUpQualityOrder.Modify();
                        until TestsToPickUpQualityOrder.Next() = 0;
                    CurrPage.Update(false);
                end;
            }
            action(Unassign)
            {
                Scope = Repeater;
                Image = CreatePutAway;
                Caption = 'Unassign';
                ToolTip = 'Specifies whether to unassign this test.';
                AboutTitle = 'Unassign';
                AboutText = 'Use this to unassign this test.';
                Visible = CanUnassign;
                Enabled = CanUnassign;

                trigger OnAction()
                var
                    TestsToUnassignQualityOrder: Record "Qlty. Inspection Test Header";
                begin
                    CurrPage.SetSelectionFilter(TestsToUnassignQualityOrder);
                    if TestsToUnassignQualityOrder.FindSet(true) then
                        repeat
                            TestsToUnassignQualityOrder.Validate("Assigned User ID", '');
                            TestsToUnassignQualityOrder.Modify(false);
                        until TestsToUnassignQualityOrder.Next() = 0;
                    CurrPage.Update(false);
                end;
            }
            action(MoveToBin)
            {
                Caption = 'Move Inventory';
                Image = CreateMovement;
                ToolTip = 'Move related inventory to a different Bin. Use this to quarantine into a specific bin.';

                trigger OnAction()
                var
                    QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
                begin
                    QltyInspectionTestHeader := Rec;
                    QltyInspectionTestHeader.SetRecFilter();
                    Report.Run(Report::"Qlty. Move Inventory", true, true, QltyInspectionTestHeader);
                end;
            }
            action(CreateInternalPutAway)
            {
                Caption = 'Create Internal Put-away';
                Image = CreatePutAway;
                ToolTip = 'Creates an Internal Put-away document.';

                trigger OnAction()
                var
                    QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
                begin
                    QltyInspectionTestHeader := Rec;
                    QltyInspectionTestHeader.SetRecFilter();
                    Report.Run(Report::"Qlty. Create Internal Put-away", true, true, QltyInspectionTestHeader);
                end;
            }
            action(Transfer)
            {
                Caption = 'Create Transfer Order';
                Image = NewShipment;
                ToolTip = 'Transfer related inventory to a different location.';

                trigger OnAction()
                var
                    QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
                begin
                    QltyInspectionTestHeader := Rec;
                    QltyInspectionTestHeader.SetRecFilter();
                    Report.Run(Report::"Qlty. Create Transfer Order", true, true, QltyInspectionTestHeader);
                end;
            }
            action(CreateNegativeAdjustment)
            {
                Caption = 'Create Negative Adjustment';
                Image = CalculateWarehouseAdjustment;
                ToolTip = 'Reduce inventory quantity, for disposal after performing destructive testing or doing a stock write-off for damage or spoilage.';

                trigger OnAction()
                var
                    QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
                begin
                    QltyInspectionTestHeader := Rec;
                    QltyInspectionTestHeader.SetRecFilter();
                    Report.Run(Report::"Qlty. Create Negative Adjmt.", true, true, QltyInspectionTestHeader);
                end;
            }
            action(ChangeItemTracking)
            {
                Caption = 'Change Item Tracking';
                Image = CalculateWarehouseAdjustment;
                ToolTip = 'Change Item Tracking Information.';

                trigger OnAction()
                var
                    QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
                begin
                    QltyInspectionTestHeader := Rec;
                    QltyInspectionTestHeader.SetRecFilter();
                    Report.Run(Report::"Qlty. Change Item Tracking", true, true, QltyInspectionTestHeader);
                end;
            }
            action(CreatePurchaseReturnOrder)
            {
                Caption = 'Create Purchase Return Order';
                Image = PurchaseCreditMemo;
                ToolTip = 'Create a purchase Return Order.';

                trigger OnAction()
                var
                    QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
                begin
                    QltyInspectionTestHeader := Rec;
                    QltyInspectionTestHeader.SetRecFilter();
                    Report.Run(Report::"Qlty. Create Purchase Return", true, true, QltyInspectionTestHeader);
                end;
            }
        }
        area(Reporting)
        {
            action(CertificateOfAnalysis)
            {
                Caption = 'Certificate of Analysis';
                ToolTip = 'Certificate of Analysis (CoA) for this test.';
                Image = Certificate;
                Scope = Repeater;
                Promoted = true;
                PromotedOnly = true;
                PromotedIsBig = true;
                PromotedCategory = Report;

                trigger OnAction()
                var
                    QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
                begin
                    QltyInspectionTestHeader := Rec;
                    QltyInspectionTestHeader.SetRecFilter();
                    QltyInspectionTestHeader.FindFirst();
                    QltyInspectionTestHeader.PrintCertificateOfAnalysis();
                end;
            }
            action(NonConformanceReport)
            {
                PromotedCategory = Report;
                Caption = 'Non Conformance Report';
                ToolTip = 'Specifies the Non Conformance Report has a layout suitable for quality inspection templates that typically contain Non Conformance Report questions.';
                Image = Certificate;
                Promoted = true;
                PromotedIsBig = true;
                PromotedOnly = true;

                trigger OnAction()
                var
                    QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
                begin
                    QltyInspectionTestHeader := Rec;
                    QltyInspectionTestHeader.SetRecFilter();
                    QltyInspectionTestHeader.FindFirst();
                    QltyInspectionTestHeader.PrintNonConformance();
                end;
            }
            action(GeneralInspectionReport)
            {
                PromotedCategory = Report;
                Caption = 'Inspection Report';
                ToolTip = 'General purpose inspection report.';
                Image = Certificate;
                Promoted = true;
                PromotedIsBig = true;
                PromotedOnly = true;

                trigger OnAction()
                var
                    QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
                begin
                    QltyInspectionTestHeader := Rec;
                    QltyInspectionTestHeader.SetRecFilter();
                    QltyInspectionTestHeader.FindFirst();
                    QltyInspectionTestHeader.PrintGeneralPurposeInspection();
                end;
            }
        }
        area(Navigation)
        {
            action(Attachments)
            {
                Caption = 'Attachments';
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
                Image = ViewSourceDocumentLine;
                ToolTip = 'Opens the related source document.';

                trigger OnAction()
                var
                    QltyMiscHelpers: Codeunit "Qlty. Misc Helpers";
                begin
                    QltyMiscHelpers.NavigateToSourceDocument(Rec);
                end;
            }
            action(FindEntries)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Image = Navigate;
                ShortCutKey = 'Ctrl+Alt+Q';
                ToolTip = 'Find entries and documents that exist for the document number.';

                trigger OnAction()
                var
                    QltyMiscHelpers: Codeunit "Qlty. Misc Helpers";
                begin
                    QltyMiscHelpers.NavigateToFindEntries(Rec);
                end;
            }
            group(SettingsForItemAvailabilityBy)
            {
                Caption = 'Item Availability by';
                Image = ItemAvailability;
                action(tItemAvailabilityByEvent)
                {
                    ApplicationArea = Suite;
                    Caption = 'Event';
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
                    Image = LotInfo;
                    RunObject = Page "Item Availability by Lot No.";
                    RunPageLink = "No." = field("Source Item No.");
                    ToolTip = 'View the current and projected quantity of the item for each lot.';
                }
                action(BinContents)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Bin Contents';
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
            OrderBy = descending("No.", "Retest No.");
        }
        view(viewOpenAndDue)
        {
            Caption = 'Open and Due (all)';
            Filters = where(Status = const(Open),
                            "Planned Start Date" = filter('<=T'));
            OrderBy = descending("No.", "Retest No.");
        }
        view(viewFinished)
        {
            Caption = 'Finished';
            Filters = where(Status = const(Finished));
            OrderBy = descending("No.", "Retest No.");
        }
        view(viewMyOpen)
        {
            Caption = 'Open (mine)';
            Filters = where(Status = const(Open),
                            "Assigned User ID" = filter('%me'));
            OrderBy = descending("No.", "Retest No.");
        }
        view(viewMyOpenAndDue)
        {
            Caption = 'Open and Due (mine)';
            Filters = where(Status = const(Open),
                            "Assigned User ID" = filter('%me'),
                            "Planned Start Date" = filter('<=T'));
            OrderBy = descending("No.", "Retest No.");
        }
        view(viewMyFinished)
        {
            Caption = 'Finished (mine)';
            Filters = where(Status = const(Finished),
                            "Assigned User ID" = filter('%me'));
            OrderBy = descending("No.", "Retest No.");
        }
        view(viewAssignedtoMe)
        {
            Caption = 'Assigned To Me';
            Filters = where("Assigned User ID" = filter('%me'));
            OrderBy = descending("No.", "Retest No.");
        }
        view(viewUnassigned)
        {
            Caption = 'Unassigned';
            Filters = where("Assigned User ID" = filter(''''''));
            OrderBy = descending("No.", "Retest No.");
        }
    }

    var
        QltyPermissionMgmt: Codeunit "Qlty. Permission Mgmt.";
        QltyMiscHelpers: Codeunit "Qlty. Misc Helpers";
        CanCreateTest: Boolean;
        CanAssignToSelf: Boolean;
        CanCreateRetest: Boolean;
        CanUnassign: Boolean;
        CanFinish: Boolean;
        CanReopen: Boolean;

    trigger OnOpenPage()
    begin
        CanCreateTest := QltyPermissionMgmt.CanCreateManualTest();
        CanReopen := QltyPermissionMgmt.CanReopenTest() and not Rec.HasMoreRecentRetest();
        CanFinish := QltyPermissionMgmt.CanFinishTest() and not (Rec.Status = Rec.Status::Finished);

        CanCreateRetest := QltyPermissionMgmt.CanCreateReTest();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        CanAssignToSelf := false;
        CanUnassign := false;
        CanReopen := QltyPermissionMgmt.CanReopenTest() and not Rec.HasMoreRecentRetest();
        CanFinish := QltyPermissionMgmt.CanFinishTest() and not (Rec.Status = Rec.Status::Finished);

        if (Rec."Assigned User ID" = '') or ((Rec."Assigned User ID" <> UserId()) and QltyPermissionMgmt.CanChangeOthersTests()) then
            CanAssignToSelf := true;

        if (Rec."Assigned User ID" = UserId()) or (((Rec."Assigned User ID" <> '') and QltyPermissionMgmt.CanChangeOthersTests()))
         then
            CanUnassign := true;
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
        Rec.SetRecordFiltersToFindTestFor(true, RecordVariant, UseItem, UseTracking, UseDocument);
        ResultAction := CurrPage.RunModal();
    end;
}
