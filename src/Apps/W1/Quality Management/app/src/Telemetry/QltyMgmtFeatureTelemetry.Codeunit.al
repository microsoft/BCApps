// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Telemetry;

using System.Telemetry;

codeunit 20458 "Qlty. Mgmt. Feature Telemetry"
{
    Access = Internal;
    InherentPermissions = X;

    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        QualityManagementTok: Label 'Quality Management', Locked = true;

    /// <summary>
    /// Logs a feature uptake telemetry event with status "Discovered" for the specified AL object.
    /// </summary>
    /// <param name="ObjectType">The AL object type (e.g. Page, Codeunit) that discovered the feature.</param>
    /// <param name="ObjectId">The AL object id that discovered the feature.</param>
    internal procedure LogFeatureUptakeDiscovered(ObjectType: ObjectType; ObjectId: Integer)
    begin
        FeatureTelemetry.LogUptake('0000QID', GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Discovered, GetObjectCustomDimensions(ObjectType, ObjectId));
    end;

    /// <summary>
    /// Logs a feature uptake telemetry event with status "Set up" for the specified AL object.
    /// </summary>
    /// <param name="ObjectType">The AL object type (e.g. Page, Codeunit) that completed setup of the feature.</param>
    /// <param name="ObjectId">The AL object id that completed setup of the feature.</param>
    internal procedure LogFeatureUptakeSetup(ObjectType: ObjectType; ObjectId: Integer)
    begin
        FeatureTelemetry.LogUptake('0000QIE', GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up", GetObjectCustomDimensions(ObjectType, ObjectId));
    end;

    /// <summary>
    /// Logs a feature usage telemetry event for the specified AL object and event name.
    /// </summary>
    /// <param name="ObjectType">The AL object type (e.g. Page, Codeunit) where the usage occurred.</param>
    /// <param name="ObjectId">The AL object id where the usage occurred.</param>
    /// <param name="EventName">The name of the usage event to log.</param>
    internal procedure LogFeatureUsage(ObjectType: ObjectType; ObjectId: Integer; EventName: Text)
    begin
        FeatureTelemetry.LogUsage('0000QIA', GetFeatureTelemetryName(), EventName, GetObjectCustomDimensions(ObjectType, ObjectId));
    end;

    /// <summary>
    /// Builds the custom dimensions dictionary used by feature telemetry events, populated with the AL object type and id.
    /// </summary>
    /// <param name="ObjectType">The AL object type to include in the custom dimensions.</param>
    /// <param name="ObjectId">The AL object id to include in the custom dimensions.</param>
    /// <returns>A dictionary containing ObjectType and ObjectId entries.</returns>
    local procedure GetObjectCustomDimensions(ObjectType: ObjectType; ObjectId: Integer) CustomDimensions: Dictionary of [Text, Text]
    begin
        CustomDimensions.Add('ObjectType', Format(ObjectType));
        CustomDimensions.Add('ObjectId', Format(ObjectId));
    end;

    /// <summary>
    /// Returns the telemetry feature name for quality management functionality tracking.
    /// </summary>
    /// <returns>Feature name used for telemetry logging</returns>
    local procedure GetFeatureTelemetryName(): Text
    begin
        exit(QualityManagementTok);
    end;
}
