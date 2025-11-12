// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Analysis;

using Microsoft.Foundation.Enums;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Service.Document;
using Microsoft.Service.Item;
using Microsoft.Service.Setup;
using System.Utilities;

page 9229 "Res. Avail. (Service) Matrix"
{
    Caption = 'Res. Availability (Service) Matrix';
    DataCaptionExpression = '';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = List;
    SourceTable = Resource;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(Name; Rec.Name)
                {
                    ApplicationArea = Service;
                    Caption = 'Selected Resource';
                    Editable = false;
                    ToolTip = 'Specifies a description of the resource.';
                }
                field(Skills; QualifiedForServItems)
                {
                    ApplicationArea = Service;
                    Caption = 'Resource Skilled For';
                    OptionCaption = 'Selected Service Item,All Service Items in Order';
                    ToolTip = 'Specifies whether the resource skills should be shown for all service items in the service order, or for the selected service item only.';

                    trigger OnValidate()
                    begin
                        QualifiedForServItemsOnAfterVa();
                    end;
                }
                field(SelectedDay; SelectedDate)
                {
                    ApplicationArea = Service;
                    Caption = 'Selected Day';
                    Enabled = SelectedDayEnable;
                    ToolTip = 'Specifies the date you select for the resource group availability.';
                }
                field(Qtytoallocate; QtytoAllocate)
                {
                    ApplicationArea = Service;
                    Caption = 'Qty. To Allocate';
                    Enabled = QtytoallocateEnable;
                    MinValue = 0;
                    ToolTip = 'Specifies the amount of hours that should be allocated to the selected resource.';
                }
            }
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;
                field("Preferred Resource"; PreferredResource)
                {
                    ApplicationArea = Service;
                    Caption = 'Preferred Resource';
                    ToolTip = 'Specifies the number of the resource that the customer prefers for servicing of the service item.';
                }
                field(Skilled; Qualified)
                {
                    ApplicationArea = Service;
                    Caption = 'Skilled';
                    ToolTip = 'Specifies that the resource is sufficiently skilled, to carry out the service on the service item that you are allocating or all the service items in the service order.';
                    Visible = SkilledVisible;
                }
                field("In Customer Zone"; Rec."In Customer Zone")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that the resource (for example, a technician) is assigned to the same service zone as a specified customer.';
                    Visible = InCustomerZoneVisible;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Name2; Rec.Name)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a description of the resource.';
                }
                field(Field1; MATRIX_CellData[1])
                {
                    ApplicationArea = Service;
                    CaptionClass = '3,' + MatrixColumnCaptions[1];
                    DecimalPlaces = 0 : 5;
                    Visible = Field1Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(1);
                    end;
                }
                field(Field2; MATRIX_CellData[2])
                {
                    ApplicationArea = Service;
                    CaptionClass = '3,' + MatrixColumnCaptions[2];
                    DecimalPlaces = 0 : 5;
                    Visible = Field2Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(2);
                    end;
                }
                field(Field3; MATRIX_CellData[3])
                {
                    ApplicationArea = Service;
                    CaptionClass = '3,' + MatrixColumnCaptions[3];
                    DecimalPlaces = 0 : 5;
                    Visible = Field3Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(3);
                    end;
                }
                field(Field4; MATRIX_CellData[4])
                {
                    ApplicationArea = Service;
                    CaptionClass = '3,' + MatrixColumnCaptions[4];
                    DecimalPlaces = 0 : 5;
                    Visible = Field4Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(4);
                    end;
                }
                field(Field5; MATRIX_CellData[5])
                {
                    ApplicationArea = Service;
                    CaptionClass = '3,' + MatrixColumnCaptions[5];
                    DecimalPlaces = 0 : 5;
                    Visible = Field5Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(5);
                    end;
                }
                field(Field6; MATRIX_CellData[6])
                {
                    ApplicationArea = Service;
                    CaptionClass = '3,' + MatrixColumnCaptions[6];
                    DecimalPlaces = 0 : 5;
                    Visible = Field6Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(6);
                    end;
                }
                field(Field7; MATRIX_CellData[7])
                {
                    ApplicationArea = Service;
                    CaptionClass = '3,' + MatrixColumnCaptions[7];
                    DecimalPlaces = 0 : 5;
                    Visible = Field7Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(7);
                    end;
                }
                field(Field8; MATRIX_CellData[8])
                {
                    ApplicationArea = Service;
                    CaptionClass = '3,' + MatrixColumnCaptions[8];
                    DecimalPlaces = 0 : 5;
                    Visible = Field8Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(8);
                    end;
                }
                field(Field9; MATRIX_CellData[9])
                {
                    ApplicationArea = Service;
                    CaptionClass = '3,' + MatrixColumnCaptions[9];
                    DecimalPlaces = 0 : 5;
                    Visible = Field9Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(9);
                    end;
                }
                field(Field10; MATRIX_CellData[10])
                {
                    ApplicationArea = Service;
                    CaptionClass = '3,' + MatrixColumnCaptions[10];
                    DecimalPlaces = 0 : 5;
                    Visible = Field10Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(10);
                    end;
                }
                field(Field11; MATRIX_CellData[11])
                {
                    ApplicationArea = Service;
                    CaptionClass = '3,' + MatrixColumnCaptions[11];
                    DecimalPlaces = 0 : 5;
                    Visible = Field11Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(11);
                    end;
                }
                field(Field12; MATRIX_CellData[12])
                {
                    ApplicationArea = Service;
                    CaptionClass = '3,' + MatrixColumnCaptions[12];
                    DecimalPlaces = 0 : 5;
                    Visible = Field12Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(12);
                    end;
                }
                field(Field13; MATRIX_CellData[13])
                {
                    ApplicationArea = Service;
                    CaptionClass = '3,' + MatrixColumnCaptions[13];
                    DecimalPlaces = 0 : 5;
                    Visible = Field13Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(13);
                    end;
                }
                field(Field14; MATRIX_CellData[14])
                {
                    ApplicationArea = Service;
                    CaptionClass = '3,' + MatrixColumnCaptions[14];
                    DecimalPlaces = 0 : 5;
                    Visible = Field14Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(14);
                    end;
                }
                field(Field15; MATRIX_CellData[15])
                {
                    ApplicationArea = Service;
                    CaptionClass = '3,' + MatrixColumnCaptions[15];
                    DecimalPlaces = 0 : 5;
                    Visible = Field15Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(15);
                    end;
                }
                field(Field16; MATRIX_CellData[16])
                {
                    ApplicationArea = Service;
                    CaptionClass = '3,' + MatrixColumnCaptions[16];
                    DecimalPlaces = 0 : 5;
                    Visible = Field16Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(16);
                    end;
                }
                field(Field17; MATRIX_CellData[17])
                {
                    ApplicationArea = Service;
                    CaptionClass = '3,' + MatrixColumnCaptions[17];
                    DecimalPlaces = 0 : 5;
                    Visible = Field17Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(17);
                    end;
                }
                field(Field18; MATRIX_CellData[18])
                {
                    ApplicationArea = Service;
                    CaptionClass = '3,' + MatrixColumnCaptions[18];
                    DecimalPlaces = 0 : 5;
                    Visible = Field18Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(18);
                    end;
                }
                field(Field19; MATRIX_CellData[19])
                {
                    ApplicationArea = Service;
                    CaptionClass = '3,' + MatrixColumnCaptions[19];
                    DecimalPlaces = 0 : 5;
                    Visible = Field19Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(19);
                    end;
                }
                field(Field20; MATRIX_CellData[20])
                {
                    ApplicationArea = Service;
                    CaptionClass = '3,' + MatrixColumnCaptions[20];
                    DecimalPlaces = 0 : 5;
                    Visible = Field20Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(20);
                    end;
                }
                field(Field21; MATRIX_CellData[21])
                {
                    ApplicationArea = Service;
                    CaptionClass = '3,' + MatrixColumnCaptions[21];
                    DecimalPlaces = 0 : 5;
                    Visible = Field21Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(21);
                    end;
                }
                field(Field22; MATRIX_CellData[22])
                {
                    ApplicationArea = Service;
                    CaptionClass = '3,' + MatrixColumnCaptions[22];
                    DecimalPlaces = 0 : 5;
                    Visible = Field22Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(22);
                    end;
                }
                field(Field23; MATRIX_CellData[23])
                {
                    ApplicationArea = Service;
                    CaptionClass = '3,' + MatrixColumnCaptions[23];
                    DecimalPlaces = 0 : 5;
                    Visible = Field23Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(23);
                    end;
                }
                field(Field24; MATRIX_CellData[24])
                {
                    ApplicationArea = Service;
                    CaptionClass = '3,' + MatrixColumnCaptions[24];
                    DecimalPlaces = 0 : 5;
                    Visible = Field24Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(24);
                    end;
                }
                field(Field25; MATRIX_CellData[25])
                {
                    ApplicationArea = Service;
                    CaptionClass = '3,' + MatrixColumnCaptions[25];
                    DecimalPlaces = 0 : 5;
                    Visible = Field25Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(25);
                    end;
                }
                field(Field26; MATRIX_CellData[26])
                {
                    ApplicationArea = Service;
                    CaptionClass = '3,' + MatrixColumnCaptions[26];
                    DecimalPlaces = 0 : 5;
                    Visible = Field26Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(26);
                    end;
                }
                field(Field27; MATRIX_CellData[27])
                {
                    ApplicationArea = Service;
                    CaptionClass = '3,' + MatrixColumnCaptions[27];
                    DecimalPlaces = 0 : 5;
                    Visible = Field27Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(27);
                    end;
                }
                field(Field28; MATRIX_CellData[28])
                {
                    ApplicationArea = Service;
                    CaptionClass = '3,' + MatrixColumnCaptions[28];
                    DecimalPlaces = 0 : 5;
                    Visible = Field28Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(28);
                    end;
                }
                field(Field29; MATRIX_CellData[29])
                {
                    ApplicationArea = Service;
                    CaptionClass = '3,' + MatrixColumnCaptions[29];
                    DecimalPlaces = 0 : 5;
                    Visible = Field29Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(29);
                    end;
                }
                field(Field30; MATRIX_CellData[30])
                {
                    ApplicationArea = Service;
                    CaptionClass = '3,' + MatrixColumnCaptions[30];
                    DecimalPlaces = 0 : 5;
                    Visible = Field30Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(30);
                    end;
                }
                field(Field31; MATRIX_CellData[31])
                {
                    ApplicationArea = Service;
                    CaptionClass = '3,' + MatrixColumnCaptions[31];
                    DecimalPlaces = 0 : 5;
                    Visible = Field31Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(31);
                    end;
                }
                field(Field32; MATRIX_CellData[32])
                {
                    ApplicationArea = Service;
                    CaptionClass = '3,' + MatrixColumnCaptions[32];
                    DecimalPlaces = 0 : 5;
                    Visible = Field32Visible;

                    trigger OnDrillDown()
                    begin
                        MatrixOnDrillDown(32);
                    end;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Resource")
            {
                Caption = '&Resource';
                Image = Resource;
                action(Card)
                {
                    ApplicationArea = Service;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Page "Resource Card";
                    RunPageLink = "No." = field("No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the record on the document or journal line.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("&Allocate")
                {
                    ApplicationArea = Service;
                    Caption = '&Allocate';
                    Image = Allocate;
                    ToolTip = 'Specifies the resources available to be allocated.';

                    trigger OnAction()
                    begin
                        if PeriodType <> PeriodType::Day then
                            Error(Text000, PeriodType);

                        Clear(ServOrderAllocMgt);
                        ServOrderAllocMgt.AllocateDate(
                          CurrentDocumentType, CurrentDocumentNo, CurrentEntryNo, Rec."No.", '', SelectedDate, QtytoAllocate);
                        CurrPage.Close();
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        QualifiedForAll: Boolean;
    begin
        MatrixOnAfterGetRecord();
        if QualifiedForServItems = QualifiedForServItems::"Selected Service Item" then begin
            if ServItemLine.Get(CurrentDocumentType, CurrentDocumentNo, CurrentServItemLineNo) then
                Qualified := ServOrderAllocMgt.QualifiedForServiceItemLine(ServItemLine, Rec."No.")
            else
                Qualified := false;
        end else begin
            QualifiedForAll := true;
            ServItemLine.SetRange("Document Type", ServHeader."Document Type");
            ServItemLine.SetRange("Document No.", ServHeader."No.");
            if ServItemLine.Find('-') then
                repeat
                    QualifiedForAll := ServOrderAllocMgt.QualifiedForServiceItemLine(ServItemLine, Rec."No.")
                until (QualifiedForAll = false) or (ServItemLine.Next() = 0);
            if QualifiedForAll then
                Qualified := true
            else
                Qualified := false;
        end;

        if ServHeader.Get(CurrentDocumentType, CurrentDocumentNo) then
            Rec."Service Zone Filter" := ServHeader."Service Zone Code"
        else
            Rec."Service Zone Filter" := '';
        PreferredResource := false;
        if ServItem.Get(ServItemLine."Service Item No.") then
            if ServItem."Preferred Resource" = Rec."No." then
                PreferredResource := true;

        Rec.CalcFields("In Customer Zone");
    end;

    trigger OnInit()
    begin
        QtytoallocateEnable := true;
        SelectedDayEnable := true;
        Field32Visible := true;
        Field31Visible := true;
        Field30Visible := true;
        Field29Visible := true;
        Field28Visible := true;
        Field27Visible := true;
        Field26Visible := true;
        Field25Visible := true;
        Field24Visible := true;
        Field23Visible := true;
        Field22Visible := true;
        Field21Visible := true;
        Field20Visible := true;
        Field19Visible := true;
        Field18Visible := true;
        Field17Visible := true;
        Field16Visible := true;
        Field15Visible := true;
        Field14Visible := true;
        Field13Visible := true;
        Field12Visible := true;
        Field11Visible := true;
        Field10Visible := true;
        Field9Visible := true;
        Field8Visible := true;
        Field7Visible := true;
        Field6Visible := true;
        Field5Visible := true;
        Field4Visible := true;
        Field3Visible := true;
        Field2Visible := true;
        Field1Visible := true;
        InCustomerZoneVisible := true;
        SkilledVisible := true;
    end;

    trigger OnOpenPage()
    begin
        ServMgtSetup.Get();
        SetSkills();
        SetVisible();
    end;

    var
        MatrixRec: Record Resource;
        ServMgtSetup: Record "Service Mgt. Setup";
        ServHeader: Record "Service Header";
        ServItemLine: Record "Service Item Line";
        ServItem: Record "Service Item";
        MatrixColumnDateFilters: array[32] of Record Date;
        ServOrderAllocMgt: Codeunit ServAllocationManagement;
        CurrentDocumentType: Integer;
        CurrentDocumentNo: Code[20];
        CurrentServItemLineNo: Integer;
        CurrentEntryNo: Integer;
        SelectedDate: Date;
        PeriodType: Enum "Analysis Period Type";
        QualifiedForServItems: Option "Selected Service Item","All Service Items in Order";
        QtytoAllocate: Decimal;
        Qualified: Boolean;
        PreferredResource: Boolean;
        MATRIX_CellData: array[32] of Decimal;
        MatrixColumnCaptions: array[32] of Text[100];
        SkilledVisible: Boolean;
        InCustomerZoneVisible: Boolean;
        Field1Visible: Boolean;
        Field2Visible: Boolean;
        Field3Visible: Boolean;
        Field4Visible: Boolean;
        Field5Visible: Boolean;
        Field6Visible: Boolean;
        Field7Visible: Boolean;
        Field8Visible: Boolean;
        Field9Visible: Boolean;
        Field10Visible: Boolean;
        Field11Visible: Boolean;
        Field12Visible: Boolean;
        Field13Visible: Boolean;
        Field14Visible: Boolean;
        Field15Visible: Boolean;
        Field16Visible: Boolean;
        Field17Visible: Boolean;
        Field18Visible: Boolean;
        Field19Visible: Boolean;
        Field20Visible: Boolean;
        Field21Visible: Boolean;
        Field22Visible: Boolean;
        Field23Visible: Boolean;
        Field24Visible: Boolean;
        Field25Visible: Boolean;
        Field26Visible: Boolean;
        Field27Visible: Boolean;
        Field28Visible: Boolean;
        Field29Visible: Boolean;
        Field30Visible: Boolean;
        Field31Visible: Boolean;
        Field32Visible: Boolean;
        SelectedDayEnable: Boolean;
        QtytoallocateEnable: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'You cannot allocate a resource when selected period is %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure SetData(DocumentType: Integer; DocumentNo: Code[20]; ServItemLineNo: Integer; EntryNo: Integer; NewMatrixColumnCaptions: array[32] of Text[100]; var NewMatrixDateFilters: array[32] of Record Date; Period: Enum "Analysis Period Type")
    begin
        CurrentDocumentType := DocumentType;
        CurrentDocumentNo := DocumentNo;
        CurrentServItemLineNo := ServItemLineNo;
        CurrentEntryNo := EntryNo;
        CopyArray(MatrixColumnCaptions, NewMatrixColumnCaptions, 1);
        CopyArray(MatrixColumnDateFilters, NewMatrixDateFilters, 1);
        PeriodType := Period;
    end;

    local procedure UpdateFields()
    begin
        if PeriodType = PeriodType::Day then begin
            if not SelectedDayEnable then
                SelectedDayEnable := true;
            if not QtytoallocateEnable then
                QtytoallocateEnable := true;
        end else begin
            if SelectedDayEnable then
                SelectedDayEnable := false;
            if QtytoallocateEnable then
                QtytoallocateEnable := false;
        end;
    end;

    local procedure MatrixOnAfterGetRecord()
    var
        I: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeMatrixOnAfterGetRecord(MatrixRec, MATRIX_CellData, MatrixColumnDateFilters, IsHandled);
        if IsHandled then
            exit;

        MatrixRec.Reset();
        MatrixRec.SetRange("No.", Rec."No.");
        for I := 1 to ArrayLen(MatrixColumnDateFilters) do begin
            MATRIX_CellData[I] := 0;
            MatrixRec.SetRange("Date Filter", MatrixColumnDateFilters[I]."Period Start",
              MatrixColumnDateFilters[I]."Period End");
            if MatrixRec.Find('-') then
                repeat
                    MatrixRec.CalcFields(Capacity, "Qty. on Service Order");
                    MATRIX_CellData[I] := MatrixRec.Capacity -
                      MatrixRec."Qty. on Service Order";
                until MatrixRec.Next() = 0;
        end;

        SetVisible();
    end;

    local procedure MatrixOnDrillDown(Column: Integer)
    var
        Res: Record Resource;
        ResAvailability: Page "Res. Availability - Overview";
    begin
        Clear(ResAvailability);
        Clear(Res);
        Res.SetRange("No.", Rec."No.");
        Res.SetRange("Date Filter", MatrixColumnDateFilters[Column]."Period Start",
          MatrixColumnDateFilters[Column]."Period End");
        ResAvailability.SetTableView(Res);
        ResAvailability.SetRecord(Res);
        ResAvailability.RunModal();
    end;

    procedure SetSkills()
    begin
        if ServMgtSetup."Resource Skills Option" = ServMgtSetup."Resource Skills Option"::"Not Used" then
            SkilledVisible := false
        else
            SkilledVisible := true;
        if ServMgtSetup."Service Zones Option" = ServMgtSetup."Service Zones Option"::"Not Used" then
            InCustomerZoneVisible := false
        else
            InCustomerZoneVisible := true;
        Clear(QtytoAllocate);

        ServHeader.Get(CurrentDocumentType, CurrentDocumentNo);

        UpdateFields();
    end;

    procedure SetVisible()
    begin
        Field1Visible := MatrixColumnCaptions[1] <> '';
        Field2Visible := MatrixColumnCaptions[2] <> '';
        Field3Visible := MatrixColumnCaptions[3] <> '';
        Field4Visible := MatrixColumnCaptions[4] <> '';
        Field5Visible := MatrixColumnCaptions[5] <> '';
        Field6Visible := MatrixColumnCaptions[6] <> '';
        Field7Visible := MatrixColumnCaptions[7] <> '';
        Field8Visible := MatrixColumnCaptions[8] <> '';
        Field9Visible := MatrixColumnCaptions[9] <> '';
        Field10Visible := MatrixColumnCaptions[10] <> '';
        Field11Visible := MatrixColumnCaptions[11] <> '';
        Field12Visible := MatrixColumnCaptions[12] <> '';
        Field13Visible := MatrixColumnCaptions[13] <> '';
        Field14Visible := MatrixColumnCaptions[14] <> '';
        Field15Visible := MatrixColumnCaptions[15] <> '';
        Field16Visible := MatrixColumnCaptions[16] <> '';
        Field17Visible := MatrixColumnCaptions[17] <> '';
        Field18Visible := MatrixColumnCaptions[18] <> '';
        Field19Visible := MatrixColumnCaptions[19] <> '';
        Field20Visible := MatrixColumnCaptions[20] <> '';
        Field21Visible := MatrixColumnCaptions[21] <> '';
        Field22Visible := MatrixColumnCaptions[22] <> '';
        Field23Visible := MatrixColumnCaptions[23] <> '';
        Field24Visible := MatrixColumnCaptions[24] <> '';
        Field25Visible := MatrixColumnCaptions[25] <> '';
        Field26Visible := MatrixColumnCaptions[26] <> '';
        Field27Visible := MatrixColumnCaptions[27] <> '';
        Field28Visible := MatrixColumnCaptions[28] <> '';
        Field29Visible := MatrixColumnCaptions[29] <> '';
        Field30Visible := MatrixColumnCaptions[30] <> '';
        Field31Visible := MatrixColumnCaptions[31] <> '';
        Field32Visible := MatrixColumnCaptions[32] <> '';
    end;

    local procedure QualifiedForServItemsOnAfterVa()
    begin
        CurrPage.Update(false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMatrixOnAfterGetRecord(var MatrixRec: Record Resource; var MATRIX_CellData: array[32] of Decimal; var MatrixColumnDateFilters: array[32] of Record Date; var IsHandled: Boolean)
    begin
    end;
}

