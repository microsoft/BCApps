// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.History;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.UOM;
using System.Utilities;

report 910 "Posted Assembly Order"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Assembly/History/PostedAssemblyOrder.rdlc';
    Caption = 'Posted Assembly Order';
    WordMergeDataItem = CopyLoop;

    dataset
    {
        dataitem(CopyLoop; "Integer")
        {
            DataItemTableView = sorting(Number);
            column(Number; Number)
            {
            }
            dataitem("Posted Assembly Header"; "Posted Assembly Header")
            {
                DataItemTableView = sorting("No.");
                RequestFilterFields = "No.", "Posting Date";
                column(No_PostedAssemblyHeader; "No.")
                {
                    IncludeCaption = true;
                }
                column(OrderNo_PostedAssemblyHeader; "Order No.")
                {
                    IncludeCaption = true;
                }
                column(PostingDate_PostedAssemblyHeader; Format("Posting Date"))
                {
                }
                column(Reversed_PostedAssemblyHeader; GetBoolText(Reversed))
                {
                }
                column(ItemNo_PostedAssemblyHeader; "Item No.")
                {
                    IncludeCaption = true;
                }
                column(Description_PostedAssemblyHeader; Description)
                {
                    IncludeCaption = true;
                }
                column(AssembledQuantity_PostedAssemblyHeader; Quantity)
                {
                    IncludeCaption = true;
                }
                column(UnitOfMeasure_PostedAssemblyHeader; GetUomDescription("Unit of Measure Code"))
                {
                }
                column(LinkedSalesShipment; GetShipmentNo("No."))
                {
                }
                column(CompanyNameConstant; CompName)
                {
                }
                column(DateConstant; DateConstant)
                {
                }
                column(PostingDateConstant; PostingDateConstant)
                {
                }
                dataitem(DimensionLoop1; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                    column(DimText; DimText)
                    {
                    }
                    column(DimLineNo; DimLineNo)
                    {
                    }

                    trigger OnAfterGetRecord()
                    var
                        StopLoop: Boolean;
                        xDimText: Text[75];
                    begin
                        if LastDimCode then
                            CurrReport.Break();
                        DimLineNo += 1;
                        DimText := '';
                        StopLoop := false;
                        repeat
                            xDimText := CopyStr(DimText, 1, MaxStrLen(xDimText));
                            if DimText = '' then
                                DimText := StrSubstNo('%1 - %2', DimensionSetEntry1."Dimension Code", DimensionSetEntry1."Dimension Value Code")
                            else
                                DimText :=
                                  StrSubstNo(
                                    '%1; %2 - %3', DimText,
                                    DimensionSetEntry1."Dimension Code", DimensionSetEntry1."Dimension Value Code");
                            if StrLen(DimText) > MaxStrLen(xDimText) then begin
                                DimText := xDimText;
                                DimensionSetEntry1.Next(-1);
                                StopLoop := true;
                            end;
                            if DimensionSetEntry1.Next() = 0 then
                                LastDimCode := true;
                        until (StopLoop or LastDimCode);
                    end;

                    trigger OnPostDataItem()
                    begin
                        DimLineNo := 0;
                    end;

                    trigger OnPreDataItem()
                    begin
                        DimLineNo := 0;
                        DimLineNo2 := 0;
                        if not ShowInternalInfo then
                            CurrReport.Break();
                        DimensionSetEntry1.SetRange("Dimension Set ID", "Posted Assembly Header"."Dimension Set ID");
                        if not DimensionSetEntry1.FindSet() then
                            CurrReport.Break();
                        LastDimCode := false;
                    end;
                }
                dataitem("Posted Assembly Line"; "Posted Assembly Line")
                {
                    DataItemLink = "Document No." = field("No.");
                    DataItemTableView = sorting("Document No.", "Line No.");
                    column(LineNo_PostedAssemblyLine; "Line No.")
                    {
                    }
                    column(Type_PostedAssemblyLine; Type)
                    {
                        IncludeCaption = true;
                    }
                    column(No_PostedAssemblyLine; "No.")
                    {
                        IncludeCaption = true;
                    }
                    column(Description_PostedAssemblyLine; Description)
                    {
                        IncludeCaption = true;
                    }
                    column(Quantity_PostedAssemblyLine; Quantity)
                    {
                        IncludeCaption = true;
                    }
                    column(Quantityper_PostedAssemblyLine; "Quantity per")
                    {
                        IncludeCaption = true;
                    }
                    column(UnitOfMeasureDescription_PostedAssemblyLine; GetUomDescription("Unit of Measure Code"))
                    {
                    }
                    dataitem(DimensionLoop2; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                        column(DimText2; DimText2)
                        {
                        }
                        column(DimLineNo2; DimLineNo2)
                        {
                        }

                        trigger OnAfterGetRecord()
                        var
                            xDimText: Text[75];
                            StopLoop: Boolean;
                        begin
                            if LastDimCode then
                                CurrReport.Break();
                            DimLineNo2 += 1;
                            DimText2 := '';
                            StopLoop := false;
                            repeat
                                xDimText := CopyStr(DimText2, 1, MaxStrLen(xDimText));
                                if DimText2 = '' then
                                    DimText2 := StrSubstNo('%1 - %2', DimensionSetEntry2."Dimension Code", DimensionSetEntry2."Dimension Value Code")
                                else
                                    DimText2 :=
                                      StrSubstNo(
                                        '%1; %2 - %3', DimText2,
                                        DimensionSetEntry2."Dimension Code", DimensionSetEntry2."Dimension Value Code");
                                if StrLen(DimText2) > MaxStrLen(xDimText) then begin
                                    DimText2 := xDimText;
                                    DimensionSetEntry2.Next(-1);
                                    StopLoop := true;
                                end;
                                if DimensionSetEntry2.Next() = 0 then
                                    LastDimCode := true;
                            until (StopLoop or LastDimCode);
                        end;

                        trigger OnPreDataItem()
                        begin
                            DimLineNo := 0;
                            DimLineNo2 := 0;
                            if not ShowInternalInfo then
                                CurrReport.Break();
                            DimensionSetEntry2.SetRange("Dimension Set ID", "Posted Assembly Line"."Dimension Set ID");
                            if not DimensionSetEntry2.FindSet() then
                                CurrReport.Break();
                            LastDimCode := false;
                        end;
                    }
                }
            }

            trigger OnPreDataItem()
            begin
                SetRange(Number, 1, NoOfCopies + 1);
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
                    field("No. of copies"; NoOfCopies)
                    {
                        ApplicationArea = Assembly;
                        Caption = 'No. of copies';
                        ToolTip = 'Specifies how many copies of the document to print.';
                    }
                    field("Show Dimensions"; ShowInternalInfo)
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Show Dimensions';
                        ToolTip = 'Specifies if the report includes dimensions information.';
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
        PostedAssemblyOrderCaption = 'Posted Assembly Order';
        AssemblyItemCaption = 'Assembly Item';
        BillOfMaterialCaption = 'Bill of Material';
        AssembledToShipmentCaption = 'Asm.-to-Shipment No.';
        UnitofMeasureCaption = 'Unit of Measure';
        AssembledQuantityCaption = 'Assembled Quantity';
        TypeCaption = 'Type';
        NumberCaption = 'No.';
        DescriptionCaption = 'Description';
        QtyPerCaption = 'Qty. per';
        ConsumedQuantityCaption = 'Consumed Quantity';
        PageCaption = 'Page';
        ReversedCaption = 'Reversed';
        ReportNameCaption = 'Posted Assembly Order';
        HeaderDimensionsCaption = 'Header dimensions';
        LineDimensionsCaption = 'Line Dimensions';
        CopyCaption = 'COPY';
    }

    trigger OnInitReport()
    begin
        CompName := CompanyName;
        DateConstant := Format(Today);
        PostingDateConstant := "Posted Assembly Header".FieldCaption("Posting Date");
    end;

    var
        DimensionSetEntry1: Record "Dimension Set Entry";
        DimensionSetEntry2: Record "Dimension Set Entry";
        CompName: Text;
#pragma warning disable AA0074
        FalseText: Label 'No';
        TrueText: Label 'Yes';
#pragma warning restore AA0074
        DateConstant: Text;
        PostingDateConstant: Text;
        ShowInternalInfo: Boolean;
        NoOfCopies: Integer;
        DimText: Text[120];
        DimText2: Text[120];
        DimLineNo: Integer;
        DimLineNo2: Integer;
        LastDimCode: Boolean;

    local procedure GetShipmentNo(PostedAsmOrderNo: Code[20]): Code[20]
    var
        PostedAssembleToOrderLink: Record "Posted Assemble-to-Order Link";
    begin
        if PostedAssembleToOrderLink.Get(PostedAssembleToOrderLink."Assembly Document Type"::Assembly, PostedAsmOrderNo) then
            if PostedAssembleToOrderLink."Document Type" = PostedAssembleToOrderLink."Document Type"::"Sales Shipment" then
                exit(PostedAssembleToOrderLink."Document No.");
        exit('');
    end;

    local procedure GetUomDescription(UOMCode: Code[10]): Text[50]
    var
        UnitOfMeasure: Record "Unit of Measure";
        IsHandled: Boolean;
        Result: Text[50];
    begin
        IsHandled := false;
        OnBeforeGetUomDescription(UOMCode, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if UnitOfMeasure.Get(UOMCode) then
            exit(UnitOfMeasure.Description);
        exit('');
    end;

    local procedure GetBoolText(Input: Boolean): Text[10]
    begin
        if Input then
            exit(TrueText);
        exit(FalseText);
    end;

    procedure InitializeRequest(NewNoOfCopies: Integer; NewShowInternalInfo: Boolean)
    begin
        NoOfCopies := NewNoOfCopies;
        ShowInternalInfo := NewShowInternalInfo;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetUomDescription(UOMCode: Code[10]; var Result: Text[50]; var IsHandled: Boolean)
    begin
    end;
}

