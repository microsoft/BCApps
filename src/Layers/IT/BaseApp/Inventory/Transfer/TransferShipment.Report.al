// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Transfer;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Shipping;
using System.Utilities;

report 5704 "Transfer Shipment"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Inventory/Transfer/TransferShipment.rdlc';
    Caption = 'Transfer Shipment';
    WordMergeDataItem = "Transfer Shipment Header";

    dataset
    {
        dataitem("Transfer Shipment Header"; "Transfer Shipment Header")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Transfer-from Code", "Transfer-to Code";
            RequestFilterHeading = 'Posted Transfer Shipment';
            column(No_TransShptHeader; "No.")
            {
            }
            dataitem(CopyLoop; "Integer")
            {
                DataItemTableView = sorting(Number);
                dataitem(PageLoop; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    column(TransferToAddr1; TransferToAddr[1])
                    {
                    }
                    column(TransferFromAddr1; TransferFromAddr[1])
                    {
                    }
                    column(TransferToAddr2; TransferToAddr[2])
                    {
                    }
                    column(TransferFromAddr2; TransferFromAddr[2])
                    {
                    }
                    column(TransferToAddr3; TransferToAddr[3])
                    {
                    }
                    column(TransferFromAddr3; TransferFromAddr[3])
                    {
                    }
                    column(TransferToAddr4; TransferToAddr[4])
                    {
                    }
                    column(TransferFromAddr4; TransferFromAddr[4])
                    {
                    }
                    column(TransferToAddr5; TransferToAddr[5])
                    {
                    }
                    column(TransferToAddr6; TransferToAddr[6])
                    {
                    }
                    column(InTransitCode_TransShptHeader; "Transfer Shipment Header"."In-Transit Code")
                    {
                        IncludeCaption = true;
                    }
                    column(PostingDate_TransShptHeader; Format("Transfer Shipment Header"."Posting Date", 0, 4))
                    {
                    }
                    column(TransferToAddr7; TransferToAddr[7])
                    {
                    }
                    column(TransferToAddr8; TransferToAddr[8])
                    {
                    }
                    column(TransferFromAddr5; TransferFromAddr[5])
                    {
                    }
                    column(TransferFromAddr6; TransferFromAddr[6])
                    {
                    }
                    column(ShptDate_TransShptHeader; Format("Transfer Shipment Header"."Shipment Date"))
                    {
                    }
                    column(TransferFromAddr7; TransferFromAddr[7])
                    {
                    }
                    column(TransferFromAddr8; TransferFromAddr[8])
                    {
                    }
                    column(PageCaption; StrSubstNo(Text002, ''))
                    {
                    }
                    column(OutputNo; OutputNo)
                    {
                    }
                    column(TransShptCopyText; StrSubstNo(Text001, CopyText) + TDDHeaderTxt)
                    {
                    }
                    column(ContracterTxt; ContracterTxt)
                    {
                    }
                    column(AddInfo_TransShptHeader; "Transfer Shipment Header"."Additional Information")
                    {
                    }
                    column(AddNotes_TransShptHeader; "Transfer Shipment Header"."Additional Notes")
                    {
                    }
                    column(AddInstructions_TransShptHeader; "Transfer Shipment Header"."Additional Instructions")
                    {
                    }
                    column(TDDPreparedBy_TransShptHeader; "Transfer Shipment Header"."TDD Prepared By")
                    {
                    }
                    column(ShippingAgentAddr1; ShippingAgentAddr[1])
                    {
                    }
                    column(ShippingAgentAddr2; ShippingAgentAddr[2])
                    {
                    }
                    column(LoaderAddr1; LoaderAddr[1])
                    {
                    }
                    column(LoaderAddr2; LoaderAddr[2])
                    {
                    }
                    column(ShippingAgentAddr3; ShippingAgentAddr[3])
                    {
                    }
                    column(LoaderAddr3; LoaderAddr[3])
                    {
                    }
                    column(ShippingAgentAddr4; ShippingAgentAddr[4])
                    {
                    }
                    column(LoaderAddr4; LoaderAddr[4])
                    {
                    }
                    column(ShippingAgentAddr5; ShippingAgentAddr[5])
                    {
                    }
                    column(LoaderAddr5; LoaderAddr[5])
                    {
                    }
                    column(ShipmenNoCaption; ShipmenNoCaptionLbl)
                    {
                    }
                    column(ShipmentDateCaption; ShipmentDateCaptionLbl)
                    {
                    }
                    column(AddDeclarationInfoCaption; AddDeclarationInfoCaptionLbl)
                    {
                    }
                    column(NotesCaption; NotesCaptionLbl)
                    {
                    }
                    column(AdditionalInstructionsCaption; AdditionalInstructionsCaptionLbl)
                    {
                    }
                    column(CompiledByCaption; CompiledByCaptionLbl)
                    {
                    }
                    column(ShippingAgentAddr1Caption; ShippingAgentAddr1CaptionLbl)
                    {
                    }
                    column(LoaderAddr1Caption; LoaderAddr1CaptionLbl)
                    {
                    }
                    dataitem(DimensionLoop1; "Integer")
                    {
                        DataItemLinkReference = "Transfer Shipment Header";
                        DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                        column(DimText; DimText)
                        {
                        }
                        column(Number_IntegerLine; DimensionLoop1.Number)
                        {
                        }
                        column(HeaderDimensionsCaption; HeaderDimensionsCaptionLbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if Number = 1 then begin
                                if not DimSetEntry1.FindSet() then
                                    CurrReport.Break();
                            end else
                                if not Continue then
                                    CurrReport.Break();

                            Clear(DimText);
                            Continue := false;
                            repeat
                                OldDimText := DimText;
                                if DimText = '' then
                                    DimText := StrSubstNo('%1 - %2', DimSetEntry1."Dimension Code", DimSetEntry1."Dimension Value Code")
                                else
                                    DimText :=
                                      StrSubstNo(
                                        '%1; %2 - %3', DimText,
                                        DimSetEntry1."Dimension Code", DimSetEntry1."Dimension Value Code");
                                if StrLen(DimText) > MaxStrLen(OldDimText) then begin
                                    DimText := OldDimText;
                                    Continue := true;
                                    exit;
                                end;
                            until DimSetEntry1.Next() = 0;
                        end;

                        trigger OnPreDataItem()
                        begin
                            if not ShowInternalInfo then
                                CurrReport.Break();
                        end;
                    }
                    dataitem("Transfer Shipment Line"; "Transfer Shipment Line")
                    {
                        DataItemLink = "Document No." = field("No.");
                        DataItemLinkReference = "Transfer Shipment Header";
                        DataItemTableView = sorting("Document No.", "Line No.");
                        column(ShowInternalInfo; ShowInternalInfo)
                        {
                        }
                        column(ItemNo_TransShptLine; "Item No.")
                        {
                            IncludeCaption = true;
                        }
                        column(Desc_TransShptLine; Description)
                        {
                            IncludeCaption = true;
                        }
                        column(Qty_TransShptLine; Quantity)
                        {
                            IncludeCaption = true;
                        }
                        column(UOM_TransShptLine; "Unit of Measure")
                        {
                            IncludeCaption = true;
                        }
                        column(LineNo_TransShptLine; "Transfer Shipment Line"."Line No.")
                        {
                        }
                        column(ShipmentMethodDescription; ShipmentMethod.Description)
                        {
                        }
                        column(ShipmentMethodDescriptionCaption; ShipmentMethodDescriptionCaptionLbl)
                        {
                        }
                        dataitem(DimensionLoop2; "Integer")
                        {
                            DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                            column(DimText_DimensionLoop2; DimText)
                            {
                            }
                            column(Number_DimensionLoop2; DimensionLoop2.Number)
                            {
                            }
                            column(LineDimensionsCaption; LineDimensionsCaptionLbl)
                            {
                            }

                            trigger OnAfterGetRecord()
                            begin
                                if Number = 1 then begin
                                    if not DimSetEntry2.FindSet() then
                                        CurrReport.Break();
                                end else
                                    if not Continue then
                                        CurrReport.Break();

                                Clear(DimText);
                                Continue := false;
                                repeat
                                    OldDimText := DimText;
                                    if DimText = '' then
                                        DimText := StrSubstNo('%1 - %2', DimSetEntry2."Dimension Code", DimSetEntry2."Dimension Value Code")
                                    else
                                        DimText :=
                                          StrSubstNo(
                                            '%1; %2 - %3', DimText,
                                            DimSetEntry2."Dimension Code", DimSetEntry2."Dimension Value Code");
                                    if StrLen(DimText) > MaxStrLen(OldDimText) then begin
                                        DimText := OldDimText;
                                        Continue := true;
                                        exit;
                                    end;
                                until DimSetEntry2.Next() = 0;
                            end;

                            trigger OnPreDataItem()
                            begin
                                if not ShowInternalInfo then
                                    CurrReport.Break();
                            end;
                        }

                        trigger OnAfterGetRecord()
                        begin
                            DimSetEntry2.SetRange("Dimension Set ID", "Dimension Set ID");
                        end;

                        trigger OnPreDataItem()
                        begin
                            MoreLines := Find('+');
                            while MoreLines and (Description = '') and ("Item No." = '') and (Quantity = 0) do
                                MoreLines := Next(-1) <> 0;
                            if not MoreLines then
                                CurrReport.Break();
                            SetRange("Line No.", 0, "Line No.");
                        end;
                    }
                }

                trigger OnAfterGetRecord()
                begin
                    if Number > 1 then begin
                        CopyText := Text000;
                        OutputNo += 1;
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    NoOfLoops := 1 + Abs(NoOfCopies);
                    CopyText := '';
                    SetRange(Number, 1, NoOfLoops);
                    OutputNo := 1;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                TDDDocument := CheckTDDData();
                if TDDDocument then begin
                    ContracterTxt := Text12100;
                    TDDHeaderTxt := ' / ' + Text12101;
                    GetTDDAddr(ShippingAgentAddr, LoaderAddr);
                end else begin
                    ContracterTxt := '';
                    TDDHeaderTxt := '';
                end;

                DimSetEntry1.SetRange("Dimension Set ID", "Dimension Set ID");

                FormatAddr.TransferShptTransferFrom(TransferFromAddr, "Transfer Shipment Header");
                FormatAddr.TransferShptTransferTo(TransferToAddr, "Transfer Shipment Header");

                if not ShipmentMethod.Get("Shipment Method Code") then
                    ShipmentMethod.Init();
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(NoOfCopies; NoOfCopies)
                    {
                        ApplicationArea = Location;
                        Caption = 'No. of Copies';
                        ToolTip = 'Specifies how many copies of the document to print.';
                    }
                    field(ShowInternalInfo; ShowInternalInfo)
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Show Internal Information';
                        ToolTip = 'Specifies if you want all dimensions assigned to the line to be shown.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        ShipmentMethod: Record "Shipment Method";
        DimSetEntry1: Record "Dimension Set Entry";
        DimSetEntry2: Record "Dimension Set Entry";
        MoreLines: Boolean;
        CopyText: Text[30];
        DimText: Text[120];
        OldDimText: Text[75];
        Continue: Boolean;
        TDDHeaderTxt: Text[60];
        ContracterTxt: Text[30];
        ShippingAgentAddr: array[8] of Text[100];
        LoaderAddr: array[8] of Text[100];

#pragma warning disable AA0074
        Text000: Label 'COPY';
#pragma warning disable AA0470
        Text001: Label 'Transfer Shipment %1';
        Text002: Label 'Page %1';
        Text12100: Label 'Contractor/Goods Owner';
        Text12101: Label 'Transport Delivery Document';
#pragma warning restore AA0470
#pragma warning restore AA0074
        TDDDocument: Boolean;
        ShipmenNoCaptionLbl: Label 'Shipment No.';
        ShipmentDateCaptionLbl: Label 'Shipment Date';
        AddDeclarationInfoCaptionLbl: Label 'Additional Declaration Information:';
        NotesCaptionLbl: Label 'Notes:';
        AdditionalInstructionsCaptionLbl: Label 'Additional Instructions:';
        CompiledByCaptionLbl: Label 'Compiled by:';
        ShippingAgentAddr1CaptionLbl: Label 'Shipping Agent:';
        LoaderAddr1CaptionLbl: Label 'Loader:';
        HeaderDimensionsCaptionLbl: Label 'Header Dimensions';
        ShipmentMethodDescriptionCaptionLbl: Label 'Shipment Method';
        LineDimensionsCaptionLbl: Label 'Line Dimensions';

    protected var
        FormatAddr: Codeunit "Format Address";
        TransferFromAddr: array[8] of Text[100];
        TransferToAddr: array[8] of Text[100];
        NoOfCopies: Integer;
        NoOfLoops: Integer;
        OutputNo: Integer;
        ShowInternalInfo: Boolean;
}

