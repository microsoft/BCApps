// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.IO;

interface "Transformation Rule"
{
    procedure TransformText(TransformationRule: Record "Transformation Rule"; OldValue: Text; var NewValue: Text)
    procedure IsDataFormatUpdateAllowed(): Boolean
    procedure CheckMandatoryFieldsInTransformationRule(TransformationRule: Record "Transformation Rule")
    procedure ValidateTransformationRuleField(FieldNo: Integer; var TransformationRule: Record "Transformation Rule"; var xTransformationRule: Record "Transformation Rule"): Boolean
    procedure GetVisibleGroups(TransformationRule: Record "Transformation Rule"; var VisibleTransformationRuleGroups: List of [Enum "Transformation Rule Group"])
}