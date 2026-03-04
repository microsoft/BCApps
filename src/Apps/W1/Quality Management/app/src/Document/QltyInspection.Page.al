// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Document;

using Microsoft.Foundation.Attachment;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Tracking;
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
using System.Device;

/// <summary>
/// Quality Inspection document.
/// </summary>
page 20406 "Qlty. Inspection"
{
    UsageCategory = None;
    Caption = 'Quality Inspection';
    DataCaptionExpression = GetDataCaptionExpression();
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Qlty. Inspection Header";
    RefreshOnActivate = true;
    ApplicationArea = QualityManagement;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                Editable = IsOpen;

                field("No."; Rec."No.")
                {
                    Editable = false;
                }
                field("Re-inspection No."; Rec."Re-inspection No.")
                {
                    Editable = false;
                }
                field("Most Recent Re-inspection"; Rec."Most Recent Re-inspection")
                {
                    Editable = false;
                    Importance = Additional;
                }
                field("Template Code"; Rec."Template Code")
                {
                }
                field(Description; Rec.Description)
                {
                }
                field("Location Code"; Rec."Location Code")
                {
                    Importance = Additional;
                }
                group(PassAndFailQty)
                {
                    ShowCaption = false;

                    group(SourceQuantityNonAQL)
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
                    field("Sample Size"; Rec."Sample Size")
                    {
                        Editable = CanChangeQuantity;
                        Importance = Additional;
                    }
                }
                group(GradingAndStatus)
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
                    field("Result Code"; Rec."Result Code")
                    {
                        Importance = Additional;
                    }
                    field("Result Description"; Rec."Result Description")
                    {
                    }
                    field("Evaluation Sequence"; Rec."Evaluation Sequence")
                    {
                        Importance = Additional;
                        Visible = false;
                    }
                }
                group(ItemTracking)
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
                    field("Source Lot No."; Rec."Source Lot No.")
                    {
                        Editable = CanChangeLotTracking;

                        trigger OnAssistEdit()
                        begin
                            Rec.AssistEditLotNo();
                        end;
                    }
                    field("Source Serial No."; Rec."Source Serial No.")
                    {
                        Editable = CanChangeSerialTracking;

                        trigger OnAssistEdit()
                        begin
                            Rec.AssistEditSerialNo();
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
                group(Statistics)
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
                        ToolTip = 'Specifies the date and time when the inspection was created.';
                    }
                    field(SystemCreatedByUserID; QltyMiscHelpers.GetUserNameByUserSecurityID(Rec.SystemCreatedBy))
                    {
                        Editable = false;
                        Importance = Additional;
                        Caption = 'Created by User ID';
                        ToolTip = 'Specifies the ID of the user who created the inspection.';
                    }
                    field(SystemModifiedAt; Rec.SystemModifiedAt)
                    {
                        Editable = false;
                        Importance = Additional;
                        Caption = 'Last modified at';
                        ToolTip = 'Specifies the date and time when the teinspectionst was last modified.';
                    }
                    field(SystemModifiedByUserID; QltyMiscHelpers.GetUserNameByUserSecurityID(Rec.SystemModifiedBy))
                    {
                        Editable = false;
                        Importance = Additional;
                        Caption = 'Last modified by User ID';
                        ToolTip = 'Specifies the ID of the user who last modified the inspection.';
                    }
                }
                field("Existing Quality Inspections This Record"; Rec."Existing Inspections This Rec.")
                {
                    Importance = Additional;
                }
                field("Existing Quality Inspections This Item"; Rec."Existing Inspections This Item")
                {
                    Importance = Additional;
                }
            }
            part(Lines; "Qlty. Inspection Subform")
            {
                Editable = IsOpen;
                Caption = 'Lines';
                SubPageLink = "Inspection No." = field("No."),
                              "Re-inspection No." = field("Re-inspection No.");
            }
            group(ControlInfo)
            {
                Caption = 'Control Information';
                field("Source Table No."; Rec."Source Table No.")
                {
                    Editable = false;
                    Importance = Additional;
                }
                field("Table Name"; Rec."Source Table Name")
                {
                    Editable = false;
                    Importance = Additional;
                }
                field("Source RecordId"; Format(Rec."Source RecordId"))
                {
                    Caption = 'Source Record';
                    Visible = false;
                    Editable = false;
                    ToolTip = 'Specifies the source record this Quality Inspection is for.';
                }
                field("Trigger RecordId"; Format(Rec."Trigger RecordId"))
                {
                    Caption = 'Trigger Record';
                    Visible = false;
                    Editable = false;
                    ToolTip = 'Specifies the triggering record that caused this Quality Inspection to be created.';
                    Importance = Additional;
                }
                group(SourceTypeVisibility)
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
                group(SourceSubTypeVisibility)
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
                group(SourceDocNoVisibility)
                {
                    ShowCaption = false;
                    Visible = VisibleDocumentNo;

                    field("Source Document No."; Rec."Source Document No.")
                    {
                        Editable = false;
                        CaptionClass = '3,' + Rec.GetControlCaptionClass('Source Document No.');
                    }
                }
                group(SourceDocLineNoVisibility)
                {
                    ShowCaption = false;
                    Visible = VisibleDocumentLineNo;

                    field("Source Document Line No."; Rec."Source Document Line No.")
                    {
                        Editable = false;
                        CaptionClass = '3,' + Rec.GetControlCaptionClass('Source Document Line No.');
                    }
                }
                group(SourceTaskNoVisibility)
                {
                    ShowCaption = false;
                    Visible = VisibleSourceTaskNo;

                    field("Source Task No."; Rec."Source Task No.")
                    {
                        Editable = false;
                        CaptionClass = '3,' + Rec.GetControlCaptionClass('Source Task No.');
                    }
                }
                group(SourceCustom1Visibility)
                {
                    ShowCaption = false;
                    Visible = VisibleCustom1;

                    field("Source Custom 1"; Rec."Source Custom 1")
                    {
                        Editable = false;
                        CaptionClass = '3,' + Rec.GetControlCaptionClass('Source Custom 1');
                    }
                }
                group(SourceCustom2Visibility)
                {
                    ShowCaption = false;
                    Visible = VisibleCustom2;

                    field("Source Custom 2"; Rec."Source Custom 2")
                    {
                        Editable = false;
                        CaptionClass = '3,' + Rec.GetControlCaptionClass('Source Custom 2');
                    }
                }
                group(SourceCustom3Visibility)
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
                group(SourceCustom4Visibility)
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
                group(SourceCustom5Visibility)
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
                group(SourceCustom6Visibility)
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
                group(SourceCustom7Visibility)
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
                group(SourceCustom8Visibility)
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
                group(SourceCustom9Visibility)
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
                group(SourceCustom10Visibility)
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

                trigger OnAction()
                begin
                    Rec.CreateReinspection();
                    CurrPage.Update(false);
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
                begin
                    Rec.FinishInspection();
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
                begin
                    Rec.ReopenInspection();
                    CurrPage.Update(false);
                end;
            }
            action(TakePicture)
            {
                Caption = 'Take Picture';
                Image = Camera;
                ToolTip = 'Activate the camera on the device.';
                Visible = CameraAvailable;

                trigger OnAction()
                begin
                    Rec.TakeNewMostRecentPicture();
                end;
            }
            action(MoveToBin)
            {
                Caption = 'Move Inventory';
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
                Image = ReturnOrder;
                ToolTip = 'Create a Purchase Return Order.';

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
                PromotedCategory = Report;
                Caption = 'Certificate of Analysis';
                ToolTip = 'Certificate of Analysis (CoA) for this inspection.';
                Image = Certificate;
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
                    QltyInspectionHeader.PrintCertificateOfAnalysis();
                end;
            }
            action(NonConformanceReport)
            {
                PromotedCategory = Report;
                Caption = 'Non Conformance Report';
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
                    QltyDocumentNavigation: Codeunit "Qlty. Document Navigation";
                begin
                    QltyDocumentNavigation.NavigateToSourceDocument(Rec);
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
                    QltyDocumentNavigation: Codeunit "Qlty. Document Navigation";
                begin
                    QltyDocumentNavigation.NavigateToFindEntries(Rec);
                end;
            }
            group(ItemAvailabilityBy)
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
                Image = TransferOrder;
                ApplicationArea = All;
                ToolTip = 'Show all related transfer documents for this inspection.';

                trigger OnAction()
                begin
                    Rec.RunModalRelatedTransfers();
                end;
            }
        }
    }

    var
        QltyPermissionMgmt: Codeunit "Qlty. Permission Mgmt.";
        QltyMiscHelpers: Codeunit "Qlty. Misc Helpers";
        Camera: Codeunit Camera;
        CameraAvailable: Boolean;
        IsOpen: Boolean;
        CanReopen: Boolean;
        CanFinish: Boolean;
        CanChangeLotTracking, CanChangeSerialTracking, CanChangePackageTracking : Boolean;
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

    trigger OnOpenPage()
    begin
        CameraAvailable := Camera.IsAvailable();
    end;

    trigger OnAfterGetRecord()
    begin
        UpdateControlVisibilityStates(true);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        UpdateControlVisibilityStates(true);
    end;

    local procedure UpdateControlVisibilityStates(UpdateCurrPageNoModify: Boolean)
    var
        TempItemTrackingSetup: Record "Item Tracking Setup" temporary;
    begin
        IsOpen := Rec.Status = Rec.Status::Open;
        CanReopen := not Rec.HasMoreRecentReinspection();
        CanFinish := Rec.Status <> Rec.Status::Finished;
        if Rec.Status = Rec.Status::Open then
            if QltyPermissionMgmt.CanChangeItemTracking() then begin
                TempItemTrackingSetup."Lot No. Required" := true;
                TempItemTrackingSetup."Serial No. Required" := true;
                TempItemTrackingSetup."Package No. Required" := true;
                Rec.IsItemTrackingUsed(TempItemTrackingSetup);
                CanChangeLotTracking := TempItemTrackingSetup."Lot No. Required";
                CanChangeSerialTracking := TempItemTrackingSetup."Serial No. Required";
                CanChangePackageTracking := TempItemTrackingSetup."Package No. Required";
            end;
        CanChangeQuantity := QltyPermissionMgmt.CanChangeSourceQuantity();

        Rec.CalcFields("Source Table Name");
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
                exit(Rec."No." + ' - ' + Rec."Template Code" + ' - ' + Rec."Source Item No." + ' - ' + Rec."Source Document No." + ' - ' + Format(Rec."Result Description") + ' - ' + Format(Rec.Status))
            else
                exit(Rec."No." + ' - ' + Rec."Template Code" + ' - ' + Rec."Source Table Name" + ' - ' + Rec."Source Document No." + ' - ' + Format(Rec."Result Description") + ' - ' + Format(Rec.Status));
        end else begin
            DataCaptionExpression := QltyExpressionMgmt.EvaluateTextExpression(DataCaptionExpression, Rec);
            exit(DataCaptionExpression);
        end;
    end;
}
