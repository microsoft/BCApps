// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

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

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"E-Doc. Import Error Context", OnValidateFieldWithContext, '', false, false)]
    local procedure ValidateFieldWithContextSubscriber(FieldCaption: Text)
    begin
        CurrentContext := StrSubstNo(ValidatingFieldLbl, FieldCaption);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"E-Doc. Import Error Context", OnSetAdditionalFieldContext, '', false, false)]
    local procedure SetAdditionalFieldContext(FieldName: Text; FieldNo: Integer; Value: Text)
    begin
        CurrentContext := StrSubstNo(AdditionalFieldContextLbl, FieldName, FieldNo, Value);
    end;

    /// <summary>
    /// Sets the context to describe a field being validated during e-document import.
    /// </summary>
    /// <param name="FieldCaption">The caption of the field being validated.</param>
    [IntegrationEvent(false, false)]
    procedure OnValidateFieldWithContext(FieldCaption: Text)
    begin
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
