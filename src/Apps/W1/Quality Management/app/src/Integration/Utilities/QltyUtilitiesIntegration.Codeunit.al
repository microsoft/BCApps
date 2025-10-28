// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Utilities;

using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Setup.Setup;
using Microsoft.Utilities;
using System.Integration;

codeunit 20418 "Qlty. Utilities Integration"
{
    var
        CaptionTok: Label 'caption', Locked = true;

    /// <summary>
    /// To identify the card for custom table, which in turns helps Graphical Scheduler know to use the card with 'Details'
    /// </summary>
    /// <param name="RecRef"></param>
    /// <param name="CardPageID"></param>
    /// <param name="IsHandled"></param>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Page Management", 'OnBeforeGetConditionalCardPageID', '', true, true)]
    local procedure HandleOnBeforeGetConditionalCardPageID(RecRef: RecordRef; var CardPageID: Integer; var IsHandled: Boolean)
    begin
        if RecRef.Number() <> Database::"Qlty. Inspection Test Header" then
            exit;

        CardPageID := Page::"Qlty. Inspection Test";
        IsHandled := true;
    end;

    /// <summary>
    /// Required for use with Business Central approval integration.
    /// </summary>
    /// <param name="RecRef"></param>
    /// <param name="PageID"></param>
    /// <param name="IsHandled"></param>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Page Management", 'OnBeforeGetConditionalListPageID', '', true, true)]
    local procedure HandleOnBeforeGetConditionalListPageID(RecRef: RecordRef; var PageID: Integer; var IsHandled: Boolean);
    begin
        if RecRef.IsTemporary() then
            exit;

        if RecRef.Number() <> Database::"Qlty. Inspection Test Header" then
            exit;

        PageID := Page::"Qlty. Inspection Test List";
        IsHandled := true;
    end;

    /// <summary>
    /// This is to help with Microsoft Teams integration.
    /// This gets called in the context of a web service when Teams is trying to figure out the display summary.
    /// </summary>
    /// <param name="PageId"></param>
    /// <param name="RecId"></param>
    /// <param name="FieldsJsonArray"></param>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Page Summary Provider", 'OnAfterGetPageSummary', '', true, true)]
    local procedure HandleOnAfterGetPageSummary(PageId: Integer; RecId: RecordId; var FieldsJsonArray: JsonArray)
    begin
        InternalHandleOnAfterGetPageSummary(PageId, RecId, FieldsJsonArray);
    end;

    internal procedure InternalHandleOnAfterGetPageSummary(PageId: Integer; RecId: RecordId; var FieldsJsonArray: JsonArray)
    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        FieldToken: JsonToken;
        CaptionToken: JsonToken;
        FieldObject: JsonObject;
    begin
        if RecId.TableNo() <> Database::"Qlty. Inspection Test Header" then
            exit;

        if not QltyManagementSetup.Get() then
            exit;

        foreach FieldToken in FieldsJsonArray do
            if FieldToken.IsObject() then begin
                FieldObject := FieldToken.AsObject();
                if FieldObject.Get(CaptionTok, CaptionToken) then
                    case CaptionToken.AsValue().AsText() of
                        QltyInspectionTestHeader.FieldCaption("Brick Bottom Left"):
                            if FieldObject.Replace(CaptionTok, QltyManagementSetup."Brick Bottom Left Header") then;
                        QltyInspectionTestHeader.FieldCaption("Brick Bottom Right"):
                            if FieldObject.Replace(CaptionTok, QltyManagementSetup."Brick Bottom Right Header") then;
                        QltyInspectionTestHeader.FieldCaption("Brick Middle Left"):
                            if FieldObject.Replace(CaptionTok, QltyManagementSetup."Brick Middle Left Header") then;
                        QltyInspectionTestHeader.FieldCaption("Brick Middle Right"):
                            if FieldObject.Replace(CaptionTok, QltyManagementSetup."Brick Middle Right Header") then;
                        QltyInspectionTestHeader.FieldCaption("Brick Top Left"):
                            if FieldObject.Replace(CaptionTok, QltyManagementSetup."Brick Top Left Header") then;
                    end;
            end;
    end;
}
