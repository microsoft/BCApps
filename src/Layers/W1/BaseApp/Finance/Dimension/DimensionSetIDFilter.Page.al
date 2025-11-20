// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

page 481 "Dimension Set ID Filter"
{
    Caption = 'Dimension Filter';
    DelayedInsert = true;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    RefreshOnActivate = true;
    ShowFilter = false;
    SourceTable = Dimension;
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control4)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Dimensions;
                    TableRelation = Dimension.Code;
                    ToolTip = 'Specifies the code for the dimension.';

                    trigger OnValidate()
                    var
                        Dimension: Record Dimension;
                    begin
                        if not Dimension.Get(Rec.Code) then begin
                            Dimension.SetFilter(Code, '%1', '@' + Rec.Code + '*');
                            if not Dimension.FindFirst() then
                                Dimension.Get(Rec.Code);
                            Rec.Code := Dimension.Code;
                        end;
                        if Rec.Get(Rec.Code) then
                            Error(RecordAlreadyExistsErr);
                        Rec.Insert();
                        TempDimensionSetIDFilterLine.Code := '';
                        TempDimensionSetIDFilterLine."Dimension Code" := Rec.Code;
                        TempDimensionSetIDFilterLine.SetDimensionValueFilter('');
                        CurrPage.Update(false);
                    end;
                }
                field(DimensionValueFilter; DimensionValueFilter)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Filter';
                    ToolTip = 'Specifies the filter for the dimension values.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        DimensionValue: Record "Dimension Value";
                    begin
                        exit(DimensionValue.LookUpDimFilter(Rec.Code, Text));
                    end;

                    trigger OnValidate()
                    begin
                        TempDimensionSetIDFilterLine.Code := '';
                        TempDimensionSetIDFilterLine."Dimension Code" := Rec.Code;
                        TempDimensionSetIDFilterLine.SetDimensionValueFilter(DimensionValueFilter);
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Clear Filter")
            {
                ApplicationArea = Dimensions;
                Caption = 'Clear Filter';
                Image = ClearFilter;
                ToolTip = 'Remove the filter for all dimensions.';

                trigger OnAction()
                begin
                    TempDimensionSetIDFilterLine.Reset();
                    TempDimensionSetIDFilterLine.DeleteAll();
                    Rec.DeleteAll();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Clear Filter_Promoted"; "Clear Filter")
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        DimensionValueFilter := TempDimensionSetIDFilterLine.GetDimensionValueFilter('', Rec.Code);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        TempDimensionSetIDFilterLine.Reset();
        TempDimensionSetIDFilterLine.SetRange(Code, '');
        TempDimensionSetIDFilterLine.SetRange("Dimension Code", Rec.Code);
        TempDimensionSetIDFilterLine.DeleteAll();
        Rec.Delete();
        CurrPage.Update(false);
        exit(false);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        exit(false);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        DimensionValueFilter := ''
    end;

    trigger OnOpenPage()
    begin
        TempDimensionSetIDFilterLine.SetRange(Code, '');
        TempDimensionSetIDFilterLine.SetRange("Line No.", 1);
        if TempDimensionSetIDFilterLine.FindSet() then
            repeat
                Rec.Code := TempDimensionSetIDFilterLine."Dimension Code";
                Rec.Insert();
            until TempDimensionSetIDFilterLine.Next() = 0;
    end;

    var
        TempDimensionSetIDFilterLine: Record "Dimension Set ID Filter Line" temporary;
        FilterNotification: Notification;
        NotificationGUID: Guid;
        DimensionValueFilter: Text;
        NotificationMsg: Label 'The view is filtered by dimensions:';
        RecordAlreadyExistsErr: Label 'The record already exists.';

    procedure LookupFilter() DimFilter: Text
    var
        DimensionMgt: Codeunit DimensionManagement;
        DimSetIDFilterPage: Page "Dimension Set ID Filter";
    begin
        DimSetIDFilterPage.SetTempDimensionSetIDFilterLine(TempDimensionSetIDFilterLine);
        DimSetIDFilterPage.Editable(true);
        DimSetIDFilterPage.RunModal();
        DimSetIDFilterPage.GetTempDimensionSetIDFilterLine(TempDimensionSetIDFilterLine);
        TempDimensionSetIDFilterLine.Reset();
        if not TempDimensionSetIDFilterLine.IsEmpty() then begin
            GetDimSetIDsForFilter(DimensionMgt);
            DimFilter := DimensionMgt.GetDimSetFilter();
            if DimFilter = '' then
                DimFilter := '0&<>0';
            SendNotification();
        end else
            RecallNotification();
    end;

    local procedure GetDimSetIDsForFilter(var DimensionMgt: Codeunit DimensionManagement)
    begin
        TempDimensionSetIDFilterLine.Reset();
        TempDimensionSetIDFilterLine.SetRange(Code, '');
        TempDimensionSetIDFilterLine.SetRange("Line No.", 1);
        if TempDimensionSetIDFilterLine.FindSet() then
            repeat
                DimensionMgt.GetDimSetIDsForFilter(TempDimensionSetIDFilterLine."Dimension Code",
                  TempDimensionSetIDFilterLine.GetDimensionValueFilter(
                    TempDimensionSetIDFilterLine.Code, TempDimensionSetIDFilterLine."Dimension Code"));
            until TempDimensionSetIDFilterLine.Next() = 0;
    end;

    procedure GetTempDimensionSetIDFilterLine(var NewTempDimensionSetIDFilterLine: Record "Dimension Set ID Filter Line" temporary)
    begin
        NewTempDimensionSetIDFilterLine.Copy(TempDimensionSetIDFilterLine, true)
    end;

    procedure SetTempDimensionSetIDFilterLine(var NewTempDimensionSetIDFilterLine: Record "Dimension Set ID Filter Line" temporary)
    begin
        TempDimensionSetIDFilterLine.Copy(NewTempDimensionSetIDFilterLine, true);
    end;

    local procedure GetNotificationMessage() MessageTxt: Text
    begin
        TempDimensionSetIDFilterLine.Reset();
        TempDimensionSetIDFilterLine.SetRange(Code, '');
        TempDimensionSetIDFilterLine.SetRange("Line No.", 1);
        if TempDimensionSetIDFilterLine.FindSet() then begin
            MessageTxt := StrSubstNo('%1 %2: %3', NotificationMsg, TempDimensionSetIDFilterLine."Dimension Code",
                TempDimensionSetIDFilterLine.GetDimensionValueFilter('', TempDimensionSetIDFilterLine."Dimension Code"));
            if TempDimensionSetIDFilterLine.Next() <> 0 then
                repeat
                    MessageTxt += StrSubstNo(', %1: %2', TempDimensionSetIDFilterLine."Dimension Code",
                        TempDimensionSetIDFilterLine.GetDimensionValueFilter('', TempDimensionSetIDFilterLine."Dimension Code"));
                until TempDimensionSetIDFilterLine.Next() = 0;
        end;
    end;

    local procedure SendNotification()
    begin
        if IsNullGuid(NotificationGUID) then
            NotificationGUID := CreateGuid();
        FilterNotification.Id := NotificationGUID;
        FilterNotification.Message(GetNotificationMessage());
        FilterNotification.Send();
    end;

    local procedure RecallNotification()
    begin
        if not IsNullGuid(NotificationGUID) then begin
            FilterNotification.Id := NotificationGUID;
            FilterNotification.Recall();
        end;
    end;
}

