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
/// Primary location to enter Quality Inspection Test information.
/// </summary>
page 20406 "Qlty. Inspection Test"
{
    UsageCategory = None;
    Caption = 'Quality Inspection Test';
    DataCaptionExpression = GetDataCaptionExpression();
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Qlty. Inspection Test Header";
    RefreshOnActivate = true;
    ApplicationArea = QualityManagement;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("No."; Rec."No.")
                {
                    Editable = false;
                }
                field("Retest No."; Rec."Retest No.")
                {
                    Editable = false;
                }
                field("Template Code"; Rec."Template Code")
                {
                    Editable = false;
                }
                field(Description; Rec.Description)
                {
                }
                field("Location Code"; Rec."Location Code")
                {
                    Importance = Additional;
                }
                group(SettingsForPassAndFailQty)
                {
                    ShowCaption = false;

                    group(SettingsForSourceQuantityNonAQL)
                    {
                        Caption = 'Quantity';

                        field(NonSamplingSourceQuantityBase; Rec."Source Quantity (Base)")
                        {
                            Editable = CanChangeQuantity;
                        }
                    }
                    field(ChoosePassedSampleQuantity; Rec."Pass Quantity")
                    {
                        Caption = 'Passed Quantity';
                        Editable = CanChangeQuantity;
                    }
                    field(ChooseFailedSampleQuantity; Rec."Fail Quantity")
                    {
                        Caption = 'Failed Quantity';
                        Editable = CanChangeQuantity;
                    }
                }
                group(SettingsForGradingAndStatus)
                {
                    Caption = 'Status';

                    field(Status; Rec.Status)
                    {
                        Editable = false;
                    }
                    field("Finished Date"; Rec."Finished Date")
                    {
                        Editable = false;
                    }
                    field("Finished By User ID"; Rec."Finished By User ID")
                    {
                        Visible = false;
                        Editable = false;
                    }
                    field("Grade Code"; Rec."Grade Code")
                    {
                        Importance = Additional;
                    }
                    field("Grade Description"; Rec."Grade Description")
                    {
                    }
                    field("Grade Priority"; Rec."Grade Priority")
                    {
                        Importance = Additional;
                    }
                }
                group(SettingsForItemTracking)
                {
                    Caption = 'Item Tracking';

                    field("Item No."; Rec."Source Item No.")
                    {
                        Editable = false;
                    }
                    field("Source Variant Code"; Rec."Source Variant Code")
                    {
                        Editable = false;
                    }
                    field("Serial No."; Rec."Source Serial No.")
                    {
                        Editable = CanChangeSerialTracking;

                        trigger OnAssistEdit()
                        begin
                            Rec.AssistEditSerialNo();
                        end;
                    }
                    field("Lot No."; Rec."Source Lot No.")
                    {
                        Editable = CanChangeLotTracking;

                        trigger OnAssistEdit()
                        begin
                            Rec.AssistEditLotNo();
                        end;
                    }
                    field("Source Package No."; Rec."Source Package No.")
                    {
                        Editable = CanChangePackageTracking;

                        trigger OnAssistEdit()
                        begin
                            Rec.AssistEditPackageNo();
                        end;
                    }
                }
                group(SettingsForStatistics)
                {
                    Caption = 'Statistics';

                    field("Assigned User ID"; Rec."Assigned User ID")
                    {
                        Editable = true;
                    }
                    field("Planned Start Date"; Rec."Planned Start Date")
                    {
                        Editable = false;
                        Importance = Additional;
                    }
                    field(SystemCreatedAt; Rec.SystemCreatedAt)
                    {
                        Editable = false;
                        Importance = Additional;
                        Caption = 'Created at';
                        ToolTip = 'Specifies the date and time when the test was created.';
                    }
                    field(SystemCreatedByUserID; QltyMiscHelpers.GetUserNameByUserSecurityID(Rec.SystemCreatedBy))
                    {
                        Editable = false;
                        Importance = Additional;
                        Caption = 'Created by User ID';
                        ToolTip = 'Specifies the ID of the user who created the test.';
                    }
                    field(SystemModifiedAt; Rec.SystemModifiedAt)
                    {
                        Editable = false;
                        Importance = Additional;
                        Caption = 'Last modified at';
                        ToolTip = 'Specifies the date and time when the test was last modified.';
                    }
                    field(SystemModifiedByUserID; QltyMiscHelpers.GetUserNameByUserSecurityID(Rec.SystemModifiedBy))
                    {
                        Editable = false;
                        Importance = Additional;
                        Caption = 'Last modified by User ID';
                        ToolTip = 'Specifies the ID of the user who last modified the test.';
                    }
                }
                field("Existing Quality Tests This Record"; Rec."Existing Tests This Record")
                {
                    Importance = Additional;
                }
                field("Existing Quality Tests This Item"; Rec."Existing Tests This Item")
                {
                    Importance = Additional;
                }
            }
            part(Lines; "Qlty. Inspection Test Subform")
            {
                Caption = 'Lines';
                SubPageLink = "Test No." = field("No."),
                              "Retest No." = field("Retest No.");
            }
            group(ControlInfo)
            {
                Caption = 'Control Information';

                field("Source Table No."; Rec."Source Table No.")
                {
                    Editable = false;
                    Importance = Additional;
                }
                field("Table Name"; Rec."Table Name")
                {
                    Editable = false;
                    Importance = Additional;
                }
                field("Source RecordId"; Format(Rec."Source RecordId"))
                {
                    Caption = 'Source Record';
                    Visible = false;
                    Editable = false;
                    ToolTip = 'Specifies the source record this Quality Inspection Test is for.';
                }
                field("Trigger RecordId"; Format(Rec."Trigger RecordId"))
                {
                    Caption = 'Trigger Record';
                    Visible = false;
                    Editable = false;
                    ToolTip = 'Specifies the triggering record that caused this Quality Inspection Test to be created.';
                    Importance = Additional;
                }
                group(SettingsForSourceTypeVisibility)
                {
                    ShowCaption = false;
                    Visible = VisibleSourceType;

                    field("Source Type"; Rec."Source Type")
                    {
                        Editable = false;
                        Importance = Additional;
                        CaptionClass = '3,' + Rec.GetControlCaptionClass('Source Type');
                    }
                }
                group(SettingsForSourceSubTypeVisibility)
                {
                    ShowCaption = false;
                    Visible = VisibleSourceSubType;

                    field("Source Sub Type"; Rec."Source Sub Type")
                    {
                        Editable = false;
                        Importance = Additional;
                        CaptionClass = '3,' + Rec.GetControlCaptionClass('Source Sub Type');
                    }
                }
                group(SettingsForSourceDocNoVisibility)
                {
                    ShowCaption = false;
                    Visible = VisibleDocumentNo;

                    field("Source Document No."; Rec."Source Document No.")
                    {
                        Editable = false;
                        CaptionClass = '3,' + Rec.GetControlCaptionClass('Source Document No.');
                    }
                }
                group(SettingsForSourceDocLineNoVisibility)
                {
                    ShowCaption = false;
                    Visible = VisibleDocumentLineNo;

                    field("Source Document Line No."; Rec."Source Document Line No.")
                    {
                        Editable = false;
                        CaptionClass = '3,' + Rec.GetControlCaptionClass('Source Document Line No.');
                    }
                }
                group(SettingsForSourceTaskNoVisibility)
                {
                    ShowCaption = false;
                    Visible = VisibleSourceTaskNo;

                    field("Source Task No."; Rec."Source Task No.")
                    {
                        Editable = false;
                        CaptionClass = '3,' + Rec.GetControlCaptionClass('Source Task No.');
                    }
                }
                group(SettingsForSourceCustom1Visibility)
                {
                    ShowCaption = false;
                    Visible = VisibleCustom1;

                    field("Source Custom 1"; Rec."Source Custom 1")
                    {
                        Editable = false;
                        CaptionClass = '3,' + Rec.GetControlCaptionClass('Source Custom 1');
                    }
                }
                group(SettingsForSourceCustom2Visibility)
                {
                    ShowCaption = false;
                    Visible = VisibleCustom2;

                    field("Source Custom 2"; Rec."Source Custom 2")
                    {
                        Editable = false;
                        CaptionClass = '3,' + Rec.GetControlCaptionClass('Source Custom 2');
                    }
                }
                group(SettingsForSourceCustom3Visibility)
                {
                    ShowCaption = false;
                    Visible = VisibleCustom3;

                    field("Source Custom 3"; Rec."Source Custom 3")
                    {
                        Editable = false;
                        CaptionClass = '3,' + Rec.GetControlCaptionClass('Source Custom 3');
                        Importance = Additional;
                    }
                }
                group(SettingsForSourceCustom4Visibility)
                {
                    ShowCaption = false;
                    Visible = VisibleCustom4;

                    field("Source Custom 4"; Rec."Source Custom 4")
                    {
                        Editable = false;
                        CaptionClass = '3,' + Rec.GetControlCaptionClass('Source Custom 4');
                        Importance = Additional;
                    }
                }
                group(SettingsForSourceCustom5Visibility)
                {
                    ShowCaption = false;
                    Visible = VisibleCustom5;

                    field("Source Custom 5"; Rec."Source Custom 5")
                    {
                        Editable = false;
                        CaptionClass = '3,' + Rec.GetControlCaptionClass('Source Custom 5');
                        Importance = Additional;
                    }
                }
                group(SettingsForSourceCustom6Visibility)
                {
                    ShowCaption = false;
                    Visible = VisibleCustom6;

                    field("Source Custom 6"; Rec."Source Custom 6")
                    {
                        Editable = false;
                        CaptionClass = '3,' + Rec.GetControlCaptionClass('Source Custom 6');
                        Importance = Additional;
                    }
                }
                group(SettingsForSourceCustom7Visibility)
                {
                    ShowCaption = false;
                    Visible = VisibleCustom7;

                    field("Source Custom 7"; Rec."Source Custom 7")
                    {
                        Editable = false;
                        CaptionClass = '3,' + Rec.GetControlCaptionClass('Source Custom 7');
                        Importance = Additional;
                    }
                }
                group(SettingsForSourceCustom8Visibility)
                {
                    ShowCaption = false;
                    Visible = VisibleCustom8;

                    field("Source Custom 8"; Rec."Source Custom 8")
                    {
                        Editable = false;
                        CaptionClass = '3,' + Rec.GetControlCaptionClass('Source Custom 8');
                        Importance = Additional;
                    }
                }
                group(SettingsForSourceCustom9Visibility)
                {
                    ShowCaption = false;
                    Visible = VisibleCustom9;

                    field("Source Custom 9"; Rec."Source Custom 9")
                    {
                        Editable = false;
                        CaptionClass = '3,' + Rec.GetControlCaptionClass('Source Custom 9');
                        Importance = Additional;
                    }
                }
                group(SettingsForSourceCustom10Visibility)
                {
                    ShowCaption = false;
                    Visible = VisibleCustom10;

                    field("Source Custom 10"; Rec."Source Custom 10")
                    {
                        Editable = false;
                        CaptionClass = '3,' + Rec.GetControlCaptionClass('Source Custom 10');
                        Importance = Additional;
                    }
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
                begin
                    Rec.FinishTest();
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
                begin
                    Rec.ReopenTest();
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
                ToolTip = 'Create a Purchase Return Order.';

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
                PromotedCategory = Report;
                Caption = 'Certificate of Analysis';
                ToolTip = 'Certificate of Analysis (CoA) for this test.';
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
            action(tShowTransfers)
            {
                Caption = 'Show Related Transfer Documents';
                Image = View;
                ApplicationArea = All;
                ToolTip = 'Show all related transfer documents for this test.';

                trigger OnAction()
                begin
                    Rec.RunModalRelatedTransfers();
                end;
            }
        }
    }

    protected var
        QltyPermissionMgmt: Codeunit "Qlty. Permission Mgmt.";
        QltyMiscHelpers: Codeunit "Qlty. Misc Helpers";
        CanReopen: Boolean;
        CanFinish: Boolean;
        CanCreateRetest: Boolean;
        CanChangeLotTracking: Boolean;
        CanChangeSerialTracking: Boolean;
        CanChangePackageTracking: Boolean;
        VisibleCustom10: Boolean;
        VisibleCustom9: Boolean;
        VisibleCustom8: Boolean;
        VisibleCustom7: Boolean;
        VisibleCustom6: Boolean;
        VisibleCustom5: Boolean;
        VisibleCustom4: Boolean;
        VisibleCustom3: Boolean;
        VisibleCustom2: Boolean;
        VisibleCustom1: Boolean;
        VisibleDocumentNo: Boolean;
        VisibleDocumentLineNo: Boolean;
        VisibleSourceTaskNo: Boolean;
        VisibleSourceSubType: Boolean;
        VisibleSourceType: Boolean;
        CanChangeQuantity: Boolean;

    trigger OnAfterGetRecord()
    begin
        UpdateControlVisibilityStates(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        UpdateControlVisibilityStates(true);
    end;

    local procedure UpdateControlVisibilityStates(UpdateCurrPageNoModify: Boolean)
    begin
        CanReopen := QltyPermissionMgmt.CanReopenTest() and not Rec.HasMoreRecentRetest();
        CanFinish := QltyPermissionMgmt.CanFinishTest() and not (Rec.Status = Rec.Status::Finished);
        CanCreateRetest := QltyPermissionMgmt.CanCreateRetest();
        CanChangeLotTracking := Rec.IsLotTracked() and (Rec.Status = Rec.Status::Open) and QltyPermissionMgmt.CanChangeTrackingNo();
        CanChangeSerialTracking := Rec.IsSerialTracked() and (Rec.Status = Rec.Status::Open) and QltyPermissionMgmt.CanChangeTrackingNo();
        CanChangePackageTracking := Rec.IsPackageTracked() and (Rec.Status = Rec.Status::Open) and QltyPermissionMgmt.CanChangeTrackingNo();
        CanChangeQuantity := QltyPermissionMgmt.CanChangeSourceQuantity();

        Rec.CalcFields("Table Name");
        Rec.DetermineControlInformation(Rec.FieldName("Source Custom 1"));
        Rec.DetermineControlInformation(Rec.FieldName("Source Custom 2"));
        Rec.DetermineControlInformation(Rec.FieldName("Source Custom 3"));
        Rec.DetermineControlInformation(Rec.FieldName("Source Custom 4"));
        Rec.DetermineControlInformation(Rec.FieldName("Source Custom 5"));
        Rec.DetermineControlInformation(Rec.FieldName("Source Custom 6"));
        Rec.DetermineControlInformation(Rec.FieldName("Source Custom 7"));
        Rec.DetermineControlInformation(Rec.FieldName("Source Custom 8"));
        Rec.DetermineControlInformation(Rec.FieldName("Source Custom 9"));
        Rec.DetermineControlInformation(Rec.FieldName("Source Custom 10"));
        Rec.DetermineControlInformation(Rec.FieldName("Source Task No."));
        Rec.DetermineControlInformation(Rec.FieldName("Source Document Line No."));
        Rec.DetermineControlInformation(Rec.FieldName("Source Document No."));
        Rec.DetermineControlInformation(Rec.FieldName("Source Type"));
        Rec.DetermineControlInformation(Rec.FieldName("Source Sub Type"));
        VisibleCustom1 := Rec.GetControlVisibleState(Rec.FieldName("Source Custom 1"));
        VisibleCustom2 := Rec.GetControlVisibleState(Rec.FieldName("Source Custom 2"));
        VisibleCustom3 := Rec.GetControlVisibleState(Rec.FieldName("Source Custom 3"));
        VisibleCustom4 := Rec.GetControlVisibleState(Rec.FieldName("Source Custom 4"));
        VisibleCustom5 := Rec.GetControlVisibleState(Rec.FieldName("Source Custom 5"));
        VisibleCustom6 := Rec.GetControlVisibleState(Rec.FieldName("Source Custom 6"));
        VisibleCustom7 := Rec.GetControlVisibleState(Rec.FieldName("Source Custom 7"));
        VisibleCustom8 := Rec.GetControlVisibleState(Rec.FieldName("Source Custom 8"));
        VisibleCustom9 := Rec.GetControlVisibleState(Rec.FieldName("Source Custom 9"));
        VisibleCustom10 := Rec.GetControlVisibleState(Rec.FieldName("Source Custom 10"));
        VisibleDocumentNo := Rec.GetControlVisibleState(Rec.FieldName("Source Document No."));
        VisibleDocumentLineNo := Rec.GetControlVisibleState(Rec.FieldName("Source Document Line No."));
        VisibleSourceTaskNo := Rec.GetControlVisibleState(Rec.FieldName("Source Task No."));
        VisibleSourceSubType := Rec.GetControlVisibleState(Rec.FieldName("Source Sub Type"));
        VisibleSourceType := Rec.GetControlVisibleState(Rec.FieldName("Source Type"));

        if UpdateCurrPageNoModify then
            CurrPage.Update(false);
    end;

    local procedure GetDataCaptionExpression(): Text
    var
        QltyExpressionMgmt: Codeunit "Qlty. Expression Mgmt.";
        DataCaptionExpression: Text;
    begin
        if DataCaptionExpression = '' then begin
            if Rec."Source Item No." <> '' then
                exit(Rec."No." + ' - ' + Rec."Template Code" + ' - ' + Rec."Source Item No." + ' - ' + Rec."Source Document No." + ' - ' + Format(Rec."Grade Description") + ' - ' + Format(Rec.Status))
            else
                exit(Rec."No." + ' - ' + Rec."Template Code" + ' - ' + Rec."Table Name" + ' - ' + Rec."Source Document No." + ' - ' + Format(Rec."Grade Description") + ' - ' + Format(Rec.Status));
        end else begin
            DataCaptionExpression := QltyExpressionMgmt.EvaluateTextExpression(DataCaptionExpression, Rec);
            exit(DataCaptionExpression);
        end;
    end;
}
