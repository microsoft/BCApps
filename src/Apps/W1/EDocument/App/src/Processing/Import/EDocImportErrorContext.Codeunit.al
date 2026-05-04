// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

using Microsoft.Purchases.Document;

codeunit 6199 "E-Doc. Import Error Context"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    EventSubscriberInstance = Manual;

    var
        CurrentContext: Text;
        AdditionalFieldContextLbl: Label 'While applying additional field "%1" (ID %2) with value ''%3''', Comment = '%1 = Field Name, %2 = Field Number, %3 = Value';
        ValidatingFieldLbl: Label 'While validating field "%1"', Comment = '%1 = Field Caption';
        WrapErrorLbl: Label '%1: %2', Comment = '%1 = Context, %2 = Original Error';

    /// <summary>
    /// Returns whether a context message is currently set.
    /// </summary>
    /// <returns>True if a context message is set, false otherwise.</returns>
    procedure HasContext(): Boolean
    begin
        exit(CurrentContext <> '');
    end;

    /// <summary>
    /// Wraps the original error message with the current context, if one is set.
    /// </summary>
    /// <param name="OriginalError">The original error message to wrap.</param>
    /// <returns>The error message prefixed with the current context, or the original message if no context is set.</returns>
    procedure WrapErrorMessage(OriginalError: Text): Text
    begin
        if CurrentContext = '' then
            exit(OriginalError);
        exit(StrSubstNo(WrapErrorLbl, CurrentContext, OriginalError));
    end;

    /// <summary>
    /// Clears the additional field context
    /// </summary>
    procedure ClearAdditionalFieldContext()
    begin
        CurrentContext := '';
    end;

    // Purchase Header OnBeforeValidate subscribers

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", OnBeforeValidateEvent, "Document Date", false, false)]
    local procedure OnBeforeValidatePurchHdrDocDate(var Rec: Record "Purchase Header"; var xRec: Record "Purchase Header"; CurrFieldNo: Integer)
    begin
        CurrentContext := StrSubstNo(ValidatingFieldLbl, Rec.FieldCaption("Document Date"));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", OnBeforeValidateEvent, "Due Date", false, false)]
    local procedure OnBeforeValidatePurchHdrDueDate(var Rec: Record "Purchase Header"; var xRec: Record "Purchase Header"; CurrFieldNo: Integer)
    begin
        CurrentContext := StrSubstNo(ValidatingFieldLbl, Rec.FieldCaption("Due Date"));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", OnBeforeValidateEvent, "Vendor Invoice No.", false, false)]
    local procedure OnBeforeValidatePurchHdrVendInvNo(var Rec: Record "Purchase Header"; var xRec: Record "Purchase Header"; CurrFieldNo: Integer)
    begin
        CurrentContext := StrSubstNo(ValidatingFieldLbl, Rec.FieldCaption("Vendor Invoice No."));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", OnBeforeValidateEvent, "Currency Code", false, false)]
    local procedure OnBeforeValidatePurchHdrCurrCode(var Rec: Record "Purchase Header"; var xRec: Record "Purchase Header"; CurrFieldNo: Integer)
    begin
        CurrentContext := StrSubstNo(ValidatingFieldLbl, Rec.FieldCaption("Currency Code"));
    end;

    // Purchase Line OnBeforeValidate subscribers

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnBeforeValidateEvent, "No.", false, false)]
    local procedure OnBeforeValidatePurchLineNo(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
        CurrentContext := StrSubstNo(ValidatingFieldLbl, Rec.FieldCaption("No."));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnBeforeValidateEvent, "Allow Invoice Disc.", false, false)]
    local procedure OnBeforeValidatePurchLineAllowInvDisc(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
        CurrentContext := StrSubstNo(ValidatingFieldLbl, Rec.FieldCaption("Allow Invoice Disc."));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnBeforeValidateEvent, "Item Reference No.", false, false)]
    local procedure OnBeforeValidatePurchLineItemRefNo(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
        CurrentContext := StrSubstNo(ValidatingFieldLbl, Rec.FieldCaption("Item Reference No."));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnBeforeValidateEvent, Quantity, false, false)]
    local procedure OnBeforeValidatePurchLineQty(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
        CurrentContext := StrSubstNo(ValidatingFieldLbl, Rec.FieldCaption(Quantity));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnBeforeValidateEvent, "Direct Unit Cost", false, false)]
    local procedure OnBeforeValidatePurchLineDirectUnitCost(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
        CurrentContext := StrSubstNo(ValidatingFieldLbl, Rec.FieldCaption("Direct Unit Cost"));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnBeforeValidateEvent, "Line Discount Amount", false, false)]
    local procedure OnBeforeValidatePurchLineLineDiscAmt(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
        CurrentContext := StrSubstNo(ValidatingFieldLbl, Rec.FieldCaption("Line Discount Amount"));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnBeforeValidateEvent, "Deferral Code", false, false)]
    local procedure OnBeforeValidatePurchLineDeferralCode(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
        CurrentContext := StrSubstNo(ValidatingFieldLbl, Rec.FieldCaption("Deferral Code"));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnBeforeValidateEvent, "Dimension Set ID", false, false)]
    local procedure OnBeforeValidatePurchLineDimSetId(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
        CurrentContext := StrSubstNo(ValidatingFieldLbl, Rec.FieldCaption("Dimension Set ID"));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnBeforeValidateEvent, "Shortcut Dimension 1 Code", false, false)]
    local procedure OnBeforeValidatePurchLineShortDim1(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
        CurrentContext := StrSubstNo(ValidatingFieldLbl, Rec.FieldCaption("Shortcut Dimension 1 Code"));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnBeforeValidateEvent, "Shortcut Dimension 2 Code", false, false)]
    local procedure OnBeforeValidatePurchLineShortDim2(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
        CurrentContext := StrSubstNo(ValidatingFieldLbl, Rec.FieldCaption("Shortcut Dimension 2 Code"));
    end;

    // Purchase Header OnAfterValidate subscribers - clear context

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", OnAfterValidateEvent, "Document Date", false, false)]
    local procedure OnAfterValidatePurchHdrDocDate(var Rec: Record "Purchase Header"; var xRec: Record "Purchase Header"; CurrFieldNo: Integer)
    begin
        CurrentContext := '';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", OnAfterValidateEvent, "Due Date", false, false)]
    local procedure OnAfterValidatePurchHdrDueDate(var Rec: Record "Purchase Header"; var xRec: Record "Purchase Header"; CurrFieldNo: Integer)
    begin
        CurrentContext := '';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", OnAfterValidateEvent, "Vendor Invoice No.", false, false)]
    local procedure OnAfterValidatePurchHdrVendInvNo(var Rec: Record "Purchase Header"; var xRec: Record "Purchase Header"; CurrFieldNo: Integer)
    begin
        CurrentContext := '';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", OnAfterValidateEvent, "Currency Code", false, false)]
    local procedure OnAfterValidatePurchHdrCurrCode(var Rec: Record "Purchase Header"; var xRec: Record "Purchase Header"; CurrFieldNo: Integer)
    begin
        CurrentContext := '';
    end;

    // Purchase Line OnAfterValidate subscribers - clear context

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnAfterValidateEvent, "No.", false, false)]
    local procedure OnAfterValidatePurchLineNo(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
        CurrentContext := '';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnAfterValidateEvent, "Allow Invoice Disc.", false, false)]
    local procedure OnAfterValidatePurchLineAllowInvDisc(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
        CurrentContext := '';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnAfterValidateEvent, "Item Reference No.", false, false)]
    local procedure OnAfterValidatePurchLineItemRefNo(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
        CurrentContext := '';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnAfterValidateEvent, Quantity, false, false)]
    local procedure OnAfterValidatePurchLineQty(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
        CurrentContext := '';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnAfterValidateEvent, "Direct Unit Cost", false, false)]
    local procedure OnAfterValidatePurchLineDirectUnitCost(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
        CurrentContext := '';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnAfterValidateEvent, "Line Discount Amount", false, false)]
    local procedure OnAfterValidatePurchLineLineDiscAmt(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
        CurrentContext := '';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnAfterValidateEvent, "Deferral Code", false, false)]
    local procedure OnAfterValidatePurchLineDeferralCode(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
        CurrentContext := '';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnAfterValidateEvent, "Dimension Set ID", false, false)]
    local procedure OnAfterValidatePurchLineDimSetId(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
        CurrentContext := '';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnAfterValidateEvent, "Shortcut Dimension 1 Code", false, false)]
    local procedure OnAfterValidatePurchLineShortDim1(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
        CurrentContext := '';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", OnAfterValidateEvent, "Shortcut Dimension 2 Code", false, false)]
    local procedure OnAfterValidatePurchLineShortDim2(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line"; CurrFieldNo: Integer)
    begin
        CurrentContext := '';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"E-Doc. Import Error Context", OnSetAdditionalFieldContext, '', false, false)]
    local procedure SetAdditionalFieldContext(FieldName: Text; FieldNo: Integer; Value: Text)
    begin
        CurrentContext := StrSubstNo(AdditionalFieldContextLbl, FieldName, FieldNo, Value);
    end;

    /// <summary>
    /// Sets the context to describe an additional field being applied
    /// </summary>
    /// <param name="FieldName">The name of the additional field being applied.</param>
    /// <param name="FieldNo">The ID of the additional field being applied.</param>
    /// <param name="Value">The value being applied to the field.</param>
    [IntegrationEvent(false, false)]
    procedure OnSetAdditionalFieldContext(FieldName: Text; FieldNo: Integer; Value: Text)
    begin
    end;
}
